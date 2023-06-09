#include <iostream>
#include "../models/mnist_digit_images/mnist_digit_overlord.hpp"

int main()
{
	mnist_digit_overlord overlord;
	
	overlord.train(150, 100, 1.0f);

	std::cout << "start testing" << std::endl;
	test_result t_result = overlord.test();
	std::cout << "testing done" << std::endl;
	std::cout << t_result.to_string() << std::endl;

	return 0;

	matrix m;
	m.get_string();
}