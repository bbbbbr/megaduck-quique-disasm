


# Keyboard/Character/Font classification
- KBD_CODE_* : Keyboard scan codes received over the serial port in Byte 3 of the serial port keyboard reply packet, as well as modifier flags from Byte 2. Upper/Lower case/etc are represented through Shift and Caps Lock flags.

- SYS_CHAR_* : Scan codes are translated into these Quique internal character codes (through lookup tables and additional translation code). Supports Upper and Lower case as distinct values.

- FONT_* : Character indexes in the system ROM font that is loaded in BG Tile pattern VRAM.


# Serial Interface to Peripherals

## Keyboard
 - ? DEF SYS_CMD_READ_KEYS_MAYBE       EQU $00

### Keyboard Reply Data
RX Bytes for Keyboard Serial Reply
 - 1st:
   -  Always 0x04 (? in disasm code it looks like and checks for 0x0E though ?)
 - 2nd:
    - KEY REPEAT : |= 0x01  (so far looks like with no key value set in 3rd Byte)
    - CAPS_LOCK: |= 0x02
    - SHIFT: |= 0x04
    - LEFT_PRINTSCREEN: |= 0x08
 - 3rd:
    - Carries the keyboard key scan code
    - ? Maybe 00 when no key pressed? (0x04, <modifiers>, 0x00, <calculated checksum>)
 - 4th:
     - Two's complement checuksum byte
     - It should be: #4 == (((#1 + #2 + #3) XOR 0xFF) + 1) [two's complement]
     - I.E: (#4 + #1 + #2 + #3) == 0x100 -> unsigned overflow -> 0x00

 - Left /right shift are shared

Keyboard serial reply scan codes have different ordering than SYS_CHAR_* codes
 - They go diagonal down from upper left for the first *4* rows
 - The bottom 4 rows (including piano keys) are more varied

 LEFT_PRINTSCREEN 00 + modifier 0x08 ??? Right seems to have actual keycode


## RTC?

## Printing

## Bank switching
Megaduck QuiQue System ROM Bank Switching
- 32K bank selected by writing to 0x1000
- Seems to use delay of ~41 M-Cycles after write to bank switch (TODO: re-check)


## Run Cartridge from Cart Slot
Request booting from the cart slot
- ? Send command: 0x08
- Wait for a serial reply with the result
  - No cart found in slot: 0x06
  - If cart was found the program seems to idle in a endless nop loop. Maybe waiting for execution to transfer over. Perhaps CPU reset is handled by the peripheral hardware.

## Any Save/External RAM built in?


## "Mouse" Game Pad
There is some cross-mapping of the GamePad and Keyboard data to allow input with either device.
- Game Pad -> Keyboard
  - START      -> SYS_CHAR_SALIDA    (Esc)
  - SELECT     -> SYS_CHAR_ENTRA_CR  (Enter)
  - A          -> SYS_CHAR_PG_ARRIBA (Pg Up)
  - B          -> SYS_CHAR_PG_ABAJO  (Pg Down)
  - UP_UP      -> SYS_CHAR_UP
  - UP_LEFT    -> SYS_CHAR_LEFT
  - UP_RIGHT   -> SYS_CHAR_RIGHT
  - UP_DOWN    -> SYS_CHAR_DOWN

  - Diagonals for 8-way equivalent input on keyboard:
  - UP_RIGHT   -> SYS_CHAR_PLUS
  - DOWN_RIGHT -> SYS_CHAR_MINUS
  - DOWN_LEFT  -> SYS_CHAR_MULTIPLY
  - UP_LEFT    -> SYS_CHAR_DIVIDE

- Keyboard -> Game Pad
  - ? TODO: Should be reverse of above, but need to check