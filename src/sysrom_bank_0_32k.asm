
; Bank 0 (32K bank size)
; Memory region 0x000 - 0x7fff

SECTION "rom0", ROM0[$0]
_DUCK_ENTRY_POINT_0000_:
    if DEF(FIX_NO_STACK_INIT)
        di
        ld  sp, $FFFE
        jp   _GB_ENTRY_POINT_100_
    ELSE
        di
        jp   _GB_ENTRY_POINT_100_
        nop
        nop
        nop
    ENDC
    nop

_RST__08_:
    ei
    call ui_icon_menu_draw_and_run__4A7B_
    di
    jp   switch_bank_return_to_saved_bank_RAM__C940_

_RST_10_:
_RST_10_serial_io_send_command_and_buffer__0010_:
    ei
    call serial_io_send_command_and_buffer__A34_
    di
    jp   switch_bank_return_to_saved_bank_RAM__C940_

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
    ld   a, [vbl_action_select__RAM_D195_]
    and  a
    jr   z, _VBL_HANDLER_TAIL__AF_
    cp   $01
    jr   nz, _VBL_HANDLER_2__88_

    call vbl_routine_1__maybe_paint_app__6A26_
    jr   _VBL_HANDLER_TAIL__AF_

    _VBL_HANDLER_2__88_:
        cp   VBL_CMD_2  ; $02
        jr   nz, _VBL_HANDLER_3__91_
        call vbl_routine_2__6F40_
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
        cp   VBL_CMD_5  ; $05
        jr   nz, _VBL_HANDLER_6__AC_
        call vbl_routine_5__6CD7_
        jr   _VBL_HANDLER_TAIL__AF_

    _VBL_HANDLER_6__AC_:
        call vbl_routine_6__6DAB_

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

IF (!(DEF(GB_DEBUG)))
    ; Initialize Serially attached peripheral
    call serial_system_init__9CF_

    ; Init will permanently hang here if the init call above failed
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

    ; Check a verification sequence in RAM
    ; If they don't match then it triggers an RTC reset via Serial IO
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
        ld   a, INIT_KEYS_NO_MATCH_RESET_RTC  ; $AA  ; TODO: needs more specific name
        ld   [_RAM_D400_], a
        jr   .init_keys_check_done_now_init__152_

    .init_keys_check_passed__014E_:
        xor  a
        ld   [_RAM_D400_], a
ENDC
    .init_keys_check_done_now_init__152_:
        di
        ld   sp, $C400
        call general_init__97A_
        call vram_init__752_



    main_system_loop__15C_:
IF (!(DEF(GB_DEBUG)))
        ; Check result of previous init sequence test
        ld   a, [_RAM_D400_]
        cp   INIT_KEYS_NO_MATCH_RESET_RTC  ; $AA
        ; Note: To force an RTC update to configured defaults use this instead (no Z test)
        ; call rtc_set_default_time_and_date__25E_
        call z, rtc_set_default_time_and_date__25E_
