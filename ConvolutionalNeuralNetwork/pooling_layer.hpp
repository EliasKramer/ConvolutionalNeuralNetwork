#pragma once
#include "matrix.hpp"
#include "layer.hpp"

enum _pooling_type
{
	max_pooling,
	min_pooling,
	average_pooling
} typedef pooling_type;

struct _pooling_layer : layer {
	int filter_size;
	int stride;
	pooling_type pooling_fn;
} typedef pooling_layer;

pooling_layer* create_pooling_layer(
	matrix* input,
	int filter_size,
	int stride, 
	pooling_type pooling_fn);

void feed_forward(pooling_layer& layer);