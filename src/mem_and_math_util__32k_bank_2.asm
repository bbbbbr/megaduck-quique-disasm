
; ===== Memory and Math Utility functions =====
; 32K Bank 2

; 32K Bank addr: $02:28F1 (16K Bank addr: $04:68F1)
memcopy_16_bytes_from_copy_buffer__RAM_DCF0_to_hl__ROM_32K_Bank2_28F1_:
    ld   de, copy_buffer__RAM_DCF0_
    ld   b, $10  ; 16 bytes
; 32K Bank addr: $02:28F6 (16K Bank addr: $04:68F6)    
memcopy_b_bytes_from_de_to_hl__ROM_32K_Bank2_28F6_:
    .copy_loop
    ld   a, [de]
    ldi  [hl], a
    inc  de
    dec  b
    jr   nz, .copy_loop
    ret


; 32K Bank addr: $02:28FD (16K Bank addr: $04:68FD)
memcopy_16_bytes_from_hl_to_copy_buffer__RAM_DCF0__ROM_32K_Bank2_28FD_:
    ld   de, copy_buffer__RAM_DCF0_
    ld   b, $10  ; 16 bytes
; Size in  : B
; Dest in  : DE
; Source in: HL
; 32K Bank addr: $02:2902 (16K Bank addr: $04:6902)
memcopy_b_bytes_from_hl_to_de__ROM_32K_Bank2_2902_:
    .copy_loop
    ldi  a, [hl]
    ld   [de], a
    inc  de
    dec  b
    jr   nz, .copy_loop
    ret


; Divides DE / H and provides result + Remainder
;
; - Result TRUNC(DE / H) in: BC
; - Result DE % H in       : L
;
; Destroys A, BC, DE, L
; 32K Bank addr: $02:2909 (16K Bank addr: $04:6909)
divide_de_by_h_result_in_bc_remainder_in_l__ROM_32K_Bank2_2909_:
    ld   bc, $0000
    ld   l, $00
    ld   a, h
    or   a
    jr   z, .done

    .subtract_loop:
        ld   a, e
        sub  h
        ld   e, a
        ld   a, d
        sbc  $00
        ld   d, a
        jr   c, .check_remainder

        inc  c
        jr   nz, .subtract_loop

        inc  b
        ld   c, $00
        jr   .subtract_loop

    .check_remainder:
        ld   a, e
        or   a
        ; If e is zero there is no remainder, use previously loaded 0x00 in L
        jr   z, .done

        ; Otherwise calculate remainder as e + h
        add  h
        ld   l, a
    .done:
        ret


; Multiply values in registers A x B
;
; - Result in: DE
;
; - Destroys C only if both A and B are non-zero
; 32K Bank addr: $02:292A (16K Bank addr: $04:692A)
multiply_a_x_b__result_in_de__ROM_32K_Bank2_292A_:
    ld   d, $00
    ld   e, $00
    or   a
    ; Return with result 0 if A is zero
    jr   z, .multiply_done

        push bc
        ld   c, a
        ld   a, b
        or   a
        ld   a, c
        pop  bc
        ; Return with result 0 if B is zero
        jr   z, .multiply_done

        ld   c, a
    .loop_multiply:
        ; Add DE + A (starts with zero) for B times
        ld   a, e
        add  c
        ld   e, a
        ld   a, d
        adc  $00
        ld   d, a
        dec  b
        jr   nz, .loop_multiply

    .multiply_done:
        ret


; Adds A to HL, result in HL
;
; 32K Bank addr: $02:2945 (16K Bank addr: $04:6945)
add_a_to_hl__ROM_32K_Bank2_2945_:
    add  l
    ld   l, a
    ld   a, h
    adc  $00
    ld   h, a
    ret
