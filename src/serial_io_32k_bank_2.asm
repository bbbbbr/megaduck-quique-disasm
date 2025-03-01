
; SECTION "32k_bank_2_serial_io_09CF", ROM0[$4B93]
; include "serial_io_32k_bank_2.asm"
;; 32K Bank addr: $02:0B93 (16K Bank addr: $04:4B93)

; All code addresses are off by +452 vs Bank 0 serial

; ===== Serial IO peripheral interface functions : 32K Bank 2 copy =====



; Does a serial IO system startup init
; Sends count up sequence, waits for and checks count down sequence in reverse
;
; - Turns on Serial interrupt on/off at various times
serial_system_init__ROM_32K_Bank2_0B93_:
    ld   a, IEF_SERIAL ; $08
    ldh  [rIE], a
    xor  a
    ld   [serial_system_status__RAM_D024_], a  ; TODO: System startup status var? (success/failure?)
    xor  a

    ; Send a count up sequence through the serial IO (0,1,2,3...255)
    ; Then wait for a response with no timeout
    .loop_send_sequence_1:
        ld   [serial_tx_data__RAM_D023_], a
        BANK32K_ADDR  call, serial_io_send_byte__32K_Bank_2_0D28_ ; call $0D28
        inc  a
        jr   nz, .loop_send_sequence_1
    BANK32K_ADDR  call, serial_io_read_byte_no_timeout__32K_Bank_2_0D41_  ; call $0D41

    ; Handle reply
    cp   SYS_REPLY_BOOT_OK  ; $01
    ld   b, $00             ; This might not do anything... (not used and later overwritten)
    BANK32K_ADDR  call, nz, serial_system_status_set_fail__32K_Bank_2_D7E_  ; call nz, $0D7E

    ; Send a "0" byte (SYS_CMD_INIT_SEQ_REQUEST)
    ; That requests a 255..0 countdown sequence (be sent into the serial IO)
    xor  a
    ld   [serial_tx_data__RAM_D023_], a
    BANK32K_ADDR  call, serial_io_send_byte__32K_Bank_2_0D28_ ; call $0D28

    ; Expects a reply sequence through the serial IO of (255,254...0)
    ld   b, $01             ; This might not do anything, again... (not used and later overwritten)
    ld   c, $FF
    .loop_receive_sequence_2:
        BANK32K_ADDR  call, serial_io_read_byte_no_timeout__32K_Bank_2_0D41_  ; call $0D41
        cp   c
        BANK32K_ADDR  call, nz, serial_system_status_set_fail__32K_Bank_2_D7E_  ; call nz, $0D7E  ; Set status failed if reply doesn't match expected  sequence value
        dec  c
        ld   a, c
        cp   $FF
        jr   nz, .loop_receive_sequence_2

    ; Check for failures during the reply sequence
    ld   a, [serial_system_status__RAM_D024_]
    bit  SYS_REPLY__BIT_BOOT_FAIL, a  ; 0, a
    jr   nz, set_send_if_sequence_no_match__32K_Bank_2_0BD2_  ; If there were any failures in the sequence, send
    ld   a, SYS_CMD_DONE_OR_OK  ; $01
    jr   send_response_to_sequence__32K_Bank2_0BD4_

    set_send_if_sequence_no_match__32K_Bank_2_0BD2_:
        ld   a, SYS_CMD_ABORT_OR_FAIL  ; $04  ; This gets sent if the startup sequence didn't match

    send_response_to_sequence__32K_Bank2_0BD4_:
    ld   [serial_tx_data__RAM_D023_], a
    BANK32K_ADDR  call, serial_io_send_byte__32K_Bank_2_0D28_ ; call $0D28
    ret


; Prepares to receive data through the serial (or special?) IO
;
; - Sets serial IO to external clock and enables ready state
; - Turns on Serial interrupt, clears pending interrupts, turns on interrupts
serial_io_enable_receive_byte__32K_Bank_2_0BDB_:
    push af
    ; Unclear what writing 0 to FF60 does. Sending and receiving over serial still works
    ; with the load instruction removed. In 32K Bank 0 it's only used for Serial RX and TX.
    ; Maybe it's used in other banks to change which peripheral is connected?
    ;
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
serial_int_disable__32K_Bank_2_0BEF_:
    push af
    ldh  a, [rIE]
    and  ~IEF_SERIAL ; $F7
    ldh  [rIE], a
    pop  af
    ret


