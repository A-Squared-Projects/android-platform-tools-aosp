NAME = fastboot

include build/version.mk

# system/core/fastboot/Android.bp
fastboot_SOURCES = \
  bootimg_utils.cpp \
  fastboot_driver.cpp \
  fastboot.cpp \
  filesystem.cpp \
  fs.cpp \
  main.cpp \
  h2h_workaround.cpp \
  socket.cpp \
  storage.cpp \
  super_flash_helper.cpp \
  tcp.cpp \
  udp.cpp \
  util.cpp \
  vendor_boot_img_utils.cpp \
  task.cpp \
  \
  usb_linux.cpp \

# system/fs/fs_mgr/liblp/Android.bp
fs_mgr_liblp_SOURCES := \
  builder.cpp \
  super_layout_builder.cpp \
  images.cpp \
  partition_opener.cpp \
  property_fetcher.cpp \
  reader.cpp \
  utility.cpp \
  writer.cpp \

SOURCES := \
  $(foreach source, $(fastboot_SOURCES), system/core/fastboot/$(source)) \
  $(foreach source, $(fs_mgr_liblp_SOURCES), system/fs/fs_mgr/liblp/$(source))
OBJECTS = $(SOURCES:.cpp=.o)

CXXFLAGS += -fpermissive
CPPFLAGS += \
  -D_FILE_OFFSET_BITS=64 \
  -DADB_BUILD_ID='"$(ADB_BUILD_ID)"' \
  -DPLATFORM_TOOLS_VERSION='"$(PLATFORM_TOOLS_VERSION)"' \
  -Ibuild/platform/include \
  -Iexternal/avb \
  -Iexternal/fmtlib/include \
  -Ipackages/modules/adb \
  -Isystem/core/demangle/include \
  -Isystem/core/diagnose_usb/include \
  -Isystem/fs/fs_mgr/include \
  -Isystem/fs/fs_mgr/include_fstab \
  -Isystem/fs/fs_mgr/liblp/include \
  -Isystem/fs/fs_mgr/libstorage_literals \
  -Isystem/core/include \
  -Isystem/core/libcutils/include \
  -Isystem/core/libsparse/include \
  -Isystem/extras/ext4_utils/include \
  -Isystem/libbase/include \
  -Isystem/libziparchive/include \
  -Isystem/tools/mkbootimg/include/bootimg \
  \
  -I$(SYSROOT)/usr/include/android \

LDFLAGS += \
  -Lout \
  -Wl,-rpath='$$ORIGIN/../lib/android' \
  out/libbase.so.0 \
  -l:libcrypto.so.0 \
  out/libcutils.so.0 \
  out/liblog.so.0 \
  -lpthread \
  -lprotobuf \
  -lsparse \
  -lusb-1.0 \
  -lziparchive \
  -pie \

STATIC_LIBS = \
  out/libadb.a \
  out/extras/libext4_utils.a \

out/$(NAME): $(OBJECTS) $(STATIC_LIBS)
	$(CXX) -o $@ $^ $(LDFLAGS)

$(OBJECTS): %.o: %.cpp
	$(CXX) -c -o $@ $< $(CXXFLAGS) $(CPPFLAGS)
