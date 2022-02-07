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

Hexagon.Teclado.Codigo: ;; Keycodes

.ESC       = 01h
.backspace = 08h 
.tab       = 15h
.enter     = 0x1C
.ctrl      = 0x1D
.shiftE    = 0x2A
.shiftD    = 0x36
.espaco    = 0x39
.capsLock  = 0x3A
.F1        = 0x3B
.F2        = 0x3C
.F3        = 0x3D
.F4        = 0x3E
.F5        = 0x3F
.F6        = 0x40
.F7        = 0x41
.F8        = 0x42
.F9        = 0x43
.F10       = 0x44
.home      = 0x47
.end       = 0x49
.esquerda  = 0x4B
.direita   = 0x4D
.delete    = 0x53
.print     = 0x54
.F11       = 0x57
.F12       = 0x58
.pause     = 0x5A
.insert    = 0x5B

;;************************************************************************************

use32

;; Inicializar o teclado, configurando os LEDS, taxa de repetição e delay

Hexagon.Kernel.Dev.Universal.Teclado.Teclado.iniciarTeclado:

	push eax

;; Primeiro precisamos enviar comandos e depois configurar os LEDs

	mov al, 0xED		;; 0xED é o comando para configurar LEDs
	
	call Hexagon.Kernel.Dev.Universal.PS2.PS2.esperarEscritaPS2
	
	out 0x60, al		;; Enviar comando
	
	call Hexagon.Kernel.Dev.Universal.PS2.PS2.esperarLeituraPS2
	
	in al, 0x60		

	mov al, 000b		;; 000 define todos os LEDs como desligados
	
	call Hexagon.Kernel.Dev.Universal.PS2.PS2.esperarEscritaPS2
	
	out 0x60, al		;; Enviar dados
	
	call Hexagon.Kernel.Dev.Universal.PS2.PS2.esperarLeituraPS2
	
	in al, 0x60		

;; Definir taxa de repetição e delay

	mov al, 0xF3		;; 0xF3 é o comando para ajustar a taxa de repetição e delay
	
	call Hexagon.Kernel.Dev.Universal.PS2.PS2.esperarEscritaPS2
	
	out 0x60, al		;; Enviar comando
	
	call Hexagon.Kernel.Dev.Universal.PS2.PS2.esperarLeituraPS2
	
	in al, 0x60		
	
	mov al, 00000000b	;; 0 é sempre 0, 00 é para delay e 250 ms, 00000 é taxa de repetição de 30 hz
	
	call Hexagon.Kernel.Dev.Universal.PS2.PS2.esperarEscritaPS2
	
	out 0x60, al		;; Agora enviar dados
	
	call Hexagon.Kernel.Dev.Universal.PS2.PS2.esperarLeituraPS2
	
	in al, 0x60		

.fim:

	pop eax
	
	ret
	
;;************************************************************************************

;; Obter string pelo teclado
;;
;; Entrada:
;;
;; AL  - Tamanho máximo da string para se obter
;; EBX - Eco do que foi digitado (1234h = sem eco, <> 1234h = com eco)
;; Saída:
;; 
;; ESI - String	

Hexagon.Kernel.Dev.Universal.Teclado.Teclado.obterString:

	push eax
	push ecx
	push edx
	
	push es
	
	mov dword[.eco], ebx
	
	mov byte[.string], 0
	mov byte[.charAtual], 0
	
	push ds
	pop es			        ;; ES = DS

	mov ecx, 0		        ;; Contador de caracteres
	movzx ebx, al	        ;; Máximo de caracteres
	
	call Hexagon.Kernel.Dev.Universal.Console.Console.obterCursor

.obterTecla:
	
	call Hexagon.Kernel.Dev.Universal.Console.Console.posicionarCursor
	
	cmp dword[.eco], 1234h
	je .continuar
	
.comEco:
	
	mov esi, .string
	
	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirString

	mov al, ' '
	
	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirCaractere
	
.continuar:

	push edx
	
	add dl, byte[.charAtual]
	
	cmp dword[.eco], 1234h
	je .semMoverCursor
	
	call Hexagon.Kernel.Dev.Universal.Console.Console.posicionarCursor

.semMoverCursor:

	pop edx
	
	call Hexagon.Kernel.Dev.Universal.Teclado.Teclado.aguardarTeclado	;; Obter caractere

	cmp ah, Hexagon.Teclado.Codigo.home		        ;; Código
	je .teclaHome
	
	cmp ah, Hexagon.Teclado.Codigo.end
	je .teclaEnd
		
	cmp ah, Hexagon.Teclado.Codigo.delete
	je .teclaDelete
	
	cmp ah, Hexagon.Teclado.Codigo.esquerda
	je .teclaEsquerda
	
	cmp ah, Hexagon.Teclado.Codigo.direita
	je .teclaDireita
	
	cmp al, 10		        ;; Código ASCII
	je .fim
	
	cmp al, Hexagon.Teclado.Codigo.backspace
	je .teclaBackspace
	
	cmp al, ' '
	jb .obterTecla		    ;; Não utilizar esta tecla
	
	cmp al, '~'
	ja .obterTecla		    ;; Não utilizar esta tecla

	cmp cl, bl
	je .obterTecla

	push edx
	
	movzx esi, byte[.charAtual]
	
	add esi, .string
	
	mov edx, 0
	
	call Hexagon.Kernel.Lib.String.inserirCaractereNaString
	
	pop edx
	
	inc byte[.charAtual]
	
	inc cl
	
	jmp .obterTecla
	
