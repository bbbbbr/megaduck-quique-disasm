


# Keyboard/Character/Font classification
- KBD_CODE_* : Keyboard scan codes received over the serial port in Byte 3 of the serial port keyboard reply packet, as well as modifier flags from Byte 2. Upper/Lower case/etc are represented through Shift and Caps Lock flags.

- SYS_CHAR_* : Scan codes are translated into these Quique internal character codes (through lookup tables and additional translation code). Supports Upper and Lower case as distinct values.

- FONT_* : Character indexes in the system ROM font that is loaded in BG Tile pattern VRAM.