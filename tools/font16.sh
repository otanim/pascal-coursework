#!/bin/bash
# Make src/_main/FONT16.INC: the 8x16 characters of 640x480 graphics once FONT.COM has installed its Armenian ones
# (FONT /A), saved by tools/FONTDUMP.PAS in DOSBox without a window. DOSBOX and TP55 as in build.sh.
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
dosbox=${DOSBOX:-$HOME/.local/opt/dosbox-staging-v0.83.0/dosbox}
tp=${TP55:-$HOME/.local/opt/tp55}
out=$(mktemp -d)
trap 'rm -rf "$out"' EXIT

cp "$repo/tools/FONTDUMP.PAS" "$repo/tools/FONT.COM" "$out/"
SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy nice -n 19 "$dosbox" \
  --noprimaryconf --nolocalconf --set nosound=true --set startup_verbosity=quiet --set keyboard_layout=us \
  -c "mount t $tp" -c "mount o $out" -c "o:" \
  -c "t:\\tpc fontdump.pas > build.log" \
  -c "font /a > font.log" \
  -c "fontdump" \
  --exit >/dev/null 2>&1

if [ ! -s "$out/INT43.BIN" ]; then
  tr -d '\r' < "$out/BUILD.LOG" >&2 || true
  echo "no INT43.BIN" >&2
  exit 1
fi
cp "$out/INT43.BIN" "$out/ROM16.BIN" "${KEEP:-$out}/" 2>/dev/null || true
python3 - "$out/INT43.BIN" "$repo/src/_main/FONT16.INC" <<'PY'
import sys
data = open(sys.argv[1], 'rb').read()
assert len(data) == 4096
lines = ['{ The 8x16 characters of 640x480 graphics, 16 bytes each, top row first: $00..$7F the VGA\'s own, $80..$FF',
         '  the Armenian ones of FONT.COM. Made by tools/font16.sh from the table FONT /A gives that mode. }',
         'const',
         '  Font16: array[0..4095] of Byte = (']
for c in range(256):
    row = ','.join(f'${b:02X}' for b in data[c * 16:(c + 1) * 16])
    lines.append(f'    {row}{"," if c < 255 else ""}  {{ ${c:02X} }}')
lines.append('  );')
open(sys.argv[2], 'w').write('\n'.join(lines) + '\n')
PY
echo "wrote src/_main/FONT16.INC"
