
; SECTION "rom0_serial_io_9CF", ROM0[$09CF]

; ===== Serial IO peripheral interface functions =====



; Does a serial IO system startup init
; and sends count up sequence / then waits for and checks a count down sequence in reverse
;
; - Does this have anything to do with the "first time boot up" voice greeting?
;
; - Turns on Serial interrupt on/off at various times
serial_system_init_check__9CF_:
    ld   a, IEF_SERIAL ; $08
    ldh  [rIE], a
    xor  a
    ld   [serial_system_status__RAM_D024_], a  ; TODO: System startup status var? (success/failure?)
    xor  a
    ; Sending some kind of init(? TODO) count up sequence through the serial IO (0,1,2,3...255)
    ; Then wait for a response with no timeout
    .loop_send_sequence__9D8_:
        ld   [serial_tx_data__RAM_D023_], a
        call serial_io_send_byte__B64_
        inc  a
        jr   nz, .loop_send_sequence__9D8_
    call serial_io_read_byte_no_timeout__B7D_

    ; Handle reply
    cp   SYS_REPLY_BOOT_OK  ; $01
    ld   b, $00             ; This might not do anything... (not used and later overwritten)
    call nz, serial_system_status_set_fail__BBA_

    ; Send a "0" byte (SYS_CMD_INIT_SEQ_REQUEST)
    ; That maybe requests a 255..0 countdown sequence (be sent into the serial IO)
    xor  a
    ld   [serial_tx_data__RAM_D023_], a
    call serial_io_send_byte__B64_

    ; ? Expects a reply sequence through the serial IO of (255,254...0) ?
    ld   b, $01             ; This might not do anything, again... (not used and later overwritten)
    ld   c, $FF
    .loop_receive_sequence__9F6_:
        call serial_io_read_byte_no_timeout__B7D_
        cp   c
        call nz, serial_system_status_set_fail__BBA_  ; Set status failed if reply doesn't match expected  sequence value
        dec  c
        ld   a, c
        cp   $FF
        jr   nz, .loop_receive_sequence__9F6_

    ; Check for failures during the reply sequence
    ld   a, [serial_system_status__RAM_D024_]
    bit  SYS_REPLY__BIT_BOOT_FAIL, a  ; 0, a
    jr   nz, set_send_if_sequence_no_match__A0E_  ; If there were any failures in the sequence, send
    ld   a, SYS_CMD_DONE_OR_OK  ; $01
    jr   send_response_to_sequence__A10_

    set_send_if_sequence_no_match__A0E_:
        ld   a, SYS_CMD_ABORT_OR_FAIL  ; $04  ; This gets sent if the startup sequence didn't match

    send_response_to_sequence__A10_:
        ld   [serial_tx_data__RAM_D023_], a
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


