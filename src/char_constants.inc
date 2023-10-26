DEF CHAR_BASE                     EQU $80  ; Font characters start at this Tile ID
MACRO CHAR_WITH_OFFSET ; Char Constant Name, Char Value
    IF _NARG != 2
        FAIL "ADD_CHAR_OFFSET accepts only 2 arguments (char constant name, char value)"
    ENDC
    DEF \1 EQU (\2 + CHAR_BASE)
ENDM

; TODO: Probably rename "CHAR_" to "FONT_" to differentiate from likely Keyboard Scan Codes

; Indentation required for invoking macro
DEF STR_TERMINATOR            EQU $00

DEF CHAR_UPPER_TO_LOWER_ADD   EQU 32  ; $20
DEF CHAR_LOWER_TO_UPPER_SUB   EQU 32  ; $20
DEF CHAR_TILDE_UPPER_TO_LOWER_ADD   EQU 7  ; $07
DEF CHAR_TILDE_LOWER_TO_UPPER_SUB   EQU 7  ; $07

; Char nums with respect to the font when loaded starting at Tile ID 0x80
    CHAR_WITH_OFFSET          CHAR_UPARROW, 0 ; $80
    ; Upper case Letters
    CHAR_WITH_OFFSET          CHAR_A, 1  ; $81
    CHAR_WITH_OFFSET          CHAR_B, 2  ; $82
    CHAR_WITH_OFFSET          CHAR_C, 3  ; $83
    CHAR_WITH_OFFSET          CHAR_D, 4  ; $84
    CHAR_WITH_OFFSET          CHAR_E, 5  ; $85
    CHAR_WITH_OFFSET          CHAR_F, 6  ; $86
    CHAR_WITH_OFFSET          CHAR_G, 7  ; $87
    CHAR_WITH_OFFSET          CHAR_H, 8  ; $88
    CHAR_WITH_OFFSET          CHAR_I, 9  ; $89
    CHAR_WITH_OFFSET          CHAR_J, 10 ; $8A
    CHAR_WITH_OFFSET          CHAR_K, 11 ; $8B
    CHAR_WITH_OFFSET          CHAR_L, 12 ; $8C
    CHAR_WITH_OFFSET          CHAR_M, 13 ; $8D
    CHAR_WITH_OFFSET          CHAR_N, 14 ; $8E
    CHAR_WITH_OFFSET          CHAR_O, 15 ; $8F
    CHAR_WITH_OFFSET          CHAR_P, 16 ; $90
    CHAR_WITH_OFFSET          CHAR_Q, 17 ; $91
    CHAR_WITH_OFFSET          CHAR_R, 18 ; $92
    CHAR_WITH_OFFSET          CHAR_S, 19 ; $93
    CHAR_WITH_OFFSET          CHAR_T, 20 ; $94
    CHAR_WITH_OFFSET          CHAR_U, 21 ; $95
    CHAR_WITH_OFFSET          CHAR_V, 22 ; $96
    CHAR_WITH_OFFSET          CHAR_W, 23 ; $97
    CHAR_WITH_OFFSET          CHAR_X, 24 ; $98
    CHAR_WITH_OFFSET          CHAR_Y, 25 ; $99
    CHAR_WITH_OFFSET          CHAR_Z, 26 ; $9A
    ; Upper case maybe umlaut Letters
    CHAR_WITH_OFFSET          CHAR_A_UMLAUT, 27 ; $9B
    CHAR_WITH_OFFSET          CHAR_O_UMLAUT, 28 ; $9C
    CHAR_WITH_OFFSET          CHAR_U_UMLAUT, 29 ; $9D
