; Actually in 32K Bank 0 Upper 16K, but 32K banking not supported in RGBDS
; SECTION "rom0_piano_apps_6328", ROMX[$6328], BANK[$1]


paint_app_init__6328_::
    xor  a  ; MENU_ESCAPE_KEY_RUNS_LAST_ICON_FALSE
    ld   [ui_grid_menu_escape_key_runs_last_icon__RAM_D06C_], a
    ld   [ui_grid_menu_icon_count__RAM_D06D_], a
    ld   a, $01
    ld   [print_tile_row_pass__maybe_more__RAM_D1A7_], a
    ld   hl, $0018
    res  7, h
    ld   a, $02
    call switch_bank_in_a_jump_hl_RAM__C920_
    ei
    ld   a, [print_tile_row_pass__maybe_more__RAM_D1A7_]
    cp   $03
    ret  z
    cp   $04
    ret  z
    push af
    call wait_until_vbl__92C_
    call display_screen_off__94C_
    pop  af
    cp   $02
    jr   z, ._LABEL_6369_

    ; Clear from 0x8800 -> 0x9800 (all of _TILEDATA8800 & _TILEDATA9000)
    ld   hl, _TILEDATA8800  ; $8800
    .tilepatterns_clear_loop__6357_:
        xor  a
        ldi  [hl], a
        ld   a, h
        cp   $98
        jr   nz, .tilepatterns_clear_loop__6357_

    ; Fill with 0xC8 from 0x9800 -> 0xA000 (all of _TILEMAP0 and _TILEMAP1)
    ld   hl, _TILEMAP0; $9800
    .tilemap_clear_loop__6361_:
        ld   a, $C8
        ldi  [hl], a
        ld   a, h
        cp   $A0
        jr   nz, .tilemap_clear_loop__6361_

    ._LABEL_6369_:
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
        ld   [_RAM_D19C_], a
        ld   [_RAM_D19D_], a
        ld   a, $50
        ld   [_tilemap_pos_y__RAM_C8CA_], a
        ld   a, $58
        ld   [_tilemap_pos_x__RAM_C8CB_], a
        call paint_app_some_util__6510_


paint_app_maybe_main_loop__63A7_:
        xor  a
        ld   [_RAM_D05D_], a
        ld   [_RAM_D05E_], a
        ld   [_RAM_D05C_], a
        ld   [_RAM_D05B_], a

input_loop__63B4_:
    call timer_wait_50msec_and_maybe_optional_audio_or_speech__289_
    call input_read_keys__C8D_
    ld   a, [input_key_pressed__RAM_D025_]
    cp   SYS_CHAR_SALIDA  ; $2A
    jp   z, paint_app_key_pressed_esc__6673_

    cp   SYS_CHAR_F1  ; $30
    jr   nz, .check_key_f2__63D1_

    ld   a, [_RAM_D19C_]
    ld   [_RAM_D073_], a
    call paint_app_set_line_thickness__67A6_
    jr   input_loop__63B4_

    .check_key_f2__63D1_:
        cp   SYS_CHAR_F2  ; $31
        jr   nz, .check_keys_f3_f4_f5_help__63E0_

        ld   a, [_RAM_D19D_]
        ld   [_RAM_D073_], a
        call paint_app_set_draw_color__67AC_
        jr   input_loop__63B4_

    .check_keys_f3_f4_f5_help__63E0_:
        cp   SYS_CHAR_F3  ; $32
        jp   z, paint_app_save__667A_

        cp   SYS_CHAR_F4  ; $33
        jp   z, paint_app_floodfill__6ACE_

        cp   SYS_CHAR_F5  ; $34
        jp   z, paint_app_erase__66D1_

        cp   SYS_CHAR_AYUDA  ; $2D
        jp   nz, .check_key_printscreen__6402_
        ld   a, [_RAM_D196_]
        cp   $00

        jp   nz, paint_app_maybe_main_loop__63A7_
        call paint_app_help_menu_show__6FED_
        jp   paint_app_maybe_main_loop__63A7_

    .check_key_printscreen__6402_:
        cp   SYS_CHAR_PRINTSCREEN  ; $2F
        jr   nz, .check_key_f6__640B_

        call call_printscreen_in_32k_bank_2__522_
        jr   input_loop__63B4_

    ; Selects drawing pen style
    .check_key_f6__640B_:
        cp   SYS_CHAR_F6  ; $35
        jr   nz, .check_key_f7__6416_
        ld   a, [buttons_new_pressed__RAM_D006_]
        or   $01  ; TODO: Maybe "Pen for drawing"
        jr   .apply_action_key_f6_f7__641F_

    ; Cursor Arrow style (just?)
    .check_key_f7__6416_:
        cp   SYS_CHAR_F7  ; $36
        jr   nz, .check_key_enter__6424_

        ld   a, [buttons_new_pressed__RAM_D006_]
        or   $02 ; TODO: Maybe "Cursor Arrow style"

        .apply_action_key_f6_f7__641F_:
            ld   [buttons_new_pressed__RAM_D006_], a
            jr   map_keys_to_gamepad__6430_

    .check_key_enter__6424_:
        cp   SYS_CHAR_ENTRA_CR  ; $2E
        jr   nz, map_keys_to_gamepad__6430_
        ld   a, [_RAM_D196_]
        bit  0, a
        jp   nz, _LABEL_68F3_

    map_keys_to_gamepad__6430_:
        call input_map_keycodes_to_gamepad_buttons__4D30_
        ld   a, [buttons_new_pressed__RAM_D006_]
        and  $C0
        cp   $C0
        jr   nz, ._LABEL_6446_
        ld   a, [buttons_new_pressed__RAM_D006_]
        and  $3F
        ld   [buttons_new_pressed__RAM_D006_], a
        jr   ._LABEL_6457_

    ._LABEL_6446_:
        ld   a, [buttons_new_pressed__RAM_D006_]
        and  $30
        cp   $30
        jr   nz, ._LABEL_6457_
        ld   a, [buttons_new_pressed__RAM_D006_]
        and  $CF
        ld   [buttons_new_pressed__RAM_D006_], a

    ._LABEL_6457_:
        ld   a, [buttons_new_pressed__RAM_D006_]
        and  $F3
        jp   z, paint_app_maybe_main_loop__63A7_
        ld   a, [_RAM_D196_]
        and  a
        jp   nz, ._LABEL_649E_

        ld   a, [buttons_new_pressed__RAM_D006_]
        bit  0, a  ; TODO: Maybe "Pen for drawing"
        ld   a, $01
        jr   nz, ._LABEL_6478_

        ld   a, [buttons_new_pressed__RAM_D006_]
        bit  1, a ; TODO: Maybe "Cursor Arrow style"
        jp   z, ._LABEL_649E_
        xor  a

    ._LABEL_6478_:
        ld   hl, _RAM_D192_
        ld   b, [hl]
        cp   b
        jr   nz, ._LABEL_6485_
        call paint_app_maybe_set_pen__6739_
        jp   input_loop__63B4_

    ._LABEL_6485_:
        ld   [hl], a
        ld   a, [_RAM_D04B_]
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        call _LABEL_953_
        call oam_free_slot_and_clear__89B_
        call paint_app_some_util__6510_
        call input_wait_for_keypress__4B84
        call _LABEL_685B_
        jp   paint_app_maybe_main_loop__63A7_

    ._LABEL_649E_:
        ld   a, [_RAM_D04B_]
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        call _LABEL_953_
        ld   a, [buttons_new_pressed__RAM_D006_]
        call _LABEL_4C87_
        ld   a, [_RAM_D05E_]
        cp   $01
        call z, _LABEL_6529_
        ld   a, [_RAM_D05D_]
        cp   $01
        call z, _LABEL_6575_
        ld   a, [_RAM_D05C_]
        cp   $01
        call z, _LABEL_65CE_
        ld   a, [_RAM_D05B_]
        cp   $01
        call z, _LABEL_6627_
        ld   a, [_RAM_D192_]
        and  a
        jp   z, input_loop__63B4_
        call _LABEL_6F97_
        ld   a, h
        ld   [_RAM_D193_], a
        ld   a, l
        ld   [_RAM_D194_], a
        ld   a, VBL_CMD_1  ; $01
        ld   [vbl_action_select__RAM_D195_], a
        ei

        .wait_vbl_command_complete__64E5_:
            ld   a, [vbl_action_select__RAM_D195_]
            and  a
            jr   nz, .wait_vbl_command_complete__64E5_

        ld   a, [buttons_new_pressed__RAM_D006_]
        and  $CF
        ld   [buttons_new_pressed__RAM_D006_], a
        and  $F0
        jp   z, input_loop__63B4_

        ld   a, VBL_CMD_1  ; $01
        ld   [vbl_action_select__RAM_D195_], a
        ld   a, [_RAM_D04B_]
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        call _LABEL_953_
        ei

    .wait_vbl_command_complete__6507_:
        ld   a, [vbl_action_select__RAM_D195_]
        and  a
        jr   nz, .wait_vbl_command_complete__6507_

        jp   input_loop__63B4_


