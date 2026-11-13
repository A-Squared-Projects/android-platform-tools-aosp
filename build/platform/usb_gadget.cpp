// SPDX-License-Identifier: MIT
// Copyright (C) 2026 Alex Kiernan <alex.kiernan@gmail.com>
/*
 * Binding adbd's USB gadget to the UDC, as Android's init does.
 *
 * adbd sets sys.usb.ffs.ready=1 each time it has opened ep0 and written its
 * descriptors: at startup, and again whenever it reopens functionfs after a
 * cable pull or a host going away (closing ep0 unbinds the gadget). On
 * Android, init.usb.configfs.rc answers by writing the UDC name to the
 * gadget's UDC attribute. Here the property store does that when the
 * property is set, before adbd starts waiting for FUNCTIONFS_BIND.
 *
 *  - ADBD_USB_GADGET is the configfs gadget directory, e.g.
 *    /sys/kernel/config/usb_gadget/adb. Empty (the default) leaves binding to
 *    whatever set the gadget up.
 *  - ADBD_USB_UDC names the controller; empty means the only one in
 *    /sys/class/udc.
 *
 * adbd binds after dropping privileges, so whoever creates the gadget must
 * make its UDC attribute writable by ADBD_USER (configfs allows chown).
 */

#include <dirent.h>

#include <memory>
#include <string>

#include <android-base/file.h>
#include <android-base/logging.h>
#include <android-base/strings.h>

#ifndef ADBD_USB_GADGET
#define ADBD_USB_GADGET ""
#endif
#ifndef ADBD_USB_UDC
#define ADBD_USB_UDC ""
#endif

namespace {

struct DirCloser {
    void operator()(DIR* d) const { closedir(d); }
};

std::string FindUdc() {
    if (*ADBD_USB_UDC) return ADBD_USB_UDC;

    std::string found;
    std::unique_ptr<DIR, DirCloser> dir(opendir("/sys/class/udc"));
    if (!dir) {
        PLOG(ERROR) << "/sys/class/udc";
        return {};
    }
    while (dirent* e = readdir(dir.get())) {
        if (e->d_name[0] == '.') continue;
        if (!found.empty()) {
            LOG(ERROR) << "several UDCs in /sys/class/udc; set ADBD_USB_UDC";
            return {};
        }
        found = e->d_name;
    }
    if (found.empty()) LOG(ERROR) << "no UDC in /sys/class/udc";
    return found;
}

void BindUdc() {
    const std::string attr = std::string(ADBD_USB_GADGET) + "/UDC";
    std::string udc = FindUdc();
    if (udc.empty()) return;

    std::string current;
    if (android::base::ReadFileToString(attr, &current) &&
        android::base::Trim(current) == udc) {
        return;
    }
    // A failed bind is retried: adbd reopens ep0 and sets the property again
    // when FUNCTIONFS_BIND doesn't arrive.
    if (!android::base::WriteStringToFile(udc, attr)) {
        PLOG(ERROR) << "binding " << udc << " to " << attr;
    }
}

}  // namespace

void adbd_platform_property_set(const std::string& name, const std::string& value) {
    if (*ADBD_USB_GADGET && name == "sys.usb.ffs.ready" && value == "1") BindUdc();
}