DEF CHAR_UPPERCASE_FIRST      EQU CHAR_A
DEF CHAR_UPPERCASE_LAST       EQU CHAR_U_UMLAUT

    ; Punctuation
    CHAR_WITH_OFFSET          CHAR_COMMA,      30 ; $9E
    CHAR_WITH_OFFSET          CHAR_DOT,        31 ; $9F  ; Period?
    CHAR_WITH_OFFSET          CHAR_UNDERSCORE, 32 ; $A0
    ; Lower case Letters
    CHAR_WITH_OFFSET          CHAR_a, 33 ; $A1 ; Upper case + 32 (0x20)
    CHAR_WITH_OFFSET          CHAR_b, 34 ; $A2
    CHAR_WITH_OFFSET          CHAR_c, 35 ; $A3
    CHAR_WITH_OFFSET          CHAR_d, 36 ; $A4
    CHAR_WITH_OFFSET          CHAR_e, 37 ; $A5
    CHAR_WITH_OFFSET          CHAR_f, 38 ; $A6
    CHAR_WITH_OFFSET          CHAR_g, 39 ; $A7
    CHAR_WITH_OFFSET          CHAR_h, 40 ; $A8
    CHAR_WITH_OFFSET          CHAR_i, 41 ; $A9
    CHAR_WITH_OFFSET          CHAR_j, 42 ; $AA
    CHAR_WITH_OFFSET          CHAR_k, 43 ; $AB
    CHAR_WITH_OFFSET          CHAR_l, 44 ; $AC
    CHAR_WITH_OFFSET          CHAR_m, 45 ; $AD
    CHAR_WITH_OFFSET          CHAR_n, 46 ; $AE
    CHAR_WITH_OFFSET          CHAR_o, 47 ; $AF
    CHAR_WITH_OFFSET          CHAR_p, 48 ; $B0
    CHAR_WITH_OFFSET          CHAR_q, 49 ; $B1
    CHAR_WITH_OFFSET          CHAR_r, 50 ; $B2
    CHAR_WITH_OFFSET          CHAR_s, 51 ; $B3
    CHAR_WITH_OFFSET          CHAR_t, 52 ; $B4
    CHAR_WITH_OFFSET          CHAR_u, 53 ; $B5
    CHAR_WITH_OFFSET          CHAR_v, 54 ; $B6
    CHAR_WITH_OFFSET          CHAR_w, 55 ; $B7
    CHAR_WITH_OFFSET          CHAR_x, 56 ; $B8
    CHAR_WITH_OFFSET          CHAR_y, 57 ; $B9
    CHAR_WITH_OFFSET          CHAR_z, 58 ; $BA
    ; Lower case maybe umlaut Letters
    CHAR_WITH_OFFSET          CHAR_a_UMLAUT, 59 ; $BB
    CHAR_WITH_OFFSET          CHAR_o_UMLAUT, 60 ; $BC
    CHAR_WITH_OFFSET          CHAR_u_UMLAUT, 61 ; $BD
DEF CHAR_LOWERCASE_FIRST      EQU CHAR_a
DEF CHAR_LOWERCASE_LAST       EQU CHAR_u_UMLAUT
    ; Space / ?
    CHAR_WITH_OFFSET          CHAR_BLANKSPACE, 62 ; $BE
    CHAR_WITH_OFFSET          CHAR_QUESTIONMARK, 63 ; $BF
    ; Numbers (set 1)
    CHAR_WITH_OFFSET          CHAR_0, 64 ; $C0
    CHAR_WITH_OFFSET          CHAR_1, 65 ; $C1
    CHAR_WITH_OFFSET          CHAR_2, 66 ; $C2
    CHAR_WITH_OFFSET          CHAR_3, 67 ; $C3
    CHAR_WITH_OFFSET          CHAR_4, 68 ; $C4
    CHAR_WITH_OFFSET          CHAR_5, 69 ; $C5
    CHAR_WITH_OFFSET          CHAR_6, 70 ; $C6
    CHAR_WITH_OFFSET          CHAR_7, 71 ; $C7
    CHAR_WITH_OFFSET          CHAR_8, 72 ; $C8
    CHAR_WITH_OFFSET          CHAR_9, 73 ; $C9
DEF CHAR_NUMBERS_FIRST        EQU CHAR_0
DEF CHAR_NUMBERS_LAST         EQU CHAR_9
    ; Math symbols
    CHAR_WITH_OFFSET          CHAR_PLUS,  74 ; $CA
    CHAR_WITH_OFFSET          CHAR_MINUS, 75 ; $CB
    CHAR_WITH_OFFSET          CHAR_MULT9, 76 ; $CC
    CHAR_WITH_OFFSET          CHAR_DIV9,  77 ; $CD
    CHAR_WITH_OFFSET          CHAR_EQUALS,78 ; $CE
    CHAR_WITH_OFFSET          CHAR_SQRT9, 79 ; $CF
    ; Start of Spanish symbols
    CHAR_WITH_OFFSET          CHAR_QUESTIONMARK_FLIPPED,    80 ; $D0
    CHAR_WITH_OFFSET          CHAR_EXCLAMATIONMARK_FLIPPED, 81 ; $D1
    CHAR_WITH_OFFSET          CHAR_PAREN_LEFT,              82 ; $D2
    CHAR_WITH_OFFSET          CHAR_PAREN_RIGHT,             83 ; $D3
    CHAR_WITH_OFFSET          CHAR_NOTEQUAL,                84 ; $D4 (Maybe not equal? hard to read letter)
    ; Upper case Tilde Letters
    CHAR_WITH_OFFSET          CHAR_N_TILDE,                 85 ; $D5
    CHAR_WITH_OFFSET          CHAR_A_TILDE,                 86 ; $D6
    CHAR_WITH_OFFSET          CHAR_E_TILDE,                 87 ; $D7
    CHAR_WITH_OFFSET          CHAR_I_TILDE,                 88 ; $D8
    CHAR_WITH_OFFSET          CHAR_O_TILDE,                 89 ; $D9
    CHAR_WITH_OFFSET          CHAR_U_TILDE,                 90 ; $DA
