# SPDX-License-Identifier: MIT (see build/COPYING)
NAME = adb

include build/version.mk

# packages/modules/adb/Android.bp
ADB_SRC_FILES = \
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
  client/adb_client.cpp \
  client/bugreport.cpp \
  client/commandline.cpp \
  client/file_sync_client.cpp \
  client/main.cpp \
  client/console.cpp \
  client/adb_install.cpp \
  client/line_printer.cpp \
  client/incremental.cpp \
  client/incremental_server.cpp \
  client/incremental_utils.cpp \
  shell_service_protocol.cpp \
  \
  proto/adb_host.pb.cc \
  proto/adb_known_hosts.pb.cc \
  proto/app_processes.pb.cc \
  proto/key_type.pb.cc \
  proto/pairing.pb.cc \
#  fastdeploy/proto/ApkEntry.pb.cc \
#  client/fastdeploy.cpp \

# packages/modules/adb/Android.bp
LIBADB_host_SRC_FILES := \
  client/auth.cpp \
  client/adb_wifi.cpp \
  client/usb_libusb.cpp \
  client/usb_libusb_device.cpp \
  client/usb_libusb_hotplug.cpp \
  client/usb_libusb_inhouse_hotplug.cpp \
  client/detach.cpp \
  client/discovered_services.cpp \
  client/mdns_tracker.cpp \
  client/transport_emulator.cpp \
  client/mdns_utils.cpp \
  client/transport_usb.cpp \
  client/pairing/pairing_client.cpp \
  \
  client/usb_linux.cpp \
  client/usb_linux_netlink.cpp \

LOCAL_SRC_FILES := \
  $(ADB_SRC_FILES) \
  $(LIBADB_host_SRC_FILES) \

LIBDIAGNOSE_USB_SRC_FILES = diagnose_usb/diagnose_usb.cpp

GEN := dummy.cpp

SOURCES := \
  $(foreach source, $(LOCAL_SRC_FILES), packages/modules/adb/$(source)) \
  $(foreach source, $(LIBDIAGNOSE_USB_SRC_FILES), system/core/$(source)) \
  $(foreach source, $(GEN), out/$(source)) \

SOURCES_CPP = $(filter %.cpp,$(SOURCES))
OBJECTS_CPP = $(SOURCES_CPP:.cpp=.o)
SOURCES_CC = $(filter %.cc,$(SOURCES))
OBJECTS_CC = $(SOURCES_CC:.cc=.o)

CPPFLAGS += \
  -D_GNU_SOURCE \
  -DADB_BUILD_ID='"$(ADB_BUILD_ID)"' \
  -DPLATFORM_TOOLS_VERSION='"$(PLATFORM_TOOLS_VERSION)"' \
  -Ibuild/platform/include \
  -DADB_HOST=1 \
  -DANDROID_BASE_UNIQUE_FD_DISABLE_IMPLICIT_CONVERSION=1 \
  -Ifastdeploy/proto \
  -Ipackages/modules/adb \
  -Ipackages/modules/adb/crypto/include \
  -Ipackages/modules/adb/pairing_connection/include \
  -Ipackages/modules/adb/proto \
  -Ipackages/modules/adb/tls/include \
  -Isystem/core/diagnose_usb/include \
  -Isystem/core/include \
  -Isystem/core/libcrypto_utils/include \
  -Isystem/libbase/include \
  -Isystem/libziparchive/include \
  \
  -I$(SYSROOT)/usr/include/android \

LDFLAGS += \
  -Lout \
  -Wl,-rpath='$$ORIGIN/../lib/android' \
  -lbase \
  -lbrotlidec \
  -lbrotlienc \
  -l:libcrypto.so.0 \
  -lcutils \
  -llog \
  -llz4 \
  -lprotobuf \
  -labsl_log_internal_message \
  -labsl_log_internal_check_op \
  -lpthread \
  -l:libssl.so.0 \
  -lusb-1.0 \
  -lziparchive \
  -lzstd \
  -pie \

STATIC_LIBS = \
  out/libadb.a \
  out/libcrypto_utils.a \

out/$(NAME): $(OBJECTS_CC) $(OBJECTS_CPP) $(STATIC_LIBS)
	$(CXX) -o $@ $^ $(LDFLAGS)

$(OBJECTS_CPP): %.o: %.cpp
	$(CXX) -c -o $@ $< $(CXXFLAGS) $(CPPFLAGS)

$(OBJECTS_CC): %.o: %.cc
	$(CXX) -c -o $@ $< $(CXXFLAGS) $(CPPFLAGS)

# mDNS is not built (client/transport_mdns.cpp needs openscreen or the Rust
# libadbmdns), so stub out what the rest of adb calls.
out/dummy.cpp:
	rm -f $@
	echo '#include "adb_mdns.h"' >> $@
	echo '#include "transport.h"' >> $@
	echo '#include "client/transport_mdns.h"' >> $@
	echo 'void init_mdns_transport_discovery() {}' >> $@
	echo 'std::string mdns_check() { return std::string(); }' >> $@
	echo 'std::string mdns_list_discovered_services() { return std::string(); }' >> $@
	echo 'std::optional<ServiceInfo> mdns_get_connect_service_info(const std::string&) { return std::nullopt; }' >> $@
	echo 'std::optional<ServiceInfo> mdns_get_pairing_service_info(const std::string&) { return std::nullopt; }' >> $@
	echo 'bool adb_secure_connect_by_service_name(const std::string&) { return false; }' >> $@
