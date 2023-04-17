#include "convolutional_layer.hpp"

convolutional_layer::convolutional_layer(
	int number_of_kernels,
	int kernel_size,
	int stride,
	e_activation_t activation_function
)
	:layer(e_layer_type_t::convolution),
	stride(stride),
	kernel_size(kernel_size),
	activation_fn(activation_function)
{
	if(number_of_kernels <= 0)
		throw std::invalid_argument("number_of_kernels must be greater than 0");
	if (kernel_size <= 0)
		throw std::invalid_argument("kernel_size must be greater than 0");
	if (stride <= 0)
		throw std::invalid_argument("stride must be greater than 0");

	if(stride > kernel_size)
		throw std::invalid_argument("stride must be smaller or equal than the kernel_size");

	for (int i = 0; i < number_of_kernels; i++)
	{
		kernels.push_back(conv_kernel(kernel_size));
		kernel_deltas.push_back(conv_kernel(kernel_size));
	}

	activations = matrix(0, 0, 0);
}

const std::vector<conv_kernel>& convolutional_layer::get_kernels_readonly() const
{
	return kernels;
}

std::vector<conv_kernel>& convolutional_layer::get_kernels()
{
	return kernels;
}

int convolutional_layer::get_kernel_size() const
{
	return kernel_size;
}

int convolutional_layer::get_stride() const
{
	return stride;
}

void convolutional_layer::set_input_format(const matrix& input_format)
{
	layer::set_input_format(input_format);

	const int input_depth = input_format.get_depth();
	
	const float output_width = 
		(input_format.get_width() - kernel_size) / (float)stride + 1;
	
	const float output_height = 
		(input_format.get_height() - kernel_size) / (float)stride + 1;

	if(!is_whole_number(output_width) || 
		!is_whole_number(output_height))
		throw std::invalid_argument("input format is not compatible with the kernel size and stride");

	for (int i = 0; i < kernels.size(); i++)
	{
		kernels[i].set_kernel_depth(input_depth);
		kernel_deltas[i].set_kernel_depth(input_depth);
	}
	
	activations.resize((int)output_width, (int)output_height, (int)kernels.size());
}

void convolutional_layer::set_all_parameter(float value)
{
	for (conv_kernel& kernel : kernels)
	{
		kernel.get_weights().set_all(value);
	}
}

void convolutional_layer::apply_noise(float range)
{
	for (conv_kernel& kernel : kernels)
	{
		kernel.get_weights().apply_noise( range);

		kernel.set_bias(
			kernel.get_bias() +
			random_float_incl(-range, range));
	}
}

void convolutional_layer::mutate(float range)
{
	//choose a random kernel
	int random_kernel_idx = random_idx((int)kernels.size());
	//choose if a weight or a bias is mutated
	if (biased_coin_toss(
		(float)kernels[0].get_weights_readonly().flat_readonly().size(),
		1.0f))
	{
		//choose a random weight to mutate
		int random_weight_idx = 
			random_idx((int)kernels[0]
				.get_weights_readonly()
				.flat_readonly()
				.size());

		//mutate the weight
		kernels[random_kernel_idx]
			.get_weights()
			.flat()[random_weight_idx] +=
				random_float_incl(-range, range);
	}
	else
	{
		//mutate the bias

		kernels[random_kernel_idx].set_bias(
			kernels[random_kernel_idx].get_bias() +
			random_float_incl(-range, range));
	}
}

void convolutional_layer::forward_propagation()
{
	const size_t kernel_size = kernels[0].get_kernel_size();
	const size_t number_of_kernels = kernels.size();
	const int output_width = activations.get_width();
	const int output_height = activations.get_height();
	const int input_depth = input->get_depth();

	for (int depth = 0; depth < number_of_kernels; depth++)
	{
		conv_kernel& kernel = kernels[depth];
		for (int y = 0; y < output_height; y++)
		{
			for (int x = 0; x < output_width; x++)
			{
				float value = kernel.lay_kernel_over_matrix(
					*input,
					x * stride,
					y * stride);
				activations.set_at( x, y, depth, value);
			}
		}
	}
	activations.apply_activation_function(activation_fn);
	
}

void convolutional_layer::back_propagation()
{
	//TODO
}

void convolutional_layer::apply_deltas(int number_of_inputs)
{
	//TODO
}
