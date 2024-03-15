.global _read_4X2
.global _read_8X2


.text

.p2align 8
_read_4X2:
    ; x0: Pointer to memory to read over and over
    ; x1: Number of iterations
    ldr w2, [x0]
    ldr w2, [x0]
    subs x1, x1, 2
    b.gt _read_4X2
    ret

.p2align 8
_read_8X2:
    ; x0: Pointer to memory to read over and over
    ; x1: Number of iterations
    ldr x2, [x0]
    ldr x2, [x0]
    subs x1, x1, 2
    b.gt _read_8X2
    ret