ENDC
        ; Load Tile Data for the Main Menu launcher (Icons, Cursor)
        call wait_until_vbl__92C_
        call display_screen_off__94C_
        ld   hl, _TILEDATA9000                          ; Dest
        ld   de, gfx_tile_data__main_menu_icons__11F2_  ; Source
        ld   bc, (MENU_ICONS_128_TILES * TILE_SZ_BYTES) ; Copy size: 128 tiles (2048 bytes)
        call memcopy_in_RAM__C900_

        ; Load Tile Data for the Main Menu font
        call wait_until_vbl__92C_
        call display_screen_off__94C_
        ld   hl, _TILEDATA8800                         ; Dest
        ld   de, gfx_tile_data__main_menu_font__2F2A_   ; Source
        ld   bc, (MENU_FONT_128_TILES * TILE_SZ_BYTES) ; Copy size: 128 tiles (2048 bytes)
        call memcopy_in_RAM__C900_

        xor  a  ; MENU_ESCAPE_KEY_RUNS_LAST_ICON_FALSE
        ld   [ui_grid_menu_escape_key_runs_last_icon__RAM_D06C_], a

        ; Draw Main Menu Tilemap
        ld   a, MAIN_MENU_NUM_ICONS  ; $0C (12)
        ld   [ui_grid_menu_icon_count__RAM_D06D_], a
        call ui_icon_menu_draw_and_run__4A7B_
        call _LABEL_56E_


    ; Select which App to run
        ld   a, [ui_grid_menu_selected_icon__RAM_D06E_]
        cp   MAIN_MENU_APP_CLOCK  ; $00
        jr   nz, .check_app_calendar__1A3_
        call clock_app_init__54AE_
        jr   main_system_loop__15C_

    .check_app_calendar__1A3_:
        cp   MAIN_MENU_APP_CALENDAR  ; $01
        jr   nz, .check_app_calculator__1B3_
        xor  a
        ldh  [rSCX], a
        call calendar_app_init__4D6F_
        ld   a, $FF
        ldh  [rSCX], a
        jr   main_system_loop__15C_

    .check_app_calculator__1B3_:
        cp   MAIN_MENU_APP_CALCULATOR  ; $02
        jr   nz, .check_app_agenda__1C5_
        di
        ld   hl, _RST__08_  ; _RST__08_ in Bank 1 might launch the Agenda App
        res  7, h           ; TODO: What does this even do when H is already 0x00?
        ld   a, $01
        call switch_bank_in_a_jump_hl_RAM__C920_
        ei
        jr   main_system_loop__15C_

    .check_app_agenda__1C5_:
        cp   MAIN_MENU_APP_AGENDA  ; $03
        jr   nz, .check_app_spellchecker__1D7_
        di
        ld   hl, _RST_10_  ; _RST_10_ in Bank 1 might launch the Agenda App
        res  7, h          ; TODO: What does this even do when H is already 0x00?
        ld   a, $01
        call switch_bank_in_a_jump_hl_RAM__C920_
        ei
        jr   main_system_loop__15C_

    .check_app_spellchecker__1D7_:
        cp   MAIN_MENU_APP_SPELLCHECKER  ; $04
        jr   nz, .check_app_games__1EA_
        di
        ld   hl, _RST__18_  ; _RST__18_ in Bank 1 might launch the Spellchecker App
        res  7, h           ; TODO: What does this even do when H is already 0x00?
        ld   a, $01
        call switch_bank_in_a_jump_hl_RAM__C920_
        ei
        jp   main_system_loop__15C_

    .check_app_games__1EA_:
        cp   MAIN_MENU_APP_GAMES  ; $05
        jr   nz, .check_app_paint__1FD_
        di
        ld   hl, _RST__20_  ; _RST__20_ in Bank 1 might launch the Games App
        res  7, h           ; TODO: What does this even do when H is already 0x00?
        ld   a, $01
        call switch_bank_in_a_jump_hl_RAM__C920_
        ei
        jp   main_system_loop__15C_

    .check_app_paint__1FD_:
        cp   MAIN_MENU_APP_PAINT  ; $06
        jr   nz, .check_app_basic__20D_
        call main_menu_maybe_save_something__52F_
        call paint_app_init__6328_
        call main_menu_maybe_restore_something__54B_
        jp   main_system_loop__15C_

    .check_app_basic__20D_:
        cp   MAIN_MENU_APP_BASIC  ; $07
        jr   nz, .check_app_paino__226_
        di
        call main_menu_maybe_save_something__52F_
        ld   hl, _RST_10_  ; _RST_10_ in Bank 2 might launch the Basic Programming App
        res  7, h          ; TODO: What does this even do when H is already 0x00?
        ld   a, $02
        call switch_bank_in_a_jump_hl_RAM__C920_
        call main_menu_maybe_restore_something__54B_
        ei
        jp   main_system_loop__15C_

    .check_app_paino__226_:
        cp   MAIN_MENU_APP_PIANO  ; $08
        jr   nz, .check_app_word_processor__230_
        call piano_app_icon_menu_init__711A_
        jp   main_system_loop__15C_

    .check_app_word_processor__230_:
        cp   MAIN_MENU_APP_WORD_PROCESSOR  ; $09
        jr   nz, .check_app_worddrawings__249_
        di
        call main_menu_maybe_save_something__52F_
        ld   hl, _RST__08_ ; _RST_08_ in Bank 2 might launch the Word Processor App
        res  7, h          ; TODO: What does this even do when H is already 0x00?
        ld   a, $02
        call switch_bank_in_a_jump_hl_RAM__C920_
        call main_menu_maybe_restore_something__54B_
        ei
        jp   main_system_loop__15C_

    .check_app_worddrawings__249_:
        cp   MAIN_MENU_APP_WORDDRAWINGS  ; $0A (10)
        jr   nz, .check_app_run_cartridge__253_
        call maybe_app_worddrawings_init__5E55_
        jp   main_system_loop__15C_

    .check_app_run_cartridge__253_:
        cp   MAIN_MENU_APP_RUN_CARTRIDGE
        jp   nz, main_system_loop__15C_
        call maybe_try_run_cart_from_slot__5E1_
        jp   main_system_loop__15C_


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
;   ... 040D
;         
;     - ei
;     - jp C940 Likely: switch_bank_return_to_saved_bank_RAM__C940_
call_printscreen_in_32k_bank_2__522_:
    di
    ld   hl, $0030  ; RST 30
    res  7, h
    ld   a, $02  ; Bank 2
    call switch_bank_in_a_jump_hl_RAM__C920_
    ei
    ret