; TODO: (called from various parts of drawing app code)
paint_app_some_util__6510_:
    ld   a, $D9  ; Unknown value, have not seen elsewhere. Maybe behaves like MENU_ESCAPE_KEY_RUNS_LAST_ICON_TRUE
    ld   hl, ui_grid_menu_escape_key_runs_last_icon__RAM_D06C_
    add  [hl]
    ld   hl, _RAM_D192_
    add  [hl]
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    xor  a
    ld   [_RAM_C8CD_], a
    call _LABEL_623_
    ld   a, b
    ld   [_RAM_D04B_], a
    ret


_LABEL_6529_:
    xor  a
    ld   [_RAM_D05E_], a
    ld   a, [_RAM_D04B_]
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call _LABEL_953_
    ld   b, $90
    call _LABEL_688E_
    ld   a, [_RAM_D196_]
    and  a
    jr   z, ._LABEL_6543_
    ld   b, $8C

    ._LABEL_6543_:
        ld   a, [_tilemap_pos_x__RAM_C8CB_]
        inc  a
        cp   b
        ret  nc
        ld   a, $01
        ld   [_tilemap_pos_x__RAM_C8CB_], a
        ld   a, [_RAM_D04B_]
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        ld   a, $00
        ld   [_tilemap_pos_y__RAM_C8CA_], a
        call _LABEL_851_
        ld   a, [_RAM_D196_]
        and  a
        ret  z
        ld   a, $01
        ld   [_tilemap_pos_x__RAM_C8CB_], a
        ld   a, [_RAM_D197_ + 1]
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        ld   a, $00
        ld   [_tilemap_pos_y__RAM_C8CA_], a
        call _LABEL_851_
        ret


_LABEL_6575_:
    xor  a
    ld   [_RAM_D05D_], a
    ld   a, [_RAM_D04B_]
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call _LABEL_953_
    ld   b, $20
    ld   a, [_RAM_D196_]
    and  a
    jr   z, ._LABEL_658C_
    ld   b, $1C

    ._LABEL_658C_:
        ld   a, [_tilemap_pos_x__RAM_C8CB_]
        dec  a
        cp   b
        ret  c
        ld   a, $01
        ld   [_tilemap_pos_x__RAM_C8CB_], a
        ld   a, [_RAM_D04B_]
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        ld   a, [_tilemap_pos_x__RAM_C8CB_]
        cpl
        inc  a
        ld   [_tilemap_pos_x__RAM_C8CB_], a
        ld   a, $00
        ld   [_tilemap_pos_y__RAM_C8CA_], a
        call _LABEL_851_
        ld   a, [_RAM_D196_]
        and  a
        ret  z
        ld   a, $01
        ld   [_tilemap_pos_x__RAM_C8CB_], a
        ld   a, [_RAM_D197_ + 1]
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        ld   a, [_tilemap_pos_x__RAM_C8CB_]
        cpl
        inc  a
        ld   [_tilemap_pos_x__RAM_C8CB_], a
        ld   a, $00
        ld   [_tilemap_pos_y__RAM_C8CA_], a
        call _LABEL_851_
        ret


_LABEL_65CE_:
    xor  a
    ld   [_RAM_D05C_], a
    ld   a, [_RAM_D04B_]
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call _LABEL_953_
    ld   b, $18
    ld   a, [_RAM_D196_]
    and  a
    jr   z, ._LABEL_65E5_
    ld   b, $14

    ._LABEL_65E5_:
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        dec  a
        cp   b
        ret  c
        ld   a, $01
        ld   [_tilemap_pos_y__RAM_C8CA_], a
        ld   a, [_RAM_D04B_]
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        cpl
        inc  a
        ld   [_tilemap_pos_y__RAM_C8CA_], a
        ld   a, $00
        ld   [_tilemap_pos_x__RAM_C8CB_], a
        call _LABEL_851_
        ld   a, [_RAM_D196_]
        and  a
        ret  z
        ld   a, $01
        ld   [_tilemap_pos_y__RAM_C8CA_], a
        ld   a, [_RAM_D197_ + 2]
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        cpl
        inc  a
        ld   [_tilemap_pos_y__RAM_C8CA_], a
        ld   a, $00
        ld   [_tilemap_pos_x__RAM_C8CB_], a
        call _LABEL_851_
        ret


_LABEL_6627_:
    xor  a
    ld   [_RAM_D05B_], a
    ld   a, [_RAM_D04B_]
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call _LABEL_953_
    ld   b, $88
    call _LABEL_688E_
    ld   a, [_RAM_D196_]
    and  a
    jr   z, ._LABEL_6641_
    ld   b, $84

    ._LABEL_6641_:
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        inc  a
        cp   b
        ret  nc
        ld   a, $01
        ld   [_tilemap_pos_y__RAM_C8CA_], a
        ld   a, [_RAM_D04B_]
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        ld   a, $00
        ld   [_tilemap_pos_x__RAM_C8CB_], a
        call _LABEL_851_
        ld   a, [_RAM_D196_]
        and  a
        ret  z
        ld   a, $01
        ld   [_tilemap_pos_y__RAM_C8CA_], a
        ld   a, [_RAM_D197_ + 2]
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        ld   a, $00
        ld   [_tilemap_pos_x__RAM_C8CB_], a
        call _LABEL_851_
        ret

paint_app_key_pressed_esc__6673_:
    ld   a, $03
    ld   [print_tile_row_pass__maybe_more__RAM_D1A7_], a
    jr   _LABEL_667F_


paint_app_save__667A_:
    ld   a, $02
    ld   [print_tile_row_pass__maybe_more__RAM_D1A7_], a
