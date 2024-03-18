.global _readMasked

_readMasked:
    ; Turns out that I need to use either three registers for the loads or a single load
    ; to three vector registers because ld1 doesn't allow to have an offset, it only
    ; allows post-index (inc x0 by i.e. 16 after the instruction). Using post-index
    ; creates a dependency between the loads, reducing the throughput to one load per cycle.
    movi v0.2d, #0
    mov x4, 0
    add x3, x0, x4
.p2align 8
Lloop:
    ld1 {v0.2d, v1.2d, v2.2d}, [x3], 48  ; This increases x3 by 48. Creates a dependency with the next load, but since this saturates the three reading ports of a m1 chip, it doesn't impact it
    ld1 {v0.2d, v1.2d, v2.2d}, [x3]
    add x4, x4, 96
    and x4, x4, x2
    add x3, x0, x4
    subs x1, x1, 96
    b.gt Lloop
    ret