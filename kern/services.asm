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
;;                 Copyright (c) 2015-2025 Felipe Miguel Nery Lunkes
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

;;************************************************************************************
;;
;;                     This file is part of the Hexagon kernel
;;
;;************************************************************************************

use32

Hexagon.Kern.Services:

.hexagonInterrupt  = 80h ;; Hexagon services
.timerInterrupt    = 08h ;; Interrupt reserved for timer
.keyboardInterrupt = 09h ;; Interrupt reserved for keyboard
.mouseInterrupt    = 74h ;; Interrupt reserved for pointing device

;;************************************************************************************

;; Installs Hexagon interrupt service routines (ISR) and hardware interruptions

Hexagon.Kern.Services.installInterruptions:

;; Install IRQ handlers

    mov dword[kernelExecute], kernelExecutePermission

    mov esi, Hexagon.Kern.Services.timerHandler ;; IRQ 0
    mov eax, Hexagon.Kern.Services.timerInterrupt ;; Interrupt number

    call Hexagon.Kern.Services.installISR

    mov esi, Hexagon.Kern.Services.keyboardHandler ;; IRQ 1
    mov eax, Hexagon.Kern.Services.keyboardInterrupt ;; Interrupt number

    call Hexagon.Kern.Services.installISR

    mov esi, Hexagon.Kern.Services.PS2MouseHandler ;; IRQ 12
    mov eax, Hexagon.Kern.Services.mouseInterrupt ;; Interrupt number

    call Hexagon.Kern.Services.installISR

;; Install the Hexagon services handler

    mov esi, Hexagon.Kern.Syscall.hexagonHandler ;; Hexagon services
    mov eax, Hexagon.Kern.Services.hexagonInterrupt ;; Interrupt number

    call Hexagon.Kern.Services.installISR

    sti ;; Enable interrupts

    mov dword[kernelExecute], kernelExecuteDisabled

    ret ;; All done

;;************************************************************************************

;; IRQ 0 - Timer Handler

;; With each interruption of the timer, the counter will be increased.
;; This counter can be used to time input and output operations, as well as
;; cause delays in various system and user processes

Hexagon.Kern.Services.timerHandler:

    push eax

    push ds

    mov ax, 10h ;; Kernel data segment
    mov ds, ax

;; Update real-time clock every interval

    call Hexagon.Arch.i386.CMOS.CMOS.updateCMOSData

    inc dword[.timerCounter] ;; Increment the counter
    inc dword[.relativeCounter]

    mov al, 20h

    out 20h, al

    pop ds
    pop eax

    iret

.timerCounter:    dd 0 ;; This content is used
.relativeCounter: dd 0

;;************************************************************************************

;; Interrupt handlers

;; IRQ 1 - Keyboard interrupt

Hexagon.Kern.Services.keyboardHandler:

    push eax
    push ebx

    push ds

    mov ax, 10h ;; Kernel data segment
    mov ds, ax

    xor eax,eax

    in al, 60h

    cmp al, Hexagon.Keyboard.keyCodes.F1 ;; F1 key
    je .killCurrentProcess

;; Check if the Control key was pressed

    cmp al, Hexagon.Keyboard.keyCodes.ctrl
    je .controlKeyPressed

    cmp al, 29 + 128
    je .controlKeyReleased

;; Check if the Shift key was pressed

    cmp al, Hexagon.Keyboard.keyCodes.shiftR ;; Right shift key
    je .shiftKeyPressed

    cmp al, Hexagon.Keyboard.keyCodes.shiftL ;; Left shift key
    je .shiftKeyPressed

    cmp al, 54 + 128 ;; Right shift key released
    je .shiftKeyReleased

    cmp al, 42 + 128 ;; Left shift key released
    je .shiftKeyReleased

    jmp .anotherKey

.controlKeyPressed:

    or dword[keyStatus], 0x00000001

    jmp .doNotStore

.controlKeyReleased:

    and dword[keyStatus], 0xFFFFFFFE

    jmp .doNotStore

.shiftKeyPressed:

    or dword[keyStatus], 0x00000002

    mov byte[.shiftKeyStatus], 1 ;; Shift pressed

    jmp .doNotStore

.shiftKeyReleased:

    and dword[keyStatus], 0xFFFFFFFD

    mov byte[.shiftKeyStatus], 0

    jmp .doNotStore

.anotherKey:

    jmp .end

;;************************************************************************************

.killCurrentProcess:

    call Hexagon.Kern.Proc.kill