_LABEL_667F_:
    ld   a, [_RAM_D196_]
    and  a
    jp   nz, _LABEL_694E_
    ld   a, [_RAM_D04B_]
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call _LABEL_953_
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    ld   [_RAM_D073_], a
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    ld   [_RAM_D074_], a
    call oam_free_slot_and_clear__89B_
    ld   hl, _RST__18_  ; _RST__18_ = $0018
    res  7, h
    ld   a, $02
    call switch_bank_in_a_jump_hl_RAM__C920_    ; Possibly invalid
    ei
    ld   a, [print_tile_row_pass__maybe_more__RAM_D1A7_]
    cp   $03
    jp   nz, paint_app_init__6328_
    ld   a, [_RAM_D073_]
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   a, [_RAM_D074_]
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    call paint_app_some_util__6510_
    ld   de, $18B2
    ld   bc, $0000
    ld   hl, $8C40
    ld   a, $1E
    call copy_a_x_tile_patterns_from_de_add_bx16_to_hl_add_cx16__48CD_
    jp   paint_app_maybe_main_loop__63A7_


paint_app_erase__66D1_:
    ld   a, [_RAM_D196_]
    cp   $00
    jp   z, _LABEL_689D_
    ld   a, [_RAM_D04B_]
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call _LABEL_953_
    call oam_free_slot_and_clear__89B_
    ld   a, [ui_grid_menu_icon_count__RAM_D06D_]
    cp   $00
    ld   a, $03
    jr   z, ._LABEL_66F8_
    ld   a, [ui_grid_menu_icon_count__RAM_D06D_]
    cp   $03
    ld   a, $06
    jr   z, ._LABEL_66F8_
    xor  a

    ._LABEL_66F8_:
        ld   [ui_grid_menu_icon_count__RAM_D06D_], a
        add  $DB
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        xor  a
        ld   [_RAM_C8CD_], a
        call _LABEL_623_
        ld   a, b
        ld   [_RAM_D04B_], a
        ld   de, _RAM_D197_ ; _RAM_D197_ = $D197
        ld   b, $03

    ._LABEL_6710_:
        ld   a, [de]
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        push bc
        push de
        call _LABEL_953_
        call oam_free_slot_and_clear__89B_
        ld   hl, ui_grid_menu_icon_count__RAM_D06D_
        ld   a, $DB
        add  [hl]
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        call _LABEL_623_
        pop  de
        ld   a, b
        ld   [de], a
        inc  de
        pop  bc
        dec  b
        jr   nz, ._LABEL_6710_

        call input_wait_for_keypress__4B84
        call _LABEL_6765_
        jp   input_loop__63B4_


paint_app_maybe_set_pen__6739_:
    ld   a, [_RAM_D04B_]
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call _LABEL_953_
    call oam_free_slot_and_clear__89B_
    ld   a, [ui_grid_menu_escape_key_runs_last_icon__RAM_D06C_]
    cp   MENU_ESCAPE_KEY_RUNS_LAST_ICON_FALSE  ; $00
    ld   a, $03
    jr   z, ._LABEL_6758_
    ld   a, [ui_grid_menu_escape_key_runs_last_icon__RAM_D06C_]
    cp   $03  ; Unknown value MENU_ESCAPE_KEY_RUNS_LAST_ICON_...? TODO
    ld   a, $06
    jr   z, ._LABEL_6758_
    xor  a  ; MENU_ESCAPE_KEY_RUNS_LAST_ICON_FALSE

    ._LABEL_6758_:
        ld   [ui_grid_menu_escape_key_runs_last_icon__RAM_D06C_], a
        call paint_app_some_util__6510_
        call input_wait_for_keypress__4B84
        call _LABEL_6765_
        ret


_LABEL_6765_:
    call timer_wait_50msec_and_maybe_optional_audio_or_speech__289_
    ld   a, [buttons_new_pressed__RAM_D006_]
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
    jr   z, ._LABEL_6784_
    ld   hl, $9E0D

    ._LABEL_6784_:
        ld   a, $C8
        ld   [hl], a
        ret

_LABEL_6788_:
    call wait_until_vbl__92C_
    ld   a, [_RAM_D19B_]
    cp   $00
    ld   hl, $9E07
    ld   a, [_RAM_D19C_]
    jr   z, ._LABEL_67A2_
    ld   hl, $9E0D
    ld   a, [_RAM_D19D_]
    add  $CD
    jr   ._LABEL_67A4_

    ._LABEL_67A2_:
        add  $D0
    ._LABEL_67A4_:
        ld   [hl], a
        ret

paint_app_set_line_thickness__67A6_:
    xor  a
    ld   [_RAM_D19B_], a
    jr   _LABEL_67B1_

paint_app_set_draw_color__67AC_:
    ld   a, $01
    ld   [_RAM_D19B_], a
_LABEL_67B1_:
    ld   a, [_RAM_D196_]
    and  a
    jp   nz, input_loop__63B4_

    ._LABEL_67B8_:
        ld   a, [_RAM_D03A_]
        inc  a
        ld   [_RAM_D03A_], a
        and  $0F
        jr   nz, ._LABEL_67C8_
        call _LABEL_6774_
        jr   ._LABEL_67CF_

    ._LABEL_67C8_:
        xor  $08
        jr   nz, ._LABEL_67CF_
        call _LABEL_6788_

    ._LABEL_67CF_:
        call input_map_gamepad_buttons_to_keycodes__49C2_
        ld   a, [input_key_pressed__RAM_D025_]
        cp   SYS_CHAR_SALIDA  ; $2A
        jr   nz, ._LABEL_67F5_

        ld   a, [_RAM_D19B_]
        cp   $00
        ld   a, [_RAM_D073_]
        jr   z, ._LABEL_67E8_
        ld   [_RAM_D19D_], a
        jr   ._LABEL_67EB_

    ._LABEL_67E8_:
        ld   [_RAM_D19C_], a

    ._LABEL_67EB_:
        call _LABEL_6788_
        call _LABEL_685B_
        call input_wait_for_keypress__4B84
        ret

    ._LABEL_67F5_:
        cp   $2E
        jr   z, ._LABEL_67EB_
        cp   $3D
        jr   nz, ._LABEL_6808_
        call _LABEL_6817_
        call _LABEL_6788_
        call input_wait_for_keypress__4B84
        jr   ._LABEL_67B8_

    ._LABEL_6808_:
        cp   $40
        jr   nz, ._LABEL_67B8_
        call _LABEL_683A_
        call _LABEL_6788_
        call input_wait_for_keypress__4B84
        jr   ._LABEL_67B8_


_LABEL_6817_:
    ld   a, [_RAM_D19B_]
    cp   $00
    ld   a, [_RAM_D19D_]
    jr   nz, ._LABEL_6825_
    ld   a, [_RAM_D19C_]
    dec  a

    ._LABEL_6825_:
        cp   $03
        ret  z
        inc  a
        ld   b, a
        ld   a, [_RAM_D19B_]
        and  a
        ld   a, b
        jr   z, ._LABEL_6835_
        ld   [_RAM_D19D_], a
        ret

    ._LABEL_6835_:
        inc  a
        ld   [_RAM_D19C_], a
        ret


_LABEL_683A_:
    ld   a, [_RAM_D19B_]
    and  a
    ld   a, [_RAM_D19D_]
    jr   nz, ._LABEL_6847_
    ld   a, [_RAM_D19C_]
    dec  a

    ._LABEL_6847_:
        and  a
        ret  z
        dec  a
        ld   b, a
        ld   a, [_RAM_D19B_]
        and  a
        ld   a, b
        jr   z, ._LABEL_6856_
        ld   [_RAM_D19D_], a
        ret

    ._LABEL_6856_:
        inc  a
        ld   [_RAM_D19C_], a
        ret


