
DEF FONT_BASE  EQU $80  ; Font characters start at this Tile ID

MACRO FONT_OFFSET ; Char Constant Name, Char Value
    IF _NARG != 2
        FAIL "FONT_OFFSET accepts only 2 arguments (char constant name, char value)"
    ENDC
    DEF \1 EQU (\2 + FONT_BASE)
ENDM

DEF STR_TERMINATOR            EQU $00

DEF FONT_UPPER_TO_LOWER_ADD   EQU 32  ; $20
DEF FONT_LOWER_TO_UPPER_SUB   EQU 32  ; $20
DEF FONT_TILDE_UPPER_TO_LOWER_ADD   EQU 7  ; $07
DEF FONT_TILDE_LOWER_TO_UPPER_SUB   EQU 7  ; $07

; Indentation required for invoking macro
; Char nums with respect to the font when loaded starting at Tile ID 0x80
    FONT_OFFSET          FONT_UPARROW, 0 ; $80
    ; Upper case Letters
    FONT_OFFSET          FONT_A, 1  ; $81
    FONT_OFFSET          FONT_B, 2  ; $82
    FONT_OFFSET          FONT_C, 3  ; $83
    FONT_OFFSET          FONT_D, 4  ; $84
    FONT_OFFSET          FONT_E, 5  ; $85
    FONT_OFFSET          FONT_F, 6  ; $86
    FONT_OFFSET          FONT_G, 7  ; $87
    FONT_OFFSET          FONT_H, 8  ; $88
    FONT_OFFSET          FONT_I, 9  ; $89
    FONT_OFFSET          FONT_J, 10 ; $8A
    FONT_OFFSET          FONT_K, 11 ; $8B
    FONT_OFFSET          FONT_L, 12 ; $8C
    FONT_OFFSET          FONT_M, 13 ; $8D
    FONT_OFFSET          FONT_N, 14 ; $8E
    FONT_OFFSET          FONT_O, 15 ; $8F
    FONT_OFFSET          FONT_P, 16 ; $90
    FONT_OFFSET          FONT_Q, 17 ; $91
    FONT_OFFSET          FONT_R, 18 ; $92
    FONT_OFFSET          FONT_S, 19 ; $93
    FONT_OFFSET          FONT_T, 20 ; $94
    FONT_OFFSET          FONT_U, 21 ; $95
    FONT_OFFSET          FONT_V, 22 ; $96
    FONT_OFFSET          FONT_W, 23 ; $97
    FONT_OFFSET          FONT_X, 24 ; $98
    FONT_OFFSET          FONT_Y, 25 ; $99
    FONT_OFFSET          FONT_Z, 26 ; $9A
    ; Upper case maybe umlaut Letters
    FONT_OFFSET          FONT_A_UMLAUT, 27 ; $9B
    FONT_OFFSET          FONT_O_UMLAUT, 28 ; $9C
    FONT_OFFSET          FONT_U_UMLAUT, 29 ; $9D
