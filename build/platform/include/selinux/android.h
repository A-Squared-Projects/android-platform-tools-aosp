/*
 * adbd only uses selinux_android_setcon() when started with --root_seclabel.
 * There's no Android SELinux policy here, so asking for one fails, and adbd
 * treats that as fatal rather than running in the wrong context.
 */
#pragma once

#include <errno.h>

static inline int selinux_android_setcon(const char* /* context */) {
    errno = ENOTSUP;
    return -1;
}
