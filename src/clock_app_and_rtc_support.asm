

; Actually in 32K Bank 0 Upper 16K, but 32K banking not supported in RGBDS
; SECTION "rom0_clock_app_54AE", ROMX[$54AE], BANK[$1]

;
; EXPORT clock_app_init__54AE_
;
; These two are also used by the Calendar App:
; EXPORT rtc_calc_day_of_week_for_current_date__5A9F_
; EXPORT convert_bcd2dec_at_hl_result_in_a__5B03_


clock_app_init__54AE_::
    ld   a, [_RAM_D059_]
    and  $F0
    cp   $C0
    jr   z, ._LABEL_54BC_
    ld   a, $C0
    ld   [_RAM_D059_], a
    ._LABEL_54BC_:
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
    .loop__54F9_:
        xor  a
        ldi  [hl], a
        ld   a, h
        cp   $9C
        jr   nz, .loop__54F9_

        ld   a, SYS_CMD_RTC_GET_DATE_AND_TIME  ; $0C
        ld   [serial_rx_cmd_to_send__RAM_D036_], a

    .receive_loop_wait_valid_reply__5505_:
        call serial_io_send_command_and_receive_buffer__AEF_
        call timer_wait_tick_AND_TODO__289_
        ld   a, [input_key_pressed__RAM_D025_]
        cp   SYS_CHAR_SERIAL_RX_SUCCESS  ; $F9
        jr   nz, .receive_loop_wait_valid_reply__5505_

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

    .loop__5532_:
        ldi  [hl], a
        dec  b
        jr   nz, .loop__5532_

        call memcopy_8_bytes_from_serial_rx_RAM_D028_to_shadow_rtc_RAM_D051__5D50_
        call _LABEL_5B5F_
        call _LABEL_55A0_
        xor  a
        ld   [_RAM_D068_], a
        ld   [_RAM_D03B_], a
        ld   [_RAM_D1A7_], a    ; _RAM_D1A7_ = $D1A7

    ._LABEL_5549_:
        ld   a, [_RAM_D1A7_]    ; _RAM_D1A7_ = $D1A7
        inc  a
        ld   [_RAM_D1A7_], a    ; _RAM_D1A7_ = $D1A7
        cp   $04
        jr   nz, ._LABEL_557B_
        xor  a
        ld   [_RAM_D1A7_], a    ; _RAM_D1A7_ = $D1A7

        ; TODO: Maybe Read Hardware RTC and then ...
        ld   a, SYS_CMD_RTC_GET_DATE_AND_TIME  ; $0C
        ld   [serial_rx_cmd_to_send__RAM_D036_], a
        call serial_io_send_command_and_receive_buffer__AEF_
        ld   a, [input_key_pressed__RAM_D025_]
        cp   SYS_CHAR_SERIAL_RX_SUCCESS  ; $F9
        jr   nz, ._LABEL_5579_

        ; TODO: Maybe then compare Hardware RTC reply data with System Shadow RTC data
        call _LABEL_5D5F_
        ld   a, [_RAM_D03A_]
        and  a
        jr   z, ._LABEL_5579_
        call memcopy_8_bytes_from_serial_rx_RAM_D028_to_shadow_rtc_RAM_D051__5D50_
        call _LABEL_5B5F_
        call _LABEL_55A0_
    ._LABEL_5579_:
        jr   ._LABEL_5549_

    ._LABEL_557B_:
        call timer_wait_tick_AND_TODO__289_
        call input_read_keys__C8D_
        ld   a, [buttons_new_pressed__RAM_D006_]
        ld   [_RAM_D03B_], a
        call _LABEL_56CB_
        ld   a, [_RAM_D05A_]
        and  a
        jr   nz, ._LABEL_5599_
        ld   a, [_RAM_D06B_]
        and  a
        jp   nz, ._LABEL_54BC_
        jr   ._LABEL_5549_

    ._LABEL_5599_:
        ldh  a, [rLCDC]
        and  ~LCDCF_OBJ16  ; $FD  ; Turn off 8x16 sprites -> 8x8 sprites
        ldh  [rLCDC], a
        ret

