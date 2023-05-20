#include "CppUnitTest.h"
#include "../ConvolutionalNeuralNetwork/data_space.hpp"
using namespace Microsoft::VisualStudio::CppUnitTestFramework;

namespace CNNTest
{
	TEST_CLASS(data_space_test)
	{
	public:
		TEST_METHOD(onlydata_data_space_constructor_test)
		{
			matrix data_format(2, 2, 1);

			std::vector<matrix> data;

			data_format.set_all(1.0f);
			data.push_back(data_format);
			data_format.set_all(2.0f);
			data.push_back(data_format);

			data_space ds(data_format, data);

			Assert::AreEqual((size_t)2, ds.get_item_count());
		}
		TEST_METHOD(data_space_constructor_test)
		{
			matrix data_format(2, 2, 3);
			matrix label_format(1, 1, 1);

			std::vector<matrix> data;
			std::vector<matrix> label;

			data_format.set_all(1.0f);
			data.push_back(data_format);

			label_format.set_all(1.5f);
			label.push_back(label_format);

			data_space ds(data_format, label_format, data, label);


			Assert::AreEqual((size_t)1, ds.get_item_count());
		}
		TEST_METHOD(get_only_data)
		{
			matrix data_format(2, 2, 1);

			std::vector<matrix> data;

			data_format.set_all(1.0f);
			data.push_back(data_format);
			data_format.set_all(2.0f);
			data.push_back(data_format);

			data_space ds(data_format, data);

			matrix m1 = matrix(2, 2, 1);
			m1.set_all(1.0f);
			matrix m2 = matrix(2, 2, 1);
			m2.set_all(2.0f);


			matrix m = ds.get_next_data();
			Assert::IsTrue(matrix::are_equal(m1, m));

			ds.iterator_next();
			m = ds.get_next_data();
			Assert::IsTrue(matrix::are_equal(m2, m));
		}
		TEST_METHOD(get_data_and_label_test)
		{
			matrix data_format(2, 2, 3);
			matrix label_format(1, 2, 1);

			std::vector<matrix> data;
			std::vector<matrix> label;

			data_format.set_all(1.0f);
			data.push_back(data_format);

			label_format.set_all(1.5f);
			label.push_back(label_format);

			data_format.set_all(5.0f);
			data.push_back(data_format);

			label_format.set_all(5.5f);
			label.push_back(label_format);

			data_space ds(data_format, label_format, data, label);

			matrix expected_data(2, 2, 3);
			matrix expected_label(1, 2, 1);

			matrix m = ds.get_next_data();
			matrix l = ds.get_next_label();
			expected_data.set_all(1.0f);
			expected_label.set_all(1.5f);
			Assert::IsTrue(matrix::are_equal(m, expected_data));
			Assert::IsTrue(matrix::are_equal(l, expected_label));

			ds.iterator_next();
			
			m = ds.get_next_data();
			l = ds.get_next_label();
			expected_data.set_all(5.0f);
			expected_label.set_all(5.5f);
			Assert::IsTrue(matrix::are_equal(m, expected_data));
			Assert::IsTrue(matrix::are_equal(l, expected_label));
		}
	};
}