_LABEL_685B_:
    ld   a, [_RAM_D04B_]
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call _LABEL_953_
    call oam_free_slot_and_clear__89B_
    ld   b, $88
    call _LABEL_688E_
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    inc  a
    cp   b
    jr   c, ._LABEL_6878_
    dec  b
    ld   a, b
    ld   [_tilemap_pos_y__RAM_C8CA_], a

    ._LABEL_6878_:
        ld   b, $90
        call _LABEL_688E_
        ld   a, [_tilemap_pos_x__RAM_C8CB_]
        inc  a
        cp   b
        jp   c, ._LABEL_688A_
        dec  b
        ld   a, b
        ld   [_tilemap_pos_x__RAM_C8CB_], a

    ._LABEL_688A_:
        call paint_app_some_util__6510_
        ret


_LABEL_688E_:
    ld   a, [_RAM_D192_]
    cp   $00
    ret  z
    ld   a, [_RAM_D19C_]
    dec  a
    ld   c, a
    ld   a, b
    sub  c
    ld   b, a
    ret


_LABEL_689D_:
    ld   a, [_RAM_D196_]
    bit  0, a
    jp   nz, paint_app_maybe_main_loop__63A7_
    ld   a, [_RAM_D04B_]
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call _LABEL_953_
    call oam_free_slot_and_clear__89B_
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    sub  $04
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    sub  $04
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    ld   hl, ui_grid_menu_icon_count__RAM_D06D_
    ld   a, $DB
    add  [hl]
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    ld   hl, _RAM_D197_ ; _RAM_D197_ = $D197
    ld   b, $03

    ._LABEL_68CF_:
        push bc
        push hl
        call _LABEL_623_
        pop  hl
        ld   a, b
        ldi  [hl], a
        pop  bc
        dec  b
        jr   nz, ._LABEL_68CF_

        call _LABEL_623_
        ld   a, b
        ld   [_RAM_D04B_], a    ; _RAM_D04B_ = $D04B
        ld   a, $01
        ld   [_RAM_D196_], a    ; _RAM_D196_ = $D196
        xor  a
        ld   [_RAM_D192_], a    ; _RAM_D192_ = $D192
        ld   a, $03
        call ret_after_delay_a_x_50msec_and_maybe_optional_audio_or_speech__4A72_
        jp   paint_app_maybe_main_loop__63A7_

_LABEL_68F3_:
    ld   a, [_RAM_D197_]    ; _RAM_D197_ = $D197
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
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
    jr   c, ._LABEL_6929_
    ld   [_RAM_D19D_ + 3], a    ; _RAM_D19D_ + 3 = $D1A0
    ld   a, [hl]
    ld   [_RAM_D19D_ + 1], a    ; _RAM_D19D_ + 1 = $D19E
    jr   ._LABEL_6930_

    ._LABEL_6929_:
        ld   [_RAM_D19D_ + 1], a    ; _RAM_D19D_ + 1 = $D19E
        ld   a, [hl]
        ld   [_RAM_D19D_ + 3], a    ; _RAM_D19D_ + 3 = $D1A0
    ._LABEL_6930_:
        ld   hl, _RAM_D03B_ ; _RAM_D03B_ = $D03B
        ld   a, [_tilemap_pos_y__RAM_C8CA_] ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
        add  $04
        cp   [hl]
        jr   c, ._LABEL_6944_
        ld   [_RAM_D1A1_], a    ; _RAM_D1A1_ = $D1A1
        ld   a, [hl]
        ld   [_RAM_D19D_ + 2], a    ; _RAM_D19D_ + 2 = $D19F
        jr   ._LABEL_694B_

    ._LABEL_6944_:
        ld   [_RAM_D19D_ + 2], a    ; _RAM_D19D_ + 2 = $D19F
        ld   a, [hl]
        ld   [_RAM_D1A1_], a    ; _RAM_D1A1_ = $D1A1
    ._LABEL_694B_:
        call _LABEL_6992_


_LABEL_694E_:
    ld   a, [_RAM_D197_]
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call _LABEL_953_
    ld   hl, _RAM_D197_
    ld   b, $03

    ._LABEL_695C_:
        ldi  a, [hl]
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
        push bc
        push hl
        call oam_free_slot_and_clear__89B_
        pop  hl
        pop  bc
        dec  b
        jr   nz, ._LABEL_695C_
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
        call paint_app_some_util__6510_
        ld   a, $0A
        call ret_after_delay_a_x_50msec_and_maybe_optional_audio_or_speech__4A72_
        jp   paint_app_maybe_main_loop__63A7_


_LABEL_6992_:
        ld   a, [_RAM_D19D_ + 1]    ; _RAM_D19D_ + 1 = $D19E
        ld   [_RAM_D1A2_], a    ; _RAM_D1A2_ = $D1A2
        and  $F8
        add  $07
        ld   b, a
        ld   a, [_RAM_D19D_ + 3]    ; _RAM_D19D_ + 3 = $D1A0
        cp   b
        jp   c, ._LABEL_69C6_
        jp   z, ._LABEL_69C6_
        ld   a, b
        ld   [_RAM_D1A4_], a    ; _RAM_D1A4_ = $D1A4
        call _LABEL_69D0_

    ._LABEL_69AE_:
            ld   a, [_RAM_D1A4_]    ; _RAM_D1A4_ = $D1A4
            inc  a
            ld   [_RAM_D1A2_], a    ; _RAM_D1A2_ = $D1A2
            add  $07
            ld   hl, _RAM_D19D_ + 3 ; _RAM_D19D_ + 3 = $D1A0
            cp   [hl]
            jp   nc, ._LABEL_69C6_
            ld   [_RAM_D1A4_], a    ; _RAM_D1A4_ = $D1A4
            call _LABEL_69D0_
            jr   ._LABEL_69AE_

    ._LABEL_69C6_:
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
        jr   c, ._LABEL_6A13_
        jr   z, ._LABEL_6A13_
        ld   a, b
        ld   [_RAM_D1A5_], a    ; _RAM_D1A5_ = $D1A5
        ld   a, VBL_CMD_2  ; $02
        ld   [vbl_action_select__RAM_D195_], a
        ei

    .wait_vbl_command_complete__69ED_:
        ld   a, [vbl_action_select__RAM_D195_]
        and  a
        jr   nz, .wait_vbl_command_complete__69ED_

    ._LABEL_69F3_:
        ld   a, [_RAM_D1A5_]    ; _RAM_D1A5_ = $D1A5
        inc  a
        ld   [_RAM_D1A3_], a    ; _RAM_D1A3_ = $D1A3
        add  $07
        ld   hl, _RAM_D1A1_ ; _RAM_D1A1_ = $D1A1
        cp   [hl]
        jr   nc, ._LABEL_6A13_

        ld   [_RAM_D1A5_], a    ; _RAM_D1A5_ = $D1A5
        ld   a, VBL_CMD_2  ; $02
        ld   [vbl_action_select__RAM_D195_], a
        ei

    .wait_vbl_command_complete__6A0B_:
        ld   a, [vbl_action_select__RAM_D195_]
        and  a
        jr   nz, .wait_vbl_command_complete__6A0B_

        jr   ._LABEL_69F3_

    ._LABEL_6A13_:
        ld   a, [_RAM_D1A1_]    ; _RAM_D1A1_ = $D1A1
        ld   [_RAM_D1A5_], a    ; _RAM_D1A5_ = $D1A5
        ld   a, $02
        ld   [vbl_action_select__RAM_D195_], a
        ei

    .wait_vbl_command_complete__6A1F_:
        ld   a, [vbl_action_select__RAM_D195_]
        and  a
        jr   nz, .wait_vbl_command_complete__6A1F_

        ret


