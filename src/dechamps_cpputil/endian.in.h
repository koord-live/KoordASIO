#pragma once

#cmakedefine01 DECHAMPS_CPPUTIL_BIG_ENDIAN

#include <cstdlib>
#include <type_traits>

namespace dechamps_cpputil {
	enum class Endianness { LITTLE, BIG };

#if !defined(DECHAMPS_CPPUTIL_BIG_ENDIAN)
#error "unknown endianness"
#elif DECHAMPS_CPPUTIL_BIG_ENDIAN == 0
	constexpr Endianness endianness = Endianness::LITTLE;
#elif DECHAMPS_CPPUTIL_BIG_ENDIAN == 1
	constexpr Endianness endianness = Endianness::BIG;
#endif

	inline Endianness OppositeEndianness(Endianness originalEndianness) {
		switch (originalEndianness) {
		case Endianness::LITTLE: return Endianness::BIG;
		case Endianness::BIG: return Endianness::LITTLE;
		}
		abort();
	}

}
