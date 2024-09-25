
; Actually in 32K Bank 0 Upper 16K, but 32K banking not supported in RGBDS
; SECTION "rom0_piano_apps_711A", ROMX[$711A], BANK[$1]


; Sets up Piano sub-menu with icons
piano_app_icon_menu_init__711A_::
        ; GFX Loading 128 Tiles (but 45 are valid at start, then a whole separate block, then some code at the end)
        ; Seems to load at least some garbage tiles...
        call wait_until_vbl__92C_
        call display_screen_off__94C_
        ld   hl, _TILEDATA9000                                          ; Dest
        ld   de, tile_data_0x40ba_720_bytes_paino_app_menu_icons__40BA_ ; $40BA
        ld   bc, (128 * TILE_SZ_BYTES)                                  ; Copy size: 128 tiles (2048 bytes)
        call memcopy_in_RAM__C900_

        ; Load Tile Data for the main menu font
        call wait_until_vbl__92C_
        call display_screen_off__94C_
        ld   hl, _TILEDATA8800                         ; Dest
        ld   de, gfx_tile_data__main_menu_font__2F2A_  ; Source
        ld   bc, (MENU_FONT_128_TILES * TILE_SZ_BYTES) ; Copy size: 128 tiles (2048 bytes)
        call memcopy_in_RAM__C900_

        ; Draw the Icon grid menu and run it
        xor  a
        ld   [_RAM_D03B_ + 1], a
        ld   [_RAM_D03B_ + 2], a
        ld   [_RAM_D03B_ + 3], a
        ld   [_RAM_D03F_], a
        ld   a, MENU_ESCAPE_KEY_RUNS_LAST_ICON_TRUE  ; $01
        ld   [ui_grid_menu_escape_key_runs_last_icon__RAM_D06C_], a
        ld   a, PIANO_MENU_NUM_ICONS  ; $05
        ld   [ui_grid_menu_icon_count__RAM_D06D_], a
        call ui_icon_menu_draw_and_run__4A7B_

        ld   a, [ui_grid_menu_selected_icon__RAM_D06E_]
        cp   PIANO_APP_FREEPLAY  ; $00
        push af
        call z, piano_freeplay_app__7185_
        pop  af

        cp   PIANO_APP_LEARN_SONG  ; $01
        push af
        call z, piano_learn_song_app__720B_
        pop  af

        cp   PIANO_APP_PRERECORDED  ; $02
        push af
        call z, piano_prerecorded_app__7226_
        pop  af

        cp   PIANO_APP_RECORD_AND_PLAYBACK  ; $03
        push af
        call z, piano_app_record_and_playback__741D_
        pop  af

        cp   PIANO_APP_BACK_TO_MAIN_MENU  ; $04
        ret  nc

        ; TODO: Why is it clearing Serial IO registers here?
        ; Haven't seen this behavior elsewhere so far
        xor  a
        ldh  [rSB], a
        ldh  [rSC], a
        call audio_init__784F_
        jp   piano_app_icon_menu_init__711A_


piano_freeplay_app__7185_:
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

        call piano_app__gfx_load_tile_map_20x6_at_438a__7691_
        call _LABEL_761F_
        call _display_bg_sprites_on__627_
        xor  a
        ld   [_RAM_D04B_], a
        ld   a, $FF
        ld   [_RAM_D079_], a
    .input_loop__71BB_:
            call timer_wait_50msec_and_maybe_optional_audio_or_speech__289_
            call input_read_keys__C8D_
            ld   a, [input_key_pressed__RAM_D025_]
            cp   SYS_CHAR_SALIDA  ; $2A
            jr   z, .done_exit__7207_

            cp   SYS_CHAR_PRINTSCREEN  ; $2F
            jr   nz, .check_if_other_keys__71D1_

            call call_printscreen_in_32k_bank_2__522_
            jr   .input_loop__71BB_

    .check_if_other_keys__71D1_:
            cp   $18  ; Unknown SYS_CHAR_
            jr   nc, ._LABEL_71F6_
            ld   hl, _RAM_D079_
            cp   [hl]
            jr   nz, ._LABEL_71E2_
            ld   a, $F9
            ld   [_RAM_CC23_], a    ; _RAM_CC23_ = $CC23
            jr   .input_loop__71BB_

    ._LABEL_71E2_:
            ld   [hl], a
            sla  a
            ld   [_RAM_D03A_], a
            ld   hl, $7980
            call add_a_to_hl__486E_
            call _LABEL_2A2_
            call maybe_piano_app__display_keyboard_note__77D3_
            jr   .input_loop__71BB_

    ._LABEL_71F6_:
            ld   a, SYS_CHAR_NO_DATA_OR_KEY  ; $FF
            ld   [_RAM_D079_], a
            call _LABEL_77B0_
            xor  a
            ld   [_RAM_CC00_], a    ; _RAM_CC00_ = $CC00
            call audio_off_on_reset_max_vol__787C_
            jr   .input_loop__71BB_

    .done_exit__7207_:
            call _LABEL_77B0_
            ret

