#include "gpu_math.cuh"

#define THREADS_PER_BLOCK 1024

static unsigned int get_block_count(unsigned int size)
{
	//if we have 1024 elements, we need 1 block
	//if we have 1025 elements, we need 2 blocks
	//if we have 2048 elements, we need 2 blocks
	//and as long as it is under 1024 - 1 thread will still work
	return ((size - 1) / THREADS_PER_BLOCK) + 1;
}

static void set_device()
{
	cudaError_t cudaStatus = cudaSetDevice(0);
	if (cudaStatus != cudaSuccess)
	{
		throw std::runtime_error("gpu_sigmoid failed. cudaSetDevice failed");
	}
}

static void check_for_error_and_synchronize()
{
	cudaError_t cudaStatus = cudaGetLastError();
	if (cudaStatus != cudaSuccess)
	{
		throw std::runtime_error("gpu_sigmoid failed. kernel launch failed");
	}

	cudaStatus = cudaDeviceSynchronize();
	if (cudaStatus != cudaSuccess)
	{
		throw std::runtime_error("gpu_sigmoid failed. cudaDeviceSynchronize failed");
	}
}

__device__ int get_idx(int x, int y, int z, int height, int width)
{
	return x + y * width + z * width * height;
}

__global__ void gpu_dot_product_kernel(
	const float* weights,
	const float* input,
	const int input_size,
	float* activations,
	const int activations_size)
{
	unsigned int activation_idx = blockIdx.x * blockDim.x + threadIdx.x;
	if (activation_idx < activations_size)
	{
		float sum = 0;
		for (int i = 0; i < input_size; i++)
		{
			int weight_idx = get_idx(i, activation_idx, 0,
				activations_size, input_size);
			sum += weights[weight_idx] * input[i];
		}
		activations[activation_idx] = sum;
	}
}

float* gpu_sub_ptr(gpu_memory<float>& gpu_memory, size_t elements_per_idx, size_t index)
{
	if (gpu_memory.gpu_data_ptr() == nullptr)
	{
		throw std::invalid_argument("gpu_sub_ptr failed. gpu_memory.gpu_data_ptr() is null");
	}
	if (index >= gpu_memory.item_count())
	{
		throw std::invalid_argument("gpu_sub_ptr failed. index out of range");
	}
	if (gpu_memory.size() < elements_per_idx * sizeof(float))
	{
		throw std::invalid_argument("gpu_sub_ptr failed. size_of_element must be less than gpu_memory.size()");
	}

	return (float*)((char*)gpu_memory.gpu_data_ptr() + index * elements_per_idx * sizeof(float));
}

void gpu_dot_product(
	const gpu_memory<float>& gpu_weights,
	const gpu_memory<float>& gpu_input,
	gpu_memory<float>& gpu_activations)
{
	if (gpu_weights.item_count() == 0 ||
		gpu_input.item_count() == 0 ||
		gpu_activations.item_count() == 0)
	{
		throw std::invalid_argument("gpu_dot_product failed. size must be greater than 0");
	}
	if (gpu_activations.item_count() * gpu_input.item_count() != gpu_weights.item_count())
	{
		throw std::invalid_argument("gpu_dot_product failed. false format");
	}

	set_device();

	unsigned int size = gpu_activations.item_count();
	unsigned int block_count = get_block_count(size);
	gpu_dot_product_kernel << < block_count, THREADS_PER_BLOCK >> > (
		gpu_weights.gpu_data_ptr(),
		gpu_input.gpu_data_ptr(),
		gpu_input.item_count(),
		gpu_activations.gpu_data_ptr(),
		gpu_activations.item_count());

	check_for_error_and_synchronize();
}

__global__ void gpu_add_matrices_kernel(const float* a, const float* b, float* result, unsigned int size)
{
	unsigned int index = blockIdx.x * blockDim.x + threadIdx.x;
	if (index < size)
	{
		result[index] = a[index] + b[index];
	}
}
void gpu_add(
	const gpu_memory<float>& gpu_memory_a,
	const gpu_memory<float>& gpu_memory_b,
	gpu_memory<float>& gpu_memory_result)
{
	if (gpu_memory_a.item_count() == 0 ||
		gpu_memory_a.item_count() != gpu_memory_b.item_count() ||
		gpu_memory_a.item_count() != gpu_memory_result.item_count())
	{
		throw std::invalid_argument("gpu_add_matrices failed. size must be greater than 0");
	}

	set_device();

	unsigned int size = gpu_memory_a.item_count();

	gpu_add_matrices_kernel << < get_block_count(size), THREADS_PER_BLOCK >> > (
		gpu_memory_a.gpu_data_ptr(),
		gpu_memory_b.gpu_data_ptr(),
		gpu_memory_result.gpu_data_ptr(),
		size);

	check_for_error_and_synchronize();
}

