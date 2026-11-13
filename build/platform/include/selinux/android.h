// SPDX-License-Identifier: MIT
// Copyright (C) 2026 Alex Kiernan <alex.kiernan@gmail.com>
/*
 * Android's libselinux extension, as far as adbd uses it: switching to the
 * --root_seclabel context when running as root. See build/platform/selinux.cpp.
 */
#pragma once

#ifdef __cplusplus
extern "C" {
#endif

int selinux_android_setcon(const char* context);

#ifdef __cplusplus
}
#endif