; Called by VBL when vbl_action_select__RAM_D195_ == 0x01
; Used in drawing app, maybe for rendering pixels bitmapped style
vbl_routine_1__maybe_paint_app__6A26_:
        ld   a, [_RAM_D19C_]
        ld   [print_tile_row_pass__maybe_more__RAM_D1A7_], a
        ld   a, [_tilemap_pos_x__RAM_C8CB_]
        and  $07
        ld   b, $80
        jr   z, ._LABEL_6A3A_

    ._LABEL_6A35_:
        srl  b
        dec  a
        jr   nz, ._LABEL_6A35_

    ._LABEL_6A3A_:
        ld   a, [buttons_new_pressed__RAM_D006_]
        and  $F0
        ret  z
        and  $30
        jp   z, ._LABEL_6A6E_

    ._LABEL_6A45_:
        push hl
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        and  $07
        sla  a
        call add_a_to_hl__486E_
        call maybe_paint_app_util__6AAD_
        pop  hl
        ld   a, [print_tile_row_pass__maybe_more__RAM_D1A7_]    ; print_tile_row_pass__maybe_more__RAM_D1A7_ = $D1A7
        dec  a
        ld   [print_tile_row_pass__maybe_more__RAM_D1A7_], a    ; print_tile_row_pass__maybe_more__RAM_D1A7_ = $D1A7
        ret  z
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        inc  a
        ld   [_tilemap_pos_y__RAM_C8CA_], a
        and  $07
        jr   nz, ._LABEL_6A45_
        push bc
        call maybe_calc_pixelxy_tile_pattern_addr_something__6FA0_
        pop  bc
        jr   ._LABEL_6A45_

    ._LABEL_6A6E_:
        push hl
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        and  $07
        sla  a
        call add_a_to_hl__486E_
        call maybe_paint_app_util__6AAD_
        pop  hl
        ld   a, [print_tile_row_pass__maybe_more__RAM_D1A7_]    ; print_tile_row_pass__maybe_more__RAM_D1A7_ = $D1A7
        dec  a
        ld   [print_tile_row_pass__maybe_more__RAM_D1A7_], a    ; print_tile_row_pass__maybe_more__RAM_D1A7_ = $D1A7
        ret  z
        ld   a, [_tilemap_pos_x__RAM_C8CB_]
        inc  a
        ld   [_tilemap_pos_x__RAM_C8CB_], a
        and  $07
        jr   z, ._LABEL_6A94_
        srl  b
        jr   ._LABEL_6A6E_

    ._LABEL_6A94_:
        call maybe_calc_pixelxy_tile_pattern_addr_something__6FA0_
        ld   b, $80
        jr   ._LABEL_6A6E_


maybe_paint_app_util__6A9B_:
        ld   a, [_RAM_D19D_]    ; _RAM_D19D_ = $D19D
        cp   $03
        jr   nz, ._LABEL_6AA6_
        ld   a, $03
        jr   .done__6AAC_

    ._LABEL_6AA6_:
        cp   $01
        jr   nz, .done__6AAC_
        ld   a, $01
    .done__6AAC_:
        ret


maybe_paint_app_util__6AAD_:
    call maybe_paint_app_util__6A9B_
    bit  0, a
    jr   nz, ._LABEL_6ABA_
    ld   a, $FF
    xor  b
    and  [hl]
    jr   ._LABEL_6ABC_

    ._LABEL_6ABA_:
        ld   a, b
        or   [hl]

    ._LABEL_6ABC_:
        ldi  [hl], a
        call maybe_paint_app_util__6A9B_
        bit  1, a
        jr   nz, ._LABEL_6ACA_
        ld   a, $FF
        xor  b
        and  [hl]
        jr   ._LABEL_6ACC_

    ._LABEL_6ACA_:
        ld   a, b
        or   [hl]

    ._LABEL_6ACC_:
        ldi  [hl], a
        ret

paint_app_floodfill__6ACE_:
    ld   a, [_RAM_D196_]
    cp   $00
    jp   nz, paint_app_maybe_main_loop__63A7_
    ld   a, [_RAM_D04B_]
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call _LABEL_953_

    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    ld   [serial_buffer__RAM_D028_], a
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    ld   [_RAM_D029_], a
    call oam_free_slot_and_clear__89B_

    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    ld   [print_tile_row_pass__maybe_more__RAM_D1A7_ + 1], a
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    ld   [print_tile_row_pass__maybe_more__RAM_D1A7_ + 2], a
    call _LABEL_6B5F_

    ld   hl, _RAM_D19D_ + 2
    ld   a, [_RAM_D1A1_]
    add  [hl]
    rr   a
    ld   b, a
    ld   a, [print_tile_row_pass__maybe_more__RAM_D1A7_ + 1]
    inc  a
    ld   [print_tile_row_pass__maybe_more__RAM_D1A7_ + 1], a
    dec  a
    dec  a
    ld   [_RAM_D1AD_], a
    ld   a, b
    ld   [print_tile_row_pass__maybe_more__RAM_D1A7_ + 2], a
    ld   [_RAM_D1AE_], a
    xor  a
    ld   [print_tile_row_pass__maybe_more__RAM_D1A7_ + 3], a
    inc  a
    ld   [_RAM_D1AF_], a
    ld   a, [_RAM_D19D_ + 2]
    ld   [_RAM_D1AB_], a
    ld   [_RAM_D1B0_], a
    ld   a, [_RAM_D1A1_]
    ld   [_RAM_D1AC_], a
    ld   [_RAM_D1B1_], a
    ld   b, $5A
    xor  a
    ld   hl, _RAM_D1B2_

    ._LABEL_6B3A_:
        ldi  [hl], a
        dec  b
        jr   nz, ._LABEL_6B3A_

    ._LABEL_6B3E_:
        ld   a, [print_tile_row_pass__maybe_more__RAM_D1A7_ + 1]
        and  a
        jr   z, ._LABEL_6B49_
        call _LABEL_6B92_
        jr   ._LABEL_6B3E_

    ._LABEL_6B49_:
        ld   a, [serial_buffer__RAM_D028_]    ; serial_buffer__RAM_D028_ = $D028
        ld   [_tilemap_pos_x__RAM_C8CB_], a ; _tilemap_pos_x__RAM_C8CB_ = $C8CB
        ld   a, [_RAM_D029_]    ; _RAM_D029_ = $D029
        ld   [_tilemap_pos_y__RAM_C8CA_], a ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
        xor  a
        ld   [_RAM_D192_], a
        call paint_app_some_util__6510_
        jp   paint_app_maybe_main_loop__63A7_