; Sends a command and a trailing multi-byte buffer over Serial IO
;
; - Serial command to send before the buffer: serial_cmd_to_send__RAM_D035_
; - Send buffer: serial_buffer__RAM_D028_
; - Length:       serial_transfer_length__RAM_D034_
;
; Destroys A, BC, HL
serial_io_send_command_and_buffer__32K_Bank_2_0BF8_:
    ; Save interrupt enables and then set only Serial to ON
    ldh  a, [rIE]
    ld   [_rIE_saved_serial__RAM_D078_], a
    ld   a, IEF_SERIAL ; $08
    ldh  [rIE], a

    ; Check if Serial Transfer Length is ok
    ; Maybe there is a max send length of 12 bytes ( < 13 )
    ld   a, [serial_transfer_length__RAM_D034_]
    cp   SYS_CMD_SERIAL_SEND_BUF_MAX_LEN_PLUS_1 ; 13 ; $0D
    jr   c, .send_command_with_timeout__32K_Bank_2_0C0A_
    jr   .command_failed__32K_Bank2_0C1F_

    .send_command_with_timeout__32K_Bank_2_0C0A_:
        ld   a, [serial_cmd_to_send__RAM_D035_]
        ld   [serial_tx_data__RAM_D023_], a
        BANK32K_ADDR call, serial_io_send_byte__32K_Bank_2_0D28_ ; call $0D28
        BANK32K_ADDR call, delay_1_msec__32K_Bank_2_0D9A_
        BANK32K_ADDR call, delay_1_msec__32K_Bank_2_0D9A_
        BANK32K_ADDR call, serial_io_wait_receive_timeout_200msec__32K_Bank_2_0D62_
        ; If reply arrived then process it, otherwise
        ; it timed out, so fall through to failure handler
        and  a
        jr   nz, .handle_reply__32K_Bank_2_0C27_

    .command_failed__32K_Bank2_0C1F_:
        ld   a, SYS_CHAR_SERIAL_TX_FAIL  ; $FD
        ld   [input_key_pressed__RAM_D025_], a
        BANK32K_ADDR  jp, .done__32K_Bank_2_0CAD_

    .handle_reply__32K_Bank_2_0C27_:
        ; Check reply byte
        ld   a, [serial_rx_data__RAM_D021_]
        cp   SYS_REPLY_SEND_BUFFER_MAYBE_ERROR  ; $06 ; TODO: Does this signify "Not Ready" or some other unwanted status?
        BANK32K_ADDR  jp, z, .done_unsure_good_or_bad_reply_0xFB__32K_Bank_2_0CA8_
        cp   SYS_REPLY_SEND_BUFFER_OK  ; $03            ; Ready for Payload
        BANK32K_ADDR  jp, nz, .command_failed__32K_Bank2_0C1F_

        ; OK to send buffer over Serial IO
        ; Set Length to (Buffer Size + 2) and send that
        ; Initialize checksum to length (Buffer Size + 2)
        ;
        ; The +2 sizing seems to be for:
        ; - Initial Length Byte
        ; - Trailing Checksum Byte
        ld   a, [serial_transfer_length__RAM_D034_]
        ld   b, a
        add  $02
        ld   [serial_tx_data__RAM_D023_], a
        ld   [serial_io_checksum_calc__RAM_D026_], a
        BANK32K_ADDR call, delay_1_msec__32K_Bank_2_0D9A_
        BANK32K_ADDR call, serial_io_send_byte__32K_Bank_2_0D28_ ; call $0D28
        BANK32K_ADDR call, delay_1_msec__32K_Bank_2_0D9A_
        BANK32K_ADDR call, delay_1_msec__32K_Bank_2_0D9A_

        ; Send the contents of RAM Buffer
        ; Number of bytes to send in: B
        ld   hl, serial_buffer__RAM_D028_
        .serial_send_buffer_loop__32K_Bank_2_0C4F_:
            ; Prep next data to send, update checksum
            ; then wait for reply from previous send with timeout
            ldi  a, [hl]
            ld   [serial_tx_data__RAM_D023_], a
            ld   c, a
            ld   a, [serial_io_checksum_calc__RAM_D026_]
            add  c
            ld   [serial_io_checksum_calc__RAM_D026_], a
            BANK32K_ADDR call, serial_io_wait_receive_timeout_200msec__32K_Bank_2_0D62_

            ; Fail if timed out
            and  a
            jr   z, .command_failed__32K_Bank2_0C1F_
            ; Check reply byte
            ld   a, [serial_rx_data__RAM_D021_]
            cp   SYS_REPLY_SEND_BUFFER_MAYBE_ERROR  ; $06 ; TODO: Does this signify "Not Ready" or some other unwanted status?
            BANK32K_ADDR  jp, z, .done_unsure_good_or_bad_reply_0xFB__32K_Bank_2_0CA8_
            cp   SYS_REPLY_SEND_BUFFER_OK  ; $03            ; Ready for Payload
            BANK32K_ADDR  jp, nz, .command_failed__32K_Bank2_0C1F_

            ; Send next buffer byte
            BANK32K_ADDR  call, serial_io_send_byte__32K_Bank_2_0D28_ ; call $0D28
            dec  b
            jr   nz, .serial_send_buffer_loop__32K_Bank_2_0C4F_

        ; Done sending buffer bytes, wait for reply to last byte sent
        ; It should be the checksum byte
        BANK32K_ADDR call, serial_io_wait_receive_timeout_200msec__32K_Bank_2_0D62_
        ; Fail if timed out
        and  a
        jr   z, .command_failed__32K_Bank2_0C1F_
        ld   a, [serial_rx_data__RAM_D021_]
         ; Check reply byte
        cp   SYS_REPLY_SEND_BUFFER_MAYBE_ERROR  ; $06 ; TODO: Does this signify "Not Ready" or some other unwanted status?
        BANK32K_ADDR  jp, z, .done_unsure_good_or_bad_reply_0xFB__32K_Bank_2_0CA8_
        cp   SYS_REPLY_SEND_BUFFER_OK  ; $03            ; Ready for Payload
        BANK32K_ADDR  jp, nz, .command_failed__32K_Bank2_0C1F_

        ; Send trailing Checksum Byte
        ;
        ; Apply two's complement to finish calc of checksum data (sum of all bytes sent)
        ; Then send it and wait for reply byte
        ld   hl, serial_io_checksum_calc__RAM_D026_
        xor  a
        sub  [hl]
        ld   [serial_tx_data__RAM_D023_], a
        BANK32K_ADDR  call, serial_io_send_byte__32K_Bank_2_0D28_ ; call $0D28
        BANK32K_ADDR call, serial_io_wait_receive_timeout_200msec__32K_Bank_2_0D62_

        ; Fail if timed out
        and  a
        BANK32K_ADDR  jp, z, .command_failed__32K_Bank2_0C1F_
        ; Check reply byte
        ; If it was 0x01 then the transfer command succeeded
        ld   a, [serial_rx_data__RAM_D021_]
        cp   SYS_REPLY_BUFFER_SEND_AND_CHECKSUM_OK  ; $01
        BANK32K_ADDR  jp, nz, .command_failed__32K_Bank2_0C1F_

        BANK32K_ADDR call, serial_io_wait_receive_timeout_200msec__32K_Bank_2_0D62_
        ld   a, SYS_CHAR_SERIAL_TX_SUCCESS  ; $FC
        jr   .done_save_result__32K_Bank_2_0CAA_

    .done_unsure_good_or_bad_reply_0xFB__32K_Bank_2_0CA8_:
        ld   a, $FB
    .done_save_result__32K_Bank_2_0CAA_:
        ld   [input_key_pressed__RAM_D025_], a
    .done__32K_Bank_2_0CAD_:
        ; Restore previous interrupt enable state
        ld   a, [_rIE_saved_serial__RAM_D078_]
        ldh  [rIE], a
        ret


