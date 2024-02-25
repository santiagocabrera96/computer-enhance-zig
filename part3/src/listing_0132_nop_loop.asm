.globl	_MOVAllBytesAsm
_MOVAllBytesAsm:
	mov	x8, #0
Lloop:
	cmp	x0, x8
	b.eq Lend
	strb	w8, [x1, x8]
	add	x8, x8, #1
	b	Lloop
Lend:
	ret

.globl _NOPAllBytesAsm
_NOPAllBytesAsm:
    mov	x8, #0
Lloop1:
	cmp	x0, x8
	b.eq Lend1
	NOP
	add	x8, x8, #1
	b	Lloop1
Lend1:
	ret

.globl _CMPAllBytesAsm
_CMPAllBytesAsm:
    mov	x8, #0
Lloop2:
	cmp	x0, x8
	b.eq Lend2
	add	x8, x8, #1
	b	Lloop2
Lend2:
	ret

.globl _DECAllBytesAsm
_DECAllBytesAsm:
Lloop3:
	cmp	x0, 0
	b.eq Lend3
	sub x0, x0, #1
	b	Lloop3
Lend3:
	ret

listing_0132_end_of_symbols: