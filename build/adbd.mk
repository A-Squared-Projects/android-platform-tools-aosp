NAME = adbd

include build/version.mk

# The Android platform adbd expects (build/platform/): who AID_SHELL is, where
# properties live, and the commands behind `adb reboot` and `adb remount`.
ADBD_USER ?= adb
ADBD_PROPERTY_FILES ?= /etc/build.prop:/run/build.prop
ADBD_PROPERTY_DIR ?= /run/adbd/properties
ADBD_REBOOT_COMMAND ?= /usr/libexec/adbd/reboot
ADBD_REMOUNT_COMMAND ?= remount

# packages/modules/adb/Android.bp
ADBD_SRC_FILES = \
  adb.cpp \
  adb_io.cpp \
  adb_listeners.cpp \
  adb_trace.cpp \
  services.cpp \
  sockets.cpp \
  socket_spec.cpp \
  transport.cpp \
  transport_fd.cpp \
  types.cpp \
  daemon/adb_wifi.cpp \
  daemon/auth.cpp \
  daemon/mdns.cpp \
  daemon/jdwp_service.cpp \
  daemon/logging.cpp \
  daemon/main.cpp \
  daemon/framebuffer_service.cpp \
  daemon/restart_service.cpp \
  daemon/transport_socket_server.cpp \
  daemon/usb.cpp \
  daemon/usb_ffs.cpp \
#  adb_mdns.cpp \

# packages/modules/adb/libs/adbconnection/Android.bp
LIBADBD_adbconnection_server_SRC_FILES := \
  libs/adbconnection/adbconnection_server.cpp \

# packages/modules/adb/Android.bp
LIBADBD_services_SRC_FILES := \
  daemon/file_sync_service.cpp \
  daemon/services.cpp \
  daemon/shell_service.cpp \
  daemon/tradeinmode.cpp \
  shell_service_protocol.cpp \

# packages/modules/adb/libs/libadbd_fs/Android.bp
LIBADBD_fs_SRC_FILES := \
  libs/libadbd_fs/adbd_fs.cpp \

LIBDIAGNOSE_USB_SRC_FILES = diagnose_usb/diagnose_usb.cpp
LIBASYNCIO_SRC_FILES = libasyncio/AsyncIO.cpp

LIBADBD_AUTH_SRC_FILES = libs/adbd_auth/adbd_auth.cpp

PLATFORM_SRC_FILES = \
  minijail.cpp \
  selinux.cpp \
  system_properties.cpp \

LOCAL_SRC_FILES := \
  $(ADBD_SRC_FILES) \
  $(LIBADBD_adbconnection_server_SRC_FILES) \
  $(LIBADBD_services_SRC_FILES) \
  $(LIBADBD_fs_SRC_FILES) \

SOURCES := \
  $(foreach source, $(LOCAL_SRC_FILES), packages/modules/adb/$(source)) \
  $(foreach source, $(LIBDIAGNOSE_USB_SRC_FILES), system/core/$(source)) \
  $(foreach source, $(LIBASYNCIO_SRC_FILES), system/core/$(source)) \
  $(foreach source, $(LIBADBD_AUTH_SRC_FILES), frameworks/native/$(source)) \
  $(foreach source, $(PLATFORM_SRC_FILES), build/platform/$(source)) \

OBJECTS = $(SOURCES:.cpp=.$(NAME).o)

CXXFLAGS += \
  -Wno-narrowing \

CPPFLAGS += \
  -D_GNU_SOURCE \
  -DADB_BUILD_ID='"$(ADB_BUILD_ID)"' \
  -DPLATFORM_TOOLS_VERSION='"$(PLATFORM_TOOLS_VERSION)"' \
  -DADB_HOST=0 \
  -DANDROID_BASE_UNIQUE_FD_DISABLE_IMPLICIT_CONVERSION=1 \
  -DPAGE_SIZE=4096 \
  -DADBD_USER='"$(ADBD_USER)"' \
  -DADBD_PROPERTY_FILES='"$(ADBD_PROPERTY_FILES)"' \
  -DADBD_PROPERTY_DIR='"$(ADBD_PROPERTY_DIR)"' \
  -DADBD_REBOOT_COMMAND='"$(ADBD_REBOOT_COMMAND)"' \
  -DADBD_REMOUNT_COMMAND='"$(ADBD_REMOUNT_COMMAND)"' \
  -Ibuild/platform/include \
  -Iframeworks/native/libs/adbd_auth/include/ \
  -Ipackages/modules/adb \
  -Ipackages/modules/adb/crypto/include \
  -Ipackages/modules/adb/libs/libadbd_fs/include \
  -Ipackages/modules/adb/libs/adbconnection/include \
  -Ipackages/modules/adb/proto \
  -Ipackages/modules/adb/tls/include \
  -Isystem/core/diagnose_usb/include \
  -Isystem/core/include \
  -Isystem/core/libasyncio/include \
  -Isystem/core/libcrypto_utils/include \
  -Isystem/core/libcutils/include \
  -Isystem/libbase/include \
  -Isystem/logging/liblog/include \
  \
  -I$(SYSROOT)/usr/include/android \

LDFLAGS += \
  -Lout \
  -Wl,-rpath='$$ORIGIN/../lib/android' \
  -lbase \
  -lbrotlidec \
  -lbrotlienc \
  -lcap \
  -l:libcrypto.so.0 \
  -lcutils \
  -llog \
  -llz4 \
  -lprotobuf \
  -labsl_log_internal_message \
  -labsl_log_internal_check_op \
  -lresolv \
  -l:libssl.so.0 \
  -lzstd \
  -pie \
  -Wl,--export-dynamic-symbol='__system_property_*' \
  -Wl,--export-dynamic-symbol=__android_log_is_debuggable \

ifeq ($(HAVE_SYSTEMD),1)
LDFLAGS += -lsystemd
CPPFLAGS += -DHAVE_SYSTEMD
endif

ifeq ($(HAVE_SELINUX),1)
LDFLAGS += -lselinux
CPPFLAGS += -DHAVE_SELINUX
endif

ifneq ($(ADBD_AUTH_KEY_PATHS),)
CPPFLAGS += -DADBD_AUTH_KEY_PATHS='"$(ADBD_AUTH_KEY_PATHS)"'
endif

STATIC_LIBS = \
  out/libadb.a \
  out/libcrypto_utils.a \

out/$(NAME): $(OBJECTS) $(STATIC_LIBS)
	$(CXX) -o $@ $^ $(LDFLAGS)

$(OBJECTS): %.$(NAME).o: %.cpp
	$(CXX) -c -o $@ $< $(CXXFLAGS) $(CPPFLAGS)
