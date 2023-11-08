
; SECTION "rom0_bankswitch_functions_07EF", ROM0[$07EF]

; ===== Bank switching functions =====
;
; Disclaimer: purpose of these has not been verified on hardware since the
; system ROM maybe un-maps itself when starting a program from the cart slot


; ** Appears to be: bank-switched memcopy
;    Returns to caller's bank
;
; - Source in DE
; - Dest   in HL
; - Length in BC
; - Bank to switch to in _rombank_switch_to__D6E6_
;
; - Gets copied to and run from: _switch_bank_memcopy_hl_to_de_len_bc_RAM__C960_
;
_switch_bank_memcopy_hl_to_de_len_bc_ROM__7EF_:
    di
    ld   a, [_rombank_switch_to__D6E6_]
    push af
    ld   a, [_rombank_currrent__C8D7_]
    ld   [_rombank_saved__C8D8_], a
    pop  af
    ld   [_rombank_currrent__C8D7_], a
    ld   [rROMB_SWITCH_MEGADUCK_QUIQUE], a
    ld   a, ROM_SWITCH_DELAY  ; $0A
    _wait_loop__703_:
        dec  a
        jr   nz, _wait_loop__703_
    call memcopy_in_RAM__C900_
    jp   $C940  ; TODO: probably the return bankswitch


; ** Appears to be: bank-switched read one byte from ROM to RAM
;    Returns to caller's bank
;
; - Address to read    in HL
; - Bank to read from  in _rombank_switch_to__D6E6_
; - Byte read returned in _rombank_readbyte_result__D6E7_
;
; - Gets copied to and run from _switch_bank_read_byte_at_hl_RAM__C980_
;
_switch_bank_read_byte_at_hl_ROM__80C_:
    di
    ld   a, [_rombank_switch_to__D6E6_]
    push af
    ld   a, [_rombank_currrent__C8D7_]
    ld   [_rombank_saved__C8D8_], a
    pop  af
    ld   [_rombank_currrent__C8D7_], a
    ld   [rROMB_SWITCH_MEGADUCK_QUIQUE], a
    ld   a, ROM_SWITCH_DELAY  ; $0A
    _wait_loop__820_:
        dec  a
        jr   nz, _wait_loop__820_
    nop  ; TODO: wait a little longer... is the standard delay not enough for some reason?
    nop
    ld   a, [hl]
    ld   [_rombank_readbyte_result__D6E7_], a
    jp   $C940  ; TODO: probably the return bankswitch


; ** Appears to be: bank switched jump to code at HL in another bank
;    Does not return to caller's bank
;
; - Address to jump to in HL
; - Bank to switch  to in A
;
; - Gets copied to and run from _switch_bank_jump_hl_RAM__C920_
;
_switch_bank_jump_hl_ROM__82C_:
    di
    push af
    ld   a, [_rombank_currrent__C8D7_]
    ld   [_rombank_saved__C8D8_], a
    pop  af
    ld   [_rombank_currrent__C8D7_], a
    ld   [rROMB_SWITCH_MEGADUCK_QUIQUE], a
    ld   a, ROM_SWITCH_DELAY  ; $0A
    _wait_loop__83D_:
        dec  a
        jr   nz, _wait_loop__83D_
    jp   hl


; ** Appears to be: basic bank switch
;    Does not return to caller's bank
;
; - Called by the some of the other bank switch functions
; - Gets copied to and run from _switch_bank_return_to_saved_bank_RAM__C940_
;
_switch_bank_return_to_saved_ROM__841_:
    di
    ld   a, [_rombank_saved__C8D8_]
    ld   [_rombank_currrent__C8D7_], a
    ld   [rROMB_SWITCH_MEGADUCK_QUIQUE], a
    ld   a, ROM_SWITCH_DELAY  ; $0A
    _wait_loop__84D_:
        dec  a
        jr   nz, _wait_loop__84D_
    ret

