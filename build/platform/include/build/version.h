/*
 * Soong's build/version.h. The build number is ADB_BUILD_ID, set by
 * build/version.mk.
 */
#pragma once

#include <string>

#ifndef ADB_BUILD_ID
#error ADB_BUILD_ID must be defined (build/version.mk)
#endif

namespace android {
namespace build {

inline std::string GetBuildNumber() {
    return ADB_BUILD_ID;
}

}  // namespace build
}  // namespace android