piano_learn_song_app__720B_:
        ld   b, $00
        call _LABEL_7242_
        ret  z
        call piano_app__gfx_load_tile_map_20x6_at_438a__7691_
        call _LABEL_761F_
        call _LABEL_765B_
        call _display_bg_sprites_on__627_
        xor  a
        ld   [_RAM_D07B_], a
        call _LABEL_7310_
        jr   piano_learn_song_app__720B_

piano_prerecorded_app__7226_:
        ld   b, $01
        call _LABEL_7242_
        ret  z
        call piano_app__gfx_load_tile_map_20x6_at_438a__7691_
        call _LABEL_761F_
        call _LABEL_766D_
        call _display_bg_sprites_on__627_
        ld   a, $01
        ld   [_RAM_D07B_], a
        call _LABEL_7310_
        jr   piano_prerecorded_app__7226_

; TODO: This might be drawing the Piano app screens (keyboard at bottom, some tall text above iirc)
_LABEL_7242_:
        push bc

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
            ld   de, string_message__piano_app__select_melody__78FF_
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
        call timer_wait_50msec_and_maybe_optional_audio_or_speech__289_
        call input_read_keys__C8D_
        ld   a, [input_key_pressed__RAM_D025_]
        cp   SYS_CHAR_SALIDA  ; $2A
        jr   nz, ._LABEL_72B5_
        xor  a
        ld   [_RAM_D03A_], a
        ret

    ._LABEL_72B5_:
            cp   SYS_CHAR_ENTRA_CR  ; $2E
            jr   nz, ._LABEL_72C0_
            ld   a, [_RAM_D03A_]
            and  a
            jr   z, _LABEL_72A0_
            ret

    ._LABEL_72C0_:
            cp   SYS_CHAR_PRINTSCREEN  ; $2F
            jr   nz, ._LABEL_72D9_
            ld   a, $0E
            ld   [_RAM_D03B_], a
            call _LABEL_72F0_
            ld   a, [_RAM_D03A_]
            push af
            call call_printscreen_in_32k_bank_2__522_
            pop  af
            ld   [_RAM_D03A_], a
            jr   _LABEL_72A0_

    ._LABEL_72D9_:
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
        jr   nz, ._LABEL_7304_
        call wait_until_vbl__92C_
        ld   a, $BF
        ld   [$9949], a
        ret

    ._LABEL_7304_:
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
        call piano_app__show_message__begin_playing__76D4_
        call input_wait_for_keypress__4B84
        xor  a
        ld   [_RAM_D04B_], a
_LABEL_7334_:
        xor  a
        ld   [_RAM_CC00_], a    ; _RAM_CC00_ = $CC00
        call audio_off_on_reset_max_vol__787C_
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
            call timer_wait_50msec_and_maybe_optional_audio_or_speech__289_
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
        call maybe_piano_app__display_keyboard_note__77D3_
_LABEL_738C_:
        call timer_wait_50msec_and_maybe_optional_audio_or_speech__289_
        call input_read_keys__C8D_
        ld   a, [input_key_pressed__RAM_D025_]
        cp   SYS_CHAR_SALIDA  ; $2A
        jp   z, _LABEL_7417_
        cp   SYS_CHAR_PRINTSCREEN ; $2F
        jr   nz, _LABEL_73A4_
        call call_printscreen_in_32k_bank_2__522_
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
        call audio_off_on_reset_max_vol__787C_
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
        call timer_wait_50msec_and_maybe_optional_audio_or_speech__289_
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
        call piano_app__show_message__stop_playing__76E0_
_LABEL_740D_:
        call _LABEL_77B0_
        call audio_init__784F_
        call input_wait_for_keypress__4B84
        ret

_LABEL_7417_:
        pop  hl
        call _LABEL_7704_
        jr   _LABEL_740D_

