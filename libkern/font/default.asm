;;*************************************************************************************************
;;
;; 88                                                                                88
;; 88                                                                                ""
;; 88
;; 88,dPPPba,   ,adPPPba, 8b,     ,d8 ,adPPPPba,  ,adPPPb,d8  ,adPPPba,  8b,dPPPba,  88 8b,     ,d8
;; 88P'    "88 a8P     88  `P8, ,8P'  ""     `P8 a8"    `P88 a8"     "8a 88P'   `"88 88  `P8, ,8P'
;; 88       88 8PP"""""""    )888(    ,adPPPPP88 8b       88 8b       d8 88       88 88    )888(
;; 88       88 "8b,   ,aa  ,d8" "8b,  88,    ,88 "8a,   ,d88 "8a,   ,a8" 88       88 88  ,d8" "8b,
;; 88       88  `"Pbbd8"' 8P'     `P8 `"8bbdP"P8  `"PbbdP"P8  `"PbbdP"'  88       88 88 8P'     `P8
;;                                               aa,    ,88
;;                                                "P8bbdP"
;;
;;                     Sistema Operacional Hexagonix - Hexagonix Operating System
;;
;;                         Copyright (c) 2015-2025 Felipe Miguel Nery Lunkes
;;                        Todos os direitos reservados - All rights reserved.
;;
;;*************************************************************************************************
;;
;; Português:
;;
;; O Hexagonix e seus componentes são licenciados sob licença BSD-3-Clause. Leia abaixo
;; a licença que governa este arquivo e verifique a licença de cada repositório para
;; obter mais informações sobre seus direitos e obrigações ao utilizar e reutilizar
;; o código deste ou de outros arquivos.
;;
;; English:
;;
;; Hexagonix and its components are licensed under a BSD-3-Clause license. Read below
;; the license that governs this file and check each repository's license for
;; obtain more information about your rights and obligations when using and reusing
;; the code of this or other files.
;;
;;*************************************************************************************************
;;
;; BSD 3-Clause License
;;
;; Copyright (c) 2015-2025, Felipe Miguel Nery Lunkes
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

;; Version 1.5.2
;; Last update: 03/05/2025

;;************************************************************************************
;;
;; Aurora font for Hexagonix Operating System
;;
;;************************************************************************************

header: db "HFNT"

.space:        ;; Space

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.exclamationMark: ;; !

    db 00000000b
    db 00000000b

    db 00001000b
    db 00001000b
    db 00001000b
    db 00001000b
    db 00001000b
    db 00001000b
    db 00000000b
    db 00000000b
    db 00001000b

    db 00001000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.quotationMarks: ;; " 

    db 00000000b
    db 00000000b

    db 00000000b
    db 00110110b
    db 00110110b
    db 00110110b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.hash: ;; #

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00100010b
    db 00100010b
    db 01111111b
    db 00100010b
    db 01111111b
    db 00100010b
    db 00100010b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.dollar: ;; $

    db 00000000b
    db 00000000b

    db 00010100b
    db 00111111b
    db 01010100b
    db 01010100b
    db 00111110b
    db 00010101b
    db 00010101b
    db 00111110b
    db 00010100b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.percent: ;; %

    db 00000000b
    db 00000000b

    db 00000000b
    db 01100010b
    db 01100010b
    db 00000100b
    db 00001000b
    db 00001000b
    db 00010011b
    db 00100011b
    db 00100000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.ampersand: ;; &

    db 00000000b
    db 00000000b

    db 10111100b
    db 01000010b
    db 00100001b
    db 00111110b
    db 01001000b
    db 10000100b
    db 10000010b
    db 01000010b
    db 01111111b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.apostrophe: ;; '

    db 00000000b
    db 00000000b

    db 00000000b
    db 00110000b
    db 00110000b
    db 00110000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.parentheses.Left: ;; (

    db 00000000b
    db 00000000b

    db 00000100b
    db 00001000b
    db 00010000b
    db 00100000b
    db 00100000b
    db 00100000b
    db 00010000b
    db 00001000b
    db 00000100b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.parentheses.Right: ;; )

    db 00000000b
    db 00000000b

    db 00100000b
    db 00010000b
    db 00001000b
    db 00000100b
    db 00000100b
    db 00000100b
    db 00001000b
    db 00010000b
    db 00100000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.asterisk: ;; *

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 01001001b
    db 00101010b
    db 01111111b
    db 00101010b
    db 01001001b
    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.plus: ;; +

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00001000b
    db 00001000b
    db 00111110b
    db 00001000b
    db 00001000b
    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.comma: ;; ,

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00001100b
    db 00001100b

    db 00011000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.minus: ;; -

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 01111110b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.dot: ;; .

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00001100b
    db 00001100b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.bar: ;; /

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000001b
    db 00000010b
    db 00000100b
    db 00001000b
    db 00010000b
    db 00100000b
    db 01000000b
    db 10000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