_LABEL_55A0_:
    ld   a, [_RAM_D059_]
    and  $0F
    and  a
    jr   nz, ._LABEL_55CB_
    ld   hl, shadow_rtc_am_pm__RAM_D055_
    ldi  a, [hl]
    and  a
    ld   a, $90
    jr   nz, ._LABEL_55B3_
    ld   a, $81

    ._LABEL_55B3_:
        ld   [_RAM_D400_], a
        ld   a, $8D
        ld   [_RAM_D401_], a

    ._LABEL_55BB_:
        ld   a, $BE
        ld   [_RAM_D402_], a
        ld   de, shadow_rtc_hour__RAM_D056_
        ld   hl, _RAM_D403_
        call _LABEL_56BC_
        jr   ._LABEL_5600_

    ._LABEL_55CB_:
        ld   a, $BE
        ld   [_RAM_D400_], a
        ld   [_RAM_D401_], a
        ld   [_RAM_D402_], a
        ld   a, [shadow_rtc_am_pm__RAM_D055_]
        and  a
        jr   z, ._LABEL_55BB_
        ld   a, [shadow_rtc_hour__RAM_D056_]
        and  $F0
        ld   b, a
        ld   a, [shadow_rtc_hour__RAM_D056_]
        and  $0F
        add  $02
        cp   $0A
        jr   c, ._LABEL_55F1_
        sub  $0A
        add  $10

    ._LABEL_55F1_:
        add  $10
        add  b
        ld   [_RAM_D03A_], a
        ld   de, _RAM_D03A_
        ld   hl, _RAM_D403_
        call _LABEL_56BC_

    ._LABEL_5600_:
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
        jr   nz, ._LABEL_5697_
        ld   a, $C2
        ld   [_RAM_D40D_], a
        ld   a, $C0
        jr   ._LABEL_569E_

    ._LABEL_5697_:
        ld   a, $C1
        ld   [_RAM_D40D_], a
        ld   a, $C9
    ._LABEL_569E_:
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
    jr   z, ._LABEL_5740_
    cp   SYS_CHAR_UP  ; $3D
    jr   z, ._LABEL_5704_
    cp   SYS_CHAR_DOWN  ; $40
    jr   z, ._LABEL_571F_
    cp   SYS_CHAR_SALIDA  ; $2A
    jp   z, ._LABEL_576B_
    cp   SYS_CHAR_PRINTSCREEN  ; $2F
    jr   nz, ._LABEL_56EE_
    call maybe_call_printscreen_in_32k_bank_2__522_
    ret


    ; TODO: keycode / button constant labeling
    ._LABEL_56EE_:
        ld   a, [buttons_new_pressed__RAM_D006_]
        and  $C4
        ret  z
        ld   a, [buttons_new_pressed__RAM_D006_]
        bit  6, a
        jr   nz, ._LABEL_5704_

        bit  7, a
        jr   nz, ._LABEL_571F_

        bit  2, a
        jr   nz, ._LABEL_5740_
        ret

    ._LABEL_5704_:
        ld   hl, _RAM_D068_
        ld   a, [_RAM_D20C_]
        cp   $06
        jr   nz, ._LABEL_5712_
        ld   [hl], $00
        jr   ._LABEL_571C_

    ._LABEL_5712_:
        cp   $09
        jr   nz, ._LABEL_571A_
        ld   [hl], $01
        jr   ._LABEL_571C_

    ._LABEL_571A_:
        ld   [hl], $02

    ._LABEL_571C_:
        jp   ._LABEL_5737_

    ._LABEL_571F_:
        ld   hl, _RAM_D068_
        ld   a, [_RAM_D20C_]
        cp   $06
        jr   nz, ._LABEL_572D_
        ld   [hl], $02
        jr   ._LABEL_5737_

    ._LABEL_572D_:
        cp   $03
        jr   z, ._LABEL_5735_
        ld   [hl], $00
        jr   ._LABEL_5737_

    ._LABEL_5735_:
        ld   [hl], $01

    ._LABEL_5737_:
        call _LABEL_5792_
        ld   a, $05
        call _LABEL_4A72_
        ret

    ._LABEL_5740_:
        ld   a, [_RAM_D068_]
        cp   $00
        jr   nz, ._LABEL_5763_
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

    ._LABEL_5763_:
        cp   $01
        jr   nz, ._LABEL_576B_
        call _LABEL_57D5_
        ret

    ._LABEL_576B_:
        call _LABEL_5774_
        ld   a, $01
        ld   [_RAM_D05A_], a
        ret


