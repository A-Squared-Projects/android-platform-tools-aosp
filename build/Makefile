# Top-level build for the Yocto android-tools recipe: builds the libraries a
# tool needs, in order, then the tool. Run from the top of the tree:
#
#   make -f build/Makefile adbd                 # target: adbd
#   make -f build/Makefile host-tools           # native: adb, fastboot, img2simg, simg2img
#
# Everything lands in out/. Variables given on the command line (SYSROOT,
# PROTOC, ADB_BUILD_ID, HAVE_SYSTEMD, ADBD_AUTH_*, LIBLOG_DEBUGGABLE_PROP_FILES,
# ...) reach every sub-make.

PROTOC ?= protoc

ADBD_LIBS := liblog libbase libcutils libcrypto_utils libadb
ADBD_TOOLS := adbd adbd-reboot

HOST_LIBS := liblog libbase libcutils libziparchive libsparse libcrypto_utils libadb libext4_utils
HOST_TOOLS := adb fastboot img2simg simg2img

.PHONY: adbd host-tools protos dirs

adbd: protos dirs
	for mk in $(ADBD_LIBS) $(ADBD_TOOLS); do $(MAKE) -f build/$$mk.mk || exit 1; done

host-tools: protos dirs
	for mk in $(HOST_LIBS) $(HOST_TOOLS); do $(MAKE) -f build/$$mk.mk || exit 1; done

dirs:
	mkdir -p out/extras

# The makefiles compile the generated protobuf sources but don't generate them.
ADB_PROTOS := $(wildcard packages/modules/adb/proto/*.proto)
FASTDEPLOY_PROTOS := $(wildcard packages/modules/adb/fastdeploy/proto/*.proto)

protos: $(ADB_PROTOS:.proto=.pb.cc) $(FASTDEPLOY_PROTOS:.proto=.pb.cc)

packages/modules/adb/proto/%.pb.cc: packages/modules/adb/proto/%.proto
	$(PROTOC) --proto_path=packages/modules/adb/proto --cpp_out=packages/modules/adb/proto $<

packages/modules/adb/fastdeploy/proto/%.pb.cc: packages/modules/adb/fastdeploy/proto/%.proto
	$(PROTOC) --proto_path=packages/modules/adb --cpp_out=packages/modules/adb $<
