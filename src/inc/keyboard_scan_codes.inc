
; TODO: maybe add in shift-equivalent keys, maybe in similar approach to SameBoy Workboy style (but with bit 7 reset)
;
;     GB_WORKBOY_NONE = 0xFF,
;     GB_WORKBOY_REQUIRE_SHIFT = 0x40,
;     GB_WORKBOY_FORBID_SHIFT = 0x80,
;
;     GB_WORKBOY_1 = 17 | GB_WORKBOY_REQUIRE_SHIFT,
;     https://github.com/LIJI32/SameBoy/blob/aff42affc01a394937979b0758d86c6918f58d2b/Core/workboy.h#L44C1-L44C50

;
;
; RX Bytes for Keyboard Serial Reply
; - 1st:
;   -  Always 0x04 (? in disasm code it looks like and checks for 0x0E though ?)
; - 2nd:
;    - KEY REPEAT : |= 0x01  (so far looks like with no key value set in 3rd Byte)
;    - CAPS_LOCK: |= 0x02
;    - SHIFT: |= 0x04
;    - LEFT_PRINTSCREEN: |= 0x08
; - 3rd:
;    - Carries the keyboard key scan code
;    - ? Maybe 00 when no key pressed? (0x04, <modifiers>, 0x00, <calculated checksum>)
; - 4th:
;     - Two's complement checuksum byte
;     - It should be: #4 == (((#1 + #2 + #3) XOR 0xFF) + 1) [two's complement]
;     - I.E: (#4 + #1 + #2 + #3) == 0x100 -> unsigned overflow -> 0x00
;
;
; - Left /right shift are shared
;
; Keyboard serial reply scan codes have different ordering than SYS_CHAR_* codes
; - They go diagonal down from upper left for the first *4* rows
; - The bottom 4 rows (including piano keys) are more varied
;
; LEFT_PRINTSCREEN 00 + modifier 0x08 ??? RIght seems to have actual keycode



; Modifier Keys
;
; See input_key_modifier_flags__RAM_D027_
DEF SYS_KBD_FLAG_KEY_REPEAT             EQU $01
DEF SYS_KBD_FLAG_KEY_REPEAT_BIT         EQU 0
DEF SYS_KBD_FLAG_CAPSLOCK               EQU $02
DEF SYS_KBD_FLAG_CAPSLOCK_BIT           EQU 1
DEF SYS_KBD_FLAG_SHIFT                  EQU $04
DEF SYS_KBD_FLAG_SHIFT_BIT              EQU 2
; Right Print Screen seems to have actual scancode, vs Left being in a flag
DEF SYS_KBD_FLAG_PRINTSCREEN_LEFT       EQU $08
DEF SYS_KBD_FLAG_PRINTSCREEN_LEFT_BIT   EQU 3


; First 4 rows (top of keyboard)  ~ 0x80 - 0xB7
;
; - For each row, most chars are +4 vs char to immediate left
;
; Starting values
; - Row 1: 0x80
; - Row 2: 0x81
; - Row 3: 0x82
; - Row 4: 0x83

; Row 1
DEF SYS_KBD_CODE_F1                  EQU  $80
DEF SYS_KBD_CODE_F2                  EQU  $84
DEF SYS_KBD_CODE_F3                  EQU  $88
DEF SYS_KBD_CODE_F4                  EQU  $8C
DEF SYS_KBD_CODE_F5                  EQU  $90
DEF SYS_KBD_CODE_F6                  EQU  $94
DEF SYS_KBD_CODE_F7                  EQU  $98
DEF SYS_KBD_CODE_F8                  EQU  $9C
DEF SYS_KBD_CODE_F9                  EQU  $A0
DEF SYS_KBD_CODE_F10                 EQU  $A4
DEF SYS_KBD_CODE_F11                 EQU  $A8
DEF SYS_KBD_CODE_F12                 EQU  $AC
; GAP at 0xB0 maybe Blank spot where F13 would be
; GAP at 0xB4 maybe ON Key?

; Row 2
DEF SYS_KBD_CODE_SALIDA              EQU  $81  ; Esc
DEF SYS_KBD_CODE_1                   EQU  $85
DEF SYS_KBD_CODE_2                   EQU  $89
DEF SYS_KBD_CODE_3                   EQU  $8D
DEF SYS_KBD_CODE_4                   EQU  $91
DEF SYS_KBD_CODE_5                   EQU  $95
DEF SYS_KBD_CODE_6                   EQU  $99
DEF SYS_KBD_CODE_7                   EQU  $9D
DEF SYS_KBD_CODE_8                   EQU  $A1
DEF SYS_KBD_CODE_9                   EQU  $A5
DEF SYS_KBD_CODE_0                   EQU  $A9
DEF SYS_KBD_CODE_COMMA_UPPER         EQU  $AD
DEF SYS_KBD_CODE_EXCLAMATION_FLIPPED EQU  $B1
DEF SYS_KBD_CODE_BACKSPACE           EQU  $B5
; See Continued Row 2 below

; Row 3
DEF SYS_KBD_CODE_AYUDA               EQU  $82  ; Help
DEF SYS_KBD_CODE_Q                   EQU  $86
DEF SYS_KBD_CODE_W                   EQU  $8A
DEF SYS_KBD_CODE_E                   EQU  $8E
DEF SYS_KBD_CODE_R                   EQU  $92
DEF SYS_KBD_CODE_T                   EQU  $96
DEF SYS_KBD_CODE_Y                   EQU  $9A
DEF SYS_KBD_CODE_U                   EQU  $9E
DEF SYS_KBD_CODE_I                   EQU  $A2
DEF SYS_KBD_CODE_O                   EQU  $A6
DEF SYS_KBD_CODE_P                   EQU  $AA
DEF SYS_KBD_CODE_BACKTICK            EQU  $AE  ; seems to only trigger if shift is pressed, generating a "["
DEF SYS_KBD_CODE_RIGHT_SQ_BRACKET    EQU  $B2
DEF SYS_KBD_CODE_ENTER               EQU  $B6
; See Continued Row 3 below

; Row 4
; GAP at 0x83 maybe CAPS LOCK
DEF SYS_KBD_CODE_A                   EQU  $87
DEF SYS_KBD_CODE_S                   EQU  $8B
DEF SYS_KBD_CODE_D                   EQU  $8F
DEF SYS_KBD_CODE_F                   EQU  $93
DEF SYS_KBD_CODE_G                   EQU  $97
DEF SYS_KBD_CODE_H                   EQU  $9B
DEF SYS_KBD_CODE_J                   EQU  $9F
DEF SYS_KBD_CODE_K                   EQU  $A3
DEF SYS_KBD_CODE_L                   EQU  $A7
DEF SYS_KBD_CODE_N_TILDE             EQU  $AB
DEF SYS_KBD_CODE_U_UMLAUT            EQU  $AF
DEF SYS_KBD_CODE_O_OVER_LINE         EQU  $B3
; ? GAP at 0x87 ?


; Second 4 rows (bottom of keyboard) ~ 0x80 - 0xB7
;
; - For each row, most chars are +4 vs char to immediate left
;
; Starting values
; - Row 5: 0xB8
; - Row 6: 0xB9
; - Row 7: 0xBA
; - Row 8: 0xBB

; Row 5
DEF SYS_KBD_CODE_Z                   EQU  $B8
DEF SYS_KBD_CODE_X                   EQU  $BC
DEF SYS_KBD_CODE_C                   EQU  $C0
DEF SYS_KBD_CODE_V                   EQU  $C4
DEF SYS_KBD_CODE_B                   EQU  $C8
DEF SYS_KBD_CODE_N                   EQU  $CC
DEF SYS_KBD_CODE_M                   EQU  $D0
DEF SYS_KBD_CODE_COMMA_LOWER         EQU  $D4
DEF SYS_KBD_CODE_PERIOD              EQU  $D8
DEF SYS_KBD_CODE_DASH_OR_UNDERSCORE  EQU  $DC
; See Continued Row 5 below
; Row 6 Continued (from below)
DEF SYS_KBD_CODE_BORRAR              EQU  $E0  ; *


; Encoding is less orderly below


; Row 6
DEF SYS_KBD_CODE_SPACE               EQU  $B9
; Continued Row 5
DEF SYS_KBD_CODE_LESS_THAN           EQU  $BD
; Continued Row 6
DEF SYS_KBD_CODE_PAGE_UP             EQU  $C1
DEF SYS_KBD_CODE_PAGE_DOWN           EQU  $C5
DEF SYS_KBD_CODE_MEMORY_MINUS        EQU  $C9
; Continued Row 5
DEF SYS_KBD_CODE_MEMORY_PLUS         EQU  $CD
DEF SYS_KBD_CODE_MEMORY_RECALL       EQU  $D1
DEF SYS_KBD_CODE_SQUAREROOT          EQU  $D5
; ** 3x3 Arrow and Math Key area **
; Continued Row 6
DEF SYS_KBD_CODE_MULTIPLY            EQU  $D9
DEF SYS_KBD_CODE_ARROW_DOWN          EQU  $DD
DEF SYS_KBD_CODE_MINUS               EQU  $E1
; Continued Row 3
DEF SYS_KBD_CODE_ARROW_LEFT          EQU  $E5
DEF SYS_KBD_CODE_EQUALS              EQU  $E9
DEF SYS_KBD_CODE_ARROW_RIGHT         EQU  $ED
; Continued Row 2
DEF SYS_KBD_CODE_DIVIDE              EQU  $E4
DEF SYS_KBD_CODE_ARROW_UP            EQU  $E8
DEF SYS_KBD_CODE_PLUS                EQU  $EC

; Row 7
; Piano Sharp Keys
DEF SYS_KBD_CODE_PIANO_DO_SHARP      EQU  $BA
DEF SYS_KBD_CODE_PIANO_RE_SHARP      EQU  $BE
; GAP at 0xC2 where there is no key
DEF SYS_KBD_CODE_PIANO_FA_SHARP      EQU  $C6
DEF SYS_KBD_CODE_PIANO_SOL_SHARP     EQU  $CA
DEF SYS_KBD_CODE_PIANO_LA_SHARP      EQU  $CE
; GAP at 0xD2 where there is no key
;
; Octave 2 maybe
DEF SYS_KBD_CODE_PIANO_DO_2_SHARP    EQU  $D6
DEF SYS_KBD_CODE_PIANO_RE_2_SHARP    EQU  $DA
; Row 6 Continued
DEF SYS_KBD_CODE_PRINTSCREEN_RIGHT   EQU  $DE  ; * Mixed in with piano keys
; Row 7 Continued
DEF SYS_KBD_CODE_PIANO_FA_2_SHARP    EQU  $E2
DEF SYS_KBD_CODE_PIANO_SOL_2_SHARP   EQU  $E6
DEF SYS_KBD_CODE_PIANO_LA_2_SHARP    EQU  $EA

; Row 8
; Piano Primary Keys
DEF SYS_KBD_CODE_PIANO_DO            EQU  $BB
DEF SYS_KBD_CODE_PIANO_RE            EQU  $BF
DEF SYS_KBD_CODE_PIANO_MI            EQU  $C3
DEF SYS_KBD_CODE_PIANO_FA            EQU  $C7
DEF SYS_KBD_CODE_PIANO_SOL           EQU  $CB
DEF SYS_KBD_CODE_PIANO_LA            EQU  $CF
DEF SYS_KBD_CODE_PIANO_SI            EQU  $D3
DEF SYS_KBD_CODE_PIANO_DO_2          EQU  $D7
DEF SYS_KBD_CODE_PIANO_RE_2          EQU  $DB
DEF SYS_KBD_CODE_PIANO_MI_2          EQU  $EF
DEF SYS_KBD_CODE_PIANO_FA_2          EQU  $E3
DEF SYS_KBD_CODE_PIANO_SOL_2         EQU  $E7
DEF SYS_KBD_CODE_PIANO_LA_2          EQU  $EB
DEF SYS_KBD_CODE_PIANO_SI_2          EQU  $EF


