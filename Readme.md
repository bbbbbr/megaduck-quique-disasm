
## Mega Duck Laptop System ROM Disassembly
A partial disassembly of the System ROM for the Mega Duck Super-Quique / Super-Junior Computer. Code which interfaces with the serial peripherals (keyboard, RTC, launch slot cartridge, etc) has been prioritized in order to document and interact with it.

## Why the Mega Duck Laptop?
It's similar to the GameBoy Workboy add-on except it actually shipped, and it may be the strangest of the Game Boy clones. It has the same Game Boy compatible CPU (sm83) with slightly altered registers as the Megaduck Handheld, along with several unique integrated features:
- Built-in (not very good) applications
- A "Mouse" (D-Pad and button controls)
- Keyboard with Piano keys
- RTC
- Printer support
- Memory cart slot
- ROM cart slot for running programs like a normal Mega Duck
- A slightly larger screen (3")

### Notes and Docs
See [docs](/docs) for additional work in progress info.


### Status
A fair amount of core functionality in Bank 0 has been labeled and commented. Less work has been done on code for the built-in applications aside from where they interact with system hardware.

### Build toolchain
- RGBDS 6.0
- Note: The System ROM uses 32K banks, which RGBDS does not support (only banking with the upper 16K). Currently only the first 32K bank is disassembled. If further banks are disassembled then changes to the build process or tools may be required to properly assemble and link the final binary.

### Building:
The default Make target will assemble both a Mega Duck ROM and a Game Boy ROM.
- The Mega Duck version should have a resulting checksum (MD5: `8ad5b9e8322e9a81977455a2bf303c20`) which matches the reference ROM.
- The Game Boy version has had it's graphics and sound register values and addresses translated from thier altered Mega Duck equivalents (at least for disassembled code).
- To allow the System ROM to partially run in an Game Boy emulator without getting stuck in peripheral hardware init uncomment this line `; def GB_DEBUG = 1` (since currently there are not emulators which support the Laptop peripheral controller)


### Misc & Thanks
- Thanks to those who dumped the System ROM
- Eucal.BB for cart slot boot initial VRAM pictures
- [Emulicious](https://emulicious.net/) for disassembler, debugger and testing
- [ImHex](https://github.com/WerWolv/ImHex) for rummaging through the binary
