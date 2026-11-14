# android-platform-tools-aosp

Workbench for android-tools (adb, adbd, fastboot): unmodified AOSP sources,
our make-based build, and a quilt patch stack. The OE layer
(meta-android-platform-tools) consumes `build/` and the patches by export;
it fetches the AOSP projects itself. See README.md for the layout.

## Rules

- This is general-purpose code, not any one product's. Never mention a
  downstream product, customer, device, internal codename or test unit in
  code, docs, patch headers or commit messages; describe behaviour
  generically ("a debug-unlock token" is fine, a product name is not).
- AOSP files are never edited and committed directly. Every change to them
  is a patch in `aosp-patches/`, listed in `aosp-patches/series`.
- Never commit with the patches applied. `quilt pop -a` and remove `.pc-aosp`
  before committing; `git status` must show only `aosp-patches/`, `build/`,
  `scripts/` or docs.
- Quilt: `export QUILT_PATCHES=aosp-patches QUILT_PC=.pc-aosp` (not the
  defaults: OE uses `patches/` and `.pc`). Refresh with
  `quilt refresh -p ab --no-timestamps --no-index`; `quilt add` before
  editing a file. Delete quilt's `*~` backups.
- The stack must apply with `quilt push -a --fuzz=0`. Check after any change.
- Prefer supplying what adbd expects from Android in `build/platform/`
  (properties, minijail, SELinux/SMACK, version headers) over patching adbd.
  New patches should be small and independent; don't add a patch that turns
  something off for another to turn back on.
- Patch headers: `From:`/`Date:`/`Subject:` (git format-patch style), a
  description saying why, then `Upstream-Status:` (required; the export
  refuses patches without it), `AI-Generated: <model>` when AI-written, and
  `Signed-off-by: Alex Kiernan <alex.kiernan@gmail.com>`.
- `build/` is ours (MIT, `build/COPYING`); new files there get an
  `SPDX-License-Identifier: MIT` header.
- `scripts/aosp-projects` lists the projects the build uses (plus
  `development`, workbench-only). It must match the layer recipe's
  `AOSP_PROJECTS`; the export checks.

## Verifying

The full build needs the OE layer (BoringSSL, protobuf, libusb, libcap come
from the sysroot), so real builds happen there. Locally:

- `make -s -f build/<x>.mk --eval='__f: ; @echo $(SOURCES)' __f` lists a
  makefile's sources; check they exist after an import.
- With the stack applied, `g++ -std=gnu++23 -fsyntax-only` using a makefile's
  `CPPFLAGS` catches missing includes and API changes. Errors about
  `bssl`/protobuf/libcap headers are host-side, not real.
- liblog and libbase build on the host with `build/liblog.mk` and
  `build/libbase.mk` (`CXXFLAGS="-std=gnu++23 -fPIC"`), enough to test
  `build/platform/` code against them.

## Export

From a clean, committed tree:

    scripts/export-oe-patches.sh <layer>/recipes-devtools/android-tools

then commit in the layer.

## New release

Google stopped tagging `platform-tools-*` after 35.0.2; use AOSP release tags
(`android-17.0.0_r1` is 37.0.0; `Pkg.Revision` in
`development/sdk/plat_tools_source.prop_template` gives the version).
`scripts/check-aosp-releases.sh` lists recent tags with their versions and
marks those newer than the last import; `--all` also checks every project in
`scripts/aosp-projects` has the tag. Then `scripts/fetch-aosp.sh <tag>`,
commit, tag `aosp/<version>` (it prints both), rebase the stack, and update
`build/*.mk` source lists against the tag's Android.bp.
