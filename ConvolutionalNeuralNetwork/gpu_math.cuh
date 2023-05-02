#pragma once
#include <stdexcept>
#include "matrix.hpp"
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include "gpu_memory.cuh"

void gpu_dot_product(
	const gpu_memory<float>& gpu_weights,
	const gpu_memory<float>& gpu_input,
	gpu_memory<float>& gpu_activations);

void gpu_add(
	const gpu_memory<float>& gpu_memory_a,
	const gpu_memory<float>& gpu_memory_b,
	gpu_memory<float>& gpu_memory_result);

using gpu_activation_fn = void(*)(gpu_memory<float>&);

void gpu_sigmoid(gpu_memory<float>& gpu_memory);
void gpu_relu(gpu_memory<float>& gpu_memory);

const gpu_activation_fn GPU_ACTIVATION[] = {
	gpu_sigmoid,
	gpu_relu
};