DEF FONT_UPPERCASE_FIRST      EQU FONT_A
DEF FONT_UPPERCASE_LAST       EQU FONT_U_UMLAUT

    ; Punctuation
    FONT_OFFSET          FONT_COMMA,      30 ; $9E
    FONT_OFFSET          FONT_DOT,        31 ; $9F  ; Period?
    FONT_OFFSET          FONT_UNDERSCORE, 32 ; $A0
    ; Lower case Letters
    ; TODO: convert lower case to ...N_LOWER instead of actual case
    FONT_OFFSET          FONT_A_LOWER, 33 ; $A1 ; Upper case + 32 (0x20)
    FONT_OFFSET          FONT_B_LOWER, 34 ; $A2
    FONT_OFFSET          FONT_C_LOWER, 35 ; $A3
    FONT_OFFSET          FONT_D_LOWER, 36 ; $A4
    FONT_OFFSET          FONT_E_LOWER, 37 ; $A5
    FONT_OFFSET          FONT_F_LOWER, 38 ; $A6
    FONT_OFFSET          FONT_G_LOWER, 39 ; $A7
    FONT_OFFSET          FONT_H_LOWER, 40 ; $A8
    FONT_OFFSET          FONT_I_LOWER, 41 ; $A9
    FONT_OFFSET          FONT_J_LOWER, 42 ; $AA
    FONT_OFFSET          FONT_K_LOWER, 43 ; $AB
    FONT_OFFSET          FONT_L_LOWER, 44 ; $AC
    FONT_OFFSET          FONT_M_LOWER, 45 ; $AD
    FONT_OFFSET          FONT_N_LOWER, 46 ; $AE
    FONT_OFFSET          FONT_O_LOWER, 47 ; $AF
    FONT_OFFSET          FONT_P_LOWER, 48 ; $B0
    FONT_OFFSET          FONT_Q_LOWER, 49 ; $B1
    FONT_OFFSET          FONT_R_LOWER, 50 ; $B2
    FONT_OFFSET          FONT_S_LOWER, 51 ; $B3
    FONT_OFFSET          FONT_T_LOWER, 52 ; $B4
    FONT_OFFSET          FONT_U_LOWER, 53 ; $B5
    FONT_OFFSET          FONT_V_LOWER, 54 ; $B6
    FONT_OFFSET          FONT_W_LOWER, 55 ; $B7
    FONT_OFFSET          FONT_X_LOWER, 56 ; $B8
    FONT_OFFSET          FONT_Y_LOWER, 57 ; $B9
    FONT_OFFSET          FONT_Z_LOWER, 58 ; $BA
    ; Lower case maybe umlaut Letters
    FONT_OFFSET          FONT_A_UMLAUT_LOWER, 59 ; $BB
    FONT_OFFSET          FONT_O_UMLAUT_LOWER, 60 ; $BC
    FONT_OFFSET          FONT_U_UMLAUT_LOWER, 61 ; $BD
DEF FONT_LOWERCASE_FIRST      EQU FONT_A_LOWER
DEF FONT_LOWERCASE_LAST       EQU FONT_U_UMLAUT_LOWER
    ; Space / ?
    FONT_OFFSET          FONT_BLANKSPACE, 62 ; $BE
    FONT_OFFSET          FONT_QUESTIONMARK, 63 ; $BF
    ; Numbers (set 1)
    FONT_OFFSET          FONT_0, 64 ; $C0
    FONT_OFFSET          FONT_1, 65 ; $C1
    FONT_OFFSET          FONT_2, 66 ; $C2
    FONT_OFFSET          FONT_3, 67 ; $C3
    FONT_OFFSET          FONT_4, 68 ; $C4
    FONT_OFFSET          FONT_5, 69 ; $C5
    FONT_OFFSET          FONT_6, 70 ; $C6
    FONT_OFFSET          FONT_7, 71 ; $C7
    FONT_OFFSET          FONT_8, 72 ; $C8
    FONT_OFFSET          FONT_9, 73 ; $C9
DEF FONT_NUMBERS_FIRST        EQU FONT_0
DEF FONT_NUMBERS_LAST         EQU FONT_9
    ; Math symbols
    FONT_OFFSET          FONT_PLUS,  74 ; $CA
    FONT_OFFSET          FONT_MINUS, 75 ; $CB
    FONT_OFFSET          FONT_MULT9, 76 ; $CC
    FONT_OFFSET          FONT_DIV9,  77 ; $CD
    FONT_OFFSET          FONT_EQUALS,78 ; $CE
    FONT_OFFSET          FONT_SQRT9, 79 ; $CF
    ; Start of Spanish symbols
    FONT_OFFSET          FONT_QUESTIONMARK_FLIPPED,    80 ; $D0
    FONT_OFFSET          FONT_EXCLAMATIONMARK_FLIPPED, 81 ; $D1
    FONT_OFFSET          FONT_PAREN_LEFT,              82 ; $D2
    FONT_OFFSET          FONT_PAREN_RIGHT,             83 ; $D3
    FONT_OFFSET          FONT_NOTEQUAL,                84 ; $D4 (Maybe not equal? hard to read letter)
    ; Upper case Tilde Letters
    FONT_OFFSET          FONT_N_TILDE,                 85 ; $D5
    FONT_OFFSET          FONT_A_TILDE,                 86 ; $D6
    FONT_OFFSET          FONT_E_TILDE,                 87 ; $D7
    FONT_OFFSET          FONT_I_TILDE,                 88 ; $D8
    FONT_OFFSET          FONT_O_TILDE,                 89 ; $D9
    FONT_OFFSET          FONT_U_TILDE,                 90 ; $DA
