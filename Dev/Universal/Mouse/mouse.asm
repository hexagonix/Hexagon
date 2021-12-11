;;************************************************************************************
;;
;;    
;;        %#@$%    &@$%$                  Kernel Hexagon®
;;        #$@$@    #@#@$
;;        @#@$%    %#$#%
;;        @#$@$    #@#$@
;;        #@#$$#$#%!@#@#     Copyright © 2016-2021 Felipe Miguel Nery Lunkes
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
;;                  Copyright © 2016-2021 Felipe Miguel Nery Lunkes                
;;                          Todos os direitos reservados.                    
;;                                                                   
;;************************************************************************************
;;
;;                    Este arquivo faz parte do Kernel Hexagon® 
;;
;;************************************************************************************

Hexagon.Mouse:

.mouseX: dd 0
.mouseY: dd 0

;;************************************************************************************

use32

;; Inicializar o mouse PS/2

Hexagon.Kernel.Dev.Universal.Mouse.Mouse.iniciarMouse:

	push eax
	
;; Habilitar IRQ para o mouse

	call Hexagon.Kernel.Dev.Universal.PS2.PS2.esperarEscritaPS2	;; Esperar se PS/2 estiver ocupado
	
	mov al, 0x20		    ;; Obter bit de status Compaq
	
	out 0x64, al		    ;; 0x64 é o registrador de estado
	
	call Hexagon.Kernel.Dev.Universal.PS2.PS2.esperarLeituraPS2	
	
	in al, 0x60
	
	or al, 2		        ;; Definir segundo bit para 1 pra habilitar IRQ12
	mov bl, al		        ;; Salvar bit modificado
	
	call Hexagon.Kernel.Dev.Universal.PS2.PS2.esperarEscritaPS2
	
	mov al, 0x60		    ;; Definir byte de estado Compaq
	
	out 0x64, al		

	call Hexagon.Kernel.Dev.Universal.PS2.PS2.esperarEscritaPS2
	
	mov al, bl		        ;; Enviar byte modificado
	
	out 0x60, al

;; Habilitar dispositivo auxiliar (Mouse)

	call Hexagon.Kernel.Dev.Universal.PS2.PS2.esperarEscritaPS2
	
	mov al, 0xA8		    ;; Habilitar dispositivo auxiliar
	
	out 0x64, al
	
;; Usar configurações padrão

	mov al, 0xF6		    ;; Definir como padrão
	
	call Hexagon.Kernel.Dev.Universal.PS2.PS2.enviarPS2
	
	call Hexagon.Kernel.Dev.Universal.PS2.PS2.esperarLeituraPS2
	
	in al, 0x60		

;; Definir resolução

	mov al, 0xE8		
	
	call Hexagon.Kernel.Dev.Universal.PS2.PS2.enviarPS2
	
	call Hexagon.Kernel.Dev.Universal.PS2.PS2.esperarLeituraPS2
	
	in al, 0x60		

	mov al, 3		        ;; 8 contagens/mm
	
	call Hexagon.Kernel.Dev.Universal.PS2.PS2.enviarPS2

	call Hexagon.Kernel.Dev.Universal.PS2.PS2.esperarLeituraPS2
	
	in al, 0x60		
	
;; Habilitar pacotes

	mov al, 0xF4		    ;; Habilitar pacotes
	
	call Hexagon.Kernel.Dev.Universal.PS2.PS2.enviarPS2
	
	call Hexagon.Kernel.Dev.Universal.PS2.PS2.esperarLeituraPS2
	
	in al, 0x60		

	mov ax, word[Hexagon.Video.Resolucao.y]
	mov word[manipuladorMousePS2.mouseY], ax

	pop eax
	
	ret

;;************************************************************************************

