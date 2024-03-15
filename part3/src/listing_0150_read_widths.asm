.global _read_4x3
.global _read_8x3
.global _read_16x3
.global _read_32x3

.text

.p2align 8
_read_4x3:
    ldr w2, [x0]
    ldr w2, [x0, 4]
    ldr w2, [x0, 8]
    subs x1, x1, 12
    b.gt _read_4x3
    ret

.p2align 8
_read_8x3:
    ldr x2, [x0]
    ldr x2, [x0, 8]
    ldr x2, [x0, 16]
    subs x1, x1, 24
    b.gt _read_8x3
    ret

_read_16x3:
    ; Turns out that I need to use either three registers for the loads or a single load
    ; to three vector registers because ld1 doesn't allow to have an offset, it only
    ; allows post-index (inc x0 by i.e. 16 after the instruction). Using post-index
    ; creates a dependency between the loads, reducing the throughput to one load per cycle.
    movi v0.2d, #0
.p2align 8
Lloop:
    ld1 {v0.2d, v1.2d, v2.2d}, [x0]
    subs x1, x1, 48
    b.gt Lloop
    ret

_read_32x3:
    movi v0.2d, #0
    movi v1.2d, #0
    add x2, x0, 48
.p2align 8
Lloop1:
    ld1 {v0.2d, v1.2d, v2.2d}, [x0]
    ld1 {v0.2d, v1.2d, v2.2d}, [x2]
    subs x1, x1, 96
    b.gt Lloop1
    ret
