; ARM A32 program for the supported project subset.
; R0-R14 and NZCV start at zero; RAM is written before every valid load.
; Labels and words below are already encoded in program.dat.

    ADD R1, R0, #0x19            ; PC=0x00, E2801019
    STR R1, [R0, #0]             ; PC=0x04, E5801000
    LDR R2, [R0, #0]             ; PC=0x08, E5902000
    ADD R3, R0, #0x5a            ; PC=0x0C, E280305A
    STR R3, [R0, #4]             ; PC=0x10, E5803004
    STR R3, [R0, #0]             ; PC=0x14, E5803000
    LDR R4, [R0, #0]             ; PC=0x18, E5904000
    ADD R5, R0, #0x7             ; PC=0x1C, E2805007
    STR R0, [R0, #4]             ; PC=0x20, E5800004
    LDR R5, [R0, #4]             ; PC=0x24, E5905004
    STR R1, [R0, #1020]          ; PC=0x28, E58013FC
    LDR R6, [R0, #1020]          ; PC=0x2C, E59063FC
    SUBS R7, R1, R1              ; PC=0x30, E0517001
    BEQ equal_ok                 ; PC=0x34, 0A000000
    STR R3, [R0, #8]             ; PC=0x38, E5803008
equal_ok:
    ADD R8, R0, #0x1             ; PC=0x3C, E2808001
    SUBS R7, R1, R3              ; PC=0x40, E0517003
    BEQ terminal                 ; PC=0x44, 0A000021
    ADD R8, R8, #0x2             ; PC=0x48, E2888002
    ADDNE R8, R8, #0x4           ; PC=0x4C, 12888004
    ADDEQ R8, R8, #0x80          ; PC=0x50, 02888080
    STREQ R3, [R0, #8]           ; PC=0x54, 05803008
    AND R9, R1, R3               ; PC=0x58, E0019003
    ORR R10, R1, R3              ; PC=0x5C, E181A003
    SUB R11, R0, #0x1            ; PC=0x60, E240B001
    ADDS R12, R11, #0x1          ; PC=0x64, E29BC001
    ADD R13, R0, #0x80000000     ; PC=0x68, E280D102
    SUBS R14, R13, #0x1          ; PC=0x6C, E25DE001
    ADDS R14, R14, #0x1          ; PC=0x70, E29EE001
    ANDS R9, R11, R0             ; PC=0x74, E01B9000
    ORRS R10, R0, R13            ; PC=0x78, E190A00D
    ORRS R10, R0, #0x80000000    ; PC=0x7C, E390A102
    ADD R1, R0, #0x2             ; PC=0x80, E2801002
loop:
    SUBS R1, R1, #0x1            ; PC=0x84, E2511001
    BEQ loop_done                ; PC=0x88, 0A000001
    B loop                       ; PC=0x8C, EAFFFFFC
    STR R3, [R0, #8]             ; PC=0x90, E5803008
loop_done:
    AND R9, R11, R11             ; PC=0x94, E00B900B
    ORR R10, R0, R0              ; PC=0x98, E180A000
    ADD R2, R15, #0x0            ; PC=0x9C, E28F2000
    ADD R3, R0, #0x100           ; PC=0xA0, E2803C01
    STR R3, [R0, #12]            ; PC=0xA4, E580300C
    LDR R4, [R0, #12]            ; PC=0xA8, E590400C
    ADD R6, R0, #0x1             ; PC=0xAC, E2806001
    STR R3, [R6, #0]             ; PC=0xB0, E5863000
    LDR R7, [R6, #0]             ; PC=0xB4, E5967000
    ADD R6, R0, #0x400           ; PC=0xB8, E2806B01
    STR R3, [R6, #0]             ; PC=0xBC, E5863000
    LDR R7, [R6, #0]             ; PC=0xC0, E5967000
    ADD R15, R15, #0x0           ; PC=0xC4, E28FF000
    STR R3, [R0, #8]             ; PC=0xC8, E5803008
    SUB R9, R0, #0x1             ; PC=0xCC, E2409001
terminal:
    B terminal                   ; PC=0xD0, EAFFFFFE
