#include "exception.h"

#include <sstream>

namespace dechamps_cpputil {

	namespace {

		void AppendException(std::stringstream& stringstream, const std::exception& exception) {
			if (stringstream.tellp() > 0) stringstream << ": ";
			stringstream << exception.what();
			try {
				std::rethrow_if_nested(exception);
			}
			catch (const std::exception& nestedException) {
				AppendException(stringstream, nestedException);
			}
			catch (...) {
				stringstream << "unknown nested exception";
			}
		}

	}

	std::string GetNestedExceptionMessage(const std::exception& exception) {
		std::stringstream stringstream;
		AppendException(stringstream, exception);
		return stringstream.str();
	}

}