; TODO: Called right before a couple apps are launched
main_menu_maybe_save_something__52F_:
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


; TODO: Called after a launch app has returned
main_menu_maybe_restore_something__54B_:
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
    call memcopy_in_RAM__C900_

    ld   a, $A0
    ldh  [rWY], a
    call _LABEL_488F_
    ; Select an App Description string to display
    ; from the string table based on the
    ; Selected App Number
    ld   hl, _string_table_630_
    ld   a, [ui_grid_menu_selected_icon__RAM_D06E_]
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
        ld   hl, $2000  ; Delay 57,346 T-States (a little less than one frame [70,224])
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
    IF (DEF(GB_DEBUG))
        call wait_until_vbl__92C_
    ENDC
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
        IF (!(DEF(GB_DEBUG)))
        call _oam_dma_routine_in_ROM__7E3_
        ENDC

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
        ; memcopy_in_RAM__C900_
        ld   de, _memcopy__7D3_
        call _memcpy_32_bytes__7CA_

        ; HL now at 0x9C20
        ; (switch_bank_in_a_jump_hl_RAM__C920_)
        ld   de, switch_bank_in_a_jump_hl_ROM__82C_
        call _memcpy_32_bytes__7CA_

        ; HL now at 0x9C40
        ; (switch_bank_return_to_saved_bank_RAM__C940_)
        ld   de, switch_bank_return_to_saved_ROM__841_
        call _memcpy_32_bytes__7CA_

        ; HL now at 0x9C60
        ; (switch_bank_memcopy_hl_to_de_len_bc_RAM__C960_)
        ld   de, switch_bank_memcopy_hl_to_de_len_bc_ROM__7EF_
        call _memcpy_32_bytes__7CA_

        ; HL now at 0x9C80
        ld   de, switch_bank_read_byte_at_hl_ROM__80C_
        call _memcpy_32_bytes__7CA_

        ; Load OAM DMA Copy routine into HRAM
        ld   hl, _oam_dma_routine_in_HRAM__FF80_
        ld   de, _oam_dma_routine_in_ROM__7E3_ ; $07E3
        call _memcpy_32_bytes__7CA_
        IF (DEF(GB_DEBUG))
            call _oam_dma_routine_in_HRAM__FF80_
        ENDC

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
; Gets copied to and run from memcopy_in_RAM__C900_
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



; Delay loop to wait ~1 msec (used by serial link function, maybe others)
;
; Delay approx: (1000 msec / 59.7275 GB FPS) * (4256 T-States delay / 70224 T-States per frame) = 1.015 msec
; or (4256 T-States delay / 456 T-States per line) = ~9.3 lines
;
; Serial clock speed used is: 8192 Hz  1 KB/s  Bit 1 cleared, Normal speed

delay_1_msec__BD6_:
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


; TODO: Maybe data by Piano Apps
; Could be note tables, pre-recorded songs, etc
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

