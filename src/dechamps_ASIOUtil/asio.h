#pragma once

#ifdef DECHAMPS_ASIOUTIL_BUILD
#include <common/asiosys.h>
#include <common/asio.h>
#else
#include <dechamps_ASIOUtil/asiosdk/asiosys.h>
#include <dechamps_ASIOUtil/asiosdk/asio.h>
#endif

#include <cstdint>
#include <string>
#include <optional>

namespace dechamps_ASIOUtil {
	template <typename ASIOInt64> int64_t ASIOToInt64(ASIOInt64);
	template <typename ASIOInt64> ASIOInt64 Int64ToASIO(int64_t);

	std::string GetASIOErrorString(ASIOError error);

	std::string GetASIOSampleTypeString(ASIOSampleType sampleType);
	std::optional<size_t> GetASIOSampleSize(ASIOSampleType sampleType);

	std::string GetASIOFutureSelectorString(long selector);
	std::string GetASIOMessageSelectorString(long selector);

	std::string GetAsioTimeInfoFlagsString(unsigned long timeInfoFlags);
	std::string GetASIOTimeCodeFlagsString(unsigned long timeCodeFlags);

	std::string DescribeASIOTimeInfo(const AsioTimeInfo& asioTimeInfo);
	std::string DescribeASIOTimeCode(const ASIOTimeCode& asioTimeCode);
	std::string DescribeASIOTime(const ASIOTime& asioTime);

}