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

use32

;;************************************************************************************

Hexagon.Graficos:

.corFundoPadrao  = PRETO_ANDROMEDA
.corFontePadrao  = BRANCO_ANDROMEDA
.corFundo:       dd .corFundoPadrao
.corFonte:       dd .corFontePadrao
.bytesPorLinha:  dd 0
.corFonteTema:   dd 0
.corFundoTema:   dd 0

PRETO_ANDROMEDA  = 0x00000000
BRANCO_ANDROMEDA = 0xFFFFFFFF

;;************************************************************************************

;; Calcular deslocamento do pixel no buffer de vídeo
;;
;; Entrada:
;;
;; EAX - X
;; EBX - Y
;;
;; Saída:
;;
;; ESI - Endereço do pixel

Hexagon.Kernel.Lib.Graficos.calcularDeslocamentoPixel:

	push eax		;; X

	mov esi, dword[Hexagon.Video.Memoria.enderecoLFB]	;; Ponteiro para a memória de vídeo
	
	movzx eax, word[Hexagon.Video.bytesPorLinha]
	
	mul ebx			;; Y * bytes por linha

	add esi, eax
	
	pop eax			;; X
	
	movzx ebx, byte[Hexagon.Video.bytesPorPixel]
	
	mul ebx			;; X * Bytes por pixel

	add esi, eax    ;; ESI é um ponteiro para a memória de vídeo
	
	ret
	
;;************************************************************************************

;; Exibir caractere bitmap no modo gráfico
;;
;; Entrada:
;;
;; DL - Coluna
;; DH - Linha
;; AL - Caractere	

Hexagon.Kernel.Lib.Graficos.colocarCaractereBitmap:
	
	push edx
	
	and eax, 0xff
	sub eax, 32
	mov ebx, Hexagon.Fontes.altura
	
	mul ebx
	
	mov edi, Hexagon.Fontes
	add edi, 04h
	add edi, eax
	
	pop edx
	
	push edx
	
	mov eax, Hexagon.Fontes.largura
	movzx ebx, dl
	
	mul ebx
	
	mov word[.x], ax

	pop edx
	
	mov eax, Hexagon.Fontes.altura
	movzx ebx, dh
	
	mul ebx
	
	mov word[.y], ax
	
	mov eax, Hexagon.Fontes.largura
	mov ebx, dword[Hexagon.Video.bytesPorPixel]
	
	mul ebx
	
	mov dword[.proximaLinha], eax
	
	movzx eax, word[.x]
	
	dec eax
	
	movzx ebx, word[.y]
	
	call Hexagon.Kernel.Lib.Graficos.calcularDeslocamentoPixel
	
	mov ecx, Hexagon.Fontes.altura
	
.colocarColuna:

	mov al, byte[edi]
	
	inc edi
		
	push ecx
	
	mov ecx, Hexagon.Fontes.largura
	
.colocarLinha:

	bt ax, 7
	jc .colocarPrimeiroPlano
	
.colocarPlanodeFundo:

	mov edx, dword[Hexagon.Graficos.corFundo]	
	
	jmp .colocarLinha.proximo
	
.colocarPrimeiroPlano:

	mov edx, dword[Hexagon.Graficos.corFonte]

.colocarLinha.proximo:

	add esi, dword[Hexagon.Video.bytesPorPixel]	
	
	mov word[gs:esi], dx
	shr edx, 8
	mov byte[gs:esi+2], dh
	
	shl al, 1
	
	loop .colocarLinha
	
	pop ecx

	add esi, dword[Hexagon.Video.bytesPorLinha]
	sub esi, dword[.proximaLinha]
	
	loop .colocarColuna
	
.fim:

	ret
	
.x:	           dw 0
.y:	           dw 0
.proximaLinha: dd 0

;;************************************************************************************

;; Usar buffer para armazenamento de mensagens e relatórios do Kernel

Hexagon.Kernel.Lib.Graficos.usarBufferKernel:

	mov eax, [Hexagon.Video.Memoria.enderecoLFB]
	mov [Hexagon.Video.Memoria.bufferVideo1], eax ;; Salvar endereço original 

	mov eax, [Hexagon.Video.Memoria.bufferVideoKernel]
	mov [Hexagon.Video.Memoria.enderecoLFB], eax
	
	ret

;;************************************************************************************

;; Usar buffer anterior (double buffering)

