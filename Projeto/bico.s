.global set_motor_speed
.global set_motors_speed
.global read_sonar
.global read_sonars
.global register_proximity_callback
.global add_alarm
.global get_time
.global set_time
.align 4

set_motor_speed:
	stmfd sp!, {r4-r11, lr}	@ Save the callee-save registers and the return address.
	ldrb r1, [r0], #1 @obtendo o ID do motor
	ldrb r2, [r0] @obtendo a velociadade do motor
	stmfd sp!, {r1, r2} @mandando para a pilha os parametros da funcao P0 e P1
	mov r7, #18
	b sys.call_2
	
set_motors_speed:
	stmfd sp!, {r4-r11, lr}	@ Save the callee-save registers and the return address.
	ldrb r2, [r0, #1] @obtendo a velociade do motor 0
	ldrb r3, [r1, #1] @obtendo a velocidade do motor 1
	stmfd sp!, {r2, r3} @passando os parametros P0 e P1
	mov r7, #19
	b sys.call_2
	
read_sonar:
	stmfd sp!, {r4-r11, lr}	@ Save the callee-save registers and the return address.
	stmfd sp!, {r0} @colocando o indentificador do sonar na pilha (paraemtro P0)
	mov r7, #16 @colocando em r7 o valor correto da syscall
	b sys.call_1
	
read_sonars:
	stmfd sp!, {r4-r11, lr}	@ Save the callee-save registers and the return address.
	mov r4, r0 @salvando em outro local o 1o sonar a ser lido
	mov r5, r1 @salvando em outro local o ultimo sonar a ser lido
	mov r6, r2 @salvando em outro local o inicio do vetor de distancias
	loop:
		cmp r4, r5 @comparando a atual posicao com a ultima
		bgt end @se for maior o loop se encerra
		stmfd sp!, {r4} @passando como paramerto o sonar a ser lido P0
		mov r7, #16 @colocando em r7 o valor da sys call
		svc 0x0
		add sp, sp, #4
		mov r10, #4
		mul r7, r4, r10 @multiplicando o valor do sonar por 4
		add r8, r6, r4 @somando o valor anterior com o endereço base do vetor
		str r0, [r8] @guardando nesta possicao o retorno da funcao
		add r4, r4, #1 @indo para o proximo sonar
		b loop
	end:
		ldmfd sp!, {r4-r11, pc} @ Restore the registers and return
		
register_proximity_callback:
	stmfd sp!, {r4-r11, lr}	@ Save the callee-save registers and the return address.
	stmfd sp!, {r0, r1, r2}
	mov r7, #17
	b sys.call_3
	
add_alarm:
	stmfd sp!, {r4-r11, lr}	@ Save the callee-save registers and the return address.
	stmfd sp!, {r0, r1}
	mov r7, #22
	b sys.call_2
	
get_time:
	stmfd sp!, {r4-r11, lr}	@ Save the callee-save registers and the return address.
	mov r7, #20
	b sys.call
	
set_time:
	stmfd sp!, {r4-r11, lr}	@ Save the callee-save registers and the return address.
	stmfd sp!, {r0}
	mov r7, #21
	b sys.call_1
	
sys.call:
	svc 0x0
	ldmfd sp!, {r4-r11, pc} @ Restore the registers and return

sys.call_1: @funcao pra chamar syscall se passamos apenas 1 parametro
	svc 0x0
	add sp, sp, #4
	ldmfd sp!, {r4-r11, pc} @ Restore the registers and return

sys.call_2: @funcao pra chamar syscall se passamos 2 parametros
	svc 0x0
	add sp, sp, #8
	ldmfd sp!, {r4-r11, pc} @ Restore the registers and return

sys.call_3: @funcao pra chamar syscall se passamos 3 parametros
	svc 0x0
	add sp, sp, #12
	ldmfd sp!, {r4-r11, pc} @ Restore the registers and return