; Sends a command and then receives a multi-byte buffer over Serial IO
;
; - Serial command to send before the buffer: serial_rx_cmd_to_send__RAM_D036_
; - Receive buffer: serial_buffer__RAM_D028_
; - Length of serial transfer: Determined by sender
;
; Destroys A, BC, D, HL
serial_io_send_command_and_receive_buffer__32K_Bank_2_0CB3_:
    ; Save interrupt enables and then set only Serial to ON
    ldh  a, [rIE]
    ld   [_rIE_saved_serial__RAM_D078_], a
    ld   a, IEF_SERIAL ; $08
    ldh  [rIE], a

    ; TODO: What does D get used for here... if anything?
    ; Send initial Command from serial_rx_cmd_to_send__RAM_D036_
    ld   d, $00
    BANK32K_ADDR  call, delay_1_msec__32K_Bank_2_0D9A_
    ld   a, [serial_rx_cmd_to_send__RAM_D036_]
    ld   [serial_tx_data__RAM_D023_], a
    BANK32K_ADDR  call, serial_io_send_byte__32K_Bank_2_0D28_ ; call $0D28
    BANK32K_ADDR  call, serial_io_wait_receive_timeout_200msec__32K_Bank_2_0D62_

    ; Fail if timed out
    and  a
    jr   z, .command_failed__32K_Bank_2_0CD7_
    ; First reply byte will be length of incoming bytes
    ; There might be a max reply length of 13 bytes ( < 14 )
    ld   a, [serial_rx_data__RAM_D021_]
    cp   $0E
    jr   c, .receive_start__32K_Bank_2_0CE0_
    ; If length isn't ok then fall through to failure handler

    .command_failed__32K_Bank_2_0CD7_:
        ld   a, SYS_CHAR_SERIAL_RX_FAIL  ; $FA
        ld   [input_key_pressed__RAM_D025_], a
        ld   a, SYS_CMD_ABORT_OR_FAIL  ; $04
        jr   .done__32K_Bank_2_0D1C_

    .receive_start__32K_Bank_2_0CE0_:
        ; Set checksum to first reply byte (Length)
        ;
        ; Reduce length by 2 (probably for below) then save it
        ; - Initial Length Byte (current one)
        ; - Trailing Checksum Byte
        ld   [serial_io_checksum_calc__RAM_D026_], a
        dec  a
        dec  a
        ld   [serial_transfer_length__RAM_D034_], a
        ld   b, a
        ld   hl, serial_buffer__RAM_D028_

        ; Number of bytes to receive in B
        .serial_receive_buffer_loop__32K_Bank_2_0CEC_:
            ; Wait for next byte
            push hl
            BANK32K_ADDR call, serial_io_wait_receive_with_timeout__32K_Bank_2_0D53_
            and  a
            pop  hl
            jr   z, .command_failed__32K_Bank_2_0CD7_

            ; Store received byte to buffer
            ; Add it to the checksum
            ld   a, [serial_rx_data__RAM_D021_]
            ldi  [hl], a
            ld   c, a
            ld   a, [serial_io_checksum_calc__RAM_D026_]
            add  c
            ld   [serial_io_checksum_calc__RAM_D026_], a

            dec  b
            jr   nz, .serial_receive_buffer_loop__32K_Bank_2_0CEC_

        ; Done receiving buffer bytes, wait for the last byte sent
        ; It should be the checksum byte
        BANK32K_ADDR call, serial_io_wait_receive_with_timeout__32K_Bank_2_0D53_
        ; Fail if timed out
        and  a
        jr   z, .command_failed__32K_Bank_2_0CD7_
        ; Why does it need the extra delay below before reading the RX Byte?
        ; It should already be loaded if the receive didn't time out
        ; Is this extra delay a typo?
        BANK32K_ADDR call, delay_1_msec__32K_Bank_2_0D9A_

        ; Verify received trailing received Checksum Byte
        ;
        ; Received Checksum Byte should == (((sum of all bytes) XOR 0xFF) + 1) [two's complement]
        ; so ((sum of received bytes) + checksum byte) should == -> unsigned 8 bit overflow -> 0x00
        ld   a, [serial_rx_data__RAM_D021_]
        ld   hl, serial_io_checksum_calc__RAM_D026_
        add  [hl]
        jr   nz, .command_failed__32K_Bank_2_0CD7_
        ld   a, SYS_CHAR_SERIAL_RX_SUCCESS  ; $F9
        ld   [input_key_pressed__RAM_D025_], a
        ld   a, SYS_CMD_DONE_OR_OK  ; $01

    .done__32K_Bank_2_0D1C_:
        ld   [serial_tx_data__RAM_D023_], a
        BANK32K_ADDR  call, serial_io_send_byte__32K_Bank_2_0D28_ ; call $0D28
        ld   a, [_rIE_saved_serial__RAM_D078_]
        ldh  [rIE], a
        ret


; Sends the byte in serial_tx_data__RAM_D023_ out through serial (or special?) IO
;
; - Called from "run cart from slot"
; - Possibly called from keyboard input polling
serial_io_send_byte__32K_Bank_2_0D28_:
    push af
    ; Unclear what writing 0 to FF60 does. Sending and receiving over serial still works
    ; with the load instruction removed. In 32K Bank 0 it's only used for Serial RX and TX.
    ; Maybe it's used in other banks to change which peripheral is connected?
    ;
    ; Start an outbound Serial transfer
    ; Load byte to send
    ; Wait ~1 msec, then clear pending interrupts
    ; Set ready to receive an inbound transfer
    xor  a
    ldh  [_PORT_60_], a
    IF DEF(FIX_SC_REG_FOR_IMPRECISE_SIO_EMULATION)
        ; Fix SC reg loading data BEFORE starting for emulators that aren't as precise
        ld   a, [serial_tx_data__RAM_D023_]
        ldh  [rSB], a

        ld   a, (SERIAL_XFER_ENABLE | SERIAL_CLOCK_INT) ; $81
        ldh  [rSC], a
    ELSE
        ; Transfer started before data is loaded into rSB
        ; Counter to recommended practice, but still works (and is expected to per Nitro2k feedback)
        ld   a, (SERIAL_XFER_ENABLE | SERIAL_CLOCK_INT) ; $81
        ldh  [rSC], a

        ld   a, [serial_tx_data__RAM_D023_]
        ldh  [rSB], a
    ENDC
    BANK32K_ADDR  call, delay_1_msec__32K_Bank_2_0D9A_

    xor  a
    ldh  [rIF], a
    ld   a, (SERIAL_XFER_ENABLE | SERIAL_CLOCK_EXT); $80
    ldh  [rSC], a
    pop  af
    ret


; Waits for and returns a byte from Serial IO with NO timeout
;
; - Returns received serial byte in: A
serial_io_read_byte_no_timeout__32K_Bank_2_0D41_:
    ld   a, SERIAL_STATUS_RESET ; $00
    ld   [serial_status__RAM_D022_], a
    BANK32K_ADDR  call, serial_io_enable_receive_byte__32K_Bank_2_0BDB_

    .loop_wait_reply__32K_Bank_2_0D49_:
        ld   a, [serial_status__RAM_D022_]
        and  a
        jr   z, .loop_wait_reply__32K_Bank_2_0D49_
        ld   a, [serial_rx_data__RAM_D021_]
        ret


; Waits for a byte from Serial IO with a timeout (100 msec)
;
; - Returns serial transfer success(0x01)/failure(0x00) in: A
serial_io_wait_receive_with_timeout__32K_Bank_2_0D53_:
    ld   a, SERIAL_STATUS_RESET ; $00
    ld   [serial_status__RAM_D022_], a
    BANK32K_ADDR  call, serial_io_enable_receive_byte__32K_Bank_2_0BDB_
    BANK32K_ADDR  call, serial_io_wait_for_transfer_w_timeout_100msec__32K_Bank_2_0D89_
    ld   a, [serial_status__RAM_D022_]
    ret


; Waits for a byte from Serial IO with a timeout (~206 msec)
;
; - Returns serial transfer success(0x01)/failure(0x00) in: A
serial_io_wait_receive_timeout_200msec__32K_Bank_2_0D62_:
    push bc
    ld   a, SERIAL_STATUS_RESET ; $00
    ld   [serial_status__RAM_D022_], a
    BANK32K_ADDR  call, serial_io_enable_receive_byte__32K_Bank_2_0BDB_

    ld   b, $02
    .loop_wait_reply__32K_Bank_2_0D6D_:
        BANK32K_ADDR call, serial_io_wait_for_transfer_w_timeout_100msec__32K_Bank_2_0D89_
        ld   a, [serial_status__RAM_D022_]
        and  a
        jr   nz, serial_done__32K_Bank_2_0D7C_
        dec  b
        jr   nz, .loop_wait_reply__32K_Bank_2_0D6D_

        ld   a, [serial_status__RAM_D022_]
    serial_done__32K_Bank_2_0D7C_:
        pop  bc
        ret


; Sets the serial system status to OK (making some assumptions right now)
serial_system_status_set_fail__32K_Bank_2_D7E_:
    push af
    ld   a, [serial_system_status__RAM_D024_]
    set  SYS_REPLY__BIT_BOOT_FAIL, a  ; 0, a
    ld   [serial_system_status__RAM_D024_], a
    pop  af
    ret

; Waits for a serial transfer to complete with a ~103 msec timeout
;
; - Timeout is about ~103 msec or ~6.14 frames
; - Delay approx: (1000 msec / 59.7275 GB FPS) * (431632 T-States delay / 70224 T-States per frame) = ~103 msec
; - Serial ISR populates status var if anything was received (serial_int_handler__00CE_)
;
serial_io_wait_for_transfer_w_timeout_100msec__32K_Bank_2_0D89_:
    push bc
    ld   b, $64
    .loop_wait_reply__32K_Bank_2_0D8C_:
        BANK32K_ADDR call, delay_1_msec__32K_Bank_2_0D9A_
        ld   a, [serial_status__RAM_D022_]
        and  a
        jr   nz, serial_done__32k_Bank_2_0D98_
        dec  b
        jr   nz, .loop_wait_reply__32K_Bank_2_0D8C_
    serial_done__32k_Bank_2_0D98_:
        pop  bc
        ret
