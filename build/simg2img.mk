# SPDX-License-Identifier: MIT (see build/COPYING)
NAME = simg2img

SOURCES = \
  simg2img.cpp \
  sparse_crc32.cpp \

SOURCES := $(foreach source, $(SOURCES), system/core/libsparse/$(source))
OBJECTS = $(SOURCES:.cpp=.o)

CPPFLAGS += \
  -Isystem/core/libsparse/include \

LDFLAGS += \
  -Lout \
  -Wl,-rpath='$$ORIGIN/../lib/android' \
  -lbase \
  -llog \
  -lpthread \
  -lsparse \
  -pie \

out/$(NAME): $(OBJECTS)
	$(CXX) -o $@ $^ $(LDFLAGS)

$(OBJECTS): %.o: %.cpp
	$(CXX) -c -o $@ $< $(CXXFLAGS) $(CPPFLAGS)
