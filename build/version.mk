# SPDX-License-Identifier: MIT (see build/COPYING)
# Version strings compiled into adb, adbd and fastboot.
#
# PLATFORM_TOOLS_VERSION defaults to the release the tree declares itself to
# be. ADB_BUILD_ID stands in for Android's build number (android::build::
# GetBuildNumber(), shown by `adb version` and `fastboot --version`) and
# defaults to the same; pass something more specific, e.g. a distro build
# identifier, on the make command line.
PLATFORM_TOOLS_VERSION ?= $(shell sed -n 's/^Pkg\.Revision=//p' development/sdk/plat_tools_source.prop_template)
ADB_BUILD_ID ?= $(PLATFORM_TOOLS_VERSION)
