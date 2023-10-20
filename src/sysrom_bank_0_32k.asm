
; Bank 0 (32K bank size)
; Memory region 0x000 - 0x7fff

SECTION "rom0", ROM0[$0]
_DUCK_ENTRY_POINT_0000_:
    di
    jp   _GB_ENTRY_POINT_100_
    nop
    nop
    nop
    nop

_RST__08_:
    ei
    call _LABEL_4A7B_
    di
    jp   _switch_bank_return_to_saved_bank_RAM__C940_

_RST__10_:
    ei
    call _LABEL_A34_
    di
    jp   _switch_bank_return_to_saved_bank_RAM__C940_

_RST__18_:
    jp   _GB_ENTRY_POINT_100_
    nop
    nop
    nop
    nop
    nop

_RST__20_:
    jp   _GB_ENTRY_POINT_100_
    nop
    nop
    nop
    nop
    nop

_RST__28_:
    jp   _GB_ENTRY_POINT_100_
    nop
    nop
    nop
    nop
    nop

_RST__30_:
    jp   _GB_ENTRY_POINT_100_
    nop
    nop
    nop
    nop
    nop

_RST__38_:
    jp   _GB_ENTRY_POINT_100_
    nop
    nop
    nop
    nop
    nop

_INT_VBL__40_:
    di
    call _VBL_HANDLER__6D_
    ei
    reti
    nop
    nop


_INT_STAT__48_:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop


_INT_TIMER__50_:
    di
    call timer_int_handler__00BB_
    ei
    reti
    nop
    nop


_INT_SERIAL__58_:
    di
    call serial_int_handler__00CE_
    ei
    reti
    nop
    nop


_INT_JOYPAD__60_:
    di
    push af
    ld   a, [_RAM_D020_]
    add  $05
    ld   [_RAM_D020_], a
    pop  af
    ei
    reti


_VBL_HANDLER__6D_:
    push af
    push bc
    push de
    push hl
    ld   a, [_RAM_D193_]
    ld   h, a
    ld   a, [_RAM_D194_]
    ld   l, a
    ld   a, [_RAM_D195_]  ; TODO: _RAM_D195_ seems like a selector for what to execute in VBL. Not sure where it gets set
    and  a
    jr   z, _VBL_HANDLER_TAIL__AF_
    cp   $01
    jr   nz, _VBL_HANDLER_2__88_

    call _LABEL_6A26_
    jr   _VBL_HANDLER_TAIL__AF_

    _VBL_HANDLER_2__88_:
        cp   $02
        jr   nz, _VBL_HANDLER_3__91_
        call _LABEL_6F40_
        jr   _VBL_HANDLER_TAIL__AF_

    _VBL_HANDLER_3__91_:
        cp   $03
        jr   nz, _VBL_HANDLER_4__9A_
        call _LABEL_481A_
        jr   _VBL_HANDLER_TAIL__AF_

    _VBL_HANDLER_4__9A_:
        cp   $04
        jr   nz, _VBL_HANDLER_5__A3_
        call _LABEL_4826_
        jr   _VBL_HANDLER_TAIL__AF_

    _VBL_HANDLER_5__A3_:
        cp   $05
        jr   nz, _VBL_HANDLER_6__AC_
        call _LABEL_6CD7_
        jr   _VBL_HANDLER_TAIL__AF_

    _VBL_HANDLER_6__AC_:
        call _LABEL_6DAB_

    _VBL_HANDLER_TAIL__AF_:
        xor  a
        ld   [_RAM_D195_], a
        call _oam_dma_routine_in_HRAM__FF80_ ; $FF80
        pop  hl
        pop  de
        pop  bc
        pop  af
        ret


; Called by Timer interrupt vector
;
; Overflows/Triggers interrupt every 201 ticks (0x100 - 0x37) = 201
; 4096 Hz / (201) = ~20.378Hz, roughly every 3rd frame
timer_int_handler__00BB_:
    push af
    ld   a, [_RAM_D020_]  ; TODO: some kind of global counter shared with serial IO
    add  $07
    ld   [_RAM_D020_], a
    ld   a, [timer_flags__RAM_D000_]
    set  TIMER_FLAG__BIT_TICKED, a  ; 2, a
    ld   [timer_flags__RAM_D000_], a
    pop  af
    ret


; Serial IO ISR
;
; - Stores serial data in:        serial_link_rx_data__RAM_D021_
; - Sets transfer status done in: serial_link_status__RAM_D022_
; - Turns off the serial IO interrupt
serial_int_handler__00CE_:
    push af
    ldh  a, [rSB]
    ld   [serial_link_rx_data__RAM_D021_], a
    ld   a, SERIAL_STATUS_DONE ; $01
    ld   [serial_link_status__RAM_D022_], a
    call serial_int_disable__A2B_
    pop  af
    ret


; Data from DE to FE (33 bytes)
ds 33, $00

; Data from FF to FF (1 bytes)
_DATA_FF_:
db $00

_GB_ENTRY_POINT_100_:
    di
    xor  a
    ld   [_RAM_D195_], a
    call serial_system_init_check__9CF_
    wait_serial_status_ok__108_:
        ld   a, [serial_system_status__RAM_D024_]
        bit  SYS_REPLY__BIT_BOOT_FAIL, a  ; 0, a
        jr   nz, wait_serial_status_ok__108_ ; @ - 5
_LABEL_10F_:
    ld   a, $09
    ld   [serial_link_tx_data__RAM_D023_], a
    call serial_io_send_byte__B64_
    call serial_io_read_byte_no_timeout__B7D_
    ld   a, [serial_link_rx_data__RAM_D021_]
    ld   [_RAM_D2E4_], a
    ld   hl, _RAM_DBFC_ ; _RAM_DBFC_ = $DBFC
    ldi  a, [hl]
    cp   $AA
    jr   nz, @ + 14
    ldi  a, [hl]
    cp   $E4
    jr   nz, @ + 9
    ldi  a, [hl]
    cp   $55
    jr   nz, @ + 4
    jr   _LABEL_14E_
    xor  a
    ld   [_RAM_DBFB_], a    ; _RAM_DBFB_ = $DBFB

_LABEL_138_:
    ld   a, $AA
    ld   [_RAM_DBFC_], a
    ld   a, $E4
    ld   [_RAM_DBFD_], a
    ld   a, $55
    ld   [_RAM_DBFE_], a
    ld   a, $AA
    ld   [_RAM_D400_], a
    jr   _LABEL_152_

_LABEL_14E_:
    xor  a
    ld   [_RAM_D400_], a    ; _RAM_D400_ = $D400

_LABEL_152_:
    di
    ld   sp, $C400
    ; TODO: For now skip over this hardware init on GB
    ; Might be related to the synthesized speech on first power + maybe keyboard, etc
    if ((!def(TARGET_MEGADUCK)) && def(GB_DEBUG))
        nop
        nop
        nop
    else
        call _LABEL_97A_
    endc
    call _vram_init__752_

_LABEL_15C_:
    ld   a, [_RAM_D400_]
    cp   $AA
    call z, _LABEL_25E_
    call wait_until_vbl__92C_
    call _LABEL_94C_

    ld   hl, $9000
    ld   de, _DATA_11F2_
    ld   bc, $0800
    call _memcopy_in_RAM__C900_

    call wait_until_vbl__92C_
    call _LABEL_94C_

    ld   hl, $8800
    ld   de, $2F2A
    ld   bc, $0800
    call _memcopy_in_RAM__C900_

    xor  a
    ld   [_RAM_D06C_], a    ; _RAM_D06C_ = $D06C
    ld   a, $0C
    ld   [_RAM_D06D_], a    ; _RAM_D06D_ = $D06D
    call _LABEL_4A7B_
    call _LABEL_56E_


; TODO: Starting here seems to be some kind of big if/else function call selector for whatever is in D06E
; Including eventually calling the "no cart in slot" using value 0B (Range 0x00 - 0x0B)
    ld   a, [_RAM_D06E_]
    cp   $00
    jr   nz, _LABEL_1A3_
    call _LABEL_54AE_
    jr   _LABEL_15C_

_LABEL_1A3_:
    cp   $01
    jr   nz, _LABEL_1B3_
    xor  a
    ldh  [rSCX], a
    call _LABEL_4D6F_
    ld   a, $FF
    ldh  [rSCX], a
    jr   _LABEL_15C_

_LABEL_1B3_:
    cp   $02
    jr   nz, _LABEL_1C5_
    di
    ld   hl, _RST__08_  ; _RST__08_ = $0008
    res  7, h
    ld   a, $01
    call _switch_bank_jump_hl_RAM__C920_    ; Possibly invalid
    ei
    jr   _LABEL_15C_

_LABEL_1C5_:
    cp   $03
    jr   nz, _LABEL_1D7_
    di
    ld   hl, _RST__10_  ; _RST__10_ = $0010
    res  7, h
    ld   a, $01
    call _switch_bank_jump_hl_RAM__C920_    ; Possibly invalid
    ei
    jr   _LABEL_15C_

_LABEL_1D7_:
    cp   $04
    jr   nz, _LABEL_1EA_
    di
        ld   hl, _RST__18_  ; _RST__18_ = $0018
        res  7, h
        ld   a, $01
        call _switch_bank_jump_hl_RAM__C920_    ; Possibly invalid
        ei
        jp   _LABEL_15C_

_LABEL_1EA_:
    cp   $05
    jr   nz, _LABEL_1FD_
    di
    ld   hl, _RST__20_  ; _RST__20_ = $0020
    res  7, h
    ld   a, $01
    call _switch_bank_jump_hl_RAM__C920_    ; Possibly invalid
    ei
    jp   _LABEL_15C_

_LABEL_1FD_:
    cp   $06
    jr   nz, _LABEL_20D_
    call _LABEL_52F_
    call _LABEL_6328_
    call _LABEL_54B_
; Data from 20A to 20C (3 bytes)
_DATA_20A_:
db $C3, $5C, $01

_LABEL_20D_:
    cp   $07
    jr   nz, _LABEL_226_
    di
    call _LABEL_52F_
    ld   hl, $0010
    res  7, h
    ld   a, $02
    call _switch_bank_jump_hl_RAM__C920_
    call _LABEL_54B_
    ei
    jp   _LABEL_15C_

_LABEL_226_:
    cp   $08
    jr   nz, _LABEL_230_
    call _LABEL_711A_
    jp   _LABEL_15C_

_LABEL_230_:
    cp   $09
    jr   nz, _LABEL_249_
    di
    call _LABEL_52F_
    ld   hl, $0008
    res  7, h
    ld   a, $02
    call _switch_bank_jump_hl_RAM__C920_
    call _LABEL_54B_
    ei
    jp   _LABEL_15C_

_LABEL_249_:
    cp   $0A
    jr   nz, _LABEL_253_
    call _LABEL_5E55_
    jp   _LABEL_15C_

; TODO : Maybe the "Run Cart from slot" Main menu item?
_LABEL_253_:
    cp   $0B ; TODO: Add constant for this SYS command
    jp   nz, _LABEL_15C_
    call maybe_try_run_cart_from_slot__5E1_
    jp   _LABEL_15C_

_LABEL_25E_:
    ld   hl, _RAM_D028_ ; _RAM_D028_ = $D028
    ld   a, $94
    ldi  [hl], a
    ld   a, $01
    ldi  [hl], a
    ldi  [hl], a
    ld   a, $06
    ldi  [hl], a
    xor  a
    ldi  [hl], a
    xor  a
    ldi  [hl], a
    ldi  [hl], a
    ldi  [hl], a
    ld   a, $0B
    ld   [_RAM_D035_], a    ; _RAM_D035_ = $D035
    ld   a, $08
    ld   [_RAM_D034_], a    ; _RAM_D034_ = $D034
_LABEL_27B_:
    call _LABEL_A34_
    ld   a, [maybe_input_key_new_pressed__RAM_D025_]
    cp   $FC
    ret  z
    call timer_wait_tick_AND_TODO__289_
    jr   _LABEL_27B_

; Turn on interrupts and wait for a Timer tick
; - Maybe audio driver related
; - Maybe gamepad / Keyboard input related
;
; - Turn on interrupts
;
; Overflows/Triggers interrupt every 201 ticks (0x100 - 0x37) = 201
; 4096 Hz / (201) = ~20.378Hz, roughly every 3rd frame
;
; TODO: maybe: timer_wait_tick_AND_TODO__289_;
timer_wait_tick_AND_TODO__289_:
    ei
loop_wait_timer__28A_:
    ld   hl, timer_flags__RAM_D000_
    bit  TIMER_FLAG__BIT_TICKED, [hl]  ; 2, [hl]
    jp   nz, _LABEL_43C_
    jr   loop_wait_timer__28A_


; Waits for a Timer tick to read the joypad & buttons
;
; Possibly unused?
wait_timer_then_read_joypad_buttons__294_:
    ld   hl, timer_flags__RAM_D000_
    bit  TIMER_FLAG__BIT_TICKED, [hl]  ; 2, [hl]
    jr   nz, start_read__29D_
    jr   wait_timer_then_read_joypad_buttons__294_

    start_read__29D_:
        ; Clear flag and read joypad
        res  TIMER_FLAG__BIT_TICKED, [hl]  ; 2, [hl]
        jp   joypad_and_buttons_read__4F9_
        ; Returns at end of joypad_and_buttons_read__4F9_


_LABEL_2A2_:
    ld   a, [_RAM_CC01_]    ; _RAM_CC01_ = $CC01
    set  0, a
    res  4, a
    ld   [_RAM_CC01_], a    ; _RAM_CC01_ = $CC01
    ld   a, l
    ld   [_RAM_CC11_], a    ; _RAM_CC11_ = $CC11
    ld   a, h
    ld   [_RAM_CC10_], a    ; _RAM_CC10_ = $CC10
    ld   a, $8B
    ld   [_RAM_CC12_], a    ; _RAM_CC12_ = $CC12
    ld   a, $00
    ld   [_RAM_CC13_], a    ; _RAM_CC13_ = $CC13
    ld   a, $C0
    ld   [_RAM_CC14_], a    ; _RAM_CC14_ = $CC14
    ld   a, [_RAM_CC00_]    ; _RAM_CC00_ = $CC00
    or   $11
    ld   [_RAM_CC00_], a    ; _RAM_CC00_ = $CC00
    ld   a, $01
    ld   [_RAM_CC23_], a    ; _RAM_CC23_ = $CC23
    ret

_LABEL_2D1_:
    ld   a, [_RAM_CC40_]    ; _RAM_CC40_ = $CC40
    ld   h, a
    ld   a, [_RAM_CC41_]    ; _RAM_CC41_ = $CC41
    ld   l, a
    ld   a, [hl]
    ld   b, a
    inc  hl
    ld   a, h
    ld   [_RAM_CC40_], a    ; _RAM_CC40_ = $CC40
    ld   a, l
    ld   [_RAM_CC41_], a    ; _RAM_CC41_ = $CC41
    ld   a, $FF
    ld   [_RAM_CC48_], a    ; _RAM_CC48_ = $CC48
    ld   [_RAM_CC49_], a    ; _RAM_CC49_ = $CC49
    bit  7, b
    jr   z, _LABEL_307_
    ld   a, [_RAM_CC47_]    ; _RAM_CC47_ = $CC47
    res  0, a
    ld   [_RAM_CC47_], a    ; _RAM_CC47_ = $CC47
    dec  hl
    ld   a, l
    ld   [_RAM_CC41_], a    ; _RAM_CC41_ = $CC41
    ld   a, h
    ld   [_RAM_CC40_], a    ; _RAM_CC40_ = $CC40
    ld   a, $01
    ld   [_RAM_CC42_], a    ; _RAM_CC42_ = $CC42
    ret

_LABEL_307_:
    ld   a, [hl]
    ld   [_RAM_CC42_], a    ; _RAM_CC42_ = $CC42
    inc  hl
    ld   a, h
    ld   [_RAM_CC40_], a    ; _RAM_CC40_ = $CC40
    ld   a, l
    ld   [_RAM_CC41_], a    ; _RAM_CC41_ = $CC41
    ret

_LABEL_315_:
    ld   a, [_RAM_CC02_]    ; _RAM_CC02_ = $CC02
    or   $01
    ld   [_RAM_CC02_], a    ; _RAM_CC02_ = $CC02
    ld   a, [_RAM_CC01_]    ; _RAM_CC01_ = $CC01
    bit  4, a
    jr   z, _LABEL_327_
    jp   _LABEL_3A6_

_LABEL_327_:
    ld   a, [_RAM_CC10_]    ; _RAM_CC10_ = $CC10
    ld   h, a
    ld   a, [_RAM_CC11_]    ; _RAM_CC11_ = $CC11
    ld   l, a
    ld   a, [hl]
    ld   b, a
    inc  hl
    ld   a, h
    ld   [_RAM_CC10_], a    ; _RAM_CC10_ = $CC10
    ld   a, l
    ld   [_RAM_CC11_], a    ; _RAM_CC11_ = $CC11
    ld   a, [_RAM_CC12_]    ; _RAM_CC12_ = $CC12
    ld   [_RAM_CC2F_], a    ; _RAM_CC2F_ = $CC2F
    bit  7, b
    jr   z, _LABEL_37D_
_LABEL_344_:
    ld   a, $FE
    xor  b
    jr   z, _LABEL_36F_
    dec  hl
    ld   a, l
    ld   [_RAM_CC11_], a    ; _RAM_CC11_ = $CC11
    ld   a, h
    ld   [_RAM_CC10_], a    ; _RAM_CC10_ = $CC10
    ld   a, $FF
    ld   [_RAM_CC28_], a    ; _RAM_CC28_ = $CC28
    ld   a, $07
    ld   [_RAM_CC27_], a    ; _RAM_CC27_ = $CC27
    ld   a, $01
    ld   [_RAM_CC23_], a    ; _RAM_CC23_ = $CC23
    ld   a, $01
    ld   [_RAM_CC2F_], a    ; _RAM_CC2F_ = $CC2F
    ld   a, [_RAM_CC00_]    ; _RAM_CC00_ = $CC00
    and  $EE
    ld   [_RAM_CC00_], a    ; _RAM_CC00_ = $CC00
    ret

_LABEL_36F_:
    ld   a, [_RAM_CC60_]    ; _RAM_CC60_ = $CC60
    ld   [_RAM_CC10_], a    ; _RAM_CC10_ = $CC10
    ld   a, [_RAM_CC61_]    ; _RAM_CC61_ = $CC61
    ld   [_RAM_CC11_], a    ; _RAM_CC11_ = $CC11
    jr   _LABEL_327_


; TODO: What is this actually doing
_LABEL_37D_:
    ; Calculate offset (A X 2) into table at _DATA_BE3_ -> HL
    ld   a, b
    add  a
    ld   c, a
    ld   b, $00
    ld   hl, _DATA_BE3_
    add  hl, bc
    ; Load u16 from table at HL into _RAM_CC27_, _RAM_CC28_
    inc  hl
    ld   a, [hl]
    ld   [_RAM_CC28_], a
    dec  hl
    ld   a, [hl]
    ld   [_RAM_CC27_], a

    ; Load pointer from _RAM_CC10_, _RAM_CC11_
    ; Read a byte and save it to _RAM_CC23_
    ; Then store pointer addr +1 back in _RAM_CC10_, _RAM_CC11_
    ld   a, [_RAM_CC10_]
    ld   h, a
    ld   a, [_RAM_CC11_]
    ld   l, a
    ld   a, [hl]
    ld   [_RAM_CC23_], a

    inc  hl
    ld   a, h
    ld   [_RAM_CC10_], a    ; _RAM_CC10_ = $CC10
    ld   a, l
    ld   [_RAM_CC11_], a    ; _RAM_CC11_ = $CC11
    ret


_LABEL_3A6_:
    ld   a, [_RAM_CC10_]    ; _RAM_CC10_ = $CC10
    ld   h, a
    ld   a, [_RAM_CC11_]    ; _RAM_CC11_ = $CC11
    ld   l, a
    ldi  a, [hl]
    bit  7, a
    jr   z, _LABEL_406_
    ld   a, [_RAM_CC47_]    ; _RAM_CC47_ = $CC47
    bit  0, a
    jp   z, _LABEL_344_
    res  0, a
    ld   [_RAM_CC47_], a    ; _RAM_CC47_ = $CC47
    ld   a, [_RAM_CC41_]    ; _RAM_CC41_ = $CC41
    ld   [_RAM_CC11_], a    ; _RAM_CC11_ = $CC11
    ld   a, [_RAM_CC40_]    ; _RAM_CC40_ = $CC40
    ld   [_RAM_CC10_], a    ; _RAM_CC10_ = $CC10
    ld   a, [_RAM_CC43_]    ; _RAM_CC43_ = $CC43
    ld   [_RAM_CC12_], a    ; _RAM_CC12_ = $CC12
    ld   a, [_RAM_CC44_]    ; _RAM_CC44_ = $CC44
    ld   [_RAM_CC13_], a    ; _RAM_CC13_ = $CC13
    ld   a, [_RAM_CC45_]    ; _RAM_CC45_ = $CC45
    ld   [_RAM_CC14_], a    ; _RAM_CC14_ = $CC14
    ld   a, [_RAM_CC48_]    ; _RAM_CC48_ = $CC48
    ld   [_RAM_CC27_], a    ; _RAM_CC27_ = $CC27
    ld   a, [_RAM_CC49_]    ; _RAM_CC49_ = $CC49
    ld   [_RAM_CC28_], a    ; _RAM_CC28_ = $CC28
    ld   a, [_RAM_CC46_]    ; _RAM_CC46_ = $CC46
    ld   b, a
    ld   a, [_RAM_CC00_]    ; _RAM_CC00_ = $CC00
    and  $EE
    or   b
    ld   [_RAM_CC00_], a    ; _RAM_CC00_ = $CC00
    ld   a, [_RAM_CC42_]    ; _RAM_CC42_ = $CC42
    ld   [_RAM_CC23_], a    ; _RAM_CC23_ = $CC23
    ld   a, [_RAM_CC01_]    ; _RAM_CC01_ = $CC01
    res  4, a
    ld   [_RAM_CC01_], a    ; _RAM_CC01_ = $CC01
    ret

_LABEL_406_:
    ld   [_RAM_CC23_], a    ; _RAM_CC23_ = $CC23
    ldi  a, [hl]
    ld   [_RAM_CC2F_], a    ; _RAM_CC2F_ = $CC2F
    ldi  a, [hl]
    ld   [_RAM_CC14_], a    ; _RAM_CC14_ = $CC14
    ldi  a, [hl]
    ld   [_RAM_CC27_], a    ; _RAM_CC27_ = $CC27
    ldi  a, [hl]
    ld   [_RAM_CC28_], a    ; _RAM_CC28_ = $CC28
    ldi  a, [hl]
    ld   [_RAM_CC13_], a    ; _RAM_CC13_ = $CC13
    and  $80
    jr   z, _LABEL_42B_
    ld   a, [_RAM_CC01_]    ; _RAM_CC01_ = $CC01
    set  0, a
    ld   [_RAM_CC01_], a    ; _RAM_CC01_ = $CC01
    jr   _LABEL_433_

_LABEL_42B_:
    ld   a, [_RAM_CC01_]    ; _RAM_CC01_ = $CC01
    res  0, a
    ld   [_RAM_CC01_], a    ; _RAM_CC01_ = $CC01
_LABEL_433_:
    ld   a, l
    ld   [_RAM_CC11_], a    ; _RAM_CC11_ = $CC11
    ld   a, h
    ld   [_RAM_CC10_], a    ; _RAM_CC10_ = $CC10
    ret


; Clears Timer ticked flag...
; TODO: probably audio driver related
_LABEL_43C_:
    res  TIMER_FLAG__BIT_TICKED, [hl]  ; 2, [hl]
    ld   a, [_RAM_CC00_]    ; _RAM_CC00_ = $CC00
    bit  0, a
    jr   nz, _LABEL_44A_
    bit  4, a
    jp   z, _LABEL_4D3_

_LABEL_44A_:
    ld   a, [_RAM_CC23_]    ; _RAM_CC23_ = $CC23
    dec  a
    ld   [_RAM_CC23_], a    ; _RAM_CC23_ = $CC23
    jr   nz, _LABEL_4C0_

    call _LABEL_315_
    ld   a, [_RAM_CC02_]    ; _RAM_CC02_ = $CC02
    bit  0, a
    jp   z, _LABEL_4C0_
    ld   a, [_RAM_CC13_]    ; _RAM_CC13_ = $CC13
    ldh  [rAUD1SWEEP], a
    ld   a, [_RAM_CC14_]    ; _RAM_CC14_ = $CC14
    ldh  [rAUD1LEN], a
    ld   a, [_RAM_CC28_]    ; _RAM_CC28_ = $CC28
    ldh  [rAUD1LOW], a
    ; TODO: Is this where it interacts with the speech synthesizer chip?
    ld   a, (AUDVOL_VIN_LEFT | AUDVOL_VIN_RIGHT | %01110111)  ; $FF  ; Set rAUDVOL to both VIN = ON, Max Left/Right volume
    ldh  [rAUDVOL], a
    ld   a, [_RAM_CC2F_]    ; _RAM_CC2F_ = $CC2F
    ld   a, [_RAM_CC27_]    ; _RAM_CC27_ = $CC27
    cp   $07
    jr   nz, _LABEL_486_
    ld   a, [_RAM_CC28_]    ; _RAM_CC28_ = $CC28
    cp   $FF
    jr   nz, _LABEL_486_
    ld   a, $80
    jr   _LABEL_488_

_LABEL_486_:
    ld   a, $0F
_LABEL_488_:
    ldh  [rAUD1ENV], a
    ld   a, [_RAM_CC27_]    ; _RAM_CC27_ = $CC27
    res  6, a
    set  7, a
    ld   b, a
    ld   a, [_RAM_CC01_]    ; _RAM_CC01_ = $CC01
    bit  0, a
    jr   z, _LABEL_49E_
    ld   a, b
    res  6, a
    jr   _LABEL_49F_

_LABEL_49E_:
    ld   a, b
_LABEL_49F_:
    ld   b, a
    ld   a, [_RAM_CC27_]    ; _RAM_CC27_ = $CC27
    cp   $07
    jr   nz, _LABEL_4B5_
    ld   a, [_RAM_CC28_]    ; _RAM_CC28_ = $CC28
    cp   $FF
    jr   nz, _LABEL_4B5_
    xor  a
    ldh  [rAUDENA], a
    ld   a, AUDENA_ON  ; $80
    ldh  [rAUDENA], a
_LABEL_4B5_:
    ld   a, b
    ldh  [rAUD1HIGH], a
    ld   a, [_RAM_CC02_]    ; _RAM_CC02_ = $CC02
    res  0, a
    ld   [_RAM_CC02_], a    ; _RAM_CC02_ = $CC02
_LABEL_4C0_:
    ld   a, [_RAM_CC47_]    ; _RAM_CC47_ = $CC47
    bit  0, a
    jr   z, _LABEL_4D3_
    ld   a, [_RAM_CC42_]    ; _RAM_CC42_ = $CC42
    dec  a
    ld   [_RAM_CC42_], a    ; _RAM_CC42_ = $CC42
    jr   nz, _LABEL_4D3_
    call _LABEL_2D1_
_LABEL_4D3_:
    ld   a, [_RAM_CC00_]    ; _RAM_CC00_ = $CC00
    bit  1, a
    jr   nz, _LABEL_4DE_
    bit  5, a
    jr   z, _LABEL_4DE_
_LABEL_4DE_:
    ld   a, [_RAM_CC00_]    ; _RAM_CC00_ = $CC00
    bit  2, a
    jr   nz, _LABEL_4E9_
    bit  6, a
    jr   z, _LABEL_4E9_
_LABEL_4E9_:
    ld   a, [_RAM_CC00_]    ; _RAM_CC00_ = $CC00
    bit  3, a
    jr   nz, _LABEL_4F4_
    bit  7, a
    jr   z, _LABEL_4F4_
_LABEL_4F4_:
    ld   a, [_RAM_CC00_]    ; _RAM_CC00_ = $CC00
    ldh  [rAUDTERM], a



; Read D-Pad and Buttons
;
; - D-Pad: Upper nibble
; - Buttons: Lower nibble
;
; - Newly pressed buttons saved to: buttons_new_pressed__RAM_D006_
; - current pressed buttons saved to: buttons_current__RAM_D007_
joypad_and_buttons_read__4F9_:
    ; Read D-Pad
    ld   a, P1F_GET_DPAD  ; $20
    ldh  [rP1], a
    ldh  a, [rP1]
    ldh  a, [rP1]
    ldh  a, [rP1]
    cpl
    and  $0F
    swap a
    ld   b, a
    ; Read Buttons
    ld   a, P1F_GET_BTN  ; $10
    ldh  [rP1], a
    ldh  a, [rP1]
    ldh  a, [rP1]
    ldh  a, [rP1]
    cpl
    and  $0F
    ; Merge D-Pad and Buttons (active High)
    or   b
    ld   b, a
    ; Determine newly pressed buttons and save result
    ld   hl, buttons_new_pressed__RAM_D006_
    xor  [hl]
    and  b
    ld   [hl], b
    ; Save currently pressed buttons as well
    ld   [buttons_current__RAM_D007_], a
    ret

; TODO: RESEARCH
; Interesting...
; TODO: ? Switch to Bank 2 and jump to an RST 30 ? ... Why the res 7, h ?
_LABEL_522_:
    di
    ld   hl, $0030
    res  7, h
    ld   a, $02  ; Bank 2
    call _switch_bank_jump_hl_RAM__C920_
    ei
    ret

_LABEL_52F_:
    ld   a, [_RAM_DBFB_]
    ld   [_RAM_D080_], a
    ld   hl, _RAM_D740_
    ld   de, _RAM_CD00_
    ld   b, $C0
    call _LABEL_482B_
    ld   hl, _RAM_DAD0_
    ld   de, _RAM_D081_
    ld   b, $C0
    jp   _LABEL_482B_

_LABEL_54B_:
    ld   a, [_RAM_D080_]
    and  $02
    ld   b, a
    ld   a, [_RAM_DBFB_]
    or   b
    ld   [_RAM_DBFB_], a
    ld   hl, _RAM_CD00_
    ld   de, _RAM_D740_
    ld   b, $C0
    call _LABEL_482B_
    ld   hl, _RAM_D081_
    ld   de, _RAM_DAD0_
    ld   b, $C0
    jp   _LABEL_482B_

_LABEL_56E_:
    call wait_until_vbl__92C_
    call _LABEL_94C_
    ld   hl, $8800
    ld   de, $2F2A
    ld   bc, $0800
    call _memcopy_in_RAM__C900_
    ld   a, $A0
    ldh  [rWY], a
    call _LABEL_488F_
    ld   hl, _string_table_630_
    ld   a, [_RAM_D06E_]
    cp   $00
    jr   z, _LABEL_59A_
    ld   b, a
_LABEL_592_:
    ldi  a, [hl]
    cp   $00
    jr   nz, _LABEL_592_
    dec  b
    jr   nz, _LABEL_592_
_LABEL_59A_:
    call wait_until_vbl__92C_
    call _LABEL_94C_
    ld   de, $9D20
_LABEL_5A3_:
    ldi  a, [hl]
    cp   $00
    jr   z, _display_win_obj_on__5B5_
    cp   $01
    jr   z, _LABEL_5B0_
    ld   [de], a
    inc  de
    jr   _LABEL_5A3_

_LABEL_5B0_:
    ld   de, $9D40
    jr   _LABEL_5A3_

; Turn on display, Window, Sprites
_display_win_obj_on__5B5_:
    ldh  a, [rLCDC]
    or   (LCDCF_ON | LCDCF_WINON | LCDCF_OBJON) ; $A1
    ldh  [rLCDC], a
    call _LABEL_967_
    ld   a, $0A
    jp   _LABEL_4A72_


; TODO:  This is probably the function that gets called
; right before the cartridge is launched.
;
; Nothing seems to call it yet though.
;
_window_scroll_up__5C3_:
    di
    ld   a, 160 ; Start Window top position at Y line 160 ; $A0
    ldh  [rWY], a

    window_scroll_up_loop__5C8_:
        ld   hl, $2000  ; Delay 57,346 M-Cycles (a little less than one frame [70,224])
        _delay_loop__5CB_:
                dec  hl
                ld   a, l
                or   h
                jr   nz, _delay_loop__5CB_
            ei
            ldh  a, [rWY]
            sub  $08
            ldh  [rWY], a
            di
            cp   $00
            jr   nz, window_scroll_up_loop__5C8_
            ld   a, $0A
            jp   _LABEL_4A72_


; TODO: Seems to check and see whether a cart was found in the slot
; If one isn't found then it displays a message indicating that
; try_run_cart_from_slot__5E1_:
maybe_try_run_cart_from_slot__5E1_:
    ; TODO: Request booting from the cart slot?
    ld   a, SYS_CMD_RUN_CART_IN_SLOT ; $08
    ld   [serial_link_tx_data__RAM_D023_], a
    call serial_io_send_byte__B64_
    call serial_io_wait_receive__B8F_  ; Result is in A. 0x01 if byte was received
    and  a
    ; Wait for a serial IO response byte
    jr   z, maybe_try_run_cart_from_slot__5E1_

    ld   a, [serial_link_rx_data__RAM_D021_]
    cp   SYS_REPLY_NO_CART_IN_SLOT ; $06  ; Indicates there was no cart in the slot to run
    jr   z, display_message__no_cart_in_slot_to_run__5F9
    ; TODO: If starting the cart slot succeeded then execute NOPs until the cart starts
    ; Presumably there may be some small delay before the system ROM unmaps itself?
    ;
    ; What about a jump to the entry point and resetting state? Does the hardware handle that
    ; by strobing the reset line?
    _idle_until_cart_starts_5F6_:
        nop
        jr   _idle_until_cart_starts_5F6_


; After a short delay this message is cleared and the program
; returns to the main menu
display_message__no_cart_in_slot_to_run__5F9:
    call _LABEL_4875_
    ld   de, _string_message__no_cart_in_slot_to_run__734_
    ; Render first line
    ld   hl, $030A         ; Column 3, Row 10 (zero based)
    ld   c, PRINT_NORMAL  ; $01
    call render_string_at_de_to_tilemap0_xy_in_hl__4A46_
    ; Render second line
    ; DE is now at the start of the second line
    ; (C is still PRINT_NORMAL  ; $01)
    ld   hl, $030B         ; Column 3, Row 11 (zero based)
    call render_string_at_de_to_tilemap0_xy_in_hl__4A46_
    ld   a, $64
    jp   _LABEL_4A72_ ; TODO: there is a small delay after string is shown, is part of this call handling that (sort of wait_vsync N times)?


; Waits until VBL then Writes byte to Tile Map 0 VRAM at preset address X,Y
;
; - Tilemap X,Y and byte to write in global vars
;
wait_vbl_write_byte_tilemap0_preset_xy_and_data__612_:
        push af
        push bc
        push de
        push hl
        call wait_until_vbl__92C_
        ld   a, TILEMAP_0  ; $00
        call write_tilemap_in_a_preset_xy_and_data_8FB_
        pop  hl
        pop  de
        pop  bc
        pop  af
        ret

_LABEL_623_:
    call oam_find_slot_and_load_into__86F
    ret

; Masks out: LCDCF_WINON, LCDCF_BG8000
; Turns Display, BG and sprites on
_display_bg_sprites_on__627_:
    ldh  a, [rLCDC]
    and  (LCDCF_ON | LCDCF_BGON | LCDCF_WIN9C00 | LCDCF_BG9C00 | LCDCF_OBJ16 | LCDCF_OBJON) ; $CF
    or   (LCDCF_ON | LCDCF_BGON | LCDCF_OBJON) ; $C1
    ldh  [rLCDC], a
    ret


; - Block of encoded text at 0x0637 - 0x0750
;        92 85 8C 8F 8A 00 BE BE BE BE BE 83 81 8C 85 8E 84 81 92 89 8F 00 BE BE BE BE BE 83 81 8C 83 95 8C 81 84 8F 92 81 00 BE BE BE BE BE BE BE 81 87 85 8E 84 81 00 BE BE BE BE BE 83 88 85 91 95 85 8F BE 84 85 01 BE BE BE BE BE BE 84 85 8C 85 94 92 85 8F 00 BE BE BE BE BE BE BE 8A 95 85 87 8F 93 00 BE BE BE BE BE BE BE 84 89 82 95 8A 8F 00 BE BE BE BE 90 92 8F 87 92 81 8D 81 83 89 8F 8E 01 BE BE BE BE BE BE BE 82 81 93 89 83 81 00 BE BE BE BE BE BE BE BE 90 89 81 8E 8F 00 BE BE BE 90 92 8F 83 85 93 81 84 8F 92 BE 84 85 01 BE BE BE BE BE BE 90 81 8C 81 82 92 81 93 00 BE BE BE 84 89 83 83 89 8F 8E 81 92 89 8F BE 84 85 01 BE BE BE BE BE BE 84 89 82 95 8A 8F 93 00 BE BE BE BE 89 8E 94 85 92 92 95 90 94 8F 92 01 BE BE BE BE 84 85 8C BE 93 89 93 94 85 8D 81 00 86 89 83 88 81 F1 86 89 83 88 85 92 8F 00 8E 8F BE 85 8E 83 8F 8E 93 92 81 84 8F 93 00
;        RELOJ ~~~~~CALENDARIO ~~~~~CALCULADORA ~~~~~~~AGENDA ~~~~~CHEQUEO~DE￁~~~~~~DELETREO ~~~~~~~JUEGOS ~~~~~~~DIBUJO ~~~~PROGRAMACION￁~~~~~~~BASICA ~~~~~~~~PIANO ~~~PROCESADOR~DE￁~~~~~~PALABRAS ~~~DICCIONARIO~DE￁~~~~~~DIBUJOS ~~~~INTERRUPTOR￁~~~~DEL~SISTEMA FICHA±FICHERO NO~ENCONSRADOS

; Encoding:
; Add +64 (0x40) to ASCII values for most letters
; Space      = 0xBE
;     /      = 0xF1
; String end = 0x00


; Data from 630 to 733 (260 bytes)
_string_table_630_:
db $BE, $BE, $BE, $BE, $BE, $BE, $BE, $92, $85, $8C, $8F, $8A, $00, $BE, $BE, $BE
db $BE, $BE, $83, $81, $8C, $85, $8E, $84, $81, $92, $89, $8F, $00, $BE, $BE, $BE
db $BE, $BE, $83, $81, $8C, $83, $95, $8C, $81, $84, $8F, $92, $81, $00, $BE, $BE
db $BE, $BE, $BE, $BE, $BE, $81, $87, $85, $8E, $84, $81, $00, $BE, $BE, $BE, $BE
db $BE, $83, $88, $85, $91, $95, $85, $8F, $BE, $84, $85, $01, $BE, $BE, $BE, $BE
db $BE, $BE, $84, $85, $8C, $85, $94, $92, $85, $8F, $00, $BE, $BE, $BE, $BE, $BE
db $BE, $BE, $8A, $95, $85, $87, $8F, $93, $00, $BE, $BE, $BE, $BE, $BE, $BE, $BE
db $84, $89, $82, $95, $8A, $8F, $00, $BE, $BE, $BE, $BE, $90, $92, $8F, $87, $92
db $81, $8D, $81, $83, $89, $8F, $8E, $01, $BE, $BE, $BE, $BE, $BE, $BE, $BE, $82
db $81, $93, $89, $83, $81, $00, $BE, $BE, $BE, $BE, $BE, $BE, $BE, $BE, $90, $89
db $81, $8E, $8F, $00, $BE, $BE, $BE, $90, $92, $8F, $83, $85, $93, $81, $84, $8F
db $92, $BE, $84, $85, $01, $BE, $BE, $BE, $BE, $BE, $BE, $90, $81, $8C, $81, $82
db $92, $81, $93, $00, $BE, $BE, $BE, $84, $89, $83, $83, $89, $8F, $8E, $81, $92
db $89, $8F, $BE, $84, $85, $01, $BE, $BE, $BE, $BE, $BE, $BE, $84, $89, $82, $95
db $8A, $8F, $93, $00, $BE, $BE, $BE, $BE

; Message text displayed before running a cart from the cart slot
; (the text is rendered to the window layer and the window scrolls
;  up and then it tries to boot the cart)
;
; INTERRUPTOR DEL SISTEMA
;   Raw ROM: at:0x0718 (Maybe starting 0713 or 0714?)
;            TEXT :I  N  T  E  R  R  U  P  T  O  R  \n             D  E  L     S  I  S  T  E  M  A
;         RAW-ROM :89 8E 94 85 92 92 95 90 94 8F 92 01 BE BE BE BE 84 85 8C BE 93 89 93 94 85 8D 81 00
db $89, $8E, $94, $85, $92, $92, $95, $90, $94, $8F, $92, $01, $BE, $BE, $BE, $BE
db $84, $85, $8C, $BE, $93, $89, $93, $94, $85, $8D, $81, $00


; Message text displayed when the user tries to run a cart
; from the cart slot, but there is no cart detected in it
;
; FICHA/FICHERO NO ECONSRADOS
;   Raw ROM: at:0x0734
;             TEXT:F  I  C  H  A  /  F  I  C  H  E  R  O  \n N  O        E  C  O  N  S  R  A  D  O  S
;         RAW-ROM :86 89 83 88 81 F1 86 89 83 88 85 92 8F 00 8E 8F BE 85 8E 83 8F 8E 93 92 81 84 8F 93 00
; Data from 734 to 751 (30 bytes)
_string_message__no_cart_in_slot_to_run__734_:
db $86, $89, $83, $88, $81, $F1, $86, $89, $83, $88, $85, $92, $8F, $00,
db $8E, $8F, $BE, $85, $8E, $83, $8F, $8E, $93, $92, $81, $84, $8F, $93, $00
db $C9

_vram_init__752_:
    ld   a, $00
    ld   [_rombank_currrent__C8D7_], a
    ldh  [rLCDC], a  ; clear all LCDC bits

        ld   hl, _TILEDATA8000  ; $8000
    _loop_clear_vram_all_tile_patterns__75C_:
        xor  a
        ldi  [hl], a
        ld   a, h
        cp   HIGH(_TILEMAP0)  ; $98
        jr   nz, _loop_clear_vram_all_tile_patterns__75C_

    ; hl now at $9800
    ; Fill Tile Map 1 with tile id $BE
    _loop_fill_tile_map0__763_:
        ld   a, $BE
        ldi  [hl], a
        ld   a, h
        cp   HIGH(_TILEMAP1) ; $9C
        jr   nz, _loop_fill_tile_map0__763_

    ; Fill RAM from _RAM_SHADOW_OAM_BASE__C800_ -> _RAM_C8BF_ ($A0 / 160 bytes)
        ld   hl, _RAM_SHADOW_OAM_BASE__C800_
        ld   b, SHADOW_OAM_SZ ; $A0
    _LABEL_770_:
        xor  a  ; This doesn't need to be re-zeroed each loop iteration...
        ldi  [hl], a
        dec  b
        jr   nz, _LABEL_770_

        ; Turn screen/etc off
        ldh  [rLCDC], a
        nop
        nop
        nop
        nop

        ; LCD on
        ld   a, (LCDCF_ON | LCDCF_BGON | LCDCF_WIN9C00) ; $C8
        ldh  [rLCDC], a

        ; Clear OAM via cleared shadow OAM
        ; TODO: Is there no bus conflict when oam DMA is run from ROM on the Quique with interrupts disabled?
        call _oam_dma_routine_in_ROM__7E3_

        ; Set the BG & Sprite color palettes
        ld   a, COLS_0WHT_1LGRY_2DGRY_3BLK  ; $E4
        ldh  [rOBP0], a
        ldh  [rBGP], a
        ld   a, COLS_0BLK_1DGRY_2LGRY_3WHT ; $1B
        ldh  [rOBP1], a

        ; Init Window and BG Map Scroll X
        ld   a, $07
        ldh  [rWX], a
        ld   a, $FF    ; Why not 0 for SCX?
        ldh  [rSCX], a

        ; Load several functions into RAM so they persist across 32K sized bank switches
        ; Mainly memcopy and bank switching related


        ld   hl, STARTOF("wram_functions_start_c900")
        ; HL at 0x9C00
        ; _memcopy_in_RAM__C900_
        ld   de, _memcopy__7D3_
        call _memcpy_32_bytes__7CA_

        ; HL now at 0x9C20
        ; (_switch_bank_jump_hl_RAM__C920_)
        ld   de, _switch_bank_jump_hl_ROM__82C_
        call _memcpy_32_bytes__7CA_

        ; HL now at 0x9C40
        ; (_switch_bank_return_to_saved_bank_RAM__C940_)
        ld   de, _switch_bank_return_to_saved_ROM__841_
        call _memcpy_32_bytes__7CA_

        ; HL now at 0x9C60
        ; (_switch_bank_memcopy_hl_to_de_len_bc_RAM__C960_)
        ld   de, _switch_bank_memcopy_hl_to_de_len_bc_ROM__7EF_
        call _memcpy_32_bytes__7CA_

        ; HL now at 0x9C80
        ld   de, _switch_bank_read_byte_at_hl_ROM__80C_
        call _memcpy_32_bytes__7CA_

        ; Load OAM DMA Copy routine into HRAM
        ld   hl, _oam_dma_routine_in_HRAM__FF80_
        ld   de, _oam_dma_routine_in_ROM__7E3_ ; $07E3
        call _memcpy_32_bytes__7CA_

        ; Clear 42 bytes of RAM used for OAM slot management
        ld   a, OAM_SLOT_EMPTY
        ld   b, (OAM_USAGE_SZ + 2) ; $2A ; TODO: Why +2 here what is at _RAM_C8C8_ and C9? 
        ld   hl, oam_slot_usage__RAM_C8A0_
        loop_oam_clear__7C5_:
            ldi  [hl], a
            dec  b
            jr   nz, loop_oam_clear__7C5_
        ret

; Always copies 32 bytes
; Source in DE
; Dest in HL
_memcpy_32_bytes__7CA_:
    ld   b, $20
_memcpy_32bytes_loop_7CC_:
    ld   a, [de]
    ldi  [hl], a
    inc  de
    dec  b
    jr   nz, _memcpy_32bytes_loop_7CC_
    ret

; Memcopy
; - Source in DE
; - Dest   in HL
; - Length in BC
; Gets copied to and run from _memcopy_in_RAM__C900_
_memcopy__7D3_:
    ld   a, [de]
    ldi  [hl], a
    inc  de
    dec  bc
    ld   a, b
    or   c
    jr   nz, _memcopy__7D3_
    ret

; TODO: does excecution ever reach here?
    ldh  a, [rLCDC]
    or   LCDCF_ON  ; $80
    ldh  [rLCDC], a
    ret

; Gets copied to and run from _oam_dma_routine_in_HRAM__FF80_
_oam_dma_routine_in_ROM__7E3_:
    di
    ld   a, HIGH(_RAM_SHADOW_OAM_BASE__C800_)  ; $C8
    ldh  [rDMA], a
    ld   a, $28  ; Wait 160 nanosec
    _oam_dma_copy_wait_loop_7EA_:
        dec  a
        jr   nz, _oam_dma_copy_wait_loop_7EA_
        ei
        ret


SECTION "rom0_bankswitch_functions_07EF", ROM0[$07EF]
include "quique_sysrom_bankswitch_functions.asm"

SECTION "rom0_end_bankswitch_functions_0851", ROM0[$0851]


_LABEL_851_:
        ld   a, [maybe_vram_data_to_write__RAM_C8CC_]
        dec  a
        sla  a
        sla  a
        ld   l, a
        ld   h, $C8
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        add  [hl]
        ld   e, a
        ld   [hl], a
        inc  hl
        ld   a, [_tilemap_pos_x__RAM_C8CB_]
        add  [hl]
        ld   d, a
        ld   [hl], a
        ld   a, $00
        ret

_LABEL_86C_:
        ld   a, $02
        ret


; Locates a free OAM slot, copies into the shadow OAM
;
; - Copies from: _tilemap_pos_y__RAM_C8CA_
; - ? Maybe Returns OAM slot number in: B
; - ? Returns $00 in : A
;
; Destroys A, BC, DE, HL
oam_find_slot_and_load_into__86F:
    ld   c, $00
    ld   hl, oam_slot_usage__RAM_C8A0_

    ; Find first empty OAM slot
    loop_find_empty_slot_874_:
        inc  c
        ldi  a, [hl]
        cp   OAM_SLOT_EMPTY ; $00
        jr   nz, loop_find_empty_slot_874_

    ; Mark the newly found slot as used
    dec  hl
    ld   a, OAM_SLOT_USED  ; $FF
    ld   [hl], a

    ; Index into the Shadow OAM by 4 x OAM Slot number
    ; Re-uses H = $C8 for that
    ld   a, c
    dec  a
    sla  a
    sla  a
    ld   l, a
    ld   de, _tilemap_pos_y__RAM_C8CA_  ; TODO: Maybe label for this is wrong?
    ld   b, $04
    ; Copy 4 bytes from TODO into the Shadow OAM slot
    ; Presumably sprite data
    loop_shadow_oam_copy__88A_:
        ld   a, [de]
        ldi  [hl], a
        inc  de
        dec  b
        jr   nz, loop_shadow_oam_copy__88A_

    ; TODO: Is this some kind of oam slot copy increment for multiple sprites?
    ld   a, [_RAM_C8C8_]    ; _RAM_C8C8_ = $C8C8
    inc  a
    ld   [_RAM_C8C8_], a    ; _RAM_C8C8_ = $C8C8
    ; Maybe return slot number in B?
    ld   b, c
    ld   a, $00
    ret


; Frees an OAM slot and clears related bytes in shadow OAM
;
; Destroys A, DE, HL
oam_free_slot_and_clear__89B_:
    ; Index into the Shadow OAM by 4 x maybe_vram_data_to_write__RAM_C8CC_
    ld   a, [maybe_vram_data_to_write__RAM_C8CC_]  ; TODO: Maybe var needs more general name
    cp   $00
    jr   z,     done_return__8C3_
    dec  a
    sla  a
    sla  a
    ld   l, a
    ld   h, HIGH(_RAM_SHADOW_OAM_BASE__C800_)  ; $C8

    ; Clear out the Shadow OAM entry
    ld   a, $00
    ldi  [hl], a
    ldi  [hl], a
    ldi  [hl], a
    ldi  [hl], a

    ; Now index into the slot manager and free the entry
    ld   de, oam_slot_usage__RAM_C8A0_
    ld   a, [maybe_vram_data_to_write__RAM_C8CC_]
    dec  a
    add  e
    ld   e, a
    ld   a, OAM_SLOT_EMPTY  ; $00
    ld   [de], a

    ; TODO: Is this some kind of oam slot copy increment for multiple sprites?
    ld   a, [_RAM_C8C8_]    ; _RAM_C8C8_ = $C8C8
    dec  a
    ld   [_RAM_C8C8_], a    ; _RAM_C8C8_ = $C8C8

    done_return__8C3_:
    ret


_LABEL_8C4_:
    ld   b, $12
    ld   hl, _TILEMAP0; $9800
    cp   $00
    jr   z, _LABEL_8D0_
    ld   hl, $9C00
_LABEL_8D0_:
    ld   c, $14
_LABEL_8D2_:
    ld   a, [de]
    ldi  [hl], a
    inc  de
    dec  c
    jr   nz, _LABEL_8D2_
    ld   a, $0C
    add  l
    ld   l, a
    ld   a, $00
    adc  h
    ld   h, a
    dec  b
    jr   nz, _LABEL_8D0_
    ldh  a, [rLCDC]
    or   $80
    ldh  [rLCDC], a
    ret


; Writes byte to Tile Map 0 VRAM at preset address X,Y
;
; - Byte to write in :A
; - Tilemap X,Y to write in global vars
;
write_tilemap0_byte_in_a_preset_xy__8EA_:
    push af
    push bc
    push de
    push hl
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    ld   a, TILEMAP_0  ; $00
    call write_tilemap_in_a_preset_xy_and_data_8FB_
    pop  hl
    pop  de
    pop  bc
    pop  af
    ret


; Writes to Tile Map VRAM at preset address X,Y with preset byte
;
; - Tilemap select [0/1 = Tilemap0/1] in :A
; - Tilemap X,Y and byte to write in global vars
;
; - Destroys: A, DE, HL
write_tilemap_in_a_preset_xy_and_data_8FB_:
    ; Select which between Tilemap 0 or 1
    ld   hl, _TILEMAP0  ; $9800
    cp   $00
    jr   z, _tilemap_sel_done__905_
    ld   hl, _TILEMAP1  ; $9C00

    _tilemap_sel_done__905_:
        ; Calculate vram address into Tile Map for X, Y in global vars
        ; First add X
        ld   a, $00
        ld   d, a
        ld   a, [_tilemap_pos_x__RAM_C8CB_]
        ld   e, a
        add  hl, de

        ; Then add Y (upshift << 5 to multiply by 32)
        ld   a, [_tilemap_pos_y__RAM_C8CA_]
        dec  a
        ld   e, a
        REPT 5
            sla  e
            rl   d
        ENDR
        add  hl, de

        ; HL now has X,Y offset into Tile Map VRAM
        ; Write byte to it and return
        ld   a, [maybe_vram_data_to_write__RAM_C8CC_]
        ld   [hl], a
        ret


; Waits until VBlank line 145
;
; - Temporarily turns off VBL ISR while doing that
; - Returns immediately if screen is off
wait_until_vbl__92C_:
    ; If screen is ON then continue
    ; If the screen is OFF then return
    ldh  a, [rLCDC]
    bit  LCDCF_B_ON, a  ; bit 7
    jr   nz, _wait_until_hblank__933_
    ret

    _wait_until_hblank__933_:
        ; wait until Mode 0: HBlank
        ldh  a, [rSTAT]
        and  STATF_LCD  ; $03 (STATF LCD Status Mask)
        jr   nz, _wait_until_hblank__933_

        ; Save state of Interrupt enables
        ; Then turn off VBlank Interrupt
        ldh  a, [rIE]
        ldh  [_rIE_saved__RAM_FFA1_], a
        res  IEF_B_VBLANK, a  ; bit 0
        ldh  [rIE], a

    ; Why line 145 instead of 144?
    _wait_until_line_145__941_:
        ldh  a, [rLY]
        cp   LY_VBL_SECOND_LINE  ; $91
        jr   nz, _wait_until_line_145__941_

        ; Restore previous state of Interrupt enables
        ldh  a, [_rIE_saved__RAM_FFA1_]
        ldh  [rIE], a
        ret


_LABEL_94C_:
    ldh  a, [rLCDC]
    and  $7F
    ldh  [rLCDC], a
    ret

_LABEL_953_:
    ld   a, [maybe_vram_data_to_write__RAM_C8CC_]
    dec  a
    sla  a
    sla  a
    ld   l, a
    ld   h, $C8
    ldi  a, [hl]
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    ldi  a, [hl]
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ret

; TODO: _window_scroll_up ... AND? ...  __967_
; Waits for timer...
_LABEL_967_:
    ld   a, 160 ; Start Window top position at Y line 160 ; $A0

    window_scroll_up_loop__969_:
        ldh  [rWY], a
        ei
        call timer_wait_tick_AND_TODO__289_
        di
        ldh  a, [rWY]
        and  a
        jr   z, _LABEL_979_
        sub  $08
        jr   window_scroll_up_loop__969_

_LABEL_979_:
    ret


; TODO: some kind of startup init
_LABEL_97A_:
    ; Timer and Enable VBlank interrupts
    ld   a, (IEF_TIMER | IEF_VBLANK)  ; $05
    ldh  [rIF], a
    ldh  [rIE], a
    ; Serial Init
    xor  a
    ldh  [rSB], a
    ldh  [rSC], a
    ldh  [rAUDENA], a
    ; Turn on Screen
    ldh  [rLCDC], a
    ld   a, LCDCF_ON  ; $80
    ldh  [rLCDC], a
    ; Set up BG Colors
    ld   a, COLS_0WHT_1LGRY_2DGRY_3BLK  ; $E4
    ldh  [rBGP], a
    ldh  [rOBP0], a
    ld   a, COLS_0BLK_1DGRY_2LGRY_3WHT  ; $1B
    ldh  [rOBP1], a
    ; Set up Audio Wave channel
    xor  a
    ldh  [rAUD3ENA], a
    ld   a, $FF
    ldh  [rAUD3LEN], a
    ld   a, $55
    ld   bc, $0800 | LOW(_AUD3WAVERAM_LAST) ; | _PORT_3F_
    loop_fill_ch3_wave_ram_LABEL__9A3_:
        ldh  [c], a
        dec  c
        dec  b
        jr   nz, loop_fill_ch3_wave_ram_LABEL__9A3_
    ld   hl, rAUDENA
    ld   a, AUDENA_ON  ; $80
    ldd  [hl], a
    ; TODO: Fix incorrect address on Game Boy (should be rAUDVOL, *not* rAUDTERM)
    ; Unless patched, GB now points to the wrong audio register due to address reshuffling and the LD HL-
    ; On MegaDuck: HL now points to rAUDVOL (0xFF44)
    ; On GB      : HL *incorrectly* points to rAUDTERM (0xFF25)
    ld   [hl], %01110111  ; $77  ; Set rAUDVOL to Max Left/Right volume, with VIN off for left and right
    nop
    nop
    nop
    nop
    xor  a
    ld   [_RAM_CC02_], a    ; _RAM_CC02_ = $CC02
    ld   [_RAM_CC00_], a    ; _RAM_CC00_ = $CC00
    ld   [_RAM_CC01_], a    ; _RAM_CC01_ = $CC01
    ld   a, $28
    ldh  [rAUD1LEN], a
    ldh  [rAUD2LEN], a
    ; Timer init
    ; Start timer and use default 4KHz freq
    ;
    ; Overflows/Triggers interrupt every 201 ticks (0x100 - 0x37) = 201
    ; 4096 Hz / (201) = ~20.378Hz, roughly every 3rd frame
    ;
    ld   a, TIMER_DIV_TO_20HZ ; $37
    ldh  [rTMA], a
    ldh  [rTIMA], a
    ld   a, (TACF_START | TACF_4KHZ); $04
    ldh  [rTAC], a
    ret


; Does some kind of serial IO system startup init
; and sends count up sequence / then waits for and checks a count down sequence in reverse
;
; - Does this have anything to do with the "first time boot up" voice greeting?
;
; - Turns on Serial interrupt
serial_system_init_check__9CF_:
    ld   a, IEF_SERIAL ; $08
    ldh  [rIE], a
    xor  a
    ld   [serial_system_status__RAM_D024_], a  ; TODO: System startup status var? (success/failure?)
    xor  a
    ; Sending some kind of init(? TODO) count up sequence through the serial IO (0,1,2,3...255)
    ; Then wait for a response with no timeout
    loop_send_sequence__9D8_:
        ld   [serial_link_tx_data__RAM_D023_], a
        call serial_io_send_byte__B64_
        inc  a
        jr   nz, loop_send_sequence__9D8_
    call serial_io_read_byte_no_timeout__B7D_

    ; Handle reply
    cp   SYS_REPLY_BOOT_OK  ; $01
    ld   b, $00             ; This might not do anything... (not used and later overwritten)
    call nz, serial_system_status_set_fail__BBA_

    ; Send a "0" byte (SYS_CMD_INIT_SEQ_REQUEST)
    ; That maybe requests a 255..0 countdown sequence (be sent into the serial IO)
    xor  a
    ld   [serial_link_tx_data__RAM_D023_], a
    call serial_io_send_byte__B64_

    ; ? Expects a reply sequence through the serial IO of (255,254...0) ?
    ld   b, $01             ; This might not do anything, again... (not used and later overwritten)
    ld   c, $FF
    loop_receive_sequence__9F6_:
        call serial_io_read_byte_no_timeout__B7D_
        cp   c
        call nz, serial_system_status_set_fail__BBA_  ; Set status failed if reply doesn't match expected  sequence value
        dec  c
        ld   a, c
        cp   $FF
        jr   nz, loop_receive_sequence__9F6_

    ; Check for failures during the reply sequence
    ld   a, [serial_system_status__RAM_D024_]
    bit  SYS_REPLY__BIT_BOOT_FAIL, a  ; 0, a
    jr   nz, set_send_if_sequence_no_match__A0E_  ; If there were any failures in the sequence, send
    ld   a, SYS_CMD_INIT_SEQ_MATCH  ; $01
    jr   send_response_to_sequence__A10_

    set_send_if_sequence_no_match__A0E_:
        ld   a, SYS_CMD_INIT_SEQ_NO_MATCH  ; $04  ; TODO: THis gets sent if the startup sequence didn't match... but what is it?

    send_response_to_sequence__A10_:
        ld   [serial_link_tx_data__RAM_D023_], a
        call serial_io_send_byte__B64_
        ret


; Prepares to receive data through the serial (or special?) IO
;
; - Sets serial IO to external clock and enables ready state
; - Turns on Serial interrupt, clears pending interrupts, turns on interrupts
serial_io_enable_receive_byte__A17_:
    push af
    ; TODO: What does writing 0 to FF60 do here? Does it select alternate input for the serial control?
    ; Set ready to receive an inbound transfer
    ; Enable Serial Interrupt and clear any pending interrupts
    ; Then turn on interrupts
    xor  a
    ldh  [_PORT_60_], a

    ld   a, (SERIAL_XFER_ENABLE | SERIAL_CLOCK_EXT)  ; $80
    ldh  [rSC], a

    ldh  a, [rIE]
    or   IEF_SERIAL ; $08
    ldh  [rIE], a
    xor  a
    ldh  [rIF], a
    ei
    pop  af
    ret


; Turns off the Serial Interrupt
serial_int_disable__A2B_:
    push af
    ldh  a, [rIE]
    and  ~IEF_SERIAL ; $F7
    ldh  [rIE], a
    pop  af
    ret


; Turns on Serial IO interrupt
_LABEL_A34_:
    ldh  a, [rIE]
    ld   [_rIE_saved_serial__RAM_D078_], a
    ld   a, IEF_SERIAL ; $08
    ldh  [rIE], a

    ld   a, [_RAM_D034_]    ; _RAM_D034_ = $D034
    cp   $0D
    jr   c, _LABEL_A46_
    jr   _LABEL_A5B_

_LABEL_A46_:
    ld   a, [_RAM_D035_]    ; _RAM_D035_ = $D035
    ld   [serial_link_tx_data__RAM_D023_], a
    call serial_io_send_byte__B64_
    call delay_quarter_msec__BD6_
    call delay_quarter_msec__BD6_
    call serial_io_wait_receive_w_timeout_50msec__B8F_
    and  a
    jr   nz, _LABEL_A63_
_LABEL_A5B_:
    ld   a, $FD
    ld   [maybe_input_key_new_pressed__RAM_D025_], a
    jp   _LABEL_AE9_

_LABEL_A63_:
    ld   a, [serial_link_rx_data__RAM_D021_]
    cp   $06
    jp   z, _LABEL_AE4_
    cp   $03
    jp   nz, _LABEL_A5B_
    ld   a, [_RAM_D034_]    ; _RAM_D034_ = $D034
    ld   b, a
    add  $02
    ld   [serial_link_tx_data__RAM_D023_], a
    ld   [_RAM_D026_], a
    call delay_quarter_msec__BD6_
    call serial_io_send_byte__B64_
    call delay_quarter_msec__BD6_
    call delay_quarter_msec__BD6_
    ld   hl, _RAM_D028_ ; _RAM_D028_ = $D028
_LABEL_A8B_:
    ldi  a, [hl]
    ld   [serial_link_tx_data__RAM_D023_], a
    ld   c, a
    ld   a, [_RAM_D026_]
    add  c
    ld   [_RAM_D026_], a
    call serial_io_wait_receive_w_timeout_50msec__B8F_
    and  a
    jr   z, _LABEL_A5B_
    ld   a, [serial_link_rx_data__RAM_D021_]
    cp   $06
    jp   z, _LABEL_AE4_
    cp   $03
    jp   nz, _LABEL_A5B_
    call serial_io_send_byte__B64_
    dec  b
    jr   nz, _LABEL_A8B_
    call serial_io_wait_receive_w_timeout_50msec__B8F_
    and  a
    jr   z, _LABEL_A5B_
    ld   a, [serial_link_rx_data__RAM_D021_]
    cp   $06
    jp   z, _LABEL_AE4_
    cp   $03
    jp   nz, _LABEL_A5B_
    ld   hl, _RAM_D026_
    xor  a
    sub  [hl]
    ld   [serial_link_tx_data__RAM_D023_], a
    call serial_io_send_byte__B64_
    call serial_io_wait_receive_w_timeout_50msec__B8F_
    and  a
    jp   z, _LABEL_A5B_
    ld   a, [serial_link_rx_data__RAM_D021_]
    cp   $01
    jp   nz, _LABEL_A5B_
    call serial_io_wait_receive_w_timeout_50msec__B8F_
    ld   a, $FC
    jr   _LABEL_AE6_

_LABEL_AE4_:
    ld   a, $FB
_LABEL_AE6_:
    ld   [maybe_input_key_new_pressed__RAM_D025_], a
_LABEL_AE9_:
    ; Restore previous interrupt enable state
    ld   a, [_rIE_saved_serial__RAM_D078_]
    ldh  [rIE], a
    ret

_LABEL_AEF_:
    ldh  a, [rIE]
    ld   [_rIE_saved_serial__RAM_D078_], a
    ld   a, IEF_SERIAL ; $08
    ldh  [rIE], a
    ld   d, $00
    call delay_quarter_msec__BD6_
    ld   a, [_RAM_D036_]    ; _RAM_D036_ = $D036
    ld   [serial_link_tx_data__RAM_D023_], a
    call serial_io_send_byte__B64_
    call serial_io_wait_receive_w_timeout_50msec__B8F_
    and  a
    jr   z, _LABEL_B13_
    ld   a, [serial_link_rx_data__RAM_D021_]
    cp   $0E
    jr   c, _LABEL_B1C_
_LABEL_B13_:
    ld   a, $FA
    ld   [maybe_input_key_new_pressed__RAM_D025_], a
    ld   a, $04
    jr   _LABEL_B58_

_LABEL_B1C_:
    ld   [_RAM_D026_], a
    dec  a
    dec  a
    ld   [_RAM_D034_], a    ; _RAM_D034_ = $D034
    ld   b, a
    ld   hl, _RAM_D028_ ; _RAM_D028_ = $D028
_LABEL_B28_:
    push hl
    call serial_io_wait_receive__B8F_
    and  a
    pop  hl
    jr   z, _LABEL_B13_
    ld   a, [serial_link_rx_data__RAM_D021_]
    ldi  [hl], a
    ld   c, a
    ld   a, [_RAM_D026_]
    add  c
    ld   [_RAM_D026_], a
    dec  b
    jr   nz, _LABEL_B28_
    call serial_io_wait_receive__B8F_
    and  a
    jr   z, _LABEL_B13_
    call delay_quarter_msec__BD6_
    ld   a, [serial_link_rx_data__RAM_D021_]
    ld   hl, _RAM_D026_
    add  [hl]
    jr   nz, _LABEL_B13_
    ld   a, $F9
    ld   [maybe_input_key_new_pressed__RAM_D025_], a
    ld   a, $01
_LABEL_B58_:
    ld   [serial_link_tx_data__RAM_D023_], a
    call serial_io_send_byte__B64_
    ld   a, [_rIE_saved_serial__RAM_D078_]
    ldh  [rIE], a
    ret


; Sends the byte in serial_link_tx_data__RAM_D023_ out through serial (or special?) IO
;
; - Called from "run cart from slot"
; - Possibly called from keyboard input polling
serial_io_send_byte__B64_:
    push af
    ; TODO: What does writing 0 to FF60 do here? Does it select alternate output for the serial control?
    ; Start an outbound (serial IO?) transfer
    ; Load byte to send
    ; Wait a quarter msec, then clear pending interrupts
    ; Set ready to receive an inbound transfer
    xor  a
    ldh  [_PORT_60_], a
    ld   a, (SERIAL_XFER_ENABLE | SERIAL_CLOCK_INT) ; $81
    ldh  [rSC], a

    ld   a, [serial_link_tx_data__RAM_D023_]
    ldh  [rSB], a
    call delay_quarter_msec__BD6_

    xor  a
    ldh  [rIF], a
    ld   a, (SERIAL_XFER_ENABLE | SERIAL_CLOCK_EXT); $80
    ldh  [rSC], a
    pop  af
    ret


; Waits for and returns a byte from Serial IO with NO timeout
;
; - Returns received serial byte in: A
serial_io_read_byte_no_timeout__B7D_:
    ld   a, SERIAL_STATUS_RESET ; $00
    ld   [serial_link_status__RAM_D022_], a
    call serial_io_enable_receive_byte__A17_

    loop_wait_reply__B85_:
        ld   a, [serial_link_status__RAM_D022_]
        and  a
        jr   z, loop_wait_reply__B85_
        ld   a, [serial_link_rx_data__RAM_D021_]
        ret


; Waits for a byte from Serial IO with a timeout (25 msec)
;
; - Returns serial transfer success(0x01)/failure(0x00) in: A
serial_io_wait_receive__B8F_:
    ld   a, SERIAL_STATUS_RESET ; $00
    ld   [serial_link_status__RAM_D022_], a
    call serial_io_enable_receive_byte__A17_
    call serial_io_wait_for_transfer_w_timeout_25msec__BC5_
    ld   a, [serial_link_status__RAM_D022_]
    ret


; Waits for a byte from Serial IO with a timeout (~50 msec)
;
; - Returns serial transfer success(0x01)/failure(0x00) in: A
serial_io_wait_receive_w_timeout_50msec__B8F_:
    push bc
    ld   a, SERIAL_STATUS_RESET ; $00
    ld   [serial_link_status__RAM_D022_], a
    call serial_io_enable_receive_byte__A17_

    ld   b, $02
    loop_wait_reply__BA9_:
        call serial_io_wait_for_transfer_w_timeout_25msec__BC5_
        ld   a, [serial_link_status__RAM_D022_]
        and  a
        jr   nz, serial_done__BB8_
        dec  b
        jr   nz, loop_wait_reply__BA9_

        ld   a, [serial_link_status__RAM_D022_]
    serial_done__BB8_:
        pop  bc
        ret


; Sets the serial system status to OK (making some assumptions right now)
serial_system_status_set_fail__BBA_:
    push af
    ld   a, [serial_system_status__RAM_D024_]
    set  SYS_REPLY__BIT_BOOT_FAIL, a  ; 0, a
    ld   [serial_system_status__RAM_D024_], a
    pop  af
    ret

; Waits for a serial transfer to complete with a timeout
;
; - Timeout is about ~ 25 msec or 1.5 frames (0.25 * 0x64)
; - Serial ISR populates status var if anything was received (serial_int_handler__00CE_)
;
serial_io_wait_for_transfer_w_timeout_25msec__BC5_:
    push bc
    ld   b, $64
    loop_wait_reply__BC8_:
        call delay_quarter_msec__BD6_
        ld   a, [serial_link_status__RAM_D022_]
        and  a
        jr   nz, serial_done__BD4_
        dec  b
        jr   nz, loop_wait_reply__BC8_
    serial_done__BD4_:
        pop  bc
        ret

; Delay loop to wait 0.25 msec (used by serial link function, maybe others)
;
; TODO: Is this a long enough delay? Given so far it sends with serial speed 8192 Hz, 1 KB/s
;
; Delay approx: (1000 msec / 59.7275 GB FPS) * (1058 M-Cycles delay / 70224 one frame M-Cycles) = 0.25 msec
; or (1058 M-Cycles delay / 456 M-Cycles per line) = ~2.3 lines
delay_quarter_msec__BD6_:
    push af
    ld   a, $46
    _loop_delay_BD9_:
        push af
        ld   a, [serial_link_tx_data__RAM_D023_] ; Why? A useless read? Or is something else going on
        pop  af
        dec  a
        jr   nz, _loop_delay_BD9_
        pop  af
        ret

; Data from BE3 to C8C (170 bytes)
; Some kind of table with values incrementing from 0x0022 -> 0x07FF
_DATA_BE3_:
db $00, $22, $00, $97, $00, $FF, $01, $72, $01, $C4, $02, $1F, $02, $80, $02, $C8
db $03, $15, $03, $5A, $03, $98, $03, $D8, $04, $19, $04, $52, $04, $86, $04, $B9
db $04, $E7, $05, $14, $05, $3D, $05, $64, $05, $8B, $05, $AD, $05, $CF, $05, $EE
db $06, $0D, $06, $28, $06, $43, $06, $5B, $06, $74, $06, $89, $06, $9F, $06, $B2
db $06, $C5, $06, $D7, $06, $E7, $06, $F7, $07, $06, $07, $14, $07, $21, $07, $2E
db $07, $3A, $07, $45, $07, $51, $07, $59, $07, $63, $07, $6C, $07, $74, $07, $7C
db $07, $83, $07, $8A, $07, $91, $07, $97, $07, $9D, $07, $A3, $07, $A8, $07, $AD
db $07, $B2, $07, $B6, $07, $BA, $07, $BE, $07, $CB, $07, $CE, $07, $D1, $07, $D4
db $07, $D6, $07, $D9, $07, $DB, $07, $DD, $07, $DF, $07, $E1, $07, $E3, $07, $E4
db $07, $E6, $07, $E8, $07, $E9, $07, $EA, $07, $EB, $07, $EC, $07, $EE, $07, $EF
db $07, $F0, $07, $F1, $07, $F2, $07, $F3, $07, $FF

; - TODO: Maybe, among other things, reading for keyboard input
maybe_input_read_keys__C8D_:
    ; Save current interrupt enables then turn all off
    ldh  a, [rIE]
    ld   [_rIE_saved_serial__RAM_D078_], a
    xor  a
    ldh  [rIE], a
    ; TODO ... ? Make a request for ??
    ld   a, $00  ; ?? Same or different tan SYS_CMD_INIT_SEQ_REQUEST
    ld   [serial_link_tx_data__RAM_D023_], a
    call serial_io_send_byte__B64_
    call serial_io_wait_receive__B8F_

    ; Fail if serial RX timed out(z), if successful(nz) continue
    and  a
    jr   z, maybe_input_req_key_failed_so_send04__CB9_
    ; Fail if RX byte was zero
    ld   a, [serial_link_rx_data__RAM_D021_]
    cp   $00  ; TODO: Some kind of invalid, or no key ready yet SYS_REPLY or SYS_KEY
    jr   z, maybe_input_req_key_failed_so_send04__CB9_
    ; TODO ...
    cp   $0E  ; TODO: does this mean another serial byte is incoming?
    jr   z, _LABEL_CB0_
    jr   nc, maybe_input_req_key_failed_so_send04__CB9_

    ; TODO: Save last RX byte and wait for another
    _LABEL_CB0_:
        ld   [_RAM_D026_], a
        call serial_io_wait_receive__B8F_
        and  a
        jr   nz, _LABEL_CC8_

    maybe_input_req_key_failed_so_send04__CB9_:
        ld   a, SYS_KEY_MAYBE_INVALID_OR_NODATA  ; $FF
        ld   [maybe_input_key_new_pressed__RAM_D025_], a
        ld   a, $04  ; TODO: Maybe a failed/reset/cancel input system command SYS_CMD
        ld   [serial_link_tx_data__RAM_D023_], a
        call serial_io_send_byte__B64_
        jr   restore_int_enables_call_TODO_and_return__D06_


    ; TODO: Maybe extended reading of keyboard input
    _LABEL_CC8_:
        ; Save RX input byte #2
        ; Also add and save it to _RAM_D026_
        ; - (Code above loaded $0E into _RAM_D026_)
        ld   a, [serial_link_rx_data__RAM_D021_]
        ld   [maybe_input_second_rx_byte__RAM_D027_], a
        ld   hl, _RAM_D026_
        add  [hl]
        ld   [hl], a
        ; Wait for RX input byte #3
        ; If successful, save it
        ; Also add and save it to _RAM_D026_
        call serial_io_wait_receive__B8F_
        and  a
        jr   z, maybe_input_req_key_failed_so_send04__CB9_
        ld   a, [serial_link_rx_data__RAM_D021_]
        ld   [maybe_input_key_new_pressed__RAM_D025_], a
        ld   hl, _RAM_D026_
        add  [hl]
        ld   [_RAM_D026_], a
        ; Wait for RX input byte #4
        ; If successful, save it
        call serial_io_wait_receive__B8F_
        and  a
        jr   z, maybe_input_req_key_failed_so_send04__CB9_
        ld   a, [serial_link_rx_data__RAM_D021_]
        ld   hl, _RAM_D026_
        add  [hl]
        jr   nz, maybe_input_req_key_failed_so_send04__CB9_

        ; TODO: Send a command byte. Something like DONE or ACK for a SYS_CMD?
        ld   a, $01
        ld   [serial_link_tx_data__RAM_D023_], a
        call serial_io_send_byte__B64_
        call _LABEL_D0F_
        ld   a, [maybe_input_key_new_pressed__RAM_D025_]
        ld   [_RAM_D181_], a

    restore_int_enables_call_TODO_and_return__D06_:
        ld   a, [_rIE_saved_serial__RAM_D078_]
        ldh  [rIE], a
        call _LABEL_DFC_
        ret


; TODO: Maybe lots of special input handling and processing below

_LABEL_D0F_:
    ld   a, [maybe_input_second_rx_byte__RAM_D027_]
    bit  0, a
    jp   nz, _LABEL_DD5_
    ld   a, [maybe_input_second_rx_byte__RAM_D027_]
    bit  3, a
    jr   z, _LABEL_D24_
    ld   a, $2F
    ld   [maybe_input_key_new_pressed__RAM_D025_], a
    ret

_LABEL_D24_:
    ld   a, [maybe_input_key_new_pressed__RAM_D025_]
    and  a
    jp   z, _LABEL_DCF_
    bit  7, a
    jp   z, _LABEL_DBD_
    cp   $F0
    jp   nc, _LABEL_DC5_
    res  7, a
    ld   hl, $0EBF
    call _LABEL_486E_
    ld   a, [hl]
    ld   [maybe_input_key_new_pressed__RAM_D025_], a
    ld   b, a
    ld   a, [maybe_input_second_rx_byte__RAM_D027_]
    and  $0E
    jr   z, _LABEL_DC5_
    ld   a, [maybe_input_second_rx_byte__RAM_D027_]
    and  $06
    jr   z, _LABEL_DC5_
    bit  2, a
    jr   nz, _LABEL_D68_
    ld   a, b
    bit  7, a
    jr   z, _LABEL_DC5_
    cp   $A1
    jr   c, _LABEL_DC5_
    cp   $BE
    jr   nc, _LABEL_DC5_
_LABEL_D61_:
    res  5, a
    ld   [maybe_input_key_new_pressed__RAM_D025_], a
    jr   _LABEL_DC5_

_LABEL_D68_:
    bit  1, a
    jr   z, _LABEL_D86_
    ld   a, b
    cp   $43
    jr   nz, _LABEL_D78_
    ld   a, $70
    ld   [maybe_input_key_new_pressed__RAM_D025_], a
    jr   _LABEL_DC5_

_LABEL_D78_:
    bit  7, a
    jr   z, _LABEL_D86_
    cp   $A1
    jr   c, _LABEL_D86_
    cp   $BE
    jr   nc, _LABEL_D86_
    jr   _LABEL_DC5_

_LABEL_D86_:
    ld   a, b
    cp   $43
    jr   nz, _LABEL_D92_
    ld   a, $70
    ld   [maybe_input_key_new_pressed__RAM_D025_], a
    jr   _LABEL_DC5_

_LABEL_D92_:
    bit  7, a
    jr   z, _LABEL_DAF_
    cp   $A1
    jr   c, _LABEL_DA0_
    cp   $BE
    jr   nc, _LABEL_DA0_
    jr   _LABEL_D61_

_LABEL_DA0_:
    cp   $C1
    jr   c, _LABEL_DAF_
    cp   $CA
    jr   nc, _LABEL_DAF_
    sub  $5E
    ld   [maybe_input_key_new_pressed__RAM_D025_], a
    jr   _LABEL_DC5_

_LABEL_DAF_:
    ld   c, $0B
    ld   hl, _DATA_F2F_ ; _DATA_F2F_ = $0F2F
_LABEL_DB4_:
    ldi  a, [hl]
    cp   b
    jr   z, _LABEL_DC1_
    inc  hl
    dec  c
    jr   nz, _LABEL_DB4_
    ret

_LABEL_DBD_:
    ld   a, $F6
    jr   _LABEL_DC2_

_LABEL_DC1_:
    ldi  a, [hl]
_LABEL_DC2_:
    ld   [maybe_input_key_new_pressed__RAM_D025_], a
_LABEL_DC5_:
    ld   a, [maybe_input_key_new_pressed__RAM_D025_]
    cp   $F0
    ret  nc
    ld   [_RAM_D181_], a
    ret

_LABEL_DCF_:
    ld   a, SYS_KEY_MAYBE_INVALID_OR_NODATA  ; $FF
    ld   [maybe_input_key_new_pressed__RAM_D025_], a
    ret

_LABEL_DD5_:
    ld   a, [_RAM_D181_]
    cp   SYS_KEY_UP_RIGHT  ; $CA
    jp   z, maybe_save_to_input__DF8_
    cp   SYS_KEY_DOWN_RIGHT  ; $CB
    jp   z, maybe_save_to_input__DF8_
    cp   SYS_KEY_DOWN_LEFT  ; $CC
    jp   z, maybe_save_to_input__DF8_
    cp   SYS_KEY_UP_LEFT  ; $CD
    jp   z, maybe_save_to_input__DF8_
    cp   $41
    jr   c, maybe_save_to_input__DF8_
    cp   $18
    jr   nc, maybe_no_match_found__DF6_
    jr   maybe_save_to_input__DF8_

    maybe_no_match_found__DF6_:
        ld   a, SYS_KEY_MAYBE_INVALID_OR_NODATA  ; $FF
    maybe_save_to_input__DF8_:
        ld   [maybe_input_key_new_pressed__RAM_D025_], a
        ret

_LABEL_DFC_:
    ld   a, [maybe_input_key_new_pressed__RAM_D025_]
    cp   $65
    jr   nz, _LABEL_E0A_
    ld   a, $9F
    ld   [maybe_input_key_new_pressed__RAM_D025_], a
    jr   _LABEL_E37_

_LABEL_E0A_:
    cp   $2B
    jr   nz, _LABEL_E1C_
    ld   a, [maybe_input_second_rx_byte__RAM_D027_]
    bit  2, a
    jr   z, _LABEL_E37_
    ld   a, $D2
    ld   [maybe_input_key_new_pressed__RAM_D025_], a
    jr   _LABEL_E37_

_LABEL_E1C_:
    ld   a, [maybe_input_key_new_pressed__RAM_D025_]
    cp   $DC
    jr   nz, _LABEL_E37_
    ld   a, [maybe_input_second_rx_byte__RAM_D027_]
    ld   c, a
    and  $02
    sla  a
    ld   b, a
    ld   a, c
    and  $04
    xor  b
    jr   z, _LABEL_E37_
    ld   a, $D5
    ld   [maybe_input_key_new_pressed__RAM_D025_], a
_LABEL_E37_:
    ld   a, [maybe_input_key_new_pressed__RAM_D025_]
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
    ld   a, SYS_KEY_MAYBE_INVALID_OR_NODATA  ; $FF
    ld   [maybe_input_key_new_pressed__RAM_D025_], a
    ret

_LABEL_E70_:
    ld   a, [maybe_input_key_new_pressed__RAM_D025_]
    cp   SYS_KEY_MAYBE_INVALID_OR_NODATA  ; $FF
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
    ld   a, [maybe_input_key_new_pressed__RAM_D025_]
    ld   b, a
_LABEL_E8B_:
    ld   a, c
    cp   b
    jr   z, _LABEL_E6A_
    ldi  a, [hl]
    cp   b
    jr   nz, _LABEL_E9D_
    ld   a, [hl]
    ld   [maybe_input_key_new_pressed__RAM_D025_], a
_LABEL_E97_:
    xor  a
    ld   [_RAM_D226_], a    ; _RAM_D226_ = $D226
    ret

; Maybe end of some input keyboard handling


; TODO: Maybe this is all data below
_LABEL_E9C_:
    inc  hl
_LABEL_E9D_:
    inc  hl
    jr   _LABEL_E4C_

_LABEL_EA0_:
    dec  hl
    and  c
; Data from EA2 to EA2 (1 bytes)
db $DD

_LABEL_EA3_:
    dec  hl
    add  c
    sub  $2B
    and  l
    sbc  $2B
    add  l
    rst  $10    ; _RST_10_
    dec  hl
    xor  c
    rst  $18    ; _RST_18_
    dec  hl
    adc  c
    ret  c
    dec  hl
    xor  a
    ldh  [rAUD3LEN], a
    adc  a
    reti

_LABEL_EB8_:
    dec  hl
    or   l
    pop  hl
    dec  hl
    sub  l
    jp   c, _LABEL_3000_
    ldi  a, [hl]
    dec  l
    cpl
    ld   sp, $B1C1
    and  c
    ldd  [hl], a
    jp   nz, $B3B7
    inc  sp
    jp   $A4A5

_LABEL_ECF_:
    inc  [hl]
    call nz, $A6B2
    dec  [hl]
    push bc
    or   h
    and  a
    ld   [hl], $C6
    cp   c
    xor  b
    scf
    rst  $00    ; _RSTL_0_
    or   l
    xor  d
    jr   c, @ - 54
    xor  c
    xor  e
    add  hl, sp
    ret

_LABEL_EE5_:
    xor  a
    xor  h
    ldd  a, [hl]
    ret  nz
    or   b
    call c, _LABEL_6E3B_
    dec  hl
    cp   l
    rst  $38    ; _RST_38_
    pop  de
; Data from EF1 to EF2 (2 bytes)
db $D3, $DB

; _LABEL_EF3_:
;     rst  $38    ; _RST_38_
;     inc  l
;     ld   l, $FF
;     cp   d
;     cp   [hl]
;     ld   bc, $B800
;     ld   [hl], a
;     inc  bc
;     ld   [bc], a
;     and  e
;     ld   b, h
;     ldd  a, [hl]
;     inc  b
;     or   [hl]
;     ld   b, l
;     ld   b, $05
;     and  d
;     ld   b, [hl]
;     ld   [$AE07], sp
;     ld   b, c
;     ld   a, [bc]
;     add  hl, bc
;     xor  l
;     ld   b, d
;     cpl
;     dec  bc
;     sbc  a, [hl]
;     ld   b, e
;     dec  c
;     inc  c
;     ld   [hl], h
;     call z, $0E0F   ; Possibly invalid
;     bit  0, b
;     cpl
;     stop
;     rl   d
;     ld   de, $3ECD
;     inc  d
; ; Data from F26 to F2E (9 bytes)
; db $13, $3D, $CE, $16, $15, $CA, $3F, $3A, $17

; Data from EF3 to F2E
_DATA_EF3_:
db $FF, $2C, $2E, $FF, $BA, $BE, $01, $00, $B8, $77, $03, $02, $A3, $44, $3A, $04
db $B6, $45, $06, $05, $A2, $46, $08, $07, $AE, $41, $0A, $09, $AD, $42, $2F, $0B
db $9E, $43, $0D, $0C, $74, $CC, $0F, $0E, $CB, $40, $2F, $10, $3C, $CB, $12, $11
db $CD, $3E, $14, $13, $3D, $CE, $16, $15, $CA, $3F, $3A, $17

; Data from F2F to 2FFF (8401 bytes)
_DATA_F2F_:
db $9E, $75, $74, $73, $CB, $A0, $DB, $D4, $D3, $6F, $C0, $6C, $6E, $BF, $D1, $D0
db $77, $76, $41, $47, $42, $48,
_DATA_F45_:
db $1F, $04, $24, $08, $1F, $04, $21, $04, $1F, $04
db $1D, $04, $1F, $04, $1C, $04, $1F, $04, $24, $08, $1F, $04, $21, $04, $1F, $04
db $1D, $04, $1F, $04, $1C, $04, $1F, $04, $24, $08, $1F, $04, $21, $04, $1F, $04
db $1D, $04, $1F, $04, $1C, $04, $1F, $04, $24, $08, $1F, $04, $21, $04, $1F, $04
db $1D, $04, $1F, $04, $1C, $08, $FF, $24, $04, $24, $04, $28, $04, $2B, $04, $2B
db $08, $2B, $04, $2B, $08, $28, $04, $28, $08, $24, $04, $24, $04, $28, $04, $2B
db $04, $2B, $08, $2B, $04, $2B, $08, $29, $04, $29, $08, $23, $04, $23, $04, $26
db $04, $29, $04, $2D, $08, $2D, $04, $2D, $08, $29, $04, $29, $08, $23, $04, $23
db $04, $26, $04, $29, $04, $2D, $08, $2D, $04, $2D, $08, $28, $04, $28, $0C, $FF
; Extra bytes from somewhere?
db $1C, $04, $1D, $04, $1F, $08, $24, $08, $23, $04, $23, $04, $21, $04, $21, $04
db $1F, $04, $1F, $04, $21, $04, $23, $04, $24, $04, $1F, $04,
db $1C, $04, $1D, $04
db $1F, $08, $24, $08, $23, $04, $23, $04, $21, $04, $21, $04, $1F, $04, $1F, $04
db $21, $04, $23, $04, $24, $08, $FF, $26, $04, $28, $08, $28, $04, $2A, $04, $28
db $04, $2A, $04, $2B, $04, $26, $08, $54, $04, $26, $04, $26, $04, $28, $04, $28
db $04, $28, $04, $2A, $04, $28, $04, $2A, $04, $2B, $04, $26, $08, $54, $04, $26
db $04, $26, $04, $24, $04, $24, $04, $24, $04, $28, $04, $26, $04, $24, $04, $23
db $0C, $26, $04, $2B, $04, $2D, $04, $2F, $08, $2F, $04, $2D, $08, $2D, $04, $2B
db $0C, $FF, $1F, $09, $21, $03, $1F, $06, $1C, $12, $1F, $09, $21, $03, $1F, $06
db $1C, $12, $26, $0C, $26, $06, $23, $12, $24, $0C, $24, $06, $1F, $12, $21, $0C
db $21, $06, $24, $09, $23, $03, $21, $06, $1F, $09, $21, $03, $1F, $06, $1C, $12
db $21, $0C, $21, $06, $24, $09, $23, $03, $21, $06, $1F, $09, $21, $03, $1F, $06
db $1C, $12, $26, $0C, $26, $06, $29, $09, $26, $03, $23, $06, $24, $12, $28, $12
db $24, $09, $1F, $03, $1C, $06, $1F, $09, $1D, $03, $1A, $06, $18, $12, $FF, $24
db $04, $24, $02, $24, $02, $24, $04, $23, $02, $24, $02, $26, $06, $23, $02, $1F
db $08, $26, $04, $26, $02, $28, $02, $29, $04, $28, $02, $26, $02, $28, $06, $26
db $02, $24, $08, $24, $04, $24, $02, $24, $02, $24, $04, $23, $02, $24, $02, $26
db $06, $23, $02, $1F, $08, $26, $04, $26, $02, $28, $02, $29, $04, $28, $02, $26
db $02, $28, $06, $26, $02, $24, $08, $FF, $1A, $02, $1F, $02, $1F, $02, $1F, $02
db $23, $02, $1F, $04, $1F, $04, $23, $02, $1F, $02, $23, $02, $1F, $02, $1A, $04
db $54, $02, $1A, $02, $1F, $02, $1F, $02, $1F, $02, $23, $02, $1F, $04, $1F, $04
db $1A, $02, $1A, $02, $1A, $02, $1A, $02, $1F, $04, $54, $02, $1A, $02, $1F, $04
db $21, $04, $1F, $04, $54, $02, $1A, $02, $1F, $02, $1F, $02, $1F, $02, $21, $02
db $1F, $04, $54, $02, $1A, $02, $1F, $02, $1F, $02, $1F, $02, $1F, $02, $21, $04
db $21, $02, $21, $02, $1A, $04, $1C, $02, $1E, $02, $1F, $04, $FF, $24, $03, $23
db $01, $23, $04, $54, $04, $23, $03, $24, $01, $24, $04, $54, $04, $24, $03, $28
db $01, $2B, $04, $2B, $03, $2D, $01, $2B, $03, $29, $01, $28, $04, $24, $04, $24
db $03, $23, $01, $23, $04, $54, $04, $23, $03, $24, $01, $24, $04, $54, $04, $24
db $03, $28, $01, $2B, $04, $2B, $04, $2B, $04, $24, $0C, $FF, $28, $04, $28, $02
db $28, $02, $29, $02, $29, $02, $29, $02, $2B, $04, $2B, $02, $54, $0C, $28, $04
db $28, $02, $28, $02, $29, $02, $29, $02, $29, $02, $2B, $06, $54, $0E, $29, $02
db $29, $02, $29, $02, $29, $04, $29, $04, $28, $04, $24, $0C, $54, $02, $29, $02
db $29, $02, $29, $02, $29, $04, $29, $04, $28, $04, $24, $04, $24, $04, $24, $04
db $26, $04, $23, $04, $26, $04, $29, $04, $28, $04, $28, $04, $24, $04, $21, $04
db $1F, $04, $FF,
_DATA_11F2_:
db $00, $00, $38, $38, $65, $45, $A6, $C6, $A8, $C8, $93, $F3, $67
db $64, $2F, $28, $00, $00, $7E, $7E, $8F, $81, $3F, $3C, $F3, $C3, $F0, $00, $E0
db $00, $C0, $00, $00, $00, $1C, $1C, $AA, $B2, $E9, $71, $F3, $1D, $F9, $CF, $3E
db $26, $9C, $94, $4F, $48, $5F, $50, $9F, $90, $BF, $A0, $BE, $A0, $BC, $90, $7C
db $50, $7F, $48, $81, $01, $42, $42, $24, $24, $10, $18, $08, $18, $00, $10, $00
db $20, $00, $40, $1E, $12, $0E, $0A, $0F, $09, $07, $05, $07, $05, $0F, $09, $0E
db $0A, $1E, $12, $3E, $28, $3C, $24, $1F, $13, $0D, $08, $06, $06, $05, $05, $38
db $38, $38, $38, $00, $80, $00, $00, $00, $00, $C3, $C3, $FC, $3C, $FF, $81, $7E
db $7E, $00, $00, $1C, $14, $2C, $24, $D8, $C8, $30, $10, $E0, $60, $A0, $A0, $1C
db $1C, $1C, $1C, $0A, $0A, $1A, $1F, $1A, $1A, $10, $10, $10, $13, $10, $10, $10
db $10, $10, $10, $AA, $AA, $AA, $FF, $AA, $AA, $00, $00, $00, $FF, $00, $00, $7F
db $7F, $7F, $7F, $A8, $A8, $AE, $FC, $AE, $AC, $06, $04, $06, $E4, $06, $04, $86
db $84, $86, $84, $10, $10, $11, $10, $13, $10, $11
ds 9, $10
db $61, $61, $03, $03, $C7, $07, $8E, $0E, $9C, $1C, $38, $38, $38, $38, $38, $38
db $86, $84, $06, $04, $46, $04, $66, $04, $66, $04, $E6, $04, $E6, $04, $C6, $04
db $10, $10, $20, $27, $20, $20, $23, $20, $60, $60, $FF, $FF, $00, $00, $00, $00
db $00, $00, $00, $FF, $00, $00, $C7, $00, $00, $00, $FF, $FF, $00, $00, $00, $00
db $0C, $08, $0C, $E8, $0C, $08, $8C, $08, $18, $10, $F8, $F0, $00, $00, $00, $00
db $7F, $7F, $80, $C0, $80, $CF, $80, $CF, $80, $C8, $80, $C0, $80, $C7, $C7, $B8
db $FF, $FF, $1F, $20, $3F, $C0, $3F, $C3, $3F, $43, $1C, $22, $08, $14, $08, $94
db $FE, $6E, $FF, $61, $FF, $01, $FF, $FD, $FF, $FD, $01, $03, $F1, $61, $F1, $69
db $FF, $80, $DF, $A0, $8E, $D1, $8E, $CC, $CC, $AC, $FC, $8C, $FF, $FF, $FF, $FF
db $01, $88, $39, $B0, $39, $38, $1D, $1D, $3F, $0F, $3F, $47, $FF, $8F, $FD, $9D
db $99, $07, $FF, $61, $F7, $E9, $C3, $C5, $81, $83, $01, $39, $F9, $85, $F9, $C5
db $FF, $8C, $FF, $8C, $FF, $8C, $FF, $80, $FF, $83, $FF, $83, $FF, $80, $7F, $7F
db $F9, $38, $F9, $30, $F8, $04, $F8, $04, $FC, $E2, $FE, $E1, $FF, $00, $FF, $FF
db $F9, $E5, $F9, $65, $F1, $09, $01, $71, $01, $03, $03, $05, $07, $F9, $FE, $FE
db $00, $00, $07, $07, $06, $19, $1F, $20, $0F, $20, $61, $44, $65, $42, $65, $42
db $00, $00, $00, $00, $C0, $C0, $60, $E0, $A0, $60, $D0, $30, $DF, $3F, $D8, $30
ds 12, $00
db $FE, $FE, $02, $02, $63, $44, $67, $40, $6F, $40, $60, $4F, $61, $50, $67, $77
db $3B, $38, $13, $10, $DD, $35, $D8, $30, $DF, $3F, $78, $B0, $B8, $70, $F8, $30
db $F8, $E0, $E0, $40, $52, $52, $02, $02, $FA, $FA, $02, $02, $02, $02, $02, $02
db $7E, $7E, $44, $44, $17, $14, $17, $14, $17, $14, $1F, $10, $1F, $11, $0E, $0A
db $04, $04, $00, $00, $E0, $40, $E0, $80, $C0, $80, $FF, $FF, $80, $80, $00, $00
db $00, $00, $00, $00, $48, $48, $50, $50, $60, $60, $C0, $C0, $00, $00, $00, $00
db $00, $00, $00, $00, $FF, $00, $FF, $00, $FF, $07, $FF, $05, $FF, $FD, $83, $83
db $83, $82, $9B, $92, $80, $80, $80, $80, $FF, $7F, $C0, $40, $CD, $4D, $E0, $E0
db $FF, $3F, $E0, $20, $00, $00, $00, $00, $FC, $FC, $04, $04, $64, $64, $04, $04
db $F4, $F4, $04, $04, $9B, $9A, $87, $86, $81, $81, $99, $91, $99, $98, $81, $81
db $87, $87, $FF, $F9, $E0, $20, $F0, $20, $D0, $00, $F8, $78, $FC, $FC, $CC, $CC
db $80, $80, $80, $80
ds 16, $04
db $FF, $05, $FF, $04, $FF, $04, $FF, $04, $FF, $04, $FF, $07, $FF, $00, $FF, $00
db $CD, $CD, $FD, $FD, $F9, $79, $C1, $01, $F1, $01, $FF, $FF, $FF, $00, $F0, $00
db $FC, $FC, $0C, $08, $18, $10, $30, $20, $60, $40, $C0, $80, $80, $00, $00, $00
db $FF, $07, $FF, $01, $FF, $0F, $FF, $11, $EF, $2F, $C0, $40, $99, $99, $A4, $26
db $FF, $1C, $FF, $22, $FF, $02, $FF, $0D, $FF, $81, $3F, $00, $9F, $88, $4F, $40
db $FF, $00, $FF, $40, $FF, $C8, $FF, $4C, $FF, $EA, $FF, $48, $FF, $18, $FF, $38
db $C4, $46, $C4, $46, $CD, $4F, $DD, $5F, $DF, $5F, $C6, $46, $E6, $26, $BC, $18
db $2F, $2F, $28, $28, $2E, $2E, $AF, $A1, $AF, $A1, $2E, $22, $4C, $44, $88, $88
db $FF, $B0, $FF, $C0, $7F, $60, $3F, $30, $9F, $9C, $A3, $A2, $47, $46, $89, $89
db $9E, $00, $A4, $20, $C0, $40, $C0, $C0, $60, $20, $30, $10, $9F, $8F, $C0, $C0
db $08, $08, $49, $49, $27, $26, $36, $32, $46, $42, $8F, $89, $1F, $19, $3F, $3C
db $91, $91, $23, $22, $C5, $C4, $E9, $69, $73, $12, $1F, $0D, $0E, $02, $FC, $FC
db $00, $00, $08, $08, $27, $27, $18, $18, $50, $42, $20, $20, $20, $29, $60, $42
db $00, $00, $00, $00, $80, $80, $40, $40, $20, $A0, $2F, $AF, $1F, $07, $9F, $8F
ds 12, $00
db $C0, $C0, $C0, $C0, $40, $5D, $21, $23, $1C, $1C, $00, $00, $01, $1F, $01, $11
db $02, $03, $07, $03, $B1, $A6, $C3, $DC, $8F, $8C, $86, $84, $82, $82, $83, $82
db $81, $81, $C0, $C0, $20, $E0, $D0, $30, $E8, $18, $74, $0C, $3A, $06, $1F, $07
db $8D, $09, $F9, $91, $0C, $04, $58, $08, $70, $50, $60, $60, $00, $00, $00, $00
db $00, $00, $00, $00, $40, $40, $60, $40, $28, $28, $18, $18, $18, $10, $00, $00
db $00, $00, $00, $00, $7B, $61, $3E, $22, $1C, $1C
ds 12, $00
db $1F, $1F, $20, $20, $57, $40, $43, $40, $53, $40, $5F, $43, $5F, $42, $00, $00
db $FF, $FF, $00, $00, $FF, $00, $FF, $00, $FF, $00, $FF, $C7, $FF, $24, $00, $00
db $F8, $F8, $04, $04, $FA, $02, $FA, $02, $FA, $02, $FA, $82, $7A, $42, $5F, $43
db $5F, $42, $5F, $42, $5F, $43, $53, $40, $5F, $40, $20, $20, $1F, $1F, $FF, $C4
db $FF, $27, $FF, $24, $FF, $C4, $FF, $00, $FF, $00, $FF, $00, $00, $00, $FA, $42
db $EA, $82, $EA, $02, $82, $02, $8A, $02, $FA, $02, $04, $04, $F8, $F8, $06, $06
db $1F, $1F, $30, $30, $7B, $5B, $70, $40, $7F, $40, $7F, $7F, $00, $00, $00, $00
db $FF, $FF, $00, $00, $6D, $6D, $00, $00, $FF, $00, $FF, $FF, $00, $00, $60, $60
db $F8, $F8, $0C, $0C, $B2, $B2, $02, $02, $FE, $02, $FE, $FE, $00, $00, $FF, $00
db $FF, $04, $DF, $06, $CF, $05, $DF, $0C, $DF, $1C, $9F, $18, $1F, $00, $FF, $00
db $FF, $07, $F9, $1E, $E0, $38, $D0, $60, $D4, $60, $A6, $C0, $A5, $C0, $FF, $00
db $FF, $FC, $FF, $04, $7F, $04, $7F, $44, $7F, $64, $7F, $54, $7F, $44, $3F, $03
db $FC, $07, $F9, $1E, $E6, $38, $E8, $30, $D0, $60, $E0, $40, $C4, $78, $44, $80
db $C5, $01, $07, $03, $0C, $00, $1C, $00, $38, $00, $01, $00, $0C, $03, $FE, $C4
db $CF, $D4, $AF, $94, $66, $1C, $06, $3C, $84, $1C, $85, $7C, $05, $FC, $FF, $7F
db $D5, $55, $D5, $55, $C0, $40, $7F, $7F, $F8, $00, $34, $00, $06, $00, $FF, $FF
db $55, $55, $55, $55, $00, $00, $FF, $FF, $71, $00, $06, $00, $08, $00, $FC, $FC
db $54, $54, $54, $54, $06, $04, $FE, $FC, $FC, $00, $60, $00, $00, $00, $00, $00
db $FF, $FF, $C0, $C0, $BF, $BF, $A1, $A1, $A9, $A1, $AD, $A1, $A1, $A1, $00, $00
db $C0, $C0, $C0, $C0, $FF, $7F, $E0, $40, $FA, $5A, $E0, $40, $FF, $7F, $00, $00
db $00, $00, $00, $00, $FE, $FE, $02, $02, $B3, $B2, $03, $02, $F3, $F2, $BF, $BF
db $FF, $C0, $80, $FF, $FF, $FF, $1E, $1E, $EC, $EC, $34, $2C, $B4, $2C, $60, $40
db $E0, $C0, $60, $C0, $FE, $FE, $06, $06, $FF, $FA, $0F, $0A, $6F, $0A, $03, $02
db $03, $02, $03, $02, $03, $02, $03, $02, $03, $02, $03, $02, $03, $02, $B5, $2D
db $35, $2D, $F5, $ED, $F6, $1E, $FF, $FF, $EF, $20, $3F, $3F, $0F, $00, $4F, $0A
db $0F, $0A, $FF, $FA, $FF, $06, $FF, $FE, $FF, $00, $FF, $FF, $FF, $00, $FF, $FE
db $87, $84, $8C, $88, $98, $90, $B0, $A0, $E0, $C0, $C0, $80, $C0, $00, $FF, $F0
db $8F, $8E, $81, $81, $A0, $A0, $9C, $9C, $A3, $A3, $9C, $9C, $83, $83, $FF, $01
db $FE, $0E, $F0, $30, $C0, $C0, $03, $03, $07, $07, $8F, $8F, $1E, $1E, $FF, $FE
db $07, $02, $07, $02, $03, $02, $F3, $F0, $FB, $F8, $FF, $FC, $1F, $1E, $A0, $A0
db $9C, $9C, $83, $83, $A0, $A0, $9C, $9C, $83, $83, $80, $80, $80, $80, $8E, $8E
db $0F, $0F, $07, $07, $87, $87, $20, $20, $20, $20, $20, $20, $21, $21, $0F, $0E
db $0F, $0E, $0F, $0E, $0F, $0E, $1D, $1C, $3B, $38, $F3, $F0, $C3, $C2, $80, $80
db $80, $80, $83, $80, $F0, $F0, $FE, $1E, $FF, $01, $FF, $00, $FF, $00, $21, $21
db $0C, $00, $50, $00, $61, $01, $47, $03, $0F, $0B, $FF, $71, $FF, $00, $C3, $C2
db $07, $02, $07, $02, $FF, $C2, $FF, $EE, $FF, $E0, $FF, $C0, $FF, $00, $00, $00
db $3F, $3F, $40, $40, $4F, $4F, $50, $50, $50, $50, $50, $50, $50, $50, $00, $00
db $FF, $FF, $FF, $00, $FF, $FF, $1F, $00, $FB, $F0, $FB, $F0, $FB, $F0, $00, $00
db $F8, $F8, $FC, $04, $FC, $E4, $EC, $04, $EC, $04, $EC, $04, $EC, $04, $50, $50
db $57, $57, $53, $53, $51, $51, $70, $50, $70, $50, $70, $50, $70, $50, $FB, $F0
db $FB, $F3, $F8, $F1, $FD, $F3, $FB, $F6, $77, $7C, $3F, $38, $1F, $10, $EC, $04
db $EC, $C4, $EC, $84, $EC, $04, $EC, $04, $EC, $04, $EC, $04, $EC, $04, $70, $50
db $6F, $4F, $7F, $40, $7F, $7F, $2A, $2A, $2A, $2A, $3F, $3F, $00, $00, $7F, $00
db $FF, $FF, $FF, $00, $FF, $FF, $AA, $AA, $AA, $AA, $FF, $FF, $00, $00, $EC, $04
db $FC, $E4, $FC, $04, $FC, $FC, $A8, $A8, $A8, $A8, $F8, $F8
ds 12, $00
db $07, $07, $07, $07, $06, $06
ds 10, $00
db $FF, $FF, $FF, $FF
ds 12, $00
db $E0, $E0, $E0, $E0, $60, $60
ds 16, $06
ds 16, $00
ds 16, $60
db $06, $06, $07, $07, $07, $07
ds 12, $00
db $FF, $FF, $FF, $FF
ds 10, $00
db $60, $60, $E0, $E0, $E0, $E0
ds 10, $00
db $FF, $FF
ds 12, $81
db $FF, $FF, $FF, $FF, $81, $81, $81, $81, $FF, $81, $FF, $81, $81, $81, $81, $81
db $FF, $FF, $FF, $FF, $81, $81, $81, $81, $81, $FF, $81, $FF, $81, $81, $81, $81
db $FF, $FF, $FF, $FF, $81, $81, $81, $81, $FF, $FF, $FF, $FF, $81, $81, $81, $81
db $FF, $FF, $FF, $FF, $81, $81, $81, $81, $FF, $FF, $81, $81, $81, $81, $81, $81
db $FF, $FF, $FF, $FF, $81, $81, $81, $81, $FF, $FF, $FF, $FF, $81, $81, $81, $81
db $FF, $FF, $FF, $FF, $81, $81, $FF, $FF, $FF, $FF, $FF, $FF, $81, $81, $81, $81
db $FF, $FF, $FF, $FF, $81, $81, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $81, $81
db $FF, $FF, $00, $00, $00, $00, $00, $00, $1E, $1E, $21, $21, $4C, $4C, $42, $42
db $43, $43, $00, $00, $00, $00, $00, $00, $00, $00, $FC, $FC, $82, $82, $FC, $FC
db $90, $90, $04, $04, $03, $03, $44, $44, $23, $23, $10, $10, $0F, $0F, $00, $00
db $00, $00, $10, $10, $F0, $F0, $20, $20, $E0, $E0, $40, $40, $C0, $C0, $00, $00
db $00, $00, $00, $F8, $00, $E0, $00, $F0, $00, $B8, $00, $9C, $00, $0E, $00, $07
db $00, $03, $00, $C0, $00, $F0, $00, $68, $00, $74, $00, $3A, $00, $1D, $00, $0E
db $00, $07, $00, $C3, $00, $FF, $00, $66, $00, $5A, $00, $5A, $00, $66, $00, $FF
db $00, $C3, $F8, $F8, $E0, $E0, $F0, $F0, $B8, $B8, $9C, $9C, $0E, $0E, $07, $07
db $03, $03, $C0, $C0, $F0, $F0, $68, $68, $74, $74, $3A, $3A, $1D, $1D, $0E, $0E
db $07, $07, $C3, $C3, $FF, $FF, $66, $66, $5A, $5A, $5A, $5A, $66, $66, $FF, $FF
db $C3, $C3, $F8, $00, $E0, $00, $F0, $00, $B8, $00, $9C, $00, $0E, $00, $07, $00
db $03, $00, $C0, $00, $F0, $00, $68, $00, $74, $00, $3A, $00, $1D, $00, $0E, $00
db $07, $00, $C3, $00, $FF, $00, $66, $00, $5A, $00, $5A, $00, $66, $00, $FF, $00
db $C3, $00

; Data from 1A92 to 2669 (3032 bytes)
_DATA_1A92_:
db $C8, $C8, $C4
ds 14, $C5
db $C6, $C8, $C8, $C8, $C8, $C7, $00, $01, $02, $03, $04, $05, $06, $07, $08, $09
db $0A, $0B, $0C, $0D, $C9, $C8, $C8, $C8, $C8, $C7, $0E, $0F, $10, $11, $12, $13
db $14, $15, $16, $17, $18, $19, $1A, $1B, $C9, $C8, $C8, $C8, $C8, $C7, $1C, $1D
db $1E, $1F, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $C9, $C8, $C8, $C8
db $C8, $C7, $2A, $2B, $2C, $2D, $2E, $2F, $30, $31, $32, $33, $34, $35, $36, $37
db $C9, $C8, $C8, $C8, $C8, $C7, $38, $39, $3A, $3B, $3C, $3D, $3E, $3F, $40, $41
db $42, $43, $44, $45, $C9, $C8, $C8, $C8, $C8, $C7, $46, $47, $48, $49, $4A, $4B
db $4C, $4D, $4E, $4F, $50, $51, $52, $53, $C9, $C8, $C8, $C8, $C8, $C7, $54, $55
db $56, $57, $58, $59, $5A, $5B, $5C, $5D, $5E, $5F, $60, $61, $C9, $C8, $C8, $C8
db $C8, $C7, $62, $63, $64, $65, $66, $67, $68, $69, $6A, $6B, $6C, $6D, $6E, $6F
db $C9, $C8, $C8, $C8, $C8, $C7, $70, $71, $72, $73, $74, $75, $76, $77, $78, $79
db $7A, $7B, $7C, $7D, $C9, $C8, $C8, $C8, $C8, $C7, $7E, $7F, $80, $81, $82, $83
db $84, $85, $86, $87, $88, $89, $8A, $8B, $C9, $C8, $C8, $C8, $C8, $C7, $8C, $8D
db $8E, $8F, $90, $91, $92, $93, $94, $95, $96, $97, $98, $99, $C9, $C8, $C8, $C8
db $C8, $C7, $9A, $9B, $9C, $9D, $9E, $9F, $A0, $A1, $A2, $A3, $A4, $A5, $A6, $A7
db $C9, $C8, $C8, $C8, $C8, $C7, $A8, $A9, $AA, $AB, $AC, $AD, $AE, $AF, $B0, $B1
db $B2, $B3, $B4, $B5, $C9, $C8, $C8, $C8, $C8, $C7, $B6, $B7, $B8, $B9, $BA, $BB
db $BC, $BD, $BE, $BF, $C0, $C1, $C2, $C3, $C9, $C8, $C8, $C8, $C8, $CA
ds 14, $CB
db $CC, $C8, $C8, $C8, $C8, $C8, $C8, $C8, $D5, $D6, $D1, $C8, $C8, $C8, $D5, $D6
db $CE
ds 11, $C8
db $D7, $D8, $C8, $C8, $C8, $C8, $D7, $D8, $C8, $C8, $C8, $C8, $C8, $C8, $C8
ds 29, $00
db $FF, $FF, $FF
ds 29, $00
db $FF, $FF, $FF
ds 28, $00
db $FF, $FF, $2F, $1F
ds 28, $00
db $A0, $C0, $FF, $FF
ds 24, $00
db $E8, $F0, $7E, $FF, $17, $0F
ds 30, $00
db $F4, $F8, $BF, $7F
ds 22, $00
db $74, $78, $3F, $7F, $0B, $07
ds 30, $00
db $E0, $F0, $78, $FC, $0F, $1F
ds 18, $00
db $60, $70, $38, $7C, $0E, $1F, $03, $07, $01
ds 29, $00
db $C0, $E0, $F0, $F8, $1C, $3E, $07, $0F
ds 16, $00
db $30, $38, $1C, $3E, $07, $0F, $01, $03
ds 28, $00
db $80, $00, $E0, $C0, $60, $F0, $38, $7C, $0F, $1E, $03, $07
ds 12, $00
db $10, $18, $18, $1C, $0E, $0E, $03, $07, $01, $03
ds 30, $00
db $C0, $C0, $60, $F0, $38, $38, $0C, $1C, $06, $0E, $03, $03, $00, $00, $00, $00
db $00, $00, $00, $00, $08, $00, $08, $0C, $0C, $0E, $07, $07, $03, $01, $01
ds 27, $00
db $80, $00, $80, $C0, $C0, $E0, $60, $70, $30, $38, $18, $1C, $0C, $0E, $06, $07
db $03, $03, $00, $00, $00, $00, $00, $00, $00, $04, $06, $06, $07, $03, $03, $01
db $00, $01
ds 28, $00
db $80, $80, $80, $C0, $C0, $E0, $60, $70, $30, $38, $18, $1C, $0C, $0E, $06, $07
db $03, $03, $01, $01, $00, $00, $00, $00, $00, $02, $03, $03, $01, $03, $00, $01
ds 28, $00
db $80, $80, $C0, $C0, $40, $E0, $60, $70, $30, $70, $30, $38, $18, $1C, $0C, $0C
db $06, $0E, $06, $07, $03, $03, $01, $01
ds 35, $00
db $80, $80, $C0, $C0, $C0, $40, $E0, $60, $60, $20, $70, $30, $30, $10, $38, $18
db $18, $0C, $0C, $04, $0E, $06, $06, $02, $07, $03, $03, $01, $01
ds 33, $00
db $40, $40, $60, $60, $60, $20, $70, $30, $30, $10, $38, $18, $18, $18, $18, $08
db $1C, $0C, $0C, $04, $0E, $06, $06, $02, $07, $03, $03, $01, $03, $01, $01
ds 32, $00
db $10, $10, $10, $18, $18, $18, $18, $18, $08, $1C, $0C, $0C, $0C, $0C, $0C, $0C
db $04, $0E, $06, $06, $06, $06, $02, $07, $03, $03, $03, $03, $01, $03, $01, $01
ds 32, $00
db $0C, $0C, $0C, $0C, $0C, $0C, $06, $0C, $0C, $06, $06, $06, $06, $06, $06, $06
db $03, $06, $06, $03, $03, $03, $03, $03, $03, $03, $01, $03, $03, $01, $01, $01
ds 32, $00
db $07, $02, $07, $02, $06, $03, $07, $03, $07
ds 9, $03
db $01, $03, $03, $01, $03, $01, $03, $01, $03, $01, $01, $01, $01, $01
ds 32, $00
db $01, $03, $01, $03, $01, $03, $01, $03, $01, $03, $01, $03, $01, $03, $01, $03
db $01, $03, $01, $03, $01, $03, $01, $03, $01, $03, $01, $03, $01, $03, $01, $03
ds 16, $00
db $3F, $BF, $40, $40, $80, $80, $91, $91, $B2, $B2, $90, $90, $91, $91, $92, $92
db $E0, $EF, $10, $10, $08, $08, $88, $88, $4F, $4F, $48, $48, $90, $90, $13, $13
db $00, $FF, $00, $01, $00, $01, $00, $01, $FC, $FD, $02, $02, $01, $01, $19, $19
db $BB, $BB, $80, $80, $40, $40, $3F, $BF, $00, $80, $00, $80, $00, $80, $00, $FF
db $D4, $D4, $10, $10, $13, $13, $F4, $F4, $17, $17, $10, $10, $08, $08, $07, $F7
db $A9, $A9, $A9, $A9, $3D, $3D, $09, $09, $89, $89, $01, $01, $02, $02, $FC, $FD
db $01, $F9, $06, $86, $18, $98, $20, $A0, $20, $A0, $40, $40, $40, $40, $80, $80
db $FF, $FF, $00, $00, $08, $08, $0C, $0C, $08, $08, $08, $08, $08, $08, $18, $18
db $80, $9F, $60, $61, $18, $19, $04, $05, $04, $05, $02, $02, $02, $02, $01, $01
db $80, $80, $40, $40, $40, $40, $20, $A0, $21, $A1, $1A, $9A, $06, $86, $01, $F9
db $18, $18, $20, $20, $40, $40, $80, $80, $00, $00, $00, $00, $00, $00, $FF, $FF
db $01, $01, $02, $02, $02, $02, $04, $05, $04, $05, $18, $19, $60, $61, $80, $9F
db $07, $F7, $08, $88, $0B, $8B, $0A, $8A, $0B, $8B, $30, $B0, $40, $40, $A0, $A0
db $F0, $F7, $08, $08, $04, $04, $24, $24, $14, $14, $02, $02, $01, $01, $00, $00
db $00, $FF, $00, $01, $01, $01, $00, $00, $01, $01, $00, $00, $06, $06, $8D, $8D
db $A0, $A0, $80, $80, $EF, $EF, $24, $3C, $18, $18, $00, $00, $F0, $F0, $07, $07
db $00, $00, $00, $00, $CF, $DF, $24, $3C, $18, $18, $00, $00, $0F, $0F, $E0, $E0
db $99, $9B, $B7, $BF, $9C, $9C, $01, $01, $04, $04, $00, $01, $C0, $C1, $00, $3F
ds 12, $00
db $1F, $1F, $E0, $E0
ds 10, $00
db $7F, $7F, $80, $80
ds 10, $00
db $7F, $7F, $80, $80, $00, $00, $7F, $7F, $00, $00, $00, $00, $00, $00, $00, $00
db $FE, $FE, $01, $01, $00, $00, $FE, $FE
ds 10, $00
db $FE, $FE, $01, $01
ds 14, $00
db $F8, $F8, $07, $07
ds 14, $00
db $01, $01, $00, $00, $00, $00, $00, $00, $03, $03, $0C, $0C, $30, $30, $C3, $C3
db $0C, $0C, $0F, $0F, $30, $30, $C0, $C0, $0F, $0F, $30, $30, $C0, $C0, $00, $00
db $00, $00, $00, $00, $1F, $1F, $E0, $E0
ds 10, $00
db $7F, $7F, $80, $80, $01, $01, $03, $03, $01, $01, $00, $00, $00, $00, $00, $00
db $80, $80, $01, $01, $03, $03, $01, $01, $00, $00, $00, $00, $00, $00, $00, $00
db $01, $01, $80, $80, $C0, $C0, $80, $80, $00, $00, $00, $00, $00, $00, $00, $00
db $FE, $FE, $01, $01, $80, $80, $C0, $C0, $80, $80, $00, $00, $00, $00, $00, $00
db $00, $00, $F8, $F8, $07, $07
ds 10, $00
db $F0, $F0, $0C, $0C, $03, $03, $F0, $F0, $0C, $0C, $03, $03
ds 10, $00
db $C0, $C0, $30, $30, $0C, $0C, $C3, $C3, $30, $30
ds 14, $00
db $80, $80, $02, $02, $04, $04, $08, $08, $11, $11, $22, $22, $44, $44, $88, $88
db $10, $10, $30, $30, $40, $40, $80, $80
ds 10, $00
db $0C, $0C, $02, $02, $01, $01
ds 10, $00
db $40, $40, $20, $20, $10, $10, $88, $88, $44, $44, $22, $22, $11, $11, $08, $08
db $02, $02, $04, $04, $04, $04, $09, $09, $09, $09, $12, $12, $12, $12, $24, $24
db $20, $20, $40, $40, $80, $80
ds 10, $00
db $04, $04, $02, $02, $01, $01
ds 10, $00
db $40, $40, $20, $20, $20, $20, $90, $90, $90, $90, $48, $48, $48, $48, $24, $24
db $24, $24, $48, $48, $48, $48, $90, $90, $90, $90, $90, $90, $20, $20, $20, $20
db $24, $24, $12, $12, $12, $12, $09, $09, $09, $09, $09, $09, $04, $04, $04, $04
db $01, $01, $01, $01
ds 12, $02
db $20, $20, $20, $20
ds 12, $40
db $04, $04, $04, $04
ds 12, $02
db $80, $80, $80, $80
ds 12, $40
ds 16, $02
db $48, $48, $5C, $5C, $5C, $5C, $48, $48, $40, $40, $40, $40, $40, $40, $40, $40
db $01, $01, $02, $02, $02, $02, $01, $01, $00, $00, $00, $00, $00, $00, $00, $00
db $80, $80, $40, $40, $40, $40, $80, $80, $00, $00, $00, $00, $00, $00, $00, $00
db $12, $12, $3A, $3A, $3A, $3A, $12, $12, $02, $02, $02, $02, $02, $02, $02, $02
ds 16, $40
db $02, $02, $02, $02, $01, $01, $01, $01, $01, $01, $01, $01, $00, $00, $00, $00
db $40, $40, $40, $40, $20, $20, $20, $20, $20, $20, $20, $20, $90, $90, $90, $90
db $02, $02, $02, $02, $04, $04, $04, $04, $04, $04, $04, $04, $09, $09, $09, $09
db $40, $40, $40, $40, $80, $80, $80, $80, $80, $80, $80, $80, $00, $00, $00, $00
db $90, $90, $48, $48, $48, $48, $24, $24, $24, $24, $12, $12, $12, $12, $09, $09
db $09, $09, $12, $12, $12, $12, $24, $24, $24, $24, $48, $48, $48, $48, $90, $90
db $09, $09, $04, $04, $04, $04, $02, $02, $01, $01, $00, $00, $00, $00, $1F, $1F
db $00, $00, $80, $80, $40, $40, $20, $20, $10, $10, $88, $88, $44, $44, $E2, $E2
db $00, $00, $01, $01, $02, $02, $04, $04, $08, $08, $11, $11, $22, $22, $47, $47
db $90, $90, $20, $20, $20, $20, $40, $40, $80, $80, $00, $00, $00, $00, $F8, $F8
db $00, $00, $00, $00, $01, $01, $01, $01, $02, $03, $02, $03, $02, $02, $02, $02
db $7F, $7F, $FF, $FF, $FF, $FF, $6F, $DF, $A3, $5F, $81, $7F, $C0, $3F, $C0, $3F
db $F1, $F1, $F8, $F8, $FC, $FC, $FE, $FE, $FF, $FF, $FE, $FE, $7E, $FE, $7E, $FE
db $00, $00, $80, $80, $40, $40, $30, $30, $0C, $0C, $C3, $C3, $30, $30, $0C, $0C
ds 12, $00
db $C0, $C0, $30, $30
ds 12, $00
db $03, $03, $0C, $0C, $00, $00, $01, $01, $02, $02, $0C, $0C, $30, $30, $C3, $C3
db $0C, $0C, $30, $30, $8F, $8F, $1F, $1F, $3F, $3F, $6D, $7B, $D4, $EB, $50, $6F
db $78, $47, $78, $47, $FE, $FE, $FF, $FF, $FF, $FF, $FF, $FF, $7F, $FF, $3F, $FF
db $0F, $FF, $0F, $FF, $00, $00, $00, $00, $80, $80, $80, $80, $C0, $C0, $C0, $C0
db $C0, $C0, $C0, $C0, $02, $03, $03, $03, $03, $03, $01, $01, $01, $01, $00, $00
db $00, $00, $00, $00, $C0, $3F, $E0, $1F, $70, $8F, $B8, $C7, $DE, $E1, $EA, $F5
db $7E, $7F, $1F, $1F, $1E, $FE, $0E, $FE, $0E, $FE, $04, $FC, $0C, $FC, $0C, $FC
db $30, $F0, $C0, $C0, $03, $03
ds 14, $00
db $0F, $0F, $C0, $C0, $30, $30, $0F, $0F
ds 10, $00
db $E0, $E0, $1F, $1F, $00, $00, $E0, $E0, $1F, $1F, $00, $00, $00, $00, $03, $03
db $01, $01, $80, $80, $7F, $7F, $00, $00, $80, $80, $7F, $7F
ds 16, $00
db $01, $01
ds 14, $00
db $80, $80, $C0, $C0, $80, $80, $01, $01, $FE, $FE, $00, $00, $01, $01, $FE, $FE
db $00, $00, $00, $00, $07, $07, $F8, $F8, $00, $00, $07, $07, $F8, $F8, $00, $00
db $00, $00, $F0, $F0, $03, $03, $0C, $0C, $F0, $F0, $00, $00, $00, $00, $00, $00
db $00, $00, $C0, $C0
ds 14, $00
db $58, $67, $7C, $63, $6E, $71, $37, $38, $3B, $3C, $1D, $1E, $0F, $0F, $03, $03
db $03, $FF, $01, $FF, $01, $FF, $00, $FF, $C0, $3F, $C1, $3F, $C6, $FE, $F8, $F8
db $C0, $C0, $C0, $C0, $C0, $C0, $80, $80, $80, $80
ds 18, $00
db $01, $01, $01, $01
ds 12, $00
db $80, $80, $80, $80, $00, $00, $00, $00, $00, $00, $1E, $1E, $21, $21, $4C, $4C
db $42, $42, $43, $43, $00, $00, $00, $00, $00, $00, $00, $00, $FC, $FC, $82, $82
db $FC, $FC, $90, $90, $04, $04, $03, $03, $44, $44, $23, $23, $10, $10, $0F, $0F
db $00, $00, $00, $00, $10, $10, $F0, $F0, $20, $20, $E0, $E0, $40, $40, $C0, $C0
ds 68, $00

; Data from 266A to 2759 (240 bytes)
_DATA_266A_:
ds 10, $00
db $13, $14, $17, $18
ds 13, $00
db $19, $1A, $1B, $1C, $1D, $20, $21, $22, $23, $24, $00, $00, $00, $00, $00, $01
db $02, $03, $00, $19, $25, $26, $00, $00, $00, $00, $00, $00, $27, $28, $24, $00
db $00, $00, $00, $04, $05, $06, $00, $29, $2A, $00, $00, $00, $00, $00, $00, $00
db $00, $2B, $2C, $00, $00, $00, $00, $00, $00, $00, $5D, $2D
ds 10, $00
db $2E, $5E, $00, $00, $00, $07, $08, $09, $2F, $30
ds 10, $00
db $31, $32, $00, $00, $00, $0A, $0B, $0C, $33, $34, $00, $00, $00, $00, $35, $36
db $00, $00, $00, $00, $37, $38, $00, $00, $00, $00, $00, $00, $39, $3A
ds 10, $00
db $3B, $3C, $00, $00, $00, $0D, $0E, $0F, $00, $3D
ds 10, $00
db $3E, $00, $00, $00, $00, $10, $11, $12, $00, $3F, $40, $00, $00, $00, $00, $00
db $00, $00, $00, $41, $42, $00, $00, $00, $00, $00, $00, $00, $43, $44, $45, $46
db $47, $00, $54, $55, $00, $48, $49, $4A, $4B, $4C, $00, $00, $00, $00, $00, $00
    db $4D, $4E, $4F, $50, $51, $52, $53, $56, $57, $58, $59, $5A, $5B, $5C, $00

; Data from 275A to 2FFF (2214 bytes)
_DATA_275A_:
    db $00, $FF, $00, $C3, $00, $99, $00, $99, $00, $99, $00, $99, $00, $C3, $00, $FF
    db $00, $FF, $00, $E7, $00, $C7, $00, $E7, $00, $E7, $00, $E7, $00, $C3, $00, $FF
    db $00, $FF, $00, $C3, $00, $B1, $00, $F1, $00, $C3, $00, $8F, $00, $81, $00, $FF
    db $00, $FF, $00, $83, $00, $F1, $00, $C3, $00, $F1, $00, $F1, $00, $83, $00, $FF
    db $00, $FF, $00, $C3, $00, $93, $00, $B3, $00, $B1, $00, $81, $00, $F3, $00, $FF
    db $00, $FF, $00, $83, $00, $9F, $00, $83, $00, $F1, $00, $B1, $00, $C3, $00, $FF
    db $00, $FF, $00, $C3, $00, $9F, $00, $83, $00, $99, $00, $99, $00, $C3, $00, $FF
    db $00, $FF, $00, $81, $00, $F9, $00, $F3, $00, $E7, $00, $C7, $00, $C7, $00, $FF
    db $00, $FF, $00, $C3, $00, $B1, $00, $C3, $00, $B1, $00, $B1, $00, $C3, $00, $FF
    db $00, $FF, $00, $C3, $00, $B1, $00, $B1, $00, $C1, $00, $F1, $00, $C3, $00, $FF
    db $FF, $FF, $C7, $C7, $93, $93, $39, $39, $39, $39, $31, $31, $29, $29, $29, $29
    db $29, $29, $19, $19, $39, $39, $39, $39, $39, $39, $93, $93, $C7, $C7, $FF, $FF
    db $FF, $FF, $E7, $E7, $C7, $C7, $87, $87
ds 18, $E7
db $81, $81, $81, $81, $FF, $FF, $FF, $FF, $C7, $C7, $83, $83, $31, $31, $79, $79
db $79, $79, $F9, $F9, $F3, $F3, $C7, $C7, $8F, $8F, $9F, $9F, $3F, $3F, $3F, $3F
db $01, $01, $01, $01, $FF, $FF, $FF, $FF, $C7, $C7, $83, $83, $31, $31, $79, $79
db $F9, $F9, $F3, $F3, $C7, $C7, $C7, $C7, $F3, $F3, $F9, $F9, $79, $79, $31, $31
db $83, $83, $C7, $C7, $FF, $FF, $FF, $FF, $E3, $E3, $E3, $E3, $C3, $C3, $D3, $D3
db $D3, $D3, $93, $93, $B3, $B3, $B3, $B3, $B3, $B3, $33, $33, $01, $01, $01, $01
db $F3, $F3, $F3, $F3, $FF, $FF, $FF, $FF, $03, $03, $03, $03, $7F, $7F, $7F, $7F
db $7F, $7F, $07, $07, $73, $73, $F9, $F9, $F9, $F9, $F9, $F9, $79, $79, $73, $73
db $03, $03, $87, $87, $FF, $FF, $FF, $FF, $C7, $C7, $83, $83, $39, $39, $3D, $3D
db $3F, $3F, $27, $27, $03, $03, $19, $19, $39, $39, $3D, $3D, $3D, $3D, $99, $99
db $83, $83, $C7, $C7, $FF, $FF, $FF, $FF, $01, $01, $01, $01, $7D, $7D, $F9, $F9
db $FB, $FB, $F7, $F7, $E7, $E7, $E7, $E7, $CF, $CF, $CF, $CF, $8F, $8F, $8F, $8F
db $8F, $8F, $8F, $8F, $FF, $FF, $FF, $FF, $C7, $C7, $93, $93, $39, $39, $7D, $7D
db $39, $39, $93, $93, $C7, $C7, $93, $93, $39, $39, $7D, $7D, $7D, $7D, $39, $39
db $83, $83, $C7, $C7, $FF, $FF, $FF, $FF, $C7, $C7, $83, $83, $39, $39, $79, $79
db $79, $79, $79, $79, $79, $79, $31, $31, $89, $89, $F9, $F9, $F9, $F9, $39, $39
db $83, $83, $C7, $C7
ds 24, $FF
db $E7, $E7, $E7, $E7, $F7, $F7, $F7, $F7, $EF, $EF, $FF, $FF, $FF, $FF, $FF, $FF
db $E7, $E7, $E7, $E7
ds 10, $FF
db $E7, $E7, $E7, $E7
ds 42, $FF
db $C7, $C7, $83, $83, $B3, $B3, $39, $39, $39, $39, $79, $79, $79, $79, $01, $01
ds 12, $79
db $FF, $FF, $FF, $FF, $07, $07, $33, $33, $39, $39, $39, $39, $39, $39, $33, $33
db $0F, $0F, $33, $33, $39, $39, $39, $39, $39, $39, $39, $39, $33, $33, $07, $07
db $FF, $FF, $FF, $FF, $C7, $C7, $83, $83, $19, $19, $3D, $3D, $3D, $3D, $3F, $3F
db $3F, $3F, $3F, $3F, $3F, $3F, $3D, $3D, $3D, $3D, $19, $19, $83, $83, $C7, $C7
db $FF, $FF, $FF, $FF, $0F, $0F, $03, $03, $71, $71
ds 16, $79
db $71, $71, $03, $03, $0F, $0F, $FF, $FF, $FF, $FF, $03, $03, $01, $01, $3D, $3D
db $3F, $3F, $3F, $3F, $07, $07, $07, $07, $3F, $3F, $3F, $3F, $3F, $3F, $3F, $3F
db $3D, $3D, $01, $01, $03, $03, $FF, $FF, $FF, $FF, $03, $03, $01, $01, $3D, $3D
db $3F, $3F, $3F, $3F, $3F, $3F, $07, $07, $07, $07
ds 12, $3F
db $FF, $FF, $FF, $FF, $C7, $C7, $83, $83, $19, $19, $3D, $3D, $3F, $3F, $3F, $3F
db $3F, $3F, $31, $31, $39, $39, $39, $39, $39, $39, $11, $11, $83, $83, $C7, $C7
db $FF, $FF, $FF, $FF
ds 12, $79
db $01, $01, $01, $01
ds 12, $79
db $FF, $FF, $FF, $FF, $C3, $C3, $C3, $C3
ds 20, $E7
db $C3, $C3, $C3, $C3, $FF, $FF, $FF, $FF, $E1, $E1, $E1, $E1
ds 14, $F3
db $73, $73, $73, $73, $33, $33, $03, $03, $87, $87, $FF, $FF, $FF, $FF, $39, $39
db $39, $39, $33, $33, $37, $37, $2F, $2F, $0F, $0F, $1F, $1F, $1F, $1F, $2F, $2F
db $27, $27, $37, $37, $31, $31, $39, $39, $39, $39, $FF, $FF, $FF, $FF
ds 24, $3F
db $03, $03, $03, $03, $FF, $FF, $FF, $FF, $7D, $7D, $39, $39, $39, $39, $11, $11
db $55, $55, $45, $45, $45, $45, $6D, $6D, $6D, $6D
ds 10, $7D
db $FF, $FF, $FF, $FF, $79, $79, $39, $39, $39, $39, $19, $19, $19, $19, $59, $59
db $49, $49, $69, $69, $69, $69, $61, $61, $71, $71, $71, $71, $71, $71, $79, $79
db $FF, $FF, $FF, $FF, $C7, $C7, $93, $93
ds 20, $39
db $93, $93, $C7, $C7, $FF, $FF, $FF, $FF, $07, $07, $33, $33, $39, $39, $39, $39
db $39, $39, $39, $39, $33, $33, $03, $03, $0F, $0F
ds 10, $3F
db $FF, $FF, $FF, $FF, $C7, $C7, $93, $93, $39, $39, $3D, $3D, $3D, $3D, $3D, $3D
db $3D, $3D, $35, $35, $35, $35, $35, $35, $39, $39, $3B, $3B, $91, $91, $C5, $C5
db $FF, $FF, $FF, $FF, $07, $07, $33, $33, $39, $39, $39, $39, $39, $39, $33, $33
db $07, $07, $0F, $0F, $2F, $2F, $2F, $2F, $27, $27, $37, $37, $31, $31, $39, $39
db $FF, $FF, $FF, $FF, $C7, $C7, $93, $93, $39, $39, $3D, $3D, $3F, $3F, $9F, $9F
db $CF, $CF, $F3, $F3, $F9, $F9, $79, $79, $79, $79, $31, $31, $83, $83, $C7, $C7
db $FF, $FF, $FF, $FF, $01, $01, $29, $29, $6D, $6D
ds 22, $EF
db $FF, $FF, $FF, $FF
ds 20, $79
db $71, $71, $71, $71, $23, $23, $87, $87, $FF, $FF, $FF, $FF, $79, $79, $79, $79
db $79, $79, $39, $39, $BB, $BB, $BB, $BB, $B3, $B3, $B3, $B3, $D7, $D7, $D7, $D7
db $C7, $C7, $EF, $EF, $EF, $EF, $EF, $EF, $FF, $FF, $FF, $FF, $79, $79
ds 12, $59
db $49, $49, $49, $49, $49, $49, $29, $29, $33, $33, $B3, $B3, $B7, $B7, $FF, $FF
db $FF, $FF, $79, $79, $39, $39, $BB, $BB, $B3, $B3, $97, $97, $C7, $C7, $C7, $C7
db $C7, $C7, $D7, $D7, $97, $97, $9B, $9B, $3B, $3B, $39, $39, $3D, $3D, $FF, $FF
db $FF, $FF, $7D, $7D, $7D, $7D, $39, $39, $BB, $BB, $93, $93, $C7, $C7, $C7, $C7
ds 14, $EF
db $FF, $FF, $FF, $FF, $01, $01, $F9, $F9, $F9, $F9, $F3, $F3, $F7, $F7, $E7, $E7
db $EF, $EF, $CF, $CF, $DF, $DF, $9F, $9F, $3F, $3F, $3F, $3F, $01, $01, $01, $01
db $FF, $FF, $FF, $FF, $B3, $B3, $FF, $FF, $C7, $C7, $83, $83, $B3, $B3, $39, $39
db $39, $39, $79, $79, $79, $79, $01, $01, $79, $79, $79, $79, $79, $79, $79, $79
db $FF, $FF, $FF, $FF, $B3, $B3, $FF, $FF, $C7, $C7, $93, $93
ds 16, $39
db $93, $93, $C7, $C7, $FF, $FF, $FF, $FF, $B3, $B3, $FF, $FF
ds 16, $79
db $71, $71, $71, $71, $23, $23, $87, $87, $FF, $FF, $FF, $FF, $C7, $C7, $93, $93
db $B9, $B9, $3D, $3D, $39, $39, $33, $33, $07, $07, $33, $33, $39, $39, $3D, $3D
db $19, $19, $03, $03, $27, $27, $3F, $3F
ds 16, $FF
db $01, $01, $01, $01
ds 26, $FF
db $FE, $FE, $FE, $FE, $F8, $F8, $F8, $F8, $F8, $F8, $F8, $F8
ds 10, $FF
db $9F, $9F, $87, $87, $87, $87, $9B, $9B, $9B, $9B, $1F, $1F, $1F, $1F, $1F, $1F
db $1F, $1F, $7F, $7F, $7F, $7F, $FE, $FE, $FE, $FE
ds 12, $FF
db $FC, $FC, $F3, $F3, $8F, $8F, $BF, $BF, $BE, $BE, $BE, $BE, $BF, $BF, $3F, $3F
db $3F, $3F, $7F, $7F
ds 10, $FF
db $3F, $3F, $BF, $BF, $BF, $BF, $BF, $BF, $3F, $3F, $3F, $3F, $7E, $7E, $FC, $FC
db $F8, $F8, $F9, $F9
ds 12, $FF
db $7F, $7F, $3F, $3F, $3F, $3F
ds 10, $7F
ds 12, $FF
db $FB, $FB, $F9, $F9, $F9, $F9, $FA, $FA, $E3, $E3, $E3, $E3, $C3, $C3, $C7, $C7
ds 22, $FF
db $FE, $FE, $FD, $FD, $FC, $FC
ds 10, $FD
db $F9, $F9, $F9, $F9, $F3, $F3, $F3, $F3, $E7, $E7, $D7, $D7, $A7, $A7, $47, $47
db $A7, $A7, $67, $67, $C7, $C7, $CF, $CF, $FF, $FF, $FF, $FF, $FC, $FC, $FC, $FC
db $FC, $FC, $7C, $7C
ds 10, $FF
db $C7, $C7, $C3, $C3, $CB, $CB, $CF, $CF, $CF, $CF, $0F, $0F, $0F, $0F, $0F, $0F
db $0F, $0F, $3F, $3F, $3F, $3F, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $1F, $1F
db $1F, $1F
ds 32, $18
db $1F, $1F, $1F, $1F, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF
ds 24, $7E
db $18, $18, $18, $18, $18, $18, $18, $18, $FF, $FF, $FF, $FF, $00, $00, $00, $00
db $00, $00, $00, $00, $FF, $FF, $FF, $FF, $18, $18, $18, $18, $18, $18, $18, $18
db $00, $00, $00, $00, $F8, $F8, $F8, $F8
ds 16, $18
db $F8, $F8, $F8, $F8, $00, $00, $00, $00, $00, $00, $00, $00, $08, $08, $1C, $1C
db $3E, $3E, $3E, $3E, $00, $00, $00, $00, $00, $00, $3C, $3C, $4E, $4E, $4E, $4E
db $7E, $7E, $4E, $4E, $4E, $4E, $00, $00, $00, $00, $7C, $7C, $66, $66, $7C, $7C
db $66, $66, $66, $66, $7C, $7C, $00, $00, $00, $00, $3C, $3C, $66, $66, $60, $60
db $60, $60, $66, $66, $3C, $3C, $00, $00, $00, $00, $7C, $7C, $4E, $4E, $4E, $4E
db $4E, $4E, $4E, $4E, $7C, $7C, $00, $00, $00, $00, $7E, $7E, $60, $60, $7C, $7C
db $60, $60, $60, $60, $7E, $7E, $00, $00, $00, $00, $7E, $7E, $60, $60, $60, $60
db $7C, $7C, $60, $60, $60, $60, $00, $00, $00, $00, $3C, $3C, $66, $66, $60, $60
db $6E, $6E, $66, $66, $3E, $3E, $00, $00, $00, $00, $46, $46, $46, $46, $7E, $7E
db $46, $46, $46, $46, $46, $46, $00, $00, $00, $00, $3C, $3C, $18, $18, $18, $18
db $18, $18, $18, $18, $3C, $3C, $00, $00, $00, $00, $1E, $1E, $0C, $0C, $0C, $0C
db $6C, $6C, $6C, $6C, $38, $38, $00, $00, $00, $00, $66, $66, $6C, $6C, $78, $78
db $78, $78, $6C, $6C, $66, $66, $00, $00, $00, $00
ds 10, $60
db $7E, $7E, $00, $00, $00, $00, $46, $46, $6E, $6E


_LABEL_3000_:
    ld   a, [hl]
    ld   a, [hl]
; Data from 3002 to 3FFF (4094 bytes)
db $56, $56, $46, $46, $46, $46, $00, $00, $00, $00, $46, $46, $66, $66, $76, $76
db $5E, $5E, $4E, $4E, $46, $46, $00, $00, $00, $00, $3C, $3C, $66, $66, $66, $66
db $66, $66, $66, $66, $3C, $3C, $00, $00, $00, $00, $7C, $7C, $66, $66, $66, $66
db $7C, $7C, $60, $60, $60, $60, $00, $00, $00, $00, $3C, $3C, $62, $62, $62, $62
db $6A, $6A, $64, $64, $3A, $3A, $00, $00, $00, $00, $7C, $7C, $66, $66, $66, $66
db $7C, $7C, $68, $68, $66, $66, $00, $00, $00, $00, $3C, $3C, $60, $60, $3C, $3C
db $0E, $0E, $4E, $4E, $3C, $3C, $00, $00, $00, $00, $7E, $7E
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
db $00, $00, $18, $18
ds 10, $3C
db $18, $18, $18, $18, $18, $18, $00, $00, $18, $18, $3C, $3C, $3C, $3C, $18, $18
db $00, $00, $00, $00, $36, $36, $36, $36, $12, $12, $24, $24
ds 24, $00
db $1C, $1C, $3E, $3E, $32, $32, $30, $30, $3C, $3C, $7E, $7E, $66, $66, $66, $66
db $7E, $7E, $3C, $3C, $0C, $0C, $4C, $4C, $7C, $7C, $38, $38, $00, $00, $00, $00
db $18, $18, $3C, $3C, $5A, $5A, $5A, $5A, $5A, $5A, $58, $58, $3C, $3C, $1A, $1A
db $1A, $1A, $5A, $5A, $5A, $5A, $5A, $5A, $3C, $3C, $18, $18, $00, $00, $00, $00
db $22, $22, $52, $52, $56, $56, $24, $24, $0C, $0C, $0C, $0C, $18, $18, $18, $18
db $30, $30, $30, $30, $24, $24, $6A, $6A, $4A, $4A, $44, $44, $00, $00, $00, $00
db $60, $60, $B0, $B0, $90, $90, $90, $90, $D0, $D0, $60, $60, $60, $60, $F0, $F0
db $92, $92, $9A, $9A, $8C, $8C, $C4, $C4, $FA, $FA, $72, $72, $00, $00, $00, $00
db $02, $02, $06, $06, $06, $06, $04, $04, $0C, $0C, $0C, $0C, $18, $18, $18, $18
db $30, $30, $30, $30, $20, $20, $60, $60, $60, $60, $40, $40, $00, $00, $00, $00
db $18, $18, $30, $30
ds 20, $60
db $30, $30, $18, $18, $00, $00, $00, $00, $18, $18, $0C, $0C
ds 20, $06
db $0C, $0C, $18, $18
ds 12, $00
db $7E, $7E, $7E, $7E, $00, $00, $00, $00, $7E, $7E, $7E, $7E
ds 12, $00
db $18, $18, $18, $18, $0C, $0C
ds 26, $00
db $18, $18, $18, $18, $30, $30
ds 30, $00
db $10, $10, $92, $92, $54, $54, $74, $74, $38, $38, $5C, $5C, $54, $54, $92, $92
db $10, $10
ds 10, $00
db $10, $10, $38, $38, $38, $38, $6C, $6C, $C6, $C6, $C6, $C6, $82, $82
ds 18, $00
db $12, $12, $12, $12, $7E, $7E, $24, $24, $24, $24, $24, $24, $24, $24, $FE, $FE
db $48, $48, $48, $48
ds 22, $00
db $7C, $7C, $82, $82, $92, $92, $AA, $AA, $AA, $AA, $AA, $AA, $B6, $B6, $80, $80
db $7C, $7C
ds 10, $00
db $18, $18, $18, $18, $00, $00, $00, $00, $00, $00, $18, $18, $18, $18
ds 34, $00
db $18, $18, $18, $18
ds 12, $00
db $18, $18, $18, $18, $00, $00, $00, $00, $18, $18, $18, $18, $08, $08, $10, $10
ds 12, $00
db $40, $40, $60, $60, $30, $30, $18, $18, $0C, $0C, $06, $06, $0C, $0C, $18, $18
db $30, $30, $60, $60, $40, $40
ds 10, $00
db $02, $02, $06, $06, $0C, $0C, $18, $18, $30, $30, $60, $60, $30, $30, $18, $18
db $0C, $0C, $06, $06, $02, $02
ds 16, $00
db $10, $10, $38, $38, $FE, $FE, $7C, $7C, $38, $38, $6C, $6C, $44, $44
ds 138, $00
db $38, $38, $6C, $6C, $46, $46, $C2, $C2, $C6, $C6, $CC, $CC, $F8, $F8, $CC, $CC
db $C6, $C6, $C2, $C2, $E6, $E6, $FC, $FC, $D8, $D8, $C0, $C0
ds 100, $00
db $38, $38, $7C, $7C, $4C, $4C, $C6, $C6, $C6, $C6, $86, $86, $86, $86, $FE, $FE
ds 12, $86
db $00, $00, $00, $00, $F8, $F8, $CC, $CC, $C6, $C6, $C6, $C6, $C6, $C6, $CC, $CC
db $F0, $F0, $CC, $CC, $C6, $C6, $C6, $C6, $C6, $C6, $C6, $C6, $CC, $CC, $F8, $F8
db $00, $00, $00, $00, $38, $38, $7C, $7C, $E6, $E6, $C2, $C2, $C2, $C2, $C0, $C0
db $C0, $C0, $C0, $C0, $C0, $C0, $C2, $C2, $C2, $C2, $E6, $E6, $7C, $7C, $38, $38
db $00, $00, $00, $00, $F0, $F0, $FC, $FC, $8E, $8E
ds 16, $86
db $8E, $8E, $FC, $FC, $F0, $F0, $00, $00, $00, $00, $FC, $FC, $FE, $FE, $C2, $C2
db $C0, $C0, $C0, $C0, $F8, $F8, $F8, $F8, $C0, $C0, $C0, $C0, $C0, $C0, $C0, $C0
db $C2, $C2, $FE, $FE, $FC, $FC, $00, $00, $00, $00, $FC, $FC, $FE, $FE, $C2, $C2
db $C0, $C0, $C0, $C0, $C0, $C0, $F8, $F8, $F8, $F8
ds 12, $C0
db $00, $00, $00, $00, $38, $38, $7C, $7C, $E6, $E6, $C2, $C2, $C0, $C0, $C0, $C0
db $C0, $C0, $CE, $CE, $C6, $C6, $C6, $C6, $C6, $C6, $EE, $EE, $7C, $7C, $38, $38
db $00, $00, $00, $00
ds 12, $86
db $FE, $FE, $FE, $FE
ds 12, $86
db $00, $00, $00, $00, $3C, $3C, $3C, $3C
ds 20, $18
db $3C, $3C, $3C, $3C, $00, $00, $00, $00, $1E, $1E, $1E, $1E
ds 14, $0C
db $8C, $8C, $8C, $8C, $CC, $CC, $FC, $FC, $78, $78, $00, $00, $00, $00, $C6, $C6
db $C6, $C6, $CC, $CC, $C8, $C8, $D0, $D0, $F0, $F0, $E0, $E0, $E0, $E0, $D0, $D0
db $D8, $D8, $C8, $C8, $CE, $CE, $C6, $C6, $C6, $C6, $00, $00, $00, $00
ds 24, $C0
db $FC, $FC, $FC, $FC, $00, $00, $00, $00, $82, $82, $C6, $C6, $C6, $C6, $EE, $EE
db $AA, $AA, $BA, $BA, $BA, $BA, $92, $92, $92, $92
ds 10, $82
db $00, $00, $00, $00, $86, $86, $C6, $C6, $C6, $C6, $E6, $E6, $E6, $E6, $A6, $A6
db $B6, $B6, $96, $96, $96, $96, $9E, $9E, $8E, $8E, $8E, $8E, $8E, $8E, $86, $86
db $00, $00, $00, $00, $38, $38, $6C, $6C
ds 20, $C6
db $6C, $6C, $38, $38, $00, $00, $00, $00, $F8, $F8, $CC, $CC, $C6, $C6, $C6, $C6
db $C6, $C6, $C6, $C6, $CC, $CC, $FC, $FC, $F0, $F0
ds 10, $C0
db $00, $00, $00, $00, $38, $38, $6C, $6C, $C6, $C6, $C2, $C2, $C2, $C2, $C2, $C2
db $C2, $C2, $CA, $CA, $CA, $CA, $CA, $CA, $C6, $C6, $C4, $C4, $6E, $6E, $3A, $3A
db $00, $00, $00, $00, $F8, $F8, $CC, $CC, $C6, $C6, $C6, $C6, $C6, $C6, $CC, $CC
db $F8, $F8, $F0, $F0, $D0, $D0, $D0, $D0, $D8, $D8, $C8, $C8, $CE, $CE, $C6, $C6
db $00, $00, $00, $00, $38, $38, $6C, $6C, $C6, $C6, $C2, $C2, $C0, $C0, $60, $60
db $30, $30, $0C, $0C, $06, $06, $86, $86, $86, $86, $CE, $CE, $7C, $7C, $38, $38
db $00, $00, $00, $00, $FE, $FE, $D6, $D6, $92, $92
ds 22, $10
db $00, $00, $00, $00
ds 20, $86
db $8E, $8E, $8E, $8E, $DC, $DC, $78, $78, $00, $00, $00, $00, $86, $86, $86, $86
db $86, $86, $C6, $C6, $44, $44, $44, $44, $4C, $4C, $4C, $4C, $28, $28, $28, $28
db $38, $38, $10, $10, $10, $10, $10, $10, $00, $00, $00, $00, $86, $86
ds 12, $A6
db $B6, $B6, $B6, $B6, $B6, $B6, $D6, $D6, $CC, $CC, $4C, $4C, $48, $48, $00, $00
db $00, $00, $86, $86, $C6, $C6, $44, $44, $4C, $4C, $68, $68, $38, $38, $38, $38
db $38, $38, $28, $28, $68, $68, $64, $64, $C4, $C4, $C6, $C6, $C2, $C2, $00, $00
db $00, $00, $82, $82, $82, $82, $C6, $C6, $44, $44, $6C, $6C, $38, $38, $38, $38
ds 14, $10
db $00, $00, $00, $00, $FE, $FE, $06, $06, $06, $06, $0C, $0C, $08, $08, $18, $18
db $10, $10, $30, $30, $20, $20, $60, $60, $C0, $C0, $C0, $C0, $FE, $FE, $FE, $FE
db $00, $00, $00, $00, $82, $82, $00, $00

SECTION "rom1", ROMX[$4000], BANK[$1]
_LABEL_4000_:
    jr   c, _LABEL_403A_
    ld   a, h
    ld   a, h
    ld   c, h
    ld   c, h
    add  $C6
    add  $C6
    add  [hl]
    add  [hl]
    add  [hl]
    add  [hl]
    cp   $FE
    add  [hl]
    add  [hl]
    add  [hl]
    add  [hl]
    add  [hl]
; Data from 4015 to 4039 (37 bytes)
db $86, $86, $86, $00, $00, $00, $00, $82, $82, $00, $00, $38, $38, $6C, $6C
ds 16, $C6
db $6C, $6C, $38, $38, $00, $00

_LABEL_403A_:
    nop
    nop
    add  d
    add  d
    nop
    nop
    add  [hl]
; Data from 4041 to 4389 (841 bytes)
ds 15, $86
db $8E, $8E, $8E, $8E, $DC, $DC, $78, $78
ds 24, $00
db $18, $18, $18, $18, $08, $08, $08, $08, $10, $10
ds 14, $00
db $18, $18, $18, $18
ds 44, $00
db $FF, $FF, $FB, $00, $F9, $00, $F9, $00, $FA, $00, $FB, $00, $F3, $00, $E3, $00
db $E7, $00, $FF, $00, $FF, $00, $FF, $07, $FF, $18, $F9, $21, $E1, $41, $E1, $41
db $C3, $83, $FF, $00, $FF, $00, $FF, $F8, $FE, $08, $FC, $08, $FC, $88, $5A, $48
db $19, $08, $FF, $00, $FF, $03, $EF, $04, $DC, $18, $7C, $20, $60, $30, $40, $78
db $40, $7C, $C7, $87, $86, $06, $00, $00, $03, $03, $07, $07, $0F, $0F, $0C, $0C
db $08, $08, $09, $08, $08, $08, $E8, $E8, $F8, $F8, $F8, $F8, $78, $78, $18, $18
db $08, $08, $46, $78, $7F, $7F, $55, $55, $55, $55, $40, $40, $7F, $7F, $00, $00
db $00, $00, $09, $09, $E8, $E8, $4A, $4A, $4D, $4D, $1C, $1C, $DA, $DA, $21, $21
db $03, $03, $48, $48, $08, $08, $28, $28, $58, $58, $9C, $9C, $2C, $2C, $42, $42
db $E0, $E0, $FF, $00, $DF, $00, $CF, $00, $D7, $04, $DF, $06, $9F, $05, $1F, $04
db $1F, $0C, $FF, $00, $FF, $00, $FF, $07, $FF, $18, $F8, $20, $E0, $40, $E0, $40
db $C0, $80, $FF, $00, $FF, $00, $FF, $F8, $FF, $08, $1F, $08, $1F, $08, $1F, $08
db $FF, $F0, $FF, $1C, $FF, $1B, $FF, $04, $FC, $18, $78, $20, $60, $30, $40, $78
db $40, $7C, $DF, $9F, $BE, $3E, $3C, $3C, $3E, $3E, $1E, $1E, $00, $00, $07, $07
db $07, $07, $FF, $FC, $1F, $1E, $0F, $0E, $0F, $0E, $1F, $1E, $7F, $7C, $FF, $F0
db $CF, $C8, $67, $58, $7F, $7F, $55, $55, $55, $55, $40, $40, $7F, $7F, $00, $00
db $00, $00, $E0, $00, $FB, $FB, $57, $57, $53, $53, $00, $00, $FF, $FF, $00, $00
db $00, $00, $0D, $08, $C9, $C8, $EA, $E8, $CA, $C8, $0B, $08, $FF, $F8, $1E, $00
db $20, $00, $BF, $00, $9F, $00, $AF, $00, $3F, $00, $3F, $01, $7F, $03, $7F, $00
db $FF, $00, $FF, $00, $FF, $80, $FF, $C7, $FF, $98, $F8, $A0, $E0, $40, $F0, $50
db $D8, $98, $FF, $00, $FF, $00, $FF, $F8, $FF, $08, $1F, $08, $1F, $08, $3F, $08
db $3F, $08, $FF, $00, $FF, $03, $FF, $04, $FC, $18, $70, $20, $60, $30, $40, $78
db $40, $70, $D4, $94, $90, $10, $30, $30, $70, $70, $F0, $F0, $E1, $E0, $03, $00
db $0E, $01, $3F, $08, $3F, $08, $7F, $08, $7F, $28, $7F, $28, $EF, $78, $EF, $F8
db $7F, $A8, $67, $58, $7F, $7F, $55, $55, $55, $55, $40, $40, $7F, $7F, $00, $00
db $00, $00, $DD, $03, $FF, $FF, $55, $55, $55, $55, $00, $00, $FF, $FF, $00, $00
db $00, $00, $7D, $08, $FC, $F8, $5A, $58, $58, $58, $08, $08, $F8, $F8, $00, $00
db $00, $00, $DF, $00, $CF, $00, $D7, $00, $DE, $00, $DE, $00, $DE, $00, $9E, $00
db $1C, $00, $FF, $00, $FF, $00, $FF, $07, $FF, $18, $7F, $21, $F9, $41, $F1, $41
db $E3, $83, $FF, $00, $FF, $00, $FC, $FC, $FC, $04, $DC, $04, $9C, $84, $5C, $44
db $1C, $04, $38, $00, $FB, $03, $FD, $06, $FA, $1C, $EC, $30, $E8, $30, $C4, $78
db $40, $7C, $C7, $87, $C6, $06, $80, $00, $00, $00, $00, $00, $35, $35, $7F, $7F
db $FE, $80, $1C, $04, $1C, $04, $1C, $04, $1A, $02, $1C, $04, $5C, $54, $FE, $FE
db $39, $01, $4E, $70, $7F, $7F, $55, $55, $55, $55, $40, $40, $7F, $7F, $00, $00
db $00, $00, $E0, $80, $D8, $98, $EC, $AC, $F5, $B4, $9A, $98, $80, $80, $7F, $7F
db $00, $00, $41, $01, $9B, $19, $AF, $2D, $37, $35, $1B, $19, $3F, $01, $FE, $FE
db $00, $00, $00, $00, $00, $00, $00, $00, $07, $07, $08, $08, $09, $09, $09, $09
db $09, $09, $00, $00, $00, $00, $00, $00, $F0, $F0, $08, $08, $84, $84, $24, $24
db $94, $94
ds 10, $00
db $01, $01, $00, $00, $01, $01, $30, $30, $40, $40, $A0, $A0, $A0, $A0, $80, $80
db $EF, $EF, $24, $3C, $18, $18, $02, $02, $01, $01, $00, $00, $00, $00, $00, $00
db $CF, $DF, $24, $3C, $18, $18, $00, $00, $06, $06, $8D, $8D, $99, $9B, $B7, $BF
db $9C, $9C, $01, $01, $08, $08, $00, $00, $F0, $F0, $07, $07
ds 12, $00
db $0F, $0F, $E0, $E0, $01, $01
ds 10, $00
db $C0, $C0, $00, $00, $F8, $F8, $00, $00, $00, $00, $00, $00, $00, $00

; Data from 438A to 4819 (1168 bytes)
_DATA_438A_:
db $BE, $BE, $6A, $6D, $6D, $70, $6D, $6D, $6D, $70, $6D, $6D, $70, $6D, $6D, $6D
db $71, $BE, $BE, $BE, $BE, $BE, $6B, $6E, $6E, $6B, $6E, $6E, $6E, $6B, $6E, $6E
db $6B, $6E, $6E, $6E, $6B, $BE, $BE, $BE, $BE, $BE, $6B, $6E, $6E, $6B, $6E, $6E
db $6E, $6B, $6E, $6E, $6B, $6E, $6E, $6E, $6B, $BE, $BE, $BE, $BE, $BE
ds 15, $6B
db $BE, $BE, $BE, $BE, $BE
ds 15, $6B
db $BE, $BE, $BE, $BE, $BE, $6C
ds 13, $6F
db $72, $BE, $BE, $BE
ds 26, $00
db $24, $24, $18, $18, $2C, $2C, $2C, $2C, $2C, $2C, $18, $18, $00, $00, $00, $00
db $24, $24, $18, $18, $2C, $2C, $2C, $2C, $2C, $2C, $18, $18, $00, $00, $00, $00
db $48, $48, $00, $00, $58, $58, $58, $58, $58, $58, $34, $34, $00, $00, $00, $00
db $48, $48, $00, $00, $58, $58, $58, $58, $58, $58, $34, $34
ds 36, $00
db $18, $18, $3C, $3C, $66, $66, $66, $66, $6E, $6E, $0C, $0C, $18, $18, $18, $18
db $18, $18, $00, $00, $18, $18, $3C, $3C, $3C, $3C, $18, $18, $00, $00, $00, $00
db $38, $38, $6C, $6C, $C6, $C6, $C6, $C6, $CE, $CE, $D6, $D6, $D6, $D6, $D6, $D6
db $E6, $E6, $C6, $C6, $C6, $C6, $C6, $C6, $6C, $6C, $38, $38, $00, $00, $00, $00
db $18, $18, $38, $38, $78, $78
ds 18, $18
db $7E, $7E, $7E, $7E, $00, $00, $00, $00, $38, $38, $7C, $7C, $CE, $CE, $86, $86
db $86, $86, $06, $06, $0C, $0C, $38, $38, $70, $70, $60, $60, $C0, $C0, $C0, $C0
db $FE, $FE, $FE, $FE, $00, $00, $00, $00, $38, $38, $7C, $7C, $CE, $CE, $86, $86
db $06, $06, $0C, $0C, $38, $38, $38, $38, $0C, $0C, $06, $06, $86, $86, $CE, $CE
db $7C, $7C, $38, $38, $00, $00, $00, $00, $1C, $1C, $1C, $1C, $3C, $3C, $2C, $2C
db $2C, $2C, $6C, $6C, $4C, $4C, $4C, $4C, $4C, $4C, $CC, $CC, $FE, $FE, $FE, $FE
db $0C, $0C, $0C, $0C, $00, $00, $00, $00, $FC, $FC, $FC, $FC, $80, $80, $80, $80
db $80, $80, $F8, $F8, $8C, $8C, $06, $06, $06, $06, $06, $06, $86, $86, $8C, $8C
db $FC, $FC, $78, $78, $00, $00, $00, $00, $38, $38, $7C, $7C, $C6, $C6, $C2, $C2
db $C0, $C0, $D8, $D8, $FC, $FC, $E6, $E6, $C6, $C6, $C2, $C2, $C2, $C2, $66, $66
db $7C, $7C, $38, $38, $00, $00, $00, $00, $FE, $FE, $FE, $FE, $82, $82, $06, $06
db $04, $04, $08, $08, $18, $18, $18, $18, $30, $30, $30, $30, $70, $70, $70, $70
db $70, $70, $70, $70, $00, $00, $00, $00, $38, $38, $6C, $6C, $C6, $C6, $82, $82
db $C6, $C6, $6C, $6C, $38, $38, $6C, $6C, $C6, $C6, $82, $82, $82, $82, $C6, $C6
db $7C, $7C, $38, $38, $00, $00, $00, $00, $38, $38, $7C, $7C, $C6, $C6, $86, $86
db $86, $86, $86, $86, $86, $86, $CE, $CE, $76, $76, $06, $06, $06, $06, $C6, $C6
db $7C, $7C, $38, $38
ds 10, $00
db $18, $18, $18, $18, $18, $18, $7E, $7E, $7E, $7E, $18, $18, $18, $18, $18, $18
ds 22, $00
db $FE, $FE, $FE, $FE
ds 24, $00
db $86, $86, $CE, $CE, $7C, $7C, $30, $30, $78, $78, $EC, $EC, $C6, $C6
ds 16, $00
db $18, $18, $18, $18, $00, $00, $7E, $7E, $7E, $7E, $00, $00, $18, $18, $18, $18
ds 18, $00
db $7C, $7C, $7C, $7C, $00, $00, $00, $00, $7C, $7C, $7C, $7C
ds 16, $00
db $3E, $3E, $3E, $3E, $30, $30, $30, $30, $30, $30, $B0, $B0, $70, $70, $70, $70
db $30, $30
ds 10, $00
db $18, $18, $3C, $3C, $3C, $3C, $18, $18, $00, $00, $18, $18, $18, $18, $18, $18
db $30, $30, $76, $76, $66, $66, $66, $66, $3C, $3C, $18, $18, $00, $00, $00, $00
db $18, $18, $3C, $3C, $3C, $3C, $18, $18, $00, $00, $18, $18, $18, $18, $18, $18
ds 10, $3C
db $18, $18, $00, $00, $00, $00, $18, $18, $30, $30
ds 20, $60
db $30, $30, $18, $18, $00, $00, $00, $00, $18, $18, $0C, $0C
ds 20, $06
db $0C, $0C, $18, $18, $00, $00, $00, $00, $18, $18, $3C, $3C, $66, $66, $66, $66
db $66, $66, $3C, $3C, $18, $18, $00, $00, $7E, $7E, $7E, $7E
ds 12, $00
db $18, $18, $60, $60, $00, $00, $86, $86, $C6, $C6, $C6, $C6, $E6, $E6, $B6, $B6
db $B6, $B6, $9E, $9E, $9E, $9E, $8E, $8E, $8E, $8E, $86, $86, $00, $00, $00, $00
db $18, $18, $60, $60, $00, $00, $38, $38, $7C, $7C, $C6, $C6, $C6, $C6, $86, $86
db $FE, $FE
ds 10, $86
db $00, $00, $00, $00, $18, $18, $60, $60, $00, $00, $FE, $FE, $FE, $FE, $C0, $C0
db $C0, $C0, $FC, $FC, $FC, $FC, $C0, $C0, $C0, $C0, $C0, $C0, $FE, $FE, $FE, $FE
db $00, $00, $00, $00, $0C, $0C, $30, $30, $00, $00, $3C, $3C, $3C, $3C
ds 14, $18
db $3C, $3C, $3C, $3C, $00, $00, $00, $00, $18, $18, $60, $60, $00, $00, $38, $38
db $EE, $EE
ds 14, $C6
db $EE, $EE, $38, $38, $00, $00, $00, $00, $18, $18, $60, $60, $00, $00
ds 14, $86
db $8E, $8E, $8E, $8E, $DC, $DC, $78, $78, $00, $00, $00, $00, $38, $38, $7C, $7C
db $0C, $0C, $3C, $3C, $6C, $6C, $6C, $6C, $3E, $3E, $00, $00, $7E, $7E, $7E, $7E
ds 10, $00

_LABEL_481A_:
    ld   de, _RAM_DCF0_ ; _RAM_DCF0_ = $DCF0
    ld   b, $10
_LABEL_481F_:
    ld   a, [de]
    ldi  [hl], a
    inc  de
    dec  b
    jr   nz, _LABEL_481F_
    ret

_LABEL_4826_:
    ld   de, _RAM_DCF0_ ; _RAM_DCF0_ = $DCF0
    ld   b, $10
_LABEL_482B_:
    ldi  a, [hl]
    ld   [de], a
    inc  de
    dec  b
    jr   nz, _LABEL_482B_
    ret

_LABEL_4832_:
    ld   bc, $0000
    ld   l, $00
    ld   a, h
    or   a
    jr   z, _LABEL_4852_
_LABEL_483B_:
    ld   a, e
    sub  h
    ld   e, a
    ld   a, d
    sbc  $00
    ld   d, a
    jr   c, _LABEL_484C_
    inc  c
    jr   nz, _LABEL_483B_
    inc  b
    ld   c, $00
    jr   _LABEL_483B_

_LABEL_484C_:
    ld   a, e
    or   a
    jr   z, _LABEL_4852_
    add  h
    ld   l, a
_LABEL_4852_:
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
    jr   z, _multiply_done_486D_

    push bc
    ld   c, a
    ld   a, b
    or   a
    ld   a, c
    pop  bc
    ; Return with result 0 if B is zero
    jr   z, _multiply_done_486D_

    ld   c, a
_loop_multiply__4863_:
    ; Add DE + A (starts with zero) for B times
    ld   a, e
    add  c
    ld   e, a
    ld   a, d
    adc  $00
    ld   d, a
    dec  b
    jr   nz, _loop_multiply__4863_
_multiply_done_486D_:
    ret

_LABEL_486E_:
    add  l
    ld   l, a
    ld   a, h
    adc  $00
    ld   h, a
    ret

_LABEL_4875_:
    call wait_until_vbl__92C_
    call _LABEL_94C_
    ld   hl, _TILEMAP0; $9800
_LABEL_487E_:
    ld   a, $BE
    ldi  [hl], a
    ld   a, h
    cp   $9C
    jr   nz, _LABEL_487E_
    ldh  a, [rLCDC]
    and  $CF
    or   $C1
    ldh  [rLCDC], a
    ret

_LABEL_488F_:
    call wait_until_vbl__92C_
    call _LABEL_94C_
    ld   hl, $9C00
_LABEL_4898_:
    ld   a, $BE
    ldi  [hl], a
    ld   a, h
    cp   $A0
    jr   nz, _LABEL_4898_
    ldh  a, [rLCDC]
    or   $A1
    ldh  [rLCDC], a
    ret

; Data from 48A7 to 48B6 (16 bytes)
db $3E, $90, $CD, $E0, $48, $41, $3E, $10, $CD, $E0, $48, $CD, $2C, $09, $06, $09

_LABEL_48B7_:
    ld   a, b
    and  $03
    cp   $00
    jr   nz, _LABEL_48C1_
    call wait_until_vbl__92C_
_LABEL_48C1_:
    ld   c, $10
_LABEL_48C3_:
    ld   a, [de]
    ldi  [hl], a
    inc  de
    dec  c
    jr   nz, _LABEL_48C3_
    dec  b
    jr   nz, _LABEL_48B7_
    ret

_LABEL_48CD_:
    push af
    ld   a, $10
    call _LABEL_48E0_
    ld   b, c
    ld   a, $10
    call _LABEL_48E0_
    call wait_until_vbl__92C_
    pop  af
    ld   b, a
    jr   _LABEL_48B7_

_LABEL_48E0_:
    push hl
    ld   h, d
    ld   l, e
    push bc
    call multiply_a_x_b__result_in_de__4853_
    pop  bc
    add  hl, de
    pop  de
    ret

; BC = Tilemap XY
_LABEL_48EB_:
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    ld   a, c
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    ld   a, b
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   hl, _TILEMAP0; $9800
    push de
    call calc_vram_addr_of_tile_xy_base_in_hl__4932_
    pop  de
    ld   b, e
    dec  b
    ld   a, [maybe_vram_data_to_write__RAM_C8CC_]
    call _LABEL_491B_
    dec  b
_LABEL_4907_:
    ld   a, [maybe_vram_data_to_write__RAM_C8CC_]
    add  $03
    call _LABEL_491B_
    dec  b
    jr   nz, _LABEL_4907_
    ld   a, [maybe_vram_data_to_write__RAM_C8CC_]
    add  $06
    call _LABEL_491B_
    ret

_LABEL_491B_:
    ld   c, a
    call wait_until_vbl__92C_
    ld   a, c
    ld   c, d
    dec  c
    ldi  [hl], a
    inc  a
    dec  c
_LABEL_4925_:
    ldi  [hl], a
    dec  c
    jr   nz, _LABEL_4925_
    inc  a
    ldi  [hl], a
    ld   a, $20
    sub  d
    call _LABEL_486E_
    ret

; Calculate the vram address of tilemap X,Y
; - Base address: HL
; - Tilemap X,Y in global vars
;
; - Returns result in HL
;
; - Destroys: A, BC, DE
calc_vram_addr_of_tile_xy_base_in_hl__4932_:
    ; Multiply Tile Y x Tilemap Width
    ld   a, [_tilemap_pos_y__RAM_C8CA_]  ; ? Tile Y
    dec  a
    ld   b, _TILEMMAP_WIDTH
    call multiply_a_x_b__result_in_de__4853_
    ; Add base Tilemap address in HL
    add  hl, de
    ;  Add X offset
    ld   a, [_tilemap_pos_x__RAM_C8CB_]  ; ? Tile X
    ld   e, a
    ld   d, $00
    add  hl, de
    ret

_LABEL_4944_:
    ld   a, h
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   a, l
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    push de
    push bc
_LABEL_494E_:
    ld   a, [de]
    cp   $00
    jr   z, _LABEL_4986_
    push bc
    ld   hl, $9000
    ld   a, c
    cp   $80
    jr   c, _LABEL_4962_
    sub  $80
    ld   c, a
    ld   hl, $8800
_LABEL_4962_:
    ld   a, [de]
    sub  $63
    push de
    dec  b
    ld   b, a
    jr   z, _LABEL_4973_
    sla  b
    ld   de, $38FA
    ld   a, $02
    jr   _LABEL_4978_

_LABEL_4973_:
    ld   de, $372A
    ld   a, $01
_LABEL_4978_:
    call _LABEL_48CD_
    pop  de
    pop  bc
    inc  c
    dec  b
    jr   z, _LABEL_4982_
    inc  c
_LABEL_4982_:
    inc  b
    inc  de
    jr   _LABEL_494E_

_LABEL_4986_:
    ld   hl, _TILEMAP0; $9800
    call calc_vram_addr_of_tile_xy_base_in_hl__4932_
    pop  bc
    pop  de
    call wait_until_vbl__92C_
_LABEL_4991_:
    ld   a, [de]
    cp   $00
    inc  de
    ret  z
    dec  de
    ld   a, c
    ldi  [hl], a
    ld   a, l
    and  $07
    cp   $00
    jr   nz, _LABEL_49A3_
    call wait_until_vbl__92C_
_LABEL_49A3_:
    push bc
    dec  b
    pop  bc
    jr   z, _LABEL_49BE_
    push de
    ld   d, $00
    ld   e, $1F
    push hl
    add  hl, de
    inc  c
    ld   a, c
    ldi  [hl], a
    ld   l, a
    and  $0F
    cp   $00
    jr   nz, _LABEL_49BC_
    call wait_until_vbl__92C_
_LABEL_49BC_:
    pop  hl
    pop  de
_LABEL_49BE_:
    inc  c
    inc  de
    jr   _LABEL_4991_


; TODO: checks buttons...
; Maps D-Pad button presses to keycode input
;
; - Reads from: buttons_new_pressed__RAM_D006_
; - Writes to : maybe_input_key_new_pressed__RAM_D025_
;
; - Performs opposite function of input_map_keycodes_to_gamepad_buttons__4D30_
;
; Destroys A
input_map_gamepad_buttons_to_keycodes__49C2_:
    call timer_wait_tick_AND_TODO__289_  ; TODO: still not sure all of what this is doing
    call maybe_input_read_keys__C8D_
    ld   a, [buttons_new_pressed__RAM_D006_]
    cp   $00
    ret  z

    bit  PADB_START, a  ; 3, a
    jr   nz, _handle_btn_start__4A00_
    bit  PADB_SELECT, a  ; 2, a
    jr   nz, _handle_btn_select__49FA_
    bit  PADB_A, a  ; 0, a
    jr   nz, _handle_btn_a__49EE_
    bit  PADB_B, a  ; 1, a
    jr   nz, _handle_btn_b__49F4_

    bit  PADB_RIGHT, a  ; 4, a
    jr   nz, handle_joy_right__4A06_
    bit  PADB_LEFT, a  ; 5, a
    jr   nz, handle_joy_left__4A14_
    bit  PADB_UP, a  ; 6, a
    jr   nz, handle_joy_up__4A22_
    bit  PADB_DOWN, a  ; 7, a
    jr   nz, handle_joy_down__4A28_

    ; Handle A/B/Start/Select mapping
    _handle_btn_a__49EE_:
        ld   a, SYS_KEY_A  ; $44
        ld   [maybe_input_key_new_pressed__RAM_D025_], a
        ret

    _handle_btn_b__49F4_:
        ld   a, SYS_KEY_B  ; $45
        ld   [maybe_input_key_new_pressed__RAM_D025_], a
        ret

    _handle_btn_select__49FA_:
        ld   a, SYS_KEY_SELECT  ; $2E
        ld   [maybe_input_key_new_pressed__RAM_D025_], a
        ret

    _handle_btn_start__4A00_:
        ld   a, SYS_KEY_START  ; $2A
        ld   [maybe_input_key_new_pressed__RAM_D025_], a
        ret

    ; Handle Joypad mapping
    handle_joy_right__4A06_:
        bit  6, a
        jr   nz, handle_joy_up_and_right___4A2E_
        bit  7, a
        jr   nz, handle_joy_down_and_right___4A34_
        ld   a, SYS_KEY_RIGHT  ; $3F
        ld   [maybe_input_key_new_pressed__RAM_D025_], a
        ret

    handle_joy_left__4A14_:
        bit  6, a
        jr   nz, handle_joy_up_and_left__4A3A_
        bit  7, a
        jr   nz, handle_joy_down_and_left__4A40_
        ld   a, SYS_KEY_LEFT  ; $3E
        ld   [maybe_input_key_new_pressed__RAM_D025_], a
        ret

    handle_joy_up__4A22_:
        ld   a, SYS_KEY_UP  ; $3D
        ld   [maybe_input_key_new_pressed__RAM_D025_], a
        ret

    handle_joy_down__4A28_:
        ld   a, SYS_KEY_DOWN  ; $40
        ld   [maybe_input_key_new_pressed__RAM_D025_], a
        ret

        ; Extra mapping for JoyPad diagonals
        handle_joy_up_and_right___4A2E_:
            ld   a, SYS_KEY_UP_RIGHT  ; $CA
            ld   [maybe_input_key_new_pressed__RAM_D025_], a
            ret

        handle_joy_down_and_right___4A34_:
            ld   a, SYS_KEY_DOWN_RIGHT  ; $CB
            ld   [maybe_input_key_new_pressed__RAM_D025_], a
            ret

        handle_joy_up_and_left__4A3A_:
            ld   a, SYS_KEY_UP_LEFT  ; $CD
            ld   [maybe_input_key_new_pressed__RAM_D025_], a
            ret

        handle_joy_down_and_left__4A40_:
            ld   a, SYS_KEY_DOWN_LEFT  ; $CC
            ld   [maybe_input_key_new_pressed__RAM_D025_], a
            ret


; Draws a text string to the Tilemap at X,Y
;
; - Encoded text string to render       : DE
; - Start at Tilemap (X,Y)              : H,L
; - Render mode (1 = Normal, 0 = Erase) : C
render_string_at_de_to_tilemap0_xy_in_hl__4A46_:
    push bc
    ; Calculate offset into VRAM base address for Tilemap X,Y
    ld   a, h
    ld   [_tilemap_pos_x__RAM_C8CB_], a  ; h -> Tilemap X
    ld   a, l
    ld   [_tilemap_pos_y__RAM_C8CA_], a  ; l -> Tilemap Y
    push de
    ld   hl, _TILEMAP0  ; $9800
    call calc_vram_addr_of_tile_xy_base_in_hl__4932_
    pop  de

    ; Wait for VBlank before continuing
    call wait_until_vbl__92C_

    ; Check to see if the text should be rendered normally (C != 0)
    ; or if the string should be rendered as Blank Spaces (i.e. erase)
    pop  bc
    ld   a, c
    cp   PRINT_ERASE
    jr   z, _loop_erase_chars_to_tilemap__4A68_
    ; Print Normal
    ;
    ; Render string characters into the Tilemap at HL
    ; until a string terminator is reached, then return
    _loop_str_chars_to_tilemap__4A60_:
        ld   a, [de]
        inc  de
        cp   STR_TERMINATOR  ; $00
        ret  z
        ldi  [hl], a
        jr _loop_str_chars_to_tilemap__4A60_

    ; Print Erase
    ; Note: This mode doesn't seem to get used by anything
    ;
    ; Write Space Characters ($BE) into the Tilemap at HL
    ; ignoring the actual character values
    ; until a string terminator is reached, then return
    _loop_erase_chars_to_tilemap__4A68_:
        ld   a, [de]
        inc  de
        cp   STR_TERMINATOR  ; $00
        ret  z
        ld   a, CHAR_BLANKSPACE  ; $BE
        ldi  [hl], a
        jr   _loop_erase_chars_to_tilemap__4A68_


; TODO:
_LABEL_4A72_:
    push af
    call timer_wait_tick_AND_TODO__289_
    pop  af
    dec  a
    jr   nz, _LABEL_4A72_
    ret

_LABEL_4A7B_:
    call _LABEL_4875_
    xor  a
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    ld   a, $03
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    ld   c, $00
_LABEL_4A89_:
    ld   a, $01
    ld   [_tilemap_pos_x__RAM_C8CB_], a
_LABEL_4A8E_:
    ld   d, $03
    push bc
    push de
    ld  hl, _TILEMAP0; $9800
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    dec  a
    ld   b, $20
    call multiply_a_x_b__result_in_de__4853_
    add  hl, de
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    ld   e, a
    ld   d, $00
    add  hl, de
    ld   c, $03
    call wait_until_vbl__92C_
_LABEL_4AAB_:
    ld   a, [maybe_vram_data_to_write__RAM_C8CC_]
    ld   b, $03
_LABEL_4AB0_:
    ld   [hl], a
    inc  a
    inc  hl
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    dec  b
    jr   nz, _LABEL_4AB0_
    xor  d
    ld   e, $1D
    add  hl, de
    dec  c
    jr   nz, _LABEL_4AAB_
    pop  de
    pop  bc
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    add  $05
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    inc  c
    ld   a, [_RAM_D06D_]    ; _RAM_D06D_ = $D06D
    cp   c
    jr   z, _LABEL_4AE6_
    ld   a, c
    cp   $04
    jr   z, _LABEL_4ADC_
    cp   $08
    jr   z, _LABEL_4ADC_
    jr   _LABEL_4A8E_

_LABEL_4ADC_:
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    add  $05
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    jr   _LABEL_4A89_

; TODO: maybe initializing the main menu
_LABEL_4AE6_:
    ld   a, $28
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    ld   a, $09
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    call _LABEL_4CD1_
    ldh  a, [rLCDC]
    and  $CF
    or   $C1
    ldh  [rLCDC], a
    xor  a
    ld   [_RAM_D06E_], a    ; TODO: maybe main menu action index
    ld   [_RAM_D05D_], a    ; _RAM_D05D_ = $D05D
    ld   [_RAM_D05E_], a    ; _RAM_D05E_ = $D05E
    ld   [_RAM_D05C_], a    ; _RAM_D05C_ = $D05C
    ld   [_RAM_D05B_], a    ; _RAM_D05B_ = $D05B
    call maybe_input_wait_for_keys__4B84
; TODO: maybe this is the main menu loop
_LABEL_4B0E_:
    call timer_wait_tick_AND_TODO__289_
    call maybe_input_read_keys__C8D_
    ld   hl, _RAM_D06D_ ; _RAM_D06D_ = $D06D
    ld   a, [maybe_input_key_new_pressed__RAM_D025_]

    cp   SYS_KEY_SELECT  ; $2E
    jp   z, _LABEL_4C83_

    cp   SYS_KEY_START  ; $2A
    jp   z, _LABEL_4C76_

    cp   $2F
    jp   z, _LABEL_4C70_

    sub  $30
    jr   c, _LABEL_4B36_
    cp   [hl]
    jr   nc, _LABEL_4B36_
    ld   [_RAM_D06E_], a
    jp   _LABEL_4C83_

_LABEL_4B36_:
    call input_map_keycodes_to_gamepad_buttons__4D30_
    ld   a, [buttons_new_pressed__RAM_D006_]
    ; Mask out to U/D/L/R/SEL only
    and  (PADF_DOWN | PADF_UP | PADF_LEFT | PADF_RIGHT | PADF_SELECT) ; $F4
    jr   nz, _LABEL_4B4F_
    xor  a
    ld   [_RAM_D05D_], a    ; _RAM_D05D_ = $D05D
    ld   [_RAM_D05E_], a    ; _RAM_D05E_ = $D05E
    ld   [_RAM_D05C_], a    ; _RAM_D05C_ = $D05C
    ld   [_RAM_D05B_], a    ; _RAM_D05B_ = $D05B
    jr   _LABEL_4B0E_

_LABEL_4B4F_:
    bit  2, a
    jp   nz, _LABEL_4C83_
    call _LABEL_4C87_
    ld   a, [_RAM_D05E_]    ; _RAM_D05E_ = $D05E
    cp   $01
    jr   z, _LABEL_4B92_
    ld   a, [_RAM_D05D_]    ; _RAM_D05D_ = $D05D
    cp   $01
    jr   z, _LABEL_4BD7_
    ld   a, [_RAM_D05C_]    ; _RAM_D05C_ = $D05C
    cp   $01
    jp   z, _LABEL_4C47_
    ld   a, [_RAM_D05B_]    ; _RAM_D05B_ = $D05B
    cp   $01
    jp   z, _LABEL_4C1A_
    jp   _LABEL_4B0E_


_LABEL_4B78_:
    call timer_wait_tick_AND_TODO__289_
    call timer_wait_tick_AND_TODO__289_
    call timer_wait_tick_AND_TODO__289_
    jp   _LABEL_4B0E_


; TODO: Maybe waits for an input key press
maybe_input_wait_for_keys__4B84:
    call timer_wait_tick_AND_TODO__289_
    call maybe_input_read_keys__C8D_
    ld   a, [maybe_input_key_new_pressed__RAM_D025_]
    cp   SYS_KEY_MAYBE_INVALID_OR_NODATA  ; $FF
    jr   nz, maybe_input_wait_for_keys__4B84
    ret

_LABEL_4B92_:
    xor  a
    ld   [_RAM_D05E_], a    ; _RAM_D05E_ = $D05E
    ld   a, [_RAM_D06E_]
    inc  a
    ld   hl, _RAM_D06D_ ; _RAM_D06D_ = $D06D
    cp   [hl]
    jp   nc, _LABEL_4B0E_
    push af
    ld   [_RAM_D06E_], a
    ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call _LABEL_953_
    call _LABEL_4D19_
    pop  af
    cp   $04
    jr   z, _LABEL_4BC4_
    cp   $08
    jr   z, _LABEL_4BC4_
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    add  $28
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    jr   _LABEL_4BD1_

_LABEL_4BC4_:
    ld   a, $09
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    add  $28
    ld   [_tilemap_pos_y__RAM_C8CA_], a
_LABEL_4BD1_:
    call _LABEL_4CD1_
    jp   _LABEL_4B78_

_LABEL_4BD7_:
    xor  a
    ld   [_RAM_D05D_], a    ; _RAM_D05D_ = $D05D
    ld   a, [_RAM_D06E_]
    dec  a
    cp   $FF
    jp   z, _LABEL_4B0E_
    push af
    ld   [_RAM_D06E_], a
    ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call _LABEL_953_
    call _LABEL_4D19_
    pop  af
    cp   $07
    jr   z, _LABEL_4C07_
    cp   $03
    jr   z, _LABEL_4C07_
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    sub  $28
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    jr   _LABEL_4C14_

_LABEL_4C07_:
    ld   a, $81
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    sub  $28
    ld   [_tilemap_pos_y__RAM_C8CA_], a
_LABEL_4C14_:
    call _LABEL_4CD1_
    jp   _LABEL_4B78_

_LABEL_4C1A_:
    xor  a
    ld   [_RAM_D05B_], a    ; _RAM_D05B_ = $D05B
    ld   a, [_RAM_D06E_]
    add  $04
    ld   hl, _RAM_D06D_ ; _RAM_D06D_ = $D06D
    cp   [hl]
    jp   nc, _LABEL_4B0E_
    ld   [_RAM_D06E_], a
    ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call _LABEL_953_
    call _LABEL_4D19_
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    add  $28
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    call _LABEL_4CD1_
    jp   _LABEL_4B78_

_LABEL_4C47_:
    xor  a
    ld   [_RAM_D05C_], a    ; _RAM_D05C_ = $D05C
    ld   a, [_RAM_D06E_]
    sub  $04
    jp   c, _LABEL_4B0E_
    ld   [_RAM_D06E_], a
    ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call _LABEL_953_
    call _LABEL_4D19_
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    sub  $28
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    call _LABEL_4CD1_
    jp   _LABEL_4B78_

_LABEL_4C70_:
    call _LABEL_522_
    jp   _LABEL_4B0E_

_LABEL_4C76_:
    ld   a, [_RAM_D06C_]    ; _RAM_D06C_ = $D06C
    and  a
    jp   z, _LABEL_4B0E_
    ld   a, [_RAM_D06D_]    ; _RAM_D06D_ = $D06D
    ld   [_RAM_D06E_], a
_LABEL_4C83_:
    call _LABEL_4D19_
    ret

_LABEL_4C87_:
    bit  4, a
    jr   z, _LABEL_4C93_
    ld   a, [_RAM_D05E_]    ; _RAM_D05E_ = $D05E
    inc  a
    res  7, a
    jr   _LABEL_4C94_

_LABEL_4C93_:
    xor  a
_LABEL_4C94_:
    ld   [_RAM_D05E_], a    ; _RAM_D05E_ = $D05E
    ld   a, [buttons_new_pressed__RAM_D006_]
    bit  5, a
    jr   z, _LABEL_4CA6_
    ld   a, [_RAM_D05D_]    ; _RAM_D05D_ = $D05D
    inc  a
    res  7, a
    jr   _LABEL_4CA7_

_LABEL_4CA6_:
    xor  a
_LABEL_4CA7_:
    ld   [_RAM_D05D_], a    ; _RAM_D05D_ = $D05D
    ld   a, [buttons_new_pressed__RAM_D006_]
    bit  6, a
    jr   z, _LABEL_4CB9_
    ld   a, [_RAM_D05C_]    ; _RAM_D05C_ = $D05C
    inc  a
    res  7, a
    jr   _LABEL_4CBA_

_LABEL_4CB9_:
    xor  a
_LABEL_4CBA_:
    ld   [_RAM_D05C_], a    ; _RAM_D05C_ = $D05C
    ld   a, [buttons_new_pressed__RAM_D006_]
    bit  7, a
    jr   z, _LABEL_4CCC_
    ld   a, [_RAM_D05B_]    ; _RAM_D05B_ = $D05B
    inc  a
    res  7, a
    jr   _LABEL_4CCD_

_LABEL_4CCC_:
    xor  a
_LABEL_4CCD_:
    ld   [_RAM_D05B_], a    ; _RAM_D05B_ = $D05B
    ret

_LABEL_4CD1_:
    ld   a, $ED
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    xor  a
    ld   [_RAM_C8CD_], a    ; _RAM_C8CD_ = $C8CD
    ld   hl, _RAM_D05F_ ; _RAM_D05F_ = $D05F
    ld   b, $02
_LABEL_4CDF_:
    push bc
    push hl
    call oam_find_slot_and_load_into__86F
    pop  hl
    ld   a, b
    ldi  [hl], a
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    add  $08
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   a, [maybe_vram_data_to_write__RAM_C8CC_]
    inc  a
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    push hl
    call oam_find_slot_and_load_into__86F
    pop  hl
    ld   a, b
    ldi  [hl], a
    pop  bc
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    add  $08
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    sub  $08
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   a, [maybe_vram_data_to_write__RAM_C8CC_]
    inc  a
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    dec  b
    jr   nz, _LABEL_4CDF_
    ret

; TODO: is this lookup for writing strings
_LABEL_4D19_:
    ld   c, $04
    ld   hl, _RAM_D05F_ ; _RAM_D05F_ = $D05F
_LABEL_4D1E_:
    ld   a, [hl]
    ld   [hl], $00
    inc  hl
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    push hl
    push bc
    call oam_free_slot_and_clear__89B_
    pop  bc
    pop  hl
    dec  c
    jr   nz, _LABEL_4D1E_
    ret

; Maps keycode input to D-Pad button presses
;
; - Reads from: maybe_input_key_new_pressed__RAM_D025_
; - Writes to : buttons_new_pressed__RAM_D006_
;
; - Performs opposite function of input_map_gamepad_buttons_to_keycodes__49C2_
;
; Destroys A, HL
input_map_keycodes_to_gamepad_buttons__4D30_:
    ld   a, [maybe_input_key_new_pressed__RAM_D025_]
    ld   hl, buttons_new_pressed__RAM_D006_
    cp   $3D
    jr   nz, check_down__4d3c_
    set  PADB_UP, [hl]  ; 6, [hl]
    check_down__4d3c_:
        cp   SYS_KEY_DOWN  ; $40
        jr   nz, check_left__4d42_
        set  PADB_DOWN, [hl]  ; 7, [hl]

    check_left__4d42_:
        cp   SYS_KEY_LEFT  ; $3E
        jr   nz, check_right__4d48_
        set  PADB_LEFT, [hl]  ; 5, [hl]

    check_right__4d48_:
        cp   SYS_KEY_RIGHT  ; $3F
        jr   nz, check_up_left__4d4e_
        set  PADB_RIGHT, [hl]  ; 4, [hl]

    check_up_left__4d4e_:
        cp   SYS_KEY_UP_LEFT  ; $CD
        jr   nz, check_up_right__4d56_
        set  PADB_LEFT, [hl]  ; 5, [hl]
        set  PADB_UP, [hl]  ; 6, [hl]

    check_up_right__4d56_:
        cp   SYS_KEY_UP_RIGHT  ; $CA
        jr   nz, check_down_left__4d5e_
        set  PADB_RIGHT, [hl]  ; 4, [hl]
        set  PADB_UP, [hl]  ; 6, [hl]

    check_down_left__4d5e_:
        cp   SYS_KEY_DOWN_LEFT  ; $CC
        jr   nz, check_down_right__4d66_
        set  PADB_LEFT, [hl]  ; 5, [hl]
        set  PADB_DOWN, [hl]  ; 7, [hl]

    check_down_right__4d66_:
        cp   SYS_KEY_DOWN_RIGHT  ; $CB
        jr   nz, done__4D6E_
        set  PADB_RIGHT, [hl]  ; 4, [hl]
        set  PADB_DOWN, [hl]  ; 7, [hl]
    done__4D6E_:
        ret


_LABEL_4D6F_:
    ld   a, [_RAM_DBFB_]    ; _RAM_DBFB_ = $DBFB
    bit  2, a
    jr   nz, _LABEL_4D7F_
    set  2, a
    ld   [_RAM_DBFB_], a    ; _RAM_DBFB_ = $DBFB
    xor  a
    ld   [_RAM_DBFE_ + 1], a    ; _RAM_DBFE_ + 1 = $DBFF
_LABEL_4D7F_:
    xor  a
    ld   [_RAM_D05D_], a    ; _RAM_D05D_ = $D05D
    ld   [_RAM_D05E_], a    ; _RAM_D05E_ = $D05E
    ld   [_RAM_D05C_], a    ; _RAM_D05C_ = $D05C
    ld   [_RAM_D05B_], a    ; _RAM_D05B_ = $D05B
    ld   [_RAM_D03B_], a    ; _RAM_D03B_ = $D03B
    ld   a, $0C
    ld   [_RAM_D036_], a    ; _RAM_D036_ = $D036
_LABEL_4D94_:
    call _LABEL_AEF_
    ld   a, [maybe_input_key_new_pressed__RAM_D025_]
    cp   $F9
    jr   nz, _LABEL_4D94_
    call wait_until_vbl__92C_
    call _LABEL_94C_
    ld   hl, $8800
    ld   de, $2F2A
    ld   bc, _wait_loop__703_ - 3   ; _wait_loop__703_ - 3 = $0800
    call _memcopy_in_RAM__C900_ ; Possibly invalid
    call wait_until_vbl__92C_
    call _LABEL_94C_
    ld   hl, $9000
    ld   de, $27FA
    ld   bc, _wait_loop__703_ - 3   ; _wait_loop__703_ - 3 = $0800
    call _memcopy_in_RAM__C900_ ; Possibly invalid
    ld   hl, _RAM_D028_ ; _RAM_D028_ = $D028
    ld   de, _RAM_D074_ + 1 ; _RAM_D074_ + 1 = $D075
    ld   b, $03
    call _LABEL_482B_
_LABEL_4DCD_:
    call _LABEL_4875_
    call wait_until_vbl__92C_
    call _LABEL_94C_
    ld   hl, _DATA_275A_
    ld   de, $8F10
    ld   b, $A0
    call _LABEL_482B_
    ld   hl, $9820
    ld   bc, $1002
    ld   a, $18
_LABEL_4DE9_:
    ldi  [hl], a
    dec  b
    jr   nz, _LABEL_4DE9_
    ld   de, _RST__10_  ; _RST__10_ = $0010
    add  hl, de
    ld   b, $10
    dec  c
    jr   nz, _LABEL_4DE9_
    ld   a, [_RAM_D028_ + 1]    ; _RAM_D028_ + 1 = $D029
    bit  4, a
    jr   z, _LABEL_4DFF_
    sub  $06
_LABEL_4DFF_:
    dec  a
    ld   b, $03
    call multiply_a_x_b__result_in_de__4853_
    ld   hl, _DATA_5E31_    ; _DATA_5E31_ = $5E31
    add  hl, de
    ld   d, h
    ld   e, l
    ld   b, $03
    ld   hl, $982B
_LABEL_4E10_:
    ld   a, [de]
    inc  de
    sub  $81
    sla  a
    add  $1A
    ld   c, $00
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    push de
    call maybe__vram_write_byte_2rows_addr_in_hl_preset_data__5494_
    pop  de
    inc  hl
    dec  b
    jr   nz, _LABEL_4E10_
    ld   hl, $9830
    ld   a, [_RAM_D028_]    ; _RAM_D028_ = $D028
    and  $F0
    cp   $90
    jr   nz, _LABEL_4E3E_
    ld   a, $02
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call maybe__vram_write_byte_2rows_addr_in_hl_preset_data__5494_
    ld   a, $12
    jr   _LABEL_4E48_

_LABEL_4E3E_:
    ld   a, $04
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call maybe__vram_write_byte_2rows_addr_in_hl_preset_data__5494_
    ld   a, $00
_LABEL_4E48_:
    inc  hl
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call maybe__vram_write_byte_2rows_addr_in_hl_preset_data__5494_
    ld   a, $10
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   a, $02
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    ld   c, $01
    ld   hl, _RAM_D028_ ; _RAM_D028_ = $D028
    call _LABEL_5401_
    ld   hl, $9880
    ld   b, $07
    ld   de, _DATA_5E19_    ; _DATA_5E19_ = $5E19
_LABEL_4E69_:
    ld   a, [de]
    inc  de
    ldi  [hl], a
    ld   a, [de]
    inc  de
    inc  de
    ldi  [hl], a
    inc  hl
    dec  b
    jr   nz, _LABEL_4E69_
    ld   a, [_RAM_D028_]    ; _RAM_D028_ = $D028
    ld   [_RAM_D051_], a    ; _RAM_D051_ = $D051
    ld   a, [_RAM_D028_ + 1]    ; _RAM_D028_ + 1 = $D029
    ld   [_RAM_D052_], a    ; _RAM_D052_ = $D052
    ld   a, $01
    ld   [_RAM_D053_], a    ; _RAM_D053_ = $D053
    call _LABEL_5A9F_
    ld   a, [_RAM_D054_]    ; _RAM_D054_ = $D054
    dec  a
    ld   [_RAM_D054_], a    ; _RAM_D054_ = $D054
    ld   a, [de]
    ld   [_RAM_D06D_], a    ; _RAM_D06D_ = $D06D
    ld   e, a
    ld   d, $00
    ld   h, $0A
    call _LABEL_4832_
    ld   a, c
    swap a
    or   l
    ld   [_RAM_D03A_], a    ; _RAM_D03A_ = $D03A
    xor  a
    ld   [_RAM_D06E_], a
    ld   a, $07
    ld   [_tilemap_pos_y__RAM_C8CA_], a
_LABEL_4EAB_:
    ld   a, [_RAM_D054_]    ; _RAM_D054_ = $D054
    ld   b, $03
    call multiply_a_x_b__result_in_de__4853_
    ld   a, e
    sub  $02
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   a, [_RAM_D03B_]    ; _RAM_D03B_ = $D03B
    and  a
    jr   nz, _LABEL_4ED4_
    ld   a, [_RAM_D053_]    ; _RAM_D053_ = $D053
    ld   hl, _RAM_D074_ + 3 ; _RAM_D074_ + 3 = $D077
    cp   [hl]
    jr   nz, _LABEL_4ED4_
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    ld   [_RAM_D073_], a    ; _RAM_D073_ = $D073
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    ld   [_RAM_D074_], a    ; _RAM_D074_ = $D074
_LABEL_4ED4_:
    ld   a, [_RAM_D053_]    ; _RAM_D053_ = $D053
    cp   $01
    jr   nz, _LABEL_4F29_
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    ld   [_RAM_D06E_ + 2], a    ; _RAM_D06E_ + 2 = $D070
    add  $02
    sla  a
    sla  a
    sla  a
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    ld   [_RAM_D06E_ + 1], a    ; _RAM_D06E_ + 1 = $D06F
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
    ld   a, [_RAM_D06E_ + 2]    ; _RAM_D06E_ + 2 = $D070
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    ld   a, b
    ld   [_RAM_D06E_ + 2], a    ; _RAM_D06E_ + 2 = $D070
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    ld   b, a
    ld   a, [_RAM_D06E_ + 1]    ; _RAM_D06E_ + 1 = $D06F
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   a, b
    ld   [_RAM_D06E_ + 1], a    ; _RAM_D06E_ + 1 = $D06F
_LABEL_4F29_:
    call _LABEL_532F_
    cp   $00
    jr   nz, _LABEL_4F3A_
    ld   hl, _RAM_D053_ ; _RAM_D053_ = $D053
    ld   c, $02
    call _LABEL_5401_
    jr   _LABEL_4F3D_

_LABEL_4F3A_:
    call _LABEL_52F5_
_LABEL_4F3D_:
    ld   a, [_RAM_D053_]    ; _RAM_D053_ = $D053
    and  $0F
    inc  a
    cp   $0A
    ld   a, [_RAM_D053_]    ; _RAM_D053_ = $D053
    jr   z, _LABEL_4F4D_
    inc  a
    jr   _LABEL_4F51_

_LABEL_4F4D_:
    and  $F0
    add  $10
_LABEL_4F51_:
    ld   [_RAM_D053_], a    ; _RAM_D053_ = $D053
    ld   b, a
    ld   a, [_RAM_D03A_]    ; _RAM_D03A_ = $D03A
    cp   b
    jr   c, _LABEL_4F72_
    ld   a, [_RAM_D054_]    ; _RAM_D054_ = $D054
    inc  a
    cp   $07
    jr   nz, _LABEL_4F6C_
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    add  $02
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    xor  a
_LABEL_4F6C_:
    ld   [_RAM_D054_], a    ; _RAM_D054_ = $D054
    jp   _LABEL_4EAB_

_LABEL_4F72_:
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    inc  a
    sla  a
    sla  a
    sla  a
    ld   [_RAM_D06E_ + 3], a    ; _RAM_D06E_ + 3 = $D071
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    add  $02
    sla  a
    sla  a
    sla  a
    ld   [_RAM_D072_], a
    ld   a, $01
    ld   [_RAM_D03A_], a    ; _RAM_D03A_ = $D03A
    call _display_bg_sprites_on__627_
_LABEL_4F95_:
    call timer_wait_tick_AND_TODO__289_
    call maybe_input_read_keys__C8D_
    ld   a, [_RAM_D074_ + 1]    ; _RAM_D074_ + 1 = $D075
    ld   hl, _RAM_D028_ ; _RAM_D028_ = $D028
    cp   [hl]
    jr   nz, _LABEL_4FAE_
    ld   a, [_RAM_D074_ + 2]    ; _RAM_D074_ + 2 = $D076
    inc  hl
    cp   [hl]
    jr   nz, _LABEL_4FAE_
    call _LABEL_538C_
_LABEL_4FAE_:
    ld   a, [maybe_input_key_new_pressed__RAM_D025_]
    cp   $2F
    jp   nz, _LABEL_4FEE_
    ld   a, [_RAM_D074_ + 1]    ; _RAM_D074_ + 1 = $D075
    push af
    ld   a, [_RAM_D074_ + 2]    ; _RAM_D074_ + 2 = $D076
    push af
    ld   a, [_RAM_D074_ + 3]    ; _RAM_D074_ + 3 = $D077
    push af
    ld   a, [_RAM_D028_]    ; _RAM_D028_ = $D028
    push af
    ld   a, [_RAM_D028_ + 1]    ; _RAM_D028_ + 1 = $D029
    push af
    ld   a, [_RAM_D028_ + 2]    ; _RAM_D028_ + 2 = $D02A
    push af
    call _LABEL_52BF_
    call maybe_input_wait_for_keys__4B84
    pop  af
    ld   [_RAM_D028_ + 2], a    ; _RAM_D028_ + 2 = $D02A
    pop  af
    ld   [_RAM_D028_ + 1], a    ; _RAM_D028_ + 1 = $D029
    pop  af
    ld   [_RAM_D028_], a    ; _RAM_D028_ = $D028
    pop  af
    ld   [_RAM_D074_ + 3], a    ; _RAM_D074_ + 3 = $D077
    pop  af
    ld   [_RAM_D074_ + 2], a    ; _RAM_D074_ + 2 = $D076
    pop  af
    ld   [_RAM_D074_ + 1], a    ; _RAM_D074_ + 1 = $D075
    jr   _LABEL_4F95_

_LABEL_4FEE_:
    cp   $2E
    jp   z, _LABEL_51B0_
    cp   $2A
    jp   z, _LABEL_52B5_
    cp   $44
    jp   z, _LABEL_522B_
    cp   $45
    jp   z, _LABEL_526F_
    call input_map_keycodes_to_gamepad_buttons__4D30_
    ld   a, [buttons_new_pressed__RAM_D006_]
    and  $F7
    jr   nz, _LABEL_5022_
    xor  a
    ld   [_RAM_D05D_], a    ; _RAM_D05D_ = $D05D
    ld   [_RAM_D05E_], a    ; _RAM_D05E_ = $D05E
    ld   [_RAM_D05B_], a    ; _RAM_D05B_ = $D05B
    ld   [_RAM_D05C_], a    ; _RAM_D05C_ = $D05C
    call delay_quarter_msec__BD6_
    call delay_quarter_msec__BD6_
    jp   _LABEL_4F95_

_LABEL_5022_:
    ld   a, [buttons_new_pressed__RAM_D006_]
    bit  PADB_SELECT, a  ; 2, a
    jp   nz, _LABEL_51B0_
    bit  PADB_A, a  ; 0, a
    jp   nz, _LABEL_522B_
    bit  PADB_B, a  ; 1, a
    jp   nz, _LABEL_526F_

    call _LABEL_4C87_
    ld   a, [_RAM_D05E_]    ; _RAM_D05E_ = $D05E
    cp   $01
    jr   z, _LABEL_5059_
    ld   a, [_RAM_D05D_]    ; _RAM_D05D_ = $D05D
    cp   $01
    jp   z, _LABEL_50C3_
    ld   a, [_RAM_D05C_]    ; _RAM_D05C_ = $D05C
    cp   $01
    jp   z, _LABEL_5167_
    ld   a, [_RAM_D05B_]    ; _RAM_D05B_ = $D05B
    cp   $01
    jp   z, _LABEL_511F_
    jp   _LABEL_4F95_

_LABEL_5059_:
    xor  a
    ld   [_RAM_D05E_], a    ; _RAM_D05E_ = $D05E
    ld   a, [_RAM_D06E_]
    inc  a
    ld   hl, _RAM_D06D_ ; _RAM_D06D_ = $D06D
    cp   [hl]
    jr   nc, _LABEL_5096_
    ld   [_RAM_D06E_], a
    ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call _LABEL_953_
    call oam_free_slot_and_clear__89B_
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    cp   $A0
    jr   z, _LABEL_5087_
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    add  $18
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    jr   _LABEL_50AF_

_LABEL_5087_:
    ld   a, $10
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    add  $10
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    jr   _LABEL_50AF_

_LABEL_5096_:
    ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call oam_free_slot_and_clear__89B_
    xor  a
    ld   [_RAM_D06E_], a
    ld   a, [_RAM_D06E_ + 1]    ; _RAM_D06E_ + 1 = $D06F
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   a, [_RAM_D06E_ + 2]    ; _RAM_D06E_ + 2 = $D070
    ld   [_tilemap_pos_y__RAM_C8CA_], a
_LABEL_50AF_:
    ld   a, $80
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call _LABEL_623_
    ld   a, b
    ld   [_RAM_D05F_], a    ; _RAM_D05F_ = $D05F
    ld   a, $03
    call _LABEL_4A72_
    jp   _LABEL_4F95_

_LABEL_50C3_:
    xor  a
    ld   [_RAM_D05D_], a    ; _RAM_D05D_ = $D05D
    ld   a, [_RAM_D06E_]
    dec  a
    cp   $FF
    jr   z, _LABEL_5100_
    ld   [_RAM_D06E_], a
    ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call _LABEL_953_
    call oam_free_slot_and_clear__89B_
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    cp   $10
    jr   z, _LABEL_50F0_
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    sub  $18
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    jp   _LABEL_50AF_

_LABEL_50F0_:
    ld   a, $A0
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    sub  $10
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    jp   _LABEL_50AF_

_LABEL_5100_:
    ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call oam_free_slot_and_clear__89B_
    ld   a, [_RAM_D06D_]    ; _RAM_D06D_ = $D06D
    dec  a
    ld   [_RAM_D06E_], a
    ld   a, [_RAM_D06E_ + 3]    ; _RAM_D06E_ + 3 = $D071
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   a, [_RAM_D072_]
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    jp   _LABEL_50AF_

_LABEL_511F_:
    xor  a
    ld   [_RAM_D05B_], a    ; _RAM_D05B_ = $D05B
    ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call _LABEL_953_
    call oam_free_slot_and_clear__89B_
    ld   a, [_RAM_D06E_]
    add  $07
    ld   hl, _RAM_D06D_ ; _RAM_D06D_ = $D06D
    cp   [hl]
    jr   nc, _LABEL_5148_
    ld   [_RAM_D06E_], a
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    add  $10
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    jp   _LABEL_50AF_

_LABEL_5148_:
    ld   a, [_RAM_D06E_]
    ld   e, a
    ld   d, $00
    ld   h, $07
    call _LABEL_4832_
    ld   a, c
    ld   b, $10
    call multiply_a_x_b__result_in_de__4853_
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    sub  e
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    ld   a, l
    ld   [_RAM_D06E_], a
    jp   _LABEL_50AF_

_LABEL_5167_:
    xor  a
    ld   [_RAM_D05C_], a    ; _RAM_D05C_ = $D05C
    ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call _LABEL_953_
    call oam_free_slot_and_clear__89B_
    ld   a, [_RAM_D06E_]
    sub  $07
    jr   c, _LABEL_518C_
    ld   [_RAM_D06E_], a
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    sub  $10
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    jp   _LABEL_50AF_

_LABEL_518C_:
    ld   a, [_RAM_D06E_]
    ld   b, $00
    ld   hl, _RAM_D06D_ ; _RAM_D06D_ = $D06D
_LABEL_5194_:
    add  $07
    cp   [hl]
    jr   nc, _LABEL_519C_
    inc  b
    jr   _LABEL_5194_

_LABEL_519C_:
    sub  $07
    ld   [_RAM_D06E_], a
    ld   a, $10
    call multiply_a_x_b__result_in_de__4853_
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    add  e
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    jp   _LABEL_50AF_

_LABEL_51B0_:
    ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call _LABEL_953_
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    cp   $A0
    jp   z, _LABEL_4F95_
    ld   a, [_RAM_D06E_]
    inc  a
    ld   e, a
    ld   d, $00
    ld   h, $0A
    call _LABEL_4832_
    ld   a, c
    swap a
    or   l
    ld   [_RAM_D053_], a    ; _RAM_D053_ = $D053
    ld   a, $01
    ld   [_RAM_D054_], a    ; _RAM_D054_ = $D054
    call _LABEL_532F_
    and  a
    jr   z, _LABEL_5206_
    ld   e, l
    ld   d, h
    dec  hl
    dec  hl
    dec  hl
_LABEL_51E4_:
    ld   a, [de]
    ldi  [hl], a
    inc  de
    ld   a, e
    cp   $FD
    jr   nz, _LABEL_51E4_
    ld   a, [_RAM_DBFE_ + 1]    ; _RAM_DBFE_ + 1 = $DBFF
    dec  a
    ld   [_RAM_DBFE_ + 1], a    ; _RAM_DBFE_ + 1 = $DBFF
    call _LABEL_535C_
    ld   hl, _RAM_D053_ ; _RAM_D053_ = $D053
    ld   c, $02
    call _LABEL_5401_
    ld   a, $03
    call _LABEL_4A72_
    jp   _LABEL_4F95_

_LABEL_5206_:
    ld   a, [_RAM_DBFE_ + 1]    ; _RAM_DBFE_ + 1 = $DBFF
    cp   $1E
    jp   nc, _LABEL_4F95_
    inc  a
    ld   [_RAM_DBFE_ + 1], a    ; _RAM_DBFE_ + 1 = $DBFF
    ld   de, _RAM_D051_ ; _RAM_D051_ = $D051
    ld   b, $03
_LABEL_5217_:
    ld   a, [de]
    ldi  [hl], a
    inc  de
    dec  b
    jr   nz, _LABEL_5217_
    call _LABEL_535C_
    call _LABEL_52F5_
    ld   a, $03
    call _LABEL_4A72_
    jp   _LABEL_4F95_

_LABEL_522B_:
    ld   hl, _RAM_D028_ + 1 ; _RAM_D028_ + 1 = $D029
    call _LABEL_5B03_
    dec  a
    jr   nz, _LABEL_525D_
    ld   hl, _RAM_D028_ ; _RAM_D028_ = $D028
    call _LABEL_5B03_
    cp   $0C
    jr   nc, _LABEL_5240_
    add  $64
_LABEL_5240_:
    dec  a
    cp   $5C
    jp   c, _LABEL_4F95_
    call _LABEL_5379_
    ld   [_RAM_D028_], a    ; _RAM_D028_ = $D028
    ld   a, $12
    ld   [_RAM_D028_ + 1], a    ; _RAM_D028_ + 1 = $D029
    ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call oam_free_slot_and_clear__89B_
    jp   _LABEL_4DCD_

_LABEL_525D_:
    call _LABEL_5379_
    ld   [_RAM_D028_ + 1], a    ; _RAM_D028_ + 1 = $D029
    ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call oam_free_slot_and_clear__89B_
    jp   _LABEL_4DCD_

_LABEL_526F_:
    ld   hl, _RAM_D028_ + 1 ; _RAM_D028_ + 1 = $D029
    call _LABEL_5B03_
    inc  a
    cp   $0D
    jr   c, _LABEL_52A3_
    ld   hl, _RAM_D028_ ; _RAM_D028_ = $D028
    call _LABEL_5B03_
    cp   $0C
    jr   nc, _LABEL_5286_
    add  $64
_LABEL_5286_:
    inc  a
    cp   $70
    jp   z, _LABEL_4F95_
    call _LABEL_5379_
    ld   [_RAM_D028_], a    ; _RAM_D028_ = $D028
    ld   a, $01
    ld   [_RAM_D028_ + 1], a    ; _RAM_D028_ + 1 = $D029
    ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call oam_free_slot_and_clear__89B_
    jp   _LABEL_4DCD_

_LABEL_52A3_:
    call _LABEL_5379_
    ld   [_RAM_D028_ + 1], a    ; _RAM_D028_ + 1 = $D029
    ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call oam_free_slot_and_clear__89B_
    jp   _LABEL_4DCD_

_LABEL_52B5_:
    ld   a, [_RAM_D05F_]    ; _RAM_D05F_ = $D05F
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call oam_free_slot_and_clear__89B_
    ret

_LABEL_52BF_:
    ld   a, [_RAM_D074_ + 1]    ; _RAM_D074_ + 1 = $D075
    ld   hl, _RAM_D028_ ; _RAM_D028_ = $D028
    cp   [hl]
    jr   nz, _LABEL_52D7_
    ld   a, [_RAM_D074_ + 2]    ; _RAM_D074_ + 2 = $D076
    inc  hl
    cp   [hl]
    jr   nz, _LABEL_52D7_
    ld   a, $07
    ld   [_RAM_D04A_], a    ; _RAM_D04A_ = $D04A
    call _LABEL_538C_
_LABEL_52D7_:
    ld   a, [_RAM_D028_ + 3]    ; _RAM_D028_ + 3 = $D02B
    push af
    call _LABEL_522_
    pop  af
    ld   [_RAM_D028_ + 3], a    ; _RAM_D028_ + 3 = $D02B
    ld   a, [_RAM_D074_ + 1]    ; _RAM_D074_ + 1 = $D075
    ld   [_RAM_D028_], a    ; _RAM_D028_ = $D028
    ld   a, [_RAM_D074_ + 2]    ; _RAM_D074_ + 2 = $D076
    ld   [_RAM_D028_ + 1], a    ; _RAM_D028_ + 1 = $D029
    ld   a, [_RAM_D074_ + 3]    ; _RAM_D074_ + 3 = $D077
    ld   [_RAM_D028_ + 2], a    ; _RAM_D028_ + 2 = $D02A
    ret

_LABEL_52F5_:
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    add  $02
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   hl, _TILEMAP0; $9800
    call calc_vram_addr_of_tile_xy_base_in_hl__4932_
    ld   a, [_RAM_D053_]    ; _RAM_D053_ = $D053
    swap a
    and  $0F
    jr   z, _LABEL_5310_
    add  $F1
    jr   _LABEL_5312_

_LABEL_5310_:
    ld   a, $BE
_LABEL_5312_:
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call wait_until_vbl__92C_
    ld   a, [maybe_vram_data_to_write__RAM_C8CC_]
    ldi  [hl], a
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    inc  a
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   a, [_RAM_D053_]    ; _RAM_D053_ = $D053
    and  $0F
    add  $F1
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    ld   [hl], a
    ret

_LABEL_532F_:
    ld   hl, $DBA0
    ld   a, [_RAM_D054_]    ; _RAM_D054_ = $D054
    cp   $06
    jr   z, _LABEL_5359_
    ld   a, [_RAM_DBFE_ + 1]    ; _RAM_DBFE_ + 1 = $DBFF
    and  a
    jr   z, _LABEL_5357_
    ld   b, a
_LABEL_5340_:
    ld   de, _RAM_D051_ ; _RAM_D051_ = $D051
    ld   c, $03
_LABEL_5345_:
    ld   a, [de]
    cp   [hl]
    jr   nz, _LABEL_5350_
    inc  hl
    inc  de
    dec  c
    jr   nz, _LABEL_5345_
    jr   _LABEL_5359_

_LABEL_5350_:
    ld   a, c
    call _LABEL_486E_
    dec  b
    jr   nz, _LABEL_5340_
_LABEL_5357_:
    xor  a
    ret

_LABEL_5359_:
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
    call _LABEL_4832_
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
    ld   a, [_RAM_D074_]    ; _RAM_D074_ = $D074
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    ld   a, [_RAM_D04A_]    ; _RAM_D04A_ = $D04A
    inc  a
    ld   [_RAM_D04A_], a    ; _RAM_D04A_ = $D04A
    and  $0F
    jr   z, _LABEL_53CC_
    cp   $08
    jr   nz, _LABEL_53CB_
    ld   a, [_RAM_D028_ + 2]    ; _RAM_D028_ + 2 = $D02A
    ld   [_RAM_D053_], a    ; _RAM_D053_ = $D053
    ld   a, [_RAM_D028_ + 3]    ; _RAM_D028_ + 3 = $D02B
    dec  a
    ld   [_RAM_D054_], a    ; _RAM_D054_ = $D054
    cp   $06
    jr   z, _LABEL_53C1_
    call _LABEL_532F_
    ld   hl, _RAM_D028_ + 2 ; _RAM_D028_ + 2 = $D02A
    and  a
    jr   z, _LABEL_53C6_
_LABEL_53C1_:
    call _LABEL_52F5_
    jr   _LABEL_53CB_

_LABEL_53C6_:
    ld   c, $02
    call _LABEL_5401_
_LABEL_53CB_:
    ret

_LABEL_53CC_:
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
    ld   a, TILEMAP_0  ; $00
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
    ld   a, TILEMAP_0  ; $00
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
    jr   z, _LABEL_542E_
    sla  a
    add  $00
    bit  1, c
    jr   z, _LABEL_5427_
    set  7, a
    bit  2, c
    jr   z, _LABEL_5427_
    cp   $80
    jr   nz, _LABEL_5427_
    ld   a, $98
_LABEL_5427_:
    push hl
    push bc
    call _LABEL_5480_
    jr   _LABEL_544F_

_LABEL_542E_:
    add  $C0
    cp   $C0
    jr   nz, _LABEL_543A_
    bit  2, c
    jr   nz, _LABEL_543A_
    ld   a, $BE
_LABEL_543A_:
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    push hl
    push bc
    bit  0, c
    jr   nz, _LABEL_544C_
    bit  1, c
    jr   nz, _LABEL_544C_
    call wait_vbl_write_byte_tilemap0_preset_xy_and_data__612_
    jr   _LABEL_544F_

_LABEL_544C_:
    call wait_vbl_write_byte_tilemap0_preset_xy_and_data__612_
_LABEL_544F_:
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    inc  a
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    pop  bc
    ld   a, b
    and  $0F
    bit  0, c
    jr   z, _LABEL_5472_
    sla  a
    add  $00
    bit  1, c
    jr   z, _LABEL_5468_
    set  7, a
_LABEL_5468_:
    call _LABEL_5480_
    jr   _LABEL_547E_

_LABEL_546D_:
    call wait_vbl_write_byte_tilemap0_preset_xy_and_data__612_
    jr   _LABEL_547E_

_LABEL_5472_:
    add  $C0
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    bit  1, c
    jr   nz, _LABEL_546D_
    call wait_vbl_write_byte_tilemap0_preset_xy_and_data__612_
_LABEL_547E_:
    pop  hl
    ret

_LABEL_5480_:
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    push bc
    push hl
    push de
    bit  1, c
    ld   hl, _TILEMAP0; $9800
    jr   z, _LABEL_5490_
    ld   hl, _TILEMAP0; $9800
_LABEL_5490_:
    call calc_vram_addr_of_tile_xy_base_in_hl__4932_
    call wait_until_vbl__92C_
    call maybe__vram_write_byte_2rows_addr_in_hl_preset_data__5494_
    pop  de
    pop  hl
    pop  bc
    ret


; Writes preset byte to vram HL, then writes (preset byte + 1) at the next row down
;
; - VRAM Address to write: HL
;
; Destroys A, DE
maybe__vram_write_byte_2rows_addr_in_hl_preset_data__5494_:
    ld   a, [maybe_vram_data_to_write__RAM_C8CC_]
    ld   [hl], a
    ld   d, $00
    ld   e, $20
    push hl
    add  hl, de
    inc  a
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    ld   [hl], a
    pop  hl
    ret


_LABEL_54AE_:
    ld   a, [_RAM_D059_]
    and  $F0
    cp   $C0
    jr   z, _LABEL_54BC_
    ld   a, $C0
    ld   [_RAM_D059_], a
_LABEL_54BC_:
    xor  a
    ld   [_RAM_D05A_], a
    call wait_until_vbl__92C_
    call _LABEL_94C_
    ld   de, $1FFA
    ld   bc, $0000
    ld   hl, $9000
    ld   a, $80
    call _LABEL_48CD_
    ld   de, $1BFA
    ld   bc, $0000
    ld   hl, $8000
    ld   a, $80
    call _LABEL_48CD_
    call wait_until_vbl__92C_
    call _LABEL_94C_
    ld   a, $00
    ld   de, _DATA_266A_
    call _LABEL_8C4_
    call wait_until_vbl__92C_
    call _LABEL_94C_
    ld   hl, $9980
_LABEL_54F9_:
    xor  a
    ldi  [hl], a
    ld   a, h
    cp   $9C
    jr   nz, _LABEL_54F9_
    ld   a, $0C
    ld   [_RAM_D036_], a    ; _RAM_D036_ = $D036
_LABEL_5505_:
    call _LABEL_AEF_
    call timer_wait_tick_AND_TODO__289_
    ld   a, [maybe_input_key_new_pressed__RAM_D025_]
    cp   $F9
    jr   nz, _LABEL_5505_
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
_LABEL_5532_:
    ldi  [hl], a
    dec  b
    jr   nz, _LABEL_5532_
    call _LABEL_5D50_
    call _LABEL_5B5F_
    call _LABEL_55A0_
    xor  a
    ld   [_RAM_D068_], a
    ld   [_RAM_D03B_], a    ; _RAM_D03B_ = $D03B
    ld   [_RAM_D1A7_], a    ; _RAM_D1A7_ = $D1A7
_LABEL_5549_:
    ld   a, [_RAM_D1A7_]    ; _RAM_D1A7_ = $D1A7
    inc  a
    ld   [_RAM_D1A7_], a    ; _RAM_D1A7_ = $D1A7
    cp   $04
    jr   nz, _LABEL_557B_
    xor  a
    ld   [_RAM_D1A7_], a    ; _RAM_D1A7_ = $D1A7
    ld   a, $0C
    ld   [_RAM_D035_ + 1], a    ; _RAM_D035_ + 1 = $D036
    call _LABEL_AEF_
    ld   a, [maybe_input_key_new_pressed__RAM_D025_]
    cp   $F9
    jr   nz, _LABEL_5579_
    call _LABEL_5D5F_
    ld   a, [_RAM_D03A_]    ; _RAM_D03A_ = $D03A
    and  a
    jr   z, _LABEL_5579_
    call _LABEL_5D50_
    call _LABEL_5B5F_
    call _LABEL_55A0_
_LABEL_5579_:
    jr   _LABEL_5549_

_LABEL_557B_:
    call timer_wait_tick_AND_TODO__289_
    call maybe_input_read_keys__C8D_
    ld   a, [buttons_new_pressed__RAM_D006_]
    ld   [_RAM_D03B_], a    ; _RAM_D03B_ = $D03B
    call _LABEL_56CB_
    ld   a, [_RAM_D05A_]
    and  a
    jr   nz, _LABEL_5599_
    ld   a, [_RAM_D06B_]
    and  a
    jp   nz, _LABEL_54BC_
    jr   _LABEL_5549_

_LABEL_5599_:
    ldh  a, [rLCDC]
    and  $FD
    ldh  [rLCDC], a
    ret

_LABEL_55A0_:
    ld   a, [_RAM_D059_]
    and  $0F
    and  a
    jr   nz, _LABEL_55CB_
    ld   hl, _RAM_D055_
    ldi  a, [hl]
    and  a
    ld   a, $90
    jr   nz, _LABEL_55B3_
    ld   a, $81
_LABEL_55B3_:
    ld   [_RAM_D400_], a
    ld   a, $8D
    ld   [_RAM_D401_], a
_LABEL_55BB_:
    ld   a, $BE
    ld   [_RAM_D402_], a
    ld   de, _RAM_D056_
    ld   hl, _RAM_D403_
    call _LABEL_56BC_
    jr   _LABEL_5600_

_LABEL_55CB_:
    ld   a, $BE
    ld   [_RAM_D400_], a
    ld   [_RAM_D401_], a
    ld   [_RAM_D402_], a
    ld   a, [_RAM_D055_]
    and  a
    jr   z, _LABEL_55BB_
    ld   a, [_RAM_D056_]
    and  $F0
    ld   b, a
    ld   a, [_RAM_D056_]
    and  $0F
    add  $02
    cp   $0A
    jr   c, _LABEL_55F1_
    sub  $0A
    add  $10
_LABEL_55F1_:
    add  $10
    add  b
    ld   [_RAM_D03A_], a    ; _RAM_D03A_ = $D03A
    ld   de, _RAM_D03A_ ; _RAM_D03A_ = $D03A
    ld   hl, _RAM_D403_
    call _LABEL_56BC_
_LABEL_5600_:
    ld   a, $73
    ld   [_RAM_D405_], a
    ld   de, _RAM_D057_
    ld   hl, _RAM_D406_
    call _LABEL_56BC_
    ld   a, $BE
    ldi  [hl], a
    ldi  [hl], a
    ld   de, _RAM_D058_
    ld   hl, _RAM_D40A_
    call _LABEL_56BC_
    xor  a
    ld   [_RAM_D40C_], a
    ld   de, _RAM_D400_
    ld   c, $A0
    ld   b, $02
    ld   hl, $030E
    call _LABEL_4944_
    ld   a, [_RAM_D054_]
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
    ld   de, _RAM_D053_
    ld   hl, _RAM_D404_
    call _LABEL_56BC_
    ld   a, $BE
    ldi  [hl], a
    ldi  [hl], a
    ld   a, [_RAM_D052_]
    swap a
    and  $0F
    ld   b, $0A
    call multiply_a_x_b__result_in_de__4853_
    ld   a, [_RAM_D052_]
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
    ld   a, [_RAM_D051_]
    bit  7, a
    jr   nz, _LABEL_5697_
    ld   a, $C2
    ld   [_RAM_D40D_], a
    ld   a, $C0
    jr   _LABEL_569E_

_LABEL_5697_:
    ld   a, $C1
    ld   [_RAM_D40D_], a
    ld   a, $C9
_LABEL_569E_:
    ld   [_RAM_D40E_], a
    ld   de, _RAM_D051_
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

; TODO: keycode / button constant labeling
_LABEL_56CB_:
    xor  a
    ld   [_RAM_D05A_], a
    ld   [_RAM_D06B_], a
    ld   a, [maybe_input_key_new_pressed__RAM_D025_]
    cp   $2E
    jr   z, _LABEL_5740_
    cp   $3D
    jr   z, _LABEL_5704_
    cp   $40
    jr   z, _LABEL_571F_
    cp   $2A
    jp   z, _LABEL_576B_
    cp   $2F
    jr   nz, _LABEL_56EE_
    call _LABEL_522_
    ret


; TODO: keycode / button constant labeling
_LABEL_56EE_:
    ld   a, [buttons_new_pressed__RAM_D006_]
    and  $C4
    ret  z
    ld   a, [buttons_new_pressed__RAM_D006_]
    bit  6, a
    jr   nz, _LABEL_5704_
    bit  7, a
    jr   nz, _LABEL_571F_
    bit  2, a
    jr   nz, _LABEL_5740_
    ret

_LABEL_5704_:
    ld   hl, _RAM_D068_
    ld   a, [_RAM_D20C_]
    cp   $06
    jr   nz, _LABEL_5712_
    ld   [hl], $00
    jr   _LABEL_571C_

_LABEL_5712_:
    cp   $09
    jr   nz, _LABEL_571A_
    ld   [hl], $01
    jr   _LABEL_571C_

_LABEL_571A_:
    ld   [hl], $02
_LABEL_571C_:
    jp   _LABEL_5737_

_LABEL_571F_:
    ld   hl, _RAM_D068_
    ld   a, [_RAM_D20C_]
    cp   $06
    jr   nz, _LABEL_572D_
    ld   [hl], $02
    jr   _LABEL_5737_

_LABEL_572D_:
    cp   $03
    jr   z, _LABEL_5735_
    ld   [hl], $00
    jr   _LABEL_5737_

_LABEL_5735_:
    ld   [hl], $01
_LABEL_5737_:
    call _LABEL_5792_
    ld   a, $05
    call _LABEL_4A72_
    ret

_LABEL_5740_:
    ld   a, [_RAM_D068_]
    cp   $00
    jr   nz, _LABEL_5763_
    ld   a, [_RAM_D059_]
    xor  $01
    ld   [_RAM_D059_], a
    xor  a
    ld   [_RAM_D052_], a
    call timer_wait_tick_AND_TODO__289_
    call timer_wait_tick_AND_TODO__289_
    call timer_wait_tick_AND_TODO__289_
    call timer_wait_tick_AND_TODO__289_
    call timer_wait_tick_AND_TODO__289_
    ret

_LABEL_5763_:
    cp   $01
    jr   nz, _LABEL_576B_
    call _LABEL_57D5_
    ret

_LABEL_576B_:
    call _LABEL_5774_
    ld   a, $01
    ld   [_RAM_D05A_], a
    ret

_LABEL_5774_:
    ld   hl, _RAM_D05F_ ; _RAM_D05F_ = $D05F
    ld   b, $02
    ld   c, $02
_LABEL_577B_:
    ldi  a, [hl]
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    push bc
    push hl
    call oam_free_slot_and_clear__89B_
    pop  hl
    pop  bc
    dec  b
    jr   nz, _LABEL_577B_
    ld   hl, _RAM_D03B_ + 1 ; _RAM_D03B_ + 1 = $D03C
    ld   b, $0C
    dec  c
    jr   nz, _LABEL_577B_
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
_LABEL_57C9_:
    ldi  [hl], a
    inc  a
    ldd  [hl], a
    inc  a
    ld   de, $0020
    add  hl, de
    dec  c
    jr   nz, _LABEL_57C9_
    ret

_LABEL_57D5_:
    xor  a
    ld   [_RAM_D06C_], a    ; _RAM_D06C_ = $D06C
    ldh  a, [rLCDC]
    and  $FD
    ldh  [rLCDC], a
    call _LABEL_5774_
    call wait_until_vbl__92C_
    call _LABEL_94C_
    ld   de, $2F2A
    ld   bc, $0000
    ld   hl, $8800
    ld   a, $80
    call _LABEL_48CD_
    ld   hl, _TILEMAP0; $9800
_LABEL_57F9_:
    xor  a
    ldi  [hl], a
    ld   a, h
    cp   $9C
    jr   nz, _LABEL_57F9_
    xor  a
    ld   [_RAM_D069_], a
    ld   de, _DATA_5DD2_
    ld   c, $A0
    ld   b, $02
    ld   hl, $0203
    call _LABEL_4944_
    ld   a, [_RAM_D056_]
    cp   $12
    jr   nz, _LABEL_581C_
    xor  a
    ld   [_RAM_D056_], a
_LABEL_581C_:
    ld   de, _RAM_D055_
    ld   a, [de]
    inc  de
    and  a
    jr   z, _LABEL_5841_
    ld   a, [de]
    and  $F0
    ld   b, a
    ld   a, [de]
    and  $0F
    add  $02
    cp   $0A
    jr   c, _LABEL_5835_
    sub  $0A
    add  $10
_LABEL_5835_:
    add  $10
    add  b
    ld   [_RAM_D402_], a
    ld   [_RAM_D056_], a
    ld   de, _RAM_D402_
_LABEL_5841_:
    ld   hl, _RAM_D400_
    call _LABEL_56BC_
    ld   a, $BE
    ldi  [hl], a
    ld   [_RAM_D404_], a
    ld   a, $73
    ldi  [hl], a
    inc  hl
    ld   de, _RAM_D057_
    call _LABEL_56BC_
    xor  a
    ldi  [hl], a
    ld   de, _RAM_D400_
    ld   c, $D2
    ld   b, $02
    ld   hl, $0207
    call _LABEL_4944_
    ld   de, _RAM_D052_
    ld   hl, _RAM_D400_
    call _LABEL_56BC_
    ld   a, $BE
    ldi  [hl], a
    ldi  [hl], a
    ld   de, _RAM_D053_
    call _LABEL_56BC_
    ld   a, $BE
    ld   [_RAM_D406_], a
    ld   [_RAM_D408_], a
    ld   a, $9E
    ld   [_RAM_D407_], a
    ld   de, _RAM_D051_
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
    ld   [_RAM_D03A_], a    ; _RAM_D03A_ = $D03A
    ld   a, $04
    ld   [_RAM_D03B_], a    ; _RAM_D03B_ = $D03B
    call _LABEL_58EA_
_LABEL_58AD_:
    call input_map_gamepad_buttons_to_keycodes__49C2_
    call _LABEL_5919_
    ld   a, [_RAM_D06B_]
    and  a
    jr   z, _LABEL_58C3_
    call _LABEL_58DC_
    ldh  a, [rLCDC]
    or   $02
    ldh  [rLCDC], a
    ret

_LABEL_58C3_:
    ld   a, [_RAM_D03B_]    ; _RAM_D03B_ = $D03B
    inc  a
    ld   [_RAM_D03B_], a    ; _RAM_D03B_ = $D03B
    and  $07
    jr   nz, _LABEL_58D3_
    call _LABEL_58DC_
    jr   _LABEL_58AD_

_LABEL_58D3_:
    cp   $04
    jr   nz, _LABEL_58AD_
    call _LABEL_58EA_
    jr   _LABEL_58AD_

_LABEL_58DC_:
    ld   a, [_RAM_D069_]
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call oam_free_slot_and_clear__89B_
    xor  a
    ld   [_RAM_D069_], a
    ret

_LABEL_58EA_:
    ld   a, [_RAM_D03A_]    ; _RAM_D03A_ = $D03A
    sla  a
    ld   hl, _DATA_590F_
    call _LABEL_486E_
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
    ld   a, [maybe_input_key_new_pressed__RAM_D025_]
    cp   $3F
    jr   nz, _LABEL_593C_
    xor  a
    ld   [_RAM_D06C_], a    ; _RAM_D06C_ = $D06C
    ld   a, [_RAM_D03A_]    ; _RAM_D03A_ = $D03A
    inc  a
    cp   $05
    jr   nz, _LABEL_5931_
    xor  a
_LABEL_5931_:
    ld   [_RAM_D03A_], a    ; _RAM_D03A_ = $D03A
    ld   a, $FF
    ld   [_RAM_D181_], a
    jp   _LABEL_59F1_

_LABEL_593C_:
    cp   $3E
    jr   nz, _LABEL_5950_
    xor  a
    ld   [_RAM_D06C_], a    ; _RAM_D06C_ = $D06C
    ld   a, [_RAM_D03A_]    ; _RAM_D03A_ = $D03A
    dec  a
    cp   $FF
    jr   nz, _LABEL_5931_
    ld   a, $04
    jr   _LABEL_5931_

_LABEL_5950_:
    cp   $C0
    jr   c, _LABEL_5987_
    cp   $CA
    jr   nc, _LABEL_5987_
    ld   b, $C0
    sub  b
    ld   c, a
    ld   a, [_RAM_D03A_]    ; _RAM_D03A_ = $D03A
    ld   hl, _DATA_5DA1_
    call _LABEL_486E_
    ld   a, [hl]
    ld   hl, _RAM_D051_
    call _LABEL_486E_
    ld   a, [_RAM_D06C_]    ; _RAM_D06C_ = $D06C
    cp   $00
    jr   nz, _LABEL_5975_
    ld   [hl], $00
_LABEL_5975_:
    ld   a, $01
    ld   [_RAM_D06C_], a    ; _RAM_D06C_ = $D06C
    ld   a, [hl]
    swap a
    and  $F0
    or   c
    ld   [hl], a
    call _LABEL_59F2_
    jp   _LABEL_59F1_

_LABEL_5987_:
    cp   $2E
    jr   nz, _LABEL_59ED_
    ld   a, [_RAM_D056_]
    swap a
    and  $0F
    ld   b, $0A
    call multiply_a_x_b__result_in_de__4853_
    ld   a, [_RAM_D056_]
    and  $0F
    add  e
    cp   $0C
    jr   nc, _LABEL_59A4_
    xor  a
    jr   _LABEL_59B7_

_LABEL_59A4_:
    sub  $0C
    ld   d, $00
    ld   e, a
    ld   h, $0A
    call _LABEL_4832_
    ld   a, c
    swap a
    or   l
    ld   [_RAM_D056_], a
    ld   a, $01
_LABEL_59B7_:
    ld   [_RAM_D055_], a
    call _LABEL_5A2B_
    ld   a, [_RAM_D06A_]
    and  a
    jp   z, _LABEL_5B12_
    di
    ld   b, $08
    ld   hl, _RAM_D051_
    ld   de, _RAM_D028_ ; _RAM_D028_ = $D028
    call _LABEL_482B_
    ld   a, $0B
    ld   [_RAM_D035_], a    ; _RAM_D035_ = $D035
_LABEL_59D5_:
    call _LABEL_A34_
    ld   a, [maybe_input_key_new_pressed__RAM_D025_]
    cp   $FC
    jr   z, _LABEL_59E4_
    call timer_wait_tick_AND_TODO__289_
    jr   _LABEL_59D5_

_LABEL_59E4_:
    ld   a, $01
    ld   [_RAM_D06B_], a
    call maybe_input_wait_for_keys__4B84
    ret

_LABEL_59ED_:
    cp   $2A
    jr   z, _LABEL_59E4_
_LABEL_59F1_:
    ret

_LABEL_59F2_:
    push hl
    pop  de
    ld   hl, _RAM_D400_
    call _LABEL_56BC_
    xor  a
    ldi  [hl], a
    ld   a, [_RAM_D03A_]    ; _RAM_D03A_ = $D03A
    ld   b, $04
    call multiply_a_x_b__result_in_de__4853_
    ld   a, $64
    add  e
    ld   c, a
    ld   a, [_RAM_D03A_]    ; _RAM_D03A_ = $D03A
    sla  a
    ld   hl, _DATA_5A21_
    call _LABEL_486E_
    ldi  a, [hl]
    ld   b, a
    ldi  a, [hl]
    ld   l, a
    ld   h, b
    ld   de, _RAM_D400_
    ld   b, $02
    call _LABEL_4944_
    ret

; Data from 5A21 to 5A2A (10 bytes)
_DATA_5A21_:
db $02, $07, $07, $07, $02, $0B, $06, $0B, $0B, $0B

_LABEL_5A2B_:
    ld   hl, _RAM_D051_
    call _LABEL_5B03_
    cp   $0C
    jr   c, _LABEL_5A3B_
    cp   $5C
    jr   nc, _LABEL_5A3B_
    jr   _LABEL_5A9A_

_LABEL_5A3B_:
    inc  hl
    call _LABEL_5B03_
    cp   $00
    jr   z, _LABEL_5A9A_
    cp   $0D
    jr   nc, _LABEL_5A9A_
    push hl
    ld   hl, $5DB2
    dec  a
    call _LABEL_486E_
    ld   c, [hl]
    inc  c
    pop  hl
    inc  hl
    push bc
    call _LABEL_5B03_
    pop  bc
    cp   $00
    jr   z, _LABEL_5A9A_
    cp   c
    jr   nc, _LABEL_5A9A_
    dec  hl
    ld   a, [hl]
    cp   $02
    jr   nz, _LABEL_5A7F_
    dec  hl
    push hl
    call _LABEL_5B03_
    ld   e, a
    ld   d, $00
    ld   h, $04
    call _LABEL_4832_
    ld   a, l
    and  a
    pop  hl
    inc  hl
    jr   z, _LABEL_5A7F_
    inc  hl
    ld   a, [hl]
    cp   $29
    jr   z, _LABEL_5A9A_
    dec  hl
_LABEL_5A7F_:
    ld   a, $04
    call _LABEL_486E_
    call _LABEL_5B03_
    cp   $0C
    jr   nc, _LABEL_5A9A_
    inc  hl
    call _LABEL_5B03_
    cp   $3C
    jr   nc, _LABEL_5A9A_
    call _LABEL_5A9F_
    ld   a, $01
    jr   _LABEL_5A9B_

_LABEL_5A9A_:
    xor  a
_LABEL_5A9B_:
    ld   [_RAM_D06A_], a
    ret

_LABEL_5A9F_:
    ld   hl, _RAM_D051_
    call _LABEL_5B03_
    ld   e, a
    cp   $5C
    jr   nc, _LABEL_5AAE_
    add  $08
    jr   _LABEL_5AB0_

_LABEL_5AAE_:
    sub  $5C
_LABEL_5AB0_:
    ld   hl, $5DBE
    call _LABEL_486E_
    ld   b, [hl]
    push bc
    ld   d, $00
    ld   h, $04
    call _LABEL_4832_
    ld   a, l
    and  a
    jr   nz, _LABEL_5AC8_
    ld   de, _DATA_5DB2_
    jr   _LABEL_5ACB_

_LABEL_5AC8_:
    ld   de, _DATA_5DA6_
_LABEL_5ACB_:
    ld   hl, _RAM_D052_
    push de
    call _LABEL_5B03_
    pop  de
    dec  a
    pop  bc
    ld   c, a
    and  a
    ld   l, b
    ld   h, $00
    jr   z, _LABEL_5AE4_
_LABEL_5ADC_:
    ld   a, [de]
    call _LABEL_486E_
    inc  de
    dec  c
    jr   nz, _LABEL_5ADC_
_LABEL_5AE4_:
    push de
    dec  hl
    push hl
    ld   hl, _RAM_D053_
    call _LABEL_5B03_
    pop  hl
    call _LABEL_486E_
    ld   e, l
    ld   d, h
    ld   h, $07
    call _LABEL_4832_
    ld   a, l
    and  a
    jr   nz, _LABEL_5AFE_
    ld   a, $07
_LABEL_5AFE_:
    ld   [_RAM_D054_], a
    pop  de
    ret

_LABEL_5B03_:
    ld   a, [hl]
    swap a
    and  $0F
    ld   b, $0A
    call multiply_a_x_b__result_in_de__4853_
    ld   a, [hl]
    and  $0F
    add  e
    ret

_LABEL_5B12_:
    ld   de, _DATA_5DE1_
    ld   hl, _LABEL_10F_
    ld   c, PRINT_NORMAL  ; $01
    call render_string_at_de_to_tilemap0_xy_in_hl__4A46_
    ld   de, _DATA_5DF4_
    ld   hl, _LABEL_10F_ + 1
    ld   c, PRINT_NORMAL  ; $01
    call render_string_at_de_to_tilemap0_xy_in_hl__4A46_
    ld   de, _DATA_5E08_
    ld   hl, $0111
    ld   c, PRINT_NORMAL  ; $01
    call render_string_at_de_to_tilemap0_xy_in_hl__4A46_
_LABEL_5B33_:
    call input_map_gamepad_buttons_to_keycodes__49C2_
    ld   a, [maybe_input_key_new_pressed__RAM_D025_]
    cp   $2A
    jr   nz, _LABEL_5B33_
    xor  a
    ld   [_RAM_D03A_], a    ; _RAM_D03A_ = $D03A
    ld   [_RAM_D06C_], a    ; _RAM_D06C_ = $D06C
    ld   c, $03
    ld   hl, $99C0
    ld   de, $000C
_LABEL_5B4C_:
    call wait_until_vbl__92C_
    ld   b, $14
_LABEL_5B51_:
    ld   a, $BE
    ldi  [hl], a
    dec  b
    jr   nz, _LABEL_5B51_
    add  hl, de
    dec  c
    jr   nz, _LABEL_5B4C_
    call maybe_input_wait_for_keys__4B84
    ret

_LABEL_5B5F_:
    ld   a, $05
    ldh  [rIE], a
    ei
    ld   hl, _RAM_D056_
    ld   a, [hl]
    bit  4, a
    jr   z, _LABEL_5B73_
    sub  $06
    cp   $0C
    jr   nz, _LABEL_5B73_
    xor  a
_LABEL_5B73_:
    ld   b, $05
    call multiply_a_x_b__result_in_de__4853_
    ld   a, e
    ld   [_RAM_D03A_], a    ; _RAM_D03A_ = $D03A
    inc  hl
    call _LABEL_5BB9_
    ld   d, $00
    ld   e, a
    ld   h, $0C
    call _LABEL_4832_
    ld   a, [_RAM_D03A_]    ; _RAM_D03A_ = $D03A
    add  c
    ld   [_RAM_D049_], a
    xor  a
    ld   [_RAM_D048_], a
    call _LABEL_5BC8_
    ld   hl, _RAM_D057_
    call _LABEL_5BB9_
    ld   [_RAM_D049_], a
    ld   a, $01
    ld   [_RAM_D048_], a
    call _LABEL_5BC8_
    ld   hl, _RAM_D058_
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
_LABEL_5BCD_:
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
    jr   nz, _LABEL_5BCD_
    ld   hl, _RAM_D04A_
    ld   a, [_RAM_D049_]
    cp   $0F
    jr   c, _LABEL_5C2B_
    cp   $1E
    jr   c, _LABEL_5C49_
    cp   $2D
    jr   c, _LABEL_5C0D_
    ld   [hl], $08
    sub  $2D
    ld   [_RAM_D03A_], a    ; _RAM_D03A_ = $D03A
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
    jr   _LABEL_5C61_

_LABEL_5C0D_:
    ld   [hl], $04
    ld   b, a
    ld   a, $2D
    sub  b
    ld   [_RAM_D03A_], a    ; _RAM_D03A_ = $D03A
    sla  a
    sla  a
    ld   [_RAM_D037_], a
    ld   hl, _DATA_5D9F_
    ldi  a, [hl]
    sub  $10
    add  $01
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ldi  a, [hl]
    jr   _LABEL_5C61_

_LABEL_5C2B_:
    ld   [hl], $01
    ld   b, a
    ld   a, $0F
    sub  b
    ld   [_RAM_D03A_], a    ; _RAM_D03A_ = $D03A
    sla  a
    sla  a
    ld   [_RAM_D037_], a
    ld   hl, _DATA_5D9F_
    ldi  a, [hl]
    add  $08
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ldi  a, [hl]
    sub  $10
    jr   _LABEL_5C61_

_LABEL_5C49_:
    ld   [hl], $02
    sub  $0F
    ld   [_RAM_D03A_], a    ; _RAM_D03A_ = $D03A
    sla  a
    sla  a
    ld   [_RAM_D037_], a
    ld   hl, _DATA_5D9F_
    ldi  a, [hl]
    add  $08
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ldi  a, [hl]
_LABEL_5C61_:
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    ld   hl, _RAM_D037_
    ld   a, $00
    add  [hl]
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    add  $02
    ld   [_RAM_D037_], a
    ld   a, [_RAM_D04A_]
    bit  3, a
    jr   z, _LABEL_5C7C_
    xor  a
    jr   _LABEL_5C8E_

_LABEL_5C7C_:
    bit  2, a
    jr   z, _LABEL_5C84_
    ld   a, $40
    jr   _LABEL_5C8E_

_LABEL_5C84_:
    bit  1, a
    jr   z, _LABEL_5C8C_
    ld   a, $60
    jr   _LABEL_5C8E_

_LABEL_5C8C_:
    ld   a, $20
_LABEL_5C8E_:
    ld   [_RAM_C8CD_], a    ; _RAM_C8CD_ = $C8CD
    call _LABEL_623_
    call _LABEL_5D30_
    ld   a, b
    ldi  [hl], a
    ld   a, [_RAM_D04A_]
    and  $0C
    jr   nz, _LABEL_5CA7_
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    sub  $08
    jr   _LABEL_5CAC_

_LABEL_5CA7_:
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    add  $08
_LABEL_5CAC_:
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
    jr   z, _LABEL_5D2F_
    ld   hl, _DATA_5D7F_
    ld   a, [_RAM_D03A_]    ; _RAM_D03A_ = $D03A
    call _LABEL_486E_
    ld   b, [hl]
    ld   a, [_RAM_D04A_]
    and  $0C
    jr   nz, _LABEL_5CD9_
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    add  b
    jr   _LABEL_5CDD_

_LABEL_5CD9_:
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    sub  b
_LABEL_5CDD_:
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   a, $10
    call _LABEL_486E_
    ld   b, [hl]
    ld   a, [_RAM_D04A_]
    and  $09
    jr   nz, _LABEL_5CF3_
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    add  b
    jr   _LABEL_5CF7_

_LABEL_5CF3_:
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    sub  b
_LABEL_5CF7_:
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
    jr   nz, _LABEL_5D18_
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    add  $08
    jr   _LABEL_5D1D_

_LABEL_5D18_:
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    sub  $08
_LABEL_5D1D_:
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   a, [_RAM_D037_]
    sub  $02
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    push hl
    call _LABEL_623_
    pop  hl
    ld   a, b
    ldi  [hl], a
_LABEL_5D2F_:
    ret

_LABEL_5D30_:
    ld   hl, _RAM_D03C_
    ld   a, [_RAM_D048_]
    sla  a
    sla  a
    call _LABEL_486E_
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

_LABEL_5D50_:
    call _LABEL_5D3E_
    ld   b, $08
    ld   hl, _RAM_D028_ ; _RAM_D028_ = $D028
    ld   de, _RAM_D051_
    call _LABEL_482B_
    ret

_LABEL_5D5F_:
    call _LABEL_5D3E_
    xor  a
    ld   [_RAM_D03A_], a    ; _RAM_D03A_ = $D03A
    ld   b, $08
    ld   hl, _RAM_D028_ ; _RAM_D028_ = $D028
    ld   de, _RAM_D051_
_LABEL_5D6E_:
    ld   a, [de]
    cp   [hl]
    jr   z, _LABEL_5D79_
    ld   a, [hl]
    ld   [de], a
    ld   a, $01
    ld   [_RAM_D03A_], a    ; _RAM_D03A_ = $D03A
_LABEL_5D79_:
    inc  de
    inc  hl
    dec  b
    jr   nz, _LABEL_5D6E_
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

; Data from 5DA6 to 5DB1 (12 bytes)
_DATA_5DA6_:
db $1F, $1C, $1F, $1E, $1F, $1E, $1F, $1F, $1E, $1F, $1E, $1F

; Data from 5DB2 to 5DD1 (32 bytes)
_DATA_5DB2_:
db $1F, $1D, $1F, $1E, $1F, $1E, $1F, $1F, $1E, $1F, $1E, $1F, $03, $05, $06, $07
db $01, $03, $04, $05, $06, $01, $02, $03, $04, $06, $07, $01, $02, $04, $05, $06

; Data from 5DD2 to 5DE0 (15 bytes)
_DATA_5DD2_:
db $90, $95, $85, $93, $94, $81, $BE, $85, $8E, $BE, $88, $8F, $92, $81, $00

; Data from 5DE1 to 5DF3 (19 bytes)
_DATA_5DE1_:
db $BE, $BE, $90, $81, $92, $81, $BE, $83, $8F, $8E, $94, $89, $8E, $95, $81, $92
db $BE, $8F, $00

; Data from 5DF4 to 5E07 (20 bytes)
_DATA_5DF4_:
db $89, $8E, $96, $81, $8C, $89, $84, $81, $92, $BE, $90, $92, $85, $93, $89, $8F
db $8E, $81, $92, $00

; Data from 5E08 to 5E18 (17 bytes)
_DATA_5E08_:
db $BE, $BE, $BE, $85, $93, $83, $81, $90, $85, $BE, $93, $81, $8C, $89, $84, $81
db $00

; Data from 5E19 to 5E30 (24 bytes)
_DATA_5E19_:
db $8C, $95, $8E, $8D, $81, $92, $8D, $89, $D7, $8A, $95, $85, $96, $89, $85, $93
db $D6, $82, $84, $8F, $8D, $8C, $95, $8E

; Data from 5E31 to 5E54 (36 bytes)
_DATA_5E31_:
db $85, $8E, $85, $86, $85, $82, $8D, $81, $92, $81, $82, $92, $8D, $81, $99, $8A
db $95, $8E, $8A, $95, $8C, $81, $87, $8F, $93, $85, $90, $8F, $83, $94, $8E, $8F
db $96, $84, $89, $83

_LABEL_5E55_:
    ldh  a, [rLCDC]
    and  $FD
    ldh  [rLCDC], a
    call _LABEL_620A_
    ld   hl, $8800
_LABEL_5E61_:
    xor  a
    ldi  [hl], a
    ld   a, h
    cp   $98
    jr   nz, _LABEL_5E61_
    ld   de, $2F2A
    ld   b, $7F
    ld   hl, $8800
    ld   c, $7B
    ld   a, $01
    call _LABEL_48CD_
    call _LABEL_60F3_
    call _display_bg_sprites_on__627_
    xor  a
    ld   [_RAM_D20D_], a
    ld   [_RAM_D04B_], a
    ld   [_RAM_D03A_], a    ; _RAM_D03A_ = $D03A
    ld   a, $18
    ld   [_RAM_D03B_], a    ; _RAM_D03B_ = $D03B
    ld   a, $BE
    ld   b, $10
    ld   hl, _RAM_D6D0_
_LABEL_5E93_:
    ldi  [hl], a
    dec  b
    jr   nz, _LABEL_5E93_
    call _LABEL_6240_
_LABEL_5E9A_:
    call input_map_gamepad_buttons_to_keycodes__49C2_
    call _LABEL_6230_
    ld   a, [maybe_input_key_new_pressed__RAM_D025_]
    cp   $2A
    jr   nz, _LABEL_5EAE_
    call _LABEL_6265_
    call maybe_input_wait_for_keys__4B84
    ret

_LABEL_5EAE_:
    cp   $2F
    jr   nz, _LABEL_5EB7_
    call _LABEL_522_
    jr   _LABEL_5E9A_

_LABEL_5EB7_:
    cp   $44
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
    cp   $45
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
    cp   $3E
    jr   nz, _LABEL_5F13_
    ld   a, [_RAM_D6D0_]
    cp   $BE
    jp   z, _LABEL_5E9A_
    ld   a, [_RAM_D03B_]    ; _RAM_D03B_ = $D03B
    sub  $08
    ld   [_RAM_D03B_], a    ; _RAM_D03B_ = $D03B
    cp   $10
    jp   nz, _LABEL_5F08_
    ld   a, $18
    ld   [_RAM_D03B_], a    ; _RAM_D03B_ = $D03B
_LABEL_5F08_:
    call _LABEL_621C_
    ld   a, $02
    call _LABEL_4A72_
    jp   _LABEL_5E9A_

_LABEL_5F13_:
    cp   $3F
    jr   nz, _LABEL_5F34_
    ld   a, [_RAM_D6D0_]
    cp   $BE
    jp   z, _LABEL_5E9A_
    ld   a, [_RAM_D03B_]    ; _RAM_D03B_ = $D03B
    add  $08
    ld   [_RAM_D03B_], a    ; _RAM_D03B_ = $D03B
    cp   $A0
    jp   nz, _LABEL_5F08_
    ld   a, $98
    ld   [_RAM_D03B_], a    ; _RAM_D03B_ = $D03B
    jp   _LABEL_5F08_

_LABEL_5F34_:
    cp   $2C
    jr   nz, _LABEL_5F50_
    ld   a, [_RAM_D03B_]    ; _RAM_D03B_ = $D03B
    sub  $08
    cp   $10
    jp   z, _LABEL_5E9A_
    ld   [_RAM_D03B_], a    ; _RAM_D03B_ = $D03B
    ld   a, $BE
    ld   [maybe_input_key_new_pressed__RAM_D025_], a
    call _LABEL_621C_
    jp   _LABEL_5F54_

_LABEL_5F50_:
    cp   $3C
    jr   nz, _LABEL_5F7A_
_LABEL_5F54_:
    ld   a, [_RAM_D03B_]    ; _RAM_D03B_ = $D03B
    srl  a
    srl  a
    srl  a
    sub  $03
    ld   hl, $D6D0
    call _LABEL_486E_
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

_LABEL_5F7A_:
    cp   $2E
    jp   z, _LABEL_6022_
    cp   $CB
    jr   nz, _LABEL_5F93_
    call maybe_input_wait_for_keys__4B84
    ld   a, [_RAM_D03B_]    ; _RAM_D03B_ = $D03B
    cp   $10
    jp   z, _LABEL_5E9A_
    ld   a, $CB
    ld   [maybe_input_key_new_pressed__RAM_D025_], a
_LABEL_5F93_:
    cp   $BE
    jr   nz, _LABEL_5FA1_
    ld   a, [_RAM_D03B_]    ; _RAM_D03B_ = $D03B
    cp   $18
    jp   z, _LABEL_5E9A_
    ld   a, $BE
_LABEL_5FA1_:
    cp   $81
    jp   c, _LABEL_5E9A_
    cp   $9E
    jr   c, _LABEL_5FDA_
    cp   $A1
    jp   c, _LABEL_5E9A_
    cp   $BF
    jp   nc, _LABEL_5FBF_
    cp   $BE
    jr   z, _LABEL_5FDA_
    sub  $20
    ld   [maybe_input_key_new_pressed__RAM_D025_], a
    jr   _LABEL_5FDA_

_LABEL_5FBF_:
    cp   $D6
    jp   c, _LABEL_5E9A_
    cp   $DB
    jr   c, _LABEL_5FDA_
    jp   z, _LABEL_5E9A_
    cp   $E2
    jp   nc, _LABEL_5E9A_
    cp   $DC
    jp   c, _LABEL_5FDA_
    sub  $07
    ld   [maybe_input_key_new_pressed__RAM_D025_], a
_LABEL_5FDA_:
    ld   a, [_RAM_D20D_]
    and  a
    jp   z, _LABEL_6007_
    ld   a, $18
    ld   [_RAM_D03B_], a    ; _RAM_D03B_ = $D03B
    xor  a
    ld   [_RAM_D20D_], a
    call _LABEL_621C_
    ld   [_RAM_D04B_], a
    ld   a, $BE
    ld   b, $10
    ld   hl, _RAM_D6D0_
_LABEL_5FF7_:
    ldi  [hl], a
    dec  b
    jr   nz, _LABEL_5FF7_
    call _LABEL_620A_
    call _LABEL_62BD_
    call _LABEL_60F3_
    call _display_bg_sprites_on__627_
_LABEL_6007_:
    ld   a, [_RAM_D03B_]    ; _RAM_D03B_ = $D03B
    add  $08
    cp   $A0
    jp   z, _LABEL_5E9A_
    call _LABEL_61D8_
    ld   a, [_RAM_D03B_]    ; _RAM_D03B_ = $D03B
    add  $08
    ld   [_RAM_D03B_], a    ; _RAM_D03B_ = $D03B
    call _LABEL_6230_
    jp   _LABEL_5E9A_

_LABEL_6022_:
    ld   hl, _RAM_D6D0_
    ld   a, [hl]
    cp   $BE
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
    call _switch_bank_jump_hl_RAM__C920_
    ei
_LABEL_6044_:
    ld   a, [_RAM_D717_]
    cp   $0F
    jr   z, _LABEL_605F_
    ld   b, $10
    ld   de, _RAM_D6F0_
    ld   hl, _RAM_D6D0_
    call _LABEL_481F_
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
    call _switch_bank_jump_hl_RAM__C920_
    ei
_LABEL_6080_:
    ld   a, $10
    ld   [_RAM_D03B_], a    ; _RAM_D03B_ = $D03B
    call _LABEL_6278_
    call _LABEL_620A_
    call _LABEL_60F3_
    ld   a, $0A
    ld   [_RAM_D717_], a
    ld   hl, $0028
    res  7, h
    ld   a, $01
    call _switch_bank_jump_hl_RAM__C920_
    ei
    ld   a, $01
    ld   [_RAM_D20D_], a
    ld   b, $10
    ld   de, _RAM_D6F0_
    ld   hl, _RAM_D6D0_
    call _LABEL_481F_
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
    ld   [_RAM_D03B_], a    ; _RAM_D03B_ = $D03B
    ld   a, $03
_LABEL_60CE_:
    ld   [_RAM_D20D_], a
    ld   a, $A0
    cp   $B0
    jp   z, _LABEL_5E9A_
    call _LABEL_611B_
    call maybe_input_wait_for_keys__4B84
    jp   _LABEL_5E9A_

_LABEL_60E1_:
    call _LABEL_620A_
    call wait_until_vbl__92C_
    call _LABEL_94C_
    call _LABEL_60F3_
    ld   a, $01
    ld   [_RAM_D20D_], a
    ret

_LABEL_60F3_:
    ld   de, _DATA_62CF_
    ld   c, $00
    ld   b, $02
    ld   hl, $0103
    call _LABEL_4944_
    ld   de, _DATA_62E3_
    ld   c, $28
    ld   b, $02
    ld   hl, $0606
    call _LABEL_4944_
    ld   de, _DATA_62ED_
    ld   c, $50
    ld   b, $02
    ld   hl, _DATA_20A_ - 1
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
    call _switch_bank_memcopy_hl_to_de_len_bc_RAM__C960_
    pop  hl
    push hl
    call _switch_bank_read_byte_at_hl_RAM__C980_
    call wait_until_vbl__92C_
    call _LABEL_94C_
    ld   a, [_rombank_readbyte_result__D6E7_]
    bit  7, a
    jr   z, _LABEL_615A_
    ld   hl, $8800
    ld   bc, $0340
    call _switch_bank_memcopy_hl_to_de_len_bc_RAM__C960_
_LABEL_615A_:
    pop  hl
    inc  hl
    ld   a, [_rombank_readbyte_result__D6E7_]
    ld   b, $10
    call multiply_a_x_b__result_in_de__4853_
    add  hl, de
    call _switch_bank_read_byte_at_hl_RAM__C980_
    ld   a, [_rombank_readbyte_result__D6E7_]
    ld   [_RAM_D03A_], a    ; _RAM_D03A_ = $D03A
    ld   b, a
    inc  hl
    call _switch_bank_read_byte_at_hl_RAM__C980_
    ld   a, [_rombank_readbyte_result__D6E7_]
    ld   [_RAM_D1A7_], a    ; _RAM_D1A7_ = $D1A7
    call multiply_a_x_b__result_in_de__4853_
    push de
    pop  bc
    inc  hl
    push hl
    pop  de
    ld   hl, $D800
    call _switch_bank_memcopy_hl_to_de_len_bc_RAM__C960_
    ld   a, [_RAM_D03A_]    ; _RAM_D03A_ = $D03A
    ld   b, a
    ld   a, $14
    sub  b
    srl  a
    ld   b, a
    ld   a, [_RAM_D1A7_]    ; _RAM_D1A7_ = $D1A7
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
    call _LABEL_94C_
    ld   de, _RAM_D800_
_LABEL_61B4_:
    ld   a, [_RAM_D03A_]    ; _RAM_D03A_ = $D03A
    ld   c, a
_LABEL_61B8_:
    ld   a, [de]
    inc  de
    ldi  [hl], a
    dec  c
    jr   nz, _LABEL_61B8_
    ld   a, [_RAM_D03A_]    ; _RAM_D03A_ = $D03A
    ld   b, a
    ld   a, $20
    sub  b
    call _LABEL_486E_
    ld   a, [_RAM_D1A7_]    ; _RAM_D1A7_ = $D1A7
    dec  a
    ld   [_RAM_D1A7_], a    ; _RAM_D1A7_ = $D1A7
    jr   nz, _LABEL_61B4_
    ldh  a, [rLCDC]
    or   $80
    ldh  [rLCDC], a
    ret

_LABEL_61D8_:
    xor  a
    ld   [_RAM_D401_], a
    ld   a, [_RAM_D03B_]    ; _RAM_D03B_ = $D03B
    srl  a
    srl  a
    srl  a
    dec  a
    push af
    ld   hl, $D6D0
    dec  a
    dec  a
    call _LABEL_486E_
    ld   a, [maybe_input_key_new_pressed__RAM_D025_]
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
    call _LABEL_94C_
    ld   hl, _TILEMAP0; $9800
_LABEL_6213_:
    ld   a, $FA
    ldi  [hl], a
    ld   a, h
    cp   $9C
    jr   nz, _LABEL_6213_
    ret

_LABEL_621C_:
    ld   a, [_RAM_D03A_]    ; _RAM_D03A_ = $D03A
    cp   $05
    call c, _LABEL_6265_
    jp   _LABEL_6240_

_LABEL_6227_:
    ld   a, [_RAM_D03A_]    ; _RAM_D03A_ = $D03A
    cp   $05
    jp   c, _LABEL_6265_
    ret

_LABEL_6230_:
    ld   a, [_RAM_D03A_]    ; _RAM_D03A_ = $D03A
    inc  a
    ld   [_RAM_D03A_], a    ; _RAM_D03A_ = $D03A
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
    ld   [_RAM_D03A_], a    ; _RAM_D03A_ = $D03A
    ld   a, $88
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    ld   a, [_RAM_D03B_]    ; _RAM_D03B_ = $D03B
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
    ld   [_RAM_D03A_], a    ; _RAM_D03A_ = $D03A
    ld   a, [_RAM_D04B_]
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call oam_free_slot_and_clear__89B_
    xor  a
    ld   [_RAM_D04B_], a
    ret

_LABEL_6278_:
    call _LABEL_620A_
    call wait_until_vbl__92C_
    call _LABEL_94C_
    call _LABEL_62BD_
    ld   de, _DATA_6312_
    ld   a, [_RAM_D6E3_]
    bit  7, a
    jr   nz, _LABEL_6291_
    ld   de, _DATA_62FF_
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
    ld   a, [maybe_input_key_new_pressed__RAM_D025_]
    cp   $FF
    jr   nz, _LABEL_62B9_
    dec  b
    jr   nz, _LABEL_62AA_
_LABEL_62B9_:
    call maybe_input_wait_for_keys__4B84
    ret

_LABEL_62BD_:
    xor  a
    ld   [_RAM_D6E0_], a
    ld   de, _RAM_D6D0_
    ld   c, $C8
    ld   b, $02
    ld   hl, $020F
    call _LABEL_4944_
    ret

; Data from 62CF to 62E2 (20 bytes)
_DATA_62CF_:
db $85, $93, $83, $92, $89, $82, $89, $92, $BE, $8C, $81, $BE, $90, $81, $8C, $81
db $82, $92, $81, $00

; Data from 62E3 to 62EC (10 bytes)
_DATA_62E3_:
db $64, $83, $8C, $81, $96, $85, $64, $BE, $99, $00

; Data from 62ED to 62FE (18 bytes)
_DATA_62ED_:
db $90, $92, $85, $93, $89, $8F, $8E, $81, $92, $BE, $85, $8E, $94, $92, $81, $84
db $81, $00

; Data from 62FF to 6311 (19 bytes)
_DATA_62FF_:
db $BE, $85, $8E, $94, $92, $81, $84, $81, $00, $8E, $8F, $BE, $96, $81, $8C, $89
db $84, $81, $00

; Data from 6312 to 6327 (22 bytes)
_DATA_6312_:
db $BE, $BE, $90, $81, $8C, $81, $82, $92, $81, $00, $84, $85, $93, $83, $8F, $8E
db $8F, $83, $89, $84, $81, $00

_LABEL_6328_:
    xor  a
    ld   [_RAM_D06C_], a    ; _RAM_D06C_ = $D06C
    ld   [_RAM_D06D_], a    ; _RAM_D06D_ = $D06D
    ld   a, $01
    ld   [_RAM_D1A7_], a    ; _RAM_D1A7_ = $D1A7
    ld   hl, $0018
    res  7, h
    ld   a, $02
    call _switch_bank_jump_hl_RAM__C920_
    ei
    ld   a, [_RAM_D1A7_]    ; _RAM_D1A7_ = $D1A7
    cp   $03
    ret  z
    cp   $04
    ret  z
    push af
    call wait_until_vbl__92C_
    call _LABEL_94C_
    pop  af
    cp   $02
    jr   z, _LABEL_6369_
    ld   hl, $8800
_LABEL_6357_:
    xor  a
    ldi  [hl], a
    ld   a, h
    cp   $98
    jr   nz, _LABEL_6357_
    ld   hl, _TILEMAP0; $9800
_LABEL_6361_:
    ld   a, $C8
    ldi  [hl], a
    ld   a, h
    cp   $A0
    jr   nz, _LABEL_6361_
_LABEL_6369_:
    ld   de, $18B2
    ld   bc, $0000
    ld   hl, $8C40
    ld   a, $1E
    call _LABEL_48CD_
    call wait_until_vbl__92C_
    call _LABEL_94C_
    ld   a, $FF
    ld   de, _DATA_1A92_
    call _LABEL_8C4_
    ldh  a, [rLCDC]
    or   $A1
    ldh  [rLCDC], a
    xor  a
    ld   [_RAM_D192_], a
    ld   [_RAM_D195_ + 1], a    ; _RAM_D195_ + 1 = $D196
    ld   a, $01
    ld   [_RAM_D19C_], a    ; _RAM_D19C_ = $D19C
    ld   [_RAM_D19D_], a    ; _RAM_D19D_ = $D19D
    ld   a, $50
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    ld   a, $58
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    call _LABEL_6510_
_LABEL_63A7_:
    xor  a
    ld   [_RAM_D05D_], a    ; _RAM_D05D_ = $D05D
    ld   [_RAM_D05E_], a    ; _RAM_D05E_ = $D05E
    ld   [_RAM_D05C_], a    ; _RAM_D05C_ = $D05C
    ld   [_RAM_D05B_], a    ; _RAM_D05B_ = $D05B
    call timer_wait_tick_AND_TODO__289_
    call maybe_input_read_keys__C8D_
    ld   a, [maybe_input_key_new_pressed__RAM_D025_]
    cp   $2A
    jp   z, _LABEL_6673_
    cp   $30
    jr   nz, _LABEL_63D1_
    ld   a, [_RAM_D19C_]    ; _RAM_D19C_ = $D19C
; Data from 63C9 to 63D0 (8 bytes)
db $EA, $73, $D0, $CD, $A6, $67, $18, $E3

_LABEL_63D1_:
    cp   $31
    jr   nz, _LABEL_63E0_
    ld   a, [_RAM_D19D_]    ; _RAM_D19D_ = $D19D
; Data from 63D8 to 63DF (8 bytes)
db $EA, $73, $D0, $CD, $AC, $67, $18, $D4

_LABEL_63E0_:
    cp   $32
    jp   z, _LABEL_667A_
    cp   $33
; Data from 63E7 to 650F (297 bytes)
db $CA, $CE, $6A, $FE, $34, $CA, $D1, $66, $FE, $2D, $C2, $02, $64, $FA, $96, $D1
db $FE, $00, $C2, $A7, $63, $CD, $ED, $6F, $C3, $A7, $63, $FE, $2F, $20, $05, $CD
db $22, $05, $18, $A9, $FE, $35, $20, $07, $FA, $06, $D0, $F6, $01, $18, $09, $FE
db $36, $20, $0A, $FA, $06, $D0, $F6, $02, $EA, $06, $D0, $18, $0C, $FE, $2E, $20
db $08, $FA, $96, $D1, $CB, $47, $C2, $F3, $68, $CD, $30, $4D, $FA, $06, $D0, $E6
db $C0, $FE, $C0, $20, $0A, $FA, $06, $D0, $E6, $3F, $EA, $06, $D0, $18, $11, $FA
db $06, $D0, $E6, $30, $FE, $30, $20, $08, $FA, $06, $D0, $E6, $CF, $EA, $06, $D0
db $FA, $06, $D0, $E6, $F3, $CA, $A7, $63, $FA, $96, $D1, $A7, $C2, $9E, $64, $FA
db $06, $D0, $CB, $47, $3E, $01, $20, $09, $FA, $06, $D0, $CB, $4F, $CA, $9E, $64
db $AF, $21, $92, $D1, $46, $B8, $20, $06, $CD, $39, $67, $C3, $B4, $63, $77, $FA
db $4B, $D0, $EA, $CC, $C8, $CD, $53, $09, $CD, $9B, $08, $CD, $10, $65, $CD, $84
db $4B, $CD, $5B, $68, $C3, $A7, $63, $FA, $4B, $D0, $EA, $CC, $C8, $CD, $53, $09
db $FA, $06, $D0, $CD, $87, $4C, $FA, $5E, $D0, $FE, $01, $CC, $29, $65, $FA, $5D
db $D0, $FE, $01, $CC, $75, $65, $FA, $5C, $D0, $FE, $01, $CC, $CE, $65, $FA, $5B
db $D0, $FE, $01, $CC, $27, $66, $FA, $92, $D1, $A7, $CA, $B4, $63, $CD, $97, $6F
db $7C, $EA, $93, $D1, $7D, $EA, $94, $D1, $3E, $01, $EA, $95, $D1, $FB, $FA, $95
db $D1, $A7, $20, $FA, $FA, $06, $D0, $E6, $CF, $EA, $06, $D0, $E6, $F0, $CA, $B4
db $63, $3E, $01, $EA, $95, $D1, $FA, $4B, $D0, $EA, $CC, $C8, $CD, $53, $09, $FB
db $FA, $95, $D1, $A7, $20, $FA, $C3, $B4, $63

_LABEL_6510_:
    ld   a, $D9
    ld   hl, _RAM_D06C_ ; _RAM_D06C_ = $D06C
    add  [hl]
    ld   hl, _RAM_D192_
    add  [hl]
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    xor  a
    ld   [_RAM_C8CD_], a    ; _RAM_C8CD_ = $C8CD
    call _LABEL_623_
    ld   a, b
    ld   [_RAM_D04B_], a
    ret

; Data from 6529 to 6672 (330 bytes)
db $AF, $EA, $5E, $D0, $FA, $4B, $D0, $EA, $CC, $C8, $CD, $53, $09, $06, $90, $CD
db $8E, $68, $FA, $96, $D1, $A7, $28, $02, $06, $8C, $FA, $CB, $C8, $3C, $B8, $D0
db $3E, $01, $EA, $CB, $C8, $FA, $4B, $D0, $EA, $CC, $C8, $3E, $00, $EA, $CA, $C8
db $CD, $51, $08, $FA, $96, $D1, $A7, $C8, $3E, $01, $EA, $CB, $C8, $FA, $98, $D1
db $EA, $CC, $C8, $3E, $00, $EA, $CA, $C8, $CD, $51, $08, $C9, $AF, $EA, $5D, $D0
db $FA, $4B, $D0, $EA, $CC, $C8, $CD, $53, $09, $06, $20, $FA, $96, $D1, $A7, $28
db $02, $06, $1C, $FA, $CB, $C8, $3D, $B8, $D8, $3E, $01, $EA, $CB, $C8, $FA, $4B
db $D0, $EA, $CC, $C8, $FA, $CB, $C8, $2F, $3C, $EA, $CB, $C8, $3E, $00, $EA, $CA
db $C8, $CD, $51, $08, $FA, $96, $D1, $A7, $C8, $3E, $01, $EA, $CB, $C8, $FA, $98
db $D1, $EA, $CC, $C8, $FA, $CB, $C8, $2F, $3C, $EA, $CB, $C8, $3E, $00, $EA, $CA
db $C8, $CD, $51, $08, $C9, $AF, $EA, $5C, $D0, $FA, $4B, $D0, $EA, $CC, $C8, $CD
db $53, $09, $06, $18, $FA, $96, $D1, $A7, $28, $02, $06, $14, $FA, $CA, $C8, $3D
db $B8, $D8, $3E, $01, $EA, $CA, $C8, $FA, $4B, $D0, $EA, $CC, $C8, $FA, $CA, $C8
db $2F, $3C, $EA, $CA, $C8, $3E, $00, $EA, $CB, $C8, $CD, $51, $08, $FA, $96, $D1
db $A7, $C8, $3E, $01, $EA, $CA, $C8, $FA, $99, $D1, $EA, $CC, $C8, $FA, $CA, $C8
db $2F, $3C, $EA, $CA, $C8, $3E, $00, $EA, $CB, $C8, $CD, $51, $08, $C9, $AF, $EA
db $5B, $D0, $FA, $4B, $D0, $EA, $CC, $C8, $CD, $53, $09, $06, $88, $CD, $8E, $68
db $FA, $96, $D1, $A7, $28, $02, $06, $84, $FA, $CA, $C8, $3C, $B8, $D0, $3E, $01
db $EA, $CA, $C8, $FA, $4B, $D0, $EA, $CC, $C8, $3E, $00, $EA, $CB, $C8, $CD, $51
db $08, $FA, $96, $D1, $A7, $C8, $3E, $01, $EA, $CA, $C8, $FA, $99, $D1, $EA, $CC
db $C8, $3E, $00, $EA, $CB, $C8, $CD, $51, $08, $C9

_LABEL_6673_:
    ld   a, $03
    ld   [_RAM_D1A7_], a    ; _RAM_D1A7_ = $D1A7
    jr   _LABEL_667F_

_LABEL_667A_:
    ld   a, $02
    ld   [_RAM_D1A7_], a    ; _RAM_D1A7_ = $D1A7
_LABEL_667F_:
    ld   a, [_RAM_D195_ + 1]    ; _RAM_D195_ + 1 = $D196
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
    ld   hl, $0018
    res  7, h
    ld   a, $02
    call _switch_bank_jump_hl_RAM__C920_
    ei
    ld   a, [_RAM_D1A7_]    ; _RAM_D1A7_ = $D1A7
    cp   $03
    jp   nz, _LABEL_6328_
    ld   a, [$D073]
; Data from 66B4 to 694D (666 bytes)
db $EA, $CB, $C8, $FA, $74, $D0, $EA, $CA, $C8, $CD, $10, $65, $11, $B2, $18, $01
db $00, $00, $21, $40, $8C, $3E, $1E, $CD, $CD, $48, $C3, $A7, $63, $FA, $96, $D1
db $FE, $00, $CA, $9D, $68, $FA, $4B, $D0, $EA, $CC, $C8, $CD, $53, $09, $CD, $9B
db $08, $FA, $6D, $D0, $FE, $00, $3E, $03, $28, $0A, $FA, $6D, $D0, $FE, $03, $3E
db $06, $28, $01, $AF, $EA, $6D, $D0, $C6, $DB, $EA, $CC, $C8, $AF, $EA, $CD, $C8
db $CD, $23, $06, $78, $EA, $4B, $D0, $11, $97, $D1, $06, $03, $1A, $EA, $CC, $C8
db $C5, $D5, $CD, $53, $09, $CD, $9B, $08, $21, $6D, $D0, $3E, $DB, $86, $EA, $CC
db $C8, $CD, $23, $06, $D1, $78, $12, $13, $C1, $05, $20, $E0, $CD, $84, $4B, $CD
db $65, $67, $C3, $B4, $63, $FA, $4B, $D0, $EA, $CC, $C8, $CD, $53, $09, $CD, $9B
db $08, $FA, $6C, $D0, $FE, $00, $3E, $03, $28, $0A, $FA, $6C, $D0, $FE, $03, $3E
db $06, $28, $01, $AF, $EA, $6C, $D0, $CD, $10, $65, $CD, $84, $4B, $CD, $65, $67
db $C9, $CD, $89, $02, $FA, $06, $D0, $CB, $47, $20, $F6, $CB, $4F, $20, $F2, $C9
db $CD, $2C, $09, $FA, $9B, $D1, $FE, $00, $21, $07, $9E, $28, $03, $21, $0D, $9E
db $3E, $C8, $77, $C9, $CD, $2C, $09, $FA, $9B, $D1, $FE, $00, $21, $07, $9E, $FA
db $9C, $D1, $28, $0A, $21, $0D, $9E, $FA, $9D, $D1, $C6, $CD, $18, $02, $C6, $D0
db $77, $C9, $AF, $EA, $9B, $D1, $18, $05, $3E, $01, $EA, $9B, $D1, $FA, $96, $D1
db $A7, $C2, $B4, $63, $FA, $3A, $D0, $3C, $EA, $3A, $D0, $E6, $0F, $20, $05, $CD
db $74, $67, $18, $07, $EE, $08, $20, $03, $CD, $88, $67, $CD, $C2, $49, $FA, $25
db $D0, $FE, $2A, $20, $1C, $FA, $9B, $D1, $FE, $00, $FA, $73, $D0, $28, $05, $EA
db $9D, $D1, $18, $03, $EA, $9C, $D1, $CD, $88, $67, $CD, $5B, $68, $CD, $84, $4B
db $C9, $FE, $2E, $28, $F2, $FE, $3D, $20, $0B, $CD, $17, $68, $CD, $88, $67, $CD
db $84, $4B, $18, $B0, $FE, $40, $20, $AC, $CD, $3A, $68, $CD, $88, $67, $CD, $84
db $4B, $18, $A1, $FA, $9B, $D1, $FE, $00, $FA, $9D, $D1, $20, $04, $FA, $9C, $D1
db $3D, $FE, $03, $C8, $3C, $47, $FA, $9B, $D1, $A7, $78, $28, $04, $EA, $9D, $D1
db $C9, $3C, $EA, $9C, $D1, $C9, $FA, $9B, $D1, $A7, $FA, $9D, $D1, $20, $04, $FA
db $9C, $D1, $3D, $A7, $C8, $3D, $47, $FA, $9B, $D1, $A7, $78, $28, $04, $EA, $9D
db $D1, $C9, $3C, $EA, $9C, $D1, $C9, $FA, $4B, $D0, $EA, $CC, $C8, $CD, $53, $09
db $CD, $9B, $08, $06, $88, $CD, $8E, $68, $FA, $CA, $C8, $3C, $B8, $38, $05, $05
db $78, $EA, $CA, $C8, $06, $90, $CD, $8E, $68, $FA, $CB, $C8, $3C, $B8, $DA, $8A
db $68, $05, $78, $EA, $CB, $C8, $CD, $10, $65, $C9, $FA, $92, $D1, $FE, $00, $C8
db $FA, $9C, $D1, $3D, $4F, $78, $91, $47, $C9, $FA, $96, $D1, $CB, $47, $C2, $A7
db $63, $FA, $4B, $D0, $EA, $CC, $C8, $CD, $53, $09, $CD, $9B, $08, $FA, $CB, $C8
db $D6, $04, $EA, $CB, $C8, $FA, $CA, $C8, $D6, $04, $EA, $CA, $C8, $21, $6D, $D0
db $3E, $DB, $86, $EA, $CC, $C8, $21, $97, $D1, $06, $03, $C5, $E5, $CD, $23, $06
db $E1, $78, $22, $C1, $05, $20, $F4, $CD, $23, $06, $78, $EA, $4B, $D0, $3E, $01
db $EA, $96, $D1, $AF, $EA, $92, $D1, $3E, $03, $CD, $72, $4A, $C3, $A7, $63, $FA
db $97, $D1, $EA, $CC, $C8, $CD, $53, $09, $FA, $CB, $C8, $C6, $04, $EA, $3A, $D0
db $FA, $CA, $C8, $C6, $04, $EA, $3B, $D0, $FA, $4B, $D0, $EA, $CC, $C8, $CD, $53
db $09, $21, $3A, $D0, $FA, $CB, $C8, $C6, $04, $BE, $38, $09, $EA, $A0, $D1, $7E
db $EA, $9E, $D1, $18, $07, $EA, $9E, $D1, $7E, $EA, $A0, $D1, $21, $3B, $D0, $FA
db $CA, $C8, $C6, $04, $BE, $38, $09, $EA, $A1, $D1, $7E, $EA, $9F, $D1, $18, $07
db $EA, $9F, $D1, $7E, $EA, $A1, $D1, $CD, $92, $69

_LABEL_694E_:
    ld   a, [_RAM_D197_]
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    call _LABEL_953_
    ld   hl, _RAM_D197_
    ld   b, $03
_LABEL_695C_:
    ldi  a, [hl]
    ld   [maybe_vram_data_to_write__RAM_C8CC_], a
    push bc
    push hl
    call oam_free_slot_and_clear__89B_
    pop  hl
    pop  bc
    dec  b
    jr   nz, _LABEL_695C_
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
    call _LABEL_6510_
    ld   a, $0A
    call _LABEL_4A72_
    jp   _LABEL_63A7_

; Data from 6992 to 6A25 (148 bytes)
    db $FA, $9E, $D1, $EA, $A2, $D1, $E6, $F8, $C6, $07, $47, $FA, $A0, $D1, $B8, $DA
    db $C6, $69, $CA, $C6, $69, $78, $EA, $A4, $D1, $CD, $D0, $69, $FA, $A4, $D1, $3C
    db $EA, $A2, $D1, $C6, $07, $21, $A0, $D1, $BE, $D2, $C6, $69, $EA, $A4, $D1, $CD
    db $D0, $69, $18, $E8, $FA, $A0, $D1, $EA, $A4, $D1, $CD, $D0, $69, $C9, $FA, $9F
    db $D1, $EA, $A3, $D1, $E6, $F8, $C6, $07, $47, $FA, $A1, $D1, $B8, $38, $32, $28
    db $30, $78, $EA, $A5, $D1, $3E, $02, $EA, $95, $D1, $FB, $FA, $95, $D1, $A7, $20
    db $FA, $FA, $A5, $D1, $3C, $EA, $A3, $D1, $C6, $07, $21, $A1, $D1, $BE, $30, $11
    db $EA, $A5, $D1, $3E, $02, $EA, $95, $D1, $FB, $FA, $95, $D1, $A7, $20, $FA, $18
    db $E0, $FA, $A1, $D1, $EA, $A5, $D1, $3E, $02, $EA, $95, $D1, $FB, $FA, $95, $D1
    db $A7, $20, $FA, $C9

_LABEL_6A26_:
    ld   a, [_RAM_D19C_]    ; _RAM_D19C_ = $D19C
    ld   [_RAM_D1A7_], a    ; _RAM_D1A7_ = $D1A7
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    and  $07
    ld   b, $80
    jr   z, _LABEL_6A3A_
_LABEL_6A35_:
    srl  b
    dec  a
    jr   nz, _LABEL_6A35_
_LABEL_6A3A_:
    ld   a, [buttons_new_pressed__RAM_D006_]
    and  $F0
    ret  z
    and  $30
    jp   z, _LABEL_6A6E_
_LABEL_6A45_:
    push hl
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    and  $07
    sla  a
    call _LABEL_486E_
    call _LABEL_6AAD_
    pop  hl
    ld   a, [_RAM_D1A7_]    ; _RAM_D1A7_ = $D1A7
    dec  a
    ld   [_RAM_D1A7_], a    ; _RAM_D1A7_ = $D1A7
    ret  z
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    inc  a
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    and  $07
    jr   nz, _LABEL_6A45_
    push bc
    call _LABEL_6FA0_
    pop  bc
    jr   _LABEL_6A45_

_LABEL_6A6E_:
    push hl
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    and  $07
    sla  a
    call _LABEL_486E_
    call _LABEL_6AAD_
    pop  hl
    ld   a, [_RAM_D1A7_]    ; _RAM_D1A7_ = $D1A7
    dec  a
    ld   [_RAM_D1A7_], a    ; _RAM_D1A7_ = $D1A7
    ret  z
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    inc  a
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    and  $07
    jr   z, _LABEL_6A94_
    srl  b
    jr   _LABEL_6A6E_

_LABEL_6A94_:
    call _LABEL_6FA0_
    ld   b, $80
    jr   _LABEL_6A6E_

_LABEL_6A9B_:
    ld   a, [_RAM_D19D_]    ; _RAM_D19D_ = $D19D
    cp   $03
    jr   nz, _LABEL_6AA6_
    ld   a, $03
    jr   _LABEL_6AAC_

_LABEL_6AA6_:
    cp   $01
    jr   nz, _LABEL_6AAC_
    ld   a, $01
_LABEL_6AAC_:
    ret

_LABEL_6AAD_:
    call _LABEL_6A9B_
    bit  0, a
    jr   nz, _LABEL_6ABA_
    ld   a, $FF
    xor  b
    and  [hl]
    jr   _LABEL_6ABC_

_LABEL_6ABA_:
    ld   a, b
    or   [hl]
_LABEL_6ABC_:
    ldi  [hl], a
    call _LABEL_6A9B_
    bit  1, a
    jr   nz, _LABEL_6ACA_
    ld   a, $FF
    xor  b
    and  [hl]
    jr   _LABEL_6ACC_

_LABEL_6ACA_:
    ld   a, b
    or   [hl]
_LABEL_6ACC_:
    ldi  [hl], a
    ret

; Data from 6ACE to 6CD6 (521 bytes)
db $FA, $96, $D1, $FE, $00, $C2, $A7, $63, $FA, $4B, $D0, $EA, $CC, $C8, $CD, $53
db $09, $FA, $CB, $C8, $EA, $28, $D0, $FA, $CA, $C8, $EA, $29, $D0, $CD, $9B, $08
db $FA, $CB, $C8, $EA, $A8, $D1, $FA, $CA, $C8, $EA, $A9, $D1, $CD, $5F, $6B, $21
db $9F, $D1, $FA, $A1, $D1, $86, $CB, $1F, $47, $FA, $A8, $D1, $3C, $EA, $A8, $D1
db $3D, $3D, $EA, $AD, $D1, $78, $EA, $A9, $D1, $EA, $AE, $D1, $AF, $EA, $AA, $D1
db $3C, $EA, $AF, $D1, $FA, $9F, $D1, $EA, $AB, $D1, $EA, $B0, $D1, $FA, $A1, $D1
db $EA, $AC, $D1, $EA, $B1, $D1, $06, $5A, $AF, $21, $B2, $D1, $22, $05, $20, $FC
db $FA, $A8, $D1, $A7, $28, $05, $CD, $92, $6B, $18, $F5, $FA, $28, $D0, $EA, $CB
db $C8, $FA, $29, $D0, $EA, $CA, $C8, $AF, $EA, $92, $D1, $CD, $10, $65, $C3, $A7
db $63, $FA, $A8, $D1, $EA, $CB, $C8, $FA, $A9, $D1, $EA, $CA, $C8, $EA, $A7, $D1
db $AF, $EA, $3B, $D0, $CD, $AF, $6C, $FA, $9F, $D1, $47, $FA, $A7, $D1, $B8, $EA
db $A1, $D1, $C8, $FA, $A8, $D1, $EA, $CB, $C8, $FA, $A9, $D1, $3C, $EA, $CA, $C8
db $CD, $8E, $6D, $C9, $FA, $AB, $D1, $EA, $9F, $D1, $FA, $AC, $D1, $EA, $A1, $D1
db $CD, $D0, $6B, $A7, $C0, $FA, $9F, $D1, $EA, $A3, $D1, $FA, $A1, $D1, $EA, $A5
db $D1, $CD, $5F, $6B, $FA, $9F, $D1, $47, $FA, $A1, $D1, $B8, $C8, $CD, $52, $6E
db $FA, $AA, $D1, $A7, $FA, $A8, $D1, $20, $03, $3C, $18, $01, $3D, $EA, $A8, $D1
db $18, $CE, $FA, $A8, $D1, $EA, $CB, $C8, $CB, $7F, $20, $06, $FE, $20, $38, $62
db $18, $04, $FE, $90, $30, $5C, $FA, $A9, $D1, $EA, $CA, $C8, $CB, $7F, $20, $06
db $FE, $18, $38, $4E, $18, $04, $FE, $88, $30, $48, $3E, $01, $EA, $3B, $D0, $CD
db $AF, $6C, $FA, $A8, $D1, $EA, $CB, $C8, $FA, $A9, $D1, $EA, $CA, $C8, $CD, $8E
db $6D, $21, $A3, $D1, $FA, $A5, $D1, $BE, $3E, $00, $C8, $FA, $9F, $D1, $21, $A3
db $D1, $96, $30, $02, $18, $22, $FA, $A5, $D1, $21, $A1, $D1, $96, $30, $13, $FA
db $A5, $D1, $3D, $86, $CB, $1F, $EA, $A9, $D1, $FA, $A5, $D1, $3D, $EA, $AB, $D1
db $AF, $C9, $CD, $9C, $6C, $3E, $01, $C9, $FA, $9F, $D1, $86, $3C, $CB, $1F, $EA
db $A9, $D1, $FA, $A3, $D1, $3C, $EA, $AC, $D1, $CD, $87, $6C, $FA, $AD, $D1, $EA
db $A8, $D1, $FA, $A5, $D1, $21, $A1, $D1, $96, $30, $19, $FA, $A5, $D1, $3D, $86
db $CB, $1F, $EA, $A9, $D1, $FA, $A5, $D1, $3D, $EA, $AB, $D1, $FA, $A1, $D1, $EA
db $AC, $D1, $AF, $C9, $CD, $9C, $6C, $AF, $C9, $E5, $21, $0B, $D2, $11, $06, $D2
db $06, $5F, $1A, $32, $1B, $05, $20, $FA, $AF, $EA, $A8, $D1, $E1, $C9, $21, $A8
db $D1, $11, $AD, $D1, $06, $5F, $1A, $22, $13, $05, $20, $FA, $AF, $EA, $07, $D2
db $C9, $CD, $A0, $6F, $FA, $CB, $C8, $E6, $07, $47, $16, $80, $A7, $28, $05, $CB
db $3A, $05, $20, $FB, $AF, $EA, $0C, $D2, $FA, $CA, $C8, $E6, $07, $4F, $0C, $CB
db $27, $CD, $6E, $48, $23, $CD, $1E, $6D, $C9

_LABEL_6CD7_:
    ld   a, [_RAM_D03B_]    ; _RAM_D03B_ = $D03B
    and  a
    jr   nz, _LABEL_6D0F_
_LABEL_6CDD_:
    ldd  a, [hl]
    ld   b, a
    ldd  a, [hl]
    or   b
    and  d
    jr   nz, _LABEL_6D19_
    inc  hl
    inc  hl
    ld   a, [_RAM_D19D_]    ; _RAM_D19D_ = $D19D
    bit  1, a
    jr   z, _LABEL_6CF1_
    ld   a, [hl]
    or   d
    jr   _LABEL_6CF7_

_LABEL_6CF1_:
    ld   a, $FF
    xor  d
    ld   b, a
    ld   a, [hl]
    and  b
_LABEL_6CF7_:
    ldd  [hl], a
    ld   a, [_RAM_D19D_]    ; _RAM_D19D_ = $D19D
    bit  0, a
    jr   z, _LABEL_6D03_
    ld   a, [hl]
    or   d
    jr   _LABEL_6D09_

_LABEL_6D03_:
    ld   a, $FF
    xor  d
    ld   b, a
    ld   a, [hl]
    and  b
_LABEL_6D09_:
    ldd  [hl], a
    dec  c
    jr   nz, _LABEL_6CDD_
    jr   _LABEL_6D19_

_LABEL_6D0F_:
    ldd  a, [hl]
    ld   b, a
    ldd  a, [hl]
    or   b
    and  d
    jr   z, _LABEL_6D19_
    dec  c
    jr   nz, _LABEL_6D0F_
_LABEL_6D19_:
    ld   a, c
    ld   [_RAM_D03A_], a    ; _RAM_D03A_ = $D03A
    ret

; Data from 6D1E to 6DAA (141 bytes)
db $7C, $EA, $93, $D1, $7D, $EA, $94, $D1, $3E, $05, $EA, $95, $D1, $FB, $FA, $95
db $D1, $A7, $20, $FA, $FA, $3A, $D0, $A7, $20, $2B, $3E, $01, $EA, $0C, $D2, $FA
db $CA, $C8, $E6, $F8, $3D, $EA, $CA, $C8, $CB, $7F, $20, $0B, $FE, $18, $30, $07
db $3E, $08, $EA, $3A, $D0, $18, $0E, $D5, $CD, $A0, $6F, $D1, $3E, $0F, $CD, $6E
db $48, $0E, $08, $18, $BB, $FA, $0C, $D2, $A7, $FA, $3A, $D0, $4F, $28, $06, $3E
db $08, $91, $4F, $18, $08, $FA, $CA, $C8, $E6, $07, $3C, $91, $4F, $FA, $3B, $D0
db $A7, $FA, $CA, $C8, $20, $05, $91, $EA, $9F, $D1, $C9, $91, $EA, $A3, $D1, $C9
db $D5, $CD, $A0, $6F, $D1, $AF, $EA, $0C, $D2, $FA, $CA, $C8, $E6, $07, $5F, $3E
db $08, $93, $4F, $7B, $CB, $27, $CD, $6E, $48, $CD, $F2, $6D, $C9

_LABEL_6DAB_:
    ld   a, [_RAM_D03B_]    ; _RAM_D03B_ = $D03B
    and  a
    jr   nz, _LABEL_6DE3_
_LABEL_6DB1_:
    ldi  a, [hl]
    ld   b, a
    ldi  a, [hl]
    or   b
    and  d
    jr   nz, _LABEL_6DED_
    dec  hl
    dec  hl
    ld   a, [_RAM_D19D_]    ; _RAM_D19D_ = $D19D
    bit  0, a
    jr   z, _LABEL_6DC5_
    ld   a, [hl]
    or   d
    jr   _LABEL_6DCB_

_LABEL_6DC5_:
    ld   a, $FF
    xor  d
    ld   b, a
    ld   a, [hl]
    and  b
_LABEL_6DCB_:
    ldi  [hl], a
    ld   a, [_RAM_D19D_]    ; _RAM_D19D_ = $D19D
    bit  1, a
    jr   z, _LABEL_6DD7_
    ld   a, [hl]
    or   d
    jr   _LABEL_6DDD_

_LABEL_6DD7_:
    ld   a, $FF
    xor  d
    ld   b, a
    ld   a, [hl]
    and  b
_LABEL_6DDD_:
    ldi  [hl], a
    dec  c
    jr   nz, _LABEL_6DB1_
    jr   _LABEL_6DED_

_LABEL_6DE3_:
    ldi  a, [hl]
    ld   b, a
    ldi  a, [hl]
    or   b
    and  d
    jr   z, _LABEL_6DED_
    dec  c
    jr   nz, _LABEL_6DE3_
_LABEL_6DED_:
    ld   a, c
    ld   [_RAM_D03A_], a    ; _RAM_D03A_ = $D03A
    ret

; Data from 6DF2 to 6E3A (73 bytes)
db $7C, $EA, $93, $D1, $7D, $EA, $94, $D1, $3E, $06, $EA, $95, $D1, $FB, $FA, $95
db $D1, $A7, $20, $FA, $FA, $3A, $D0, $A7, $20, $22, $3E, $01, $EA, $0C, $D2, $FA
db $CA, $C8, $E6, $F8, $C6, $08, $EA, $CA, $C8, $CB, $7F, $28, $06, $FE, $88, $3E
db $08, $28, $09, $D5, $CD, $A0, $6F, $D1, $0E, $08, $18, $C4, $4F, $FA, $0C, $D2
db $A7, $20, $06, $3E, $08, $93, $91, $18, $03

_LABEL_6E3B_:
    ld   a, $08
    sub  c
; Data from 6E3E to 6F3F (258 bytes)
db $5F, $FA, $3B, $D0, $A7, $FA, $CA, $C8, $20, $05, $83, $EA, $A1, $D1, $C9, $83
db $EA, $A5, $D1, $C9, $FA, $AA, $D1, $57, $21, $9F, $D1, $FA, $A3, $D1, $96, $C6
db $01, $FE, $03, $38, $60, $CD, $87, $6C, $FA, $AD, $D1, $EA, $A8, $D1, $FA, $A3
db $D1, $BE, $30, $1D, $86, $CB, $1F, $EA, $AE, $D1, $FA, $A3, $D1, $EA, $B0, $D1
db $FA, $9F, $D1, $EA, $B1, $D1, $EA, $AB, $D1, $FA, $A1, $D1, $EA, $AC, $D1, $18
db $34, $86, $CB, $1F, $EA, $AE, $D1, $FA, $AF, $D1, $CB, $47, $20, $06, $FA, $AD
db $D1, $3D, $20, $04, $FA, $AD, $D1, $3C, $EA, $AD, $D1, $FA, $AF, $D1, $06, $01
db $A8, $EA, $AF, $D1, $FA, $9F, $D1, $EA, $B0, $D1, $FA, $A3, $D1, $EA, $B1, $D1
db $FA, $9F, $D1, $18, $C1, $21, $A1, $D1, $FA, $A5, $D1, $96, $C6, $01, $FE, $03
db $38, $57, $CD, $87, $6C, $FA, $AD, $D1, $EA, $A8, $D1, $21, $A1, $D1, $FA, $A5
db $D1, $BE, $38, $14, $86, $CB, $1F, $EA, $AE, $D1, $FA, $A1, $D1, $EA, $B0, $D1
db $FA, $A5, $D1, $EA, $B1, $D1, $18, $3D, $86, $CB, $1F, $EA, $AE, $D1, $FA, $AF
db $D1, $CB, $47, $20, $06, $FA, $AD, $D1, $3D, $18, $04, $FA, $AD, $D1, $3C, $EA
db $AD, $D1, $FA, $AF, $D1, $06, $01, $A8, $EA, $AF, $D1, $FA, $A5, $D1, $EA, $B0
db $D1, $FA, $A1, $D1, $EA, $B1, $D1, $18, $0C, $FA, $9F, $D1, $21, $A1, $D1, $86
db $CB, $1F, $EA, $A9, $D1, $FA, $9F, $D1, $EA, $AB, $D1, $FA, $A1, $D1, $EA, $AC
db $D1, $C9

_LABEL_6F40_:
    ld   a, [_RAM_D1A2_]    ; _RAM_D1A2_ = $D1A2
    ld   [_tilemap_pos_x__RAM_C8CB_], a
    ld   a, [_RAM_D1A3_]    ; _RAM_D1A3_ = $D1A3
    ld   [_tilemap_pos_y__RAM_C8CA_], a
    call _LABEL_6FA0_
    ld   a, [_RAM_D1A3_]    ; _RAM_D1A3_ = $D1A3
    ld   b, a
    ld   a, [_RAM_D1A5_]    ; _RAM_D1A5_ = $D1A5
    sub  b
    inc  a
    ld   [_RAM_D1A7_], a    ; _RAM_D1A7_ = $D1A7
    ld   a, [_RAM_D1A3_]    ; _RAM_D1A3_ = $D1A3
    and  $07
    sla  a
    call _LABEL_486E_
    ld   a, [_RAM_D1A2_]    ; _RAM_D1A2_ = $D1A2
    and  $07
    ld   c, a
    ld   a, [_RAM_D1A4_]    ; _RAM_D1A4_ = $D1A4
    and  $07
    sub  c
    ld   b, $80
    jr   z, _LABEL_6F7A_
_LABEL_6F75_:
    sra  b
    dec  a
    jr   nz, _LABEL_6F75_
_LABEL_6F7A_:
    ld   a, c
    and  a
    jr   z, _LABEL_6F83_
_LABEL_6F7E_:
    srl  b
    dec  c
    jr   nz, _LABEL_6F7E_
_LABEL_6F83_:
    ld   a, $FF
    xor  b
    ld   b, a
_LABEL_6F87_:
    ld   a, b
    and  [hl]
    ldi  [hl], a
    ld   a, b
    and  [hl]
    ldi  [hl], a
    ld   a, [_RAM_D1A7_]    ; _RAM_D1A7_ = $D1A7
    dec  a
    ld   [_RAM_D1A7_], a    ; _RAM_D1A7_ = $D1A7
    jr   nz, _LABEL_6F87_
    ret

; Data from 6F97 to 6F9F (9 bytes)
db $FA, $4B, $D0, $EA, $CC, $C8, $CD, $53, $09

_LABEL_6FA0_:
    ld   a, [_tilemap_pos_x__RAM_C8CB_]
    srl  a
    srl  a
    srl  a
    sub  $04
    ld   [_RAM_D03A_], a    ; _RAM_D03A_ = $D03A
    ld   a, [_tilemap_pos_y__RAM_C8CA_]
    srl  a
    srl  a
    srl  a
    sub  $03
    ld   b, $0E
    call multiply_a_x_b__result_in_de__4853_
    ld   a, e
    ld   hl, _RAM_D03A_ ; _RAM_D03A_ = $D03A
    add  [hl]
    bit  7, a
    push af
    res  7, a
    ld   b, $10
    call multiply_a_x_b__result_in_de__4853_
    pop  af
    jr   nz, _LABEL_6FD5_
    ld   hl, $9000
_LABEL_6FD3_:
    jr   _LABEL_6FEB_

_LABEL_6FD5_:
    ld   hl, $8800
    add  hl, de
    ld   a, h
    cp   $8C
    ret  c
    jr   z, _LABEL_6FE3_
    ld   hl, $8FF0
    ret

_LABEL_6FE3_:
    ld   a, l
    cp   $40
    ret  c
    ld   hl, $8FF0
    ret

_LABEL_6FEB_:
    add  hl, de
    ret

    ; Data from 6FED to 7119 (301 bytes)
db $FA, $4B, $D0, $EA, $CC, $C8, $CD, $53, $09, $FA, $CB, $C8, $EA, $73, $D0, $FA
db $CA, $C8, $EA, $74, $D0, $CD, $9B, $08, $CD, $75, $48, $CD, $2C, $09, $CD, $4C
db $09, $21, $00, $88, $11, $00, $80, $2A, $12, $13, $7A, $FE, $88, $C2, $14, $70
db $CD, $2C, $09, $CD, $4C, $09, $21, $00, $88, $11, $2A, $2F, $01, $00, $08, $CD
db $00, $C9, $01, $04, $01, $11, $0E, $12, $3E, $F2, $21, $00, $98, $CD, $EB, $48
db $11, $9F, $70, $21, $04, $08, $0E, $01, $CD, $46, $4A, $11, $A5, $70, $21, $06
db $02, $06, $0A, $0E, $01, $C5, $E5, $CD, $46, $4A, $E1, $C1, $2C, $05, $20, $F5
db $CD, $27, $06, $CD, $84, $4B, $CD, $21, $77, $CD, $84, $4B, $CD, $2C, $09, $CD
db $4C, $09, $21, $00, $80, $11, $00, $88, $2A, $12, $13, $7C, $FE, $88, $C2, $75
db $70, $21, $00, $98, $3E, $C8, $22, $7C, $FE, $9C, $20, $F8, $F0, $10, $F6, $A1
db $E0, $10, $FA, $73, $D0, $EA, $CB, $C8, $FA, $74, $D0, $EA, $CA, $C8, $CD, $10
db $65, $C9, $81, $99, $95, $84, $81, $00, $86, $C1, $FE, $BE, $87, $92, $8F, $93
db $8F, $92, $00, $BE, $BE, $BE, $BE, $94, $92, $81, $9A, $8F, $00, $86, $C2, $FE
db $BE, $94, $8F, $8E, $8F, $BE, $84, $85, $BE, $87, $92, $89, $93, $00, $86, $C3
db $FE, $BE, $93, $81, $8C, $96, $81, $92, $00, $BE, $BE, $BE, $BE, $81, $92, $83
db $88, $89, $96, $8F, $00, $86, $C4, $FE, $BE, $8C, $8C, $85, $8E, $8F, $00, $86
db $C5, $FE, $BE, $82, $8F, $92, $92, $81, $92, $00, $86, $C6, $FE, $BE, $90, $8C
db $95, $8D, $81, $BE, $84, $85, $00, $BE, $BE, $BE, $BE, $84, $89, $82, $95, $8A
    db $8F, $00, $86, $C7, $FE, $BE, $86, $8C, $85, $83, $88, $81, $00

_LABEL_711A_:
        call wait_until_vbl__92C_
        call _LABEL_94C_
        ld   hl, $9000
        ld   de, $40BA
        ld   bc, $0800
        call _memcopy_in_RAM__C900_
        call wait_until_vbl__92C_
        call _LABEL_94C_
        ld   hl, $8800
        ld   de, $2F2A
        ld   bc, $0800
        call _memcopy_in_RAM__C900_
        xor  a
        ld   [_RAM_D03B_ + 1], a
        ld   [_RAM_D03B_ + 2], a
        ld   [_RAM_D03B_ + 3], a
        ld   [_RAM_D03F_], a
        ld   a, $01
        ld   [_RAM_D06C_], a    ; _RAM_D06C_ = $D06C
        ld   a, $05
        ld   [_RAM_D06D_], a    ; _RAM_D06D_ = $D06D
        call _LABEL_4A7B_
        ld   a, [_RAM_D06E_]
        cp   $00
        push af
        call z, _LABEL_7185_
        pop  af
        cp   $01
        push af
        call z, _LABEL_720B_
        pop  af
        cp   $02
        push af
        call z, _LABEL_7226_
        pop  af
        cp   $03
        push af
        call z, _LABEL_741D_
        pop  af
        cp   $04
        ret  nc
        xor  a
        ldh  [rSB], a
        ldh  [rSC], a
        call _LABEL_784F_
        jp   _LABEL_711A_

_LABEL_7185_:
        call wait_until_vbl__92C_
        call _LABEL_94C_
        ld   hl, $8800
        ld   de, $2F2A
        ld   bc, $0800
        call _memcopy_in_RAM__C900_
        call wait_until_vbl__92C_
        call _LABEL_94C_
        ld   hl, $9000
        ld   de, $27FA
        ld   bc, $0800
        call _memcopy_in_RAM__C900_
        call _LABEL_7691_
        call _LABEL_761F_
        call _display_bg_sprites_on__627_
        xor  a
        ld   [_RAM_D04B_], a
        ld   a, $FF
        ld   [_RAM_D079_], a
_LABEL_71BB_:
        call timer_wait_tick_AND_TODO__289_
        call maybe_input_read_keys__C8D_
        ld   a, [maybe_input_key_new_pressed__RAM_D025_]
        cp   $2A
        jr   z, _LABEL_7207_
        cp   $2F
        jr   nz, _LABEL_71D1_
        call _LABEL_522_
        jr   _LABEL_71BB_

_LABEL_71D1_:
        cp   $18
        jr   nc, _LABEL_71F6_
        ld   hl, _RAM_D079_
        cp   [hl]
        jr   nz, _LABEL_71E2_
        ld   a, $F9
        ld   [_RAM_CC23_], a    ; _RAM_CC23_ = $CC23
        jr   _LABEL_71BB_

_LABEL_71E2_:
        ld   [hl], a
        sla  a
        ld   [_RAM_D03A_], a    ; _RAM_D03A_ = $D03A
        ld   hl, $7980
        call _LABEL_486E_
        call _LABEL_2A2_
        call _LABEL_77D3_
        jr   _LABEL_71BB_

_LABEL_71F6_:
        ld   a, $FF
        ld   [_RAM_D079_], a
        call _LABEL_77B0_
        xor  a
        ld   [_RAM_CC00_], a    ; _RAM_CC00_ = $CC00
        call _LABEL_787C_
        jr   _LABEL_71BB_

_LABEL_7207_:
        call _LABEL_77B0_
        ret

_LABEL_720B_:
        ld   b, $00
        call _LABEL_7242_
        ret  z
        call _LABEL_7691_
        call _LABEL_761F_
        call _LABEL_765B_
        call _display_bg_sprites_on__627_
        xor  a
        ld   [_RAM_D07B_], a
        call _LABEL_7310_
        jr   _LABEL_720B_

_LABEL_7226_:
        ld   b, $01
        call _LABEL_7242_
        ret  z
        call _LABEL_7691_
        call _LABEL_761F_
        call _LABEL_766D_
        call _display_bg_sprites_on__627_
        ld   a, $01
        ld   [_RAM_D07B_], a
        call _LABEL_7310_
        jr   _LABEL_7226_

_LABEL_7242_:
        push bc
        call wait_until_vbl__92C_
        call _LABEL_94C_
        ld   hl, $8800
        ld   de, $2F2A
        ld   bc, $0800
        call _memcopy_in_RAM__C900_
        call wait_until_vbl__92C_
        call _LABEL_94C_
        ld   hl, $9000
        ld   de, $27FA
        ld   bc, $0800
        call _memcopy_in_RAM__C900_
        call _LABEL_4875_
        call wait_until_vbl__92C_
        call _LABEL_94C_
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
        ld   de, _DATA_78FF_
        ld   hl, $0109
        ld   c, PRINT_NORMAL  ; $01
        call render_string_at_de_to_tilemap0_xy_in_hl__4A46_
        ld   de, _DATA_7912_
        ld   hl, $030B
        ld   c, PRINT_NORMAL  ; $01
        call render_string_at_de_to_tilemap0_xy_in_hl__4A46_
        xor  a
        ld   [_RAM_D03A_], a    ; _RAM_D03A_ = $D03A
        ld   [_RAM_D03B_], a    ; _RAM_D03B_ = $D03B
_LABEL_72A0_:
        call _LABEL_72F0_
        call timer_wait_tick_AND_TODO__289_
        call maybe_input_read_keys__C8D_
        ld   a, [maybe_input_key_new_pressed__RAM_D025_]
        cp   $2A
        jr   nz, _LABEL_72B5_
        xor  a
        ld   [_RAM_D03A_], a    ; _RAM_D03A_ = $D03A
        ret

_LABEL_72B5_:
        cp   $2E
        jr   nz, _LABEL_72C0_
        ld   a, [_RAM_D03A_]    ; _RAM_D03A_ = $D03A
        and  a
        jr   z, _LABEL_72A0_
        ret

_LABEL_72C0_:
        cp   $2F
        jr   nz, _LABEL_72D9_
        ld   a, $0E
        ld   [_RAM_D03B_], a    ; _RAM_D03B_ = $D03B
        call _LABEL_72F0_
        ld   a, [_RAM_D03A_]    ; _RAM_D03A_ = $D03A
        push af
        call _LABEL_522_
        pop  af
        ld   [_RAM_D03A_], a    ; _RAM_D03A_ = $D03A
        jr   _LABEL_72A0_

_LABEL_72D9_:
        cp   $C1
        jr   c, _LABEL_72A0_
        cp   $CA
        jr   nc, _LABEL_72A0_
        ld   b, a
        call wait_until_vbl__92C_
        ld   a, b
        ld   [$994B], a
        sub  $C0
        ld   [_RAM_D03A_], a    ; _RAM_D03A_ = $D03A
        jr   _LABEL_72A0_

_LABEL_72F0_:
        ld   a, [_RAM_D03B_]    ; _RAM_D03B_ = $D03B
        inc  a
        ld   [_RAM_D03B_], a    ; _RAM_D03B_ = $D03B
        and  $0F
        jr   nz, _LABEL_7304_
        call wait_until_vbl__92C_
        ld   a, $BF
        ld   [$9949], a
        ret

_LABEL_7304_:
        cp   $08
        ret  nz
        call wait_until_vbl__92C_
        ld   a, $BE
        ld   [$9949], a
        ret

_LABEL_7310_:
        ld   hl, _DATA_F45_
        ld   a, [_RAM_D03A_]    ; _RAM_D03A_ = $D03A
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
        call _LABEL_76D4_
        call maybe_input_wait_for_keys__4B84
        xor  a
        ld   [_RAM_D04B_], a
_LABEL_7334_:
        xor  a
        ld   [_RAM_CC00_], a    ; _RAM_CC00_ = $CC00
        call _LABEL_787C_
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
        ld   a, [_RAM_D03B_]    ; _RAM_D03B_ = $D03B
        cp   b
        jr   nz, _LABEL_7377_
        push hl
        push bc
        ld   a, [_RAM_D07B_]
        and  a
        jr   nz, _LABEL_7375_
_LABEL_7366_:
        call maybe_input_read_keys__C8D_
        ld   a, [maybe_input_second_rx_byte__RAM_D027_]
        bit  0, a
        jr   z, _LABEL_7375_
        call timer_wait_tick_AND_TODO__289_
        jr   _LABEL_7366_

_LABEL_7375_:
        pop  bc
        pop  hl
_LABEL_7377_:
        ld   a, b
        ld   [_RAM_D03B_], a    ; _RAM_D03B_ = $D03B
        sla  a
        ld   [_RAM_D03A_], a    ; _RAM_D03A_ = $D03A
        ldi  a, [hl]
        push hl
        ld   [_RAM_D07A_], a
        xor  a
        ld   [_RAM_D400_], a
        call _LABEL_77D3_
_LABEL_738C_:
        call timer_wait_tick_AND_TODO__289_
        call maybe_input_read_keys__C8D_
        ld   a, [maybe_input_key_new_pressed__RAM_D025_]
        cp   $2A
        jp   z, _LABEL_7417_
        cp   $2F
        jr   nz, _LABEL_73A4_
        call _LABEL_522_
        jp   _LABEL_738C_

_LABEL_73A4_:
        ld   a, [_RAM_D07B_]
        and  a
        jr   nz, _LABEL_73C5_
        ld   a, [maybe_input_key_new_pressed__RAM_D025_]
        ld   b, a
        ld   a, [_RAM_D03B_]    ; _RAM_D03B_ = $D03B
        cp   b
        jr   z, _LABEL_73C5_
        ld   a, [_RAM_D400_]
        cp   $01
        jp   z, _LABEL_7334_
        xor  a
        ld   [_RAM_CC00_], a    ; _RAM_CC00_ = $CC00
        call _LABEL_787C_
        jr   _LABEL_738C_

_LABEL_73C5_:
        ld   hl, $7980
        ld   a, [_RAM_D03B_]    ; _RAM_D03B_ = $D03B
        cp   $3C
        jr   nz, _LABEL_73D1_
        ld   a, $18
_LABEL_73D1_:
        sla  a
        call _LABEL_486E_
        ld   a, [_RAM_CC00_]    ; _RAM_CC00_ = $CC00
        and  a
        jr   nz, _LABEL_73DF_
        call _LABEL_2A2_
_LABEL_73DF_:
        ld   a, [_RAM_D07C_]
        and  a
        jr   nz, _LABEL_73E8_
        call timer_wait_tick_AND_TODO__289_
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
        call _LABEL_76E0_
_LABEL_740D_:
        call _LABEL_77B0_
        call _LABEL_784F_
        call maybe_input_wait_for_keys__4B84
        ret

_LABEL_7417_:
        pop  hl
        call _LABEL_7704_
        jr   _LABEL_740D_

_LABEL_741D_:
        call wait_until_vbl__92C_
        call _LABEL_94C_
        ld   hl, $8800
        ld   de, $2F2A
        ld   bc, $0800
        call _memcopy_in_RAM__C900_
        call wait_until_vbl__92C_
        call _LABEL_94C_
        ld   hl, $9000
        ld   de, $27FA
        ld   bc, $0800
        call _memcopy_in_RAM__C900_
        call _LABEL_7691_
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
        call timer_wait_tick_AND_TODO__289_
        call maybe_input_read_keys__C8D_
        pop  de
        inc  e
_LABEL_7470_:
        ld   a, [maybe_input_key_new_pressed__RAM_D025_]
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
        call _LABEL_76F8_
        call maybe_input_wait_for_keys__4B84
        ld   a, $03
        ld   [_RAM_D07F_], a
        ld   a, $03
        ld   [_RAM_D03B_], a    ; _RAM_D03B_ = $D03B
        call _LABEL_7721_
        call _LABEL_7704_
        ld   e, $00
        jp   _LABEL_7470_

_LABEL_74A6_:
        cp   $31
        jp   z, _LABEL_75F0_
        cp   $2E
        jp   z, _LABEL_75BD_
        cp   $32
        jp   z, _LABEL_75A3_
        cp   $2D
        jp   nz, _LABEL_74BD_
        call _LABEL_7733_
_LABEL_74BD_:
        ld   a, [_RAM_D07F_]
        and  a
        jr   nz, _LABEL_74D9_
        ld   a, e
        cp   $1E
        jr   nz, _LABEL_74CB_
        call _LABEL_7704_
_LABEL_74CB_:
        ld   a, [maybe_input_key_new_pressed__RAM_D025_]
        cp   $2F
        jp   nz, _LABEL_7467_
        call _LABEL_522_
        jp   _LABEL_7465_

_LABEL_74D9_:
        ld   a, [maybe_input_key_new_pressed__RAM_D025_]
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
        call _LABEL_486E_
        call _LABEL_2A2_
        call _LABEL_77D3_
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
        call _LABEL_486E_
        ld   a, [_RAM_D07E_]
        add  $18
        ldi  [hl], a
        ld   a, [_RAM_D03B_]    ; _RAM_D03B_ = $D03B
        ldi  [hl], a
        ld   a, $03
        ld   [_RAM_D03B_], a    ; _RAM_D03B_ = $D03B
        jp   _LABEL_7465_

_LABEL_7532_:
        call _LABEL_76BC_
        ld   a, $01
        ld   [_RAM_D07C_], a
        xor  a
        ld   [_RAM_CC00_], a    ; _RAM_CC00_ = $CC00
        call _LABEL_787C_
        ld   [_RAM_D07F_], a
        ld   a, $FF
        ld   [_RAM_D180_], a
        ld   a, $3C
        ld   [_RAM_D079_], a
        call _LABEL_77B0_
        call maybe_input_wait_for_keys__4B84
        ld   b, $32
_LABEL_7556_:
        push bc
        call timer_wait_tick_AND_TODO__289_
        call maybe_input_read_keys__C8D_
        pop  bc
        ld   a, [maybe_input_key_new_pressed__RAM_D025_]
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
        call _LABEL_787C_
        ld   a, [_RAM_D079_]
        cp   $3C
        ld   [_RAM_D07E_], a
        ld   a, $3C
        ld   [_RAM_D079_], a
        jp   nz, _LABEL_750C_
        ld   [_RAM_D07E_], a
_LABEL_7593_:
        ld   a, [_RAM_D03B_]    ; _RAM_D03B_ = $D03B
        inc  a
        cp   $FA
        jr   nz, _LABEL_759D_
        ld   a, $F9
_LABEL_759D_:
        ld   [_RAM_D03B_], a    ; _RAM_D03B_ = $D03B
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
        call maybe_input_wait_for_keys__4B84
        jp   _LABEL_7465_

_LABEL_75BD_:
        call _LABEL_75CF_
        call _LABEL_7704_
        call _LABEL_76B0_
        call _LABEL_77B0_
        call maybe_input_wait_for_keys__4B84
        jp   _LABEL_7465_

_LABEL_75CF_:
        ld   hl, _RAM_D080_
        ld   a, [_RAM_D07D_]
        bit  7, a
        jr   nz, _LABEL_75E0_
        sla  a
        call _LABEL_486E_
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
        call maybe_input_wait_for_keys__4B84
        jp   _LABEL_7465_

_LABEL_760A_:
        call _LABEL_7704_
        call _LABEL_76EC_
        call _LABEL_77B0_
        ld   e, $00
        xor  a
        ld   [_RAM_D07F_], a
        call maybe_input_wait_for_keys__4B84
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
        call maybe__vram_write_byte_2rows_addr_in_hl_preset_data__5494_
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

_LABEL_7691_:
        call _LABEL_4875_
        ld   de, _DATA_438A_
        ld   hl, $9940
        call wait_until_vbl__92C_
        call _LABEL_94C_
        ld   c, $06
_LABEL_76A2_:
        ld   b, $14
        call _LABEL_481F_
        ld   a, $0C
        call _LABEL_486E_
        dec  c
        jr   nz, _LABEL_76A2_
        ret

_LABEL_76B0_:
        ld   de, _DATA_7918_
        ld   hl, $0107
        ld   c, PRINT_NORMAL  ; $01
        call render_string_at_de_to_tilemap0_xy_in_hl__4A46_
        ret

_LABEL_76BC_:
        ld   de, _DATA_7927_
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

_LABEL_76D4_:
        ld   de, _DATA_795A_
        ld   hl, $0107
        ld   c, PRINT_NORMAL  ; $01
        call render_string_at_de_to_tilemap0_xy_in_hl__4A46_
        ret

_LABEL_76E0_:
        ld   de, _DATA_796B_
        ld   hl, $0107
        ld  c, PRINT_NORMAL  ; $01
        call render_string_at_de_to_tilemap0_xy_in_hl__4A46_
        ret

_LABEL_76EC_:
        ld   de, _DATA_7935_
        ld   hl, $0107
        ld  c, PRINT_NORMAL  ; $01
        call render_string_at_de_to_tilemap0_xy_in_hl__4A46_
        ret

_LABEL_76F8_:
        ld   de, _DATA_7948_
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
        ld   a, [maybe_input_key_new_pressed__RAM_D025_]
        push af
        cp   $2F
        call z, _LABEL_522_
        pop  af
        cp   $FF
        jr   z, _LABEL_7721_
        ret

_LABEL_7733_:
        call wait_until_vbl__92C_
        call _LABEL_94C_
        ld   hl, $8800
        ld   de, $2F2A
        ld   bc, $0800
        call _memcopy_in_RAM__C900_
        call wait_until_vbl__92C_
        call _LABEL_94C_
        ld   hl, _TILEMAP0; $9800
        ld   de, $9C00
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
        call _LABEL_48EB_
        ld   de, _DATA_7888_
        ld   hl, $0707
        ld   c, PRINT_NORMAL  ; $01
        call render_string_at_de_to_tilemap0_xy_in_hl__4A46_
        ld   de, _DATA_788E_
        ld   hl, _DATA_20A_
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
        call maybe_input_wait_for_keys__4B84
        call _LABEL_7721_
        call wait_until_vbl__92C_
        call _LABEL_94C_
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
        call maybe_input_wait_for_keys__4B84
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

_LABEL_77D3_:
        call _LABEL_77B0_
        ld   hl, _DATA_79B2_
        ld   a, [_RAM_D03A_]    ; _RAM_D03A_ = $D03A
        cp   $78
        jr   nz, _LABEL_77E4_
        call _LABEL_787C_
        ret

_LABEL_77E4_:
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
        jr   z, _LABEL_7807_
        ld   a, $FD
        ld   [maybe_vram_data_to_write__RAM_C8CC_], a
_LABEL_7807_:
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
        jr   z, _LABEL_7827_
        sub  $10
_LABEL_7827_:
        ld   [_tilemap_pos_y__RAM_C8CA_], a
        xor  a
        ld   [_RAM_C8CD_], a    ; _RAM_C8CD_ = $C8CD
        ld   b, $04
        ld   de, _RAM_D03B_ + 1 ; _RAM_D03B_ + 1 = $D03C
_LABEL_7833_:
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
        jr   nz, _LABEL_7833_
        ret

_LABEL_784F_:
        xor  a
        ldh  [rAUDENA], a
        xor  a
        ldh  [rAUD3ENA], a
        ld   a, $FF
        ldh  [rAUD3LEN], a
        ld   a, $55
        ld   bc, $0800 | LOW(_AUD3WAVERAM_LAST) ; | _PORT_3F_
_LABEL_785E_:
        ldh  [c], a
        dec  c
        dec  b
        jr   nz, _LABEL_785E_
        ld   a, AUDENA_ON  ; $80
        ldh  [rAUDENA], a
        ld   a, %01110111  ; $77  ; Set rAUDVOL to Max Left/Right volume, with VIN off for left and right
        ldh  [rAUDVOL], a
        xor  a
        ldh  [rAUD3ENA], a
        ld   a, $28
        ldh  [rAUD1LEN], a
        ldh  [rAUD2LEN], a
        xor  a
        ld   [_RAM_CC00_], a    ; _RAM_CC00_ = $CC00
        call timer_wait_tick_AND_TODO__289_
        ret

_LABEL_787C_:
        xor  a
        ldh  [rAUDENA], a
        ld   a, AUDENA_ON  ; $80
        ldh  [rAUDENA], a
        ld   a, %01110111  ; $77  ; Set rAUDVOL to Max Left/Right volume, with VIN off for left and right
        ldh  [rAUDVOL], a
        ret

; Data from 7888 to 788D (6 bytes)
_DATA_7888_:
    db $81, $99, $95, $84, $81, $00

; Data from 788E to 78C2 (53 bytes)
_DATA_788E_:
    db $86, $C1, $BE, $FE, $BE, $87, $92, $81, $82, $81, $83, $89, $8F, $8E, $00, $86
    db $C2, $BE, $FE, $BE, $94, $8F, $83, $81, $00, $86, $C3, $BE, $FE, $BE, $82, $8F
    db $92, $92, $81, $00, $85, $8E, $94, $92, $81, $BE, $FE, $BE, $83, $8F, $8E, $86
    db $89, $92, $8D, $81, $00

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
_DATA_78FF_:
    db $93, $85, $8C, $85, $83, $83, $89, $8F, $8E, $81, $BE, $8D, $85, $8C, $8F, $84
    db $89, $81, $00

; Data from 7912 to 7917 (6 bytes)
_DATA_7912_:
    db $C1, $BE, $CB, $BE, $C9, $00

; Data from 7918 to 7926 (15 bytes)
_DATA_7918_:
    db $84, $85, $8A, $81, $BE, $84, $85, $BE, $87, $92, $81, $82, $81, $92, $00

; Data from 7927 to 7934 (14 bytes)
_DATA_7927_:
    db $8D, $85, $8D, $8F, $92, $89, $81, $BE, $8C, $8C, $85, $8E, $81, $00

; Data from 7935 to 7947 (19 bytes)
_DATA_7935_:
    db $8D, $85, $8C, $8F, $84, $89, $81, $BE, $8E, $8F, $BE, $87, $92, $81, $82, $81
    db $84, $81, $00

; Data from 7948 to 7959 (18 bytes)
_DATA_7948_:
    db $83, $8F, $8D, $89, $85, $8E, $9A, $81, $BE, $81, $BE, $87, $92, $81, $82, $81
    db $92, $00

; Data from 795A to 796A (17 bytes)
_DATA_795A_:
    db $83, $8F, $8D, $89, $85, $8E, $9A, $81, $BE, $81, $BE, $94, $8F, $83, $81, $92
    db $00

; Data from 796B to 7978 (14 bytes)
_DATA_796B_:
    db $84, $85, $8A, $81, $BE, $84, $85, $BE, $94, $8F, $83, $81, $92, $00

; Data from 7979 to 79B1 (57 bytes)
_DATA_7979_:
    db $82, $8F, $92, $92, $81, $92, $00, $18, $F9, $19, $F9, $1A, $F9, $1B, $F9, $1C
    db $F9, $1D, $F9, $1E, $F9, $1F, $F9, $20, $F9, $21, $F9, $22, $F9, $23, $F9, $24
    db $F9, $25, $F9, $26, $F9, $27, $F9, $28, $F9, $29, $F9, $2A, $F9, $2B, $F9, $2C
    db $F9, $2D, $F9, $2E, $F9, $2F, $F9, $54, $F9

; Data from 79B2 to 7FFF (1614 bytes)
_DATA_79B2_:
    db $1C, $90, $84, $8F, $BE, $BE, $20, $58, $84, $8F, $FC, $BE, $24, $90, $92, $85
    db $BE, $BE, $28, $58, $92, $85, $FC, $BE, $2C, $90, $8D, $89, $BE, $BE, $34, $90
    db $86, $81, $BE, $BE, $38, $58, $86, $81, $FC, $BE, $3C, $90, $93, $8F, $8C, $BE
    db $40, $58, $93, $8F, $8C, $FC, $44, $90, $8C, $81, $BE, $BE, $48, $58, $8C, $81
    db $FC, $BE, $4C, $90, $93, $89, $BE, $BE, $54, $90, $84, $8F, $BE, $BE, $58, $58
    db $84, $8F, $FC, $BE, $5C, $90, $92, $85, $BE, $BE, $60, $58, $92, $85, $FC, $BE
    db $64, $90, $8D, $89, $BE, $BE, $6C, $90, $86, $81, $BE, $BE, $70, $58, $86, $81
    db $FC, $BE, $74, $90, $93, $8F, $8C, $BE, $78, $58, $93, $8F, $8C, $FC, $7C, $90
    db $8C, $81, $BE, $BE, $80, $58, $8C, $81, $FC, $BE, $84, $90, $93, $89, $BE, $BE
ds 1470, $00