_LABEL_6B5F_:
    ld   a, [print_tile_row_pass__maybe_more__RAM_D1A7_ + 1]
    ld   [_tilemap_pos_x__RAM_C8CB_], a ; _tilemap_pos_x__RAM_C8CB_ = $C8CB
    ld   a, [print_tile_row_pass__maybe_more__RAM_D1A7_ + 2]
    ld   [_tilemap_pos_y__RAM_C8CA_], a ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
    ld   [print_tile_row_pass__maybe_more__RAM_D1A7_], a
    xor  a
    ld   [_RAM_D03B_], a
    call _LABEL_6CAF_
    ld   a, [_RAM_D19D_ + 2]
    ld   b, a
    ld   a, [print_tile_row_pass__maybe_more__RAM_D1A7_]
    cp   b
    ld   [_RAM_D1A1_], a
    ret  z
    ld   a, [print_tile_row_pass__maybe_more__RAM_D1A7_ + 1]
    ld   [_tilemap_pos_x__RAM_C8CB_], a ; _tilemap_pos_x__RAM_C8CB_ = $C8CB
    ld   a, [print_tile_row_pass__maybe_more__RAM_D1A7_ + 2]
    inc  a
    ld   [_tilemap_pos_y__RAM_C8CA_], a ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
    call _LABEL_6D8E_
    ret


_LABEL_6B92_:
    ld   a, [_RAM_D1AB_]
    ld   [_RAM_D19D_ + 2], a
    ld   a, [_RAM_D1AC_]
    ld   [_RAM_D1A1_], a

    ._LABEL_6B9E_:
        call ._LABEL_6BD0_
        and  a
        ret  nz
        ld   a, [_RAM_D19D_ + 2]
        ld   [_RAM_D1A3_], a
        ld   a, [_RAM_D1A1_]
        ld   [_RAM_D1A5_], a
        call _LABEL_6B5F_
        ld   a, [_RAM_D19D_ + 2]
        ld   b, a
        ld   a, [_RAM_D1A1_]
        cp   b
        ret  z
        call _LABEL_6E52_
        ld   a, [print_tile_row_pass__maybe_more__RAM_D1A7_ + 3]
        and  a
        ld   a, [print_tile_row_pass__maybe_more__RAM_D1A7_ + 1]
        jr   nz, ._LABEL_6BCA_
        inc  a
        jr   ._LABEL_6BCB_

    ._LABEL_6BCA_:
        dec  a

    ._LABEL_6BCB_:
        ld   [print_tile_row_pass__maybe_more__RAM_D1A7_ + 1], a
        jr   ._LABEL_6B9E_

    ._LABEL_6BD0_:
        ld   a, [print_tile_row_pass__maybe_more__RAM_D1A7_ + 1]
        ld   [_tilemap_pos_x__RAM_C8CB_], a ; _tilemap_pos_x__RAM_C8CB_ = $C8CB
        bit  7, a
        jr   nz, ._LABEL_6BE0_
        cp   $20
        jr   c, ._LABEL_6C40_
        jr   ._LABEL_6BE4_

    ._LABEL_6BE0_:
        cp   $90
        jr   nc, ._LABEL_6C40_
    ._LABEL_6BE4_:
        ld   a, [print_tile_row_pass__maybe_more__RAM_D1A7_ + 2]
        ld   [_tilemap_pos_y__RAM_C8CA_], a ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
        bit  7, a
        jr   nz, ._LABEL_6BF4_
        cp   $18
        jr   c, ._LABEL_6C40_
        jr   ._LABEL_6BF8_

    ._LABEL_6BF4_:
        cp   $88
        jr   nc, ._LABEL_6C40_
    ._LABEL_6BF8_:
        ld   a, $01
        ld   [_RAM_D03B_], a
        call _LABEL_6CAF_
        ld   a, [print_tile_row_pass__maybe_more__RAM_D1A7_ + 1]
        ld   [_tilemap_pos_x__RAM_C8CB_], a ; _tilemap_pos_x__RAM_C8CB_ = $C8CB
        ld   a, [print_tile_row_pass__maybe_more__RAM_D1A7_ + 2]
        ld   [_tilemap_pos_y__RAM_C8CA_], a ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
        call _LABEL_6D8E_
        ld   hl, _RAM_D1A3_
        ld   a, [_RAM_D1A5_]
        cp   [hl]
        ld   a, $00
        ret  z
        ld   a, [_RAM_D19D_ + 2]
        ld   hl, _RAM_D1A3_
        sub  [hl]
        jr   nc, ._LABEL_6C24_
        jr   ._LABEL_6C46_

    ._LABEL_6C24_:
        ld   a, [_RAM_D1A5_]
        ld   hl, _RAM_D1A1_
        sub  [hl]
        jr   nc, ._LABEL_6C40_
        ld   a, [_RAM_D1A5_]
        dec  a
        add  [hl]
        rr   a
        ld   [print_tile_row_pass__maybe_more__RAM_D1A7_ + 2], a
        ld   a, [_RAM_D1A5_]
        dec  a
        ld   [_RAM_D1AB_], a
        xor  a
        ret

    ._LABEL_6C40_:
        call _LABEL_6C9C_
        ld   a, $01
        ret

    ._LABEL_6C46_:
        ld   a, [_RAM_D19D_ + 2]
        add  [hl]
        inc  a
        rr   a
        ld   [print_tile_row_pass__maybe_more__RAM_D1A7_ + 2], a
        ld   a, [_RAM_D1A3_]
        inc  a
        ld   [_RAM_D1AC_], a
        call _LABEL_6C87_
        ld   a, [_RAM_D1AD_]
        ld   [print_tile_row_pass__maybe_more__RAM_D1A7_ + 1], a
        ld   a, [_RAM_D1A5_]
        ld   hl, _RAM_D1A1_
        sub  [hl]
        jr   nc, ._LABEL_6C82_
        ld   a, [_RAM_D1A5_]
        dec  a
        add  [hl]
        rr   a
        ld   [print_tile_row_pass__maybe_more__RAM_D1A7_ + 2], a
        ld   a, [_RAM_D1A5_]
        dec  a
        ld   [_RAM_D1AB_], a
        ld   a, [_RAM_D1A1_]
        ld   [_RAM_D1AC_], a
        xor  a
        ret

    ._LABEL_6C82_:
        call _LABEL_6C9C_
        xor  a
        ret


_LABEL_6C87_:
    push hl
    ld   hl, _RAM_D20B_
    ld   de, _RAM_D206_
    ld   b, $5F

    ._LABEL_6C90_:
        ld   a, [de]
        ldd  [hl], a
        dec  de
        dec  b
        jr   nz, ._LABEL_6C90_

        xor  a
        ld   [print_tile_row_pass__maybe_more__RAM_D1A7_ + 1], a
        pop  hl
        ret


_LABEL_6C9C_:
    ld   hl, print_tile_row_pass__maybe_more__RAM_D1A7_ + 1 ; print_tile_row_pass__maybe_more__RAM_D1A7_ + 1 = $D1A8
    ld   de, _RAM_D1AD_
    ld   b, $5F

    ._LABEL_6CA4_:
        ld   a, [de]
        ldi  [hl], a
        inc  de
        dec  b
        jr   nz, ._LABEL_6CA4_

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
    jr   z, ._LABEL_6CC2_
    ._LABEL_6CBD_:
        srl  d
        dec  b
        jr   nz, ._LABEL_6CBD_

    ._LABEL_6CC2_:
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


