
; TODO: Move to common macro
; Fixes bank numbers for the lower 16K region of 32K Banks > 0
; which has to handle as 16K banks in the upper 16k region, and
; so they address has 0x4000 added that needs to be stripped
;
; So Even 16K BANK()s with the address > 0x4000 get shifted
; \1 = Label which needs address fixed
call_FIX_32K_BANK_ADDR: MACRO
    IF _NARG != 1
        FAIL "call_FIX_32K_BANK_ADDR accepts only 1 argument (address or address label)"
    ENDC
    IF ((BANK(\1) % 1) == 0)
        call (\1 & $3FFF)
    ELSE
        call \1
    ENDC
ENDM

; Actually 32K Bank 2 -> Lower 16K region. 32K banking not supported in RGBDS
SECTION "rom4", ROMX, BANK[$4]
; 32K Bank memory region: 0x0000 -> 0x3FFF
; Data from 10000 to 13FFF (16384 bytes)

bank_2_32k_DUCK_ENTRY_POINT_0000_:
    di
    jp   _GB_ENTRY_POINT_100_

    nop
    nop
    nop
    nop

bank_2_32k_RST__08_:
    ei
    call z, $3580
    di
    jp   switch_bank_return_to_saved_bank_RAM__C940_

bank_2_32k_RST__10_:
    ei
    call z, $552E
    di
    jp   switch_bank_return_to_saved_bank_RAM__C940_

bank_2_32k_RST__18_:
    ei
    call $7804
    di
    jp   switch_bank_return_to_saved_bank_RAM__C940_

bank_2_32k_RST__20_:
    jp   _GB_ENTRY_POINT_100_
    nop
    nop
    nop
    nop
    nop

bank_2_32k_RST__28_:
    jp   _GB_ENTRY_POINT_100_
    nop
    nop
    nop
    nop
    nop

bank_2_32k_RST__30_:
    di
    call $052B
    ei
    jp   switch_bank_return_to_saved_bank_RAM__C940_

    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

bank_2_32k__RST__40_:
    di
    call _VBL_HANDLER__6D_
    ei
    reti

    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

bank_2_32k__RST__50_:
    di
    call $00C6
    ei
    reti

    nop
    nop

bank_2_32k__RST__58_:
    di
    call $00D9
    ei
    reti


; 32K Bank addr: $02:005E (16K Bank addr: $04:405E)
            nop
            nop
            di
            push af
            ld   a, [_RAM_D020_]
            add  $05
            ld   [_RAM_D020_], a
            pop  af
            ei
            reti

            push af
            push bc
            push de
            push hl
            ld   a, [_RAM_D193_]
            ld   h, a
            ld   a, [_RAM_D194_]
            ld   l, a
            ld   a, [vbl_action_select__RAM_D195_]  ; vbl_action_select__RAM_D195_ = $D195
            and  a
            jr   z, tile_data_0x40ba_720_bytes_paino_app_menu_icons__40BA_
            cp   $01
            jr   nz, @ + 4
            jr   tile_data_0x40ba_720_bytes_paino_app_menu_icons__40BA_

            cp   $02
            jr   nz, @ + 4
            jr   tile_data_0x40ba_720_bytes_paino_app_menu_icons__40BA_

            cp   $03
            jr   nz, @ + 7
            call $28F1
            jr   tile_data_0x40ba_720_bytes_paino_app_menu_icons__40BA_

            cp   $04
            jr   nz, @ + 7
            call $28FD
            jr   tile_data_0x40ba_720_bytes_paino_app_menu_icons__40BA_

            cp   $05
            jr   nz, @ + 4
            jr   tile_data_0x40ba_720_bytes_paino_app_menu_icons__40BA_

            cp   $06
            jr   nz, @ + 2
            cp   $07
            jr   nz, @ + 7
            call $28F6
            jr   tile_data_0x40ba_720_bytes_paino_app_menu_icons__40BA_

            cp   $08
            jp   nz, $00BA
            call $2902
            jr   tile_data_0x40ba_720_bytes_paino_app_menu_icons__40BA_

            xor  a
            ld   [vbl_action_select__RAM_D195_], a  ; vbl_action_select__RAM_D195_ = $D195
            call _oam_dma_routine_in_HRAM__FF80_
            pop  hl
            pop  de
            pop  bc
            pop  af
            ret

            push af
            ld   a, [_RAM_D020_]
            add  $07
            ld   [_RAM_D020_], a
            ld   a, [timer_flags__RAM_D000_]    ; timer_flags__RAM_D000_ = $D000
            set  2, a
            ld   [timer_flags__RAM_D000_], a    ; timer_flags__RAM_D000_ = $D000
            pop  af
            ret

            push af
            ldh  a, [rSB]
            ld   [serial_rx_data__RAM_D021_], a
            ld   a, $01
            ld   [serial_status__RAM_D022_], a
            call $0BEF
            pop  af
            ret

            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            di
            call $0B93
            ld   a, [serial_system_status__RAM_D024_]
            bit  0, a
            jr   nz, @ - 5
            ld   hl, init_key_slot_1__RAM_DBFC_ ; init_key_slot_1__RAM_DBFC_ = $DBFC
            ldi  a, [hl]
            cp   $AA
            jr   nz, @ + 14
            ldi  a, [hl]
            cp   $E4
            jr   nz, @ + 9
            ldi  a, [hl]
            cp   $55
            jr   nz, @ + 4
            jr   @ + 21

            xor  a
            ld   [_RAM_DBFB_], a
            ld   a, $AA
            ld   [init_key_slot_1__RAM_DBFC_], a    ; init_key_slot_1__RAM_DBFC_ = $DBFC
            ld   a, $E4
            ld   [init_key_slot_2__RAM_DBFD_], a    ; init_key_slot_2__RAM_DBFD_ = $DBFD
            ld   a, $55
            ld   [init_key_slot_3__RAM_DBFE_], a    ; init_key_slot_3__RAM_DBFE_ = $DBFE
            di
            ld   sp, $C400
            call $0B3E
            call $0916
            jr   @ + 2

            call $0AF0
            call $0B10
            ld   hl, $8800
            ld   de, $1109
            ld   bc, $0800
            call memcopy_in_RAM__C900_  ; Code is loaded from _memcopy__7D3_
            ld   a, $80
            ld   [ui_grid_menu_escape_key_runs_last_icon__RAM_D06C_], a ; ui_grid_menu_escape_key_runs_last_icon__RAM_D06C_ = $D06C
            ld   a, $08
            ld   [ui_grid_menu_icon_count__RAM_D06D_], a    ; ui_grid_menu_icon_count__RAM_D06D_ = $D06D
            call $294C
            call $29E5
            ld   a, [ui_grid_menu_selected_icon__RAM_D06E_] ; ui_grid_menu_selected_icon__RAM_D06E_ = $D06E
            cp   $00
            jr   nz, @ + 12
            ld   a, $01
            ld   [_RAM_D1A7_], a
            call $7804
            jr   @ - 49

            cp   $01
            jr   nz, @ + 12
            ld   a, $02
            ld   [_RAM_D1A7_], a
            call $7804
            jr   @ - 63

            cp   $03
            jr   nz, @ + 15
            ld   bc, $00FF
            ld   hl, $B000
            ld   a, $00
            call $5281
            jr   @ - 80

            cp   $05
            jr   nz, @ + 7
            call $3580 ; _LABEL_3580_
            jr   @ - 89

            cp   $06
            jr   nz, @ - 93
            call $552E
            jr   @ - 98

; Turn on interrupts and wait for a Timer tick
; - Called from printing
;
; - Turn on interrupts
;
; Overflows/Triggers interrupt every 201 ticks (0x100 - 0x37) = 201
; 4096 Hz / (201) = ~20.378Hz, roughly every 3rd frame
;
; Destroys a, hl (maybe more in subsequent jump to 0355)
;
; 32K Bank addr: $02:01A2 (16K Bank addr: $04:41A2)
timer_wait_50msec_and_maybe_print_related__ROM_32K_Bank2_01A2_:
    ei
    .loop_wait_timer__1A3_:
        ld   hl, timer_flags__RAM_D000_
        bit  TIMER_FLAG__BIT_TICKED, [hl]  ; 2, [hl]
        jp   nz, $0355  ; timer_20hz_tick_done__maybe_print_related_355_  ; $0355
        jr   .loop_wait_timer__1A3_

; Waits for a Timer tick to read the joypad & buttons
;
; Possibly unused?
wait_timer_then_read_joypad_buttons__ROM_32K_Bank2_01AD_:
    ld   hl, timer_flags__RAM_D000_
    bit  TIMER_FLAG__BIT_TICKED, [hl]  ; 2, [hl]
    jr   nz, .start_read__1B6_
    jr   wait_timer_then_read_joypad_buttons__ROM_32K_Bank2_01AD_

    .start_read__1B6_:
        ; Clear flag and read joypad
        res  TIMER_FLAG__BIT_TICKED, [hl]  ; 2, [hl]
        jp   $0412  ; TODO: joypad_and_buttons_read__412_  ; $0412
        ; Returns at end of joypad_and_buttons_read__412_




; 32K Bank addr: $02:01BB (16K Bank addr: $04:41BB)
            ld   a, [_RAM_CC01_]
            set  0, a
            res  4, a
            ld   [_RAM_CC01_], a
            ld   a, l
            ld   [_RAM_CC11_], a
            ld   a, h
            ld   [_RAM_CC10_], a
            ld   a, $8B
            ld   [_RAM_CC12_], a
            ld   a, $00
            ld   [maybe_audio_cache_rAUD1SWEEP__RAM_CC13_], a   ; maybe_audio_cache_rAUD1SWEEP__RAM_CC13_ = $CC13
            ld   a, $C0
            ld   [maybe_audio_cache_rAUD1LEN__RAM_CC14_], a ; maybe_audio_cache_rAUD1LEN__RAM_CC14_ = $CC14
            ld   a, [_RAM_CC00_]
            or   $11
            ld   [_RAM_CC00_], a
            ld   a, $01
            ld   [_RAM_CC23_], a
            ret

            ld   a, [_RAM_CC40_]
            ld   h, a
            ld   a, [_RAM_CC41_]
            ld   l, a
            ld   a, [hl]
            ld   b, a
            inc  hl
            ld   a, h
            ld   [_RAM_CC40_], a
            ld   a, l
            ld   [_RAM_CC41_], a
            ld   a, $FF
            ld   [_RAM_CC48_], a
            ld   [_RAM_CC49_], a
            bit  7, b
            jr   z, @ + 25
            ld   a, [_RAM_CC47_]
            res  0, a
            ld   [_RAM_CC47_], a
            dec  hl
            ld   a, l
            ld   [_RAM_CC41_], a
            ld   a, h
            ld   [_RAM_CC40_], a
            ld   a, $01
            ld   [_RAM_CC42_], a
            ret

            ld   a, [hl]
            ld   [_RAM_CC42_], a
            inc  hl
            ld   a, h
            ld   [_RAM_CC40_], a
            ld   a, l
            ld   [_RAM_CC41_], a
            ret

            ld   a, [_RAM_CC02_]
            or   $01
            ld   [_RAM_CC02_], a
            ld   a, [_RAM_CC01_]
            bit  4, a
            jr   z, @ + 5
            jp   $02BF

            ld   a, [_RAM_CC10_]
            ld   h, a
            ld   a, [_RAM_CC11_]
            ld   l, a
            ld   a, [hl]
            ld   b, a
            inc  hl
            ld   a, h
            ld   [_RAM_CC10_], a
            ld   a, l
            ld   [_RAM_CC11_], a
            ld   a, [_RAM_CC12_]
            ld   [_RAM_CC2F_], a
            bit  7, b
            jr   z, @ + 59
            ld   a, $FE
            xor  b
            jr   z, @ + 40
            dec  hl
            ld   a, l
            ld   [_RAM_CC11_], a
            ld   a, h
            ld   [_RAM_CC10_], a
            ld   a, $FF
            ld   [maybe_audio_cache_rAUD1LOW__RAM_CC28_], a ; maybe_audio_cache_rAUD1LOW__RAM_CC28_ = $CC28
            ld   a, $07
            ld   [_RAM_CC27_], a
            ld   a, $01
            ld   [_RAM_CC23_], a
            ld   a, $01
            ld   [_RAM_CC2F_], a
            ld   a, [_RAM_CC00_]
            and  $EE
            ld   [_RAM_CC00_], a
            ret

            ld   a, [_RAM_CC60_]
            ld   [_RAM_CC10_], a
            ld   a, [_RAM_CC61_]
            ld   [_RAM_CC11_], a
            jr   @ - 84

            ld   a, b
            add  a
            ld   c, a
            ld   b, $00
            ld   hl, $0DA7
            add  hl, bc
            inc  hl
            ld   a, [hl]
            ld   [maybe_audio_cache_rAUD1LOW__RAM_CC28_], a ; maybe_audio_cache_rAUD1LOW__RAM_CC28_ = $CC28
            dec  hl
            ld   a, [hl]
            ld   [_RAM_CC27_], a
            ld   a, [_RAM_CC10_]
            ld   h, a
            ld   a, [_RAM_CC11_]
            ld   l, a
            ld   a, [hl]
            ld   [_RAM_CC23_], a
            inc  hl
            ld   a, h
            ld   [_RAM_CC10_], a
            ld   a, l
            ld   [_RAM_CC11_], a
            ret

            ld   a, [_RAM_CC10_]
            ld   h, a
            ld   a, [_RAM_CC11_]
            ld   l, a
            ldi  a, [hl]
            bit  7, a
            jr   z, @ + 85
            ld   a, [_RAM_CC47_]
            bit  0, a
            jp   z, $025D
            res  0, a
            ld   [_RAM_CC47_], a
            ld   a, [_RAM_CC41_]
            ld   [_RAM_CC11_], a
            ld   a, [_RAM_CC40_]
            ld   [_RAM_CC10_], a
            ld   a, [_RAM_CC43_]
            ld   [_RAM_CC12_], a
            ld   a, [_RAM_CC44_]
            ld   [maybe_audio_cache_rAUD1SWEEP__RAM_CC13_], a   ; maybe_audio_cache_rAUD1SWEEP__RAM_CC13_ = $CC13
            ld   a, [_RAM_CC45_]
            ld   [maybe_audio_cache_rAUD1LEN__RAM_CC14_], a ; maybe_audio_cache_rAUD1LEN__RAM_CC14_ = $CC14
            ld   a, [_RAM_CC48_]
            ld   [_RAM_CC27_], a
            ld   a, [_RAM_CC49_]
            ld   [maybe_audio_cache_rAUD1LOW__RAM_CC28_], a ; maybe_audio_cache_rAUD1LOW__RAM_CC28_ = $CC28
            ld   a, [_RAM_CC46_]
            ld   b, a
            ld   a, [_RAM_CC00_]
            and  $EE
            or   b
            ld   [_RAM_CC00_], a
            ld   a, [_RAM_CC42_]
            ld   [_RAM_CC23_], a
            ld   a, [_RAM_CC01_]
            res  4, a
            ld   [_RAM_CC01_], a
            ret

            ld   [_RAM_CC23_], a
            ldi  a, [hl]
            ld   [_RAM_CC2F_], a
            ldi  a, [hl]
            ld   [maybe_audio_cache_rAUD1LEN__RAM_CC14_], a ; maybe_audio_cache_rAUD1LEN__RAM_CC14_ = $CC14
            ldi  a, [hl]
            ld   [_RAM_CC27_], a
            ldi  a, [hl]
            ld   [maybe_audio_cache_rAUD1LOW__RAM_CC28_], a ; maybe_audio_cache_rAUD1LOW__RAM_CC28_ = $CC28
            ldi  a, [hl]
            ld   [maybe_audio_cache_rAUD1SWEEP__RAM_CC13_], a   ; maybe_audio_cache_rAUD1SWEEP__RAM_CC13_ = $CC13
            and  $80
            jr   z, @ + 12
            ld   a, [_RAM_CC01_]
            set  0, a
            ld   [_RAM_CC01_], a
            jr   @ + 10

            ld   a, [_RAM_CC01_]
            res  0, a
            ld   [_RAM_CC01_], a
            ld   a, l
            ld   [_RAM_CC11_], a
            ld   a, h
            ld   [_RAM_CC10_], a
            ret

            res  2, [hl]
            ld   a, [_RAM_CC00_]
            bit  0, a
            jr   nz, @ + 7
            bit  4, a
            jp   z, $03EC
            ld   a, [_RAM_CC23_]
            dec  a
            ld   [_RAM_CC23_], a
            jr   nz, @ + 111
            call $022E
            ld   a, [_RAM_CC02_]
            bit  0, a
            jp   z, $03D9
            ld   a, [maybe_audio_cache_rAUD1SWEEP__RAM_CC13_]   ; maybe_audio_cache_rAUD1SWEEP__RAM_CC13_ = $CC13
            ldh  [rAUD1SWEEP], a
            ld   a, [maybe_audio_cache_rAUD1LEN__RAM_CC14_] ; maybe_audio_cache_rAUD1LEN__RAM_CC14_ = $CC14
            ldh  [rAUD1LEN], a
            ld   a, [maybe_audio_cache_rAUD1LOW__RAM_CC28_] ; maybe_audio_cache_rAUD1LOW__RAM_CC28_ = $CC28
            ldh  [rAUD1LOW], a
            ld   a, $FF
            ldh  [rAUDVOL], a
            ld   a, [_RAM_CC2F_]
            ld   a, [_RAM_CC27_]
            cp   $07
            jr   nz, @ + 13
            ld   a, [maybe_audio_cache_rAUD1LOW__RAM_CC28_] ; maybe_audio_cache_rAUD1LOW__RAM_CC28_ = $CC28
            cp   $FF
            jr   nz, @ + 6
            ld   a, $80
            jr   @ + 4

            ld   a, $0F
            ldh  [rAUD1ENV], a
            ld   a, [_RAM_CC27_]
            res  6, a
            set  7, a
            ld   b, a
            ld   a, [_RAM_CC01_]
            bit  0, a
            jr   z, @ + 7
            ld   a, b
            res  6, a
            jr   @ + 3

            ld   a, b
            ld   b, a
            ld   a, [_RAM_CC27_]
            cp   $07
            jr   nz, @ + 16
            ld   a, [maybe_audio_cache_rAUD1LOW__RAM_CC28_] ; maybe_audio_cache_rAUD1LOW__RAM_CC28_ = $CC28
            cp   $FF
            jr   nz, @ + 9
            xor  a
            ldh  [rAUDENA], a
            ld   a, $80
            ldh  [rAUDENA], a
            ld   a, b
            ldh  [rAUD1HIGH], a
            ld   a, [_RAM_CC02_]
            res  0, a
            ld   [_RAM_CC02_], a
            ld   a, [_RAM_CC47_]
            bit  0, a
            jr   z, @ + 14
            ld   a, [_RAM_CC42_]
            dec  a
            ld   [_RAM_CC42_], a
            jr   nz, @ + 5
            call main_system_loop__15C_.check_app_games__1EA_
            ld   a, [_RAM_CC00_]
            bit  1, a
            jr   nz, @ + 6
            bit  5, a
            jr   z, @ + 2
            ld   a, [_RAM_CC00_]
            bit  2, a
            jr   nz, @ + 6
            bit  6, a
            jr   z, @ + 2
            ld   a, [_RAM_CC00_]
            bit  3, a
            jr   nz, @ + 6
            bit  7, a
            jr   z, @ + 2
            ld   a, [_RAM_CC00_]
            ldh  [rAUDTERM], a
            ld   a, $20
            ldh  [rP1], a
            ldh  a, [rP1]
            ldh  a, [rP1]
            ldh  a, [rP1]
            cpl
            and  $0F
            swap a
            ld   b, a
            ld   a, $10
            ldh  [rP1], a
            ldh  a, [rP1]
            ldh  a, [rP1]
            ldh  a, [rP1]
            cpl
            and  $0F
            or   b
            ld   b, a
            ld   hl, buttons_new_pressed__RAM_D006_ ; buttons_new_pressed__RAM_D006_ = $D006
            xor  [hl]
            and  b
            ld   [hl], b
            ld   [buttons_current__RAM_D007_], a    ; buttons_current__RAM_D007_ = $D007
            ret

            di
            ld   hl, $0010
            res  7, h
            ld   a, $00
            call switch_bank_in_a_jump_hl_RAM__C920_
            ei
            xor  a
            ld   [_rombank_saved__C8D8_], a ; _rombank_saved__C8D8_ = $C8D8
            ld   a, $02
            ld   [_rombank_currrent__C8D7_], a  ; _rombank_currrent__C8D7_ = $C8D7
            ei
            ret

            call $0AF0
            call $0B10
            ld   a, $BE
            ld   b, $80
            sub  b
            ld   b, $10
            call $292A
            ld   hl, $8800
            add  hl, de
            ld   de, $2301
            ld   bc, $0010
            call memcopy_in_RAM__C900_  ; Code is loaded from _memcopy__7D3_
            ret

            ld   c, $0E
            ld   hl, $9862
            ld   b, $10
            ld   a, [de]
            ldi  [hl], a
            inc  de
            dec  b
            jr   nz, @ - 4
            ld   a, e
            add  $30
            ld   e, a
            ld   a, d
            adc  $00
            ld   d, a
            ld   a, l
            add  $10
            ld   l, a
            ld   a, h
            adc  $00
            ld   h, a
            dec  c
            jr   nz, @ - 25
            ret

            push af
            push bc
            push de
            push hl
            call $0AF0
            ld   a, $00
            call $0ABF
            pop  hl
            pop  de
            pop  bc
            pop  af
            ret

            ld   h, e
            ld   hl, $2264
            ld   h, l
            ld   a, [$2466]
            ld   h, a
            dec  h
            ld   l, b
            ld   h, $69
            cpl
            ld   l, d
            jr   z, @ + 109
            add  hl, hl
            ld   l, h
            ld   e, h
            ld   l, l
            ld   h, b
            ld   l, [hl]
            daa
            ld   l, a
            ldi  a, [hl]
            ld   [hl], b
            ld   e, [hl]
            ld   [hl], c
            inc  hl
            ld   [hl], d
            ld   b, b
            ld   [hl], e
            ldd  a, [hl]
            ld   [hl], h
            ld   l, $75
            dec  sp
            halt
            ld   a, $77
            inc  a
            ld   a, l
            pop  hl
            sbc  a, e
            adc  [hl]
            sbc  a, h
            sbc  a, c
            sbc  a, l
            sbc  a, d
            sbc  a, [hl]
            inc  l
            sbc  a, a
            ld   a, [$5FA0]
            cp   e
            add  h
            cp   h
            sub  h
            cp   l
            add  c
            cp   [hl]
            jr   nz, @ - 63
            ccf
            jp   z, $CB2B
            dec  l
            call z, $CD2A
            or   $CE
            dec  a
            ret  nc
            xor  b
            pop  de
            xor  l
            jp   nc, $D35B
            ld   e, l
            call nc, $D5A7
            and  l
            sub  $41
            rst  $10    ; _RST_10_serial_io_send_command_and_buffer__0010_
            sub  b
            ret  c
            ld   c, c
            reti

            ld   c, a
            jp   c, $DB55
            and  [hl]
            call c, $DDA4
            and  b
            sbc  $82
            rst  $18    ; _RST__18_
            and  c
            ldh  [$A2], a
            pop  hl
            and  e
            ld   bc, $100A
            inc  d
            add  hl, de
            ld   e, $23
            jr   z, @ + 47
            ldd  [hl], a
            scf
            inc  a
            ld   b, c
            ld   b, [hl]
            ld   c, e
            ld   d, b
            ld   d, l
            ld   e, d
            ld   e, a
            ld   h, h
            ld   l, c
            ld   l, [hl]
            ld   [hl], e
            ld   a, b
            ld   a, a
    ; ABOVE: May be data


; Set up a print request and load x,y from ROM vars
; 32K Bank addr: $02:052B (16K Bank addr: $04:452B)
print__start_loading_x_y_from_ram__maybe___ROM_32K_Bank2_052B_:
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    push af
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    push af
    call $053F
    pop  af
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    pop  af
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ret


; - Start X,Y expected on stack, two bytes each with lower byte garbage
; - Y (stack+2..3)
; - X (stack+4..5)
; 32K Bank addr: $02:0535 (16K Bank addr: $04:4535)
print_start__maybe___ROM_32K_Bank2_0535_:
            xor  a
            ld   [_RAM_CC00_], a  ; TODO: Possible a reply bugger for the print command?
            call_FIX_32K_BANK_ADDR timer_wait_50msec_and_maybe_print_related__ROM_32K_Bank2_01A2_

            ld   a, SYS_CMD_PRINT_OR_EXT_IO_MAYBE__0x09  ; $09
            ld   [serial_tx_data__RAM_D023_], a
            call $0D28
            call $0D62
            ld   a, [serial_rx_data__RAM_D021_]
            ld   [serial_cmd_0x09_reply_data__RAM_D2E4_], a
            and  a
            ret  z

            call_FIX_32K_BANK_ADDR timer_wait_50msec_and_maybe_print_related__ROM_32K_Bank2_01A2_  ; call $01A2
            ld   a, SYS_CMD_PRINT_OR_EXT_IO_MAYBE__0x09  ; $09
            ld   [serial_tx_data__RAM_D023_], a
            call $0D28
            call $0D62
            ld   a, [serial_rx_data__RAM_D021_]
            ld   [serial_cmd_0x09_reply_data__RAM_D2E4_], a
            and  a
            ret  z
            call $01A2
            ld   a, SYS_CMD_PRINT_OR_EXT_IO_MAYBE__0x09  ; $09
            ld   [serial_tx_data__RAM_D023_], a
            call $0D28
            call $0D62
            ld   a, [serial_rx_data__RAM_D021_]
            ld   [serial_cmd_0x09_reply_data__RAM_D2E4_], a
            and  a
            ret  z
            call $05BF
            ld   a, $01
            ld   [_RAM_D1A7_], a
            call $0887
            ld   a, $10
            ld   [_tilemap_pos_y__RAM_C8CA_], a ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
            ld   a, $00
            ld   [_RAM_D1A7_], a
            call $05CA
            call $0887
            ld   a, [serial_cmd_0x09_reply_data__RAM_D2E4_]
            bit  1, a
            jr   nz, @ + 13
            ld   a, $01
            ld   [_RAM_D1A7_], a
            call $05CA
            call $0887
            ld   a, [_tilemap_pos_y__RAM_C8CA_] ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
            add  $08
            ld   [_tilemap_pos_y__RAM_C8CA_], a ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
            cp   $A0
            jr   nz, @ - 39
            ret

            ld   c, $B6
            ld   hl, _RAM_D20D_ + 1
            xor  a
            ldi  [hl], a
            dec  c
            jr   nz, @ - 2
            ret

            call $05BF
            ld   a, $08
            ld   [_tilemap_pos_x__RAM_C8CB_], a ; _tilemap_pos_x__RAM_C8CB_ = $C8CB
            call _oam_dma_copy_wait_loop_7EA_
            ld   a, h
            ld   [_RAM_D193_], a
            ld   a, l
            ld   [_RAM_D194_], a
            ld   a, $04
            ld   [vbl_action_select__RAM_D195_], a  ; vbl_action_select__RAM_D195_ = $D195
            ei
            ld   a, [vbl_action_select__RAM_D195_]  ; vbl_action_select__RAM_D195_ = $D195
            and  a
            jr   nz, @ - 4
            call $082E
            ld   a, [_tilemap_pos_x__RAM_C8CB_] ; _tilemap_pos_x__RAM_C8CB_ = $C8CB
            add  $08
            ld   [_tilemap_pos_x__RAM_C8CB_], a ; _tilemap_pos_x__RAM_C8CB_ = $C8CB
            cp   $A8
            jr   c, @ - 36
            call $05FC
            ret

            ld   hl, shadow_oam_base__RAM_C800_ ; shadow_oam_base__RAM_C800_ = $C800
            push hl
            ldi  a, [hl]
            ld   b, a
            ld   a, [_tilemap_pos_y__RAM_C8CA_] ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
            sub  b
            add  $07
            bit  7, a
            jr   nz, @ + 25
            cp   $0F
            jr   nc, @ + 4
            jr   @ + 16

            ld   d, a
            ldh  a, [rLCDC]
            bit  1, a
            jr   z, @ + 12
            ld   a, d
            sub  $08
            cp   $0F
            jr   nc, @ + 5
            call $062F
            pop  hl
            ld   a, $04
            call $2945
            ld   a, l
            cp   $A0
            jr   nz, @ - 45
            ret

            ldi  a, [hl]
            and  a
            ret  z
            bit  7, a
            jr   z, @ + 5
            cp   $A8
            ret  nc
            ld   a, [hl]
            push hl
            bit  7, a
            jr   nz, @ + 7
            ld   hl, $8000
            jr   @ + 7

            ld   hl, $8800
            res  7, a
            push hl
            ld   b, $10
            call $292A
            pop  hl
            add  hl, de
            ld   a, h
            ld   [_RAM_D193_], a
            ld   a, l
            ld   [_RAM_D194_], a
            ld   a, $04
            ld   [vbl_action_select__RAM_D195_], a  ; vbl_action_select__RAM_D195_ = $D195
            ei
            ld   a, [vbl_action_select__RAM_D195_]  ; vbl_action_select__RAM_D195_ = $D195
            and  a
            jr   nz, @ - 4
            pop  hl
            push hl
            dec  hl
            dec  hl
            ldi  a, [hl]
            ld   b, a
            ld   a, [_tilemap_pos_y__RAM_C8CA_] ; _tilemap_pos_y__RAM_C8CA_ = $C8CA
            cp   b
            jr   c, @ + 7
            sub  b
            sla  a
            jr   @ + 11

            ld   d, a
            ld   a, b
            sub  d
            sla  a
            ld   b, a
            ld   a, $00
            sub  b
            ld   b, a
            call $0726
            pop  hl
            dec  hl
            ld   a, [hl]
            ld   [_tilemap_pos_x__RAM_C8CB_], a ; _tilemap_pos_x__RAM_C8CB_ = $C8CB
            call $082E
            ret

            push bc
            inc  hl
            inc  hl
            ld   a, [hl]
            bit  5, a
            jr   z, @ + 21
            ld   b, $10
            ld   de, copy_buffer__RAM_DCF0_ ; copy_buffer__RAM_DCF0_ = $DCF0
            call $0704
            ld   a, [de]
            swap a
            ld   [de], a
            call $0704
            inc  de
            dec  b
            jr   nz, @ - 12
            ld   a, [hl]
            bit  6, a
            jp   z, $06B8
            ld   b, $08
            ld   c, $0E
            ld   de, copy_buffer__RAM_DCF0_ ; copy_buffer__RAM_DCF0_ = $DCF0
            call $06E7
            pop  bc
            ret

            push bc
            inc  hl
            inc  hl
            ld   a, [hl]
            bit  5, a
            jr   z, @ + 21
            ld   b, $20
            ld   de, $D2C4
            call $0704
            ld   a, [de]
            swap a
            ld   [de], a
            call $0704
            inc  de
            dec  b
            jr   nz, @ - 12
            ld   a, [hl]
            bit  6, a
            jp   z, $06E5
            ld   b, $10
            ld   c, $1E
            ld   de, $D2C4
            call $06E7
            pop  bc
            ret

            ld   l, c
            ld   h, $00
            add  hl, de
            ld   a, [de]
            ld   [_RAM_D03A_], a
            ld   a, [hl]
            ld   [de], a
            ld   a, [_RAM_D03A_]
            ldi  [hl], a
            inc  de
            dec  b
            bit  0, b
            jr   nz, @ - 14
            ld   a, c
            sub  $04
            ld   c, a
            ld   a, b
            and  a
            jr   nz, @ - 26
            ret

            push bc
            ld   a, [de]
            and  $09
            ld   b, a
            jr   z, @ + 9
            cp   $09
            jr   z, @ + 5
            xor  $09
            ld   b, a
            ld   a, [de]
            and  $06
            jr   z, @ + 8
            cp   $06
            jr   z, @ + 4
            xor  $06
            or   b
            ld   b, a
            ld   a, [de]
            and  $F0
            or   b
            ld   [de], a
            pop  bc
            ret

            bit  7, b
            jp   nz, $0776
            ld   a, b
            and  a
            ret  z
            ldh  a, [rLCDC]
            bit  1, a
            jr   z, @ + 46
            push bc
            call $07A7
            ld   c, $10
            ld   de, copy_buffer__RAM_DCF0_ ; copy_buffer__RAM_DCF0_ = $DCF0
            xor  a
            ld   [de], a
            inc  de
            dec  c
            jr   nz, @ - 3
            pop  bc
            ld   c, $10
            ld   a, b
            cp   $11
            jr   c, @ + 6
            ld   a, $20
            sub  b
            ld   c, a
            ld   hl, $D2C4
            ld   a, b
            call $2945
            ld   de, copy_buffer__RAM_DCF0_ ; copy_buffer__RAM_DCF0_ = $DCF0
            ldi  a, [hl]
            ld   [de], a
            inc  de
            dec  c
            jr   nz, @ - 4
            ret

            call $068D
            ld   c, $0F
            ld   hl, copy_buffer__RAM_DCF0_ ; copy_buffer__RAM_DCF0_ = $DCF0
            inc  hl
            ldd  a, [hl]
            ldi  [hl], a
            dec  c
            jr   nz, @ - 4
            xor  a
            ld   [$DCFF], a
            dec  b
            jr   nz, @ - 16
            ret



