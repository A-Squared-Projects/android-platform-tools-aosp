# SPDX-License-Identifier: MIT (see build/COPYING)
NAME = img2simg

SOURCES = img2simg.cpp

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
