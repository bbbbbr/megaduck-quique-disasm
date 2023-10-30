
    debug_log_serial_keyboard_data:
        cp   a, $FF  ; Skip printing when main character is FF
        ret  z

        push bc
        push de
        push hl

        push af
        ld   a, [__debug_buf_ptr]
        ld   b, a
        dec  b
        ld   hl, (32 * 0) + 8 ; ROW 0, COL 8
        ld   de,  32
        .print_sys_key_offset_loop:
            add   hl, de
            dec   b
            jr    nz, .print_sys_key_offset_loop

        ld   d, h
        ld   e, l
        pop  af
        call debug_print_a_in_hex


        ld   de, (32 * 0) + 12 ; ROW 0, COL 8
        ld   a, [__debug_buf_ptr]
        call debug_print_a_in_hex


        ld   a, [__debug_buf_ptr]  ; Number of values to print
        ld   c, a
        ld   de, (32 * 0) + 4; Row number 2+, COL 4
        ld   hl, ____debug_buf__addr_start ; first var in set to display
        .print_vars_loop:
            ld   a, [hl+]
            call debug_print_a_in_hex

            ; Increment Row in DE
            ld   a, 32
            add  e
            ld   e, a
            ld   a, 0
            adc  d
            ld   d, a

            dec  c
            jr   NZ, .print_vars_loop

        pop hl
        pop de
        pop bc
        ret

    ; tilemap offset: DE
    ; value to print: a
    debug_print_a_in_hex:
        push hl
        push de
        push bc
        push af
        call wait_until_vbl__92C_

        ld   hl, _TILEMAP0
        add  hl, de
        pop  af

        ld   c, a  ; save low nybble
        swap a     ; print high nybble first
        ld   b, 2

        .print_loop
        and  a, $0F
        cp   a, $0A
        jr   NC, .A_to_F

        ; Handle 0-9
        add  FONT_0
        jr   .write_char

        .A_to_F
            sub  a, $0A
            add  FONT_A

        .write_char:
            ldi   [hl], a  ; write char and move to next map tile
            ld     a, c
            dec    b
            jr    NZ, .print_loop

        .done:
        pop bc
        pop de
        pop hl
        ret
