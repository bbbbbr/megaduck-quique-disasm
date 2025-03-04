


# Keyboard/Character/Font classification
See definitions in `src/inc`
- KBD_CODE_* : Keyboard scan codes received over the serial port in Byte 3 of the serial port keyboard reply packet, as well as modifier flags from Byte 2. Upper/Lower case/etc are represented through Shift and Caps Lock flags.

- SYS_CHAR_* : Scan codes are translated into these Quique internal character codes (through lookup tables and additional translation code). Supports Upper and Lower case as distinct values.

- FONT_* : Character indexes in the system ROM font that is loaded in BG Tile pattern VRAM.


# Serial Interface to Peripherals

## Serial Interrupt handler
```
_INT_SERIAL__0058_:
    di
    call serial_int_handler
    ei
    reti
```

```
serial_int_handler:
    serial_rx_data = SB_REG;
    serial_status = 0x01;
    call serial_int_disable__A2B_
```

```
serial_int_disable:
    IE_REG &= ~IEF_SERIAL; ~0x08 -> 0xF7
```



## Send Byte of Serial Interface
```
  // In testing FF60 write appears to be optional, at least when other peripherals haven't been used
  0xFF60 = 0x00;
  // Order of SC reg arm then SB load seems non-standard
  // When tested it also works in normal order (SB load then arm SC)
  SC_REG = (SERIAL_XFER_ENABLE | SERIAL_CLOCK_INT); // 0x81
  SB_REG = `Data Byte to Send`;
  delay_1_msec();
  IF_REG = 0x00;
  SC_REG = (SERIAL_XFER_ENABLE | SERIAL_CLOCK_EXT); // 0x80
```

## Receive Byte of Serial Interface
```
  // In testing FF60 write appears to be optional, at least when other peripherals haven't been used
  0xFF60 = 0x00;
  SC_REG = (SERIAL_XFER_ENABLE | SERIAL_CLOCK_EXT); // 0x80

  IE_REG |= IEF_SERIAL; 0x08
  IF_REG = 0x00;
  enable_interrupts();
```


## Power-On Initialization
  - TODO: needs review and maybe tidyup

  - Turn off all interrupts except serial
  - Send following sequence of bytes via serial_io_send_byte__B64_
    - 0,1,2,3...255
      - 1 msec delay between each transfer
  - Wait for response up to ~206 msec
    - If failed
    - If OK and resulting byte was SYS_REPLY_BOOT_OK (0x01)
      - Send SYS_CMD_INIT_SEQ_REQUEST (0x00) via serial_io_send_byte__B64_
        - 1 msec delay
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
 - ? DEF SYS_CMD_GET_KEYS       EQU $00

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


## RTC
- Allowed Date Range in QuiQue System ROM: (1992 - 2011)
- Format for all values is in BCD

