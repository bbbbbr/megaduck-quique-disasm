
; Actually in 32K Bank 0 Upper 16K, but 32K banking not supported in RGBDS
; SECTION "rom0_calendar_app_4D6F", ROMX[$4D6F], BANK[$1]



calendar_app_init__4D6F_::
    ld   a, [_RAM_DBFB_]    ; _RAM_DBFB_ = $DBFB
    bit  2, a
    jr   nz, ._LABEL_4D7F_
    set  2, a
    ld   [_RAM_DBFB_], a    ; _RAM_DBFB_ = $DBFB
    xor  a
    ld   [_RAM_DBFF_], a    ; _RAM_DBFF_ = $DBFF

    ._LABEL_4D7F_:
        xor  a
        ld   [_RAM_D05D_], a    ; _RAM_D05D_ = $D05D
        ld   [_RAM_D05E_], a    ; _RAM_D05E_ = $D05E
        ld   [_RAM_D05C_], a    ; _RAM_D05C_ = $D05C
        ld   [_RAM_D05B_], a    ; _RAM_D05B_ = $D05B
        ld   [_RAM_D03B_], a
        ld   a, SYS_CMD_RTC_GET_DATE_AND_TIME  ; $0C
        ld   [serial_rx_cmd_to_send__RAM_D036_], a

        ; Received data will be in buffer__RAM_D028_
        .receive_loop_wait_valid_reply_4D94_:
            call serial_io_send_command_and_receive_buffer__AEF_
            ld   a, [input_key_pressed__RAM_D025_]
            cp   SYS_CHAR_SERIAL_RX_SUCCESS  ; $F9
            jr   nz, .receive_loop_wait_valid_reply_4D94_

        ; Load Tile Data for the main menu font
        call wait_until_vbl__92C_
        call display_screen_off__94C_
        ld   hl, _TILEDATA8800                         ; Dest
        ld   de, gfx_tile_data__main_menu_font__2F2A_   ; Source
        ld   bc, (MENU_FONT_128_TILES * TILE_SZ_BYTES) ; Copy size: 128 tiles (2048 bytes)
        call memcopy_in_RAM__C900_

        ; GFX Loading 128 Tiles (only 115 intended though?) of 8x16 font
        ;
        ; Note: This accidentally(?) copies more tiles than are in the the tile
        ;       set blob so it picks up the first 13 tiles of the  following 8x8 font (at 0x2FA).
        call wait_until_vbl__92C_
        call display_screen_off__94C_
        ld   hl, _TILEDATA9000                                ; Dest
        ld   de, tile_data_0x27fa_1840_bytes_8x16_font__27FA_ ; Source
        ld   bc, (128 * TILE_SZ_BYTES)                        ; Copy size: 128 tiles (2048 bytes)
        call memcopy_in_RAM__C900_

        ; Copy first 3 bytes (Year, Month, Day) of received RTC data
        ; from Serial IO RX buffer to _RAM_D075_ ...
        ld   hl, buffer__RAM_D028_
        ld   de, _RAM_D074_ + 1
        ld   b, $03
        call memcopy_b_bytes_from_hl_to_de__482B_

    ._LABEL_4DCD_:
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

        .tile_row_loop__4DE9_:
            ldi  [hl], a
            dec  b
            jr   nz, .tile_row_loop__4DE9_

            ; Advance to next Tilemap Row and reset column counter
            ld   de, (_TILEMAP_WIDTH - $10)  ; $0010
            add  hl, de
            ld   b, $10
            dec  c
            jr   nz, .tile_row_loop__4DE9_

        ; Load RX RTC Month
        ; Do a simple conversion from BCD -> Decimal
        ; If left digit is 1 then subtract 6 to convert. Ex. 0x10 - 6 = 0xA (10)
        ld   a, [buffer__RAM_D028_ + 1]  ; Should be RTC Month from last Serial IO RX data buffer
        bit  4, a
        jr   z, .rtc_month_less_than_10__4DFF_
        sub  $06

    .rtc_month_less_than_10__4DFF_:
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

        ._LABEL_4E10_:
            ld   a, [de]
            inc  de
            sub  $81
            sla  a
            add  $1A
            ld   c, $00
            ld   [maybe_vram_data_to_write__RAM_C8CC_], a
            push de
            call maybe__vram_write_byte_2rows_addr_in_hl_preset_data__549D_
            pop  de
            inc  hl
            dec  b
            jr   nz, ._LABEL_4E10_

        ld   hl, _TILEMAP0 + $30 ; $9830

        ; Load RX RTC Year
        ; Do a simple conversion from BCD -> Decimal
        ; If left digit is 1 then subtract 6 to convert. Ex. 0x10 - 6 = 0xA (10)
        ld   a, [buffer__RAM_D028_]  ; Should be RTC Year from last Serial IO RX data buffer
        ; Check if left digit is in "9" (i.e. 1990-1999) year range
        and  $F0
        cp   $90
        jr   nz, .maybe_year_is_1990_1999__4E3E_

        ; ? Otherwise year is assumed to be in 2000+ range
        ld   a, $02
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        call maybe__vram_write_byte_2rows_addr_in_hl_preset_data__549D_
        ld   a, $12
        jr   ._LABEL_4E48_

    .maybe_year_is_1990_1999__4E3E_:
        ld   a, $04
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        call maybe__vram_write_byte_2rows_addr_in_hl_preset_data__549D_
        ld   a, $00

    ._LABEL_4E48_:
        inc  hl
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        call maybe__vram_write_byte_2rows_addr_in_hl_preset_data__549D_
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
    ._LABEL_4E69_:
        ld   a, [de]
        inc  de
        ldi  [hl], a
        ld   a, [de]
        inc  de
        inc  de
        ldi  [hl], a
        inc  hl
        dec  b
        jr   nz, ._LABEL_4E69_

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
        ld   [ui_grid_menu_icon_count__RAM_D06D_], a

        ld   e, a
        ld   d, $00
        ld   h, $0A
        call divide_de_by_h_result_in_bc_remainder_in_l__4832_
        ld   a, c
        swap a
        or   l
        ld   [_RAM_D03A_], a
        xor  a
        ld   [ui_grid_menu_selected_icon__RAM_D06E_], a
        ld   a, $07
        ld   [_tilemap_pos_y__RAM_C8CA_], a

    ._LABEL_4EAB_:
        ld   a, [shadow_rtc_dayofweek__RAM_D054_]
        ld   b, $03
        call multiply_a_x_b__result_in_de__4853_
        ld   a, e
        sub  $02
        ld   [_tilemap_pos_x__RAM_C8CB_], a
        ld   a, [_RAM_D03B_]
        and  a
        jr   nz, ._LABEL_4ED4_

        ld   a, [shadow_rtc_day__RAM_D053_]    ; shadow_rtc_day__RAM_D053_ = $D053
        ld   hl, _RAM_D074_ + 3
        cp   [hl]
        jr   nz, ._LABEL_4ED4_

        ld   a, [_tilemap_pos_x__RAM_C8CB_]
        ld   [_RAM_D073_], a    ; _RAM_D073_ = $D073
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        ld   [_RAM_D074_], a

    ._LABEL_4ED4_:
        ld   a, [shadow_rtc_day__RAM_D053_]    ; shadow_rtc_day__RAM_D053_ = $D053
        cp   $01
        jr   nz, ._LABEL_4F29_
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        ld   [ui_grid_menu_selected_icon__RAM_D06E_ + 2], a    ; ui_grid_menu_selected_icon__RAM_D06E_ + 2 = $D070
        add  $02
        sla  a
        sla  a
        sla  a
        ld   [_tilemap_pos_y__RAM_C8CA_], a
        ld   a, [_tilemap_pos_x__RAM_C8CB_]
        ld   [ui_grid_menu_selected_icon__RAM_D06E_ + 1], a    ; ui_grid_menu_selected_icon__RAM_D06E_ + 1 = $D06F
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
        ld   a, [ui_grid_menu_selected_icon__RAM_D06E_ + 2]    ; ui_grid_menu_selected_icon__RAM_D06E_ + 2 = $D070
        ld   [_tilemap_pos_y__RAM_C8CA_], a
        ld   a, b
        ld   [ui_grid_menu_selected_icon__RAM_D06E_ + 2], a    ; ui_grid_menu_selected_icon__RAM_D06E_ + 2 = $D070
        ld   a, [_tilemap_pos_x__RAM_C8CB_]
        ld   b, a
        ld   a, [ui_grid_menu_selected_icon__RAM_D06E_ + 1]    ; ui_grid_menu_selected_icon__RAM_D06E_ + 1 = $D06F
        ld   [_tilemap_pos_x__RAM_C8CB_], a
        ld   a, b
        ld   [ui_grid_menu_selected_icon__RAM_D06E_ + 1], a    ; ui_grid_menu_selected_icon__RAM_D06E_ + 1 = $D06F

    ._LABEL_4F29_:
        call _LABEL_532F_
        cp   $00
        jr   nz, ._LABEL_4F3A_
        ld   hl, shadow_rtc_day__RAM_D053_ ; shadow_rtc_day__RAM_D053_ = $D053
        ld   c, $02
        call _LABEL_5401_
        jr   ._LABEL_4F3D_

    ._LABEL_4F3A_:
        call _LABEL_52F5_

    ._LABEL_4F3D_:
        ld   a, [shadow_rtc_day__RAM_D053_]    ; shadow_rtc_day__RAM_D053_ = $D053
        and  $0F
        inc  a
        cp   $0A
        ld   a, [shadow_rtc_day__RAM_D053_]    ; shadow_rtc_day__RAM_D053_ = $D053
        jr   z, ._LABEL_4F4D_
        inc  a
        jr   ._LABEL_4F51_

    ._LABEL_4F4D_:
        and  $F0
        add  $10
    ._LABEL_4F51_:
        ld   [shadow_rtc_day__RAM_D053_], a    ; shadow_rtc_day__RAM_D053_ = $D053
        ld   b, a
        ld   a, [_RAM_D03A_]
        cp   b
        jr   c, ._LABEL_4F72_
        ld   a, [shadow_rtc_dayofweek__RAM_D054_]    ; shadow_rtc_dayofweek__RAM_D054_ = $D054
        inc  a
        cp   $07
        jr   nz, ._LABEL_4F6C_
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        add  $02
        ld   [_tilemap_pos_y__RAM_C8CA_], a
        xor  a

    ._LABEL_4F6C_:
        ld   [shadow_rtc_dayofweek__RAM_D054_], a    ; shadow_rtc_dayofweek__RAM_D054_ = $D054
        jp   ._LABEL_4EAB_

    ._LABEL_4F72_:
        ld   a, [_tilemap_pos_x__RAM_C8CB_]
        inc  a
        sla  a
        sla  a
        sla  a
        ld   [ui_grid_menu_selected_icon__RAM_D06E_ + 3], a    ; ui_grid_menu_selected_icon__RAM_D06E_ + 3 = $D071
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        add  $02
        sla  a
        sla  a
        sla  a
        ld   [_RAM_D072_], a
        ld   a, $01
        ld   [_RAM_D03A_], a
        call _display_bg_sprites_on__627_

    .maybe_calendar_app_main_input_loop__4F95_:
        call timer_wait_tick_AND_TODO__289_
        call input_read_keys__C8D_
        ld   a, [_RAM_D074_ + 1]
        ld   hl, buffer__RAM_D028_
        cp   [hl]
        jr   nz, ._LABEL_4FAE_
        ld   a, [_RAM_D074_ + 2]
        inc  hl
        cp   [hl]
        jr   nz, ._LABEL_4FAE_
        call _LABEL_538C_

    ._LABEL_4FAE_:
        ld   a, [input_key_pressed__RAM_D025_]
        cp   SYS_CHAR_PRINTSCREEN  ; $2F
        jp   nz, ._LABEL_4FEE_
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
        call ._LABEL_52BF_
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
        jr   .maybe_calendar_app_main_input_loop__4F95_

    ._LABEL_4FEE_:
        ; Alias SYS_CHAR_GPAD_SELECT
        cp   SYS_CHAR_ENTRA_CR  ; $2E
        jp   z, ._LABEL_51B0_

        ; Alias SYS_CHAR_GPAD_START
        cp   SYS_CHAR_SALIDA  ; $2A
        jp   z, ._LABEL_52B5_

        ; Alias SYS_CHAR_GPAD_A
        cp   SYS_CHAR_PG_ARRIBA  ; $44
        jp   z, ._LABEL_522B_

        ; Alias SYS_CHAR_GPAD_B
        cp   SYS_CHAR_PG_ABAJO  ; $45
        jp   z, ._LABEL_526F_

        call input_map_keycodes_to_gamepad_buttons__4D30_
        ld   a, [buttons_new_pressed__RAM_D006_]
        and  $F7
        jr   nz, ._LABEL_5022_
        xor  a
        ld   [_RAM_D05D_], a    ; _RAM_D05D_ = $D05D
        ld   [_RAM_D05E_], a    ; _RAM_D05E_ = $D05E
        ld   [_RAM_D05B_], a    ; _RAM_D05B_ = $D05B
        ld   [_RAM_D05C_], a    ; _RAM_D05C_ = $D05C
        call delay_quarter_msec__BD6_
        call delay_quarter_msec__BD6_
        jp   .maybe_calendar_app_main_input_loop__4F95_

    ._LABEL_5022_:
        ld   a, [buttons_new_pressed__RAM_D006_]
        bit  PADB_SELECT, a  ; 2, a
        jp   nz, ._LABEL_51B0_
        bit  PADB_A, a  ; 0, a
        jp   nz, ._LABEL_522B_
        bit  PADB_B, a  ; 1, a
        jp   nz, ._LABEL_526F_

        call _LABEL_4C87_
        ld   a, [_RAM_D05E_]    ; _RAM_D05E_ = $D05E
        cp   $01
        jr   z, ._LABEL_5059_
        ld   a, [_RAM_D05D_]    ; _RAM_D05D_ = $D05D
        cp   $01
        jp   z, ._LABEL_50C3_
        ld   a, [_RAM_D05C_]    ; _RAM_D05C_ = $D05C
        cp   $01
        jp   z, ._LABEL_5167_
        ld   a, [_RAM_D05B_]    ; _RAM_D05B_ = $D05B
        cp   $01
        jp   z, ._LABEL_511F_
        jp   .maybe_calendar_app_main_input_loop__4F95_

    ._LABEL_5059_:
        xor  a
        ld   [_RAM_D05E_], a    ; _RAM_D05E_ = $D05E
        ld   a, [ui_grid_menu_selected_icon__RAM_D06E_]
        inc  a
        ld   hl, ui_grid_menu_icon_count__RAM_D06D_
        cp   [hl]
        jr   nc, ._LABEL_5096_
        ld   [ui_grid_menu_selected_icon__RAM_D06E_], a
        ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        call _LABEL_953_
        call oam_free_slot_and_clear__89B_
        ld   a, [_tilemap_pos_x__RAM_C8CB_]
        cp   $A0
        jr   z, ._LABEL_5087_
        ld   a, [_tilemap_pos_x__RAM_C8CB_]
        add  $18
        ld   [_tilemap_pos_x__RAM_C8CB_], a
        jr   ._LABEL_50AF_

    ._LABEL_5087_:
        ld   a, $10
        ld   [_tilemap_pos_x__RAM_C8CB_], a
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        add  $10
        ld   [_tilemap_pos_y__RAM_C8CA_], a
        jr   ._LABEL_50AF_

    ._LABEL_5096_:
        ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        call oam_free_slot_and_clear__89B_
        xor  a
        ld   [ui_grid_menu_selected_icon__RAM_D06E_], a
        ld   a, [ui_grid_menu_selected_icon__RAM_D06E_ + 1]    ; ui_grid_menu_selected_icon__RAM_D06E_ + 1 = $D06F
        ld   [_tilemap_pos_x__RAM_C8CB_], a
        ld   a, [ui_grid_menu_selected_icon__RAM_D06E_ + 2]    ; ui_grid_menu_selected_icon__RAM_D06E_ + 2 = $D070
        ld   [_tilemap_pos_y__RAM_C8CA_], a
    ._LABEL_50AF_:
        ld   a, $80
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        call _LABEL_623_
        ld   a, b
        ld   [_RAM_D05F_], a    ; _RAM_D05F_ = $D05F
        ld   a, $03
        call _LABEL_4A72_
        jp   .maybe_calendar_app_main_input_loop__4F95_

    ._LABEL_50C3_:
        xor  a
        ld   [_RAM_D05D_], a    ; _RAM_D05D_ = $D05D
        ld   a, [ui_grid_menu_selected_icon__RAM_D06E_]
        dec  a
        cp   $FF
        jr   z, ._LABEL_5100_
        ld   [ui_grid_menu_selected_icon__RAM_D06E_], a
        ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        call _LABEL_953_
        call oam_free_slot_and_clear__89B_
        ld   a, [_tilemap_pos_x__RAM_C8CB_]
        cp   $10
        jr   z, ._LABEL_50F0_
        ld   a, [_tilemap_pos_x__RAM_C8CB_]
        sub  $18
        ld   [_tilemap_pos_x__RAM_C8CB_], a
        jp   ._LABEL_50AF_

    ._LABEL_50F0_:
        ld   a, $A0
        ld   [_tilemap_pos_x__RAM_C8CB_], a
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        sub  $10
        ld   [_tilemap_pos_y__RAM_C8CA_], a
        jp   ._LABEL_50AF_

    ._LABEL_5100_:
        ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        call oam_free_slot_and_clear__89B_
        ld   a, [ui_grid_menu_icon_count__RAM_D06D_]
        dec  a
        ld   [ui_grid_menu_selected_icon__RAM_D06E_], a
        ld   a, [ui_grid_menu_selected_icon__RAM_D06E_ + 3]    ; ui_grid_menu_selected_icon__RAM_D06E_ + 3 = $D071
        ld   [_tilemap_pos_x__RAM_C8CB_], a
        ld   a, [_RAM_D072_]
        ld   [_tilemap_pos_y__RAM_C8CA_], a
        jp   ._LABEL_50AF_

    ._LABEL_511F_:
        xor  a
        ld   [_RAM_D05B_], a    ; _RAM_D05B_ = $D05B
        ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        call _LABEL_953_
        call oam_free_slot_and_clear__89B_
        ld   a, [ui_grid_menu_selected_icon__RAM_D06E_]
        add  $07
        ld   hl, ui_grid_menu_icon_count__RAM_D06D_
        cp   [hl]
        jr   nc, ._LABEL_5148_
        ld   [ui_grid_menu_selected_icon__RAM_D06E_], a
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        add  $10
        ld   [_tilemap_pos_y__RAM_C8CA_], a
        jp   ._LABEL_50AF_

    ._LABEL_5148_:
        ld   a, [ui_grid_menu_selected_icon__RAM_D06E_]
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
        ld   [ui_grid_menu_selected_icon__RAM_D06E_], a
        jp   ._LABEL_50AF_

    ._LABEL_5167_:
        xor  a
        ld   [_RAM_D05C_], a    ; _RAM_D05C_ = $D05C
        ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        call _LABEL_953_
        call oam_free_slot_and_clear__89B_
        ld   a, [ui_grid_menu_selected_icon__RAM_D06E_]
        sub  $07
        jr   c, ._LABEL_518C_
        ld   [ui_grid_menu_selected_icon__RAM_D06E_], a
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        sub  $10
        ld   [_tilemap_pos_y__RAM_C8CA_], a
        jp   ._LABEL_50AF_

    ._LABEL_518C_:
        ld   a, [ui_grid_menu_selected_icon__RAM_D06E_]
        ld   b, $00
        ld   hl, ui_grid_menu_icon_count__RAM_D06D_
    ._LABEL_5194_:
        add  $07
        cp   [hl]
        jr   nc, ._LABEL_519C_
        inc  b
        jr   ._LABEL_5194_

    ._LABEL_519C_:
        sub  $07
        ld   [ui_grid_menu_selected_icon__RAM_D06E_], a
        ld   a, $10
        call multiply_a_x_b__result_in_de__4853_
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        add  e
        ld   [_tilemap_pos_y__RAM_C8CA_], a
        jp   ._LABEL_50AF_

    ._LABEL_51B0_:
        ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        call _LABEL_953_
        ld   a, [_tilemap_pos_x__RAM_C8CB_]
        cp   $A0
        jp   z, .maybe_calendar_app_main_input_loop__4F95_
        ld   a, [ui_grid_menu_selected_icon__RAM_D06E_]
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
        jr   z, ._LABEL_5206_
        ld   e, l
        ld   d, h
        dec  hl
        dec  hl
        dec  hl

    ._LABEL_51E4_:
        ld   a, [de]
        ldi  [hl], a
        inc  de
        ld   a, e
        cp   $FD
        jr   nz, ._LABEL_51E4_
        ld   a, [_RAM_DBFF_]    ; _RAM_DBFF_ = $DBFF
        dec  a
        ld   [_RAM_DBFF_], a    ; _RAM_DBFF_ = $DBFF
        call _LABEL_535C_
        ld   hl, shadow_rtc_day__RAM_D053_ ; shadow_rtc_day__RAM_D053_ = $D053
        ld   c, $02
        call _LABEL_5401_
        ld   a, $03
        call _LABEL_4A72_
        jp   .maybe_calendar_app_main_input_loop__4F95_

    ._LABEL_5206_:
        ld   a, [_RAM_DBFF_]    ; _RAM_DBFF_ = $DBFF
        cp   $1E
        jp   nc, .maybe_calendar_app_main_input_loop__4F95_
        inc  a
        ld   [_RAM_DBFF_], a    ; _RAM_DBFF_ = $DBFF
        ld   de, shadow_rtc_buf_start_and_year__RAM_D051_ ; shadow_rtc_buf_start_and_year__RAM_D051_ = $D051
        ld   b, $03

    ._LABEL_5217_:
        ld   a, [de]
        ldi  [hl], a
        inc  de
        dec  b
        jr   nz, ._LABEL_5217_
        call _LABEL_535C_
        call _LABEL_52F5_
        ld   a, $03
        call _LABEL_4A72_
        jp   .maybe_calendar_app_main_input_loop__4F95_

    ._LABEL_522B_:
        ld   hl, _RAM_D029_ ; _RAM_D029_ = $D029
        call convert_bcd2dec_at_hl_result_in_a__5B03_
        dec  a
        jr   nz, ._LABEL_525D_
        ld   hl, buffer__RAM_D028_
        call convert_bcd2dec_at_hl_result_in_a__5B03_
        cp   $0C
        jr   nc, ._LABEL_5240_
        add  $64

    ._LABEL_5240_:
        dec  a
        cp   $5C
        jp   c, .maybe_calendar_app_main_input_loop__4F95_
        call _LABEL_5379_
        ld   [buffer__RAM_D028_], a
        ld   a, $12
        ld   [_RAM_D029_], a    ; _RAM_D029_ = $D029
        ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        call oam_free_slot_and_clear__89B_
        jp   ._LABEL_4DCD_

    ._LABEL_525D_:
        call _LABEL_5379_
        ld   [_RAM_D029_], a    ; _RAM_D029_ = $D029
        ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        call oam_free_slot_and_clear__89B_
        jp   ._LABEL_4DCD_

    ._LABEL_526F_:
        ld   hl, _RAM_D029_ ; _RAM_D029_ = $D029
        call convert_bcd2dec_at_hl_result_in_a__5B03_
        inc  a
        cp   $0D
        jr   c, ._LABEL_52A3_
        ld   hl, buffer__RAM_D028_
        call convert_bcd2dec_at_hl_result_in_a__5B03_
        cp   $0C
        jr   nc, ._LABEL_5286_
        add  $64

    ._LABEL_5286_:
        inc  a
        cp   $70
        jp   z, .maybe_calendar_app_main_input_loop__4F95_
        call _LABEL_5379_
        ld   [buffer__RAM_D028_], a
        ld   a, $01
        ld   [_RAM_D029_], a    ; _RAM_D029_ = $D029
        ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        call oam_free_slot_and_clear__89B_
        jp   ._LABEL_4DCD_

    ._LABEL_52A3_:
        call _LABEL_5379_
        ld   [_RAM_D029_], a    ; _RAM_D029_ = $D029
        ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        call oam_free_slot_and_clear__89B_
        jp   ._LABEL_4DCD_

    ._LABEL_52B5_:
        ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        call oam_free_slot_and_clear__89B_
        ret

    ._LABEL_52BF_:
        ld   a, [_RAM_D074_ + 1]
        ld   hl, buffer__RAM_D028_
        cp   [hl]
        jr   nz, ._LABEL_52D7_
        ld   a, [_RAM_D074_ + 2]
        inc  hl
        cp   [hl]
        jr   nz, ._LABEL_52D7_
        ld   a, $07
        ld   [_RAM_D04A_], a    ; _RAM_D04A_ = $D04A
        call _LABEL_538C_

    ._LABEL_52D7_:
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