;; Numbers

.zero: ;; 0

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00111100b
    db 01100010b
    db 01010010b
    db 01001010b
    db 01000110b
    db 01000010b
    db 00111100b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.one: ;; 1

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00011100b
    db 00100100b
    db 00000100b
    db 00000100b
    db 00000100b
    db 00000100b
    db 00011111b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.two: ;; 2

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00111110b
    db 01000001b
    db 00000001b
    db 00111110b
    db 01000000b
    db 01000000b
    db 00111111b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.three: ;; 3

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 01111110b
    db 00000001b
    db 00000001b
    db 00111110b
    db 00000001b
    db 00000001b
    db 01111110b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.four: ;; 4

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000111b
    db 00001001b
    db 00010001b
    db 00111111b
    db 00000001b
    db 00000001b
    db 00000001b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.five: ;; 5

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00111110b
    db 01000000b
    db 01000000b
    db 00111110b
    db 00000001b
    db 00000001b
    db 01111110b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.six: ;; 6

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00111111b
    db 01000000b
    db 01000000b
    db 01111110b
    db 01000001b
    db 01000001b
    db 00111110b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.seven: ;; 7

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 01111111b
    db 00000001b
    db 00000010b
    db 00000100b
    db 00001000b
    db 00010000b
    db 00100000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.eight: ;; 8

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00111110b
    db 01000001b
    db 01000001b
    db 00111110b
    db 01000001b
    db 01000001b
    db 00111110b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.nine: ;; 9

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00111110b
    db 01000001b
    db 01000001b
    db 00111111b
    db 00000010b
    db 00000100b
    db 00001000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.colon: ;; :

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00011000b
    db 00011000b
    db 00000000b
    db 00000000b
    db 00011000b
    db 00011000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.semicolon: ;; ;

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00001100b
    db 00001100b
    db 00000000b
    db 00000000b
    db 00001100b
    db 00001100b

    db 00011000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.lessThan: ;; <

    db 00000000b
    db 00000000b

    db 00000001b
    db 00000010b
    db 00000100b
    db 00001000b
    db 00010000b
    db 00001000b
    db 00000100b
    db 00000010b
    db 00000001b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.equal: ;; =

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 01111110b
    db 00000000b
    db 01111110b
    db 00000000b
    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.greaterThan: ;; >

    db 00000000b
    db 00000000b

    db 01000000b
    db 00100000b
    db 00010000b
    db 00001000b
    db 00000100b
    db 00001000b
    db 00010000b
    db 00100000b
    db 01000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.quationMark: ;; ?

    db 00000000b
    db 00000000b

    db 01111110b
    db 10000001b
    db 00000001b
    db 00000010b
    db 00001000b
    db 00001000b
    db 00000000b
    db 00000000b
    db 00001000b

    db 00001000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.atSign: ;; @

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00011100b
    db 00100010b
    db 01001111b
    db 01010001b
    db 01001110b
    db 00100000b
    db 00011110b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

;; Uppercase

