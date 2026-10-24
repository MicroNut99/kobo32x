# Kobo 32X (Emulator Fusion Edition)

## This is a specialized build of the Kobo Deluxe port for the Sega 32X. 
Unlike standard Sega CD / 32XCD releases, 
this version is engineered specifically to execute entirely from the Kega Fusion Emulator.

## Building

### What you need
- **Chilly Willy's Sega MD/CD/32X devkit** (sh-elf + m68k-elf GCC 12.1), from the 32XDK releases page:
  https://github.com/viciious/32XDK/releases. The Makefiles expect it at `/opt/toolchains/sega` (folders `sh-elf/`,
  `m68k-elf/`, `ldscripts/`, `bootblocks/`, `bin/`). The original setup keeps this project inside the toolchain
  folder, as `sega-toolchain-12.1/sega/kobo32x`.
  - Toolchain somewhere else: `sh2/Makefile` takes `GENDEV=/path/to/sega`. `subcpu/Makefile` ignores `GENDEV`:
    give it `ROOTDIR=/path/to/sega` (`make cd ROOTDIR=...`), or link `/opt/toolchains/sega` to your toolchain.
    (`build.sh` passes neither, so with `build.sh` the link is the simple way.)
- **genisoimage** (makes the ISO) and **python3**.
- **The disc image step:** `Track02-04.wav` are 48 kHz and the disc needs 44.1 kHz. `make_mixed_cd2.py`
  converts them with Python's `audioop`, which **Python 3.13 removed**. Use Python 3.12 or older, or
  `pip install audioop-lts` on 3.13+. Or convert the WAVs first:
  `ffmpeg -i Track02.wav -ar 44100 -ac 2 -sample_fmt s16 Track02_44k.wav` (and name those on the command line).
- **Linux / macOS (case-sensitive file systems):** the game files are in `subcpu/ROMs/`, but the Makefile
  reads `subcpu/ROMS/`. Rename the folder once: `mv subcpu/ROMs subcpu/ROMS`. Without it the sound pack
  (`KOBOSFX.BIN`) is left off the disc. On a Windows drive (WSL `/mnt/...`) they are the same folder.

### One command
```bash
cd kobo32x
bash build.sh
```
The compiler prints some warnings (unused functions, `pri_start`); they are expected.
`build.sh` takes **no arguments or switches**. It runs these steps in order:
1. Writes `sh2/track_len.h` from the length of `subcpu/Track02.wav`. `sh2_main.c` currently overrides
   this with `TRACK02_SECONDS 60`: the demo starts after 60 s on an idle menu.
2. Builds the SH2 program (`sh2/D32XR.32x`).
3. Builds the Sub-CPU / 68000 program and the ISO (`subcpu/CDROMPlayer.iso`).
4. Builds the mixed-mode disc: **`subcpu/CDROMPlayer_mixed.bin` + `.cue`**. Load the `.cue` in Fusion,
   or burn it.

### Step by step (what `build.sh` runs)
```bash
cd sh2    && make clean && make        # -> sh2/D32XR.32x            (make GENDEV=/path/to/sega ...)
cd ../subcpu && make clean && make cd  # -> CDROMPlayer.bin, cd/, CDROMPlayer.iso  (make cd ROOTDIR=/path/to/sega ...)
python3 make_mixed_cd2.py CDROMPlayer.iso Track02.wav Track03.wav Track04.wav
                                       # -> CDROMPlayer_mixed.bin / .cue
```
`make cd` copies `../sh2/D32XR.32x` to `ROMS/KOBO32X.BIN`, builds it into the Sub-CPU program, and puts
`APP.BIN`, `KOBOGFX.BIN`, `KOBOSFX.BIN`, `IMAGE.RAW` and `KOBO32X.BIN` on the disc.

**Make options**
| Option | Where | What it does |
|---|---|---|
| `GENDEV=/path/to/sega` | `sh2` | toolchain folder (default `/opt/toolchains/sega`) |
| `ROOTDIR=/path/to/sega` | `subcpu` | toolchain folder (default `/opt/toolchains/sega`) |
| `BOOTBLOCK=/opt/toolchains/sega/bootblocks/EU_BOOT.BIN` | `subcpu` | disc region: `US_BOOT.BIN` (default), `EU_BOOT.BIN`, `JP_BOOT.BIN` |
| `make clean` | both | removes the build outputs (in `subcpu/`: `*.bin`, `*.elf`, `*.iso`, `cd/` - not `ROMS/`) |

**`make_mixed_cd2.py` options**
```
python3 make_mixed_cd2.py [iso] [wav ...] [--out NAME] [--mode2] [--pregap N]
```
| Option | Default | What it does |
|---|---|---|
| `iso` | `CDROMPlayer.iso` | the data track |
| `wav ...` | `Track02.wav` | the audio tracks, in order: track 2, 3, ... |
| `--out NAME` | `<iso name>_mixed` | output name, without extension |
| `--mode2` | off | write the data track as MODE2/2352 (Mode 2 Form 1) instead of MODE1/2352 |
| `--pregap N` | `150` | silent sectors before each audio track (150 = Red Book's 2 s; 0 = like the Doom CD32X cue) |

### Compile-time switches
There are no command-line switches for the game itself. These are `#define`s: edit the value, then rebuild.

`sh2/sh2_main.c`
| Switch | Now | What it does |
|---|---|---|
| `KOBO_NOCART` | 1 | 1 = Fusion: no RAM cart (Fusion cannot emulate the 4 MB cart). 0 = real hardware with the cart (set it in `subcpu/main.c` too) |
| `KOBO_FIXED_STEP` | 0 | 0 = one game step per drawn frame (the Fusion speed). 1 = fixed step of `KOBO_STEP_MS`, the same speed at any frame rate (for real hardware) |
| `KOBO_STEP_MS` | 30 | the fixed step, in ms (30 = Kobo Classic) |
| `KOBO_START_PAUSE` | 0 | pause is MODE (6-button pad); 1 = START pauses too |
| `TRACK02_SECONDS` | 60 | seconds of idle menu before the demo starts |
| `KOBO_SPLASH` | 1 | 1 = `IMAGE.RAW` splash while loading; 0 = no splash (the file isn't read) |
| `KOBO_HW_PCM` | 1 | 1 = sound effects (sound pack loaded into the Sega CD PCM chip); 0 = music only |
| `KOBO_HW_BRAM` | 1 | 1 = high scores / options saved in backup RAM; 0 = this session only |
| `KOBO_HW_DIAG` | 0 | 1 = hardware readout bottom-left (Sub-CPU heartbeat, commands, pad requests, FPS) |
| `KOBO_HW_QUIET` | 0 | test: 1 = the SH2 stops all requests once the game runs (no controller). Must match `subcpu/main.c` |
| `KOBO_DIAG_STRIP` | 0 | 0 = Kobo's right-hand panel; 1 = the diagnostic strip instead |
| `KOBO_DIAG_GRID` | 0 | 1 = palette grid in place of the radar |
| `KOBO_DEBUG_KEYS` | 0 | 1 = X (6-button pad) skips to the next level. 0 for a release |
| `KOBO_VERSION` | 37 | the version shown on screen |

`subcpu/main.c`
| Switch | Now | What it does |
|---|---|---|
| `KOBO_NOCART` | 1 | must match `sh2/sh2_main.c` (1 = Fusion, 0 = real hardware with the 4 MB cart) |
| `KOBO_PACK_SLOT` | 16 | cart mode: where the graphics pack goes in the cart (16 x 128 KB = 2 MB) |
| `KOBO_BOOT_TEXT` | 1 | 1 = Chilly's white 32X start-up messages show |
| `KOBO_DIAG_TEXT` | 0 | 1 = the green diagnostic text at start-up |
| `KOBO_HW_QUIET` | 0 | must match `sh2/sh2_main.c` |

### Asset tools (not part of `build.sh`; their outputs are already in `subcpu/ROMs/`)
```bash
python3 tools/kobo_gfx.py --gfx <Kobo data/gfx folder> --out <folder> [--only B_TILES1,B_OLDSTARS] [--name KOBOGFX.BIN]
python3 tools/kobo_sfx.py [wav folder (default wav)] [output (default KOBOSFX.BIN)]
python3 tools/convert_32x_image.py picture.png [IMAGE.RAW] [--height 200] [--mode stretch|fit|fill] [--dither none|fs|bayer]
python3 tools/convert_32x_image.py --decode IMAGE.RAW check.png       # preview a .raw
```
- `kobo_gfx.py` makes the graphics pack, plus previews. `--only` writes just those banks.
- `kobo_sfx.py` makes the PCM sound pack from Kobo's rendered effects.
- `convert_32x_image.py` makes the 320x200 splash. `convert_32x_image.ps1` is the PowerShell version.

These need `numpy` and `pillow` (`pip install numpy pillow`).

## Acknowledgments
Chilly Willy, aka Joeseph Fenton for the advice and support.

At the heart of this project beats this critical code, Thank you!

https://forums.sonicretro.org/threads/sega-cd-mode-1-player.27372/

https://gendev.spritesmind.net/forum/viewtopic.php?t=1018
