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

Hexagon.Keyboard.keyCodes: ;; Keycodes

.esc       = 01h
.backspace = 08h
.tab       = 15h
.enter     = 0x1C
.ctrl      = 0x1D
.shiftL    = 0x2A
.shiftR    = 0x36
.space     = 0x39
.capsLock  = 0x3A
.F1        = 0x3B
.F2        = 0x3C
.F3        = 0x3D
.F4        = 0x3E
.F5        = 0x3F
.F6        = 0x40
.F7        = 0x41
.F8        = 0x42
.F9        = 0x43
.F10       = 0x44
.home      = 0x47
.end       = 0x49
.leftKey   = 0x4B
.rightKey  = 0x4D
.delete    = 0x53
.print     = 0x54
.F11       = 0x57
.F12       = 0x58
.pause     = 0x5A
.insert    = 0x5B

;;************************************************************************************

;; Initialize the keyboard, configuring the LEDS, repetition rate and delay

Hexagon.Kernel.Dev.Gen.Keyboard.Keyboard.setupKeyboard:

    push eax

;; First we need to send commands and then configure the LEDs

    mov al, 0xED ;; 0xED is the command to configure LEDs

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.waitPS2Write

    out 60h, al ;; Send command

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.waitPS2Read

    in al, 60h

    mov al, 000b ;; 000 sets all LEDs to off

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.waitPS2Write

    out 60h, al ;; Send data

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.waitPS2Read

    in al, 60h

;; Set repetition rate and delay

    mov al, 0xF3 ;; 0xF3 is the command to adjust the repetition rate and delay

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.waitPS2Write

    out 60h, al ;; Send command

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.waitPS2Read

    in al, 60h

    mov al, 00000000b ;; 0 is always 0, 00 is for delay and 250 ms, 00000 is 30 hz repetition rate

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.waitPS2Write

    out 60h, al ;; Now send data

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.waitPS2Read

    in al, 60h

.end:

    pop eax

    ret

;;************************************************************************************

;; Get string from keyboard
;;
;; Input:
;;
;; AL  - Maximum string length to obtain
;; EBX - Echo of what was typed (1234h = without echo, <> 1234h = with echo)
;;
;; Output:
;;
;; ESI - String

Hexagon.Kernel.Dev.Gen.Keyboard.Keyboard.getString:

    push eax
    push ecx
    push edx

    push es

    mov dword[.echo], ebx

    mov byte[.string], 0
    mov byte[.currentCharacter], 0

    push ds ;; Kernel data segment
    pop es

    mov ecx, 0 ;; Character counter
    movzx ebx, al ;; Maximum characters

    call Hexagon.Kernel.Dev.Gen.Console.Console.getCursor

.getKey:

    call Hexagon.Kernel.Dev.Gen.Console.Console.positionCursor

    cmp dword[.echo], 1234h
    je .continue

.withEcho:

    mov esi, .string

    call Hexagon.Kernel.Dev.Gen.Console.Console.printString

    mov al, ' '

    call Hexagon.Kernel.Dev.Gen.Console.Console.printCharacter

.continue:

    push edx

    add dl, byte[.currentCharacter]

    cmp dword[.echo], 1234h
    je .withoutMoveCursor

    call Hexagon.Kernel.Dev.Gen.Console.Console.positionCursor

.withoutMoveCursor:

    pop edx

    call Hexagon.Kernel.Dev.Gen.Keyboard.Keyboard.waitKeyboard ;; Get character

    cmp ah, Hexagon.Keyboard.keyCodes.home ;; Code
    je .homeKey

    cmp ah, Hexagon.Keyboard.keyCodes.end
    je .endKey

    cmp ah, Hexagon.Keyboard.keyCodes.delete
    je .deleteKey

    cmp ah, Hexagon.Keyboard.keyCodes.leftKey
    je .leftKey

    cmp ah, Hexagon.Keyboard.keyCodes.rightKey
    je .rightKey

    cmp al, 10 ;; ASCII code
    je .end

    cmp al, Hexagon.Keyboard.keyCodes.backspace
    je .backspaceKey

    cmp al, ' '
    jb .getKey ;; Do not use this key

    cmp al, '~'
    ja .getKey ;; Do not use this key

    cmp cl, bl
    je .getKey

    push edx

    movzx esi, byte[.currentCharacter]

    add esi, .string

    mov edx, 0

    call Hexagon.Libkern.String.insertCharacterInString

    pop edx

    inc byte[.currentCharacter]

    inc cl

    jmp .getKey

.backspaceKey:

    cmp byte[.currentCharacter], 0 ;; Not allowed
    je .getKey

    dec byte[.currentCharacter]

    push ecx

    movzx esi, byte[.currentCharacter]

    add esi, .string

    mov eax, 0

    call Hexagon.Libkern.String.removeCharacterInString

    pop ecx

    dec cl

    jmp .getKey

