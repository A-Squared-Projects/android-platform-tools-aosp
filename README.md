# android-platform-tools

Unmodified AOSP sources for platform-tools, with a quilt patch stack on top.

- `scripts/aosp-projects`: AOSP projects and where they live in the tree
- `scripts/fetch-aosp.sh`: replaces the tree with a given `platform-tools-*` tag, filtered through `aosp.excludes`
- `debian/**/*.mk`: Debian's hand-written makefiles (from 35.0.2-1~exp6), which replace Soong; the Yocto recipe builds with these
- `aosp-patches/debian/`: Debian's patches, copied unchanged from salsa
- `aosp-patches/yocto/`: Yocto patches (from meta-oe android-tools)
- `aosp-patches/series`: Debian's full series
- `aosp-patches/series.yocto`: what Yocto applies, which is Debian's series minus the MIPS reverts, then `yocto/`

Applying the patches:

    export QUILT_PATCHES=aosp-patches QUILT_PC=.pc-aosp
    QUILT_SERIES=series.yocto quilt push -a

The non-default names keep out of the way of OE's own `${S}/patches` and `.pc`.

New upstream release:

    scripts/fetch-aosp.sh platform-tools-X.Y.Z
    git add -A && git commit -m "Import platform-tools-X.Y.Z" && git tag aosp/X.Y.Z
    quilt push -a      # refresh/fix failing patches, then: quilt pop -a; commit

Never commit the tree with patches applied.
