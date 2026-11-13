// SPDX-License-Identifier: MIT
// Copyright (C) 2026 Alex Kiernan <alex.kiernan@gmail.com>
/*
 * Soong generates this header; here PLATFORM_TOOLS_VERSION comes from the
 * command line, set by build/version.mk.
 */
#pragma once

#ifndef PLATFORM_TOOLS_VERSION
#error PLATFORM_TOOLS_VERSION must be defined (build/version.mk)
#endif
