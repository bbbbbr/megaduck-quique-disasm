
; SECTION "rom0_keyboard_C8D", ROM0[$0C8D]

; ===== Keyboard reading and processing functions =====


; Request keyboard input and handle the response
;
; Destroys A, HL (maybe others in calls)
input_read_keys__C8D_:
    ; Save current interrupt enables then turn all off
    ldh  a, [rIE]
    ld   [_rIE_saved_serial__RAM_D078_], a
    xor  a
    ldh  [rIE], a
    ; TODO ... ? Make a request for ??
    ld   a, SYS_CMD_READ_KEYS_MAYBE ; $00  ; ? Same or different as SYS_CMD_INIT_SEQ_REQUEST ?
    ld   [serial_tx_data__RAM_D023_], a
    call serial_io_send_byte__B64_
    call serial_io_wait_receive_with_timeout__B8F_

    ; Fail if serial RX timed out(z), if successful(nz) continue
    and  a
    jr   z, .req_key_failed_so_send04__CB9_
    ; Fail if RX byte was zero
    ld   a, [serial_rx_data__RAM_D021_]

    cp   SYS_REPLY_READ_FAIL_MAYBE ; $00
    jr   z, .req_key_failed_so_send04__CB9_

    cp   SYS_REPLY_MAYBE_KBD_START  ; $0E  ; TODO: Verify
    jr   z, .rx_byte_1_ok__CB0_

    jr   nc, .req_key_failed_so_send04__CB9_

    ; Save 1st RX byte and wait for 2nd RX Byte
    .rx_byte_1_ok__CB0_:
        ld   [serial_io_checksum_calc__RAM_D026_], a
        call serial_io_wait_receive_with_timeout__B8F_
        and  a
        jr   nz, .rx_byte_2_ok__CC8_

    .req_key_failed_so_send04__CB9_:
        ld   a, SYS_CHAR_NO_DATA_OR_KEY  ; $FF
        ld   [input_key_pressed__RAM_D025_], a
        ld   a, SYS_CMD_ABORT_OR_FAIL  ; $04 ; TODO: Maybe a failed/reset/cancel input system command SYS_CMD
        ld   [serial_tx_data__RAM_D023_], a
        call serial_io_send_byte__B64_
        jr   .done_restore_int__call_TODO_and_return__D06_

    ; Continue reading keyboard reply bytes
    .rx_byte_2_ok__CC8_:
        ; Save RX input byte #2 and add it to checksum
        ld   a, [serial_rx_data__RAM_D021_]
        ld   [input_key_modifier_flags__RAM_D027_], a
        ld   hl, serial_io_checksum_calc__RAM_D026_
        add  [hl]
        ld   [hl], a

        ; Wait for RX input byte #3
        ; If successful then save it and add to checksum
        call serial_io_wait_receive_with_timeout__B8F_
        and  a
        jr   z, .req_key_failed_so_send04__CB9_
        ld   a, [serial_rx_data__RAM_D021_]
        ld   [input_key_pressed__RAM_D025_], a
        ld   hl, serial_io_checksum_calc__RAM_D026_
        add  [hl]
        ld   [serial_io_checksum_calc__RAM_D026_], a

        ; Wait for RX input byte #4
        ; If successful then verify it against the
        ; calculated checksum in serial_io_checksum_calc__RAM_D026_
        ;
        ; Make sure RX byte #4 == (((#1 + #2 + #3) XOR 0xFF) + 1) [two's complement]
        ; I.E: (#4 + #1 + #2 + #3) == 0x100 -> unsigned 8 bit overflow -> 0x00
        call serial_io_wait_receive_with_timeout__B8F_
        and  a
        jr   z, .req_key_failed_so_send04__CB9_
        ld   a, [serial_rx_data__RAM_D021_]
        ld   hl, serial_io_checksum_calc__RAM_D026_
        add  [hl]
        jr   nz, .req_key_failed_so_send04__CB9_

        ; TODO: Send a command byte. Something like DONE or ACK for a SYS_CMD?
        ld   a, SYS_CMD_DONE_OR_OK ; $01
        ld   [serial_tx_data__RAM_D023_], a
        call serial_io_send_byte__B64_
        call input_process_key_codes_and_flags__D0F_
        ; Save key for later use with Key Repeat
        ld   a, [input_key_pressed__RAM_D025_]
        ld   [input_prev_key_pressed__RAM_D181_], a

    .done_restore_int__call_TODO_and_return__D06_:
        ld   a, [_rIE_saved_serial__RAM_D078_]
        ldh  [rIE], a
        call _LABEL_DFC_
        ret

; Processing of the received Key Codes
input_process_key_codes_and_flags__D0F_:
    ; Check if Key Repeat flag is enabled
    ld   a, [input_key_modifier_flags__RAM_D027_]
    bit  SYS_KBD_FLAG_KEY_REPEAT_BIT, a  ; 0, a
    jp   nz, .input_handle_key_repeat_flag__DD5_

    ; Check if Left PrintScreen flag is set
    ; If it isn't then continue processing
    ; (Right PrintScreen generates an actual scancode)
    ld   a, [input_key_modifier_flags__RAM_D027_]
    bit  SYS_KBD_FLAG_PRINTSCREEN_LEFT_BIT, a  ; 3, a
    jr   z, .continue_processing_key_codes__D24_

    ld   a, SYS_CHAR_PRINTSCREEN  ; $2F
    ld   [input_key_pressed__RAM_D025_], a
    ret

    .continue_processing_key_codes__D24_:
        ld   a, [input_key_pressed__RAM_D025_]
        and  a
        jp   z, .invalid_key_or_no_data__DCF_

        ; Keyboard keys codes must be 0x80+
        bit  SYS_KBD_KEYCODE_BASE_BIT, a  ; 7, a
        jp   z, .not_a_keyboard_key__DBD_

        ; If it's 0xF0 or higher don't process it
        ; Note: 0xF0+ is filtered out from repeat after the jump
        cp   (SYS_KBD_CODE_LAST_KEY + 1)  ; $F0
        jp   nc, .done_and_save_key_for_repeat__DC5_

        ; Strip 0x80 base offset from key code
        ; Then use it as A LUT index to translate
        ; from key code -> to system char
        ;
        ; B then holds translated system char
        res  SYS_KBD_KEYCODE_BASE_BIT, a  ; 7, a
        ld   hl, KEYCODE_TO_SYS_CHAR_LUT__0EBF_  ; $0EBF
        call add_a_to_hl__486E_
        ld   a, [hl]
        ld   [input_key_pressed__RAM_D025_], a
        ld   b, a

        ; If SHIFT, CAPS LOCK or PRINTSCREEN are not set then processing is done
        ld   a, [input_key_modifier_flags__RAM_D027_]
        and  (SYS_KBD_FLAG_PRINTSCREEN_LEFT | SYS_KBD_FLAG_SHIFT | SYS_KBD_FLAG_CAPSLOCK)  ; $0E
        jr   z, .done_and_save_key_for_repeat__DC5_

        ; Now, if SHIFT or CAPS LOCK are not set then processing is done  :)
        ld   a, [input_key_modifier_flags__RAM_D027_]
        and  (SYS_KBD_FLAG_SHIFT | SYS_KBD_FLAG_CAPSLOCK)  ; $06
        jr   z, .done_and_save_key_for_repeat__DC5_

        ; Process SHIFT key if it's set
        bit  SYS_KBD_FLAG_SHIFT_BIT, a  ; 2, a
        jr   nz, .handle_shift_modifier__D68_

        ; At this point, CAPS LOCK must be set and SHIFT is *NOT*
        ;
        ; Reload translated system char code from B
        ; Make sure it could be a Letter (0x80+)
        ld   a, b
        bit  SYS_CHAR_LETTERS_BASE_BIT, a  ; 7, a
        jr   z, .done_and_save_key_for_repeat__DC5_

        ; Only apply CAPS LOCK to lower-case (a-z).
        ; If it's anything else (upper-case A-Z, numbers, symbol, etc)
        ; then no need to apply CAPS LOCK. Processing is done
        cp   SYS_CHAR_LOWERCASE_FIRST  ; $A1
        jr   c, .done_and_save_key_for_repeat__DC5_
        cp   (SYS_CHAR_LOWERCASE_LAST + 1)  ; $BE
        jr   nc, .done_and_save_key_for_repeat__DC5_

        ; Otherwise fall-through and translate to upper-case

    .convert_a_to_z_to_uppercase__D61_:
        ; A holds translated system char code (from key code)
        ;
        ; Translates a-z (0xA1+) to A-Z (0x81+) by clearing bit 5
        res  SYS_CHAR_A_TO_Z_LOWER_CASE_BIT, a  ; 5, a
        ld   [input_key_pressed__RAM_D025_], a
        jr   .done_and_save_key_for_repeat__DC5_

    .handle_shift_modifier__D68_:
        ; B holds translated system char code (from key code)
        ;
        ; If CAPS LOCK is not set then do SHIFT only processing
        bit  SYS_KBD_FLAG_CAPSLOCK_BIT, a  ; 1, a
        jr   z, .shift_now_check_if_sqrt_key__D86_

        ; At this point it's (SHIFT + CAPS LOCK)
        ; Skip to further processing for anything not Square Root Key
        ld   a, b
        cp   SYS_CHAR_SQRT  ; $43
        jr   nz, .shift_plus_capslock_check_is_letter_and_lowercase__D78_

        ; Not shown on keycap, but Square Root + SHIFT = Caret
        ; Apply translation and processing is done
        ld   a, SYS_CHAR_UP_CARET  ; $70
        ld   [input_key_pressed__RAM_D025_], a
        jr   .done_and_save_key_for_repeat__DC5_

    .shift_plus_capslock_check_is_letter_and_lowercase__D78_:
        ; A holds translated system char code (from key code)
        ;
        ; If < 0x80 it's in symbols and special chars range
        ; and so is not a Letter (lower-case a-z)
        bit  SYS_CHAR_LETTERS_BASE_BIT, a  ; 7, a
        jr   z, .shift_now_check_if_sqrt_key__D86_

        ; If it's lower-case (a-z) then processing is done
        ; since (SHIFT + CAPSLOCK) negate each other when both on
        cp   SYS_CHAR_LOWERCASE_FIRST  ; $A1
        jr   c, .shift_now_check_if_sqrt_key__D86_
        cp   (SYS_CHAR_LOWERCASE_LAST + 1)  ; $BE
        jr   nc, .shift_now_check_if_sqrt_key__D86_
        jr   .done_and_save_key_for_repeat__DC5_

    ; (Based on special handling here + elsewhere and lack of keycap label,
    ; perhaps shift + sqrt -> caret got patched in late in
    ; system production. Seems like it ccould have just been
    ; added to symbol+shift LUT instead.)
    .shift_now_check_if_sqrt_key__D86_:
        ; B holds translated system char code (from key code)
        ld   a, b
        cp   SYS_CHAR_SQRT  ; $43
        jr   nz, .shift_and_is_not_sqrt_key__D92_

        ; Not shown on keycap, but Square Root + SHIFT = Caret
        ; Apply translation and processing is done
        ld   a, SYS_CHAR_UP_CARET  ; $70
        ld   [input_key_pressed__RAM_D025_], a
        jr   .done_and_save_key_for_repeat__DC5_

    .shift_and_is_not_sqrt_key__D92_:
        ; A holds translated system char code (from key code)
        ;
        ; If < 0x80 it's in symbols and special chars range
        bit  SYS_CHAR_LETTERS_BASE_BIT, a  ; 7, a
        jr   z, .check_symbol_key_has_shift_alternative__DAF_

        ; If it's >= 0x80 and not lower-case (a-z)
        ; then continue on for additional SHIFT processing.
        cp   SYS_CHAR_LOWERCASE_FIRST  ; $A1
        jr   c, .process_shift_for_symbols__DA0_
        cp   (SYS_CHAR_LOWERCASE_LAST + 1)  ; $BE
        jr   nc, .process_shift_for_symbols__DA0_
        ; Otherwise convert (a-z) to to upper-case
        jr   .convert_a_to_z_to_uppercase__D61_

    .process_shift_for_symbols__DA0_:
        ; A holds translated system char code (from key code)
        ;
        ; If (( < SYS_CHAR_1) && ( > SYS_CHAR_9)) then check for shift version
        cp   SYS_CHAR_1  ; $C1
        jr   c, .check_symbol_key_has_shift_alternative__DAF_
        ;
        cp   (SYS_CHAR_9 + 1)  ; SYS_CHAR_PLUS or higher  ; $CA
        jr   nc, .check_symbol_key_has_shift_alternative__DAF_

        ; If it's within (SYS_CHAR_1 - SYS_CHAR_9)
        ; Then subtract to translate it to row's matching SHIFT keys
        ; which are (SYS_CHAR_EXCLAMATION - SYS_CHAR_PAREN_RIGHT)
        sub  SYS_CHAR_NUM_TO_SHIFT_SYM_OFFSET ; $5E
        ld   [input_key_pressed__RAM_D025_], a
        jr   .done_and_save_key_for_repeat__DC5_

    ; Maps SYS_CHAR format symbol keys to their matching
    ; SHIFT equivalent on the keyboard
    ;
    ; If no match is found in LUT then the key is used as-is
    ; from the previously stored value to [input_key_pressed__RAM_D025_]
    ; and processing is done
    .check_symbol_key_has_shift_alternative__DAF_:
        ; B holds Non-Shift System Char symbol to match
        ld   c, SYS_CHAR_SYMBOLS_SHIFT_LUT__LEN  ; $0B
        ld   hl, SYS_CHAR_SYMBOLS_SHIFT_LUT__F2F_
        .symbol_lookup_loop__DB4_:
            ; Check for match with SYS_CHAR in B
            ldi  a, [hl]
            cp   b
            ; When there is a match it returns hl at the address 1 byte after
            ; *after* the matching symbol. This will be the SHIFT equivalent
            jr   z, .load_at_hl_to_key_pressed__DC1_
            inc  hl
            dec  c
            jr   nz, .symbol_lookup_loop__DB4_
            ret

    ; Not sure if this gets used anywhere outside processing
    .not_a_keyboard_key__DBD_:
        ld   a, SYS_KBD_CODE_MAYBE_RX_NOT_A_KEY  ; $F6
        jr   .load_reg_a_to_key_pressed__DC2_

    .load_at_hl_to_key_pressed__DC1_:
        ldi  a, [hl]

    .load_reg_a_to_key_pressed__DC2_:
        ld   [input_key_pressed__RAM_D025_], a

    .done_and_save_key_for_repeat__DC5_:
        ld   a, [input_key_pressed__RAM_D025_]
        ; If it's 0xF0 or higher it's not a keyboard key
        ; So don't save it for repeat
        cp   (SYS_KBD_CODE_LAST_KEY + 1)  ; $F0
        ret  nc
        ld   [input_prev_key_pressed__RAM_D181_], a
        ret

    .invalid_key_or_no_data__DCF_:
        ld   a, SYS_CHAR_NO_DATA_OR_KEY  ; $FF
        ld   [input_key_pressed__RAM_D025_], a
        ret

    ; Called when the keyboard repeat flag SYS_KBD_FLAG_KEY_REPEAT
    ; is detected in input_key_modifier_flags__RAM_D027_
    ; - Loads to input_key_pressed__RAM_D025_
    .input_handle_key_repeat_flag__DD5_:
        ld   a, [input_prev_key_pressed__RAM_D181_]
        cp   SYS_CHAR_UP_RIGHT  ; $CA
        jp   z, .load_repeat_key_to_input__DF8_

        cp   SYS_CHAR_DOWN_RIGHT  ; $CB
        jp   z, .load_repeat_key_to_input__DF8_

        cp   SYS_CHAR_DOWN_LEFT  ; $CC
        jp   z, .load_repeat_key_to_input__DF8_

        cp   SYS_CHAR_UP_LEFT  ; $CD
        jp   z, .load_repeat_key_to_input__DF8_

        ; Note: Is their order of testing correct?
        ; Block (>= Piano) should have been above this
        ; if they wanted to block repeat for it...
        cp   SYS_CHAR_MEMORY_PLUS  ; $41
        jr   c, .load_repeat_key_to_input__DF8_

        cp   (SYS_CHAR_LAST_PIANO + 1)  ; $18
        jr   nc, .repeat_blocked__DF6_

        jr   .load_repeat_key_to_input__DF8_

    .repeat_blocked__DF6_:
        ld   a, SYS_CHAR_NO_DATA_OR_KEY  ; $FF

    .load_repeat_key_to_input__DF8_:
        ld   [input_key_pressed__RAM_D025_], a
        ret



