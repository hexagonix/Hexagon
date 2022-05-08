;;************************************************************************************
;;
;;    
;;        %#@$%    &@$%$                  Kernel Hexagon®
;;        #$@$@    #@#@$
;;        @#@$%    %#$#%
;;        @#$@$    #@#$@
;;        #@#$$#$#%!@#@#     Copyright © 2016-2022 Felipe Miguel Nery Lunkes
;;        @#@%!@&$#&$#@#             Todos os direitos reservados
;;        !@$%#    @&$%#
;;        @$#!%    #&*@&
;;        $#$#%    &%$#@
;;        @#!$$    !#@#@
;;
;;
;;************************************************************************************
;;                                                                                  
;;                                 Kernel Hexagon®          
;;                                                                   
;;                  Copyright © 2016-2022 Felipe Miguel Nery Lunkes                
;;                          Todos os direitos reservados.                    
;;                                                                   
;;************************************************************************************
;;
;;                    Este arquivo faz parte do Kernel Hexagon® 
;;
;;************************************************************************************

Hexagon.Int:

.interrupcaoHexagon = 69h ;; Interrupção do Hexagon®
.interrupcaoTimer   = 08h ;; Interrupção reservada ao timer
.interrupcaoTeclado = 09h ;; Interrupção reservada ao teclado
.interrupcaoMouse   = 74h ;; Interrupção reservada ao dispositivo apontador

;;************************************************************************************

use32

;; Instala as rotinas de interrupção do Hexagon® (ISR - Interrupt Service Routine)

instalarInterrupcoes:

;; Instalar os manipuladores de IRQs
	
	mov dword[ordemKernel], ordemKernelExecutar

	mov esi, manipuladorTimer               ;; IRQ 0
	mov eax, Hexagon.Int.interrupcaoTimer   ;; Número da interrupção
	
	call instalarISR

	mov esi, manipuladorTeclado	            ;; IRQ 1
	mov eax, Hexagon.Int.interrupcaoTeclado ;; Número da interrupção			
	
	call instalarISR
	
	mov esi, manipuladorHexagon             ;; Serviços do Hexagon®
	mov eax, Hexagon.Int.interrupcaoHexagon ;; Número da interrupção       
	
	call instalarISR

	mov esi, manipuladorMousePS2            ;; IRQ 12
	mov eax, Hexagon.Int.interrupcaoMouse   ;; Número da interrupção	    
	
	call instalarISR

	sti				              ;; Habilitar interrupções
	
	mov dword[ordemKernel], ordemKernelDesativada

	ret                           ;; Tudo pronto

;;************************************************************************************

;; IRQ 0 - Manipulador do Timer

;; A cada interrupção do timer, será incromentado o contador. Este contador pode
;; ser utilizado para temporizar operações de entrada e saída, assim como causar
;; atraso em diversas aplicações do Sistema e de aplicativos.

manipuladorTimer:

	push eax
	
	inc dword[.contagemTimer] ;; Incrementa o contador
	inc dword[.contadorRelativo]

	mov al, 0x20
	
	out 0x20, al

	pop eax
	
	pushad

	call Hexagon.Kernel.Arch.x86.CMOS.CMOS.atualizarDadosCMOS ;; Atualizar o relógio em tempo real a cada intervalo

	popad

	iret
	
.contagemTimer:    dd 0 ;; Este conteúdo é utilizado
.contadorRelativo: dd 0

;;************************************************************************************

;; Manipuladores de interrupção

;; IRQ 1 - Interrupção de teclado

manipuladorTeclado:

	push eax
	push ebx
	
	push ds
	
	mov ax, 0x10			;; Segmento de dados do Kernel
	mov ds, ax
		
	xor eax,eax

	in al, 0x60
  	
	cmp al, Hexagon.Teclado.Codigo.F1 ;; Tecla F1
	je .terminarTarefa

;; Checar se a tecla Control foi pressionada

	cmp al, Hexagon.Teclado.Codigo.ctrl
	je .controlPressionada
	
	cmp al, 29+128
	je .controlLiberada
	
;; Checar pressionamento da tecla Shift

	cmp al, Hexagon.Teclado.Codigo.shiftD ;; Tecla shift da direita
	je .shiftPressionado
	
	cmp al, Hexagon.Teclado.Codigo.shiftE ;; Tecla shift da esquerda
	je .shiftPressionado
	
	cmp al, 54+128         ;; Tecla shift direita liberada
	je .shiftLiberado
	
	cmp al, 42+128         ;; Tecla shift esquerda liberada
	je .shiftLiberado
	
	jmp .outraTecla

.controlPressionada:

	or dword[estadoTeclas], 0x00000001
	
	jmp .naoArmazenar
	
.controlLiberada:

	and dword[estadoTeclas], 0xFFFFFFFE
	
	jmp .naoArmazenar
	
.shiftPressionado:

	or dword[estadoTeclas], 0x00000002
	
	mov byte[.sinalShift], 1 ;; Shift pressionada
	
	jmp .naoArmazenar