DEF FONT_UPPER_TILDE_FIRST    EQU FONT_N_TILDE
DEF FONT_UPPER_TILDE_LAST     EQU FONT_U_TILDE
    ; Misc char
    FONT_OFFSET          FONT_JOT_UNDERBAR_MAYBE,      91 ; $DB
    ; Lower case Tilde Letters
    FONT_OFFSET          FONT_N_TILDE_LOWER,                 92 ; $DC
    FONT_OFFSET          FONT_A_TILDE_LOWER,                 93 ; $DD
    FONT_OFFSET          FONT_E_TILDE_LOWER,                 94 ; $DE
    FONT_OFFSET          FONT_I_TILDE_LOWER,                 95 ; $DF
    FONT_OFFSET          FONT_O_TILDE_LOWER,                 96 ; $E0
    FONT_OFFSET          FONT_U_TILDE_LOWER,                 97 ; $E1
DEF FONT_LOWER_TILDE_FIRST    EQU FONT_N_TILDE_LOWER
DEF FONT_LOWER_TILDE_LAST     EQU FONT_U_TILDE_LOWER
    ; Misc char
    FONT_OFFSET          FONT_DOT_BETWEEN_BARS_MAYBE,  98 ; $E2
    ; End of Spanish symbols

    ; Numbers (set 2, color inverted)
    FONT_OFFSET          FONT_0_INV, 99  ; $E3
    FONT_OFFSET          FONT_1_INV, 100 ; $E4
    FONT_OFFSET          FONT_2_INV, 101 ; $E5
    FONT_OFFSET          FONT_3_INV, 102 ; $E6
    FONT_OFFSET          FONT_4_INV, 103 ; $E7
    FONT_OFFSET          FONT_5_INV, 104 ; $E8
    FONT_OFFSET          FONT_6_INV, 105 ; $E9
    FONT_OFFSET          FONT_7_INV, 106 ; $EA
    FONT_OFFSET          FONT_8_INV, 107 ; $EB
    FONT_OFFSET          FONT_9_INV, 108 ; $EC
DEF FONT_NUMBERS_INV_FIRST        EQU FONT_0_INV
DEF FONT_NUMBERS_INV_LAST         EQU FONT_9_INV
    ; Finger Icon (4 tiles)
    FONT_OFFSET          FONT_FINGER_ICON0, 109 ; $ED
    FONT_OFFSET          FONT_FINGER_ICON1, 110 ; $EE
    FONT_OFFSET          FONT_FINGER_ICON2, 111 ; $EF
    FONT_OFFSET          FONT_FINGER_ICON3, 112 ; $F0
    ; Slash character
    FONT_OFFSET          FONT_SLASH,        113 ; $F1

    ; Textbox drawing (Top)
    FONT_OFFSET          FONT_TEXTBOX_TOP_LEFT, 114 ; $F2
    FONT_OFFSET          FONT_TEXTBOX_TOP_MID,  115 ; $F3
    FONT_OFFSET          FONT_TEXTBOX_TOP_RIGHT,116 ; $F4
    ; Textbox drawing (Middle)
    FONT_OFFSET          FONT_TEXTBOX_MID_LEFT, 117 ; $F5
    FONT_OFFSET          FONT_TEXTBOX_MID_MID,  118 ; $F6
    FONT_OFFSET          FONT_TEXTBOX_MID_RIGHT,119 ; $F7
    ; Textbox drawing (Bottom)
    FONT_OFFSET          FONT_TEXTBOX_BOT_LEFT, 120 ; $F8
    FONT_OFFSET          FONT_TEXTBOX_BOT_MID,  121 ; $F9
    FONT_OFFSET          FONT_TEXTBOX_BOT_RIGHT,122 ; $FA
DEF FONT_TEXTBOX_START        EQU FONT_TEXTBOX_TOP_LEFT

    FONT_OFFSET          FONT_DOWN_SOLID_BLACK, 123 ; $FB  ; Might be text cursor
    FONT_OFFSET          FONT_HASH,             124 ; $FC
    FONT_OFFSET          FONT_DOWN_ARROW,       125 ; $FD
    FONT_OFFSET          FONT_COLON,            126 ; $FE
