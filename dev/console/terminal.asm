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


;;************************************************************************************
;;
;; Hexagon console terminal
;;
;; Turns the bytes written to a tty into console output, interpreting the
;; subset of ANSI escape sequences listed below. An unknown sequence is consumed
;; whole and draws nothing
;;
;;************************************************************************************

use32

;; Recognized sequences, CSI being ESC [
;;
;; CSI n A/B/C/D      - Cursor up, down, forward, back, n defaulting to 1
;; CSI n G            - Cursor to column n of its row, counted from 1
;; CSI row ; col H/f  - Cursor position, counted from 1
;; CSI J, CSI 2 J     - Clear to the end of the screen, the whole screen
;; CSI K, 1 K, 2 K    - Clear to the end of the line, to its start, the whole line
;; CSI ... m          - 0, 7, 27, 30-37, 39, 40-47, 49, 90-97, 100-107, 38;2;r;g;b, 48;2;r;g;b
;; ESC 7, ESC 8       - Save the cursor, and put it back where it was saved

Hexagon.Console.Terminal.maxParams = 5

Hexagon.Console.Terminal.States.ground = 0
Hexagon.Console.Terminal.States.escape = 1
Hexagon.Console.Terminal.States.csi    = 2

Hexagon.Console.Terminal:

.state:   times Hexagon.Console.VT.count db 0
.private: times Hexagon.Console.VT.count db 0
.index:   times Hexagon.Console.VT.count db 0
.params:  times Hexagon.Console.VT.count * Hexagon.Console.Terminal.maxParams dd 0
.saved:   times Hexagon.Console.VT.count dw 0 ;; Column and row from ESC 7
.reverse: times Hexagon.Console.VT.count db 0 ;; Colors swapped by CSI 7 m

;; The 16 colors of CSI 30-37, 90-97 and their backgrounds

.palette:

dd 0x000000, 0xAA0000, 0x00AA00, 0xAA5500, 0x0000AA, 0xAA00AA, 0x00AAAA, 0xAAAAAA
dd 0x555555, 0xFF5555, 0x55FF55, 0xFFFF55, 0x5555FF, 0xFF55FF, 0x55FFFF, 0xFFFFFF

;;************************************************************************************

;; Input:
;;
;; EDX - VT
;; ESI - Bytes
;; ECX - How many

Hexagon.Kernel.Dev.Console.Terminal.write:

    pushad

    mov ebp, edx ;; VT, kept here since no console routine touches EBP

    xor edi, edi ;; Whether the caller's own draw target was set aside

    movzx ebx, byte[Hexagon.Scheduler.current]

    cmp ebx, 0xFF

    je .write

    cmp edx, dword[Hexagon.Processes.Table.tty + ebx * 4]

    je .write

;; Another process's VT. The caller draws on it until the end of this write,
;; its own target and the generation it was resolved at kept on the stack

    push dword[Hexagon.Processes.Table.addressLFB + ebx * 4]
    push dword[Hexagon.Processes.Table.addressLFBGeneration + ebx * 4]

    inc edx

    mov dword[Hexagon.Processes.Table.drawTTY + ebx * 4], edx

    call Hexagon.Kernel.Dev.Console.Console.useMainConsole
    call Hexagon.Kernel.Dev.Console.Console.ensureCurrentVT

    inc edi

.write:

    jecxz .done

.nextByte:

    lodsb

    call Hexagon.Kernel.Dev.Console.Terminal.putByte

    loop .nextByte

.done:

    cmp edi, 0

    je .end

    movzx ebx, byte[Hexagon.Scheduler.current]

    mov dword[Hexagon.Processes.Table.drawTTY + ebx * 4], 0

    pop dword[Hexagon.Processes.Table.addressLFBGeneration + ebx * 4]
    pop dword[Hexagon.Processes.Table.addressLFB + ebx * 4]

    call Hexagon.Kernel.Dev.Console.Console.ensureCurrentVT

.end:

    popad

    ret

;;************************************************************************************

;; Input:
;;
;; AL  - Byte
;; EBP - VT

Hexagon.Kernel.Dev.Console.Terminal.putByte:

    pushad

    cmp byte[Hexagon.Console.Terminal.state + ebp], Hexagon.Console.Terminal.States.escape

    je .escape

    cmp byte[Hexagon.Console.Terminal.state + ebp], Hexagon.Console.Terminal.States.csi

    je .csi

    cmp al, 27

    je .enterEscape

    cmp al, 13

    je .carriageReturn

    cmp al, 8

    je .backspace

    cmp al, 10

    je .print

    cmp al, 9

    je .print

    cmp al, ' '

    jb .end ;; Any other control character, BEL among them, draws nothing

    cmp al, 7Fh

    je .end

.print:

    xor ebx, ebx

    call Hexagon.Kernel.Dev.Console.Console.printCharacter

    jmp .end

.carriageReturn:

    call Hexagon.Kernel.Dev.Console.Console.getCursor

    mov dl, 0

    call Hexagon.Kernel.Dev.Console.Console.positionCursor

    jmp .end

.backspace:

    call Hexagon.Kernel.Dev.Console.Console.getCursor

    cmp dl, 0

    je .end

    dec dl

    call Hexagon.Kernel.Dev.Console.Console.positionCursor

    jmp .end

.enterEscape:

    mov byte[Hexagon.Console.Terminal.state + ebp], Hexagon.Console.Terminal.States.escape

    jmp .end

.escape:

    cmp al, '['

    je .enterCSI

    cmp al, '7'

    je .saveCursor

    cmp al, '8'

    je .restoreCursor

    cmp al, 20h

    jb .toGround

    cmp al, 2Fh

    jbe .end ;; Intermediate bytes, such as the ( of ESC ( B, wait for the final one

    jmp .toGround ;; Final byte, dropped with the whole sequence

.saveCursor:

    call Hexagon.Kernel.Dev.Console.Console.getCursor

    mov word[Hexagon.Console.Terminal.saved + ebp * 2], dx

    jmp .toGround

.restoreCursor:

    mov dx, word[Hexagon.Console.Terminal.saved + ebp * 2]

    call Hexagon.Kernel.Dev.Console.Console.positionCursor

    jmp .toGround

.enterCSI:

    mov byte[Hexagon.Console.Terminal.state + ebp], Hexagon.Console.Terminal.States.csi
    mov byte[Hexagon.Console.Terminal.private + ebp], 0
    mov byte[Hexagon.Console.Terminal.index + ebp], 0

    imul edi, ebp, Hexagon.Console.Terminal.maxParams * 4
    add edi, Hexagon.Console.Terminal.params

    mov ecx, Hexagon.Console.Terminal.maxParams

.clearParam:

    mov dword[edi], 0

    add edi, 4

    loop .clearParam

    jmp .end

.csi:

    cmp al, '0'

    jb .notDigit

    cmp al, '9'

    ja .notDigit

    movzx ebx, byte[Hexagon.Console.Terminal.index + ebp]

    cmp ebx, Hexagon.Console.Terminal.maxParams

    jae .end

    imul edi, ebp, Hexagon.Console.Terminal.maxParams * 4
    add edi, Hexagon.Console.Terminal.params

    sub al, '0'
    movzx eax, al

    mov ecx, dword[edi + ebx * 4]
    imul ecx, ecx, 10
    add ecx, eax

    cmp ecx, 0FFFFh

    jbe .storeParam

    mov ecx, 0FFFFh

.storeParam:

    mov dword[edi + ebx * 4], ecx

    jmp .end

.notDigit:

    cmp al, ';'

    jne .notSeparator

    cmp byte[Hexagon.Console.Terminal.index + ebp], Hexagon.Console.Terminal.maxParams

    jae .end

    inc byte[Hexagon.Console.Terminal.index + ebp]

    jmp .end

.notSeparator:

    cmp al, '<'

    jb .notPrivate

    cmp al, '?'

    ja .notPrivate

    mov byte[Hexagon.Console.Terminal.private + ebp], 1

    jmp .end

.notPrivate:

    cmp al, 40h

    jb .end ;; Intermediate bytes, ignored

    cmp al, 7Eh

    ja .toGround

    mov byte[Hexagon.Console.Terminal.state + ebp], Hexagon.Console.Terminal.States.ground

    cmp byte[Hexagon.Console.Terminal.private + ebp], 0

    jne .end ;; Private sequences, such as CSI ? 25 l, are not supported

    call Hexagon.Kernel.Dev.Console.Terminal.execute

    jmp .end

.toGround:

    mov byte[Hexagon.Console.Terminal.state + ebp], Hexagon.Console.Terminal.States.ground

.end:

    popad

    ret

;;************************************************************************************

;; Input:
;;
;; EBX - Parameter index
;; EBP - VT
;;
;; Output:
;;
;; EAX - Its value, 0 when it was left empty

Hexagon.Kernel.Dev.Console.Terminal.param:

    xor eax, eax

    cmp bl, byte[Hexagon.Console.Terminal.index + ebp]

    ja .end

    cmp ebx, Hexagon.Console.Terminal.maxParams

    jae .end

    push edi

    imul edi, ebp, Hexagon.Console.Terminal.maxParams * 4
    add edi, Hexagon.Console.Terminal.params

    mov eax, dword[edi + ebx * 4]

    pop edi

.end:

    ret

;;************************************************************************************

;; Runs a complete CSI sequence
;;
;; Input:
;;
;; AL  - Final byte
;; EBP - VT

Hexagon.Kernel.Dev.Console.Terminal.execute:

    cmp al, 'A'

    jb .end

    cmp al, 'D'

    jbe Hexagon.Kernel.Dev.Console.Terminal.moveCursor

    cmp al, 'G'

    je Hexagon.Kernel.Dev.Console.Terminal.setColumn

    cmp al, 'H'

    je Hexagon.Kernel.Dev.Console.Terminal.setCursor

    cmp al, 'f'

    je Hexagon.Kernel.Dev.Console.Terminal.setCursor

    cmp al, 'J'

    je Hexagon.Kernel.Dev.Console.Terminal.eraseScreen

    cmp al, 'K'

    je Hexagon.Kernel.Dev.Console.Terminal.eraseLine

    cmp al, 'm'

    je Hexagon.Kernel.Dev.Console.Terminal.setGraphics

.end:

    ret

;;************************************************************************************

;; CSI n A/B/C/D, stopping at the edges of the console

Hexagon.Kernel.Dev.Console.Terminal.moveCursor:

    mov cl, al

    xor ebx, ebx

    call Hexagon.Kernel.Dev.Console.Terminal.param

    cmp eax, 0

    jne .haveCount

    inc eax

.haveCount:

    push eax

    call Hexagon.Kernel.Dev.Console.Console.getCursor ;; DL = column, DH = row

    pop eax

    movzx esi, dl
    movzx edi, dh

    cmp cl, 'A'

    je .up

    cmp cl, 'B'

    je .down

    cmp cl, 'C'

    je .forward

    sub esi, eax

    jmp .clamp

.up:

    sub edi, eax

    jmp .clamp

.down:

    add edi, eax

    jmp .clamp

.forward:

    add esi, eax

.clamp:

    call Hexagon.Kernel.Dev.Console.Terminal.clampAndPosition

    ret

;;************************************************************************************

;; CSI row ; column H, both counted from 1

Hexagon.Kernel.Dev.Console.Terminal.setCursor:

    xor ebx, ebx

    call Hexagon.Kernel.Dev.Console.Terminal.param

    mov edi, eax

    inc ebx

    call Hexagon.Kernel.Dev.Console.Terminal.param

    mov esi, eax

    cmp edi, 0

    je .rowGiven

    dec edi

.rowGiven:

    cmp esi, 0

    je .columnGiven

    dec esi

.columnGiven:

    call Hexagon.Kernel.Dev.Console.Terminal.clampAndPosition

    ret

;;************************************************************************************

;; CSI n G, counted from 1, on the row the cursor is on

Hexagon.Kernel.Dev.Console.Terminal.setColumn:

    xor ebx, ebx

    call Hexagon.Kernel.Dev.Console.Terminal.param

    mov esi, eax

    cmp esi, 0

    je .columnGiven

    dec esi

.columnGiven:

    call Hexagon.Kernel.Dev.Console.Console.getCursor ;; DH = row

    movzx edi, dh

    call Hexagon.Kernel.Dev.Console.Terminal.clampAndPosition

    ret

;;************************************************************************************

;; Input:
;;
;; ESI - Column, signed
;; EDI - Row, signed

Hexagon.Kernel.Dev.Console.Terminal.clampAndPosition:

    cmp esi, 0

    jge .columnNotNegative

    xor esi, esi

.columnNotNegative:

    movzx eax, byte[Hexagon.Console.maxColumns]

    cmp esi, eax

    jle .columnInside

    mov esi, eax

.columnInside:

    cmp edi, 0

    jge .rowNotNegative

    xor edi, edi

.rowNotNegative:

    movzx eax, byte[Hexagon.Console.maxRows]

    cmp edi, eax

    jle .rowInside

    mov edi, eax

.rowInside:

    mov edx, esi
    mov eax, edi
    mov dh, al

    call Hexagon.Kernel.Dev.Console.Console.positionCursor

    ret

;;************************************************************************************

;; CSI J clears from the cursor to the end of the screen, CSI 2 J and 3 J the
;; whole screen. The cursor stays where it was

Hexagon.Kernel.Dev.Console.Terminal.eraseScreen:

    xor ebx, ebx

    call Hexagon.Kernel.Dev.Console.Terminal.param

    push eax

    call Hexagon.Kernel.Dev.Console.Console.getCursor

    pop eax

    push edx ;; The cursor, put back at the end

    cmp eax, 0

    je .toEnd

    cmp eax, 2

    jb .done

    call Hexagon.Kernel.Dev.Console.Console.clearConsole

    jmp .done

.toEnd:

    mov ecx, edx

    xor eax, eax ;; To the end of the line

    call Hexagon.Kernel.Dev.Console.Terminal.clearInLine

    movzx eax, ch

.nextRow:

    inc eax

    cmp al, byte[Hexagon.Console.maxRows]

    ja .done

    call Hexagon.Kernel.Dev.Console.Console.clearRow

    jmp .nextRow

.done:

    pop edx

    call Hexagon.Kernel.Dev.Console.Console.positionCursor

    ret

;;************************************************************************************

;; CSI K, 1 K and 2 K. The cursor stays where it was

Hexagon.Kernel.Dev.Console.Terminal.eraseLine:

    xor ebx, ebx

    call Hexagon.Kernel.Dev.Console.Terminal.param

    push eax

    call Hexagon.Kernel.Dev.Console.Console.getCursor

    pop eax

    push edx

    cmp eax, 2

    je .wholeLine

    ja .done

    mov ecx, edx

    call Hexagon.Kernel.Dev.Console.Terminal.clearInLine

    jmp .done

.wholeLine:

    mov al, dh

    call Hexagon.Kernel.Dev.Console.Console.clearRow

.done:

    pop edx

    call Hexagon.Kernel.Dev.Console.Console.positionCursor

    ret

;;************************************************************************************

;; Writes spaces over part of a row, leaving the cursor wherever they ended
;;
;; Input:
;;
;; EAX - 0 from the cursor to the end of the row, 1 from its start to the cursor
;; CL  - Cursor column
;; CH  - Cursor row

Hexagon.Kernel.Dev.Console.Terminal.clearInLine:

    pushad

    mov edx, ecx

    cmp eax, 0

    je .fromCursor

    movzx ecx, dl
    inc ecx

    mov dl, 0

    jmp .position

.fromCursor:

    movzx ecx, byte[Hexagon.Console.maxColumns]
    movzx eax, dl
    sub ecx, eax
    inc ecx

.position:

    call Hexagon.Kernel.Dev.Console.Console.positionCursor

    xor ebx, ebx

.space:

    mov al, ' '

    call Hexagon.Kernel.Dev.Console.Console.printCharacter

    loop .space

    popad

    ret

;;************************************************************************************

;; CSI ... m. Colors apply to whatever is written next

Hexagon.Kernel.Dev.Console.Terminal.setGraphics:

    call Hexagon.Kernel.Dev.Console.Console.getConsoleColor ;; EAX/EBX = colors, ECX/EDX = theme

    mov esi, eax ;; Foreground being built
    mov edi, ebx ;; Background being built

    push edx
    push ecx

    xor ebx, ebx

.nextParam:

    cmp bl, byte[Hexagon.Console.Terminal.index + ebp]

    ja .apply

    cmp ebx, Hexagon.Console.Terminal.maxParams

    jae .apply

    call Hexagon.Kernel.Dev.Console.Terminal.param

    cmp eax, 0

    je .reset

    cmp eax, 7

    je .reverse

    cmp eax, 27

    je .notReverse

    cmp eax, 38

    je .directForeground

    cmp eax, 48

    je .directBackground

    cmp eax, 39

    je .themeForeground

    cmp eax, 49

    je .themeBackground

    cmp eax, 30

    jb .next

    cmp eax, 37

    jbe .foreground

    cmp eax, 40

    jb .next

    cmp eax, 47

    jbe .background

    cmp eax, 90

    jb .next

    cmp eax, 97

    jbe .brightForeground

    cmp eax, 100

    jb .next

    cmp eax, 107

    jbe .brightBackground

    jmp .next

.reset:

    mov esi, dword[esp]
    mov edi, dword[esp + 4]

    mov byte[Hexagon.Console.Terminal.reverse + ebp], 0

    jmp .next

.reverse:

    cmp byte[Hexagon.Console.Terminal.reverse + ebp], 0

    jne .next

    mov byte[Hexagon.Console.Terminal.reverse + ebp], 1

    xchg esi, edi

    jmp .next

.notReverse:

    cmp byte[Hexagon.Console.Terminal.reverse + ebp], 0

    je .next

    mov byte[Hexagon.Console.Terminal.reverse + ebp], 0

    xchg esi, edi

    jmp .next

.themeForeground:

    mov esi, dword[esp]

    jmp .next

.themeBackground:

    mov edi, dword[esp + 4]

    jmp .next

.foreground:

    mov esi, dword[Hexagon.Console.Terminal.palette + eax * 4 - 30 * 4]

    jmp .next

.background:

    mov edi, dword[Hexagon.Console.Terminal.palette + eax * 4 - 40 * 4]

    jmp .next

.brightForeground:

    mov esi, dword[Hexagon.Console.Terminal.palette + eax * 4 - 82 * 4]

    jmp .next

.brightBackground:

    mov edi, dword[Hexagon.Console.Terminal.palette + eax * 4 - 92 * 4]

    jmp .next

.directForeground:

    call Hexagon.Kernel.Dev.Console.Terminal.directColor

    jc .apply

    mov esi, eax

    jmp .next

.directBackground:

    call Hexagon.Kernel.Dev.Console.Terminal.directColor

    jc .apply

    mov edi, eax

.next:

    inc ebx

    jmp .nextParam

.apply:

    add esp, 8

    mov eax, esi
    mov ebx, edi
    xor ecx, ecx

    call Hexagon.Kernel.Dev.Console.Console.setConsoleColor

    ret

;;************************************************************************************

;; Reads the 2;r;g;b that follows a 38 or 48
;;
;; Input:
;;
;; EBX - Index of the 38 or 48
;;
;; Output:
;;
;; EAX - Color
;; EBX - Index of the last parameter used
;; CF set if what follows is not 2;r;g;b, which ends the sequence

Hexagon.Kernel.Dev.Console.Terminal.directColor:

    push ecx

    add ebx, 4

    cmp bl, byte[Hexagon.Console.Terminal.index + ebp]

    ja .invalid

    sub ebx, 3

    call Hexagon.Kernel.Dev.Console.Terminal.param

    cmp eax, 2

    jne .invalid

    xor ecx, ecx

    inc ebx

    call Hexagon.Kernel.Dev.Console.Terminal.param

    mov cl, al
    shl ecx, 8

    inc ebx

    call Hexagon.Kernel.Dev.Console.Terminal.param

    mov cl, al
    shl ecx, 8

    inc ebx

    call Hexagon.Kernel.Dev.Console.Terminal.param

    mov cl, al

    mov eax, ecx

    pop ecx

    clc

    ret

.invalid:

    pop ecx

    stc

    ret
