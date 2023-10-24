;;************************************************************************************
;;
;; 88       88
;; 88       88
;; 88       88  ,adPPPba, 8b,     ,d8 ,adPPPPba,  ,adPPPb,d8  ,adPPPba,    ,dPPPba,
;; 88PPPPPPP88 a8P     88  `P8, ,8P'  ""     `P8 a8"    `P88 a8"     "8a 88P'   `"88
;; 88       88 8PP"""""""    )888(    ,adPPPPP88 8b       88 8b       d8 88       88
;; 88       88 '8b,   ,aa  ,d8" "8b,  88,    ,88 "8a,   ,d88 "8a,   ,a8" 88       88
;; 88       88  `"Pbbd8"' 8P'     `P8 `"8bbdP"P8  `"PbbdP"P8  `"PbbdP"'  88       88
;;                                                aa,    ,88
;;                                                 "P8bbdP"
;;
;;                          Kernel Hexagon - Hexagon kernel
;;
;;                 Copyright (c) 2015-2023 Felipe Miguel Nery Lunkes
;;                Todos os direitos reservados - All rights reserved.
;;
;;************************************************************************************
;;
;; Português:
;;
;; O Hexagon, Hexagonix e seus componentes são licenciados sob licença BSD-3-Clause.
;; Leia abaixo a licença que governa este arquivo e verifique a licença de cada repositório
;; para obter mais informações sobre seus direitos e obrigações ao utilizar e reutilizar
;; o código deste ou de outros arquivos.
;;
;; English:
;;
;; The Hexagon, the Hexagonix and its components are licensed under a BSD-3-Clause license.
;; Read below the license that governs this file and check each repository's license for
;; obtain more information about your rights and obligations when using and reusing
;; the code of this or other files.
;;
;;************************************************************************************
;;
;; BSD 3-Clause License
;;
;; Copyright (c) 2015-2023, Felipe Miguel Nery Lunkes
;; All rights reserved.
;;
;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions are met:
;;
;; 1. Redistributions of source code must retain the above copyright notice, this
;;    list of conditions and the following disclaimer.
;;
;; 2. Redistributions in binary form must reproduce the above copyright notice,
;;    this list of conditions and the following disclaimer in the documentation
;;    and/or other materials provided with the distribution.
;;
;; 3. Neither the name of the copyright holder nor the names of its
;;    contributors may be used to endorse or promote products derived from
;;    this software without specific prior written permission.
;;
;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
;; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
;; DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
;; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
;; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
;; SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
;; CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
;; OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
;; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;;
;; $HexagonixOS$

;;************************************************************************************
;;
;;                     Este arquivo faz parte do kernel Hexagon
;;
;;************************************************************************************

;; Informações úteis para utilização do modo gráfico
;; Implementação de modo gráfico do Hexagon

;; A implementação de modo gráfico se baseia nas especificações VESA 3.0.

;; Visualizar especificações VESA 3.0 para mais informações
;; VBE = VESA BIOS Extensions

use32

;;************************************************************************************

Hexagon.Video:

.modoUsuario:   db 0
.modoGrafico:   db 0
.tamanhoVideo:  dd 0
.modoVBE:       dw .padrao
.padrao         = 118h
.maxColunas:    dw 0
.maxLinhas:     dw 0
.bitsPorPixel:  db 0
.bytesPorPixel: dd 0
.bytesPorLinha: dd 0

Hexagon.Video.Resolucao:

.x: dw 1024
.y: dw 768

Hexagon.Video.Memoria:

;; Endereços de memória para operações de vídeo

.bufferVideo1:      dd 100000h
.bufferVideo2:      dd 100000h
.bufferVideoKernel: dd 300000h
.enderecoLFB:       dd 0 ;; Endereço do LFB (Linear Frame Buffer)

Hexagon.Video.modoTexto:

.corAtual:      db .corPadrao
.corPadrao      = 0xF0
.cursor.X:      db 0
.cursor.Y:      db 0
.maximoLinhas   = 24 ;; Contando de 0
.maximoColunas  = 79 ;; Contando de 0
.memoriaDeVideo = 0xB8000

;;************************************************************************************

;; Define a resolução à ser utilizada para a exibição
;;
;; Entrada:
;;
;; EAX - Número relativo a resolução à ser utilizada
;;       1 - Resolução de 800x600 pixels
;;       2 - Resolução de 1024x768 pixels
;;       3 - Alterar para modo texto

Hexagon.Kernel.Dev.Gen.Console.Console.definirResolucao:

    cmp eax, 01h ;; 800x600 pixels
    je .modoGrafico1

    cmp eax, 02h ;; 1024x768
    je .modoGrafico2

    cmp eax, 03h ;; Modo texto legado (será removido)
    je .modoTexto

    jmp .fim

.modoGrafico1:

    mov word[Hexagon.Video.modoVBE], 0x115 ;; Resolução de 800x600 pixels segundo especificação VESA 3.0

    call Hexagon.Kernel.Dev.Gen.Console.Console.definirModoGrafico

    jmp .fim

.modoGrafico2:

    mov word[Hexagon.Video.modoVBE], 0x118 ;; Resolução de 1024x768 pixels segundo especificação VESA 3.0

    call Hexagon.Kernel.Dev.Gen.Console.Console.definirModoGrafico

    jmp .fim

.modoTexto:

    call Hexagon.Kernel.Dev.Gen.Console.Console.definirModoTexto

.fim:

    ret

;;************************************************************************************

;; Retorna o número relativo à resolução atual do vídeo
;;
;; Saída:
;;
;; EAX - Número relativo a resolução atualmente utilizada
;;       1 - Resolução de 800x600 pixels
;;       2 - Resolução de 1024x768 pixels

Hexagon.Kernel.Dev.Gen.Console.Console.obterResolucao:

    mov ax, word[Hexagon.Video.modoVBE]

    cmp ax, 115h
    je .modoGrafico1

    cmp ax, 118h
    je .modoGrafico2

    ret

.modoGrafico1:

    mov eax, 1

    ret

.modoGrafico2:

    mov eax, 2

    ret

;;************************************************************************************

Hexagon.Kernel.Dev.Gen.Console.Console.definirModoTexto:

    push eax

    mov ah, 0 ;; Função para definir modo de vídeo
    mov al, 3 ;; Vídeo em modo texto

    call Hexagon.Kernel.Arch.i386.BIOS.BIOS.int10h ;; Chamar interrupção BIOS de modo real

    mov ax, 1003h
    mov bx, 0

    call Hexagon.Kernel.Arch.i386.BIOS.BIOS.int10h ;; Desligar blinking

    mov byte[Hexagon.Video.modoGrafico], 0

    call Hexagon.Kernel.Dev.Gen.Console.Console.limparConsole

    pop eax

    ret

;;************************************************************************************

;; Colocar computador em modo gráfico
;;
;; Saída:
;;
;; ESI - Ponteiro para a memória de vídeo

Hexagon.Kernel.Dev.Gen.Console.Console.definirModoGrafico:

    push eax
    push ebx
    push ecx
    push edi

    mov ax, word[Hexagon.Video.modoVBE] ;; O padrão é 1024*768*24

    mov cx, ax ;; CX: modo de obter informações
    mov ax, 0x4F01 ;; Função para obter informações de vídeo
    mov di, Hexagon.Heap.VBE + 500h ;; Endereço onde são armazenados os dados

    call Hexagon.Kernel.Arch.i386.BIOS.BIOS.int10h ;; Chamar interrupção BIOS em modo real

    mov esi, dword[Hexagon.Heap.VBE+40] ;; Ponteiro para a base da memória de vídeo
    mov dword[Hexagon.Video.Memoria.enderecoLFB], esi

    or cx, 100000000000000b ;; Definir bit 14 para obter frame buffer linear

    mov bx, cx
    mov ax, 0x4F02 ;; Função para definir modo de vídeo

    call Hexagon.Kernel.Arch.i386.BIOS.BIOS.int10h ;; Chamar interrupção BIOS em modo real

    mov ax, word[Hexagon.Heap.VBE+16]
    mov word[Hexagon.Video.bytesPorLinha], ax

    mov al, byte[Hexagon.Heap.VBE+25] ;; Obter bits por pixel

    cmp al, 0
    jne .bitsPorPixelOK

    mov al, 24

.bitsPorPixelOK:

    mov byte[Hexagon.Video.bitsPorPixel], al ;; Salvar bits por pixel
    shr al, 3 ;; Divide por 8
    mov byte[Hexagon.Video.bytesPorPixel], al

    mov ax, word[Hexagon.Heap.VBE+18] ;; Obter resolução X

    cmp ax, 0
    jne .xResOK

    mov ax, 1024

.xResOK:

    mov word[Hexagon.Video.Resolucao.x], ax ;; Salvar resolução X

    mov ax, word[Hexagon.Heap.VBE+20] ;; Obter resolução Y

    cmp ax, 0
    jne .yResOK

    mov ax, 768

.yResOK:

    mov word[Hexagon.Video.Resolucao.y], ax ;; Salvar resolução Y

    movzx eax, word[Hexagon.Video.Resolucao.x]
    mov ebx, Hexagon.Fontes.largura

    xor edx, edx

    div ebx

    dec ax ;; Contando de 0

    mov word[Hexagon.Video.maxColunas], ax

    movzx eax, word[Hexagon.Video.Resolucao.y]
    mov ebx, Hexagon.Fontes.altura

    xor edx, edx

    div ebx

    dec ax ;; Contando de 0

    mov word[Hexagon.Video.maxLinhas], ax

    mov byte[Hexagon.Video.modoGrafico], 1

    mov eax, dword[Hexagon.Video.bytesPorLinha]
    movzx ebx, word[Hexagon.Video.Resolucao.y]

    mul ebx

    mov dword[Hexagon.Video.tamanhoVideo], eax

    mov eax, dword[Hexagon.Video.bytesPorLinha]
    mov ebx, Hexagon.Fontes.altura

    mul ebx

    mov dword[Hexagon.Graficos.bytesPorLinha], eax

    mov eax, [Hexagon.Video.Memoria.enderecoLFB]
    mov [Hexagon.Video.Memoria.bufferVideo1], eax ;; Salvar endereço original

    call Hexagon.Kernel.Dev.Gen.Console.Console.limparConsole

    pop edi
    pop ecx
    pop ebx
    pop eax

    ret

;;************************************************************************************

;; Obter informações de vídeo
;;
;; Saída:
;;
;; EAX - Resolução de X (bits 0-15), Y (bits 16-31)
;; EBX - Colunas (bits 0-7), Linhas (8-15), Bits por Pixel (16-23)
;; EDX - Endereço inicial do buffer
;; CF definido quando em modo de vídeo

Hexagon.Kernel.Dev.Gen.Console.Console.obterInfoVideo:

    cmp byte[Hexagon.Video.modoGrafico], 0
    je .modoTextoVideo

.modoGraficoVideo:

    push ecx

    mov bl, byte[Hexagon.Video.bitsPorPixel]
    shl ebx, 8

    mov bl, byte[Hexagon.Video.maxLinhas]

    inc bl ;; Contando de 1

    shl ebx, 8

    mov bl, byte[Hexagon.Video.maxColunas]

    inc bl ;; Contando de 1

    mov ax, word[Hexagon.Video.Resolucao.y]
    shl eax, 16
    mov ax, word[Hexagon.Video.Resolucao.x]

    mov edx, dword[Hexagon.Video.Memoria.enderecoLFB]

    pop ecx

    clc

    ret

.modoTextoVideo:

    mov bl, Hexagon.Video.modoTexto.maximoColunas+1
    mov bh, Hexagon.Video.modoTexto.maximoLinhas+1

    and ebx, 0xFFFF

    mov eax, 0
    mov edx, Hexagon.Video.modoTexto.memoriaDeVideo

    stc

    ret

;;************************************************************************************

;; Limpa a tela

Hexagon.Kernel.Dev.Gen.Console.Console.limparConsole:

    cmp byte[Hexagon.Video.modoGrafico], 1 ;; Checar modo gráfico
    je .graficos

.texto:

    xor edx, edx

    call Hexagon.Kernel.Dev.Gen.Console.Console.posicionarCursor

    mov edi, Hexagon.Video.modoTexto.memoriaDeVideo
    mov ecx, (Hexagon.Video.modoTexto.maximoLinhas+1) * (Hexagon.Video.modoTexto.maximoColunas+1)
    mov ah, byte[Hexagon.Video.modoTexto.corAtual] ;; Cor
    mov al, ' ' ;; Caractere para preencher a tela

    rep stosw ;; Realizar loop para preencher (limpar) a memória de vídeo

    jmp .fim

align 16

.graficos:

    mov ebx, Hexagon.Graficos.corFundoPadrao

    cmp dword[Hexagon.Graficos.corFundo], ebx
    je .sseLimpar

    mov esi, dword[Hexagon.Video.Memoria.enderecoLFB]

    mov eax, dword[Hexagon.Video.tamanhoVideo]
    mov ebx, dword[Hexagon.Video.bytesPorPixel]
    xor edx, edx

    div ebx

    mov ecx, eax

    mov ebx, dword[Hexagon.Video.bytesPorPixel]
    mov edx, dword[Hexagon.Graficos.corFundo]

.limparLoop:

    mov dword[gs:esi], edx

    add esi, ebx

    loop .limparLoop

    mov dx, 0

    call Hexagon.Kernel.Dev.Gen.Console.Console.posicionarCursor

    ret

.sseLimpar:

    mov edi, dword[Hexagon.Video.Memoria.enderecoLFB]

    movdqa xmm0, [.bytesLimpos]

    mov ecx, dword[Hexagon.Video.tamanhoVideo]
    shr ecx, 7

    push ds

    mov ax, 18h
    mov ds, ax

.loop:

    movdqa [edi+00], xmm0
    movdqa [edi+16], xmm0
    movdqa [edi+32], xmm0
    movdqa [edi+48], xmm0
    movdqa [edi+64], xmm0
    movdqa [edi+80], xmm0
    movdqa [edi+96], xmm0
    movdqa [edi+112], xmm0

    add edi, 128

    loop .loop

    pop ds

    mov dx, 0

    call Hexagon.Kernel.Dev.Gen.Console.Console.posicionarCursor

.fim:

    ret

align 16

.bytesLimpos: times 4 dd Hexagon.Graficos.corFundoPadrao

;;************************************************************************************

;; Limpar linha específica na tela
;;
;; Entrada:
;;
;; AL - Linha para limpar

Hexagon.Kernel.Dev.Gen.Console.Console.limparLinha:

    cmp byte[Hexagon.Video.modoGrafico], 1
    je .graficos

    push eax
    push ecx
    push edx
    push edi

    push es

    push 18h
    pop es

    mov dl, 0
    mov dh, al

    call Hexagon.Kernel.Dev.Gen.Console.Console.posicionarCursor

    movzx eax, al ;; Calcular posição
    mov ecx, 160

    xor edx, edx

    mul cx

    mov edi, Hexagon.Video.modoTexto.memoriaDeVideo
    add edi, eax

    shr ecx, 2 ;; Dividir ECX por 4

    mov ah, [Hexagon.Video.modoTexto.corAtual] ;; Cor
    mov al, ' '
    shl eax, 16
    mov ah, [Hexagon.Video.modoTexto.corAtual] ;; Cor
    mov al, ' '

    rep stosd

    pop es

    pop edi
    pop edx
    pop ecx
    pop eax

    ret

.graficos:

    push eax
    push ebx
    push ecx
    push edx
    push esi

    xor dl, dl
    mov dh, al

    call Hexagon.Kernel.Dev.Gen.Console.Console.posicionarCursor

    mov esi, dword[Hexagon.Video.Memoria.enderecoLFB]

    and eax, 0xFF
    mov ebx, Hexagon.Fontes.altura

    mul ebx

    mov ebx, dword[Hexagon.Video.bytesPorLinha]

    mul ebx

    add esi, eax

    movzx eax, word[Hexagon.Video.bytesPorLinha]
    mov ebx, Hexagon.Fontes.altura

    mul ebx

    mov ebx, dword[Hexagon.Video.bytesPorPixel]
    xor edx, edx

    div ebx

    mov ecx, eax

    mov ebx, dword[Hexagon.Video.bytesPorPixel]
    mov edx, dword[Hexagon.Graficos.corFundo]

.limparLoop:

    mov dword[gs:esi], edx
    add esi, ebx

    loop .limparLoop

    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax

    ret

;;************************************************************************************

;; Rolar a tela para baixo

Hexagon.Kernel.Dev.Gen.Console.Console.rolarParaBaixo:

    push eax
    push ecx
    push edx
    push esi
    push edi

    push ds
    push es

    cmp byte[Hexagon.Video.modoGrafico], 1
    je .graficos

.texto:

;; Mover todo o conteúdo da tela uma linha acima

    mov ax, 18h
    mov es, ax
    mov ds, ax

    mov esi, Hexagon.Video.modoTexto.memoriaDeVideo
    mov edi, Hexagon.Video.modoTexto.memoriaDeVideo-160 ;; Uma linha acima
    mov ecx, 2000

    rep movsw ;; Repetir ECX vezes (mov byte[ES:EDI], byte[DS:ESI])

    mov ax, 10h
    mov ds, ax

    mov eax, Hexagon.Video.modoTexto.maximoLinhas ;; Limpar última linha

    call Hexagon.Kernel.Dev.Gen.Console.Console.limparLinha

    jmp .fim

.graficos:

    mov esi, dword[Hexagon.Video.Memoria.enderecoLFB]

    mov edi, esi

    sub edi, dword[Hexagon.Graficos.bytesPorLinha]

    mov ecx, [Hexagon.Video.tamanhoVideo]
    shr ecx, 7 ;; Dividir por 128

    mov ax, 18h
    mov es, ax
    mov ds, ax

.copiar:

    prefetchnta [esi+0]
    prefetchnta [esi+32]
    prefetchnta [esi+64]
    prefetchnta [esi+96]

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

    loop .copiar

    mov ax, 10h
    mov ds, ax

    movzx eax, word[Hexagon.Video.maxLinhas]

    call Hexagon.Kernel.Dev.Gen.Console.Console.limparLinha

.fim:

    pop es
    pop ds

    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax

    ret

;;************************************************************************************

;; Central de solicitações de saída para dispositivos do sistema
;;
;; Entrada:
;;
;; EAX - Conteúdo numérico
;; EBX - Tipo de entrada, que pode ser:
;;       01 - Inteiro decimal
;;       02 - Inteiro hexadecimal
;;       03 - Inteiro binário
;;       04 - String
;; ESI - Ponteiro para a string à ser impressa

Hexagon.Kernel.Dev.Gen.Console.Console.imprimir:

    cmp ebx, 01h
    je Hexagon.Kernel.Dev.Gen.Console.Console.imprimirDecimal

    cmp ebx, 02h
    je Hexagon.Kernel.Dev.Gen.Console.Console.imprimirHexadecimal

    cmp ebx, 03h
    je Hexagon.Kernel.Dev.Gen.Console.Console.imprimirBinario

    cmp ebx, 04h
    je Hexagon.Kernel.Dev.Gen.Console.Console.imprimirString

    stc

    ret

;;************************************************************************************

;; Imprime um inteiro com decimal
;;
;; Entrada:
;;
;; EAX - Inteiro

Hexagon.Kernel.Dev.Gen.Console.Console.imprimirDecimal:

    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi

;; Checar se negativo

    cmp eax, 0
    jge .positivo

.nagativo:

    push eax

    mov al, '-' ;; Imprimir menos

    call Hexagon.Kernel.Dev.Gen.Console.Console.imprimirCaractere

    pop eax

    neg eax

.positivo:

;; Converter inteiro para string para poder imprimir

    mov ebx, 10  ;; Decimais estão na base 10
    xor ecx, ecx ;; mov ECX, 0

.loopConverter:

    xor edx, edx ;; mov EDX, 0

    div ebx

    add dl, 30h ;; Converter para ASCII

    push edx

    inc ecx

    or eax, eax ;; cmp EAX, 0
    jne .loopConverter

    mov edx, esi

.loopImprimir:

    pop eax

    call Hexagon.Kernel.Dev.Gen.Console.Console.imprimirCaractere

    loop .loopImprimir

.fim:

    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax

    ret

;;************************************************************************************

;; Imprimir um inteiro como binário
;;
;; Entrada:
;;
;; EAX - Inteiro

Hexagon.Kernel.Dev.Gen.Console.Console.imprimirBinario:

    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi

;; Checar por negativo

    cmp eax, 0
    jge .positivo

.nagativo:

    push eax

    mov al, '-' ;; Imprimir menos

    call Hexagon.Kernel.Dev.Gen.Console.Console.imprimirCaractere

    pop eax

    neg eax

.positivo:

;; Converter inteiro para string para que possa ser impresso

    mov ebx, 2   ;; Números em binário tem base 2
    xor ecx, ecx ;; mov ECX, 0

.loopConverter:

    xor edx, edx ;; mov EDX, 0

    div ebx

    add dl, 30h ;; Converter isso para ASCII

    push edx

    inc ecx

    or eax, eax ;; cmp EAX, 0
    jne .loopConverter

    mov edx, esi

.loopImprimir:

    pop eax

    call Hexagon.Kernel.Dev.Gen.Console.Console.imprimirCaractere

    loop .loopImprimir

.fim:

    mov al, 'b'

    call Hexagon.Kernel.Dev.Gen.Console.Console.imprimirCaractere

    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax

    ret

;;************************************************************************************

;; Imprimir um inteiro como hexadecimal
;;
;; Entrada:
;;
;; EAX - Inteiro

Hexagon.Kernel.Dev.Gen.Console.Console.imprimirHexadecimal:

    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi

;; Checar por negativo

    cmp eax, 0
    jge .positivo

.nagativo:

    push eax

    mov al, '-' ;; Imprimir negativo

    call Hexagon.Kernel.Dev.Gen.Console.Console.imprimirCaractere

    pop eax

    neg eax

.positivo:

    push eax

    mov al, '0'

    call Hexagon.Kernel.Dev.Gen.Console.Console.imprimirCaractere

    mov al, 'x'

    call Hexagon.Kernel.Dev.Gen.Console.Console.imprimirCaractere

    pop eax

;; Converter inteiro para hexadecimal

    mov ebx, 16  ;; Números hexadecimais tem base 16
    xor ecx, ecx ;; mov ECX, 0

.loopConverter:

    xor edx, edx ;; mov EDX, 0

    div ebx

    add dl, 30h

    cmp dl, 39h
    ja .adicionar

    jmp short .proximo

.adicionar:

    add dl, 7 ;; Converter isso para ASCII

.proximo:

    push edx

    inc ecx

    or eax, eax ;; cmp EAX, 0
    jne .loopConverter

    mov edx, esi

.loopImprimir:

    pop eax

    call Hexagon.Kernel.Dev.Gen.Console.Console.imprimirCaractere

    loop .loopImprimir

.fim:

    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax

    ret

;;************************************************************************************

;; Realiza a mesma função que Hexagon.Kernel.Dev.Gen.Console.Console.imprimirCaractere, mas não move o cursor
;;
;; Entrada:
;;
;; AL - Caractere

Hexagon.Kernel.Dev.Gen.Console.Console.imprimirCaractereBase:

    cmp byte[Hexagon.Video.modoGrafico], 1
    je Hexagon.Kernel.Dev.Gen.Console.Console.imprimirCaractere.graficos

    mov dl, byte[Hexagon.Video.modoTexto.cursor.X]
    mov dh, byte[Hexagon.Video.modoTexto.cursor.Y]

    cmp al, 10 ;; Caractere de nova linha
    je .novaLinha

    cmp al, 9
    je .tab

    cmp al, ' ' ;; Primeiro caractere imprimível
    jb .naoImprimivel

    cmp al, '~' ;; Último caractere imprimível
    ja .naoImprimivel

    jmp .proximo

.tab:

    mov al, ' '

    jmp .proximo

.novaLinha:

    inc dh

    mov dl, 0
    mov al, 0xFF

    jmp .proximo

.naoImprimivel:

    mov al, 0xFF

.proximo:

;; Consertar X e Y

    cmp dh, Hexagon.Video.modoTexto.maximoLinhas
    jna .yOK

    call Hexagon.Kernel.Dev.Gen.Console.Console.rolarParaBaixo

    mov dh, Hexagon.Video.modoTexto.maximoLinhas

.yOK:

    cmp dl, Hexagon.Video.modoTexto.maximoColunas
    jna .xOK

    mov dl, 0

    inc dh

.xOK:

    push edx
    push eax

;; Calcular posição do caractere na tela

    mov eax, 0
    mov al, dl
    shl ax, 1    ;; Multiplicar X por 2
    mov edi, eax ;; Adicionar isso ao índice
    mov al, (Hexagon.Video.modoTexto.maximoColunas+1)*2 ;; Contando de 1

    mul dh ;; Multiplica Y por maximoColunas*2

    add edi, eax ;; Adicionar isso ao índice

    pop eax

;; Colocar caractere

    pop edx

    cmp al, 0xFF
    je .caractereNaoImprimivel

    inc dl

    mov ah, byte[Hexagon.Video.modoTexto.corAtual]

;; Se o caractere já existe

    cmp word[gs:Hexagon.Video.modoTexto.memoriaDeVideo + edi], ax
    je .fim

    mov word[gs:Hexagon.Video.modoTexto.memoriaDeVideo + edi], ax

.caractereNaoImprimivel:

.fim:

;; Atualizar o cursor

    call Hexagon.Kernel.Dev.Gen.Console.Console.posicionarCursor

    ret

Hexagon.Kernel.Dev.Gen.Console.Console.imprimirCaractere.graficos:

    call Hexagon.Kernel.Dev.Gen.Console.Console.obterCursor

    cmp al, 9
    je .tab

    cmp al, 10
    je .retorno

    cmp al, '~'
    ja .naoImprimivel

    cmp al, ' '
    jl .naoImprimivel

    jmp .consertarXeY

.tab:

    mov al, ' '

    jmp .consertarXeY

.naoImprimivel:

    mov al, ' '

    jmp .consertarXeY

.retorno:

    movzx eax, word[Hexagon.Kernel.Dev.Gen.Console.Console.posicionarCursor.graficos.Xanterior]
    movzx ebx, word[Hexagon.Kernel.Dev.Gen.Console.Console.posicionarCursor.graficos.Yanterior]

    push edx

    mov ecx, Hexagon.Fontes.altura
    mov edx, [Hexagon.Kernel.Dev.Gen.Console.Console.posicionarCursor.graficos.corCursorAnterior]

.limparCursorAnterior:

    call Hexagon.Kernel.Lib.Graficos.colocarPixel

    inc ebx

    loop .limparCursorAnterior

    pop edx

    mov dl, 0

    inc dh

    mov al, 0 ;; Marcar como não imprimível

.consertarXeY:

    cmp dl, byte[Hexagon.Video.maxColunas]
    jna .yOK

    mov dl, 0

    inc dh

.yOK:

    cmp dh, byte[Hexagon.Video.maxLinhas]
    jna .xOK

    call Hexagon.Kernel.Dev.Gen.Console.Console.rolarParaBaixo

    mov dh, byte[Hexagon.Video.maxLinhas]
    mov dl, 0

.xOK:

    cmp al, 0
    je .proximo

.imprimivel:

    push edx

    call Hexagon.Kernel.Lib.Graficos.colocarCaractereBitmap

    pop edx

    inc dl

    jmp .proximo

.proximo:

    mov byte[Hexagon.Video.modoTexto.cursor.X], dl
    mov byte[Hexagon.Video.modoTexto.cursor.Y], dh

    ret

;;************************************************************************************

;; Escrever um caractere na posição do cursor
;;
;; Entrada:
;;
;; AL - Caractere
;; EBX - 01h para posicionar o cursor e diferente disso para não alterar a posição

Hexagon.Kernel.Dev.Gen.Console.Console.imprimirCaractere:

    pushad

    push ebx

    call Hexagon.Kernel.Dev.Gen.Console.Console.imprimirCaractereBase

    pop ebx

    cmp ebx, 01h
    je .alterarCursor

    jmp .fim

.alterarCursor:

    call Hexagon.Kernel.Dev.Gen.Console.Console.posicionarCursor

.fim:

    popad

    ret

;;************************************************************************************

;; Obter posição do cursor
;;
;; Saída:
;; DL - X
;; DH - Y

Hexagon.Kernel.Dev.Gen.Console.Console.obterCursor:

    mov dl, byte[Hexagon.Video.modoTexto.cursor.X]
    mov dh, byte[Hexagon.Video.modoTexto.cursor.Y]

    ret

;;************************************************************************************

;; Mover o cursor para a posição específica
;;
;; Entrada:
;;
;; DL - X
;; DH - Y

Hexagon.Kernel.Dev.Gen.Console.Console.posicionarCursor:

    cmp byte[Hexagon.Video.modoGrafico], 1
    je Hexagon.Kernel.Dev.Gen.Console.Console.posicionarCursor.graficos

    push eax
    push ebx
    push edx

    mov byte[Hexagon.Video.modoTexto.cursor.X], dl
    mov byte[Hexagon.Video.modoTexto.cursor.Y], dh

;; Consertar X e Y

    cmp dh, Hexagon.Video.modoTexto.maximoLinhas
    jna .yOK

    mov dh, Hexagon.Video.modoTexto.maximoLinhas

.yOK:

    cmp dl, Hexagon.Video.modoTexto.maximoColunas
    jna .xOK

    mov dl, Hexagon.Video.modoTexto.maximoColunas

.xOK:

;; Agora devemos multiplicar Y pelo total de colunas de X

    movzx eax, dh
    mov bl, Hexagon.Video.modoTexto.maximoColunas+1 ;; Contando de 1

    mul bl ;; Multiplicando Y pelas colunas

    movzx ebx, dl
    add eax, ebx ;; Adicionar X para isso

    mov ebx, eax

    mov al, 0x0F
    mov dx, 0x3D4

    out dx, al

;; Enviar byte menos significante para a porta VGA

    mov al, bl ;; BL é o byte menos significante
    mov dx, 0x3D5 ;; Porta VGA

    out dx, al

    mov al, 0x0E
    mov dx, 0x3D4

    out dx, ax

;; Enviar byte mais significante para a porta VGA

    mov al, bh ;; BH é o byte mais significante
    mov dx, 0x3D5 ;; Porta VGA

    out dx, al

    pop edx
    pop ebx
    pop eax

    ret

Hexagon.Kernel.Dev.Gen.Console.Console.posicionarCursor.graficos:

    push eax
    push ebx
    push ecx
    push edx

    mov byte[Hexagon.Video.modoTexto.cursor.X], dl
    mov byte[Hexagon.Video.modoTexto.cursor.Y], dh

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

    movzx eax, word[.Xanterior]
    movzx ebx, word[.Yanterior]

    mov ecx, Hexagon.Fontes.altura
    mov edx, [.corCursorAnterior]

.limparCursorAnterior:

    call Hexagon.Kernel.Lib.Graficos.colocarPixel

    inc ebx

    loop .limparCursorAnterior

    movzx eax, word[.x]
    movzx ebx, word[.y]

    mov word[.Xanterior], ax
    mov word[.Yanterior], bx

    mov edx, dword[Hexagon.Graficos.corFundo]
    mov dword[.corCursorAnterior], edx

    mov ecx, Hexagon.Fontes.altura
    mov edx, dword[Hexagon.Graficos.corFonte]

.desenharCursor:

    call Hexagon.Kernel.Lib.Graficos.colocarPixel

    inc ebx

    loop .desenharCursor

    pop edx
    pop ecx
    pop ebx
    pop eax

    ret

.Xanterior: dw 0
.Yanterior: dw 0
.corCursorAnterior: dd Hexagon.Graficos.corFundoPadrao
.x: dw 0
.y: dw 0

;;************************************************************************************

;; Imprimir uma string terminada em 0 na posição do cursor
;;
;; Entrada:
;;
;; ESI - String

Hexagon.Kernel.Dev.Gen.Console.Console.imprimirString:

    push esi
    push eax
    push ecx

;; Checar por nulo

    cmp byte[esi], 0
    je .fim

;; Obter tamanho da string

    call Hexagon.Kernel.Lib.String.tamanhoString

    mov ecx, eax

;; Escrever todos os caracteres

.imprimirStringLoop:

    lodsb ;; mov AL, byte[ESI] & inc ESI

    call Hexagon.Kernel.Dev.Gen.Console.Console.imprimirCaractere

    loop .imprimirStringLoop

.fim:

    pop ecx
    pop eax
    pop esi

    ret

;;************************************************************************************

;; Alterar o fundo do texto e a cor do primeiro plano
;;
;; Entrada:
;;
;; EAX - Cor da fonte (hex RGB)
;; EBX - Cor do plano de fundo (hex RGB)
;; ECX - 1234h para alterar o tema padrão com base no que foi inserido
;;
;; O modo texto tem de ser apenas preto e branco

Hexagon.Kernel.Dev.Gen.Console.Console.definirCorTexto:

    cmp byte[Hexagon.Video.modoGrafico], 1
    je .graficos

.modoTextoVideo:

    mov byte[Hexagon.Video.modoTexto.corAtual], Hexagon.Video.modoTexto.corPadrao

    ret

.graficos:

    mov dword[Hexagon.Graficos.corFonte], eax
    mov dword[Hexagon.Graficos.corFundo], ebx

    cmp ecx, 1234h
    je .definirTema

    jmp .fim

.definirTema:

    mov dword[Hexagon.Graficos.corFonteTema], eax
    mov dword[Hexagon.Graficos.corFundoTema], ebx

.fim:

    ret

;;************************************************************************************

;; Obter cor do fundo e primeiro plano
;;
;; Saída:
;;
;; EAX - Primeiro plano (hex RGB)
;; EBX - Plano de fundo (hex RGB)
;; ECX - Cor definida para a fonte segundo o tema escolhido
;; EDX - Cor definida para o plano de fundo de acordo com o tema

Hexagon.Kernel.Dev.Gen.Console.Console.obterCorTexto:

    cmp byte[Hexagon.Video.modoGrafico], 1
    je .graficos

.modoTextoVideo:

    mov al, Hexagon.Video.modoTexto.corPadrao

    ret

.graficos:

    mov eax, dword[Hexagon.Graficos.corFonte]
    mov ebx, dword[Hexagon.Graficos.corFundo]

    mov ecx, dword[Hexagon.Graficos.corFonteTema]
    mov edx, dword[Hexagon.Graficos.corFundoTema]

    ret

;;************************************************************************************

;; Altera a fonte utilizada para exibir informações na tela
;;
;; Entrada:
;;
;; ESI - Ponteiro para o buffer contendo o nome da fonte
;;
;; Saída:
;;
;; CF definido em caso de erro

Hexagon.Kernel.Dev.Gen.Console.Console.alterarFonte:

    call Hexagon.Kernel.FS.VFS.arquivoExiste

    jc .erroFonte

    mov edi, Hexagon.Fontes.espacoFonte

    call Hexagon.Kernel.FS.VFS.carregarArquivo

    ret

.erroFonte:

    stc

    ret
