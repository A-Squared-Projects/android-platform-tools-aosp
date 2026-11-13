# SPDX-License-Identifier: MIT (see build/COPYING)
NAME:= libcrypto_utils

SOURCES = system/core/libcrypto_utils/android_pubkey.cpp
OBJECTS = $(SOURCES:.cpp=.o)

CPPFLAGS += \
  -Isystem/core/include \
  -Isystem/core/libcrypto_utils/include \
  \
  -I$(SYSROOT)/usr/include/android \

out/$(NAME).a: $(OBJECTS)
	ar -rcs $@ $^

$(OBJECTS): %.o: %.cpp
	$(CXX) -c -o $@ $< $(CXXFLAGS) $(CPPFLAGS)
