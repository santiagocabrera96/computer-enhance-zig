nop
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

.globl _NOP3AllBytesAsm
_NOP3AllBytesAsm:
    mov	x8, #0
Lloop2:
	cmp	x0, x8
	b.eq Lend2
    NOP
    NOP
    NOP
	add	x8, x8, #1
	b	Lloop2
Lend2:
	ret

.globl _NOP9AllBytesAsm
_NOP9AllBytesAsm:
    mov	x8, #0
Lloop3:
	cmp	x0, x8
	b.eq Lend3
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
	add	x8, x8, #1
	b	Lloop3
Lend3:
	ret

.globl _NOP12AllBytesAsm
_NOP12AllBytesAsm:
    mov	x8, #0
Lloop4:
	cmp	x0, x8
	b.eq Lend4
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
	add	x8, x8, #1
	b	Lloop4
Lend4:
	ret

listing_0134_end_of_symbols: