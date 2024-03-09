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

Hexagon.Kernel.Dev.Gen.Mouse:

.mouseX: dd 0
.mouseY: dd 0

;;************************************************************************************

;; Initialize the PS/2 mouse

Hexagon.Kernel.Dev.Gen.Mouse.Mouse.setupMouse:

    push eax

;; Enable IRQ for the mouse

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.waitPS2Write ;; Wait if PS/2 is busy

    mov al, 20h ;; Get Compaq Status Bit

    out 64h, al ;; 64h is the state register

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.waitPS2Read

    in al, 60h

    or al, 2   ;; Set second bit to 1 to enable IRQ12
    mov bl, al ;; Save modified bit

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.waitPS2Write

    mov al, 60h ;; Set Compaq state byte

    out 64h, al

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.waitPS2Write

    mov al, bl ;; Send modified byte

    out 60h, al

;; Enable auxiliary device (mouse)

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.waitPS2Write

    mov al, 0xA8 ;; Enable auxiliary device

    out 64h, al

;; Use default settings

    mov al, 0xF6 ;; Set as dafault

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.sendPS2

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.waitPS2Read

    in al, 60h

;; Set resolution

    mov al, 0xE8

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.sendPS2

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.waitPS2Read

    in al, 60h

    mov al, 3 ;; 8 counts/mm

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.sendPS2

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.waitPS2Read

    in al, 60h

;; Enable packages

    mov al, 0xF4 ;; Enable packages

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.sendPS2

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.waitPS2Read

    in al, 60h

    mov ax, word[Hexagon.Console.Resolution.y]
    mov word[Hexagon.Int.PS2MouseHandler.mouseY], ax

    pop eax

    ret

;;************************************************************************************

;; Get current mouse position and button state
;;
;; Input:
;;
;; EAX - Mouse X Position
;; EBX - Mouse Y Position
;; EDX - Mouse buttons (bit #0 = left button, bit #1 = right button)

Hexagon.Kernel.Dev.Gen.Mouse.Mouse.getFromMouse:

    mov eax, [Hexagon.Kernel.Dev.Gen.Mouse.mouseX]
    mov ebx, [Hexagon.Kernel.Dev.Gen.Mouse.mouseY]
    mov edx, 0 ;; byte[manipuladorMousePS2.data]

    ret

;;************************************************************************************

;; Set new mouse position
;;
;; Input:
;;
;; EAX - Mouse X Position
;; EBX - Mouse Y Position

Hexagon.Kernel.Dev.Gen.Mouse.Mouse.setMouse:

    mov [Hexagon.Kernel.Dev.Gen.Mouse.mouseX], eax
    mov [Hexagon.Kernel.Dev.Gen.Mouse.mouseY], ebx
    mov byte[Hexagon.Int.PS2MouseHandler.data], 0

    ret

;;************************************************************************************

Hexagon.Kernel.Dev.Gen.Mouse.Mouse.setupTouchpad:

    push eax

    mov al, 0xF5 ;; Disable

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.sendPS2

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.waitPS2Read

    in al, 60h

    mov al, 0xE8

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.sendPS2

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.waitPS2Read

    in al, 60h

    mov al, 0x03

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.sendPS2

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.waitPS2Read

    in al, 60h

    mov al, 0xE8

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.sendPS2

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.waitPS2Read

    in al, 60h

    mov al, 0x00

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.sendPS2

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.waitPS2Read

    in al, 60h

    mov al, 0xE8

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.sendPS2

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.waitPS2Read

    in al, 60h

    mov al, 00h

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.sendPS2

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.waitPS2Read

    in al, 60h

    mov al, 0xE8

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.sendPS2

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.waitPS2Read

    in al, 60h

    mov al, 01h

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.sendPS2

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.waitPS2Read

    in al, 60h

    mov al, 0xF3

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.sendPS2

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.waitPS2Read

    in al, 60h

    mov al, 0x14

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.sendPS2

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.waitPS2Read

    in al, 60h

    mov al, 0xF4 ;; Enable

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.sendPS2

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.waitPS2Read

    in al, 60h

    mov esi, Hexagon.Int.touchpadHandler ;; IRQ 12
    mov eax, 74h ;; Interruption number

    call Hexagon.Int.installISR

    pop eax

    ret

;;************************************************************************************

;; Wait for mouse events and get their values
;;
;; Input:
;;
;; EAX - Mouse X Position
;; EBX - Mouse Y Position
;; EDX - Mouse Buttons (bit #0 = left button, bit #1 = right button)

Hexagon.Kernel.Dev.Gen.Mouse.Mouse.waitMouseEvent:

    sti

    mov byte[Hexagon.Int.PS2MouseHandler.changed], 0

.Wait:

;; Check if the mouse state has changed

    cmp byte[Hexagon.Int.PS2MouseHandler.changed], 1

    hlt

    jne .Wait

    mov eax, [Hexagon.Kernel.Dev.Gen.Mouse.mouseX]
    mov ebx, [Hexagon.Kernel.Dev.Gen.Mouse.mouseY]
    movzx edx, byte[Hexagon.Int.PS2MouseHandler.data]

    ret
