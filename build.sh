#!/bin/bash
# Kobo Deluxe CD32X - full build: SH2 program -> Sub-CPU/68K program -> mixed-mode disc image.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
# K37d: the demo starts after one play of Track02 on an idle menu - its length goes to the SH2.
# The WAV is read directly (RIFF chunks: length = data bytes / bytes per second) so any PCM
# WAV works, including the "extensible" kind some editors write.
python3 - "$HERE/subcpu/Track02.wav" "$HERE/sh2/track_len.h" <<'PY'
import sys, struct
path, out = sys.argv[1], sys.argv[2]
d = open(path, "rb").read()
if d[:4] != b"RIFF" or d[8:12] != b"WAVE":
    sys.exit("*** %s is not a WAV file" % path)
pos, byterate, datalen = 12, 0, 0
while pos + 8 <= len(d):
    cid, n = d[pos:pos + 4], struct.unpack("<I", d[pos + 4:pos + 8])[0]
    if cid == b"fmt ": byterate = struct.unpack("<I", d[pos + 16:pos + 20])[0]
    if cid == b"data": datalen = min(n, len(d) - pos - 8)
    pos += 8 + n + (n & 1)
if not byterate or not datalen:
    sys.exit("*** could not read the length of %s" % path)
secs = (datalen + byterate - 1) // byterate
open(out, "w").write("#define TRACK02_SECONDS %d   /* written by build.sh from Track02.wav */\n" % secs)
print("==> Track02.wav: %d s  (the demo starts after %d s on an idle menu)" % (secs, secs))
PY
echo "==> SH2";         cd "$HERE/sh2"    && make clean && make
echo "==> Sub-CPU";     cd "$HERE/subcpu" && make clean && make cd
echo "==> disc image";  python3 make_mixed_cd2.py CDROMPlayer.iso Track02.wav Track03.wav Track04.wav
echo "==> done: disc image is in $HERE/subcpu/"
ls -1 "$HERE/subcpu" | grep -i "mixed" || true