vbl_routine_5__6CD7_:
    ld   a, [_RAM_D03B_]
    and  a
    jr   nz, ._LABEL_6D0F_
    ._LABEL_6CDD_:
        ldd  a, [hl]
        ld   b, a
        ldd  a, [hl]
        or   b
        and  d
        jr   nz, ._LABEL_6D19_
        inc  hl
        inc  hl
        ld   a, [_RAM_D19D_]    ; _RAM_D19D_ = $D19D
        bit  1, a
        jr   z, ._LABEL_6CF1_
        ld   a, [hl]
        or   d
        jr   ._LABEL_6CF7_

    ._LABEL_6CF1_:
        ld   a, $FF
        xor  d
        ld   b, a
        ld   a, [hl]
        and  b

    ._LABEL_6CF7_:
        ldd  [hl], a
        ld   a, [_RAM_D19D_]    ; _RAM_D19D_ = $D19D
        bit  0, a
        jr   z, ._LABEL_6D03_
        ld   a, [hl]
        or   d
        jr   ._LABEL_6D09_

    ._LABEL_6D03_:
        ld   a, $FF
        xor  d
        ld   b, a
        ld   a, [hl]
        and  b

    ._LABEL_6D09_:
        ldd  [hl], a
        dec  c
        jr   nz, ._LABEL_6CDD_
        jr   ._LABEL_6D19_

    ._LABEL_6D0F_:
        ldd  a, [hl]
        ld   b, a
        ldd  a, [hl]
        or   b
        and  d
        jr   z, ._LABEL_6D19_
        dec  c
        jr   nz, ._LABEL_6D0F_

    ._LABEL_6D19_:
        ld   a, c
        ld   [_RAM_D03A_], a
        ret


_LABEL_6D1E_:
    ld   a, h
    ld   [_RAM_D193_], a
    ld   a, l
    ld   [_RAM_D194_], a
    ld   a, VBL_CMD_5  ; $05
    ld   [vbl_action_select__RAM_D195_], a
    ei

    .wait_vbl_command_complete__6D2C_:
        ld   a, [vbl_action_select__RAM_D195_]
        and  a
        jr   nz, .wait_vbl_command_complete__6D2C_

        ld   a, [_RAM_D03A_]
        and  a
        jr   nz, ._LABEL_6D63_
        ld   a, $01
        ld   [_RAM_D20C_], a
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        and  $F8
        dec  a
        ld   [_tilemap_pos_y__RAM_C8CA_], a
        bit  7, a
        jr   nz, ._LABEL_6D55_
        cp   $18
        jr   nc, ._LABEL_6D55_
        ld   a, $08
        ld   [_RAM_D03A_], a
        jr   ._LABEL_6D63_

    ._LABEL_6D55_:
        push de
        call maybe_calc_pixelxy_tile_pattern_addr_something__6FA0_
        pop  de
        ld   a, $0F
        call add_a_to_hl__486E_
        ld   c, $08
        jr   _LABEL_6D1E_

    ._LABEL_6D63_:
        ld   a, [_RAM_D20C_]
        and  a
        ld   a, [_RAM_D03A_]
        ld   c, a
        jr   z, ._LABEL_6D73_
        ld   a, $08
        sub  c
        ld   c, a
        jr   ._LABEL_6D7B_

    ._LABEL_6D73_:
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        and  $07
        inc  a
        sub  c
        ld   c, a

    ._LABEL_6D7B_:
        ld   a, [_RAM_D03B_]
        and  a
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        jr   nz, ._LABEL_6D89_
        sub  c
        ld   [_RAM_D19D_ + 2], a
        ret

    ._LABEL_6D89_:
        sub  c
        ld   [_RAM_D1A3_], a
        ret


_LABEL_6D8E_:
    push de
    call maybe_calc_pixelxy_tile_pattern_addr_something__6FA0_
    pop  de
    xor  a
    ld   [_RAM_D20C_], a
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
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


vbl_routine_6__6DAB_:
    ld   a, [_RAM_D03B_]
    and  a
    jr   nz, ._LABEL_6DE3_

    ._LABEL_6DB1_:
        ldi  a, [hl]
        ld   b, a
        ldi  a, [hl]
        or   b
        and  d
        jr   nz, ._LABEL_6DED_
        dec  hl
        dec  hl
        ld   a, [_RAM_D19D_]
        bit  0, a
        jr   z, ._LABEL_6DC5_
        ld   a, [hl]
        or   d
        jr   ._LABEL_6DCB_

    ._LABEL_6DC5_:
        ld   a, $FF
        xor  d
        ld   b, a
        ld   a, [hl]
        and  b

    ._LABEL_6DCB_:
        ldi  [hl], a
        ld   a, [_RAM_D19D_]
        bit  1, a
        jr   z, ._LABEL_6DD7_
        ld   a, [hl]
        or   d
        jr   ._LABEL_6DDD_

    ._LABEL_6DD7_:
        ld   a, $FF
        xor  d
        ld   b, a
        ld   a, [hl]
        and  b

    ._LABEL_6DDD_:
        ldi  [hl], a
        dec  c
        jr   nz, ._LABEL_6DB1_
        jr   ._LABEL_6DED_

    ._LABEL_6DE3_:
        ldi  a, [hl]
        ld   b, a
        ldi  a, [hl]
        or   b
        and  d
        jr   z, ._LABEL_6DED_
        dec  c
        jr   nz, ._LABEL_6DE3_

    ._LABEL_6DED_:
        ld   a, c
        ld   [_RAM_D03A_], a
        ret


_LABEL_6DF2_:
    ld   a, h
    ld   [_RAM_D193_], a
    ld   a, l
    ld   [_RAM_D194_], a
    ld   a, VBL_CMD_6  ; $06
    ld   [vbl_action_select__RAM_D195_], a
    ei

    .wait_vbl_command_complete__6E00_:
        ld   a, [vbl_action_select__RAM_D195_]
        and  a
        jr   nz, .wait_vbl_command_complete__6E00_

        ld   a, [_RAM_D03A_]
        and  a
        jr   nz, ._LABEL_6E2E_
        ld   a, $01
        ld   [_RAM_D20C_], a
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        and  $F8
        add  $08
        ld   [_tilemap_pos_y__RAM_C8CA_], a
        bit  7, a
        jr   z, ._LABEL_6E25_
        cp   $88
        ld   a, $08
        jr   z, ._LABEL_6E2E_

    ._LABEL_6E25_:
        push de
        call maybe_calc_pixelxy_tile_pattern_addr_something__6FA0_
        pop  de
        ld   c, $08
        jr   _LABEL_6DF2_

    ._LABEL_6E2E_:
        ld   c, a
        ld   a, [_RAM_D20C_]
        and  a
        jr   nz, ._LABEL_6E3B_
        ld   a, $08
        sub  e
        sub  c
        jr   ._LABEL_6E3E_

    ._LABEL_6E3B_:
        ld   a, $08
        sub  c

    ._LABEL_6E3E_:
        ld   e, a
        ld   a, [_RAM_D03B_]
        and  a
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        jr   nz, ._LABEL_6E4D_
        add  e
        ld   [_RAM_D1A1_], a
        ret

    ._LABEL_6E4D_:
        add  e
        ld   [_RAM_D1A5_], a
        ret