.shiftLiberado:

	and dword[estadoTeclas], 0xFFFFFFFD
	
	mov byte[.sinalShift], 0
	
	jmp .naoArmazenar
	
.outraTecla:
		
	jmp .fim

;;************************************************************************************

.terminarTarefa:

	call Hexagon.Kernel.Kernel.Proc.matarProcesso

;;************************************************************************************
	
.fim:	

	mov ebx, .codigosEscaneamento
	add bl, byte[.codigosEscaneamento.indice]
	
	mov byte[ebx], al

	cmp byte[.codigosEscaneamento.indice], 31
	jl .incrementarIndice
	
	mov byte[.codigosEscaneamento.indice], -1
	
.incrementarIndice:

	inc byte[.codigosEscaneamento.indice]

.naoArmazenar:

	mov al, 0x20
	
	out 0x20, al
	
	pop ds
	
	pop ebx
	pop eax
	
	iret

.codigosEscaneamento: times 32	db 0
.codigosEscaneamento.indice:	db 0
.sinalShift:                    db 0

;; Bit 0: Tecla Control
;; Bit 1: Tecla Shift
;; Bit 2-31: Reservado

estadoTeclas:    dd 0

;;************************************************************************************

;; IRQ 12 - Manipulador de Mouse PS/2

manipuladorMousePS2:

	pusha

	cmp byte[.estado], 0
	je .pacoteDeDados
	
	cmp byte[.estado], 1
	je .pacoteX
	
	cmp byte[.estado], 2
	je .pacoteY
	
.pacoteDeDados:

	in al, 0x60
	mov byte[.dados], al

	mov byte[.estado], 1
	jmp .fim2

.pacoteX:

	in al, 0x60
	mov byte[.deltaX], al

	mov byte[.estado], 2
	jmp .fim2

.pacoteY:

	in al, 0x60
	mov byte[.deltaY], al

	mov byte[.estado], 0

	mov byte[.alterado], 1

.fim:

	
	movzx eax, byte[manipuladorMousePS2.deltaX]	;; DeltaX alterado em X
	movzx ebx, byte[manipuladorMousePS2.deltaY]	;; DeltaY alterado em Y
	mov dl, byte[manipuladorMousePS2.dados]
	
	bt dx, 4		;; Checar se o mouse se moveu para a esquerda
	jnc .movimentoADireita
	
	xor eax, 0xff		;; 255 - deltaX
	sub word[.mouseX], ax	;; MouseX - DeltaX
	
	jnc .xOK		;; Checar se MouseX é menor que 0
	mov word[.mouseX], 0	;; Corrigir MouseX

	jmp .xOK
	
.movimentoADireita:

	add word[.mouseX], ax	;; MouseX + DeltaX
	
.xOK:

	bt dx, 5		;; Checar se o mouse se moveu para baixo
	jnc .movimentoParaCima
	
	xor ebx, 0xff		;; 255 - DeltaY
	sub word[.mouseY], bx	;; MouseY - DeltaY

	jnc .yOK		;; Checar se MouseY é menor que 0
	mov word[.mouseY], 0	;; Corrigir MouseY

	jmp .yOK

.movimentoParaCima:

	add word[.mouseY], bx	;; MouseY + DeltaY
	
.yOK:
	
	movzx eax, word[.mouseX]
	movzx ebx, word[.mouseY]

	;; Ter certeza que X e Y não são maiores que a resolução do vídeo
	
	cmp ax, word[Hexagon.Video.Resolucao.x]
	jng .xNaoMaior
	
	mov ax, word[Hexagon.Video.Resolucao.x]
	mov word[.mouseX], ax
	
.xNaoMaior:

	cmp bx, word[Hexagon.Video.Resolucao.y]
	jng .yNaoMaior
	
	mov bx, word[Hexagon.Video.Resolucao.y]
	mov word[.mouseY], bx

.yNaoMaior:
	
	push edx
	movzx edx, word[Hexagon.Video.Resolucao.y]
	sub dx, word[.mouseY]
	mov ebx, edx
	pop edx
	
	mov dword[Hexagon.Mouse.mouseX], eax
	mov dword[Hexagon.Mouse.mouseY], ebx

.fim2:	

	
	mov al, 0x20		;; Fim da interrupção
	out 0x20, al
	out 0xa0, al

	popa
	
	iret
	
.estado:	db 0
.deltaX: 	db 0
.deltaY:	db 0
.dados:		db 0
.alterado:	db 0

align 32

.estadoMouse: dd 0
.mouseX:	  dd 0
.mouseY:	  dd 0

;;************************************************************************************

;; Manipulador especializado para touchpads - IRQ 12

