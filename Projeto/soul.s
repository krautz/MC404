.org 0x0
.section .iv,"a"

_start:		

interrupt_vector:

    b RESET_TIMER
.org 0x8
    b sys_call
.org 0x18
    b IRQ_HANDLER

.org 0x100
.text

@@@@@@@@@@@@@@@@@@@@
@ Start up process @
@@@@@@@@@@@@@@@@@@@@
@@
@ Enables GPT timing control
@ If the clock gets to TIME_SZ it will do an interruption
@ The interruption will increase 1 to the system timer SYSTIME
@@
RESET_TIMER:
    @Set interrupt table base address on coprocessor 15.
    ldr r0, =interrupt_vector
    mcr p15, 0, r0, c12, c0, 0
    
    @ GPT constants
    .set GPT_BASE,      0x53FA0000
    .set GPT_CR,        0x0
    .set GPT_PR,        0x4
    .set GPT_SR,        0x8
    .set GPT_IR,        0xC
    .set GPT_OCR1,      0x10
    .set GPT_OCR2,      0x14
    .set GPT_OCR3,      0x18
    .set GPT_ICR1,      0x1C
    .set GPT_ICR2,      0x20
    .set GPT_CNT,       0x24

    @ Control Register activated with clck_src set as peripherical
    ldr r1, =GPT_BASE   @ Loads GPT Base to r1
    mov r0, #0x00000041
    str r0, [r1, #GPT_CR]

    @ Prescaler zeroed
    mov r0, #0
    str r0, [r1, #GPT_SR]

    @ Compare current value to TIME_SZ
    mov r0, #TIME_SZ 
    str r0, [r1, #GPT_OCR1]

    @ Enable Output Compare Channel 1 interruption
    mov r0, #1
    str r0, [r1, #GPT_IR]
@@
@ Initializing the GPIO system
@ Configuring each I/O
@ Input  == 1
@ Output == 0
@@
RESET_GPIO:
    @ GPIO constants
	.set GPIO_BASE, 0x53F84000
	.set GPIO_DR, 	0x00
	.set GPIO_GDIR, 0x04
	.set GPIO_PSR, 	0x08
	
	.set SET_GDIR, 				0b11111111111111000000000000111110	

	.set STANDARD_DR, 			0b00000010000001000000000000000000
	.set MASK_SET_TRIGGER, 		0b00000000000000000000000000000010
	.set MASK_UNSET_TRIGGER, 	0b11111111111111111111111111111101
	.set MASK_SET_FLAG,			0b00000000000000000000000000000001
	.set MASK_SONAR_DISTANCE, 	0b00000000000000111111111111000000
	
	.set MASK_WRITE_MOTOR0,		0b11111111111110111111111111111111
	.set MASK_WRITE_MOTOR1, 	0b11111101111111111111111111111111
	
	ldr r0, =GPIO_BASE 			@ loads GPIO base to r0
	ldr r1, =SET_GDIR			@ Loads GDIR mask to r1
	str r1, [r0, #GPIO_GDIR]	@ Saves GDIR mask
	ldr r1, =STANDARD_DR 		@ setting DR so it won't write any speed 
								@ or read any sonar distance
	str r1, [r0, #GPIO_DR]		@ Saves DR

SET_STACKS:
    @ Set svc mode stack
    msr CPSR_c, 0x13    @ Sets control to svc
    ldr sp, =SVC_STACK  @ Starts sp address
    
    @ Set irq mode stack
    msr CPSR_c, 0x12    @ Sets control to irq
    ldr sp, =IRQ_STACK  @ Starts sp address

    @ Set user mode stack
    msr CPSR_c, 0x1F    @ Sets control to SYSTEM
    ldr sp, =USER_STACK @ Starts sp address

@@
@ Zeroes allocated memory area
@@
ZERO_MEM:
    ldr r0, =INI_MEM    @ Loads initial memory address
    ldr r1, =END_MEM    @ Loads end memory address
    mov r2, #0
    ZERO_LOOP:          @ Runs from initial to end zeroing
        str r2, [r0], #1
        cmp r0, r1
        blt ZERO_LOOP

@@
@ Enables TZIC to be notified of GPT timing control interruption
@ This will change SYSTIME every TIME_SZ cycles
@@    
SET_TZIC:
    @ TZIC constants
    .set TZIC_BASE,             0x0FFFC000
    .set TZIC_INTCTRL,          0x0
    .set TZIC_INTSEC1,          0x84 
    .set TZIC_ENSET1,           0x104
    .set TZIC_PRIOMASK,         0xC
    .set TZIC_PRIORITY9,        0x424

    @ Activates interruption controller
    ldr r1, =TZIC_BASE

    @ Configures GPT interruption as non secure
    @ Monitors the interruption 39
    mov r0, #(1 << 7)
    str r0, [r1, #TZIC_INTSEC1]

    @ Enables interruption 39
    mov r0, #(1 << 7)
    str r0, [r1, #TZIC_ENSET1]

    @ Sets interuption 39 priority as 1
    ldr r0, [r1, #TZIC_PRIORITY9]
    bic r0, r0, #0xFF000000
    mov r2, #1
    orr r0, r0, r2, lsl #24
    str r0, [r1, #TZIC_PRIORITY9]

    @ Configure PRIOMASK as 0
    eor r0, r0, r0
    str r0, [r1, #TZIC_PRIOMASK]

    @ Enables interruptions controls 
    mov r0, #1
    str r0, [r1, #TZIC_INTCTRL]

@@
@ Skips to USER program
@@
USER_PROG:
    ldr r0, =USER_PROGRAM
    msr CPSR_c, #0x10   @ USER mode
    bx  r0


@@@@@@@@@@@@@@@@@@@@@@@
@ Treats interruption @
@@@@@@@@@@@@@@@@@@@@@@@
IRQ_HANDLER:
    msr CPSR_c, #0xD2   @ Disables interruptions
    
    sub     lr, lr, #4  @ Sets lr to its right position 
    push    {lr}        @ Backups lr
    mrs    lr, SPSR     @ Backups SPSR
    
    push {r0-r12, lr}   @ Backups current context in IRQ stack

    @ Tells GPT it's treating interruption
    ldr r1, =GPT_BASE   @ Loads GPT address
    mov r0, #0x1
    str r0, [r1, #GPT_SR]

    @ Update SYSTIME
    ldr r1, =SYSTIME    @ Loads current SYSTIME
    ldr r0, [r1]
    add r0, r0, #1      @ Increases current SYSTIME
    str r0, [r1]        @ Saves current SYSTIME

    ldr r1, =DISABLE    @ Verifies if function is enabled
    ldr r1, [r1]
    cmp r1, #1
    beq IRQ_END   
   

    @ todo DEBUG!!!
    cmp r0, #2000
    blo skip2
    mov r0, r0

skip2:
    @ Update DIST_TIMER
    ldr r1, =DIST_TIMER @ Loads current DIST_TIMER
    ldr r0, [r1]
    add r0, r0, #1      @ Increase current DIST_TIMER
    str r0, [r1]        @ Saves current DIST_TIMER

    @ Verifies alarms
    ldr r1, =ALARMS     @ Loads current ALARM count

    ldr r1, [r1]
    cmp r1, #0
    beq IRQ_CALL_VER    @ If there are no alarms skip to callbacks

    ldr r3, =INI_ALARM  @ Loads first alarm address
    ldr r3, [r3]
    mov r2, #0          @ Sets previous alarm as null
    
    IRQ_ALARM:
        ldr r0, [r3]        @ Loads current alarm time

        ldr r1, =SYSTIME    @ Loads systime
        ldr r1, [r1]
        cmp r1, r0          @ Verifies if alarm is going off
        bhs ALARM_OFF       @ Set alarm off

    IRQ_MID:
        ldr r4, [r3, #8]    @ Load next alarm
        cmp r4, #0          @ Verifies if next is null
        movne r2, r3        @ Sets previous as current
        movne r3, r4        @ Loads next alarm address to r3
        bne IRQ_ALARM       @ Verifies next alarm

IRQ_CALL_VER:
    @ Verifies callbacks
    ldr r1, =CALLBACKS  @ Loads callbacks
    ldr r1, [r1]
    cmp r1, #0          @ If there are none skip to end
    beq IRQ_END

    @ Verifies if it's time to verify callback
    ldr r1, =DIST_TIMER     @ Loads dist interval time counter
    ldr r1, [r1]
    cmp r1, #DIST_INTERVAL  @ If it's not time, skip to end
    blt IRQ_END
    b CALLBACK_OFF          @ Runs through Callback list and verifies all
                            @ callbacks

IRQ_END:
    pop {r0-r12, lr}    @ Restores context from IRQ stack

    msr SPSR_cxsf, lr

    ldm sp!, {pc}^

ALARM_OFF:
    ldr r0, [r3, #4]    @ Loads function pointer

    push {r0-r12, lr}
    ldr r2, =SAFETY_BYTE@ Loads safety byte
    mov r3, #1          @ Enables safety byte
    strb r3, [r2]

    ldr r2, =DISABLE
    mov r3, #1
    str r3, [r2]

    msr CPSR_c, #0x10   @ Sets user mode
    blx  r0             @ Runs the function

    mov r7, #100        @ Syscall to change user mode to svc
    svc 0x0

    msr CPSR_c, #0xD2   @ Goes back to IRQ mode

    ldr r2, =DISABLE
    mov r3, #0
    str r3, [r2]

    pop {r0-r12, lr}

    @ Deletes alarm from list
    ldr r4, [r3, #8]    @ Gets next alarm from current one
    cmp r2, #0          @ Verifies if previous alarm is null
    strne r4, [r2, #8]  @ Next alarm for previous is next alarm from current
    ldreq r1, =INI_ALARM
    streq r4, [r1]      @ Sets head as next
    
    mov r0, r3          @ Deactivates alarm pointed by r3
    push {r2, lr}
    bl free
    pop {r2, lr}

    ldr r0, =ALARMS     @ Updates alarm count
    ldr r1, [r0]
    sub r1, r1, #1
    str r1, [r0]

    mov r3, r4          @ Puts current alarm in r3
    cmp r3, #0
    bne IRQ_ALARM
    b IRQ_CALL_VER

@ Triggers callback
CALLBACK_OFF:
    ldr r3, =INI_CALLB  @ Loads first callback address
    ldr r3, [r3]

    CALLBACK_LOOP:
        ldrb r0, [r3]           @ Loads sensor id in r0

        msr CPSR_c, #0xDF       @ Sets SYSTEM mode to put parameter in stack
        push {r0}               @ Pushes read sonar parameter
        msr CPSR_c, #0xD2       @ Goes back to IRQ mode
        
        mov r7, #16             @ Does read_sonar syscall
        svc 0x0                 @ Returns value to r0

        msr CPSR_c, #0xDF       @ Sets SYSTEM mode to return stack pointer
        add sp, sp, #4          @ Fixes stack pointer
        msr CPSR_c, #0xD2       @ Goes back to IRQ mode

        ldr r1, [r3, #1]        @ Loads distance threshold
        cmp r1, r0
        blt CALLBACK_POST

        ldr r2, [r3, #5]        @ Loads function pointer
        push {r0-r12, lr}
        ldr r3, =SAFETY_BYTE    @ Loads safety byte
        mov r4, #1              @ Enables safety byte
        strb r4, [r3]
    
    ldr r5, =DISABLE
    mov r6, #1
    str r6, [r5]
        msr CPSR_c, 0x10        @ Sets user mode
        blx r2                  @ Runs function

        mov r7, #100            @ Syscall to change user mode to svc
        svc 0x0
    
        msr CPSR_c, #0xD2   @ Goes back to IRQ mode

    ldr r2, =DISABLE
    mov r3, #0
    str r3, [r2]
        pop {r0-r12, lr}
        
    CALLBACK_POST:
        ldr r3, [r3, #9]        @ Loads next address
        cmp r3, #0              @ Verifies if it's null
        bne CALLBACK_LOOP       @ Goes back to execution

        ldr r0, =DIST_TIMER     @ Resets DIST_TIMER
        mov r1, #0
        str r1, [r0]
        b IRQ_END               @ Finishes callback verifying
        

sys_call:
    msr CPSR_c, #0xD3   @ Sets mode to svc disabling interruptions
   
    @ Doesn't backup context 
    cmp r7, #100
    beq change_mode

    push {r0-r12, lr}    @ Backups current context in SVC stack

    ldr r0, =DISABLE
    ldr r0, [r0]
    ldr r1, =DISABLE_P
    str r0, [r1]

    msr CPSR_c, #0x13   @ Sets mode to svc disabling interruptions

    ldr r2, =DISABLE
    mov r3, #1
    str r3, [r2]
    
    cmp r7, #16
    beq read_sonar
    cmp r7, #17
    beq register_proximity_callback
    cmp r7, #18
    beq set_motor_speed
    cmp r7, #19
    beq set_motors_speed
    cmp r7, #20
    beq get_time
    cmp r7, #21
    beq set_time
    cmp r7, #22
    beq set_alarm

    @ If there's no matching syscall id
    b end1

@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Syscalls implementation @
@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@
@ Reads sonar and returns distance read
@@
read_sonar:
    msr CPSR_c, #0xDF   @ Setting mode to system to access user stack
    ldr r0, [sp]        @ Getting the sonar ID from stack
    msr CPSR_c, #0xD3   @ Goes back to SVC mode
    
    cmp r0, #15 		@ checking if the sonar id is a valid one (0 'till 15) 
    bhi set_r0_1
    
   	ldr r3, =GPIO_BASE 					@ loading on r3 the valor of GPIO_BASE
    ldr r1, =STANDARD_DR 				@ getting the GPIO_DR valor (the one with no flags setted) and put it on r1
    mov r0, r0, lsl #2 					@ deslocating the bits on r0 so we put it in the right position on de MUX_SONAR bits to DR
    orr r1, r1, r0 						@ adding r1 to r0, so it makes DR with the MUX_SONAR bits setted (trigger still 0)
    
    ldr r10, =MASK_UNSET_TRIGGER
    and r1, r1, r10						@ setting triger to 0 again
    
    str r1, [r3, #GPIO_DR] 				@ storing the valor on DR
    bl loop
    
	ldr r2, =MASK_SET_TRIGGER 			@ setting on r2 the trigger
    orr r1, r1, r2 						@ adding r1+r2 to r1 so the trigger is now 1 and the reading is able
    str r1, [r3, #GPIO_DR] 				@ storing the valor on DR
    bl loop
    
    ldr r9, [r3, #GPIO_DR]
    ldr r8, =MASK_SET_FLAG
    and r9, r9, r8
    
    ldr r10, =MASK_UNSET_TRIGGER
    and r1, r1, r10						@ setting triger to 0 again
    str r1, [r3, #GPIO_DR] 				@ storing the valor on DR
    bl loop

    flag:
    	bl loop
    	ldr r2, [r3, #GPIO_DR]			@ getting the PSR registor on r1
    	
    	ldr r10, =MASK_SET_FLAG
    	and r2, r2, r10			 		@ getting only the valor of the flag
    	cmp r2, #1 						@ comparing the flag with 1
    	bne flag		 				@ if flag == 1 the reading is complete, otherwise we still need to wait
    	
    ldr r2, [r3, #GPIO_DR] 				@ getting the PSR registor on r2
    ldr r10, =MASK_SONAR_DISTANCE
    and r2, r2, r10						@ getting only the bits that inform the distance read
    mov r2, r2, lsr #6 					@ so we have the distance in the least significant bites

	mov r0, r2	
	
    @ Restores context
    add sp, sp, #4
    b end2               @ Ends syscall

@@
@ Sets a callback
@ Callback format:
@       1 byte: sensor id
@       2 byte: distance threshold
@       4 byte: function pointer
@       4 byte: next pointer
@ Returns:
@       r0
@@
register_proximity_callback:
    msr CPSR_c, #0xDF   @ Sets mode to SYSTEM to access user stack

    ldr r0, [sp]        @ Loads sonar identifier from stack into r0
    ldr r1, [sp, #4]    @ Loads distance threshold from stack to r1
    ldr r2, [sp, #8]    @ Loads function pointer to r2

    msr CPSR_c, #0xD3   @ Goes back to svc mode after getting data from stack

    @ If more than 8 callbacks sets r0 as -1 and exits 
    ldr r3, =CALLBACKS  @ Load current callback address into r3
    ldr r4, [r3]        @ Load current callback value to r4
    cmp r4, #MAX_CALLBACKS
    bhs set_r0_1

    @ If invalid sonar in r0, sets r0 as -2 and exits
    cmp r0, #0          @ Verifies if r0 is lower than 0
    blt set_r0_2        @ That is negative index
    cmp r0, #15         @ Verifies if r0 is higher than 15
    bhi set_r0_2        @ That is index is too large

    ldr r3, =INI_CALLB  @ Loads first list address
    ldr r3, [r3]

    mov r4, #0          @ Sets a previous pointer as null
    set_callback_loop:
        cmp r3, #0              @ Verifies if it's not null
        beq new_callback        @ If it is, allocates new callback

        mov r4, r3              @ Sets previous as current
        ldr r3, [r3, #9]        @ Loads next callback

        b set_callback_loop

    new_callback:
    @ New callback
    @ Malloc memory
    push {r0-r2, lr}
    mov r0, #13         @ Size 13 (id + dist + function + next)
    bl malloc
    mov r3, r0          @ Moves return pointer to r3
    pop {r0-r2, lr}

    strb r0, [r3], #1   @ Stores sensor id (mem+0x0)
    str r1, [r3], #4    @ Stores distance threshold (mem+0x1)
    str r2, [r3], #4    @ Stores function pointer (mem+0x5)
    eor r0, r0, r0      @ Zeroes r0
    str r0, [r3]        @ Saves next pointer (mem+0x9)

    sub r3, r3, #9      @ Goes back to original position

    ldr r0, =INI_CALLB
    cmp r4, #0          @ Verifies if previous is null
    streq r3, [r0]      @ If it is, saves current as new head
    strne r3, [r4, #9]  @ Else saves as next for previous

    @ Increase current CALLBACKS count
    ldr r3, =CALLBACKS  @ Load current callback address into r3
    ldr r4, [r3]        @ Load current callback value to r4
    add r4, r4, #1      @ Increments CALLBACK
    str r4, [r3]        @ Save CALLBACK

    add sp, sp, #4      @ Skips r0
    mov r0, #0          @ Sets return value
    b end2              @ Exits function
@@
@ Sets a single motor speed
@ Chooses motor from id in stack
@@	
set_motor_speed:
    msr CPSR_c, 0xDF    @ Sets SYSTEM mode to access USER stack
    ldr r0, [sp]        @ Gets motor ID from stack to r0
    ldr r1, [sp, #4]    @ Gets motor speed from stack to r1
    msr CPSR_c, 0xD3    @ Goes back to SVC mode

    cmp r0, #2			@ if the motor ID is 2 or higher it's invalid (valid == 0 or 1)
    bge set_r0_1
	
    cmp r1, #63			@ checking if the speed sent is a useable speed
    bgt set_r0_2
   	
   	
    ldr r3, =GPIO_BASE 					@ putting the GPIO_BASE on r3
    ldr r2, =STANDARD_DR 				@ getting the DR with the flags setted on r2
    cmp r0, #1 							@ comparing r0 with 1 to check which motor should we write
    beq motor_1
    
    motor_0:
    	
    	mov r1, r1, lsl #19 			@ putting the motor speed on the right place to DR
    	orr r1, r1, r2 					@ adding the motor speed to DR registor
    	ldr r10, =MASK_WRITE_MOTOR0
    	and r1, r1, r10				 	@ setting the trigger to write on the motor 0 to 0, so the valor will be writen
    	bl loop
    	str r1, [r3, #GPIO_DR] 			@ saving the r1 registor on DR
    	
    	b fim
    	  
    motor_1:
    	
    	mov r1, r1, lsl #26 			@ putting the motor speed on the right place to DR
    	orr r1, r1, r2 					@ adding the motor speed to DR registor
    	ldr r10, =MASK_WRITE_MOTOR1
    	and r1, r1, r10 				@ setting the trigger to write on the motor 0 to 0, so the valor will be writen
    	bl loop
    	str r1, [r3, #GPIO_DR] 			@ saving the r1 registor on DR
    	
    fim:
		mov r0, #0

    @ Restoring context
    add sp, sp, #4      @ Skips r0
    b end2
@@
@ Sets both motors speed
@ Speed comes from stack
@ P0 - speed 0
@ P1 - speed 1
@@
set_motors_speed:
    msr CPSR_c, #0xDF           @ Goes to SYSTEM mode to access USER stack
    
    ldr r1, [sp]                @ Gets motor 0 speed from stack
    ldr r0, [sp, #4]            @ Gets motor 1 speed from stack

    msr CPSR_c, #0xD3           @ Goes back to SVC mode

    ldr r3, =GPIO_BASE 					@ putting the GPIO_BASE on r3
    ldr r2, =STANDARD_DR 				@ getting the DR with the flags setted on r2
   	
   	@checking if the speed sent is a useable speed for motor 0
    cmp r1, #63
   	bgt set_r0_1
   	
   	@checking if the speed sent is a useable speed for motor 1
    cmp r0, #63
   	bgt set_r0_2
   	
   	@writing on the motor 0
   	mov r1, r1, lsl #19 				@ putting the motor speed on the right place to DR
	orr r1, r1, r2 						@ adding the motor speed to DR registor
	mov r0, r0, lsl #26 				@ putting the motor 1 speed on the right place to DR
	orr r1, r1, r0 						@ adding the motor 1 speed to DR registor
	
	ldr r10, =MASK_WRITE_MOTOR0
	and r1, r1, r10				 		@ setting the trigger to write on the motor 0 to 0, so the valor will be writen
	ldr r10, =MASK_WRITE_MOTOR1
	and r1, r1, r10				 		@ setting the trigger to write on the motor 1 to 0, so the valor will be writen	
        @msr CPSR_c, #0x13           @ Goes back to SVC mode
	bl loop
	str r1, [r3, #GPIO_DR] 				@ saving the r1 registor on DR

    @ Restoring context
    mov r0, #0                  @ Sets successful value
    add sp, sp, #4
    b end2

@@
@ Returns SYSTIME in r0
@@
get_time:
    ldr r0, =SYSTIME    @ Loads SYSTIME in r0
    ldr r0, [r0]

    add sp, sp, #4      @ Skips r0 (return)

    b end2              @ Goes to end to finish syscall

@@
@ Sets SYSTIME with r0 value
@@
set_time: 
    msr CPSR_c, #0xDF   @ Sets SYSTEM mode to access USER stack
    ldr r0, [sp]        @ Loads r0 from stack into local r0
                        @ Doesn't alter the stack pointer

    msr CPSR_c, #0xD3   @ Goes back to svc mode

    ldr r1, =SYSTIME    @ Loads SYSTIME address in r1
    str r0, [r1]        @ Saves r0 into SYSTIME

    b end1               @ Goes to end to finish syscall

@@
@ Sets an alarm 
@ Alarm format:
@       4 byte: time
@       4 byte: function pointer
@       4 byte: next
@ Returns:
@       r0
@@
set_alarm:
    msr CPSR_c, #0xDF   @ Sets SYSTEM mode to access USER stack
    ldr r0, [sp]        @ Loads function pointer to r0
    ldr r1, [sp, #4]    @ Loads alarm time

    msr CPSR_c, #0xD3   @ Goes back to svc mode after getting data from stack

    @ If more than 8 alarms sets r0 as -1 and exits 
    ldr r2, =ALARMS     @ Loads current alarm address into r2
    ldr r3, [r2]        @ Loads current alarm value to r3
    cmp r3, #MAX_ALARMS
    bhs set_r0_1

    @ If current time greater than alarm time, sets r0 as -2 and exits
    ldr r2, =SYSTIME    @ Loads current system time address
    ldr r3, [r2]        @ Loads current system time value
    cmp r3, r1          @ Verifies if alarm time is bigger than systime
    bhi set_r0_2
    
    ldr r2, =INI_ALARM  @ Loads first list address
    ldr r2, [r2]

    mov r4, #0          @ Sets previous as null
    set_alarm_loop:
        cmp r2, #0              @ Verifies if it's not null
        beq set_alarm_end       @ If it is, allocates new alarm

        mov r4, r2              @ Backups previous pointer
        ldr r2, [r2, #8]        @ Loads next alarm as r2
 
        b set_alarm_loop

    set_alarm_end:
    @ New alarm
    @ Malloc memory
    push {r0-r1, lr}
    mov r0, #12         @ Size 12 (time + function + next)
    bl malloc
    mov r2, r0          @ Moves pointer to r2
    pop {r0-r1, lr}

    @ Alarm 1 + 0 --> time
    @ Alarm 1 + 4 --> function
    @ Alarm 1 + 8 --> alarm 2
    str r1, [r2], #4    @ Saves time
    str r0, [r2], #4    @ Saves function pointer
    eor r0, r0, r0      @ Zeroes r0
    str r0, [r2]        @ Sets next as null

    sub r2, r2, #8      @ Goes back to original position

    ldr r1, =INI_ALARM
    cmp r4, #0          @ Verifies previous null
    streq r2, [r1]      @ If it's null, saves current as new head
    strne r2, [r4, #8]  @ Else saves as next for the previous

    ldr r2, =ALARMS     @ Load current alarm address into r2
    ldr r3, [r2]        @ Load current alarm value to r3

    add r3, r3, #1      @ Increases alarm count
    str r3, [r2]        @ Stores new value
    

    mov r0, #0          @ Sets return value
    add sp, sp, #4
    b end2

@@
@ Change mode from user to svc
@@
change_mode:
    ldr r0, =SAFETY_BYTE@ Loads safety byte
    ldrb r1, [r0]

    cmp r1, #1          @ Verifies if user has irq permissions
    
    mov r1, #0          @ Resets safety byte
    strb r1, [r0]

    moveq pc, lr        @ If user had irq permission moves back without
                        @ setting up CPSR as user, returns as svc

    movs pc, lr         @ Else skips back to normal end

@@@@@@@@@@@@@@@@@@@@@@@
@ Exceptions Handling @
@@@@@@@@@@@@@@@@@@@@@@@
@ Sets r0 to -1
set_r0_1:
    pop {r0-r12, lr}
    mov r0, #-1
    b end

@ Sets r0 to -2 if input is invalid sonar
set_r0_2:
    pop {r0-r12, lr}
    mov r0, #-2
    b end


@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Goes back to USER code @
@@@@@@@@@@@@@@@@@@@@@@@@@@
end1:
    pop {r0}
end2:
    msr CPSR_c, #0xD3
    ldr r1, =DISABLE_P
    ldr r1, [r1]
    ldr r2, =DISABLE
    str r1, [r2]
    pop {r1-r12, lr}
    movs pc, lr

@@@@@@@@@@
@ Extras @
@@@@@@@@@@
@@ Delay @@
@ 15ms delay to set up DR flags @
@ Literally just count from 0 to #LOOP
loop:
    push {r9, r11, lr}
    mov r9, #0
    ldr r11, =LOOP
    looop:
        cmp r9, r11
        add r9, r9, #1
        blt looop
    pop {r9, r11, pc}

@@ Memory allocation @@
@ Allocates a memory area of the size requested and returns to the user
@ a pointer to that memory area
@ Parameter:
@       r0: size of the area
@ Returns:
@       r0: pointer
malloc:
    push {lr}
    @ Data format:
    @ BASE
    @ +0x0: allocated
    @ +0x1: size
    @ +0x7: data start
    @ +0x7+size: data end

    ldr r1, =INI_MEM    @ Loads start of memory area
    malloc_loop:
        ldrb r2, [r1]   @ Loads if allocated
        cmp r2, #1      @ Verifies if memory is free
        bne malloc_post @ If it is keeps going
    malloc_mid:
        ldr r2, [r1, #1]@ Loads size
        add r1, r1, #7  @ Moves r1 to data start
        add r1, r1, r2  @ Moves r1 to data end
        b   malloc_loop @ Restarts loop

    malloc_post:
        push {r0-r1, lr}@ Backups registers for function calling
        bl malloc_size
        cmp r2, #0      @ Verifies if there's size for allocation
        beq malloc_loop @ If there's no size, goes back to loop

        @ Else ends loop here
        pop {r0-r1, lr} @ Current pointer saved in r1

    mov r2, #1          @ Sets allocated bit as true
    strb r2, [r1], #1
    mov r2, r0          @ Sets r2 as size
    str r2, [r1]

    mov r0, r1          @ Copies pointer from r1
    add r0, r0, #5      @ Skips header
    pop {pc}            @ Goes back to program

@ Auxiliary function to verify if memory size is enough
@ Parameters:
@       r0: Size
@       r1: Current pointer
@ Returns:
@       r1: Last pointer
@       r2: 0 - not enough for memory allocation
@       r2: 1 - enough for memory allocation
malloc_size:
    push {lr}
    
    mov r3, r0          @ Total memory size
    add r3, r3, #7

    size_loop:
        cmp r3, #0      @ Verifies if it got to zero
        beq size_true   @ If it is zero, then returns enough memory
        add r1, r1, #1  @ Keeps verifying if memory size is enough
        ldr r2, [r1]    @ Loads what's in r1
        cmp r2, #1      @ Verifies if it's allocated already
        beq size_false  @ If it is, returns false
        sub r3, r3, #1  @ Can put one byte in memory area
        b size_loop

    size_true:
        mov r2, #1
        b size_end
    
    size_false:
        mov r2, #0
        b size_end

    size_end:
    pop {pc}


@ Frees previously allocated memory from malloc
@ Parameter:
@       r0: pointer to memory area
@ Returns:
@       void
free:
    push {lr}

    sub r0, r0, #6
    mov r1, #0          @ Sets allocated bit as zero
    strb r1, [r0], #1

    ldr r2, [r0]        @ Loads size in r2
    free_loop:
        cmp r2, #0      @ While size is bigger than zero, saves zeroes
        beq free_end
        strb r1, [r0], #1
        sub r2, r2, #1
        b free_loop
        
    free_end:
    pop {pc}

.data
    @ Constants
    .set        TIME_SZ,        10              @ Number of clocks for GPT
    .set        MAX_CALLBACKS,  8               @ Max callbacks
    .set        MAX_ALARMS,     8               @ Max alarms
    .set        SVC_STACK,      0x77811000      @ SVC stack memory
    .set        IRQ_STACK,      0x77811250      @ IRC stack memory
    .set        USER_STACK,     0x77811500      @ USER stack memory
    .set        USER_PROGRAM,   0x77802000      @ User program area
    .set        INI_MEM,        0x77823000      @ Malloc start area
    .set        END_MEM,        0x7782FFFF      @ Malloc end area
    .set        SAFETY_BYTE,    0x77832999      @ Verifies if was previously in IRQ
    .set        DIST_INTERVAL,  1               @ Verifies sensor every 5 systimes
    .set        LOOP,           1200            @ Loop comparing size

    @ Variables
    SYSTIME:    .word           0       @ System timer starts at zero
    CALLBACKS:  .word           0       @ System callbacks count
    ALARMS:     .word           0       @ System alarms count
    DIST_TIMER: .word           0       @ Temporary dist counter
    INI_ALARM:  .word           0       @ Alarm list head address
    INI_CALLB:  .word           0       @ Callback list head address
    DISABLE:    .word           0       @ Enables or disables irq function
    DISABLE_P:  .word           0       @ Previous disable status

    @ Alarm format:
    @   allocated       - 4 bytes
    @   time            - 4 bytes
    @   function        - 4 bytes
    @   next            - 4 bytes
