.global _RATAdd
.global _RATMovAdd
.global _RATHomework
.global _RATMovAddUnrolled
.global _RATMovAddUnrolled6

.text

_RATAdd:
    mov x0, 0
; 1_000_000_000 in hex is 0x3b9aca00
; So we need to mov to load the number 0xca00
; And then to load 0x3b9a shifted 16 with keep
    mov x1, 0xca00
    movk x1, 0x3b9a, lsl 16
Lloop0:
.align 8
    add x0, x0, 1
    add x0, x0, 1
    sub x1, x1, 1
    cbnz x1, Lloop0
    ret

_RATMovAdd:
    mov x0, 0
; 1_000_000_000 in hex is 0x3b9aca00
; So we need to mov to load the number 0xca00
; And then to load 0x3b9a shifted 16 with keep
    mov x1, 0xca00
    movk x1, 0x3b9a, lsl 16
.align 8
Lloop1:
    mov x0, x1
    add x0, x0, 1
    mov x0, x1
    add x0, x0, 1
    sub x1, x1, 1
    cbnz x1, Lloop1
    ret

.p2align 8
_RATMovAddUnrolled:
    mov x0, 0
; 500_000_000 in hex is 0x1dcd6500
; So we need to mov to load the number 0x6500
; And then to load 0x1dcd shifted 16 with keep
    mov x1, 0x6500
    movk x1, 0x1dcd, lsl 16
LloopU:
    add x0, x1, 1
    add x0, x1, 1
    add x0, x1, 1
    add x0, x1, 1
    sub x1, x1, 1
    cbnz x1, LloopU
    ret

.p2align 8
_RATMovAddUnrolled6:
    mov x0, 0
; 1000_000_000 / 3 is 333_333_333 in hex is 0x13DE4355
; So we need to mov to load the number 0x4355
; And then to load 0x13DE shifted 16 with keep
    mov x1, 0x4355
    movk x1, 0x13DE, lsl 16
Lloop6:
    add x0, x1, 1
    add x0, x1, 1
    add x0, x1, 1
    add x0, x1, 1
    add x0, x1, 1
    add x0, x1, 1
    sub x1, x1, 1
    cbnz x1, Lloop6
    ret


_RATHomework:
; 1_000_000_000 in hex is 0x3b9aca00
; So we need to mov to load the number 0xca00
; And then to load 0x3b9a shifted 16 with keep
    mov x0, 0xca00
    movk x0, 0x3b9a, lsl 16
Lloop2:
.align 8
    mov x1, 1
    mov x2, 2
    mov x3, 3
    mov x4, 4
    add x1, x1, x2
    add x3, x3, x4
    add x1, x1, x3
    add x3, x3, x2
    add x1, x1, 1
    sub x3, x3, 1
    sub x1, x1, x2
    sub x3, x3, x4
    sub x1, x1, x3
    
    sub x0, x0, 1
    cbnz x0, Lloop2
    ret

;  NOTE(casey): CHALLENGE MODE WITH ULTIMATE DIFFICULTY SETTINGS
;               DO NOT ATTEMPT THIS! IT IS MUCH TOO HARD FOR
;               A HOMEWORK ASSIGNMENT!1!11!!
;
;top:
;    pop rcx
;    sub rsp, rdx
;    mov rbx, rax
;    shl rbx, 0
;    not rbx
;    loopne top
