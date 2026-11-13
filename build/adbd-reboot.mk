# SPDX-License-Identifier: MIT (see build/COPYING)
NAME = adbd-reboot

out/$(NAME): build/platform/adbd-reboot.c
	$(CC) -o $@ $< $(CFLAGS) $(CPPFLAGS) $(LDFLAGS)