### Set RTC
- Use "Send Command With Buffer" (along with it's error handling and success/fail status)
    - Values shown are system power-up defaults
    - All values are in BCD format
      - Ex: Month = December = 12th month = 0x12 (NOT 0x0C)
    - Command: (0x0B) SYS_CMD_RTC_SET_DATE_AND_TIME
    - Buffer: 8 Bytes
        - 00: Year   : 94 (Year = 1900 + Date Byte in BCD 0x94) `HW Range: 0-99. Quique Sys Range: 0x92 - 0x11` (1992 - 2011)
        - 01: Month  : 01 (January / Enero) `Range: 0x01 - 0x12`
        - 02: Day    : 01 (1st)
        - 03: DoW    : 06 (6th day of week: Saturday / Sabado) `Days since Sunday, 0x00 - 0x06`
        - 04: AM/PM  : 00 (AM) `0=AM, 1=PM`
        - 05: Hour   : 00 (With above it's: 12 am) `Range 0-11`
        - 06: Minute : 00
        - 07: Second?: 00

### Read RTC
- Use "Send Command and Read Buffer" (along with it's error handling and success/fail status)
    - Command: (0x0C) SYS_CMD_RTC_GET_DATE_AND_TIME
      - Values are the same (so far) as SYS_CMD_RTC_SET_DATE_AND_TIME


## Speech
- Use "Send Command With Buffer" (along with it's error handling and success/fail status)
    - Command: (0x05) SYS_CMD_PLAYSPEECH
    - Buffer: 1 Bytes
        - 00: Play speech phrase N (range 1-6, no audio enable required). Playback of one phrase can be interrupted by request for playback of another phrase

- Spanish Phrases
  - 1. "Genial" (brilliant)
  - 2. "Estupendo" (great)
  - 3. "Fantástico" (fantastic)
  - 4. "No, inténtalo otra vez." (no, try it again)
  - 5. "No, prueba una vez más" (no, try once again)
  - 6. "Vuelve a intentarlo" (try again)

- German Phrases (Thanks kuddel, zwenergy)
  - 1. "Ja, sehr gut" (yes, very good)
  - 2. "Gut gemacht" (well done)
  - 3. "Super" (great, awesome)
  - 4. "Uh uh, probier's noch mal" (uh oh, try again)
  - 5. "Uh uh, versuch's noch einmal" (give it another try)
  - 6. "Oooh, schade" (ohh, what a pity)

## Printing
- TODO: document Large buffer single pass model printing
  - have hunch that it's output may not be rotated and mirrored in same way
- Printing init is sending 2 x CMD 0x09
  - Response from init:
    - 0 = failed
    - Bit.1 indicates printer type (1 = single pass large buffer, 0 = two pass small buffer)
- Data sent is in 1bpp 8x8 tile format
- Each tile looks like it may be flipped horizontally and then rotated -90 degrees
  - so: rotate 90 degrees, then flip horizontal
- Optionally supports 2-pass printing (depending on bit .1 of CMD 9 response)
  - Bit.1 indicates printer type (1 = single pass large buffer, 0 = two pass small buffer)
  - First pass prints : Black + Light Grey as Black
  - Second pass prints: Black + Dark  Grey as Black
  - Sends Tile Row of data (20 x 8x8 1bpp tiles)
    - 160 bytes + 1 or 2 control chars at end
    - System Rom printing
      - Starts with 1 x blank row of tiles (single pass)
      - Then does either double or single pass printing for 18 Tile Rows
        - 13 x 12 gfx byte CMD 0x11 multi-byte packets
        - 1 x Row printing terminator packet 5 or 6 bytes
          - If Single pass printing, only ever 5 byte packets
          - If Two pass printing, alternating 5/6 byte packets
          - 0x0D = Carriage Return
          - 0x0A = Line Feed
          - 5 byte packets: <4 bytes 1bpp 8x8 tile data> <CR 0x0D>
          - 6 byte packets: <4 bytes 1bpp 8x8 tile data> <CR 0x0D> <LF 0x0A>
- Not yet sure if there is a printing teriminator ACK/handshake expected
  - Emulated printing seems to go on for a very lonnngggg time...

WIP:
- Once on device power-up and init:
  - Send single byte command: `0x09`
- print_start__maybe___ROM_32K_Bank2_053F_
  - Wait `50 msec`
  - Repeat **1-3 times** (not including 1x on program startup)
    - System ROM: 3 times
    - Bilder Lexikon: 1 time
    - Data Bank: 0 times
    - Send single byte command: `0x09`
      - Wait `200 msec` for a reply
        - Check reply byte: **Fail if zero**
        - Save reply byte to `serial_print_init_result__RAM_D2E4_`
  - Clear a `182` byte RAM buffer
  - not_yet_known___ROM_32K_Bank2_0887_
    - Copy 12 bytes from (previously zeroed) source buffer to transfer buffer
      - memcopy_12_bytes_from_hl_to_serial_buffer_RAM_D028____ROM_32K_Bank2_08FD_
    - Send command and buffer: `0x11` with `12` bytes
      - print_send_command_and_buffer_until_valid_reply__ROM_32K_Bank2_0906_
      - Check reply byte
        - Repeat send until: **Success (0xFC)**
    - Check `Bit 1` of `serial_print_init_result__RAM_D2E4_`
      - If **set/non-zero**
        - Repeat 3 times:
          - Copy 12 bytes from (previously zeroed) source buffer to transfer buffer
            - memcopy_12_bytes_from_hl_to_serial_buffer_RAM_D028____ROM_32K_Bank2_08FD_
          - Send command and buffer: `0x11` with `12` bytes
            - print_send_command_and_buffer_until_valid_reply__ROM_32K_Bank2_0906_
            - Check reply byte
              - Repeat send until: **Success (0xFC)**
        - Send `118` bytes from (mostly-previously zeroed) buffer:
          - Wait to receive 1 byte with timeout
            - serial_io_wait_receive_with_timeout__32K_Bank_2_0D53_
          - Send buffer byte
            - serial_io_send_byte__32K_Bank_2_0D28_
          - increment buffer index
        - Wait `1 msec`
        - Repeat 2x
          - Wait to receive byte with `200 msec` timeout
        - exit subroutine
      - If **zero**
        - ... TODO ...

## Bank switching
Laptop model System ROM MBC (CEFA Super Quique, Hartung Super Junior Computer)
  - Informal MBC Number: `0xE0` (SuperJuniorSameDuck emulator)
  - Informal extension: `.md0`
  - Register: `0x1000`
    - ROM Bank
      - Selected by writing (`0 - 15`) in Lower Nibble (mask `0x0F`)
      - Bank Size/Region: Switches the full 32K ROM region
    - SRAM Bank (on secondary memory cart plugged into memory cart slot)
      - Selected by writing (`0 - 3`) in Upper Nibble (mask `0x30`)
      - Bank Size/Region: 8k mapped at `0xA000 - 0xBFFF`
  - Games/Programs: Laptop System ROM, Bilder Lexikon, DataBank (requires SRAM cart)
  - Note: Uses a delay of ~41 M-Cycles (executed from WRAM) after writing the bank switch before resuming execution from ROM. Unclear if required.

## Run Cartridge from Cart Slot
Request booting from the cart slot
- ? Send command: 0x08
- Wait for a serial reply with the result
  - No cart found in slot: 0x06
  - If cart was found the program seems to idle in a endless nop loop. Maybe waiting for execution to transfer over. Perhaps CPU reset is handled by the peripheral hardware.

- ? TODO: What happens to WRAM? Does it get preserved or reset?

- Tile Pattern VRAM does not get cleared when a cart in the slot is launched from the System ROM main menu, so the main menu icon and font tiles can be inspected by the launched cart program.


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
  - Wait ~2 msec (?)
  - Wait for response up to ~206 msec
    `Check_Send_Byte_OK`
      - If OK prep for sending buffer data:
        - Wait 1 msec
        - Send (length + 0x02)
          - The +2 sizing seems to be for:
            - Initial Length Byte
            - Trailing Checksum Byte
        - Wait ~2 msec
        - Send Buffer data Loop
          - Wait for response up to ~206 msec
            `Check_Send_Byte_OK`
            - If OK send next Buffer Byte
        - Done sending buffer bytes
        - Wait for reply to last buffer byte sent
          - Wait for response up to ~206 msec
            `Check_Send_Byte_OK`
              - If OK calculate checksum (truncated to 8 bits) and send it
                - two's complement of (Sum of all bytes sent but excluding checksum)
                  - I.E: (((Length + 2) + sum of buffer bytes) xor 0xFF) + 1
              - Wait for response up to ~206 msec
                - If no Reply then Failed
                - If Reply was:
                   - 0x01: Then return SUCCESS
                   - If OK return failure

 - `Check_Send_Byte_OK` is as follows:
    - If no Reply then Failed
    - If Reply was:
      - 0x06: Some kind of abort or not ready?
      - 0x03: Then Success/Ready for payload


## Receiving a Buffer over Serial IO
  - serial_io_send_command_and_receive_buffer__AEF_
  - Max Length: maybe 13 bytes
    - So far observed max used is 8 bytes for reading RTC data

  - Turn off all interrupts except serial
  - Wait 1 msec
  - Send Initial Command (Ex: 0x0C)
    - `RX_Byte_Loop`
      - Wait for response up to ~206 msec
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

    
