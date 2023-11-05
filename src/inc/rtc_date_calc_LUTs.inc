; TODO: Maybe not that hard to support years for a couple more decades > 2011

; Days Per Month
;
RTC_DAYS_PER_MONTH_LUT__5DA6_:
db   31,  28,  31,  30,  31,  30,  31,  31,  30,  31,  30,  31
;    J    F    M    A    M    J    J    A    S    O    N    D

; Days Per Month (Leap Year version)
;
; Applicable Leap Years in dates supported by Quique:
; 1992, 1996, 2000, 2004, 2008
RTC_DAYS_PER_MONTH_LEAP_YEARS_LUT__5DB2_:
db  31,  29,  31,  30,  31,  30,  31,  31,  30,  31,  30,  31
;    J    F    M    A    M    J    J    A    S    O    N    D

; Starting day of week for years 1992 - 2011
RTC_DOW_FIRST_DAY_OF_YEAR_LUT__5DB2_:
db _WEEK_WED  ; 1992
db _WEEK_FRI  ; 1993
db _WEEK_SAT  ; 1994
db _WEEK_SUN  ; 1995
db _WEEK_MON  ; 1996
db _WEEK_WED  ; 1997
db _WEEK_THU  ; 1998
db _WEEK_FRI  ; 1999
db _WEEK_SAT  ; 2000
db _WEEK_MON  ; 2001
db _WEEK_TUE  ; 2002
db _WEEK_WED  ; 2003
db _WEEK_THU  ; 2004
db _WEEK_SAT  ; 2005
db _WEEK_SUN  ; 2006
db _WEEK_MON  ; 2007
db _WEEK_TUE  ; 2008
db _WEEK_THU  ; 2009
db _WEEK_FRI  ; 2010
db _WEEK_SAT  ; 2011
