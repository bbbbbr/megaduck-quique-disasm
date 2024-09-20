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

IF (!(DEF(FIX_Y2K12_BUG)))
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
ELSE
    ; Need to relocate the LUT when expanded
    SECTION "rom0_rtc_first_day_of_year_relocated_lut", ROMX, BANK[$1]

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

    ; Extend it several more decades
    db _WEEK_SUN  ; 2012
    db _WEEK_TUE  ; 2013
    db _WEEK_WED  ; 2014
    db _WEEK_THU  ; 2015
    db _WEEK_FRI  ; 2016
    db _WEEK_SUN  ; 2017
    db _WEEK_MON  ; 2018
    db _WEEK_TUE  ; 2019
    db _WEEK_WED  ; 2020
    db _WEEK_FRI  ; 2021
    db _WEEK_SAT  ; 2022
    db _WEEK_SUN  ; 2023
    db _WEEK_MON  ; 2024
    db _WEEK_WED  ; 2025
    db _WEEK_THU  ; 2026
    db _WEEK_FRI  ; 2027
    db _WEEK_SAT  ; 2028
    db _WEEK_MON  ; 2029

    db _WEEK_TUE  ; 2030
    db _WEEK_WED  ; 2031
    db _WEEK_THU  ; 2032
    db _WEEK_SAT  ; 2033
    db _WEEK_SUN  ; 2034
    db _WEEK_MON  ; 2035
    db _WEEK_TUE  ; 2036
    db _WEEK_THU  ; 2037
    db _WEEK_FRI  ; 2038
    db _WEEK_SAT  ; 2039

    db _WEEK_SUN  ; 2040
    db _WEEK_TUE  ; 2041
    db _WEEK_WED  ; 2042
    db _WEEK_THU  ; 2043
    db _WEEK_FRI  ; 2044
    db _WEEK_SUN  ; 2045
    db _WEEK_MON  ; 2046
    db _WEEK_TUE  ; 2047
    db _WEEK_WED  ; 2048
    db _WEEK_FRI  ; 2049

    db _WEEK_SAT  ; 2050
    db _WEEK_SUN  ; 2051
    db _WEEK_MON  ; 2052
    db _WEEK_WED  ; 2053
    db _WEEK_THU  ; 2054
    db _WEEK_FRI  ; 2055
    db _WEEK_SAT  ; 2056
    db _WEEK_MON  ; 2057
    db _WEEK_TUE  ; 2058
    db _WEEK_WED  ; 2059

    db _WEEK_THU  ; 2060
    db _WEEK_SAT  ; 2061
    db _WEEK_SUN  ; 2062
    db _WEEK_MON  ; 2063
    db _WEEK_TUE  ; 2064
    db _WEEK_THU  ; 2065
    db _WEEK_FRI  ; 2066
    db _WEEK_SAT  ; 2067
    db _WEEK_SUN  ; 2068
    db _WEEK_TUE  ; 2069

    db _WEEK_WED  ; 2070
    db _WEEK_THU  ; 2071
    db _WEEK_FRI  ; 2072
    db _WEEK_SUN  ; 2073
    db _WEEK_MON  ; 2074
    db _WEEK_TUE  ; 2075
    db _WEEK_WED  ; 2076
    db _WEEK_FRI  ; 2077
    db _WEEK_SAT  ; 2078
    db _WEEK_SUN  ; 2079

    db _WEEK_MON  ; 2080
    db _WEEK_WED  ; 2081
    db _WEEK_THU  ; 2082
    db _WEEK_FRI  ; 2083
    db _WEEK_SAT  ; 2084
    db _WEEK_MON  ; 2085
    db _WEEK_TUE  ; 2086
    db _WEEK_WED  ; 2087
    db _WEEK_THU  ; 2088
    db _WEEK_SAT  ; 2089

    db _WEEK_SUN  ; 2090
    db _WEEK_MON  ; 2091
    db _WEEK_TUE  ; 2092
    RTC_DOW_FIRST_DAY_OF_YEAR_LUT__END_:
ENDC
