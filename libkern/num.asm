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
;;                 Copyright (c) 2015-2024 Felipe Miguel Nery Lunkes
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
;; Copyright (c) 2015-2024, Felipe Miguel Nery Lunkes
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
;;                     This file is part of the Hexagon kernel
;;
;;************************************************************************************

use32

;; Gerar número aleatório
;;
;; Entrada:
;;
;; EAX - Máximo
;;
;; Saída:
;;
;; EAX - Número gerado

Hexagon.Libkern.Num.obterAleatorio:

    mov ecx, eax

    mov eax, [.numeroAleatorio]

    push ecx

    movzx ecx, byte[Hexagon.Arch.i386.CMOS.hour]

    add eax, ecx

    movzx ecx, byte[Hexagon.Arch.i386.CMOS.minute]

    add eax, ecx

    movzx ecx, byte[Hexagon.Arch.i386.CMOS.second]

    add eax, ecx

    pop ecx

    mov ebx, 9FA3204Ah

    mul ebx

    add eax, 15EA5h

    mov [.numeroAleatorio], eax

    mov ebx, 10000h
    mov edx, 0

    div ebx

    mov ebx, ecx
    mov edx, 0

    div ebx

    mov eax, edx ;; Resto da divisão

    ret

.numeroAleatorio: dd 1

;;************************************************************************************

;; Alimentar o gerador de números aleatórios
;;
;; Entrada:
;;
;; EAX - Número

Hexagon.Libkern.Num.alimentarAleatorios:

    mov [Hexagon.Libkern.Num.obterAleatorio.numeroAleatorio], eax

    ret

;;************************************************************************************

;; Realiza a conversão de BCD para binário
;;
;; Entrada:
;;
;; AL - Valor em BCD
;;
;; Saída:
;;
;; AL - Valor em binário

Hexagon.Libkern.Num.BCDParaBinario:

    push ebx

    mov bl, al ;; BL = AL mod 16
    and bl, 0x0F

    shr al, 4 ;; AL = AL/16

    mov bh, 10

    mul bh ;; Multiplicar por 10

    add al, bl ;; Adicionar o produto a AL

    pop ebx

    ret
