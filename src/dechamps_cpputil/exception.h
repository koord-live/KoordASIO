#pragma once

#include <exception>
#include <string>

namespace dechamps_cpputil {

	std::string GetNestedExceptionMessage(const std::exception& exception);

}