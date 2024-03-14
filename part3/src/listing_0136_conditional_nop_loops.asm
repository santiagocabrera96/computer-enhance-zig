nop
.globl _conditionalNOP
_conditionalNOP:
    mov	x8, #0
Lloop1:
	cmp	x0, x8
	b.eq Lend1
    ldrb w2, [x1, x8]
    tbnz w2, 1, Lskip
	NOP
Lskip:
	add	x8, x8, #1
	b	Lloop1
Lend1:
	ret