; ===== Appears to be support code for Calendar App =====


_LABEL_52F5_:
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    add  $02
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   hl, _TILEMAP0; $9800
    call calc_vram_addr_of_tile_xy_base_in_hl__4932_
    ld   a, [shadow_rtc_day__RAM_D053_]    ; shadow_rtc_day__RAM_D053_ = $D053
    swap a
    and  $0F
    jr   z, ._LABEL_5310_
    add  $F1
    jr   ._LABEL_5312_

    ._LABEL_5310_:
        ld   a, $BE
    ._LABEL_5312_:
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
    jr   z, ._LABEL_5359_
    ld   a, [_RAM_DBFF_]    ; _RAM_DBFF_ = $DBFF
    and  a
    jr   z, ._LABEL_5357_
    ld   b, a

    ._LABEL_5340_:
        ld   de, shadow_rtc_buf_start_and_year__RAM_D051_ ; shadow_rtc_buf_start_and_year__RAM_D051_ = $D051
        ld   c, $03

    ._LABEL_5345_:
        ld   a, [de]
        cp   [hl]
        jr   nz, ._LABEL_5350_
        inc  hl
        inc  de
        dec  c
        jr   nz, ._LABEL_5345_
        jr   ._LABEL_5359_

    ._LABEL_5350_:
        ld   a, c
        call add_a_to_hl__486E_
        dec  b
        jr   nz, ._LABEL_5340_

    ._LABEL_5357_:
        xor  a
        ret

    ._LABEL_5359_:
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
    jr   z, ._LABEL_53CC_
    cp   $08
    jr   nz, ._LABEL_53CB_
    ld   a, [buffer__RAM_D028_ + 2]    ; buffer__RAM_D028_ + 2 = $D02A
    ld   [shadow_rtc_day__RAM_D053_], a    ; shadow_rtc_day__RAM_D053_ = $D053
    ld   a, [buffer__RAM_D028_ + 3]    ; buffer__RAM_D028_ + 3 = $D02B
    dec  a
    ld   [shadow_rtc_dayofweek__RAM_D054_], a    ; shadow_rtc_dayofweek__RAM_D054_ = $D054
    cp   $06
    jr   z, ._LABEL_53C1_
    call _LABEL_532F_
    ld   hl, buffer__RAM_D028_ + 2 ; buffer__RAM_D028_ + 2 = $D02A
    and  a
    jr   z, ._LABEL_53C6_

    ._LABEL_53C1_:
        call _LABEL_52F5_
        jr   ._LABEL_53CB_

    ._LABEL_53C6_:
        ld   c, $02
        call _LABEL_5401_
    ._LABEL_53CB_:
        ret

    ._LABEL_53CC_:
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
    jr   z, ._LABEL_542E_
    sla  a
    add  $00
    bit  1, c
    jr   z, ._LABEL_5427_
    set  7, a
    bit  2, c
    jr   z, ._LABEL_5427_
    cp   $80
    jr   nz, ._LABEL_5427_
    ld   a, $98
    ._LABEL_5427_:
        push hl
        push bc
        call _LABEL_5480_
        jr   ._LABEL_544F_

    ._LABEL_542E_:
        add  $C0
        cp   $C0
        jr   nz, ._LABEL_543A_
        bit  2, c
        jr   nz, ._LABEL_543A_
        ld   a, $BE

    ._LABEL_543A_:
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        push hl
        push bc
        bit  0, c
        jr   nz, ._LABEL_544C_
        bit  1, c
        jr   nz, ._LABEL_544C_
        call wait_vbl_write_byte_tilemap0_preset_xy_and_data__612_
        jr   ._LABEL_544F_

    ._LABEL_544C_:
        call wait_vbl_write_byte_tilemap0_preset_xy_and_data__612_
    ._LABEL_544F_:
        ld   a, [_tilemap_pos_x__RAM_C8CB_]
        inc  a
        ld   [_tilemap_pos_x__RAM_C8CB_], a
        pop  bc
        ld   a, b
        and  $0F
        bit  0, c
        jr   z, ._LABEL_5472_
        sla  a
        add  $00
        bit  1, c
        jr   z, ._LABEL_5468_
        set  7, a
    ._LABEL_5468_:
        call _LABEL_5480_
        jr   ._LABEL_547E_

    ._LABEL_546D_:
        call wait_vbl_write_byte_tilemap0_preset_xy_and_data__612_
        jr   ._LABEL_547E_

    ._LABEL_5472_:
        add  $C0
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        bit  1, c
        jr   nz, ._LABEL_546D_
        call wait_vbl_write_byte_tilemap0_preset_xy_and_data__612_

    ._LABEL_547E_:
        pop  hl
        ret

_LABEL_5480_:
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    push bc
    push hl
    push de
    bit  1, c
    ld   hl, _TILEMAP0; $9800
    jr   z, ._LABEL_5490_
    ld   hl, _TILEMAP0; $9800

    ._LABEL_5490_:
        call calc_vram_addr_of_tile_xy_base_in_hl__4932_
        call wait_until_vbl__92C_
        call maybe__vram_write_byte_2rows_addr_in_hl_preset_data__549D_
        pop  de
        pop  hl
        pop  bc
        ret

