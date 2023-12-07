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

    mov esi, dword[Hexagon.Console.Memoria.enderecoLFB] ;; Ponteiro para a memória de vídeo

    movzx eax, word[Hexagon.Console.bytesPorLinha]

    mul ebx ;; Y * bytes por linha

    add esi, eax

    pop eax ;; X

    movzx ebx, byte[Hexagon.Console.bytesPorPixel]

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
    mov ebx, dword[Hexagon.Console.bytesPorPixel]

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

    mov edx, dword[Hexagon.Console.corFundo]

    jmp .colocarLinha.proximo

.colocarPrimeiroPlano:

    mov edx, dword[Hexagon.Console.corFonte]

.colocarLinha.proximo:

    add esi, dword[Hexagon.Console.bytesPorPixel]

    mov word[gs:esi], dx
    shr edx, 8
    mov byte[gs:esi+2], dh

    shl al, 1

    loop .colocarLinha

    pop ecx

    add esi, dword[Hexagon.Console.bytesPorLinha]
    sub esi, dword[.proximaLinha]

    loop .colocarColuna

.fim:

    ret

.x:            dw 0
.y:            dw 0
.proximaLinha: dd 0

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

;; Corrigir endereço com a base do segmento (endereço físico = endereço + base do segmento)

    add esi, 500h

    sub edi, dword[Hexagon.Processos.BCP.tamanhoProcessos]

;; Corrigir endereço com a base do segmento (endereço físico = endereço + base do segmento)

    add edi, 500h

    call Hexagon.Kernel.Lib.Graficos.desenharBloco

    add esi, dword[Hexagon.Processos.BCP.tamanhoProcessos]

;; Corrigir endereço com a base do segmento (endereço físico = endereço + base do segmento)

    sub esi, 500h

    add edi, dword[Hexagon.Processos.BCP.tamanhoProcessos]

;; Corrigir endereço com a base do segmento (endereço físico = endereço + base do segmento)

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

    cmp byte[Hexagon.Console.modoGrafico], 1
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