.deleteKey:

    cmp byte[.currentCharacter], cl ;; Not allowed
    je .getKey

    push ecx

    movzx esi, byte[.currentCharacter]

    add esi, .string

    mov eax, 0

    call Hexagon.Libkern.String.removeCharacterInString

    pop ecx

    dec cl

    jmp .getKey

.homeKey:

    mov byte[.currentCharacter], 0

    jmp .getKey

.endKey:

    mov byte[.currentCharacter], cl

    jmp .getKey

.leftKey:

    cmp byte[.currentCharacter], 0 ;; Not allowed
    je .getKey

    dec byte[.currentCharacter]

    jmp .getKey

.rightKey:

    cmp byte[.currentCharacter], cl ;; Not allowed
    je .getKey

    inc byte[.currentCharacter]

    jmp .getKey

.end:

    and ecx, 0x0F
    mov esi, .string

    pop es

    pop edx
    pop ecx
    pop eax

    mov dword[.echo], 00h

    ret

.string: times 256 db 0 ;; Buffer to store characters
.currentCharacter: db 0
.echo: dd 0 ;; Registers whether or not the pressed key should be displayed (echo)

;;************************************************************************************

;; Get special key status
;;
;; Output:
;;
;; EAX - Key status
;;
;; Format:
;;
;; Bit 0: Control Key
;; Bit 1: Shift Key
;; Bit 2-31: Reserved

Hexagon.Kernel.Dev.Gen.Keyboard.Keyboard.getSpecialKeysStatus:

    mov eax, [keyStatus]

    ret

;;************************************************************************************

;; Changes the layout of the input device (keyboard)
;;
;; Input:
;;
;; ESI - Pointer to the buffer containing the name of the file containing the layout to be used
;;
;; Output:
;;
;; CF set in case of error

Hexagon.Kernel.Dev.Gen.Keyboard.Keyboard.changeLayout:

    call Hexagon.Kernel.FS.VFS.fileExists

    jc .layoutError

    mov edi, Hexagon.Keyboard.keyboardDefaultLayout

    call Hexagon.Kernel.FS.VFS.openFile

    ret

.layoutError:

    stc

    ret

;;************************************************************************************

;; Wait for keys on the keyboard
;;
;; Input:
;;
;; AL - ASCII Character
;; AH - Code

Hexagon.Kernel.Dev.Gen.Keyboard.Keyboard.waitKeyboard:

    push ebx

    sti

.keyLoop:

    mov al, byte[.currentCodesIndex]

    cmp byte[Hexagon.Kern.Services.keyboardHandler.scanCodes.index], al
    je .keyLoop

    mov ebx, Hexagon.Kern.Services.keyboardHandler.scanCodes

    add bl, byte[.currentCodesIndex]

    mov ah, byte[ebx]
    mov al, ah

    cmp byte[.currentCodesIndex], 31
    jl .incrementIndex

    mov byte[.currentCodesIndex], -1

.incrementIndex:

    inc byte[.currentCodesIndex]

    bt ax, 7
    jc .keyLoop

;; Check Shift

    cmp byte[Hexagon.Kern.Services.keyboardHandler.sinalShift], 1
    je .useShiftCharacters

    mov ebx, Hexagon.Keyboard.keyboardDefaultLayout.keys ;; Scan code vector

    xlatb

    jmp .end

.useShiftCharacters:

    mov ebx, Hexagon.Keyboard.keyboardDefaultLayout.shiftKeys ;; Shift code vector

    xlatb

.end:

    pop ebx

    ret

.currentCodesIndex: db 0

;;************************************************************************************

Hexagon.Keyboard.keyboardDefaultLayout:

.keys:

    db 27, 0, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', 8, ' ', 'q', 'w', 'e'
    db 'r', 't', 'y', 'u', 'i', 'o', 'p', "'", '[', 10, 29, 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k'
    db 'l', 127, '~', "'", 42, ']', 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', ';', 0xFF, 0xFF
    db 0xFF, ' '

    db 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, '7', '8', '9'
    db '-', '4', '5', '6', '+', '1', '2', '3', '0', '.', 0xFF, 0xFF, '\', 0xFF, 0xFF, 0xFF, 0xFF
    db 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
    db 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, '/', 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
    db 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF

.shiftKeys:

    db 27, 0, '!', '@', '#', '$', '%', '?', '&', '*', '(', ')', '_', '+', 8, 9, 'Q', 'W', 'E', 'R'
    db 'T', 'Y', 'U', 'I', 'O', 'P', '`', '{', 10, 29, 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'
    db 127, '^', '"', 42, '}', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', '<', '>', ':', 0xFF, 0xFF, 0xFF
    db ' '

    db 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, '7', '8', '9'
    db '-', '4', '5', '6', '+', '1', '2', '3', '0', '.', 0xFF, 0xFF, '|', 0xFF, 0xFF, 0xFF, 0xFF
    db 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
    db 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, '?', 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
    db 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
