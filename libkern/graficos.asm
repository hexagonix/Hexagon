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

use32

;;************************************************************************************

Hexagon.Graficos.Cores.Padrao:

.COR_FUNDO_PADRAO = 0x00000000
.COR_FONTE_PADRAO = 0xFFFFFFFF

Hexagon.Graficos:

.corFundoPadrao  = Hexagon.Graficos.Cores.Padrao.COR_FUNDO_PADRAO
.corFontePadrao  = Hexagon.Graficos.Cores.Padrao.COR_FONTE_PADRAO
.corFundo:       dd .corFundoPadrao
.corFonte:       dd .corFontePadrao
.bytesPorLinha:  dd 0
.corFonteTema:   dd 0
.corFundoTema:   dd 0

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

    push eax ;; X

    mov esi, dword[Hexagon.Video.Memoria.enderecoLFB] ;; Ponteiro para a memória de vídeo

    movzx eax, word[Hexagon.Video.bytesPorLinha]

    mul ebx ;; Y * bytes por linha

    add esi, eax

    pop eax ;; X

    movzx ebx, byte[Hexagon.Video.bytesPorPixel]

    mul ebx ;; X * Bytes por pixel

    add esi, eax ;; ESI é um ponteiro para a memória de vídeo

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

    and eax, 0xFF
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

.x:            dw 0
.y:            dw 0
.proximaLinha: dd 0

;;************************************************************************************

;; Usar buffer para armazenamento de mensagens e relatórios do kernel

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

    mov ax, 18h
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

Hexagon.Kernel.Lib.Graficos.desenharBlocoSyscall:

    sub esi, dword[Hexagon.Processos.BCP.tamanhoProcessos]
    add esi, 500h

    sub edi, dword[Hexagon.Processos.BCP.tamanhoProcessos]
    add edi, 500h

    call Hexagon.Kernel.Lib.Graficos.desenharBloco

    add esi, dword[Hexagon.Processos.BCP.tamanhoProcessos]
    sub esi, 500h

    add edi, dword[Hexagon.Processos.BCP.tamanhoProcessos]
    sub edi, 500h

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

    mov ecx, edi ;; Largura

.y:

    push ecx

    mov ecx, esi ;; Comprimento

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

    call Hexagon.Kernel.Dev.Gen.Console.Console.definirResolucao

    ret