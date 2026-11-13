# SPDX-License-Identifier: MIT (see build/COPYING)
NAME = libext4_utils

# system/extras/ext4_utils/Android.bp
ext4_utils_SOURCES = \
  ext4_utils.cpp \
  wipe.cpp \
  ext4_sb.cpp \

ext4_utils_SOURCES := $(foreach source, $(ext4_utils_SOURCES), system/extras/ext4_utils/$(source))

SOURCES = $(ext4_utils_SOURCES)

SOURCES_C = $(filter %.c,$(SOURCES))
OBJECTS_C = $(SOURCES_C:.c=.o)
SOURCES_CXX = $(filter %.cpp,$(SOURCES))
OBJECTS_CXX = $(SOURCES_CXX:.cpp=.o)

CPPFLAGS += \
  -D_GNU_SOURCE \
  -D_LARGEFILE64_SOURCE \
  -DFEC_NO_KLOG \
  -I$(SYSROOT)/usr/include/android \
  -Isystem/core/libcutils/include \
  -Isystem/core/libsparse/include \
  -Isystem/extras/ext4_utils/include \
  -Isystem/extras/libfec/include \
  -Isystem/libbase/include \

out/extras/libext4_utils.a: $(OBJECTS_C) $(OBJECTS_CXX)
	ar -rcs $@ $^

$(OBJECTS_C): %.o: %.c
	$(CC) -c -o $@ $< $(CFLAGS) $(CPPFLAGS)

$(OBJECTS_CXX): %.o: %.cpp
	$(CXX) -c -o $@ $< $(CPPFLAGS) $(CXXFLAGS)