; Actually in 32K Bank 0 Upper 16K, but 32K banking not supported in RGBDS
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


; 45 Tiles of Piano sub-menu (3x3 tile) icon tiles
; Loaded to _TILEDATA9000 from piano_app_icon_menu_init__711A_
tile_data_0x40ba_720_bytes_paino_app_menu_icons__40BA_:
INCBIN "res/tile_data_0x40ba_720_bytes_paino_app_menu_icons.2bpp"


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

; TODO: Probably render some text at DE to X,Y (H,L) to ...
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



; Sets up Tilemap for menu with up to 4 x 3 grid of 3x3 tile icons
; Then runs the user menu item selection
;
; Number of icons to draw in:      ui_grid_menu_icon_count__RAM_D06D_
; Returns selected icon number in: ui_grid_menu_selected_icon__RAM_D06E_
;
; Icon Tile Data should be pre-loaded at _TILEDATA9000
;
; - Used by Main Menu, Piano App, probably games app, etc
;
ui_icon_menu_draw_and_run__4A7B_::

    ; First set up the Main Menu screen
    call display_clear_screen_with_space_char__4875_
    xor  a
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    ld   a, MAIN_MENU_ICON_FIRST_Y  ; $03
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    ld   c, $00  ; Counter for number of Tilemap Icons to set up

    ; Sets up a Tilemap with 4 wide x 3 tall grid of 3x3 Tile icons
    ; with Icon Tile IDs incrementing from Left -> Right, Top -> Bottom
    ; 9 Tile IDs per icon, 108 tiles total
    icons_start_of_row__4A89_:
        ; Start at TileMap 1,3 (A, C)
        ld   a, MAIN_MENU_ICON_FIRST_X  ; $01
        ld   [_tilemap_pos_x__RAM_C8CB_], a

        .icons_make_row__4A8E_:
            ld   d, $03  ; ?
            push bc
            push de

            ; Calc Tile Row address in TileMap0, result in HL
            ld  hl, _TILEMAP0; $9800
            ld   a, [_tilemap_pos_y__RAM_C8CA_]
            dec  a
            ld   b, _TILEMAP_WIDTH ; $20 (32)
            call multiply_a_x_b__result_in_de__4853_
            add  hl, de

            ; Then add Column offset, result still in HL
            ld   a, [_tilemap_pos_x__RAM_C8CB_]
            ld   e, a
            ld   d, $00
            add  hl, de

            ld   c, MAIN_MENU_ICON_HEIGHT  ; $03
            call wait_until_vbl__92C_

            ; Write a 3 x 3 tile icon to the Tilemap of incrementing Tile IDs
            ; Loop through all 3 Rows (so 9 Tilemap entries total)
            .per_icon_all_rows_loop__4AAB_:
                ld   a, [maybe_vram_data_to_write__RAM_C8CC_]
                ld   b, MAIN_MENU_ICON_WIDTH  ; $03

                ; write current row of incrementing Tile IDs
                .per_icon_current_row_loop__4AB0_:
                    ld   [hl], a
                    inc  a
                    inc  hl
                    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
                    dec  b
                    jr   nz, .per_icon_current_row_loop__4AB0_

                ;  Go to next Icon Row Start on Tilemap (tilemap_x += 29)
                ; (1 Row @ 32 tiles - Icon is 3 tiles wide wide) = 29
                xor  d
                ld   e, (_TILEMAP_WIDTH - MAIN_MENU_ICON_WIDTH) ; $1D (29)
                add  hl, de
                dec  c
                jr   nz, .per_icon_all_rows_loop__4AAB_

            ; Increment starting X position in main 4x3 icon grid by 5
            pop  de
            pop  bc
            ld   a, [_tilemap_pos_x__RAM_C8CB_]
            add  (MAIN_MENU_ICON_WIDTH + MAIN_MENU_ICON_SPACE_X)  ; $05
            ld   [_tilemap_pos_x__RAM_C8CB_], a

            ; Update counter for number of Tilemap Icons to set up
            ; Once it reaches 12 then it's finished
            inc  c
            ld   a, [ui_grid_menu_icon_count__RAM_D06D_]  ; Set to 0x0C by caller
            cp   c
            jr   z, .mainmenu_finish_setup__4AE6_

            ; Wrap down to a new row of icons once total icon count reaches 4 or 8
            ld   a, c
            cp   (MAIN_MENU_GRID_WIDTH * 1)  ; $04
            jr   z, .icons_reset_to_new_row__4ADC_
            cp   (MAIN_MENU_GRID_WIDTH * 2)  ; $08
            jr   z, .icons_reset_to_new_row__4ADC_
            jr   .icons_make_row__4A8E_

    .icons_reset_to_new_row__4ADC_:
        ; Start a new row of icons 5 tiles down
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        add  (MAIN_MENU_ICON_HEIGHT + MAIN_MENU_ICON_SPACE_Y)  ; $05
        ld   [_tilemap_pos_y__RAM_C8CA_], a
        jr   icons_start_of_row__4A89_

    ; TODO: maybe initializing the main menu
    .mainmenu_finish_setup__4AE6_:
        ld   a, $28
        ld   [_tilemap_pos_y__RAM_C8CA_], a
        ld   a, $09
        ld   [_tilemap_pos_x__RAM_C8CB_], a
        call _LABEL_4CD1_

        ; Make sure Display, BG and Sprites are on
        ldh  a, [rLCDC]
        and  (LCDCF_ON | LCDCF_BGON | LCDCF_WIN9C00 | LCDCF_BG9C00 | LCDCF_OBJ16 | LCDCF_OBJON)  ; $CF
        or   (LCDCF_ON | LCDCF_BGON |                                              LCDCF_OBJON)  ; $C1
        ldh  [rLCDC], a

        xor  a
        ld   [ui_grid_menu_selected_icon__RAM_D06E_], a    ; TODO: maybe main menu action index
        ld   [_RAM_D05D_], a    ; _RAM_D05D_ = $D05D
        ld   [_RAM_D05E_], a    ; _RAM_D05E_ = $D05E
        ld   [_RAM_D05C_], a    ; _RAM_D05C_ = $D05C
        ld   [_RAM_D05B_], a    ; _RAM_D05B_ = $D05B
        call maybe_input_wait_for_keys__4B84

    ; TODO: track down all calls to this and see if scope can be reduced
    ui_grid_menu_input_loop__4B0E_:
        call timer_wait_tick_AND_TODO__289_
        call input_read_keys__C8D_
        ld   hl, ui_grid_menu_icon_count__RAM_D06D_
        ld   a, [input_key_pressed__RAM_D025_]

        cp   SYS_CHAR_ENTRA_CR  ; $2E
        jp   z, ui_grid_menu_keypressed_enter__4C83_

        cp   SYS_CHAR_SALIDA  ; $2A
        jp   z, ui_grid_menu_keypressed_escape__4C76_

        cp   SYS_CHAR_PRINTSCREEN  ; $2F
        jp   z, ui_grid_menu_keypressed_printscreen__4C70_

        sub  $30  ; TODO: possibly SYS_CHAR_FUNCTION_KEYS_START
        jr   c, _LABEL_4B36_
        cp   [hl]
        jr   nc, _LABEL_4B36_
        ld   [ui_grid_menu_selected_icon__RAM_D06E_], a
        jp   ui_grid_menu_keypressed_enter__4C83_

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
        jr   ui_grid_menu_input_loop__4B0E_

    _LABEL_4B4F_:
        bit  2, a
        jp   nz, ui_grid_menu_keypressed_enter__4C83_
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
        jp   ui_grid_menu_input_loop__4B0E_


    _LABEL_4B78_:
        call timer_wait_tick_AND_TODO__289_
        call timer_wait_tick_AND_TODO__289_
        call timer_wait_tick_AND_TODO__289_
        jp   ui_grid_menu_input_loop__4B0E_


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
    ld   a, [ui_grid_menu_selected_icon__RAM_D06E_]
    inc  a
    ld   hl, ui_grid_menu_icon_count__RAM_D06D_
    cp   [hl]
    jp   nc, ui_grid_menu_input_loop__4B0E_
    push af
    ld   [ui_grid_menu_selected_icon__RAM_D06E_], a
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
    ld   a, [ui_grid_menu_selected_icon__RAM_D06E_]
    dec  a
    cp   $FF
    jp   z, ui_grid_menu_input_loop__4B0E_
    push af
    ld   [ui_grid_menu_selected_icon__RAM_D06E_], a
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
    ld   a, [ui_grid_menu_selected_icon__RAM_D06E_]
    add  $04
    ld   hl, ui_grid_menu_icon_count__RAM_D06D_
    cp   [hl]
    jp   nc, ui_grid_menu_input_loop__4B0E_
    ld   [ui_grid_menu_selected_icon__RAM_D06E_], a
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
    ld   a, [ui_grid_menu_selected_icon__RAM_D06E_]
    sub  $04
    jp   c, ui_grid_menu_input_loop__4B0E_
    ld   [ui_grid_menu_selected_icon__RAM_D06E_], a
    ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call _LABEL_953_
    call _LABEL_4D19_
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    sub  $28
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    call _LABEL_4CD1_
    jp   _LABEL_4B78_

