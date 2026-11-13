// SPDX-License-Identifier: MIT
// Copyright (C) 2026 Alex Kiernan <alex.kiernan@gmail.com>
/*
 * Android system properties for adbd on Linux.
 *
 * libbase's own non-bionic implementation is an in-process map, defined as
 * weak symbols so a program can supply a real one; adbd links this file and
 * exports these symbols so libbase and liblog use them too.
 *
 *  - Every property is first looked up in the writable store, one file per
 *    property under ADBD_PROPERTY_DIR (default /run/adbd/properties, so it
 *    doesn't outlive a reboot), except ro.* properties, which are never
 *    written.
 *  - Otherwise it comes from the build.prop-style files in
 *    ADBD_PROPERTY_FILES (colon-separated, default
 *    /etc/build.prop:/run/build.prop): "key=value" lines, '#' comments. When
 *    several files set a key, the later file wins.
 *
 * Values are read on every lookup, so a file written while adbd runs (a
 * build.prop staged in /run, say) is seen by later lookups. adbd itself
 * decides root and authentication at startup, as on Android.
 */

#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <string_view>

#include <android-base/file.h>
#include <android-base/properties.h>
#include <android-base/strings.h>
#include <log/log_properties.h>

#ifndef ADBD_PROPERTY_FILES
#define ADBD_PROPERTY_FILES "/etc/build.prop:/run/build.prop"
#endif
#ifndef ADBD_PROPERTY_DIR
#define ADBD_PROPERTY_DIR "/run/adbd/properties"
#endif

#define PROP_VALUE_MAX 92

struct prop_info {
    std::string name;
};

namespace {

bool IsReadOnly(std::string_view name) {
    return name.starts_with("ro.");
}

// Property names become file names in the store.
bool IsValidName(std::string_view name) {
    if (name.empty() || name.size() > 255 || name == "." || name == "..") return false;
    for (char c : name) {
        if (!isalnum(static_cast<unsigned char>(c)) && !strchr("._-:@", c)) return false;
    }
    return true;
}

std::string StorePath(std::string_view name) {
    return std::string(ADBD_PROPERTY_DIR "/").append(name);
}

bool ReadFromStore(const std::string& name, std::string* value) {
    if (IsReadOnly(name)) return false;
    if (!android::base::ReadFileToString(StorePath(name), value)) return false;
    if (value->ends_with('\n')) value->pop_back();
    return true;
}

bool ReadFromFiles(const std::string& name, std::string* value) {
    bool found = false;
    for (const auto& path : android::base::Split(ADBD_PROPERTY_FILES, ":")) {
        std::string content;
        if (path.empty() || !android::base::ReadFileToString(path, &content)) continue;
        for (const auto& raw : android::base::Split(content, "\n")) {
            std::string line = android::base::Trim(raw);
            if (line.empty() || line[0] == '#') continue;
            size_t eq = line.find('=');
            if (eq == std::string::npos || android::base::Trim(line.substr(0, eq)) != name) continue;
            *value = android::base::Trim(line.substr(eq + 1));
            found = true;
        }
    }
    return found;
}

bool Lookup(const std::string& name, std::string* value) {
    return ReadFromStore(name, value) || ReadFromFiles(name, value);
}

bool MakeDirs(const std::string& path, mode_t mode) {
    for (size_t i = 1; i <= path.size(); ++i) {
        if (i != path.size() && path[i] != '/') continue;
        std::string dir = path.substr(0, i);
        if (mkdir(dir.c_str(), mode) != 0 && errno != EEXIST) return false;
    }
    return true;
}

}  // namespace

// Called as root by minijail_enter(), before adbd changes uid: the store must
// stay writable, since `adb root` is requested from the unprivileged adbd.
void adbd_platform_prepare_user(uid_t uid, gid_t gid) {
    if (!MakeDirs(ADBD_PROPERTY_DIR, 0755) || chown(ADBD_PROPERTY_DIR, uid, gid) != 0) {
        fprintf(stderr, "adbd: property store %s: %s\n", ADBD_PROPERTY_DIR, strerror(errno));
    }
}

extern "C" int __system_property_get(const char* key, char* value) {
    std::string v;
    if (key == nullptr || !IsValidName(key) || !Lookup(key, &v)) {
        *value = '\0';
        return 0;
    }
    snprintf(value, PROP_VALUE_MAX, "%s", v.c_str());
    return strlen(value);
}

extern "C" const prop_info* __system_property_find(const char* key) {
    static std::mutex lock;
    static auto& infos = *new std::map<std::string, std::unique_ptr<prop_info>, std::less<>>;

    std::string v;
    if (key == nullptr || !IsValidName(key) || !Lookup(key, &v)) return nullptr;

    std::lock_guard guard(lock);
    auto it = infos.find(std::string_view(key));
    if (it == infos.end()) {
        it = infos.emplace(key, std::make_unique<prop_info>(prop_info{key})).first;
    }
    return it->second.get();
}

extern "C" void __system_property_read_callback(const prop_info* pi,
                                                void (*callback)(void*, const char*, const char*,
                                                                 uint32_t),
                                                void* cookie) {
    std::string v;
    Lookup(pi->name, &v);
    callback(cookie, pi->name.c_str(), v.c_str(), 0);
}

extern "C" int __system_property_set(const char* key, const char* value) {
    if (key == nullptr || !IsValidName(key) || IsReadOnly(key)) {
        errno = EPERM;
        return -1;
    }
    if (value == nullptr) value = "";
    if (strlen(value) >= PROP_VALUE_MAX) {
        errno = EINVAL;
        return -1;
    }

    if (!MakeDirs(ADBD_PROPERTY_DIR, 0755)) return -1;
    std::string tmp = StorePath(std::string(".") + key + ".XXXXXX");
    int fd = mkstemp(tmp.data());
    if (fd == -1) return -1;
    bool ok = android::base::WriteStringToFd(value, fd) && fchmod(fd, 0644) == 0;
    close(fd);
    if (!ok || rename(tmp.c_str(), StorePath(key).c_str()) != 0) {
        int saved = errno;
        unlink(tmp.c_str());
        errno = saved;
        return -1;
    }
    return 0;
}

// liblog's non-Android version always says yes; answer from ro.debuggable,
// as Android's does.
extern "C" int __android_log_is_debuggable() {
    char value[PROP_VALUE_MAX];
    return __system_property_get("ro.debuggable", value) > 0 && strcmp(value, "1") == 0;
}