piano_app_record_and_playback__741D_:
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

        call piano_app__gfx_load_tile_map_20x6_at_438a__7691_
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
            call timer_wait_50msec_and_maybe_optional_audio_or_speech__289_
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
        call piano_app__show_message__begin_recording__76F8_
        call input_wait_for_keypress__4B84
        ld   a, $03
        ld   [_RAM_D07F_], a
        ld   a, $03
        ld   [_RAM_D03B_], a
        call _LABEL_7721_
        call _LABEL_7704_
        ld   e, $00
        jp   _LABEL_7470_

_LABEL_74A6_:
        cp   SYS_CHAR_F2  ; $31
        jp   z, _LABEL_75F0_

        cp   SYS_CHAR_ENTRA_CR  ; $2E
        jp   z, _LABEL_75BD_

        cp   SYS_CHAR_F3  ; $32
        jp   z, _LABEL_75A3_

        cp   SYS_CHAR_AYUDA  ; $2D
        jp   nz, _LABEL_74BD_
        call piano_freeplay_app__show_help_menu__7733_

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
        call call_printscreen_in_32k_bank_2__522_
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
        call maybe_piano_app__display_keyboard_note__77D3_
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
        call piano_app__show_message__memory_full__76BC_
        ld   a, $01
        ld   [_RAM_D07C_], a
        xor  a
        ld   [_RAM_CC00_], a    ; _RAM_CC00_ = $CC00
        call audio_off_on_reset_max_vol__787C_
        ld   [_RAM_D07F_], a
        ld   a, $FF
        ld   [_RAM_D180_], a
        ld   a, $3C
        ld   [_RAM_D079_], a
        call _LABEL_77B0_
        call input_wait_for_keypress__4B84
        ld   b, $32
_LABEL_7556_:
        push bc
        call timer_wait_50msec_and_maybe_optional_audio_or_speech__289_
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
        call audio_off_on_reset_max_vol__787C_
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
        call input_wait_for_keypress__4B84
        jp   _LABEL_7465_

_LABEL_75BD_:
        call _LABEL_75CF_
        call _LABEL_7704_
        call piano_app__show_message__stop_recording__76B0_
        call _LABEL_77B0_
        call input_wait_for_keypress__4B84
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
        call input_wait_for_keypress__4B84
        jp   _LABEL_7465_

_LABEL_760A_:
        call _LABEL_7704_
        call piano_app__show_message__melody_not_recorded__76EC_
        call _LABEL_77B0_
        ld   e, $00
        xor  a
        ld   [_RAM_D07F_], a
        call input_wait_for_keypress__4B84
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
        call maybe__vram_write_byte_2rows_addr_in_hl_preset_data__549D_
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


piano_app__gfx_load_tile_map_20x6_at_438a__7691_:
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


piano_app__show_message__stop_recording__76B0_:
        ld   de, string_message__piano_app__stop_recording__7918_
        ld   hl, $0107
        ld   c, PRINT_NORMAL  ; $01
        call render_string_at_de_to_tilemap0_xy_in_hl__4A46_
        ret

piano_app__show_message__memory_full__76BC_:
        ld   de, string_message__piano_app__memory_full__7927_
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

piano_app__show_message__begin_playing__76D4_:
        ld   de, string_message__piano_app__begin_playing__795A_
        ld   hl, $0107
        ld   c, PRINT_NORMAL  ; $01
        call render_string_at_de_to_tilemap0_xy_in_hl__4A46_
        ret

piano_app__show_message__stop_playing__76E0_:
        ld   de, string_message__piano_app__stop_playing__796B_
        ld   hl, $0107
        ld  c, PRINT_NORMAL  ; $01
        call render_string_at_de_to_tilemap0_xy_in_hl__4A46_
        ret

piano_app__show_message__melody_not_recorded__76EC_:
        ld   de, string_message__piano_app__melody_not_recorded__7935_
        ld   hl, $0107
        ld  c, PRINT_NORMAL  ; $01
        call render_string_at_de_to_tilemap0_xy_in_hl__4A46_
        ret

piano_app__show_message__begin_recording__76F8_:
        ld   de, string_message__piano_app__begin_recording__7948_
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
        call z, call_printscreen_in_32k_bank_2__522_
        pop  af
        cp   $FF
        jr   z, _LABEL_7721_
        ret


