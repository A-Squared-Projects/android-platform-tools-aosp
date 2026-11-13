/*
 * minijail, as far as adbd's drop_privileges() needs it, for Linux systems.
 *
 * adbd asks to become AID_SHELL with Android's supplementary groups. Android
 * ids mean nothing here, so AID_SHELL is the Linux user ADBD_USER (default
 * "adb"), with that user's primary group and its groups from /etc/group in
 * place of Android's list. minijail_use_caps() limits the capability bounding
 * set; the uid change itself clears the other capability sets, which adbd
 * then clears again explicitly.
 */

#include <libminijail.h>

#include <errno.h>
#include <grp.h>
#include <pwd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/prctl.h>
#include <unistd.h>

#include <linux/capability.h>

#include <string>

#include <private/android_filesystem_config.h>

#ifndef ADBD_USER
#define ADBD_USER "adb"
#endif

// From system_properties.cpp: make the property store writable by the user
// adbd is about to become.
void adbd_platform_prepare_user(uid_t uid, gid_t gid);

struct minijail {
    bool change_uid = false;
    uid_t uid = 0;
    bool change_gid = false;
    gid_t gid = 0;
    bool use_caps = false;
    uint64_t caps = 0;
};

[[noreturn]] static void die(const char* what) {
    fprintf(stderr, "adbd: minijail: %s: %s\n", what, strerror(errno));
    abort();
}

struct User {
    std::string name;
    uid_t uid;
    gid_t gid;
};

static User LookupAdbdUser() {
    errno = 0;
    passwd* pw = getpwnam(ADBD_USER);
    if (pw == nullptr) {
        if (errno == 0) errno = ENOENT;
        die("getpwnam(" ADBD_USER ")");
    }
    return {pw->pw_name, pw->pw_uid, pw->pw_gid};
}

extern "C" {

struct minijail* minijail_new(void) {
    return new minijail;
}

void minijail_destroy(struct minijail* j) {
    delete j;
}

int minijail_change_uid(struct minijail* j, uid_t uid) {
    j->change_uid = true;
    j->uid = uid;
    return 0;
}

int minijail_change_gid(struct minijail* j, gid_t gid) {
    j->change_gid = true;
    j->gid = gid;
    return 0;
}

int minijail_set_supplementary_gids(struct minijail*, size_t, const gid_t*) {
    // Android's AID groups; the adbd user's own groups are used instead.
    return 0;
}

void minijail_use_caps(struct minijail* j, uint64_t capmask) {
    j->use_caps = true;
    j->caps = capmask;
}

void minijail_enter(const struct minijail* j) {
    if (j->use_caps) {
        for (int cap = 0; cap <= CAP_LAST_CAP; ++cap) {
            if ((j->caps & (uint64_t{1} << cap)) == 0 && prctl(PR_CAPBSET_DROP, cap, 0, 0, 0) != 0 &&
                errno != EINVAL) {
                die("PR_CAPBSET_DROP");
            }
        }
    }

    if (!j->change_uid && !j->change_gid) {
        return;
    }

    User user = LookupAdbdUser();
    uid_t uid = !j->change_uid ? getuid() : j->uid == AID_SHELL ? user.uid : j->uid;
    gid_t gid = !j->change_gid ? getgid() : j->gid == AID_SHELL ? user.gid : j->gid;

    adbd_platform_prepare_user(uid, gid);

    if (uid == user.uid ? initgroups(user.name.c_str(), gid) != 0 : setgroups(0, nullptr) != 0) {
        die("setting supplementary groups");
    }
    if (setgid(gid) != 0) {
        die("setgid");
    }
    if (setuid(uid) != 0) {
        die("setuid");
    }
}

}  // extern "C"
