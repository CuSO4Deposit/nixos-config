#!/usr/bin/env python3
# Hunk 0 only: fix the DBus SelectSources/Start race in
# libscreen_share_module.so (the native XDG-portal screencast path).
# Required for wlr/Hyprland-style backends that block inside SelectSources.
#
# Offsets verified against the nixpkgs build of wemeet 3.26.10.401
# (autoPatchelfHook does not touch .text).
import mmap
import os
import sys

HUNK0 = {
    0x43d2fa: ("00", "5d"),
    0x43d331: ("88f7", "60fb"),
    0x43d336: ("83c718488b8588f7ffff48", "89fe4883c618e910000000"),
    0x43d357: ("0000", "e208"),
    0x43dc38: ("e8c305d9", "e9ecf6ff"),
}

rel = "bin/modules/screen_share/libscreen_share_module.so"


def main():
    root = sys.argv[1].rstrip("/")
    path = f"{root}/{rel}"
    ok = True
    with open(path, "r+b") as fh:
        mm = mmap.mmap(fh.fileno(), 0)
        for off, (o, n) in sorted(HUNK0.items()):
            ob, nb = bytes.fromhex(o), bytes.fromhex(n)
            actual = mm[off:off + len(ob)]
            if actual != ob:
                print(f"[MISMATCH] 0x{off:08x}: want {ob.hex()} got {actual.hex()}")
                ok = False
                break
            mm[off:off + len(nb)] = nb
            print(f"[PATCH]    0x{off:08x}: {ob.hex()} => {nb.hex()}")
        mm.flush()
        mm.close()
    print("OK" if ok else "FAILED")
    sys.exit(0 if ok else 1)


main()
