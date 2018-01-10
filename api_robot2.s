@ Uoli Control Application Programming Interface
@ Global
.global read_sonar
.global read_sonars
.global register_proximity_callback
.global set_motor_speed
.global set_motors_speed
.global get_time
.global set_time
.global add_alarm


@@@@@  Motors  @@@@@
@ Struct for changing motor speed
@       unsigned char id;
@       unsigned char speed;

@ Sets motor speed.
@ Parameter:
@       r0: pointer to motor_cfg_t struct
@ Returns:
@       void
set_motor_speed:
    push {r7, lr}

    ldrb r1, [r0, #1]   @ Loads motor speed to r1
    push {r1}           @ Pushes motor speed to the stack
    ldrb r1, [r0]       @ Loads motor id to r1
    push {r1}           @ Pushes motor id to the stack

    mov r7, #18         @ Calls set_motor_speed syscall
    svc 0x0

    add sp, sp, #8      @ Returns stack pointer to initial position
    pop {r7, pc}

@ Sets both motors speed
@ Parameters:
@       r0: pointer to motor_cfg_t struct
@       r1: pointer to motor_cfg_t struct
@ Returns:
@       void
set_motors_speed:
    push {r7, lr}

    ldrb r2, [r0]       @ Loads motor id to r2
    ldrb r3, [r1]       @ Loads motor id to r3

    cmp r2, #0          @ Verifies if r0 is id zero
    ldr r2, [r0, #1]    @ Loads speed 1 to r2
    ldr r3, [r1, #1]    @ Loads speed 2 to r3
    beq set_motors_speed_1
    bne set_motors_speed_2

    set_motors_speed_1:
    push {r3}           @ Pushes speed 2
    push {r2}           @ Pushes speed 1           
    b set_motors_speed_end

    set_motors_speed_2: @ Else
    push {r2}           @ Pushes speed 2
    push {r3}           @ Pushes speed 1

    set_motors_speed_end:
    mov r7, #19         @ Calls set_motors_speed syscall
    svc 0x0 

    add sp, sp, #8      @ Returns stack pointer to initial position
    pop {r7, pc}
@@@@@@@@@@@@@@@@@@@@

@@@@@  Sonars  @@@@@

@ Reads one of the sonars
@ Paremeter:
@       r0: sonar id (ranges from 0 to 15)
@ Returns:
@       r0: distance of selected sonar
read_sonar:
    push {r7, lr}

    push {r0}           @ Puts selected sonar to the stack

    mov r7, #16         @ Calls read_sonar syscall
    svc 0x0

    add sp, sp, #4       @ Returns stack pointer to initial position
    pop {r7, pc}

@ Reads a range of sonars at once
@ Parameter:
@       r0: start of sonars indexes to read
@       r1: end of sonars indexes to read
@       r2: pointer to sonar distances array
@ Returns:
@       void
read_sonars:
    push {lr}

    mov r3, r0          @ Put start of sonars to read index in r3

    read_loop:
    cmp r3, r2          @ Verifies if loop has reached to its end
                        @ current sonar index > final sonar index
    bgt loop_end        @ Goes to end of function if that happens

    mov r0, r2          @ Moves current sonar index to read to r0
    bl  read_sonar      @ Reads current sonar state with function

    str r0, [r1], #4    @ Saves current sonar distance into array

    add r3, r3, #1      @ Increments 1 to index for the next read
    b   read_loop       @ Branching back to the start of the loop

    loop_end:

    pop {pc}

@ Registers a function f to be called when robot gets close to an object
@ Parameters:
@       r0: id of the sensors to be monitored
@       r1: threshold distance
@       r2: function pointer
@ Returns:
@       void
register_proximity_callback:
    push {r7, lr}       @ Backups registers

    push {r2}           @ Puts function pointer to be called in the stack
    push {r1}           @ Puts the min distance to be considered in the stack
    push {r0}           @ Puts the sensor to be read in the stack

    mov r7, #17         @ Sets syscall id in r7
    svc 0x0             @ Does the syscall

    add sp, sp, #12     @ Removes stacked items

    pop {r7, pc}        @ Returns to main program
@@@@@@@@@@@@@@@@@@@

@@@@@  Timer  @@@@@

@ Adds an alarm to the system
@ Parameters:
@       r0: function pointer
@       r1: alarm time
@ Returns:
@       void
add_alarm:
    push {r7, lr}

    push {r0-r1}        @ Puts vars in the stack
    mov r7, #22         @ Sets add_alarm syscall id
    svc 0x0

    add sp, sp, #8      @ Removes stacked items

    pop {r7, pc}

@ Reads system time
@ Parameter:
@       r0: time var return pointer
@ Returns:
@       void
get_time:
    push {r7, lr}

    mov r1, r0          @ Backups r0 to r1

    mov r7, #20         @ Sets get_time syscall id
    svc 0x0
    
    @ Syscall returns time to r0
    str r0, [r1]        @ Stores time to address pointed by r1
                        @ which was previously saved at r0

    pop {r7, pc}

@ Sets the system time
@ Parameter:
@       r0: system time
@ Returns:
@       void
set_time:
    push {r7, lr}

    push {r0}           @ Adds r0 var to stack

    mov r7, #21         @ Sets set_set syscall id
    svc 0x0

    add sp, sp, #4      @ Removes stacked items

    pop {r7, pc}