ui_grid_menu_keypressed_printscreen__4C70_:
    call call_printscreen_in_32k_bank_2__522_
    jp   ui_grid_menu_input_loop__4B0E_

ui_grid_menu_keypressed_escape__4C76_:
    ld   a, [ui_grid_menu_escape_key_runs_last_icon__RAM_D06C_]
    and  a
    ; If a == MENU_ESCAPE_KEY_RUNS_LAST_ICON_FALSE
    ; then ignore escape key and continue poling for input
    jp   z, ui_grid_menu_input_loop__4B0E_
    ; If a == MENU_ESCAPE_KEY_RUNS_LAST_ICON_TRUE
    ; Then load last icon as icon pressed and fall through to Enter key processing
    ld   a, [ui_grid_menu_icon_count__RAM_D06D_]
    ld   [ui_grid_menu_selected_icon__RAM_D06E_], a
ui_grid_menu_keypressed_enter__4C83_:
    call _LABEL_4D19_
    ret

_LABEL_4C87_:
    bit  4, a
    jr   z, ._LABEL_4C93_
    ld   a, [_RAM_D05E_]    ; _RAM_D05E_ = $D05E
    inc  a
    res  7, a
    jr   ._LABEL_4C94_

    ._LABEL_4C93_:
        xor  a
    ._LABEL_4C94_:
        ld   [_RAM_D05E_], a    ; _RAM_D05E_ = $D05E
        ld   a, [buttons_new_pressed__RAM_D006_]
        bit  5, a
        jr   z, ._LABEL_4CA6_
        ld   a, [_RAM_D05D_]    ; _RAM_D05D_ = $D05D
        inc  a
        res  7, a
        jr   ._LABEL_4CA7_

    ._LABEL_4CA6_:
        xor  a
    ._LABEL_4CA7_:
        ld   [_RAM_D05D_], a    ; _RAM_D05D_ = $D05D
        ld   a, [buttons_new_pressed__RAM_D006_]
        bit  6, a
        jr   z, ._LABEL_4CB9_
        ld   a, [_RAM_D05C_]    ; _RAM_D05C_ = $D05C
        inc  a
        res  7, a
        jr   ._LABEL_4CBA_

    ._LABEL_4CB9_:
        xor  a
    ._LABEL_4CBA_:
        ld   [_RAM_D05C_], a    ; _RAM_D05C_ = $D05C
        ld   a, [buttons_new_pressed__RAM_D006_]
        bit  7, a
        jr   z, ._LABEL_4CCC_
        ld   a, [_RAM_D05B_]    ; _RAM_D05B_ = $D05B
        inc  a
        res  7, a
        jr   ._LABEL_4CCD_

    ._LABEL_4CCC_:
        xor  a
    ._LABEL_4CCD_:
        ld   [_RAM_D05B_], a    ; _RAM_D05B_ = $D05B
        ret