.A:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00011000b
    db 00100100b
    db 01000010b
    db 01111110b
    db 01000010b
    db 01000010b
    db 01000010b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.B:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 01111110b
    db 01000001b
    db 01000001b
    db 01111110b
    db 01000001b
    db 01000001b
    db 01111110b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.C:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00111110b
    db 01000001b
    db 01000000b
    db 01000000b
    db 01000000b
    db 01000001b
    db 00111110b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.D:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 01111100b
    db 01000010b
    db 01000001b
    db 01000001b
    db 01000001b
    db 01000010b
    db 01111100b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.E:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00111111b
    db 01000000b
    db 01000000b
    db 01111100b
    db 01000000b
    db 01000000b
    db 00111111b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.F:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00111111b
    db 01000000b
    db 01000000b
    db 01111000b
    db 01000000b
    db 01000000b
    db 01000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.G:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00111111b
    db 01000000b
    db 01000000b
    db 01000110b
    db 01000001b
    db 01000001b
    db 00111110b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.H:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 01000001b
    db 01000001b
    db 01000001b
    db 01111101b
    db 01000001b
    db 01000001b
    db 01000001b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.I:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00111110b
    db 00001000b
    db 00001000b
    db 00001000b
    db 00001000b
    db 00001000b
    db 00111110b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.J:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00011111b
    db 00000010b
    db 00000010b
    db 00000010b
    db 00000010b
    db 01000100b
    db 00111000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.K:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 01000100b
    db 01001000b
    db 01110000b
    db 01110000b
    db 01001000b
    db 01000100b
    db 01000010b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.L:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 01000000b
    db 01000000b
    db 01000000b
    db 01000000b
    db 01000000b
    db 01000000b
    db 01111111b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.M:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 01100011b
    db 01010101b
    db 01001001b
    db 01000001b
    db 01000001b
    db 01000001b
    db 01000001b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.N:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 01000001b
    db 01100001b
    db 01010001b
    db 01001001b
    db 01000101b
    db 01000011b
    db 01000001b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.O:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00111110b
    db 01000001b
    db 01000001b
    db 01000001b
    db 01000001b
    db 01000001b
    db 00111110b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.P:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00111110b
    db 01000001b
    db 01000001b
    db 01111110b
    db 01000000b
    db 01000000b
    db 01000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.Q:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00111110b
    db 01000001b
    db 01000001b
    db 01000001b
    db 01000001b
    db 01010001b
    db 00111110b

    db 00000110b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.R:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00111110b
    db 01000001b
    db 01000001b
    db 01111110b
    db 01000100b
    db 01000010b
    db 01000001b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.S:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00111110b
    db 01000001b
    db 01000000b
    db 00111110b
    db 00000001b
    db 01000001b
    db 00111110b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.T:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 01111111b
    db 00001000b
    db 00001000b
    db 00001000b
    db 00001000b
    db 00001000b
    db 00001000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.U:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 01000001b
    db 01000001b
    db 01000001b
    db 01000001b
    db 01000001b
    db 00100010b
    db 00011100b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.V:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00100001b
    db 00100001b
    db 00100001b
    db 00100001b
    db 00100010b
    db 00010100b
    db 00001000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.W:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 01000001b
    db 01000001b
    db 01000001b
    db 01001001b
    db 01010101b
    db 01100011b
    db 01000001b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.X:
    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 01000001b
    db 00100010b
    db 00010100b
    db 00001000b
    db 00010100b
    db 00100010b
    db 01000001b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.Y:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 01000010b
    db 01000010b
    db 00100100b
    db 00011000b
    db 00010000b
    db 00010000b
    db 00010000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.Z:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 01111111b
    db 00000010b
    db 00000100b
    db 00001000b
    db 00010000b
    db 00100000b
    db 01111110b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.bracket.Left: ;; [

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 01111000b
    db 01000000b
    db 01000000b
    db 01000000b
    db 01000000b
    db 01000000b
    db 01111000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.backslash: ;; \

    db 00000000b
    db 00000000b

    db 00000000b
    db 0000000b
    db 10000000b
    db 01000000b
    db 00100000b
    db 00010000b
    db 00001000b
    db 00000100b
    db 00000010b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.bracket.Right: ;; ]

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00011110b
    db 00000010b
    db 00000010b
    db 00000010b
    db 00000010b
    db 00000010b
    db 00011110b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.circumflex: ;; ^

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00011000b
    db 00100100b
    db 01000010b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.underscore: ;; _

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

    db 01111110b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.graveAccent: ;; '

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 01100000b
    db 00011000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

;; Lowercase

