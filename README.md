# pascal Course Work

This is my course work that I wrote in Pascal and Assembler, I did it in the second year of studying at SEUA.
Then I still was a novice in programming, so do not judge strictly :smile:

**Play it in the browser: https://coursework.otanim.com**

## How to run
The game is a DOS program, so it runs in [DOSBox Staging](https://www.dosbox-staging.org/). From the repository folder:

    dosbox bin/COURSE.EXE

`COURSE.EXE` carries its own graphics driver and Armenian font, so it needs no other files and works with any DOSBox keyboard layout. Problem 547 saves the matrix as `547.TXT` next to `COURSE.EXE`.

## How to build
`./build.sh` compiles `src/_main/COURSE.PAS` into `bin/COURSE.EXE` with [Turbo Pascal 5.5](https://altd.embarcadero.com/download/museum/tp55.zip), which Embarcadero offers as a free download. It runs DOSBox Staging without a window, and links in `EGAVGA.BGI` from Turbo Pascal with `BINOBJ`. The source is kept as UTF-8, so the script first uses `python3 tools/akconv.py` to give the compiler a copy in the DOS encoding.

The script expects Turbo Pascal in `~/.local/opt/tp55`, with `BGI.ARC` and `UTILS.ARC` unpacked there (for `GRAPH.TPU`, `EGAVGA.BGI` and `BINOBJ.EXE`), and DOSBox Staging in `~/.local/opt/dosbox-staging-v0.83.0`. Set `TP55` or `DOSBOX` to use other locations.

## Files
- `src/_main/COURSE.PAS`: the main program (desktop, Tron, Problem 547), stored as UTF-8. Its Armenian texts must stay within the letters and marks the DOS font has: write `եւ`, not `և`, and Armenian punctuation, `՛` or `՞` after the stressed vowel, never `!` or `?`.
- `src/_main/GRMOUSE.PAS`: the graphical mouse unit. It talks to the DOS mouse driver; the Turbo Pascal 7 original did this in inline assembler.
- `src/_main/ARMFONT.INC`: the Armenian 8x8 font the program draws its texts with.
- `src/_main/FONT16.INC`: the 8x16 characters the rules of Tron are written in, taller than the 8x8 ones: the VGA's own, and FONT.COM's Armenian ones. `tools/font16.sh` makes it again, running `FONT /A` and `tools/FONTDUMP.PAS` in DOSBox without a window.
- `bin/COURSE.EXE`: the ready-to-run program.
- `package.json`: lets other projects, like the coursework.otanim.com website, install `COURSE.EXE` from a release tag (`github:otanim/pascal-coursework#v2.1.3`).
- `tools/akconv.py`: converts between UTF-8 and the AK Yerevan DOS encoding the font uses.
- `tools/FONT.COM`: the Armenian font driver from 1990 that `ARMFONT.INC` comes from. To edit in the Turbo Pascal editor, make a DOS copy with `tools/akconv.py encode` and run `FONT /A` first.

## Demonstration
[**YouTube**](http://www.youtube.com/watch?v=uPadzHyEbVo)

## Screenshots
### Desktop
![alt text](screenshots/desktop.gif "Desktop")
### Tron: logo
![alt text](screenshots/tron_logo.gif "Tron - logo")
### Tron: game
![alt text](screenshots/tron.gif "Tron")