DEF CHAR_UPPER_TILDE_FIRST    EQU CHAR_N_TILDE
DEF CHAR_UPPER_TILDE_LAST     EQU CHAR_U_TILDE
    ; Misc char
    CHAR_WITH_OFFSET          CHAR_JOT_UNDERBAR_MAYBE,      91 ; $DB
    ; Lower case Tilde Letters
    CHAR_WITH_OFFSET          CHAR_n_TILDE,                 92 ; $DC
    CHAR_WITH_OFFSET          CHAR_a_TILDE,                 93 ; $DD
    CHAR_WITH_OFFSET          CHAR_e_TILDE,                 94 ; $DE
    CHAR_WITH_OFFSET          CHAR_i_TILDE,                 95 ; $DF
    CHAR_WITH_OFFSET          CHAR_o_TILDE,                 96 ; $E0
    CHAR_WITH_OFFSET          CHAR_u_TILDE,                 97 ; $E1
DEF CHAR_LOWER_TILDE_FIRST    EQU CHAR_n_TILDE
DEF CHAR_LOWER_TILDE_LAST     EQU CHAR_u_TILDE
    ; Misc char
    CHAR_WITH_OFFSET          CHAR_DOT_BETWEEN_BARS_MAYBE,  98 ; $E2
    ; End of Spanish symbols

    ; Numbers (set 2, color inverted)
    CHAR_WITH_OFFSET          CHAR_0_INV, 99  ; $E3
    CHAR_WITH_OFFSET          CHAR_1_INV, 100 ; $E4
    CHAR_WITH_OFFSET          CHAR_2_INV, 101 ; $E5
    CHAR_WITH_OFFSET          CHAR_3_INV, 102 ; $E6
    CHAR_WITH_OFFSET          CHAR_4_INV, 103 ; $E7
    CHAR_WITH_OFFSET          CHAR_5_INV, 104 ; $E8
    CHAR_WITH_OFFSET          CHAR_6_INV, 105 ; $E9
    CHAR_WITH_OFFSET          CHAR_7_INV, 106 ; $EA
    CHAR_WITH_OFFSET          CHAR_8_INV, 107 ; $EB
    CHAR_WITH_OFFSET          CHAR_9_INV, 108 ; $EC
DEF CHAR_NUMBERS_INV_FIRST        EQU CHAR_0_INV
DEF CHAR_NUMBERS_INV_LAST         EQU CHAR_9_INV
    ; Finger Icon (4 tiles)
    CHAR_WITH_OFFSET          CHAR_FINGER_ICON0, 109 ; $ED
    CHAR_WITH_OFFSET          CHAR_FINGER_ICON1, 110 ; $EE
    CHAR_WITH_OFFSET          CHAR_FINGER_ICON2, 111 ; $EF
    CHAR_WITH_OFFSET          CHAR_FINGER_ICON3, 112 ; $F0
    ; Slash character
    CHAR_WITH_OFFSET          CHAR_SLASH,        113 ; $F1
    ; Textbox drawing (Top)
    CHAR_WITH_OFFSET          CHAR_TEXTBOX_TOP_LEFT, 114 ; $F2
    CHAR_WITH_OFFSET          CHAR_TEXTBOX_TOP_MID,  115 ; $F3
    CHAR_WITH_OFFSET          CHAR_TEXTBOX_TOP_RIGHT,116 ; $F4
    ; Textbox drawing (Middle)
    CHAR_WITH_OFFSET          CHAR_TEXTBOX_MID_LEFT, 117 ; $F5
    CHAR_WITH_OFFSET          CHAR_TEXTBOX_MID_MID,  118 ; $F6
    CHAR_WITH_OFFSET          CHAR_TEXTBOX_MID_RIGHT,119 ; $F7
    ; Textbox drawing (Bottom)
    CHAR_WITH_OFFSET          CHAR_TEXTBOX_BOT_LEFT, 120 ; $F8
    CHAR_WITH_OFFSET          CHAR_TEXTBOX_BOT_MID,  121 ; $F9
    CHAR_WITH_OFFSET          CHAR_TEXTBOX_BOT_RIGHT,122 ; $FA
DEF CHAR_TEXTBOX_START        EQU CHAR_TEXTBOX_TOP_LEFT
    CHAR_WITH_OFFSET          CHAR_COLON, 126            ; $FE