; Sends a command and a trailing multi-byte buffer over Serial IO
;
; - Serial command to send before the buffer: serial_cmd_to_send__RAM_D035_
; - Send buffer: buffer__RAM_D028_
; - Length:       serial_transfer_length__RAM_D034_
;
; Destroys A, BC, HL
serial_io_send_command_and_buffer__A34_:
    ; Save interrupt enables and then set only Serial to ON
    ldh  a, [rIE]
    ld   [_rIE_saved_serial__RAM_D078_], a
    ld   a, IEF_SERIAL ; $08
    ldh  [rIE], a

    ; Check if Serial Transfer Length is ok
    ; Maybe there is a max send length of 12 bytes ( < 13 )
    ld   a, [serial_transfer_length__RAM_D034_]
    cp   $0D
    jr   c, .send_command_with_timeout__A46_
    jr   .command_failed___A5B_

    .send_command_with_timeout__A46_:
        ld   a, [serial_cmd_to_send__RAM_D035_]
        ld   [serial_tx_data__RAM_D023_], a
        call serial_io_send_byte__B64_
        call delay_quarter_msec__BD6_
        call delay_quarter_msec__BD6_
        call serial_io_wait_receive_w_timeout_50msec__B8F_
        ; If reply arrived then process it, otherwise
        ; it timed out, so fall through to failure handler
        and  a
        jr   nz, .handle_reply__A63_

    .command_failed___A5B_:
        ld   a, SYS_CHAR_SERIAL_TX_FAIL  ; $FD
        ld   [input_key_pressed__RAM_D025_], a
        jp   .done__AE9_

    .handle_reply__A63_:
        ; Check reply byte
        ld   a, [serial_rx_data__RAM_D021_]
        cp   $06                                          ; TODO: Does this signify "Not Ready" or some other unwanted status?
        jp   z, .done_unsure_good_or_bad_reply_0xFB__AE4_
        cp   $03                                          ; TODO: Apparently 0x03 is a failure status as well
        jp   nz, .command_failed___A5B_

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
        call delay_quarter_msec__BD6_
        call serial_io_send_byte__B64_
        call delay_quarter_msec__BD6_
        call delay_quarter_msec__BD6_

        ; Send the contents of RAM Buffer
        ; Number of bytes to send in: B
        ld   hl, buffer__RAM_D028_
        .serial_send_buffer_loop__A8B_:
            ; Prep next data to send, update checksum
            ; then wait for reply from previous send with timeout
            ldi  a, [hl]
            ld   [serial_tx_data__RAM_D023_], a
            ld   c, a
            ld   a, [serial_io_checksum_calc__RAM_D026_]
            add  c
            ld   [serial_io_checksum_calc__RAM_D026_], a
            call serial_io_wait_receive_w_timeout_50msec__B8F_

            ; Fail if timed out
            and  a
            jr   z, .command_failed___A5B_
            ; Check reply byte
            ld   a, [serial_rx_data__RAM_D021_]
            cp   $06                                          ; TODO: Does this signify "Not Ready" or some other unwanted status?
            jp   z, .done_unsure_good_or_bad_reply_0xFB__AE4_
            cp   $03                                          ; TODO: Apparently 0x03 is a failure status as well
            jp   nz, .command_failed___A5B_

            ; Send next buffer byte
            call serial_io_send_byte__B64_
            dec  b
            jr   nz, .serial_send_buffer_loop__A8B_

        ; Done sending buffer bytes, wait for reply to last byte sent
        ; It should be the checksum byte
        call serial_io_wait_receive_w_timeout_50msec__B8F_
        ; Fail if timed out
        and  a
        jr   z, .command_failed___A5B_
        ld   a, [serial_rx_data__RAM_D021_]
         ; Check reply byte
        cp   $06                                          ; TODO: Does this signify "Not Ready" or some other unwanted status?
        jp   z, .done_unsure_good_or_bad_reply_0xFB__AE4_
        cp   $03                                          ; TODO: Apparently 0x03 is a failure status as well
        jp   nz, .command_failed___A5B_

        ; Send trailing Checksum Byte
        ;
        ; Apply two's complement to finish calc of checksum data (sum of all bytes sent)
        ; Then send it and wait for reply byte
        ld   hl, serial_io_checksum_calc__RAM_D026_
        xor  a
        sub  [hl]
        ld   [serial_tx_data__RAM_D023_], a
        call serial_io_send_byte__B64_
        call serial_io_wait_receive_w_timeout_50msec__B8F_

        ; Fail if timed out
        and  a
        jp   z, .command_failed___A5B_
        ; Check reply byte
        ; If it was 0x01 then the transfer command succeeded
        ld   a, [serial_rx_data__RAM_D021_]
        cp   SYS_REPLY_MULTI_BYTE_SEND_AND_CHECKSUM_OK  ; $01
        jp   nz, .command_failed___A5B_

        call serial_io_wait_receive_w_timeout_50msec__B8F_
        ld   a, SYS_CHAR_SERIAL_TX_SUCCESS  ; $FC
        jr   .done_save_result__AE6_

    .done_unsure_good_or_bad_reply_0xFB__AE4_:
        ld   a, $FB
    .done_save_result__AE6_:
        ld   [input_key_pressed__RAM_D025_], a
    .done__AE9_:
        ; Restore previous interrupt enable state
        ld   a, [_rIE_saved_serial__RAM_D078_]
        ldh  [rIE], a
        ret


