#include "log.h"

#include <shlobj.h>
#include <windows.h>

// #include <dechamps_CMakeUtils/version.h>

#include "../FlexASIOUtil/shell.h"

namespace flexasio {

	namespace {

		class FlexASIOLogSink final : public ::dechamps_cpplog::LogSink {
			public:
				static std::unique_ptr<FlexASIOLogSink> Open() {
					std::filesystem::path path;
					try {
						path = GetUserDirectory();
					}
					catch (...) {
						return nullptr;
					}
					path.append("FlexASIO.log");

					if (!std::filesystem::exists(path)) return nullptr;

					return std::make_unique<FlexASIOLogSink>(path);
				}

				static FlexASIOLogSink* Get() {
					static const auto output = Open();
					return output.get();
				}

				FlexASIOLogSink(const std::filesystem::path& path) : file_sink(path) {
					//::dechamps_cpplog::Logger(this) << "FlexASIO " << BUILD_CONFIGURATION << " " << BUILD_PLATFORM << " " << ::dechamps_CMakeUtils_gitDescriptionDirty << " built on " << ::dechamps_CMakeUtils_buildTime;

				}

				void Write(const std::string_view str) override { return preamble_sink.Write(str); }

			private:
				::dechamps_cpplog::FileLogSink file_sink;
				::dechamps_cpplog::ThreadSafeLogSink thread_safe_sink{ file_sink };
				::dechamps_cpplog::PreambleLogSink preamble_sink{ thread_safe_sink };
		};

	}

	bool IsLoggingEnabled() { return FlexASIOLogSink::Get() != nullptr; }
	::dechamps_cpplog::Logger Log() { return ::dechamps_cpplog::Logger(FlexASIOLogSink::Get()); }

}