_LABEL_4CD1_:
    ld   a, $ED
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    xor  a
    ld   [_RAM_C8CD_], a    ; _RAM_C8CD_ = $C8CD
    ld   hl, _RAM_D05F_ ; _RAM_D05F_ = $D05F
    ld   b, $02

    ._LABEL_4CDF_:
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
        jr   nz, ._LABEL_4CDF_
    ret


; TODO: is this hiding the OAM/sprite cursor before executing a main menu item?
_LABEL_4D19_:
    ld   c, $04
    ld   hl, _RAM_D05F_ ; _RAM_D05F_ = $D05F

    ._LABEL_4D1E_:
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
        jr   nz, ._LABEL_4D1E_
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


; Actually in 32K Bank 0 Upper 16K, but 32K banking not supported in RGBDS
SECTION "rom0_app_calendar_4D6F", ROMX[$4D6F], BANK[$1]
include "app_calendar.asm"
; Ends 549E


SECTION "rom0_after_app_calendar_549D", ROMX[$549D], BANK[$1]
; Writes preset byte to vram HL, then writes (preset byte + 1) at the next row down
;
; - VRAM Address to write: HL
;
; Destroys A, DE
maybe__vram_write_byte_2rows_addr_in_hl_preset_data__549D_::
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


; Actually in 32K Bank 0 Upper 16K, but 32K banking not supported in RGBDS
SECTION "rom0_app_clock_54AE", ROMX[$54AE], BANK[$1]
include "app_clock_and_rtc_support.asm"
; Ends 5DA5