_LABEL_5774_:
    ld   hl, _RAM_D05F_ ; _RAM_D05F_ = $D05F
    ld   b, $02
    ld   c, $02

    ._LABEL_577B_:
        ldi  a, [hl]
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        push bc
        push hl
        call oam_free_slot_and_clear__89B_
        pop  hl
        pop  bc
        dec  b
        jr   nz, ._LABEL_577B_

        ld   hl, _RAM_D03B_ + 1 ; _RAM_D03B_ + 1 = $D03C
        ld   b, $0C
        dec  c
        jr   nz, ._LABEL_577B_

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

    ._LABEL_57C9_:
        ldi  [hl], a
        inc  a
        ldd  [hl], a
        inc  a
        ld   de, $0020
        add  hl, de
        dec  c
        jr   nz, ._LABEL_57C9_

    ret


; TODO: Maybe something about setting the time
; Could be the clock/calendar application
_LABEL_57D5_:
    xor  a  ; MENU_ESCAPE_KEY_RUNS_LAST_ICON_FALSE
    ld   [ui_grid_menu_escape_key_runs_last_icon__RAM_D06C_], a
    ldh  a, [rLCDC]
    and  ~LCDCF_OBJ16  ; $FD  ; Turn off 8x16 sprites -> 8x8 sprites
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
    jr   nz, ._LABEL_581C_
    xor  a
    ld   [shadow_rtc_hour__RAM_D056_], a

    ._LABEL_581C_:
        ld   de, shadow_rtc_am_pm__RAM_D055_
        ld   a, [de]
        inc  de
        and  a
        jr   z, ._LABEL_5841_
        ld   a, [de]
        and  $F0
        ld   b, a
        ld   a, [de]
        and  $0F
        add  $02
        cp   $0A
        jr   c, ._LABEL_5835_
        sub  $0A
        add  $10

    ._LABEL_5835_:
        add  $10
        add  b
        ld   [_RAM_D402_], a
        ld   [shadow_rtc_hour__RAM_D056_], a
        ld   de, _RAM_D402_

    ._LABEL_5841_:
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

    ._LABEL_58AD_:
        call input_map_gamepad_buttons_to_keycodes__49C2_
        call _LABEL_5919_
        ld   a, [_RAM_D06B_]
        and  a
        jr   z, ._LABEL_58C3_
        call ._LABEL_58DC_
        ldh  a, [rLCDC]
        or   $02
        ldh  [rLCDC], a
        ret

    ._LABEL_58C3_:
        ld   a, [_RAM_D03B_]
        inc  a
        ld   [_RAM_D03B_], a
        and  $07
        jr   nz, ._LABEL_58D3_
        call ._LABEL_58DC_
        jr   ._LABEL_58AD_

    ._LABEL_58D3_:
        cp   $04
        jr   nz, ._LABEL_58AD_
        call _LABEL_58EA_
        jr   ._LABEL_58AD_


._LABEL_58DC_:
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
    jr   nz, ._LABEL_593C_
    xor  a  ; MENU_ESCAPE_KEY_RUNS_LAST_ICON_FALSE
    ld   [ui_grid_menu_escape_key_runs_last_icon__RAM_D06C_], a
    ld   a, [_RAM_D03A_]
    inc  a
    cp   $05
    jr   nz, ._LABEL_5931_
    xor  a

    ._LABEL_5931_:
        ld   [_RAM_D03A_], a
        ld   a, $FF
        ld   [input_prev_key_pressed__RAM_D181_], a
        jp   _LABEL_59F1_

    ._LABEL_593C_:
        cp   SYS_CHAR_LEFT  ; $3E
        jr   nz, ._LABEL_5950_
        xor  a  ; MENU_ESCAPE_KEY_RUNS_LAST_ICON_FALSE
        ld   [ui_grid_menu_escape_key_runs_last_icon__RAM_D06C_], a
        ld   a, [_RAM_D03A_]
        dec  a
        cp   $FF
        jr   nz, ._LABEL_5931_
        ld   a, $04
        jr   ._LABEL_5931_

    ._LABEL_5950_:
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
        ld   a, [ui_grid_menu_escape_key_runs_last_icon__RAM_D06C_]
        cp   MENU_ESCAPE_KEY_RUNS_LAST_ICON_FALSE  ; $00
        jr   nz, ._LABEL_5975_
        ld   [hl], $00

    ._LABEL_5975_:
        ld   a, MENU_ESCAPE_KEY_RUNS_LAST_ICON_TRUE  ; $01
        ld   [ui_grid_menu_escape_key_runs_last_icon__RAM_D06C_], a
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
; - Used by both Clock and Calendar Apps
;
rtc_calc_day_of_week_for_current_date__5A9F_::

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
;
; - Used by both Clock and Calendar Apps
;
convert_bcd2dec_at_hl_result_in_a__5B03_::
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
    ld   [_RAM_D03A_], a  ; TODO not sure what this is for, maybe "copy new rtc data" = FALSE?
    ;     a == MENU_ESCAPE_KEY_RUNS_LAST_ICON_FALSE
    ld   [ui_grid_menu_escape_key_runs_last_icon__RAM_D06C_], a

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
    jr   z, ._LABEL_5B73_
    sub  $06
    cp   $0C
    jr   nz, ._LABEL_5B73_
    xor  a

    ._LABEL_5B73_:
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

    ._LABEL_5BCD_:
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
        jr   nz, ._LABEL_5BCD_
        ld   hl, _RAM_D04A_
        ld   a, [_RAM_D049_]
        cp   $0F
        jr   c, ._LABEL_5C2B_
        cp   $1E
        jr   c, ._LABEL_5C49_
        cp   $2D
        jr   c, ._LABEL_5C0D_
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
        jr   ._LABEL_5C61_

    ._LABEL_5C0D_:
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
        jr   ._LABEL_5C61_

    ._LABEL_5C2B_:
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
        jr   ._LABEL_5C61_

    ._LABEL_5C49_:
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
    ._LABEL_5C61_:
        ld   [_tilemap_pos_y__RAM_C8CA_], a
        ld   hl, _RAM_D037_
        ld   a, $00
        add  [hl]
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        add  $02
        ld   [_RAM_D037_], a
        ld   a, [_RAM_D04A_]
        bit  3, a
        jr   z, ._LABEL_5C7C_
        xor  a
        jr   ._LABEL_5C8E_

    ._LABEL_5C7C_:
        bit  2, a
        jr   z, ._LABEL_5C84_
        ld   a, $40
        jr   ._LABEL_5C8E_

    ._LABEL_5C84_:
        bit  1, a
        jr   z, ._LABEL_5C8C_
        ld   a, $60
        jr   ._LABEL_5C8E_

    ._LABEL_5C8C_:
        ld   a, $20
    ._LABEL_5C8E_:
        ld   [_RAM_C8CD_], a    ; _RAM_C8CD_ = $C8CD
        call _LABEL_623_
        call _LABEL_5D30_
        ld   a, b
        ldi  [hl], a
        ld   a, [_RAM_D04A_]
        and  $0C
        jr   nz, ._LABEL_5CA7_
        ld   a, [_tilemap_pos_x__RAM_C8CB_]
        sub  $08
        jr   ._LABEL_5CAC_

    ._LABEL_5CA7_:
        ld   a, [_tilemap_pos_x__RAM_C8CB_]
        add  $08
    ._LABEL_5CAC_:
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
        jr   z, .done__5D2F_
        ld   hl, _DATA_5D7F_
        ld   a, [_RAM_D03A_]
        call add_a_to_hl__486E_
        ld   b, [hl]
        ld   a, [_RAM_D04A_]
        and  $0C
        jr   nz, ._LABEL_5CD9_
        ld   a, [_tilemap_pos_x__RAM_C8CB_]
        add  b
        jr   ._LABEL_5CDD_

    ._LABEL_5CD9_:
        ld   a, [_tilemap_pos_x__RAM_C8CB_]
        sub  b
    ._LABEL_5CDD_:
        ld   [_tilemap_pos_x__RAM_C8CB_], a
        ld   a, $10
        call add_a_to_hl__486E_
        ld   b, [hl]
        ld   a, [_RAM_D04A_]
        and  $09
        jr   nz, ._LABEL_5CF3_
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        add  b
        jr   ._LABEL_5CF7_

    ._LABEL_5CF3_:
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        sub  b
    ._LABEL_5CF7_:
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
        jr   nz, ._LABEL_5D18_
        ld   a, [_tilemap_pos_x__RAM_C8CB_]
        add  $08
        jr   ._LABEL_5D1D_

    ._LABEL_5D18_:
        ld   a, [_tilemap_pos_x__RAM_C8CB_]
        sub  $08
    ._LABEL_5D1D_:
        ld   [_tilemap_pos_x__RAM_C8CB_], a
        ld   a, [_RAM_D037_]
        sub  $02
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        push hl
        call _LABEL_623_
        pop  hl
        ld   a, b
        ldi  [hl], a

    .done__5D2F_:
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