manipuladorTouchpad:

	push eax
	push edx

	cmp byte[.estado], 0
	je .pacote0
	
	cmp byte[.estado], 1
	je .pacote1
	
	cmp byte[.estado], 2
	je .pacote2

	cmp byte[.estado], 3
	je .pacote3

	cmp byte[.estado], 4
	je .pacote4

	cmp byte[.estado], 5
	je .pacote5
	
.pacote0:

	mov al, 0
	
	call Hexagon.Kernel.Dev.Universal.Console.Console.limparLinha

	in al, 0x60

	movzx eax, al
	mov dl, 0
	mov dh, 0	
	
	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirBinario
	
	mov byte[.estado], 1
	
	jmp .fim

.pacote1:

	mov al, 1

	call Hexagon.Kernel.Dev.Universal.Console.Console.limparLinha

	in al, 0x60
	
	mov bl, al

	and al, 1111b
	movzx eax, al
	shl eax, 8
	mov word[.X], ax
	
	mov al, bl
	and al, 11110000b
	movzx eax, al
	shl eax, 4
	mov word[.Y], ax

	mov al, bl
	movzx eax, al
	mov dl, 0
	mov dh, 1	
	
	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirBinario

	mov byte[.estado], 2

	jmp .fim

.pacote2:

	mov al, 2
	
	call Hexagon.Kernel.Dev.Universal.Console.Console.limparLinha

	in al, 0x60

	movzx eax, al
	mov dl, 0
	mov dh, 2	
	
	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirDecimal

	mov byte[.estado], 3
	
	jmp .fim
	
.pacote3:

	mov al, 3
	
	call Hexagon.Kernel.Dev.Universal.Console.Console.limparLinha

	in al, 0x60
	
	mov bl, al
	
	movzx eax, al
	and eax, 00010000b
	shl eax, 8
	or word[.X], ax

	mov al, bl

	movzx eax, al
	and eax, 00100000b
	shl eax, 7
	or word[.Y], ax
	
	mov al, bl

	movzx eax, al
	mov dl, 0
	mov dh, 3
	
	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirBinario

	mov byte[.estado], 4
	
	jmp .fim

.pacote4:

	mov al, 4

	call Hexagon.Kernel.Dev.Universal.Console.Console.limparLinha

	in al, 0x60

	movzx ax, al
	or word[.X], ax

	movzx eax, word[.X]
	
;; sub EAX, 1000

	mov dl, 0
	mov dh, 4	
	
	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirDecimal

	mov byte[.estado], 5
	
	jmp .fim

.pacote5:

	mov al, 5
	
	call Hexagon.Kernel.Dev.Universal.Console.Console.limparLinha

	in al, 0x60

	movzx ax, al
	or word[.Y], ax

	movzx eax, word[.Y]
	
;; sub EAX, 1000

	mov dl, 0
	mov dh, 5	

	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirDecimal

	mov byte[.estado], 0
	
	jmp .fim

.fim:

	mov al, 0x20		;; Fim da interrupção
	
	out 0x20, al
	
	out 0xa0, al

	pop edx
	pop eax
	
	iret
	
.estado:		db 0
.X:		dw 0
.Y:		dw 0
.Z:		db 0

;;************************************************************************************

;; Manipulador para outras interrupções, quando as mesmas não estiverem disponíveis

naoManipulado:

	push eax
	
	mov al, 0x20
	
	out 0x20, al
	
	pop eax
	
	iret

;;************************************************************************************	

;; Instala um manipulador de interrupção ou manipulador IRQ
;;
;; Entrada:
;;
;; EAX - Número da interrupção
;; ESI - Rotina de interrupção

instalarISR:

	push eax
	push ebp

;; Primeiramente vamos verificar se o pedido de instalação de interrupção partiu
;; do Hexagon®, observando a variável que registra essas solicitações previlegiadas.

	cmp dword[ordemKernel], ordemKernelExecutar ;; Caso sim, ignorar medidas de discriminação
	je .instalar

;; Caso a solicitação tenha partido do usuário ou aplicativo, verificar se os valores
;; passados poderiam sobrescrever as interrupções instaladas previamente pelo Hexagon®

	cmp eax, Hexagon.Int.interrupcaoHexagon ;; Tentativa de substituir a chamada do Hexagon®
	je .negar                               ;; Negar instalação

	cmp eax, Hexagon.Int.interrupcaoTimer   ;; Tentativa de alterar a interrupção de timer
	je .negar                               ;; Negar instalação

	cmp eax, Hexagon.Int.interrupcaoTeclado ;; Tentativa de alterar a interrupção de teclado
	je .negar                               ;; Negar instalação

	cmp eax, Hexagon.Int.interrupcaoMouse   ;; Tentativa de alterar a interrupção de mouse
	je .negar                               ;; Negar instalação

.instalar:

	mov ebp, eax
	mov eax, esi
	
	mov word[IDT+ebp*8], ax
	shr eax, 16
	
	mov word[IDT+ebp*8+6], ax

	jmp .fim

.negar:

	stc 

	mov eax, 01h

.fim:

	pop ebp
	pop eax
	
	ret
