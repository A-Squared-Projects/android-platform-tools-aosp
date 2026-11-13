# android-platform-tools

AOSP's platform-tools sources (adb, adbd, fastboot and the libraries they
need), with a small make-based build in place of Soong and a quilt patch
stack for building and running them on plain Linux.

Debian's android-platform-tools packaging was the starting point for the
makefiles and several patches; nothing here tracks Debian any more.

## Layout

- AOSP sources, unmodified, at their AOSP paths (`packages/modules/adb`,
  `system/core`, ...). `scripts/aosp-projects` lists the projects: the ones
  the build uses (the recipe's `AOSP_PROJECTS`), plus `development`, imported
  only for the version; `aosp.excludes` lists what's left out (prebuilts,
  test data, ...).
- `build/`: the build. `build/Makefile` builds a tool and the libraries it
  needs; `build/*.mk` build one library or tool each; `build/version.mk` sets
  `PLATFORM_TOOLS_VERSION` (from the tree's own `Pkg.Revision`) and
  `ADB_BUILD_ID`.
- `build/platform/`: the Android platform adbd expects, supplied for Linux so
  adbd's own code runs unchanged rather than being patched case by case:
  - system properties (`system_properties.cpp`): `ro.*` from build.prop-style
    files (`ADBD_PROPERTY_FILES`, default `/etc/build.prop:/run/build.prop`,
    later files win), everything else one file per property under
    `ADBD_PROPERTY_DIR` (default `/run/adbd/properties`). It overrides
    libbase's weak non-bionic implementation and liblog's
    `__android_log_is_debuggable()`, so upstream's `ro.secure`,
    `ro.debuggable`, `service.adb.root` and `ro.adb.secure` handling applies;
  - minijail (`minijail.cpp`): `AID_SHELL` is the Linux user `ADBD_USER`
    (default `adb`), with its own groups;
  - `selinux_android_setcon()` (`selinux.cpp`), for `--root_seclabel`: the
    context `adb root` runs in. SELinux's `setcon()` when built with
    `HAVE_SELINUX=1` and enabled, else SMACK's process label if SMACK is
    active, else it fails (and adbd comes back unprivileged);
  - `build/version.h`, `platform_tools_version.h`: stand-ins;
  - `adbd-reboot`: the default `ADBD_REBOOT_COMMAND`.
- `aosp-patches/`: the patch stack (`aosp-patches/series`). Every patch
  carries an `Upstream-Status`.
- `scripts/export-oe-patches.sh <recipe-dir>`: copies `build/` and the
  patch stack into the OE recipe directory and writes
  `android-tools-aosp-patches.inc` (the patches in SRC_URI). The recipe
  fetches the AOSP projects itself, from android.googlesource.com at
  `AOSP_TAG`; this repo is where releases get imported and patches rebased.

## Building

    QUILT_PATCHES=aosp-patches QUILT_PC=.pc-aosp quilt push -a
    make -f build/Makefile adbd          # target daemon
    make -f build/Makefile host-tools    # adb, fastboot, img2simg, simg2img

Output goes to `out/`. Pass `SYSROOT=`, `PROTOC=` and any of the options the
makefiles read (`ADB_BUILD_ID`, `HAVE_SYSTEMD=1`, `ADBD_AUTH_KEY_PATHS=`,
`ADBD_USER=`, `ADBD_PROPERTY_FILES=`, `ADBD_PROPERTY_DIR=`,
`ADBD_REBOOT_COMMAND=`, `ADBD_REMOUNT_COMMAND=`, `HAVE_SELINUX=1`) on the make
command line.

adbd, on the device: it needs a user `ADBD_USER`; root/auth policy comes
from `ro.secure`, `ro.debuggable` and `ro.adb.secure` in the build.prop
files, as on Android; `adb root`/`unroot` and `adb tcpip`/`usb` make adbd
exit for init to restart it (any restart policy that restarts on exit);
readiness is `sd_notify` with `HAVE_SYSTEMD=1`, else `$ADBD_READY_FIFO`;
`adb remount` runs `ADBD_REMOUNT_COMMAND` (default `remount` on `$PATH`).

The non-default quilt names keep out of the way of OE's own `${S}/patches`
and `.pc`.

## New upstream release

    scripts/fetch-aosp.sh <tag>          # platform-tools-X.Y.Z, or android-N.0.0_rM
    git add -A && git commit -m "Import platform-tools X.Y.Z (<tag>)" && git tag aosp/X.Y.Z
    QUILT_PATCHES=aosp-patches QUILT_PC=.pc-aosp quilt push -a
    # fix and refresh failing patches, update build/*.mk source lists, then
    # quilt pop -a and commit

Google stopped tagging `platform-tools-*` after 35.0.2; later releases come
from AOSP release tags (`Pkg.Revision` in
`development/sdk/plat_tools_source.prop_template` gives the version).

Never commit the tree with patches applied.

## Licensing

The AOSP sources keep their own licenses (mostly Apache-2.0; see each
project's NOTICE/LICENSE and file headers). `build/` is MIT (Expat), see
`build/COPYING`; it started from Debian's android-platform-tools packaging.
The patches in `aosp-patches/` are under the license of the files they
change.
