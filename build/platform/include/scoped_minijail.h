// SPDX-License-Identifier: MIT
// Copyright (C) 2026 Alex Kiernan <alex.kiernan@gmail.com>
#pragma once

#include <memory>

#include <libminijail.h>

struct ScopedMinijailDeleter {
    void operator()(struct minijail* j) const {
        if (j) minijail_destroy(j);
    }
};

using ScopedMinijail = std::unique_ptr<struct minijail, ScopedMinijailDeleter>;