; 32K Bank addr: $02:0776 (16K Bank addr: $04:4776)
db $C5, $F0, $10, $CB, $4F, $20, $05, $CD, $8D, $06
db $18, $11, $CD, $A7, $07, $21, $F0, $DC, $11, $C4, $D2, $0E, $10, $1A, $22, $13
db $0D, $20, $FA, $C1, $0E, $0F, $21, $FF, $DC, $2B, $2A, $32, $0D, $20, $FA, $AF
db $EA, $F0, $DC, $04, $20, $EE, $C9, $E5, $0E, $10, $21, $C4, $D2, $11, $F0, $DC
db $1A, $22, $13, $0D, $20, $FA, $FA, $93, $D1, $67, $FA, $94, $D1, $6F, $3E, $10
db $CD, $45, $29, $7C, $EA, $93, $D1, $7D, $EA, $94, $D1, $3E, $04, $EA, $95, $D1
db $FB, $FA, $95, $D1, $A7, $20, $FA, $0E, $10, $21, $D4, $D2, $11, $F0, $DC, $1A
db $22, $13, $0D, $20, $FA, $E1, $CD, $BA, $06, $C9, $FA, $CA, $C8, $CB, $3F, $CB
db $3F, $CB, $3F, $D6, $02, $06, $20, $CD, $2A, $29, $FA, $CB, $C8, $CB, $3F, $CB
db $3F, $CB, $3F, $3D, $83, $5F, $3E, $00, $8A, $57, $CD, $F0, $0A, $21, $00, $98
db $F0, $10, $CB, $6F, $28, $03, $21, $00, $9C, $19, $7E, $21, $00, $90, $CB, $7F
db $28, $05, $21, $00, $88, $CB, $BF, $06, $10, $CD, $2A, $29, $19, $C9, $FA, $CB
db $C8, $21, $0E, $D2, $CD, $45, $29, $FA, $A7, $D1, $CB, $47, $28, $05, $11, $F1
db $DC, $18, $03, $11, $F0, $DC, $06, $80, $3E, $08, $EA, $3A, $D0, $0E, $80, $D5
db $1A, $A0, $20, $0F, $FA, $E4, $D2, $CB, $4F, $28, $18, $13, $1A, $1B, $A0, $28
db $12, $18, $0D, $FA, $E4, $D2, $CB, $4F, $28, $06, $13, $1A, $1B, $A0, $28, $03
db $79, $B6, $77, $13, $13, $CB, $39, $FA, $3A, $D0, $3D, $EA, $3A, $D0, $20, $D0
db $D1, $23, $CB, $38, $20, $C2, $C9, $21, $16, $D2, $CD, $FD, $08, $3E, $11, $EA
db $35, $D0, $3E, $0C, $EA, $34, $D0, $CD, $06, $09, $FA, $E4, $D2, $CB, $4F, $28
db $2A, $06, $03, $C5, $CD, $FD, $08, $CD, $06, $09, $C1, $05, $20, $F5, $06, $76
db $2A, $EA, $23, $D0, $C5, $E5, $CD, $53, $0D, $CD, $28, $0D, $E1, $C1, $05, $20
db $EF, $CD, $9A, $0D, $CD, $62, $0D, $CD, $62, $0D, $C9, $06, $0C, $C5, $CD, $FD
db $08, $CD, $06, $09, $C1, $05, $20, $F5, $CD, $FD, $08, $3E, $0D, $EA, $2C, $D0
db $3E, $05, $EA, $34, $D0, $FA, $A7, $D1, $CB, $47, $28, $0A, $3E, $0A, $EA, $2D
db $D0, $3E, $06, $EA, $34, $D0, $CD, $06, $09, $CD, $62, $0D, $C9, $06, $0C, $11
db $28, $D0, $CD, $02, $29, $C9, $E5, $CD, $F8, $0B, $CD, $9A, $0D, $FA, $25, $D0
db $FE, $FC, $20, $F3, $E1, $C9, $3E, $00, $EA, $D7, $C8, $E0, $10, $21, $00, $80
db $AF, $22, $7C, $FE, $98, $20, $F9, $3E, $BE, $22, $7C, $FE, $9C, $20, $F8, $21
db $00, $C8, $06, $A0, $AF, $22, $05, $20, $FB, $E0, $10, $00, $00, $00, $00, $3E
db $C8, $E0, $10, $CD, $A7, $09, $3E, $E4, $E0, $14, $E0, $1B, $3E, $1B, $E0, $15
db $3E, $07, $E0, $17, $3E, $FF, $E0, $13, $21, $00, $C9, $11, $97, $09, $CD, $8E
db $09, $11, $F0, $09, $CD, $8E, $09, $11, $05, $0A, $CD, $8E, $09, $11, $B3, $09
db $CD, $8E, $09, $11, $D0, $09, $CD, $8E, $09, $21, $80, $FF, $11, $A7, $09, $CD
db $8E, $09, $3E, $00, $06, $2A, $21, $A0, $C8, $22, $05, $20, $FC, $C9, $06, $20
db $1A, $22, $13, $05, $20, $FA, $C9, $1A, $22, $13, $0B, $78, $B1, $20, $F8, $C9
db $F0, $10, $F6, $80, $E0, $10, $C9, $F3, $3E, $C8, $E0, $1A, $3E, $28, $3D, $20
db $FD, $FB, $C9, $F3, $FA, $E6, $D6, $F5, $FA, $D7, $C8, $EA, $D8, $C8, $F1, $EA
db $D7, $C8, $EA, $00, $10, $3E, $0A, $3D, $20, $FD, $CD, $00, $C9, $C3, $40, $C9
db $F3, $FA, $E6, $D6, $F5, $FA, $D7, $C8, $EA, $D8, $C8, $F1, $EA, $D7, $C8, $EA
db $00, $10, $3E, $0A, $3D, $20, $FD, $00, $00, $7E, $EA, $E7, $D6, $C3, $40, $C9
db $F3, $F5, $FA, $D7, $C8, $EA, $D8, $C8, $F1, $EA, $D7, $C8, $EA, $00, $10, $3E
db $0A, $3D, $20, $FD, $E9, $F3, $FA, $D8, $C8, $EA, $D7, $C8, $EA, $00, $10, $3E
db $0A, $3D, $20, $FD, $C9, $FA, $CC, $C8, $3D, $CB, $27, $CB, $27, $6F, $26, $C8
db $FA, $CA, $C8, $86, $5F, $77, $23, $FA, $CB, $C8, $86, $57, $77, $3E, $00, $C9
db $3E, $02, $C9, $0E, $00, $21, $A0, $C8, $0C, $2A, $FE, $00, $20, $FA, $2B, $3E
db $FF, $77, $79, $3D, $CB, $27, $CB, $27, $6F, $11, $CA, $C8, $06, $04, $1A, $22
db $13, $05, $20, $FA, $FA, $C8, $C8, $3C, $EA, $C8, $C8, $41, $3E, $00, $C9, $FA
db $CC, $C8, $FE, $00, $28, $21, $3D, $CB, $27, $CB, $27, $6F, $26, $C8, $3E, $00
db $22, $22, $22, $22, $11, $A0, $C8, $FA, $CC, $C8, $3D, $83, $5F, $3E, $00, $12
db $FA, $C8, $C8, $3D, $EA, $C8, $C8, $C9, $06, $12, $21, $00, $98, $FE, $00, $28
db $03, $21, $00, $9C, $0E, $14, $1A, $22, $13, $0D, $20, $FA, $3E, $0C, $85, $6F
db $3E, $00, $8C, $67, $05, $20, $ED, $F0, $10, $F6, $80, $E0, $10, $C9, $F5, $C5
db $D5, $E5, $EA, $CC, $C8, $3E, $00, $CD, $BF, $0A, $E1, $D1, $C1, $F1, $C9, $21
db $00, $98, $FE, $00, $28, $03, $21, $00, $9C, $3E, $00, $57, $FA, $CB, $C8, $5F
db $19, $FA, $CA, $C8, $3D, $5F, $CB, $23, $CB, $12, $CB, $23, $CB, $12, $CB, $23
db $CB, $12, $CB, $23, $CB, $12, $CB, $23, $CB, $12, $19, $FA, $CC, $C8, $77, $C9
db $F0, $10, $CB, $7F, $20, $01, $C9, $F0, $11, $E6, $03, $20, $FA, $F0, $FF, $E0
db $A1, $CB, $87, $E0, $FF, $F0, $18, $FE, $91, $20, $FA, $F0, $A1, $E0, $FF, $C9
db $F0, $10, $E6, $7F, $E0, $10, $C9, $FA, $CC, $C8, $3D, $CB, $27, $CB, $27, $6F
db $26, $C8, $2A, $EA, $CA, $C8, $2A, $EA, $CB, $C8, $C9, $3E, $A0, $E0, $16, $FB
db $CD, $A2, $01, $F3, $F0, $16, $A7, $28, $04, $D6, $08, $18, $F0, $C9, $3E, $05
db $E0, $0F, $E0, $FF, $AF, $E0, $01, $E0, $02, $E0, $45, $E0, $10, $3E, $80, $E0
db $10, $3E, $E4, $E0, $1B, $E0, $14, $3E, $1B, $E0, $15, $AF, $E0, $2A, $3E, $FF
db $E0, $2B, $3E, $55, $01, $3F, $08, $E2, $0D, $05, $20, $FB, $21, $45, $FF, $3E
db $80, $32, $36, $77, $00, $00, $00, $00, $AF, $EA, $02, $CC, $EA, $00, $CC, $EA
db $01, $CC, $3E, $28, $E0, $22, $E0, $25, $3E, $37, $E0, $06, $E0, $05, $3E, $04
db $E0, $07, $C9, $3E, $08, $E0, $FF, $AF, $EA, $24, $D0, $AF, $EA, $23, $D0, $CD
db $28, $0D, $3C, $20, $F7, $CD, $41, $0D, $FE, $01, $06, $00, $C4, $7E, $0D, $AF
db $EA, $23, $D0, $CD, $28, $0D, $06, $01, $0E, $FF, $CD, $41, $0D, $B9, $C4, $7E
db $0D, $0D, $79, $FE, $FF, $20, $F3, $FA, $24, $D0, $CB, $47, $20, $04, $3E, $01
db $18, $02, $3E, $04, $EA, $23, $D0, $CD, $28, $0D, $C9, $F5, $AF, $E0, $60, $3E
db $80, $E0, $02, $F0, $FF, $F6, $08, $E0, $FF, $AF, $E0, $0F, $FB, $F1, $C9, $F5
db $F0, $FF, $E6, $F7, $E0, $FF, $F1, $C9, $F0, $FF, $EA, $78, $D0, $3E, $08, $E0
db $FF, $FA, $34, $D0, $FE, $0D, $38, $02, $18, $15, $FA, $35, $D0, $EA, $23, $D0
db $CD, $28, $0D, $CD, $9A, $0D, $CD, $9A, $0D, $CD, $62, $0D, $A7, $20, $08, $3E
db $FD, $EA, $25, $D0, $C3, $AD, $0C, $FA, $21, $D0, $FE, $06, $CA, $A8, $0C, $FE
db $03, $C2, $1F, $0C, $FA, $34, $D0, $47, $C6, $02, $EA, $23, $D0, $EA, $26, $D0
db $CD, $9A, $0D, $CD, $28, $0D, $CD, $9A, $0D, $CD, $9A, $0D, $21, $28, $D0, $2A
db $EA, $23, $D0, $4F, $FA, $26, $D0, $81, $EA, $26, $D0, $CD, $62, $0D, $A7, $28
db $BE, $FA, $21, $D0, $FE, $06, $CA, $A8, $0C, $FE, $03, $C2, $1F, $0C, $CD, $28
db $0D, $05, $20, $DB, $CD, $62, $0D, $A7, $28, $A5, $FA, $21, $D0, $FE, $06, $CA
db $A8, $0C, $FE, $03, $C2, $1F, $0C, $21, $26, $D0, $AF, $96, $EA, $23, $D0, $CD
db $28, $0D, $CD, $62, $0D, $A7, $CA, $1F, $0C, $FA, $21, $D0, $FE, $01, $C2, $1F
db $0C, $CD, $62, $0D, $3E, $FC, $18, $02, $3E, $FB, $EA, $25, $D0, $FA, $78, $D0
db $E0, $FF, $C9, $F0, $FF, $EA, $78, $D0, $3E, $08, $E0, $FF, $16, $00, $CD, $9A
db $0D, $FA, $36, $D0, $EA, $23, $D0, $CD, $28, $0D, $CD, $62, $0D, $A7, $28, $07
db $FA, $21, $D0, $FE, $0E, $38, $09, $3E, $FA, $EA, $25, $D0, $3E, $04, $18, $3C
db $EA, $26, $D0, $3D, $3D, $EA, $34, $D0, $47, $21, $28, $D0, $E5, $CD, $53, $0D
db $A7, $E1, $28, $E3, $FA, $21, $D0, $22, $4F, $FA, $26, $D0, $81, $EA, $26, $D0
db $05, $20, $E9, $CD, $53, $0D, $A7, $28, $CE, $CD, $9A, $0D, $FA, $21, $D0, $21
db $26, $D0, $86, $20, $C2, $3E, $F9, $EA, $25, $D0, $3E, $01, $EA, $23, $D0, $CD
db $28, $0D, $FA, $78, $D0, $E0, $FF, $C9, $F5, $AF, $E0, $60, $3E, $81, $E0, $02
db $FA, $23, $D0, $E0, $01, $CD, $9A, $0D, $AF, $E0, $0F, $3E, $80, $E0, $02, $F1
db $C9, $3E, $00, $EA, $22, $D0, $CD, $DB, $0B, $FA, $22, $D0, $A7, $28, $FA, $FA
db $21, $D0, $C9, $3E, $00, $EA, $22, $D0, $CD, $DB, $0B, $CD, $89, $0D, $FA, $22
db $D0, $C9, $C5, $3E, $00, $EA, $22, $D0, $CD, $DB, $0B, $06, $02, $CD, $89, $0D
db $FA, $22, $D0, $A7, $20, $06, $05, $20, $F4, $FA, $22, $D0, $C1, $C9, $F5, $FA
db $24, $D0, $CB, $C7, $EA, $24, $D0, $F1, $C9, $C5, $06, $64, $CD, $9A, $0D, $FA
db $22, $D0, $A7, $20, $03, $05, $20, $F4, $C1, $C9, $F5, $3E, $46, $F5, $FA, $23
db $D0, $F1, $3D, $20, $F8, $F1, $C9, $00, $22, $00, $97, $00, $FF, $01, $72, $01
db $C4, $02, $1F, $02, $80, $02, $C8, $03, $15, $03, $5A, $03, $98, $03, $D8, $04
db $19, $04, $52, $04, $86, $04, $B9, $04, $E7, $05, $14, $05, $3D, $05, $64, $05
db $8B, $05, $AD, $05, $CF, $05, $EE, $06, $0D, $06, $28, $06, $43, $06, $5B, $06
db $74, $06, $89, $06, $9F, $06, $B2, $06, $C5, $06, $D7, $06, $E7, $06, $F7, $07
db $06, $07, $14, $07, $21, $07, $2E, $07, $3A, $07, $45, $07, $51, $07, $59, $07
db $63, $07, $6C, $07, $74, $07, $7C, $07, $83, $07, $8A, $07, $91, $07, $97, $07
db $9D, $07, $A3, $07, $A8, $07, $AD, $07, $B2, $07, $B6, $07, $BA, $07, $BE, $07
db $CB, $07, $CE, $07, $D1, $07, $D4, $07, $D6, $07, $D9, $07, $DB, $07, $DD, $07
db $DF, $07, $E1, $07, $E3, $07, $E4, $07, $E6, $07, $E8, $07, $E9, $07, $EA, $07
db $EB, $07, $EC, $07, $EE, $07, $EF, $07, $F0, $07, $F1, $07, $F2, $07, $F3, $07
db $FF, $F0, $FF, $EA, $78, $D0, $AF, $E0, $FF, $3E, $00, $EA, $23, $D0, $CD, $28
db $0D, $CD, $53, $0D, $A7, $28, $16, $FA, $21, $D0, $FE, $00, $28, $0F, $FE, $0E
db $28, $02, $30, $09, $EA, $26, $D0, $CD, $53, $0D, $A7, $20, $0F, $3E, $FF, $EA
db $25, $D0, $3E, $04, $EA, $23, $D0, $CD, $28, $0D, $18, $3E, $FA, $21, $D0, $EA
db $27, $D0, $21, $26, $D0, $86, $77, $CD, $53, $0D, $A7, $28, $E0, $FA, $21, $D0
db $EA, $25, $D0, $21, $26, $D0, $86, $EA, $26, $D0, $CD, $53, $0D, $A7, $28, $CD
db $FA, $21, $D0, $21, $26, $D0, $86, $20, $C4, $3E, $01, $EA, $23, $D0, $CD, $28
db $0D, $CD, $D3, $0E, $FA, $25, $D0, $EA, $81, $D1, $FA, $78, $D0, $E0, $FF, $CD
db $C0, $0F, $C9, $FA, $27, $D0, $CB, $47, $C2, $99, $0F, $FA, $27, $D0, $CB, $5F
db $28, $06, $3E, $2F, $EA, $25, $D0, $C9, $FA, $25, $D0, $A7, $CA, $93, $0F, $CB
db $7F, $CA, $81, $0F, $FE, $F0, $D2, $89, $0F, $CB, $BF, $21, $83, $10, $CD, $45
db $29, $7E, $EA, $25, $D0, $47, $FA, $27, $D0, $E6, $0E, $28, $7C, $FA, $27, $D0
db $E6, $06, $28, $75, $CB, $57, $20, $14, $78, $CB, $7F, $28, $6C, $FE, $A1, $38
db $68, $FE, $BE, $30, $64, $CB, $AF, $EA, $25, $D0, $18, $5D, $CB, $4F, $28, $1A
db $78, $FE, $43, $20, $07, $3E, $70, $EA, $25, $D0, $18, $4D, $CB, $7F, $28, $0A
db $FE, $A1, $38, $06, $FE, $BE, $30, $02, $18, $3F, $78, $FE, $43, $20, $07, $3E
db $70, $EA, $25, $D0, $18, $33, $CB, $7F, $28, $19, $FE, $A1, $38, $06, $FE, $BE
db $30, $02, $18, $C1, $FE, $C1, $38, $0B, $FE, $CA, $30, $07, $D6, $5E, $EA, $25
db $D0, $18, $16, $0E, $0B, $21, $F3, $10, $2A, $B8, $28, $09, $23, $0D, $20, $F8
db $C9, $3E, $F6, $18, $01, $2A, $EA, $25, $D0, $FA, $25, $D0, $FE, $F0, $D0, $EA
db $81, $D1, $C9, $3E, $FF, $EA, $25, $D0, $C9, $FA, $81, $D1, $FE, $CA, $CA, $BC
db $0F, $FE, $CB, $CA, $BC, $0F, $FE, $CC, $CA, $BC, $0F, $FE, $CD, $CA, $BC, $0F
db $FE, $41, $38, $08, $FE, $18, $30, $02, $18, $02, $3E, $FF, $EA, $25, $D0, $C9
db $FA, $25, $D0, $FE, $65, $20, $07, $3E, $9F, $EA, $25, $D0, $18, $2D, $FE, $2B
db $20, $0E, $FA, $27, $D0, $CB, $57, $28, $22, $3E, $D2, $EA, $25, $D0, $18, $1B
db $FA, $25, $D0, $FE, $DC, $20, $14, $FA, $27, $D0, $4F, $E6, $02, $CB, $27, $47
db $79, $E6, $04, $A8, $28, $05, $3E, $D5, $EA, $25, $D0, $FA, $25, $D0, $4F, $FA
db $26, $D2, $FE, $AA, $28, $2E, $AF, $EA, $21, $D2, $EA, $26, $D2, $21, $64, $10
db $2A, $A7, $28, $47, $B9, $20, $49, $FA, $21, $D2, $FE, $01, $28, $31, $5D, $54
db $21, $22, $D2, $70, $23, $71, $23, $72, $23, $73, $23, $3E, $AA, $77, $3E, $FF
db $EA, $25, $D0, $C9, $FA, $25, $D0, $FE, $FF, $C8, $21, $22, $D2, $46, $23, $4E
db $23, $56, $23, $5E, $6B, $62, $3E, $01, $EA, $21, $D2, $FA, $25, $D0, $47, $79
db $B8, $28, $DB, $2A, $B8, $20, $0A, $7E, $EA, $25, $D0, $AF, $EA, $26, $D2, $C9
db $23, $23, $18, $AC, $2B, $A1, $DD, $2B, $81, $D6, $2B, $A5, $DE, $2B, $85, $D7
db $2B, $A9, $DF, $2B, $89, $D8, $2B, $AF, $E0, $2B, $8F, $D9, $2B, $B5, $E1, $2B
db $95, $DA, $00, $30, $2A, $2D, $2F, $31, $C1, $B1, $A1, $32, $C2, $B7, $B3, $33
db $C3, $A5, $A4, $34, $C4, $B2, $A6, $35, $C5, $B4, $A7, $36, $C6, $B9, $A8, $37
db $C7, $B5, $AA, $38, $C8, $A9, $AB, $39, $C9, $AF, $AC, $3A, $C0, $B0, $DC, $3B
db $6E, $2B, $BD, $FF, $D1, $D3, $DB, $FF, $2C, $2E, $FF, $BA, $BE, $01, $00, $B8
db $77, $03, $02, $A3, $44, $3A, $04, $B6, $45, $06, $05, $A2, $46, $08, $07, $AE
db $41, $0A, $09, $AD, $42, $2F, $0B, $9E, $43, $0D, $0C, $74, $CC, $0F, $0E, $CB
db $40, $2F, $10, $3C, $CB, $12, $11, $CD, $3E, $14, $13, $3D, $CE, $16, $15, $CA
db $3F, $3A, $17, $9E, $75, $74, $73, $CB, $A0, $DB, $D4, $D3, $6F, $C0, $6C, $6E
db $BF, $D1, $D0, $77, $76, $41, $47, $42, $48, $FF, $00, $FF, $7F, $FF, $40, $FF
db $40, $FF, $40, $FF, $46, $FF, $49, $FF, $48, $FF, $48, $FF, $49, $FF, $46, $FF
db $40, $FF, $40, $FF, $40, $FF, $7F, $FF, $00, $FF, $00, $FF, $FF, $FF, $00, $FF
db $00, $FF, $00, $FF, $20, $FF, $20, $FF, $20, $FF, $20, $FF, $20, $FF, $3C, $FF
db $00, $FF, $00, $FF, $00, $FF, $FF, $FF, $00, $FF, $00, $FF, $FE, $FF, $02, $FF
db $02, $FF, $02, $FF, $92, $FF, $A2, $FF, $C2, $FF, $C2, $FF, $A2, $FF, $92, $FF
db $02, $FF, $02, $FF, $02, $FF, $FE, $FF, $00, $FF, $00, $FF, $7F, $FF, $40, $FF
db $40, $FF, $40, $FF, $46, $FF, $49, $FF, $48, $FF, $48, $FF, $49, $FF, $46, $FF
db $40, $FF, $40, $FF, $40, $FF, $7F, $FF, $00, $FF, $00, $FF, $FF, $FF, $00, $FF
db $00, $FF, $00, $FF, $3C, $FF, $20, $FF, $38, $FF, $20, $FF, $20, $FF, $3C, $FF
db $00, $FF, $00, $FF, $00, $FF, $FF, $FF, $00, $FF, $00, $FF, $FE, $FF, $02, $FF
db $02, $FF, $02, $FF, $E2, $FF, $92, $FF, $92, $FF, $E2, $FF, $A2, $FF, $92, $FF
db $02, $FF, $02, $FF, $02, $FF, $FE, $FF, $00, $FF, $00, $FF, $7F, $FF, $40, $FF
db $40, $FF, $40, $FF, $46, $FF, $49, $FF, $48, $FF, $48, $FF, $49, $FF, $46, $FF
db $40, $FF, $40, $FF, $40, $FF, $7F, $FF, $00, $FF, $00, $FF, $FF, $FF, $00, $FF
db $00, $FF, $00, $FF, $20, $FF, $20, $FF, $20, $FF, $20, $FF, $20, $FF, $3C, $FF
db $00, $FF, $00, $FF, $00, $FF, $FF, $FF, $00, $FF, $00, $FF, $FE, $FF, $02, $FF
db $02, $FF, $02, $FF, $E2, $FF, $92, $FF, $92, $FF, $E2, $FF, $A2, $FF, $92, $FF
db $02, $FF, $02, $FF, $02, $FF, $FE, $FF, $00, $FF, $00, $FF, $7F, $FF, $40, $FF
db $40, $FF, $40, $FF, $44, $FF, $44, $FF, $47, $FF, $44, $FF, $44, $FF, $44, $FF
db $40, $FF, $40, $FF, $40, $FF, $7F, $FF, $00, $FF, $00, $FF, $FF, $FF, $00, $FF
db $00, $FF, $00, $FF, $44, $FF, $46, $FF, $C6, $FF, $45, $FF, $45, $FF, $44, $FF
db $00, $FF, $00, $FF, $00, $FF, $FF, $FF, $00, $FF, $00, $FF, $FE, $FF, $02, $FF
db $02, $FF, $02, $FF, $42, $FF, $C2, $FF, $C2, $FF, $42, $FF, $42, $FF, $42, $FF
db $02, $FF, $02, $FF, $02, $FF, $FE, $FF, $00, $FF, $00, $FF, $7F, $FF, $40, $FF
db $40, $FF, $40, $FF, $43, $FF, $44, $FF, $44, $FF, $43, $FF, $40, $FF, $44, $FF
db $43, $FF, $40, $FF, $40, $FF, $7F, $FF, $00, $FF, $00, $FF, $FF, $FF, $00, $FF
db $00, $FF, $00, $FF, $03, $FF, $84, $FF, $04, $FF, $04, $FF, $84, $FF, $84, $FF
db $03, $FF, $00, $FF, $00, $FF, $FF, $FF, $00, $FF, $00, $FF, $FE, $FF, $02, $FF
db $02, $FF, $02, $FF, $82, $FF, $42, $FF, $02, $FF, $02, $FF, $02, $FF, $42, $FF
db $82, $FF, $02, $FF, $02, $FF, $FE, $FF, $00, $FF, $00, $FF, $7F, $FF, $40, $FF
db $40, $FF, $40, $FF, $45, $FF, $45, $FF, $45, $FF, $45, $FF, $42, $FF, $42, $FF
db $40, $FF, $40, $FF, $40, $FF, $7F, $FF, $00, $FF, $00, $FF, $FF, $FF, $00, $FF
db $00, $FF, $00, $FF, $43, $FF, $42, $FF, $42, $FF, $43, $FF, $82, $FF, $82, $FF
db $00, $FF, $00, $FF, $00, $FF, $FF, $FF, $00, $FF, $00, $FF, $FE, $FF, $02, $FF
db $02, $FF, $02, $FF, $82, $FF, $42, $FF, $42, $FF, $82, $FF, $02, $FF, $02, $FF
db $02, $FF, $02, $FF, $02, $FF, $FE, $FF, $00, $FF, $00, $FF, $7F, $FF, $40, $FF
db $40, $FF, $40, $FF, $46, $FF, $49, $FF, $48, $FF, $4B, $FF, $49, $FF, $46, $FF
db $40, $FF, $40, $FF, $40, $FF, $7F, $FF, $00, $FF, $00, $FF, $FF, $FF, $00, $FF
db $00, $FF, $00, $FF, $45, $FF, $6D, $FF, $6D, $FF, $55, $FF, $55, $FF, $45, $FF
db $00, $FF, $00, $FF, $00, $FF, $FF, $FF, $00, $FF, $00, $FF, $FE, $FF, $02, $FF
db $02, $FF, $02, $FF, $E2, $FF, $02, $FF, $C2, $FF, $02, $FF, $02, $FF, $E2, $FF
db $02, $FF, $02, $FF, $02, $FF, $FE, $FF, $00, $FF, $00, $FF, $7F, $FF, $40, $FF
db $40, $FF, $40, $FF, $46, $FF, $49, $FF, $48, $FF, $46, $FF, $41, $FF, $49, $FF
db $46, $FF, $40, $FF, $40, $FF, $7F, $FF, $00, $FF, $00, $FF, $FF, $FF, $00, $FF
db $00, $FF, $00, $FF, $22, $FF, $22, $FF, $14, $FF, $08, $FF, $08, $FF, $08, $FF
db $08, $FF, $00, $FF, $00, $FF, $FF, $FF, $00, $FF, $00, $FF, $FE, $FF, $02, $FF
db $02, $FF, $02, $FF, $32, $FF, $4A, $FF, $42, $FF, $32, $FF, $0A, $FF, $4A, $FF
db $32, $FF, $02, $FF, $02, $FF, $FE, $FF, $00, $FF, $FF, $C1, $C3, $A1, $BD, $A1
db $A5, $A1, $A5, $BD, $BD, $C3, $C3, $FF, $FF, $00, $00, $00, $00, $FF, $FF
ds 14, $00
db $FF, $FF
ds 14, $00
db $FF, $FF
ds 14, $00
db $FF, $FF, $00, $00, $00, $00, $7C, $7C, $66, $66, $66, $66, $00, $00, $00, $00
db $FF, $FF, $00, $00, $00, $00, $7C, $7C, $66, $66, $66, $66, $00, $00, $00, $00
db $FF, $FF, $00, $00, $00, $00, $3C, $3C, $66, $66, $66, $66, $00, $00, $00, $00
db $FF, $FF, $00, $00, $00, $00, $3C, $3C, $66, $66, $60, $60, $00, $00, $00, $00
db $FF, $FF
ds 14, $00
db $FF, $FF, $00, $00, $00, $00, $7E, $7E, $18, $18, $18, $18, $00, $00, $00, $00
db $FF, $FF, $00, $00, $00, $00, $7E, $7E, $60, $60, $7C, $7C, $00, $00, $00, $00
db $FF, $FF, $00, $00, $00, $00, $46, $46, $2C, $2C, $18, $18, $00, $00, $00, $00
db $FF, $FF, $00, $00, $00, $00, $7E, $7E, $18, $18, $18, $18, $00, $00, $00, $00
db $FF, $FF, $00, $00, $00, $00, $3C, $3C, $66, $66, $66, $66, $00, $00, $00, $00
db $FF, $FF, $00, $00, $00, $00, $3C, $3C, $60, $60, $3C, $3C, $00, $00, $00, $00
db $FF, $FF
ds 14, $00
db $FF, $FF
ds 14, $00
db $FF, $FF
ds 14, $00
db $FF, $FF, $00, $00, $00, $00, $00, $00, $00, $00, $1F, $1F, $00, $00, $00, $00
db $E0, $E0, $20, $20, $20, $20, $20, $20, $20, $20, $E0, $E0, $08, $0F, $0C, $0C
db $0B, $0B, $0A, $0B, $0A, $0B, $0B, $0B, $0C, $0C, $0F, $0F, $00, $F0, $20, $30
db $C0, $D0, $40, $50, $40, $D0, $DF, $DF, $30, $30, $F0, $F0
ds 10, $00
db $FF, $FF
ds 14, $00
db $FF, $FF, $00, $00, $00, $00, $7C, $7C, $60, $60, $60, $60, $00, $00, $00, $00
db $FF, $FF, $00, $00, $00, $00, $7C, $7C, $68, $68, $66, $66, $00, $00, $00, $00
db $FF, $FF, $00, $00, $00, $00, $66, $66, $66, $66, $3C, $3C, $00, $00, $00, $00
db $FF, $FF, $00, $00, $00, $00, $60, $60, $66, $66, $3C, $3C, $00, $00, $00, $00
db $FF, $FF, $00, $00, $00, $00, $00, $00, $00, $00, $18, $18, $00, $00, $00, $00
db $FF, $FF, $00, $00, $00, $00, $18, $18, $18, $18, $18, $18, $00, $00, $00, $00
db $FF, $FF, $00, $00, $00, $00, $60, $60, $60, $60, $7E, $7E, $00, $00, $00, $00
db $FF, $FF, $00, $00, $00, $00, $38, $38, $64, $64, $42, $42, $00, $00, $00, $00
db $FF, $FF, $00, $00, $00, $00, $18, $18, $18, $18, $18, $18, $00, $00, $00, $00
db $FF, $FF, $00, $00, $00, $00, $66, $66, $66, $66, $3C, $3C, $00, $00, $00, $00
db $FF, $FF, $00, $00, $00, $00, $0E, $0E, $4E, $4E, $3C, $3C, $00, $00, $00, $00
db $FF, $FF
ds 14, $00
db $FF, $FF
ds 14, $00
db $FF, $FF
ds 14, $00
db $FF, $FF, $00, $00, $00, $00, $10, $10, $10, $10, $11, $11, $12, $12, $14, $14
db $F8, $F8, $00, $00, $00, $00, $40, $40, $80, $80
ds 12, $00
db $40, $40, $40, $40, $20, $20, $18, $18, $07, $07, $00, $00, $00, $00, $00, $00
db $02, $02, $02, $02, $04, $04, $18, $18, $E0, $E0
ds 12, $00
db $07, $07, $18, $18, $20, $20, $40, $40, $40, $40, $00, $00, $00, $00, $00, $00
db $E0, $E0, $18, $18, $04, $04, $02, $02, $02, $02
ds 16, $80
db $00, $00, $00, $00, $00, $00, $FF, $FF
ds 24, $00
ds 16, $01
db $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $00, $00, $00, $00, $00, $00
db $00, $00, $42, $42, $24, $24, $18, $18, $18, $18, $24, $24, $42, $42, $00, $00
db $00, $00, $60, $60, $18, $18, $06, $06, $01, $01, $06, $06, $18, $18, $60, $60
db $00, $00, $06, $06, $18, $18, $60, $60, $80, $80, $60, $60, $18, $18, $06, $06
db $00, $00, $00, $00, $00, $00, $00, $00, $40, $40, $20, $20, $13, $13, $0C, $0C
db $00, $00, $00, $00, $03, $03, $0C, $0C, $30, $30, $C0, $C0, $00, $00, $00, $00
db $7E, $7E, $C3, $C3, $FF, $FF, $81, $81, $85, $85, $81, $81, $85, $85, $81, $81
db $85, $85, $81, $81, $85, $85, $81, $81, $85, $85, $81, $81, $81, $81, $FF, $FF
db $10, $10, $38, $38, $7C, $7C, $FE, $FE, $10, $10, $10, $10, $10, $10, $00, $00
db $10, $10, $10, $10, $10, $10, $FE, $FE, $7C, $7C, $38, $38, $10, $10, $00, $00
db $FF, $FF, $E6, $E6, $C3, $C3, $C3, $C3, $E7, $E7, $FF, $FF, $E7, $E7, $FF, $FF
db $10, $10, $08, $08, $04, $04, $03, $03, $00, $00, $00, $00, $00, $00, $00, $00
db $10, $10, $20, $20, $40, $40, $80, $80
ds 14, $00
db $03, $03, $04, $04, $08, $08, $10, $10, $10, $10, $00, $00, $00, $00, $00, $00
db $80, $80, $40, $40, $20, $20
ds 20, $10
db $00, $00, $00, $00, $00, $00, $FF, $FF
ds 12, $00
db $3C, $3C, $3C, $3C, $3C, $3C, $3C, $3C, $00, $00, $00, $00, $FF, $00, $FF, $1C
db $FF, $10, $FF, $10, $FF, $10, $FF, $50, $FF, $20, $FF
ds 11, $00
db $07, $07, $07, $07, $06, $06
ds 10, $00
db $FF, $FF, $FF, $FF
ds 12, $00
db $E0, $E0, $E0, $E0, $60, $60
ds 16, $06
ds 16, $60
db $06, $06, $07, $07, $07, $07
ds 12, $00
db $FF, $FF, $FF, $FF
ds 10, $00
db $60, $60, $E0, $E0, $E0, $E0
ds 10, $00
db $C4, $C4, $C5
ds 14, $C6
db $C7, $C4, $C4, $C4, $C4, $C8, $00, $01, $02, $03, $04, $05, $06, $07, $08, $09
db $0A, $0B, $0C, $0D, $C9, $C4, $C4, $C4, $C4, $C8, $0E, $0F, $10, $11, $12, $13
db $14, $15, $16, $17, $18, $19, $1A, $1B, $C9, $C4, $C4, $C4, $C4, $C8, $1C, $1D
db $1E, $1F, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $C9, $C4, $C4, $C4
db $C4, $C8, $2A, $2B, $2C, $2D, $2E, $2F, $30, $31, $32, $33, $34, $35, $36, $37
db $C9, $C4, $C4, $C4, $C4, $C8, $38, $39, $3A, $3B, $3C, $3D, $3E, $3F, $40, $41
db $42, $43, $44, $45, $C9, $C4, $C4, $C4, $C4, $C8, $46, $47, $48, $49, $4A, $4B
db $4C, $4D, $4E, $4F, $50, $51, $52, $53, $C9, $C4, $C4, $C4, $C4, $C8, $54, $55
db $56, $57, $58, $59, $5A, $5B, $5C, $5D, $5E, $5F, $60, $61, $C9, $C4, $C4, $C4
db $C4, $C8, $62, $63, $64, $65, $66, $67, $68, $69, $6A, $6B, $6C, $6D, $6E, $6F
db $C9, $C4, $C4, $C4, $C4, $C8, $70, $71, $72, $73, $74, $75, $76, $77, $78, $79
db $7A, $7B, $7C, $7D, $C9, $C4, $C4, $C4, $C4, $C8, $7E, $7F, $80, $81, $82, $83
db $84, $85, $86, $87, $88, $89, $8A, $8B, $C9, $C4, $C4, $C4, $C4, $C8, $8C, $8D
db $8E, $8F, $90, $91, $92, $93, $94, $95, $96, $97, $98, $99, $C9, $C4, $C4, $C4
db $C4, $C8, $9A, $9B, $9C, $9D, $9E, $9F, $A0, $A1, $A2, $A3, $A4, $A5, $A6, $A7
db $C9, $C4, $C4, $C4, $C4, $C8, $A8, $A9, $AA, $AB, $AC, $AD, $AE, $AF, $B0, $B1
db $B2, $B3, $B4, $B5, $C9, $C4, $C4, $C4, $C4, $C8, $B6, $B7, $B8, $B9, $BA, $BB
db $BC, $BD, $BE, $BF, $C0, $C1, $C2, $C3, $C9, $C4, $C4, $C4, $C4, $CA
ds 14, $CB
db $CC
ds 42, $C4
ds 18, $FF
db $07, $07, $33, $33, $39, $39, $39, $39, $39, $39, $39, $39, $33, $33, $FF, $FF
db $07, $07, $33, $33, $39, $39, $39, $39, $39, $39, $33, $33, $07, $07, $FF, $FF
db $C7, $C7, $93, $93
ds 10, $39
db $FF, $FF, $C7, $C7, $83, $83, $19, $19, $3D, $3D, $3F, $3F, $3F, $3F, $3F, $3F
db $FF, $FF, $07, $07, $33, $33, $39, $39, $39, $39, $39, $39, $33, $33, $07, $07
db $FF, $FF, $C7, $C7, $83, $83, $B3, $B3, $39, $39, $39, $39, $79, $79, $79, $79
db $FF, $FF, $7D, $7D, $39, $39, $39, $39, $11, $11, $55, $55, $45, $45, $45, $45
db $FF, $FF, $C7, $C7, $83, $83, $B3, $B3, $39, $39, $39, $39, $79, $79, $79, $79
db $FF, $FF, $C7, $C7, $83, $83, $19, $19, $3D, $3D, $3D, $3D, $3F, $3F, $3F, $3F
db $FF, $FF, $C3, $C3, $C3, $C3
ds 10, $E7
db $FF, $FF, $C7, $C7, $93, $93
ds 10, $39
db $FF, $FF, $79, $79, $39, $39, $39, $39, $19, $19, $19, $19, $59, $59, $49, $49
ds 18, $FF
db $07, $07, $33, $33, $39, $39, $39, $39, $39, $39, $33, $33, $0F, $0F, $FF, $FF
db $C7, $C7, $83, $83, $B3, $B3, $39, $39, $39, $39, $79, $79, $79, $79, $FF, $FF
db $C7, $C7, $93, $93, $39, $39, $3D, $3D, $3F, $3F, $9F, $9F, $CF, $CF, $FF, $FF
db $C3, $C3, $C3, $C3
ds 10, $E7
db $FF, $FF, $C7, $C7, $83, $83, $19, $19, $3D, $3D, $3D, $3D, $3F, $3F, $3F, $3F
ds 32, $FF
db $03, $03, $0F, $0F
ds 10, $3F
db $FF, $FF, $0F, $0F, $2F, $2F, $2F, $2F, $27, $27, $37, $37, $31, $31, $39, $39
db $FF, $FF
ds 10, $39
db $93, $93, $C7, $C7, $FF, $FF, $31, $31, $39, $39, $39, $39, $39, $39, $19, $19
db $83, $83, $C7, $C7, $FF, $FF, $0F, $0F, $2F, $2F, $2F, $2F, $27, $27, $37, $37
db $31, $31, $39, $39, $FF, $FF, $01, $01
ds 12, $79
db $FF, $FF, $6D, $6D, $6D, $6D, $6D, $6D, $7D, $7D, $7D, $7D, $7D, $7D, $7D, $7D
db $FF, $FF, $01, $01
ds 12, $79
db $FF, $FF, $3F, $3F, $3F, $3F, $3D, $3D, $3D, $3D, $19, $19, $83, $83, $C7, $C7
db $FF, $FF
ds 10, $E7
db $C3, $C3, $C3, $C3, $FF, $FF
ds 10, $39
db $93, $93, $C7, $C7, $FF, $FF, $69, $69, $69, $69, $61, $61, $71, $71, $71, $71
db $71, $71, $79, $79
ds 18, $FF
db $33, $33, $39, $39, $39, $39, $39, $39, $39, $39, $33, $33, $07, $07, $FF, $FF
db $01, $01
ds 12, $79
db $FF, $FF, $F3, $F3, $F9, $F9, $79, $79, $79, $79, $31, $31, $83, $83, $C7, $C7
db $FF, $FF
ds 10, $E7
db $C3, $C3, $C3, $C3, $FF, $FF, $3F, $3F, $3F, $3F, $3D, $3D, $3D, $3D, $19, $19
db $83, $83, $C7, $C7
ds 132, $FF
db $0F, $0F, $03, $03, $71, $71, $79, $79, $79, $79, $79, $79, $79, $79, $FF, $FF
db $C3, $C3, $C3, $C3
ds 10, $E7
db $FF, $FF, $07, $07, $33, $33, $39, $39, $39, $39, $39, $39, $33, $33, $0F, $0F
db $FF, $FF
ds 14, $79
db $FF, $FF, $E1, $E1, $E1, $E1
ds 10, $F3
db $FF, $FF, $C7, $C7, $93, $93
ds 10, $39
ds 224, $FF
db $79, $79, $79, $79, $79, $79, $79, $79, $71, $71, $03, $03, $0F, $0F, $FF, $FF
ds 10, $E7
db $C3, $C3, $C3, $C3, $FF, $FF, $33, $33, $39, $39, $39, $39, $39, $39, $39, $39
db $33, $33, $07, $07, $FF, $FF, $79, $79, $79, $79, $79, $79, $71, $71, $71, $71
db $23, $23, $87, $87, $FF, $FF, $F3, $F3, $F3, $F3, $73, $73, $73, $73, $33, $33
db $03, $03, $87, $87, $FF, $FF
ds 10, $39
db $93, $93, $C7, $C7
ds 114, $FF
db $00, $00, $00, $00, $08, $08, $1C, $1C, $3E, $3E, $3E, $3E, $00, $00, $00, $00
db $00, $00, $3C, $3C, $4E, $4E, $4E, $4E, $7E, $7E, $4E, $4E, $4E, $4E, $00, $00
db $00, $00, $7C, $7C, $66, $66, $7C, $7C, $66, $66, $66, $66, $7C, $7C, $00, $00
db $00, $00, $3C, $3C, $66, $66, $60, $60, $60, $60, $66, $66, $3C, $3C, $00, $00
db $00, $00, $7C, $7C, $4E, $4E, $4E, $4E, $4E, $4E, $4E, $4E, $7C, $7C, $00, $00
db $00, $00, $7E, $7E, $60, $60, $7C, $7C, $60, $60, $60, $60, $7E, $7E, $00, $00
db $00, $00, $7E, $7E, $60, $60, $60, $60, $7C, $7C, $60, $60, $60, $60, $00, $00
db $00, $00, $3C, $3C, $66, $66, $60, $60, $6E, $6E, $66, $66, $3E, $3E, $00, $00
db $00, $00, $46, $46, $46, $46, $7E, $7E, $46, $46, $46, $46, $46, $46, $00, $00
db $00, $00, $3C, $3C, $18, $18, $18, $18, $18, $18, $18, $18, $3C, $3C, $00, $00
db $00, $00, $1E, $1E, $0C, $0C, $0C, $0C, $6C, $6C, $6C, $6C, $38, $38, $00, $00
db $00, $00, $66, $66, $6C, $6C, $78, $78, $78, $78, $6C, $6C, $66, $66, $00, $00
db $00, $00
ds 10, $60
db $7E, $7E, $00, $00, $00, $00, $46, $46, $6E, $6E, $7E, $7E, $56, $56, $46, $46
db $46, $46, $00, $00, $00, $00, $46, $46, $66, $66, $76, $76, $5E, $5E, $4E, $4E
db $46, $46, $00, $00, $00, $00, $3C, $3C, $66, $66, $66, $66, $66, $66, $66, $66
db $3C, $3C, $00, $00, $00, $00, $7C, $7C, $66, $66, $66, $66, $7C, $7C, $60, $60
db $60, $60, $00, $00, $00, $00, $3C, $3C, $62, $62, $62, $62, $6A, $6A, $64, $64
db $3A, $3A, $00, $00, $00, $00, $7C, $7C, $66, $66, $66, $66, $7C, $7C, $68, $68
db $66, $66, $00, $00, $00, $00, $3C, $3C, $60, $60, $3C, $3C, $0E, $0E, $4E, $4E
db $3C, $3C, $00, $00, $00, $00, $7E, $7E
ds 10, $18
db $00, $00, $00, $00, $46, $46, $46, $46, $46, $46, $46, $46, $4E, $4E, $3C, $3C
db $00, $00, $00, $00, $46, $46, $46, $46, $46, $46, $46, $46, $2C, $2C, $18, $18
db $00, $00, $00, $00, $46, $46, $46, $46, $56, $56, $7E, $7E, $6E, $6E, $46, $46
db $00, $00, $00, $00, $46, $46, $2C, $2C, $18, $18, $38, $38, $64, $64, $42, $42
db $00, $00, $00, $00, $66, $66, $66, $66, $3C, $3C, $18, $18, $18, $18, $18, $18
db $00, $00, $00, $00, $7E, $7E, $0E, $0E, $1C, $1C, $38, $38, $70, $70, $7E, $7E
db $00, $00, $00, $00, $44, $44, $30, $30, $7C, $7C, $4C, $4C, $7C, $7C, $4C, $4C
db $00, $00, $00, $00, $44, $44, $38, $38, $4C, $4C, $4C, $4C, $4C, $4C, $38, $38
db $00, $00, $66, $66, $00, $00, $46, $46, $46, $46, $46, $46, $4E, $4E, $3C, $3C
ds 10, $00
db $18, $18, $18, $18, $08, $08, $10, $10, $00, $00, $00, $00, $00, $00, $18, $18
db $18, $18
ds 20, $00
db $FF, $FF, $00, $00, $00, $00, $38, $38, $0C, $0C, $3C, $3C, $4C, $4C, $7E, $7E
db $00, $00, $00, $00, $60, $60, $60, $60, $78, $78, $64, $64, $64, $64, $78, $78
db $00, $00, $00, $00, $00, $00, $3C, $3C, $64, $64, $60, $60, $64, $64, $3C, $3C
db $00, $00, $00, $00, $0C, $0C, $0C, $0C, $3C, $3C, $4C, $4C, $4C, $4C, $3C, $3C
db $00, $00, $00, $00, $00, $00, $38, $38, $6C, $6C, $7C, $7C, $60, $60, $3C, $3C
db $00, $00, $00, $00, $1C, $1C, $30, $30, $7C, $7C, $30, $30, $30, $30, $30, $30
db $00, $00, $00, $00, $00, $00, $3C, $3C, $4C, $4C, $3C, $3C, $0C, $0C, $78, $78
db $00, $00, $00, $00, $60, $60, $60, $60, $78, $78, $6C, $6C, $6C, $6C, $6C, $6C
db $00, $00, $00, $00, $18, $18, $00, $00, $18, $18, $18, $18, $18, $18, $18, $18
db $00, $00, $00, $00, $0C, $0C, $00, $00, $0C, $0C, $0C, $0C, $2C, $2C, $3C, $3C
db $18, $18, $00, $00, $60, $60, $6C, $6C, $78, $78, $70, $70, $78, $78, $6C, $6C
db $00, $00, $00, $00
ds 12, $18
db $00, $00, $00, $00, $00, $00, $AC, $AC, $D6, $D6, $D6, $D6, $D6, $D6, $D6, $D6
db $00, $00, $00, $00, $00, $00, $58, $58, $6C, $6C, $6C, $6C, $6C, $6C, $6C, $6C
db $00, $00, $00, $00, $00, $00, $38, $38, $6C, $6C, $6C, $6C, $6C, $6C, $38, $38
db $00, $00, $00, $00, $00, $00, $78, $78, $6C, $6C, $6C, $6C, $78, $78, $60, $60
db $60, $60, $00, $00, $00, $00, $3C, $3C, $6C, $6C, $6C, $6C, $3C, $3C, $0C, $0C
db $0C, $0C, $00, $00, $00, $00, $58, $58, $74, $74, $60, $60, $60, $60, $60, $60
db $00, $00, $00, $00, $00, $00, $3C, $3C, $60, $60, $38, $38, $0C, $0C, $7C, $7C
db $00, $00, $00, $00, $30, $30, $7C, $7C, $30, $30, $30, $30, $34, $34, $18, $18
db $00, $00, $00, $00, $00, $00, $6C, $6C, $6C, $6C, $6C, $6C, $6C, $6C, $3A, $3A
db $00, $00, $00, $00, $00, $00, $6C, $6C, $6C, $6C, $6C, $6C, $38, $38, $10, $10
db $00, $00, $00, $00, $00, $00, $C6, $C6, $D6, $D6, $D6, $D6, $EE, $EE, $44, $44
db $00, $00, $00, $00, $00, $00, $66, $66, $3C, $3C, $18, $18, $3C, $3C, $66, $66
db $00, $00, $00, $00, $00, $00, $22, $22, $36, $36, $1C, $1C, $0C, $0C, $18, $18
db $70, $70, $00, $00, $00, $00, $7C, $7C, $18, $18, $30, $30, $60, $60, $7C, $7C
db $00, $00, $00, $00, $44, $44, $38, $38, $0C, $0C, $3C, $3C, $4C, $4C, $3E, $3E
db $00, $00, $00, $00, $24, $24, $18, $18, $2C, $2C, $2C, $2C, $2C, $2C, $18, $18
db $00, $00, $6C, $6C, $00, $00, $00, $00, $6C, $6C, $6C, $6C, $6C, $6C, $3A, $3A
ds 20, $00
db $7C, $7C, $4C, $4C, $0C, $0C, $38, $38, $00, $00, $38, $38, $00, $00, $00, $00
db $3E, $3E, $67, $67, $6B, $6B, $6B, $6B, $73, $73, $3E, $3E, $00, $00, $00, $00
db $18, $18, $38, $38, $18, $18, $18, $18, $18, $18, $3C, $3C, $00, $00, $00, $00
db $3C, $3C, $4E, $4E, $0E, $0E, $3C, $3C, $70, $70, $7E, $7E, $00, $00, $00, $00
db $7C, $7C, $0E, $0E, $3C, $3C, $0E, $0E, $0E, $0E, $7C, $7C, $00, $00, $00, $00
db $3C, $3C, $6C, $6C, $4C, $4C, $4E, $4E, $7E, $7E, $0C, $0C, $00, $00, $00, $00
db $7C, $7C, $60, $60, $7C, $7C, $0E, $0E, $4E, $4E, $3C, $3C, $00, $00, $00, $00
db $3C, $3C, $60, $60, $7C, $7C, $66, $66, $66, $66, $3C, $3C, $00, $00, $00, $00
db $7E, $7E, $06, $06, $0C, $0C, $18, $18, $38, $38, $38, $38, $00, $00, $00, $00
db $3C, $3C, $4E, $4E, $3C, $3C, $4E, $4E, $4E, $4E, $3C, $3C, $00, $00, $00, $00
db $3C, $3C, $4E, $4E, $4E, $4E, $3E, $3E, $0E, $0E, $3C, $3C, $00, $00, $00, $00
db $00, $00, $10, $10, $10, $10, $10, $7C, $10, $10, $10, $10
ds 10, $00
db $7C, $7C
ds 10, $00
db $44, $44, $28, $28, $10, $10, $28, $28, $44, $44, $00, $00, $00, $00, $00, $00
db $10, $10, $00, $00, $7C, $7C, $00, $00, $10, $10, $00, $00, $00, $00, $00, $00
db $00, $00, $7C, $7C, $00, $00, $7C, $7C, $00, $00, $00, $00, $00, $00, $1E, $1E
db $18, $18, $18, $18, $58, $58, $38, $38, $18, $18, $00, $00, $00, $00, $18, $18
db $00, $00, $38, $38, $70, $70, $72, $72, $76, $76, $3C, $3C, $00, $00, $18, $18
db $00, $00, $18, $18, $3C, $3C, $3C, $3C, $3C, $3C, $18, $18, $00, $00, $30, $30
ds 10, $60
db $30, $30, $00, $00, $0C, $0C
ds 10, $06
db $0C, $0C, $00, $00, $3C, $3C, $0C, $0C, $34, $34, $3A, $3A, $00, $00, $3C, $3C
db $00, $00, $34, $34, $28, $28, $46, $46, $66, $66, $76, $76, $5E, $5E, $4E, $4E
db $00, $00, $18, $18, $60, $60, $38, $38, $4C, $4C, $4C, $4C, $7C, $7C, $4C, $4C
db $00, $00, $0C, $0C, $30, $30, $7E, $7E, $60, $60, $7C, $7C, $60, $60, $7E, $7E
db $00, $00, $0C, $0C, $30, $30, $3C, $3C, $18, $18, $18, $18, $18, $18, $3C, $3C
db $00, $00, $0C, $0C, $30, $30, $3C, $3C, $66, $66, $66, $66, $66, $66, $3C, $3C
db $00, $00, $0C, $0C, $10, $10, $46, $46, $46, $46, $46, $46, $4E, $4E, $3C, $3C
db $00, $00, $00, $00, $18, $18, $34, $34, $3C, $3C, $18, $18, $00, $00, $3C, $3C
db $00, $00, $68, $68, $50, $50, $00, $00, $58, $58, $6C, $6C, $6C, $6C, $6C, $6C
db $00, $00, $18, $18, $60, $60, $00, $00, $78, $78, $18, $18, $68, $68, $74, $74
db $00, $00, $0C, $0C, $30, $30, $00, $00, $3C, $3C, $4C, $4C, $70, $70, $3C, $3C
db $00, $00, $0C, $0C, $30, $30, $00, $00, $38, $38, $18, $18, $18, $18, $3C, $3C
db $00, $00, $0C, $0C, $30, $30, $00, $00, $3C, $3C, $66, $66, $66, $66, $3C, $3C
db $00, $00, $18, $18, $60, $60, $00, $00, $6C, $6C, $6C, $6C, $6C, $6C, $3A, $3A
db $00, $00, $FF, $FF, $FF, $FF, $00, $00, $18, $18, $18, $18, $00, $00, $FF, $FF
db $FF, $FF, $00, $FF, $00, $C3, $00, $99, $00, $99, $00, $99, $00, $99, $00, $C3
db $00, $FF, $00, $FF, $00, $E7, $00, $C7, $00, $E7, $00, $E7, $00, $E7, $00, $C3
db $00, $FF, $00, $FF, $00, $C3, $00, $B1, $00, $F1, $00, $C3, $00, $8F, $00, $81
db $00, $FF, $00, $FF, $00, $83, $00, $F1, $00, $C3, $00, $F1, $00, $F1, $00, $83
db $00, $FF, $00, $FF, $00, $C3, $00, $93, $00, $B3, $00, $B1, $00, $81, $00, $F3
db $00, $FF, $00, $FF, $00, $83, $00, $9F, $00, $83, $00, $F1, $00, $B1, $00, $C3
db $00, $FF, $00, $FF, $00, $C3, $00, $9F, $00, $83, $00, $99, $00, $99, $00, $C3
db $00, $FF, $00, $FF, $00, $81, $00, $F9, $00, $F3, $00, $E7, $00, $C7, $00, $C7
db $00, $FF, $00, $FF, $00, $C3, $00, $B1, $00, $C3, $00, $B1, $00, $B1, $00, $C3
db $00, $FF, $00, $FF, $00, $C3, $00, $B1, $00, $B1, $00, $C1, $00, $F1, $00, $C3
db $00, $FF, $00, $00, $00, $00, $00, $00, $1E, $1E, $21, $21, $4C, $4C, $42, $42
db $43, $43, $00, $00, $00, $00, $00, $00, $00, $00, $FC, $FC, $82, $82, $FC, $FC
db $90, $90, $04, $04, $03, $03, $44, $44, $23, $23, $10, $10, $0F, $0F, $00, $00
db $00, $00, $10, $10, $F0, $F0, $20, $20, $E0, $E0, $40, $40, $C0, $C0, $00, $00
db $00, $00, $00, $00, $06, $06, $0C, $0C, $18, $18, $30, $30, $60, $60, $40, $40
db $00, $00, $00, $00, $00, $00, $00, $00, $07, $07, $18, $18, $20, $20, $40, $40
db $40, $40, $00, $00, $00, $00, $00, $00, $FF, $FF
ds 14, $00
db $E0, $E0, $18, $18, $04, $04, $02, $02, $02, $02
ds 16, $80
ds 16, $00
ds 16, $01
db $40, $40, $40, $40, $20, $20, $18, $18, $07, $07
ds 14, $00
db $FF, $FF, $00, $00, $00, $00, $00, $00, $02, $02, $02, $02, $04, $04, $18, $18
db $E0, $E0, $00, $00, $00, $00, $00, $00
ds 16, $FF
db $28, $28, $28, $28, $7C, $7C, $28, $28, $7C, $7C, $28, $28, $28, $28, $00, $00
db $00, $00, $00, $00, $3E, $3E, $3E, $3E, $1C, $1C, $08, $08, $00, $00, $00, $00
db $00, $00, $00, $00, $18, $18, $18, $18, $00, $00, $18, $18, $18, $18
ds 14, $00
db $FF, $FF, $FF, $FF, $00, $00, $18, $18, $18, $18, $18, $18, $18, $18, $00, $00
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
db $11, $F0, $DC, $06, $10, $1A, $22, $13, $05, $20, $FA, $C9, $11, $F0, $DC, $06
db $10, $2A, $12, $13, $05, $20, $FA, $C9, $01, $00, $00, $2E, $00, $7C, $B7, $28
db $17, $7B, $94, $5F, $7A, $DE, $00, $57, $38, $08, $0C, $20, $F4, $04, $0E, $00
db $18, $EF, $7B, $B7, $28, $02, $84, $6F, $C9, $16, $00, $1E, $00, $B7, $28, $13
db $C5, $4F, $78, $B7, $79, $C1, $28, $0B, $4F, $7B, $81, $5F, $7A, $CE, $00, $57
db $05, $20, $F6, $C9, $85, $6F, $7C, $CE, $00, $67, $C9, $CD, $F0, $0A, $CD, $10
db $0B, $21, $00, $98, $3E, $BE, $22, $7C, $FE, $9C, $20, $F8, $F0, $10, $E6, $CF
db $F6, $C1, $E0, $10, $C9, $CD, $F0, $0A, $CD, $10, $0B, $21, $00, $9C, $3E, $BE
db $22, $7C, $FE, $A0, $20, $F8, $F0, $10, $F6, $A1, $E0, $10, $C9, $FA, $CB, $C8
db $CB, $3F, $CB, $3F, $CB, $3F, $D6, $04, $EA, $3A, $D0, $FA, $CA, $C8, $CB, $3F
db $CB, $3F, $CB, $3F, $D6, $03, $06, $0E, $CD, $2A, $29, $7B, $21, $3A, $D0, $86
db $CB, $7F, $F5, $CB, $BF, $06, $10, $CD, $2A, $29, $F1, $20, $05, $21, $00, $90
db $18, $03, $21, $00, $88, $19, $C9, $C5, $E5, $21, $00, $0A, $01, $00, $00, $2E
db $00, $7C, $B7, $28, $11, $7B, $94, $5F, $7A, $DE, $00, $57, $38, $08, $0C, $20
db $F4, $04, $0E, $00, $18, $EF, $7B, $B7, $28, $02, $84, $6F, $78, $57, $79, $5F
db $7D, $E1, $C1, $C9, $F3, $3E, $37, $E0, $06, $E0, $05, $3E, $04, $E0, $07, $F0
db $FF, $F6, $01, $E0, $FF, $F0, $10, $F6, $02, $E0, $10, $3E, $1B, $E0, $15, $FB
db $CD, $52, $04, $CD, $4C, $29, $FA, $6C, $D0, $EA, $CC, $C8, $3E, $03, $EA, $CA
db $C8, $0E, $00, $3E, $02, $EA, $CB, $C8, $06, $03, $CD, $91, $04, $FA, $CA, $C8
db $3C, $EA, $CA, $C8, $FA, $CC, $C8, $3C, $EA, $CC, $C8, $F5, $C5, $D5, $E5, $CD
db $F0, $0A, $3E, $00, $CD, $BF, $0A, $E1, $D1, $C1, $F1, $FA, $CA, $C8, $3D, $EA
db $CA, $C8, $FA, $CB, $C8, $3C, $EA, $CB, $C8, $FA, $CC, $C8, $3C, $EA, $CC, $C8
db $05, $20, $C7, $0C, $FA, $6D, $D0, $B9, $28, $1D, $79, $FE, $03, $28, $0E, $FE
db $06, $28, $0A, $FA, $CB, $C8, $C6, $04, $EA, $CB, $C8, $18, $AB, $FA, $CA, $C8
db $C6, $04, $EA, $CA, $C8, $18, $9C, $FA, $6C, $D0, $EA, $CC, $C8, $3E, $20, $EA
db $CA, $C8, $3E, $19, $EA, $CB, $C8, $3E, $10, $EA, $CD, $C8, $21, $5F, $D0, $06
db $03, $C5, $E5, $CD, $33, $0A, $E1, $78, $22, $FA, $CB, $C8, $C6, $08, $EA, $CB
db $C8, $FA, $CC, $C8, $C6, $02, $EA, $CC, $C8, $C1, $05, $20, $E4, $3E, $00, $EA
db $6E, $D0, $EA, $5D, $D0, $EA, $5E, $D0, $EA, $5C, $D0, $EA, $5B, $D0, $CD, $51
db $0E, $CD, $A2, $01, $CD, $23, $30, $21, $6D, $D0, $FA, $25, $D0, $FE, $2E, $CA
db $01, $2C, $D6, $30, $38, $09, $BE, $30, $06, $EA, $6E, $D0, $C3, $01, $2C, $FA
db $06, $D0, $E6, $F4, $20, $0F, $AF, $EA, $5D, $D0, $EA, $5E, $D0, $EA, $5C, $D0
db $EA, $5B, $D0, $18, $C9, $CB, $57, $C2, $01, $2C, $CD, $05, $2C, $FA, $5E, $D0
db $21, $12, $05, $BE, $23, $28, $2B, $30, $FA, $FA, $5D, $D0, $21, $12, $05, $BE
db $23, $28, $60, $30, $FA, $FA, $5C, $D0, $21, $12, $05, $BE, $23, $CA, $DC, $2B
db $30, $F9, $FA, $5B, $D0, $21, $12, $05, $BE, $23, $CA, $B3, $2B, $30, $F9, $C3
db $BF, $2A, $FA, $6E, $D0, $3C, $21, $6D, $D0, $BE, $D2, $BF, $2A, $F5, $EA, $6E
db $D0, $FA, $5F, $D0, $EA, $CC, $C8, $CD, $17, $0B, $CD, $42, $30, $F1, $FE, $03
db $28, $0E, $FE, $06, $28, $0A, $FA, $CB, $C8, $C6, $38, $EA, $CB, $C8, $18, $0D
db $3E, $19, $EA, $CB, $C8, $FA, $CA, $C8, $C6, $20, $EA, $CA, $C8, $CD, $4F, $2C
db $C3, $BF, $2A, $FA, $6E, $D0, $3D, $FE, $FF, $CA, $BF, $2A, $F5, $EA, $6E, $D0
db $FA, $5F, $D0, $EA, $CC, $C8, $CD, $17, $0B, $CD, $42, $30, $F1, $FE, $05, $28
db $0E, $FE, $02, $28, $0A, $FA, $CB, $C8, $D6, $38, $EA, $CB, $C8, $18, $0D, $3E
db $89, $EA, $CB, $C8, $FA, $CA, $C8, $D6, $20, $EA, $CA, $C8, $CD, $4F, $2C, $C3
db $BF, $2A, $FA, $6E, $D0, $C6, $03, $21, $6D, $D0, $BE, $D2, $BF, $2A, $EA, $6E
db $D0, $FA, $5F, $D0, $EA, $CC, $C8, $CD, $17, $0B, $CD, $42, $30, $FA, $CA, $C8
db $C6, $20, $EA, $CA, $C8, $CD, $4F, $2C, $C3, $BF, $2A, $FA, $6E, $D0, $D6, $03
db $DA, $BF, $2A, $EA, $6E, $D0, $FA, $5F, $D0, $EA, $CC, $C8, $CD, $17, $0B, $CD
db $42, $30, $FA, $CA, $C8, $D6, $20, $EA, $CA, $C8, $CD, $4F, $2C, $C3, $BF, $2A
db $CD, $42, $30, $C9, $CB, $67, $28, $08, $FA, $5E, $D0, $3C, $CB, $BF, $18, $01
db $AF, $EA, $5E, $D0, $FA, $06, $D0, $CB, $6F, $28, $08, $FA, $5D, $D0, $3C, $CB
db $BF, $18, $01, $AF, $EA, $5D, $D0, $FA, $06, $D0, $CB, $77, $28, $08, $FA, $5C
db $D0, $3C, $CB, $BF, $18, $01, $AF, $EA, $5C, $D0, $FA, $06, $D0, $CB, $7F, $28
db $08, $FA, $5B, $D0, $3C, $CB, $BF, $18, $01, $AF, $EA, $5B, $D0, $C9, $FA, $6E
db $D0, $06, $06, $CD, $2A, $29, $FA, $6C, $D0, $83, $EA, $CC, $C8, $3E, $10, $EA
db $CD, $C8, $06, $03, $21, $5F, $D0, $C5, $E5, $CD, $33, $0A, $E1, $78, $22, $FA
db $CC, $C8, $C6, $02, $EA, $CC, $C8, $FA, $CB, $C8, $C6, $08, $EA, $CB, $C8, $C1
db $05, $20, $E4, $C9, $C5, $CB, $27, $CB, $27, $CB, $27, $CB, $27, $4F, $FA, $D7
db $C8, $B1, $EA, $00, $10, $00, $00, $00, $3E, $0A, $CD, $A0, $2C, $C1, $C9, $3D
db $20, $FD, $C9, $E5, $21, $D7, $C8, $B6, $EA, $00, $10, $00, $00, $00, $3E, $05
db $CD, $A0, $2C, $E1, $C9, $CB, $7C, $28, $02, $7E, $C9, $E5, $7C, $E6, $60, $1F
db $CD, $A4, $2C, $7C, $E6, $1F, $C6, $A0, $67, $7E, $E1, $C9, $CB, $7C, $28, $02
db $77, $C9, $E5, $F5, $7C, $E6, $60, $1F, $CD, $A4, $2C, $7C, $E6, $1F, $C6, $A0
db $67, $F1, $77, $E1, $C9, $E5, $69, $60, $CD, $F6, $2C, $E1, $C9, $E5, $6B, $62
db $CD, $F6, $2C, $E1, $C9, $CB, $7C, $28, $02, $7E, $C9, $C5, $E5, $7C, $E6, $60
db $4F, $7C, $E6, $1F, $67, $79, $01, $00, $A0, $09, $CB, $37, $CB, $3F, $CD, $85
db $2C, $7E, $F5, $AF, $CD, $85, $2C, $F1, $E1, $C1, $C9, $CB, $7C, $28, $02, $77
db $C9, $C5, $E5, $F5, $7C, $E6, $60, $4F, $7C, $E6, $1F, $67, $79, $CB, $37, $CB
db $3F, $CD, $85, $2C, $01, $00, $A0, $09, $F1, $77, $AF, $CD, $85, $2C, $E1, $C1
db $C9, $E5, $69, $60, $CD, $1C, $2D, $E1, $C9, $E5, $6B, $62, $CD, $1C, $2D, $E1
db $C9, $FA, $00, $A0, $EA, $A1, $D4, $A7, $28, $33, $21, $00, $A0, $23, $06, $01
db $11, $28, $D0, $0E, $0C, $1A, $BE, $20, $0B, $13, $23, $0D, $20, $F7, $78, $EA
db $4B, $D0, $18, $1D, $3E, $12, $C5, $CD, $2A, $29, $C1, $21, $00, $A0, $23, $7B
db $CD, $45, $29, $7A, $84, $67, $04, $FA, $A1, $D4, $B8, $30, $D3, $AF, $EA, $4B
db $D0, $C9, $FA, $00, $A0, $06, $12, $CD, $2A, $29, $21, $00, $A0, $19, $2B, $2A
db $EA, $3A, $D0, $2A, $EA, $3B, $D0, $CD, $52, $2D, $FA, $4B, $D0, $A7, $CA, $47
db $2E, $47, $FA, $00, $A0, $B8, $CA, $3C, $2E, $2A, $EA, $4D, $D0, $2A, $EA, $4E
db $D0, $56, $23, $5E, $23, $46, $23, $4E, $03, $FA, $3A, $D0, $67, $FA, $3B, $D0
db $6F, $23, $CD, $E6, $2C, $CD, $4A, $2D, $03, $13, $7C, $B8, $20, $F4, $7D, $B9
db $20, $F0, $FA, $4B, $D0, $3D, $06, $12, $CD, $2A, $29, $21, $00, $A0, $23, $19
db $5D, $54, $3E, $12, $CD, $45, $29, $4D, $44, $C5, $D5, $FA, $00, $A0, $06, $12
db $CD, $2A, $29, $21, $00, $A0, $23, $19, $D1, $C1, $0A, $12, $03, $13, $7C, $B8
db $20, $F8, $7D, $B9, $20, $F4, $FA, $4B, $D0, $3D, $06, $12, $CD, $2A, $29, $21
db $00, $A0, $23, $19, $FA, $4B, $D0, $57, $FA, $00, $A0, $5F, $3E, $0E, $CD, $45
db $29, $14, $7B, $BA, $38, $05, $CD, $4D, $2E, $18, $F1, $FA, $00, $A0, $3D, $EA
db $00, $A0, $3E, $01, $18, $02, $3E, $06, $EA, $25, $D0, $C9, $D5, $0E, $02, $56
db $23, $5E, $FA, $4E, $D0, $47, $7B, $90, $5F, $FA, $4D, $D0, $47, $7A, $98, $57
db $73, $2B, $72, $23, $23, $0D, $20, $E7, $D1, $C9, $FA, $4C, $D0, $A7, $C2, $EE
db $2E, $CD, $09, $35, $28, $06, $3E, $A5, $EA, $25, $D0, $C9, $CD, $52, $2D, $FA
db $4B, $D0, $A7, $28, $10, $FA, $25, $D0, $FE, $F8, $28, $06, $3E, $F7, $EA, $25
db $D0, $C9, $CD, $93, $2D, $FA, $00, $A0, $A7, $28, $0A, $FE, $40, $20, $0F, $3E
db $06, $EA, $25, $D0, $C9, $16, $04, $1E, $85, $21, $00, $A0, $18, $18, $06, $12
db $CD, $2A, $29, $21, $00, $A0, $19, $2B, $56, $23, $5E, $13, $CB, $7A, $28, $06
db $3E, $06, $EA, $25, $D0, $C9, $7A, $EA, $4F, $D0, $7B, $EA, $50, $D0, $23, $11
db $28, $D0, $06, $0C, $1A, $22, $13, $05, $20, $FA, $23, $23, $FA, $4F, $D0, $22
db $FA, $50, $D0, $22, $3E, $01, $EA, $4C, $D0, $EA, $25, $D0, $C9, $FA, $50, $D0
db $6F, $FA, $4F, $D0, $67, $FA, $34, $D0, $A7, $28, $2C, $47, $11, $28, $D0, $1A
db $CD, $1C, $2D, $23, $13, $CB, $7C, $20, $18, $05, $20, $F3, $FA, $34, $D0, $FE
db $0C, $38, $14, $7D, $EA, $50, $D0, $7C, $EA, $4F, $D0, $3E, $01, $EA, $25, $D0
db $C9, $3E, $06, $EA, $25, $D0, $C9, $3E, $01, $EA, $25, $D0, $2B, $7D, $EA, $50
db $D0, $7C, $EA, $4F, $D0, $FA, $00, $A0, $3C, $EA, $00, $A0, $06, $12, $CD, $2A
db $29, $21, $00, $A0, $19, $FA, $50, $D0, $5F, $32, $FA, $4F, $D0, $57, $32, $4E
db $2B, $46, $13, $7B, $91, $5F, $7A, $98, $57, $2B, $73, $2B, $72, $C9, $FA, $4C
db $D0, $A7, $20, $30, $CD, $09, $35, $28, $06, $3E, $A5, $EA, $25, $D0, $C9, $CD
db $52, $2D, $FA, $4B, $D0, $A7, $28, $57, $23, $23, $2A, $EA, $4F, $D0, $2A, $EA
db $50, $D0, $23, $3A, $C6, $01, $EA, $4E, $D0, $3A, $CE, $00, $EA, $4D, $D0, $3E
db $01, $EA, $4C, $D0, $FA, $4F, $D0, $67, $FA, $50, $D0, $6F, $06, $0C, $11, $28
db $D0, $CD, $F6, $2C, $23, $12, $13, $FA, $4D, $D0, $BC, $20, $0B, $FA, $4E, $D0
db $BD, $20, $05, $05, $3E, $07, $18, $05, $05, $20, $E6, $3E, $01, $EA, $25, $D0
db $7C, $EA, $4F, $D0, $7D, $EA, $50, $D0, $3E, $0C, $90, $EA, $34, $D0, $C9, $3E
db $06, $EA, $25, $D0, $C9, $FE, $00, $28, $11, $FA, $4C, $D0, $FE, $00, $28, $3F
db $FE, $01, $28, $3B, $3D, $EA, $4C, $D0, $18, $0E, $FA, $4C, $D0, $3C, $EA, $4C
db $D0, $47, $FA, $00, $A0, $B8, $38, $27, $FA, $4C, $D0, $3D, $06, $12, $CD, $2A
db $29, $21, $00, $A0, $23, $19, $06, $0C, $11, $28, $D0, $2A, $12, $13, $05, $20
db $FA, $2A, $EA, $4D, $D0, $2A, $EA, $4E, $D0, $3E, $0C, $EA, $34, $D0, $C9, $AF
db $18, $F9, $FA, $25, $D0, $21, $06, $D0, $FE, $3D, $20, $02, $CB, $F6, $FE, $40
db $20, $02, $CB, $FE, $FE, $3E, $20, $02, $CB, $EE, $FE, $3F, $20, $02, $CB, $E6
db $C9, $0E, $03, $21, $5F, $D0, $7E, $36, $00, $23, $EA, $CC, $C8, $E5, $C5, $CD
db $5F, $0A, $C1, $E1, $0D, $20, $EF, $C9, $3E, $08, $EA, $23, $D0, $CD, $28, $0D
db $CD, $41, $0D, $FA, $21, $D0, $FE, $06, $28, $03, $00, $18, $FD, $C9, $06, $0C
db $21, $28, $D0, $7E, $FE, $81, $38, $08, $FE, $9B, $30, $04, $D6, $40, $18, $2D
db $FE, $A1, $38, $08, $FE, $BB, $30, $04, $D6, $40, $18, $21, $FE, $C0, $38, $08
db $FE, $CA, $30, $04, $D6, $90, $18, $15, $0E, $38, $57, $E5, $21, $A2, $04, $2A
db $BA, $28, $08, $23, $0D, $20, $F8, $E1, $23, $18, $03, $2A, $E1, $22, $05, $20
db $C2, $C9, $AF, $22, $15, $20, $FB, $C9, $16, $08, $C3, $C0, $30, $16, $0C, $0A
db $22, $03, $15, $20, $FA, $0B, $C9, $01, $00, $D4, $21, $18, $D4, $CD, $EA, $30
db $01, $0C, $D4, $21, $00, $D4, $CD, $EA, $30, $01, $18, $D4, $21, $0C, $D4, $CD
db $EA, $30, $21, $18, $D4, $16, $0C, $18, $C9, $16, $0A, $18, $D2, $21, $19, $D4
db $7E, $FE, $05, $30, $04, $36, $00, $3C, $C9, $36, $00, $23, $34, $7E, $FE, $0A
db $30, $01, $C9, $D6, $0A, $77, $18, $F3, $CD, $87, $31, $0A, $BE, $28, $03, $D8
db $AF, $C9, $0B, $2B, $15, $20, $F4, $C9, $FA, $0C, $D4, $C6, $07, $E6, $0F, $47
db $EA, $0C, $D4, $FA, $00, $D4, $C6, $07, $E6, $0F, $EA, $00, $D4, $B8, $28, $1C
db $38, $2C, $FA, $0C, $D4, $3C, $EA, $0C, $D4, $04, $C5, $01, $0E, $D4, $21, $0D
db $D4, $CD, $B9, $30, $AF, $02, $C1, $FA, $00, $D4, $18, $E1, $D6, $07, $E6, $0F
db $EA, $00, $D4, $FA, $0C, $D4, $D6, $07, $E6, $0F, $EA, $0C, $D4, $C9, $FA, $00
db $D4, $3C, $EA, $00, $D4, $C5, $01, $02, $D4, $21, $01, $D4, $18, $D3, $01, $01
db $D4, $21, $0D, $D4, $3E, $0A, $11, $19, $D4, $EA, $3C, $D4, $C9, $03, $12, $13
db $FA, $3C, $D4, $3D, $18, $F3, $01, $0A, $D4, $21, $16, $D4, $16, $09, $C9, $CD
db $19, $31, $CD, $6F, $31, $0A, $86, $23, $FE, $0A, $30, $35, $CD, $7E, $31, $20
db $F4, $FA, $00, $D4, $EA, $18, $D4, $FA, $0A, $D4, $FA, $22, $D4, $FE, $00, $20
db $02, $3C, $C9, $FA, $18, $D4, $3C, $E6, $0F, $EA, $18, $D4, $01, $1A, $D4, $21
db $19, $D4, $16, $09, $CD, $C0, $30, $AF, $EA, $22, $D4, $FA, $18, $D4, $FE, $08
db $C9, $D6, $0A, $34, $18, $C6, $CD, $19, $31, $CD, $09, $31, $20, $24, $CD, $6F
db $31, $0A, $FE, $FF, $28, $11, $96, $03, $38, $2B, $23, $CD, $7F, $31, $20, $F1
db $FA, $00, $D4, $EA, $18, $D4, $C9, $C6, $0A, $03, $F5, $0A, $3D, $02, $F1, $0B
db $18, $E4, $FA, $23, $D4, $EE, $FF, $EA, $23, $D4, $21, $01, $D4, $01, $0D, $D4
db $CD, $75, $31, $18, $CC, $F5, $0A, $3D, $02, $F1, $C6, $0A, $18, $CC, $E1, $C9
db $01, $0C, $D4, $21, $24, $D4, $CD, $EA, $30, $21, $0C, $D4, $16, $0B, $CD, $B3
db $30, $FA, $00, $D4, $47, $FA, $24, $D4, $80, $E6, $0F, $EA, $24, $D4, $FA, $00
db $D4, $C6, $07, $E6, $0F, $47, $FA, $24, $D4, $C6, $07, $E6, $0F, $80, $FE, $1D
db $D2, $95, $33, $21, $2D, $D4, $3E, $09, $EA, $3D, $D4, $FA, $00, $D4, $EA, $0C
db $D4, $7E, $FE, $00, $28, $26, $E5, $CD, $90, $31, $28, $B2, $FA, $00, $D4, $47
db $FA, $18, $D4, $B8, $28, $07, $FA, $24, $D4, $3C, $EA, $24, $D4, $01, $18, $D4
db $21, $0C, $D4, $16, $0B, $CD, $C0, $30, $E1, $35, $20, $D5, $2B, $FA, $3D, $D4
db $3D, $28, $12, $EA, $3D, $D4, $E5, $01, $02, $D4, $21, $01, $D4, $CD, $B9, $30
db $AF, $02, $E1, $18, $BC, $CD, $EE, $30, $FA, $24, $D4, $C3, $A5, $31, $CD, $97
db $33, $79, $FE, $00, $28, $0F, $CD, $A9, $33, $FA, $00, $D4, $3D, $E6, $0F, $EA
db $00, $D4, $0D, $20, $F1, $21, $15, $D4, $CD, $9A, $33, $79, $FE, $00, $28, $17
db $11, $14, $D4, $21, $15, $D4, $06, $08, $CD, $B1, $33, $FA, $0C, $D4, $3D, $E6
db $0F, $EA, $0C, $D4, $0D, $20, $E9, $FA, $0C, $D4, $C6, $07, $E6, $0F, $47, $FA
db $00, $D4, $C6, $07, $E6, $0F, $90, $EA, $24, $D4, $FA, $00, $D4, $EA, $0C, $D4
db $CD, $09, $31, $28, $12, $01, $0E, $D4, $21, $0D, $D4, $16, $09, $CD, $C0, $30
db $FA, $24, $D4, $3D, $EA, $24, $D4, $FA, $24, $D4, $FE, $08, $38, $05, $FE, $0F
db $DA, $95, $33, $21, $2D, $D4, $3E, $09, $EA, $3E, $D4, $E5, $CD, $09, $31, $20
db $17, $CD, $DF, $31, $FA, $3D, $D4, $3C, $EA, $3D, $D4, $01, $19, $D4, $21, $01
db $D4, $16, $09, $CD, $C0, $30, $18, $E4, $E1, $FA, $3D, $D4, $77, $AF, $EA, $3D
db $D4, $2B, $FA, $3E, $D4, $3D, $EA, $3E, $D4, $28, $06, $E5, $CD, $A9, $33, $18
db $CB, $01, $24, $D4, $21, $18, $D4, $CD, $EA, $30, $FA, $18, $D4, $FE, $08, $28
db $23, $CB, $7F, $28, $06, $FE, $F8, $38, $1A, $28, $08, $E6, $0F, $EA, $18, $D4
db $C3, $EE, $30, $CD, $EE, $30, $FA, $1A, $D4, $FE, $00, $28, $05, $3E, $09, $EA
db $18, $D4, $3C, $C9, $AF, $C9, $21, $09, $D4, $06, $08, $0E, $00, $7E, $FE, $00
db $20, $05, $0C, $2B, $05, $20, $F6, $C9, $11, $09, $D4, $21, $0A, $D4, $06, $09
db $1A, $32, $1B, $05, $20, $FA, $C9, $CB, $E7, $18, $11, $FA, $0B, $D4, $FE, $00
db $C0, $FA, $00, $D4, $CB, $47, $20, $43, $CB, $5F, $20, $EB, $CB, $3F, $EA, $24
db $D4, $FA, $00, $D4, $EA, $0C, $D4, $21, $15, $D4, $01, $2D, $D4, $16, $09, $34
db $C5, $E5, $D5, $CD, $09, $31, $20, $2F, $CD, $D7, $31, $01, $1A, $D4, $21, $02
db $D4, $16, $09, $CD, $C0, $30, $D1, $E1, $C1, $0A, $3C, $02, $34, $34, $7E, $FE
db $0B, $20, $DD, $D6, $0A, $77, $23, $34, $2B, $18, $D5, $CD, $A9, $33, $FA, $00
db $D4, $3D, $EA, $00, $D4, $18, $B1, $D1, $E1, $C1, $15, $CA, $9C, $34, $2B, $0B
db $C5, $E5, $D5, $FA, $0A, $D4, $FE, $00, $20, $54, $CD, $A9, $33, $01, $00, $D4
db $21, $30, $D4, $CD, $BE, $30, $01, $24, $D4, $21, $00, $D4, $16, $0B, $CD, $C0
db $30, $01, $00, $D4, $21, $0C, $D4, $16, $0B, $CD, $C0, $30, $CD, $90, $31, $FA
db $0C, $D4, $47, $FA, $18, $D4, $B8, $28, $05, $21, $0F, $D4, $18, $03, $21, $0E
db $D4, $01, $1A, $D4, $16, $09, $CD, $C0, $30, $01, $30, $D4, $21, $00, $D4, $CD
db $BE, $30, $FA, $00, $D4, $EA, $0C, $D4, $D1, $E1, $C1, $C3, $E0, $33, $01, $26
db $D4, $21, $25, $D4, $CD, $B9, $30, $AF, $02, $FA, $24, $D4, $3C, $EA, $24, $D4
db $D1, $E1, $C1, $2B, $0B, $15, $C5, $E5, $D5, $18, $92, $FA, $00, $D4, $0F, $FE
db $04, $30, $0F, $EA, $18, $D4, $01, $24, $D4, $21, $18, $D4, $CD, $EA, $30, $C3
db $EE, $30, $CB, $DF, $18, $ED, $FA, $17, $D4, $FE, $FF, $20, $24, $FA, $3F, $D4
db $FE, $02, $38, $11, $FE, $04, $30, $0C, $FA, $0B, $D4, $FE, $00, $20, $05, $3E
db $FF, $EA, $23, $D4, $C9, $FA, $3F, $D4, $EE, $01, $EA, $3F, $D4, $AF, $EA, $17
db $D4, $FA, $0B, $D4, $FE, $FF, $20, $EC, $FA, $3F, $D4, $FE, $02, $30, $E0, $EE
db $01, $EA, $3F, $D4, $FE, $00, $28, $05, $CD, $C8, $30, $18, $05, $3E, $FF, $EA
db $23, $D4, $AF, $EA, $0B, $D4, $18, $CC, $21, $00, $00, $CD, $68, $35, $C0, $21
db $00, $20, $CD, $68, $35, $C0, $21, $00, $40, $CD, $68, $35, $C0, $21, $00, $60
db $CD, $68, $35, $C0, $21, $81, $04, $CD, $F6, $2C, $FE, $86, $20, $17, $23, $CD
db $F6, $2C, $FE, $92, $20, $0F, $23, $CD, $F6, $2C, $FE, $85, $20, $07, $23, $CD
db $F6, $2C, $FE, $85, $C8, $21, $00, $00, $AF, $CD, $1C, $2D, $21, $81, $04, $3E
db $86, $CD, $1C, $2D, $23, $3E, $92, $CD, $1C, $2D, $23, $3E, $85, $CD, $1C, $2D
db $23, $3E, $85, $CD, $1C, $2D, $C9, $CD, $F6, $2C, $4F, $3E, $5A, $CD, $1C, $2D
db $CD, $F6, $2C, $FE, $5A, $C0, $79, $CD, $1C, $2D, $3E, $00, $CB, $4F, $C9, $AF
db $EA, $17, $D7, $F3, $CD, $40, $36, $CD, $31, $52, $CD, $F0, $0A, $CD, $10, $0B
db $21, $00, $90, $11, $09, $14, $01, $00, $08, $CD, $00, $C9, $CD, $F0, $0A, $CD
db $10, $0B, $21, $00, $88, $11, $21, $1F, $01, $00, $08, $CD, $00, $C9, $CD, $F0
db $0A, $CD, $10, $0B, $21, $30, $96, $11, $21, $27, $01, $D0, $01, $1A, $13, $22
db $0B, $78, $B1, $20, $F8, $01, $00, $04, $21, $00, $98, $3E, $BE, $CD, $81, $52
db $CD, $C1, $4D, $FB, $FA, $FB, $DB, $CB, $47, $C2, $E8, $35, $CD, $D9, $55, $FA
db $FB, $DB, $CB, $C7, $EA, $FB, $DB, $CD, $4C, $29, $CD, $D3, $45, $CD, $51, $47
db $FA, $25, $D0, $FE, $FF, $CA, $38, $52, $FE, $85, $28, $2E, $FE, $A5, $28, $2A
db $FA, $15, $D7, $CB, $57, $C2, $38, $52, $CD, $34, $49, $FA, $25, $D0, $FE, $2A
db $CA, $38, $52, $FE, $33, $C2, $21, $36, $CD, $7C, $41, $CD, $54, $4E, $18, $C7
db $FE, $31, $CA, $2B, $36, $FE, $34, $CA, $84, $35, $CD, $D8, $4D, $18, $B8, $CB
db $37, $E6, $0F, $FE, $01, $C8, $FE, $02, $C8, $FE, $04, $C8, $FE, $08, $C9, $FA
db $09, $D7, $CB, $E7, $EA, $09, $D7, $C9, $FA, $09, $D7, $CB, $A7, $EA, $09, $D7
db $C9, $FA, $0D, $D7, $67, $FA, $1F, $D7, $94, $E6, $0F, $C6, $03, $67, $AF, $C6
db $08, $25, $20, $FB, $EA, $CB, $C8, $F5, $FA, $1E, $D7, $67, $FA, $1F, $D7, $6F
db $F1, $CD, $31, $3D, $CB, $35, $CB, $34, $7D, $E6, $0F, $6F, $7C, $E6, $F0, $B5
db $D6, $C0, $CB, $3F, $CB, $3F, $C6, $05, $67, $AF, $C6, $08, $25, $20, $FB, $EA
db $CA, $C8, $FA, $09, $D7, $CB, $67, $20, $07, $FA, $08, $D7, $CB, $67, $28, $11
db $FA, $26, $D7, $FE, $00, $C8, $EA, $CC, $C8, $AF, $EA, $26, $D7, $CD, $5F, $0A
db $C9, $3E, $FF, $EA, $CC, $C8, $CD, $33, $0A, $78, $EA, $26, $D7, $C9, $CD, $AA
db $39, $18, $05, $CD, $37, $38, $18, $00, $F5, $CD, $40, $36, $CD, $52, $36, $21
db $08, $D7, $CB, $A6, $CD, $49, $36, $CD, $52, $36, $F1, $C9, $E5, $F5, $CD, $0D
db $37, $F1, $EA, $07, $D7, $FE, $06, $20, $11, $6F, $FA, $17, $D7, $FE, $00, $28
db $19, $FE, $03, $28, $15, $FE, $0C, $28, $11, $7D, $EA, $CA, $C8, $3E, $01, $EA
db $CB, $C8, $3E, $9F, $EA, $CC, $C8, $CD, $91, $04, $E1, $C9, $FA, $07, $D7, $EA
db $CA, $C8, $3E, $01, $EA, $CB, $C8, $3E, $BE, $EA, $CC, $C8, $CD, $91, $04, $C9
db $D5, $F5, $E5, $CD, $6E, $37, $28, $07, $CD, $D3, $44, $E1, $F1, $D1, $C9, $CD
db $BE, $3C, $16, $BE, $F5, $FA, $0E, $D7, $67, $FA, $0F, $D7, $6F, $F1, $CD, $B6
db $2C, $5F, $7A, $CD, $CD, $2C, $53, $FA, $1D, $D7, $BD, $20, $06, $FA, $1C, $D7
db $BC, $28, $03, $23, $18, $E8, $23, $7A, $CD, $1C, $2D, $F5, $7C, $EA, $29, $D7
db $7D, $EA, $2A, $D7, $F1, $AF, $CD, $A4, $2C, $E1, $F1, $D1, $C9, $CD, $BE, $3C
db $FA, $23, $D7, $BD, $20, $0B, $FA, $22, $D7, $BC, $20, $05, $3E, $01, $CB, $47
db $C9, $AF, $CB, $47, $C9, $E5, $CD, $BE, $3C, $E1, $E5, $C5, $FA, $08, $D7, $CB
db $9F, $EA, $08, $D7, $F5, $FA, $03, $D7, $67, $FA, $04, $D7, $6F, $F1, $0E, $40
db $23, $CD, $C9, $37, $28, $06, $2B, $CD, $C9, $37, $20, $0B, $FA, $08, $D7, $CB
db $DF, $EA, $08, $D7, $C3, $34, $38, $CD, $F6, $2C, $0D, $28, $08, $FE, $2E, $23
db $20, $DE, $C3, $2A, $38, $23, $18, $61, $FA, $1D, $D7, $BD, $C0, $FA, $1C, $D7
db $BC, $C9, $E5, $C5, $FA, $08, $D7, $CB, $9F, $EA, $08, $D7, $F5, $FA, $03, $D7
db $67, $FA, $04, $D7, $6F, $F1, $CD, $C2, $3B, $CA, $34, $38, $F5, $FA, $20, $D7
db $67, $FA, $21, $D7, $6F, $F1, $0E, $40, $E5, $CD, $F6, $2C, $23, $FE, $2E, $28
db $03, $0D, $20, $F5, $F5, $FA, $03, $D7, $47, $FA, $04, $D7, $4F, $F1, $7C, $B8
db $20, $04, $7D, $B9, $28, $03, $C1, $18, $DD, $E1, $CD, $C2, $3B, $20, $0A, $FA
db $08, $D7, $CB, $DF, $EA, $08, $D7, $18, $00, $F5, $7C, $EA, $03, $D7, $7D, $EA
db $04, $D7, $F1, $C1, $E1, $C9, $CD, $BE, $3C, $CD, $88, $39, $20, $03, $3E, $FF
db $C9, $F5, $FA, $0E, $D7, $67, $FA, $0F, $D7, $6F, $F1, $F5, $FA, $1E, $D7, $47
db $FA, $1F, $D7, $4F, $F1, $CD, $F6, $2C, $FE, $2E, $C2, $FE, $38, $78, $FE, $DF
db $20, $35, $CB, $71, $28, $31, $CD, $86, $37, $CD, $46, $3D, $AF, $EA, $18, $D7
db $01, $40, $DF, $F5, $78, $EA, $1E, $D7, $79, $EA, $1F, $D7, $F1, $01, $00, $DC
db $F5, $78, $EA, $0C, $D7, $79, $EA, $0D, $D7, $F1, $23, $F5, $7C, $EA, $0E, $D7
db $7D, $EA, $0F, $D7, $F1, $AF, $C9, $F5, $FA, $1E, $D7, $67, $FA, $1F, $D7, $6F
db $F1, $7D, $C6, $40, $6F, $7C, $CE, $00, $67, $CD, $31, $3D, $F5, $7C, $EA, $1E
db $D7, $7D, $EA, $1F, $D7, $F1, $AF, $EA, $12, $D7, $F5, $FA, $0C, $D7, $67, $FA
db $0D, $D7, $6F, $F1, $3E, $00, $BD, $20, $0A, $3E, $DC, $BC, $20, $05, $3E, $FF
db $EA, $12, $D7, $21, $00, $DC, $F5, $7C, $EA, $0C, $D7, $7D, $EA, $0D, $D7, $F1
db $AF, $EA, $18, $D7, $F5, $FA, $0E, $D7, $67, $FA, $0F, $D7, $6F, $F1, $23, $F5
db $7C, $EA, $0E, $D7, $7D, $EA, $0F, $D7, $F1, $FA, $12, $D7, $C9, $03, $79, $FE
db $80, $20, $08, $78, $FE, $DF, $20, $03, $C3, $67, $38, $F5, $FA, $1E, $D7, $47
db $FA, $1F, $D7, $4F, $F1, $03, $F5, $78, $EA, $1E, $D7, $79, $EA, $1F, $D7, $F1
db $79, $FE, $00, $28, $0E, $FE, $40, $28, $0A, $FE, $80, $28, $06, $FE, $C0, $28
db $02, $18, $21, $01, $00, $DC, $F5, $78, $EA, $0C, $D7, $79, $EA, $0D, $D7, $F1
db $AF, $EA, $18, $D7, $23, $F5, $7C, $EA, $0E, $D7, $7D, $EA, $0F, $D7, $F1, $CD
db $46, $3D, $AF, $C9, $FA, $18, $D7, $FE, $0F, $20, $17, $F5, $FA, $0C, $D7, $47
db $FA, $0D, $D7, $4F, $F1, $03, $F5, $78, $EA, $0C, $D7, $79, $EA, $0D, $D7, $F1
db $18, $D2, $3C, $EA, $18, $D7, $23, $F5, $7C, $EA, $0E, $D7, $7D, $EA, $0F, $D7
db $F1, $CD, $46, $3D, $3E, $FF, $C9, $E5, $C5, $F5, $FA, $1C, $D7, $67, $FA, $1D
db $D7, $6F, $F1, $F5, $FA, $0E, $D7, $47, $FA, $0F, $D7, $4F, $F1, $CD, $A4, $39
db $C1, $E1, $C9, $79, $BD, $C0, $78, $BC, $C9, $F5, $FA, $0E, $D7, $67, $FA, $0F
db $D7, $6F, $F1, $CD, $C2, $3B, $20, $03, $3E, $FF, $C9, $F5, $FA, $1E, $D7, $67
db $FA, $1F, $D7, $6F, $F1, $7D, $FE, $00, $20, $60, $7C, $FE, $DC, $20, $5B, $F5
db $FA, $0E, $D7, $67, $FA, $0F, $D7, $6F, $F1, $2B, $F5, $7C, $EA, $0E, $D7, $7D
db $EA, $0F, $D7, $F1, $CD, $D3, $37, $01, $00, $DC, $F5, $FA, $03, $D7, $67, $FA
db $04, $D7, $6F, $F1, $16, $40, $CD, $F6, $2C, $23, $03, $15, $28, $28, $FE, $2E
db $20, $F4, $0B, $F5, $78, $EA, $1E, $D7, $79, $EA, $1F, $D7, $F1, $79, $E6, $0F
db $EA, $18, $D7, $79, $E6, $F0, $4F, $F5, $78, $EA, $0C, $D7, $79, $EA, $0D, $D7
db $F1, $CD, $46, $3D, $AF, $C9, $2B, $0B, $18, $D9, $2B, $7D, $FE, $3F, $28, $43
db $FE, $7F, $28, $3F, $FE, $BF, $28, $3B, $FE, $FF, $28, $37, $F5, $7C, $EA, $1E
db $D7, $7D, $EA, $1F, $D7, $F1, $FA, $18, $D7, $FE, $00, $20, $1B, $F5, $FA, $0C
db $D7, $67, $FA, $0D, $D7, $6F, $F1, $2B, $F5, $7C, $EA, $0C, $D7, $7D, $EA, $0D
db $D7, $F1, $AF, $EA, $12, $D7, $18, $57, $3D, $EA, $18, $D7, $3E, $FF, $EA, $12
db $D7, $18, $4C, $3A, $FE, $BE, $28, $FB, $23, $F5, $7C, $EA, $1E, $D7, $7D, $EA
db $1F, $D7, $F1, $F5, $FA, $0C, $D7, $47, $FA, $0D, $D7, $4F, $F1, $C5, $7D, $E6
db $0F, $EA, $18, $D7, $7D, $E6, $30, $4F, $F5, $FA, $0C, $D7, $67, $FA, $0D, $D7
db $6F, $F1, $69, $F5, $7C, $EA, $0C, $D7, $7D, $EA, $0D, $D7, $F1, $AF, $EA, $12
db $D7, $C1, $7D, $B9, $20, $09, $7C, $B8, $20, $05, $3E, $FF, $EA, $12, $D7, $CD
db $F1, $3C, $FA, $12, $D7, $C9, $CD, $4B, $3B, $CD, $8B, $37, $FA, $08, $D7, $CB
db $5F, $20, $3C, $15, $20, $F3, $18, $37, $CD, $4B, $3B, $1E, $01, $CD, $D3, $37
db $FA, $08, $D7, $CB, $5F, $20, $28, $15, $20, $F3, $CB, $43, $20, $21, $F5, $FA
db $20, $D7, $47, $FA, $21, $D7, $4F, $F1, $F5, $78, $EA, $0E, $D7, $79, $EA, $0F
db $D7, $F1, $01, $00, $DC, $F5, $78, $EA, $1E, $D7, $79, $EA, $1F, $D7, $F1, $FA
db $08, $D7, $CB, $9F, $EA, $08, $D7, $CD, $46, $3D, $01, $00, $DC, $F5, $78, $EA
db $0C, $D7, $79, $EA, $0D, $D7, $F1, $F5, $78, $EA, $1E, $D7, $79, $EA, $1F, $D7
db $F1, $F5, $FA, $03, $D7, $67, $FA, $04, $D7, $6F, $F1, $F5, $7C, $EA, $0E, $D7
db $7D, $EA, $0F, $D7, $F1, $AF, $EA, $18, $D7, $C9, $F5, $FA, $1E, $D7, $67, $FA
db $1F, $D7, $6F, $F1, $CD, $31, $3D, $F5, $7C, $EA, $1E, $D7, $7D, $EA, $1F, $D7
db $F1, $16, $0C, $C9, $F5, $FA, $1E, $D7, $67, $FA, $1F, $D7, $6F, $F1, $7C, $FE
db $DC, $20, $2E, $7D, $E6, $C0, $FE, $00, $20, $27, $F5, $FA, $03, $D7, $67, $FA
db $04, $D7, $6F, $F1, $CD, $C2, $3B, $20, $03, $3E, $FF, $C9, $CD, $D3, $37, $CD
db $46, $3D, $F5, $FA, $1E, $D7, $67, $FA, $1F, $D7, $6F, $F1, $CD, $43, $3C, $AF
db $C9, $7D, $D6, $40, $6F, $7C, $DE, $00, $67, $F5, $7C, $EA, $1E, $D7, $7D, $EA
db $1F, $D7, $F1, $F5, $FA, $1E, $D7, $67, $FA, $1F, $D7, $6F, $F1, $CD, $43, $3C
db $C9, $C5, $F5, $FA, $20, $D7, $47, $FA, $21, $D7, $4F, $F1, $7D, $B9, $20, $02
db $7C, $B8, $C1, $C9, $CD, $BE, $3C, $CD, $88, $39, $20, $03, $3E, $FF, $C9, $2B
db $CD, $F6, $2C, $FE, $2E, $20, $01, $2B, $16, $40, $FA, $0E, $D7, $BC, $20, $09
db $FA, $0F, $D7, $BD, $20, $03, $3E, $FF, $C9, $2B, $CD, $F6, $2C, $FE, $2E, $28
db $03, $15, $20, $E6, $F5, $FA, $1E, $D7, $67, $FA, $1F, $D7, $6F, $F1, $7C, $FE
db $DF, $20, $19, $CB, $75, $28, $15, $CD, $86, $37, $CD, $46, $3D, $F5, $FA, $1E
db $D7, $67, $FA, $1F, $D7, $6F, $F1, $CD, $43, $3C, $AF, $C9, $7D, $C6, $40, $6F
db $7C, $CE, $00, $67, $F5, $7C, $EA, $1E, $D7, $7D, $EA, $1F, $D7, $F1, $CD, $43
db $3C, $C9, $3E, $FF, $EA, $12, $D7, $7E, $FE, $BE, $20, $14, $7D, $FE, $00, $28
db $0F, $FE, $40, $28, $0B, $FE, $80, $28, $07, $FE, $C0, $28, $03, $2B, $18, $E2
db $F5, $FA, $0C, $D7, $47, $FA, $0D, $D7, $4F, $F1, $79, $E6, $3F, $4F, $7D, $E6
db $3F, $B9, $30, $21, $AF, $EA, $12, $D7, $FA, $1F, $D7, $95, $4F, $FA, $0D, $D7
db $91, $30, $0F, $01, $00, $DC, $F5, $78, $EA, $0C, $D7, $79, $EA, $0D, $D7, $F1
db $18, $03, $EA, $0D, $D7, $F5, $7C, $EA, $1E, $D7, $7D, $EA, $1F, $D7, $F1, $FA
db $0D, $D7, $E6, $3F, $67, $7D, $E6, $3F, $94, $EA, $18, $D7, $F5, $FA, $1E, $D7
db $67, $FA, $1F, $D7, $6F, $F1, $CD, $F1, $3C, $FA, $12, $D7, $C9, $F5, $FA, $29
db $D7, $67, $FA, $2A, $D7, $6F, $F1, $F5, $7C, $EA, $1C, $D7, $7D, $EA, $1D, $D7
db $F1, $C9, $F5, $FA, $0E, $D7, $67, $FA, $0F, $D7, $6F, $F1, $CD, $F6, $2C, $23
db $FE, $FF, $20, $F8, $2B, $F5, $7C, $EA, $29, $D7, $7D, $EA, $2A, $D7, $F1, $C9
db $16, $00, $1E, $00, $21, $00, $DC, $FA, $1E, $D7, $BC, $20, $06, $FA, $1F, $D7
db $BD, $28, $14, $2A, $13, $FE, $2E, $20, $EE, $2B, $7D, $C6, $40, $6F, $7C, $CE
db $00, $67, $CD, $31, $3D, $18, $E0, $F5, $FA, $03, $D7, $67, $FA, $04, $D7, $6F
db $F1, $19, $F5, $7C, $EA, $0E, $D7, $7D, $EA, $0F, $D7, $F1, $CD, $46, $3D, $C9
db $7D, $CB, $7F, $28, $08, $2E, $80, $CB, $77, $C8, $2E, $C0, $C9, $2E, $00, $CB
db $77, $C8, $2E, $40, $C9, $E5, $F5, $FA, $0E, $D7, $47, $FA, $0F, $D7, $4F, $F1
db $C5, $CD, $BE, $3C, $16, $0E, $1E, $40, $F5, $FA, $03, $D7, $67, $FA, $04, $D7
db $6F, $F1, $01, $00, $DC, $F5, $7C, $EA, $0E, $D7, $7D, $EA, $0F, $D7, $F1, $CD
db $88, $39, $28, $30, $CD, $B6, $2C, $23, $CD, $B5, $3D, $FE, $2E, $20, $0A, $02
db $03, $1D, $3E, $BE, $20, $F9, $C3, $8F, $3D, $02, $03, $1D, $20, $D7, $1E, $40
db $15, $20, $D2, $AF, $CD, $85, $2C, $C1, $F5, $78, $EA, $0E, $D7, $79, $EA, $0F
db $D7, $F1, $E1, $C9, $79, $FE, $80, $20, $05, $78, $FE, $DF, $28, $E5, $3E, $BE
db $02, $03, $18, $F0, $FE, $54, $38, $04, $FE, $7E, $30, $00, $C9, $C5, $F5, $E6
db $0F, $47, $F1, $E6, $F0, $CB, $37, $E5, $F5, $EA, $12, $D7, $CD, $24, $3E, $F1
db $EA, $12, $D7, $E1, $7D, $C6, $40, $6F, $7C, $CE, $00, $67, $E5, $FA, $12, $D7
db $F5, $CD, $38, $3E, $05, $20, $E8, $F1, $EA, $12, $D7, $E1, $7D, $C6, $40, $6F
db $7C, $CE, $00, $67, $CD, $2E, $3E, $C1, $C9, $3E, $2D, $22, $FA, $12, $D7, $D6
db $01, $EA, $12, $D7, $20, $F3, $C9, $3E, $30, $22, $FA, $12, $D7, $D6, $01, $EA
db $12, $D7, $20, $F3, $C9, $3E, $BE, $22, $FA, $12, $D7, $D6, $01, $EA, $12, $D7
db $20, $F3, $C9, $3E, $2A, $22, $CD, $FA, $3D, $3E, $2B, $77, $C9, $3E, $28, $22
db $CD, $08, $3E, $3E, $29, $77, $C9, $3E, $2C, $22, $CD, $16, $3E, $3E, $2F, $77
db $C9, $22, $CD, $FA, $3D, $77, $C9, $FA, $25, $D0, $F5, $CD, $40, $36, $CD, $52
db $36, $01, $43, $DC, $21, $28, $D0, $16, $0A, $0A, $0C, $22, $15, $20, $FA, $3E
db $0C, $EA, $34, $D0, $CD, $C5, $4C, $7A, $EA, $33, $D0, $3E, $9F, $EA, $32, $D0
db $CD, $93, $2D, $CD, $0D, $37, $3E, $06, $CD, $DD, $36, $FA, $25, $D0, $FE, $01
db $28, $03, $CD, $F1, $45, $CD, $49, $36, $F1, $EA, $25, $D0, $C9, $AF, $EA, $25
db $D7, $3E, $38, $EA, $CC, $C8, $AF, $EA, $CB, $C8, $3E, $03, $EA, $CA, $C8, $CD
db $91, $04, $3E, $3A, $EA, $CC, $C8, $3E, $04, $EA, $CA, $C8, $CD, $91, $04, $FA
db $25, $D0, $F5, $CD, $40, $36, $CD, $52, $36, $01, $0C, $00, $21, $90, $DB, $3E
db $BE, $CD, $81, $52, $01, $0C, $00, $21, $28, $D0, $CD, $81, $52, $CD, $DC, $3F
db $CD, $FF, $47, $21, $00, $DC, $F5, $7C, $EA, $03, $D7, $7D, $EA, $04, $D7, $F1
db $CD, $E3, $47, $01, $00, $02, $21, $00, $D8, $3E, $BE, $CD, $81, $52, $CD, $09
db $35, $C2, $AB, $3F, $FA, $00, $A0, $A7, $20, $26, $21, $85, $04, $F5, $7C, $EA
db $20, $D7, $7D, $EA, $21, $D7, $F1, $3E, $FF, $CD, $1C, $2D, $21, $00, $80, $F5
db $7C, $EA, $22, $D7, $7D, $EA, $23, $D7, $F1, $AF, $EA, $25, $D7, $C3, $CE, $3F
db $06, $12, $CD, $2A, $29, $21, $00, $00, $19, $2B, $CD, $F6, $2C, $23, $57, $CD
db $F6, $2C, $23, $5F, $13, $F5, $7A, $EA, $20, $D7, $7B, $EA, $21, $D7, $F1, $3E
db $FF, $CD, $4A, $2D, $CD, $52, $2D, $FA, $4B, $D0, $A7, $CA, $CE, $3F, $06, $12
db $CD, $2A, $29, $21, $00, $00, $19, $2B, $2B, $CD, $F6, $2C, $2B, $5F, $CD, $F6
db $2C, $2B, $57, $CD, $F6, $2C, $2B, $4F, $CD, $F6, $2C, $2B, $47, $F5, $FA, $20
db $D7, $67, $FA, $21, $D7, $6F, $F1, $CD, $EE, $2C, $CD, $1C, $2D, $23, $13, $CB
db $7C, $28, $0A, $CD, $3C, $45, $3E, $FF, $EA, $25, $D7, $18, $40, $0B, $79, $B0
db $20, $E5, $3E, $FF, $CD, $1C, $2D, $11, $00, $80, $F5, $7A, $EA, $22, $D7, $7B
db $EA, $23, $D7, $F1, $AF, $EA, $25, $D7, $18, $23, $21, $FF, $D9, $F5, $7C, $EA
db $22, $D7, $7D, $EA, $23, $D7, $F1, $21, $00, $D8, $F5, $7C, $EA, $20, $D7, $7D
db $EA, $21, $D7, $F1, $3E, $FF, $EA, $00, $D8, $AF, $EA, $25, $D7, $CD, $0C, $40
db $CD, $49, $36, $F1, $EA, $25, $D0, $FA, $25, $D7, $C9, $CD, $B8, $4C, $C8, $11
db $90, $DB, $01, $28, $D0, $21, $43, $DC, $2A, $FE, $BE, $28, $FB, $2D, $2A, $02
db $12, $0C, $1C, $7D, $FE, $4D, $20, $F6, $CD, $C5, $4C, $7A, $EA, $33, $D0