piano_freeplay_app__show_help_menu__7733_:
        ; Load Tile Data for the main menu font
        call wait_until_vbl__92C_
        call display_screen_off__94C_
        ld   hl, _TILEDATA8800                         ; Dest
        ld   de, gfx_tile_data__main_menu_font__2F2A_  ; Source
        ld   bc, (MENU_FONT_128_TILES * TILE_SZ_BYTES) ; Copy size: 128 tiles (2048 bytes)
        call memcopy_in_RAM__C900_

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

        ld   de, string_message__piano_freeplay_help__7888_
        ld   hl, $0707
        ld   c, PRINT_NORMAL  ; $01
        call render_string_at_de_to_tilemap0_xy_in_hl__4A46_

        ld   de, string_message__piano_freeplay_help_text__788E_
        ld   hl, $020A
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
        call input_wait_for_keypress__4B84
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
        call input_wait_for_keypress__4B84
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

maybe_piano_app__display_keyboard_note__77D3_:
        call _LABEL_77B0_
        ld   hl, piano_app__keyboard_note_names_LUT__79B2_
        ld   a, [_RAM_D03A_]
        cp   $78
        jr   nz, ._LABEL_77E4_
        call audio_off_on_reset_max_vol__787C_
        ret

    ._LABEL_77E4_:
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
            jr   z, ._LABEL_7807_
            ld   a, $FD
            ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    ._LABEL_7807_:
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
            jr   z, ._LABEL_7827_
            sub  $10
    ._LABEL_7827_:
            ld   [_tilemap_pos_y__RAM_C8CA_], a
            xor  a
            ld   [_RAM_C8CD_], a    ; _RAM_C8CD_ = $C8CD
            ld   b, $04
            ld   de, _RAM_D03B_ + 1 ; _RAM_D03B_ + 1 = $D03C
    ._LABEL_7833_:
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
            jr   nz, ._LABEL_7833_
            ret

audio_init__784F_:
        xor  a
        ldh  [rAUDENA], a
        xor  a
        ldh  [rAUD3ENA], a
        ld   a, $FF
        ldh  [rAUD3LEN], a
        ld   a, $55
        ld   bc, $0800 | LOW(_AUD3WAVERAM_LAST) ; | _PORT_3F_
        .waveram_load_loop__785E_:
                ldh  [c], a
                dec  c
                dec  b
                jr   nz, .waveram_load_loop__785E_

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
        call timer_wait_50msec_and_maybe_optional_audio_or_speech__289_
        ret

audio_off_on_reset_max_vol__787C_:
        xor  a
        ldh  [rAUDENA], a
        ld   a, AUDENA_ON  ; $80
        ldh  [rAUDENA], a
        ld   a, (AUDVOL_LEFT_MAX | AUDVOL_RIGHT_MAX)  ; $77  ; Set rAUDVOL to Max Left/Right volume, with VIN off for left and right
        ldh  [rAUDVOL], a
        ret


; Data from 7888 to 788D (6 bytes)
string_message__piano_freeplay_help__7888_:
; "AYUDA" (Help)
    db $81, $99, $95, $84, $81, $00


; Data from 788E to 78C2 (53 bytes)
string_message__piano_freeplay_help_text__788E_:
    ; "F1 : GRABACION" (Record)
    db $86, $C1, $BE, $FE, $BE, $87, $92, $81, $82, $81, $83, $89, $8F, $8E, $00
    ; "F2 : TOCA" (Play Back)
    db $86, $C2, $BE, $FE, $BE, $94, $8F, $83, $81, $00
    ; "F3 : BORRA" (Erase)
    db $86, $C3, $BE, $FE, $BE, $82, $8F, $92, $92, $81, $00
    ; "ENTRA : CONFIRMA" (Confirm)
    db $85, $8E, $94, $92, $81, $BE, $FE, $BE, $83, $8F, $8E, $86, $89, $92, $8D, $81, $00


; Maybe some sprite or tile id map data below

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
string_message__piano_app__select_melody__78FF_:
; "SELECCIONA MELODIA" (Select melody)
    db $93, $85, $8C, $85, $83, $83, $89, $8F, $8E, $81, $BE, $8D, $85, $8C, $8F, $84, $89, $81, $00

; Data from 7912 to 7917 (6 bytes)
_DATA_7912_:
    db $C1, $BE, $CB, $BE, $C9, $00

; Data from 7918 to 7926 (15 bytes)
; "DEJA DE GRABAR" (Stop Recording)
string_message__piano_app__stop_recording__7918_:
    db $84, $85, $8A, $81, $BE, $84, $85, $BE, $87, $92, $81, $82, $81, $92, $00