; TODO: Some additional keyboard processing?

_LABEL_DFC_:
    ld   a, [input_key_pressed__RAM_D025_]
    cp   $65
    jr   nz, _LABEL_E0A_
    ld   a, $9F
    ld   [input_key_pressed__RAM_D025_], a
    jr   _LABEL_E37_

_LABEL_E0A_:
    cp   $2B  ; TODO: what is this value? Missing in SYS_CHAR_...
    jr   nz, _LABEL_E1C_

    ld   a, [input_key_modifier_flags__RAM_D027_]
    bit  SYS_KBD_FLAG_SHIFT_BIT, a  ; 2, a
    jr   z, _LABEL_E37_

    ld   a, $D2
    ld   [input_key_pressed__RAM_D025_], a
    jr   _LABEL_E37_

_LABEL_E1C_:
    ld   a, [input_key_pressed__RAM_D025_]
    cp   $DC
    jr   nz, _LABEL_E37_

    ; Looks Negate Caps Lock and Shift negate each other
    ld   a, [input_key_modifier_flags__RAM_D027_]
    ld   c, a
    and  SYS_KBD_FLAG_CAPSLOCK  ; $02
    sla  a
    ld   b, a
    ld   a, c
    and  SYS_KBD_FLAG_SHIFT  ; $04
    xor  b
    jr   z, _LABEL_E37_

    ; TODO: Load SYS_CHAR_N_TILDE ? hmm...
    ld   a, $D5
    ld   [input_key_pressed__RAM_D025_], a
