.global _read_4X2
.global _read_8X2

.global _readX1
.global _readX2
.global _readX3
.global _readX4
.global _readX5
.global _storeX1
.global _storeX2
.global _storeX3
.global _storeX4
.global _storeX5


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


.p2align 8
_readX1:
    ; x0: Pointer to memory to read over and over
    ; x1: Number of iterations
    ldr x2, [x0]
    subs x1, x1, 1
    b.gt _readX1
    ret

.align 8
_readX2:
    ldr x2, [x0]
    ldr x2, [x0]
    subs x1, x1, 2
    b.gt _readX2
    ret

.align 8
_readX3:
    ldr x2, [x0]
    ldr x2, [x0]
    ldr x2, [x0]
    subs x1, x1, 3
    b.gt _readX3
    ret

.align 8
_readX4:
    ldr x2, [x0]
    ldr x2, [x0]
    ldr x2, [x0]
    ldr x2, [x0]
    subs x1, x1, 4
    b.gt _readX4
    ret

.align 8
_readX5:
    ldr x2, [x0]
    ldr x2, [x0]
    ldr x2, [x0]
    ldr x2, [x0]
    ldr x2, [x0]
    subs x1, x1, 5
    b.gt _readX5
    ret

.align 8
_storeX1:
    ; x0: Pointer to memory to write over and over
    ; x1: Number of iterations
    str x2, [x0]
    subs x1, x1, 1
    b.gt _storeX1
    ret

.align 8
_storeX2:
    str x2, [x0]
    str x2, [x0]
    subs x1, x1, 2
    b.gt _storeX2
    ret

.align 8
_storeX3:
    str x2, [x0]
    str x2, [x0]
    str x2, [x0]
    subs x1, x1, 3
    b.gt _storeX3
    ret

.align 8
_storeX4:
    str x2, [x0]
    str x2, [x0]
    str x2, [x0]
    str x2, [x0]
    subs x1, x1, 4
    b.gt _storeX4
    ret

.align 8
_storeX5:
    str x2, [x0]
    str x2, [x0]
    str x2, [x0]
    str x2, [x0]
    str x2, [x0]
    subs x1, x1, 5
    b.gt _storeX5
    ret
