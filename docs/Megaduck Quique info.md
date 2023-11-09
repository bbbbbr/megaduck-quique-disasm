


# Keyboard/Character/Font classification
See definitions in `src/inc`
- KBD_CODE_* : Keyboard scan codes received over the serial port in Byte 3 of the serial port keyboard reply packet, as well as modifier flags from Byte 2. Upper/Lower case/etc are represented through Shift and Caps Lock flags.

- SYS_CHAR_* : Scan codes are translated into these Quique internal character codes (through lookup tables and additional translation code). Supports Upper and Lower case as distinct values.

- FONT_* : Character indexes in the system ROM font that is loaded in BG Tile pattern VRAM.


# Serial Interface to Peripherals

## Power-On Initialization
  - TODO: needs review and maybe tidyup

  - Turn off all interrupts except serial
  - Send following sequence of bytes via serial_io_send_byte__B64_
    - 0,1,2,3...255
      - 1/4 msec delay between each transfer
  - Wait for response up to 50 msec
    - If failed
    - If OK and resulting byte was SYS_REPLY_BOOT_OK (0x01)
      - Send SYS_CMD_INIT_SEQ_REQUEST (0x00) via serial_io_send_byte__B64_
        - 1/4 msec delay
        - Turn on serial interrupt
        - Use external serial clock
        - Wait for reply sequence of 255, 254, 253..0
          - Use a wait with no timeout
            - If any byte didn't match then set fail flag
        - After done receiving check fail flag
          - Turn off serial interrupt
          - If any failed then send
            - SYS_CMD_ABORT_OR_FAIL  ; $04
          - If all bytes matched the expected sequence order then send
            - SYS_CMD_DONE_OR_OK  ; $01


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
- Allowed Date Range in QuiQue System ROM: (1992 - 2011)
  - Supported dates in RTC Hardware: TODO
  - Format for all values is in BCD

### Set RTC
- Use "Send Command With Buffer" (along with it's error handling and success/fail status)
    - Values shown are system power-up defaults
    - All values are in BCD format
      - Ex: Month = December = 12th month = 0x12 (NOT 0x0C)
    - Command: (0x0B) SYS_CMD_RTC_SET_DATE_AND_TIME
    - Buffer: 8 Bytes
        - 00: Year   : 94 (Year = 1900 + Date Byte in BCD 0x94) `Quique Sys Range: 0x92 - 0x11` (1992 - 2011)
        - 01: Month  : 01 (January / Enero) `TODO: Range: 0x01 - 0x12`
        - 02: Day    : 01 (1st)
        - 03: DoW    : 06 (6th day of week: Saturday / Sabado) `TODO: Range: 0x01 -0x07`
        - 04: AM/PM  : 00 (AM) `0=AM, 1=PM`- TODO: Verify
        - 05: Hour   : 00 (With above it's: 12 am) `TODO: Range 0-11`
        - 06: Minute : 00
        - 07: Second?: 00

### Read RTC
- Use "Send Command and Read Buffer" (along with it's error handling and success/fail status)
    - Command: (0x0C) SYS_CMD_RTC_GET_DATE_AND_TIME
      - Values are the same (so far) as SYS_CMD_RTC_SET_DATE_AND_TIME

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

- ? TODO: What happens to WRAM? Does it get preserved or reset?

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

## Sending a Buffer over Serial IO  
  - serial_io_send_command_and_buffer__A34_
  - Max Length: 12 (?)

  - Turn off all interrupts except serial
  - Send Initial Command (Ex: 0x0B)
  - Wait 1/2 msec (?)
  - Wait for response up to 50 msec
    `Check_Send_Byte_OK`
      - If OK prep for sending buffer data:
        - Wait 1/4 msec
        - Send (length + 0x02)
          - The +2 sizing seems to be for:
            - Initial Length Byte
            - Trailing Checksum Byte
        - Wait 1/2 msec
        - Send Buffer data Loop
          - Wait for response up to 50 msec
            `Check_Send_Byte_OK`
            - If OK send next Buffer Byte
        - Done sending buffer bytes
        - Wait for reply to last buffer byte sent
          - Wait for response up to 50 msec
            `Check_Send_Byte_OK`
              - If OK calculate checksum (truncated to 8 bits) and send it
                - two's complement of (Sum of all bytes sent but excluding checksum)
                  - I.E: (((Length + 2) + sum of buffer bytes) xor 0xFF) + 1
              - Wait for response up to 50 msec
                - If no Reply then Failed
                - If Reply was:
                   - 0x01: Then return SUCCESS
                   - If OK return failure

 - `Check_Send_Byte_OK` is as follows:
    - If no Reply then Failed
    - If Reply was:
      - 0x06: Some kind of abort or not ready?
      - 0x03: Then Failed


## Receiving a Buffer over Serial IO
  - serial_io_send_command_and_receive_buffer__AEF_
  - Max Length: maybe 13 bytes
    - So far observed max used is 8 bytes for reading RTC data

  - Turn off all interrupts except serial
  - Wait 1/4 msec
  - Send Initial Command (Ex: 0x0C)
    - `RX_Byte_Loop`
      - Wait for response up to 50 msec
        - If no Reply then Failed
        - If RX OK then Save/Process Reply byte
          - 1st RX Byte: Length of transfer
            - (Payload size = Length - 2 to strip off Length and Checksum bytes)
            - If Raw Length >= 14: Then Failed
                - Send SYS_CMD_ABORT_OR_FAIL (0x04) out over serial
            - If Raw length < 14: continue receiving bytes
          - 2nd -> (Length-1) RX Bytes : Payload bytes, save them to buffer
          - Last RX Byte: Checksum
            - two's complement of (Sum of all bytes received except checksum [so length is included])
              - I.E: (((Length + 2) + sum of buffer bytes) xor 0xFF) + 1
    - If transfer completed with no errors and expected number of bytes (from 1st RX byte)
      - then Send SYS_CMD_DONE_OR_OK (0x01) out over serial

    