; Data from 7927 to 7934 (14 bytes)
string_message__piano_app__memory_full__7927_:
; "MEMORIA LLENA" (Memory Full)
    db $8D, $85, $8D, $8F, $92, $89, $81, $BE, $8C, $8C, $85, $8E, $81, $00

; Data from 7935 to 7947 (19 bytes)
string_message__piano_app__melody_not_recorded__7935_:
; "MELODIA NO GRABADA" (Melody Not Recorded)
    db $8D, $85, $8C, $8F, $84, $89, $81, $BE, $8E, $8F, $BE, $87, $92, $81, $82, $81, $84, $81, $00

; Data from 7948 to 7959 (18 bytes)
string_message__piano_app__begin_recording__7948_:
; "COMIENZA A GRABAR" (Begin Recording)
    db $83, $8F, $8D, $89, $85, $8E, $9A, $81, $BE, $81, $BE, $87, $92, $81, $82, $81, $92, $00

; Data from 795A to 796A (17 bytes)
string_message__piano_app__begin_playing__795A_:
; "COMIENZA A TOCAR" (Begin Playing)
    db $83, $8F, $8D, $89, $85, $8E, $9A, $81, $BE, $81, $BE, $94, $8F, $83, $81, $92
    db $00

; Data from 796B to 7978 (14 bytes)
string_message__piano_app__stop_playing__796B_:
; "DEJA DE TOCAR" (Stop Playing)
    db $84, $85, $8A, $81, $BE, $84, $85, $BE, $94, $8F, $83, $81, $92, $00

; TODO: Something encoded as a string that gets printed
; Data from 7979 to 79B1 (57 bytes)
_DATA_7979_:
    db $82, $8F, $92, $92, $81, $92, $00, $18, $F9, $19, $F9, $1A, $F9, $1B, $F9, $1C
    db $F9, $1D, $F9, $1E, $F9, $1F, $F9, $20, $F9, $21, $F9, $22, $F9, $23, $F9, $24
    db $F9, $25, $F9, $26, $F9, $27, $F9, $28, $F9, $29, $F9, $2A, $F9, $2B, $F9, $2C
    db $F9, $2D, $F9, $2E, $F9, $2F, $F9, $54, $F9

; Data from 79B2 to 7FFF (1614 bytes)
; 6 x 24 table of encoded note / keyboard key strings
piano_app__keyboard_note_names_LUT__79B2_:
;       X   Y    |------Name------|
    db $1C, $90, $84, $8F, $BE, $BE   ; DO
    db $20, $58, $84, $8F, $FC, $BE   ; DO_SHARP
    db $24, $90, $92, $85, $BE, $BE   ; RE
    db $28, $58, $92, $85, $FC, $BE   ; RE_SHARP
    db $2C, $90, $8D, $89, $BE, $BE   ; MI
    db $34, $90, $86, $81, $BE, $BE   ; FA
    db $38, $58, $86, $81, $FC, $BE   ; FA_SHARP
    db $3C, $90, $93, $8F, $8C, $BE   ; SOL
    db $40, $58, $93, $8F, $8C, $FC   ; SOL_SHARP
    db $44, $90, $8C, $81, $BE, $BE   ; LA
    db $48, $58, $8C, $81, $FC, $BE   ; LA_SHARP
    db $4C, $90, $93, $89, $BE, $BE   ; SI
    db $54, $90, $84, $8F, $BE, $BE   ; DO_2
    db $58, $58, $84, $8F, $FC, $BE   ; DO_2_SHARP
    db $5C, $90, $92, $85, $BE, $BE   ; RE_2
    db $60, $58, $92, $85, $FC, $BE   ; RE_2_SHARP
    db $64, $90, $8D, $89, $BE, $BE   ; MI_2
    db $6C, $90, $86, $81, $BE, $BE   ; FA_2
    db $70, $58, $86, $81, $FC, $BE   ; FA_2_SHARP
    db $74, $90, $93, $8F, $8C, $BE   ; SOL_2
    db $78, $58, $93, $8F, $8C, $FC   ; SOL_2_SHARP
    db $7C, $90, $8C, $81, $BE, $BE   ; LA_2
    db $80, $58, $8C, $81, $FC, $BE   ; LA_2_SHARP
    db $84, $90, $93, $89, $BE, $BE   ; SI_2

; Free up space at end of ROM if needed
IF (!DEF(BUILD_FREE_TRAILING_SPACE_BANK_0))
; Unused space
ds 1470, $00
ENDC
