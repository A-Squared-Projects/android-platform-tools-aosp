# android-platform-tools

AOSP's platform-tools sources (adb, adbd, fastboot and the libraries they
need), with a small make-based build in place of Soong and a quilt patch
stack for building and running them on plain Linux.

Debian's android-platform-tools packaging was the starting point for the
makefiles and several patches; nothing here tracks Debian any more.

## Layout

- AOSP sources, unmodified, at their AOSP paths (`packages/modules/adb`,
  `system/core`, ...). `scripts/aosp-projects` lists the projects;
  `aosp.excludes` lists what's left out (prebuilts, test data, ...).
- `build/`: the build. `build/Makefile` builds a tool and the libraries it
  needs; `build/*.mk` build one library or tool each; `build/version.mk` sets
  `PLATFORM_TOOLS_VERSION` (from the tree's own `Pkg.Revision`) and
  `ADB_BUILD_ID`.
- `aosp-patches/`: the patch stack (`aosp-patches/series`). Every patch
  carries an `Upstream-Status`.

## Building

    QUILT_PATCHES=aosp-patches QUILT_PC=.pc-aosp quilt push -a
    make -f build/Makefile adbd          # target daemon
    make -f build/Makefile host-tools    # adb, fastboot, img2simg, simg2img

Output goes to `out/`. Pass `SYSROOT=`, `PROTOC=` and any of the options the
makefiles read (`ADB_BUILD_ID`, `HAVE_SYSTEMD=1`,
`ADBD_AUTH_UNLESS_DEBUGGABLE=1`, `ADBD_AUTH_KEY_PATHS=`,
`LIBLOG_DEBUGGABLE_PROP_FILES=`) on the make command line.

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