;;************************************************************************************

.end:

    mov ebx, .scanCodes
    add bl, byte[.scanCodes.index]

    mov byte[ebx], al

    cmp byte[.scanCodes.index], 31
    jl .incrementIndex

    mov byte[.scanCodes.index], -1

.incrementIndex:

    inc byte[.scanCodes.index]

.doNotStore:

    mov al, 20h

    out 20h, al

    pop ds

    pop ebx
    pop eax

    iret

.scanCodes:
times 32 db 0
.scanCodes.index: db 0
.shiftKeyStatus: db 0

;; Bit 0: Control key
;; Bit 1: Shift key
;; Bit 2-31: Reserved

keyStatus: dd 0

;;************************************************************************************

;; IRQ 12 - PS/2 Mouse Handler

Hexagon.Kern.Services.PS2MouseHandler:

    pusha

    cmp byte[.status], 0
    je .dataPackage

    cmp byte[.status], 1
    je .packageX

    cmp byte[.status], 2
    je .packageY

.dataPackage:

    in al, 60h

    mov byte[.data], al

    mov byte[.status], 1

    jmp .finish

.packageX:

    in al, 60h

    mov byte[.deltaX], al

    mov byte[.status], 2

    jmp .finish

.packageY:

    in al, 60h

    mov byte[.deltaY], al

    mov byte[.status], 0

    mov byte[.changed], 1

.end:

    movzx eax, byte[Hexagon.Kern.Services.PS2MouseHandler.deltaX] ;; DeltaX changed to X
    movzx ebx, byte[Hexagon.Kern.Services.PS2MouseHandler.deltaY] ;; DeltaY changed to Y
    mov dl, byte[Hexagon.Kern.Services.PS2MouseHandler.data]

    bt dx, 4 ;; Check if the mouse has moved to the left
    jnc .movementToTheRight

    xor eax, 0xFF ;; 255 - deltaX
    sub word[.mouseX], ax ;; MouseX - DeltaX

    jnc .xOK ;; Check if MouseX is less than 0
    mov word[.mouseX], 0 ;; Fix MouseX

    jmp .xOK

.movementToTheRight:

    add word[.mouseX], ax ;; MouseX + DeltaX

.xOK:

    bt dx, 5 ;; Check if the mouse has moved down
    jnc .upMovement

    xor ebx, 0xFF ;; 255 - DeltaY
    sub word[.mouseY], bx ;; MouseY - DeltaY

    jnc .yOK ;; Check if MouseY is less than 0
    mov word[.mouseY], 0 ;; Fix MouseY

    jmp .yOK

.upMovement:

    add word[.mouseY], bx ;; MouseY + DeltaY

.yOK:

    movzx eax, word[.mouseX]
    movzx ebx, word[.mouseY]

;; Make sure that X and Y are not greater than the video resolution

    cmp ax, word[Hexagon.Console.Resolution.x]
    jng .xNotGreater

    mov ax, word[Hexagon.Console.Resolution.x]
    mov word[.mouseX], ax

.xNotGreater:

    cmp bx, word[Hexagon.Console.Resolution.y]
    jng .yNotGreater

    mov bx, word[Hexagon.Console.Resolution.y]
    mov word[.mouseY], bx

.yNotGreater:

    push edx

    movzx edx, word[Hexagon.Console.Resolution.y]
    sub dx, word[.mouseY]
    mov ebx, edx

    pop edx

    mov dword[Hexagon.Kernel.Dev.Gen.Mouse.mouseX], eax
    mov dword[Hexagon.Kernel.Dev.Gen.Mouse.mouseY], ebx

.finish:

    mov al, 20h ;; End of interruption handling

    out 20h, al
    out 0xA0, al

    popa

    iret

.status:   db 0
.deltaX:   db 0
.deltaY:   db 0
.data:     db 0
.changed:  db 0

align 32

.mouseStatus: dd 0
.mouseX:      dd 0
.mouseY:      dd 0

;;************************************************************************************

;; Specialized handler for touchpads - IRQ 12

Hexagon.Kern.Services.touchpadHandler:

    push eax
    push edx

    cmp byte[.status], 0
    je .package0

    cmp byte[.status], 1
    je .package1

    cmp byte[.status], 2
    je .package2

    cmp byte[.status], 3
    je .package3

    cmp byte[.status], 4
    je .package4

    cmp byte[.status], 5
    je .package5

