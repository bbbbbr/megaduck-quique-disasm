
; See related include files for
; SYS_CHAR and SYS_KBD_CODE constants

; This LUT maps Keyboard scan codes to system character values
;
; First value is DEF SYS_KBD_CODE_F1, which is $80
; That's the first valid key scan code


; The Rows Refer to the physical location on the keyboard
; starting with the top row and incrementing downward.
;
;  Row 1 (Top)              Row 2                         Row 3                      Row 4
;
; TODO: $3B Might be F12
; TODO: $2B is possibly some special key given it's system char number
db SYS_CHAR_F1,             SYS_CHAR_SALIDA,               SYS_CHAR_AYUDA,            SYS_CHAR_PRINTSCREEN
db SYS_CHAR_F2,             SYS_CHAR_1,                    SYS_CHAR_Q_LOWER,          SYS_CHAR_A_LOWER
db SYS_CHAR_F3,             SYS_CHAR_2,                    SYS_CHAR_W_LOWER,          SYS_CHAR_S_LOWER
db SYS_CHAR_F4,             SYS_CHAR_3,                    SYS_CHAR_E_LOWER,          SYS_CHAR_D_LOWER
db SYS_CHAR_F5,             SYS_CHAR_4,                    SYS_CHAR_R_LOWER,          SYS_CHAR_F_LOWER
db SYS_CHAR_F6,             SYS_CHAR_5,                    SYS_CHAR_T_LOWER,          SYS_CHAR_G_LOWER
db SYS_CHAR_F7,             SYS_CHAR_6,                    SYS_CHAR_Y_LOWER,          SYS_CHAR_H_LOWER
db SYS_CHAR_F8,             SYS_CHAR_7,                    SYS_CHAR_U_LOWER,          SYS_CHAR_J_LOWER
db SYS_CHAR_F9,             SYS_CHAR_8,                    SYS_CHAR_I_LOWER,          SYS_CHAR_K_LOWER
db SYS_CHAR_F10,            SYS_CHAR_9,                    SYS_CHAR_O_LOWER,          SYS_CHAR_L_LOWER
db SYS_CHAR_F11,            SYS_CHAR_0,                    SYS_CHAR_P_LOWER,          SYS_CHAR_N_TILDE_LOWER
db $3B,                     SYS_CHAR_SINGLE_QUOTE,         $2B,                       SYS_CHAR_U_UMLAUT_LOWER
db SYS_CHAR_NO_DATA_OR_KEY, SYS_CHAR_EXCLAMATION_FLIPPED, SYS_CHAR_RIGHT_SQ_BRACKET, SYS_CHAR_O_OVER_LINE
db SYS_CHAR_NO_DATA_OR_KEY, SYS_CHAR_BACKSPACE,            SYS_CHAR_ENTRA_CR,         SYS_CHAR_NO_DATA_OR_KEY


;  Row 5                    Row 6                          Row 7                     Row 8
;
; TODO: $3A maps to SYS_CHAR_F11
;       and $2F maps to SYS_CHAR_PRINTSCREEN
;       but in that location they're filling gaps in the keyboard scan code sequence
;       So it's hard to tell if they're meaningful or randomly assigned.
db SYS_CHAR_Z_LOWER,        SYS_CHAR_SPACE,                SYS_CHAR_PIANO_DO_SHARP,   SYS_CHAR_PIANO_DO
db SYS_CHAR_X_LOWER,        SYS_CHAR_LESS_THAN,            SYS_CHAR_PIANO_RE_SHARP,   SYS_CHAR_PIANO_RE
db SYS_CHAR_C_LOWER,        SYS_CHAR_PG_ARRIBA,            $3A,                       SYS_CHAR_PIANO_MI
db SYS_CHAR_V_LOWER,        SYS_CHAR_PG_ABAJO,             SYS_CHAR_PIANO_FA_SHARP,   SYS_CHAR_PIANO_FA
db SYS_CHAR_B_LOWER,        SYS_CHAR_MEMORY_MINUS,         SYS_CHAR_PIANO_SOL_SHARP,  SYS_CHAR_PIANO_SOL
db SYS_CHAR_N_LOWER,        SYS_CHAR_MEMORY_PLUS,          SYS_CHAR_PIANO_LA_SHARP,   SYS_CHAR_PIANO_LA
db SYS_CHAR_M_LOWER,        SYS_CHAR_MEMORY_RECALL,        $2F,                       SYS_CHAR_PIANO_SI
db SYS_CHAR_COMMA,          SYS_CHAR_SQRT,                 SYS_CHAR_PIANO_DO_2_SHARP, SYS_CHAR_PIANO_DO_2
db SYS_CHAR_PERIOD,         SYS_CHAR_MULTIPLY,             SYS_CHAR_PIANO_RE_2_SHARP, SYS_CHAR_PIANO_RE_2
db SYS_CHAR_MINUS,          SYS_CHAR_DOWN,                 $2F,                       SYS_CHAR_PIANO_MI_2
db SYS_CHAR_BORRAR,         SYS_CHAR_MINUS,                SYS_CHAR_PIANO_FA_2_SHARP, SYS_CHAR_PIANO_FA_2
db SYS_CHAR_DIVIDE,         SYS_CHAR_LEFT,                 SYS_CHAR_PIANO_SOL_2_SHARP,SYS_CHAR_PIANO_SOL_2
db SYS_CHAR_UP,             SYS_CHAR_EQUALS,               SYS_CHAR_PIANO_LA_2_SHARP, SYS_CHAR_PIANO_LA_2
db SYS_CHAR_PLUS,           SYS_CHAR_RIGHT,                $3A,                       SYS_CHAR_PIANO_SI_2

; Last value is SYS_KBD_CODE_PIANO_SI_2, which is $EF
; That's the last valid key scan code