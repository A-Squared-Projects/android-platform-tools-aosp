// SPDX-License-Identifier: MIT
// Copyright (C) 2026 Alex Kiernan <alex.kiernan@gmail.com>
/*
 * The part of minijail's API that adbd's drop_privileges() uses, for Linux
 * systems without minijail. See build/platform/minijail.cpp.
 */
#pragma once

#include <stddef.h>
#include <stdint.h>
#include <sys/types.h>

#ifdef __cplusplus
extern "C" {
#endif

struct minijail;

struct minijail* minijail_new(void);
void minijail_destroy(struct minijail* j);

int minijail_change_uid(struct minijail* j, uid_t uid);
int minijail_change_gid(struct minijail* j, gid_t gid);
int minijail_set_supplementary_gids(struct minijail* j, size_t size, const gid_t* list);
void minijail_use_caps(struct minijail* j, uint64_t capmask);

/* Applies the jail to the calling process; aborts on any failure. */
void minijail_enter(const struct minijail* j);

#ifdef __cplusplus
}
#endif
