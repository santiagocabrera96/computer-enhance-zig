.global _readMasked

_readMasked:
    ; Turns out that I need to use either three registers for the loads or a single load
    ; to three vector registers because ld1 doesn't allow to have an offset, it only
    ; allows post-index (inc x0 by i.e. 16 after the instruction). Using post-index
    ; creates a dependency between the loads, reducing the throughput to one load per cycle.
    movi v0.2d, #0
.p2align 8
LOuter:
    mov x6, 0
    mov x7, x1
Lloop:
    add x5, x0, x6
    ld1 {v0.2d, v1.2d, v2.2d}, [x5], 48  ; This increases x3 by 48. Creates a dependency with the next load, but since this saturates the three reading ports of a m1 chip, it doesn't impact it
    ld1 {v0.2d, v1.2d, v2.2d}, [x5]
    add x6, x6, 96
    subs x7, x7, 1
    b.gt Lloop
    subs x2, x2, 1
    b.gt LOuter

    ret