.teclaBackspace:

	cmp byte[.charAtual], 0	;; Não permitido
	je .obterTecla

	dec byte[.charAtual]
	
	push ecx	
	
	movzx esi, byte[.charAtual]
	
	add esi, .string
	
	mov eax, 0
	
	call Hexagon.Kernel.Lib.String.removerCaractereNaString
	
	pop ecx
	
	dec cl
	
	jmp .obterTecla

.teclaDelete:

	cmp byte[.charAtual], cl ;; Não permitido
	je .obterTecla
	
	push ecx	
	
	movzx esi, byte[.charAtual]
	
	add esi, .string
	
	mov eax, 0
	
	call Hexagon.Kernel.Lib.String.removerCaractereNaString
	
	pop ecx
	
	dec cl
	
	jmp .obterTecla	
	
.teclaHome:

	mov byte[.charAtual], 0
	
	jmp .obterTecla

.teclaEnd:

	mov byte[.charAtual], cl
	
	jmp .obterTecla
	
.teclaEsquerda:

	cmp byte[.charAtual], 0	;; Não permitido
	je .obterTecla
	
	dec byte[.charAtual]
	
	jmp .obterTecla
	
.teclaDireita:

	cmp byte[.charAtual], cl ;; Não permitido
	je .obterTecla
	
	inc byte[.charAtual]
	
	jmp .obterTecla
	
.fim:

	and ecx, 0x0f
	mov esi, .string
	
	pop es
	
	pop edx
	pop ecx
	pop eax
	
	mov dword[.eco], 00h
	
	ret
	
.string: times 256 db 0 ;; Buffer para armazenar caracteres
.charAtual:	       db 0
.eco:              dd 0 ;; Registra se a tecla pressionada deve ou não ser exibida (eco)

;;************************************************************************************

;; Obter status de teclas especiais
;;
;; Saída:
;;
;; EAX - Estado das teclas
;;
;;  Formato:
;;
;; Bit 0: Tecla Control
;; Bit 1: Tecla Shift
;; Bit 2-31: Reservado

Hexagon.Kernel.Dev.Universal.Teclado.Teclado.obterEstadoTeclas:

	mov eax, [estadoTeclas]
	
	ret

;;************************************************************************************

;; Altera o leiaute do dispositivo de entrada (teclado)
;;
;; Entrada: 
;;
;; ESI - Ponteiro para o buffer contendo o nome do arquivo que contêm o leiaute à ser usado
;;
;; Saída:
;;
;; CF definido em caso de erro

Hexagon.Kernel.Dev.Universal.Teclado.Teclado.alterarLeiaute:

	call Hexagon.Kernel.FS.VFS.arquivoExiste
	
	jc .erroLeiaute
	
	mov edi, Hexagon.Teclado.leiauteTeclado
		
	call Hexagon.Kernel.FS.VFS.carregarArquivo
	
	ret
	
.erroLeiaute:

	stc
	
	ret

;;************************************************************************************

;; Aguardar por teclas no teclado
;;
;; Saída:
;;
;; AL - Caractere ASCII
;; AH - Código	

Hexagon.Kernel.Dev.Universal.Teclado.Teclado.aguardarTeclado:

	push ebx
	
	sti
	
.loopTeclas:

	mov al, byte[.indiceCodigosAtual]
	
	cmp byte[manipuladorTeclado.codigosEscaneamento.indice], al
	je .loopTeclas

	mov ebx, manipuladorTeclado.codigosEscaneamento
	
	add bl, byte[.indiceCodigosAtual]
	
	mov ah, byte[ebx]
	mov al, ah
	
	cmp byte[.indiceCodigosAtual], 31
	jl .incrementarIndice
	
	mov byte[.indiceCodigosAtual], -1
	
.incrementarIndice:

	inc byte[.indiceCodigosAtual]
	
	bt ax, 7			
	jc .loopTeclas

;; Checar Shift

	cmp byte[manipuladorTeclado.sinalShift], 1
	je .usarCaracteresShift
	
	mov ebx, Hexagon.Teclado.leiauteTeclado.teclas        ;; Vetor de códigos de escaneamento
	
	xlatb
	
	jmp .fim
	
.usarCaracteresShift:

	mov ebx, Hexagon.Teclado.leiauteTeclado.teclasShift   ;; Vetor de códigos de escaneamento com Shift
	
	xlatb
	
.fim:

	pop ebx
	
	ret
	
.indiceCodigosAtual: db 0

;;************************************************************************************

Hexagon.Teclado.leiauteTeclado:

.teclas:

	db 27, 0, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', 8, ' ', 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', "'", '['
	db 10, 29, 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 127, '~', "'", 42, ']', 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', ';'
	db 0xff, 0xff, 0xff, ' '
	
	db 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, '7', '8', '9', '-', '4', '5', '6', '+'
	db '1', '2', '3', '0', '.', 0xff, 0xff, '\', 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	db 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	db '/', 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	
.teclasShift:

	db 27, 0, '!', '@', '#', '$', '%', '?', '&', '*', '(', ')', '_', '+', 8, 9, 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '`', '{'
	db 10, 29, 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 127, '^', '"', 42, '}', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', '<', '>', ':'
	db 0xff, 0xff, 0xff, ' '
	
	db 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, '7', '8', '9', '-', '4', '5', '6', '+'
	db '1', '2', '3', '0', '.', 0xff, 0xff, '|', 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	db 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	db '?', 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