;; Obter posição atual do mouse e estado dos botões
;;
;; Saída:
;;
;; EAX - Posição X do mouse
;; EBX - Posição Y do mouse
;; EDX - Botões do mouse (bit #0 = botão esquerdo, bit #1 = botão direito)

Hexagon.Kernel.Dev.Universal.Mouse.Mouse.obterDoMouse:

	mov eax, [Hexagon.Mouse.mouseX]
	mov ebx, [Hexagon.Mouse.mouseY]
	mov edx, 0 ;;byte[manipuladorMousePS2.dados]

	ret

;;************************************************************************************

;; Definir nova posição do mouse
;;
;; Entrada:
;;
;; EAX - Posição X do mouse
;; EBX - Posição Y do mouse	

Hexagon.Kernel.Dev.Universal.Mouse.Mouse.configurarMouse:

	mov [Hexagon.Mouse.mouseX], eax
	mov [Hexagon.Mouse.mouseY], ebx
	mov byte[manipuladorMousePS2.dados], 0
	
	ret

;;************************************************************************************	

Hexagon.Kernel.Dev.Universal.Mouse.Mouse.iniciarTouchPad:

	push eax

	mov al, 0xF5		;; Desativar
	
	call Hexagon.Kernel.Dev.Universal.PS2.PS2.enviarPS2

	call Hexagon.Kernel.Dev.Universal.PS2.PS2.esperarLeituraPS2
	
	in al, 0x60		

	mov al, 0xE8
	
	call Hexagon.Kernel.Dev.Universal.PS2.PS2.enviarPS2
	
	call Hexagon.Kernel.Dev.Universal.PS2.PS2.esperarLeituraPS2
	
	in al, 0x60		

	mov al, 0x03
	
	call Hexagon.Kernel.Dev.Universal.PS2.PS2.enviarPS2

	call Hexagon.Kernel.Dev.Universal.PS2.PS2.esperarLeituraPS2
	
	in al, 0x60		

	mov al, 0xE8
	
	call Hexagon.Kernel.Dev.Universal.PS2.PS2.enviarPS2

	call Hexagon.Kernel.Dev.Universal.PS2.PS2.esperarLeituraPS2
	
	in al, 0x60		

	mov al, 0x00
	
	call Hexagon.Kernel.Dev.Universal.PS2.PS2.enviarPS2

	call Hexagon.Kernel.Dev.Universal.PS2.PS2.esperarLeituraPS2
	
	in al, 0x60		

	mov al, 0xE8
	
	call Hexagon.Kernel.Dev.Universal.PS2.PS2.enviarPS2

	call Hexagon.Kernel.Dev.Universal.PS2.PS2.esperarLeituraPS2
	
	in al, 0x60		

	mov al, 0x00
	
	call Hexagon.Kernel.Dev.Universal.PS2.PS2.enviarPS2

	call Hexagon.Kernel.Dev.Universal.PS2.PS2.esperarLeituraPS2
	
	in al, 0x60		

	mov al, 0xE8
	
	call Hexagon.Kernel.Dev.Universal.PS2.PS2.enviarPS2

	call Hexagon.Kernel.Dev.Universal.PS2.PS2.esperarLeituraPS2
	
	in al, 0x60		

	mov al, 0x01
	
	call Hexagon.Kernel.Dev.Universal.PS2.PS2.enviarPS2

	call Hexagon.Kernel.Dev.Universal.PS2.PS2.esperarLeituraPS2
	
	in al, 0x60		

	mov al, 0xF3
	
	call Hexagon.Kernel.Dev.Universal.PS2.PS2.enviarPS2

	call Hexagon.Kernel.Dev.Universal.PS2.PS2.esperarLeituraPS2
	
	in al, 0x60		

	mov al, 0x14
	
	call Hexagon.Kernel.Dev.Universal.PS2.PS2.enviarPS2

	call Hexagon.Kernel.Dev.Universal.PS2.PS2.esperarLeituraPS2
	
	in al, 0x60		

	mov al, 0xF4		;; Habilitar
	
	call Hexagon.Kernel.Dev.Universal.PS2.PS2.enviarPS2

	call Hexagon.Kernel.Dev.Universal.PS2.PS2.esperarLeituraPS2
	
	in al, 0x60		

	mov esi, manipuladorTouchpad ;; IRQ 12
	mov eax, 74h		         ;; Número da interrupção
	
	call instalarISR

	pop eax
	
	ret
		
;;************************************************************************************

;; Aguardar por eventos do mouse e obter seus valores
;;
;; Saída:
;; 
;; EAX - Posição X do mouse
;; EBX - Posição Y do mouse
;; EDX - Botões do mouse (bit #0 = botão esquerdo, bit #1 = botão direito)

;; Aguardar por eventos do mouse e obter seus valores
;;
;; Saída:
;; 
;; EAX - Posição X do mouse
;; EBX - Posição Y do mouse
;; EDX - Botões do mouse (bit #0 = botão esquerdo, bit #1 = botão direito)

Hexagon.Kernel.Dev.Universal.Mouse.Mouse.aguardarMouse:

	sti

	mov byte[manipuladorMousePS2.alterado], 0
	
.aguardar:

	cmp byte[manipuladorMousePS2.alterado], 1	;; Checar se o estado do mouse foi alterado
	
	hlt
	
	jne .aguardar

	mov eax, [Hexagon.Mouse.mouseX]
	mov ebx, [Hexagon.Mouse.mouseY]
	movzx edx, byte[manipuladorMousePS2.dados]
	
	ret