.a:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00111110b
    db 00000001b
    db 00111111b
    db 01000001b
    db 01000001b
    db 00111110b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.b:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 01000000b
    db 01111110b
    db 01000001b
    db 01000001b
    db 01000001b
    db 00111110b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.c:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00111110b
    db 01000001b
    db 01000000b
    db 01000000b
    db 01000001b
    db 00111110b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.d:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000001b
    db 00111111b
    db 01000001b
    db 01000001b
    db 01000001b
    db 00111110b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.e:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00111100b
    db 01000010b
    db 01000010b
    db 01111100b
    db 01000000b
    db 00111110b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.f:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00001111b
    db 00010000b
    db 00010000b
    db 00111100b
    db 00010000b
    db 00010000b

    db 00010000b
    db 01100000b
    db 00000000b
    db 00000000b
    db 00000000b

.g:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00111110b
    db 01000001b
    db 01000001b
    db 01000001b
    db 00111111b
    db 00000001b

    db 00000001b
    db 00011110b
    db 00000000b
    db 00000000b
    db 00000000b

.h:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 01000000b
    db 01000000b
    db 01111100b
    db 01000010b
    db 01000010b
    db 01000010b
    db 01000010b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.i:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00001100b
    db 00000000b
    db 00011000b
    db 00000100b
    db 00000100b
    db 00000100b
    db 00000100b
    db 00011111b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.j:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00011000b
    db 00000000b
    db 00111000b
    db 00000100b
    db 00000100b
    db 00000100b
    db 00000100b
    db 00000100b

    db 00000100b
    db 00011000b
    db 00000000b
    db 00000000b
    db 00000000b

.k:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 01000000b
    db 01000100b
    db 01001000b
    db 01110000b
    db 01001000b
    db 01000110b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.l:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 01100000b
    db 00010000b
    db 00010000b
    db 00010000b
    db 00010000b
    db 00001111b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.m:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 01110111b
    db 01001001b
    db 01001001b
    db 01001001b
    db 01001001b
    db 01001001b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.n:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 01111110b
    db 01000001b
    db 01000001b
    db 01000001b
    db 01000001b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.o:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00111110b
    db 01000001b
    db 01000001b
    db 01000001b
    db 01000001b
    db 00111110b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.p:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00111110b
    db 01000001b
    db 01000001b
    db 01000010b
    db 01111100b

    db 01000000b
    db 01000000b
    db 00000000b
    db 00000000b
    db 00000000b

.q:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00111110b
    db 01000001b
    db 01000001b
    db 01000001b
    db 00111111b

    db 00000001b
    db 00000001b
    db 00000000b
    db 00000000b
    db 00000000b

.r:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 01011100b
    db 01100000b
    db 01000000b
    db 01000000b
    db 01000000b
    db 01000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.s:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00111111b
    db 01000000b
    db 01111110b
    db 00000001b
    db 00000001b
    db 01111110b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.t:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00100000b
    db 00100000b
    db 01110000b
    db 00100000b
    db 00100000b
    db 00011111b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.u:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 01000001b
    db 01000001b
    db 01000001b
    db 01000001b
    db 00111110b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.v:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 01000001b
    db 01000001b
    db 01000001b
    db 00100010b
    db 00010100b
    db 00001000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.w:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 01000001b
    db 01000001b
    db 01001001b
    db 01010101b
    db 01100011b
    db 01000001b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.x:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 01000010b
    db 00100100b
    db 00011000b
    db 00011000b
    db 00100100b
    db 01000010b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.y:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 01000010b
    db 01000010b
    db 01000010b
    db 01000010b
    db 00111110b

    db 00000010b
    db 00000010b
    db 00100010b
    db 00011100b
    db 00000000b

.z:

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00111111b
    db 00000010b
    db 00000100b
    db 00001000b
    db 00010000b
    db 00111111b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.brace.Left: ;; {

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000011b
    db 00001100b
    db 00110000b
    db 11000000b
    db 00110000b
    db 00001100b
    db 00000011b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.pipe: ;; |

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00001000b
    db 00001000b
    db 00001000b
    db 00001000b
    db 00001000b
    db 00001000b
    db 00001000b

    db 00001000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.brace.Right: ;; }

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 11000000b
    db 00110000b
    db 00001100b
    db 00000011b
    db 00001100b
    db 00110000b
    db 11000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

.tilde: ;; ~

    db 00000000b
    db 00000000b

    db 00000000b
    db 00000010b
    db 00111100b
    db 01000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b

    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
    db 00000000b
