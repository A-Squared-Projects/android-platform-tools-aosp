/*
 * selinux_android_setcon() for Linux: the security context adbd switches to
 * when it runs as root and was started with --root_seclabel=<context>.
 *
 *  - SELinux, if built with HAVE_SELINUX and enabled on the running system:
 *    setcon(), which the policy must allow as a dynamic transition.
 *  - Otherwise SMACK, if active: the label is written to the process's SMACK
 *    attribute (needs CAP_MAC_ADMIN, which root adbd has).
 *  - Otherwise there's nothing to apply the context with, so it fails.
 *
 * adbd treats failure as fatal and resets service.adb.root first, so it comes
 * back unprivileged rather than as root in the wrong context.
 */

#include <selinux/android.h>

#include <errno.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>

#if defined(HAVE_SELINUX)
#include <selinux/selinux.h>
#endif

namespace {

bool SmackActive() {
    return access("/sys/fs/smackfs", F_OK) == 0;
}

int SmackSetLabel(const char* label) {
    // /proc/self/attr/smack/current where the kernel has per-LSM attribute
    // directories (LSM stacking), /proc/self/attr/current otherwise.
    int fd = open("/proc/self/attr/smack/current", O_WRONLY | O_CLOEXEC);
    if (fd == -1 && errno == ENOENT) {
        fd = open("/proc/self/attr/current", O_WRONLY | O_CLOEXEC);
    }
    if (fd == -1) return -1;
    size_t len = strlen(label);
    ssize_t n = write(fd, label, len);
    int saved = errno;
    close(fd);
    if (n != static_cast<ssize_t>(len)) {
        errno = n == -1 ? saved : EIO;
        return -1;
    }
    return 0;
}

}  // namespace

extern "C" int selinux_android_setcon(const char* context) {
    if (context == nullptr || *context == '\0') {
        errno = EINVAL;
        return -1;
    }
#if defined(HAVE_SELINUX)
    if (is_selinux_enabled() > 0) {
        return setcon(context);
    }
#endif
    if (SmackActive()) {
        return SmackSetLabel(context);
    }
    errno = ENOTSUP;
    return -1;
}
