#pragma once

#include <memory>

#include <libminijail.h>

struct ScopedMinijailDeleter {
    void operator()(struct minijail* j) const {
        if (j) minijail_destroy(j);
    }
};

using ScopedMinijail = std::unique_ptr<struct minijail, ScopedMinijailDeleter>;
