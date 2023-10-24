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

;; Variáveis onde os dados obtidos do CMOS serão armazenados

Hexagon.Arch.i386.CMOS:

.seculo    db 0
.ano       db 0
.mes       db 0
.dia       db 0
.hora      db 0
.minuto    db 0
.segundo   db 0
.diaSemana db 0

;;************************************************************************************

;; Essa função é solicitada pelo manipulador do timer a cada intervalo de tempo, mantendo
;; o relógio em tempo real do Hexagon atualizado.

Hexagon.Kernel.Arch.i386.CMOS.CMOS.atualizarDadosCMOS:

    push ax

    mov al, 00h ;; Obter o byte de segundos

    out 70h, al

    in al, 71h

    mov [Hexagon.Arch.i386.CMOS.segundo], al ;; Armazenar essa informação

    mov al, 02h ;; Obter o byte de minutos

    out 70h, al

    in al, 71h

    mov [Hexagon.Arch.i386.CMOS.minuto], al

    mov al, 04h ;; Obter o byte de horas

    out 70h, al

    in al, 71h

    mov [Hexagon.Arch.i386.CMOS.hora], al

    mov al, 06h ;; Obter o byte de dia da semana

    out 70h, al

    in al, 71h

    mov [Hexagon.Arch.i386.CMOS.diaSemana], al

    mov al, 07h ;; Obter o byte de dia

    out 70h, al

    in al, 71h

    mov [Hexagon.Arch.i386.CMOS.dia], al

    mov al, 08h ;; Obter o byte de mês

    out 70h, al

    in al, 71h

    mov [Hexagon.Arch.i386.CMOS.mes], al

    mov al, 09h ;; Obter o byte de ano

    out 70h, al

    in al, 71h

    mov [Hexagon.Arch.i386.CMOS.ano], al

    mov al, 32h ;; Obter o byte de século

    out 70h, al

    in al, 71h

    mov [Hexagon.Arch.i386.CMOS.seculo], al

    pop ax

    ret

;;************************************************************************************

;; Chamado por instâncias do Hexagon para obtenção direta, independente de atualização
;; por timer. Função com nome mantido para garantir compatibilidade com o código fonte

Hexagon.Kernel.Arch.i386.CMOS.CMOS.obterDadosCMOS:

    call Hexagon.Kernel.Arch.i386.CMOS.CMOS.atualizarDadosCMOS

    ret

