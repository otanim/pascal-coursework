#!/bin/bash
# Build bin/COURSE.EXE from src/_main with Turbo Pascal 5.5, running DOSBox without a window.
# COURSE.PAS is kept as UTF-8; the compiler gets a copy in the AK Yerevan DOS encoding (tools/akconv.py).
#   DOSBOX  path to the DOSBox Staging binary (default: ~/.local/opt/dosbox-staging-v0.83.0/dosbox)
#   TP55    folder holding TPC.EXE, TURBO.TPL, GRAPH.TPU, BINOBJ.EXE and EGAVGA.BGI (default: ~/.local/opt/tp55)
set -euo pipefail

repo=$(cd "$(dirname "$0")" && pwd)
dosbox=${DOSBOX:-$HOME/.local/opt/dosbox-staging-v0.83.0/dosbox}
tp=${TP55:-$HOME/.local/opt/tp55}
out=$(mktemp -d)
trap 'rm -rf "$out"' EXIT

python3 "$repo/tools/akconv.py" encode "$repo/src/_main/COURSE.PAS" "$out/COURSE.PAS"
cp "$repo/src/_main/GRMOUSE.PAS" "$repo/src/_main/ARMFONT.INC" "$out/"

SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy nice -n 19 "$dosbox" \
  --noprimaryconf --nolocalconf --set nosound=true --set startup_verbosity=quiet \
  -c "mount t $tp" -c "mount o $out" -c "o:" \
  -c "t:\\binobj t:\\egavga.bgi egavga.obj EgaVgaDriverProc > binobj.log" \
  -c "t:\\tpc /b /ut:\\ course.pas > build.log" \
  -c "if errorlevel 1 echo failed > o:\\failed" \
  --exit >/dev/null 2>&1

tr -d '\r' < "$out/BUILD.LOG"
# DOS creates the redirect target even when the IF is false, so only a non-empty FAILED counts
if [ -s "$out/FAILED" ] || [ ! -e "$out/COURSE.EXE" ]; then
  echo "build failed" >&2
  exit 1
fi
cp "$out/COURSE.EXE" "$repo/bin/COURSE.EXE"
echo "built bin/COURSE.EXE ($(stat -c %s "$repo/bin/COURSE.EXE") bytes)"