__global__ void gpu_valid_cross_correlation_kernel(
	const float* input,
	const float* weights,
	float* result,
	const int input_depth,
	const int input_width)
{

}

void gpu_valid_cross_correlation(
	const gpu_memory<float>& gpu_input,
	const std::vector<gpu_memory<float>>& gpu_kernel_weights,
	gpu_memory<float>& gpu_activations,
	size_t input_size,
	size_t input_depth,
	size_t kernel_size,
	size_t kernel_count,
	size_t stride,
	size_t output_size)
{
	if (gpu_input.item_count() == 0 ||
		gpu_activations.item_count() == 0 ||
		gpu_kernel_weights.size() == 0)
	{
		throw std::invalid_argument("gpu_valid_cross_correlation failed. size must be greater than 0");
	}
	if (input_size * input_size * input_depth != gpu_input.item_count())
	{
		throw std::invalid_argument("input size is different on gpu and cpu");
	}
	if (!is_whole_number(gpu_kernel_weights[0].item_count() / kernel_count))
	{
		throw std::invalid_argument("gpu kernels could not be devided by kernel count");
	}
	if (kernel_size * kernel_size * input_depth != (gpu_kernel_weights[0].item_count() / kernel_count))
	{
		throw std::invalid_argument("kernel size false");
	}

	const float output_side_size = (input_size - kernel_size) / (float)stride + 1;
	if (!is_whole_number(output_side_size))
	{
		throw std::invalid_argument("gpu_valid_cross_correlation failed. this stride, size combination cannot be used");
	}
	if (gpu_activations.item_count() != output_side_size * output_side_size * kernel_count)
	{
		throw std::invalid_argument("gpu_valid_cross_correlation failed. false format");
	}
	set_device();


	for (int activation_depth = 0; activation_depth < kernel_count; activation_depth++)
	{
		//splits the gpu_activations into its dephts
		float* activation_ptr = gpu_sub_ptr(gpu_activations, output_size * output_size, activation_depth);

		dim3 thread(output_side_size, output_side_size, 1);
		//TODO
		gpu_valid_cross_correlation_kernel << <1, 1 >> > (
			gpu_input.gpu_data_ptr(),
			gpu_kernel_weights[activation_depth].gpu_data_ptr(),
			activation_ptr,
			input_depth,
			input_size);
	}

	check_for_error_and_synchronize();
}

__global__ void gpu_sigmoid_kernel(float* data, int size)
{
	unsigned int index = blockIdx.x * blockDim.x + threadIdx.x;
	if (index < size)
	{
		data[index] = 1 / (1 + exp(-data[index]));
	}
}

void gpu_sigmoid(gpu_memory<float>& gpu_memory)
{
	if (gpu_memory.item_count() == 0)
	{
		throw std::invalid_argument("gpu_sigmoid failed. size must be greater than 0");
	}

	set_device();

	unsigned int size = gpu_memory.item_count();
	gpu_sigmoid_kernel << < get_block_count(size), THREADS_PER_BLOCK >> > (
		gpu_memory.gpu_data_ptr(),
		size);

	check_for_error_and_synchronize();
}

__global__ void gpu_relu_kernel(float* data, int size)
{
	unsigned int index = blockIdx.x * blockDim.x + threadIdx.x;
	if (index < size)
	{
		data[index] = data[index] > 0 ? data[index] : 0;
	}
}

void gpu_relu(gpu_memory<float>& gpu_memory)
{
	if (gpu_memory.item_count() == 0)
	{
		throw std::invalid_argument("gpu_relu failed. size must be greater than 0");
	}

	set_device();

	unsigned int size = gpu_memory.item_count();
	gpu_relu_kernel << < get_block_count(size), THREADS_PER_BLOCK >> > (
		gpu_memory.gpu_data_ptr(),
		size);

	check_for_error_and_synchronize();
}