; Sends a command receives a multi-byte buffer over Serial IO
;
; - Serial command to send before the buffer: serial_rx_cmd_to_send__RAM_D036_
; - Receive buffer: buffer__RAM_D028_
; - Length of serial transfer: Determined by sender
;
; Destroys A, BC, D, HL
serial_io_send_command_and_receive_buffer__AEF_:
    ; Save interrupt enables and then set only Serial to ON
    ldh  a, [rIE]
    ld   [_rIE_saved_serial__RAM_D078_], a
    ld   a, IEF_SERIAL ; $08
    ldh  [rIE], a

    ; TODO: What does D get used for here... if anything?
    ; Send initial Command from serial_rx_cmd_to_send__RAM_D036_
    ld   d, $00
    call delay_quarter_msec__BD6_
    ld   a, [serial_rx_cmd_to_send__RAM_D036_]
    ld   [serial_tx_data__RAM_D023_], a
    call serial_io_send_byte__B64_
    call serial_io_wait_receive_w_timeout_50msec__B8F_

    ; Fail if timed out
    and  a
    jr   z, .command_failed__B13_
    ; First reply byte will be length of incoming bytes
    ; There might be a max reply length of 13 bytes ( < 14 )
    ld   a, [serial_rx_data__RAM_D021_]
    cp   $0E
    jr   c, .receive_start__B1C_
    ; If length isn't ok then fall through to failure handler

    .command_failed__B13_:
        ld   a, SYS_CHAR_SERIAL_RX_FAIL  ; $FA
        ld   [input_key_pressed__RAM_D025_], a
        ld   a, SYS_CMD_ABORT_OR_FAIL  ; $04
        jr   .done__B58_

    .receive_start__B1C_:
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
        ld   hl, buffer__RAM_D028_

        ; Number of bytes to receive in B
        .serial_receive_buffer_loop__B28_:
            ; Wait for next byte
            push hl
            call serial_io_wait_receive_with_timeout__B8F_
            and  a
            pop  hl
            jr   z, .command_failed__B13_

            ; Store received byte to buffer
            ; Add it to the checksum
            ld   a, [serial_rx_data__RAM_D021_]
            ldi  [hl], a
            ld   c, a
            ld   a, [serial_io_checksum_calc__RAM_D026_]
            add  c
            ld   [serial_io_checksum_calc__RAM_D026_], a

            dec  b
            jr   nz, .serial_receive_buffer_loop__B28_

        ; Done receiving buffer bytes, wait for the last byte sent
        ; It should be the checksum byte
        call serial_io_wait_receive_with_timeout__B8F_
        ; Fail if timed out
        and  a
        jr   z, .command_failed__B13_
        ; Why does it need the extra delay below before reading the RX Byte?
        ; It should already be loaded if the receive didn't time out
        ; Is this extra delay a typo?
        call delay_quarter_msec__BD6_

        ; Verify received trailing received Checksum Byte
        ;
        ; Received Checksum Byte should == (((sum of all bytes) XOR 0xFF) + 1) [two's complement]
        ; so ((sum of received bytes) + checksum byte) should == -> unsigned 8 bit overflow -> 0x00
        ld   a, [serial_rx_data__RAM_D021_]
        ld   hl, serial_io_checksum_calc__RAM_D026_
        add  [hl]
        jr   nz, .command_failed__B13_
        ld   a, SYS_CHAR_SERIAL_RX_SUCCESS  ; $F9
        ld   [input_key_pressed__RAM_D025_], a
        ld   a, SYS_CMD_DONE_OR_OK  ; $01

    .done__B58_:
        ld   [serial_tx_data__RAM_D023_], a
        call serial_io_send_byte__B64_
        ld   a, [_rIE_saved_serial__RAM_D078_]
        ldh  [rIE], a
        ret


; Sends the byte in serial_tx_data__RAM_D023_ out through serial (or special?) IO
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
    ; Why does this start the transfer before the data is loaded into rSB?
    ld   a, (SERIAL_XFER_ENABLE | SERIAL_CLOCK_INT) ; $81
    ldh  [rSC], a

    ld   a, [serial_tx_data__RAM_D023_]
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
    ld   [serial_status__RAM_D022_], a
    call serial_io_enable_receive_byte__A17_

    .loop_wait_reply__B85_:
        ld   a, [serial_status__RAM_D022_]
        and  a
        jr   z, .loop_wait_reply__B85_
        ld   a, [serial_rx_data__RAM_D021_]
        ret


; Waits for a byte from Serial IO with a timeout (25 msec)
;
; - Returns serial transfer success(0x01)/failure(0x00) in: A
serial_io_wait_receive_with_timeout__B8F_:
    ld   a, SERIAL_STATUS_RESET ; $00
    ld   [serial_status__RAM_D022_], a
    call serial_io_enable_receive_byte__A17_
    call serial_io_wait_for_transfer_w_timeout_25msec__BC5_
    ld   a, [serial_status__RAM_D022_]
    ret


; Waits for a byte from Serial IO with a timeout (~50 msec)
;
; - Returns serial transfer success(0x01)/failure(0x00) in: A
serial_io_wait_receive_w_timeout_50msec__B8F_:
    push bc
    ld   a, SERIAL_STATUS_RESET ; $00
    ld   [serial_status__RAM_D022_], a
    call serial_io_enable_receive_byte__A17_

    ld   b, $02
    .loop_wait_reply__BA9_:
        call serial_io_wait_for_transfer_w_timeout_25msec__BC5_
        ld   a, [serial_status__RAM_D022_]
        and  a
        jr   nz, serial_done__BB8_
        dec  b
        jr   nz, .loop_wait_reply__BA9_

        ld   a, [serial_status__RAM_D022_]
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
    .loop_wait_reply__BC8_:
        call delay_quarter_msec__BD6_
        ld   a, [serial_status__RAM_D022_]
        and  a
        jr   nz, serial_done__BD4_
        dec  b
        jr   nz, .loop_wait_reply__BC8_
    serial_done__BD4_:
        pop  bc
        ret