; Actually 32K Bank 2 -> Upper 16K region. 32K banking not supported in RGBDS
SECTION "rom5", ROMX, BANK[$5]
; 32K Bank memory region: 0x4000 -> 0x7FFF
; Data from 14000 to 17FFF (16384 bytes)
db $EA, $9B, $DB, $3E, $9F, $EA, $32, $D0, $EA, $9A, $DB, $C9, $3E, $03, $EA, $CA
db $C8, $3E, $BE, $EA, $CC, $C8, $AF, $EA, $CB, $C8, $CD, $91, $04, $3E, $BE, $EA
db $CC, $C8, $FA, $CA, $C8, $3C, $EA, $CA, $C8, $CD, $91, $04, $C9, $AF, $EA, $25
db $D7, $FA, $25, $D0, $F5, $CD, $40, $36, $CD, $52, $36, $CD, $96, $45, $3E, $39
db $EA, $CC, $C8, $AF, $EA, $CB, $C8, $3E, $03, $EA, $CA, $C8, $CD, $91, $04, $3E
db $3A, $EA, $CC, $C8, $3E, $04, $EA, $CA, $C8, $CD, $91, $04, $CD, $13, $41, $AF
db $EA, $4C, $D0, $CD, $6B, $2E, $FA, $25, $D0, $FE, $A5, $20, $12, $CD, $EC, $46
db $FA, $15, $D7, $CB, $8F, $EA, $15, $D7, $F1, $3E, $A5, $F5, $C3, $08, $41, $FE
db $01, $28, $39, $FE, $F7, $28, $0A, $FE, $06, $20, $06, $CD, $52, $45, $C3, $08
db $41, $CD, $13, $45, $CD, $10, $4D, $FA, $25, $D0, $FE, $2A, $28, $6A, $FE, $93
db $28, $0F, $FE, $B3, $28, $0B, $FE, $8E, $28, $5E, $FE, $AE, $28, $5A, $C3, $94
db $40, $3E, $F8, $EA, $25, $D0, $CD, $13, $41, $CD, $6B, $2E, $F5, $FA, $20, $D7
db $67, $FA, $21, $D7, $6F, $F1, $F5, $7C, $EA, $1A, $D7, $7D, $EA, $1B, $D7, $F1
db $CD, $BE, $3C, $CD, $28, $41, $CD, $6B, $2E, $FA, $25, $D0, $FE, $01, $20, $20
db $FA, $34, $D0, $FE, $0C, $28, $EC, $FA, $15, $D7, $CB, $97, $EA, $15, $D7, $16
db $0A, $21, $43, $DC, $01, $90, $DB, $0A, $03, $22, $15, $20, $FA, $C3, $B4, $3E
db $CD, $3C, $45, $3E, $FF, $EA, $25, $D7, $CD, $0C, $40, $CD, $49, $36, $F1, $EA
db $25, $D0, $C9, $D5, $01, $90, $DB, $21, $28, $D0, $3E, $0C, $EA, $34, $D0, $57
db $0A, $22, $0C, $15, $20, $FA, $D1, $C9, $E5, $D5, $16, $0C, $01, $28, $D0, $F5
db $FA, $1A, $D7, $67, $FA, $1B, $D7, $6F, $F1, $CD, $F6, $2C, $FE, $FF, $20, $0F
db $3E, $0C, $92, $EA, $34, $D0, $3E, $BE, $02, $03, $15, $20, $F9, $18, $0B, $23
db $02, $03, $15, $20, $E4, $3E, $0C, $EA, $34, $D0, $F5, $7C, $EA, $1A, $D7, $7D
db $EA, $1B, $D7, $F1, $FA, $34, $D0, $D1, $E1, $C9, $3E, $09, $EA, $23, $D0, $CD
db $28, $0D, $CD, $41, $0D, $FA, $21, $D0, $EA, $E4, $D2, $C9, $3E, $09, $EA, $23
db $D0, $CD, $28, $0D, $CD, $62, $0D, $FA, $21, $D0, $EA, $E4, $D2, $A7, $28, $2E
db $CD, $A2, $01, $3E, $09, $EA, $23, $D0, $CD, $28, $0D, $CD, $62, $0D, $FA, $21
db $D0, $EA, $E4, $D2, $A7, $28, $17, $CD, $A2, $01, $3E, $09, $EA, $23, $D0, $CD
db $28, $0D, $CD, $62, $0D, $FA, $21, $D0, $EA, $E4, $D2, $A7, $20, $0A, $CD, $0D
db $37, $CD, $96, $45, $CD, $46, $3D, $C9, $CD, $0D, $37, $CD, $FF, $47, $3E, $36
db $EA, $CC, $C8, $AF, $EA, $CB, $C8, $3E, $03, $EA, $CA, $C8, $CD, $91, $04, $3E
db $37, $EA, $CC, $C8, $3E, $04, $EA, $CA, $C8, $CD, $91, $04, $FA, $E4, $D2, $FE
db $01, $CA, $1F, $43, $01, $40, $00, $21, $80, $DF, $3E, $BE, $CD, $81, $52, $CD
db $9D, $42, $C2, $6C, $42, $F5, $FA, $20, $D7, $47, $FA, $21, $D7, $4F, $F1, $F5
db $78, $EA, $0E, $D7, $79, $EA, $0F, $D7, $F1, $F5, $78, $EA, $03, $D7, $79, $EA
db $04, $D7, $F1, $01, $00, $DC, $F5, $78, $EA, $1E, $D7, $79, $EA, $1F, $D7, $F1
db $AF, $EA, $18, $D7, $CD, $46, $3D, $3E, $BC, $EA, $19, $D7, $CD, $CD, $42, $CD
db $87, $08, $FA, $25, $D0, $FE, $FC, $20, $23, $FA, $18, $D7, $3C, $EA, $18, $D7
db $FE, $40, $20, $E8, $16, $0E, $CD, $86, $37, $FA, $08, $D7, $CB, $5F, $20, $11
db $15, $20, $F3, $CD, $9D, $42, $C2, $6C, $42, $C3, $23, $42, $CD, $69, $45, $18
db $06, $CD, $9D, $42, $C2, $6C, $42, $21, $08, $D7, $CB, $9E, $CD, $96, $45, $CD
db $46, $3D, $CD, $0C, $40, $C9, $3E, $80, $01, $9B, $00, $21, $21, $D2, $CD, $81
db $52, $21, $16, $D2, $0E, $0B, $AF, $22, $15, $20, $FB, $18, $0B, $3E, $80, $01
db $A6, $00, $21, $16, $D2, $CD, $81, $52, $CD, $87, $08, $FA, $25, $D0, $FE, $FC
db $C0, $AF, $01, $A6, $00, $21, $16, $D2, $CD, $81, $52, $CD, $87, $08, $FA, $25
db $D0, $FE, $FC, $C0, $CD, $87, $08, $FA, $25, $D0, $FE, $FC, $C9, $01, $00, $DC
db $21, $BC, $D2, $FA, $18, $D7, $4F, $16, $0F, $0A, $D5, $C5, $FE, $2E, $20, $02
db $3E, $BE, $01, $F1, $20, $FE, $80, $38, $05, $D6, $80, $01, $21, $1F, $CD, $14
db $43, $79, $83, $5F, $78, $8A, $57, $AF, $32, $32, $32, $0E, $08, $13, $1A, $32
db $13, $0D, $20, $F9, $C1, $D1, $3E, $40, $81, $4F, $78, $CE, $00, $47, $15, $20
db $C8, $AF, $32, $C9, $CB, $37, $5F, $E6, $0F, $57, $7B, $E6, $F0, $5F, $C9, $AF
db $EA, $3F, $D7, $CD, $BE, $3C, $3E, $2E, $CD, $1C, $2D, $23, $CD, $F6, $2C, $EA
db $34, $D7, $3E, $FF, $CD, $1C, $2D, $F5, $7C, $EA, $1C, $D7, $7D, $EA, $1D, $D7
db $F1, $F5, $FA, $20, $D7, $67, $FA, $21, $D7, $6F, $F1, $F5, $7C, $EA, $0E, $D7
db $7D, $EA, $0F, $D7, $F1, $1E, $41, $FA, $08, $D7, $CB, $BF, $EA, $08, $D7, $AF
db $EA, $3E, $D7, $EA, $34, $D0, $16, $0C, $01, $0C, $00, $21, $28, $D0, $3E, $BE
db $CD, $81, $52, $F5, $FA, $0E, $D7, $67, $FA, $0F, $D7, $6F, $F1, $01, $28, $D0
db $FA, $08, $D7, $CB, $7F, $28, $19, $CB, $BF, $EA, $08, $D7, $3E, $0D, $02, $03
db $15, $3E, $01, $EA, $34, $D0, $F5, $FA, $0E, $D7, $67, $FA, $0F, $D7, $6F, $F1
db $FA, $1C, $D7, $BC, $20, $08, $FA, $1D, $D7, $BD, $20, $02, $18, $29, $1D, $20
db $09, $CD, $4A, $44, $1E, $41, $28, $1F, $18, $E6, $CD, $F6, $2C, $23, $FE, $2E
db $20, $09, $CD, $4A, $44, $1E, $41, $28, $0E, $18, $D5, $02, $FA, $34, $D0, $3C
db $EA, $34, $D0, $03, $15, $20, $C9, $FA, $34, $D0, $FE, $00, $28, $42, $F5, $7C
db $EA, $0E, $D7, $7D, $EA, $0F, $D7, $F1, $CD, $6F, $30, $21, $28, $D0, $0E, $0D
db $2A, $F5, $0D, $20, $FB, $3E, $10, $EA, $35, $D0, $CD, $3B, $04, $21, $34, $D0
db $0E, $0D, $F1, $32, $0D, $20, $FB, $FA, $25, $D0, $FE, $FC, $CA, $5F, $43, $CD
db $9A, $0D, $FA, $3E, $D7, $3C, $EA, $3E, $D7, $FE, $03, $38, $CE, $CD, $69, $45
db $CD, $30, $44, $CD, $96, $45, $CD, $46, $3D, $CD, $0C, $40, $CD, $49, $36, $C9
db $CD, $BE, $3C, $F5, $FA, $1C, $D7, $67, $FA, $1D, $D7, $6F, $F1, $3E, $FF, $CD
db $1C, $2D, $23, $FA, $24, $D7, $CD, $1C, $2D, $C9, $3E, $0A, $02, $03, $FA, $34
db $D0, $3C, $EA, $34, $D0, $15, $20, $09, $FA, $08, $D7, $CB, $FF, $EA, $08, $D7
db $C9, $FA, $34, $D0, $3C, $EA, $34, $D0, $3E, $0D, $02, $03, $15, $C9, $CD, $F0
db $0A, $CD, $10, $0B, $7E, $FE, $00, $28, $1B, $E5, $D5, $7E, $EA, $CC, $C8, $AF
db $EA, $CD, $C8, $7B, $EA, $CB, $C8, $7A, $EA, $CA, $C8, $CD, $91, $04, $D1, $E1
db $13, $23, $18, $DA, $C9, $0A, $03, $FE, $00, $C8, $22, $18, $F8, $3E, $E1, $21
db $00, $DC, $CD, $BE, $3D, $C9, $FA, $29, $D7, $67, $FA, $2A, $D7, $6F, $7C, $E6
db $F0, $CB, $37, $C6, $C0, $EA, $04, $98, $7C, $E6, $0F, $C6, $C0, $EA, $05, $98
db $7D, $E6, $F0, $CB, $37, $C6, $C0, $EA, $06, $98, $7D, $E6, $0F, $C6, $C0, $EA
db $07, $98, $C9, $3E, $E2, $CD, $9F, $44, $01, $8D, $53, $21, $41, $DC, $CD, $95
db $44, $01, $98, $53, $21, $81, $DC, $C3, $80, $45, $3E, $E4, $CD, $9F, $44, $01
db $A9, $53, $21, $41, $DC, $CD, $95, $44, $01, $B5, $53, $21, $81, $DC, $CD, $95
db $44, $01, $04, $54, $21, $C1, $DC, $CD, $95, $44, $01, $10, $54, $21, $01, $DD
db $C3, $0D, $47, $3E, $E4, $CD, $9F, $44, $01, $16, $54, $21, $41, $DC, $CD, $95
db $44, $01, $21, $54, $21, $81, $DC, $CD, $95, $44, $01, $2C, $54, $21, $C1, $DC
db $CD, $95, $44, $01, $3B, $54, $21, $01, $DD, $C3, $0D, $47, $3E, $E2, $CD, $9F
db $44, $01, $70, $54, $21, $41, $DC, $CD, $95, $44, $01, $7E, $54, $21, $81, $DC
db $18, $2E, $3E, $E2, $CD, $9F, $44, $01, $87, $54, $21, $43, $DC, $CD, $95, $44
db $01, $92, $54, $21, $84, $DC, $C3, $80, $45, $CD, $96, $45, $3E, $E2, $CD, $9F
db $44, $01, $9A, $54, $21, $41, $DC, $CD, $95, $44, $01, $A8, $54, $21, $81, $DC
db $CD, $95, $44, $CD, $40, $36, $CD, $52, $36, $CD, $E3, $47, $CD, $10, $4D, $CD
db $46, $3D, $CD, $49, $36, $C9, $01, $00, $DC, $F5, $78, $EA, $0C, $D7, $79, $EA
db $0D, $D7, $F1, $F5, $78, $EA, $1E, $D7, $79, $EA, $1F, $D7, $F1, $F5, $FA, $20
db $D7, $47, $FA, $21, $D7, $4F, $F1, $F5, $78, $EA, $03, $D7, $79, $EA, $04, $D7
db $F1, $F5, $78, $EA, $0E, $D7, $79, $EA, $0F, $D7, $F1, $AF, $EA, $18, $D7, $CD
db $46, $3D, $C9, $CD, $D7, $45, $C9, $CD, $F0, $0A, $CD, $10, $0B, $21, $00, $98
db $AF, $22, $3C, $FE, $14, $20, $FA, $21, $20, $98, $22, $3C, $FE, $28, $20, $FA
db $C9, $3E, $E2, $CD, $9F, $44, $01, $AE, $54, $21, $41, $DC, $CD, $95, $44, $01
db $B9, $54, $21, $81, $DC, $C3, $80, $45, $CD, $D7, $45, $C9, $CD, $D7, $45, $C9
db $3E, $92, $21, $03, $DC, $CD, $BE, $3D, $01, $C3, $54, $21, $44, $DC, $CD, $95
db $44, $23, $FA, $FB, $D6, $16, $00, $5F, $CD, $B8, $29, $57, $7B, $C6, $C0, $22
db $7A, $C6, $C0, $22, $01, $CA, $54, $21, $84, $DC, $CD, $95, $44, $23, $23, $F5
db $FA, $FE, $D6, $57, $FA, $FF, $D6, $5F, $F1, $01, $E0, $D6, $CD, $B8, $29, $02
db $03, $7A, $FE, $00, $20, $F6, $7B, $FE, $0A, $30, $F1, $0B, $C6, $C0, $22, $79
db $FE, $DF, $28, $04, $0A, $0B, $18, $F4, $CD, $E3, $47, $FA, $FB, $D6, $FE, $03
db $C0, $CD, $17, $7B, $C9, $CD, $96, $45, $3E, $E9, $CD, $9F, $44, $01, $A0, $53
db $21, $41, $DC, $CD, $95, $44, $01, $A9, $53, $21, $81, $DC, $CD, $95, $44, $01
db $B5, $53, $21, $C1, $DC, $CD, $95, $44, $01, $BE, $53, $21, $01, $DD, $CD, $95
db $44, $01, $C9, $53, $21, $41, $DD, $CD, $6C, $48, $CA, $CA, $46, $CD, $76, $48
db $FA, $9B, $DB, $20, $07, $FE, $90, $C2, $CA, $46, $18, $05, $FE, $82, $C2, $CA
db $46, $CD, $95, $44, $01, $D7, $53, $21, $81, $DD, $CD, $95, $44, $01, $E2, $53
db $21, $C1, $DD, $CD, $95, $44, $01, $EB, $53, $21, $01, $DE, $CD, $95, $44, $01
db $FA, $53, $21, $41, $DE, $CD, $95, $44, $CD, $E3, $47, $C9, $CD, $96, $45, $3E
db $E2, $CD, $9F, $44, $01, $D3, $54, $21, $43, $DC, $CD, $95, $44, $01, $DD, $54
db $21, $81, $DC, $CD, $95, $44, $CD, $E3, $47, $CD, $10, $4D, $C9, $CD, $95, $44
db $CD, $40, $36, $CD, $52, $36, $CD, $E3, $47, $CD, $46, $3D, $C9, $FA, $0D, $D7
db $67, $FA, $1F, $D7, $94, $E6, $0F, $C6, $02, $EA, $CB, $C8, $F5, $FA, $1E, $D7
db $67, $FA, $1F, $D7, $6F, $F1, $CD, $31, $3D, $CB, $35, $CB, $34, $7D, $E6, $0F
db $6F, $7C, $E6, $F0, $B5, $D6, $C0, $CB, $3F, $CB, $3F, $C6, $04, $EA, $CA, $C8
db $C9, $3E, $2E, $EA, $25, $D0, $CD, $40, $36, $CD, $52, $36, $FA, $15, $D7, $CB
db $57, $28, $15, $CD, $0B, $48, $FA, $25, $D0, $FE, $FF, $C8, $FE, $85, $C8, $FE
db $A5, $C8, $FA, $15, $D7, $CB, $57, $C0, $21, $15, $D7, $CB, $86, $01, $00, $02
db $21, $00, $D8, $FA, $17, $D7, $57, $3E, $BE, $CD, $81, $52, $01, $20, $00, $21
db $00, $D7, $AF, $CD, $81, $52, $7A, $EA, $17, $D7, $CD, $FF, $47, $21, $00, $DC
db $F5, $7C, $EA, $0C, $D7, $7D, $EA, $0D, $D7, $F1, $3E, $01, $EA, $1C, $D7, $21
db $02, $DC, $3E, $A1, $CD, $BE, $3D, $21, $43, $DC, $F5, $7C, $EA, $1E, $D7, $7D
db $EA, $1F, $D7, $F1, $CD, $E3, $47, $CD, $09, $35, $CC, $8A, $48, $3E, $06, $EA
db $07, $D7, $CD, $DD, $36, $3E, $01, $EA, $1C, $D7, $CD, $49, $36, $3E, $FF, $EA
db $16, $D7, $C9, $CD, $F0, $0A, $CD, $10, $0B, $F5, $FA, $0C, $D7, $57, $FA, $0D
db $D7, $5F, $F1, $CD, $70, $04, $F0, $10, $E6, $CF, $F6, $C1, $E0, $10, $C9, $01
db $80, $03, $21, $00, $DC, $3E, $BE, $CD, $81, $52, $C9, $CD, $75, $46, $CD, $10
db $4D, $FA, $25, $D0, $FE, $2A, $20, $06, $3E, $FF, $EA, $25, $D0, $C9, $D6, $80
db $E6, $1F, $FE, $13, $28, $25, $FE, $04, $28, $38, $FE, $05, $20, $E0, $CD, $6C
db $48, $28, $DB, $CD, $76, $48, $20, $06, $FA, $9B, $DB, $FE, $90, $C8, $CD, $80
db $48, $20, $CB, $FA, $9B, $DB, $FE, $82, $C8, $18, $C3, $CD, $2D, $40, $CD, $40
db $36, $CD, $52, $36, $FA, $25, $D0, $FE, $A5, $28, $B0, $FA, $25, $D7, $FE, $FF
db $28, $A9, $AF, $EA, $25, $D0, $21, $15, $D7, $CB, $96, $C9, $3E, $01, $CB, $47
db $FA, $17, $D7, $FE, $0C, $C9, $3E, $01, $CB, $47, $FA, $17, $D7, $FE, $00, $C9
db $3E, $01, $CB, $47, $FA, $17, $D7, $FE, $03, $C9, $01, $C0, $02, $21, $C0, $DC
db $3E, $BE, $CD, $81, $52, $01, $C0, $DC, $AF, $EA, $1D, $D7, $EA, $2C, $D7, $EA
db $2E, $D7, $FA, $1C, $D7, $3D, $EA, $2D, $D7, $FA, $2E, $D7, $5F, $FA, $2C, $D7
db $83, $5F, $FA, $1D, $D7, $83, $EA, $4C, $D0, $AF, $C5, $CD, $D6, $2F, $C1, $FA
db $34, $D0, $FE, $00, $28, $54, $FA, $33, $D0, $FE, $90, $CC, $7A, $48, $28, $14
db $FE, $82, $CC, $84, $48, $28, $0D, $FE, $87, $CC, $70, $48, $28, $06, $21, $2C
db $D7, $34, $18, $C5, $FA, $2D, $D7, $FE, $00, $28, $06, $3D, $EA, $2D, $D7, $18
db $ED, $21, $28, $D0, $16, $0A, $2A, $CD, $B5, $3D, $02, $03, $15, $20, $F7, $C5
db $E1, $CD, $31, $3D, $11, $40, $00, $19, $E5, $03, $03, $CD, $07, $52, $C1, $FA
db $1D, $D7, $3C, $EA, $1D, $D7, $FE, $0D, $38, $8F, $C9, $21, $02, $DC, $3E, $A1
db $CD, $BE, $3D, $21, $43, $DC, $F5, $7C, $EA, $1E, $D7, $7D, $EA, $1F, $D7, $F1
db $CD, $E3, $47, $C9, $CD, $E3, $47, $CD, $10, $4D, $FA, $25, $D0, $FE, $2A, $C8
db $FE, $2D, $CA, $23, $4B, $FE, $35, $CC, $84, $48, $CA, $C9, $49, $FA, $25, $D0
db $FE, $31, $CA, $C9, $49, $FE, $34, $CA, $EF, $49, $FE, $2E, $CA, $C9, $49, $FE
db $2C, $CA, $00, $4A, $FE, $3C, $CA, $2C, $4A, $FE, $3D, $CA, $85, $4A, $FE, $40
db $CA, $90, $4A, $FE, $3F, $CA, $67, $4A, $FE, $3E, $CA, $54, $4A, $FE, $44, $CA
db $09, $4B, $FE, $45, $CA, $16, $4B, $FE, $BE, $28, $0A, $CD, $07, $4C, $FA, $09
db $D7, $E6, $06, $28, $A2, $F5, $FA, $1E, $D7, $67, $FA, $1F, $D7, $6F, $F1, $FA
db $25, $D0, $77, $CD, $51, $52, $F5, $FA, $1E, $D7, $67, $FA, $1F, $D7, $6F, $F1
db $7D, $FE, $4C, $28, $0B, $23, $F5, $7C, $EA, $1E, $D7, $7D, $EA, $1F, $D7, $F1
db $FA, $25, $D0, $EA, $06, $D7, $C3, $37, $49, $CD, $0D, $37, $CD, $88, $4C, $28
db $12, $FA, $17, $D7, $FE, $0C, $C8, $CD, $8E, $3E, $FE, $FF, $C0, $CD, $51, $47
db $C3, $34, $49, $FA, $07, $D7, $CD, $DD, $36, $C3, $37, $49, $C3, $34, $49, $CD
db $51, $4B, $FE, $FF, $CA, $37, $49, $CD, $88, $4C, $28, $E7, $CD, $48, $3E, $C9
db $F5, $FA, $1E, $D7, $47, $FA, $1F, $D7, $4F, $F1, $79, $FE, $43, $CA, $EC, $49
db $0D, $F5, $78, $EA, $1E, $D7, $79, $EA, $1F, $D7, $F1, $06, $BE, $21, $4C, $DC
db $7E, $70, $47, $2D, $7D, $B9, $20, $F8, $70, $C3, $EC, $49, $F5, $FA, $1E, $D7
db $67, $FA, $1F, $D7, $6F, $F1, $FA, $08, $D7, $CB, $47, $28, $05, $36, $BE, $C3
db $EC, $49, $7D, $FE, $4D, $28, $F6, $2C, $F5, $7C, $EA, $1E, $D7, $7D, $EA, $1F
db $D7, $F1, $18, $AC, $F5, $FA, $1E, $D7, $67, $FA, $1F, $D7, $6F, $F1, $2D, $7D
db $FE, $42, $CA, $37, $49, $18, $11, $F5, $FA, $1E, $D7, $67, $FA, $1F, $D7, $6F
db $F1, $2C, $7D, $FE, $4D, $CA, $37, $49, $F5, $7C, $EA, $1E, $D7, $7D, $EA, $1F
db $D7, $F1, $C3, $37, $49, $CD, $9B, $4A, $FE, $00, $CA, $37, $49, $C3, $34, $49
db $CD, $C6, $4A, $FE, $00, $CA, $37, $49, $C3, $34, $49, $FA, $07, $D7, $FE, $06
db $28, $22, $FE, $07, $28, $06, $3D, $CD, $DD, $36, $18, $18, $FA, $1C, $D7, $FE
db $01, $20, $07, $3E, $06, $CD, $DD, $36, $18, $0A, $3D, $EA, $1C, $D7, $CD, $8A
db $48, $3E, $FF, $C9, $AF, $C9, $FA, $07, $D7, $FE, $11, $20, $17, $CD, $0D, $37
db $FA, $1C, $D7, $3C, $EA, $1C, $D7, $CD, $8A, $48, $FA, $07, $D7, $3D, $EA, $07
db $D7, $CD, $DD, $36, $21, $80, $DC, $01, $40, $00, $FA, $07, $D7, $3C, $D6, $06
db $09, $3D, $20, $FC, $0E, $10, $2A, $FE, $BE, $20, $05, $0D, $20, $F8, $18, $C1
db $FA, $07, $D7, $3C, $CD, $DD, $36, $18, $B8, $16, $0C, $D5, $CD, $9B, $4A, $D1
db $15, $20, $F8, $C3, $34, $49, $16, $0C, $D5, $CD, $C6, $4A, $D1, $15, $20, $F8
db $C3, $34, $49, $CD, $0D, $37, $21, $43, $DC, $16, $0C, $2A, $F5, $15, $20, $FB
db $CB, $BF, $CD, $A9, $4B, $CD, $FF, $47, $FA, $07, $D7, $CD, $DD, $36, $CD, $1B
db $49, $21, $4E, $DC, $16, $0C, $F1, $32, $15, $20, $FB, $CD, $8A, $48, $C3, $34
db $49, $06, $0E, $21, $23, $9A, $11, $20, $55, $CD, $F0, $0A, $1A, $13, $22, $05
db $20, $FA, $CD, $A2, $01, $CD, $51, $0E, $FA, $25, $D0, $FE, $93, $28, $12, $FE
db $B3, $28, $0E, $FE, $8E, $28, $08, $FE, $2A, $28, $04, $FE, $AE, $20, $E3, $3E
db $FF, $F5, $CD, $9B, $4B, $06, $0E, $21, $23, $9A, $CD, $F0, $0A, $3E, $BE, $13
db $22, $05, $20, $F9, $3E, $34, $EA, $25, $D0, $F1, $C9, $CD, $A2, $01, $CD, $51
db $0E, $FA, $25, $D0, $FE, $FF, $20, $F3, $C9, $F5, $CD, $40, $36, $CD, $52, $36
db $F1, $6F, $F5, $FA, $0C, $D7, $47, $FA, $0D, $D7, $4F, $F1, $C5, $F5, $01, $00
db $DC, $F5, $78, $EA, $0C, $D7, $79, $EA, $0D, $D7, $F1, $CD, $FF, $47, $21, $40
db $DC, $3E, $EB, $CD, $BE, $3D, $21, $45, $DC, $01, $CD, $54, $CD, $95, $44, $11
db $0F, $53, $21, $C1, $DC, $0E, $09, $CD, $F3, $51, $F1, $CB, $7F, $C2, $B2, $51
db $01, $0E, $00, $21, $C1, $DC, $3E, $BE, $CD, $81, $52, $01, $0E, $00, $21, $41
db $DD, $CD, $81, $52, $C3, $B2, $51, $F5, $FA, $09, $D7, $E6, $F1, $EA, $09, $D7
db $F1, $CD, $1B, $4C, $CD, $46, $4C, $CD, $59, $4C, $C9, $F5, $FE, $81, $38, $1A
db $FE, $BE, $30, $16, $FE, $9E, $28, $12, $FE, $9F, $28, $0E, $FE, $A0, $28, $0A
db $FA, $09, $D7, $CB, $CF, $EA, $09, $D7, $18, $0A, $FE, $D0, $38, $06, $FE, $E2
db $30, $02, $18, $EC, $F1, $C9, $F5, $FE, $C0, $38, $0C, $FE, $CA, $30, $08, $FA
db $09, $D7, $CB, $D7, $EA, $09, $D7, $F1, $C9, $F5, $FE, $BE, $28, $20, $FE, $BF
db $28, $1C, $FE, $9E, $28, $18, $FE, $9F, $28, $14, $FE, $A0, $28, $10, $FE, $CA
db $38, $04, $FE, $CF, $38, $08, $FE, $63, $38, $0C, $FE, $7E, $30, $08, $FA, $09
db $D7, $CB, $DF, $EA, $09, $D7, $F1, $C9, $CD, $B8, $4C, $C0, $01, $43, $DC, $21
db $07, $D7, $7E, $D6, $06, $C8, $21, $80, $DC, $11, $40, $00, $19, $3D, $20, $FC
db $16, $0A, $2A, $02, $0C, $15, $20, $FA, $CD, $B8, $4C, $C9, $CD, $C5, $4C, $7A
db $EA, $4D, $DC, $3E, $9F, $EA, $4C, $DC, $0E, $0A, $21, $43, $DC, $2A, $FE, $BE
db $C0, $0D, $20, $F9, $C9, $16, $90, $CD, $76, $48, $28, $0E, $16, $82, $CD, $80
db $48, $28, $07, $16, $87, $CD, $6C, $48, $28, $00, $C9, $CD, $A2, $01, $FA, $06
db $D0, $CD, $30, $36, $0E, $FF, $20, $23, $0E, $40, $FA, $06, $D0, $CB, $7F, $20
db $1A, $0E, $3D, $CB, $77, $20, $14, $0E, $3E, $CB, $6F, $20, $0E, $0E, $3F, $CB
db $67, $20, $08, $0E, $2E, $CB, $57, $20, $02, $0E, $FF, $79, $EA, $25, $D0, $C9
db $CD, $34, $4D, $20, $42, $FA, $0A, $D7, $3C, $FE, $02, $38, $0C, $FA, $08, $D7
db $EE, $10, $EA, $08, $D7, $CD, $52, $36, $AF, $EA, $0A, $D7, $CD, $34, $4D, $20
db $26, $C3, $10, $4D, $CD, $DB, $4C, $FA, $25, $D0, $FE, $FF, $C0, $CD, $51, $0E
db $FA, $25, $D0, $FE, $FF, $C0, $FA, $25, $D0, $EA, $06, $D7, $FA, $08, $D7, $CB
db $97, $EA, $08, $D7, $CB, $57, $C9, $FE, $FE, $CA, $10, $4D, $FE, $FA, $CA, $10
db $4D, $CD, $A1, $36, $CD, $52, $36, $FA, $06, $D7, $4F, $FA, $25, $D0, $FE, $00
db $28, $06, $EA, $06, $D7, $EA, $16, $D7, $B9, $20, $23, $FA, $08, $D7, $CB, $57
db $28, $0E, $FA, $10, $D7, $FE, $00, $20, $0E, $3E, $02, $EA, $10, $D7, $18, $16
db $CB, $D7, $EA, $08, $D7, $3E, $10, $3D, $EA, $10, $D7, $C3, $10, $4D, $FA, $08
db $D7, $CB, $97, $EA, $08, $D7, $FA, $25, $D0, $FE, $2F, $C0, $FA, $E4, $D2, $A7
db $28, $06, $CD, $6A, $41, $A7, $20, $03, $C3, $10, $4D, $CD, $2B, $05, $C3, $10
db $4D, $3E, $37, $E0, $06, $E0, $05, $3E, $04, $E0, $07, $3E, $15, $E0, $FF, $E0
db $0F, $AF, $E0, $2A, $CD, $A2, $01, $C9, $21, $15, $D7, $CB, $C6, $CB, $8E, $3E
db $FF, $EA, $16, $D7, $CD, $FF, $47, $AF, $EA, $18, $D7, $01, $00, $DC, $F5, $78
db $EA, $0C, $D7, $79, $EA, $0D, $D7, $F1, $F5, $78, $EA, $1E, $D7, $79, $EA, $1F
db $D7, $F1, $F5, $FA, $20, $D7, $47, $FA, $21, $D7, $4F, $F1, $F5, $78, $EA, $03
db $D7, $79, $EA, $04, $D7, $F1, $F5, $78, $EA, $0E, $D7, $79, $EA, $0F, $D7, $F1
db $CD, $46, $3D, $CD, $49, $36, $CD, $0D, $37, $FA, $9A, $DB, $4F, $FA, $8F, $DB
db $47, $C5, $3E, $41, $EA, $8F, $DB, $AF, $EA, $9A, $DB, $21, $8F, $DB, $16, $12
db $1E, $01, $CD, $6E, $44, $C1, $79, $EA, $9A, $DB, $78, $EA, $8F, $DB, $CD, $D3
db $3C, $CD, $46, $3D, $CD, $E3, $47, $CD, $10, $4D, $FA, $25, $D0, $FE, $35, $20
db $42, $FA, $17, $D7, $FE, $03, $20, $EF, $CD, $F6, $55, $FA, $FB, $D6, $FE, $00
db $CA, $7E, $4E, $FE, $FF, $CA, $7E, $4E, $CD, $21, $74, $CD, $10, $46, $CD, $10
db $4D, $FA, $25, $D0, $FE, $2A, $20, $F6, $FA, $C1, $D6, $CB, $77, $28, $0E, $CB
db $B7, $EA, $C1, $D6, $CD, $FF, $47, $CD, $E3, $47, $CD, $5E, $6A, $CD, $49, $36
db $C3, $D8, $4D, $FA, $25, $D0, $FE, $2D, $CA, $34, $51, $FE, $3D, $CA, $99, $4F
db $FE, $40, $CA, $A7, $4F, $FE, $3E, $CA, $BA, $4F, $FE, $3F, $CA, $B5, $4F, $FE
db $44, $CA, $2B, $50, $FE, $45, $CA, $31, $50, $FE, $31, $CA, $6B, $50, $FE, $2A
db $CA, $6B, $50, $FE, $32, $CA, $45, $50, $FE, $33, $CA, $65, $50, $FE, $34, $20
db $03, $C3, $B2, $50, $FE, $2C, $CA, $CD, $4F, $FA, $25, $D0, $FE, $30, $CA, $0A
db $4F, $FE, $3C, $CA, $BF, $4F, $FE, $2E, $28, $10, $FE, $00, $CA, $37, $50, $CD
db $07, $4C, $FA, $09, $D7, $E6, $0E, $CA, $57, $4E, $CD, $6E, $37, $28, $06, $CD
db $D3, $44, $C3, $54, $4E, $21, $15, $D7, $CB, $CE, $CB, $D6, $CD, $BE, $3C, $CD
db $88, $39, $20, $03, $CD, $21, $37, $FA, $25, $D0, $FE, $30, $20, $0C, $CD, $21
db $37, $CD, $46, $3D, $CD, $51, $52, $C3, $54, $4E, $FE, $2E, $20, $30, $F5, $FA
db $0E, $D7, $67, $FA, $0F, $D7, $6F, $F1, $CD, $F6, $2C, $FE, $2E, $28, $03, $CD
db $21, $37, $F5, $FA, $0E, $D7, $67, $FA, $0F, $D7, $6F, $F1, $FA, $25, $D0, $CD
db $1C, $2D, $CD, $46, $3D, $CD, $51, $52, $CD, $C4, $36, $C3, $54, $4E, $F5, $FA
db $0E, $D7, $67, $FA, $0F, $D7, $6F, $F1, $FA, $25, $D0, $CD, $F6, $2C, $FE, $2E
db $20, $03, $CD, $21, $37, $FA, $25, $D0, $CD, $1C, $2D, $CD, $66, $52, $CD, $C4
db $36, $FE, $FF, $CA, $57, $4E, $C3, $54, $4E, $CD, $65, $3B, $CD, $C9, $36, $FE
db $FF, $CA, $57, $4E, $C3, $54, $4E, $CD, $D5, $3B, $CD, $C9, $36, $FE, $FF, $CA
db $57, $4E, $C3, $54, $4E, $CD, $C4, $36, $18, $E5, $CD, $BF, $36, $18, $E0, $CD
db $BE, $3C, $CD, $88, $39, $20, $03, $C3, $54, $4E, $CD, $C4, $36, $F5, $FA, $0E
db $D7, $67, $FA, $0F, $D7, $6F, $F1, $CD, $C2, $3B, $CA, $54, $4E, $21, $15, $D7
db $CB, $CE, $CB, $D6, $CD, $BF, $36, $F5, $FA, $0E, $D7, $47, $FA, $0F, $D7, $4F
db $F1, $CD, $BE, $3C, $16, $BE, $5A, $CD, $B6, $2C, $57, $7B, $CD, $CD, $2C, $2B
db $7D, $B9, $20, $F2, $7C, $B8, $20, $EE, $7A, $CD, $1C, $2D, $AF, $CD, $A4, $2C
db $F5, $FA, $29, $D7, $67, $FA, $2A, $D7, $6F, $F1, $2B, $F5, $7C, $EA, $29, $D7
db $7D, $EA, $2A, $D7, $F1, $CD, $46, $3D, $C3, $54, $4E, $CD, $D9, $3A, $C3, $54
db $4E, $CD, $C7, $3A, $C3, $54, $4E, $FA, $16, $D7, $FE, $FF, $CA, $57, $4E, $EA
db $25, $D0, $C3, $5A, $4E, $F5, $FA, $20, $D7, $67, $FA, $21, $D7, $6F, $F1, $CD
db $F6, $2C, $FE, $FF, $CA, $57, $4E, $CD, $2D, $40, $FA, $25, $D7, $FE, $FF, $CA
db $AC, $50, $C3, $D8, $4D, $CD, $7C, $41, $C3, $54, $4E, $CD, $40, $36, $CD, $52
db $36, $CD, $96, $45, $CD, $E3, $47, $21, $15, $D7, $CB, $4E, $C8, $FA, $00, $D8
db $FE, $FF, $C8, $CD, $40, $36, $CD, $52, $36, $CD, $EA, $44, $CD, $10, $4D, $FA
db $25, $D0, $FE, $2A, $28, $10, $FE, $B3, $28, $12, $FE, $93, $28, $0E, $FE, $AE
db $28, $04, $FE, $8E, $20, $E6, $CD, $46, $3D, $C3, $23, $4E, $21, $15, $D7, $CB
db $96, $C9, $3E, $31, $EA, $CC, $C8, $AF, $EA, $CB, $C8, $3E, $03, $EA, $CA, $C8
db $CD, $91, $04, $3E, $3A, $EA, $CC, $C8, $3E, $04, $EA, $CA, $C8, $CD, $91, $04
db $CD, $40, $36, $CD, $52, $36, $21, $43, $DC, $F5, $7C, $EA, $1E, $D7, $7D, $EA
db $1F, $D7, $F1, $AF, $EA, $4C, $D0, $AF, $CD, $D6, $2F, $FA, $34, $D0, $FE, $00
db $CA, $2E, $51, $21, $00, $DC, $3E, $E2, $CD, $BE, $3D, $16, $0C, $21, $28, $D0
db $01, $43, $DC, $2A, $02, $03, $15, $20, $FA, $01, $86, $DC, $CD, $07, $52, $CD
db $E3, $47, $CD, $10, $4D, $FA, $25, $D0, $FE, $2A, $CA, $2E, $51, $FE, $34, $28
db $0A, $FE, $2E, $28, $06, $FE, $40, $28, $BE, $18, $E7, $CD, $48, $3E, $CD, $0C
db $40, $C3, $D8, $4D, $CD, $76, $48, $3E, $9F, $28, $02, $3E, $BF, $CD, $46, $51
db $CD, $46, $3D, $C3, $23, $4E, $F5, $CD, $40, $36, $CD, $52, $36, $F1, $6F, $F5
db $FA, $0C, $D7, $47, $FA, $0D, $D7, $4F, $F1, $C5, $F5, $01, $00, $DC, $F5, $78
db $EA, $0C, $D7, $79, $EA, $0D, $D7, $F1, $CD, $FF, $47, $21, $40, $DC, $3E, $EB
db $CD, $BE, $3D, $21, $45, $DC, $01, $CD, $54, $CD, $95, $44, $11, $91, $52, $21
db $C1, $DC, $0E, $09, $CD, $F3, $51, $F1, $CB, $7F, $20, $26, $01, $0E, $00, $21
db $C1, $DC, $3E, $BE, $CD, $81, $52, $01, $0E, $00, $21, $41, $DD, $CD, $81, $52
db $01, $83, $52, $21, $01, $DD, $CD, $95, $44, $01, $75, $52, $21, $C1, $DE, $CD
db $95, $44, $FA, $17, $D7, $FE, $03, $28, $25, $21, $01, $DE, $01, $0E, $00, $3E
db $BE, $CD, $81, $52, $21, $41, $DE, $01, $0E, $00, $CD, $81, $52, $FA, $17, $D7
db $A7, $28, $0B, $01, $0E, $00, $3E, $BE, $21, $81, $DD, $CD, $81, $52, $CD, $E3
db $47, $CD, $10, $4D, $C1, $F5, $78, $EA, $0C, $D7, $79, $EA, $0D, $D7, $F1, $CD
db $49, $36, $C9, $06, $0E, $1A, $22, $13, $05, $20, $FA, $7D, $C6, $32, $6F, $7C
db $CE, $00, $67, $0D, $20, $ED, $C9, $C5, $E1, $3E, $BE, $22, $22, $22, $77, $FA
db $4E, $D0, $5F, $FA, $4D, $D0, $57, $7A, $FE, $00, $20, $0D, $7B, $FE, $0A, $30
db $08, $C6, $C0, $32, $03, $03, $03, $03, $C9, $CD, $B8, $29, $C6, $C0, $32, $18
db $E6, $F0, $10, $CB, $8F, $E0, $10, $C9, $CD, $40, $36, $CD, $52, $36, $F3, $3E
db $37, $E0, $06, $E0, $05, $3E, $04, $E0, $07, $F0, $FF, $F6, $01, $E0, $FF, $FB
db $C9, $CD, $1D, $47, $F5, $FA, $1E, $D7, $67, $FA, $1F, $D7, $6F, $F1, $7E, $EA
db $CC, $C8, $CD, $91, $04, $C9, $CD, $1D, $47, $F5, $FA, $1E, $D7, $67, $FA, $1F
db $D7, $6F, $F1, $FA, $25, $D0, $CD, $B5, $3D, $EA, $CC, $C8, $77, $CD, $91, $04
db $C9, $D5, $C5, $F5, $57, $7A, $22, $0B, $78, $B1, $20, $F9, $7A, $F1, $C1, $D1
db $C9, $86, $C1, $BE, $73, $BE, $89, $8E, $93, $85, $92, $94, $81, $92, $BE, $86
db $C2, $BE, $73, $BE, $93, $81, $8C, $89, $92, $BE, $BE, $BE, $BE, $86, $C3, $BE
db $73, $BE, $93, $81, $8C, $96, $81, $92, $BE, $BE, $BE, $86, $C4, $BE, $73, $BE
db $89, $8D, $90, $92, $89, $8D, $89, $92, $BE, $86, $C5, $BE, $73, $BE, $82, $8F
db $92, $92, $81, $92, $BE, $BE, $BE, $86, $C6, $BE, $73, $BE, $83, $8F, $92, $92
db $85, $92
ds 17, $BE
db $93, $81, $8C, $89, $84, $81, $BE, $73, $BE, $89, $92, $BE, $81, $8C, $BE, $BE
db $BE, $BE, $84, $89, $92, $85, $83, $94, $8F, $92, $89, $8F
ds 14, $BE
db $86, $C2, $BE, $73, $BE, $93, $81, $8C, $89, $92
ds 32, $BE
db $86, $C5, $BE, $73, $BE, $82, $8F, $92, $92, $81, $92
ds 31, $BE
db $93, $81, $8C, $89, $84, $81, $BE, $73, $BE, $89, $92, $BE, $81, $8C, $BE, $BE
db $BE, $BE, $84, $89, $92, $85, $83, $94, $8F, $92, $89, $8F, $8E, $8F, $BE, $88
db $81, $99, $BE, $8D, $81, $93, $00, $85, $93, $90, $81, $83, $89, $8F, $00, $95
db $8C, $94, $89, $8D, $8F, $BE, $BE, $00, $81, $92, $83, $88, $89, $96, $8F, $BE
db $8E, $8F, $BE, $00, $93, $81, $8C, $96, $81, $84, $8F, $9E, $00, $D0, $6A, $93
db $6B, $81, $8C, $96, $81, $92, $BF, $00, $D0, $6A, $84, $6B, $85, $93, $83, $81
db $92, $94, $81, $92, $BF, $00, $D0, $6A, $85, $6B, $84, $89, $94, $81, $92, $BF
db $00, $6A, $93, $81, $8C, $89, $84, $81, $6B, $00, $96, $8F, $8C, $96, $85, $92
db $BE, $81, $8C, $BE, $8D, $85, $8E, $95, $00, $90, $92, $89, $8E, $83, $89, $90
db $81, $8C, $00, $D0, $84, $85, $93, $83, $81, $92, $94, $81, $92, $BF, $00, $93
db $89, $69, $8E, $8F, $00, $85, $8C, $BE, $81, $92, $83, $88, $89, $96, $8F, $00
db $99, $81, $BE, $85, $98, $89, $93, $94, $85, $9E, $00, $D0, $93, $8F, $82, $92
db $85, $85, $93, $83, $92, $89, $82, $89, $92, $00, $93, $89, $69, $8E, $8F, $BF
db $00, $85, $93, $94, $85, $BE, $81, $92, $83, $88, $89, $96, $8F, $00, $99, $81
db $BE, $85, $98, $89, $93, $94, $85, $9E, $00, $D0, $93, $8F, $82, $92, $85, $85
db $93, $83, $92, $89, $82, $89, $92, $00, $85, $8E, $BE, $85, $8C, $BF, $00, $85
db $8C, $BE, $84, $89, $93, $83, $8F, $BE, $85, $93, $94, $81, $00, $83, $8F, $8D
db $90, $8C, $85, $94, $8F, $00, $84, $89, $92, $85, $83, $94, $8F, $92, $89, $8F
db $00, $83, $8D, $90, $8C, $85, $94, $8F, $00, $89, $8D, $90, $92, $85, $93, $8F
db $92, $81, $BE, $8E, $8F, $BE, $00, $8C, $89, $93, $94, $81, $00, $85, $8C, $BE
db $81, $92, $83, $88, $89, $96, $8F, $00, $8E, $8F, $BE, $85, $98, $89, $93, $94
db $85, $00, $85, $B2, $B2, $AF, $B2, $BE, $00, $A5, $AE, $00, $81, $99, $95, $84
db $81, $00, $8E, $8F, $BE, $85, $98, $89, $93, $94, $85, $00, $84, $89, $93, $83
db $8F, $BE, $8D, $85, $8D, $8F, $CB, $92, $81, $8D, $00, $8E, $8F, $BE, $85, $98
db $89, $93, $94, $85, $BE, $84, $89, $93, $83, $8F, $00, $84, $85, $BE, $8D, $85
db $8D, $8F, $92, $89, $81, $BE, $92, $81, $8D, $00, $85, $93, $90, $85, $92, $81
db $92, $00, $93, $81, $8C, $96, $81, $92, $BE, $93, $89, $F1, $8E, $8F, $00, $D0
db $85, $93, $94, $81, $93, $BE, $93, $85, $87, $95, $92, $8F, $BF, $F3, $CD, $40
db $36, $CD, $31, $52, $CD, $F0, $0A, $CD, $10, $0B, $21, $00, $90, $11, $09, $14
db $01, $00, $08, $CD, $00, $C9, $CD, $F0, $0A, $CD, $10, $0B, $21, $00, $88, $11
db $21, $1F, $01, $00, $08, $CD, $00, $C9, $11, $21, $1A, $CD, $CA, $57, $CD, $4C
db $29, $CD, $C1, $4D, $FB, $3E, $03, $EA, $17, $D7, $FA, $FB, $DB, $CB, $67, $20
db $0B, $CD, $D9, $55, $FA, $FB, $DB, $CB, $E7, $EA, $FB, $DB, $CD, $4C, $29, $CD
db $08, $46, $CD, $51, $47, $FA, $25, $D0, $FE, $FF, $CA, $38, $52, $FE, $85, $28
db $42, $FE, $A5, $28, $3E, $FA, $15, $D7, $CB, $57, $C2, $38, $52, $CD, $34, $49
db $FA, $25, $D0, $FE, $2A, $CA, $38, $52, $FE, $33, $C2, $B6, $55, $CD, $7C, $41
db $CD, $26, $4E, $18, $C7, $FE, $34, $CA, $7D, $55, $FE, $2E, $28, $15, $FE, $31
db $28, $11, $FE, $35, $20, $B6, $CD, $80, $48, $20, $B1, $CD, $F6, $55, $CD, $6B
db $4E, $18, $A9, $CC, $D8, $4D, $18, $A4, $FA, $FB, $DB, $E6, $05, $20, $04, $AF
db $EA, $15, $D7, $CD, $09, $35, $C0, $21, $00, $00, $CD, $F6, $2C, $FE, $40, $D8
db $AF, $CD, $1C, $2D, $C9, $F5, $FA, $20, $D7, $67, $FA, $21, $D7, $6F, $F1, $2B
db $CD, $F6, $2C, $EA, $24, $D7, $3E, $2E, $CD, $1C, $2D, $CD, $21, $56, $F5, $FA
db $20, $D7, $67, $FA, $21, $D7, $6F, $F1, $2B, $FA, $24, $D7, $CD, $1C, $2D, $C9
db $CD, $77, $65, $CD, $40, $36, $CD, $52, $36, $AF, $01, $00, $02, $21, $00, $D5
db $CD, $81, $52, $3E, $8F, $EA, $2F, $D7, $AF, $EA, $3A, $D7, $F5, $FA, $20, $D7
db $47, $FA, $21, $D7, $4F, $F1, $0B, $21, $F5, $D6, $78, $22, $79, $22, $21, $FC
db $D6, $3E, $FF, $22, $22, $AF, $22, $3C, $22, $21, $15, $D7, $CB, $A6, $CD, $F3
db $64, $21, $00, $DC, $F5, $7C, $EA, $1E, $D7, $7D, $EA, $1F, $D7, $F1, $F5, $FA
db $F5, $D6, $67, $FA, $F6, $D6, $6F, $F1, $CD, $F6, $2C, $FE, $2E, $20, $3F, $CD
db $F6, $2C, $23, $FE, $2E, $28, $F8, $FE, $BE, $28, $F4, $FE, $C0, $28, $F0, $2B
db $F5, $7C, $EA, $F5, $D6, $7D, $EA, $F6, $D6, $F1, $CD, $EB, $57, $CD, $A3, $57
db $FA, $FB, $D6, $FE, $00, $28, $17, $F5, $FA, $F9, $D6, $67, $FA, $FA, $D6, $6F
db $F1, $F5, $7C, $EA, $FE, $D6, $7D, $EA, $FF, $D6, $F1, $C3, $15, $74, $F5, $FA
db $F5, $D6, $67, $FA, $F6, $D6, $6F, $F1, $CD, $F6, $2C, $23, $4F, $F5, $7C, $EA
db $F5, $D6, $7D, $EA, $F6, $D6, $F1, $79, $FE, $FF, $20, $92, $FA, $F9, $D6, $4F
db $FA, $FE, $D6, $B9, $38, $14, $20, $0C, $FA, $FA, $D6, $4F, $FA, $FF, $D6, $B9
db $38, $08, $28, $06, $3E, $02, $EA, $FB, $D6, $C9, $F5, $FA, $F7, $D6, $67, $FA
db $F8, $D6, $6F, $F1, $F5, $7C, $EA, $F5, $D6, $7D, $EA, $F6, $D6, $F1, $F5, $FA
db $F9, $D6, $67, $FA, $FA, $D6, $6F, $F1, $F5, $7C, $EA, $FE, $D6, $7D, $EA, $FF
db $D6, $F1, $CD, $A3, $57, $FA, $3A, $D7, $A7, $28, $34, $AF, $EA, $3A, $D7, $F5
db $FA, $FE, $D6, $67, $FA, $FF, $D6, $6F, $F1, $FA, $38, $D7, $BC, $20, $06, $FA
db $39, $D7, $BD, $28, $1A, $F5, $FA, $3C, $D7, $67, $FA, $3D, $D7, $6F, $F1, $F5
db $7C, $EA, $FE, $D6, $7D, $EA, $FF, $D6, $F1, $3E, $0E, $EA, $FB, $D6, $C9, $CD
db $10, $59, $CD, $AF, $73, $F5, $FA, $FE, $D6, $67, $FA, $FF, $D6, $6F, $F1, $23
db $F5, $7C, $EA, $FE, $D6, $7D, $EA, $FF, $D6, $F1, $FA, $15, $D7, $CB, $A7, $EA
db $15, $D7, $3E, $FF, $EA, $FC, $D6, $EA, $FD, $D6, $F5, $FA, $20, $D7, $67, $FA
db $21, $D7, $6F, $F1, $2B, $F5, $7C, $EA, $F5, $D6, $7D, $EA, $F6, $D6, $F1, $C3
db $6F, $56, $3E, $0A, $CD, $A0, $2C, $FA, $2F, $D7, $3D, $EA, $2F, $D7, $C0, $3E
db $8F, $EA, $2F, $D7, $E5, $C5, $D5, $CD, $51, $0E, $D1, $C1, $E1, $FA, $25, $D0
db $FE, $2A, $C0, $3E, $03, $EA, $FB, $D6, $C9, $CD, $F0, $0A, $CD, $10, $0B, $01
db $80, $02, $21, $00, $90, $CD, $00, $C9, $21, $30, $96, $11, $21, $27, $01, $D0
db $01, $1A, $13, $22, $0B, $78, $B1, $20, $F8, $C9, $CD, $6C, $58, $CD, $AF, $73
db $C5, $D1, $21, $FE, $D6, $78, $96, $D8, $20, $04, $23, $79, $96, $D8, $21, $FF
db $D6, $79, $96, $4F, $2B, $78, $9E, $47, $21, $FC, $D6, $78, $96, $38, $2D, $C0
db $23, $79, $96, $38, $27, $C0, $21, $F9, $D6, $7A, $BE, $20, $1F, $23, $7B, $BE
db $20, $1A, $F5, $FA, $F9, $D6, $67, $FA, $FA, $D6, $6F, $F1, $F5, $7C, $EA, $FE
db $D6, $7D, $EA, $FF, $D6, $F1, $3E, $01, $EA, $FB, $D6, $C9, $F5, $7A, $EA, $F9
db $D6, $7B, $EA, $FA, $D6, $F1, $F5, $78, $EA, $FC, $D6, $79, $EA, $FD, $D6, $F1
db $F5, $FA, $F5, $D6, $67, $FA, $F6, $D6, $6F, $F1, $F5, $7C, $EA, $F7, $D6, $7D
db $EA, $F8, $D6, $F1, $C9, $3E, $01, $EA, $FB, $D6, $C9, $01, $00, $00, $CD, $53
db $74, $F5, $FA, $F5, $D6, $67, $FA, $F6, $D6, $6F, $F1, $CD, $F6, $2C, $23, $FE
db $2E, $28, $5A, $FE, $CB, $28, $56, $CD, $07, $4C, $5F, $FA, $09, $D7, $CB, $57
db $20, $06, $7B, $FE, $FF, $20, $46, $C9, $7B, $FE, $C0, $20, $0C, $F5, $7C, $EA
db $F5, $D6, $7D, $EA, $F6, $D6, $F1, $18, $C2, $CD, $07, $4C, $D6, $C0, $5F, $FA
db $09, $D7, $E6, $0E, $FE, $04, $28, $2B, $2B, $F5, $7C, $EA, $F5, $D6, $7D, $EA
db $F6, $D6, $F1, $CD, $F6, $2C, $FE, $BE, $C8, $FE, $2E, $C8, $FE, $9E, $20, $0D
db $FA, $C3, $D6, $FE, $0A, $20, $06, $FA, $C0, $D6, $FE, $08, $C8, $3E, $07, $EA
db $FB, $D6, $C9, $16, $00, $D5, $11, $00, $00, $79, $B0, $28, $12, $7B, $C6, $0A
db $5F, $7A, $CE, $00, $57, $0B, $30, $F1, $D1, $3E, $15, $EA, $FB, $D6, $C9, $C1
db $79, $83, $4F, $7A, $CE, $00, $47, $38, $F0, $CD, $F6, $2C, $23, $18, $9A, $CD
db $AF, $73, $21, $C1, $D6, $CB, $AE, $AF, $EA, $DC, $D6, $EA, $DD, $D6, $CD, $85
db $74, $FA, $C0, $D6, $FE, $00, $20, $05, $CD, $53, $77, $18, $58, $21, $15, $D7
db $CB, $9E, $21, $C1, $D6, $CB, $66, $20, $03, $CD, $61, $61, $CD, $99, $65, $CD
db $87, $62, $CD, $DA, $65, $CD, $64, $65, $CD, $30, $72, $CD, $5E, $65, $CD, $53
db $65, $CD, $FD, $67, $CD, $09, $69, $CD, $8C, $59, $CD, $A1, $6A, $CD, $F8, $69
db $CD, $59, $6A, $CD, $BB, $6C, $CD, $ED, $6E, $CD, $69, $70, $CD, $E0, $72, $CD
db $74, $73, $CD, $D8, $72, $21, $C1, $D6, $CB, $5E, $28, $09, $CB, $9E, $CB, $E6
db $CD, $A3, $57, $18, $8A, $21, $C1, $D6, $CB, $A6, $C9, $AF, $E0, $01, $E0, $02
db $E0, $45, $AF, $E0, $2A, $3E, $FF, $E0, $2B, $3E, $55, $01, $3F, $08, $E2, $0D
db $05, $20, $FB, $21, $45, $FF, $3E, $80, $32, $36, $77, $3E, $28, $E0, $22, $E0
db $25, $C9, $16, $00, $F5, $FA, $F5, $D6, $67, $FA, $F6, $D6, $6F, $F1, $CD, $F6
db $2C, $23, $FE, $2E, $20, $06, $3E, $04, $EA, $FB, $D6, $C9, $FE, $CE, $20, $05
db $16, $01, $C3, $03, $5A, $FE, $76, $28, $06, $FE, $77, $28, $02, $18, $DF, $D6
db $75, $CB, $27, $57, $CD, $F6, $2C, $FE, $CE, $20, $04, $14, $C3, $03, $5A, $FE
db $76, $C2, $03, $5A, $7A, $16, $06, $FE, $02, $C2, $03, $5A, $3E, $0D, $EA, $FB
db $D6, $C9, $2B, $7A, $EA, $C2, $D6, $F5, $7C, $EA, $F7, $D6, $7D, $EA, $F8, $D6
db $F1, $FA, $C1, $D6, $CB, $BF, $EA, $C1, $D6, $16, $00, $2B, $CD, $F6, $2C, $FE
db $6B, $20, $03, $14, $18, $05, $FE, $6A, $20, $01, $15, $FA, $F6, $D6, $BD, $20
db $EA, $FA, $F5, $D6, $BC, $20, $E4, $7A, $FE, $00, $C8, $FE, $FF, $C2, $52, $5A
db $23, $F5, $7C, $EA, $F5, $D6, $7D, $EA, $F6, $D6, $F1, $21, $C1, $D6, $CB, $FE
db $C9, $3E, $0C, $EA, $FB, $D6, $C9, $CD, $53, $74, $1E, $00, $F5, $FA, $F5, $D6
db $67, $FA, $F6, $D6, $6F, $F1, $CD, $F6, $2C, $23, $FE, $2E, $20, $0D, $2B, $F5
db $7C, $EA, $F7, $D6, $7D, $EA, $F8, $D6, $F1, $18, $4E, $FE, $6A, $20, $03, $1C
db $18, $E4, $FE, $6B, $20, $03, $1D, $18, $DD, $E5, $F5, $FA, $F5, $D6, $47, $FA
db $F6, $D6, $4F, $F1, $C5, $F5, $7C, $EA, $F5, $D6, $7D, $EA, $F6, $D6, $F1, $FA
db $C0, $D6, $F5, $CD, $85, $74, $FA, $C0, $D6, $57, $F1, $EA, $C0, $D6, $C1, $F5
db $78, $EA, $F5, $D6, $79, $EA, $F6, $D6, $F1, $7A, $FE, $00, $E1, $28, $A7, $F5
db $7C, $EA, $F7, $D6, $7D, $EA, $F8, $D6, $F1, $7B, $FE, $00, $C8, $FE, $FF, $C2
db $52, $5A, $21, $C1, $D6, $CB, $7E, $CB, $BE, $28, $1E, $F5, $FA, $F7, $D6, $67
db $FA, $F8, $D6, $6F, $F1, $CD, $F6, $2C, $2B, $FE, $6B, $20, $F8, $23, $F5, $7C
db $EA, $F7, $D6, $7D, $EA, $F8, $D6, $F1, $C9, $3E, $0C, $EA, $FB, $D6, $C9, $21
db $C1, $D6, $CB, $86, $CD, $B8, $5F, $16, $0A, $21, $D0, $D6, $01, $E0, $D6, $2A
db $02, $03, $15, $20, $FA, $CD, $98, $5F, $3E, $CB, $CD, $69, $5F, $EA, $3F, $D4
db $CD, $B7, $34, $FA, $3F, $D4, $CD, $0B, $60, $20, $06, $3E, $0A, $EA, $FB, $D6
db $C9, $CD, $6C, $5B, $20, $0E, $FA, $C2, $D6, $FE, $01, $C8, $FE, $03, $C8, $FE
db $05, $C8, $18, $21, $FA, $C2, $D6, $FE, $06, $C8, $FA, $23, $D4, $FE, $00, $20
db $0B, $FA, $C2, $D6, $FE, $02, $C8, $FE, $03, $C8, $18, $09, $FA, $C2, $D6, $FE
db $04, $C8, $FE, $05, $C8, $21, $C1, $D6, $CB, $C6, $C9, $21, $21, $D4, $16, $08
db $3A, $FE, $00, $C0, $15, $20, $F9, $C9, $F5, $FA, $EC, $D6, $67, $FA, $ED, $D6
db $6F, $F1, $FA, $F6, $D6, $BD, $20, $0F, $FA, $F5, $D6, $BC, $20, $09, $FA, $C4
db $D6, $CB, $DF, $EA, $C4, $D6, $C9, $2B, $F5, $7C, $EA, $EC, $D6, $7D, $EA, $ED
db $D6, $F1, $CD, $30, $74, $FA, $C4, $D6, $CB, $9F, $CB, $AF, $EA, $C4, $D6, $F5
db $FA, $EC, $D6, $67, $FA, $ED, $D6, $6F, $F1, $CD, $F6, $2C, $2B, $FE, $9E, $28
db $4C, $FE, $6A, $28, $48, $FE, $6B, $28, $44, $FE, $76, $28, $40, $FE, $77, $28
db $3C, $FE, $6F, $28, $38, $FE, $69, $28, $34, $FE, $CA, $28, $30, $FE, $CB, $28
db $2C, $FE, $CC, $28, $28, $FE, $CD, $28, $24, $FE, $CE, $28, $20, $FE, $BE, $28
db $1C, $FA, $C4, $D6, $CB, $EF, $EA, $C4, $D6, $FA, $F6, $D6, $BD, $20, $BA, $BC
db $20, $B7, $F5, $7C, $EA, $EC, $D6, $7D, $EA, $ED, $D6, $F1, $C9, $23, $FA, $C4
db $D6, $CB, $6F, $28, $01, $23, $F5, $7C, $EA, $EC, $D6, $7D, $EA, $ED, $D6, $F1
db $C9, $FA, $15, $D7, $CB, $B7, $EA, $15, $D7, $AF, $EA, $F4, $D6, $F5, $FA, $F7
db $D6, $67, $FA, $F8, $D6, $6F, $F1, $F5, $7C, $EA, $EC, $D6, $7D, $EA, $ED, $D6
db $F1, $FA, $C4, $D6, $CB, $9F, $EA, $C4, $D6, $CD, $79, $5B, $FA, $C4, $D6, $CB
db $5F, $C2, $94, $5E, $F5, $FA, $EC, $D6, $67, $FA, $ED, $D6, $6F, $F1, $CD, $F6
db $2C, $FE, $6B, $20, $0E, $F5, $CD, $91, $5F, $FA, $15, $D7, $CB, $B7, $EA, $15
db $D7, $18, $CE, $FE, $6A, $C2, $99, $5D, $01, $E0, $D6, $CD, $88, $5F, $DA, $21
db $5F, $F1, $FE, $CA, $28, $0A, $FE, $CB, $28, $06, $F5, $CD, $91, $5F, $18, $12
db $F5, $01, $0A, $00, $21, $E0, $D6, $AF, $CD, $81, $52, $CD, $98, $5F, $F1, $C3
db $55, $5D, $CD, $88, $5F, $DA, $21, $5F, $F1, $02, $0C, $79, $FE, $EA, $C2, $A3
db $5C, $CD, $98, $5F, $FA, $F4, $D6, $FE, $00, $CA, $21, $5F, $CD, $88, $5F, $DA
db $94, $5E, $F1, $FE, $6B, $C2, $4D, $5D, $CD, $88, $5F, $30, $15, $AF, $EA, $F4
db $D6, $01, $E9, $D6, $0A, $F5, $CD, $91, $5F, $0D, $79, $FE, $DF, $20, $F5, $C3
db $42, $5C, $F1, $FE, $69, $28, $21, $FE, $6F, $28, $1D, $FE, $CD, $28, $19, $FE
db $CC, $28, $15, $F5, $CD, $91, $5F, $01, $E9, $D6, $0A, $F5, $CD, $91, $5F, $0D
db $79, $FE, $DF, $20, $F5, $C3, $42, $5C, $CD, $69, $5F, $EA, $3F, $D4, $01, $E0
db $D6, $CD, $88, $5F, $DA, $21, $5F, $F1, $02, $0C, $79, $FE, $EA, $20, $F2, $CD
db $B8, $5F, $CD, $2D, $5F, $CD, $B7, $34, $FA, $3F, $D4, $CD, $0B, $60, $20, $08
db $3E, $0A, $EA, $FB, $D6, $C3, $94, $5E, $CD, $D8, $5F, $01, $E9, $D6, $0A, $F5
db $CD, $91, $5F, $0D, $79, $FE, $DF, $20, $F5, $C3, $42, $5C, $FE, $CA, $28, $04
db $FE, $CB, $28, $00, $CD, $69, $5F, $EA, $3F, $D4, $01, $E0, $D6, $CD, $88, $5F
db $DA, $94, $5E, $F1, $02, $0C, $79, $FE, $EA, $20, $F2, $CD, $B8, $5F, $CD, $B7
db $34, $FA, $3F, $D4, $CD, $0B, $60, $20, $08, $3E, $0A, $EA, $FB, $D6, $C3, $94
db $5E, $CD, $D8, $5F, $01, $E9, $D6, $0A, $F5, $CD, $91, $5F, $0D, $79, $FE, $DF
db $20, $F5, $01, $E0, $D6, $C3, $7C, $5C, $FE, $69, $28, $0C, $FE, $CD, $28, $08
db $FE, $6F, $28, $04, $FE, $CC, $20, $0F, $F5, $CD, $91, $5F, $FA, $15, $D7, $CB
db $F7, $EA, $15, $D7, $C3, $42, $5C, $FE, $CA, $28, $04, $FE, $CB, $20, $0F, $F5
db $CD, $91, $5F, $FA, $15, $D7, $CB, $B7, $EA, $15, $D7, $C3, $42, $5C, $F5, $FA
db $F5, $D6, $47, $FA, $F6, $D6, $4F, $F1, $C5, $F5, $7C, $EA, $F5, $D6, $7D, $EA
db $F6, $D6, $F1, $CD, $F6, $2C, $FE, $9F, $28, $38, $FE, $74, $28, $34, $CD, $07
db $4C, $FA, $09, $D7, $CB, $57, $20, $2A, $CD, $69, $75, $CD, $2D, $75, $28, $13
db $3E, $06, $EA, $FB, $D6, $C1, $F5, $78, $EA, $F5, $D6, $79, $EA, $F6, $D6, $F1
db $C3, $94, $5E, $F5, $FA, $EE, $D6, $67, $FA, $EF, $D6, $6F, $F1, $CD, $E2, $75
db $18, $0A, $CD, $15, $76, $FA, $FB, $D6, $FE, $00, $20, $67, $C1, $F5, $78, $EA
db $F5, $D6, $79, $EA, $F6, $D6, $F1, $FA, $FB, $D6, $FE, $00, $20, $55, $FA, $15
db $D7, $CB, $77, $28, $3D, $CD, $98, $5F, $CD, $88, $5F, $38, $46, $F1, $CD, $69
db $5F, $EA, $3F, $D4, $01, $E0, $D6, $CD, $88, $5F, $38, $37, $F1, $02, $0C, $79
db $FE, $EA, $20, $F3, $CD, $B8, $5F, $CD, $2D, $5F, $CD, $B7, $34, $FA, $3F, $D4
db $CD, $0B, $60, $F5, $CD, $D8, $5F, $F1, $20, $08, $3E, $0A, $EA, $FB, $D6, $C3
db $94, $5E, $01, $E9, $D6, $0A, $F5, $CD, $91, $5F, $0D, $79, $FE, $DF, $20, $F5
db $C3, $42, $5C, $01, $E0, $D6, $CD, $88, $5F, $DA, $21, $5F, $F1, $FE, $CA, $28
db $0A, $FE, $CB, $28, $06, $F5, $CD, $91, $5F, $18, $11, $F5, $01, $0A, $00, $21
db $E0, $D6, $AF, $CD, $81, $52, $CD, $98, $5F, $F1, $18, $27, $CD, $88, $5F, $38
db $5F, $F1, $02, $0C, $79, $FE, $EA, $20, $F3, $CD, $98, $5F, $FA, $F4, $D6, $FE
db $00, $C8, $CD, $88, $5F, $F1, $FE, $CA, $28, $09, $FE, $CB, $28, $05, $3E, $0F
db $EA, $FB, $D6, $CD, $69, $5F, $EA, $3F, $D4, $01, $E0, $D6, $CD, $88, $5F, $38
db $2F, $F1, $02, $0C, $79, $FE, $EA, $20, $F3, $CD, $B8, $5F, $CD, $B7, $34, $FA
db $3F, $D4, $CD, $0B, $60, $20, $06, $3E, $0A, $EA, $FB, $D6, $C9, $CD, $D8, $5F
db $21, $E9, $D6, $3A, $F5, $CD, $91, $5F, $7D, $FE, $DF, $20, $F6, $C3, $94, $5E
db $FA, $FB, $D6, $FE, $00, $C0, $3E, $0C, $EA, $FB, $D6, $C9, $F5, $E5, $F5, $FA
db $EC, $D6, $67, $FA, $ED, $D6, $6F, $F1, $E5, $2B, $F5, $7C, $EA, $EC, $D6, $7D
db $EA, $ED, $D6, $F1, $CD, $30, $74, $CD, $F6, $2C, $FE, $CD, $28, $04, $FE, $69
db $20, $08, $FA, $3F, $D4, $EE, $01, $EA, $3F, $D4, $E1, $F5, $7C, $EA, $EC, $D6
db $7D, $EA, $ED, $D6, $F1, $E1, $F1, $C9, $F5, $E5, $21, $18, $D4, $AF, $22, $7D
db $FE, $3F, $20, $F9, $E1, $F1, $FE, $6F, $20, $03, $3E, $02, $C9, $FE, $69, $20
db $03, $3E, $03, $C9, $D6, $CA, $C9, $FA, $F4, $D6, $D6, $01, $EA, $F4, $D6, $C9
db $E5, $21, $F4, $D6, $34, $E1, $C9, $E5, $AF, $EA, $01, $D4, $EA, $0A, $D4, $21
db $E9, $D6, $3A, $EA, $0B, $D4, $3A, $EA, $00, $D4, $01, $09, $D4, $16, $08, $3A
db $02, $0D, $15, $20, $FA, $E1, $C9, $E5, $AF, $EA, $0D, $D4, $EA, $16, $D4, $21
db $E9, $D6, $3A, $EA, $17, $D4, $3A, $EA, $0C, $D4, $01, $15, $D4, $16, $08, $3A
db $02, $0D, $15, $20, $FA, $E1, $C9, $E5, $21, $E9, $D6, $FA, $23, $D4, $32, $FA
db $18, $D4, $32, $16, $08, $01, $21, $D4, $0A, $32, $0D, $15, $20, $FA, $E1, $C9
db $E5, $C5, $21, $18, $D4, $01, $0C, $D4, $2A, $02, $0C, $7D, $FE, $24, $20, $F8
db $AF, $EA, $0C, $D4, $EA, $15, $D4, $C1, $E1, $C9, $FE, $00, $CA, $43, $60, $3D
db $CA, $50, $60, $3D, $CA, $76, $60, $21, $02, $D4, $0E, $08, $CD, $B4, $60, $20
db $08, $CD, $BD, $60, $3E, $01, $CB, $47, $C9, $21, $0E, $D4, $0E, $08, $CD, $B4
db $60, $C8, $CD, $AF, $32, $F5, $FA, $18, $D4, $E6, $F0, $FE, $F0, $CC, $BD, $60
db $F1, $C9, $CD, $90, $31, $C8, $CD, $EE, $30, $CD, $A8, $31, $C3, $C8, $60, $CD
db $D7, $31, $CD, $EE, $30, $C3, $C8, $60, $FA, $0C, $D4, $CB, $5F, $28, $35, $E6
db $0F, $EE, $0F, $47, $FA, $00, $D4, $E6, $0F, $EE, $0F, $80, $FE, $07, $38, $24
db $3E, $01, $CB, $47, $C9, $AF, $EA, $2E, $D7, $FA, $00, $D4, $CB, $5F, $20, $D8
db $FA, $0C, $D4, $CB, $5F, $20, $0D, $4F, $FA, $00, $D4, $81, $EA, $2E, $D7, $EE
db $08, $CB, $5F, $C8, $CD, $21, $32, $F5, $FA, $2E, $D7, $4F, $A7, $28, $11, $FA
db $18, $D4, $CB, $5F, $20, $03, $91, $30, $07, $F1, $3E, $00, $CB, $47, $18, $17
db $F1, $18, $14, $2A, $FE, $00, $C0, $0D, $C2, $B4, $60, $C9, $AF, $0E, $0C, $21
db $18, $D4, $22, $0D, $20, $FC, $C9, $F5, $21, $1A, $D4, $0E, $08, $CD, $B4, $60
db $20, $05, $CD, $BD, $60, $F1, $C9, $16, $08, $FA, $18, $D4, $A7, $20, $20, $16
db $00, $1E, $08, $21, $21, $D4, $3A, $A7, $20, $0D, $06, $08, $AF, $21, $1A, $D4
db $CD, $2B, $61, $15, $1D, $20, $EC, $7A, $E6, $0F, $EA, $18, $D4, $16, $08, $FA
db $21, $D4, $FE, $00, $20, $22, $FA, $18, $D4, $CB, $5F, $20, $1B, $E6, $07, $28
db $04, $3D, $EA, $18, $D4, $06, $08, $AF, $21, $1A, $D4, $CD, $2B, $61, $15, $20
db $DE, $AF, $EA, $18, $D4, $EA, $23, $D4, $F1, $C9, $4E, $22, $79, $05, $20, $FA
db $C9, $E5, $C5, $21, $E0, $D6, $01, $0E, $00, $AF, $CD, $81, $52, $C1, $E5, $C9
db $01, $E9, $D6, $F5, $FA, $EE, $D6, $67, $FA, $EF, $D6, $6F, $F1, $1E, $05, $0A
db $0B, $E6, $0F, $CB, $37, $57, $0A, $0B, $E6, $0F, $B2, $22, $1D, $20, $F0, $C9
db $1E, $02, $CD, $FE, $73, $FA, $C0, $D6, $EA, $C3, $D6, $F5, $FA, $F5, $D6, $67
db $FA, $F6, $D6, $6F, $F1, $E5, $CD, $53, $74, $F5, $FA, $F5, $D6, $67, $FA, $F6
db $D6, $6F, $F1, $CD, $F6, $2C, $FE, $2E, $20, $07, $3E, $10, $EA, $FB, $D6, $E1
db $C9, $CD, $85, $74, $FA, $C0, $D6, $FE, $07, $28, $26, $FE, $08, $28, $22, $F5
db $FA, $F5, $D6, $67, $FA, $F6, $D6, $6F, $F1, $CD, $F6, $2C, $23, $FE, $2E, $28
db $D9, $FE, $BE, $20, $F4, $F5, $7C, $EA, $F5, $D6, $7D, $EA, $F6, $D6, $F1, $18
db $B5, $F5, $FA, $F5, $D6, $67, $FA, $F6, $D6, $6F, $F1, $C1, $F5, $78, $EA, $F5
db $D6, $79, $EA, $F6, $D6, $F1, $E5, $CD, $B3, $59, $F5, $FA, $F7, $D6, $67, $FA
db $F8, $D6, $6F, $F1, $F5, $7C, $EA, $EC, $D6, $7D, $EA, $ED, $D6, $F1, $CD, $22
db $5C, $CD, $BA, $73, $21, $E9, $D6, $01, $D9, $D6, $16, $0A, $3A, $02, $0D, $15
db $20, $FA, $F5, $FA, $F7, $D6, $67, $FA, $F8, $D6, $6F, $F1, $23, $CD, $7B, $62
db $28, $01, $23, $F5, $7C, $EA, $F5, $D6, $7D, $EA, $F6, $D6, $F1, $CD, $58, $5A
db $F5, $FA, $F7, $D6, $67, $FA, $F8, $D6, $6F, $F1, $F5, $7C, $EA, $EC, $D6, $7D
db $EA, $ED, $D6, $F1, $CD, $22, $5C, $CD, $BA, $73, $CD, $00, $5B, $FA, $C1, $D6
db $CB, $47, $28, $02, $E1, $C9, $E1, $F5, $7C, $EA, $F5, $D6, $7D, $EA, $F6, $D6
db $F1, $CD, $53, $74, $FA, $C0, $D6, $FE, $07, $C2, $A2, $65, $F5, $FA, $F5, $D6
db $67, $FA, $F6, $D6, $6F, $F1, $CD, $F6, $2C, $CD, $07, $4C, $FA, $09, $D7, $CB
db $57, $C2, $A2, $65, $21, $C1, $D6, $CB, $DE, $C9, $FA, $C2, $D6, $FE, $01, $C8
db $FE, $02, $C8, $FE, $04, $C9, $1E, $01, $CD, $C3, $73, $21, $C4, $D6, $CB, $C6
db $CD, $53, $74, $F5, $FA, $F5, $D6, $67, $FA, $F6, $D6, $6F, $F1, $CD, $F6, $2C
db $FE, $2E, $20, $04, $CD, $F3, $64, $C9, $CD, $53, $74, $F5, $FA, $F5, $D6, $67
db $FA, $F6, $D6, $6F, $F1, $CD, $F6, $2C, $5F, $23, $F5, $7C, $EA, $F5, $D6, $7D
db $EA, $F6, $D6, $F1, $7B, $FE, $64, $20, $2D, $CD, $83, $63, $CD, $AF, $73, $F5
db $FA, $F5, $D6, $67, $FA, $F6, $D6, $6F, $F1, $CD, $53, $74, $CD, $F6, $2C, $FE
db $75, $CA, $75, $63, $FE, $9E, $CA, $75, $63, $FE, $2E, $CA, $75, $63, $3E, $0F
db $EA, $FB, $D6, $CD, $AF, $73, $FE, $75, $28, $2C, $FE, $9E, $20, $30, $F5, $FA
db $1E, $D7, $47, $FA, $1F, $D7, $4F, $F1, $79, $E6, $0F, $28, $19, $FE, $08, $28
db $15, $79, $E6, $F8, $C6, $08, $4F, $F5, $78, $EA, $1E, $D7, $79, $EA, $1F, $D7
db $F1, $CB, $61, $C4, $F3, $64, $21, $C4, $D6, $CB, $86, $C3, $A9, $62, $FE, $2E
db $20, $19, $FA, $C4, $D6, $CB, $47, $C8, $FA, $1F, $D7, $FE, $40, $C8, $FE, $80
db $C8, $FE, $C0, $C8, $FE, $00, $C8, $CD, $F3, $64, $C9, $F5, $FA, $F5, $D6, $67
db $FA, $F6, $D6, $6F, $F1, $2B, $F5, $7C, $EA, $F5, $D6, $7D, $EA, $F6, $D6, $F1
db $CD, $69, $75, $CD, $2D, $75, $28, $06, $3E, $06, $EA, $FB, $D6, $C9, $CD, $F0
db $63, $CD, $E3, $47, $FA, $C4, $D6, $CB, $C7, $EA, $C4, $D6, $CD, $53, $74, $C3
db $A9, $62, $F5, $FA, $1E, $D7, $47, $FA, $1F, $D7, $4F, $F1, $CB, $61, $C4, $F3
db $64, $F5, $FA, $F5, $D6, $67, $FA, $F6, $D6, $6F, $F1, $CD, $F6, $2C, $23, $FE
db $2E, $20, $06, $3E, $05, $EA, $FB, $D6, $C9, $FE, $64, $20, $27, $F5, $7C, $EA
db $F5, $D6, $7D, $EA, $F6, $D6, $F1, $CD, $E3, $47, $F5, $FA, $1E, $D7, $47, $FA
db $1F, $D7, $4F, $F1, $CB, $61, $C4, $F3, $64, $F5, $FA, $F5, $D6, $67, $FA, $F6
db $D6, $6F, $F1, $C9, $CD, $B5, $3D, $02, $0C, $F5, $7C, $EA, $F5, $D6, $7D, $EA
db $F6, $D6, $F1, $F5, $78, $EA, $1E, $D7, $79, $EA, $1F, $D7, $F1, $18, $93, $FA
db $EA, $D6, $EA, $3F, $D7, $AF, $EA, $3E, $D7, $CD, $E2, $75, $CD, $69, $64, $F5
db $FA, $1E, $D7, $67, $FA, $1F, $D7, $6F, $F1, $01, $E9, $D6, $FA, $E8, $D6, $FE
db $9F, $20, $13, $FA, $E9, $D6, $EA, $EA, $D6, $3E, $C0, $EA, $E9, $D6, $01, $EA
db $D6, $3E, $01, $EA, $3E, $D7, $0A, $FE, $BE, $20, $0F, $FA, $3E, $D7, $CB, $47
db $3E, $EA, $20, $02, $3E, $E9, $B9, $0A, $20, $27, $22, $F5, $7C, $EA, $1E, $D7
db $7D, $EA, $1F, $D7, $F1, $7D, $E6, $1F, $FE, $10, $20, $0F, $C5, $CD, $F3, $64
db $C1, $F5, $FA, $1E, $D7, $67, $FA, $1F, $D7, $6F, $F1, $0D, $79, $FE, $DF, $20
db $C5, $FA, $3F, $D7, $EA, $EA, $D6, $C9, $01, $E9, $D6, $0A, $FE, $00, $3E, $BE
db $28, $02, $3E, $CB, $EA, $E9, $D6, $FA, $E8, $D6, $5F, $CB, $9B, $CB, $5F, $28
db $3D, $3E, $9F, $EA, $E8, $D6, $21, $E8, $D6, $CD, $E3, $64, $7D, $B9, $28, $0C
db $21, $E8, $D6, $2D, $7E, $C6, $C0, $77, $7D, $B9, $20, $F7, $7B, $EE, $07, $5F
db $FE, $00, $C8, $3E, $C0, $21, $E7, $D6, $4E, $32, $79, $FE, $BE, $28, $06, $7D
db $FE, $DF, $79, $20, $F3, $3E, $C0, $21, $E7, $D6, $1D, $20, $EB, $C9, $3E, $9F
db $EA, $E8, $D6, $1C, $21, $E8, $D6, $3A, $4E, $22, $79, $C6, $C0, $32, $1D, $20
db $F6, $7D, $FE, $DF, $C8, $CD, $E3, $64, $7D, $B9, $C8, $2D, $7E, $C6, $C0, $77
db $18, $F6, $01, $DF, $D6, $0C, $0A, $FE, $00, $C0, $3E, $BE, $02, $79, $BD, $20
db $F4, $C9, $F5, $FA, $1E, $D7, $67, $FA, $1F, $D7, $6F, $F1, $CD, $31, $3D, $7D
db $FE, $40, $20, $05, $7C, $FE, $DF, $28, $14, $7D, $C6, $40, $6F, $7C, $CE, $00
db $67, $F5, $7C, $EA, $1E, $D7, $7D, $EA, $1F, $D7, $F1, $18, $27, $F5, $7C, $EA
db $1E, $D7, $7D, $EA, $1F, $D7, $F1, $01, $40, $DC, $21, $00, $DC, $0A, $22, $03
db $FA, $1F, $D7, $BD, $20, $F7, $FA, $1E, $D7, $BC, $20, $F1, $3E, $BE, $0E, $10
db $22, $0D, $20, $FC, $CD, $E3, $47, $F5, $FA, $1E, $D7, $47, $FA, $1F, $D7, $4F
db $F1, $C9, $1E, $03, $CD, $FE, $73, $3E, $FF, $EA, $FB, $D6, $C9, $1E, $05, $CD
db $FE, $73, $C9, $1E, $04, $CD, $FE, $73, $FA, $C1, $D6, $CB, $77, $20, $26, $CD
db $77, $65, $CD, $E3, $47, $C9, $CD, $FF, $47, $21, $00, $DC, $F5, $7C, $EA, $1E
db $D7, $7D, $EA, $1F, $D7, $F1, $F5, $7C, $EA, $0C, $D7, $7D, $EA, $0D, $D7, $F1
db $AF, $EA, $18, $D7, $C9, $C3, $0B, $6A, $1E, $08, $CD, $FE, $73, $AF, $EA, $C3
db $D6, $CD, $53, $74, $CD, $6C, $58, $CD, $AF, $73, $F5, $78, $EA, $38, $D7, $79
db $EA, $39, $D7, $F1, $3E, $01, $EA, $3A, $D7, $F5, $FA, $FE, $D6, $67, $FA, $FF
db $D6, $6F, $F1, $F5, $7C, $EA, $3C, $D7, $7D, $EA, $3D, $D7, $F1, $0B, $F5, $78
db $EA, $FE, $D6, $79, $EA, $FF, $D6, $F1, $C9, $1E, $09, $CD, $C3, $73, $CD, $53
db $74, $CD, $F6, $2C, $FE, $64, $20, $28, $F5, $FA, $F5, $D6, $67, $FA, $F6, $D6
db $6F, $F1, $23, $F5, $7C, $EA, $F5, $D6, $7D, $EA, $F6, $D6, $F1, $CD, $83, $63
db $CD, $53, $74, $CD, $F6, $2C, $FE, $75, $28, $06, $3E, $11, $EA, $FB, $D6, $C9
db $CD, $AF, $73, $F5, $FA, $1E, $D7, $67, $FA, $1F, $D7, $6F, $F1, $3E, $BF, $77
db $CD, $51, $52, $F5, $FA, $1E, $D7, $67, $FA, $1F, $D7, $6F, $F1, $23, $F5, $7C
db $EA, $1E, $D7, $7D, $EA, $1F, $D7, $F1, $CD, $51, $52, $F5, $FA, $1E, $D7, $67
db $FA, $1F, $D7, $6F, $F1, $23, $F5, $7C, $EA, $1E, $D7, $7D, $EA, $1F, $D7, $F1
db $CB, $65, $28, $14, $7D, $E6, $E0, $C6, $40, $6F, $7C, $CE, $00, $67, $F5, $7C
db $EA, $1E, $D7, $7D, $EA, $1F, $D7, $F1, $21, $E0, $D6, $F5, $7C, $EA, $C5, $D6
db $7D, $EA, $C6, $D6, $F1, $CD, $F6, $66, $CD, $AF, $73, $CD, $40, $36, $CD, $52
db $36, $FA, $E8, $D6, $3D, $EA, $E8, $D6, $16, $08, $21, $E7, $D6, $3A, $FE, $00
db $20, $07, $15, $20, $F8, $AF, $EA, $E8, $D6, $F5, $FA, $F5, $D6, $67, $FA, $F6
db $D6, $6F, $F1, $CD, $F6, $2C, $FE, $75, $20, $01, $23, $F5, $7C, $EA, $F5, $D6
db $7D, $EA, $F6, $D6, $F1, $CD, $69, $75, $CD, $2D, $75, $28, $0C, $CD, $F5, $74
db $28, $07, $3E, $1A, $EA, $FB, $D6, $18, $1C, $CD, $41, $61, $CD, $53, $74, $F5
db $FA, $F5, $D6, $67, $FA, $F6, $D6, $6F, $F1, $CD, $F6, $2C, $FE, $2E, $28, $05
db $3E, $0B, $EA, $FB, $D6, $CD, $40, $36, $CD, $52, $36, $CD, $F3, $64, $C9, $3E
db $03, $EA, $FB, $D6, $C9, $AF, $EA, $37, $D7, $CD, $49, $36, $21, $E9, $D6, $AF
db $32, $7D, $FE, $DF, $20, $F9, $21, $E7, $D6, $F5, $7C, $EA, $C5, $D6, $7D, $EA
db $C6, $D6, $F1, $21, $C4, $D6, $CB, $96, $CB, $CE, $CD, $10, $4D, $FA, $25, $D0
db $FE, $2A, $28, $CB, $FE, $CB, $20, $07, $3E, $0F, $EA, $E9, $D6, $18, $6D, $FE
db $CA, $28, $69, $18, $0A, $CD, $10, $4D, $FA, $25, $D0, $FE, $2A, $28, $B0, $FE
db $2E, $C8, $FA, $E8, $D6, $FE, $F9, $28, $EC, $F5, $FA, $C5, $D6, $67, $FA, $C6
db $D6, $6F, $F1, $7D, $FE, $DF, $28, $DD, $FA, $25, $D0, $FE, $C0, $20, $76, $21
db $C4, $D6, $CB, $4E, $28, $11, $CB, $56, $28, $32, $FA, $E8, $D6, $FE, $F9, $28
db $C4, $3D, $EA, $E8, $D6, $18, $25, $CB, $56, $20, $07, $FA, $E8, $D6, $3C, $EA
db $E8, $D6, $F5, $FA, $C5, $D6, $67, $FA, $C6, $D6, $6F, $F1, $FA, $25, $D0, $D6
db $C0, $32, $F5, $7C, $EA, $C5, $D6, $7D, $EA, $C6, $D6, $F1, $F5, $FA, $1E, $D7
db $67, $FA, $1F, $D7, $6F, $F1, $E5, $FA, $25, $D0, $CD, $B5, $3D, $77, $CD, $51
db $52, $E1, $23, $7D, $E6, $1F, $FE, $10, $20, $0E, $CD, $40, $36, $CD, $52, $36
db $CD, $F3, $64, $C5, $E1, $CD, $49, $36, $F5, $7C, $EA, $1E, $D7, $7D, $EA, $1F
db $D7, $F1, $C3, $36, $67, $FE, $74, $28, $04, $FE, $9F, $20, $0C, $21, $C4, $D6
db $CB, $56, $C2, $36, $67, $CB, $D6, $18, $B3, $CD, $07, $4C, $FA, $09, $D7, $CB
db $57, $CA, $36, $67, $21, $C4, $D6, $CB, $8E, $C3, $78, $67, $1E, $0A, $CD, $FE
db $73, $FA, $C0, $D6, $EA, $C3, $D6, $F5, $FA, $F5, $D6, $67, $FA, $F6, $D6, $6F
db $F1, $E5, $CD, $53, $74, $F5, $FA, $F5, $D6, $67, $FA, $F6, $D6, $6F, $F1, $CD
db $F6, $2C, $FE, $2E, $20, $07, $3E, $10, $EA, $FB, $D6, $E1, $C9, $CD, $85, $74
db $FA, $C0, $D6, $FE, $08, $28, $22, $F5, $FA, $F5, $D6, $67, $FA, $F6, $D6, $6F
db $F1, $CD, $F6, $2C, $23, $FE, $2E, $28, $DD, $FE, $BE, $20, $F4, $F5, $7C, $EA
db $F5, $D6, $7D, $EA, $F6, $D6, $F1, $18, $B9, $F5, $FA, $F5, $D6, $67, $FA, $F6
db $D6, $6F, $F1, $C1, $F5, $78, $EA, $F5, $D6, $79, $EA, $F6, $D6, $F1, $E5, $CD
db $58, $5A, $F5, $FA, $F7, $D6, $67, $FA, $F8, $D6, $6F, $F1, $F5, $7C, $EA, $EC
db $D6, $7D, $EA, $ED, $D6, $F1, $CD, $22, $5C, $CD, $BA, $73, $CD, $E3, $68, $FA
db $E8, $D6, $FE, $00, $28, $02, $E1, $C9, $FA, $E9, $D6, $E6, $0F, $EA, $E9, $D6
db $FE, $00, $28, $02, $E1, $C9, $E1, $F5, $7C, $EA, $F5, $D6, $7D, $EA, $F6, $D6
db $F1, $FA, $E7, $D6, $FE, $00, $C8, $3D, $EA, $E7, $D6, $FA, $E7, $D6, $FE, $00
db $20, $0D, $F5, $7C, $EA, $F5, $D6, $7D, $EA, $F6, $D6, $F1, $C3, $A2, $65, $3D
db $EA, $E7, $D6, $CD, $F6, $2C, $23, $FE, $2E, $28, $06, $FE, $9E, $20, $F4, $18
db $DA, $C9, $21, $E7, $D6, $FA, $E8, $D6, $CB, $5F, $28, $0B, $16, $0A, $21, $E9
db $D6, $AF, $32, $15, $20, $FB, $C9, $FE, $00, $28, $04, $2B, $3D, $18, $F8, $2B
db $7D, $FE, $DF, $C8, $AF, $77, $18, $F7, $1E, $0B, $CD, $FE, $73, $F5, $FA, $F5
db $D6, $67, $FA, $F6, $D6, $6F, $F1, $CD, $F6, $2C, $FE, $6A, $28, $06, $3E, $14
db $EA, $FB, $D6, $C9, $CD, $A3, $57, $FA, $FB, $D6, $FE, $00, $C0, $F5, $7C, $EA
db $F5, $D6, $7D, $EA, $F6, $D6, $F1, $CD, $EC, $71, $F5, $FA, $E7, $D6, $67, $FA
db $E8, $D6, $6F, $F1, $CD, $F6, $2C, $FE, $6B, $20, $06, $3E, $17, $EA, $FB, $D6
db $C9, $CD, $22, $5C, $CD, $AF, $73, $CD, $E3, $68, $CD, $90, $71, $CD, $AF, $73
db $FA, $E7, $D6, $FE, $55, $38, $06, $3E, $15, $EA, $FB, $D6, $C9, $EA, $CC, $D6
db $F5, $FA, $F7, $D6, $67, $FA, $F8, $D6, $6F, $F1, $F5, $7C, $EA, $F5, $D6, $7D
db $EA, $F6, $D6, $F1, $CD, $EC, $71, $CD, $22, $5C, $CD, $AF, $73, $CD, $E3, $68
db $CD, $90, $71, $CD, $AF, $73, $FA, $E7, $D6, $A7, $28, $1B, $EA, $CD, $D6, $3E
db $FF, $EA, $CE, $D6, $AF, $EA, $CF, $D6, $21, $CC, $D6, $CD, $BB, $01, $CD, $A2
db $01, $FA, $00, $CC, $A7, $20, $F7, $F5, $FA, $F7, $D6, $67, $FA, $F8, $D6, $6F
db $F1, $CD, $F6, $2C, $FE, $9E, $CA, $25, $69, $FE, $6B, $20, $24, $23, $F5, $7C
db $EA, $F5, $D6, $7D, $EA, $F6, $D6, $F1, $CD, $53, $74, $F5, $FA, $F5, $D6, $67
db $FA, $F6, $D6, $6F, $F1, $CD, $F6, $2C, $FE, $2E, $C8, $3E, $16, $EA, $FB, $D6
db $C9, $3E, $0C, $EA, $FB, $D6, $C9, $1E, $0E, $CD, $FE, $73, $CD, $40, $36, $CD
db $52, $36, $FA, $C1, $D6, $CB, $F7, $EA, $C1, $D6, $CD, $F0, $0A, $CD, $10, $0B
db $21, $00, $90, $01, $00, $08, $AF, $22, $0B, $78, $B1, $20, $F9, $21, $00, $88
db $01, $60, $04, $AF, $22, $0B, $78, $B1, $20, $F9, $21, $50, $8C, $01, $30, $01
db $11, $39, $18, $1A, $22, $13, $0B, $78, $B1, $20, $F8, $F0, $10, $F6, $80, $E6
db $FD, $E0, $10, $CD, $F0, $0A, $CD, $10, $0B, $3E, $FF, $11, $B9, $18, $CD, $88
db $0A, $F0, $10, $F6, $A1, $E0, $10, $C9, $1E, $0F, $CD, $FE, $73, $F3, $CD, $40
db $36, $CD, $31, $52, $CD, $F0, $0A, $CD, $10, $0B, $21, $00, $90, $11, $09, $14
db $01, $00, $08, $CD, $00, $C9, $CD, $F0, $0A, $CD, $10, $0B, $21, $00, $88, $11
db $21, $1F, $01, $00, $08, $CD, $00, $C9, $11, $21, $1A, $CD, $CA, $57, $F0, $10
db $E6, $CF, $F6, $C1, $E0, $10, $FA, $C1, $D6, $CB, $B7, $EA, $C1, $D6, $FB, $C9
db $AF, $EA, $DB, $D6, $1E, $0D, $CD, $DD, $73, $F5, $FA, $F5, $D6, $67, $FA, $F6
db $D6, $6F, $F1, $CD, $F6, $2C, $FE, $6A, $28, $06, $3E, $14, $EA, $FB, $D6, $C9
db $CD, $6F, $71, $EA, $CC, $D6, $CD, $AF, $73, $F5, $FA, $F7, $D6, $67, $FA, $F8
db $D6, $6F, $F1, $F5, $7C, $EA, $F5, $D6, $7D, $EA, $F6, $D6, $F1, $CD, $6F, $71
db $EA, $CD, $D6, $CD, $AF, $73, $CD, $A3, $57, $FA, $FB, $D6, $FE, $00, $C0, $F5
db $FA, $F7, $D6, $67, $FA, $F8, $D6, $6F, $F1, $F5, $7C, $EA, $F5, $D6, $7D, $EA
db $F6, $D6, $F1, $CD, $6F, $71, $EA, $CE, $D6, $CD, $AF, $73, $F5, $FA, $F7, $D6
db $67, $FA, $F8, $D6, $6F, $F1, $F5, $7C, $EA, $F5, $D6, $7D, $EA, $F6, $D6, $F1
db $CD, $6F, $71, $EA, $CF, $D6, $CD, $AF, $73, $FA, $CC, $D6, $4F, $FA, $CE, $D6
db $91, $21, $C1, $D6, $CB, $8E, $30, $0A, $CB, $CE, $FA, $CE, $D6, $4F, $FA, $CC
db $D6, $91, $EA, $C7, $D6, $FA, $CD, $D6, $4F, $FA, $CF, $D6, $91, $21, $C1, $D6
db $CB, $96, $30, $0A, $CB, $D6, $FA, $CF, $D6, $4F, $FA, $CD, $D6, $91, $EA, $C8
db $D6, $FA, $CC, $D6, $EA, $C5, $D6, $FA, $CD, $D6, $EA, $C6, $D6, $AF, $EA, $DA
db $D6, $FA, $C8, $D6, $4F, $FA, $C7, $D6, $B9, $38, $05, $CD, $BF, $6B, $18, $03
db $CD, $3D, $6C, $F5, $FA, $F7, $D6, $67, $FA, $F8, $D6, $6F, $F1, $CD, $F6, $2C
db $FE, $6B, $28, $06, $3E, $18, $EA, $FB, $D6, $C9, $23, $F5, $7C, $EA, $F5, $D6
db $7D, $EA, $F6, $D6, $F1, $CD, $53, $74, $F5, $FA, $F5, $D6, $67, $FA, $F6, $D6
db $6F, $F1, $CD, $F6, $2C, $FE, $2E, $C8, $3E, $16, $EA, $FB, $D6, $C9, $FA, $C7
db $D6, $CB, $3F, $EA, $C9, $D6, $FA, $C7, $D6, $3C, $EA, $CB, $D6, $CD, $D3, $70
db $FA, $C5, $D6, $3C, $21, $C1, $D6, $CB, $4E, $28, $02, $3D, $3D, $EA, $C5, $D6
db $FA, $C8, $D6, $4F, $FA, $DA, $D6, $81, $EA, $DA, $D6, $FA, $DB, $D6, $CE, $00
db $EA, $DB, $D6, $FA, $DB, $D6, $FE, $01, $28, $10, $FA, $DA, $D6, $4F, $FA, $C9
db $D6, $B9, $30, $29, $FA, $DB, $D6, $A7, $20, $23, $FA, $C7, $D6, $4F, $FA, $DA
db $D6, $91, $EA, $DA, $D6, $FA, $DB, $D6, $DE, $00, $EA, $DB, $D6, $FA, $C6, $D6
db $3C, $21, $C1, $D6, $CB, $56, $28, $02, $3D, $3D, $EA, $C6, $D6, $FA, $CB, $D6
db $3D, $EA, $CB, $D6, $20, $97, $21, $00, $00, $C3, $00, $71, $FA, $C8, $D6, $CB
db $3F, $EA, $CA, $D6, $FA, $C8, $D6, $3C, $EA, $CB, $D6, $CD, $D3, $70, $FA, $C6
db $D6, $3C, $21, $C1, $D6, $CB, $56, $28, $02, $3D, $3D, $EA, $C6, $D6, $FA, $C7
db $D6, $4F, $FA, $DA, $D6, $81, $EA, $DA, $D6, $FA, $DB, $D6, $CE, $00, $EA, $DB
db $D6, $FA, $DB, $D6, $FE, $01, $28, $10, $FA, $DA, $D6, $4F, $FA, $CA, $D6, $B9
db $30, $29, $FA, $DB, $D6, $A7, $20, $23, $FA, $C8, $D6, $4F, $FA, $DA, $D6, $91
db $EA, $DA, $D6, $FA, $DB, $D6, $DE, $00, $EA, $DB, $D6, $FA, $C5, $D6, $3C, $21
db $C1, $D6, $CB, $4E, $28, $02, $3D, $3D, $EA, $C5, $D6, $FA, $CB, $D6, $3D, $EA
db $CB, $D6, $20, $97, $21, $00, $00, $C3, $00, $71, $1E, $10, $CD, $DD, $73, $F5
db $FA, $F5, $D6, $67, $FA, $F6, $D6, $6F, $F1, $CD, $F6, $2C, $FE, $6A, $28, $06
db $3E, $14, $EA, $FB, $D6, $C9, $CD, $6F, $71, $EA, $CC, $D6, $CD, $AF, $73, $F5
db $FA, $F7, $D6, $67, $FA, $F8, $D6, $6F, $F1, $F5, $7C, $EA, $F5, $D6, $7D, $EA
db $F6, $D6, $F1, $CD, $6F, $71, $EA, $CD, $D6, $CD, $AF, $73, $F5, $FA, $F7, $D6
db $67, $FA, $F8, $D6, $6F, $F1, $F5, $7C, $EA, $F5, $D6, $7D, $EA, $F6, $D6, $F1
db $CD, $6F, $71, $EA, $CE, $D6, $FE, $00, $20, $12, $FA, $CC, $D6, $EA, $C5, $D6
db $FA, $CD, $D6, $EA, $C6, $D6, $CD, $D3, $70, $C3, $00, $71, $FE, $65, $38, $06
db $3E, $15, $EA, $FB, $D6, $C9, $CD, $AF, $73, $F5, $FA, $F7, $D6, $67, $FA, $F8
db $D6, $6F, $F1, $CD, $F6, $2C, $FE, $6B, $28, $06, $3E, $18, $EA, $FB, $D6, $C9
db $23, $F5, $7C, $EA, $F5, $D6, $7D, $EA, $F6, $D6, $F1, $CD, $53, $74, $F5, $FA
db $F5, $D6, $67, $FA, $F6, $D6, $6F, $F1, $CD, $F6, $2C, $FE, $2E, $28, $06, $3E
db $16, $EA, $FB, $D6, $C9, $3E, $01, $EA, $DB, $D6, $AF, $EA, $C5, $D6, $EA, $CF
db $D6, $EA, $DA, $D6, $FA, $CE, $D6, $EA, $C6, $D6, $CB, $27, $EA, $CF, $D6, $FA
db $DA, $D6, $CB, $17, $EA, $DA, $D6, $FA, $CF, $D6, $4F, $3E, $03, $91, $EA, $CF
db $D6, $FA, $DA, $D6, $DE, $00, $EA, $DA, $D6, $FA, $C5, $D6, $4F, $FA, $C6, $D6
db $B9, $DA, $9E, $6E, $F5, $FA, $C5, $D6, $67, $FA, $C6, $D6, $6F, $F1, $E5, $FA
db $DB, $D6, $FE, $01, $28, $57, $CD, $AD, $6E, $FA, $DB, $D6, $FE, $02, $28, $4D
db $CD, $AD, $6E, $CD, $B6, $6E, $CD, $AD, $6E, $FA, $DB, $D6, $FE, $03, $28, $3D
db $CD, $B6, $6E, $CD, $AD, $6E, $CD, $B6, $6E, $FA, $DB, $D6, $FE, $04, $28, $2D
db $CD, $B6, $6E, $FA, $DB, $D6, $FE, $05, $28, $23, $CD, $AD, $6E, $FA, $DB, $D6
db $FE, $06, $28, $19, $CD, $AD, $6E, $CD, $B6, $6E, $CD, $AD, $6E, $FA, $DB, $D6
db $FE, $07, $28, $09, $CD, $B6, $6E, $CD, $AD, $6E, $CD, $B6, $6E, $CD, $BD, $6E
db $E1, $F5, $7C, $EA, $C5, $D6, $7D, $EA, $C6, $D6, $F1, $FA, $DA, $D6, $CB, $7F
db $20, $02, $18, $27, $21, $00, $00, $FA, $C5, $D6, $6F, $CB, $25, $CB, $14, $CB
db $25, $CB, $12, $3E, $06, $85, $6F, $7C, $CE, $00, $67, $FA, $CF, $D6, $85, $EA
db $CF, $D6, $FA, $DA, $D6, $8C, $EA, $DA, $D6, $18, $38, $FA, $C5, $D6, $4F, $FA
db $C6, $D6, $91, $26, $00, $6F, $CB, $25, $CB, $14, $CB, $25, $CB, $14, $FA, $CF
db $D6, $C6, $0A, $EA, $CF, $D6, $FA, $DA, $D6, $CE, $00, $EA, $DA, $D6, $FA, $CF
db $D6, $95, $EA, $CF, $D6, $FA, $DA, $D6, $9C, $EA, $DA, $D6, $FA, $C6, $D6, $3D
db $EA, $C6, $D6, $FA, $C5, $D6, $3C, $EA, $C5, $D6, $C3, $AA, $6D, $FA, $DB, $D6
db $3C, $EA, $DB, $D6, $FE, $09, $C2, $7B, $6D, $C3, $00, $71, $21, $C5, $D6, $2A
db $4F, $3A, $22, $71, $C9, $21, $C5, $D6, $AF, $96, $77, $C9, $F5, $FA, $C5, $D6
db $67, $FA, $C6, $D6, $6F, $F1, $E5, $FA, $CC, $D6, $4F, $FA, $C5, $D6, $81, $EA
db $C5, $D6, $FA, $CD, $D6, $4F, $FA, $C6, $D6, $81, $EA, $C6, $D6, $CD, $D3, $70
db $E1, $F5, $7C, $EA, $C5, $D6, $7D, $EA, $C6, $D6, $F1, $C9, $1E, $11, $CD, $DD
db $73, $F5, $FA, $F5, $D6, $67, $FA, $F6, $D6, $6F, $F1, $CD, $F6, $2C, $FE, $6A
db $28, $06, $3E, $14, $EA, $FB, $D6, $C9, $CD, $6F, $71, $EA, $CC, $D6, $CD, $AF
db $73, $F5, $FA, $F7, $D6, $67, $FA, $F8, $D6, $6F, $F1, $F5, $7C, $EA, $F5, $D6
db $7D, $EA, $F6, $D6, $F1, $CD, $6F, $71, $EA, $CD, $D6, $CD, $AF, $73, $F5, $FA
db $F7, $D6, $67, $FA, $F8, $D6, $6F, $F1, $F5, $7C, $EA, $F5, $D6, $7D, $EA, $F6
db $D6, $F1, $CD, $6F, $71, $EA, $CE, $D6, $CD, $AF, $73, $F5, $FA, $F7, $D6, $67
db $FA, $F8, $D6, $6F, $F1, $F5, $7C, $EA, $F5, $D6, $7D, $EA, $F6, $D6, $F1, $CD
db $6F, $71, $EA, $CF, $D6, $CD, $AF, $73, $F5, $FA, $CE, $D6, $67, $FA, $CF, $D6
db $6F, $F1, $F5, $7C, $EA, $C9, $D6, $7D, $EA, $CA, $D6, $F1, $FA, $CE, $D6, $4F
db $FA, $CC, $D6, $B9, $CA, $47, $70, $38, $07, $EA, $CE, $D6, $79, $EA, $CC, $D6
db $FA, $CF, $D6, $4F, $FA, $CD, $D6, $B9, $CA, $47, $70, $38, $07, $EA, $CF, $D6
db $79, $EA, $CD, $D6, $FA, $CC, $D6, $EA, $C5, $D6, $FA, $CD, $D6, $EA, $C6, $D6
db $CD, $4D, $70, $FA, $CC, $D6, $EA, $C5, $D6, $FA, $CF, $D6, $EA, $C6, $D6, $CD
db $4D, $70, $FA, $CC, $D6, $EA, $C5, $D6, $FA, $CD, $D6, $EA, $C6, $D6, $CD, $5B
db $70, $FA, $CE, $D6, $EA, $C5, $D6, $FA, $CD, $D6, $EA, $C6, $D6, $CD, $5B, $70
db $F5, $FA, $F7, $D6, $67, $FA, $F8, $D6, $6F, $F1, $F5, $7C, $EA, $F5, $D6, $7D
db $EA, $F6, $D6, $F1, $CD, $53, $74, $CD, $F6, $2C, $FE, $9E, $C2, $17, $70, $F5
db $FA, $C9, $D6, $67, $FA, $CA, $D6, $6F, $F1, $F5, $7C, $EA, $CC, $D6, $7D, $EA
db $CD, $D6, $F1, $C3, $43, $6F, $FE, $6B, $20, $26, $23, $F5, $7C, $EA, $F5, $D6
db $7D, $EA, $F6, $D6, $F1, $CD, $53, $74, $F5, $FA, $F5, $D6, $67, $FA, $F6, $D6
db $6F, $F1, $CD, $F6, $2C, $FE, $2E, $CA, $00, $71, $3E, $16, $EA, $FB, $D6, $C9
db $3E, $18, $EA, $FB, $D6, $C9, $3E, $19, $EA, $FB, $D6, $C9, $CD, $D3, $70, $21
db $C5, $D6, $FA, $CE, $D6, $BE, $C8, $34, $18, $F2, $CD, $D3, $70, $21, $C6, $D6
db $FA, $CF, $D6, $BE, $C8, $34, $18, $F2, $1E, $12, $CD, $DD, $73, $F5, $FA, $F5
db $D6, $67, $FA, $F6, $D6, $6F, $F1, $CD, $F6, $2C, $FE, $6A, $28, $06, $3E, $14
db $EA, $FB, $D6, $C9, $CD, $6F, $71, $EA, $C5, $D6, $CD, $AF, $73, $F5, $FA, $F7
db $D6, $67, $FA, $F8, $D6, $6F, $F1, $F5, $7C, $EA, $F5, $D6, $7D, $EA, $F6, $D6
db $F1, $CD, $6F, $71, $EA, $C6, $D6, $F5, $FA, $F7, $D6, $67, $FA, $F8, $D6, $6F
db $F1, $F5, $7C, $EA, $F5, $D6, $7D, $EA, $F6, $D6, $F1, $CD, $F6, $2C, $FE, $6B
db $28, $05, $3E, $18, $EA, $FB, $D6, $CD, $AF, $73, $CD, $53, $74, $CD, $D3, $70
db $18, $2D, $FA, $C6, $D6, $C6, $18, $EA, $CA, $C8, $FA, $C5, $D6, $C6, $20, $EA
db $CB, $C8, $CD, $7E, $29, $FA, $DD, $D6, $BD, $20, $06, $FA, $DC, $D6, $BC, $28
db $48, $FA, $C1, $D6, $CB, $6F, $20, $07, $CB, $EF, $EA, $C1, $D6, $18, $1F, $E5
db $F5, $FA, $DC, $D6, $67, $FA, $DD, $D6, $6F, $F1, $F5, $7C, $EA, $93, $D1, $7D
db $EA, $94, $D1, $F1, $3E, $03, $EA, $95, $D1, $FB, $CD, $3F, $7C, $E1, $F5, $7C
db $EA, $DC, $D6, $7D, $EA, $DD, $D6, $F1, $7C, $EA, $93, $D1, $7D, $EA, $94, $D1
db $3E, $04, $EA, $95, $D1, $FB, $CD, $3F, $7C, $FA, $C5, $D6, $FE, $70, $D0, $FA
db $C6, $D6, $FE, $70, $D0, $FA, $C6, $D6, $D6, $08, $30, $FC, $C6, $08, $CB, $27
db $21, $F0, $DC, $85, $6F, $E5, $FA, $C5, $D6, $D6, $08, $30, $FC, $C6, $08, $2E
db $80, $28, $05, $CB, $3D, $3D, $20, $FB, $7D, $E1, $B6, $22, $22, $C9, $CD, $53
db $74, $CD, $EC, $71, $CD, $22, $5C, $CD, $AF, $73, $CD, $E3, $68, $CD, $90, $71
db $CD, $AF, $73, $FA, $E7, $D6, $FE, $70, $D8, $3E, $15, $EA, $FB, $D6, $C9, $FA
db $E9, $D6, $A7, $28, $06, $3E, $15, $EA, $FB, $D6, $C9, $11, $00, $00, $FA, $E8
db $D6, $FE, $00, $28, $30, $FE, $01, $28, $1F, $FE, $02, $20, $2F, $FA, $E7, $D6
db $CD, $E3, $71, $38, $27, $5F, $FA, $E6, $D6, $83, $CD, $E3, $71, $38, $1D, $5F
db $FA, $E5, $D6, $83, $38, $16, $18, $10, $FA, $E7, $D6, $CD, $E3, $71, $5F, $FA
db $E6, $D6, $83, $18, $03, $FA, $E7, $D6, $EA, $E7, $D6, $C9, $3E, $15, $EA, $FB
db $D6, $C9, $4F, $AF, $C6, $0A, $D8, $0D, $20, $FA, $C9, $F5, $FA, $F5, $D6, $67
db $FA, $F6, $D6, $6F, $F1, $23, $F5, $7C, $EA, $F5, $D6, $7D, $EA, $F6, $D6, $F1
db $CD, $53, $74, $F5, $FA, $F5, $D6, $67, $FA, $F6, $D6, $6F, $F1, $CD, $F6, $2C
db $23, $FE, $2E, $20, $06, $3E, $04, $EA, $FB, $D6, $C9, $FE, $6B, $28, $04, $FE
db $9E, $20, $EA, $2B, $F5, $7C, $EA, $F7, $D6, $7D, $EA, $F8, $D6, $F1, $C9, $1E
db $0C, $CD, $C3, $73, $F5, $FA, $F5, $D6, $67, $FA, $F6, $D6, $6F, $F1, $CD, $F6
db $2C, $FE, $6A, $28, $06, $3E, $14, $EA, $FB, $D6, $C9, $CD, $53, $74, $CD, $EC
db $71, $CD, $22, $5C, $CD, $AF, $73, $CD, $E3, $68, $CD, $90, $71, $CD, $AF, $73
db $FA, $E7, $D6, $FE, $10, $38, $06, $3E, $15, $EA, $FB, $D6, $C9, $EA, $CC, $D6
db $F5, $FA, $F7, $D6, $67, $FA, $F8, $D6, $6F, $F1, $F5, $7C, $EA, $F5, $D6, $7D
db $EA, $F6, $D6, $F1, $CD, $EC, $71, $CD, $22, $5C, $CD, $AF, $73, $CD, $E3, $68
db $CD, $90, $71, $CD, $AF, $73, $FA, $E7, $D6, $FE, $0E, $38, $06, $3E, $15, $EA
db $FB, $D6, $C9, $FA, $E7, $D6, $EA, $CD, $D6, $01, $00, $DC, $FA, $CD, $D6, $FE
db $00, $57, $28, $0B, $79, $C6, $40, $4F, $78, $CE, $00, $47, $15, $20, $F5, $FA
db $CC, $D6, $81, $4F, $C5, $CD, $40, $36, $CD, $52, $36, $C1, $F5, $78, $EA, $1E
db $D7, $79, $EA, $1F, $D7, $F1, $C9, $AF, $EA, $27, $D7, $1E, $15, $18, $07, $3E
db $01, $EA, $27, $D7, $1E, $13, $CD, $FE, $73, $F5, $FA, $F5, $D6, $67, $FA, $F6
db $D6, $6F, $F1, $CD, $F6, $2C, $FE, $6A, $28, $06, $3E, $14, $EA, $FB, $D6, $C9
db $23, $F5, $7C, $EA, $F5, $D6, $7D, $EA, $F6, $D6, $F1, $CD, $53, $74, $CD, $69
db $75, $CD, $AF, $73, $CD, $2D, $75, $28, $0B, $CD, $F5, $74, $28, $06, $3E, $1A
db $EA, $FB, $D6, $C9, $0E, $0A, $21, $E9, $D6, $AF, $32, $0D, $20, $FC, $FA, $27
db $D7, $CB, $47, $FA, $1F, $D7, $20, $10, $E6, $C0, $4F, $FA, $1E, $D7, $E6, $03
db $B1, $4F, $CB, $21, $17, $CB, $21, $17, $E6, $0F, $FE, $0A, $38, $02, $C6, $06
db $4F, $CB, $37, $E6, $0F, $FE, $00, $28, $10, $EA, $E7, $D6, $79, $E6, $0F, $EA
db $E6, $D6, $3E, $01, $EA, $E8, $D6, $18, $06, $79, $E6, $0F, $EA, $E7, $D6, $CD
db $41, $61, $C9, $1E, $14, $CD, $FE, $73, $F5, $FA, $F5, $D6, $67, $FA, $F6, $D6
db $6F, $F1, $CD, $F6, $2C, $FE, $6A, $28, $06, $3E, $14, $EA, $FB, $D6, $C9, $23
db $F5, $7C, $EA, $F5, $D6, $7D, $EA, $F6, $D6, $F1, $CD, $53, $74, $CD, $EC, $71
db $CD, $22, $5C, $CD, $AF, $73, $AF, $EA, $EA, $D6, $CD, $41, $61, $C9, $CD, $A3
db $57, $FA, $FB, $D6, $FE, $00, $20, $5C, $C9, $FA, $FB, $D6, $FE, $00, $C8, $E1
db $18, $52, $CD, $19, $74, $20, $4D, $CD, $53, $74, $FA, $C0, $D6, $BB, $20, $44
db $CD, $21, $74, $FA, $15, $D7, $CB, $E7, $EA, $15, $D7, $C9, $CD, $19, $74, $20
db $33, $CD, $53, $74, $FA, $C0, $D6, $BB, $20, $2A, $FA, $C1, $D6, $CB, $77, $20
db $03, $CD, $FD, $69, $FA, $15, $D7, $CB, $E7, $EA, $15, $D7, $C9, $CD, $19, $74
db $20, $12, $CD, $53, $74, $FA, $C0, $D6, $BB, $20, $09, $FA, $15, $D7, $CB, $E7
db $EA, $15, $D7, $C9, $F8, $02, $F9, $C9, $E5, $21, $15, $D7, $CB, $66, $E1, $C9
db $FA, $C1, $D6, $CB, $77, $C8, $CB, $B7, $EA, $C1, $D6, $CD, $5E, $6A, $C9, $CD
db $F6, $2C, $2B, $FE, $BE, $28, $F8, $23, $F5, $7C, $EA, $EC, $D6, $7D, $EA, $ED
db $D6, $F1, $C9, $C5, $0E, $C0, $F5, $FA, $F5, $D6, $67, $FA, $F6, $D6, $6F, $F1
db $18, $0D, $C5, $0E, $BE, $F5, $FA, $F5, $D6, $67, $FA, $F6, $D6, $6F, $F1, $CD
db $F6, $2C, $23, $FE, $2E, $20, $0D, $2B, $F5, $7C, $EA, $F5, $D6, $7D, $EA, $F6
db $D6, $F1, $C1, $C9, $B9, $28, $E8, $2B, $F5, $7C, $EA, $F5, $D6, $7D, $EA, $F6
db $D6, $F1, $C1, $C9, $CD, $53, $74, $AF, $EA, $C0, $D6, $21, $AE, $7C, $F5, $FA
db $F5, $D6, $47, $FA, $F6, $D6, $4F, $F1, $CD, $E6, $2C, $CB, $AF, $BE, $20, $47
db $03, $23, $CD, $E6, $2C, $FE, $75, $28, $08, $FE, $9E, $28, $04, $FE, $2E, $20
db $02, $3E, $BE, $FE, $BE, $20, $07, $7E, $FE, $00, $28, $09, $18, $29, $7E, $FE
db $00, $28, $24, $18, $D3, $F5, $78, $EA, $F5, $D6, $79, $EA, $F6, $D6, $F1, $01
db $AE, $7C, $16, $00, $3A, $FE, $00, $20, $01, $14, $7D, $B9, $20, $F6, $7C, $B8
db $20, $F2, $7A, $EA, $C0, $D6, $C9, $23, $2A, $FE, $00, $20, $FB, $2A, $FE, $00
db $C8, $2B, $18, $9A, $21, $00, $D5, $7E, $FE, $00, $20, $1B, $FA, $F0, $D6, $22
db $FA, $F1, $D6, $22, $FA, $F2, $D6, $22, $F5, $7C, $EA, $EE, $D6, $7D, $EA, $EF
db $D6, $F1, $3E, $00, $CB, $47, $C9, $7D, $C6, $08, $6F, $7C, $CE, $00, $67, $7D
db $FE, $B0, $20, $D3, $7C, $FE, $D6, $20, $CE, $CB, $4F, $C9, $21, $00, $D5, $FA
db $F0, $D6, $BE, $20, $1A, $2C, $FA, $F1, $D6, $BE, $20, $13, $2C, $FA, $F2, $D6
db $BE, $20, $0C, $23, $F5, $7C, $EA, $EE, $D6, $7D, $EA, $EF, $D6, $F1, $C9, $7D
db $E6, $F8, $C6, $08, $6F, $7C, $CE, $00, $67, $7D, $FE, $C0, $20, $D1, $7C, $FE
db $D6, $20, $CC, $3E, $01, $CB, $47, $C9, $21, $F0, $D6, $3E, $BE, $22, $22, $22
db $F5, $FA, $F5, $D6, $67, $FA, $F6, $D6, $6F, $F1, $FA, $C4, $D6, $CB, $67, $28
db $0A, $F5, $FA, $EC, $D6, $67, $FA, $ED, $D6, $6F, $F1, $CD, $F6, $2C, $23, $CD
db $07, $4C, $4F, $FA, $09, $D7, $CB, $4F, $20, $06, $3E, $0B, $EA, $FB, $D6, $C9
db $79, $EA, $F0, $D6, $06, $02, $11, $F1, $D6, $CD, $F6, $2C, $23, $CD, $07, $4C
db $4F, $FA, $09, $D7, $E6, $06, $20, $03, $2B, $18, $15, $79, $12, $1C, $05, $20
db $E8, $CD, $F6, $2C, $23, $CD, $07, $4C, $FA, $09, $D7, $E6, $06, $20, $F2, $2B
db $FA, $C4, $D6, $CB, $67, $C0, $F5, $7C, $EA, $F5, $D6, $7D, $EA, $F6, $D6, $F1
db $C9, $F5, $FA, $EE, $D6, $67, $FA, $EF, $D6, $6F, $F1, $2A, $4F, $CB, $37, $E6
db $0F, $28, $02, $3E, $FF, $EA, $E9, $D6, $79, $E6, $0F, $EA, $E8, $D6, $16, $04
db $01, $E7, $D6, $2A, $5F, $CB, $37, $E6, $0F, $02, $0D, $7B, $E6, $0F, $02, $0D
db $15, $20, $F0, $C9, $CD, $44, $74, $F5, $FA, $F5, $D6, $67, $FA, $F6, $D6, $6F
db $F1, $FA, $C4, $D6, $CB, $BF, $EA, $C4, $D6, $FA, $FB, $D6, $A7, $C0, $CD, $F6
db $2C, $23, $FE, $74, $CC, $3F, $77, $28, $F0, $FE, $9F, $CC, $3F, $77, $28, $E9
db $CD, $07, $4C, $FA, $09, $D7, $CB, $57, $20, $DF, $2B, $CD, $F6, $2C, $23, $CD
db $84, $7C, $28, $06, $3E, $06, $EA, $FB, $D6, $C9, $F5, $FA, $F5, $D6, $67, $FA
db $F6, $D6, $6F, $F1, $16, $09, $CD, $F6, $2C, $23, $FE, $74, $28, $12, $FE, $9F
db $28, $0E, $CD, $84, $7C, $28, $09, $15, $20, $EC, $3E, $15, $EA, $FB, $D6, $C9
db $21, $E9, $D6, $0E, $0A, $AF, $32, $0D, $20, $FC, $F5, $FA, $F5, $D6, $67, $FA
db $F6, $D6, $6F, $F1, $11, $00, $00, $01, $E7, $D6, $CD, $F6, $2C, $23, $FE, $C0
db $28, $F8, $FE, $2E, $C8, $FE, $74, $28, $04, $FE, $9F, $20, $21, $1E, $0F, $16
db $07, $E5, $CD, $F6, $2C, $FE, $C0, $20, $10, $23, $15, $20, $F5, $E1, $16, $0A
db $21, $E0, $D6, $AF, $22, $15, $20, $FC, $C9, $E1, $16, $01, $18, $16, $CD, $07
db $4C, $FA, $09, $D7, $CB, $57, $20, $01, $C9, $2B, $CD, $F6, $2C, $23, $D6, $C0
db $02, $0D, $CB, $FA, $CD, $F6, $2C, $FE, $74, $28, $04, $FE, $9F, $20, $06, $CB
db $C2, $23, $CD, $F6, $2C, $CD, $07, $4C, $FA, $09, $D7, $CB, $57, $20, $0F, $F5
db $7C, $EA, $F5, $D6, $7D, $EA, $F6, $D6, $F1, $CD, $53, $74, $18, $2B, $CD, $F6
db $2C, $23, $D6, $C0, $20, $13, $CB, $7A, $20, $0F, $CB, $42, $28, $C6, $CB, $5B
db $28, $C2, $1D, $CB, $5B, $20, $BD, $18, $10, $CB, $FA, $02, $CB, $42, $20, $01
db $1C, $0D, $79, $FE, $DF, $20, $AD, $CB, $42, $7B, $EA, $E8, $D6, $C9, $F5, $FA
db $C4, $D6, $CB, $7F, $28, $05, $3E, $0F, $EA, $FB, $D6, $CB, $FF, $EA, $C4, $D6
db $F1, $C9, $CD, $53, $74, $CD, $69, $75, $CD, $AF, $73, $CD, $2D, $75, $28, $0E
db $CD, $F5, $74, $01, $F0, $D6, $28, $06, $3E, $1A, $EA, $FB, $D6, $C9, $F5, $FA
db $EE, $D6, $67, $FA, $EF, $D6, $6F, $F1, $F5, $7C, $EA, $DE, $D6, $7D, $EA, $DF
db $D6, $F1, $F5, $FA, $F5, $D6, $67, $FA, $F6, $D6, $6F, $F1, $CD, $F6, $2C, $23
db $FE, $2E, $20, $06, $3E, $04, $EA, $FB, $D6, $C9, $FE, $CE, $20, $EE, $F5, $7C
db $EA, $F5, $D6, $7D, $EA, $F6, $D6, $F1, $CD, $53, $74, $CD, $85, $74, $FA, $C0
db $D6, $FE, $00, $28, $0E, $CD, $53, $74, $23, $F5, $7C, $EA, $F5, $D6, $7D, $EA
db $F6, $D6, $F1, $CD, $58, $5A, $F5, $FA, $F7, $D6, $67, $FA, $F8, $D6, $6F, $F1
db $F5, $7C, $EA, $EC, $D6, $7D, $EA, $ED, $D6, $F1, $CD, $22, $5C, $CD, $AF, $73
db $FA, $C0, $D6, $FE, $14, $20, $04, $AF, $EA, $E9, $D6, $F5, $FA, $DE, $D6, $67
db $FA, $DF, $D6, $6F, $F1, $F5, $7C, $EA, $EE, $D6, $7D, $EA, $EF, $D6, $F1, $CD
db $41, $61, $C9, $F3, $FA, $A7, $D1, $F5, $CD, $40, $36, $CD, $31, $52, $F1, $FE
db $01, $CA, $4B, $78, $F5, $F0, $10, $E6, $CF, $F6, $C1, $E0, $10, $21, $00, $90
db $11, $00, $80, $CD, $F0, $0A, $CD, $10, $0B, $CD, $6B, $79, $CD, $F0, $0A, $CD
db $10, $0B, $21, $00, $90, $11, $21, $1F, $01, $00, $08, $CD, $00, $C9, $CD, $5D
db $7C, $F1, $FE, $02, $CA, $B2, $79, $C3, $76, $79, $CD, $F0, $0A, $CD, $10, $0B
db $21, $00, $90, $11, $09, $14, $01, $00, $08, $CD, $00, $C9, $CD, $F0, $0A, $CD
db $10, $0B, $21, $00, $88, $11, $21, $1F, $01, $00, $08, $CD, $00, $C9, $11, $A1
db $1C, $CD, $CA, $57, $CD, $5D, $7C, $CD, $C1, $4D, $FB, $3E, $0C, $EA, $17, $D7
db $FA, $FB, $DB, $CB, $6F, $20, $0B, $CD, $D9, $55, $FA, $FB, $DB, $CB, $EF, $EA
db $FB, $DB, $CD, $0C, $46, $CD, $51, $47, $FA, $25, $D0, $FE, $FF, $CA, $DA, $7A
db $FA, $15, $D7, $CB, $57, $C2, $38, $52, $CD, $34, $49, $FA, $25, $D0, $F5, $CD
db $DC, $3F, $CD, $40, $36, $CD, $52, $36, $F1, $FE, $2A, $CA, $DA, $7A, $FE, $34
db $28, $D0, $FE, $2E, $28, $1C, $FE, $31, $28, $18, $C3, $04, $78, $21, $0B, $55
db $3E, $07, $EA, $CB, $C8, $3E, $09, $EA, $CA, $C8, $AF, $EA, $CD, $C8, $CD, $46
db $7C, $C9, $CD, $F0, $0A, $CD, $10, $0B, $21, $00, $90, $11, $21, $1F, $01, $00
db $08, $CD, $00, $C9, $CD, $5D, $7C, $CD, $CE, $78, $0E, $AA, $21, $00, $80, $3E
db $00, $EA, $4C, $D0, $3E, $0C, $EA, $A7, $D1, $CD, $DD, $7B, $FE, $A5, $CA, $5F
db $79, $79, $FE, $AA, $3E, $01, $CA, $5F, $79, $0E, $01, $3E, $08, $EA, $A7, $D1
db $CD, $DD, $7B, $21, $30, $D0, $11, $28, $D0, $06, $04, $CD, $02, $29, $0E, $01
db $3E, $04, $EA, $A7, $D1, $21, $00, $88, $CD, $ED, $7B, $0E, $5A, $3E, $0C, $EA
db $A7, $D1, $CD, $DD, $7B, $0E, $01, $3E, $04, $EA, $A7, $D1, $CD, $DD, $7B, $0E
db $01, $3E, $04, $EA, $A7, $D1, $CD, $ED, $7B, $3E, $02, $C3, $8A, $7A, $EA, $A7
db $D1, $C3, $38, $52, $CD, $F0, $0A, $CD, $10, $0B, $2A, $12, $13, $7A, $E6, $0F
db $FE, $08, $20, $F6, $C9, $CD, $A2, $01, $21, $13, $55, $3E, $04, $EA, $CB, $C8
db $3E, $09, $EA, $CA, $C8, $AF, $EA, $CD, $C8, $CD, $46, $7C, $CD, $A2, $01, $CD
db $51, $0E, $FA, $25, $D0, $FE, $2A, $CA, $DA, $7A, $FE, $93, $CA, $B2, $79, $FE
db $B3, $CA, $B2, $79, $FE, $8E, $CA, $88, $7A, $FE, $AE, $C2, $8D, $79, $C3, $88
db $7A, $CD, $A2, $01, $CD, $5D, $7C, $CD, $CE, $78, $21, $90, $DB, $11, $28, $D0
db $06, $0C, $CD, $02, $29, $3E, $00, $EA, $4C, $D0, $CD, $6B, $2E, $FA, $25, $D0
db $FE, $A5, $CA, $25, $7B, $FE, $06, $CA, $A5, $7A, $FE, $01, $CA, $E3, $79, $C3
db $5D, $7B, $3E, $0C, $EA, $A7, $D1, $0E, $AA, $21, $00, $80, $CD, $0E, $7C, $7C
db $EA, $93, $D1, $7D, $EA, $94, $D1, $FA, $25, $D0, $FE, $06, $CA, $A5, $7A, $7C
db $EA, $93, $D1, $7D, $EA, $94, $D1, $3E, $08, $EA, $95, $D1, $11, $28, $D0, $06
db $08, $FB, $CD, $3F, $7C, $21, $00, $88, $7C, $EA, $93, $D1, $7D, $EA, $94, $D1
db $3E, $08, $EA, $95, $D1, $11, $30, $D0, $06, $04, $FB, $CD, $3F, $7C, $0E, $01
db $06, $0C, $CD, $26, $7C, $FA, $25, $D0, $FE, $06, $CA, $A5, $7A, $21, $04, $88
db $0E, $5A, $3E, $0C, $EA, $A7, $D1, $CD, $0E, $7C, $FA, $25, $D0, $FE, $06, $CA
db $A5, $7A, $7C, $EA, $93, $D1, $7D, $EA, $94, $D1, $3E, $08, $EA, $95, $D1, $11
db $28, $D0, $06, $04, $FB, $CD, $3F, $7C, $21, $2C, $D0, $06, $08, $AF, $22, $05
db $C2, $6E, $7A, $0E, $01, $06, $04, $CD, $26, $7C, $FA, $25, $D0, $FE, $06, $CA
db $A5, $7A, $3E, $02, $C3, $8A, $7A, $3E, $01, $EA, $A7, $D1, $21, $00, $80, $11
db $00, $90, $CD, $F0, $0A, $CD, $10, $0B, $CD, $6B, $79, $F0, $10, $F6, $A1, $E0
db $10, $C3, $38, $52, $CD, $5D, $7C, $21, $70, $54, $3E, $04, $EA, $CB, $C8, $3E
db $09, $EA, $CA, $C8, $AF, $EA, $CD, $C8, $CD, $46, $7C, $21, $7E, $54, $3E, $04
db $EA, $CB, $C8, $3E, $0A, $EA, $CA, $C8, $CD, $46, $7C, $CD, $A2, $01, $CD, $51
db $0E, $FA, $25, $D0, $FE, $FF, $CA, $CC, $7A, $CD, $17, $7B, $3E, $03, $EA, $A7
db $D1, $21, $00, $80, $11, $00, $90, $CD, $F0, $0A, $CD, $10, $0B, $CD, $6B, $79
db $F0, $10, $F6, $A1, $E0, $10, $C3, $38, $52, $3E, $04, $EA, $A7, $D1, $21, $00
db $80, $11, $00, $90, $CD, $F0, $0A, $CD, $10, $0B, $CD, $6B, $79, $F0, $10, $F6
db $A1, $E0, $10, $C3, $38, $52, $CD, $A2, $01, $CD, $51, $0E, $FA, $25, $D0, $FE
db $FF, $20, $F3, $C9, $CD, $5D, $7C, $21, $EC, $54, $3E, $02, $EA, $CB, $C8, $3E
db $09, $EA, $CA, $C8, $AF, $EA, $CD, $C8, $CD, $46, $7C, $21, $FC, $54, $3E, $03
db $EA, $CB, $C8, $3E, $0A, $EA, $CA, $C8, $CD, $46, $7C, $CD, $A2, $01, $CD, $51
db $0E, $FA, $25, $D0, $FE, $FF, $CA, $4C, $7B, $C3, $DA, $7A, $CD, $5D, $7C, $21
db $42, $54, $3E, $04, $EA, $CB, $C8, $3E, $09, $EA, $CA, $C8, $AF, $EA, $CD, $C8
db $CD, $46, $7C, $21, $4F, $54, $3E, $05, $EA, $CB, $C8, $3E, $0A, $EA, $CA, $C8
db $CD, $46, $7C, $21, $5A, $54, $3E, $03, $EA, $CB, $C8, $3E, $0B, $EA, $CA, $C8
db $CD, $46, $7C, $21, $69, $54, $3E, $07, $EA, $CB, $C8, $3E, $0C, $EA, $CA, $C8
db $CD, $46, $7C, $CD, $A2, $01, $CD, $51, $0E, $FA, $25, $D0, $FE, $2A, $CA, $DA
db $7A, $FE, $93, $CA, $C9, $7B, $FE, $B3, $CA, $C9, $7B, $FE, $8E, $CA, $DA, $7A
db $FE, $AE, $C2, $A4, $7B, $C3, $DA, $7A, $CD, $5D, $7C, $CD, $CE, $78, $3E, $F8
db $EA, $25, $D0, $CD, $13, $41, $CD, $6B, $2E, $C3, $E3, $79, $C5, $E5, $CD, $5F
db $2F, $E1, $C1, $FA, $25, $D0, $FE, $06, $C8, $FE, $A5, $C8, $7C, $EA, $93, $D1
db $7D, $EA, $94, $D1, $3E, $07, $EA, $95, $D1, $11, $28, $D0, $FA, $A7, $D1, $47
db $FB, $CD, $3F, $7C, $16, $00, $58, $19, $0D, $20, $D1, $AF, $C9, $7C, $EA, $93
db $D1, $7D, $EA, $94, $D1, $3E, $08, $EA, $95, $D1, $11, $28, $D0, $FA, $A7, $D1
db $47, $FB, $CD, $3F, $7C, $78, $EA, $34, $D0, $C5, $E5, $CD, $6B, $2E, $E1, $C1
db $FA, $25, $D0, $FE, $06, $C8, $16, $00, $58, $19, $0D, $20, $D0, $C9, $FA, $95
db $D1, $A7, $20, $FA, $C9, $2A, $FE, $00, $C8, $D6, $80, $EA, $CC, $C8, $E5, $CD
db $91, $04, $E1, $FA, $CB, $C8, $3C, $EA, $CB, $C8, $18, $E9, $CD, $F0, $0A, $CD
db $10, $0B, $21, $F0, $8C, $06, $10, $AF, $22, $05, $20, $FC, $21, $00, $98, $11
db $00, $04, $3E, $CF, $22, $1B, $7A, $B3, $20, $F8, $F0, $10, $E6, $CF, $F6, $C1
db $E0, $10, $C9, $FE, $6A, $C8, $FE, $6B, $C8, $FE, $76, $C8, $FE, $77, $C8, $FE
db $69, $C8, $FE, $6F, $C8, $FE, $9E, $C8, $FE, $CA, $C8, $FE, $CB, $C8, $FE, $CC
db $C8, $FE, $CD, $C8, $FE, $CE, $C8, $FE, $BE, $C8, $FE, $2E, $C9, $90, $92, $89
db $8E, $94, $00, $89, $86, $00, $85, $8E, $84, $00, $83, $8C, $93, $00, $92, $85
db $8D, $00, $93, $94, $8F, $90, $00, $94, $88, $85, $8E, $00, $87, $8F, $94, $8F
db $00, $89, $8E, $90, $95, $94, $00, $8F, $8E, $00, $93, $8F, $95, $8E, $84, $00
db $8C, $8F, $83, $81, $94, $85, $00, $8C, $89, $8E, $85, $00, $87, $92, $81, $90
db $88, $89, $83, $00, $94, $85, $98, $94, $00, $83, $89, $92, $83, $8C, $85, $00
db $92, $85, $83, $94, $81, $8E, $87, $8C, $85, $00, $90, $8F, $89, $8E, $94, $00
db $90, $8F, $93, $00, $81, $82, $93, $00, $83, $93, $92, $8C, $89, $8E
ds 737, $00
