.global _NOPAligned64
.global _NOPAligned1
.global _NOPAligned15
.global _NOPAligned31
.global _NOPAligned63
.global _NOPAligned127

.text

_NOPAligned64:
    mov	x8, #0
.align 8
Lloop1:
	cmp	x0, x8
	b.eq Lend1
	add	x8, x8, #1
	b	Lloop1
Lend1:
    ret

_NOPAligned1:
    mov	x8, #0

.align 8
NOP
Lloop2:
	cmp	x0, x8
	b.eq Lend2
	add	x8, x8, #1
	b	Lloop2
Lend2:
    ret

_NOPAligned15:
    mov	x8, #0
.align 8
.rept 15
NOP
.endr
Lloop3:
	cmp	x0, x8
	b.eq Lend3
	add	x8, x8, #1
	b	Lloop3
Lend3:
    ret


_NOPAligned31:
    mov	x8, #0
.align 8
.rept 31
NOP
.endr
Lloop4:
	cmp	x0, x8
	b.eq Lend4
	add	x8, x8, #1
	b	Lloop4
Lend4:
    ret

_NOPAligned63:
    mov	x8, #0
.align 8
.rept 63
NOP
.endr
Lloop5:
	cmp	x0, x8
	b.eq Lend5
	add	x8, x8, #1
	b	Lloop5
Lend5:
    ret

_NOPAligned127:
    mov	x8, #0
.align 8
.rept 127
NOP
.endr
Lloop6:
	cmp	x0, x8
	b.eq Lend6
	add	x8, x8, #1
	b	Lloop6
Lend6:
    ret

