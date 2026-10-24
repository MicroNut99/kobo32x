# ROM Loader for the Mega 32X RAM Cart

This project shows an example of how to load files onto the 4MiB RAM cart. 

## Description

Make sure the lower switch on the cart is set to "boot off the CD" position. Write the ISO file of this project to a CD-R and boot using the SegaCD addon.

After initial loading, the program will list files it was able to find on the CD. Select a ROM file from the CD and press A to write it onto the RAM cart. Pressing B will verify ROM/RAM contents with the selected file.

To boot off the previously written ROM, you need to toggle the lower switch to the off position and power cycle the console. Pressing the RESET button on the console will not work!

## Building (in this repository)
This folder is Kobo's Sega CD side. It is the Sub-CPU / 68000 program, built on the ROM loader above, and it
carries the SH2 program. Build the whole disc from the top folder with **`bash build.sh`** (see `../README.md`).
To build this part on its own, build the SH2 program in `../sh2` first:
```bash
cd ../sh2 && make clean && make     # -> ../sh2/D32XR.32x
cd ../subcpu
make clean && make cd               # -> CDROMPlayer.bin, cd/ (the disc files), CDROMPlayer.iso
python3 make_mixed_cd2.py CDROMPlayer.iso Track02.wav Track03.wav Track04.wav   # -> CDROMPlayer_mixed.bin / .cue
```
Make options: `GENDEV=/path/to/sega` (toolchain, default `/opt/toolchains/sega`) and
`BOOTBLOCK=/opt/toolchains/sega/bootblocks/EU_BOOT.BIN` (region: `US_BOOT.BIN` default, `EU_BOOT.BIN`,
`JP_BOOT.BIN`).

Needs **genisoimage**. The game files live in `ROMs/`. The WAVs are 48 kHz: `make_mixed_cd2.py`
converts them with `audioop` (Python 3.12 and older) or numpy (3.13+). Its options are `--out NAME`,
`--mode2` and `--pregap N` (see `../README.md`).

## "ROM Loader for the Mega 32X RAM Cart" Credits
* Programming : Chilly Willy and Victor Luchits
* Base Docker Code : Victor Luchits
## 

## License
All original code is available under the MIT license.
