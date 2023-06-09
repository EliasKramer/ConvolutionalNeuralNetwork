#include "test_result.hpp"

std::string test_result::to_string()
{
	std::string result = "";
	result += "Data count: " + std::to_string(data_count) + "\n";
	result += "Time taken: " + ms_to_str(time_in_ms) + "\n";
	result += "Avg cost: " + std::to_string(avg_cost) + "\n";
	result += "Accuracy: " + std::to_string(accuracy * 100) + "%\n";
	return result;	
}