.package0:

    mov al, 0

    call Hexagon.Kernel.Dev.Gen.Console.Console.clearRow

    in al, 60h

    movzx eax, al
    mov dl, 0
    mov dh, 0

    call Hexagon.Kernel.Dev.Gen.Console.Console.printBinary

    mov byte[.status], 1

    jmp .end

.package1:

    mov al, 1

    call Hexagon.Kernel.Dev.Gen.Console.Console.clearRow

    in al, 60h

    mov bl, al

    and al, 1111b

    movzx eax, al

    shl eax, 8

    mov word[.X], ax

    mov al, bl

    and al, 11110000b

    movzx eax, al

    shl eax, 4

    mov word[.Y], ax

    mov al, bl
    movzx eax, al
    mov dl, 0
    mov dh, 1

    call Hexagon.Kernel.Dev.Gen.Console.Console.printBinary

    mov byte[.status], 2

    jmp .end

.package2:

    mov al, 2

    call Hexagon.Kernel.Dev.Gen.Console.Console.clearRow

    in al, 60h

    movzx eax, al
    mov dl, 0
    mov dh, 2

    call Hexagon.Kernel.Dev.Gen.Console.Console.printDecimal

    mov byte[.status], 3

    jmp .end

.package3:

    mov al, 3

    call Hexagon.Kernel.Dev.Gen.Console.Console.clearRow

    in al, 60h

    mov bl, al

    movzx eax, al

    and eax, 00010000b

    shl eax, 8

    or word[.X], ax

    mov al, bl

    movzx eax, al

    and eax, 00100000b

    shl eax, 7

    or word[.Y], ax

    mov al, bl

    movzx eax, al
    mov dl, 0
    mov dh, 3

    call Hexagon.Kernel.Dev.Gen.Console.Console.printBinary

    mov byte[.status], 4

    jmp .end

.package4:

    mov al, 4

    call Hexagon.Kernel.Dev.Gen.Console.Console.clearRow

    in al, 60h

    movzx ax, al

    or word[.X], ax

    movzx eax, word[.X]

;; sub EAX, 1000

    mov dl, 0
    mov dh, 4

    call Hexagon.Kernel.Dev.Gen.Console.Console.printDecimal

    mov byte[.status], 5

    jmp .end

.package5:

    mov al, 5

    call Hexagon.Kernel.Dev.Gen.Console.Console.clearRow

    in al, 60h

    movzx ax, al
    or word[.Y], ax

    movzx eax, word[.Y]

;; sub EAX, 1000

    mov dl, 0
    mov dh, 5

    call Hexagon.Kernel.Dev.Gen.Console.Console.printDecimal

    mov byte[.status], 0

    jmp .end

.end:

    mov al, 20h ;; End of interrupt handling

    out 20h, al

    out 20h, al

    pop edx
    pop eax

    iret

.status: db 0
.X:      dw 0
.Y:      dw 0
.Z:      db 0

;;************************************************************************************

;; Handler for other interrupts, when they are not available

Hexagon.Kern.Services.nullHandler:

    push eax

    mov al, 20h

    out 20h, al

    pop eax

    iret

;;************************************************************************************

;; Installs an interrupt handler or IRQ handler
;;
;; Input:
;;
;; EAX - Interrupt number
;; ESI - Interrupt routine

Hexagon.Kern.Services.installISR:

    push eax
    push ebp

;; First, let's check if the interrupt installation request came from Hexagon,
;; observing the variable that records these privileged requests

    cmp dword[kernelExecute], kernelExecutePermission ;; If yes, skip check and install
    je .install

;; If the request came from the user or application, check whether the values ​​passed could
;; overwrite the interrupts previously installed by Hexagon

    cmp eax, Hexagon.Kern.Services.hexagonInterrupt ;; Attempt to replace Hexagon call
    je .deny ;; Deny installation

    cmp eax, Hexagon.Kern.Services.timerInterrupt ;; Attempt to change timer interrupt
    je .deny ;; Deny installation

    cmp eax, Hexagon.Kern.Services.keyboardInterrupt ;; Attempting to change the keyboard interrupt
    je .deny ;; Deny installation

    cmp eax, Hexagon.Kern.Services.mouseInterrupt ;; Attempt to change mouse interrupt
    je .deny ;; Deny installation

.install:

    mov ebp, eax
    mov eax, esi

    mov word[IDT+ebp*8], ax
    shr eax, 16

    mov word[IDT+ebp*8+6], ax

    jmp .end

.deny:

    stc

    mov eax, 01h

.end:

    pop ebp
    pop eax

    ret
