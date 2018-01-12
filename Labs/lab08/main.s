	.arch armv5te
	.fpu softvfp
	.eabi_attribute 20, 1
	.eabi_attribute 21, 1
	.eabi_attribute 23, 3
	.eabi_attribute 24, 1
	.eabi_attribute 25, 1
	.eabi_attribute 26, 1
	.eabi_attribute 30, 6
	.eabi_attribute 18, 4
	.file	"main.c"
	.text
	.align	2
	.global	_start
	.type	_start, %function
_start:
	@ args = 0, pretend = 0, frame = 72
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #72
	mov	r0, #15
	mov	r1, #15
	bl	set_speed_motors
	b	.L6
.L8:
	mov	r0, r0	@ nop
.L6:
	mov	r0, #15
	mov	r1, #0
	bl	set_speed_motor
	bl	delay
	mov	r0, #3
	bl	read_sonar
	mov	r3, r0
	strh	r3, [fp, #-8]	@ movhi
	mov	r0, #4
	bl	read_sonar
	mov	r3, r0
	strh	r3, [fp, #-6]	@ movhi
	ldrh	r2, [fp, #-8]
	ldr	r3, .L9
	cmp	r2, r3
	bls	.L2
	ldrh	r2, [fp, #-6]
	ldr	r3, .L9
	cmp	r2, r3
	bhi	.L8
.L2:
	mov	r0, #0
	mov	r1, #0
	bl	set_speed_motor
	mov	r3, #0
	strh	r3, [fp, #-6]	@ movhi
	b	.L4
.L5:
	bl	delay
	mov	r0, #3
	bl	read_sonar
	mov	r3, r0
	strh	r3, [fp, #-8]	@ movhi
	mov	r0, #4
	bl	read_sonar
	mov	r3, r0
	strh	r3, [fp, #-6]	@ movhi
.L4:
	ldrh	r2, [fp, #-8]
	ldr	r3, .L9
	cmp	r2, r3
	bls	.L5
	ldrh	r2, [fp, #-6]
	ldr	r3, .L9
	cmp	r2, r3
	bls	.L5
	b	.L6
.L10:
	.align	2
.L9:
	.word	1199
	.size	_start, .-_start
	.align	2
	.global	delay
	.type	delay, %function
delay:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #12
	mov	r3, #0
	str	r3, [fp, #-8]
	b	.L12
.L13:
	ldr	r3, [fp, #-8]
	add	r3, r3, #1
	str	r3, [fp, #-8]
.L12:
	ldr	r2, [fp, #-8]
	ldr	r3, .L15
	cmp	r2, r3
	ble	.L13
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
.L16:
	.align	2
.L15:
	.word	9999
	.size	delay, .-delay
	.ident	"GCC: (GNU) 4.4.3"
	.section	.note.GNU-stack,"",%progbits
