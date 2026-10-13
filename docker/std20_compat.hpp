// Backfills the C++20 library pieces that libstdc++ 10 (the aarch64 sysroot, glibc 2.31 era) lacks.
// Force-included into every C++ translation unit by docker/toolchain-aarch64.cmake. Each definition is
// guarded by its feature macro, so a newer library makes it a no-op.
#pragma once
#include <type_traits>
#include <version>

#if !defined(__cpp_lib_bit_cast)
namespace std {
template <typename To, typename From>
constexpr To bit_cast(const From& from) noexcept {
    static_assert(sizeof(To) == sizeof(From) && is_trivially_copyable_v<To> && is_trivially_copyable_v<From>);
    return __builtin_bit_cast(To, from);
}
} // namespace std
#endif
