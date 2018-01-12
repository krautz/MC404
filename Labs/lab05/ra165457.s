@ CAIO KRAUTHAMER RA 165457

.globl _start

.data

input_buffer:   .skip 32
output_buffer:  .skip 32
    
.text
.align 4

@ Funcao inicial
_start:
    @ Chama a funcao "read" para ler 4 caracteres da entrada padrao
    ldr r0, =input_buffer
    mov r1, #5             @ 4 caracteres + '\n'
    bl  read
    mov r4, r0             @ copia o retorno para r4.

    @ Chama a funcao "atoi" para converter a string para um numero
    ldr r0, =input_buffer
    mov r1, r4
    bl  atoi

    @ Chama a funcao "encode" para codificar o valor de r0 usando
    @ o codigo de hamming.
    bl  encode
    mov r4, r0             @ copia o retorno para r4.
	
    @ Chama a funcao "itoa" para converter o valor codificado
    @ para uma sequencia de caracteres '0's e '1's
    ldr r0, =output_buffer
    mov r1, #7
    mov r2, r4
    bl  itoa

    @ Adiciona o caractere '\n' ao final da sequencia (byte 7)
    ldr r0, =output_buffer
    mov r1, #'\n'
    strb r1, [r0, #7]

    @ Chama a funcao write para escrever os 7 caracteres e
    @ o '\n' na saida padrao.
    ldr r0, =output_buffer
    mov r1, #8         @ 7 caracteres + '\n'
    bl  write
    
    
    
    
    
    @ Chama a funcao "read" para ler 7 caracteres da entrada padrao
    ldr r0, =input_buffer
    mov r1, #8             @ 7 caracteres + '\n'
    bl  read
    mov r4, r0             @ copia o retorno para r4.

    @ Chama a funcao "atoi" para converter a string para um numero
    ldr r0, =input_buffer
    mov r1, r4
    bl  atoi

    @ Chama a funcao "decode" para decodificar o valor de r0 usando
    @ o codigo de hamming.
    bl  decode
    mov r4, r0             @ copia o retorno para r4.
    mov r5, r1
	
    @ Chama a funcao "itoa" para converter o valor codificado
    @ para uma sequencia de caracteres '0's e '1's
    ldr r0, =output_buffer
    mov r1, #4
    mov r2, r4
    bl  itoa

    @ Adiciona o caractere '\n' ao final da sequencia (byte 4)
    ldr r0, =output_buffer
    mov r1, #'\n'
    strb r1, [r0, #4]
    
    @ Chama a funcao write para escrever os 4 caracteres e
    @ o '\n' na saida padrao.
    ldr r0, =output_buffer
    mov r1, #5         @ 4 caracteres + '\n'
    bl  write
    
    
    
    
    @ Chama a funcao "itoa" para converter o valor codificado
    @ para uma sequencia de caracteres '0's e '1's
    ldr r0, =output_buffer
    mov r1, #1
    mov r2, r5
    bl  itoa

    @ Adiciona o caractere '\n' ao final da sequencia (byte 1)
    ldr r0, =output_buffer
    mov r1, #'\n'
    strb r1, [r0, #1]
    
    @ Chama a funcao write para escrever o caracter e
    @ o '\n' na saida padrao.
    ldr r0, =output_buffer
    mov r1, #2         @ 1 caracteres + '\n'
    bl  write

    @

    @ Chama a funcao exit para finalizar processo.
    mov r0, #0
    bl  exit

@ Codifica o valor de entrada usando o codigo de hamming.
@ parametros:
@  r0: valor de entrada (4 bits menos significativos)
@ retorno:
@  r0: valor codificado (7 bits como especificado no enunciado).
encode:    
       push {r4-r11, lr}
       
       @ <<<<<< ADICIONE SEU CODIGO AQUI >>>>>>
       and r1, r0, #1 @colocando em R1 o valor de d4
       and r2, r0, #2 @colocando em R2 o valor de d3
       mov r2, r2, lsr #1 @deslocando o bit de R2 para termos ele no local menos significativo
       and r3, r0, #4 @colocando em R3 o valor de d2
       mov r3, r3, lsr #2 @deslocando o bit de R3 para termos ele no local menos significativo
       and r5, r0, #8 @colocando em R5 o valor de d1
       mov r5, r5, lsr #3 @deslocando o bit de R5 para termos ele no local menos significativo
       eor r6, r3, r2 @em R6 guardaremos p3
       eor r6, r6, r1
       eor r7, r5, r2 @em R7 guardaremos p2
       eor r7, r7, r1
       eor r8, r5, r3 @em R8 guardaremos p1
       eor r8, r8, r1
       and r1, r0, #7 @colocando agr em R1 o valor d2d3d4
       and r2, r0, #8 @colocando agr em R2 o valor d1
       mov r2, r2, lsl #1 @movendo d1 para o local certo da soma
       mov r6, r6, lsl #3 @movendo p3 para o local certo da soma
       mov r7, r7, lsl #5 @movendo p2 para o local certo da soma
       mov r8, r8, lsl #6 @movendo p1 para o local certo da soma
       add r0, r1, r6 @formando em R0 p3d2d3d4
       add r0, r0, r2 @formando agr em RO d1p3d2d3d4
       add r0, r0, r7 @formando agr em R0 p2d1p3d2d3d4
       add r0, r0, r8 @formando agr o final em R0 p1p2d1p3d2d3d4
       
    
       pop  {r4-r11, lr}
       mov  pc, lr

@ Decodifica o valor de entrada usando o codigo de hamming.
@ parametros:
@  r0: valor de entrada (7 bits menos significativos)
@ retorno:
@  r0: valor decodificado (4 bits como especificado no enunciado).
@  r1: 1 se houve erro e 0 se nao houve.
decode:    
       push {r4-r11, lr}
       
       @ <<<<<< ADICIONE SEU CODIGO AQUI >>>>>>
       
       and r1, r0, #1 @colocando em R1 o valor de d4
       and r2, r0, #2 @colocando em R2 o valor de d3
       mov r2, r2, lsr #1 @deslocando o bit de R2 para termos ele no local menos significativo
       and r3, r0, #4 @colocando em R3 o valor de d2
       mov r3, r3, lsr #2 @deslocando o bit de R3 para termos ele no local menos significativo
       and r5, r0, #8 @colocando em R5 o valor de p3
       mov r5, r5, lsr #3 @deslocando o bit de R5 para termos ele no local menos significativo
       and r6, r0, #16 @colocando em R66 o valor de d1
       mov r6, r6, lsr #4 @deslocando o bit de R6 para termos ele no local menos significativo
       and r7, r0, #32 @colocando em R7 o valor de p2
       mov r7, r7, lsr #5 @deslocando o bit de R7 para termos ele no local menos significativo
       and r8, r0, #64 @colocando em R8 o valor de p1
       mov r8, r8, lsr #6 @deslocando o bit de R8 para termos ele no local menos significativo
       
       eor r9, r6, r3 @vendo se p1 XOR d1 XOR d2 XOR d4 = 0
       eor r9, r9, r1
       eor r9, r9, r8
       cmp r9, #0
       bne invalid
       
       eor r9, r6, r2 @vendo se p2 XOR d1 XOR d3 XOR d4 = 0
       eor r9, r9, r1
       eor r9, r9, r7
       cmp r9, #0
       bne invalid
       
       eor r9, r3, r2 @vendo se p3 XOR d2 XOR d3 XOR d4 = 0
       eor r9, r9, r1
       eor r9, r9, r5
       cmp r9, #0
       bne invalid
       
       mov r1, #0
            
       fim:
              and r2, r0, #7 @colocando d2d3d4 em R1
              and r3, r0, #16 @colocando d1 em R2
              mov r3, r3, lsr #1 @colocando d1 no local correto
              add r0, r2, r3 @colocando em R0 d1d2d3d4
              b end
              
       invalid: 
              mov r1, #1
              b fim
       
       end:
              pop  {r4-r11, lr}
              mov  pc, lr

@ Le uma sequencia de bytes da entrada padrao.
@ parametros:
@  r0: endereco do buffer de memoria que recebera a sequencia de bytes.
@  r1: numero maximo de bytes que pode ser lido (tamanho do buffer).
@ retorno:
@  r0: numero de bytes lidos.
read:
    push {r4,r5, lr}
    mov r4, r0
    mov r5, r1
    mov r0, #0         @ stdin file descriptor = 0
    mov r1, r4         @ endereco do buffer
    mov r2, r5         @ tamanho maximo.
    mov r7, #3         @ read
    svc 0x0
    pop {r4, r5, lr}
    mov pc, lr

@ Escreve uma sequencia de bytes na saida padrao.
@ parametros:
@  r0: endereco do buffer de memoria que contem a sequencia de bytes.
@  r1: numero de bytes a serem escritos
write:
    push {r4,r5, lr}
    mov r4, r0
    mov r5, r1
    mov r0, #1         @ stdout file descriptor = 1
    mov r1, r4         @ endereco do buffer
    mov r2, r5         @ tamanho do buffer.
    mov r7, #4         @ write
    svc 0x0
    pop {r4, r5, lr}
    mov pc, lr

@ Finaliza a execucao de um processo.
@  r0: codigo de finalizacao (Zero para finalizacao correta)
exit:    
    mov r7, #1         @ syscall number for exit
    svc 0x0

@ Converte uma sequencia de caracteres '0' e '1' em um numero binario
@ parametros:
@  r0: endereco do buffer de memoria que armazena a sequencia de caracteres.
@  r1: numero de caracteres a ser considerado na conversao
@ retorno:
@  r0: numero binario
atoi:
    push {r4, r5, lr}
    mov r4, r0         @ r4 == endereco do buffer de caracteres
    mov r5, r1         @ r5 == numero de caracteres a ser considerado 
    mov r0, #0         @ number = 0
    mov r1, #0         @ loop indice
atoi_loop:
    cmp r1, r5         @ se indice == tamanho maximo
    beq atoi_end       @ finaliza conversao
    mov r0, r0, lsl #1 
    ldrb r2, [r4, r1]  
    cmp r2, #'0'       @ identifica bit
    orrne r0, r0, #1   
    add r1, r1, #1     @ indice++
    b atoi_loop
atoi_end:
    pop {r4, r5, lr}
    mov pc, lr

@ Converte um numero binario em uma sequencia de caracteres '0' e '1'
@ parametros:
@  r0: endereco do buffer de memoria que recebera a sequencia de caracteres.
@  r1: numero de caracteres a ser considerado na conversao
@  r2: numero binario
itoa:
    push {r4, r5, lr}
    mov r4, r0
itoa_loop:
    sub r1, r1, #1         @ decremento do indice
    cmp r1, #0          @ verifica se ainda ha bits a serem lidos
    blt itoa_end
    and r3, r2, #1
    cmp r3, #0
    moveq r3, #'0'      @ identifica o bit
    movne r3, #'1'
    mov r2, r2, lsr #1  @ prepara o proximo bit
    strb r3, [r4, r1]   @ escreve caractere na memoria
    b itoa_loop
itoa_end:
    pop {r4, r5, lr}
    mov pc, lr    