Hexagon.Kernel.Lib.Graficos.usarBufferVideo2:

	mov eax, [Hexagon.Video.Memoria.enderecoLFB]
	mov [Hexagon.Video.Memoria.bufferVideo1], eax ;; Salvar endereço original 

	mov eax, [Hexagon.Video.Memoria.bufferVideo2]
	mov [Hexagon.Video.Memoria.enderecoLFB], eax
	
	ret
	
;;************************************************************************************	

;; Usar buffer de página real

Hexagon.Kernel.Lib.Graficos.usarBufferVideo1:

	mov eax, [Hexagon.Video.Memoria.bufferVideo1]
	mov [Hexagon.Video.Memoria.enderecoLFB], eax ;; Restaurar endereço original
	
	ret

;;************************************************************************************

;; Copiar buffer para a memória de vídeo	

Hexagon.Kernel.Lib.Graficos.atualizarTela:

	cmp byte[Hexagon.Video.modoGrafico], 1
	jne .nadaAFazer
	
	mov eax, dword[Hexagon.Video.tamanhoVideo]
	mov ecx, eax
	shr ecx, 7 ;; Dividir por 128
	
	cmp ebx, 1h
	je .bufferKernel

.bufferUsuario:
	
	mov edi, dword[Hexagon.Video.Memoria.bufferVideo1]
	mov esi, dword[Hexagon.Video.Memoria.bufferVideo2]
	
	jmp .continuar

.bufferKernel:
	
	mov edi, dword[Hexagon.Video.Memoria.bufferVideo1]
	mov esi, dword[Hexagon.Video.Memoria.bufferVideoKernel]

.continuar:
	
	push es
	push ds
	
	mov ax, 0x18
	mov es, ax
	mov ds, ax

.loopAtualizar:

	prefetchnta [esi+128]
	prefetchnta [esi+160]
	prefetchnta [esi+192]
	prefetchnta [esi+224]

	movdqa xmm0, [esi+0]
	movdqa xmm1, [esi+16]
	movdqa xmm2, [esi+32]
	movdqa xmm3, [esi+48]
	movdqa xmm4, [esi+64]
	movdqa xmm5, [esi+80]
	movdqa xmm6, [esi+96]
	movdqa xmm7, [esi+112]
	
	movdqa [edi+0], xmm0 
	movdqa [edi+16], xmm1
	movdqa [edi+32], xmm2
	movdqa [edi+48], xmm3
	movdqa [edi+64], xmm4
	movdqa [edi+80], xmm5
	movdqa [edi+96], xmm6
	movdqa [edi+112], xmm7
		
	add edi, 128
	add esi, 128
	
	loop .loopAtualizar
	
	pop ds
	pop es

.nadaAFazer:

	ret

;;************************************************************************************

;; Colocar um pixel na tela
;;
;; Entrada:
;;
;; EAX - X
;; EBX - Y
;; EDX - Cor em hexadecimal
 
Hexagon.Kernel.Lib.Graficos.colocarPixel:

	push eax
	push edx
	push ebx
	push esi
	
	push edx
	
	call Hexagon.Kernel.Lib.Graficos.calcularDeslocamentoPixel ;; Obter deslocamento do pixel
	
	pop edx
	
	mov word[gs:esi], dx
	shr edx, 8
	mov byte[gs:esi+2], dh

.fim:	

	pop esi
	pop ebx
	pop edx
	pop eax
	
	ret

;;************************************************************************************

;; Desenhar um bloco de cor específica
;;
;; Entrada:
;;
;; EAX - X
;; EBX - Y
;; ESI - Comprimento
;; EDI - Largura
;; EDX - Cor em hexadecimal
	
Hexagon.Kernel.Lib.Graficos.desenharBloco:

	push eax
	push ebx
	push ecx

	cmp byte[Hexagon.Video.modoGrafico], 1
	jne .fim

	mov ecx, edi        ;; Largura
	
.y:

	push ecx
	
	mov ecx, esi        ;; Comprimento
	
.x:

	call Hexagon.Kernel.Lib.Graficos.colocarPixel	
	
	inc eax
	
	loop .x
	
	pop ecx

	sub eax, esi

	inc ebx
	
	loop .y

.fim:

	pop ecx
	pop ebx
	pop eax
	
	ret

;;************************************************************************************	

;; Configura a resolução e configurações padrão de vídeo durante a inicialização

Hexagon.Kernel.Lib.Graficos.configurarVideo:

.modoGrafico1:

	mov eax, 01h
	
	call Hexagon.Kernel.Dev.Universal.Console.Console.definirResolucao
	
	ret				