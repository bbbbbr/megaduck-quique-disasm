
; Actually in 32K Bank 0 Upper 16K, but 32K banking not supported in RGBDS
; SECTION "rom0_app_worddrawings_5E55", ROMX[$5E55], BANK[$1]


; This App may use graphics data in other ROM banks

maybe_app_worddrawings_init__5E55_:
    ldh  a, [rLCDC]
    and  ~LCDCF_OBJ16  ; $FD  ; Turn off 8x16 sprites -> 8x8 sprites
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
        ; Does execution fall through here to input processing below?

    ; Is this only used for the "worddrawings" app?
    _LABEL_5E9A_:
        call input_map_gamepad_buttons_to_keycodes__49C2_
        call _LABEL_6230_
        ld   a, [input_key_pressed__RAM_D025_]
        cp   SYS_CHAR_SALIDA  ; $2A
        jr   nz, _LABEL_5EAE_

        call _LABEL_6265_
        call input_wait_for_keypress__4B84
        ret

        _LABEL_5EAE_:
            cp   SYS_CHAR_PRINTSCREEN  ; $2F
            jr   nz, _LABEL_5EB7_
            call call_printscreen_in_32k_bank_2__522_
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
            call ret_after_delay_a_x_50msec_and_maybe_optional_audio_or_speech__4A72_
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
            call input_wait_for_keypress__4B84
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

            ; TODO: Check whether constants here should be switched from FONT_* to SYS_CHAR_*

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
            call switch_bank_in_a_jump_hl_RAM__C920_
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
            call switch_bank_in_a_jump_hl_RAM__C920_
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
            call switch_bank_in_a_jump_hl_RAM__C920_
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
            call input_wait_for_keypress__4B84
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
    ld   de, rom_str__ESCRIBIR_LA_PALABRA__62CF_
    ld   c, $00
    ld   b, $02
    ld   hl, $0103
    call _LABEL_4944_
    ld   de, rom_str__CLAVE__62E3_
    ld   c, $28
    ld   b, $02
    ld   hl, $0606
    call _LABEL_4944_
    ld   de, rom_str__PRESIONAR_ENTRADA__62ED_
    ld   c, $50
    ld   b, $02
    ld   hl, $020A - 1
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
    call switch_bank_memcopy_hl_to_de_len_bc_RAM__C960_
    pop  hl
    push hl
    call switch_bank_read_byte_at_hl_RAM__C980_
    call wait_until_vbl__92C_
    call display_screen_off__94C_
    ld   a, [_rombank_readbyte_result__D6E7_]
    bit  7, a
    jr   z, _LABEL_615A_
    ld   hl, $8800
    ld   bc, $0340
    call switch_bank_memcopy_hl_to_de_len_bc_RAM__C960_
_LABEL_615A_:
    pop  hl
    inc  hl
    ld   a, [_rombank_readbyte_result__D6E7_]
    ld   b, $10
    call multiply_a_x_b__result_in_de__4853_
    add  hl, de
    call switch_bank_read_byte_at_hl_RAM__C980_
    ld   a, [_rombank_readbyte_result__D6E7_]
    ld   [_RAM_D03A_], a
    ld   b, a
    inc  hl
    call switch_bank_read_byte_at_hl_RAM__C980_
    ld   a, [_rombank_readbyte_result__D6E7_]
    ld   [print_serial_etc_something__RAM_D1A7_], a    ; print_serial_etc_something__RAM_D1A7_ = $D1A7
    call multiply_a_x_b__result_in_de__4853_
    push de
    pop  bc
    inc  hl
    push hl
    pop  de
    ld   hl, $D800
    call switch_bank_memcopy_hl_to_de_len_bc_RAM__C960_
    ld   a, [_RAM_D03A_]
    ld   b, a
    ld   a, $14
    sub  b
    srl  a
    ld   b, a
    ld   a, [print_serial_etc_something__RAM_D1A7_]    ; print_serial_etc_something__RAM_D1A7_ = $D1A7
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
    ld   a, [print_serial_etc_something__RAM_D1A7_]    ; print_serial_etc_something__RAM_D1A7_ = $D1A7
    dec  a
    ld   [print_serial_etc_something__RAM_D1A7_], a    ; print_serial_etc_something__RAM_D1A7_ = $D1A7
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
    ld   de, rom_str__PALABRA_DESCONOCIDA_6312_
    ld   a, [_RAM_D6E3_]
    bit  7, a
    jr   nz, _LABEL_6291_
    ld   de, ENTRADA_NO_VALIDA__62FF_
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
    call input_wait_for_keypress__4B84
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
rom_str__ESCRIBIR_LA_PALABRA__62CF_:
; "ESCRIBIR LA PALABRA" (Write the word)
db $85, $93, $83, $92, $89, $82, $89, $92, $BE, $8C, $81, $BE, $90, $81, $8C, $81
db $82, $92, $81, $00

; Data from 62E3 to 62EC (10 bytes)
rom_str__CLAVE__62E3_:
; Text string "Clave" (Clue)
db $64, $83, $8C, $81, $96, $85, $64, $BE, $99, $00

; Data from 62ED to 62FE (18 bytes)
rom_str__PRESIONAR_ENTRADA__62ED_:
; Text string  "PRESIONAR ENTRADA" (Press Enter)
db $90, $92, $85, $93, $89, $8F, $8E, $81, $92, $BE, $85, $8E, $94, $92, $81, $84
db $81, $00

; Data from 62FF to 6311 (19 bytes)
ENTRADA_NO_VALIDA__62FF_:
; Text string  "ENTRADA NO VALIDA" (Entry is not valid)
db $BE, $85, $8E, $94, $92, $81, $84, $81, $00, $8E, $8F, $BE, $96, $81, $8C, $89
db $84, $81, $00

; Data from 6312 to 6327 (22 bytes)
rom_str__PALABRA_DESCONOCIDA_6312_:
; Text string  "PALABRA DESCONOCIDA" (Unknown word)
db $BE, $BE, $90, $81, $8C, $81, $82, $92, $81, $00, $84, $85, $93, $83, $8F, $8E
db $8F, $83, $89, $84, $81, $00
