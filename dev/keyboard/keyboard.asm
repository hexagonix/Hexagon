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
;;                 Copyright (c) 2015-2026 Felipe Miguel Nery Lunkes
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
;; Copyright (c) 2015-2026, Felipe Miguel Nery Lunkes
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
.c         = 0x2E
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
.end       = 0x4F
.upKey     = 0x48
.leftKey   = 0x4B
.rightKey  = 0x4D
.downKey   = 0x50
.delete    = 0x53
.print     = 0x54
.F11       = 0x57
.F12       = 0x58
.pause     = 0x5A
.insert    = 0x5B

;;************************************************************************************

;; Initialize the keyboard, configuring the LEDS, repetition rate and delay

Hexagon.Kernel.Dev.Keyboard.Keyboard.setupKeyboard:

    push eax

;; First we need to send commands and then configure the LEDs

    mov al, 0xED ;; 0xED is the command to configure LEDs

    call Hexagon.Kernel.Dev.PS2.PS2.waitPS2Write

    out 60h, al ;; Send command

    call Hexagon.Kernel.Dev.PS2.PS2.waitPS2Read

    in al, 60h

    mov al, 000b ;; 000 sets all LEDs to off

    call Hexagon.Kernel.Dev.PS2.PS2.waitPS2Write

    out 60h, al ;; Send data

    call Hexagon.Kernel.Dev.PS2.PS2.waitPS2Read

    in al, 60h

;; Set repetition rate and delay

    mov al, 0xF3 ;; 0xF3 is the command to adjust the repetition rate and delay

    call Hexagon.Kernel.Dev.PS2.PS2.waitPS2Write

    out 60h, al ;; Send command

    call Hexagon.Kernel.Dev.PS2.PS2.waitPS2Read

    in al, 60h

    mov al, 00000000b ;; 0 is always 0, 00 is for delay and 250 ms, 00000 is 30 hz repetition rate

    call Hexagon.Kernel.Dev.PS2.PS2.waitPS2Write

    out 60h, al ;; Now send data

    call Hexagon.Kernel.Dev.PS2.PS2.waitPS2Read

    in al, 60h

.end:

    pop eax

    ret

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

Hexagon.Kernel.Dev.Keyboard.Keyboard.getSpecialKeysStatus:

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

Hexagon.Kernel.Dev.Keyboard.Keyboard.changeLayout:

    call Hexagon.Kernel.FS.VFS.fileExists

    jc .layoutError

    mov edi, Hexagon.Keyboard.keyboardDefaultLayout

    xor ecx, ecx ;; Load the whole layout, uncapped

    call Hexagon.Kernel.FS.VFS.openFile

    ret

.layoutError:

    stc

    ret

;;************************************************************************************

;; Wait for keys on the keyboard
;;
;; Output:
;;
;; AL - ASCII Character
;; AH - Code
;; CF set, with no key, when the read in progress may not wait

Hexagon.Kernel.Dev.Keyboard.Keyboard.waitKeyboard:

    push ebx
    push ecx
    push edx

    sti

;; Resolve this caller's slot and home VT once, not per spin, and claim that
;; VT's foreground when nobody holds it yet. A spawned process never goes
;; through the blocking foreground handoff in Hexagon.Kern.Proc.exec, so this
;; is what lets it read its own VT at all

    movzx ecx, byte[Hexagon.Scheduler.current]

    cmp ecx, 0xFF
    jne .knownCaller

    xor edx, edx ;; Kernel boot context has no slot, uses VT0

    jmp .haveCallerTTY

.knownCaller:

    mov edx, dword[Hexagon.Processes.Table.tty + ecx * 4]

.haveCallerTTY:

    cmp dword[Hexagon.Console.VT.foregroundSlot + edx * 4], 0xFFFFFFFF
    jne .keyLoop

    mov dword[Hexagon.Console.VT.foregroundSlot + edx * 4], ecx

.keyLoop:

    mov al, byte[.currentCodesIndex]

    cmp byte[Hexagon.Kern.Services.keyboardHandler.scanCodes.index], al
    je .noKey

;; A new scan code is sitting on the shared cursor, but it may only be
;; consumed by the foreground process of the currently active VT. An
;; unmatched caller just keeps spinning here, leaving the byte alone for
;; the real reader

    cmp edx, dword[Hexagon.Console.activeVT]
    jne .noKey

    cmp dword[Hexagon.Console.VT.foregroundSlot + edx * 4], ecx
    jne .noKey

;; Hexagon.Kern.Services.keyboardHandler tags every stored byte with the VT
;; that was on screen when it was captured, and that tag is trusted over the
;; check above, which a fast enough switch can slip past. A mismatched byte was
;; never meant for this caller and is dropped silently