_LABEL_E37_:
    ld   a, [input_key_pressed__RAM_D025_]
    ld   c, a
    ld   a, [_RAM_D226_]    ; _RAM_D226_ = $D226
    cp   $AA
    jr   z, _LABEL_E70_
    xor  a
    ld   [_RAM_D221_], a    ; _RAM_D221_ = $D221
    ld   [_RAM_D226_], a    ; _RAM_D226_ = $D226
    ld   hl, $0EA0
_LABEL_E4C_:
    ldi  a, [hl]
    and  a
    jr   z, _LABEL_E97_
    cp   c
    jr   nz, _LABEL_E9C_
    ld   a, [_RAM_D221_]    ; _RAM_D221_ = $D221
    cp   $01
    jr   z, _LABEL_E8B_
    ld   e, l
    ld   d, h
    ld   hl, _RAM_D222_ ; _RAM_D222_ = $D222
    ld   [hl], b
    inc  hl
    ld   [hl], c
    inc  hl
    ld   [hl], d
    inc  hl
    ld   [hl], e
    inc  hl
    ld   a, $AA
    ld   [hl], a
_LABEL_E6A_:
    ld   a, SYS_CHAR_NO_DATA_OR_KEY  ; $FF
    ld   [input_key_pressed__RAM_D025_], a
    ret

_LABEL_E70_:
    ld   a, [input_key_pressed__RAM_D025_]
    cp   SYS_CHAR_NO_DATA_OR_KEY  ; $FF
    ret  z
    ld   hl, _RAM_D222_ ; _RAM_D222_ = $D222
    ld   b, [hl]
    inc  hl
    ld   c, [hl]
    inc  hl
    ld   d, [hl]
    inc  hl
    ld   e, [hl]
    ld   l, e
    ld   h, d
    ld   a, $01
    ld   [_RAM_D221_], a    ; _RAM_D221_ = $D221
    ld   a, [input_key_pressed__RAM_D025_]
    ld   b, a
_LABEL_E8B_:
    ld   a, c
    cp   b
    jr   z, _LABEL_E6A_
    ldi  a, [hl]
    cp   b
    jr   nz, _LABEL_E9D_
    ld   a, [hl]
    ld   [input_key_pressed__RAM_D025_], a
_LABEL_E97_:
    xor  a
    ld   [_RAM_D226_], a    ; _RAM_D226_ = $D226
    ret

