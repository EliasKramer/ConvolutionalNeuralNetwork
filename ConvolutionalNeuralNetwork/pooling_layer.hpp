#pragma once
#include "matrix.hpp"
#include "layer.hpp"

enum _pooling_type
{
	max_pooling,
	min_pooling,
	average_pooling
} typedef e_pooling_type_t;

class pooling_layer : public layer {
private:
	int filter_size;
	int stride;
	e_pooling_type_t pooling_fn;
public:
	//constructor
	pooling_layer(
		matrix* input,
		int filter_size,
		int stride,
		e_pooling_type_t pooling_fn
	);

	int get_filter_size() const;
	int get_stride() const;
	e_pooling_type_t get_pooling_fn() const;

	void forward_propagation() override;
	void back_propagation() override;
};