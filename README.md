# android-platform-tools

Unmodified AOSP sources for platform-tools, with a quilt patch stack on top.

- `scripts/aosp-projects`: AOSP projects and where they live in the tree
- `scripts/fetch-aosp.sh`: replaces the tree with a given `platform-tools-*` tag, filtered through `aosp.excludes`
- `aosp-patches/`: quilt series, Debian patches (`debian/`, copied unchanged from salsa) first, then `yocto/`

Applying the patches:

    export QUILT_PATCHES=aosp-patches QUILT_PC=.pc-aosp
    quilt push -a

The non-default names keep out of the way of OE's own `${S}/patches` and `.pc`.

New upstream release:

    scripts/fetch-aosp.sh platform-tools-X.Y.Z
    git add -A && git commit -m "Import platform-tools-X.Y.Z" && git tag aosp/X.Y.Z
    quilt push -a      # refresh/fix failing patches, then: quilt pop -a; commit

Never commit the tree with patches applied.
