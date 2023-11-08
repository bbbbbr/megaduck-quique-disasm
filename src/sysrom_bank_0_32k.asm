
; Bank 0 (32K bank size)
; Memory region 0x000 - 0x7fff

SECTION "rom0", ROM0[$0]
_DUCK_ENTRY_POINT_0000_:
    di
    jp   _GB_ENTRY_POINT_100_
    nop
    nop
    nop
    nop

_RST__08_:
    ei
    call _LABEL_4A7B_
    di
    jp   _switch_bank_return_to_saved_bank_RAM__C940_

_RST_10_serial_io_send_command_and_buffer__0010_:
    ei
    call serial_io_send_command_and_buffer__A34_
    di
    jp   _switch_bank_return_to_saved_bank_RAM__C940_

_RST__18_:
    jp   _GB_ENTRY_POINT_100_
    nop
    nop
    nop
    nop
    nop

_RST__20_:
    jp   _GB_ENTRY_POINT_100_
    nop
    nop
    nop
    nop
    nop

_RST__28_:
    jp   _GB_ENTRY_POINT_100_
    nop
    nop
    nop
    nop
    nop

_RST__30_:
    jp   _GB_ENTRY_POINT_100_
    nop
    nop
    nop
    nop
    nop

_RST__38_:
    jp   _GB_ENTRY_POINT_100_
    nop
    nop
    nop
    nop
    nop

_INT_VBL__40_:
    di
    call _VBL_HANDLER__6D_
    ei
    reti
    nop
    nop


_INT_STAT__48_:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop


_INT_TIMER__50_:
    di
    call timer_int_handler__00BB_
    ei
    reti
    nop
    nop


_INT_SERIAL__58_:
    di
    call serial_int_handler__00CE_
    ei
    reti
    nop
    nop


_INT_JOYPAD__60_:
    di
    push af
    ld   a, [_RAM_D020_]
    add  $05
    ld   [_RAM_D020_], a
    pop  af
    ei
    reti


_VBL_HANDLER__6D_:
    push af
    push bc
    push de
    push hl
    ld   a, [_RAM_D193_]
    ld   h, a
    ld   a, [_RAM_D194_]
    ld   l, a
    ld   a, [vbl_action_select__RAM_D195_]  ; Not sure where it gets set
    and  a
    jr   z, _VBL_HANDLER_TAIL__AF_
    cp   $01
    jr   nz, _VBL_HANDLER_2__88_

    call _LABEL_6A26_
    jr   _VBL_HANDLER_TAIL__AF_

    _VBL_HANDLER_2__88_:
        cp   $02
        jr   nz, _VBL_HANDLER_3__91_
        call _LABEL_6F40_
        jr   _VBL_HANDLER_TAIL__AF_

    _VBL_HANDLER_3__91_:
        cp   VBL_CMD_COPY_16_BYTES_FROM_COPY_BUF_TO_HL  ; $03
        jr   nz, _VBL_HANDLER_4__9A_
        call memcopy_16_bytes_from_copy_buffer__RAM_DCF0_to_hl__481A_
        jr   _VBL_HANDLER_TAIL__AF_

    _VBL_HANDLER_4__9A_:
        cp   VBL_CMD_COPY_16_BYTES_FROM_HL_TO_COPY_BUF  ; $04
        jr   nz, _VBL_HANDLER_5__A3_
        call memcopy_16_bytes_from_hl_to_copy_buffer__RAM_DCF0__4826_
        jr   _VBL_HANDLER_TAIL__AF_

    _VBL_HANDLER_5__A3_:
        cp   $05
        jr   nz, _VBL_HANDLER_6__AC_
        call _LABEL_6CD7_
        jr   _VBL_HANDLER_TAIL__AF_

    _VBL_HANDLER_6__AC_:
        call _LABEL_6DAB_

    _VBL_HANDLER_TAIL__AF_:
        xor  a
        ld   [vbl_action_select__RAM_D195_], a
        call _oam_dma_routine_in_HRAM__FF80_ ; $FF80
        pop  hl
        pop  de
        pop  bc
        pop  af
        ret


; Called by Timer interrupt vector
;
; Overflows/Triggers interrupt every 201 ticks (0x100 - 0x37) = 201
; 4096 Hz / (201) = ~20.378Hz, roughly every 3rd frame
timer_int_handler__00BB_:
    push af
    ld   a, [_RAM_D020_]  ; TODO: some kind of global counter shared with serial IO
    add  $07
    ld   [_RAM_D020_], a
    ld   a, [timer_flags__RAM_D000_]
    set  TIMER_FLAG__BIT_TICKED, a  ; 2, a
    ld   [timer_flags__RAM_D000_], a
    pop  af
    ret


; Serial IO ISR
;
; - Stores serial data in:        serial_rx_data__RAM_D021_
; - Sets transfer status done in: serial_status__RAM_D022_
; - Turns off the serial IO interrupt
serial_int_handler__00CE_:
    push af
    ldh  a, [rSB]
    ld   [serial_rx_data__RAM_D021_], a
    ld   a, SERIAL_STATUS_DONE ; $01
    ld   [serial_status__RAM_D022_], a
    call serial_int_disable__A2B_
    pop  af
    ret


; Data from DE to FE (33 bytes)
_DATA_00DE_:
ds 34, $00


SECTION "rom0_gbentrypoint_100", ROM0[$0100]
_GB_ENTRY_POINT_100_:
    di
    xor  a
    ld   [vbl_action_select__RAM_D195_], a

    ; Initialize Serially attached peripheral
    call serial_system_init_check__9CF_
    wait_serial_status_ok__108_:
        ld   a, [serial_system_status__RAM_D024_]
        bit  SYS_REPLY__BIT_BOOT_FAIL, a  ; 0, a
        jr   nz, wait_serial_status_ok__108_

    ; TODO: Save response from some command
    ; (so far not seen being used in 32K Bank 0)
    ld   a, SYS_CMD_INIT_UNKNOWN_0x09  ; $09  // TODO
    ld   [serial_tx_data__RAM_D023_], a
    call serial_io_send_byte__B64_
    call serial_io_read_byte_no_timeout__B7D_
    ld   a, [serial_rx_data__RAM_D021_]
    ld   [serial_cmd_0x09_reply_data__RAM_D2E4_], a

    ; Check some kind of verification sequence in RAM
    ld   hl, init_key_slot_1__RAM_DBFC_
    ldi  a, [hl]
    cp   INIT_KEY_1  ; $AA
    jr   nz, .init_keys_check_failed__0134_
    ldi  a, [hl]
    cp   INIT_KEY_2  ; $E4
    jr   nz, .init_keys_check_failed__0134_
    ldi  a, [hl]
    cp   INIT_KEY_3  ; $55
    jr   nz, .init_keys_check_failed__0134_
    jr   .init_keys_check_passed__014E_

    .init_keys_check_failed__0134_:
        xor  a
        ld   [_RAM_DBFB_], a    ; _RAM_DBFB_ = $DBFB
        ld   a, INIT_KEY_1  ; $AA
        ld   [init_key_slot_1__RAM_DBFC_], a
        ld   a, INIT_KEY_2  ; $E4
        ld   [init_key_slot_2__RAM_DBFD_], a
        ld   a, INIT_KEY_3  ; $55
        ld   [init_key_slot_3__RAM_DBFE_], a
        ld   a, INIT_KEYS_DIDNT_MATCH_IN_RAM  ; $AA  ; TODO: needs more specific name
        ld   [_RAM_D400_], a
        jr   .init_keys_check_done_now_init__152_

    .init_keys_check_passed__014E_:
        xor  a
        ld   [_RAM_D400_], a

    .init_keys_check_done_now_init__152_:
        di
        ld   sp, $C400
        call general_init__97A_
        call vram_init__752_

    ; TODO: Maybe main menu loop?
    _LABEL_15C_:
        ; Check result of previous init sequence test
        ld   a, [_RAM_D400_]
        cp   INIT_KEYS_DIDNT_MATCH_IN_RAM  ; $AA
        ; Note: To force an RTC update to configured defaults use this instead (no Z test)
        ; call rtc_set_default_time_and_date__25E_
        call z, rtc_set_default_time_and_date__25E_

        ; Load Tile Data for the main menu launcher (Icons, Cursor)
        call wait_until_vbl__92C_
        call display_screen_off__94C_
        ld   hl, _TILEDATA9000                          ; Dest
        ld   de, gfx_tile_data__main_menu_icons__11F2_  ; Source
        ld   bc, (MENU_ICONS_128_TILES * TILE_SZ_BYTES) ; Copy size: 128 tiles (2048 bytes)
        call _memcopy_in_RAM__C900_


        ; Load Tile Data for the main menu font
        call wait_until_vbl__92C_
        call display_screen_off__94C_
        ld   hl, _TILEDATA8800                         ; Dest
        ld   de, gfx_tile_data__main_menu_font__2F2A_   ; Source
        ld   bc, (MENU_FONT_128_TILES * TILE_SZ_BYTES) ; Copy size: 128 tiles (2048 bytes)
        call _memcopy_in_RAM__C900_

        xor  a
        ld   [_RAM_D06C_], a    ; _RAM_D06C_ = $D06C
        ld   a, $0C
        ld   [_RAM_D06D_], a    ; _RAM_D06D_ = $D06D
        call _LABEL_4A7B_
        call _LABEL_56E_


; TODO: Starting here seems to be some kind of big if/else function call selector for whatever is in D06E
; Including eventually calling the "no cart in slot" using value 0B (Range 0x00 - 0x0B)
    ld   a, [_RAM_D06E_]
    cp   $00
    jr   nz, _LABEL_1A3_
    call _LABEL_54AE_
    jr   _LABEL_15C_

_LABEL_1A3_:
    cp   $01
    jr   nz, _LABEL_1B3_
    xor  a
    ldh  [rSCX], a
    call _LABEL_4D6F_
    ld   a, $FF
    ldh  [rSCX], a
    jr   _LABEL_15C_

_LABEL_1B3_:
    cp   $02
    jr   nz, _LABEL_1C5_
    di
    ld   hl, _RST__08_  ; _RST__08_ = $0008
    res  7, h
    ld   a, $01
    call _switch_bank_jump_hl_RAM__C920_
    ei
    jr   _LABEL_15C_

_LABEL_1C5_:
    cp   $03
    jr   nz, _LABEL_1D7_
    di
    ld   hl, $0010
    res  7, h
    ld   a, $01
    call _switch_bank_jump_hl_RAM__C920_
    ei
    jr   _LABEL_15C_

_LABEL_1D7_:
    cp   $04
    jr   nz, _LABEL_1EA_
    di
        ld   hl, _RST__18_  ; _RST__18_ = $0018
        res  7, h
        ld   a, $01
        call _switch_bank_jump_hl_RAM__C920_
        ei
        jp   _LABEL_15C_

_LABEL_1EA_:
    cp   $05
    jr   nz, _LABEL_1FD_
    di
    ld   hl, _RST__20_  ; _RST__20_ = $0020
    res  7, h
    ld   a, $01
    call _switch_bank_jump_hl_RAM__C920_
    ei
    jp   _LABEL_15C_

_LABEL_1FD_:
    cp   $06
    jr   nz, _LABEL_20D_
    call _LABEL_52F_
    call _LABEL_6328_
    call _LABEL_54B_
; Data from 20A to 20C (3 bytes)
_DATA_20A_:
db $C3, $5C, $01

_LABEL_20D_:
    cp   $07
    jr   nz, _LABEL_226_
    di
    call _LABEL_52F_
    ld   hl, $0010
    res  7, h
    ld   a, $02
    call _switch_bank_jump_hl_RAM__C920_
    call _LABEL_54B_
    ei
    jp   _LABEL_15C_

_LABEL_226_:
    cp   $08
    jr   nz, _LABEL_230_
    call _LABEL_711A_
    jp   _LABEL_15C_

_LABEL_230_:
    cp   $09
    jr   nz, _LABEL_249_
    di
    call _LABEL_52F_
    ld   hl, $0008
    res  7, h
    ld   a, $02
    call _switch_bank_jump_hl_RAM__C920_
    call _LABEL_54B_
    ei
    jp   _LABEL_15C_

_LABEL_249_:
    cp   $0A
    jr   nz, _LABEL_253_
    call _LABEL_5E55_
    jp   _LABEL_15C_


; TODO : Maybe the "Run Cart from slot" Main menu item?
_LABEL_253_:
    cp   $0B ; TODO: Add constant for this Main Menu Item (11) MAIN_MENU_CMD_RUNCART
    jp   nz, _LABEL_15C_
    call maybe_try_run_cart_from_slot__5E1_
    jp   _LABEL_15C_  ; TODO: Return to main_menu_init?


; Sets the RTC to Power-Up default Date and Time via Serial IO
;
; -  Saturday,  January 1, 1994 12:00am
;
; - Dates after Y2K Are not supported by the default System ROM
rtc_set_default_time_and_date__25E_:
    ; Uses RAM starting at buffer__RAM_D028_ for a multi-send serial buffer
    ; Sends 8 Bytes: 0x94, 0x01, 0x01, 0x06, 0x00, 0x00, 0x00, 0x00
    ld   hl, buffer__RAM_D028_
    ld   a, $94
    ldi  [hl], a    ; 00: Year   : 94 (Year = 1900 + Date Byte in BCD 0x94) `Quique Sys Range: 0x92 - 0x11` (1992 - 2011)
    ld   a, $1
    ldi  [hl], a    ; 01: Month  : 01 (January / Enero) `TODO: Range: 0x01 - 0x12`
    ldi  [hl], a    ; 02: Day    : 01 (1st)
    ld   a, $06
    ldi  [hl], a    ; 03: DoW    : 06 (6th day of week: Saturday / Sabado) `TODO: Range: 0x01 -0x07`
    xor  a
    ldi  [hl], a    ; 04: AM/PM  : 00 (AM) `0=AM, 1=PM`- TODO: Verify
    xor  a
    ldi  [hl], a    ; 05: Hour   : 00 (With above it's: 12 am) `TODO: Range 0-11`
    ldi  [hl], a    ; 06: Minute : 00
    ldi  [hl], a    ; 07: Second?: 00

    ld   a, SYS_CMD_RTC_SET_DATE_AND_TIME ; $0B
    ld   [serial_cmd_to_send__RAM_D035_], a

    ld   a, SYS_RTC_SET_DATE_AND_TIME_LEN  ; $08  ; Send 8 bytes
    ld   [serial_transfer_length__RAM_D034_], a

    ; Wait for system message passed via the 0xF0+ reserved
    ; Sys Char value range in serial rx key press var
    .loop_wait_valid_reply_0xFC__27B_:
        ; Try to send buffer
        ; Check result from sending
        ; If no success then wait a tick + ? and retry
        call serial_io_send_command_and_buffer__A34_
        ld   a, [input_key_pressed__RAM_D025_]
        cp   SYS_CHAR_SERIAL_TX_SUCCESS  ; $FC
        ret  z
        call timer_wait_tick_AND_TODO__289_
        jr   .loop_wait_valid_reply_0xFC__27B_


; Turn on interrupts and wait for a Timer tick
; - Maybe audio driver related
; - Maybe gamepad / Keyboard input related
;
; - Turn on interrupts
;
; Overflows/Triggers interrupt every 201 ticks (0x100 - 0x37) = 201
; 4096 Hz / (201) = ~20.378Hz, roughly every 3rd frame
;
; TODO: maybe: timer_wait_tick_AND_TODO__289_;
timer_wait_tick_AND_TODO__289_:
    ei
loop_wait_timer__28A_:
    ld   hl, timer_flags__RAM_D000_
    bit  TIMER_FLAG__BIT_TICKED, [hl]  ; 2, [hl]
    jp   nz, _LABEL_43C_
    jr   loop_wait_timer__28A_


; Waits for a Timer tick to read the joypad & buttons
;
; Possibly unused?
wait_timer_then_read_joypad_buttons__294_:
    ld   hl, timer_flags__RAM_D000_
    bit  TIMER_FLAG__BIT_TICKED, [hl]  ; 2, [hl]
    jr   nz, start_read__29D_
    jr   wait_timer_then_read_joypad_buttons__294_

    start_read__29D_:
        ; Clear flag and read joypad
        res  TIMER_FLAG__BIT_TICKED, [hl]  ; 2, [hl]
        jp   joypad_and_buttons_read__4F9_
        ; Returns at end of joypad_and_buttons_read__4F9_


_LABEL_2A2_:
    ld   a, [_RAM_CC01_]    ; _RAM_CC01_ = $CC01
    set  0, a
    res  4, a
    ld   [_RAM_CC01_], a    ; _RAM_CC01_ = $CC01
    ld   a, l
    ld   [_RAM_CC11_], a    ; _RAM_CC11_ = $CC11
    ld   a, h
    ld   [_RAM_CC10_], a    ; _RAM_CC10_ = $CC10
    ld   a, $8B
    ld   [_RAM_CC12_], a    ; _RAM_CC12_ = $CC12
    ld   a, $00
    ld   [_RAM_CC13_], a    ; _RAM_CC13_ = $CC13
    ld   a, $C0
    ld   [_RAM_CC14_], a    ; _RAM_CC14_ = $CC14
    ld   a, [_RAM_CC00_]    ; _RAM_CC00_ = $CC00
    or   $11
    ld   [_RAM_CC00_], a    ; _RAM_CC00_ = $CC00
    ld   a, $01
    ld   [_RAM_CC23_], a    ; _RAM_CC23_ = $CC23
    ret

_LABEL_2D1_:
    ld   a, [_RAM_CC40_]    ; _RAM_CC40_ = $CC40
    ld   h, a
    ld   a, [_RAM_CC41_]    ; _RAM_CC41_ = $CC41
    ld   l, a
    ld   a, [hl]
    ld   b, a
    inc  hl
    ld   a, h
    ld   [_RAM_CC40_], a    ; _RAM_CC40_ = $CC40
    ld   a, l
    ld   [_RAM_CC41_], a    ; _RAM_CC41_ = $CC41
    ld   a, $FF
    ld   [_RAM_CC48_], a    ; _RAM_CC48_ = $CC48
    ld   [_RAM_CC49_], a    ; _RAM_CC49_ = $CC49
    bit  7, b
    jr   z, _LABEL_307_
    ld   a, [_RAM_CC47_]    ; _RAM_CC47_ = $CC47
    res  0, a
    ld   [_RAM_CC47_], a    ; _RAM_CC47_ = $CC47
    dec  hl
    ld   a, l
    ld   [_RAM_CC41_], a    ; _RAM_CC41_ = $CC41
    ld   a, h
    ld   [_RAM_CC40_], a    ; _RAM_CC40_ = $CC40
    ld   a, $01
    ld   [_RAM_CC42_], a    ; _RAM_CC42_ = $CC42
    ret

_LABEL_307_:
    ld   a, [hl]
    ld   [_RAM_CC42_], a    ; _RAM_CC42_ = $CC42
    inc  hl
    ld   a, h
    ld   [_RAM_CC40_], a    ; _RAM_CC40_ = $CC40
    ld   a, l
    ld   [_RAM_CC41_], a    ; _RAM_CC41_ = $CC41
    ret

_LABEL_315_:
    ld   a, [_RAM_CC02_]    ; _RAM_CC02_ = $CC02
    or   $01
    ld   [_RAM_CC02_], a    ; _RAM_CC02_ = $CC02
    ld   a, [_RAM_CC01_]    ; _RAM_CC01_ = $CC01
    bit  4, a
    jr   z, _LABEL_327_
    jp   _LABEL_3A6_

_LABEL_327_:
    ld   a, [_RAM_CC10_]    ; _RAM_CC10_ = $CC10
    ld   h, a
    ld   a, [_RAM_CC11_]    ; _RAM_CC11_ = $CC11
    ld   l, a
    ld   a, [hl]
    ld   b, a
    inc  hl
    ld   a, h
    ld   [_RAM_CC10_], a    ; _RAM_CC10_ = $CC10
    ld   a, l
    ld   [_RAM_CC11_], a    ; _RAM_CC11_ = $CC11
    ld   a, [_RAM_CC12_]    ; _RAM_CC12_ = $CC12
    ld   [_RAM_CC2F_], a    ; _RAM_CC2F_ = $CC2F
    bit  7, b
    jr   z, _LABEL_37D_
_LABEL_344_:
    ld   a, $FE
    xor  b
    jr   z, _LABEL_36F_
    dec  hl
    ld   a, l
    ld   [_RAM_CC11_], a    ; _RAM_CC11_ = $CC11
    ld   a, h
    ld   [_RAM_CC10_], a    ; _RAM_CC10_ = $CC10
    ld   a, $FF
    ld   [_RAM_CC28_], a    ; _RAM_CC28_ = $CC28
    ld   a, $07
    ld   [_RAM_CC27_], a    ; _RAM_CC27_ = $CC27
    ld   a, $01
    ld   [_RAM_CC23_], a    ; _RAM_CC23_ = $CC23
    ld   a, $01
    ld   [_RAM_CC2F_], a    ; _RAM_CC2F_ = $CC2F
    ld   a, [_RAM_CC00_]    ; _RAM_CC00_ = $CC00
    and  $EE
    ld   [_RAM_CC00_], a    ; _RAM_CC00_ = $CC00
    ret

_LABEL_36F_:
    ld   a, [_RAM_CC60_]    ; _RAM_CC60_ = $CC60
    ld   [_RAM_CC10_], a    ; _RAM_CC10_ = $CC10
    ld   a, [_RAM_CC61_]    ; _RAM_CC61_ = $CC61
    ld   [_RAM_CC11_], a    ; _RAM_CC11_ = $CC11
    jr   _LABEL_327_


; TODO: What is this actually doing
_LABEL_37D_:
    ; Calculate offset (A X 2) into table at _DATA_BE3_ -> HL
    ld   a, b
    add  a
    ld   c, a
    ld   b, $00
    ld   hl, _DATA_BE3_
    add  hl, bc
    ; Load u16 from table at HL into _RAM_CC27_, _RAM_CC28_
    inc  hl
    ld   a, [hl]
    ld   [_RAM_CC28_], a
    dec  hl
    ld   a, [hl]
    ld   [_RAM_CC27_], a

    ; Load pointer from _RAM_CC10_, _RAM_CC11_
    ; Read a byte and save it to _RAM_CC23_
    ; Then store pointer addr +1 back in _RAM_CC10_, _RAM_CC11_
    ld   a, [_RAM_CC10_]
    ld   h, a
    ld   a, [_RAM_CC11_]
    ld   l, a
    ld   a, [hl]
    ld   [_RAM_CC23_], a

    inc  hl
    ld   a, h
    ld   [_RAM_CC10_], a    ; _RAM_CC10_ = $CC10
    ld   a, l
    ld   [_RAM_CC11_], a    ; _RAM_CC11_ = $CC11
    ret


_LABEL_3A6_:
    ld   a, [_RAM_CC10_]    ; _RAM_CC10_ = $CC10
    ld   h, a
    ld   a, [_RAM_CC11_]    ; _RAM_CC11_ = $CC11
    ld   l, a
    ldi  a, [hl]
    bit  7, a
    jr   z, _LABEL_406_
    ld   a, [_RAM_CC47_]    ; _RAM_CC47_ = $CC47
    bit  0, a
    jp   z, _LABEL_344_
    res  0, a
    ld   [_RAM_CC47_], a    ; _RAM_CC47_ = $CC47
    ld   a, [_RAM_CC41_]    ; _RAM_CC41_ = $CC41
    ld   [_RAM_CC11_], a    ; _RAM_CC11_ = $CC11
    ld   a, [_RAM_CC40_]    ; _RAM_CC40_ = $CC40
    ld   [_RAM_CC10_], a    ; _RAM_CC10_ = $CC10
    ld   a, [_RAM_CC43_]    ; _RAM_CC43_ = $CC43
    ld   [_RAM_CC12_], a    ; _RAM_CC12_ = $CC12
    ld   a, [_RAM_CC44_]    ; _RAM_CC44_ = $CC44
    ld   [_RAM_CC13_], a    ; _RAM_CC13_ = $CC13
    ld   a, [_RAM_CC45_]    ; _RAM_CC45_ = $CC45
    ld   [_RAM_CC14_], a    ; _RAM_CC14_ = $CC14
    ld   a, [_RAM_CC48_]    ; _RAM_CC48_ = $CC48
    ld   [_RAM_CC27_], a    ; _RAM_CC27_ = $CC27
    ld   a, [_RAM_CC49_]    ; _RAM_CC49_ = $CC49
    ld   [_RAM_CC28_], a    ; _RAM_CC28_ = $CC28
    ld   a, [_RAM_CC46_]    ; _RAM_CC46_ = $CC46
    ld   b, a
    ld   a, [_RAM_CC00_]    ; _RAM_CC00_ = $CC00
    and  $EE
    or   b
    ld   [_RAM_CC00_], a    ; _RAM_CC00_ = $CC00
    ld   a, [_RAM_CC42_]    ; _RAM_CC42_ = $CC42
    ld   [_RAM_CC23_], a    ; _RAM_CC23_ = $CC23
    ld   a, [_RAM_CC01_]    ; _RAM_CC01_ = $CC01
    res  4, a
    ld   [_RAM_CC01_], a    ; _RAM_CC01_ = $CC01
    ret

_LABEL_406_:
    ld   [_RAM_CC23_], a    ; _RAM_CC23_ = $CC23
    ldi  a, [hl]
    ld   [_RAM_CC2F_], a    ; _RAM_CC2F_ = $CC2F
    ldi  a, [hl]
    ld   [_RAM_CC14_], a    ; _RAM_CC14_ = $CC14
    ldi  a, [hl]
    ld   [_RAM_CC27_], a    ; _RAM_CC27_ = $CC27
    ldi  a, [hl]
    ld   [_RAM_CC28_], a    ; _RAM_CC28_ = $CC28
    ldi  a, [hl]
    ld   [_RAM_CC13_], a    ; _RAM_CC13_ = $CC13
    and  $80
    jr   z, _LABEL_42B_
    ld   a, [_RAM_CC01_]    ; _RAM_CC01_ = $CC01
    set  0, a
    ld   [_RAM_CC01_], a    ; _RAM_CC01_ = $CC01
    jr   _LABEL_433_

_LABEL_42B_:
    ld   a, [_RAM_CC01_]    ; _RAM_CC01_ = $CC01
    res  0, a
    ld   [_RAM_CC01_], a    ; _RAM_CC01_ = $CC01
_LABEL_433_:
    ld   a, l
    ld   [_RAM_CC11_], a    ; _RAM_CC11_ = $CC11
    ld   a, h
    ld   [_RAM_CC10_], a    ; _RAM_CC10_ = $CC10
    ret


; Clears Timer ticked flag...
; TODO: probably audio driver related
_LABEL_43C_:
    res  TIMER_FLAG__BIT_TICKED, [hl]  ; 2, [hl]
    ld   a, [_RAM_CC00_]    ; _RAM_CC00_ = $CC00
    bit  0, a
    jr   nz, _LABEL_44A_
    bit  4, a
    jp   z, _LABEL_4D3_

_LABEL_44A_:
    ld   a, [_RAM_CC23_]    ; _RAM_CC23_ = $CC23
    dec  a
    ld   [_RAM_CC23_], a    ; _RAM_CC23_ = $CC23
    jr   nz, _LABEL_4C0_

    call _LABEL_315_
    ld   a, [_RAM_CC02_]    ; _RAM_CC02_ = $CC02
    bit  0, a
    jp   z, _LABEL_4C0_
    ld   a, [_RAM_CC13_]    ; _RAM_CC13_ = $CC13
    ldh  [rAUD1SWEEP], a
    ld   a, [_RAM_CC14_]    ; _RAM_CC14_ = $CC14
    ldh  [rAUD1LEN], a
    ld   a, [_RAM_CC28_]    ; _RAM_CC28_ = $CC28
    ldh  [rAUD1LOW], a
    ; TODO: Is this where it interacts with the speech synthesizer chip?
    ld   a, (AUDVOL_VIN_LEFT | AUDVOL_VIN_RIGHT | AUDVOL_LEFT_MAX | AUDVOL_RIGHT_MAX)  ; $FF  ; Set rAUDVOL to both VIN = ON, Max Left/Right volume
    ldh  [rAUDVOL], a
    ld   a, [_RAM_CC2F_]    ; _RAM_CC2F_ = $CC2F
    ld   a, [_RAM_CC27_]    ; _RAM_CC27_ = $CC27
    cp   $07
    jr   nz, _LABEL_486_
    ld   a, [_RAM_CC28_]    ; _RAM_CC28_ = $CC28
    cp   $FF
    jr   nz, _LABEL_486_
    ld   a, $80
    jr   _LABEL_488_

_LABEL_486_:
    ld   a, $0F
_LABEL_488_:
    ldh  [rAUD1ENV], a
    ld   a, [_RAM_CC27_]    ; _RAM_CC27_ = $CC27
    res  6, a
    set  7, a
    ld   b, a
    ld   a, [_RAM_CC01_]    ; _RAM_CC01_ = $CC01
    bit  0, a
    jr   z, _LABEL_49E_
    ld   a, b
    res  6, a
    jr   _LABEL_49F_

_LABEL_49E_:
    ld   a, b
_LABEL_49F_:
    ld   b, a
    ld   a, [_RAM_CC27_]    ; _RAM_CC27_ = $CC27
    cp   $07
    jr   nz, _LABEL_4B5_
    ld   a, [_RAM_CC28_]    ; _RAM_CC28_ = $CC28
    cp   $FF
    jr   nz, _LABEL_4B5_
    xor  a
    ldh  [rAUDENA], a
    ld   a, AUDENA_ON  ; $80
    ldh  [rAUDENA], a
_LABEL_4B5_:
    ld   a, b
    ldh  [rAUD1HIGH], a
    ld   a, [_RAM_CC02_]    ; _RAM_CC02_ = $CC02
    res  0, a
    ld   [_RAM_CC02_], a    ; _RAM_CC02_ = $CC02
_LABEL_4C0_:
    ld   a, [_RAM_CC47_]    ; _RAM_CC47_ = $CC47
    bit  0, a
    jr   z, _LABEL_4D3_
    ld   a, [_RAM_CC42_]    ; _RAM_CC42_ = $CC42
    dec  a
    ld   [_RAM_CC42_], a    ; _RAM_CC42_ = $CC42
    jr   nz, _LABEL_4D3_
    call _LABEL_2D1_
_LABEL_4D3_:
    ld   a, [_RAM_CC00_]    ; _RAM_CC00_ = $CC00
    bit  1, a
    jr   nz, _LABEL_4DE_
    bit  5, a
    jr   z, _LABEL_4DE_
_LABEL_4DE_:
    ld   a, [_RAM_CC00_]    ; _RAM_CC00_ = $CC00
    bit  2, a
    jr   nz, _LABEL_4E9_
    bit  6, a
    jr   z, _LABEL_4E9_
_LABEL_4E9_:
    ld   a, [_RAM_CC00_]    ; _RAM_CC00_ = $CC00
    bit  3, a
    jr   nz, _LABEL_4F4_
    bit  7, a
    jr   z, _LABEL_4F4_
_LABEL_4F4_:
    ld   a, [_RAM_CC00_]    ; _RAM_CC00_ = $CC00
    ldh  [rAUDTERM], a



; Read D-Pad and Buttons
;
; - D-Pad: Upper nibble
; - Buttons: Lower nibble
;
; - Newly pressed buttons saved to: buttons_new_pressed__RAM_D006_
; - current pressed buttons saved to: buttons_current__RAM_D007_
joypad_and_buttons_read__4F9_:
    ; Read D-Pad
    ld   a, P1F_GET_DPAD  ; $20
    ldh  [rP1], a
    ldh  a, [rP1]
    ldh  a, [rP1]
    ldh  a, [rP1]
    cpl
    and  $0F
    swap a
    ld   b, a
    ; Read Buttons
    ld   a, P1F_GET_BTN  ; $10
    ldh  [rP1], a
    ldh  a, [rP1]
    ldh  a, [rP1]
    ldh  a, [rP1]
    cpl
    and  $0F
    ; Merge D-Pad and Buttons (active High)
    or   b
    ld   b, a
    ; Determine newly pressed buttons and save result
    ld   hl, buttons_new_pressed__RAM_D006_
    xor  [hl]
    and  b
    ld   [hl], b
    ; Save currently pressed buttons as well
    ld   [buttons_current__RAM_D007_], a
    ret

; TODO: Most Printscreen key presses ultimately call this
;  ? ... Why the res 7, h ?
;
; - Switches to Bank 2
; - Jumps to an RST 30
; - Once in Bank 2:
;   - _RST__30_:
;     - call _LABEL_52B_
;       - call _LABEL_53F_
;         - Looks like it sends a series commands:
;           - TX: 3 x 0x09, RX: checks non-zero
;           ... then a lot more code
;     - ei
;     - jp C940 Likely: _switch_bank_return_to_saved_bank_RAM__C940_
maybe_call_printscreen_in_32k_bank_2__522_:
    di
    ld   hl, $0030  ; RST 30
    res  7, h
    ld   a, $02  ; Bank 2
    call _switch_bank_jump_hl_RAM__C920_
    ei
    ret

_LABEL_52F_:
    ld   a, [_RAM_DBFB_]
    ld   [_RAM_D080_], a
    ld   hl, _RAM_D740_
    ld   de, _RAM_CD00_
    ld   b, $C0
    call memcopy_b_bytes_from_hl_to_de__482B_
    ld   hl, _RAM_DAD0_
    ld   de, _RAM_D081_
    ld   b, $C0
    jp   memcopy_b_bytes_from_hl_to_de__482B_

_LABEL_54B_:
    ld   a, [_RAM_D080_]
    and  $02
    ld   b, a
    ld   a, [_RAM_DBFB_]
    or   b
    ld   [_RAM_DBFB_], a
    ld   hl, _RAM_CD00_
    ld   de, _RAM_D740_
    ld   b, $C0
    call memcopy_b_bytes_from_hl_to_de__482B_
    ld   hl, _RAM_D081_
    ld   de, _RAM_DAD0_
    ld   b, $C0
    jp   memcopy_b_bytes_from_hl_to_de__482B_

_LABEL_56E_:
    ; Load Tile Data for the main menu font
    call wait_until_vbl__92C_
    call display_screen_off__94C_
    ld   hl, _TILEDATA8800                         ; Dest
    ld   de, gfx_tile_data__main_menu_font__2F2A_   ; Source
    ld   bc, (MENU_FONT_128_TILES * TILE_SZ_BYTES) ; Copy size: 128 tiles (2048 bytes)
    call _memcopy_in_RAM__C900_

    ld   a, $A0
    ldh  [rWY], a
    call _LABEL_488F_
    ld   hl, _string_table_630_
    ld   a, [_RAM_D06E_]
    cp   $00
    jr   z, _LABEL_59A_
    ld   b, a
_LABEL_592_:
    ldi  a, [hl]
    cp   $00
    jr   nz, _LABEL_592_
    dec  b
    jr   nz, _LABEL_592_
_LABEL_59A_:
    call wait_until_vbl__92C_
    call display_screen_off__94C_
    ld   de, $9D20
_LABEL_5A3_:
    ldi  a, [hl]
    cp   $00
    jr   z, _display_win_obj_on__5B5_
    cp   $01
    jr   z, _LABEL_5B0_
    ld   [de], a
    inc  de
    jr   _LABEL_5A3_

_LABEL_5B0_:
    ld   de, $9D40
    jr   _LABEL_5A3_

; Turn on display, Window, Sprites
_display_win_obj_on__5B5_:
    ldh  a, [rLCDC]
    or   (LCDCF_ON | LCDCF_WINON | LCDCF_OBJON) ; $A1
    ldh  [rLCDC], a
    call _LABEL_967_
    ld   a, $0A
    jp   _LABEL_4A72_


; TODO:  This is probably the function that gets called
; right before the cartridge is launched.
;
; Nothing seems to call it yet though.
;
_window_scroll_up__5C3_:
    di
    ld   a, 160 ; Start Window top position at Y line 160 ; $A0
    ldh  [rWY], a

    window_scroll_up_loop__5C8_:
        ld   hl, $2000  ; Delay 57,346 M-Cycles (a little less than one frame [70,224])
        _delay_loop__5CB_:
                dec  hl
                ld   a, l
                or   h
                jr   nz, _delay_loop__5CB_
            ei
            ldh  a, [rWY]
            sub  $08
            ldh  [rWY], a
            di
            cp   $00
            jr   nz, window_scroll_up_loop__5C8_
            ld   a, $0A
            jp   _LABEL_4A72_


; TODO: Seems to check and see whether a cart was found in the slot
; If one isn't found then it displays a message indicating that
; try_run_cart_from_slot__5E1_:
maybe_try_run_cart_from_slot__5E1_:
    ; TODO: Request booting from the cart slot?
    ld   a, SYS_CMD_RUN_CART_IN_SLOT ; $08
    ld   [serial_tx_data__RAM_D023_], a
    call serial_io_send_byte__B64_
    call serial_io_wait_receive_with_timeout__B8F_  ; Result is in A. 0x01 if byte was received
    and  a
    ; Wait for a serial IO response byte
    jr   z, maybe_try_run_cart_from_slot__5E1_

    ld   a, [serial_rx_data__RAM_D021_]
    cp   SYS_REPLY_NO_CART_IN_SLOT ; $06  ; Indicates there was no cart in the slot to run
    jr   z, display_message__no_cart_in_slot_to_run__5F9
    ; TODO: If starting the cart slot succeeded then execute NOPs until the cart starts
    ; Presumably there may be some small delay before the system ROM unmaps itself?
    ;
    ; What about a jump to the entry point and resetting state? Does the hardware handle that
    ; by strobing the reset line?
    _idle_until_cart_starts_5F6_:
        nop
        jr   _idle_until_cart_starts_5F6_


; After a short delay this message is cleared and the program
; returns to the main menu
display_message__no_cart_in_slot_to_run__5F9:
    call display_clear_screen_with_space_char__4875_
    ld   de, _string_message__no_cart_in_slot_to_run__734_
    ; Render first line
    ld   hl, $030A         ; Column 3, Row 10 (zero based)
    ld   c, PRINT_NORMAL  ; $01
    call render_string_at_de_to_tilemap0_xy_in_hl__4A46_
    ; Render second line
    ; DE is now at the start of the second line
    ; (C is still PRINT_NORMAL  ; $01)
    ld   hl, $030B         ; Column 3, Row 11 (zero based)
    call render_string_at_de_to_tilemap0_xy_in_hl__4A46_
    ld   a, $64
    jp   _LABEL_4A72_ ; TODO: there is a small delay after string is shown, is part of this call handling that (sort of wait_vsync N times)?


; Waits until VBL then Writes byte to Tile Map 0 VRAM at preset address X,Y
;
; - Tilemap X,Y and byte to write in global vars
;
wait_vbl_write_byte_tilemap0_preset_xy_and_data__612_:
        push af
        push bc
        push de
        push hl
        call wait_until_vbl__92C_
        ld   a, SELECT_TILEMAP_0  ; $00
        call write_tilemap_in_a_preset_xy_and_data_8FB_
        pop  hl
        pop  de
        pop  bc
        pop  af
        ret

_LABEL_623_:
    call oam_find_slot_and_load_into__86F
    ret

; Masks out: LCDCF_WINON, LCDCF_BG8000
; Turns Display, BG and sprites on
_display_bg_sprites_on__627_:
    ldh  a, [rLCDC]
    and  (LCDCF_ON | LCDCF_BGON | LCDCF_WIN9C00 | LCDCF_BG9C00 | LCDCF_OBJ16 | LCDCF_OBJON) ; $CF
    or   (LCDCF_ON | LCDCF_BGON | LCDCF_OBJON) ; $C1
    ldh  [rLCDC], a
    ret


; - Block of encoded text at 0x0637 - 0x0750
;        92 85 8C 8F 8A 00 BE BE BE BE BE 83 81 8C 85 8E 84 81 92 89 8F 00 BE BE BE BE BE 83 81 8C 83 95 8C 81 84 8F 92 81 00 BE BE BE BE BE BE BE 81 87 85 8E 84 81 00 BE BE BE BE BE 83 88 85 91 95 85 8F BE 84 85 01 BE BE BE BE BE BE 84 85 8C 85 94 92 85 8F 00 BE BE BE BE BE BE BE 8A 95 85 87 8F 93 00 BE BE BE BE BE BE BE 84 89 82 95 8A 8F 00 BE BE BE BE 90 92 8F 87 92 81 8D 81 83 89 8F 8E 01 BE BE BE BE BE BE BE 82 81 93 89 83 81 00 BE BE BE BE BE BE BE BE 90 89 81 8E 8F 00 BE BE BE 90 92 8F 83 85 93 81 84 8F 92 BE 84 85 01 BE BE BE BE BE BE 90 81 8C 81 82 92 81 93 00 BE BE BE 84 89 83 83 89 8F 8E 81 92 89 8F BE 84 85 01 BE BE BE BE BE BE 84 89 82 95 8A 8F 93 00 BE BE BE BE 89 8E 94 85 92 92 95 90 94 8F 92 01 BE BE BE BE 84 85 8C BE 93 89 93 94 85 8D 81 00 86 89 83 88 81 F1 86 89 83 88 85 92 8F 00 8E 8F BE 85 8E 83 8F 8E 93 92 81 84 8F 93 00
;        RELOJ ~~~~~CALENDARIO ~~~~~CALCULADORA ~~~~~~~AGENDA ~~~~~CHEQUEO~DE￁~~~~~~DELETREO ~~~~~~~JUEGOS ~~~~~~~DIBUJO ~~~~PROGRAMACION￁~~~~~~~BASICA ~~~~~~~~PIANO ~~~PROCESADOR~DE￁~~~~~~PALABRAS ~~~DICCIONARIO~DE￁~~~~~~DIBUJOS ~~~~INTERRUPTOR￁~~~~DEL~SISTEMA FICHA±FICHERO NO~ENCONSRADOS

; Encoding:
; Add +64 (0x40) to ASCII values for most letters
; Space      = 0xBE
;     /      = 0xF1
; String end = 0x00


; Data from 630 to 733 (260 bytes)
_string_table_630_:
db $BE, $BE, $BE, $BE, $BE, $BE, $BE, $92, $85, $8C, $8F, $8A, $00, $BE, $BE, $BE
db $BE, $BE, $83, $81, $8C, $85, $8E, $84, $81, $92, $89, $8F, $00, $BE, $BE, $BE
db $BE, $BE, $83, $81, $8C, $83, $95, $8C, $81, $84, $8F, $92, $81, $00, $BE, $BE
db $BE, $BE, $BE, $BE, $BE, $81, $87, $85, $8E, $84, $81, $00, $BE, $BE, $BE, $BE
db $BE, $83, $88, $85, $91, $95, $85, $8F, $BE, $84, $85, $01, $BE, $BE, $BE, $BE
db $BE, $BE, $84, $85, $8C, $85, $94, $92, $85, $8F, $00, $BE, $BE, $BE, $BE, $BE
db $BE, $BE, $8A, $95, $85, $87, $8F, $93, $00, $BE, $BE, $BE, $BE, $BE, $BE, $BE
db $84, $89, $82, $95, $8A, $8F, $00, $BE, $BE, $BE, $BE, $90, $92, $8F, $87, $92
db $81, $8D, $81, $83, $89, $8F, $8E, $01, $BE, $BE, $BE, $BE, $BE, $BE, $BE, $82
db $81, $93, $89, $83, $81, $00, $BE, $BE, $BE, $BE, $BE, $BE, $BE, $BE, $90, $89
db $81, $8E, $8F, $00, $BE, $BE, $BE, $90, $92, $8F, $83, $85, $93, $81, $84, $8F
db $92, $BE, $84, $85, $01, $BE, $BE, $BE, $BE, $BE, $BE, $90, $81, $8C, $81, $82
db $92, $81, $93, $00, $BE, $BE, $BE, $84, $89, $83, $83, $89, $8F, $8E, $81, $92
db $89, $8F, $BE, $84, $85, $01, $BE, $BE, $BE, $BE, $BE, $BE, $84, $89, $82, $95
db $8A, $8F, $93, $00, $BE, $BE, $BE, $BE

; Message text displayed before running a cart from the cart slot
; (the text is rendered to the window layer and the window scrolls
;  up and then it tries to boot the cart)
;
; INTERRUPTOR DEL SISTEMA
;   Raw ROM: at:0x0718 (Maybe starting 0713 or 0714?)
;            TEXT :I  N  T  E  R  R  U  P  T  O  R  \n             D  E  L     S  I  S  T  E  M  A
;         RAW-ROM :89 8E 94 85 92 92 95 90 94 8F 92 01 BE BE BE BE 84 85 8C BE 93 89 93 94 85 8D 81 00
db $89, $8E, $94, $85, $92, $92, $95, $90, $94, $8F, $92, $01, $BE, $BE, $BE, $BE
db $84, $85, $8C, $BE, $93, $89, $93, $94, $85, $8D, $81, $00


; Message text displayed when the user tries to run a cart
; from the cart slot, but there is no cart detected in it
;
; FICHA/FICHERO NO ECONSRADOS
;   Raw ROM: at:0x0734
;             TEXT:F  I  C  H  A  /  F  I  C  H  E  R  O  \n N  O        E  C  O  N  S  R  A  D  O  S
;         RAW-ROM :86 89 83 88 81 F1 86 89 83 88 85 92 8F 00 8E 8F BE 85 8E 83 8F 8E 93 92 81 84 8F 93 00
; Data from 734 to 751 (30 bytes)
_string_message__no_cart_in_slot_to_run__734_:
db $86, $89, $83, $88, $81, $F1, $86, $89, $83, $88, $85, $92, $8F, $00,
db $8E, $8F, $BE, $85, $8E, $83, $8F, $8E, $93, $92, $81, $84, $8F, $93, $00
db $C9

vram_init__752_:
    ld   a, $00
    ld   [_rombank_currrent__C8D7_], a
    ldh  [rLCDC], a  ; clear all LCDC bits

        ld   hl, _TILEDATA8000  ; $8000
    _loop_clear_vram_all_tile_patterns__75C_:
        xor  a
        ldi  [hl], a
        ld   a, h
        cp   HIGH(_TILEMAP0)  ; $98
        jr   nz, _loop_clear_vram_all_tile_patterns__75C_

    ; hl now at $9800
    ; Fill Tile Map 1 with tile id $BE
    _loop_fill_tile_map0__763_:
        ld   a, $BE
        ldi  [hl], a
        ld   a, h
        cp   HIGH(_TILEMAP1) ; $9C
        jr   nz, _loop_fill_tile_map0__763_

    ; Fill RAM from shadow_oam_base__RAM_C800_ -> _RAM_C8BF_ ($A0 / 160 bytes)
        ld   hl, shadow_oam_base__RAM_C800_
        ld   b, SHADOW_OAM_SZ ; $A0
    _LABEL_770_:
        xor  a  ; This doesn't need to be re-zeroed each loop iteration...
        ldi  [hl], a
        dec  b
        jr   nz, _LABEL_770_

        ; Turn screen/etc off
        ldh  [rLCDC], a
        nop
        nop
        nop
        nop

        ; LCD on
        ld   a, (LCDCF_ON | LCDCF_BGON | LCDCF_WIN9C00) ; $C8
        ldh  [rLCDC], a

        ; Clear OAM via cleared shadow OAM
        ; TODO: Is there no bus conflict when oam DMA is run from ROM on the Quique with interrupts disabled?
        call _oam_dma_routine_in_ROM__7E3_

        ; Set the BG & Sprite color palettes
        ld   a, COLS_0WHT_1LGRY_2DGRY_3BLK  ; $E4
        ldh  [rOBP0], a
        ldh  [rBGP], a
        ld   a, COLS_0BLK_1DGRY_2LGRY_3WHT ; $1B
        ldh  [rOBP1], a

        ; Init Window and BG Map Scroll X
        ld   a, $07
        ldh  [rWX], a
        ld   a, $FF    ; Why not 0 for SCX?
        ldh  [rSCX], a

        ; Load several functions into RAM so they persist across 32K sized bank switches
        ; Mainly memcopy and bank switching related


        ld   hl, STARTOF("wram_functions_start_c900")
        ; HL at 0x9C00
        ; _memcopy_in_RAM__C900_
        ld   de, _memcopy__7D3_
        call _memcpy_32_bytes__7CA_

        ; HL now at 0x9C20
        ; (_switch_bank_jump_hl_RAM__C920_)
        ld   de, _switch_bank_jump_hl_ROM__82C_
        call _memcpy_32_bytes__7CA_

        ; HL now at 0x9C40
        ; (_switch_bank_return_to_saved_bank_RAM__C940_)
        ld   de, _switch_bank_return_to_saved_ROM__841_
        call _memcpy_32_bytes__7CA_

        ; HL now at 0x9C60
        ; (_switch_bank_memcopy_hl_to_de_len_bc_RAM__C960_)
        ld   de, _switch_bank_memcopy_hl_to_de_len_bc_ROM__7EF_
        call _memcpy_32_bytes__7CA_

        ; HL now at 0x9C80
        ld   de, _switch_bank_read_byte_at_hl_ROM__80C_
        call _memcpy_32_bytes__7CA_

        ; Load OAM DMA Copy routine into HRAM
        ld   hl, _oam_dma_routine_in_HRAM__FF80_
        ld   de, _oam_dma_routine_in_ROM__7E3_ ; $07E3
        call _memcpy_32_bytes__7CA_

        ; Clear 42 bytes of RAM used for OAM slot management
        ld   a, OAM_SLOT_EMPTY
        ld   b, (OAM_USAGE_SZ + 2) ; $2A ; TODO: Why +2 here what is at _RAM_C8C8_ and C9?
        ld   hl, oam_slot_usage__RAM_C8A0_
        .loop_oam_clear__7C5_:
            ldi  [hl], a
            dec  b
            jr   nz, .loop_oam_clear__7C5_
        ret

; Always copies 32 bytes
; Source in DE
; Dest in HL
_memcpy_32_bytes__7CA_:
    ld   b, $20
_memcpy_32bytes_loop_7CC_:
    ld   a, [de]
    ldi  [hl], a
    inc  de
    dec  b
    jr   nz, _memcpy_32bytes_loop_7CC_
    ret

; Memcopy
; - Source   : DE
; - Dest     : HL
; - Num Bytes: BC
; Gets copied to and run from _memcopy_in_RAM__C900_
_memcopy__7D3_:
    ld   a, [de]
    ldi  [hl], a
    inc  de
    dec  bc
    ld   a, b
    or   c
    jr   nz, _memcopy__7D3_
    ret

; TODO: does excecution ever reach here?
    ldh  a, [rLCDC]
    or   LCDCF_ON  ; $80
    ldh  [rLCDC], a
    ret

; Gets copied to and run from _oam_dma_routine_in_HRAM__FF80_
_oam_dma_routine_in_ROM__7E3_:
    di
    ld   a, HIGH(shadow_oam_base__RAM_C800_)  ; $C8
    ldh  [rDMA], a
    ld   a, $28  ; Wait 160 nanosec
    _oam_dma_copy_wait_loop_7EA_:
        dec  a
        jr   nz, _oam_dma_copy_wait_loop_7EA_
        ei
        ret


SECTION "rom0_bankswitch_functions_07EF", ROM0[$07EF]
include "bankswitch_functions.asm"

SECTION "rom0_after_bankswitch_functions_0851", ROM0[$0851]


_LABEL_851_:
        ld   a, [maybe_vram_data_to_write__RAM_C8CC_]
        dec  a
        sla  a
        sla  a
        ld   l, a
        ld   h, $C8
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        add  [hl]
        ld   e, a
        ld   [hl], a
        inc  hl
        ld   a, [_tilemap_pos_x__RAM_C8CB_]
        add  [hl]
        ld   d, a
        ld   [hl], a
        ld   a, $00
        ret

_LABEL_86C_:
        ld   a, $02
        ret


; Locates a free OAM slot, copies into the shadow OAM
;
; - Copies from: _tilemap_pos_y__RAM_C8CA_
; - ? Maybe Returns OAM slot number in: B
; - ? Returns $00 in : A
;
; Destroys A, BC, DE, HL
oam_find_slot_and_load_into__86F:
    ld   c, $00
    ld   hl, oam_slot_usage__RAM_C8A0_

    ; Find first empty OAM slot
    .loop_find_empty_slot_874_:
        inc  c
        ldi  a, [hl]
        cp   OAM_SLOT_EMPTY ; $00
        jr   nz, .loop_find_empty_slot_874_

    ; Mark the newly found slot as used
    dec  hl
    ld   a, OAM_SLOT_USED  ; $FF
    ld   [hl], a

    ; Index into the Shadow OAM by 4 x OAM Slot number
    ; Re-uses H = $C8 for that
    ld   a, c
    dec  a
    sla  a
    sla  a
    ld   l, a
    ld   de, _tilemap_pos_y__RAM_C8CA_  ; TODO: Maybe label for this is wrong?
    ld   b, $04
    ; Copy 4 bytes from TODO into the Shadow OAM slot
    ; Presumably sprite data
    .loop_shadow_oam_copy__88A_:
        ld   a, [de]
        ldi  [hl], a
        inc  de
        dec  b
        jr   nz, .loop_shadow_oam_copy__88A_

    ; TODO: Is this some kind of oam slot copy increment for multiple sprites?
    ld   a, [_RAM_C8C8_]    ; _RAM_C8C8_ = $C8C8
    inc  a
    ld   [_RAM_C8C8_], a    ; _RAM_C8C8_ = $C8C8
    ; Maybe return slot number in B?
    ld   b, c
    ld   a, $00
    ret


; Frees an OAM slot and clears related bytes in shadow OAM
;
; Destroys A, DE, HL
oam_free_slot_and_clear__89B_:
    ; Index into the Shadow OAM by 4 x maybe_vram_data_to_write__RAM_C8CC_
    ld   a, [maybe_vram_data_to_write__RAM_C8CC_]  ; TODO: Maybe var needs more general name
    cp   $00
    jr   z,     .done_return__8C3_
    dec  a
    sla  a
    sla  a
    ld   l, a
    ld   h, HIGH(shadow_oam_base__RAM_C800_)  ; $C8

    ; Clear out the Shadow OAM entry
    ld   a, $00
    ldi  [hl], a
    ldi  [hl], a
    ldi  [hl], a
    ldi  [hl], a

    ; Now index into the slot manager and free the entry
    ld   de, oam_slot_usage__RAM_C8A0_
    ld   a, [maybe_vram_data_to_write__RAM_C8CC_]
    dec  a
    add  e
    ld   e, a
    ld   a, OAM_SLOT_EMPTY  ; $00
    ld   [de], a

    ; TODO: Is this some kind of oam slot copy increment for multiple sprites?
    ld   a, [_RAM_C8C8_]    ; _RAM_C8C8_ = $C8C8
    dec  a
    ld   [_RAM_C8C8_], a    ; _RAM_C8C8_ = $C8C8

    .done_return__8C3_:
    ret


; Load a 20x18 Tile Map from DE into the start of Map VRAM
;
; - Expects to be called with Screen OFF
;
; - Tilemap Select in       : A (0 = _TILEMAP0, 1 = _TILEMAP1)
; - Source Tile Map Data in : DE
write_tilemap_20x18_from_de_mapselect_in_a__8c4_:
    ld   b, _TILEMAP_SCREEN_HEIGHT  ; $12
    ld   hl, _TILEMAP0  ; $9800
    cp   $00
    jr   z, .loop_screen_top_to_bottom__8D0_
    ld   hl, _TILEMAP1  ; $9C00

    .loop_screen_top_to_bottom__8D0_:
        ld   c, _TILEMAP_SCREEN_WIDTH  ; $14

        .loop_screen_row_load__8D2_:
            ld   a, [de]
            ldi  [hl], a
            inc  de
            dec  c
            jr   nz, .loop_screen_row_load__8D2_

        ; Skip remainder of current Tile Map row down to next line
        ld   a, (_TILEMAP_WIDTH - _TILEMAP_SCREEN_WIDTH); $0C
        add  l
        ld   l, a
        ld   a, $00
        adc  h
        ld   h, a

        dec  b
        jr   nz, .loop_screen_top_to_bottom__8D0_

    ldh  a, [rLCDC]
    or   LCDCF_ON  ; $80
    ldh  [rLCDC], a
    ret


; Writes byte to Tile Map 0 VRAM at preset address X,Y
;
; - Byte to write in :A
; - Tilemap X,Y to write in global vars
;
write_tilemap0_byte_in_a_preset_xy__8EA_:
    push af
    push bc
    push de
    push hl
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    ld   a, SELECT_TILEMAP_0  ; $00
    call write_tilemap_in_a_preset_xy_and_data_8FB_
    pop  hl
    pop  de
    pop  bc
    pop  af
    ret


; Writes to Tile Map VRAM at preset address X,Y with preset byte
;
; - Tilemap select [0/1 = Tilemap0/1] in :A
; - Tilemap X,Y and byte to write in global vars
;
; - Destroys: A, DE, HL
write_tilemap_in_a_preset_xy_and_data_8FB_:
    ; Select which between Tilemap 0 or 1
    ld   hl, _TILEMAP0  ; $9800
    cp   $00
    jr   z, _tilemap_sel_done__905_
    ld   hl, _TILEMAP1  ; $9C00

    _tilemap_sel_done__905_:
        ; Calculate vram address into Tile Map for X, Y in global vars
        ; First add X
        ld   a, $00
        ld   d, a
        ld   a, [_tilemap_pos_x__RAM_C8CB_]
        ld   e, a
        add  hl, de

        ; Then add Y (upshift << 5 to multiply by 32)
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        dec  a
        ld   e, a
        REPT 5
            sla  e
            rl   d
        ENDR
        add  hl, de

        ; HL now has X,Y offset into Tile Map VRAM
        ; Write byte to it and return
        ld   a, [maybe_vram_data_to_write__RAM_C8CC_]
        ld   [hl], a
        ret


; Waits until VBlank line 145
;
; - Temporarily turns off VBL ISR while doing that
; - Returns immediately if screen is off
wait_until_vbl__92C_:
    ; If screen is ON then continue
    ; If the screen is OFF then return
    ldh  a, [rLCDC]
    bit  LCDCF_B_ON, a  ; bit 7
    jr   nz, _wait_until_hblank__933_
    ret

    _wait_until_hblank__933_:
        ; wait until Mode 0: HBlank
        ldh  a, [rSTAT]
        and  STATF_LCD  ; $03 (STATF LCD Status Mask)
        jr   nz, _wait_until_hblank__933_

        ; Save state of Interrupt enables
        ; Then turn off VBlank Interrupt
        ldh  a, [rIE]
        ldh  [_rIE_saved__RAM_FFA1_], a
        res  IEF_B_VBLANK, a  ; bit 0
        ldh  [rIE], a

    ; Why line 145 instead of 144?
    _wait_until_line_145__941_:
        ldh  a, [rLY]
        cp   LY_VBL_SECOND_LINE  ; $91
        jr   nz, _wait_until_line_145__941_

        ; Restore previous state of Interrupt enables
        ldh  a, [_rIE_saved__RAM_FFA1_]
        ldh  [rIE], a
        ret


display_screen_off__94C_:
    ldh  a, [rLCDC]
    and  ~LCDCF_ON  ; $7F
    ldh  [rLCDC], a
    ret

_LABEL_953_:
    ld   a, [maybe_vram_data_to_write__RAM_C8CC_]
    dec  a
    sla  a
    sla  a
    ld   l, a
    ld   h, $C8
    ldi  a, [hl]
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    ldi  a, [hl]
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ret

; TODO: _window_scroll_up ... AND? ...  __967_
; Waits for timer...
_LABEL_967_:
    ld   a, 160 ; Start Window top position at Y line 160 ; $A0

    window_scroll_up_loop__969_:
        ldh  [rWY], a
        ei
        call timer_wait_tick_AND_TODO__289_
        di
        ldh  a, [rWY]
        and  a
        jr   z, _LABEL_979_
        sub  $08
        jr   window_scroll_up_loop__969_

_LABEL_979_:
    ret


; Startup Init (ISR, audio, palettes, display)
general_init__97A_:
    ; Timer and Enable VBlank interrupts
    ld   a, (IEF_TIMER | IEF_VBLANK)  ; $05
    ldh  [rIF], a
    ldh  [rIE], a
    ; Serial Init
    xor  a
    ldh  [rSB], a
    ldh  [rSC], a
    ldh  [rAUDENA], a

    ; Turn on Screen
    ldh  [rLCDC], a
    ld   a, LCDCF_ON  ; $80
    ldh  [rLCDC], a
    ; Set up BG Colors
    ld   a, COLS_0WHT_1LGRY_2DGRY_3BLK  ; $E4
    ldh  [rBGP], a
    ldh  [rOBP0], a
    ld   a, COLS_0BLK_1DGRY_2LGRY_3WHT  ; $1B
    ldh  [rOBP1], a

    ; Set up Audio Wave channel and fill half of it with 0x55
    xor  a
    ldh  [rAUD3ENA], a
    ld   a, $FF
    ldh  [rAUD3LEN], a
    ld   a, $55
    ld   bc, ($08 << 8) | LOW(_AUD3WAVERAM_LAST) ; | _PORT_3F_
    .loop_fill_ch3_wave_ram_LABEL__9A3_:
        ldh  [c], a
        dec  c
        dec  b
        jr   nz, .loop_fill_ch3_wave_ram_LABEL__9A3_
    ld   hl, rAUDENA
    ld   a, AUDENA_ON  ; $80
    ld  [hl-], a
    ; Note: This will have incorrect address on Game Boy (should be rAUDVOL, *not* rAUDTERM)
    ; Unless patched, GB now points to the wrong audio register due to address reshuffling and the LD HL-
    ; On MegaDuck: HL now points to rAUDVOL (0xFF44)
    ; On GB      : HL *incorrectly* points to rAUDTERM (0xFF25)
    ld   [hl], (AUDVOL_LEFT_MAX | AUDVOL_RIGHT_MAX)  ; $77  ; Set rAUDVOL to Max Left/Right volume, with VIN off for left and right
    nop
    nop
    nop
    nop
    xor  a
    ld   [_RAM_CC02_], a    ; _RAM_CC02_ = $CC02
    ld   [_RAM_CC00_], a    ; _RAM_CC00_ = $CC00
    ld   [_RAM_CC01_], a    ; _RAM_CC01_ = $CC01
    ld   a, (AUDLEN_DUTY_12_5 | $28)  ; $28  ; Initial timer length of 40
    ldh  [rAUD1LEN], a
    ldh  [rAUD2LEN], a

    ; Timer init
    ; Start timer and use default 4KHz freq
    ;
    ; Overflows/Triggers interrupt every 201 ticks (0x100 - 0x37) = 201
    ; 4096 Hz / (201) = ~20.378Hz, roughly every 3rd frame
    ;
    ld   a, TIMER_DIV_TO_20HZ ; $37
    ldh  [rTMA], a
    ldh  [rTIMA], a
    ld   a, (TACF_START | TACF_4KHZ); $04
    ldh  [rTAC], a
    ret


SECTION "rom0_serial_io_9CF", ROM0[$09CF]
include "serial_io.asm"

SECTION "rom0_after_serial_io_0BD6", ROM0[$0BD6]



; Delay loop to wait 0.25 msec (used by serial link function, maybe others)
;
; TODO: Is this a long enough delay? Given so far it sends with serial speed 8192 Hz, 1 KB/s
;
; Delay approx: (1000 msec / 59.7275 GB FPS) * (1058 M-Cycles delay / 70224 one frame M-Cycles) = 0.25 msec
; or (1058 M-Cycles delay / 456 M-Cycles per line) = ~2.3 lines
delay_quarter_msec__BD6_:
    push af
    ld   a, $46
    _loop_delay_BD9_:
        push af
        ld   a, [serial_tx_data__RAM_D023_] ; Why? A useless read? Or is something else going on
        pop  af
        dec  a
        jr   nz, _loop_delay_BD9_
        pop  af
        ret

; Data from BE3 to C8C (170 bytes)
; Some kind of table with values incrementing from 0x0022 -> 0x07FF
; Used by code at _LABEL_37D_
_DATA_BE3_:
db $00, $22, $00, $97, $00, $FF, $01, $72, $01, $C4, $02, $1F, $02, $80, $02, $C8
db $03, $15, $03, $5A, $03, $98, $03, $D8, $04, $19, $04, $52, $04, $86, $04, $B9
db $04, $E7, $05, $14, $05, $3D, $05, $64, $05, $8B, $05, $AD, $05, $CF, $05, $EE
db $06, $0D, $06, $28, $06, $43, $06, $5B, $06, $74, $06, $89, $06, $9F, $06, $B2
db $06, $C5, $06, $D7, $06, $E7, $06, $F7, $07, $06, $07, $14, $07, $21, $07, $2E
db $07, $3A, $07, $45, $07, $51, $07, $59, $07, $63, $07, $6C, $07, $74, $07, $7C
db $07, $83, $07, $8A, $07, $91, $07, $97, $07, $9D, $07, $A3, $07, $A8, $07, $AD
db $07, $B2, $07, $B6, $07, $BA, $07, $BE, $07, $CB, $07, $CE, $07, $D1, $07, $D4
db $07, $D6, $07, $D9, $07, $DB, $07, $DD, $07, $DF, $07, $E1, $07, $E3, $07, $E4
db $07, $E6, $07, $E8, $07, $E9, $07, $EA, $07, $EB, $07, $EC, $07, $EE, $07, $EF
db $07, $F0, $07, $F1, $07, $F2, $07, $F3, $07, $FF


SECTION "rom0_keyboard_C8D", ROM0[$0C8D]
include "keyboard.asm"

SECTION "rom0_after_keyboard_0E9C", ROM0[$0E9C]


; TODO: Maybe this is all data below
_LABEL_E9C_:
    inc  hl
_LABEL_E9D_:
    inc  hl
    jr   _LABEL_E4C_

_LABEL_EA0_:
    dec  hl
    and  c
; Data from EA2 to EA2 (1 bytes)
db $DD

_LABEL_EA3_:
    dec  hl
    add  c
    sub  $2B
    and  l
    sbc  $2B
    add  l
    rst  $10    ; _RST_10_
    dec  hl
    xor  c
    rst  $18    ; _RST_18_
    dec  hl
    adc  c
    ret  c
    dec  hl
    xor  a
    ldh  [rAUD3LEN], a
    adc  a
    reti

; Reverting this to data (it had a jump to the middle of tile data)
_LABEL_EB8_:
db $2B, $B5, $E1, $2B, $95, $DA, $00


KEYCODE_TO_SYS_CHAR_LUT__0EBF_:
; LUT for translating keyboard key scan codes to system character values
include "inc/keycode_to_syschar_LUT.inc"


; Maps SYS_CHAR format symbol keys to their matching SHIFT equivalent on the keyboard
; Data from F2F to 2FFF (8401 bytes)
SYS_CHAR_SYMBOLS_SHIFT_LUT__F2F_:
include "inc/syschar_symbol_shift_LUT.inc"
SYS_CHAR_SYMBOLS_SHIFT_LUT_AFTER__F45_:
DEF SYS_CHAR_SYMBOLS_SHIFT_LUT__LEN  EQU ((SYS_CHAR_SYMBOLS_SHIFT_LUT_AFTER__F45_ - SYS_CHAR_SYMBOLS_SHIFT_LUT__F2F_) / 2)


_DATA_F45_:
db $1F, $04, $24, $08, $1F, $04, $21, $04, $1F, $04
db $1D, $04, $1F, $04, $1C, $04, $1F, $04, $24, $08, $1F, $04, $21, $04, $1F, $04
db $1D, $04, $1F, $04, $1C, $04, $1F, $04, $24, $08, $1F, $04, $21, $04, $1F, $04
db $1D, $04, $1F, $04, $1C, $04, $1F, $04, $24, $08, $1F, $04, $21, $04, $1F, $04
db $1D, $04, $1F, $04, $1C, $08, $FF, $24, $04, $24, $04, $28, $04, $2B, $04, $2B
db $08, $2B, $04, $2B, $08, $28, $04, $28, $08, $24, $04, $24, $04, $28, $04, $2B
db $04, $2B, $08, $2B, $04, $2B, $08, $29, $04, $29, $08, $23, $04, $23, $04, $26
db $04, $29, $04, $2D, $08, $2D, $04, $2D, $08, $29, $04, $29, $08, $23, $04, $23
db $04, $26, $04, $29, $04, $2D, $08, $2D, $04, $2D, $08, $28, $04, $28, $0C, $FF
; Extra bytes from somewhere?
db $1C, $04, $1D, $04, $1F, $08, $24, $08, $23, $04, $23, $04, $21, $04, $21, $04
db $1F, $04, $1F, $04, $21, $04, $23, $04, $24, $04, $1F, $04,
db $1C, $04, $1D, $04
db $1F, $08, $24, $08, $23, $04, $23, $04, $21, $04, $21, $04, $1F, $04, $1F, $04
db $21, $04, $23, $04, $24, $08, $FF, $26, $04, $28, $08, $28, $04, $2A, $04, $28
db $04, $2A, $04, $2B, $04, $26, $08, $54, $04, $26, $04, $26, $04, $28, $04, $28
db $04, $28, $04, $2A, $04, $28, $04, $2A, $04, $2B, $04, $26, $08, $54, $04, $26
db $04, $26, $04, $24, $04, $24, $04, $24, $04, $28, $04, $26, $04, $24, $04, $23
db $0C, $26, $04, $2B, $04, $2D, $04, $2F, $08, $2F, $04, $2D, $08, $2D, $04, $2B
db $0C, $FF, $1F, $09, $21, $03, $1F, $06, $1C, $12, $1F, $09, $21, $03, $1F, $06
db $1C, $12, $26, $0C, $26, $06, $23, $12, $24, $0C, $24, $06, $1F, $12, $21, $0C
db $21, $06, $24, $09, $23, $03, $21, $06, $1F, $09, $21, $03, $1F, $06, $1C, $12
db $21, $0C, $21, $06, $24, $09, $23, $03, $21, $06, $1F, $09, $21, $03, $1F, $06
db $1C, $12, $26, $0C, $26, $06, $29, $09, $26, $03, $23, $06, $24, $12, $28, $12
db $24, $09, $1F, $03, $1C, $06, $1F, $09, $1D, $03, $1A, $06, $18, $12, $FF, $24
db $04, $24, $02, $24, $02, $24, $04, $23, $02, $24, $02, $26, $06, $23, $02, $1F
db $08, $26, $04, $26, $02, $28, $02, $29, $04, $28, $02, $26, $02, $28, $06, $26
db $02, $24, $08, $24, $04, $24, $02, $24, $02, $24, $04, $23, $02, $24, $02, $26
db $06, $23, $02, $1F, $08, $26, $04, $26, $02, $28, $02, $29, $04, $28, $02, $26
db $02, $28, $06, $26, $02, $24, $08, $FF, $1A, $02, $1F, $02, $1F, $02, $1F, $02
db $23, $02, $1F, $04, $1F, $04, $23, $02, $1F, $02, $23, $02, $1F, $02, $1A, $04
db $54, $02, $1A, $02, $1F, $02, $1F, $02, $1F, $02, $23, $02, $1F, $04, $1F, $04
db $1A, $02, $1A, $02, $1A, $02, $1A, $02, $1F, $04, $54, $02, $1A, $02, $1F, $04
db $21, $04, $1F, $04, $54, $02, $1A, $02, $1F, $02, $1F, $02, $1F, $02, $21, $02
db $1F, $04, $54, $02, $1A, $02, $1F, $02, $1F, $02, $1F, $02, $1F, $02, $21, $04
db $21, $02, $21, $02, $1A, $04, $1C, $02, $1E, $02, $1F, $04, $FF, $24, $03, $23
db $01, $23, $04, $54, $04, $23, $03, $24, $01, $24, $04, $54, $04, $24, $03, $28
db $01, $2B, $04, $2B, $03, $2D, $01, $2B, $03, $29, $01, $28, $04, $24, $04, $24
db $03, $23, $01, $23, $04, $54, $04, $23, $03, $24, $01, $24, $04, $54, $04, $24
db $03, $28, $01, $2B, $04, $2B, $04, $2B, $04, $24, $0C, $FF, $28, $04, $28, $02
db $28, $02, $29, $02, $29, $02, $29, $02, $2B, $04, $2B, $02, $54, $0C, $28, $04
db $28, $02, $28, $02, $29, $02, $29, $02, $29, $02, $2B, $06, $54, $0E, $29, $02
db $29, $02, $29, $02, $29, $04, $29, $04, $28, $04, $24, $0C, $54, $02, $29, $02
db $29, $02, $29, $02, $29, $04, $29, $04, $28, $04, $24, $04, $24, $04, $24, $04
db $26, $04, $23, $04, $26, $04, $29, $04, $28, $04, $28, $04, $24, $04, $21, $04
db $1F, $04, $FF,

; 128 Tiles of Main Menu Icons and Cursor, etc
; Loaded to _TILEDATA9000 during startup
; This tile data is in sets of 24x24 pixel icons (9 sequential 8x8 tiles)
gfx_tile_data__main_menu_icons__11F2_:
INCBIN "res/tile_data_0x11f2_2048_bytes_main_menu_icons.2bpp"


_DATA_19F2_:
db $10, $10, $F0, $F0, $20, $20, $E0, $E0, $40, $40, $C0, $C0, $00, $00
db $00, $00, $00, $F8, $00, $E0, $00, $F0, $00, $B8, $00, $9C, $00, $0E, $00, $07
db $00, $03, $00, $C0, $00, $F0, $00, $68, $00, $74, $00, $3A, $00, $1D, $00, $0E
db $00, $07, $00, $C3, $00, $FF, $00, $66, $00, $5A, $00, $5A, $00, $66, $00, $FF
db $00, $C3, $F8, $F8, $E0, $E0, $F0, $F0, $B8, $B8, $9C, $9C, $0E, $0E, $07, $07
db $03, $03, $C0, $C0, $F0, $F0, $68, $68, $74, $74, $3A, $3A, $1D, $1D, $0E, $0E
db $07, $07, $C3, $C3, $FF, $FF, $66, $66, $5A, $5A, $5A, $5A, $66, $66, $FF, $FF
db $C3, $C3, $F8, $00, $E0, $00, $F0, $00, $B8, $00, $9C, $00, $0E, $00, $07, $00
db $03, $00, $C0, $00, $F0, $00, $68, $00, $74, $00, $3A, $00, $1D, $00, $0E, $00
db $07, $00, $C3, $00, $FF, $00, $66, $00, $5A, $00, $5A, $00, $66, $00, $FF, $00
db $C3, $00

; Data from 1A92 to 2669 (3032 bytes)
_DATA_1A92_:
db $C8, $C8, $C4
ds 14, $C5
db $C6, $C8, $C8, $C8, $C8, $C7, $00, $01, $02, $03, $04, $05, $06, $07, $08, $09
db $0A, $0B, $0C, $0D, $C9, $C8, $C8, $C8, $C8, $C7, $0E, $0F, $10, $11, $12, $13
db $14, $15, $16, $17, $18, $19, $1A, $1B, $C9, $C8, $C8, $C8, $C8, $C7, $1C, $1D
db $1E, $1F, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $C9, $C8, $C8, $C8
db $C8, $C7, $2A, $2B, $2C, $2D, $2E, $2F, $30, $31, $32, $33, $34, $35, $36, $37
db $C9, $C8, $C8, $C8, $C8, $C7, $38, $39, $3A, $3B, $3C, $3D, $3E, $3F, $40, $41
db $42, $43, $44, $45, $C9, $C8, $C8, $C8, $C8, $C7, $46, $47, $48, $49, $4A, $4B
db $4C, $4D, $4E, $4F, $50, $51, $52, $53, $C9, $C8, $C8, $C8, $C8, $C7, $54, $55
db $56, $57, $58, $59, $5A, $5B, $5C, $5D, $5E, $5F, $60, $61, $C9, $C8, $C8, $C8
db $C8, $C7, $62, $63, $64, $65, $66, $67, $68, $69, $6A, $6B, $6C, $6D, $6E, $6F
db $C9, $C8, $C8, $C8, $C8, $C7, $70, $71, $72, $73, $74, $75, $76, $77, $78, $79
db $7A, $7B, $7C, $7D, $C9, $C8, $C8, $C8, $C8, $C7, $7E, $7F, $80, $81, $82, $83
db $84, $85, $86, $87, $88, $89, $8A, $8B, $C9, $C8, $C8, $C8, $C8, $C7, $8C, $8D
db $8E, $8F, $90, $91, $92, $93, $94, $95, $96, $97, $98, $99, $C9, $C8, $C8, $C8
db $C8, $C7, $9A, $9B, $9C, $9D, $9E, $9F, $A0, $A1, $A2, $A3, $A4, $A5, $A6, $A7
db $C9, $C8, $C8, $C8, $C8, $C7, $A8, $A9, $AA, $AB, $AC, $AD, $AE, $AF, $B0, $B1
db $B2, $B3, $B4, $B5, $C9, $C8, $C8, $C8, $C8, $C7, $B6, $B7, $B8, $B9, $BA, $BB
db $BC, $BD, $BE, $BF, $C0, $C1, $C2, $C3, $C9, $C8, $C8, $C8, $C8, $CA
ds 14, $CB
db $CC, $C8, $C8, $C8, $C8, $C8, $C8, $C8, $D5, $D6, $D1, $C8, $C8, $C8, $D5, $D6
db $CE
ds 11, $C8
db $D7, $D8, $C8, $C8, $C8, $C8, $D7, $D8, $C8, $C8, $C8, $C8, $C8, $C8, $C8
ds 29, $00
db $FF, $FF, $FF
ds 29, $00
db $FF, $FF, $FF
ds 28, $00
db $FF, $FF, $2F, $1F
ds 28, $00
db $A0, $C0, $FF, $FF
ds 24, $00
db $E8, $F0, $7E, $FF, $17, $0F
ds 30, $00
db $F4, $F8, $BF, $7F
ds 22, $00
db $74, $78, $3F, $7F, $0B, $07
ds 30, $00
db $E0, $F0, $78, $FC, $0F, $1F
ds 18, $00
db $60, $70, $38, $7C, $0E, $1F, $03, $07, $01
ds 29, $00
db $C0, $E0, $F0, $F8, $1C, $3E, $07, $0F
ds 16, $00
db $30, $38, $1C, $3E, $07, $0F, $01, $03
ds 28, $00
db $80, $00, $E0, $C0, $60, $F0, $38, $7C, $0F, $1E, $03, $07
ds 12, $00
db $10, $18, $18, $1C, $0E, $0E, $03, $07, $01, $03
ds 30, $00
db $C0, $C0, $60, $F0, $38, $38, $0C, $1C, $06, $0E, $03, $03, $00, $00, $00, $00
db $00, $00, $00, $00, $08, $00, $08, $0C, $0C, $0E, $07, $07, $03, $01, $01
ds 27, $00
db $80, $00, $80, $C0, $C0, $E0, $60, $70, $30, $38, $18, $1C, $0C, $0E, $06, $07
db $03, $03, $00, $00, $00, $00, $00, $00, $00, $04, $06, $06, $07, $03, $03, $01
db $00, $01
ds 28, $00
db $80, $80, $80, $C0, $C0, $E0, $60, $70, $30, $38, $18, $1C, $0C, $0E, $06, $07
db $03, $03, $01, $01, $00, $00, $00, $00, $00, $02, $03, $03, $01, $03, $00, $01
ds 28, $00
db $80, $80, $C0, $C0, $40, $E0, $60, $70, $30, $70, $30, $38, $18, $1C, $0C, $0C
db $06, $0E, $06, $07, $03, $03, $01, $01
ds 35, $00
db $80, $80, $C0, $C0, $C0, $40, $E0, $60, $60, $20, $70, $30, $30, $10, $38, $18
db $18, $0C, $0C, $04, $0E, $06, $06, $02, $07, $03, $03, $01, $01
ds 33, $00
db $40, $40, $60, $60, $60, $20, $70, $30, $30, $10, $38, $18, $18, $18, $18, $08
db $1C, $0C, $0C, $04, $0E, $06, $06, $02, $07, $03, $03, $01, $03, $01, $01
ds 32, $00
db $10, $10, $10, $18, $18, $18, $18, $18, $08, $1C, $0C, $0C, $0C, $0C, $0C, $0C
db $04, $0E, $06, $06, $06, $06, $02, $07, $03, $03, $03, $03, $01, $03, $01, $01
ds 32, $00
db $0C, $0C, $0C, $0C, $0C, $0C, $06, $0C, $0C, $06, $06, $06, $06, $06, $06, $06
db $03, $06, $06, $03, $03, $03, $03, $03, $03, $03, $01, $03, $03, $01, $01, $01
ds 32, $00
db $07, $02, $07, $02, $06, $03, $07, $03, $07
ds 9, $03
db $01, $03, $03, $01, $03, $01, $03, $01, $03, $01, $01, $01, $01, $01
ds 32, $00
db $01, $03, $01, $03, $01, $03, $01, $03, $01, $03, $01, $03, $01, $03, $01, $03
db $01, $03, $01, $03, $01, $03, $01, $03, $01, $03, $01, $03, $01, $03, $01, $03
ds 16, $00
db $3F, $BF, $40, $40, $80, $80, $91, $91, $B2, $B2, $90, $90, $91, $91, $92, $92
db $E0, $EF, $10, $10, $08, $08, $88, $88, $4F, $4F, $48, $48, $90, $90, $13, $13
db $00, $FF, $00, $01, $00, $01, $00, $01, $FC, $FD, $02, $02, $01, $01, $19, $19
db $BB, $BB, $80, $80, $40, $40, $3F, $BF, $00, $80, $00, $80, $00, $80, $00, $FF
db $D4, $D4, $10, $10, $13, $13, $F4, $F4, $17, $17, $10, $10, $08, $08, $07, $F7
db $A9, $A9, $A9, $A9, $3D, $3D, $09, $09, $89, $89, $01, $01, $02, $02, $FC, $FD
db $01, $F9, $06, $86, $18, $98, $20, $A0, $20, $A0, $40, $40, $40, $40, $80, $80
db $FF, $FF, $00, $00, $08, $08, $0C, $0C, $08, $08, $08, $08, $08, $08, $18, $18
db $80, $9F, $60, $61, $18, $19, $04, $05, $04, $05, $02, $02, $02, $02, $01, $01
db $80, $80, $40, $40, $40, $40, $20, $A0, $21, $A1, $1A, $9A, $06, $86, $01, $F9
db $18, $18, $20, $20, $40, $40, $80, $80, $00, $00, $00, $00, $00, $00, $FF, $FF
db $01, $01, $02, $02, $02, $02, $04, $05, $04, $05, $18, $19, $60, $61, $80, $9F
db $07, $F7, $08, $88, $0B, $8B, $0A, $8A, $0B, $8B, $30, $B0, $40, $40, $A0, $A0
db $F0, $F7, $08, $08, $04, $04, $24, $24, $14, $14, $02, $02, $01, $01, $00, $00
db $00, $FF, $00, $01, $01, $01, $00, $00, $01, $01, $00, $00, $06, $06, $8D, $8D
db $A0, $A0, $80, $80, $EF, $EF, $24, $3C, $18, $18, $00, $00, $F0, $F0, $07, $07
db $00, $00, $00, $00, $CF, $DF, $24, $3C, $18, $18, $00, $00, $0F, $0F, $E0, $E0
db $99, $9B, $B7, $BF, $9C, $9C, $01, $01, $04, $04, $00, $01, $C0, $C1, $00, $3F
ds 12, $00
db $1F, $1F, $E0, $E0
ds 10, $00
db $7F, $7F, $80, $80
ds 10, $00
db $7F, $7F, $80, $80, $00, $00, $7F, $7F, $00, $00, $00, $00, $00, $00, $00, $00
db $FE, $FE, $01, $01, $00, $00, $FE, $FE
ds 10, $00
db $FE, $FE, $01, $01
ds 14, $00
db $F8, $F8, $07, $07
ds 14, $00
db $01, $01, $00, $00, $00, $00, $00, $00, $03, $03, $0C, $0C, $30, $30, $C3, $C3
db $0C, $0C, $0F, $0F, $30, $30, $C0, $C0, $0F, $0F, $30, $30, $C0, $C0, $00, $00
db $00, $00, $00, $00, $1F, $1F, $E0, $E0
ds 10, $00
db $7F, $7F, $80, $80, $01, $01, $03, $03, $01, $01, $00, $00, $00, $00, $00, $00
db $80, $80, $01, $01, $03, $03, $01, $01, $00, $00, $00, $00, $00, $00, $00, $00
db $01, $01, $80, $80, $C0, $C0, $80, $80, $00, $00, $00, $00, $00, $00, $00, $00
db $FE, $FE, $01, $01, $80, $80, $C0, $C0, $80, $80, $00, $00, $00, $00, $00, $00
db $00, $00, $F8, $F8, $07, $07
ds 10, $00
db $F0, $F0, $0C, $0C, $03, $03, $F0, $F0, $0C, $0C, $03, $03
ds 10, $00
db $C0, $C0, $30, $30, $0C, $0C, $C3, $C3, $30, $30
ds 14, $00
db $80, $80, $02, $02, $04, $04, $08, $08, $11, $11, $22, $22, $44, $44, $88, $88
db $10, $10, $30, $30, $40, $40, $80, $80
ds 10, $00
db $0C, $0C, $02, $02, $01, $01
ds 10, $00
db $40, $40, $20, $20, $10, $10, $88, $88, $44, $44, $22, $22, $11, $11, $08, $08
db $02, $02, $04, $04, $04, $04, $09, $09, $09, $09, $12, $12, $12, $12, $24, $24
db $20, $20, $40, $40, $80, $80
ds 10, $00
db $04, $04, $02, $02, $01, $01
ds 10, $00
db $40, $40, $20, $20, $20, $20, $90, $90, $90, $90, $48, $48, $48, $48, $24, $24
db $24, $24, $48, $48, $48, $48, $90, $90, $90, $90, $90, $90, $20, $20, $20, $20
db $24, $24, $12, $12, $12, $12, $09, $09, $09, $09, $09, $09, $04, $04, $04, $04
db $01, $01, $01, $01
ds 12, $02
db $20, $20, $20, $20
ds 12, $40
db $04, $04, $04, $04
ds 12, $02
db $80, $80, $80, $80
ds 12, $40
ds 16, $02
db $48, $48, $5C, $5C, $5C, $5C, $48, $48, $40, $40, $40, $40, $40, $40, $40, $40
db $01, $01, $02, $02, $02, $02, $01, $01, $00, $00, $00, $00, $00, $00, $00, $00
db $80, $80, $40, $40, $40, $40, $80, $80, $00, $00, $00, $00, $00, $00, $00, $00
db $12, $12, $3A, $3A, $3A, $3A, $12, $12, $02, $02, $02, $02, $02, $02, $02, $02
ds 16, $40
db $02, $02, $02, $02, $01, $01, $01, $01, $01, $01, $01, $01, $00, $00, $00, $00
db $40, $40, $40, $40, $20, $20, $20, $20, $20, $20, $20, $20, $90, $90, $90, $90
db $02, $02, $02, $02, $04, $04, $04, $04, $04, $04, $04, $04, $09, $09, $09, $09
db $40, $40, $40, $40, $80, $80, $80, $80, $80, $80, $80, $80, $00, $00, $00, $00
db $90, $90, $48, $48, $48, $48, $24, $24, $24, $24, $12, $12, $12, $12, $09, $09
db $09, $09, $12, $12, $12, $12, $24, $24, $24, $24, $48, $48, $48, $48, $90, $90
db $09, $09, $04, $04, $04, $04, $02, $02, $01, $01, $00, $00, $00, $00, $1F, $1F
db $00, $00, $80, $80, $40, $40, $20, $20, $10, $10, $88, $88, $44, $44, $E2, $E2
db $00, $00, $01, $01, $02, $02, $04, $04, $08, $08, $11, $11, $22, $22, $47, $47
db $90, $90, $20, $20, $20, $20, $40, $40, $80, $80, $00, $00, $00, $00, $F8, $F8
db $00, $00, $00, $00, $01, $01, $01, $01, $02, $03, $02, $03, $02, $02, $02, $02
db $7F, $7F, $FF, $FF, $FF, $FF, $6F, $DF, $A3, $5F, $81, $7F, $C0, $3F, $C0, $3F
db $F1, $F1, $F8, $F8, $FC, $FC, $FE, $FE, $FF, $FF, $FE, $FE, $7E, $FE, $7E, $FE
db $00, $00, $80, $80, $40, $40, $30, $30, $0C, $0C, $C3, $C3, $30, $30, $0C, $0C
ds 12, $00
db $C0, $C0, $30, $30
ds 12, $00
db $03, $03, $0C, $0C, $00, $00, $01, $01, $02, $02, $0C, $0C, $30, $30, $C3, $C3
db $0C, $0C, $30, $30, $8F, $8F, $1F, $1F, $3F, $3F, $6D, $7B, $D4, $EB, $50, $6F
db $78, $47, $78, $47, $FE, $FE, $FF, $FF, $FF, $FF, $FF, $FF, $7F, $FF, $3F, $FF
db $0F, $FF, $0F, $FF, $00, $00, $00, $00, $80, $80, $80, $80, $C0, $C0, $C0, $C0
db $C0, $C0, $C0, $C0, $02, $03, $03, $03, $03, $03, $01, $01, $01, $01, $00, $00
db $00, $00, $00, $00, $C0, $3F, $E0, $1F, $70, $8F, $B8, $C7, $DE, $E1, $EA, $F5
db $7E, $7F, $1F, $1F, $1E, $FE, $0E, $FE, $0E, $FE, $04, $FC, $0C, $FC, $0C, $FC
db $30, $F0, $C0, $C0, $03, $03
ds 14, $00
db $0F, $0F, $C0, $C0, $30, $30, $0F, $0F
ds 10, $00
db $E0, $E0, $1F, $1F, $00, $00, $E0, $E0, $1F, $1F, $00, $00, $00, $00, $03, $03
db $01, $01, $80, $80, $7F, $7F, $00, $00, $80, $80, $7F, $7F
ds 16, $00
db $01, $01
ds 14, $00
db $80, $80, $C0, $C0, $80, $80, $01, $01, $FE, $FE, $00, $00, $01, $01, $FE, $FE
db $00, $00, $00, $00, $07, $07, $F8, $F8, $00, $00, $07, $07, $F8, $F8, $00, $00
db $00, $00, $F0, $F0, $03, $03, $0C, $0C, $F0, $F0, $00, $00, $00, $00, $00, $00
db $00, $00, $C0, $C0
ds 14, $00
db $58, $67, $7C, $63, $6E, $71, $37, $38, $3B, $3C, $1D, $1E, $0F, $0F, $03, $03
db $03, $FF, $01, $FF, $01, $FF, $00, $FF, $C0, $3F, $C1, $3F, $C6, $FE, $F8, $F8
db $C0, $C0, $C0, $C0, $C0, $C0, $80, $80, $80, $80
ds 18, $00
db $01, $01, $01, $01
ds 12, $00
db $80, $80, $80, $80, $00, $00, $00, $00, $00, $00, $1E, $1E, $21, $21, $4C, $4C
db $42, $42, $43, $43, $00, $00, $00, $00, $00, $00, $00, $00, $FC, $FC, $82, $82
db $FC, $FC, $90, $90, $04, $04, $03, $03, $44, $44, $23, $23, $10, $10, $0F, $0F
db $00, $00, $00, $00, $10, $10, $F0, $F0, $20, $20, $E0, $E0, $40, $40, $C0, $C0
ds 68, $00

; Data from 266A to 2759 (240 bytes)
_DATA_266A_:
ds 10, $00
db $13, $14, $17, $18
ds 13, $00
db $19, $1A, $1B, $1C, $1D, $20, $21, $22, $23, $24, $00, $00, $00, $00, $00, $01
db $02, $03, $00, $19, $25, $26, $00, $00, $00, $00, $00, $00, $27, $28, $24, $00
db $00, $00, $00, $04, $05, $06, $00, $29, $2A, $00, $00, $00, $00, $00, $00, $00
db $00, $2B, $2C, $00, $00, $00, $00, $00, $00, $00, $5D, $2D
ds 10, $00
db $2E, $5E, $00, $00, $00, $07, $08, $09, $2F, $30
ds 10, $00
db $31, $32, $00, $00, $00, $0A, $0B, $0C, $33, $34, $00, $00, $00, $00, $35, $36
db $00, $00, $00, $00, $37, $38, $00, $00, $00, $00, $00, $00, $39, $3A
ds 10, $00
db $3B, $3C, $00, $00, $00, $0D, $0E, $0F, $00, $3D
ds 10, $00
db $3E, $00, $00, $00, $00, $10, $11, $12, $00, $3F, $40, $00, $00, $00, $00, $00
db $00, $00, $00, $41, $42, $00, $00, $00, $00, $00, $00, $00, $43, $44, $45, $46

db $47, $00, $54, $55, $00, $48, $49, $4A, $4B, $4C, $00, $00, $00, $00, $00, $00
db $4D, $4E, $4F, $50, $51, $52, $53, $56, $57, $58, $59, $5A, $5B, $5C, $00


; 10 Tiles of 8x8 numeric characters
; Loaded to: _TILEDATA8800 + (113 * TILE_SZ_BYTES)  ; $8F10    ; Start loading 113 tiles into 8800 range
tile_data_0x275A_160_bytes_8x8_num_chars__275A_:
INCBIN "res/tile_data_0x275A_160_bytes_8x8_num_chars.2bpp"


; 115 Tiles of 8x16 font characters + some misc at the end
; Loaded to _TILEDATA9000
; Note: Code loading these accidentally(?) copies more tiles than are in the the tile
;       set blob so it picks up the first 13 tiles of the following 8x8 font (at 0x2FA).
tile_data_0x27fa_1840_bytes_8x16_font__27FA_:
INCBIN "res/tile_data_0x27fa_1840_bytes_8x16_font.2bpp"


; 128 Tiles of 8x8 Main Menu Font characters
; Loaded to _TILEDATA8800 during startup
gfx_tile_data__main_menu_font__2F2A_:
INCBIN "res/tile_data_0x2f2a_2048_bytes_main_menu_font.2bpp"


_DATA_372A_:
db $00, $00, $18, $18, $18, $18, $18, $18, $18, $18, $00, $00
db $18, $18, $00, $00, $00, $00, $28, $28, $28, $28
ds 10, $00
db $3C, $3C, $40, $40, $38, $38, $44, $44, $38, $38, $04, $04, $78, $78, $00, $00
db $10, $10, $3C, $3C, $70, $70, $38, $38, $1C, $1C, $78, $78, $10, $10, $00, $00
db $00, $00, $62, $62, $64, $64, $08, $08, $10, $10, $26, $26, $46, $46, $00, $00
db $20, $20, $50, $50, $50, $50, $20, $20, $74, $74, $68, $68, $36, $36, $00, $00
db $00, $00, $06, $06, $0C, $0C, $18, $18, $30, $30, $60, $60, $40, $40, $00, $00
db $00, $00, $08, $08, $10, $10, $30, $30, $30, $30, $10, $10, $08, $08, $00, $00
db $00, $00, $10, $10, $08, $08, $0C, $0C, $0C, $0C, $08, $08, $10, $10, $00, $00
db $00, $00, $60, $60, $30, $30, $18, $18, $0C, $0C, $06, $06, $02, $02, $00, $00
db $00, $00, $18, $18, $18, $18, $10, $10, $08, $08, $00, $00, $00, $00, $00, $00
db $00, $00, $18, $18, $18, $18, $08, $08, $10, $10, $00, $00, $00, $00, $00, $00
db $10, $10, $D6, $D6, $7C, $7C, $38, $38, $7C, $7C, $D6, $D6, $10, $10, $00, $00
db $00, $00, $10, $10, $38, $38, $6C, $6C
ds 10, $00
db $14, $14, $7E, $7E, $28, $28, $28, $28, $FC, $FC, $50, $50, $00, $00, $7C, $7C
db $82, $82, $BA, $BA, $AA, $AA, $BA, $BA, $84, $84, $70, $70, $00, $00, $00, $00
db $00, $00, $18, $18, $18, $18, $00, $00, $18, $18, $18, $18
ds 10, $00
db $18, $18, $18, $18, $00, $00, $00, $00, $00, $00, $18, $18, $00, $00, $18, $18
db $18, $18, $08, $08, $10, $10, $00, $00, $20, $20, $30, $30, $18, $18, $0C, $0C
db $18, $18, $30, $30, $20, $20, $00, $00, $04, $04, $0C, $0C, $18, $18, $30, $30
db $18, $18, $0C, $0C, $04, $04
ds 20, $00
db $10, $10, $30, $30, $7E, $7E, $7E, $7E, $30, $30, $10, $10, $00, $00, $00, $00
db $08, $08, $0C, $0C, $7E, $7E, $7E, $7E, $0C, $0C, $08, $08
ds 36, $00
db $3C, $3C, $62, $62, $7C, $7C, $62, $62, $7C, $7C, $60, $60, $00, $00, $1C, $1C
db $38, $38, $70, $70, $38, $38, $FE, $FE, $7C, $7C, $70, $70, $10, $10
ds 16, $FF
db $00, $00, $18, $18
ds 10, $3C
db $18, $18, $18, $18, $18, $18, $00, $00, $18, $18, $3C, $3C, $3C, $3C, $18, $18
db $00, $00, $00, $00, $36, $36, $36, $36, $12, $12, $24, $24
ds 24, $00
db $1C, $1C, $3E, $3E, $32, $32, $30, $30, $3C, $3C, $7E, $7E, $66, $66, $66, $66
db $7E, $7E, $3C, $3C, $0C, $0C, $4C, $4C, $7C, $7C, $38, $38, $00, $00, $00, $00
db $18, $18, $3C, $3C, $5A, $5A, $5A, $5A, $5A, $5A, $58, $58, $3C, $3C, $1A, $1A
db $1A, $1A, $5A, $5A, $5A, $5A, $5A, $5A, $3C, $3C, $18, $18, $00, $00, $00, $00
db $22, $22, $52, $52, $56, $56, $24, $24, $0C, $0C, $0C, $0C, $18, $18, $18, $18
db $30, $30, $30, $30, $24, $24, $6A, $6A, $4A, $4A, $44, $44, $00, $00, $00, $00
db $60, $60, $B0, $B0, $90, $90, $90, $90, $D0, $D0, $60, $60, $60, $60, $F0, $F0
db $92, $92, $9A, $9A, $8C, $8C, $C4, $C4, $FA, $FA, $72, $72, $00, $00, $00, $00
db $02, $02, $06, $06, $06, $06, $04, $04, $0C, $0C, $0C, $0C, $18, $18, $18, $18
db $30, $30, $30, $30, $20, $20, $60, $60, $60, $60, $40, $40, $00, $00, $00, $00
db $18, $18, $30, $30
ds 20, $60
db $30, $30, $18, $18, $00, $00, $00, $00, $18, $18, $0C, $0C
ds 20, $06
db $0C, $0C, $18, $18
ds 12, $00
db $7E, $7E, $7E, $7E, $00, $00, $00, $00, $7E, $7E, $7E, $7E
ds 12, $00
db $18, $18, $18, $18, $0C, $0C
ds 26, $00
db $18, $18, $18, $18, $30, $30
ds 30, $00
db $10, $10, $92, $92, $54, $54, $74, $74, $38, $38, $5C, $5C, $54, $54, $92, $92
db $10, $10
ds 10, $00
db $10, $10, $38, $38, $38, $38, $6C, $6C, $C6, $C6, $C6, $C6, $82, $82
ds 18, $00
db $12, $12, $12, $12, $7E, $7E, $24, $24, $24, $24, $24, $24, $24, $24, $FE, $FE
db $48, $48, $48, $48
ds 22, $00
db $7C, $7C, $82, $82, $92, $92, $AA, $AA, $AA, $AA, $AA, $AA, $B6, $B6, $80, $80
db $7C, $7C
ds 10, $00
db $18, $18, $18, $18, $00, $00, $00, $00, $00, $00, $18, $18, $18, $18
ds 34, $00
db $18, $18, $18, $18
ds 12, $00
db $18, $18, $18, $18, $00, $00, $00, $00, $18, $18, $18, $18, $08, $08, $10, $10
ds 12, $00
db $40, $40, $60, $60, $30, $30, $18, $18, $0C, $0C, $06, $06, $0C, $0C, $18, $18
db $30, $30, $60, $60, $40, $40
ds 10, $00
db $02, $02, $06, $06, $0C, $0C, $18, $18, $30, $30, $60, $60, $30, $30, $18, $18
db $0C, $0C, $06, $06, $02, $02
ds 16, $00
db $10, $10, $38, $38, $FE, $FE, $7C, $7C, $38, $38, $6C, $6C, $44, $44
ds 138, $00
db $38, $38, $6C, $6C, $46, $46, $C2, $C2, $C6, $C6, $CC, $CC, $F8, $F8, $CC, $CC
db $C6, $C6, $C2, $C2, $E6, $E6, $FC, $FC, $D8, $D8, $C0, $C0
ds 100, $00
db $38, $38, $7C, $7C, $4C, $4C, $C6, $C6, $C6, $C6, $86, $86, $86, $86, $FE, $FE
ds 12, $86
db $00, $00, $00, $00, $F8, $F8, $CC, $CC, $C6, $C6, $C6, $C6, $C6, $C6, $CC, $CC
db $F0, $F0, $CC, $CC, $C6, $C6, $C6, $C6, $C6, $C6, $C6, $C6, $CC, $CC, $F8, $F8
db $00, $00, $00, $00, $38, $38, $7C, $7C, $E6, $E6, $C2, $C2, $C2, $C2, $C0, $C0
db $C0, $C0, $C0, $C0, $C0, $C0, $C2, $C2, $C2, $C2, $E6, $E6, $7C, $7C, $38, $38
db $00, $00, $00, $00, $F0, $F0, $FC, $FC, $8E, $8E
ds 16, $86
db $8E, $8E, $FC, $FC, $F0, $F0, $00, $00, $00, $00, $FC, $FC, $FE, $FE, $C2, $C2
db $C0, $C0, $C0, $C0, $F8, $F8, $F8, $F8, $C0, $C0, $C0, $C0, $C0, $C0, $C0, $C0
db $C2, $C2, $FE, $FE, $FC, $FC, $00, $00, $00, $00, $FC, $FC, $FE, $FE, $C2, $C2
db $C0, $C0, $C0, $C0, $C0, $C0, $F8, $F8, $F8, $F8
ds 12, $C0
db $00, $00, $00, $00, $38, $38, $7C, $7C, $E6, $E6, $C2, $C2, $C0, $C0, $C0, $C0
db $C0, $C0, $CE, $CE, $C6, $C6, $C6, $C6, $C6, $C6, $EE, $EE, $7C, $7C, $38, $38
db $00, $00, $00, $00
ds 12, $86
db $FE, $FE, $FE, $FE
ds 12, $86
db $00, $00, $00, $00, $3C, $3C, $3C, $3C
ds 20, $18
db $3C, $3C, $3C, $3C, $00, $00, $00, $00, $1E, $1E, $1E, $1E
ds 14, $0C
db $8C, $8C, $8C, $8C, $CC, $CC, $FC, $FC, $78, $78, $00, $00, $00, $00, $C6, $C6
db $C6, $C6, $CC, $CC, $C8, $C8, $D0, $D0, $F0, $F0, $E0, $E0, $E0, $E0, $D0, $D0
db $D8, $D8, $C8, $C8, $CE, $CE, $C6, $C6, $C6, $C6, $00, $00, $00, $00
ds 24, $C0
db $FC, $FC, $FC, $FC, $00, $00, $00, $00, $82, $82, $C6, $C6, $C6, $C6, $EE, $EE
db $AA, $AA, $BA, $BA, $BA, $BA, $92, $92, $92, $92
ds 10, $82
db $00, $00, $00, $00, $86, $86, $C6, $C6, $C6, $C6, $E6, $E6, $E6, $E6, $A6, $A6
db $B6, $B6, $96, $96, $96, $96, $9E, $9E, $8E, $8E, $8E, $8E, $8E, $8E, $86, $86
db $00, $00, $00, $00, $38, $38, $6C, $6C
ds 20, $C6
db $6C, $6C, $38, $38, $00, $00, $00, $00, $F8, $F8, $CC, $CC, $C6, $C6, $C6, $C6
db $C6, $C6, $C6, $C6, $CC, $CC, $FC, $FC, $F0, $F0
ds 10, $C0
db $00, $00, $00, $00, $38, $38, $6C, $6C, $C6, $C6, $C2, $C2, $C2, $C2, $C2, $C2
db $C2, $C2, $CA, $CA, $CA, $CA, $CA, $CA, $C6, $C6, $C4, $C4, $6E, $6E, $3A, $3A
db $00, $00, $00, $00, $F8, $F8, $CC, $CC, $C6, $C6, $C6, $C6, $C6, $C6, $CC, $CC
db $F8, $F8, $F0, $F0, $D0, $D0, $D0, $D0, $D8, $D8, $C8, $C8, $CE, $CE, $C6, $C6
db $00, $00, $00, $00, $38, $38, $6C, $6C, $C6, $C6, $C2, $C2, $C0, $C0, $60, $60
db $30, $30, $0C, $0C, $06, $06, $86, $86, $86, $86, $CE, $CE, $7C, $7C, $38, $38
db $00, $00, $00, $00, $FE, $FE, $D6, $D6, $92, $92
ds 22, $10
db $00, $00, $00, $00
ds 20, $86
db $8E, $8E, $8E, $8E, $DC, $DC, $78, $78, $00, $00, $00, $00, $86, $86, $86, $86
db $86, $86, $C6, $C6, $44, $44, $44, $44, $4C, $4C, $4C, $4C, $28, $28, $28, $28
db $38, $38, $10, $10, $10, $10, $10, $10, $00, $00, $00, $00, $86, $86
ds 12, $A6
db $B6, $B6, $B6, $B6, $B6, $B6, $D6, $D6, $CC, $CC, $4C, $4C, $48, $48, $00, $00
db $00, $00, $86, $86, $C6, $C6, $44, $44, $4C, $4C, $68, $68, $38, $38, $38, $38
db $38, $38, $28, $28, $68, $68, $64, $64, $C4, $C4, $C6, $C6, $C2, $C2, $00, $00
db $00, $00, $82, $82, $82, $82, $C6, $C6, $44, $44, $6C, $6C, $38, $38, $38, $38
ds 14, $10
db $00, $00, $00, $00, $FE, $FE, $06, $06, $06, $06, $0C, $0C, $08, $08, $18, $18
db $10, $10, $30, $30, $20, $20, $60, $60, $C0, $C0, $C0, $C0, $FE, $FE, $FE, $FE
db $00, $00, $00, $00, $82, $82, $00, $00

SECTION "rom1", ROMX[$4000], BANK[$1]
_LABEL_4000_:
    jr   c, _LABEL_403A_
    ld   a, h
    ld   a, h
    ld   c, h
    ld   c, h
    add  $C6
    add  $C6
    add  [hl]
    add  [hl]
    add  [hl]
    add  [hl]
    cp   $FE
    add  [hl]
    add  [hl]
    add  [hl]
    add  [hl]
    add  [hl]
; Data from 4015 to 4039 (37 bytes)
db $86, $86, $86, $00, $00, $00, $00, $82, $82, $00, $00, $38, $38, $6C, $6C
ds 16, $C6
db $6C, $6C, $38, $38, $00, $00

_LABEL_403A_:
    nop
    nop
    add  d
    add  d
    nop
    nop
    add  [hl]
; Data from 4041 to 4389 (841 bytes)
ds 15, $86
db $8E, $8E, $8E, $8E, $DC, $DC, $78, $78
ds 24, $00
db $18, $18, $18, $18, $08, $08, $08, $08, $10, $10
ds 14, $00
db $18, $18, $18, $18
ds 44, $00
db $FF, $FF,

; ; 45 Tiles of ...?
; ; Loaded to _TILEDATA9000 from _LABEL_711A_
tile_data_0x40ba_720_bytes__40BA_:
INCBIN "res/tile_data_0x40ba_720_bytes.2bpp"


; Tile Map data loaded by gfx_load_tile_map_20x6_at_438a__7691_
tile_map_0x438a_20x6_120_bytes__438a_:
INCBIN "res/tile_map_0x438a_20x6_120_bytes.bin"


ds 26, $00
db $24, $24, $18, $18, $2C, $2C, $2C, $2C, $2C, $2C, $18, $18, $00, $00, $00, $00
db $24, $24, $18, $18, $2C, $2C, $2C, $2C, $2C, $2C, $18, $18, $00, $00, $00, $00
db $48, $48, $00, $00, $58, $58, $58, $58, $58, $58, $34, $34, $00, $00, $00, $00
db $48, $48, $00, $00, $58, $58, $58, $58, $58, $58, $34, $34
ds 36, $00
db $18, $18, $3C, $3C, $66, $66, $66, $66, $6E, $6E, $0C, $0C, $18, $18, $18, $18
db $18, $18, $00, $00, $18, $18, $3C, $3C, $3C, $3C, $18, $18, $00, $00, $00, $00
db $38, $38, $6C, $6C, $C6, $C6, $C6, $C6, $CE, $CE, $D6, $D6, $D6, $D6, $D6, $D6
db $E6, $E6, $C6, $C6, $C6, $C6, $C6, $C6, $6C, $6C, $38, $38, $00, $00, $00, $00
db $18, $18, $38, $38, $78, $78
ds 18, $18
db $7E, $7E, $7E, $7E, $00, $00, $00, $00, $38, $38, $7C, $7C, $CE, $CE, $86, $86
db $86, $86, $06, $06, $0C, $0C, $38, $38, $70, $70, $60, $60, $C0, $C0, $C0, $C0
db $FE, $FE, $FE, $FE, $00, $00, $00, $00, $38, $38, $7C, $7C, $CE, $CE, $86, $86
db $06, $06, $0C, $0C, $38, $38, $38, $38, $0C, $0C, $06, $06, $86, $86, $CE, $CE
db $7C, $7C, $38, $38, $00, $00, $00, $00, $1C, $1C, $1C, $1C, $3C, $3C, $2C, $2C
db $2C, $2C, $6C, $6C, $4C, $4C, $4C, $4C, $4C, $4C, $CC, $CC, $FE, $FE, $FE, $FE
db $0C, $0C, $0C, $0C, $00, $00, $00, $00, $FC, $FC, $FC, $FC, $80, $80, $80, $80
db $80, $80, $F8, $F8, $8C, $8C, $06, $06, $06, $06, $06, $06, $86, $86, $8C, $8C
db $FC, $FC, $78, $78, $00, $00, $00, $00, $38, $38, $7C, $7C, $C6, $C6, $C2, $C2
db $C0, $C0, $D8, $D8, $FC, $FC, $E6, $E6, $C6, $C6, $C2, $C2, $C2, $C2, $66, $66
db $7C, $7C, $38, $38, $00, $00, $00, $00, $FE, $FE, $FE, $FE, $82, $82, $06, $06
db $04, $04, $08, $08, $18, $18, $18, $18, $30, $30, $30, $30, $70, $70, $70, $70
db $70, $70, $70, $70, $00, $00, $00, $00, $38, $38, $6C, $6C, $C6, $C6, $82, $82
db $C6, $C6, $6C, $6C, $38, $38, $6C, $6C, $C6, $C6, $82, $82, $82, $82, $C6, $C6
db $7C, $7C, $38, $38, $00, $00, $00, $00, $38, $38, $7C, $7C, $C6, $C6, $86, $86
db $86, $86, $86, $86, $86, $86, $CE, $CE, $76, $76, $06, $06, $06, $06, $C6, $C6
db $7C, $7C, $38, $38
ds 10, $00
db $18, $18, $18, $18, $18, $18, $7E, $7E, $7E, $7E, $18, $18, $18, $18, $18, $18
ds 22, $00
db $FE, $FE, $FE, $FE
ds 24, $00
db $86, $86, $CE, $CE, $7C, $7C, $30, $30, $78, $78, $EC, $EC, $C6, $C6
ds 16, $00
db $18, $18, $18, $18, $00, $00, $7E, $7E, $7E, $7E, $00, $00, $18, $18, $18, $18
ds 18, $00
db $7C, $7C, $7C, $7C, $00, $00, $00, $00, $7C, $7C, $7C, $7C
ds 16, $00
db $3E, $3E, $3E, $3E, $30, $30, $30, $30, $30, $30, $B0, $B0, $70, $70, $70, $70
db $30, $30
ds 10, $00
db $18, $18, $3C, $3C, $3C, $3C, $18, $18, $00, $00, $18, $18, $18, $18, $18, $18
db $30, $30, $76, $76, $66, $66, $66, $66, $3C, $3C, $18, $18, $00, $00, $00, $00
db $18, $18, $3C, $3C, $3C, $3C, $18, $18, $00, $00, $18, $18, $18, $18, $18, $18
ds 10, $3C
db $18, $18, $00, $00, $00, $00, $18, $18, $30, $30
ds 20, $60
db $30, $30, $18, $18, $00, $00, $00, $00, $18, $18, $0C, $0C
ds 20, $06
db $0C, $0C, $18, $18, $00, $00, $00, $00, $18, $18, $3C, $3C, $66, $66, $66, $66
db $66, $66, $3C, $3C, $18, $18, $00, $00, $7E, $7E, $7E, $7E
ds 12, $00
db $18, $18, $60, $60, $00, $00, $86, $86, $C6, $C6, $C6, $C6, $E6, $E6, $B6, $B6
db $B6, $B6, $9E, $9E, $9E, $9E, $8E, $8E, $8E, $8E, $86, $86, $00, $00, $00, $00
db $18, $18, $60, $60, $00, $00, $38, $38, $7C, $7C, $C6, $C6, $C6, $C6, $86, $86
db $FE, $FE
ds 10, $86
db $00, $00, $00, $00, $18, $18, $60, $60, $00, $00, $FE, $FE, $FE, $FE, $C0, $C0
db $C0, $C0, $FC, $FC, $FC, $FC, $C0, $C0, $C0, $C0, $C0, $C0, $FE, $FE, $FE, $FE
db $00, $00, $00, $00, $0C, $0C, $30, $30, $00, $00, $3C, $3C, $3C, $3C
ds 14, $18
db $3C, $3C, $3C, $3C, $00, $00, $00, $00, $18, $18, $60, $60, $00, $00, $38, $38
db $EE, $EE
ds 14, $C6
db $EE, $EE, $38, $38, $00, $00, $00, $00, $18, $18, $60, $60, $00, $00
ds 14, $86
db $8E, $8E, $8E, $8E, $DC, $DC, $78, $78, $00, $00, $00, $00, $38, $38, $7C, $7C
db $0C, $0C, $3C, $3C, $6C, $6C, $6C, $6C, $3E, $3E, $00, $00, $7E, $7E, $7E, $7E
ds 10, $00



SECTION "rom0_mem_and_math_util_481A", ROMX[$481A], BANK[$1]
include "mem_and_math_util.asm"

SECTION "rom0_after_bankswitch_functions_4875", ROMX[$4875], BANK[$1]


; Clears TileMap0 with the Empty/Space character (0xBE)
;
; Destroys A, HL
display_clear_screen_with_space_char__4875_:
    call wait_until_vbl__92C_
    call display_screen_off__94C_
    ld   hl, _TILEMAP0; $9800
    clear_tilemap0_loop__487E_:
        ld   a, FONT_BLANKSPACE  ; $BE
        ldi  [hl], a
        ld   a, h
        cp   HIGH(_TILEMAP1) ; $9C
        jr   nz, clear_tilemap0_loop__487E_
    ldh  a, [rLCDC]
    ; Turn off window and select LCDCF_BG8800 tile data
    and  ~(LCDCF_WINON | LCDCF_BG8000)  ; $CF
    or   (LCDCF_ON | LCDCF_BGON | LCDCF_OBJON)  ; $C1
    ldh  [rLCDC], a
    ret

_LABEL_488F_:
    call wait_until_vbl__92C_
    call display_screen_off__94C_
    ld   hl, $9C00
_LABEL_4898_:
    ld   a, $BE
    ldi  [hl], a
    ld   a, h
    cp   $A0
    jr   nz, _LABEL_4898_
    ldh  a, [rLCDC]
    or   $A1
    ldh  [rLCDC], a
    ret

; Data from 48A7 to 48B6 (16 bytes)
db $3E, $90, $CD, $E0, $48, $41, $3E, $10, $CD, $E0, $48, $CD, $2C, $09, $06, $09

; Copies B x 16 byte tile pattern data from DE to HL only during vblanks
;
; - Number of X to copy: B
; - Source: DE
; - Destination: HL
copy_b_x_tile_patterns_from_de_to_hl__48B7_:
    ld   a, b
    and  $03
    cp   $00
    jr   nz, skip_wait_vbl__48C1_
    call wait_until_vbl__92C_

    skip_wait_vbl__48C1_:
        ld   c, $10
    .loop_tile_pattern_copy_16_bytes__48C3_:
        ld   a, [de]
        ldi  [hl], a
        inc  de
        dec  c
        jr   nz, .loop_tile_pattern_copy_16_bytes__48C3_
        dec  b
        jr   nz, copy_b_x_tile_patterns_from_de_to_hl__48B7_
        ret


; - Tiles to copy: A (16 bytes)
; - Source address: DE + (B x 16)
; - Dest   address: HL + (C x 16)
copy_a_x_tile_patterns_from_de_add_bx16_to_hl_add_cx16__48CD_:
    ; Calculate (original) DE + (B x 16) -> HL
    ; Move (original HL) -> DE
    push af
    ld   a, $10
    call add_a_x_b_to_de_result_in_hl_and_hl_moved_to_de__48E0_

    ; Calculate (original) HL + (C x 16) -> HL
    ; Move DE + (B x 16) -> DE
    ld   b, c
    ld   a, $10
    call add_a_x_b_to_de_result_in_hl_and_hl_moved_to_de__48E0_

    call wait_until_vbl__92C_
    pop  af
    ld   b, a
    jr   copy_b_x_tile_patterns_from_de_to_hl__48B7_

    ; - Unchanged HL: -> returned in DE
    ; - DE + (A x B): -> returned in HL
    ; Preserves: BC
    add_a_x_b_to_de_result_in_hl_and_hl_moved_to_de__48E0_:
        push hl
        ld   h, d
        ld   l, e
        push bc
        call multiply_a_x_b__result_in_de__4853_
        pop  bc
        add  hl, de
        pop  de
        ret


; Maybe draws a Text Dialog Box of variable width and height on Tilemap0
;
; Uses System font tiles
;
; - B: Tilemap X
; - C: Tilemap Y
; - D:  Width in tiles?
; - E: Numer of rows  in tiles
; - A: Tile Pattern id to start with (0xF2 in some cases, font tile 114 [0xF2 - 0x80])
display_textbox_draw_xy_in_bc_wh_in_de_st_id_in_a__48EB_:
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a  ; TODO: C8CC sems like a vram temp/scratch var

    ; Calc X,Y in tiles offset into tilemap0
    ld   a, c
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    ld   a, b
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   hl, _TILEMAP0; $9800
    push de
    call calc_vram_addr_of_tile_xy_base_in_hl__4932_

    pop  de
    ld   b, e  ; B is counter for number of rows in tiles
    dec  b

    ; Draw Top of Box
    ld   a, [maybe_vram_data_to_write__RAM_C8CC_]
    call display_textbox_draw_row__491B_
    dec  b

    ; Draw middle section of box (variable height)
    ; A+3 is the offset to next part of textbox tiles
    .loop_textbox_middle_rows__4907_:
        ld   a, [maybe_vram_data_to_write__RAM_C8CC_]
        add  TEXTBOX_OFFSET_TO_MIDDLE_TILES  ; $03
        call display_textbox_draw_row__491B_
        dec  b
        jr   nz, .loop_textbox_middle_rows__4907_

    ; Draw bottom of textbox
    ld   a, [maybe_vram_data_to_write__RAM_C8CC_]
    add  TEXTBOX_OFFSET_TO_BOTTOM_TILES  ; $06
    call display_textbox_draw_row__491B_
    ret

    ; Helper function to draw text box rows
    ;
    ; D: Width in tiles to write
    ; A: Tile ID N to start row with. Rows are like: (N | N+1... | N+2)
    display_textbox_draw_row__491B_:
        ld   c, a
        call wait_until_vbl__92C_
        ld   a, c
        ; Load width in tiles
        ld   c, d

        ; Write left edge tile first
        ; Then increment a to middle tile
        dec  c
        ldi  [hl], a
        inc  a
        dec  c

        ; Write middle tiles
        ; Then increment a to middle tile
        .loop_middle_tiles__4925_:
            ldi  [hl], a
            dec  c
            jr   nz, .loop_middle_tiles__4925_
        inc  a

        ; Write right edge tile
        ; Calculate and apply same starting x position on next tile row down
        ldi  [hl], a
        ld   a, _TILEMAP_WIDTH  ; $20
        sub  d
        call add_a_to_hl__486E_
        ret


; Calculate the vram address of tilemap X,Y
; - Base address: HL
; - Tilemap X,Y in global vars
;
; - Returns result in HL
;
; - Destroys: A, BC, DE
calc_vram_addr_of_tile_xy_base_in_hl__4932_:
    ; Multiply Tile Y x Tilemap Width
    ld   a, [_tilemap_pos_y__RAM_C8CA_]  ; ? Tile Y
    dec  a
    ld   b, _TILEMAP_WIDTH
    call multiply_a_x_b__result_in_de__4853_
    ; Add base Tilemap address in HL
    add  hl, de
    ;  Add X offset
    ld   a, [_tilemap_pos_x__RAM_C8CB_]  ; ? Tile X
    ld   e, a
    ld   d, $00
    add  hl, de
    ret

; TODO: Probably render some text at DE to X,y (H,L) to ...
_LABEL_4944_:
    ld   a, h
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   a, l
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    push de
    push bc
_LABEL_494E_:
    ld   a, [de]
    cp   $00
    jr   z, _LABEL_4986_
    push bc
    ld   hl, $9000
    ld   a, c
    cp   $80
    jr   c, _LABEL_4962_
    sub  $80
    ld   c, a
    ld   hl, $8800
_LABEL_4962_:
    ld   a, [de]
    sub  $63
    push de
    dec  b
    ld   b, a
    jr   z, _LABEL_4973_
    sla  b
    ld   de, $38FA
    ld   a, $02
    jr   _LABEL_4978_

_LABEL_4973_:
    ld   de, $372A
    ld   a, $01
_LABEL_4978_:
    call copy_a_x_tile_patterns_from_de_add_bx16_to_hl_add_cx16__48CD_
    pop  de
    pop  bc
    inc  c
    dec  b
    jr   z, _LABEL_4982_
    inc  c
_LABEL_4982_:
    inc  b
    inc  de
    jr   _LABEL_494E_

_LABEL_4986_:
    ld   hl, _TILEMAP0; $9800
    call calc_vram_addr_of_tile_xy_base_in_hl__4932_
    pop  bc
    pop  de
    call wait_until_vbl__92C_
_LABEL_4991_:
    ld   a, [de]
    cp   $00
    inc  de
    ret  z
    dec  de
    ld   a, c
    ldi  [hl], a
    ld   a, l
    and  $07
    cp   $00
    jr   nz, _LABEL_49A3_
    call wait_until_vbl__92C_
_LABEL_49A3_:
    push bc
    dec  b
    pop  bc
    jr   z, _LABEL_49BE_
    push de
    ld   d, $00
    ld   e, $1F
    push hl
    add  hl, de
    inc  c
    ld   a, c
    ldi  [hl], a
    ld   l, a
    and  $0F
    cp   $00
    jr   nz, _LABEL_49BC_
    call wait_until_vbl__92C_
_LABEL_49BC_:
    pop  hl
    pop  de
_LABEL_49BE_:
    inc  c
    inc  de
    jr   _LABEL_4991_


; TODO: checks buttons...
; Maps D-Pad button presses to keycode input
;
; - Reads from: buttons_new_pressed__RAM_D006_
; - Writes to : input_key_pressed__RAM_D025_
;
; - Performs opposite function of input_map_keycodes_to_gamepad_buttons__4D30_
;
; Destroys A
input_map_gamepad_buttons_to_keycodes__49C2_:
    call timer_wait_tick_AND_TODO__289_  ; TODO: still not sure all of what this is doing
    call input_read_keys__C8D_
    ld   a, [buttons_new_pressed__RAM_D006_]
    cp   $00
    ret  z

    bit  PADB_START, a  ; 3, a
    jr   nz, _handle_btn_start__4A00_
    bit  PADB_SELECT, a  ; 2, a
    jr   nz, _handle_btn_select__49FA_
    bit  PADB_A, a  ; 0, a
    jr   nz, _handle_btn_a__49EE_
    bit  PADB_B, a  ; 1, a
    jr   nz, _handle_btn_b__49F4_

    bit  PADB_RIGHT, a  ; 4, a
    jr   nz, handle_joy_right__4A06_
    bit  PADB_LEFT, a  ; 5, a
    jr   nz, handle_joy_left__4A14_
    bit  PADB_UP, a  ; 6, a
    jr   nz, handle_joy_up__4A22_
    bit  PADB_DOWN, a  ; 7, a
    jr   nz, handle_joy_down__4A28_

    ; Handle A/B/Start/Select mapping
    _handle_btn_a__49EE_:
        ld   a, SYS_CHAR_PG_ARRIBA  ; $44
        ld   [input_key_pressed__RAM_D025_], a
        ret

    _handle_btn_b__49F4_:
        ld   a, SYS_CHAR_PG_ABAJO  ; $45
        ld   [input_key_pressed__RAM_D025_], a
        ret

    _handle_btn_select__49FA_:
        ld   a, SYS_CHAR_ENTRA_CR  ; $2E
        ld   [input_key_pressed__RAM_D025_], a
        ret

    _handle_btn_start__4A00_:
        ld   a, SYS_CHAR_SALIDA  ; $2A
        ld   [input_key_pressed__RAM_D025_], a
        ret

    ; Handle Joypad mapping
    handle_joy_right__4A06_:
        bit  6, a
        jr   nz, handle_joy_up_and_right___4A2E_
        bit  7, a
        jr   nz, handle_joy_down_and_right___4A34_
        ld   a, SYS_CHAR_RIGHT  ; $3F
        ld   [input_key_pressed__RAM_D025_], a
        ret

    handle_joy_left__4A14_:
        bit  6, a
        jr   nz, handle_joy_up_and_left__4A3A_
        bit  7, a
        jr   nz, handle_joy_down_and_left__4A40_
        ld   a, SYS_CHAR_LEFT  ; $3E
        ld   [input_key_pressed__RAM_D025_], a
        ret

    handle_joy_up__4A22_:
        ld   a, SYS_CHAR_UP  ; $3D
        ld   [input_key_pressed__RAM_D025_], a
        ret

    handle_joy_down__4A28_:
        ld   a, SYS_CHAR_DOWN  ; $40
        ld   [input_key_pressed__RAM_D025_], a
        ret

        ; Extra mapping for JoyPad diagonals
        handle_joy_up_and_right___4A2E_:
            ld   a, SYS_CHAR_UP_RIGHT  ; $CA
            ld   [input_key_pressed__RAM_D025_], a
            ret

        handle_joy_down_and_right___4A34_:
            ld   a, SYS_CHAR_DOWN_RIGHT  ; $CB
            ld   [input_key_pressed__RAM_D025_], a
            ret

        handle_joy_up_and_left__4A3A_:
            ld   a, SYS_CHAR_UP_LEFT  ; $CD
            ld   [input_key_pressed__RAM_D025_], a
            ret

        handle_joy_down_and_left__4A40_:
            ld   a, SYS_CHAR_DOWN_LEFT  ; $CC
            ld   [input_key_pressed__RAM_D025_], a
            ret


; Draws a text string to the Tilemap at X,Y
;
; - Encoded text string to render       : DE
; - Start at Tilemap (X,Y)              : H,L
; - Render mode (1 = Normal, 0 = Erase) : C
render_string_at_de_to_tilemap0_xy_in_hl__4A46_:
    push bc
    ; Calculate offset into VRAM base address for Tilemap X,Y
    ld   a, h
    ld   [_tilemap_pos_x__RAM_C8CB_], a  ; h -> Tilemap X
    ld   a, l
    ld   [_tilemap_pos_y__RAM_C8CA_], a  ; l -> Tilemap Y
    push de
    ld   hl, _TILEMAP0  ; $9800
    call calc_vram_addr_of_tile_xy_base_in_hl__4932_
    pop  de

    ; Wait for VBlank before continuing
    call wait_until_vbl__92C_

    ; Check to see if the text should be rendered normally (C != 0)
    ; or if the string should be rendered as Blank Spaces (i.e. erase)
    pop  bc
    ld   a, c
    cp   PRINT_ERASE
    jr   z, _loop_erase_chars_to_tilemap__4A68_
    ; Print Normal
    ;
    ; Render string characters into the Tilemap at HL
    ; until a string terminator is reached, then return
    _loop_str_chars_to_tilemap__4A60_:
        ld   a, [de]
        inc  de
        cp   STR_TERMINATOR  ; $00
        ret  z
        ldi  [hl], a
        jr _loop_str_chars_to_tilemap__4A60_

    ; Print Erase
    ; Note: This mode doesn't seem to get used by anything
    ;
    ; Write Space Characters ($BE) into the Tilemap at HL
    ; ignoring the actual character values
    ; until a string terminator is reached, then return
    _loop_erase_chars_to_tilemap__4A68_:
        ld   a, [de]
        inc  de
        cp   STR_TERMINATOR  ; $00
        ret  z
        ld   a, FONT_BLANKSPACE  ; $BE
        ldi  [hl], a
        jr   _loop_erase_chars_to_tilemap__4A68_


; TODO:
_LABEL_4A72_:
    push af
    call timer_wait_tick_AND_TODO__289_
    pop  af
    dec  a
    jr   nz, _LABEL_4A72_
    ret

_LABEL_4A7B_:
    call display_clear_screen_with_space_char__4875_
    xor  a
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    ld   a, $03
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    ld   c, $00
_LABEL_4A89_:
    ld   a, $01
    ld   [_tilemap_pos_x__RAM_C8CB_], a
_LABEL_4A8E_:
    ld   d, $03
    push bc
    push de
    ld  hl, _TILEMAP0; $9800
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    dec  a
    ld   b, $20
    call multiply_a_x_b__result_in_de__4853_
    add  hl, de
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    ld   e, a
    ld   d, $00
    add  hl, de
    ld   c, $03
    call wait_until_vbl__92C_
_LABEL_4AAB_:
    ld   a, [maybe_vram_data_to_write__RAM_C8CC_]
    ld   b, $03
_LABEL_4AB0_:
    ld   [hl], a
    inc  a
    inc  hl
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    dec  b
    jr   nz, _LABEL_4AB0_
    xor  d
    ld   e, $1D
    add  hl, de
    dec  c
    jr   nz, _LABEL_4AAB_
    pop  de
    pop  bc
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    add  $05
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    inc  c
    ld   a, [_RAM_D06D_]    ; _RAM_D06D_ = $D06D
    cp   c
    jr   z, _LABEL_4AE6_
    ld   a, c
    cp   $04
    jr   z, _LABEL_4ADC_
    cp   $08
    jr   z, _LABEL_4ADC_
    jr   _LABEL_4A8E_

_LABEL_4ADC_:
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    add  $05
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    jr   _LABEL_4A89_

; TODO: maybe initializing the main menu
_LABEL_4AE6_:
    ld   a, $28
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    ld   a, $09
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    call _LABEL_4CD1_
    ldh  a, [rLCDC]
    and  $CF
    or   $C1
    ldh  [rLCDC], a
    xor  a
    ld   [_RAM_D06E_], a    ; TODO: maybe main menu action index
    ld   [_RAM_D05D_], a    ; _RAM_D05D_ = $D05D
    ld   [_RAM_D05E_], a    ; _RAM_D05E_ = $D05E
    ld   [_RAM_D05C_], a    ; _RAM_D05C_ = $D05C
    ld   [_RAM_D05B_], a    ; _RAM_D05B_ = $D05B
    call maybe_input_wait_for_keys__4B84
; TODO: maybe this is the main menu loop
_LABEL_4B0E_:
    call timer_wait_tick_AND_TODO__289_
    call input_read_keys__C8D_
    ld   hl, _RAM_D06D_ ; _RAM_D06D_ = $D06D
    ld   a, [input_key_pressed__RAM_D025_]

    cp   SYS_CHAR_ENTRA_CR  ; $2E
    jp   z, _LABEL_4C83_

    cp   SYS_CHAR_SALIDA  ; $2A
    jp   z, _LABEL_4C76_

    cp   SYS_CHAR_PRINTSCREEN  ; $2F
    jp   z, _LABEL_4C70_

    sub  $30  ; TODO: possibly SYS_CHAR_FUNCTION_KEYS_START
    jr   c, _LABEL_4B36_
    cp   [hl]
    jr   nc, _LABEL_4B36_
    ld   [_RAM_D06E_], a
    jp   _LABEL_4C83_

_LABEL_4B36_:
    call input_map_keycodes_to_gamepad_buttons__4D30_
    ld   a, [buttons_new_pressed__RAM_D006_]
    ; Mask out to U/D/L/R/SEL only
    and  (PADF_DOWN | PADF_UP | PADF_LEFT | PADF_RIGHT | PADF_SELECT) ; $F4
    jr   nz, _LABEL_4B4F_
    xor  a
    ld   [_RAM_D05D_], a    ; _RAM_D05D_ = $D05D
    ld   [_RAM_D05E_], a    ; _RAM_D05E_ = $D05E
    ld   [_RAM_D05C_], a    ; _RAM_D05C_ = $D05C
    ld   [_RAM_D05B_], a    ; _RAM_D05B_ = $D05B
    jr   _LABEL_4B0E_

_LABEL_4B4F_:
    bit  2, a
    jp   nz, _LABEL_4C83_
    call _LABEL_4C87_
    ld   a, [_RAM_D05E_]    ; _RAM_D05E_ = $D05E
    cp   $01
    jr   z, _LABEL_4B92_
    ld   a, [_RAM_D05D_]    ; _RAM_D05D_ = $D05D
    cp   $01
    jr   z, _LABEL_4BD7_
    ld   a, [_RAM_D05C_]    ; _RAM_D05C_ = $D05C
    cp   $01
    jp   z, _LABEL_4C47_
    ld   a, [_RAM_D05B_]    ; _RAM_D05B_ = $D05B
    cp   $01
    jp   z, _LABEL_4C1A_
    jp   _LABEL_4B0E_


_LABEL_4B78_:
    call timer_wait_tick_AND_TODO__289_
    call timer_wait_tick_AND_TODO__289_
    call timer_wait_tick_AND_TODO__289_
    jp   _LABEL_4B0E_


; TODO: Maybe waits for an input key press
maybe_input_wait_for_keys__4B84:
    call timer_wait_tick_AND_TODO__289_
    call input_read_keys__C8D_
    ld   a, [input_key_pressed__RAM_D025_]
    cp   SYS_CHAR_NO_DATA_OR_KEY  ; $FF
    jr   nz, maybe_input_wait_for_keys__4B84
    ret

_LABEL_4B92_:
    xor  a
    ld   [_RAM_D05E_], a    ; _RAM_D05E_ = $D05E
    ld   a, [_RAM_D06E_]
    inc  a
    ld   hl, _RAM_D06D_ ; _RAM_D06D_ = $D06D
    cp   [hl]
    jp   nc, _LABEL_4B0E_
    push af
    ld   [_RAM_D06E_], a
    ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call _LABEL_953_
    call _LABEL_4D19_
    pop  af
    cp   $04
    jr   z, _LABEL_4BC4_
    cp   $08
    jr   z, _LABEL_4BC4_
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    add  $28
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    jr   _LABEL_4BD1_

_LABEL_4BC4_:
    ld   a, $09
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    add  $28
    ld   [_tilemap_pos_y__RAM_C8CA_], a
_LABEL_4BD1_:
    call _LABEL_4CD1_
    jp   _LABEL_4B78_

_LABEL_4BD7_:
    xor  a
    ld   [_RAM_D05D_], a    ; _RAM_D05D_ = $D05D
    ld   a, [_RAM_D06E_]
    dec  a
    cp   $FF
    jp   z, _LABEL_4B0E_
    push af
    ld   [_RAM_D06E_], a
    ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call _LABEL_953_
    call _LABEL_4D19_
    pop  af
    cp   $07
    jr   z, _LABEL_4C07_
    cp   $03
    jr   z, _LABEL_4C07_
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    sub  $28
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    jr   _LABEL_4C14_

_LABEL_4C07_:
    ld   a, $81
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    sub  $28
    ld   [_tilemap_pos_y__RAM_C8CA_], a
_LABEL_4C14_:
    call _LABEL_4CD1_
    jp   _LABEL_4B78_

_LABEL_4C1A_:
    xor  a
    ld   [_RAM_D05B_], a    ; _RAM_D05B_ = $D05B
    ld   a, [_RAM_D06E_]
    add  $04
    ld   hl, _RAM_D06D_ ; _RAM_D06D_ = $D06D
    cp   [hl]
    jp   nc, _LABEL_4B0E_
    ld   [_RAM_D06E_], a
    ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call _LABEL_953_
    call _LABEL_4D19_
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    add  $28
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    call _LABEL_4CD1_
    jp   _LABEL_4B78_

_LABEL_4C47_:
    xor  a
    ld   [_RAM_D05C_], a    ; _RAM_D05C_ = $D05C
    ld   a, [_RAM_D06E_]
    sub  $04
    jp   c, _LABEL_4B0E_
    ld   [_RAM_D06E_], a
    ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call _LABEL_953_
    call _LABEL_4D19_
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    sub  $28
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    call _LABEL_4CD1_
    jp   _LABEL_4B78_

_LABEL_4C70_:
    call maybe_call_printscreen_in_32k_bank_2__522_
    jp   _LABEL_4B0E_

_LABEL_4C76_:
    ld   a, [_RAM_D06C_]    ; _RAM_D06C_ = $D06C
    and  a
    jp   z, _LABEL_4B0E_
    ld   a, [_RAM_D06D_]    ; _RAM_D06D_ = $D06D
    ld   [_RAM_D06E_], a
_LABEL_4C83_:
    call _LABEL_4D19_
    ret

_LABEL_4C87_:
    bit  4, a
    jr   z, _LABEL_4C93_
    ld   a, [_RAM_D05E_]    ; _RAM_D05E_ = $D05E
    inc  a
    res  7, a
    jr   _LABEL_4C94_

_LABEL_4C93_:
    xor  a
_LABEL_4C94_:
    ld   [_RAM_D05E_], a    ; _RAM_D05E_ = $D05E
    ld   a, [buttons_new_pressed__RAM_D006_]
    bit  5, a
    jr   z, _LABEL_4CA6_
    ld   a, [_RAM_D05D_]    ; _RAM_D05D_ = $D05D
    inc  a
    res  7, a
    jr   _LABEL_4CA7_

_LABEL_4CA6_:
    xor  a
_LABEL_4CA7_:
    ld   [_RAM_D05D_], a    ; _RAM_D05D_ = $D05D
    ld   a, [buttons_new_pressed__RAM_D006_]
    bit  6, a
    jr   z, _LABEL_4CB9_
    ld   a, [_RAM_D05C_]    ; _RAM_D05C_ = $D05C
    inc  a
    res  7, a
    jr   _LABEL_4CBA_

_LABEL_4CB9_:
    xor  a
_LABEL_4CBA_:
    ld   [_RAM_D05C_], a    ; _RAM_D05C_ = $D05C
    ld   a, [buttons_new_pressed__RAM_D006_]
    bit  7, a
    jr   z, _LABEL_4CCC_
    ld   a, [_RAM_D05B_]    ; _RAM_D05B_ = $D05B
    inc  a
    res  7, a
    jr   _LABEL_4CCD_

_LABEL_4CCC_:
    xor  a
_LABEL_4CCD_:
    ld   [_RAM_D05B_], a    ; _RAM_D05B_ = $D05B
    ret

_LABEL_4CD1_:
    ld   a, $ED
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    xor  a
    ld   [_RAM_C8CD_], a    ; _RAM_C8CD_ = $C8CD
    ld   hl, _RAM_D05F_ ; _RAM_D05F_ = $D05F
    ld   b, $02
_LABEL_4CDF_:
    push bc
    push hl
    call oam_find_slot_and_load_into__86F
    pop  hl
    ld   a, b
    ldi  [hl], a
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    add  $08
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   a, [maybe_vram_data_to_write__RAM_C8CC_]
    inc  a
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    push hl
    call oam_find_slot_and_load_into__86F
    pop  hl
    ld   a, b
    ldi  [hl], a
    pop  bc
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    add  $08
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    sub  $08
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   a, [maybe_vram_data_to_write__RAM_C8CC_]
    inc  a
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    dec  b
    jr   nz, _LABEL_4CDF_
    ret

; TODO: is this lookup for writing strings
_LABEL_4D19_:
    ld   c, $04
    ld   hl, _RAM_D05F_ ; _RAM_D05F_ = $D05F
_LABEL_4D1E_:
    ld   a, [hl]
    ld   [hl], $00
    inc  hl
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    push hl
    push bc
    call oam_free_slot_and_clear__89B_
    pop  bc
    pop  hl
    dec  c
    jr   nz, _LABEL_4D1E_
    ret

; Maps keycode input to D-Pad button presses
;
; - Reads from: input_key_pressed__RAM_D025_
; - Writes to : buttons_new_pressed__RAM_D006_
;
; - Performs opposite function of input_map_gamepad_buttons_to_keycodes__49C2_
;
; Destroys A, HL
input_map_keycodes_to_gamepad_buttons__4D30_:
    ld   a, [input_key_pressed__RAM_D025_]
    ld   hl, buttons_new_pressed__RAM_D006_
    cp   $3D
    jr   nz, check_down__4d3c_
    set  PADB_UP, [hl]  ; 6, [hl]
    check_down__4d3c_:
        cp   SYS_CHAR_DOWN  ; $40
        jr   nz, check_left__4d42_
        set  PADB_DOWN, [hl]  ; 7, [hl]

    check_left__4d42_:
        cp   SYS_CHAR_LEFT  ; $3E
        jr   nz, check_right__4d48_
        set  PADB_LEFT, [hl]  ; 5, [hl]

    check_right__4d48_:
        cp   SYS_CHAR_RIGHT  ; $3F
        jr   nz, check_up_left__4d4e_
        set  PADB_RIGHT, [hl]  ; 4, [hl]

    check_up_left__4d4e_:
        cp   SYS_CHAR_UP_LEFT  ; $CD
        jr   nz, check_up_right__4d56_
        set  PADB_LEFT, [hl]  ; 5, [hl]
        set  PADB_UP, [hl]  ; 6, [hl]

    check_up_right__4d56_:
        cp   SYS_CHAR_UP_RIGHT  ; $CA
        jr   nz, check_down_left__4d5e_
        set  PADB_RIGHT, [hl]  ; 4, [hl]
        set  PADB_UP, [hl]  ; 6, [hl]

    check_down_left__4d5e_:
        cp   SYS_CHAR_DOWN_LEFT  ; $CC
        jr   nz, check_down_right__4d66_
        set  PADB_LEFT, [hl]  ; 5, [hl]
        set  PADB_DOWN, [hl]  ; 7, [hl]

    check_down_right__4d66_:
        cp   SYS_CHAR_DOWN_RIGHT  ; $CB
        jr   nz, done__4D6E_
        set  PADB_RIGHT, [hl]  ; 4, [hl]
        set  PADB_DOWN, [hl]  ; 7, [hl]
    done__4D6E_:
        ret


_LABEL_4D6F_:
    ld   a, [_RAM_DBFB_]    ; _RAM_DBFB_ = $DBFB
    bit  2, a
    jr   nz, _LABEL_4D7F_
    set  2, a
    ld   [_RAM_DBFB_], a    ; _RAM_DBFB_ = $DBFB
    xor  a
    ld   [_RAM_DBFF_], a    ; _RAM_DBFF_ = $DBFF
    _LABEL_4D7F_:
        xor  a
        ld   [_RAM_D05D_], a    ; _RAM_D05D_ = $D05D
        ld   [_RAM_D05E_], a    ; _RAM_D05E_ = $D05E
        ld   [_RAM_D05C_], a    ; _RAM_D05C_ = $D05C
        ld   [_RAM_D05B_], a    ; _RAM_D05B_ = $D05B
        ld   [_RAM_D03B_], a
        ld   a, SYS_CMD_RTC_GET_DATE_AND_TIME  ; $0C
        ld   [serial_rx_cmd_to_send__RAM_D036_], a

        ; Received data will be in buffer__RAM_D028_
        receive_loop_wait_valid_reply_4D94_:
            call serial_io_send_command_and_receive_buffer__AEF_
            ld   a, [input_key_pressed__RAM_D025_]
            cp   SYS_CHAR_SERIAL_RX_SUCCESS  ; $F9
            jr   nz, receive_loop_wait_valid_reply_4D94_

        ; Load Tile Data for the main menu font
        call wait_until_vbl__92C_
        call display_screen_off__94C_
        ld   hl, _TILEDATA8800                         ; Dest
        ld   de, gfx_tile_data__main_menu_font__2F2A_   ; Source
        ld   bc, (MENU_FONT_128_TILES * TILE_SZ_BYTES) ; Copy size: 128 tiles (2048 bytes)
        call _memcopy_in_RAM__C900_

        ; GFX Loading 128 Tiles (only 115 intended though?) of 8x16 font
        ;
        ; Note: This accidentally(?) copies more tiles than are in the the tile
        ;       set blob so it picks up the first 13 tiles of the  following 8x8 font (at 0x2FA).
        call wait_until_vbl__92C_
        call display_screen_off__94C_
        ld   hl, _TILEDATA9000                                ; Dest
        ld   de, tile_data_0x27fa_1840_bytes_8x16_font__27FA_ ; Source
        ld   bc, (128 * TILE_SZ_BYTES)                        ; Copy size: 128 tiles (2048 bytes)
        call _memcopy_in_RAM__C900_

        ; Copy first 3 bytes (Year, Month, Day) of received RTC data
        ; from Serial IO RX buffer to _RAM_D075_ ...
        ld   hl, buffer__RAM_D028_
        ld   de, _RAM_D074_ + 1
        ld   b, $03
        call memcopy_b_bytes_from_hl_to_de__482B_

    _LABEL_4DCD_:
        call display_clear_screen_with_space_char__4875_

        ; Load 10 8x8 numeric character Tiles
        call wait_until_vbl__92C_
        call display_screen_off__94C_

        ld   hl, tile_data_0x275A_160_bytes_8x8_num_chars__275A_   ;Source
        ld   de, _TILEDATA8800 + (113 * TILE_SZ_BYTES)  ; $8F10    ; Start loading 113 tiles into 8800 range
        ld   b, $A0                                                ; Copy size: 10 tiles (160 bytes)
        call memcopy_b_bytes_from_hl_to_de__482B_


        ; Fill 2 (visible portion of) rows of Tilemap with Tile Pattern $18
        ld   hl, _TILEMAP0 + _TILEMAP_WIDTH  ; Start in 2nd row in Tilemap  ; $9820
        ld   bc, $1002  ; Column:Row counters, $10 (16) x 2
        ld   a, $18     ; Tile Pattern ID to load

        tile_row_loop__4DE9_:
            ldi  [hl], a
            dec  b
            jr   nz, tile_row_loop__4DE9_

            ; Advance to next Tilemap Row and reset column counter
            ld   de, (_TILEMAP_WIDTH - $10)  ; $0010
            add  hl, de
            ld   b, $10
            dec  c
            jr   nz, tile_row_loop__4DE9_

        ; Load RX RTC Month
        ; Do a simple conversion from BCD -> Decimal
        ; If left digit is 1 then subtract 6 to convert. Ex. 0x10 - 6 = 0xA (10)
        ld   a, [buffer__RAM_D028_ + 1]  ; Should be RTC Month from last Serial IO RX data buffer
        bit  4, a
        jr   z, rtc_month_less_than_10__4DFF_
        sub  $06

    rtc_month_less_than_10__4DFF_:
        ; TODO: Probably rendering the month onto the Tilemap
        dec  a
        ld   b, $03
        call multiply_a_x_b__result_in_de__4853_
        ld   hl, _DATA_5E31_    ; _DATA_5E31_ = $5E31
        add  hl, de
        ld   d, h
        ld   e, l
        ld   b, $03
        ld   hl, $982B
    _LABEL_4E10_:
        ld   a, [de]
        inc  de
        sub  $81
        sla  a
        add  $1A
        ld   c, $00
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        push de
        call maybe__vram_write_byte_2rows_addr_in_hl_preset_data__5494_
        pop  de
        inc  hl
        dec  b
        jr   nz, _LABEL_4E10_

        ld   hl, _TILEMAP0 + $30 ; $9830

        ; Load RX RTC Year
        ; Do a simple conversion from BCD -> Decimal
        ; If left digit is 1 then subtract 6 to convert. Ex. 0x10 - 6 = 0xA (10)
        ld   a, [buffer__RAM_D028_]  ; Should be RTC Year from last Serial IO RX data buffer
        ; Check if left digit is in "9" (i.e. 1990-1999) year range
        and  $F0
        cp   $90
        jr   nz, maybe_year_is_1990_1999__4E3E_

        ; ? Otherwise year is assumed to be in 2000+ range
        ld   a, $02
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        call maybe__vram_write_byte_2rows_addr_in_hl_preset_data__5494_
        ld   a, $12
        jr   _LABEL_4E48_

    maybe_year_is_1990_1999__4E3E_:
        ld   a, $04
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        call maybe__vram_write_byte_2rows_addr_in_hl_preset_data__5494_
        ld   a, $00

    _LABEL_4E48_:
        inc  hl
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        call maybe__vram_write_byte_2rows_addr_in_hl_preset_data__5494_
        ld   a, $10
        ld   [_tilemap_pos_x__RAM_C8CB_], a
        ld   a, $02
        ld   [_tilemap_pos_y__RAM_C8CA_], a
        ld   c, $01

        ld   hl, buffer__RAM_D028_
        call _LABEL_5401_
        ld   hl, $9880
        ld   b, $07
        ld   de, _DATA_5E19_    ; _DATA_5E19_ = $5E19
    _LABEL_4E69_:
        ld   a, [de]
        inc  de
        ldi  [hl], a
        ld   a, [de]
        inc  de
        inc  de
        ldi  [hl], a
        inc  hl
        dec  b
        jr   nz, _LABEL_4E69_

        ; Save RX Serial IO RTC data to shadow RTC data
        ld   a, [buffer__RAM_D028_]
        ld   [shadow_rtc_buf_start_and_year__RAM_D051_], a

        ld   a, [_RAM_D029_]
        ld   [shadow_rtc_month__RAM_D052_], a

        ; Force day to the 1st (not yet sure why)
        ld   a, $01
        ld   [shadow_rtc_day__RAM_D053_], a

        call rtc_calc_day_of_week_for_current_date__5A9F_
        ld   a, [shadow_rtc_dayofweek__RAM_D054_]
        dec  a
        ld   [shadow_rtc_dayofweek__RAM_D054_], a

        ld   a, [de]
        ld   [_RAM_D06D_], a

        ld   e, a
        ld   d, $00
        ld   h, $0A
        call divide_de_by_h_result_in_bc_remainder_in_l__4832_
        ld   a, c
        swap a
        or   l
        ld   [_RAM_D03A_], a
        xor  a
        ld   [_RAM_D06E_], a
        ld   a, $07
        ld   [_tilemap_pos_y__RAM_C8CA_], a
    _LABEL_4EAB_:
        ld   a, [shadow_rtc_dayofweek__RAM_D054_]
        ld   b, $03
        call multiply_a_x_b__result_in_de__4853_
        ld   a, e
        sub  $02
        ld   [_tilemap_pos_x__RAM_C8CB_], a
        ld   a, [_RAM_D03B_]
        and  a
        jr   nz, _LABEL_4ED4_
        ld   a, [shadow_rtc_day__RAM_D053_]    ; shadow_rtc_day__RAM_D053_ = $D053
        ld   hl, _RAM_D074_ + 3
        cp   [hl]
        jr   nz, _LABEL_4ED4_
        ld   a, [_tilemap_pos_x__RAM_C8CB_]
        ld   [_RAM_D073_], a    ; _RAM_D073_ = $D073
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        ld   [_RAM_D074_], a
    _LABEL_4ED4_:
        ld   a, [shadow_rtc_day__RAM_D053_]    ; shadow_rtc_day__RAM_D053_ = $D053
        cp   $01
        jr   nz, _LABEL_4F29_
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        ld   [_RAM_D06E_ + 2], a    ; _RAM_D06E_ + 2 = $D070
        add  $02
        sla  a
        sla  a
        sla  a
        ld   [_tilemap_pos_y__RAM_C8CA_], a
        ld   a, [_tilemap_pos_x__RAM_C8CB_]
        ld   [_RAM_D06E_ + 1], a    ; _RAM_D06E_ + 1 = $D06F
        add  $04
        sla  a
        sla  a
        sla  a
        ld   [_tilemap_pos_x__RAM_C8CB_], a
        xor  a
        ld   [_RAM_C8CD_], a    ; _RAM_C8CD_ = $C8CD
        ld   a, $80
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        call _LABEL_623_
        ld   a, b
        ld   [_RAM_D05F_], a    ; _RAM_D05F_ = $D05F
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        ld   b, a
        ld   a, [_RAM_D06E_ + 2]    ; _RAM_D06E_ + 2 = $D070
        ld   [_tilemap_pos_y__RAM_C8CA_], a
        ld   a, b
        ld   [_RAM_D06E_ + 2], a    ; _RAM_D06E_ + 2 = $D070
        ld   a, [_tilemap_pos_x__RAM_C8CB_]
        ld   b, a
        ld   a, [_RAM_D06E_ + 1]    ; _RAM_D06E_ + 1 = $D06F
        ld   [_tilemap_pos_x__RAM_C8CB_], a
        ld   a, b
        ld   [_RAM_D06E_ + 1], a    ; _RAM_D06E_ + 1 = $D06F
    _LABEL_4F29_:
        call _LABEL_532F_
        cp   $00
        jr   nz, _LABEL_4F3A_
        ld   hl, shadow_rtc_day__RAM_D053_ ; shadow_rtc_day__RAM_D053_ = $D053
        ld   c, $02
        call _LABEL_5401_
        jr   _LABEL_4F3D_

    _LABEL_4F3A_:
        call _LABEL_52F5_
    _LABEL_4F3D_:
        ld   a, [shadow_rtc_day__RAM_D053_]    ; shadow_rtc_day__RAM_D053_ = $D053
        and  $0F
        inc  a
        cp   $0A
        ld   a, [shadow_rtc_day__RAM_D053_]    ; shadow_rtc_day__RAM_D053_ = $D053
        jr   z, _LABEL_4F4D_
        inc  a
        jr   _LABEL_4F51_

    _LABEL_4F4D_:
        and  $F0
        add  $10
    _LABEL_4F51_:
        ld   [shadow_rtc_day__RAM_D053_], a    ; shadow_rtc_day__RAM_D053_ = $D053
        ld   b, a
        ld   a, [_RAM_D03A_]
        cp   b
        jr   c, _LABEL_4F72_
        ld   a, [shadow_rtc_dayofweek__RAM_D054_]    ; shadow_rtc_dayofweek__RAM_D054_ = $D054
        inc  a
        cp   $07
        jr   nz, _LABEL_4F6C_
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        add  $02
        ld   [_tilemap_pos_y__RAM_C8CA_], a
        xor  a
    _LABEL_4F6C_:
        ld   [shadow_rtc_dayofweek__RAM_D054_], a    ; shadow_rtc_dayofweek__RAM_D054_ = $D054
        jp   _LABEL_4EAB_

    _LABEL_4F72_:
        ld   a, [_tilemap_pos_x__RAM_C8CB_]
        inc  a
        sla  a
        sla  a
        sla  a
        ld   [_RAM_D06E_ + 3], a    ; _RAM_D06E_ + 3 = $D071
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        add  $02
        sla  a
        sla  a
        sla  a
        ld   [_RAM_D072_], a
        ld   a, $01
        ld   [_RAM_D03A_], a
        call _display_bg_sprites_on__627_
    _LABEL_4F95_:
        call timer_wait_tick_AND_TODO__289_
        call input_read_keys__C8D_
        ld   a, [_RAM_D074_ + 1]
        ld   hl, buffer__RAM_D028_
        cp   [hl]
        jr   nz, _LABEL_4FAE_
        ld   a, [_RAM_D074_ + 2]
        inc  hl
        cp   [hl]
        jr   nz, _LABEL_4FAE_
        call _LABEL_538C_
    _LABEL_4FAE_:
        ld   a, [input_key_pressed__RAM_D025_]
        cp   SYS_CHAR_PRINTSCREEN  ; $2F
        jp   nz, _LABEL_4FEE_
        ld   a, [_RAM_D074_ + 1]
        push af
        ld   a, [_RAM_D074_ + 2]
        push af
        ld   a, [_RAM_D074_ + 3]
        push af
        ld   a, [buffer__RAM_D028_]
        push af
        ld   a, [_RAM_D029_]    ; _RAM_D029_ = $D029
        push af
        ld   a, [buffer__RAM_D028_ + 2]    ; buffer__RAM_D028_ + 2 = $D02A
        push af
        call _LABEL_52BF_
        call maybe_input_wait_for_keys__4B84
        pop  af
        ld   [buffer__RAM_D028_ + 2], a    ; buffer__RAM_D028_ + 2 = $D02A
        pop  af
        ld   [_RAM_D029_], a    ; _RAM_D029_ = $D029
        pop  af
        ld   [buffer__RAM_D028_], a
        pop  af
        ld   [_RAM_D074_ + 3], a
        pop  af
        ld   [_RAM_D074_ + 2], a
        pop  af
        ld   [_RAM_D074_ + 1], a
        jr   _LABEL_4F95_

    _LABEL_4FEE_:
        ; Alias SYS_CHAR_GPAD_SELECT
        cp   SYS_CHAR_ENTRA_CR  ; $2E
        jp   z, _LABEL_51B0_

        ; Alias SYS_CHAR_GPAD_START
        cp   SYS_CHAR_SALIDA  ; $2A
        jp   z, _LABEL_52B5_

        ; Alias SYS_CHAR_GPAD_A
        cp   SYS_CHAR_PG_ARRIBA  ; $44
        jp   z, _LABEL_522B_

        ; Alias SYS_CHAR_GPAD_B
        cp   SYS_CHAR_PG_ABAJO  ; $45
        jp   z, _LABEL_526F_

        call input_map_keycodes_to_gamepad_buttons__4D30_
        ld   a, [buttons_new_pressed__RAM_D006_]
        and  $F7
        jr   nz, _LABEL_5022_
        xor  a
        ld   [_RAM_D05D_], a    ; _RAM_D05D_ = $D05D
        ld   [_RAM_D05E_], a    ; _RAM_D05E_ = $D05E
        ld   [_RAM_D05B_], a    ; _RAM_D05B_ = $D05B
        ld   [_RAM_D05C_], a    ; _RAM_D05C_ = $D05C
        call delay_quarter_msec__BD6_
        call delay_quarter_msec__BD6_
        jp   _LABEL_4F95_

    _LABEL_5022_:
        ld   a, [buttons_new_pressed__RAM_D006_]
        bit  PADB_SELECT, a  ; 2, a
        jp   nz, _LABEL_51B0_
        bit  PADB_A, a  ; 0, a
        jp   nz, _LABEL_522B_
        bit  PADB_B, a  ; 1, a
        jp   nz, _LABEL_526F_

        call _LABEL_4C87_
        ld   a, [_RAM_D05E_]    ; _RAM_D05E_ = $D05E
        cp   $01
        jr   z, _LABEL_5059_
        ld   a, [_RAM_D05D_]    ; _RAM_D05D_ = $D05D
        cp   $01
        jp   z, _LABEL_50C3_
        ld   a, [_RAM_D05C_]    ; _RAM_D05C_ = $D05C
        cp   $01
        jp   z, _LABEL_5167_
        ld   a, [_RAM_D05B_]    ; _RAM_D05B_ = $D05B
        cp   $01
        jp   z, _LABEL_511F_
        jp   _LABEL_4F95_

    _LABEL_5059_:
        xor  a
        ld   [_RAM_D05E_], a    ; _RAM_D05E_ = $D05E
        ld   a, [_RAM_D06E_]
        inc  a
        ld   hl, _RAM_D06D_ ; _RAM_D06D_ = $D06D
        cp   [hl]
        jr   nc, _LABEL_5096_
        ld   [_RAM_D06E_], a
        ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        call _LABEL_953_
        call oam_free_slot_and_clear__89B_
        ld   a, [_tilemap_pos_x__RAM_C8CB_]
        cp   $A0
        jr   z, _LABEL_5087_
        ld   a, [_tilemap_pos_x__RAM_C8CB_]
        add  $18
        ld   [_tilemap_pos_x__RAM_C8CB_], a
        jr   _LABEL_50AF_

    _LABEL_5087_:
        ld   a, $10
        ld   [_tilemap_pos_x__RAM_C8CB_], a
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        add  $10
        ld   [_tilemap_pos_y__RAM_C8CA_], a
        jr   _LABEL_50AF_

    _LABEL_5096_:
        ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        call oam_free_slot_and_clear__89B_
        xor  a
        ld   [_RAM_D06E_], a
        ld   a, [_RAM_D06E_ + 1]    ; _RAM_D06E_ + 1 = $D06F
        ld   [_tilemap_pos_x__RAM_C8CB_], a
        ld   a, [_RAM_D06E_ + 2]    ; _RAM_D06E_ + 2 = $D070
        ld   [_tilemap_pos_y__RAM_C8CA_], a
    _LABEL_50AF_:
        ld   a, $80
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        call _LABEL_623_
        ld   a, b
        ld   [_RAM_D05F_], a    ; _RAM_D05F_ = $D05F
        ld   a, $03
        call _LABEL_4A72_
        jp   _LABEL_4F95_

    _LABEL_50C3_:
        xor  a
        ld   [_RAM_D05D_], a    ; _RAM_D05D_ = $D05D
        ld   a, [_RAM_D06E_]
        dec  a
        cp   $FF
        jr   z, _LABEL_5100_
        ld   [_RAM_D06E_], a
        ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        call _LABEL_953_
        call oam_free_slot_and_clear__89B_
        ld   a, [_tilemap_pos_x__RAM_C8CB_]
        cp   $10
        jr   z, _LABEL_50F0_
        ld   a, [_tilemap_pos_x__RAM_C8CB_]
        sub  $18
        ld   [_tilemap_pos_x__RAM_C8CB_], a
        jp   _LABEL_50AF_

    _LABEL_50F0_:
        ld   a, $A0
        ld   [_tilemap_pos_x__RAM_C8CB_], a
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        sub  $10
        ld   [_tilemap_pos_y__RAM_C8CA_], a
        jp   _LABEL_50AF_

    _LABEL_5100_:
        ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        call oam_free_slot_and_clear__89B_
        ld   a, [_RAM_D06D_]    ; _RAM_D06D_ = $D06D
        dec  a
        ld   [_RAM_D06E_], a
        ld   a, [_RAM_D06E_ + 3]    ; _RAM_D06E_ + 3 = $D071
        ld   [_tilemap_pos_x__RAM_C8CB_], a
        ld   a, [_RAM_D072_]
        ld   [_tilemap_pos_y__RAM_C8CA_], a
        jp   _LABEL_50AF_

    _LABEL_511F_:
        xor  a
        ld   [_RAM_D05B_], a    ; _RAM_D05B_ = $D05B
        ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        call _LABEL_953_
        call oam_free_slot_and_clear__89B_
        ld   a, [_RAM_D06E_]
        add  $07
        ld   hl, _RAM_D06D_ ; _RAM_D06D_ = $D06D
        cp   [hl]
        jr   nc, _LABEL_5148_
        ld   [_RAM_D06E_], a
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        add  $10
        ld   [_tilemap_pos_y__RAM_C8CA_], a
        jp   _LABEL_50AF_

    _LABEL_5148_:
        ld   a, [_RAM_D06E_]
        ld   e, a
        ld   d, $00
        ld   h, $07
        call divide_de_by_h_result_in_bc_remainder_in_l__4832_
        ld   a, c
        ld   b, $10
        call multiply_a_x_b__result_in_de__4853_
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        sub  e
        ld   [_tilemap_pos_y__RAM_C8CA_], a
        ld   a, l
        ld   [_RAM_D06E_], a
        jp   _LABEL_50AF_

    _LABEL_5167_:
        xor  a
        ld   [_RAM_D05C_], a    ; _RAM_D05C_ = $D05C
        ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        call _LABEL_953_
        call oam_free_slot_and_clear__89B_
        ld   a, [_RAM_D06E_]
        sub  $07
        jr   c, _LABEL_518C_
        ld   [_RAM_D06E_], a
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        sub  $10
        ld   [_tilemap_pos_y__RAM_C8CA_], a
        jp   _LABEL_50AF_

    _LABEL_518C_:
        ld   a, [_RAM_D06E_]
        ld   b, $00
        ld   hl, _RAM_D06D_ ; _RAM_D06D_ = $D06D
    _LABEL_5194_:
        add  $07
        cp   [hl]
        jr   nc, _LABEL_519C_
        inc  b
        jr   _LABEL_5194_

    _LABEL_519C_:
        sub  $07
        ld   [_RAM_D06E_], a
        ld   a, $10
        call multiply_a_x_b__result_in_de__4853_
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        add  e
        ld   [_tilemap_pos_y__RAM_C8CA_], a
        jp   _LABEL_50AF_

    _LABEL_51B0_:
        ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        call _LABEL_953_
        ld   a, [_tilemap_pos_x__RAM_C8CB_]
        cp   $A0
        jp   z, _LABEL_4F95_
        ld   a, [_RAM_D06E_]
        inc  a
        ld   e, a
        ld   d, $00
        ld   h, $0A
        call divide_de_by_h_result_in_bc_remainder_in_l__4832_
        ld   a, c
        swap a
        or   l
        ld   [shadow_rtc_day__RAM_D053_], a    ; shadow_rtc_day__RAM_D053_ = $D053
        ld   a, $01
        ld   [shadow_rtc_dayofweek__RAM_D054_], a    ; shadow_rtc_dayofweek__RAM_D054_ = $D054
        call _LABEL_532F_
        and  a
        jr   z, _LABEL_5206_
        ld   e, l
        ld   d, h
        dec  hl
        dec  hl
        dec  hl
    _LABEL_51E4_:
        ld   a, [de]
        ldi  [hl], a
        inc  de
        ld   a, e
        cp   $FD
        jr   nz, _LABEL_51E4_
        ld   a, [_RAM_DBFF_]    ; _RAM_DBFF_ = $DBFF
        dec  a
        ld   [_RAM_DBFF_], a    ; _RAM_DBFF_ = $DBFF
        call _LABEL_535C_
        ld   hl, shadow_rtc_day__RAM_D053_ ; shadow_rtc_day__RAM_D053_ = $D053
        ld   c, $02
        call _LABEL_5401_
        ld   a, $03
        call _LABEL_4A72_
        jp   _LABEL_4F95_

    _LABEL_5206_:
        ld   a, [_RAM_DBFF_]    ; _RAM_DBFF_ = $DBFF
        cp   $1E
        jp   nc, _LABEL_4F95_
        inc  a
        ld   [_RAM_DBFF_], a    ; _RAM_DBFF_ = $DBFF
        ld   de, shadow_rtc_buf_start_and_year__RAM_D051_ ; shadow_rtc_buf_start_and_year__RAM_D051_ = $D051
        ld   b, $03
    _LABEL_5217_:
        ld   a, [de]
        ldi  [hl], a
        inc  de
        dec  b
        jr   nz, _LABEL_5217_
        call _LABEL_535C_
        call _LABEL_52F5_
        ld   a, $03
        call _LABEL_4A72_
        jp   _LABEL_4F95_

    _LABEL_522B_:
        ld   hl, _RAM_D029_ ; _RAM_D029_ = $D029
        call convert_bcd2dec_at_hl_result_in_a__5B03_
        dec  a
        jr   nz, _LABEL_525D_
        ld   hl, buffer__RAM_D028_
        call convert_bcd2dec_at_hl_result_in_a__5B03_
        cp   $0C
        jr   nc, _LABEL_5240_
        add  $64
    _LABEL_5240_:
        dec  a
        cp   $5C
        jp   c, _LABEL_4F95_
        call _LABEL_5379_
        ld   [buffer__RAM_D028_], a
        ld   a, $12
        ld   [_RAM_D029_], a    ; _RAM_D029_ = $D029
        ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        call oam_free_slot_and_clear__89B_
        jp   _LABEL_4DCD_

    _LABEL_525D_:
        call _LABEL_5379_
        ld   [_RAM_D029_], a    ; _RAM_D029_ = $D029
        ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        call oam_free_slot_and_clear__89B_
        jp   _LABEL_4DCD_

    _LABEL_526F_:
        ld   hl, _RAM_D029_ ; _RAM_D029_ = $D029
        call convert_bcd2dec_at_hl_result_in_a__5B03_
        inc  a
        cp   $0D
        jr   c, _LABEL_52A3_
        ld   hl, buffer__RAM_D028_
        call convert_bcd2dec_at_hl_result_in_a__5B03_
        cp   $0C
        jr   nc, _LABEL_5286_
        add  $64
    _LABEL_5286_:
        inc  a
        cp   $70
        jp   z, _LABEL_4F95_
        call _LABEL_5379_
        ld   [buffer__RAM_D028_], a
        ld   a, $01
        ld   [_RAM_D029_], a    ; _RAM_D029_ = $D029
        ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        call oam_free_slot_and_clear__89B_
        jp   _LABEL_4DCD_

    _LABEL_52A3_:
        call _LABEL_5379_
        ld   [_RAM_D029_], a    ; _RAM_D029_ = $D029
        ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        call oam_free_slot_and_clear__89B_
        jp   _LABEL_4DCD_

    _LABEL_52B5_:
        ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        call oam_free_slot_and_clear__89B_
        ret

    _LABEL_52BF_:
        ld   a, [_RAM_D074_ + 1]
        ld   hl, buffer__RAM_D028_
        cp   [hl]
        jr   nz, _LABEL_52D7_
        ld   a, [_RAM_D074_ + 2]
        inc  hl
        cp   [hl]
        jr   nz, _LABEL_52D7_
        ld   a, $07
        ld   [_RAM_D04A_], a    ; _RAM_D04A_ = $D04A
        call _LABEL_538C_
    _LABEL_52D7_:
        ld   a, [buffer__RAM_D028_ + 3]    ; buffer__RAM_D028_ + 3 = $D02B
        push af
        call maybe_call_printscreen_in_32k_bank_2__522_
        pop  af
        ld   [buffer__RAM_D028_ + 3], a    ; buffer__RAM_D028_ + 3 = $D02B
        ld   a, [_RAM_D074_ + 1]
        ld   [buffer__RAM_D028_], a
        ld   a, [_RAM_D074_ + 2]
        ld   [_RAM_D029_], a    ; _RAM_D029_ = $D029
        ld   a, [_RAM_D074_ + 3]
        ld   [buffer__RAM_D028_ + 2], a    ; buffer__RAM_D028_ + 2 = $D02A
        ret

_LABEL_52F5_:
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    add  $02
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   hl, _TILEMAP0; $9800
    call calc_vram_addr_of_tile_xy_base_in_hl__4932_
    ld   a, [shadow_rtc_day__RAM_D053_]    ; shadow_rtc_day__RAM_D053_ = $D053
    swap a
    and  $0F
    jr   z, _LABEL_5310_
    add  $F1
    jr   _LABEL_5312_

_LABEL_5310_:
    ld   a, $BE
_LABEL_5312_:
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call wait_until_vbl__92C_
    ld   a, [maybe_vram_data_to_write__RAM_C8CC_]
    ldi  [hl], a
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    inc  a
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   a, [shadow_rtc_day__RAM_D053_]    ; shadow_rtc_day__RAM_D053_ = $D053
    and  $0F
    add  $F1
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    ld   [hl], a
    ret

_LABEL_532F_:
    ld   hl, $DBA0
    ld   a, [shadow_rtc_dayofweek__RAM_D054_]    ; shadow_rtc_dayofweek__RAM_D054_ = $D054
    cp   $06
    jr   z, _LABEL_5359_
    ld   a, [_RAM_DBFF_]    ; _RAM_DBFF_ = $DBFF
    and  a
    jr   z, _LABEL_5357_
    ld   b, a
_LABEL_5340_:
    ld   de, shadow_rtc_buf_start_and_year__RAM_D051_ ; shadow_rtc_buf_start_and_year__RAM_D051_ = $D051
    ld   c, $03
_LABEL_5345_:
    ld   a, [de]
    cp   [hl]
    jr   nz, _LABEL_5350_
    inc  hl
    inc  de
    dec  c
    jr   nz, _LABEL_5345_
    jr   _LABEL_5359_

_LABEL_5350_:
    ld   a, c
    call add_a_to_hl__486E_
    dec  b
    jr   nz, _LABEL_5340_
_LABEL_5357_:
    xor  a
    ret

_LABEL_5359_:
    ld   a, $01
    ret

_LABEL_535C_:
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    srl  a
    srl  a
    srl  a
    sub  $04
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    srl  a
    srl  a
    srl  a
    sub  $02
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    ret

_LABEL_5379_:
    ld   e, a
    ld   d, $00
    ld   h, $0A
    call divide_de_by_h_result_in_bc_remainder_in_l__4832_
    ld   a, c
    cp   $0A
    jr   c, _LABEL_5388_
    sub  $0A
_LABEL_5388_:
    swap a
    or   l
    ret

_LABEL_538C_:
    ld   a, [_RAM_D073_]    ; _RAM_D073_ = $D073
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   a, [_RAM_D074_]
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    ld   a, [_RAM_D04A_]    ; _RAM_D04A_ = $D04A
    inc  a
    ld   [_RAM_D04A_], a    ; _RAM_D04A_ = $D04A
    and  $0F
    jr   z, _LABEL_53CC_
    cp   $08
    jr   nz, _LABEL_53CB_
    ld   a, [buffer__RAM_D028_ + 2]    ; buffer__RAM_D028_ + 2 = $D02A
    ld   [shadow_rtc_day__RAM_D053_], a    ; shadow_rtc_day__RAM_D053_ = $D053
    ld   a, [buffer__RAM_D028_ + 3]    ; buffer__RAM_D028_ + 3 = $D02B
    dec  a
    ld   [shadow_rtc_dayofweek__RAM_D054_], a    ; shadow_rtc_dayofweek__RAM_D054_ = $D054
    cp   $06
    jr   z, _LABEL_53C1_
    call _LABEL_532F_
    ld   hl, buffer__RAM_D028_ + 2 ; buffer__RAM_D028_ + 2 = $D02A
    and  a
    jr   z, _LABEL_53C6_
_LABEL_53C1_:
    call _LABEL_52F5_
    jr   _LABEL_53CB_

_LABEL_53C6_:
    ld   c, $02
    call _LABEL_5401_
_LABEL_53CB_:
    ret

_LABEL_53CC_:
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    add  $02
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   a, $BE
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    push af
    push bc
    push de
    push hl
    call wait_until_vbl__92C_
    ld   a, SELECT_TILEMAP_0  ; $00
    call write_tilemap_in_a_preset_xy_and_data_8FB_
    pop  hl
    pop  de
    pop  bc
    pop  af
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    inc  a
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    push af
    push bc
    push de
    push hl
    call wait_until_vbl__92C_
    ld   a, SELECT_TILEMAP_0  ; $00
    call write_tilemap_in_a_preset_xy_and_data_8FB_
    pop  hl
    pop  de
    pop  bc
    pop  af
    ret

_LABEL_5401_:
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    add  $02
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ldi  a, [hl]
    ld   b, a
    swap a
    and  $0F
    bit  0, c
    jr   z, _LABEL_542E_
    sla  a
    add  $00
    bit  1, c
    jr   z, _LABEL_5427_
    set  7, a
    bit  2, c
    jr   z, _LABEL_5427_
    cp   $80
    jr   nz, _LABEL_5427_
    ld   a, $98
_LABEL_5427_:
    push hl
    push bc
    call _LABEL_5480_
    jr   _LABEL_544F_

_LABEL_542E_:
    add  $C0
    cp   $C0
    jr   nz, _LABEL_543A_
    bit  2, c
    jr   nz, _LABEL_543A_
    ld   a, $BE
_LABEL_543A_:
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    push hl
    push bc
    bit  0, c
    jr   nz, _LABEL_544C_
    bit  1, c
    jr   nz, _LABEL_544C_
    call wait_vbl_write_byte_tilemap0_preset_xy_and_data__612_
    jr   _LABEL_544F_

_LABEL_544C_:
    call wait_vbl_write_byte_tilemap0_preset_xy_and_data__612_
_LABEL_544F_:
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    inc  a
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    pop  bc
    ld   a, b
    and  $0F
    bit  0, c
    jr   z, _LABEL_5472_
    sla  a
    add  $00
    bit  1, c
    jr   z, _LABEL_5468_
    set  7, a
_LABEL_5468_:
    call _LABEL_5480_
    jr   _LABEL_547E_

_LABEL_546D_:
    call wait_vbl_write_byte_tilemap0_preset_xy_and_data__612_
    jr   _LABEL_547E_

_LABEL_5472_:
    add  $C0
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    bit  1, c
    jr   nz, _LABEL_546D_
    call wait_vbl_write_byte_tilemap0_preset_xy_and_data__612_
_LABEL_547E_:
    pop  hl
    ret

_LABEL_5480_:
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    push bc
    push hl
    push de
    bit  1, c
    ld   hl, _TILEMAP0; $9800
    jr   z, _LABEL_5490_
    ld   hl, _TILEMAP0; $9800
_LABEL_5490_:
    call calc_vram_addr_of_tile_xy_base_in_hl__4932_
    call wait_until_vbl__92C_
    call maybe__vram_write_byte_2rows_addr_in_hl_preset_data__5494_
    pop  de
    pop  hl
    pop  bc
    ret


; Writes preset byte to vram HL, then writes (preset byte + 1) at the next row down
;
; - VRAM Address to write: HL
;
; Destroys A, DE
maybe__vram_write_byte_2rows_addr_in_hl_preset_data__5494_:
    ld   a, [maybe_vram_data_to_write__RAM_C8CC_]
    ld   [hl], a
    ld   d, $00
    ld   e, _TILEMAP_WIDTH  ; $20
    push hl
    add  hl, de
    inc  a
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    ld   [hl], a
    pop  hl
    ret


_LABEL_54AE_:
    ld   a, [_RAM_D059_]
    and  $F0
    cp   $C0
    jr   z, _LABEL_54BC_
    ld   a, $C0
    ld   [_RAM_D059_], a
_LABEL_54BC_:
    xor  a
    ld   [_RAM_D05A_], a
    call wait_until_vbl__92C_
    call display_screen_off__94C_
    ld   de, $1FFA
    ld   bc, $0000
    ld   hl, _TILEDATA9000  ; $9000
    ld   a, $80
    call copy_a_x_tile_patterns_from_de_add_bx16_to_hl_add_cx16__48CD_

    ld   de, $1BFA
    ld   bc, $0000
    ld   hl, _TILEDATA8000  ; $8000
    ld   a, $80
    call copy_a_x_tile_patterns_from_de_add_bx16_to_hl_add_cx16__48CD_
    call wait_until_vbl__92C_
    call display_screen_off__94C_

    ld   a, SELECT_TILEMAP_0  ; $00
    ld   de, _DATA_266A_
    call write_tilemap_20x18_from_de_mapselect_in_a__8c4_
    call wait_until_vbl__92C_
    call display_screen_off__94C_

    ld   hl, $9980
_LABEL_54F9_:
    xor  a
    ldi  [hl], a
    ld   a, h
    cp   $9C
    jr   nz, _LABEL_54F9_
    ld   a, SYS_CMD_RTC_GET_DATE_AND_TIME  ; $0C
    ld   [serial_rx_cmd_to_send__RAM_D036_], a

    receive_loop_wait_valid_reply__5505_:
        call serial_io_send_command_and_receive_buffer__AEF_
        call timer_wait_tick_AND_TODO__289_
        ld   a, [input_key_pressed__RAM_D025_]
        cp   SYS_CHAR_SERIAL_RX_SUCCESS  ; $F9
        jr   nz, receive_loop_wait_valid_reply__5505_

    ldh  a, [rLCDC]
    or   $02
    ldh  [rLCDC], a
    xor  a
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   a, $03
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    ld   [_RAM_D20C_], a
    ld   a, $5F
    call _LABEL_57BC_
    call _display_bg_sprites_on__627_
    ld   hl, _RAM_D03C_    ; _RAM_D03C_ = $D03C
    ld   b, $0C
    xor  a
_LABEL_5532_:
    ldi  [hl], a
    dec  b
    jr   nz, _LABEL_5532_
    call memcopy_8_bytes_from_serial_rx_RAM_D028_to_shadow_rtc_RAM_D051__5D50_
    call _LABEL_5B5F_
    call _LABEL_55A0_
    xor  a
    ld   [_RAM_D068_], a
    ld   [_RAM_D03B_], a
    ld   [_RAM_D1A7_], a    ; _RAM_D1A7_ = $D1A7
_LABEL_5549_:
    ld   a, [_RAM_D1A7_]    ; _RAM_D1A7_ = $D1A7
    inc  a
    ld   [_RAM_D1A7_], a    ; _RAM_D1A7_ = $D1A7
    cp   $04
    jr   nz, _LABEL_557B_
    xor  a
    ld   [_RAM_D1A7_], a    ; _RAM_D1A7_ = $D1A7

    ; TODO: Maybe Read Hardware RTC and then ...
    ld   a, SYS_CMD_RTC_GET_DATE_AND_TIME  ; $0C
    ld   [serial_rx_cmd_to_send__RAM_D036_], a
    call serial_io_send_command_and_receive_buffer__AEF_
    ld   a, [input_key_pressed__RAM_D025_]
    cp   SYS_CHAR_SERIAL_RX_SUCCESS  ; $F9
    jr   nz, _LABEL_5579_

    ; TODO: Maybe then compare Hardware RTC reply data with System Shadow RTC data
    call _LABEL_5D5F_
    ld   a, [_RAM_D03A_]
    and  a
    jr   z, _LABEL_5579_
    call memcopy_8_bytes_from_serial_rx_RAM_D028_to_shadow_rtc_RAM_D051__5D50_
    call _LABEL_5B5F_
    call _LABEL_55A0_
_LABEL_5579_:
    jr   _LABEL_5549_

_LABEL_557B_:
    call timer_wait_tick_AND_TODO__289_
    call input_read_keys__C8D_
    ld   a, [buttons_new_pressed__RAM_D006_]
    ld   [_RAM_D03B_], a
    call _LABEL_56CB_
    ld   a, [_RAM_D05A_]
    and  a
    jr   nz, _LABEL_5599_
    ld   a, [_RAM_D06B_]
    and  a
    jp   nz, _LABEL_54BC_
    jr   _LABEL_5549_

_LABEL_5599_:
    ldh  a, [rLCDC]
    and  $FD
    ldh  [rLCDC], a
    ret

_LABEL_55A0_:
    ld   a, [_RAM_D059_]
    and  $0F
    and  a
    jr   nz, _LABEL_55CB_
    ld   hl, shadow_rtc_am_pm__RAM_D055_
    ldi  a, [hl]
    and  a
    ld   a, $90
    jr   nz, _LABEL_55B3_
    ld   a, $81
_LABEL_55B3_:
    ld   [_RAM_D400_], a
    ld   a, $8D
    ld   [_RAM_D401_], a
_LABEL_55BB_:
    ld   a, $BE
    ld   [_RAM_D402_], a
    ld   de, shadow_rtc_hour__RAM_D056_
    ld   hl, _RAM_D403_
    call _LABEL_56BC_
    jr   _LABEL_5600_

_LABEL_55CB_:
    ld   a, $BE
    ld   [_RAM_D400_], a
    ld   [_RAM_D401_], a
    ld   [_RAM_D402_], a
    ld   a, [shadow_rtc_am_pm__RAM_D055_]
    and  a
    jr   z, _LABEL_55BB_
    ld   a, [shadow_rtc_hour__RAM_D056_]
    and  $F0
    ld   b, a
    ld   a, [shadow_rtc_hour__RAM_D056_]
    and  $0F
    add  $02
    cp   $0A
    jr   c, _LABEL_55F1_
    sub  $0A
    add  $10
_LABEL_55F1_:
    add  $10
    add  b
    ld   [_RAM_D03A_], a
    ld   de, _RAM_D03A_
    ld   hl, _RAM_D403_
    call _LABEL_56BC_
_LABEL_5600_:
    ld   a, $73
    ld   [_RAM_D405_], a
    ld   de, shadow_rtc_minute__RAM_D057_
    ld   hl, _RAM_D406_
    call _LABEL_56BC_
    ld   a, $BE
    ldi  [hl], a
    ldi  [hl], a
    ld   de, shadow_rtc_maybe_seconds__RAM_D058_
    ld   hl, _RAM_D40A_
    call _LABEL_56BC_
    xor  a
    ld   [_RAM_D40C_], a
    ld   de, _RAM_D400_
    ld   c, $A0
    ld   b, $02
    ld   hl, $030E
    call _LABEL_4944_
    ld   a, [shadow_rtc_dayofweek__RAM_D054_]
    dec  a
    ld   b, $03
    call multiply_a_x_b__result_in_de__4853_
    ld   hl, _DATA_5E19_
    add  hl, de
    ldi  a, [hl]
    ld   [_RAM_D400_], a
    ldi  a, [hl]
    ld   [_RAM_D401_], a
    ldi  a, [hl]
    ld   [_RAM_D402_], a
    ld   a, $BE
    ld   [_RAM_D403_], a
    ld   de, shadow_rtc_day__RAM_D053_
    ld   hl, _RAM_D404_
    call _LABEL_56BC_
    ld   a, $BE
    ldi  [hl], a
    ldi  [hl], a
    ld   a, [shadow_rtc_month__RAM_D052_]
    swap a
    and  $0F
    ld   b, $0A
    call multiply_a_x_b__result_in_de__4853_
    ld   a, [shadow_rtc_month__RAM_D052_]
    and  $0F
    add  e
    dec  a
    ld   b, $03
    call multiply_a_x_b__result_in_de__4853_
    ld   hl, _DATA_5E31_
    add  hl, de
    ldi  a, [hl]
    ld   [_RAM_D408_], a
    ldi  a, [hl]
    ld   [_RAM_D409_], a
    ldi  a, [hl]
    ld   [_RAM_D40A_], a
    ld   a, $BE
    ld   [_RAM_D40B_], a
    ld   [_RAM_D40C_], a
    ld   a, [shadow_rtc_buf_start_and_year__RAM_D051_]
    bit  7, a
    jr   nz, _LABEL_5697_
    ld   a, $C2
    ld   [_RAM_D40D_], a
    ld   a, $C0
    jr   _LABEL_569E_

_LABEL_5697_:
    ld   a, $C1
    ld   [_RAM_D40D_], a
    ld   a, $C9
_LABEL_569E_:
    ld   [_RAM_D40E_], a
    ld   de, shadow_rtc_buf_start_and_year__RAM_D051_
    ld   hl, _RAM_D40F_
    call _LABEL_56BC_
    xor  a
    ld   [_RAM_D411_], a
    ld   de, _RAM_D400_
    ld   c, $C8
    ld   b, $02
    ld   hl, $0210
    call _LABEL_4944_
    ret

_LABEL_56BC_:
    ld   a, [de]
    swap a
    and  $0F
    add  $C0
    ldi  [hl], a
    ld   a, [de]
    and  $0F
    add  $C0
    ldi  [hl], a
    ret

_LABEL_56CB_:
    xor  a
    ld   [_RAM_D05A_], a
    ld   [_RAM_D06B_], a
    ld   a, [input_key_pressed__RAM_D025_]
    cp   SYS_CHAR_ENTRA_CR  ; $2E
    jr   z, _LABEL_5740_
    cp   SYS_CHAR_UP  ; $3D
    jr   z, _LABEL_5704_
    cp   SYS_CHAR_DOWN  ; $40
    jr   z, _LABEL_571F_
    cp   SYS_CHAR_SALIDA  ; $2A
    jp   z, _LABEL_576B_
    cp   SYS_CHAR_PRINTSCREEN  ; $2F
    jr   nz, _LABEL_56EE_
    call maybe_call_printscreen_in_32k_bank_2__522_
    ret


; TODO: keycode / button constant labeling
_LABEL_56EE_:
    ld   a, [buttons_new_pressed__RAM_D006_]
    and  $C4
    ret  z
    ld   a, [buttons_new_pressed__RAM_D006_]
    bit  6, a
    jr   nz, _LABEL_5704_
    bit  7, a
    jr   nz, _LABEL_571F_
    bit  2, a
    jr   nz, _LABEL_5740_
    ret

_LABEL_5704_:
    ld   hl, _RAM_D068_
    ld   a, [_RAM_D20C_]
    cp   $06
    jr   nz, _LABEL_5712_
    ld   [hl], $00
    jr   _LABEL_571C_

_LABEL_5712_:
    cp   $09
    jr   nz, _LABEL_571A_
    ld   [hl], $01
    jr   _LABEL_571C_

_LABEL_571A_:
    ld   [hl], $02
_LABEL_571C_:
    jp   _LABEL_5737_

_LABEL_571F_:
    ld   hl, _RAM_D068_
    ld   a, [_RAM_D20C_]
    cp   $06
    jr   nz, _LABEL_572D_
    ld   [hl], $02
    jr   _LABEL_5737_

_LABEL_572D_:
    cp   $03
    jr   z, _LABEL_5735_
    ld   [hl], $00
    jr   _LABEL_5737_

_LABEL_5735_:
    ld   [hl], $01
_LABEL_5737_:
    call _LABEL_5792_
    ld   a, $05
    call _LABEL_4A72_
    ret

_LABEL_5740_:
    ld   a, [_RAM_D068_]
    cp   $00
    jr   nz, _LABEL_5763_
    ld   a, [_RAM_D059_]
    xor  $01
    ld   [_RAM_D059_], a
    xor  a
    ld   [shadow_rtc_month__RAM_D052_], a
    call timer_wait_tick_AND_TODO__289_
    call timer_wait_tick_AND_TODO__289_
    call timer_wait_tick_AND_TODO__289_
    call timer_wait_tick_AND_TODO__289_
    call timer_wait_tick_AND_TODO__289_
    ret

_LABEL_5763_:
    cp   $01
    jr   nz, _LABEL_576B_
    call _LABEL_57D5_
    ret

_LABEL_576B_:
    call _LABEL_5774_
    ld   a, $01
    ld   [_RAM_D05A_], a
    ret

_LABEL_5774_:
    ld   hl, _RAM_D05F_ ; _RAM_D05F_ = $D05F
    ld   b, $02
    ld   c, $02
_LABEL_577B_:
    ldi  a, [hl]
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    push bc
    push hl
    call oam_free_slot_and_clear__89B_
    pop  hl
    pop  bc
    dec  b
    jr   nz, _LABEL_577B_
    ld   hl, _RAM_D03B_ + 1 ; _RAM_D03B_ + 1 = $D03C
    ld   b, $0C
    dec  c
    jr   nz, _LABEL_577B_
    ret

_LABEL_5792_:
    xor  a
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   a, [_RAM_D20C_]
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    ld   a, $63
    call _LABEL_57BC_
    ld   a, [_RAM_D068_]
    ld   b, $03
    call multiply_a_x_b__result_in_de__4853_
    ld   a, e
    add  $03
    ld   [_RAM_D20C_], a
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    xor  a
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   a, $5F
    call _LABEL_57BC_
    ret

_LABEL_57BC_:
    push af
    ld   hl, _TILEMAP0; $9800
    call calc_vram_addr_of_tile_xy_base_in_hl__4932_
    ld   c, $02
    call wait_until_vbl__92C_
    pop  af
_LABEL_57C9_:
    ldi  [hl], a
    inc  a
    ldd  [hl], a
    inc  a
    ld   de, $0020
    add  hl, de
    dec  c
    jr   nz, _LABEL_57C9_
    ret


; TODO: Maybe something about setting the time
; Could be the clock/calendar application
_LABEL_57D5_:
    xor  a
    ld   [_RAM_D06C_], a    ; _RAM_D06C_ = $D06C
    ldh  a, [rLCDC]
    and  $FD
    ldh  [rLCDC], a
    call _LABEL_5774_

    ; Load Tile Data for the main menu font
    call wait_until_vbl__92C_
    call display_screen_off__94C_
    ld   de, gfx_tile_data__main_menu_font__2F2A_ ; Source
    ld   bc, $0000                               ; No source and no dest offset (0/0)
    ld   hl, _TILEDATA8800                       ; Dest
    ld   a, MENU_FONT_128_TILES                  ; Copy size: 128 tiles (2048 bytes)
    call copy_a_x_tile_patterns_from_de_add_bx16_to_hl_add_cx16__48CD_

    ; Clear Tile Map 0
    ld   hl, _TILEMAP0  ; $9800
    .loop_clear_tilemap_9800__57F9_:
        xor  a
        ldi  [hl], a
        ld   a, h
        cp   HIGH(_TILEMAP1) ; $9C
        jr   nz, .loop_clear_tilemap_9800__57F9_

    xor  a
    ld   [_RAM_D069_], a
    ld   de, rom_str__PUESTA_EN_HORA__5DD2_
    ld   c, $A0
    ld   b, $02
    ld   hl, $0203
    call _LABEL_4944_
    ld   a, [shadow_rtc_hour__RAM_D056_]
    cp   $12
    jr   nz, _LABEL_581C_
    xor  a
    ld   [shadow_rtc_hour__RAM_D056_], a
_LABEL_581C_:
    ld   de, shadow_rtc_am_pm__RAM_D055_
    ld   a, [de]
    inc  de
    and  a
    jr   z, _LABEL_5841_
    ld   a, [de]
    and  $F0
    ld   b, a
    ld   a, [de]
    and  $0F
    add  $02
    cp   $0A
    jr   c, _LABEL_5835_
    sub  $0A
    add  $10
_LABEL_5835_:
    add  $10
    add  b
    ld   [_RAM_D402_], a
    ld   [shadow_rtc_hour__RAM_D056_], a
    ld   de, _RAM_D402_
_LABEL_5841_:
    ld   hl, _RAM_D400_
    call _LABEL_56BC_
    ld   a, $BE
    ldi  [hl], a
    ld   [_RAM_D404_], a
    ld   a, $73
    ldi  [hl], a
    inc  hl
    ld   de, shadow_rtc_minute__RAM_D057_
    call _LABEL_56BC_
    xor  a
    ldi  [hl], a
    ld   de, _RAM_D400_
    ld   c, $D2
    ld   b, $02
    ld   hl, $0207
    call _LABEL_4944_
    ld   de, shadow_rtc_month__RAM_D052_
    ld   hl, _RAM_D400_
    call _LABEL_56BC_
    ld   a, $BE
    ldi  [hl], a
    ldi  [hl], a
    ld   de, shadow_rtc_day__RAM_D053_
    call _LABEL_56BC_
    ld   a, $BE
    ld   [_RAM_D406_], a
    ld   [_RAM_D408_], a
    ld   a, $9E
    ld   [_RAM_D407_], a
    ld   de, shadow_rtc_buf_start_and_year__RAM_D051_
    ld   hl, _RAM_D409_
    call _LABEL_56BC_
    xor  a
    ldi  [hl], a
    ld   de, _RAM_D400_
    ld   c, $E6
    ld   b, $02
    ld   hl, $020B
    call _LABEL_4944_
    call _display_bg_sprites_on__627_
    xor  a
    ld   [_RAM_D03A_], a
    ld   a, $04
    ld   [_RAM_D03B_], a
    call _LABEL_58EA_
_LABEL_58AD_:
    call input_map_gamepad_buttons_to_keycodes__49C2_
    call _LABEL_5919_
    ld   a, [_RAM_D06B_]
    and  a
    jr   z, _LABEL_58C3_
    call _LABEL_58DC_
    ldh  a, [rLCDC]
    or   $02
    ldh  [rLCDC], a
    ret

_LABEL_58C3_:
    ld   a, [_RAM_D03B_]
    inc  a
    ld   [_RAM_D03B_], a
    and  $07
    jr   nz, _LABEL_58D3_
    call _LABEL_58DC_
    jr   _LABEL_58AD_

_LABEL_58D3_:
    cp   $04
    jr   nz, _LABEL_58AD_
    call _LABEL_58EA_
    jr   _LABEL_58AD_

_LABEL_58DC_:
    ld   a, [_RAM_D069_]
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call oam_free_slot_and_clear__89B_
    xor  a
    ld   [_RAM_D069_], a
    ret

_LABEL_58EA_:
    ld   a, [_RAM_D03A_]
    sla  a
    ld   hl, _DATA_590F_
    call add_a_to_hl__486E_
    ldi  a, [hl]
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ldi  a, [hl]
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    ld   a, $FF
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    ld   a, $80
    ld   [_RAM_C8CD_], a    ; _RAM_C8CD_ = $C8CD
    call _LABEL_623_
    ld   a, b
    ld   [_RAM_D069_], a
    ret

; Data from 590F to 5918 (10 bytes)
_DATA_590F_:
db $20, $48, $48, $48, $20, $68, $40, $68, $68, $68

_LABEL_5919_:
    xor  a
    ld   [_RAM_D06B_], a
    ld   a, [input_key_pressed__RAM_D025_]
    cp   SYS_CHAR_RIGHT  ; $3F
    jr   nz, _LABEL_593C_
    xor  a
    ld   [_RAM_D06C_], a    ; _RAM_D06C_ = $D06C
    ld   a, [_RAM_D03A_]
    inc  a
    cp   $05
    jr   nz, _LABEL_5931_
    xor  a
_LABEL_5931_:
    ld   [_RAM_D03A_], a
    ld   a, $FF
    ld   [input_prev_key_pressed__RAM_D181_], a
    jp   _LABEL_59F1_

_LABEL_593C_:
    cp   SYS_CHAR_LEFT  ; $3E
    jr   nz, _LABEL_5950_
    xor  a
    ld   [_RAM_D06C_], a    ; _RAM_D06C_ = $D06C
    ld   a, [_RAM_D03A_]
    dec  a
    cp   $FF
    jr   nz, _LABEL_5931_
    ld   a, $04
    jr   _LABEL_5931_

_LABEL_5950_:
    cp   SYS_CHAR_0  ; $C0
    jr   c, rtc_set_to_new_date_and_time___5987_
    cp   (SYS_CHAR_LAST_NUM + 1)  ; $CA
    jr   nc, rtc_set_to_new_date_and_time___5987_
    ld   b, $C0
    sub  b
    ld   c, a
    ld   a, [_RAM_D03A_]
    ld   hl, _DATA_5DA1_
    call add_a_to_hl__486E_
    ld   a, [hl]
    ld   hl, shadow_rtc_buf_start_and_year__RAM_D051_
    call add_a_to_hl__486E_
    ld   a, [_RAM_D06C_]    ; _RAM_D06C_ = $D06C
    cp   $00
    jr   nz, _LABEL_5975_
    ld   [hl], $00
_LABEL_5975_:
    ld   a, $01
    ld   [_RAM_D06C_], a    ; _RAM_D06C_ = $D06C
    ld   a, [hl]
    swap a
    and  $F0
    or   c
    ld   [hl], a
    call _LABEL_59F2_
    jp   _LABEL_59F1_


; Probably being called by Clock App
; Set Hardware RTC with new values
rtc_set_to_new_date_and_time___5987_:
    ; Wait for Enter Key to finalize
    ; Any other key... (
    cp   SYS_CHAR_ENTRA_CR  ; $2E
    jr   nz, .not_enter_key__59ED_

    ; Convert Hour from BCD to decimal
    ; and check if it's greater than 12
    ld   a, [shadow_rtc_hour__RAM_D056_]
    ; Multiply Upper BCD digit x 10
    swap a
    and  $0F
    ld   b, $0A
    call multiply_a_x_b__result_in_de__4853_
    ; Add result to Lower BCD digit
    ld   a, [shadow_rtc_hour__RAM_D056_]
    and  $0F
    add  e
    ; If hour >= 12:00 then it's PM and
    ; and needs 24 -> 12 hour time conversion
    cp   _TIME_HOUR_12  ; $0C
    jr   nc, .convert_from_24hour_time__59A4_
    xor  a  ; Set AM/PM, 0 = AM
    jr   .set_am_pm__59B7_

    .convert_from_24hour_time__59A4_:
        ; Convert from decimal back to BCD
        ; First: Hour -= 12
        sub  _TIME_HOUR_12  ; $0C
        ; Hour / 10 -> Upper BCD Digit
        ld   d, $00
        ld   e, a
        ld   h, $0A
        call divide_de_by_h_result_in_bc_remainder_in_l__4832_
        ld   a, c
        swap a
        ; Use Remainder for Lower BCD Digit
        or   l
        ld   [shadow_rtc_hour__RAM_D056_], a
        ; Set AM/PM, 1 = PM
        ld   a, _TIME_PM  ; $01

    .set_am_pm__59B7_:
        ld   [shadow_rtc_am_pm__RAM_D055_], a

        ; Now Validate RTC data
        call rtc_validate_shadow_data_and_time__5A2B_
        ld   a, [rtc_validate_result__RAM_D06A_]
        and  a
        ; If validation failed
        jp   z, clock_app_message__invalid_date_time__then_ret__5B12_

        ; Copy from Shadow RTC Buffer to Serial TX Buffer
        ; then transfer it over Serial IO
        di
        ld   b, SYS_RTC_SET_DATE_AND_TIME_LEN  ; $08
        ld   hl, shadow_rtc_buf_start_and_year__RAM_D051_
        ld   de, buffer__RAM_D028_
        call memcopy_b_bytes_from_hl_to_de__482B_
        ld   a, SYS_CMD_RTC_SET_DATE_AND_TIME  ; $0B
        ld   [serial_cmd_to_send__RAM_D035_], a

    .send_loop_wait_valid_reply__59D5_:
        ; Note: Where does it set the required buffer TX length?
        ; (should be: 8, aka SYS_RTC_SET_DATE_AND_TIME_LEN )
        ; Maybe casually relying on existing value from first system power-up?
        ;
        ; For example:
        ; ld   a, SYS_RTC_SET_DATE_AND_TIME_LEN  ; $08  ; Send 8 bytes
        ; ld   [serial_transfer_length__RAM_D034_], a
        ;
        call serial_io_send_command_and_buffer__A34_
        ld   a, [input_key_pressed__RAM_D025_]
        cp   SYS_CHAR_SERIAL_TX_SUCCESS  ; $FC
        jr   z, .done_ok__59E4_

        call timer_wait_tick_AND_TODO__289_
        jr   .send_loop_wait_valid_reply__59D5_

    .done_ok__59E4_:
        ld   a, SYS_RTC_UPDATE_DATE_TIME_OK  ; $01
        ld   [_RAM_D06B_], a  ; TODO: Label this, maybe RTC update status of some kind
        call maybe_input_wait_for_keys__4B84
        ret

    .not_enter_key__59ED_:
        cp   SYS_CHAR_SALIDA  ; $2A
        jr   z, .done_ok__59E4_

    _LABEL_59F1_:  ; TODO Maybe return no update?
        ret

; TODO: Could this part of Data Entry for Set New Date Time in the Clock App
; Maybe calculating cursor position in fields
_LABEL_59F2_:
    push hl
    pop  de
    ld   hl, _RAM_D400_
    call _LABEL_56BC_
    xor  a
    ldi  [hl], a
    ld   a, [_RAM_D03A_]
    ld   b, $04
    call multiply_a_x_b__result_in_de__4853_
    ld   a, $64
    add  e
    ld   c, a
    ld   a, [_RAM_D03A_]
    sla  a
    ld   hl, _DATA_5A21_
    call add_a_to_hl__486E_
    ldi  a, [hl]
    ld   b, a
    ldi  a, [hl]
    ld   l, a
    ld   h, b
    ld   de, _RAM_D400_
    ld   b, $02
    call _LABEL_4944_
    ret

    ; TODO: Maybe Look Up Table for Date/Time data entry screen
    ; Offsets from first character on screen?
    ; Data from 5A21 to 5A2A (10 bytes)
    _DATA_5A21_:
    db $02, $07, $07, $07, $02, $0B, $06, $0B, $0B, $0B


; Validate the Shadow RTC Date and Time before sending it to the Hardware RTC
;
; Note: Super Quique has a Y2K12 Bug!
;       Look up tables only support years 1992 - 2011
;
;
;
rtc_validate_shadow_data_and_time__5A2B_:
    ; Validate Year: Allowed range is 1992 - 2011
    ;
    ld   hl, shadow_rtc_buf_start_and_year__RAM_D051_
    call convert_bcd2dec_at_hl_result_in_a__5B03_
    ; Year must be < 12 ( <= 2012)
    ; And year must be >= 92 ( >= 1992)
    cp   _DATE_MAX_YEAR_2011_  ; $0C (12)
    jr   c, .continue_validation__5A3B_
    cp   _DATE_MIN_YEAR_1992_  ; $5C (92)
    jr   nc, .continue_validation__5A3B_
    jr   .validation_fail_and_return__5A9A_

    .continue_validation__5A3B_:
        ; Validate Month: Allowed range is  1 - 12
        ;
        inc  hl
        ; HL now points to shadow_rtc_month__RAM_D052_
        call convert_bcd2dec_at_hl_result_in_a__5B03_
        ; Month must != 0
        ; And Month be < 13 ( <= 12)
        cp   $00
        jr   z, .validation_fail_and_return__5A9A_
        cp   $0D
        jr   nc, .validation_fail_and_return__5A9A_

        ; Validate Day within Month
        ;
        ; The Leap Year table is used first for all dates and then
        ;  later non-leap year Februarys are checked to be < 29
        ;
        ; Use Month to into Max Days per Month Look Up Table
        ; and store result in C (then increment +1 for >= via NC)
        push hl
        ld   hl, RTC_DAYS_PER_MONTH_LEAP_YEARS_LUT__5DB2_  ; $5DB2
        dec  a
        call add_a_to_hl__486E_
        ld   c, [hl]
        inc  c
        pop  hl
        inc  hl
        ; HL now points to shadow_rtc_day__RAM_D053_
        push bc
        call convert_bcd2dec_at_hl_result_in_a__5B03_
        pop  bc
        ; Day must != 0
        ; And Day must be <= Max day for current Month (in C)
        cp   $00
        jr   z, .validation_fail_and_return__5A9A_
        cp   c
        jr   nc, .validation_fail_and_return__5A9A_

        ; Validate Day of Month for February in NON-Leap years
        ;
        ; Load month again and check if it's February (2nd month)
        ; If not Feb then skip test
        dec  hl
        ; HL now points to shadow_rtc_month__RAM_D052_
        ld   a, [hl]
        cp   _MONTH_FEB  ; $02
        jr   nz, .test_is_february_or_is_leap_year_done__5A7F_

        ; Check to see if it's a Leap Year
        dec  hl
        ; HL now points to shadow_rtc_buf_start_and_year__RAM_D051_
        push hl
        call convert_bcd2dec_at_hl_result_in_a__5B03_
        ld   e, a
        ld   d, $00
        ld   h, $04
        call divide_de_by_h_result_in_bc_remainder_in_l__4832_
        ld   a, l
        and  a
        pop  hl
        inc  hl
        ; If (Year % 4) == 0 then it's a leap year, skip Non-Leap Year handling
        ; HL now points to shadow_rtc_month__RAM_D052_
        jr   z, .test_is_february_or_is_leap_year_done__5A7F_

        ; If it's a non-leap year, make sure Day of Month != 29 (in BCD format)
        inc  hl
        ; HL now points to shadow_rtc_day__RAM_D053_
        ld   a, [hl]
        cp   $29  ; 29th day in BCD format
        jr   z, .validation_fail_and_return__5A9A_
        dec  hl
        ; HL now points to shadow_rtc_month__RAM_D052_

    .test_is_february_or_is_leap_year_done__5A7F_:
        ; Make sure Hour is 0 - 11 (not >= 12)
        ld   a, (shadow_rtc_minute__RAM_D057_ - shadow_rtc_day__RAM_D053_)  ; $04
        call add_a_to_hl__486E_
        ; HL now points to shadow_rtc_hour__RAM_D056_
        call convert_bcd2dec_at_hl_result_in_a__5B03_
        cp   _TIME_HOUR_12  ; $0C (12)
        jr   nc, .validation_fail_and_return__5A9A_

        ; Make sure Minute is Hour is 0 - 59 (not >= 60)
        inc  hl
        ; HL now points to shadow_rtc_minute__RAM_D057_
        call convert_bcd2dec_at_hl_result_in_a__5B03_
        cp   _TIME_MINUTE_60  ; $3C (60)
        jr   nc, .validation_fail_and_return__5A9A_

        ; Calculate Day of Week (DoW) based on current Year/Month/Day
        ; Result is stored in  shadow_rtc_dayofweek__RAM_D054_
        call rtc_calc_day_of_week_for_current_date__5A9F_
        ld   a, SYS_RTC_VALIDATE_DATE_TIME_OK  ; $01
        jr   .validation_success_return_ok__5A9B_

    .validation_fail_and_return__5A9A_:
        xor  a

    .validation_success_return_ok__5A9B_:
        ld   [rtc_validate_result__RAM_D06A_], a
        ret


; Calculate current Day of Week based on (Leap)Year, Month, Day
; (only supports 1992 - 2011)
;
; Day of Week range is 1-7
;
; Formula is roughly:
;  ((Starting Day of Week for Year
;    + Sum of days for all preceding Months
;    + Current day of Month) - 1)% 7
;
rtc_calc_day_of_week_for_current_date__5A9F_:

    ; First step is to get Starting Day of Week by Year as start of Total

        ; If Year is >= 92 ( >= 1992 ) then skip ahead
        ld   hl, shadow_rtc_buf_start_and_year__RAM_D051_
        call convert_bcd2dec_at_hl_result_in_a__5B03_
        ld   e, a
        cp   _DATE_MIN_YEAR_1992_  ; $5C (92)
        jr   nc, .year_1992_thru_1999__5AAE_

        ; Otherwise Year += 8 to handle 2 digit year Y2K overflow
        ; and having 1992 as zero base
        ;
        ; 2000 (00) -> 2008 (8)
        add  (_DATE_Y2K_RTC_WRAP_2000_ - _DATE_MIN_YEAR_1992_)  ; $08
        jr   .year_adjustment_done__5AB0_

        .year_1992_thru_1999__5AAE_:
            ; Year -= 92 to set 1992 as zero base
            sub  _DATE_MIN_YEAR_1992_  ; $5C (92)

        .year_adjustment_done__5AB0_:
            ; Use LUT to find starting Day of Week for current Year
            ; Save DoW result in B
            ld   hl, RTC_DOW_FIRST_DAY_OF_YEAR_LUT__5DB2_
            call add_a_to_hl__486E_
            ld   b, [hl]
            push bc


    ; Second step is to add the days from all the preceding months to Total

        ; For Days per Month LUT, select whether or not to use Leap Year version
        ; - E has decimal value of last 2 digits of year (non-1992 base modified)
        ld   d, $00
        ld   h, $04
        call divide_de_by_h_result_in_bc_remainder_in_l__4832_
        ld   a, l
        and  a
        ; If (Year % 4) != 0 then it's not a leap year
        jr   nz, .not_a_leap_year__5AC8_
        ; Use the Leap Year version of LUT
        ld   de, RTC_DAYS_PER_MONTH_LEAP_YEARS_LUT__5DB2_
        jr   .lookup_table_ready__5ACB_

        .not_a_leap_year__5AC8_:
            ; Use Non-Leap Year version of LUT
            ld   de, RTC_DAYS_PER_MONTH_LUT__5DA6_

        .lookup_table_ready__5ACB_:
            ; Load (Month - 1) (since no need to add days for current month)
            ld   hl, shadow_rtc_month__RAM_D052_
            push de
            call convert_bcd2dec_at_hl_result_in_a__5B03_
            pop  de
            dec  a
            pop  bc
            ; B has saved Day of Week (DoW)
            ; Use HL to start calculating Day of Year (DoY)
            ; - Initial value will be start DoW for Year
            ld   c, a
            and  a
            ld   l, b
            ld   h, $00
            ; Skip over add loop if month is January
            jr   z, .finalize_dow_calc__5AE4_

        ; Add days from all preceding months to DoY total in HL
        .loop_add_days_of_each_month__5ADC_:
            ld   a, [de]
            call add_a_to_hl__486E_
            inc  de
            dec  c
            jr   nz, .loop_add_days_of_each_month__5ADC_

    ; Now add current Day (of current month) to total
    ; and calculate final Day of Week based on (Total -1) % 7

        .finalize_dow_calc__5AE4_:
            push de
            dec  hl ; Adjust for current day being DoW Year Start +0 (not +1)
            push hl

            ; Add current Day to Day of Year Total in HL
            ld   hl, shadow_rtc_day__RAM_D053_
            call convert_bcd2dec_at_hl_result_in_a__5B03_
            pop  hl
            call add_a_to_hl__486E_

            ; Final Day of Week = Day of Year % 7
            ld   e, l
            ld   d, h
            ld   h, _DAYS_IN_WEEK ; $07
            call divide_de_by_h_result_in_bc_remainder_in_l__4832_
            ld   a, l
            and  a
            jr   nz, .done__5AFE_

            ; Remap (Year % 7) == 0 -> 7th Day (Sunday)
            ld   a, _WEEK_SUN  ; $07

    .done__5AFE_:
        ; Save result
        ld   [shadow_rtc_dayofweek__RAM_D054_], a
        pop  de
        ret


; Convert value at [HL] from BCD to Decimal
;
; - Resulting BCD value in: A
;
; Destroys A, B, E (not counting call to multiply)
convert_bcd2dec_at_hl_result_in_a__5B03_:
    ld   a, [hl]
    ; Multiply Upper BCD digit x 10
    swap a
    and  $0F
    ld   b, $0A
    call multiply_a_x_b__result_in_de__4853_
    ; Add result to Lower BCD digit
    ld   a, [hl]
    and  $0F
    add  e
    ret


; Render text message to screen about continuing /
; aborting by pressing escape/salida key.
;
; - Wait for a keypress
; - It's Ret will return to main clock app screen
clock_app_message__invalid_date_time__then_ret__5B12_:
    ;
    ld   de, rom_str__PARA_CONTINUAR_O___5DE1_
    ld   hl, $010F        ; X,Y = 1,15
    ld   c, PRINT_NORMAL  ; $01
    call render_string_at_de_to_tilemap0_xy_in_hl__4A46_

    ld   de, rom_str__INVALIDAR_PRESIONAR__5DF4_
    ld   hl, $0110        ; X,Y = 1,16
    ld   c, PRINT_NORMAL  ; $01
    call render_string_at_de_to_tilemap0_xy_in_hl__4A46_

    ld   de, rom_str____ESCAPE_SALIDA__5E08_
    ld   hl, $0111        ; X,Y = 1,17
    ld   c, PRINT_NORMAL  ; $01
    call render_string_at_de_to_tilemap0_xy_in_hl__4A46_

    .wait_salida_esc_key_loop__5B33_:
        call input_map_gamepad_buttons_to_keycodes__49C2_
        ld   a, [input_key_pressed__RAM_D025_]
        cp   SYS_CHAR_SALIDA  ; $2A
        jr   nz, .wait_salida_esc_key_loop__5B33_

    xor  a
    ld   [_RAM_D03A_], a  ; TODO not sure what these are for... maybe sets "copy new rtc data" = FALSE?
    ld   [_RAM_D06C_], a  ; TODO

    ; After user presses key, clear the message off the screen
    ; Starting at Tile Row #15 write 3 rows of blank tiles
    ld   c, $03  ; 3 rows
    ld   hl, _TILEMAP0 + (_TILEMAP_WIDTH * 14)  ; $99C0
    ld   de, (_TILEMAP_WIDTH - _TILEMAP_SCREEN_WIDTH)  ; $000C

    clear_tile_rows_loop__5B4C_:
        call wait_until_vbl__92C_
        ld   b, _TILEMAP_SCREEN_WIDTH  ; $14

        clear_single_tile_row_loop__5B51_:
            ld   a, FONT_BLANKSPACE  ; $BE
            ldi  [hl], a
            dec  b
            jr   nz, clear_single_tile_row_loop__5B51_

        ; Skip remainder of current Tile Map row down to next line
        add  hl, de
        dec  c
        jr   nz, clear_tile_rows_loop__5B4C_

    call maybe_input_wait_for_keys__4B84  ; TODO
    ret


_LABEL_5B5F_:
    ld   a, $05
    ldh  [rIE], a
    ei
    ld   hl, shadow_rtc_hour__RAM_D056_
    ld   a, [hl]
    bit  4, a
    jr   z, _LABEL_5B73_
    sub  $06
    cp   $0C
    jr   nz, _LABEL_5B73_
    xor  a
_LABEL_5B73_:
    ld   b, $05
    call multiply_a_x_b__result_in_de__4853_
    ld   a, e
    ld   [_RAM_D03A_], a
    inc  hl
    call _LABEL_5BB9_
    ld   d, $00
    ld   e, a
    ld   h, $0C
    call divide_de_by_h_result_in_bc_remainder_in_l__4832_
    ld   a, [_RAM_D03A_]
    add  c
    ld   [_RAM_D049_], a
    xor  a
    ld   [_RAM_D048_], a
    call _LABEL_5BC8_
    ld   hl, shadow_rtc_minute__RAM_D057_
    call _LABEL_5BB9_
    ld   [_RAM_D049_], a
    ld   a, $01
    ld   [_RAM_D048_], a
    call _LABEL_5BC8_
    ld   hl, shadow_rtc_maybe_seconds__RAM_D058_
    call _LABEL_5BB9_
    ld   [_RAM_D049_], a
    ld   a, $02
    ld   [_RAM_D048_], a
    call _LABEL_5BC8_
    ret

_LABEL_5BB9_:
    ld   a, [hl]
    swap a
    and  $0F
    ld   b, $0A
    call multiply_a_x_b__result_in_de__4853_
    ld   a, [hl]
    and  $0F
    add  e
    ret

_LABEL_5BC8_:
    ld   b, $04
    call _LABEL_5D30_
_LABEL_5BCD_:
    ld   a, [hl]
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    xor  a
    ldi  [hl], a
    push bc
    push hl
    call oam_free_slot_and_clear__89B_
    pop  hl
    pop  bc
    dec  b
    jr   nz, _LABEL_5BCD_
    ld   hl, _RAM_D04A_
    ld   a, [_RAM_D049_]
    cp   $0F
    jr   c, _LABEL_5C2B_
    cp   $1E
    jr   c, _LABEL_5C49_
    cp   $2D
    jr   c, _LABEL_5C0D_
    ld   [hl], $08
    sub  $2D
    ld   [_RAM_D03A_], a
    sla  a
    sla  a
    ld   [_RAM_D037_], a
    ld   hl, _DATA_5D9F_
    ldi  a, [hl]
    sub  $10
    add  $01
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ldi  a, [hl]
    sub  $10
    jr   _LABEL_5C61_

_LABEL_5C0D_:
    ld   [hl], $04
    ld   b, a
    ld   a, $2D
    sub  b
    ld   [_RAM_D03A_], a
    sla  a
    sla  a
    ld   [_RAM_D037_], a
    ld   hl, _DATA_5D9F_
    ldi  a, [hl]
    sub  $10
    add  $01
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ldi  a, [hl]
    jr   _LABEL_5C61_

_LABEL_5C2B_:
    ld   [hl], $01
    ld   b, a
    ld   a, $0F
    sub  b
    ld   [_RAM_D03A_], a
    sla  a
    sla  a
    ld   [_RAM_D037_], a
    ld   hl, _DATA_5D9F_
    ldi  a, [hl]
    add  $08
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ldi  a, [hl]
    sub  $10
    jr   _LABEL_5C61_

_LABEL_5C49_:
    ld   [hl], $02
    sub  $0F
    ld   [_RAM_D03A_], a
    sla  a
    sla  a
    ld   [_RAM_D037_], a
    ld   hl, _DATA_5D9F_
    ldi  a, [hl]
    add  $08
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ldi  a, [hl]
_LABEL_5C61_:
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    ld   hl, _RAM_D037_
    ld   a, $00
    add  [hl]
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    add  $02
    ld   [_RAM_D037_], a
    ld   a, [_RAM_D04A_]
    bit  3, a
    jr   z, _LABEL_5C7C_
    xor  a
    jr   _LABEL_5C8E_

_LABEL_5C7C_:
    bit  2, a
    jr   z, _LABEL_5C84_
    ld   a, $40
    jr   _LABEL_5C8E_

_LABEL_5C84_:
    bit  1, a
    jr   z, _LABEL_5C8C_
    ld   a, $60
    jr   _LABEL_5C8E_

_LABEL_5C8C_:
    ld   a, $20
_LABEL_5C8E_:
    ld   [_RAM_C8CD_], a    ; _RAM_C8CD_ = $C8CD
    call _LABEL_623_
    call _LABEL_5D30_
    ld   a, b
    ldi  [hl], a
    ld   a, [_RAM_D04A_]
    and  $0C
    jr   nz, _LABEL_5CA7_
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    sub  $08
    jr   _LABEL_5CAC_

_LABEL_5CA7_:
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    add  $08
_LABEL_5CAC_:
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   a, [_RAM_D037_]
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    push hl
    call _LABEL_623_
    pop  hl
    ld   a, b
    ldi  [hl], a
    ld   a, [_RAM_D048_]
    and  a
    jr   z, _LABEL_5D2F_
    ld   hl, _DATA_5D7F_
    ld   a, [_RAM_D03A_]
    call add_a_to_hl__486E_
    ld   b, [hl]
    ld   a, [_RAM_D04A_]
    and  $0C
    jr   nz, _LABEL_5CD9_
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    add  b
    jr   _LABEL_5CDD_

_LABEL_5CD9_:
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    sub  b
_LABEL_5CDD_:
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   a, $10
    call add_a_to_hl__486E_
    ld   b, [hl]
    ld   a, [_RAM_D04A_]
    and  $09
    jr   nz, _LABEL_5CF3_
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    add  b
    jr   _LABEL_5CF7_

_LABEL_5CF3_:
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    sub  b
_LABEL_5CF7_:
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    ld   a, [_RAM_D037_]
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call _LABEL_623_
    call _LABEL_5D30_
    inc  hl
    inc  hl
    ld   a, b
    ldi  [hl], a
    ld   a, [_RAM_D04A_]
    and  $0C
    jr   nz, _LABEL_5D18_
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    add  $08
    jr   _LABEL_5D1D_

_LABEL_5D18_:
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    sub  $08
_LABEL_5D1D_:
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   a, [_RAM_D037_]
    sub  $02
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    push hl
    call _LABEL_623_
    pop  hl
    ld   a, b
    ldi  [hl], a
_LABEL_5D2F_:
    ret

_LABEL_5D30_:
    ld   hl, _RAM_D03C_
    ld   a, [_RAM_D048_]
    sla  a
    sla  a
    call add_a_to_hl__486E_
    ret

_LABEL_5D3E_:
    ld   a, [_RAM_D059_]
    and  $0F
    and  a
    ret  nz
    ld   a, [_RAM_D02D_]
    and  a
    ret  nz
    ld   a, $12
    ld   [_RAM_D02D_], a
    ret

memcopy_8_bytes_from_serial_rx_RAM_D028_to_shadow_rtc_RAM_D051__5D50_:
    call _LABEL_5D3E_
    ld   b, $08
    ld   hl, buffer__RAM_D028_
    ld   de, shadow_rtc_buf_start_and_year__RAM_D051_
    call memcopy_b_bytes_from_hl_to_de__482B_
    ret

; TODO: compares buffers at buffer__RAM_D028_ and shadow_rtc_buf_start_and_year__RAM_D051_
; - Wherever they don't match:
;   -  ..D028 is copied into ...D051
;   - _RAM_D03A_ is set to 0x01
_LABEL_5D5F_:
    call _LABEL_5D3E_
    xor  a
    ld   [_RAM_D03A_], a
    ld   b, $08
    ld   hl, buffer__RAM_D028_
    ld   de, shadow_rtc_buf_start_and_year__RAM_D051_

    .loop_compare_buffers__5D6E_:
        ld   a, [de]
        cp   [hl]
        jr   z, .match_ok__5D79_

        ld   a, [hl]
        ld   [de], a
        ld   a, $01
        ld   [_RAM_D03A_], a  ; TODO: Maybe setting "system shadow RTC" doesn't match "Received Hardware RTC"?

    .match_ok__5D79_:
        inc  de
        inc  hl
        dec  b
        jr   nz, .loop_compare_buffers__5D6E_
        ret

; Data from 5D7F to 5D9E (32 bytes)
_DATA_5D7F_:
db $08, $08, $08, $08, $07, $07, $06, $06, $05, $05, $04, $03, $02, $02, $01, $00
db $00, $01, $02, $02, $03, $04, $05, $05, $06, $06, $07, $07, $08, $08, $08, $08

; Data from 5D9F to 5DA5 (7 bytes)
_DATA_5D9F_:
db $68, $42

_DATA_5DA1_:
db $05, $06, $01, $02, $00


; Located at: _5DA6_
;
; Look up Tables used for RTC Date Calculations
;
; Particularly
; - rtc_validate_shadow_data_and_time__5A2B_
;   - called via: rtc_set_to_new_date_and_time___5987_
;
include "inc/rtc_date_calc_LUTs.inc"



; Data from 5DD2 to 5DE0 (15 bytes)
; Text string: "PUESTA EN HORA" (setting the time)
rom_str__PUESTA_EN_HORA__5DD2_:
db $90, $95, $85, $93, $94, $81, $BE, $85, $8E, $BE, $88, $8F, $92, $81, $00

; Data from 5DE1 to 5DF3 (19 bytes)
; Text string: "  PARA CONTINUAR O" (To continue or...)
rom_str__PARA_CONTINUAR_O___5DE1_:
db $BE, $BE, $90, $81, $92, $81, $BE, $83, $8F, $8E, $94, $89, $8E, $95, $81, $92
db $BE, $8F, $00

; Data from 5DF4 to 5E07 (20 bytes)
; Text string: "INVALIDAR PRESIONAR" (... abort, press...)
rom_str__INVALIDAR_PRESIONAR__5DF4_:
db $89, $8E, $96, $81, $8C, $89, $84, $81, $92, $BE, $90, $92, $85, $93, $89, $8F
db $8E, $81, $92, $00

; Data from 5E08 to 5E18 (17 bytes)
; Text string "   ESCAPE SALIDA" (escape/salida key)
rom_str____ESCAPE_SALIDA__5E08_:
db $BE, $BE, $BE, $85, $93, $83, $81, $90, $85, $BE, $93, $81, $8C, $89, $84, $81
db $00

; Data from 5E19 to 5E30 (24 bytes)
_DATA_5E19_:
db $8C, $95, $8E, $8D, $81, $92, $8D, $89, $D7, $8A, $95, $85, $96, $89, $85, $93
db $D6, $82, $84, $8F, $8D, $8C, $95, $8E

; Data from 5E31 to 5E54 (36 bytes)
_DATA_5E31_:
db $85, $8E, $85, $86, $85, $82, $8D, $81, $92, $81, $82, $92, $8D, $81, $99, $8A
db $95, $8E, $8A, $95, $8C, $81, $87, $8F, $93, $85, $90, $8F, $83, $94, $8E, $8F
db $96, $84, $89, $83

_LABEL_5E55_:
    ldh  a, [rLCDC]
    and  $FD
    ldh  [rLCDC], a
    call _LABEL_620A_
    ld   hl, $8800
_LABEL_5E61_:
    xor  a
    ldi  [hl], a
    ld   a, h
    cp   $98
    jr   nz, _LABEL_5E61_

    ; Load last character (underscore) Tile from the main menu font
    ; to Tile Num 0x7B in 0x8800 range
    ld   de, gfx_tile_data__main_menu_font__2F2A_ ; Source
    ld   b, $7F                                  ; Offset +127 tiles (last char)
    ld   hl, _TILEDATA8800                       ; Dest
    ld   c, $7B                                  ; Offset 0x8800 + 0x7B0 = 8FB0
    ld   a, $01                                  ; Copy Size: 1 tile
    call copy_a_x_tile_patterns_from_de_add_bx16_to_hl_add_cx16__48CD_

    call _LABEL_60F3_
    call _display_bg_sprites_on__627_
    xor  a
    ld   [_RAM_D20D_], a
    ld   [_RAM_D04B_], a
    ld   [_RAM_D03A_], a
    ld   a, $18
    ld   [_RAM_D03B_], a

    ld   a, FONT_BLANKSPACE  ; $BE
    ld   b, $10
    ld   hl, maybe_text_buffer__RAM_D6D0_
    .loop_fill_with_spaces__5E93_:
        ldi  [hl], a
        dec  b
        jr   nz, .loop_fill_with_spaces__5E93_

    call _LABEL_6240_


; TODO: This gets called from a lot of places that process characters
_LABEL_5E9A_:
    call input_map_gamepad_buttons_to_keycodes__49C2_
    call _LABEL_6230_
    ld   a, [input_key_pressed__RAM_D025_]
    cp   SYS_CHAR_SALIDA  ; $2A
    jr   nz, _LABEL_5EAE_

    call _LABEL_6265_
    call maybe_input_wait_for_keys__4B84
    ret


_LABEL_5EAE_:
    cp   SYS_CHAR_PRINTSCREEN  ; $2F
    jr   nz, _LABEL_5EB7_
    call maybe_call_printscreen_in_32k_bank_2__522_
    jr   _LABEL_5E9A_

_LABEL_5EB7_:
    cp   SYS_CHAR_PG_ARRIBA  ; $44
    jp   nz, _LABEL_5ED1_
    ld   a, [_RAM_D20D_]
    bit  0, a
    jp   z, _LABEL_5E9A_
    cp   $03
    call z, _LABEL_60E1_
    ld   a, $0E
    ld   [_RAM_D717_], a
    jp   _LABEL_6030_

_LABEL_5ED1_:
    cp   SYS_CHAR_PG_ABAJO  ; $45
    jr   nz, _LABEL_5EEA_
    ld   a, [_RAM_D20D_]
    bit  0, a
    jp   z, _LABEL_5E9A_
    cp   $03
    call z, _LABEL_60E1_
    ld   a, $0D
    ld   [_RAM_D717_], a
    jp   _LABEL_6030_

_LABEL_5EEA_:
    cp   SYS_CHAR_LEFT  ; $3E
    jr   nz, _LABEL_5F13_
    ld   a, [maybe_text_buffer__RAM_D6D0_]
    cp   FONT_BLANKSPACE  ; $BE
    jp   z, _LABEL_5E9A_
    ld   a, [_RAM_D03B_]
    sub  $08
    ld   [_RAM_D03B_], a
    cp   $10
    jp   nz, _LABEL_5F08_
    ld   a, $18
    ld   [_RAM_D03B_], a
_LABEL_5F08_:
    call _LABEL_621C_
    ld   a, $02
    call _LABEL_4A72_
    jp   _LABEL_5E9A_

_LABEL_5F13_:
    cp   SYS_CHAR_RIGHT  ; $3F
    jr   nz, _LABEL_5F34_
    ld   a, [maybe_text_buffer__RAM_D6D0_]
    cp   FONT_BLANKSPACE  ; $BE
    jp   z, _LABEL_5E9A_
    ld   a, [_RAM_D03B_]
    add  $08
    ld   [_RAM_D03B_], a
    cp   $A0
    jp   nz, _LABEL_5F08_
    ld   a, $98
    ld   [_RAM_D03B_], a
    jp   _LABEL_5F08_

_LABEL_5F34_:
    cp   SYS_CHAR_BACKSPACE  ; $2C
    jr   nz, _LABEL_5F50_
    ld   a, [_RAM_D03B_]
    sub  $08
    cp   $10
    jp   z, _LABEL_5E9A_
    ld   [_RAM_D03B_], a
    ld   a, $BE
    ld   [input_key_pressed__RAM_D025_], a
    call _LABEL_621C_
    jp   _LABEL_5F54_

_LABEL_5F50_:
    cp   SYS_CHAR_BORRAR  ; $3C
    jr   nz, _LABEL_5F7A_
_LABEL_5F54_:
    ld   a, [_RAM_D03B_]
    srl  a
    srl  a
    srl  a
    sub  $03
    ld   hl, $D6D0
    call add_a_to_hl__486E_
_LABEL_5F65_:
    ld   a, l
    cp   $DF
    jr   nz, _LABEL_5F73_
    ld   a, $BE
    ld   [hl], a
    call _LABEL_62BD_
    jp   _LABEL_5E9A_

_LABEL_5F73_:
    inc  l
    ld   a, [hl]
    dec  l
    ld   [hl], a
    inc  l
    jr   _LABEL_5F65_


; TODO Is this font -> keyboard char recoding?
_LABEL_5F7A_:
    cp   SYS_CHAR_ENTRA_CR  ; $2E
    jp   z, _LABEL_6022_
    cp   SYS_CHAR_MINUS  ; $CB  ; Maybe also aliased SYS_CHAR_DASH
    jr   nz, _LABEL_5F93_
    call maybe_input_wait_for_keys__4B84
    ld   a, [_RAM_D03B_]
    cp   $10
    jp   z, _LABEL_5E9A_
    ld   a, $CB
    ld   [input_key_pressed__RAM_D025_], a
    _LABEL_5F93_:
        cp   FONT_BLANKSPACE  ; $BE
        jr   nz, char_not_blankspace__5FA1_

        ld   a, [_RAM_D03B_]
        cp   $18
        jp   z, _LABEL_5E9A_
        ld   a, FONT_BLANKSPACE        ; $BE
    char_not_blankspace__5FA1_:

        ; if (char < A..Z) [aka is: FONT_UPARROW]
        cp   FONT_UPPERCASE_FIRST      ; $81
        jp   c, _LABEL_5E9A_

        ; if (char < ,._) [aka is: A..Z uppercase]
        cp   (FONT_UPPERCASE_LAST + 1) ; $9E ; (aka FONT_COMMA)
        jr   c, maybe_handle_alpha_chars__5FDA_

        ; if (char < a..z) [aka is: ,._]
        cp   FONT_LOWERCASE_FIRST      ; $A1
        jp   c, _LABEL_5E9A_

        ; if (char >= ?) [aka is: ?,0-9,and higher (upper 65 chars)]
        cp   FONT_QUESTIONMARK        ; $BF
        jp   nc, _LABEL_5FBF_

        cp   FONT_BLANKSPACE  ; $BE
        jr   z, maybe_handle_alpha_chars__5FDA_

        ; What remains are Lower Case characters
        ; Convert them to Upper Case
        ; Save the result
        sub  FONT_LOWER_TO_UPPER_SUB  ; $20
        ld   [input_key_pressed__RAM_D025_], a
        jr   maybe_handle_alpha_chars__5FDA_

    _LABEL_5FBF_:
        ; Is this a bug that they used $D6 (A-Tilde) instead of the $D5 (N-Tilde) that starts the upper-case tilde chars?
        ; if (char < uppercase A-Tilde) [aka is: a whole bunch, chars 63 - 85]
        cp   (FONT_UPPER_TILDE_FIRST + 1) ; $D6
        jp   c, _LABEL_5E9A_

        ; if (char < jot-underbar) [aka is: upper case tilde]
        cp   (FONT_UPPER_TILDE_LAST + 1)  ; $DB
        jr   c, maybe_handle_alpha_chars__5FDA_
        ; if (char == FONT_JOT_UNDERBAR_MAYBE)
        jp   z, _LABEL_5E9A_

        ; if (char >= dot between bars) [aka is: dot-bars, color inverted 0-9,and higher
        cp   FONT_DOT_BETWEEN_BARS_MAYBE  ; $E2
        jp   nc, _LABEL_5E9A_

        ; if (char < lowercase a-Tilde) skip over lower -> upper adjustment
        cp   FONT_LOWER_TILDE_FIRST  ; $DC
        jp   c, maybe_handle_alpha_chars__5FDA_

        ; What remains are Lower Case Tilde characters
        ; Convert them to Upper Case Tilde characters
        ; Save the result
        sub  FONT_TILDE_LOWER_TO_UPPER_SUB  ; $07
        ld   [input_key_pressed__RAM_D025_], a

    ; Seems to handle A-Z + Tilde + space characters
    maybe_handle_alpha_chars__5FDA_:
        ld   a, [_RAM_D20D_]
        and  a
        jp   z, _LABEL_6007_
        ld   a, $18
        ld   [_RAM_D03B_], a
        xor  a
        ld   [_RAM_D20D_], a
        call _LABEL_621C_
        ld   [_RAM_D04B_], a

        ; Fill maybe_text_buffer__RAM_D6D0_ with blank spaces (clear it out probably)
        ld   a, FONT_BLANKSPACE  ; $BE
        ld   b, $10
        ld   hl, maybe_text_buffer__RAM_D6D0_
        .loop_fill_with_spaces__5FF7_:
            ldi  [hl], a
            dec  b
            jr   nz, .loop_fill_with_spaces__5FF7_

        call _LABEL_620A_
        call _LABEL_62BD_
        call _LABEL_60F3_
        call _display_bg_sprites_on__627_
    _LABEL_6007_:
        ld   a, [_RAM_D03B_]
        add  $08
        cp   $A0
        jp   z, _LABEL_5E9A_
        call _LABEL_61D8_
        ld   a, [_RAM_D03B_]
        add  $08
        ld   [_RAM_D03B_], a
        call _LABEL_6230_
        jp   _LABEL_5E9A_

    _LABEL_6022_:
        ld   hl, maybe_text_buffer__RAM_D6D0_
        ld   a, [hl]
        cp   FONT_BLANKSPACE  ; $BE
        jp   z, _LABEL_5E9A_
        ld   a, $0F
        ld   [_RAM_D717_], a
    _LABEL_6030_:
        call _LABEL_6227_
        ld   a, $A0
        cp   $B0
        jr   z, _LABEL_6044_
        ld   hl, $0028
        res  7, h
        ld   a, $01
        call _switch_bank_jump_hl_RAM__C920_
        ei
    _LABEL_6044_:
        ld   a, [_RAM_D717_]
        cp   $0F
        jr   z, _LABEL_605F_

        ld   b, $10
        ld   de, _RAM_D6F0_
        ld   hl, maybe_text_buffer__RAM_D6D0_
        call memcopy_b_bytes_from_de_to_hl__481F_
        call _LABEL_62BD_
        call _display_bg_sprites_on__627_
        jp   _LABEL_5E9A_

    _LABEL_605F_:
        ld   a, [_RAM_D6E3_]
        bit  7, a
        jr   nz, _LABEL_60B7_
        xor  a
        ld   [_RAM_D20D_], a
        ld   a, $05
        ld   [_RAM_D717_], a
        ld   a, $A0
        cp   $B0
        jr   z, _LABEL_6080_
        ld   hl, $0028
        res  7, h
        ld   a, $01
        call _switch_bank_jump_hl_RAM__C920_
        ei
    _LABEL_6080_:
        ld   a, $10
        ld   [_RAM_D03B_], a
        call _LABEL_6278_
        call _LABEL_620A_
        call _LABEL_60F3_
        ld   a, $0A
        ld   [_RAM_D717_], a
        ld   hl, $0028
        res  7, h
        ld   a, $01
        call _switch_bank_jump_hl_RAM__C920_
        ei
        ld   a, $01
        ld   [_RAM_D20D_], a

        ld   b, $10
        ld   de, _RAM_D6F0_
        ld   hl, maybe_text_buffer__RAM_D6D0_
        call memcopy_b_bytes_from_de_to_hl__481F_
        call _LABEL_62BD_
        call _display_bg_sprites_on__627_
        jp   _LABEL_5E9A_

    _LABEL_60B7_:
        ld   a, [_RAM_D20D_]
        cp   $01
        ld   a, $03
        jr   z, _LABEL_60CE_
        ld   a, [_RAM_D20D_]
        cp   $03
        jr   z, _LABEL_60CE_
        ld   a, $18
        ld   [_RAM_D03B_], a
        ld   a, $03
    _LABEL_60CE_:
        ld   [_RAM_D20D_], a
        ld   a, $A0
        cp   $B0
        jp   z, _LABEL_5E9A_
        call _LABEL_611B_
        call maybe_input_wait_for_keys__4B84
        jp   _LABEL_5E9A_

    _LABEL_60E1_:
        call _LABEL_620A_
        call wait_until_vbl__92C_
        call display_screen_off__94C_
        call _LABEL_60F3_
        ld   a, $01
        ld   [_RAM_D20D_], a
        ret

_LABEL_60F3_:
    ld   de, _DATA_62CF_
    ld   c, $00
    ld   b, $02
    ld   hl, $0103
    call _LABEL_4944_
    ld   de, _DATA_62E3_
    ld   c, $28
    ld   b, $02
    ld   hl, $0606
    call _LABEL_4944_
    ld   de, _DATA_62ED_
    ld   c, $50
    ld   b, $02
    ld   hl, _DATA_20A_ - 1
    call _LABEL_4944_
    ret

_LABEL_611B_:
    call _LABEL_620A_
    call _LABEL_62BD_
    ld   a, [_RAM_D715_]
    and  $7F
    ld   [_RAM_D715_], a
    di
    ld   a, [_RAM_D6E1_]
    ld   h, a
    ld   a, [_RAM_D6E2_]
    ld   l, a
    push hl
    inc  hl
    push hl
    pop  de
    ld   hl, $9000
    ld   bc, $0800
    call _switch_bank_memcopy_hl_to_de_len_bc_RAM__C960_
    pop  hl
    push hl
    call _switch_bank_read_byte_at_hl_RAM__C980_
    call wait_until_vbl__92C_
    call display_screen_off__94C_
    ld   a, [_rombank_readbyte_result__D6E7_]
    bit  7, a
    jr   z, _LABEL_615A_
    ld   hl, $8800
    ld   bc, $0340
    call _switch_bank_memcopy_hl_to_de_len_bc_RAM__C960_
_LABEL_615A_:
    pop  hl
    inc  hl
    ld   a, [_rombank_readbyte_result__D6E7_]
    ld   b, $10
    call multiply_a_x_b__result_in_de__4853_
    add  hl, de
    call _switch_bank_read_byte_at_hl_RAM__C980_
    ld   a, [_rombank_readbyte_result__D6E7_]
    ld   [_RAM_D03A_], a
    ld   b, a
    inc  hl
    call _switch_bank_read_byte_at_hl_RAM__C980_
    ld   a, [_rombank_readbyte_result__D6E7_]
    ld   [_RAM_D1A7_], a    ; _RAM_D1A7_ = $D1A7
    call multiply_a_x_b__result_in_de__4853_
    push de
    pop  bc
    inc  hl
    push hl
    pop  de
    ld   hl, $D800
    call _switch_bank_memcopy_hl_to_de_len_bc_RAM__C960_
    ld   a, [_RAM_D03A_]
    ld   b, a
    ld   a, $14
    sub  b
    srl  a
    ld   b, a
    ld   a, [_RAM_D1A7_]    ; _RAM_D1A7_ = $D1A7
    ld   c, a
    ld   a, $0F
    sub  c
    srl  a
    ld   c, a
    push bc
    ld   b, c
    ld   a, $20
    call multiply_a_x_b__result_in_de__4853_
    pop  bc
    ld   hl, _TILEMAP0; $9800
    add  hl, de
    ld   c, b
    ld   b, $00
    add  hl, bc
    call wait_until_vbl__92C_
    call display_screen_off__94C_
    ld   de, _RAM_D800_
_LABEL_61B4_:
    ld   a, [_RAM_D03A_]
    ld   c, a
_LABEL_61B8_:
    ld   a, [de]
    inc  de
    ldi  [hl], a
    dec  c
    jr   nz, _LABEL_61B8_
    ld   a, [_RAM_D03A_]
    ld   b, a
    ld   a, $20
    sub  b
    call add_a_to_hl__486E_
    ld   a, [_RAM_D1A7_]    ; _RAM_D1A7_ = $D1A7
    dec  a
    ld   [_RAM_D1A7_], a    ; _RAM_D1A7_ = $D1A7
    jr   nz, _LABEL_61B4_
    ldh  a, [rLCDC]
    or   $80
    ldh  [rLCDC], a
    ret

_LABEL_61D8_:
    xor  a
    ld   [_RAM_D401_], a
    ld   a, [_RAM_D03B_]
    srl  a
    srl  a
    srl  a
    dec  a
    push af
    ld   hl, $D6D0
    dec  a
    dec  a
    call add_a_to_hl__486E_
    ld   a, [input_key_pressed__RAM_D025_]
    ld   [_RAM_D400_], a
    ld   [hl], a
    pop  af
    ld   h, a
    ld   l, $0F
    dec  a
    dec  a
    sla  a
    add  $C8
    ld   c, a
    ld   de, _RAM_D400_
    ld   b, $02
    call _LABEL_4944_
    ret

_LABEL_620A_:
    call wait_until_vbl__92C_
    call display_screen_off__94C_
    ld   hl, _TILEMAP0; $9800
_LABEL_6213_:
    ld   a, $FA
    ldi  [hl], a
    ld   a, h
    cp   $9C
    jr   nz, _LABEL_6213_
    ret

_LABEL_621C_:
    ld   a, [_RAM_D03A_]
    cp   $05
    call c, _LABEL_6265_
    jp   _LABEL_6240_

_LABEL_6227_:
    ld   a, [_RAM_D03A_]
    cp   $05
    jp   c, _LABEL_6265_
    ret

_LABEL_6230_:
    ld   a, [_RAM_D03A_]
    inc  a
    ld   [_RAM_D03A_], a
    cp   $05
    jr   z, _LABEL_6265_
    cp   $0A
    jr   z, _LABEL_6240_
    ret

_LABEL_6240_:
    ld   a, [_RAM_D20D_]
    and  a
    ret  nz
    xor  a
    ld   [_RAM_D03A_], a
    ld   a, $88
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    ld   a, [_RAM_D03B_]
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   a, $FB
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    xor  a
    ld   [_RAM_C8CD_], a    ; _RAM_C8CD_ = $C8CD
    call _LABEL_623_
    ld   a, b
    ld   [_RAM_D04B_], a
    ret

_LABEL_6265_:
    ld   a, $05
    ld   [_RAM_D03A_], a
    ld   a, [_RAM_D04B_]
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call oam_free_slot_and_clear__89B_
    xor  a
    ld   [_RAM_D04B_], a
    ret

_LABEL_6278_:
    call _LABEL_620A_
    call wait_until_vbl__92C_
    call display_screen_off__94C_
    call _LABEL_62BD_
    ld   de, _DATA_6312_
    ld   a, [_RAM_D6E3_]
    bit  7, a
    jr   nz, _LABEL_6291_
    ld   de, _DATA_62FF_
_LABEL_6291_:
    ld   c, $00
    ld   b, $02
    ld   hl, $0504
    call _LABEL_4944_
    ld   c, $28
    ld   b, $02
    ld   hl, $0507
    call _LABEL_4944_
    call _display_bg_sprites_on__627_
    ld   b, $19
_LABEL_62AA_:
    push bc
    call input_map_gamepad_buttons_to_keycodes__49C2_
    pop  bc
    ld   a, [input_key_pressed__RAM_D025_]
    cp   $FF
    jr   nz, _LABEL_62B9_
    dec  b
    jr   nz, _LABEL_62AA_
_LABEL_62B9_:
    call maybe_input_wait_for_keys__4B84
    ret

_LABEL_62BD_:
    xor  a
    ld   [_RAM_D6E0_], a
    ld   de, maybe_text_buffer__RAM_D6D0_
    ld   c, $C8
    ld   b, $02
    ld   hl, $020F
    call _LABEL_4944_
    ret

; Data from 62CF to 62E2 (20 bytes)
_DATA_62CF_:
db $85, $93, $83, $92, $89, $82, $89, $92, $BE, $8C, $81, $BE, $90, $81, $8C, $81
db $82, $92, $81, $00

; Data from 62E3 to 62EC (10 bytes)
_DATA_62E3_:
db $64, $83, $8C, $81, $96, $85, $64, $BE, $99, $00

; Data from 62ED to 62FE (18 bytes)
_DATA_62ED_:
db $90, $92, $85, $93, $89, $8F, $8E, $81, $92, $BE, $85, $8E, $94, $92, $81, $84
db $81, $00

; Data from 62FF to 6311 (19 bytes)
_DATA_62FF_:
db $BE, $85, $8E, $94, $92, $81, $84, $81, $00, $8E, $8F, $BE, $96, $81, $8C, $89
db $84, $81, $00

; Data from 6312 to 6327 (22 bytes)
_DATA_6312_:
db $BE, $BE, $90, $81, $8C, $81, $82, $92, $81, $00, $84, $85, $93, $83, $8F, $8E
db $8F, $83, $89, $84, $81, $00

_LABEL_6328_:
    xor  a
    ld   [_RAM_D06C_], a    ; _RAM_D06C_ = $D06C
    ld   [_RAM_D06D_], a    ; _RAM_D06D_ = $D06D
    ld   a, $01
    ld   [_RAM_D1A7_], a    ; _RAM_D1A7_ = $D1A7
    ld   hl, $0018
    res  7, h
    ld   a, $02
    call _switch_bank_jump_hl_RAM__C920_
    ei
    ld   a, [_RAM_D1A7_]    ; _RAM_D1A7_ = $D1A7
    cp   $03
    ret  z
    cp   $04
    ret  z
    push af
    call wait_until_vbl__92C_
    call display_screen_off__94C_
    pop  af
    cp   $02
    jr   z, _LABEL_6369_
    ld   hl, $8800
_LABEL_6357_:
    xor  a
    ldi  [hl], a
    ld   a, h
    cp   $98
    jr   nz, _LABEL_6357_
    ld   hl, _TILEMAP0; $9800
_LABEL_6361_:
    ld   a, $C8
    ldi  [hl], a
    ld   a, h
    cp   $A0
    jr   nz, _LABEL_6361_
_LABEL_6369_:
    ld   de, $18B2
    ld   bc, $0000
    ld   hl, $8C40
    ld   a, $1E
    call copy_a_x_tile_patterns_from_de_add_bx16_to_hl_add_cx16__48CD_
    call wait_until_vbl__92C_
    call display_screen_off__94C_

    ld   a, SELECT_TILEMAP_1  ; $FF
    ld   de, _DATA_1A92_
    call write_tilemap_20x18_from_de_mapselect_in_a__8c4_

    ldh  a, [rLCDC]
    or   (LCDCF_ON | LCDCF_WINON | LCDCF_OBJON)  ; $A1
    ldh  [rLCDC], a
    xor  a
    ld   [_RAM_D192_], a
    ld   [_RAM_D196_], a
    ld   a, $01
    ld   [_RAM_D19C_], a    ; _RAM_D19C_ = $D19C
    ld   [_RAM_D19D_], a    ; _RAM_D19D_ = $D19D
    ld   a, $50
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    ld   a, $58
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    call _LABEL_6510_

_LABEL_63A7_:
    xor  a
    ld   [_RAM_D05D_], a    ; _RAM_D05D_ = $D05D
    ld   [_RAM_D05E_], a    ; _RAM_D05E_ = $D05E
    ld   [_RAM_D05C_], a    ; _RAM_D05C_ = $D05C
    ld   [_RAM_D05B_], a    ; _RAM_D05B_ = $D05B

_LABEL_63B4_:
    call timer_wait_tick_AND_TODO__289_
    call input_read_keys__C8D_
    ld   a, [input_key_pressed__RAM_D025_]
    cp   $2A
    jp   z, _LABEL_6673_
    cp   $30
    jr   nz, _LABEL_63D1_
    ld   a, [_RAM_D19C_]    ; _RAM_D19C_ = $D19C
    ld   [_RAM_D073_], a    ; _RAM_D073_ = $D073
    call _LABEL_67A6_
    jr   _LABEL_63B4_

_LABEL_63D1_:
    cp   $31
    jr   nz, _LABEL_63E0_
    ld   a, [_RAM_D19D_]    ; _RAM_D19D_ = $D19D
    ld   [_RAM_D073_], a    ; _RAM_D073_ = $D073
    call _LABEL_67AC_
    jr   _LABEL_63B4_

_LABEL_63E0_:
cp   SYS_CHAR_F3  ; $32
jp   z, _LABEL_667A_
cp   SYS_CHAR_F4  ; $33


    jp   z, _LABEL_6ACE_
    cp   $34
    jp   z, _LABEL_66D1_
    cp   $2D
    jp   nz, _LABEL_6402_
    ld   a, [_RAM_D196_]    ; _RAM_D196_ = $D196
    cp   $00
    jp   nz, _LABEL_63A7_
    call drawing_app_help_menu_show__6FED_
    jp   _LABEL_63A7_

_LABEL_6402_:
    cp   $2F
    jr   nz, _LABEL_640B_
    call maybe_call_printscreen_in_32k_bank_2__522_
    jr   _LABEL_63B4_

_LABEL_640B_:
    cp   $35
    jr   nz, _LABEL_6416_
    ld   a, [buttons_new_pressed__RAM_D006_]    ; buttons_new_pressed__RAM_D006_ = $D006
    or   $01
    jr   _LABEL_641F_

_LABEL_6416_:
    cp   $36
    jr   nz, _LABEL_6424_
    ld   a, [buttons_new_pressed__RAM_D006_]    ; buttons_new_pressed__RAM_D006_ = $D006
    or   $02
_LABEL_641F_:
    ld   [buttons_new_pressed__RAM_D006_], a    ; buttons_new_pressed__RAM_D006_ = $D006
    jr   _LABEL_6430_

_LABEL_6424_:
    cp   $2E
    jr   nz, _LABEL_6430_
    ld   a, [_RAM_D196_]    ; _RAM_D196_ = $D196
    bit  0, a
    jp   nz, _LABEL_68F3_
_LABEL_6430_:
    call input_map_keycodes_to_gamepad_buttons__4D30_
    ld   a, [buttons_new_pressed__RAM_D006_]    ; buttons_new_pressed__RAM_D006_ = $D006
    and  $C0
    cp   $C0
    jr   nz, _LABEL_6446_
    ld   a, [buttons_new_pressed__RAM_D006_]    ; buttons_new_pressed__RAM_D006_ = $D006
    and  $3F
    ld   [buttons_new_pressed__RAM_D006_], a    ; buttons_new_pressed__RAM_D006_ = $D006
    jr   _LABEL_6457_

_LABEL_6446_:
    ld   a, [buttons_new_pressed__RAM_D006_]    ; buttons_new_pressed__RAM_D006_ = $D006
    and  $30
    cp   $30
    jr   nz, _LABEL_6457_
    ld   a, [buttons_new_pressed__RAM_D006_]    ; buttons_new_pressed__RAM_D006_ = $D006
    and  $CF
    ld   [buttons_new_pressed__RAM_D006_], a    ; buttons_new_pressed__RAM_D006_ = $D006
_LABEL_6457_:
    ld   a, [buttons_new_pressed__RAM_D006_]    ; buttons_new_pressed__RAM_D006_ = $D006
    and  $F3
    jp   z, _LABEL_63A7_
    ld   a, [_RAM_D196_]    ; _RAM_D196_ = $D196
    and  a
    jp   nz, _LABEL_649E_
    ld   a, [buttons_new_pressed__RAM_D006_]    ; buttons_new_pressed__RAM_D006_ = $D006
    bit  0, a
    ld   a, $01
    jr   nz, _LABEL_6478_
    ld   a, [buttons_new_pressed__RAM_D006_]    ; buttons_new_pressed__RAM_D006_ = $D006
    bit  1, a
    jp   z, _LABEL_649E_
    xor  a
_LABEL_6478_:
    ld   hl, _RAM_D192_ ; _RAM_D192_ = $D192
    ld   b, [hl]
    cp   b
    jr   nz, _LABEL_6485_
    call _LABEL_6739_
    jp   _LABEL_63B4_

_LABEL_6485_:
    ld   [hl], a
    ld   a, [_RAM_D04B_]    ; _RAM_D04B_ = $D04B
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a   ; maybe_vram_data_to_write__RAM_C8CC_ = $C8CC
    call _LABEL_953_
    call oam_free_slot_and_clear__89B_
    call _LABEL_6510_
    call maybe_input_wait_for_keys__4B84
    call _LABEL_685B_
    jp   _LABEL_63A7_

_LABEL_649E_:
    ld   a, [_RAM_D04B_]    ; _RAM_D04B_ = $D04B
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a   ; maybe_vram_data_to_write__RAM_C8CC_ = $C8CC
    call _LABEL_953_
    ld   a, [buttons_new_pressed__RAM_D006_]    ; buttons_new_pressed__RAM_D006_ = $D006
    call _LABEL_4C87_
    ld   a, [_RAM_D05E_]    ; _RAM_D05E_ = $D05E
    cp   $01
    call z, _LABEL_6529_
    ld   a, [_RAM_D05D_]    ; _RAM_D05D_ = $D05D
    cp   $01
    call z, _LABEL_6575_
    ld   a, [_RAM_D05C_]    ; _RAM_D05C_ = $D05C
    cp   $01
    call z, _LABEL_65CE_
    ld   a, [_RAM_D05B_]    ; _RAM_D05B_ = $D05B
    cp   $01
    call z, _LABEL_6627_
    ld   a, [_RAM_D192_]    ; _RAM_D192_ = $D192
    and  a
    jp   z, _LABEL_63B4_
    call _LABEL_6F97_
    ld   a, h
    ld   [_RAM_D193_], a    ; _RAM_D193_ = $D193
    ld   a, l
    ld   [_RAM_D194_], a    ; _RAM_D194_ = $D194
    ld   a, $01
    ld   [vbl_action_select__RAM_D195_], a  ; vbl_action_select__RAM_D195_ = $D195
    ei
_LABEL_64E5_:
    ld   a, [vbl_action_select__RAM_D195_]  ; vbl_action_select__RAM_D195_ = $D195
    and  a
    jr   nz, _LABEL_64E5_
    ld   a, [buttons_new_pressed__RAM_D006_]    ; buttons_new_pressed__RAM_D006_ = $D006
    and  $CF
    ld   [buttons_new_pressed__RAM_D006_], a    ; buttons_new_pressed__RAM_D006_ = $D006
    and  $F0
    jp   z, _LABEL_63B4_
    ld   a, $01
    ld   [vbl_action_select__RAM_D195_], a  ; vbl_action_select__RAM_D195_ = $D195
    ld   a, [_RAM_D04B_]    ; _RAM_D04B_ = $D04B
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a   ; maybe_vram_data_to_write__RAM_C8CC_ = $C8CC
    call _LABEL_953_
    ei
_LABEL_6507_:
    ld   a, [vbl_action_select__RAM_D195_]  ; vbl_action_select__RAM_D195_ = $D195
    and  a
    jr   nz, _LABEL_6507_
    jp   _LABEL_63B4_



; TODO: (called from end of drawing app help menu)
_LABEL_6510_:
    ld   a, $D9
    ld   hl, _RAM_D06C_ ; _RAM_D06C_ = $D06C
    add  [hl]
    ld   hl, _RAM_D192_
    add  [hl]
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    xor  a
    ld   [_RAM_C8CD_], a    ; _RAM_C8CD_ = $C8CD
    call _LABEL_623_
    ld   a, b
    ld   [_RAM_D04B_], a
    ret

_LABEL_6529_:
    xor  a
    ld   [_RAM_D05E_], a    ; _RAM_D05E_ = $D05E
    ld   a, [_RAM_D04B_]    ; _RAM_D04B_ = $D04B
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a   ; maybe_vram_data_to_write__RAM_C8CC_ = $C8CC
    call _LABEL_953_
    ld   b, $90
    call _LABEL_688E_
    ld   a, [_RAM_D196_]    ; _RAM_D196_ = $D196
    and  a
    jr   z, _LABEL_6543_
    ld   b, $8C
_LABEL_6543_:
    ld   a, [_tilemap_pos_x__RAM_C8CB_] ; _tilemap_pos_x__RAM_C8CB_ = $C8CB
    inc  a
    cp   b
    ret  nc
    ld   a, $01
    ld   [_tilemap_pos_x__RAM_C8CB_], a ; _tilemap_pos_x__RAM_C8CB_ = $C8CB
    ld   a, [_RAM_D04B_]    ; _RAM_D04B_ = $D04B
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a   ; maybe_vram_data_to_write__RAM_C8CC_ = $C8CC
    ld   a, $00
    ld   [_tilemap_pos_y__RAM_C8CA_], a ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
    call _LABEL_851_
    ld   a, [_RAM_D196_]    ; _RAM_D196_ = $D196
    and  a
    ret  z
    ld   a, $01
    ld   [_tilemap_pos_x__RAM_C8CB_], a ; _tilemap_pos_x__RAM_C8CB_ = $C8CB
    ld   a, [_RAM_D197_ + 1]    ; _RAM_D197_ + 1 = $D198
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a   ; maybe_vram_data_to_write__RAM_C8CC_ = $C8CC
    ld   a, $00
    ld   [_tilemap_pos_y__RAM_C8CA_], a ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
    call _LABEL_851_
    ret

_LABEL_6575_:
    xor  a
    ld   [_RAM_D05D_], a    ; _RAM_D05D_ = $D05D
    ld   a, [_RAM_D04B_]    ; _RAM_D04B_ = $D04B
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a   ; maybe_vram_data_to_write__RAM_C8CC_ = $C8CC
    call _LABEL_953_
    ld   b, $20
    ld   a, [_RAM_D196_]    ; _RAM_D196_ = $D196
    and  a
    jr   z, _LABEL_658C_
    ld   b, $1C
_LABEL_658C_:
    ld   a, [_tilemap_pos_x__RAM_C8CB_] ; _tilemap_pos_x__RAM_C8CB_ = $C8CB
    dec  a
    cp   b
    ret  c
    ld   a, $01
    ld   [_tilemap_pos_x__RAM_C8CB_], a ; _tilemap_pos_x__RAM_C8CB_ = $C8CB
    ld   a, [_RAM_D04B_]    ; _RAM_D04B_ = $D04B
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a   ; maybe_vram_data_to_write__RAM_C8CC_ = $C8CC
    ld   a, [_tilemap_pos_x__RAM_C8CB_] ; _tilemap_pos_x__RAM_C8CB_ = $C8CB
    cpl
    inc  a
    ld   [_tilemap_pos_x__RAM_C8CB_], a ; _tilemap_pos_x__RAM_C8CB_ = $C8CB
    ld   a, $00
    ld   [_tilemap_pos_y__RAM_C8CA_], a ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
    call _LABEL_851_
    ld   a, [_RAM_D196_]    ; _RAM_D196_ = $D196
    and  a
    ret  z
    ld   a, $01
    ld   [_tilemap_pos_x__RAM_C8CB_], a ; _tilemap_pos_x__RAM_C8CB_ = $C8CB
    ld   a, [_RAM_D197_ + 1]    ; _RAM_D197_ + 1 = $D198
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a   ; maybe_vram_data_to_write__RAM_C8CC_ = $C8CC
    ld   a, [_tilemap_pos_x__RAM_C8CB_] ; _tilemap_pos_x__RAM_C8CB_ = $C8CB
    cpl
    inc  a
    ld   [_tilemap_pos_x__RAM_C8CB_], a ; _tilemap_pos_x__RAM_C8CB_ = $C8CB
    ld   a, $00
    ld   [_tilemap_pos_y__RAM_C8CA_], a ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
    call _LABEL_851_
    ret

_LABEL_65CE_:
    xor  a
_LABEL_65CF_:
    ld   [_RAM_D05C_], a    ; _RAM_D05C_ = $D05C
    ld   a, [_RAM_D04B_]    ; _RAM_D04B_ = $D04B
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a   ; maybe_vram_data_to_write__RAM_C8CC_ = $C8CC
    call _LABEL_953_
    ld   b, $18
    ld   a, [_RAM_D196_]    ; _RAM_D196_ = $D196
    and  a
    jr   z, _LABEL_65E5_
    ld   b, $14
_LABEL_65E5_:
    ld   a, [_tilemap_pos_y__RAM_C8CA_] ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
    dec  a
    cp   b
    ret  c
    ld   a, $01
    ld   [_tilemap_pos_y__RAM_C8CA_], a ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
    ld   a, [_RAM_D04B_]    ; _RAM_D04B_ = $D04B
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a   ; maybe_vram_data_to_write__RAM_C8CC_ = $C8CC
    ld   a, [_tilemap_pos_y__RAM_C8CA_] ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
    cpl
    inc  a
    ld   [_tilemap_pos_y__RAM_C8CA_], a ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
    ld   a, $00
    ld   [_tilemap_pos_x__RAM_C8CB_], a ; _tilemap_pos_x__RAM_C8CB_ = $C8CB
    call _LABEL_851_
    ld   a, [_RAM_D196_]    ; _RAM_D196_ = $D196
    and  a
    ret  z
    ld   a, $01
    ld   [_tilemap_pos_y__RAM_C8CA_], a ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
    ld   a, [_RAM_D197_ + 2]    ; _RAM_D197_ + 2 = $D199
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a   ; maybe_vram_data_to_write__RAM_C8CC_ = $C8CC
    ld   a, [_tilemap_pos_y__RAM_C8CA_] ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
    cpl
    inc  a
    ld   [_tilemap_pos_y__RAM_C8CA_], a ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
    ld   a, $00
    ld   [_tilemap_pos_x__RAM_C8CB_], a ; _tilemap_pos_x__RAM_C8CB_ = $C8CB
    call _LABEL_851_
    ret

_LABEL_6627_:
    xor  a
    ld   [_RAM_D05B_], a    ; _RAM_D05B_ = $D05B
    ld   a, [_RAM_D04B_]    ; _RAM_D04B_ = $D04B
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a   ; maybe_vram_data_to_write__RAM_C8CC_ = $C8CC
    call _LABEL_953_
    ld   b, $88
    call _LABEL_688E_
    ld   a, [_RAM_D196_]    ; _RAM_D196_ = $D196
    and  a
    jr   z, _LABEL_6641_
    ld   b, $84
_LABEL_6641_:
    ld   a, [_tilemap_pos_y__RAM_C8CA_] ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
    inc  a
    cp   b
    ret  nc
    ld   a, $01
    ld   [_tilemap_pos_y__RAM_C8CA_], a ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
    ld   a, [_RAM_D04B_]    ; _RAM_D04B_ = $D04B
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a   ; maybe_vram_data_to_write__RAM_C8CC_ = $C8CC
    ld   a, $00
    ld   [_tilemap_pos_x__RAM_C8CB_], a ; _tilemap_pos_x__RAM_C8CB_ = $C8CB
    call _LABEL_851_
    ld   a, [_RAM_D196_]    ; _RAM_D196_ = $D196
    and  a
    ret  z
    ld   a, $01
    ld   [_tilemap_pos_y__RAM_C8CA_], a ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
    ld   a, [_RAM_D197_ + 2]    ; _RAM_D197_ + 2 = $D199
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a   ; maybe_vram_data_to_write__RAM_C8CC_ = $C8CC
    ld   a, $00
    ld   [_tilemap_pos_x__RAM_C8CB_], a ; _tilemap_pos_x__RAM_C8CB_ = $C8CB
    call _LABEL_851_
    ret

_LABEL_6673_:
    ld   a, $03
    ld   [_RAM_D1A7_], a    ; _RAM_D1A7_ = $D1A7
    jr   _LABEL_667F_

_LABEL_667A_:
    ld   a, $02
    ld   [_RAM_D1A7_], a    ; _RAM_D1A7_ = $D1A7
_LABEL_667F_:
    ld   a, [_RAM_D196_]    ; _RAM_D196_ = $D196
    and  a
    jp   nz, _LABEL_694E_
    ld   a, [_RAM_D04B_]    ; _RAM_D04B_ = $D04B
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a   ; maybe_vram_data_to_write__RAM_C8CC_ = $C8CC
    call _LABEL_953_
    ld   a, [_tilemap_pos_x__RAM_C8CB_] ; _tilemap_pos_x__RAM_C8CB_ = $C8CB
    ld   [_RAM_D073_], a    ; _RAM_D073_ = $D073
    ld   a, [_tilemap_pos_y__RAM_C8CA_] ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
    ld   [_RAM_D074_], a
    call oam_free_slot_and_clear__89B_
    ld   hl, _RST__18_  ; _RST__18_ = $0018
    res  7, h
    ld   a, $02
    call _switch_bank_jump_hl_RAM__C920_    ; Possibly invalid
    ei
    ld   a, [_RAM_D1A7_]    ; _RAM_D1A7_ = $D1A7
    cp   $03
    jp   nz, _LABEL_6328_
    ld   a, [_RAM_D073_]    ; _RAM_D073_ = $D073
    ld   [_tilemap_pos_x__RAM_C8CB_], a ; _tilemap_pos_x__RAM_C8CB_ = $C8CB
    ld   a, [_RAM_D074_]
    ld   [_tilemap_pos_y__RAM_C8CA_], a ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
    call _LABEL_6510_
    ld   de, $18B2
    ld   bc, $0000
    ld   hl, $8C40
    ld   a, $1E
    call copy_a_x_tile_patterns_from_de_add_bx16_to_hl_add_cx16__48CD_
    jp   _LABEL_63A7_

_LABEL_66D1_:
    ld   a, [_RAM_D196_]    ; _RAM_D196_ = $D196
    cp   $00
    jp   z, _LABEL_689D_
    ld   a, [_RAM_D04B_]    ; _RAM_D04B_ = $D04B
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a   ; maybe_vram_data_to_write__RAM_C8CC_ = $C8CC
    call _LABEL_953_
    call oam_free_slot_and_clear__89B_
    ld   a, [_RAM_D06D_]    ; _RAM_D06D_ = $D06D
    cp   $00
    ld   a, $03
    jr   z, _LABEL_66F8_
    ld   a, [_RAM_D06D_]    ; _RAM_D06D_ = $D06D
    cp   $03
    ld   a, $06
    jr   z, _LABEL_66F8_
    xor  a
_LABEL_66F8_:
    ld   [_RAM_D06D_], a    ; _RAM_D06D_ = $D06D
    add  $DB
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a   ; maybe_vram_data_to_write__RAM_C8CC_ = $C8CC
    xor  a
    ld   [_RAM_C8CD_], a    ; _RAM_C8CD_ = $C8CD
    call _LABEL_623_
    ld   a, b
    ld   [_RAM_D04B_], a    ; _RAM_D04B_ = $D04B
    ld   de, _RAM_D197_ ; _RAM_D197_ = $D197
    ld   b, $03
_LABEL_6710_:
    ld   a, [de]
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a   ; maybe_vram_data_to_write__RAM_C8CC_ = $C8CC
    push bc
    push de
    call _LABEL_953_
    call oam_free_slot_and_clear__89B_
    ld   hl, _RAM_D06D_ ; _RAM_D06D_ = $D06D
    ld   a, $DB
    add  [hl]
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a   ; maybe_vram_data_to_write__RAM_C8CC_ = $C8CC
    call _LABEL_623_
    pop  de
    ld   a, b
    ld   [de], a
    inc  de
    pop  bc
    dec  b
    jr   nz, _LABEL_6710_
    call maybe_input_wait_for_keys__4B84
    call _LABEL_6765_
    jp   _LABEL_63B4_

_LABEL_6739_:
    ld   a, [_RAM_D04B_]    ; _RAM_D04B_ = $D04B
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a   ; maybe_vram_data_to_write__RAM_C8CC_ = $C8CC
    call _LABEL_953_
    call oam_free_slot_and_clear__89B_
    ld   a, [_RAM_D06C_]    ; _RAM_D06C_ = $D06C
    cp   $00
    ld   a, $03
    jr   z, _LABEL_6758_
    ld   a, [_RAM_D06C_]    ; _RAM_D06C_ = $D06C
    cp   $03
    ld   a, $06
    jr   z, _LABEL_6758_
    xor  a
_LABEL_6758_:
    ld   [_RAM_D06C_], a    ; _RAM_D06C_ = $D06C
    call _LABEL_6510_
    call maybe_input_wait_for_keys__4B84
    call _LABEL_6765_
    ret

_LABEL_6765_:
    call timer_wait_tick_AND_TODO__289_
    ld   a, [buttons_new_pressed__RAM_D006_]    ; buttons_new_pressed__RAM_D006_ = $D006
    bit  0, a
    jr   nz, _LABEL_6765_
    bit  1, a
    jr   nz, _LABEL_6765_
    ret

_LABEL_6774_:
    call wait_until_vbl__92C_
    ld   a, [_RAM_D19B_]
    cp   $00
    ld   hl, $9E07
    jr   z, _LABEL_6784_
    ld   hl, $9E0D
_LABEL_6784_:
    ld   a, $C8
    ld   [hl], a
    ret

_LABEL_6788_:
    call wait_until_vbl__92C_
    ld   a, [_RAM_D19B_]
    cp   $00
    ld   hl, $9E07
    ld   a, [_RAM_D19C_]    ; _RAM_D19C_ = $D19C
    jr   z, _LABEL_67A2_
    ld   hl, $9E0D
    ld   a, [_RAM_D19D_]    ; _RAM_D19D_ = $D19D
    add  $CD
    jr   _LABEL_67A4_

_LABEL_67A2_:
    add  $D0
_LABEL_67A4_:
    ld   [hl], a
    ret

_LABEL_67A6_:
    xor  a
    ld   [_RAM_D19B_], a
    jr   _LABEL_67B1_

_LABEL_67AC_:
    ld   a, $01
    ld   [_RAM_D19B_], a
_LABEL_67B1_:
    ld   a, [_RAM_D196_]    ; _RAM_D196_ = $D196
    and  a
    jp   nz, _LABEL_63B4_
_LABEL_67B8_:
    ld   a, [_RAM_D03A_]    ; _RAM_D03A_ = $D03A
    inc  a
    ld   [_RAM_D03A_], a    ; _RAM_D03A_ = $D03A
    and  $0F
    jr   nz, _LABEL_67C8_
    call _LABEL_6774_
    jr   _LABEL_67CF_

_LABEL_67C8_:
    xor  $08
    jr   nz, _LABEL_67CF_
    call _LABEL_6788_
_LABEL_67CF_:
    call input_map_gamepad_buttons_to_keycodes__49C2_
    ld   a, [input_key_pressed__RAM_D025_]  ; input_key_pressed__RAM_D025_ = $D025
    cp   $2A
    jr   nz, _LABEL_67F5_
    ld   a, [_RAM_D19B_]
    cp   $00
    ld   a, [_RAM_D073_]    ; _RAM_D073_ = $D073
    jr   z, _LABEL_67E8_
    ld   [_RAM_D19D_], a    ; _RAM_D19D_ = $D19D
    jr   _LABEL_67EB_

_LABEL_67E8_:
    ld   [_RAM_D19C_], a    ; _RAM_D19C_ = $D19C
_LABEL_67EB_:
    call _LABEL_6788_
    call _LABEL_685B_
    call maybe_input_wait_for_keys__4B84
    ret

_LABEL_67F5_:
    cp   $2E
    jr   z, _LABEL_67EB_
    cp   $3D
    jr   nz, _LABEL_6808_
    call _LABEL_6817_
    call _LABEL_6788_
    call maybe_input_wait_for_keys__4B84
    jr   _LABEL_67B8_

_LABEL_6808_:
    cp   $40
    jr   nz, _LABEL_67B8_
    call _LABEL_683A_
    call _LABEL_6788_
    call maybe_input_wait_for_keys__4B84
    jr   _LABEL_67B8_

_LABEL_6817_:
    ld   a, [_RAM_D19B_]
    cp   $00
    ld   a, [_RAM_D19D_]    ; _RAM_D19D_ = $D19D
    jr   nz, _LABEL_6825_
    ld   a, [_RAM_D19C_]    ; _RAM_D19C_ = $D19C
    dec  a
_LABEL_6825_:
    cp   $03
    ret  z
    inc  a
    ld   b, a
    ld   a, [_RAM_D19B_]
    and  a
    ld   a, b
    jr   z, _LABEL_6835_
    ld   [_RAM_D19D_], a    ; _RAM_D19D_ = $D19D
    ret

_LABEL_6835_:
    inc  a
    ld   [_RAM_D19C_], a    ; _RAM_D19C_ = $D19C
    ret

_LABEL_683A_:
    ld   a, [_RAM_D19B_]
    and  a
    ld   a, [_RAM_D19D_]    ; _RAM_D19D_ = $D19D
    jr   nz, _LABEL_6847_
    ld   a, [_RAM_D19C_]    ; _RAM_D19C_ = $D19C
    dec  a
_LABEL_6847_:
    and  a
    ret  z
    dec  a
    ld   b, a
    ld   a, [_RAM_D19B_]
    and  a
    ld   a, b
    jr   z, _LABEL_6856_
    ld   [_RAM_D19D_], a    ; _RAM_D19D_ = $D19D
    ret

_LABEL_6856_:
    inc  a
    ld   [_RAM_D19C_], a    ; _RAM_D19C_ = $D19C
    ret

_LABEL_685B_:
    ld   a, [_RAM_D04B_]    ; _RAM_D04B_ = $D04B
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a   ; maybe_vram_data_to_write__RAM_C8CC_ = $C8CC
    call _LABEL_953_
    call oam_free_slot_and_clear__89B_
    ld   b, $88
    call _LABEL_688E_
    ld   a, [_tilemap_pos_y__RAM_C8CA_] ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
    inc  a
    cp   b
    jr   c, _LABEL_6878_
    dec  b
    ld   a, b
    ld   [_tilemap_pos_y__RAM_C8CA_], a ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
_LABEL_6878_:
    ld   b, $90
    call _LABEL_688E_
    ld   a, [_tilemap_pos_x__RAM_C8CB_] ; _tilemap_pos_x__RAM_C8CB_ = $C8CB
    inc  a
    cp   b
    jp   c, _LABEL_688A_
    dec  b
    ld   a, b
    ld   [_tilemap_pos_x__RAM_C8CB_], a ; _tilemap_pos_x__RAM_C8CB_ = $C8CB
_LABEL_688A_:
    call _LABEL_6510_
    ret

_LABEL_688E_:
    ld   a, [_RAM_D192_]    ; _RAM_D192_ = $D192
    cp   $00
    ret  z
    ld   a, [_RAM_D19C_]    ; _RAM_D19C_ = $D19C
    dec  a
    ld   c, a
    ld   a, b
    sub  c
    ld   b, a
    ret

_LABEL_689D_:
    ld   a, [_RAM_D196_]    ; _RAM_D196_ = $D196
    bit  0, a
    jp   nz, _LABEL_63A7_
    ld   a, [_RAM_D04B_]    ; _RAM_D04B_ = $D04B
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a   ; maybe_vram_data_to_write__RAM_C8CC_ = $C8CC
    call _LABEL_953_
    call oam_free_slot_and_clear__89B_
    ld   a, [_tilemap_pos_x__RAM_C8CB_] ; _tilemap_pos_x__RAM_C8CB_ = $C8CB
    sub  $04
    ld   [_tilemap_pos_x__RAM_C8CB_], a ; _tilemap_pos_x__RAM_C8CB_ = $C8CB
    ld   a, [_tilemap_pos_y__RAM_C8CA_] ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
    sub  $04
    ld   [_tilemap_pos_y__RAM_C8CA_], a ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
    ld   hl, _RAM_D06D_ ; _RAM_D06D_ = $D06D
    ld   a, $DB
    add  [hl]
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a   ; maybe_vram_data_to_write__RAM_C8CC_ = $C8CC
    ld   hl, _RAM_D197_ ; _RAM_D197_ = $D197
    ld   b, $03
_LABEL_68CF_:
    push bc
    push hl
    call _LABEL_623_
    pop  hl
    ld   a, b
    ldi  [hl], a
    pop  bc
    dec  b
    jr   nz, _LABEL_68CF_
    call _LABEL_623_
    ld   a, b
    ld   [_RAM_D04B_], a    ; _RAM_D04B_ = $D04B
    ld   a, $01
    ld   [_RAM_D196_], a    ; _RAM_D196_ = $D196
    xor  a
    ld   [_RAM_D192_], a    ; _RAM_D192_ = $D192
    ld   a, $03
    call _LABEL_4A72_
    jp   _LABEL_63A7_

_LABEL_68F3_:
    ld   a, [_RAM_D197_]    ; _RAM_D197_ = $D197
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a   ; maybe_vram_data_to_write__RAM_C8CC_ = $C8CC
    call _LABEL_953_
    ld   a, [_tilemap_pos_x__RAM_C8CB_] ; _tilemap_pos_x__RAM_C8CB_ = $C8CB
    add  $04
    ld   [_RAM_D03A_], a    ; _RAM_D03A_ = $D03A
    ld   a, [_tilemap_pos_y__RAM_C8CA_] ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
    add  $04
    ld   [_RAM_D03B_], a    ; _RAM_D03B_ = $D03B
    ld   a, [_RAM_D04B_]    ; _RAM_D04B_ = $D04B
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a   ; maybe_vram_data_to_write__RAM_C8CC_ = $C8CC
    call _LABEL_953_
    ld   hl, _RAM_D03A_ ; _RAM_D03A_ = $D03A
    ld   a, [_tilemap_pos_x__RAM_C8CB_] ; _tilemap_pos_x__RAM_C8CB_ = $C8CB
    add  $04
    cp   [hl]
    jr   c, _LABEL_6929_
    ld   [_RAM_D19D_ + 3], a    ; _RAM_D19D_ + 3 = $D1A0
    ld   a, [hl]
    ld   [_RAM_D19D_ + 1], a    ; _RAM_D19D_ + 1 = $D19E
    jr   _LABEL_6930_

_LABEL_6929_:
    ld   [_RAM_D19D_ + 1], a    ; _RAM_D19D_ + 1 = $D19E
    ld   a, [hl]
    ld   [_RAM_D19D_ + 3], a    ; _RAM_D19D_ + 3 = $D1A0
_LABEL_6930_:
    ld   hl, _RAM_D03B_ ; _RAM_D03B_ = $D03B
    ld   a, [_tilemap_pos_y__RAM_C8CA_] ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
    add  $04
    cp   [hl]
    jr   c, _LABEL_6944_
    ld   [_RAM_D1A1_], a    ; _RAM_D1A1_ = $D1A1
    ld   a, [hl]
    ld   [_RAM_D19D_ + 2], a    ; _RAM_D19D_ + 2 = $D19F
    jr   _LABEL_694B_

_LABEL_6944_:
    ld   [_RAM_D19D_ + 2], a    ; _RAM_D19D_ + 2 = $D19F
    ld   a, [hl]
    ld   [_RAM_D1A1_], a    ; _RAM_D1A1_ = $D1A1
_LABEL_694B_:
    call _LABEL_6992_

_LABEL_694E_:
    ld   a, [_RAM_D197_]
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call _LABEL_953_
    ld   hl, _RAM_D197_
    ld   b, $03
_LABEL_695C_:
    ldi  a, [hl]
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    push bc
    push hl
    call oam_free_slot_and_clear__89B_
    pop  hl
    pop  bc
    dec  b
    jr   nz, _LABEL_695C_
    ld   a, [_RAM_D04B_]
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call oam_free_slot_and_clear__89B_
    xor  a
    ld   [_RAM_D196_], a
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    add  $04
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    add  $04
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    call _LABEL_6510_
    ld   a, $0A
    call _LABEL_4A72_
    jp   _LABEL_63A7_

_LABEL_6992_:
        ld   a, [_RAM_D19D_ + 1]    ; _RAM_D19D_ + 1 = $D19E
        ld   [_RAM_D1A2_], a    ; _RAM_D1A2_ = $D1A2
        and  $F8
        add  $07
        ld   b, a
        ld   a, [_RAM_D19D_ + 3]    ; _RAM_D19D_ + 3 = $D1A0
        cp   b
        jp   c, _LABEL_69C6_
        jp   z, _LABEL_69C6_
        ld   a, b
        ld   [_RAM_D1A4_], a    ; _RAM_D1A4_ = $D1A4
        call _LABEL_69D0_
_LABEL_69AE_:
        ld   a, [_RAM_D1A4_]    ; _RAM_D1A4_ = $D1A4
        inc  a
        ld   [_RAM_D1A2_], a    ; _RAM_D1A2_ = $D1A2
        add  $07
        ld   hl, _RAM_D19D_ + 3 ; _RAM_D19D_ + 3 = $D1A0
        cp   [hl]
        jp   nc, _LABEL_69C6_
        ld   [_RAM_D1A4_], a    ; _RAM_D1A4_ = $D1A4
        call _LABEL_69D0_
        jr   _LABEL_69AE_

_LABEL_69C6_:
        ld   a, [_RAM_D19D_ + 3]    ; _RAM_D19D_ + 3 = $D1A0
        ld   [_RAM_D1A4_], a    ; _RAM_D1A4_ = $D1A4
        call _LABEL_69D0_
        ret

_LABEL_69D0_:
        ld   a, [_RAM_D19D_ + 2]    ; _RAM_D19D_ + 2 = $D19F
        ld   [_RAM_D1A3_], a    ; _RAM_D1A3_ = $D1A3
        and  $F8
        add  $07
        ld   b, a
        ld   a, [_RAM_D1A1_]    ; _RAM_D1A1_ = $D1A1
        cp   b
        jr   c, _LABEL_6A13_
        jr   z, _LABEL_6A13_
        ld   a, b
        ld   [_RAM_D1A5_], a    ; _RAM_D1A5_ = $D1A5
        ld   a, $02
        ld   [vbl_action_select__RAM_D195_], a  ; vbl_action_select__RAM_D195_ = $D195
        ei
_LABEL_69ED_:
        ld   a, [vbl_action_select__RAM_D195_]  ; vbl_action_select__RAM_D195_ = $D195
        and  a
        jr   nz, _LABEL_69ED_
_LABEL_69F3_:
        ld   a, [_RAM_D1A5_]    ; _RAM_D1A5_ = $D1A5
        inc  a
        ld   [_RAM_D1A3_], a    ; _RAM_D1A3_ = $D1A3
        add  $07
        ld   hl, _RAM_D1A1_ ; _RAM_D1A1_ = $D1A1
        cp   [hl]
        jr   nc, _LABEL_6A13_
        ld   [_RAM_D1A5_], a    ; _RAM_D1A5_ = $D1A5
        ld   a, $02
        ld   [vbl_action_select__RAM_D195_], a  ; vbl_action_select__RAM_D195_ = $D195
        ei
_LABEL_6A0B_:
        ld   a, [vbl_action_select__RAM_D195_]  ; vbl_action_select__RAM_D195_ = $D195
        and  a
        jr   nz, _LABEL_6A0B_
        jr   _LABEL_69F3_

_LABEL_6A13_:
        ld   a, [_RAM_D1A1_]    ; _RAM_D1A1_ = $D1A1
        ld   [_RAM_D1A5_], a    ; _RAM_D1A5_ = $D1A5
        ld   a, $02
        ld   [vbl_action_select__RAM_D195_], a  ; vbl_action_select__RAM_D195_ = $D195
        ei
_LABEL_6A1F_:
        ld   a, [vbl_action_select__RAM_D195_]  ; vbl_action_select__RAM_D195_ = $D195
        and  a
        jr   nz, _LABEL_6A1F_
        ret

_LABEL_6A26_:
    ld   a, [_RAM_D19C_]    ; _RAM_D19C_ = $D19C
    ld   [_RAM_D1A7_], a    ; _RAM_D1A7_ = $D1A7
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    and  $07
    ld   b, $80
    jr   z, _LABEL_6A3A_
_LABEL_6A35_:
    srl  b
    dec  a
    jr   nz, _LABEL_6A35_
_LABEL_6A3A_:
    ld   a, [buttons_new_pressed__RAM_D006_]
    and  $F0
    ret  z
    and  $30
    jp   z, _LABEL_6A6E_
_LABEL_6A45_:
    push hl
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    and  $07
    sla  a
    call add_a_to_hl__486E_
    call _LABEL_6AAD_
    pop  hl
    ld   a, [_RAM_D1A7_]    ; _RAM_D1A7_ = $D1A7
    dec  a
    ld   [_RAM_D1A7_], a    ; _RAM_D1A7_ = $D1A7
    ret  z
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    inc  a
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    and  $07
    jr   nz, _LABEL_6A45_
    push bc
    call maybe_calc_pixelxy_tile_pattern_addr_something__6FA0_
    pop  bc
    jr   _LABEL_6A45_

_LABEL_6A6E_:
    push hl
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    and  $07
    sla  a
    call add_a_to_hl__486E_
    call _LABEL_6AAD_
    pop  hl
    ld   a, [_RAM_D1A7_]    ; _RAM_D1A7_ = $D1A7
    dec  a
    ld   [_RAM_D1A7_], a    ; _RAM_D1A7_ = $D1A7
    ret  z
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    inc  a
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    and  $07
    jr   z, _LABEL_6A94_
    srl  b
    jr   _LABEL_6A6E_

_LABEL_6A94_:
    call maybe_calc_pixelxy_tile_pattern_addr_something__6FA0_
    ld   b, $80
    jr   _LABEL_6A6E_

_LABEL_6A9B_:
    ld   a, [_RAM_D19D_]    ; _RAM_D19D_ = $D19D
    cp   $03
    jr   nz, _LABEL_6AA6_
    ld   a, $03
    jr   _LABEL_6AAC_

_LABEL_6AA6_:
    cp   $01
    jr   nz, _LABEL_6AAC_
    ld   a, $01
_LABEL_6AAC_:
    ret

_LABEL_6AAD_:
    call _LABEL_6A9B_
    bit  0, a
    jr   nz, _LABEL_6ABA_
    ld   a, $FF
    xor  b
    and  [hl]
    jr   _LABEL_6ABC_

_LABEL_6ABA_:
    ld   a, b
    or   [hl]
_LABEL_6ABC_:
    ldi  [hl], a
    call _LABEL_6A9B_
    bit  1, a
    jr   nz, _LABEL_6ACA_
    ld   a, $FF
    xor  b
    and  [hl]
    jr   _LABEL_6ACC_

_LABEL_6ACA_:
    ld   a, b
    or   [hl]
_LABEL_6ACC_:
    ldi  [hl], a
    ret

_LABEL_6ACE_:
    ld   a, [_RAM_D196_]
    cp   $00
    jp   nz, _LABEL_63A7_
    ld   a, [_RAM_D04B_]
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call _LABEL_953_

    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    ld   [buffer__RAM_D028_], a
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    ld   [_RAM_D029_], a
    call oam_free_slot_and_clear__89B_

    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    ld   [_RAM_D1A7_ + 1], a
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    ld   [_RAM_D1A7_ + 2], a
    call _LABEL_6B5F_

    ld   hl, _RAM_D19D_ + 2 ; _RAM_D19D_ + 2 = $D19F
    ld   a, [_RAM_D1A1_]    ; _RAM_D1A1_ = $D1A1
    add  [hl]
    rr   a
    ld   b, a
    ld   a, [_RAM_D1A7_ + 1]    ; _RAM_D1A7_ + 1 = $D1A8
    inc  a
    ld   [_RAM_D1A7_ + 1], a    ; _RAM_D1A7_ + 1 = $D1A8
    dec  a
    dec  a
    ld   [_RAM_D1AD_], a
    ld   a, b
    ld   [_RAM_D1A7_ + 2], a    ; _RAM_D1A7_ + 2 = $D1A9
    ld   [_RAM_D1AE_], a
    xor  a
    ld   [_RAM_D1A7_ + 3], a    ; _RAM_D1A7_ + 3 = $D1AA
    inc  a
    ld   [_RAM_D1AF_], a
    ld   a, [_RAM_D19D_ + 2]    ; _RAM_D19D_ + 2 = $D19F
    ld   [_RAM_D1AB_], a
    ld   [_RAM_D1B0_], a
    ld   a, [_RAM_D1A1_]    ; _RAM_D1A1_ = $D1A1
    ld   [_RAM_D1AC_], a
    ld   [_RAM_D1B1_], a
    ld   b, $5A
    xor  a
    ld   hl, _RAM_D1B2_
_LABEL_6B3A_:
    ldi  [hl], a
    dec  b
    jr   nz, _LABEL_6B3A_
_LABEL_6B3E_:
    ld   a, [_RAM_D1A7_ + 1]    ; _RAM_D1A7_ + 1 = $D1A8
    and  a
    jr   z, _LABEL_6B49_
    call _LABEL_6B92_
    jr   _LABEL_6B3E_

_LABEL_6B49_:
    ld   a, [buffer__RAM_D028_]    ; buffer__RAM_D028_ = $D028
    ld   [_tilemap_pos_x__RAM_C8CB_], a ; _tilemap_pos_x__RAM_C8CB_ = $C8CB
    ld   a, [_RAM_D029_]    ; _RAM_D029_ = $D029
    ld   [_tilemap_pos_y__RAM_C8CA_], a ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
    xor  a
    ld   [_RAM_D192_], a    ; _RAM_D192_ = $D192
    call _LABEL_6510_
    jp   _LABEL_63A7_

_LABEL_6B5F_:
    ld   a, [_RAM_D1A7_ + 1]    ; _RAM_D1A7_ + 1 = $D1A8
    ld   [_tilemap_pos_x__RAM_C8CB_], a ; _tilemap_pos_x__RAM_C8CB_ = $C8CB
    ld   a, [_RAM_D1A7_ + 2]    ; _RAM_D1A7_ + 2 = $D1A9
    ld   [_tilemap_pos_y__RAM_C8CA_], a ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
    ld   [_RAM_D1A7_], a    ; _RAM_D1A7_ = $D1A7
    xor  a
    ld   [_RAM_D03B_], a    ; _RAM_D03B_ = $D03B
    call _LABEL_6CAF_
    ld   a, [_RAM_D19D_ + 2]    ; _RAM_D19D_ + 2 = $D19F
    ld   b, a
    ld   a, [_RAM_D1A7_]    ; _RAM_D1A7_ = $D1A7
    cp   b
    ld   [_RAM_D1A1_], a    ; _RAM_D1A1_ = $D1A1
    ret  z
    ld   a, [_RAM_D1A7_ + 1]    ; _RAM_D1A7_ + 1 = $D1A8
    ld   [_tilemap_pos_x__RAM_C8CB_], a ; _tilemap_pos_x__RAM_C8CB_ = $C8CB
    ld   a, [_RAM_D1A7_ + 2]    ; _RAM_D1A7_ + 2 = $D1A9
    inc  a
    ld   [_tilemap_pos_y__RAM_C8CA_], a ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
    call _LABEL_6D8E_
    ret

_LABEL_6B92_:
    ld   a, [_RAM_D1AB_]
    ld   [_RAM_D19D_ + 2], a    ; _RAM_D19D_ + 2 = $D19F
    ld   a, [_RAM_D1AC_]
    ld   [_RAM_D1A1_], a    ; _RAM_D1A1_ = $D1A1
_LABEL_6B9E_:
    call _LABEL_6BD0_
    and  a
    ret  nz
    ld   a, [_RAM_D19D_ + 2]    ; _RAM_D19D_ + 2 = $D19F
    ld   [_RAM_D1A3_], a    ; _RAM_D1A3_ = $D1A3
    ld   a, [_RAM_D1A1_]    ; _RAM_D1A1_ = $D1A1
    ld   [_RAM_D1A5_], a    ; _RAM_D1A5_ = $D1A5
    call _LABEL_6B5F_
    ld   a, [_RAM_D19D_ + 2]    ; _RAM_D19D_ + 2 = $D19F
    ld   b, a
    ld   a, [_RAM_D1A1_]    ; _RAM_D1A1_ = $D1A1
    cp   b
    ret  z
    call _LABEL_6E52_
    ld   a, [_RAM_D1A7_ + 3]    ; _RAM_D1A7_ + 3 = $D1AA
    and  a
    ld   a, [_RAM_D1A7_ + 1]    ; _RAM_D1A7_ + 1 = $D1A8
    jr   nz, _LABEL_6BCA_
    inc  a
    jr   _LABEL_6BCB_

_LABEL_6BCA_:
    dec  a
_LABEL_6BCB_:
    ld   [_RAM_D1A7_ + 1], a    ; _RAM_D1A7_ + 1 = $D1A8
    jr   _LABEL_6B9E_

_LABEL_6BD0_:
    ld   a, [_RAM_D1A7_ + 1]    ; _RAM_D1A7_ + 1 = $D1A8
    ld   [_tilemap_pos_x__RAM_C8CB_], a ; _tilemap_pos_x__RAM_C8CB_ = $C8CB
    bit  7, a
    jr   nz, _LABEL_6BE0_
    cp   $20
    jr   c, _LABEL_6C40_
    jr   _LABEL_6BE4_

_LABEL_6BE0_:
    cp   $90
    jr   nc, _LABEL_6C40_
_LABEL_6BE4_:
    ld   a, [_RAM_D1A7_ + 2]    ; _RAM_D1A7_ + 2 = $D1A9
    ld   [_tilemap_pos_y__RAM_C8CA_], a ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
    bit  7, a
    jr   nz, _LABEL_6BF4_
    cp   $18
    jr   c, _LABEL_6C40_
    jr   _LABEL_6BF8_

_LABEL_6BF4_:
    cp   $88
    jr   nc, _LABEL_6C40_
_LABEL_6BF8_:
    ld   a, $01
    ld   [_RAM_D03B_], a    ; _RAM_D03B_ = $D03B
    call _LABEL_6CAF_
    ld   a, [_RAM_D1A7_ + 1]    ; _RAM_D1A7_ + 1 = $D1A8
    ld   [_tilemap_pos_x__RAM_C8CB_], a ; _tilemap_pos_x__RAM_C8CB_ = $C8CB
    ld   a, [_RAM_D1A7_ + 2]    ; _RAM_D1A7_ + 2 = $D1A9
    ld   [_tilemap_pos_y__RAM_C8CA_], a ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
    call _LABEL_6D8E_
    ld   hl, _RAM_D1A3_ ; _RAM_D1A3_ = $D1A3
    ld   a, [_RAM_D1A5_]    ; _RAM_D1A5_ = $D1A5
    cp   [hl]
    ld   a, $00
    ret  z
    ld   a, [_RAM_D19D_ + 2]    ; _RAM_D19D_ + 2 = $D19F
    ld   hl, _RAM_D1A3_ ; _RAM_D1A3_ = $D1A3
    sub  [hl]
    jr   nc, _LABEL_6C24_
    jr   _LABEL_6C46_

_LABEL_6C24_:
    ld   a, [_RAM_D1A5_]    ; _RAM_D1A5_ = $D1A5
    ld   hl, _RAM_D1A1_ ; _RAM_D1A1_ = $D1A1
    sub  [hl]
    jr   nc, _LABEL_6C40_
    ld   a, [_RAM_D1A5_]    ; _RAM_D1A5_ = $D1A5
    dec  a
    add  [hl]
    rr   a
    ld   [_RAM_D1A7_ + 2], a    ; _RAM_D1A7_ + 2 = $D1A9
    ld   a, [_RAM_D1A5_]    ; _RAM_D1A5_ = $D1A5
    dec  a
    ld   [_RAM_D1AB_], a
    xor  a
    ret

_LABEL_6C40_:
    call _LABEL_6C9C_
    ld   a, $01
    ret

_LABEL_6C46_:
    ld   a, [_RAM_D19D_ + 2]    ; _RAM_D19D_ + 2 = $D19F
    add  [hl]
    inc  a
    rr   a
    ld   [_RAM_D1A7_ + 2], a    ; _RAM_D1A7_ + 2 = $D1A9
    ld   a, [_RAM_D1A3_]    ; _RAM_D1A3_ = $D1A3
    inc  a
    ld   [_RAM_D1AC_], a
    call _LABEL_6C87_
    ld   a, [_RAM_D1AD_]
    ld   [_RAM_D1A7_ + 1], a    ; _RAM_D1A7_ + 1 = $D1A8
    ld   a, [_RAM_D1A5_]    ; _RAM_D1A5_ = $D1A5
    ld   hl, _RAM_D1A1_ ; _RAM_D1A1_ = $D1A1
    sub  [hl]
    jr   nc, _LABEL_6C82_
    ld   a, [_RAM_D1A5_]    ; _RAM_D1A5_ = $D1A5
    dec  a
    add  [hl]
    rr   a
    ld   [_RAM_D1A7_ + 2], a    ; _RAM_D1A7_ + 2 = $D1A9
    ld   a, [_RAM_D1A5_]    ; _RAM_D1A5_ = $D1A5
    dec  a
    ld   [_RAM_D1AB_], a
    ld   a, [_RAM_D1A1_]    ; _RAM_D1A1_ = $D1A1
    ld   [_RAM_D1AC_], a
    xor  a
    ret

_LABEL_6C82_:
    call _LABEL_6C9C_
    xor  a
    ret

_LABEL_6C87_:
    push hl
    ld   hl, _RAM_D20B_
    ld   de, _RAM_D206_
    ld   b, $5F
_LABEL_6C90_:
    ld   a, [de]
    ldd  [hl], a
    dec  de
    dec  b
    jr   nz, _LABEL_6C90_
    xor  a
    ld   [_RAM_D1A7_ + 1], a    ; _RAM_D1A7_ + 1 = $D1A8
    pop  hl
    ret

_LABEL_6C9C_:
    ld   hl, _RAM_D1A7_ + 1 ; _RAM_D1A7_ + 1 = $D1A8
    ld   de, _RAM_D1AD_
    ld   b, $5F
_LABEL_6CA4_:
    ld   a, [de]
    ldi  [hl], a
    inc  de
    dec  b
    jr   nz, _LABEL_6CA4_
    xor  a
    ld   [_RAM_D207_], a
    ret

_LABEL_6CAF_:
    call maybe_calc_pixelxy_tile_pattern_addr_something__6FA0_
    ld   a, [_tilemap_pos_x__RAM_C8CB_] ; _tilemap_pos_x__RAM_C8CB_ = $C8CB
    and  $07
    ld   b, a
    ld   d, $80
    and  a
    jr   z, _LABEL_6CC2_
_LABEL_6CBD_:
    srl  d
    dec  b
    jr   nz, _LABEL_6CBD_
_LABEL_6CC2_:
    xor  a
    ld   [_RAM_D20C_], a    ; _RAM_D20C_ = $D20C
    ld   a, [_tilemap_pos_y__RAM_C8CA_] ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
    and  $07
    ld   c, a
    inc  c
    sla  a
    call add_a_to_hl__486E_
    inc  hl
    call _LABEL_6D1E_
    ret

_LABEL_6CD7_:
    ld   a, [_RAM_D03B_]
    and  a
    jr   nz, _LABEL_6D0F_
_LABEL_6CDD_:
    ldd  a, [hl]
    ld   b, a
    ldd  a, [hl]
    or   b
    and  d
    jr   nz, _LABEL_6D19_
    inc  hl
    inc  hl
    ld   a, [_RAM_D19D_]    ; _RAM_D19D_ = $D19D
    bit  1, a
    jr   z, _LABEL_6CF1_
    ld   a, [hl]
    or   d
    jr   _LABEL_6CF7_

_LABEL_6CF1_:
    ld   a, $FF
    xor  d
    ld   b, a
    ld   a, [hl]
    and  b
_LABEL_6CF7_:
    ldd  [hl], a
    ld   a, [_RAM_D19D_]    ; _RAM_D19D_ = $D19D
    bit  0, a
    jr   z, _LABEL_6D03_
    ld   a, [hl]
    or   d
    jr   _LABEL_6D09_

_LABEL_6D03_:
    ld   a, $FF
    xor  d
    ld   b, a
    ld   a, [hl]
    and  b
_LABEL_6D09_:
    ldd  [hl], a
    dec  c
    jr   nz, _LABEL_6CDD_
    jr   _LABEL_6D19_

_LABEL_6D0F_:
    ldd  a, [hl]
    ld   b, a
    ldd  a, [hl]
    or   b
    and  d
    jr   z, _LABEL_6D19_
    dec  c
    jr   nz, _LABEL_6D0F_
_LABEL_6D19_:
    ld   a, c
    ld   [_RAM_D03A_], a
    ret

_LABEL_6D1E_:
    ld   a, h
    ld   [_RAM_D193_], a    ; _RAM_D193_ = $D193
    ld   a, l
    ld   [_RAM_D194_], a    ; _RAM_D194_ = $D194
    ld   a, $05
    ld   [vbl_action_select__RAM_D195_], a  ; vbl_action_select__RAM_D195_ = $D195
    ei
_LABEL_6D2C_:
    ld   a, [vbl_action_select__RAM_D195_]  ; vbl_action_select__RAM_D195_ = $D195
    and  a
    jr   nz, _LABEL_6D2C_
    ld   a, [_RAM_D03A_]    ; _RAM_D03A_ = $D03A
    and  a
    jr   nz, _LABEL_6D63_
    ld   a, $01
    ld   [_RAM_D20C_], a    ; _RAM_D20C_ = $D20C
    ld   a, [_tilemap_pos_y__RAM_C8CA_] ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
    and  $F8
    dec  a
    ld   [_tilemap_pos_y__RAM_C8CA_], a ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
    bit  7, a
    jr   nz, _LABEL_6D55_
    cp   $18
    jr   nc, _LABEL_6D55_
    ld   a, $08
    ld   [_RAM_D03A_], a    ; _RAM_D03A_ = $D03A
    jr   _LABEL_6D63_

_LABEL_6D55_:
    push de
    call maybe_calc_pixelxy_tile_pattern_addr_something__6FA0_
    pop  de
    ld   a, $0F
    call add_a_to_hl__486E_
    ld   c, $08
    jr   _LABEL_6D1E_

_LABEL_6D63_:
    ld   a, [_RAM_D20C_]    ; _RAM_D20C_ = $D20C
    and  a
    ld   a, [_RAM_D03A_]    ; _RAM_D03A_ = $D03A
    ld   c, a
    jr   z, _LABEL_6D73_
    ld   a, $08
    sub  c
    ld   c, a
    jr   _LABEL_6D7B_

_LABEL_6D73_:
    ld   a, [_tilemap_pos_y__RAM_C8CA_] ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
    and  $07
    inc  a
    sub  c
    ld   c, a
_LABEL_6D7B_:
    ld   a, [_RAM_D03B_]    ; _RAM_D03B_ = $D03B
    and  a
    ld   a, [_tilemap_pos_y__RAM_C8CA_] ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
    jr   nz, _LABEL_6D89_
    sub  c
    ld   [_RAM_D19D_ + 2], a    ; _RAM_D19D_ + 2 = $D19F
    ret

_LABEL_6D89_:
    sub  c
    ld   [_RAM_D1A3_], a    ; _RAM_D1A3_ = $D1A3
    ret

_LABEL_6D8E_:
    push de
    call maybe_calc_pixelxy_tile_pattern_addr_something__6FA0_
    pop  de
    xor  a
    ld   [_RAM_D20C_], a    ; _RAM_D20C_ = $D20C
    ld   a, [_tilemap_pos_y__RAM_C8CA_] ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
    and  $07
    ld   e, a
    ld   a, $08
    sub  e
    ld   c, a
    ld   a, e
    sla  a
    call add_a_to_hl__486E_
    call _LABEL_6DF2_
    ret

_LABEL_6DAB_:
    ld   a, [_RAM_D03B_]
    and  a
    jr   nz, _LABEL_6DE3_
_LABEL_6DB1_:
    ldi  a, [hl]
    ld   b, a
    ldi  a, [hl]
    or   b
    and  d
    jr   nz, _LABEL_6DED_
    dec  hl
    dec  hl
    ld   a, [_RAM_D19D_]    ; _RAM_D19D_ = $D19D
    bit  0, a
    jr   z, _LABEL_6DC5_
    ld   a, [hl]
    or   d
    jr   _LABEL_6DCB_

_LABEL_6DC5_:
    ld   a, $FF
    xor  d
    ld   b, a
    ld   a, [hl]
    and  b
_LABEL_6DCB_:
    ldi  [hl], a
    ld   a, [_RAM_D19D_]    ; _RAM_D19D_ = $D19D
    bit  1, a
    jr   z, _LABEL_6DD7_
    ld   a, [hl]
    or   d
    jr   _LABEL_6DDD_

_LABEL_6DD7_:
    ld   a, $FF
    xor  d
    ld   b, a
    ld   a, [hl]
    and  b
_LABEL_6DDD_:
    ldi  [hl], a
    dec  c
    jr   nz, _LABEL_6DB1_
    jr   _LABEL_6DED_

_LABEL_6DE3_:
    ldi  a, [hl]
    ld   b, a
    ldi  a, [hl]
    or   b
    and  d
    jr   z, _LABEL_6DED_
    dec  c
    jr   nz, _LABEL_6DE3_
_LABEL_6DED_:
    ld   a, c
    ld   [_RAM_D03A_], a
    ret

_LABEL_6DF2_:
    ld   a, h
    ld   [_RAM_D193_], a    ; _RAM_D193_ = $D193
    ld   a, l
    ld   [_RAM_D194_], a    ; _RAM_D194_ = $D194
    ld   a, $06
    ld   [vbl_action_select__RAM_D195_], a  ; vbl_action_select__RAM_D195_ = $D195
    ei
_LABEL_6E00_:
    ld   a, [vbl_action_select__RAM_D195_]  ; vbl_action_select__RAM_D195_ = $D195
    and  a
    jr   nz, _LABEL_6E00_
    ld   a, [_RAM_D03A_]    ; _RAM_D03A_ = $D03A
    and  a
    jr   nz, _LABEL_6E2E_
    ld   a, $01
    ld   [_RAM_D20C_], a    ; _RAM_D20C_ = $D20C
    ld   a, [_tilemap_pos_y__RAM_C8CA_] ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
    and  $F8
    add  $08
    ld   [_tilemap_pos_y__RAM_C8CA_], a ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
    bit  7, a
    jr   z, _LABEL_6E25_
    cp   $88
    ld   a, $08
    jr   z, _LABEL_6E2E_
_LABEL_6E25_:
    push de
    call maybe_calc_pixelxy_tile_pattern_addr_something__6FA0_
    pop  de
    ld   c, $08
    jr   _LABEL_6DF2_

_LABEL_6E2E_:
    ld   c, a
    ld   a, [_RAM_D20C_]    ; _RAM_D20C_ = $D20C
    and  a
    jr   nz, _LABEL_6E3B_
    ld   a, $08
    sub  e
    sub  c
    jr   _LABEL_6E3E_

_LABEL_6E3B_:
    ld   a, $08
    sub  c
_LABEL_6E3E_:
    ld   e, a
    ld   a, [_RAM_D03B_]    ; _RAM_D03B_ = $D03B
    and  a
    ld   a, [_tilemap_pos_y__RAM_C8CA_] ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
    jr   nz, _LABEL_6E4D_
    add  e
    ld   [_RAM_D1A1_], a    ; _RAM_D1A1_ = $D1A1
    ret

_LABEL_6E4D_:
    add  e
    ld   [_RAM_D1A5_], a    ; _RAM_D1A5_ = $D1A5
    ret

_LABEL_6E52_:
    ld   a, [_RAM_D1A7_ + 3]    ; _RAM_D1A7_ + 3 = $D1AA
    ld   d, a
    ld   hl, _RAM_D19D_ + 2 ; _RAM_D19D_ + 2 = $D19F
    ld   a, [_RAM_D1A3_]    ; _RAM_D1A3_ = $D1A3
    sub  [hl]
    add  $01
    cp   $03
    jr   c, _LABEL_6EC3_
    call _LABEL_6C87_
    ld   a, [_RAM_D1AD_]
    ld   [_RAM_D1A7_ + 1], a    ; _RAM_D1A7_ + 1 = $D1A8
    ld   a, [_RAM_D1A3_]    ; _RAM_D1A3_ = $D1A3
    cp   [hl]
    jr   nc, _LABEL_6E8F_
    add  [hl]
    rr   a
    ld   [_RAM_D1AE_], a
    ld   a, [_RAM_D1A3_]    ; _RAM_D1A3_ = $D1A3
    ld   [_RAM_D1B0_], a
    ld   a, [_RAM_D19D_ + 2]    ; _RAM_D19D_ + 2 = $D19F
    ld   [_RAM_D1B1_], a
_LABEL_6E84_:
    ld   [_RAM_D1AB_], a
    ld   a, [_RAM_D1A1_]    ; _RAM_D1A1_ = $D1A1
    ld   [_RAM_D1AC_], a
    jr   _LABEL_6EC3_

_LABEL_6E8F_:
    add  [hl]
    rr   a
    ld   [_RAM_D1AE_], a
    ld   a, [_RAM_D1AF_]
    bit  0, a
    jr   nz, _LABEL_6EA2_
    ld   a, [_RAM_D1AD_]
    dec  a
    jr   nz, _LABEL_6EA6_
_LABEL_6EA2_:
    ld   a, [_RAM_D1AD_]
    inc  a
_LABEL_6EA6_:
    ld   [_RAM_D1AD_], a
    ld   a, [_RAM_D1AF_]
    ld   b, $01
    xor  b
    ld   [_RAM_D1AF_], a
    ld   a, [_RAM_D19D_ + 2]    ; _RAM_D19D_ + 2 = $D19F
    ld   [_RAM_D1B0_], a
    ld   a, [_RAM_D1A3_]    ; _RAM_D1A3_ = $D1A3
    ld   [_RAM_D1B1_], a
    ld   a, [_RAM_D19D_ + 2]    ; _RAM_D19D_ + 2 = $D19F
    jr   _LABEL_6E84_

_LABEL_6EC3_:
    ld   hl, _RAM_D1A1_ ; _RAM_D1A1_ = $D1A1
    ld   a, [_RAM_D1A5_]    ; _RAM_D1A5_ = $D1A5
    sub  [hl]
    add  $01
    cp   $03
    jr   c, _LABEL_6F27_
    call _LABEL_6C87_
    ld   a, [_RAM_D1AD_]
    ld   [_RAM_D1A7_ + 1], a    ; _RAM_D1A7_ + 1 = $D1A8
    ld   hl, _RAM_D1A1_ ; _RAM_D1A1_ = $D1A1
    ld   a, [_RAM_D1A5_]    ; _RAM_D1A5_ = $D1A5
    cp   [hl]
    jr   c, _LABEL_6EF6_
    add  [hl]
    rr   a
    ld   [_RAM_D1AE_], a
    ld   a, [_RAM_D1A1_]    ; _RAM_D1A1_ = $D1A1
    ld   [_RAM_D1B0_], a
    ld   a, [_RAM_D1A5_]    ; _RAM_D1A5_ = $D1A5
    ld   [_RAM_D1B1_], a
    jr   _LABEL_6F33_

_LABEL_6EF6_:
    add  [hl]
    rr   a
    ld   [_RAM_D1AE_], a
    ld   a, [_RAM_D1AF_]
    bit  0, a
    jr   nz, _LABEL_6F09_
    ld   a, [_RAM_D1AD_]
    dec  a
    jr   _LABEL_6F0D_

_LABEL_6F09_:
    ld   a, [_RAM_D1AD_]
    inc  a
_LABEL_6F0D_:
    ld   [_RAM_D1AD_], a
    ld   a, [_RAM_D1AF_]
    ld   b, $01
    xor  b
    ld   [_RAM_D1AF_], a
    ld   a, [_RAM_D1A5_]    ; _RAM_D1A5_ = $D1A5
    ld   [_RAM_D1B0_], a
    ld   a, [_RAM_D1A1_]    ; _RAM_D1A1_ = $D1A1
    ld   [_RAM_D1B1_], a
    jr   _LABEL_6F33_

_LABEL_6F27_:
    ld   a, [_RAM_D19D_ + 2]    ; _RAM_D19D_ + 2 = $D19F
    ld   hl, _RAM_D1A1_ ; _RAM_D1A1_ = $D1A1
    add  [hl]
    rr   a
    ld   [_RAM_D1A7_ + 2], a    ; _RAM_D1A7_ + 2 = $D1A9
_LABEL_6F33_:
    ld   a, [_RAM_D19D_ + 2]    ; _RAM_D19D_ + 2 = $D19F
    ld   [_RAM_D1AB_], a
    ld   a, [_RAM_D1A1_]    ; _RAM_D1A1_ = $D1A1
    ld   [_RAM_D1AC_], a
    ret


; TODO: Called from VBL, calculates an Tile Pattern VRAM address and loops doing something
_LABEL_6F40_:
    ld   a, [_RAM_D1A2_]    ; _RAM_D1A2_ = $D1A2
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   a, [_RAM_D1A3_]    ; _RAM_D1A3_ = $D1A3
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    call maybe_calc_pixelxy_tile_pattern_addr_something__6FA0_

    ld   a, [_RAM_D1A3_]    ; _RAM_D1A3_ = $D1A3
    ld   b, a
    ld   a, [_RAM_D1A5_]    ; _RAM_D1A5_ = $D1A5
    sub  b
    inc  a
    ld   [_RAM_D1A7_], a    ; _RAM_D1A7_ = $D1A7
    ld   a, [_RAM_D1A3_]    ; _RAM_D1A3_ = $D1A3
    and  $07
    sla  a
    call add_a_to_hl__486E_
    ld   a, [_RAM_D1A2_]    ; _RAM_D1A2_ = $D1A2
    and  $07
    ld   c, a
    ld   a, [_RAM_D1A4_]    ; _RAM_D1A4_ = $D1A4
    and  $07
    sub  c
    ld   b, $80
    jr   z, _LABEL_6F7A_
_LABEL_6F75_:
    sra  b
    dec  a
    jr   nz, _LABEL_6F75_
_LABEL_6F7A_:
    ld   a, c
    and  a
    jr   z, _LABEL_6F83_
_LABEL_6F7E_:
    srl  b
    dec  c
    jr   nz, _LABEL_6F7E_
_LABEL_6F83_:
    ld   a, $FF
    xor  b
    ld   b, a
_LABEL_6F87_:
    ld   a, b
    and  [hl]
    ldi  [hl], a
    ld   a, b
    and  [hl]
    ldi  [hl], a
    ld   a, [_RAM_D1A7_]    ; _RAM_D1A7_ = $D1A7
    dec  a
    ld   [_RAM_D1A7_], a    ; _RAM_D1A7_ = $D1A7
    jr   nz, _LABEL_6F87_
    ret

; Data from 6F97 to 6F9F (9 bytes)
_LABEL_6F97_:
    ld   a, [_RAM_D04B_]    ; _RAM_D04B_ = $D04B
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a   ; maybe_vram_data_to_write__RAM_C8CC_ = $C8CC
    call _LABEL_953_

; TODO - might be for a special direct pixel drawing mode
;
;
; - Indexing something into Tile Pattern VRAM
;
; - Returns resulting address in HL
; maybe_calc_pixelxy_tile_pattern_addr_something__6FA0_
maybe_calc_pixelxy_tile_pattern_addr_something__6FA0_:
    ; Maybe X position of ...
    ; (N / 8) - 4
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    srl  a
    srl  a
    srl  a
    sub  $04
    ld   [_RAM_D03A_], a  ; Maybe just a temp/scratch var
    ; Maybe Y position of ...
    ; ((N / 8) - 3)
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    srl  a
    srl  a
    srl  a
    sub  $03
    ; ... x 14
    ld   b, $0E
    call multiply_a_x_b__result_in_de__4853_
    ; ... +  _RAM_D03A_ (X position?)
    ld   a, e
    ld   hl, _RAM_D03A_
    add  [hl]
    ; Check bit .7 (128) of lower nibble, then save flag result
    bit  7, a
    push af
    ; ... Clear bit .7 of lower nibble
    res  7, a
    ; ... x 16 (maybe calculating tile offset in tile pattern vram)
    ld   b, $10
    call multiply_a_x_b__result_in_de__4853_
    pop  af
    ; If ((a & 0x80) == 0) (For saved bit 7 flag result)
    ; Then wrap around and use the middle tile pattern data at 0x8800
    jr   nz, use_tiledata_8800__6FD5_
    ld   hl, _TILEDATA9000  ; $9000
    jr   using_tiledata_9000__6FEB_

    use_tiledata_8800__6FD5_:
        ld   hl, _TILEDATA8800  ; $8800
        add  hl, de
        ld   a, h
        ; Done if hl addr < 0x8Cxx
        cp   $8C
        ret  c
        jr   z, is_tiledata_8Cxx__6FE3_
        ; If hl addr is > 0x8CFF return fixed addr (last tile in 8800-8FFF)
        ld   hl, $8FF0
        ret

    is_tiledata_8Cxx__6FE3_:
        ld   a, l
        cp   $40
        ret  c
        ld   hl, $8FF0
        ret

    using_tiledata_9000__6FEB_:
        add  hl, de
        ret


; Drawing App Help Menu
;
; It doesn't called from anywhere in 32K Bank 1
; so it's probably launched via a banked call from another bank
;
; Display Drawing App Help Menu Text
; drawing_app_help_menu_show__6FED_:
drawing_app_help_menu_show__6FED_:
        ld   a, [_RAM_D04B_]
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        call _LABEL_953_
        ld   a, [_tilemap_pos_x__RAM_C8CB_]
        ld   [_RAM_D073_], a
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        ld   [_RAM_D074_], a
        call oam_free_slot_and_clear__89B_

        call display_clear_screen_with_space_char__4875_

        ; Copy (Save) Tile Pattern data from 0x8800 -> 0x8000
        call wait_until_vbl__92C_
        call display_screen_off__94C_
        ld   hl, _TILEDATA8800  ; $8800
        ld   de, _TILEDATA8000  ; $8000
        .loop_copy_tile_data__7014_:
            ldi  a, [hl]
            ld   [de], a
            inc  de
            ld   a, d
            cp   HIGH(_TILEDATA8800)  ; $88
            jp   nz, .loop_copy_tile_data__7014_

        ; Now load 8x8 font Tile Patterns into 0x8800
        call wait_until_vbl__92C_
        call display_screen_off__94C_
        ld   hl, _TILEDATA8800                         ; Dest
        ld   de, gfx_tile_data__main_menu_font__2F2A_  ; Source
        ld   bc, (MENU_FONT_128_TILES * TILE_SZ_BYTES) ; Copy size: 128 tiles (2048 bytes)
        call _memcopy_in_RAM__C900_ ; Code is loaded from _memcopy__7D3_

        ; Make a textbox
        ld   bc, $0104             ; Start at 1,4 (x,y) in tiles
        ld   de, $120E             ; Width, Height in tiles
        ld   a, FONT_TEXTBOX_START ; $F2
        ld   hl, _TILEMAP0         ; $9800
        call display_textbox_draw_xy_in_bc_wh_in_de_st_id_in_a__48EB_

        ; Draw Top of Help Menu text (AYUDA) on top of text box
        ld   de, _string_message__drawing_app_help_header__709F_ ; $709F
        ld   hl, $0804    ; Start at 8,4 (x,y) in tiles
        ld   c, PRINT_NORMAL  ; $01
        call render_string_at_de_to_tilemap0_xy_in_hl__4A46_

        ; Draw 10 lines of help text
        ld   de, _string_message__drawing_app_help_text__70A5_ ; $70A5
        ld   hl, $0206   ; Start at 2,6 (x,y) in tiles
        ld   b, 10       ; $0A ; Loop for 10 lines
        ld   c, PRINT_NORMAL  ; $01
        .loop_render_text__7052_:
            push bc
            push hl
            call render_string_at_de_to_tilemap0_xy_in_hl__4A46_
            pop  hl
            pop  bc
            inc  l
            dec  b
            jr   nz, .loop_render_text__7052_

        call _display_bg_sprites_on__627_

        ; TODO : Seems to be the wait loop for User input before leaving help menu
        call maybe_input_wait_for_keys__4B84
        call _LABEL_7721_
        call maybe_input_wait_for_keys__4B84

        ; Copy (Restore) Tile Pattern data from 0x8000 -> 0x8800
        ; that was saved above
        call wait_until_vbl__92C_
        call display_screen_off__94C_
        ld   hl, _TILEDATA8000
        ld   de, _TILEDATA8800
        .loop_copy_tile_data__7075_:
            ldi  a, [hl]
            ld   [de], a
            inc  de
            ld   a, h
            cp   HIGH(_TILEDATA8800)  ; $88
            jp   nz, .loop_copy_tile_data__7075_

        ; Fill Tilemap0 with 0xC8 (TODO: What is this char? "8" ?? (0xC8 - 128 = 72)
        ld   hl, _TILEMAP0
        _LABEL_7081_:
            ld   a, $C8
            ldi  [hl], a
            ld   a, h
            cp   $9C
            jr   nz, _LABEL_7081_

        ; Turn screen + window + sprites on
        ldh  a, [rLCDC]
        or   (LCDCF_ON | LCDCF_WINON | LCDCF_OBJON)  ; $A1
        ldh  [rLCDC], a

        ld   a, [_RAM_D073_]    ; _RAM_D073_ = $D073
        ld   [_tilemap_pos_x__RAM_C8CB_], a ; _tilemap_pos_x__RAM_C8CB_ = $C8CB
        ld   a, [_RAM_D074_]
        ld   [_tilemap_pos_y__RAM_C8CA_], a ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
        call _LABEL_6510_
        ret


        ; Strings for Drawing App Help Menu
        ; Used by drawing_app_help_menu_show__6FED_
        _string_message__drawing_app_help_header__709F_:
        ; "AYUDA" (Help)
        db $81, $99, $95, $84, $81, $00

        _string_message__drawing_app_help_text__70A5_:
        ; "F1: GROSOR" (Thickness ...)
        db $86, $C1, $FE, $BE, $87, $92, $8F, $93, $8F, $92, $00
        ; "    TRAZO" (... Stroke)
        db $BE, $BE, $BE, $BE, $94, $92, $81, $9A, $8F, $00
        ; "F2: TONO DE GRIS" (Color of Gray to draw with)
        db $86, $C2, $FE, $BE, $94, $8F, $8E, $8F, $BE, $84, $85, $BE, $87, $92, $89, $93, $00
        ; "F3: SALVAR" (Save ...)
        db $86, $C3, $FE, $BE, $93, $81, $8C, $96, $81, $92, $00
        ; "    ARCHIVO" (... File)
        db $BE, $BE, $BE, $BE, $81, $92, $83, $88, $89, $96, $8F, $00
        ; "F4: LLENO" (Fill)
        db $86, $C4, $FE, $BE, $8C, $8C, $85, $8E, $8F, $00
        ; "F5: BORRAR" (Erase)
        db $86, $C5, $FE, $BE, $82, $8F, $92, $92, $81, $92, $00
        ; "F6: PLUMA DE" (Pen for ...)
        db $86, $C6, $FE, $BE, $90, $8C, $95, $8D, $81, $BE, $84, $85, $00
        ; "    DIBUJO" (... Drawing)
        db $BE, $BE, $BE, $BE, $84, $89, $82, $95, $8A, $8F, $00
        ; "F7: Flecha" (Arrow?)
        db $86, $C7, $FE, $BE, $86, $8C, $85, $83, $88, $81, $00



_LABEL_711A_:
        ; GFX Loading 128 Tiles (but 45 are valid at start, then a whole separate block, then some code at the end)
        ; Seems to load at least some garbage tiles...
        call wait_until_vbl__92C_
        call display_screen_off__94C_
        ld   hl, _TILEDATA9000                     ; Dest
        ld   de, tile_data_0x40ba_720_bytes__40BA_ ; $40BA
        ld   bc, (128 * TILE_SZ_BYTES)             ; Copy size: 128 tiles (2048 bytes)
        call _memcopy_in_RAM__C900_

        ; Load Tile Data for the main menu font
        call wait_until_vbl__92C_
        call display_screen_off__94C_
        ld   hl, _TILEDATA8800                         ; Dest
        ld   de, gfx_tile_data__main_menu_font__2F2A_   ; Source
        ld   bc, (MENU_FONT_128_TILES * TILE_SZ_BYTES) ; Copy size: 128 tiles (2048 bytes)
        call _memcopy_in_RAM__C900_

        xor  a
        ld   [_RAM_D03B_ + 1], a
        ld   [_RAM_D03B_ + 2], a
        ld   [_RAM_D03B_ + 3], a
        ld   [_RAM_D03F_], a
        ld   a, $01
        ld   [_RAM_D06C_], a    ; _RAM_D06C_ = $D06C
        ld   a, $05
        ld   [_RAM_D06D_], a    ; _RAM_D06D_ = $D06D
        call _LABEL_4A7B_
        ld   a, [_RAM_D06E_]
        cp   $00
        push af
        call z, _LABEL_7185_
        pop  af
        cp   $01
        push af
        call z, _LABEL_720B_
        pop  af
        cp   $02
        push af
        call z, _LABEL_7226_
        pop  af
        cp   $03
        push af
        call z, _LABEL_741D_
        pop  af
        cp   $04
        ret  nc
        xor  a
        ldh  [rSB], a
        ldh  [rSC], a
        call _LABEL_784F_
        jp   _LABEL_711A_

_LABEL_7185_:
        ; Load Tile Data for the main menu font
        call wait_until_vbl__92C_
        call display_screen_off__94C_
        ld   hl, _TILEDATA8800                         ; Dest
        ld   de, gfx_tile_data__main_menu_font__2F2A_   ; Source
        ld   bc, (MENU_FONT_128_TILES * TILE_SZ_BYTES) ; Copy size: 128 tiles (2048 bytes)
        call _memcopy_in_RAM__C900_

        ; GFX Loading 128 Tiles (only 115 intended though?) of 8x16 font
        ;
        ; Note: This accidentally(?) copies more tiles than are in the the tile
        ;       set blob so it picks up the first 13 tiles of the  following 8x8 font (at 0x2FA).
        call wait_until_vbl__92C_
        call display_screen_off__94C_
        ld   hl, _TILEDATA9000                                ; Dest
        ld   de, tile_data_0x27fa_1840_bytes_8x16_font__27FA_ ; Source
        ld   bc, (128 * TILE_SZ_BYTES)                        ; Copy size: 128 tiles (2048 bytes)
        call _memcopy_in_RAM__C900_

        call gfx_load_tile_map_20x6_at_438a__7691_
        call _LABEL_761F_
        call _display_bg_sprites_on__627_
        xor  a
        ld   [_RAM_D04B_], a
        ld   a, $FF
        ld   [_RAM_D079_], a
_LABEL_71BB_:
        call timer_wait_tick_AND_TODO__289_
        call input_read_keys__C8D_
        ld   a, [input_key_pressed__RAM_D025_]
        cp   SYS_CHAR_SALIDA  ; $2A
        jr   z, _LABEL_7207_
        cp   SYS_CHAR_PRINTSCREEN  ; $2F
        jr   nz, _LABEL_71D1_
        call maybe_call_printscreen_in_32k_bank_2__522_
        jr   _LABEL_71BB_

_LABEL_71D1_:
        cp   $18
        jr   nc, _LABEL_71F6_
        ld   hl, _RAM_D079_
        cp   [hl]
        jr   nz, _LABEL_71E2_
        ld   a, $F9
        ld   [_RAM_CC23_], a    ; _RAM_CC23_ = $CC23
        jr   _LABEL_71BB_

_LABEL_71E2_:
        ld   [hl], a
        sla  a
        ld   [_RAM_D03A_], a
        ld   hl, $7980
        call add_a_to_hl__486E_
        call _LABEL_2A2_
        call _LABEL_77D3_
        jr   _LABEL_71BB_

_LABEL_71F6_:
        ld   a, $FF
        ld   [_RAM_D079_], a
        call _LABEL_77B0_
        xor  a
        ld   [_RAM_CC00_], a    ; _RAM_CC00_ = $CC00
        call _LABEL_787C_
        jr   _LABEL_71BB_

_LABEL_7207_:
        call _LABEL_77B0_
        ret

_LABEL_720B_:
        ld   b, $00
        call _LABEL_7242_
        ret  z
        call gfx_load_tile_map_20x6_at_438a__7691_
        call _LABEL_761F_
        call _LABEL_765B_
        call _display_bg_sprites_on__627_
        xor  a
        ld   [_RAM_D07B_], a
        call _LABEL_7310_
        jr   _LABEL_720B_

_LABEL_7226_:
        ld   b, $01
        call _LABEL_7242_
        ret  z
        call gfx_load_tile_map_20x6_at_438a__7691_
        call _LABEL_761F_
        call _LABEL_766D_
        call _display_bg_sprites_on__627_
        ld   a, $01
        ld   [_RAM_D07B_], a
        call _LABEL_7310_
        jr   _LABEL_7226_

_LABEL_7242_:
        push bc

        ; Load Tile Data for the main menu font
        call wait_until_vbl__92C_
        call display_screen_off__94C_
        ld   hl, _TILEDATA8800                         ; Dest
        ld   de, gfx_tile_data__main_menu_font__2F2A_   ; Source
        ld   bc, (MENU_FONT_128_TILES * TILE_SZ_BYTES) ; Copy size: 128 tiles (2048 bytes)
        call _memcopy_in_RAM__C900_

        ; GFX Loading 128 Tiles (only 115 intended though?) of 8x16 font
        ;
        ; Note: This accidentally(?) copies more tiles than are in the the tile
        ;       set blob so it picks up the first 13 tiles of the  following 8x8 font (at 0x2FA).
        call wait_until_vbl__92C_
        call display_screen_off__94C_
        ld   hl, _TILEDATA9000                                ; Dest
        ld   de, tile_data_0x27fa_1840_bytes_8x16_font__27FA_ ; Source
        ld   bc, (128 * TILE_SZ_BYTES)                        ; Copy size: 128 tiles (2048 bytes)
        call _memcopy_in_RAM__C900_

        call display_clear_screen_with_space_char__4875_
        call wait_until_vbl__92C_
        call display_screen_off__94C_
        call _LABEL_761F_
        pop  bc
        bit  0, b
        jr   nz, _LABEL_727D_
        call _LABEL_765B_
        jr   _LABEL_7280_

_LABEL_727D_:
        call _LABEL_766D_
_LABEL_7280_:
        call _display_bg_sprites_on__627_
        ld   de, _DATA_78FF_
        ld   hl, $0109
        ld   c, PRINT_NORMAL  ; $01
        call render_string_at_de_to_tilemap0_xy_in_hl__4A46_
        ld   de, _DATA_7912_
        ld   hl, $030B
        ld   c, PRINT_NORMAL  ; $01
        call render_string_at_de_to_tilemap0_xy_in_hl__4A46_
        xor  a
        ld   [_RAM_D03A_], a
        ld   [_RAM_D03B_], a
_LABEL_72A0_:
        call _LABEL_72F0_
        call timer_wait_tick_AND_TODO__289_
        call input_read_keys__C8D_
        ld   a, [input_key_pressed__RAM_D025_]
        cp   SYS_CHAR_SALIDA  ; $2A
        jr   nz, _LABEL_72B5_
        xor  a
        ld   [_RAM_D03A_], a
        ret

_LABEL_72B5_:
        cp   SYS_CHAR_ENTRA_CR  ; $2E
        jr   nz, _LABEL_72C0_
        ld   a, [_RAM_D03A_]
        and  a
        jr   z, _LABEL_72A0_
        ret

_LABEL_72C0_:
        cp   SYS_CHAR_PRINTSCREEN  ; $2F
        jr   nz, _LABEL_72D9_
        ld   a, $0E
        ld   [_RAM_D03B_], a
        call _LABEL_72F0_
        ld   a, [_RAM_D03A_]
        push af
        call maybe_call_printscreen_in_32k_bank_2__522_
        pop  af
        ld   [_RAM_D03A_], a
        jr   _LABEL_72A0_

_LABEL_72D9_:
        cp   $C1
        jr   c, _LABEL_72A0_
        cp   $CA
        jr   nc, _LABEL_72A0_
        ld   b, a
        call wait_until_vbl__92C_
        ld   a, b
        ld   [$994B], a
        sub  $C0
        ld   [_RAM_D03A_], a
        jr   _LABEL_72A0_

_LABEL_72F0_:
        ld   a, [_RAM_D03B_]
        inc  a
        ld   [_RAM_D03B_], a
        and  $0F
        jr   nz, _LABEL_7304_
        call wait_until_vbl__92C_
        ld   a, $BF
        ld   [$9949], a
        ret

_LABEL_7304_:
        cp   $08
        ret  nz
        call wait_until_vbl__92C_
        ld   a, $BE
        ld   [$9949], a
        ret

_LABEL_7310_:
        ld   hl, _DATA_F45_
        ld   a, [_RAM_D03A_]
        dec  a
        jr   z, _LABEL_7322_
        ld   b, a
_LABEL_731A_:
        ldi  a, [hl]
        cp   $FF
        jr   nz, _LABEL_731A_
        dec  b
        jr   nz, _LABEL_731A_
_LABEL_7322_:
        xor  a
        ld   [_RAM_D07C_], a
_LABEL_7326_:
        push hl
        call _LABEL_7704_
        call _LABEL_76D4_
        call maybe_input_wait_for_keys__4B84
        xor  a
        ld   [_RAM_D04B_], a
_LABEL_7334_:
        xor  a
        ld   [_RAM_CC00_], a    ; _RAM_CC00_ = $CC00
        call _LABEL_787C_
        pop  hl
        ld   a, [hl]
        and  $F0
        cp   $F0
        jp   z, _LABEL_7407_
        ldi  a, [hl]
        ld   b, a
        cp   $54
        jr   nz, _LABEL_7354_
        ld   a, [_RAM_D07B_]
        and  a
        jr   nz, _LABEL_7354_
        inc  hl
        push hl
        jr   _LABEL_7334_

_LABEL_7354_:
        ld   a, b
        sub  $18
        ld   b, a
        ld   a, [_RAM_D03B_]
        cp   b
        jr   nz, _LABEL_7377_
        push hl
        push bc
        ld   a, [_RAM_D07B_]
        and  a
        jr   nz, _LABEL_7375_

input_repeat_key_until_released__7366_:
        call input_read_keys__C8D_
        ld   a, [input_key_modifier_flags__RAM_D027_]
        bit  SYS_KBD_FLAG_KEY_REPEAT_BIT, a  ; 0, a
        jr   z, _LABEL_7375_

        ; delay before Key Repeat test
        call timer_wait_tick_AND_TODO__289_
        jr   input_repeat_key_until_released__7366_

_LABEL_7375_:
        pop  bc
        pop  hl
_LABEL_7377_:
        ld   a, b
        ld   [_RAM_D03B_], a
        sla  a
        ld   [_RAM_D03A_], a
        ldi  a, [hl]
        push hl
        ld   [_RAM_D07A_], a
        xor  a
        ld   [_RAM_D400_], a
        call _LABEL_77D3_
_LABEL_738C_:
        call timer_wait_tick_AND_TODO__289_
        call input_read_keys__C8D_
        ld   a, [input_key_pressed__RAM_D025_]
        cp   SYS_CHAR_SALIDA  ; $2A
        jp   z, _LABEL_7417_
        cp   SYS_CHAR_PRINTSCREEN ; $2F
        jr   nz, _LABEL_73A4_
        call maybe_call_printscreen_in_32k_bank_2__522_
        jp   _LABEL_738C_

_LABEL_73A4_:
        ld   a, [_RAM_D07B_]
        and  a
        jr   nz, _LABEL_73C5_
        ld   a, [input_key_pressed__RAM_D025_]
        ld   b, a
        ld   a, [_RAM_D03B_]
        cp   b
        jr   z, _LABEL_73C5_
        ld   a, [_RAM_D400_]
        cp   $01
        jp   z, _LABEL_7334_
        xor  a
        ld   [_RAM_CC00_], a    ; _RAM_CC00_ = $CC00
        call _LABEL_787C_
        jr   _LABEL_738C_

_LABEL_73C5_:
        ld   hl, $7980
        ld   a, [_RAM_D03B_]
        cp   $3C
        jr   nz, _LABEL_73D1_
        ld   a, $18
_LABEL_73D1_:
        sla  a
        call add_a_to_hl__486E_
        ld   a, [_RAM_CC00_]    ; _RAM_CC00_ = $CC00
        and  a
        jr   nz, _LABEL_73DF_
        call _LABEL_2A2_
_LABEL_73DF_:
        ld   a, [_RAM_D07C_]
        and  a
        jr   nz, _LABEL_73E8_
        call timer_wait_tick_AND_TODO__289_
_LABEL_73E8_:
        ld   a, $01
        ld   [_RAM_D400_], a
        ld   a, [_RAM_D07A_]
        dec  a
        ld   [_RAM_D07A_], a
        jp   z, _LABEL_7334_
        cp   $01
        jr   nz, _LABEL_738C_
        ld   a, [_RAM_D07B_]
        and  a
        jr   z, _LABEL_738C_
        call _LABEL_77B0_
        jp   _LABEL_738C_

_LABEL_7407_:
        call _LABEL_7704_
        call _LABEL_76E0_
_LABEL_740D_:
        call _LABEL_77B0_
        call _LABEL_784F_
        call maybe_input_wait_for_keys__4B84
        ret

_LABEL_7417_:
        pop  hl
        call _LABEL_7704_
        jr   _LABEL_740D_

_LABEL_741D_:
        ; Load Tile Data for the main menu font
        call wait_until_vbl__92C_
        call display_screen_off__94C_
        ld   hl, _TILEDATA8800                         ; Dest
        ld   de, gfx_tile_data__main_menu_font__2F2A_   ; Source
        ld   bc, (MENU_FONT_128_TILES * TILE_SZ_BYTES) ; Copy size: 128 tiles (2048 bytes)
        call _memcopy_in_RAM__C900_

        ; GFX Loading 128 Tiles (only 115 intended though?) of 8x16 font
        ;
        ; Note: This accidentally(?) copies more tiles than are in the the tile
        ;       set blob so it picks up the first 13 tiles of the  following 8x8 font (at 0x2FA).
        call wait_until_vbl__92C_
        call display_screen_off__94C_
        ld   hl, _TILEDATA9000                                ; Dest
        ld   de, tile_data_0x27fa_1840_bytes_8x16_font__27FA_ ; Source
        ld   bc, (128 * TILE_SZ_BYTES)                        ; Copy size: 128 tiles (2048 bytes)
        call _memcopy_in_RAM__C900_

        call gfx_load_tile_map_20x6_at_438a__7691_
        call _LABEL_7631_
        call _LABEL_7704_
        call _LABEL_767F_
        call _display_bg_sprites_on__627_
        xor  a
        ld   [_RAM_D04B_], a
        ld   [_RAM_D03A_], a
        ld   [_RAM_D03B_], a
        ld   [_RAM_D07D_], a
        ld   [_RAM_D07F_], a
        ld   a, $3C
        ld   [_RAM_D079_], a
_LABEL_7465_:
        ld   e, $00
_LABEL_7467_:
        push de
        call timer_wait_tick_AND_TODO__289_
        call input_read_keys__C8D_
        pop  de
        inc  e
_LABEL_7470_:
        ld   a, [input_key_pressed__RAM_D025_]
_LABEL_7473_:
        cp   $2A
        jr   nz, _LABEL_747B_
        call _LABEL_77B0_
        ret

_LABEL_747B_:
        ld   b, a
        ld   a, [_RAM_D079_]
        cp   $3C
        jr   nz, _LABEL_74BD_
        ld   a, b
        cp   $30
        jr   nz, _LABEL_74A6_
        call _LABEL_7704_
        call _LABEL_76F8_
        call maybe_input_wait_for_keys__4B84
        ld   a, $03
        ld   [_RAM_D07F_], a
        ld   a, $03
        ld   [_RAM_D03B_], a
        call _LABEL_7721_
        call _LABEL_7704_
        ld   e, $00
        jp   _LABEL_7470_

_LABEL_74A6_:
        cp   $31
        jp   z, _LABEL_75F0_
        cp   $2E
        jp   z, _LABEL_75BD_
        cp   $32
        jp   z, _LABEL_75A3_
        cp   $2D
        jp   nz, _LABEL_74BD_
        call _LABEL_7733_
_LABEL_74BD_:
        ld   a, [_RAM_D07F_]
        and  a
        jr   nz, _LABEL_74D9_
        ld   a, e
        cp   $1E
        jr   nz, _LABEL_74CB_
        call _LABEL_7704_
_LABEL_74CB_:
        ld   a, [input_key_pressed__RAM_D025_]
        cp   SYS_CHAR_PRINTSCREEN  ; $2F
        jp   nz, _LABEL_7467_
        call maybe_call_printscreen_in_32k_bank_2__522_
        jp   _LABEL_7465_

_LABEL_74D9_:
        ld   a, [input_key_pressed__RAM_D025_]
        cp   $18
        jp   nc, _LABEL_756E_
        ld   hl, _RAM_D079_
        cp   [hl]
        jr   nz, _LABEL_74EF_
        ld   a, $F9
        ld   [_RAM_CC23_], a    ; _RAM_CC23_ = $CC23
        jp   _LABEL_7593_

_LABEL_74EF_:
        ld   b, a
        ld   a, [hl]
        ld   [_RAM_D07E_], a
        ld   [hl], b
        ld   a, b
        sla  a
        ld   [_RAM_D03A_], a
        ld   hl, $7980
        call add_a_to_hl__486E_
        call _LABEL_2A2_
        call _LABEL_77D3_
        ld   a, $01
        ld   [_RAM_D07F_], a
_LABEL_750C_:
        ld   a, [_RAM_D07D_]
        bit  7, a
        jr   nz, _LABEL_7532_
        ld   hl, _RAM_D080_
        inc  a
        ld   [_RAM_D07D_], a
        dec  a
        sla  a
        call add_a_to_hl__486E_
        ld   a, [_RAM_D07E_]
        add  $18
        ldi  [hl], a
        ld   a, [_RAM_D03B_]
        ldi  [hl], a
        ld   a, $03
        ld   [_RAM_D03B_], a
        jp   _LABEL_7465_

_LABEL_7532_:
        call _LABEL_76BC_
        ld   a, $01
        ld   [_RAM_D07C_], a
        xor  a
        ld   [_RAM_CC00_], a    ; _RAM_CC00_ = $CC00
        call _LABEL_787C_
        ld   [_RAM_D07F_], a
        ld   a, $FF
        ld   [_RAM_D180_], a
        ld   a, $3C
        ld   [_RAM_D079_], a
        call _LABEL_77B0_
        call maybe_input_wait_for_keys__4B84
        ld   b, $32
_LABEL_7556_:
        push bc
        call timer_wait_tick_AND_TODO__289_
        call input_read_keys__C8D_
        pop  bc
        ld   a, [input_key_pressed__RAM_D025_]
        cp   $FF
        jr   nz, _LABEL_7568_
        dec  b
        jr   nz, _LABEL_7556_
_LABEL_7568_:
        call _LABEL_7704_
        jp   _LABEL_7473_

_LABEL_756E_:
        ld   a, [_RAM_D07F_]
        bit  1, a
        jp   nz, _LABEL_7465_
        call _LABEL_77B0_
        xor  a
        ld   [_RAM_CC00_], a    ; _RAM_CC00_ = $CC00
        call _LABEL_787C_
        ld   a, [_RAM_D079_]
        cp   $3C
        ld   [_RAM_D07E_], a
        ld   a, $3C
        ld   [_RAM_D079_], a
        jp   nz, _LABEL_750C_
        ld   [_RAM_D07E_], a
_LABEL_7593_:
        ld   a, [_RAM_D03B_]
        inc  a
        cp   $FA
        jr   nz, _LABEL_759D_
        ld   a, $F9
_LABEL_759D_:
        ld   [_RAM_D03B_], a
        jp   _LABEL_7465_

_LABEL_75A3_:
        xor  a
        ld   [_RAM_D07D_], a
        ld   [_RAM_D07C_], a
        call _LABEL_77B0_
        call _LABEL_7704_
        call _LABEL_76C8_
        xor  a
        ld   [_RAM_D07F_], a
        call maybe_input_wait_for_keys__4B84
        jp   _LABEL_7465_

_LABEL_75BD_:
        call _LABEL_75CF_
        call _LABEL_7704_
        call _LABEL_76B0_
        call _LABEL_77B0_
        call maybe_input_wait_for_keys__4B84
        jp   _LABEL_7465_

_LABEL_75CF_:
        ld   hl, _RAM_D080_
        ld   a, [_RAM_D07D_]
        bit  7, a
        jr   nz, _LABEL_75E0_
        sla  a
        call add_a_to_hl__486E_
        jr   _LABEL_75E3_

_LABEL_75E0_:
        ld   hl, _RAM_D180_
_LABEL_75E3_:
        ld   a, $FF
        ld   [hl], a
        ld   a, $01
        ld   [_RAM_D07C_], a
        xor  a
        ld   [_RAM_D07F_], a
        ret

_LABEL_75F0_:
        ld   a, [_RAM_D07C_]
        and  a
        jr   z, _LABEL_760A_
        call _LABEL_75CF_
        ld   a, $01
        ld   [_RAM_D07B_], a
        ld   hl, _RAM_D080_
        call _LABEL_7326_
        call maybe_input_wait_for_keys__4B84
        jp   _LABEL_7465_

_LABEL_760A_:
        call _LABEL_7704_
        call _LABEL_76EC_
        call _LABEL_77B0_
        ld   e, $00
        xor  a
        ld   [_RAM_D07F_], a
        call maybe_input_wait_for_keys__4B84
        jp   _LABEL_7473_

_LABEL_761F_:
        ld   hl, $9820
        call _LABEL_7643_
        ld   de, _DATA_78D7_
        ld   hl, $9828
        ld   b, $05
        call _LABEL_764C_
        ret

_LABEL_7631_:
        ld   hl, $9860
        call _LABEL_7643_
        ld   de, _DATA_78DC_
        ld   hl, $9866
        ld   b, $09
        call _LABEL_764C_
        ret

_LABEL_7643_:
        ld   de, _DATA_78C3_
        ld   b, $14
        call _LABEL_764C_
        ret

_LABEL_764C_:
        ld   a, [de]
        inc  de
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        push de
        call maybe__vram_write_byte_2rows_addr_in_hl_preset_data__5494_
        pop  de
        inc  hl
        dec  b
        jr   nz, _LABEL_764C_
        ret

_LABEL_765B_:
        ld   hl, $9860
        call _LABEL_7643_
        ld   de, _DATA_78E5_
        ld   hl, $9867
        ld   b, $07
        call _LABEL_764C_
        ret

_LABEL_766D_:
        ld   hl, $9860
        call _LABEL_7643_
        ld   de, _DATA_78EC_
        ld   hl, $9865
        ld   b, $0A
        call _LABEL_764C_
        ret

_LABEL_767F_:
        ld   hl, $9820
        call _LABEL_7643_
        ld   de, _DATA_78F6_
        ld   hl, $9826
        ld   b, $09
        call _LABEL_764C_
        ret


gfx_load_tile_map_20x6_at_438a__7691_:
    call display_clear_screen_with_space_char__4875_
    ; Load a tile map for ... ? TODO
    ld   de, tile_map_0x438a_20x6_120_bytes__438a_
    ld   hl, (_TILEMAP0 + (_TILEMAP_WIDTH * 10)) ; $9940 ; 0,10 (x,y) on Tilemap 0
    call wait_until_vbl__92C_
    call display_screen_off__94C_
    ld   c, $06                         ; 6 Rows x 20 Tiles wide of Tile Map entries

    .loop_tilemap_row_load___76A2_:
        ld   b, _TILEMAP_SCREEN_WIDTH  ; $14 ; 20 bytes / Tile Map entries
        call memcopy_b_bytes_from_de_to_hl__481F_
        ; Skip remainder of current Tile Map row down to next line
        ld   a, (_TILEMAP_WIDTH - _TILEMAP_SCREEN_WIDTH)  ; $0C
        call add_a_to_hl__486E_
        dec  c
        jr   nz, .loop_tilemap_row_load___76A2_
    ret


_LABEL_76B0_:
        ld   de, _DATA_7918_
        ld   hl, $0107
        ld   c, PRINT_NORMAL  ; $01
        call render_string_at_de_to_tilemap0_xy_in_hl__4A46_
        ret

_LABEL_76BC_:
        ld   de, _DATA_7927_
        ld   hl, $0107
        ld   c, PRINT_NORMAL  ; $01
        call render_string_at_de_to_tilemap0_xy_in_hl__4A46_
        ret

_LABEL_76C8_:
        ld   de, _DATA_7979_
        ld   hl, $0107
        ld   c, PRINT_NORMAL  ; $01
        call render_string_at_de_to_tilemap0_xy_in_hl__4A46_
        ret

_LABEL_76D4_:
        ld   de, _DATA_795A_
        ld   hl, $0107
        ld   c, PRINT_NORMAL  ; $01
        call render_string_at_de_to_tilemap0_xy_in_hl__4A46_
        ret

_LABEL_76E0_:
        ld   de, _DATA_796B_
        ld   hl, $0107
        ld  c, PRINT_NORMAL  ; $01
        call render_string_at_de_to_tilemap0_xy_in_hl__4A46_
        ret

_LABEL_76EC_:
        ld   de, _DATA_7935_
        ld   hl, $0107
        ld  c, PRINT_NORMAL  ; $01
        call render_string_at_de_to_tilemap0_xy_in_hl__4A46_
        ret

_LABEL_76F8_:
        ld   de, _DATA_7948_
        ld   hl, $0107
        ld  c, PRINT_NORMAL  ; $01
        call render_string_at_de_to_tilemap0_xy_in_hl__4A46_
        ret

_LABEL_7704_:
        ld   hl, $98C0
        ld   b, $14
        call wait_until_vbl__92C_
        ld   a, $BE
_LABEL_770E_:
        ldi  [hl], a
        dec  b
        jr   nz, _LABEL_770E_
        ld   hl, $98E0
        ld   b, $14
        call wait_until_vbl__92C_
        ld   a, $BE
_LABEL_771C_:
        ldi  [hl], a
        dec  b
        jr   nz, _LABEL_771C_
        ret

_LABEL_7721_:
        call input_map_gamepad_buttons_to_keycodes__49C2_
        ld   a, [input_key_pressed__RAM_D025_]
        push af
        cp   SYS_CHAR_PRINTSCREEN  ; $2F
        call z, maybe_call_printscreen_in_32k_bank_2__522_
        pop  af
        cp   $FF
        jr   z, _LABEL_7721_
        ret

_LABEL_7733_:
        ; Load Tile Data for the main menu font
        call wait_until_vbl__92C_
        call display_screen_off__94C_
        ld   hl, _TILEDATA8800                         ; Dest
        ld   de, gfx_tile_data__main_menu_font__2F2A_  ; Source
        ld   bc, (MENU_FONT_128_TILES * TILE_SZ_BYTES) ; Copy size: 128 tiles (2048 bytes)
        call _memcopy_in_RAM__C900_

        ; TODO: GFX
        call wait_until_vbl__92C_
        call display_screen_off__94C_
        ld   hl, _TILEMAP0  ; $9800
        ld   de, _TILEMAP1  ; $9C00
_LABEL_7751_:
        ldi  a, [hl]
        ld   [de], a
        inc  de
        ld   a, h
        cp   $9C
        jr   nz, _LABEL_7751_
        ld   bc, $0107
        ld   de, $120A
        ld   a, $F2
        ld   hl, _TILEMAP0; $9800
        call display_textbox_draw_xy_in_bc_wh_in_de_st_id_in_a__48EB_
        ld   de, _DATA_7888_
        ld   hl, $0707
        ld   c, PRINT_NORMAL  ; $01
        call render_string_at_de_to_tilemap0_xy_in_hl__4A46_
        ld   de, _DATA_788E_
        ld   hl, _DATA_20A_
        ld   b, $04
        ld   c, PRINT_NORMAL  ; $01
_LABEL_777C_:
        push bc
        push hl
        call render_string_at_de_to_tilemap0_xy_in_hl__4A46_
        pop  hl
        pop  bc
        inc  l
        dec  b
        jr   nz, _LABEL_777C_
        ldh  a, [rLCDC]
        and  $CF
        or   $C1
        ldh  [rLCDC], a
        call maybe_input_wait_for_keys__4B84
        call _LABEL_7721_
        call wait_until_vbl__92C_
        call display_screen_off__94C_
        ld   hl, $9C00
        ld   de, _TILEMAP0; $9800
_LABEL_77A1_:
        ldi  a, [hl]
        ld   [de], a
        inc  de
        ld   a, h
        cp   $A0
        jr   nz, _LABEL_77A1_
        call _display_bg_sprites_on__627_
        call maybe_input_wait_for_keys__4B84
        ret

_LABEL_77B0_:
        ld   a, [_RAM_D04B_]
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        call oam_free_slot_and_clear__89B_
        xor  a
        ld   [_RAM_D04B_], a
        ld   b, $04
        ld   hl, _RAM_D03C_
_LABEL_77C2_:
        ld   a, [hl]
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        xor  a
        ldi  [hl], a
        push hl
        push bc
        call oam_free_slot_and_clear__89B_
        pop  bc
        pop  hl
        dec  b
        jr   nz, _LABEL_77C2_
        ret

_LABEL_77D3_:
        call _LABEL_77B0_
        ld   hl, _DATA_79B2_
        ld   a, [_RAM_D03A_]
        cp   $78
        jr   nz, _LABEL_77E4_
        call _LABEL_787C_
        ret

_LABEL_77E4_:
        push bc
        srl  a
        ld   b, $06
        call multiply_a_x_b__result_in_de__4853_
        add  hl, de
        pop  bc
        ldi  a, [hl]
        ld   [_tilemap_pos_x__RAM_C8CB_], a
        ldi  a, [hl]
        ld   [_tilemap_pos_y__RAM_C8CA_], a
        ld   a, $80
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        cp   $90
        jr   z, _LABEL_7807_
        ld   a, $FD
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
_LABEL_7807_:
        xor  a
        ld   [_RAM_C8CD_], a    ; _RAM_C8CD_ = $C8CD
        push hl
        call _LABEL_623_
        pop  hl
        ld   a, b
        ld   [_RAM_D04B_], a
        ld   a, [_tilemap_pos_x__RAM_C8CB_]
        sub  $06
        ld   [_tilemap_pos_x__RAM_C8CB_], a
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        add  $08
        cp   $98
        jr   z, _LABEL_7827_
        sub  $10
_LABEL_7827_:
        ld   [_tilemap_pos_y__RAM_C8CA_], a
        xor  a
        ld   [_RAM_C8CD_], a    ; _RAM_C8CD_ = $C8CD
        ld   b, $04
        ld   de, _RAM_D03B_ + 1 ; _RAM_D03B_ + 1 = $D03C
_LABEL_7833_:
        ldi  a, [hl]
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        push bc
        push de
        push hl
        call _LABEL_623_
        pop  hl
        pop  de
        ld   a, b
        ld   [de], a
        inc  de
        pop  bc
        ld   a, [_tilemap_pos_x__RAM_C8CB_]
        add  $07
        ld   [_tilemap_pos_x__RAM_C8CB_], a
        dec  b
        jr   nz, _LABEL_7833_
        ret

_LABEL_784F_:
        xor  a
        ldh  [rAUDENA], a
        xor  a
        ldh  [rAUD3ENA], a
        ld   a, $FF
        ldh  [rAUD3LEN], a
        ld   a, $55
        ld   bc, $0800 | LOW(_AUD3WAVERAM_LAST) ; | _PORT_3F_
_LABEL_785E_:
        ldh  [c], a
        dec  c
        dec  b
        jr   nz, _LABEL_785E_
        ld   a, AUDENA_ON  ; $80
        ldh  [rAUDENA], a
        ld   a, (AUDVOL_LEFT_MAX | AUDVOL_RIGHT_MAX)  ; $77  ; Set rAUDVOL to Max Left/Right volume, with VIN off for left and right
        ldh  [rAUDVOL], a
        xor  a
        ldh  [rAUD3ENA], a
        ld   a, $28
        ldh  [rAUD1LEN], a
        ldh  [rAUD2LEN], a
        xor  a
        ld   [_RAM_CC00_], a    ; _RAM_CC00_ = $CC00
        call timer_wait_tick_AND_TODO__289_
        ret

_LABEL_787C_:
        xor  a
        ldh  [rAUDENA], a
        ld   a, AUDENA_ON  ; $80
        ldh  [rAUDENA], a
        ld   a, (AUDVOL_LEFT_MAX | AUDVOL_RIGHT_MAX)  ; $77  ; Set rAUDVOL to Max Left/Right volume, with VIN off for left and right
        ldh  [rAUDVOL], a
        ret

; Data from 7888 to 788D (6 bytes)
_DATA_7888_:
    db $81, $99, $95, $84, $81, $00

; Data from 788E to 78C2 (53 bytes)
_DATA_788E_:
    db $86, $C1, $BE, $FE, $BE, $87, $92, $81, $82, $81, $83, $89, $8F, $8E, $00, $86
    db $C2, $BE, $FE, $BE, $94, $8F, $83, $81, $00, $86, $C3, $BE, $FE, $BE, $82, $8F
    db $92, $92, $81, $00, $85, $8E, $94, $92, $81, $BE, $FE, $BE, $83, $8F, $8E, $86
    db $89, $92, $8D, $81, $00

; Data from 78C3 to 78D6 (20 bytes)
_DATA_78C3_:
    db $58, $5A, $5C, $5E, $60
ds 11, $18
    db $62, $64, $66, $68

; Data from 78D7 to 78DB (5 bytes)
_DATA_78D7_:
    db $38, $2A, $1A, $34, $36

; Data from 78DC to 78E4 (9 bytes)
_DATA_78DC_:
    db $20, $22, $18, $18, $38, $2A, $1A, $34, $36

; Data from 78E5 to 78EB (7 bytes)
_DATA_78E5_:
    db $22, $3E, $1E, $42, $22, $30, $1A

; Data from 78EC to 78F5 (10 bytes)
_DATA_78EC_:
    db $1A, $42, $40, $36, $32, $1A, $40, $2A, $1E, $36

; Data from 78F6 to 78FE (9 bytes)
_DATA_78F6_:
    db $26, $3C, $1A, $1C, $1A, $1E, $2A, $36, $34

; Data from 78FF to 7911 (19 bytes)
_DATA_78FF_:
    db $93, $85, $8C, $85, $83, $83, $89, $8F, $8E, $81, $BE, $8D, $85, $8C, $8F, $84
    db $89, $81, $00

; Data from 7912 to 7917 (6 bytes)
_DATA_7912_:
    db $C1, $BE, $CB, $BE, $C9, $00

; Data from 7918 to 7926 (15 bytes)
_DATA_7918_:
    db $84, $85, $8A, $81, $BE, $84, $85, $BE, $87, $92, $81, $82, $81, $92, $00

; Data from 7927 to 7934 (14 bytes)
_DATA_7927_:
    db $8D, $85, $8D, $8F, $92, $89, $81, $BE, $8C, $8C, $85, $8E, $81, $00

; Data from 7935 to 7947 (19 bytes)
_DATA_7935_:
    db $8D, $85, $8C, $8F, $84, $89, $81, $BE, $8E, $8F, $BE, $87, $92, $81, $82, $81
    db $84, $81, $00

; Data from 7948 to 7959 (18 bytes)
_DATA_7948_:
    db $83, $8F, $8D, $89, $85, $8E, $9A, $81, $BE, $81, $BE, $87, $92, $81, $82, $81
    db $92, $00

; Data from 795A to 796A (17 bytes)
_DATA_795A_:
    db $83, $8F, $8D, $89, $85, $8E, $9A, $81, $BE, $81, $BE, $94, $8F, $83, $81, $92
    db $00

; Data from 796B to 7978 (14 bytes)
_DATA_796B_:
    db $84, $85, $8A, $81, $BE, $84, $85, $BE, $94, $8F, $83, $81, $92, $00

; Data from 7979 to 79B1 (57 bytes)
_DATA_7979_:
    db $82, $8F, $92, $92, $81, $92, $00, $18, $F9, $19, $F9, $1A, $F9, $1B, $F9, $1C
    db $F9, $1D, $F9, $1E, $F9, $1F, $F9, $20, $F9, $21, $F9, $22, $F9, $23, $F9, $24
    db $F9, $25, $F9, $26, $F9, $27, $F9, $28, $F9, $29, $F9, $2A, $F9, $2B, $F9, $2C
    db $F9, $2D, $F9, $2E, $F9, $2F, $F9, $54, $F9

; Data from 79B2 to 7FFF (1614 bytes)
_DATA_79B2_:
    db $1C, $90, $84, $8F, $BE, $BE, $20, $58, $84, $8F, $FC, $BE, $24, $90, $92, $85
    db $BE, $BE, $28, $58, $92, $85, $FC, $BE, $2C, $90, $8D, $89, $BE, $BE, $34, $90
    db $86, $81, $BE, $BE, $38, $58, $86, $81, $FC, $BE, $3C, $90, $93, $8F, $8C, $BE
    db $40, $58, $93, $8F, $8C, $FC, $44, $90, $8C, $81, $BE, $BE, $48, $58, $8C, $81
    db $FC, $BE, $4C, $90, $93, $89, $BE, $BE, $54, $90, $84, $8F, $BE, $BE, $58, $58
    db $84, $8F, $FC, $BE, $5C, $90, $92, $85, $BE, $BE, $60, $58, $92, $85, $FC, $BE
    db $64, $90, $8D, $89, $BE, $BE, $6C, $90, $86, $81, $BE, $BE, $70, $58, $86, $81
    db $FC, $BE, $74, $90, $93, $8F, $8C, $BE, $78, $58, $93, $8F, $8C, $FC, $7C, $90
    db $8C, $81, $BE, $BE, $80, $58, $8C, $81, $FC, $BE, $84, $90, $93, $89, $BE, $BE
ds 1470, $00
