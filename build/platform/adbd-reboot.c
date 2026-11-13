/*
 * adbd's reboot command (Android's /system/bin/reboot): `adbd-reboot [target]`.
 *
 * Syncs and restarts straight away, without an init shutdown, passing the
 * target (e.g. "bootloader") to LINUX_REBOOT_CMD_RESTART2 for the bootloader
 * to interpret. Needs CAP_SYS_BOOT, i.e. `adb root` first.
 */

#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <sys/syscall.h>
#include <unistd.h>

#include <linux/reboot.h>

int main(int argc, char** argv) {
    const char* target = argc > 1 ? argv[1] : "";
    long rc;

    sync();
    if (*target) {
        rc = syscall(SYS_reboot, LINUX_REBOOT_MAGIC1, LINUX_REBOOT_MAGIC2, LINUX_REBOOT_CMD_RESTART2,
                     target);
    } else {
        rc = syscall(SYS_reboot, LINUX_REBOOT_MAGIC1, LINUX_REBOOT_MAGIC2, LINUX_REBOOT_CMD_RESTART,
                     NULL);
    }
    if (rc != 0) {
        fprintf(stderr, "reboot (%s) failed: %s\n", target, strerror(errno));
        return 1;
    }
    return 0;
}
