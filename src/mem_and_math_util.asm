
; SECTION "rom0_mem-and_math_util_481A", ROM0[$481A]

; ===== Memory and Math Utility functions =====


memcopy_16_bytes_from_copy_buffer__RAM_DCF0_to_hl__481A_:
    ld   de, copy_buffer__RAM_DCF0_
    ld   b, $10  ; 16 bytes
memcopy_b_bytes_from_de_to_hl__481F_:
    ld   a, [de]
    ldi  [hl], a
    inc  de
    dec  b
    jr   nz, memcopy_b_bytes_from_de_to_hl__481F_
    ret


memcopy_16_bytes_from_hl_to_copy_buffer__RAM_DCF0__4826_:
    ld   de, copy_buffer__RAM_DCF0_
    ld   b, $10  ; 16 bytes
; Size in  : B
; Dest in  : DE
; Source in: HL
memcopy_b_bytes_from_hl_to_de__482B_:
    ldi  a, [hl]
    ld   [de], a
    inc  de
    dec  b
    jr   nz, memcopy_b_bytes_from_hl_to_de__482B_
    ret


; Divides DE / H and provides result + Remainder
;
; - Result TRUNC(DE / H) in: BC
; - Result DE % H in       : L
;
; Destroys A, BC, DE, L
divide_de_by_h_result_in_bc_remainder_in_l__4832_:
    ld   bc, $0000
    ld   l, $00
    ld   a, h
    or   a
    jr   z, .done__4852_

    .subtract_loop__483B_:
        ld   a, e
        sub  h
        ld   e, a
        ld   a, d
        sbc  $00
        ld   d, a
        jr   c, .check_remainder__484C_

        inc  c
        jr   nz, .subtract_loop__483B_

        inc  b
        ld   c, $00
        jr   .subtract_loop__483B_

    .check_remainder__484C_:
        ld   a, e
        or   a
        ; If e is zero there is no remainder, use previously loaded 0x00 in L
        jr   z, .done__4852_

        ; Otherwise calculate remainder as e + h
        add  h
        ld   l, a
    .done__4852_:
        ret


; Multiply values in registers A x B
;
; - Result in: DE
;
; - Destroys C only if both A and B are non-zero
multiply_a_x_b__result_in_de__4853_:
    ld   d, $00
    ld   e, $00
    or   a
    ; Return with result 0 if A is zero
    jr   z, ._multiply_done_486D_

        push bc
        ld   c, a
        ld   a, b
        or   a
        ld   a, c
        pop  bc
        ; Return with result 0 if B is zero
        jr   z, ._multiply_done_486D_

        ld   c, a
    ._loop_multiply__4863_:
        ; Add DE + A (starts with zero) for B times
        ld   a, e
        add  c
        ld   e, a
        ld   a, d
        adc  $00
        ld   d, a
        dec  b
        jr   nz, ._loop_multiply__4863_

    ._multiply_done_486D_:
        ret


; Adds A to HL, result in HL
;
add_a_to_hl__486E_:
    add  l
    ld   l, a
    ld   a, h
    adc  $00
    ld   h, a
    ret