;; The index is zero extended into a full register, and not added to
;; the low byte of an address, which wraps inside that byte and reads 256
;; bytes short of the array as soon as the two no longer share a page

    movzx ebx, byte[.currentCodesIndex]

    mov al, byte[ebx + Hexagon.Kern.Services.keyboardHandler.scanCodesVT]

    cmp al, dl

    jne .discardByte

    mov ah, byte[ebx + Hexagon.Kern.Services.keyboardHandler.scanCodes]
    mov al, ah

    cmp byte[.currentCodesIndex], 31
    jl .incrementIndex

    mov byte[.currentCodesIndex], -1

.incrementIndex:

    inc byte[.currentCodesIndex]

    jmp .haveByte

.discardByte:

    cmp byte[.currentCodesIndex], 31
    jl .discardIncrementIndex

    mov byte[.currentCodesIndex], -1

.discardIncrementIndex:

    inc byte[.currentCodesIndex]

    jmp .keyLoop

.haveByte:

;; The numpad divide key sends the same 35h as the regular one, distinguished
;; only by this E0 prefix, which is skipped here and not in the handler.
;; It has to be caught before the bit7 check below, since 0E0h already has
;; that bit set and would be dropped as a release code

    cmp al, 0E0h
    jne .notExtendedPrefix

    mov byte[.extendedPending], 1

    jmp .keyLoop

.notExtendedPrefix:

;; Kept for the tty, where an arrow and the keypad digit sharing its code are
;; told apart by this prefix alone

    mov bl, byte[.extendedPending]
    mov byte[.extendedKey + edx], bl

;; Clear the pending flag on this byte no matter what it turns out to be,
;; make or break code, so a release right after E0 (Numpad / being let go)
;; can't leave it stuck set for whatever key comes next

    cmp byte[.extendedPending], 0
    je .checkRelease

    mov byte[.extendedPending], 0

    cmp al, 35h
    jne .checkRelease

    add al, 40h ;; Numpad /, tell it apart from ; sharing this same code

.checkRelease:

    bt ax, 7
    jc .keyLoop

.lookup:

;; Check Shift

    cmp byte[Hexagon.Kern.Services.keyboardHandler.shiftKeyStatus], 1
    je .useShiftCharacters

    mov ebx, Hexagon.Keyboard.keyboardDefaultLayout.keys ;; Scan code vector

    xlatb

    jmp .end

.useShiftCharacters:

    mov ebx, Hexagon.Keyboard.keyboardDefaultLayout.shiftKeys ;; Shift code vector

    xlatb

.end:

    pop edx
    pop ecx
    pop ebx

    clc

    ret

;; Nothing for this caller yet

.noKey:

    call Hexagon.Kern.FD.mayWait

    jc .noWait

;; The processor goes to someone else until the next key, or a tick at most

    cmp ecx, 0xFF

    je .keyLoop

    push eax
    push ecx

    mov eax, Hexagon.Kern.Services.keyboardHandler.scanCodes
    mov ecx, 1

    call Hexagon.Kern.Sched.sleepOn

    pop ecx
    pop eax

    jmp .keyLoop

.noWait:

    pop edx
    pop ecx
    pop ebx

    ret

.currentCodesIndex: db 0
.extendedPending: db 0
.extendedKey: times Hexagon.Console.VT.count db 0 ;; Whether each VT's last key came after E0

;;************************************************************************************

Hexagon.Keyboard.keyboardDefaultLayout:

.keys:

    db 27, 0, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', 8, ' ', 'q', 'w', 'e'
    db 'r', 't', 'y', 'u', 'i', 'o', 'p', "'", '[', 10, 29, 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k'
    db 'l', 127, '~', "'", 42, ']', 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', ';', 0xFF, '*'
    db 0xFF, ' '

    db 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, '7', '8', '9'
    db '-', '4', '5', '6', '+', '1', '2', '3', '0', '.', 0xFF, 0xFF, '\', 0xFF, 0xFF, 0xFF, 0xFF
    db 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
    db 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, '/', 0xFF, '/', 0xFF, 0xFF, 0xFF ;; Last '/' is Numpad /, tagged 40h by keyboardHandler to tell it apart from the one above sharing 35h with ;
    db 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF

.shiftKeys:

    db 27, 0, '!', '@', '#', '$', '%', '?', '&', '*', '(', ')', '_', '+', 8, 9, 'Q', 'W', 'E', 'R'
    db 'T', 'Y', 'U', 'I', 'O', 'P', '`', '{', 10, 29, 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'
    db 127, '^', '"', 42, '}', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', '<', '>', ':', 0xFF, 0xFF, '*'
    db ' '

    db 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, '7', '8', '9'
    db '-', '4', '5', '6', '+', '1', '2', '3', '0', '.', 0xFF, 0xFF, '|', 0xFF, 0xFF, 0xFF, 0xFF
    db 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
    db 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, '?', 0xFF, '/', 0xFF, 0xFF, 0xFF ;; Numpad / stays '/' even shifted, like on real hardware
    db 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
