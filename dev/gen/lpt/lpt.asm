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

;; Initializes the parallel port, using the given port number

Hexagon.Kernel.Dev.Gen.LPT.LPT.setupParallelPort:

    pusha

;; Reset port via control register (base+2)

    mov dx, word[Hexagon.Kernel.Dev.Gen.LPT.LPT.currentParallelPort]

    add dx, 2 ;; Control register (base+2)

    in al, dx

    mov al, 00001100b

;; Bit 2 - Reset port
;; Bit 3 - Select device
;; Bit 5 - Enable bidirectional port

    out dx, al ;; Send restart signal

    popa

    ret

;;************************************************************************************

;; Function that allows data to be sent to a parallel port

Hexagon.Kernel.Dev.Gen.LPT.LPT.sendViaParallelPort:

    lodsb ;; Load the next character to be sent

    or al, al ;; Compares the character with the end of the message
    jz .done ;; If equal to end, jump to .done

;; Calls function that will perform input and output

    call Hexagon.Kernel.Dev.Gen.LPT.LPT.send

    jc .parallelPortError

;; If it is not finished, return to the function and load the next character

    jmp Hexagon.Kernel.Dev.Gen.LPT.LPT.sendViaParallelPort

.done: ;; If it's over...

    ret

.parallelPortError:

    stc ;; Set Carry

    ret

;;************************************************************************************

;; Send data to the parallel port
;;
;; Input:
;;
;; AL - byte to send

Hexagon.Kernel.Dev.Gen.LPT.LPT.send:

    pusha

    push ax ;; Save the given byte in AL

;; Reset port via control register (base+2)

    mov dx, word[Hexagon.Kernel.Dev.Gen.LPT.LPT.currentParallelPort]

    add dx, 2 ;; Control register (base+2)

    in al, dx

    mov al, 00001100b

;; Bit 2 - Reset port
;; Bit 3 - Select device
;; Bit 5 - Enable bidirectional port

    out dx, al ;; Send restart signal

;; Send data to port via data logger (base+0)

    pop ax ;; Restore past data in AL

    mov dx, word[Hexagon.Kernel.Dev.Gen.LPT.LPT.currentParallelPort]

    out dx, al ;; Send data

;; Send signaling to control register (base+2), showing that data is available

    mov dx, word [Hexagon.Kernel.Dev.Gen.LPT.LPT.currentParallelPort]

    add dx, 2

    mov al, 1

;; Bit 0 - signal

    out dx, al ;; Send

    popa

    ret

;;************************************************************************************

Hexagon.Kernel.Dev.Gen.LPT.LPT:

.currentParallelPort dw 0 ;; Stores the device's input and output address