_LABEL_6E52_:
    ld   a, [print_tile_row_pass__maybe_more__RAM_D1A7_ + 3]
    ld   d, a
    ld   hl, _RAM_D19D_ + 2
    ld   a, [_RAM_D1A3_]
    sub  [hl]
    add  $01
    cp   $03
    jr   c, ._LABEL_6EC3_
    call _LABEL_6C87_
    ld   a, [_RAM_D1AD_]
    ld   [print_tile_row_pass__maybe_more__RAM_D1A7_ + 1], a
    ld   a, [_RAM_D1A3_]
    cp   [hl]
    jr   nc, ._LABEL_6E8F_
    add  [hl]
    rr   a
    ld   [_RAM_D1AE_], a
    ld   a, [_RAM_D1A3_]
    ld   [_RAM_D1B0_], a
    ld   a, [_RAM_D19D_ + 2]
    ld   [_RAM_D1B1_], a

    ._LABEL_6E84_:
        ld   [_RAM_D1AB_], a
        ld   a, [_RAM_D1A1_]
        ld   [_RAM_D1AC_], a
        jr   ._LABEL_6EC3_

    ._LABEL_6E8F_:
        add  [hl]
        rr   a
        ld   [_RAM_D1AE_], a
        ld   a, [_RAM_D1AF_]
        bit  0, a
        jr   nz, ._LABEL_6EA2_
        ld   a, [_RAM_D1AD_]
        dec  a
        jr   nz, ._LABEL_6EA6_

    ._LABEL_6EA2_:
        ld   a, [_RAM_D1AD_]
        inc  a

    ._LABEL_6EA6_:
        ld   [_RAM_D1AD_], a
        ld   a, [_RAM_D1AF_]
        ld   b, $01
        xor  b
        ld   [_RAM_D1AF_], a
        ld   a, [_RAM_D19D_ + 2]
        ld   [_RAM_D1B0_], a
        ld   a, [_RAM_D1A3_]
        ld   [_RAM_D1B1_], a
        ld   a, [_RAM_D19D_ + 2]
        jr   ._LABEL_6E84_

    ._LABEL_6EC3_:
        ld   hl, _RAM_D1A1_
        ld   a, [_RAM_D1A5_]
        sub  [hl]
        add  $01
        cp   $03
        jr   c, ._LABEL_6F27_
        call _LABEL_6C87_
        ld   a, [_RAM_D1AD_]
        ld   [print_tile_row_pass__maybe_more__RAM_D1A7_ + 1], a
        ld   hl, _RAM_D1A1_
        ld   a, [_RAM_D1A5_]
        cp   [hl]
        jr   c, ._LABEL_6EF6_
        add  [hl]
        rr   a
        ld   [_RAM_D1AE_], a
        ld   a, [_RAM_D1A1_]
        ld   [_RAM_D1B0_], a
        ld   a, [_RAM_D1A5_]
        ld   [_RAM_D1B1_], a
        jr   ._LABEL_6F33_

    ._LABEL_6EF6_:
        add  [hl]
        rr   a
        ld   [_RAM_D1AE_], a
        ld   a, [_RAM_D1AF_]
        bit  0, a
        jr   nz, ._LABEL_6F09_
        ld   a, [_RAM_D1AD_]
        dec  a
        jr   ._LABEL_6F0D_

    ._LABEL_6F09_:
        ld   a, [_RAM_D1AD_]
        inc  a

    ._LABEL_6F0D_:
        ld   [_RAM_D1AD_], a
        ld   a, [_RAM_D1AF_]
        ld   b, $01
        xor  b
        ld   [_RAM_D1AF_], a
        ld   a, [_RAM_D1A5_]
        ld   [_RAM_D1B0_], a
        ld   a, [_RAM_D1A1_]
        ld   [_RAM_D1B1_], a
        jr   ._LABEL_6F33_

    ._LABEL_6F27_:
        ld   a, [_RAM_D19D_ + 2]
        ld   hl, _RAM_D1A1_
        add  [hl]
        rr   a
        ld   [print_tile_row_pass__maybe_more__RAM_D1A7_ + 2], a

    ._LABEL_6F33_:
        ld   a, [_RAM_D19D_ + 2]
        ld   [_RAM_D1AB_], a
        ld   a, [_RAM_D1A1_]
        ld   [_RAM_D1AC_], a
        ret


; TODO: Called from VBL, calculates an Tile Pattern VRAM address and loops doing something
vbl_routine_2__6F40_:
    ld   a, [_RAM_D1A2_]
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   a, [_RAM_D1A3_]
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    call maybe_calc_pixelxy_tile_pattern_addr_something__6FA0_

    ld   a, [_RAM_D1A3_]
    ld   b, a
    ld   a, [_RAM_D1A5_]
    sub  b
    inc  a
    ld   [print_tile_row_pass__maybe_more__RAM_D1A7_], a
    ld   a, [_RAM_D1A3_]
    and  $07
    sla  a
    call add_a_to_hl__486E_
    ld   a, [_RAM_D1A2_]
    and  $07
    ld   c, a
    ld   a, [_RAM_D1A4_]
    and  $07
    sub  c
    ld   b, $80
    jr   z, ._LABEL_6F7A_

    ._LABEL_6F75_:
        sra  b
        dec  a
        jr   nz, ._LABEL_6F75_

    ._LABEL_6F7A_:
        ld   a, c
        and  a
        jr   z, ._LABEL_6F83_

    ._LABEL_6F7E_:
        srl  b
        dec  c
        jr   nz, ._LABEL_6F7E_

    ._LABEL_6F83_:
        ld   a, $FF
        xor  b
        ld   b, a

    ._LABEL_6F87_:
        ld   a, b
        and  [hl]
        ldi  [hl], a
        ld   a, b
        and  [hl]
        ldi  [hl], a
        ld   a, [print_tile_row_pass__maybe_more__RAM_D1A7_]
        dec  a
        ld   [print_tile_row_pass__maybe_more__RAM_D1A7_], a
        jr   nz, ._LABEL_6F87_
        ret

; Data from 6F97 to 6F9F (9 bytes)
_LABEL_6F97_:
    ld   a, [_RAM_D04B_]
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a   ; maybe_vram_data_to_write__RAM_C8CC_ = $C8CC
    call _LABEL_953_


; TODO - might be for a direct pixel drawing mode
;
;
; - Indexing something into Tile Pattern VRAM
;
; - Returns resulting address in HL
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
; paint_app_help_menu_show__6FED_:
paint_app_help_menu_show__6FED_:
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
        call memcopy_in_RAM__C900_ ; Code is loaded from _memcopy__7D3_

        ; Make a textbox
        ld   bc, $0104             ; Start at 1,4 (x,y) in tiles
        ld   de, $120E             ; Width, Height in tiles
        ld   a, FONT_TEXTBOX_START ; $F2
        ld   hl, _TILEMAP0         ; $9800
        call display_textbox_draw_xy_in_bc_wh_in_de_st_id_in_a__48EB_

        ; Draw Top of Help Menu text (AYUDA) on top of text box
        ld   de, _string_message__paint_app_help_header__709F_ ; $709F
        ld   hl, $0804    ; Start at 8,4 (x,y) in tiles
        ld   c, PRINT_NORMAL  ; $01
        call render_string_at_de_to_tilemap0_xy_in_hl__4A46_

        ; Draw 10 lines of help text
        ld   de, _string_message__paint_app_help_text__70A5_ ; $70A5
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
        call input_wait_for_keypress__4B84
        call _LABEL_7721_
        call input_wait_for_keypress__4B84

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
        call paint_app_some_util__6510_
        ret


        ; Strings for Drawing App Help Menu
        ; Used by paint_app_help_menu_show__6FED_
        _string_message__paint_app_help_header__709F_:
        ; "AYUDA" (Help)
        db $81, $99, $95, $84, $81, $00

        _string_message__paint_app_help_text__70A5_:
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