SECTION "rom0_rtc_date_calc_LUTs_5DA6", ROMX[$5DA6], BANK[$1]
; Look up Tables used for RTC Date Calculations
;
; - rtc_validate_shadow_data_and_time__5A2B_
;   - called via: rtc_set_to_new_date_and_time___5987_
;
include "inc/rtc_date_calc_LUTs.inc"


; Anchroing here in cases where the LUT above gets relocated when expanded
SECTION "rom0_date_time_strings_5DD2", ROMX[$5DD2], BANK[$1]
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
rom_str___ESCAPE_SALIDA__5E08_:
db $BE, $BE, $BE, $85, $93, $83, $81, $90, $85, $BE, $93, $81, $8C, $89, $84, $81
db $00

; Data from 5E19 to 5E30 (24 bytes)
; 8 x 3 Look Up Table for 3 Letter Day of Week abbreviations (2 entries for Monday)
string_table_day_of_week_3_letter_abbrev__5E19_:
; Text string (commas not in data)  "LUN,MAR,MIÉ,JUE,VIE,SÃB,DOM,LUN"
;                                   (Mon,Tue,Wed,Thu,Fri,Sat,Sun,Mon)
db $8C, $95, $8E
db $8D, $81, $92
db $8D, $89, $D7
db $8A, $95, $85
db $96, $89, $85
db $93, $D6, $82
db $84, $8F, $8D
db $8C, $95, $8E

; Data from 5E31 to 5E54 (36 bytes)
; 12 x 3 Look Up Table for 3 Letter Month abbreviations
string_table_month_3_letter_abbrev__5E31_:
; Text string (commas not in data) "ENE,FEB,MAR,ABR,MAY,JUN,JUL,AGO,SEP,OCT,NOV,DIC"
;                                  (Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)
db $85, $8E, $85
db $86, $85, $82
db $8D, $81, $92
db $81, $82, $92
db $8D, $81, $99
db $8A, $95, $8E
db $8A, $95, $8C
db $81, $87, $8F
db $93, $85, $90
db $8F, $83, $94
db $8E, $8F, $96
db $84, $89, $83



; Actually in 32K Bank 0 Upper 16K, but 32K banking not supported in RGBDS
SECTION "rom0_app_worddrawings_5E55", ROMX[$5E55], BANK[$1]
include "app_worddrawings.asm"
; Ends at $711B



; Actually in 32K Bank 0 Upper 16K, but 32K banking not supported in RGBDS
SECTION "rom0_app_paint_6328", ROMX[$6328], BANK[$1]
include "app_paint.asm"
; Ends at $711B


; Actually in 32K Bank 0 Upper 16K, but 32K banking not supported in RGBDS
SECTION "rom0_apps_piano_711A", ROMX[$711A], BANK[$1]
include "apps_piano.asm"

; Piano app code and data runs to the end of 32K bank 0 (with ~1.5K bytes empty space)


