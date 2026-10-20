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
;; Hexagon terminal line discipline
;;
;; Turns what the keyboard of a VT delivers into the bytes a read of its tty
;; returns, according to the mode of that tty, as tty(4) does in BSD
;;
;;************************************************************************************

use32

;; Mode bits, as in the c_lflag of termios

Hexagon.TTY.Modes.canonical = 01h ;; ICANON, whole lines
Hexagon.TTY.Modes.echo      = 02h ;; ECHO, typed bytes shown

Hexagon.TTY.Modes.all = Hexagon.TTY.Modes.canonical or Hexagon.TTY.Modes.echo

;; Mode of each VT, the tty's and not its processes', cooked by default

Hexagon.TTY.mode:
times Hexagon.Console.VT.count db Hexagon.TTY.Modes.all

;;************************************************************************************

;; Reads the keyboard of a VT as a byte stream. Keys with no byte of their own
;; become the escape sequences a terminal sends for them, and Ctrl with a letter
;; its control character. Blocks until there is at least one byte
;;
;; Input:
;;
;; EDX - VT
;; EDI - Buffer
;; ECX - Maximum bytes, at least 1
;;
;; Output:
;;
;; EAX - Bytes read

Hexagon.Kernel.Dev.TTY.read:

    test byte[Hexagon.TTY.mode + edx], Hexagon.TTY.Modes.canonical

    jnz Hexagon.Kernel.Dev.TTY.readLine

    push ebx
    push ecx
    push esi
    push edi

    cmp byte[.pendingCount + edx], 0

    jne .copy

.waitKey:

    call Hexagon.Kernel.Dev.Keyboard.Keyboard.waitKeyboard ;; AL = character, AH = code

    call Hexagon.Kernel.Dev.TTY.findSequence

    jc .plainByte

    mov eax, dword[esi + 1]
    mov dword[.pending + edx * 4], eax

    mov byte[.pendingCount + edx], 3

    cmp byte[esi + 4], 0

    je .queued

    mov byte[.pendingCount + edx], 4

    jmp .queued

.plainByte:

    call Hexagon.Kernel.Dev.TTY.byteOfKey

    jc .waitKey

    mov byte[.pending + edx * 4], al

    mov byte[.pendingCount + edx], 1

.queued:

    mov byte[.pendingIndex + edx], 0

.copy:

    xor ebx, ebx ;; Bytes read

.copyByte:

    movzx esi, byte[.pendingIndex + edx]

    mov al, byte[.pending + edx * 4 + esi]
    mov byte[edi], al

    inc edi
    inc ebx
    inc esi

    mov eax, esi
    mov byte[.pendingIndex + edx], al

    cmp al, byte[.pendingCount + edx]

    je .drained

    cmp ebx, ecx

    jb .copyByte

    jmp .end

.drained:

    mov byte[.pendingCount + edx], 0

.end:

    mov eax, ebx

    pop edi
    pop esi
    pop ecx
    pop ebx

    ret

;; Key code, then its sequence padded to four bytes

.sequences:

db Hexagon.Keyboard.keyCodes.upKey,    27, '[', 'A', 0
db Hexagon.Keyboard.keyCodes.downKey,  27, '[', 'B', 0
db Hexagon.Keyboard.keyCodes.rightKey, 27, '[', 'C', 0
db Hexagon.Keyboard.keyCodes.leftKey,  27, '[', 'D', 0
db Hexagon.Keyboard.keyCodes.home,     27, '[', 'H', 0
db Hexagon.Keyboard.keyCodes.end,      27, '[', 'F', 0
db Hexagon.Keyboard.keyCodes.delete,   27, '[', '3', '~'
db 0

;; What a VT still has to hand out of the last key, when it did not fit

.pending:      times Hexagon.Console.VT.count dd 0
.pendingCount: times Hexagon.Console.VT.count db 0
.pendingIndex: times Hexagon.Console.VT.count db 0

;;************************************************************************************

;; Input:
;;
;; AH - Key code
;;
;; Output:
;;
;; ESI - Its entry in Hexagon.Kernel.Dev.TTY.read.sequences, CF set if it has none

Hexagon.Kernel.Dev.TTY.findSequence:

    mov esi, Hexagon.Kernel.Dev.TTY.read.sequences

.check:

    cmp byte[esi], 0

    je .none

    cmp byte[esi], ah

    je .found

    add esi, 5

    jmp .check

.found:

    clc

    ret

.none:

    stc

    ret

;;************************************************************************************

;; The byte of a key that has no escape sequence, Esc and Ctrl with a letter
;; included
;;
;; Input:
;;
;; AL - Character, as the layout gives it
;; AH - Key code
;;
;; Output:
;;
;; AL - Byte, CF set if the key has none

Hexagon.Kernel.Dev.TTY.byteOfKey:

    cmp ah, Hexagon.Keyboard.keyCodes.esc

    jne .checkByte

    mov al, 27 ;; The layouts hold no character for it

.checkByte:

    cmp al, 0

    je .none

    cmp al, 0FFh

    je .none

    test dword[keyStatus], 1 ;; Ctrl held

    jz .done

    mov ah, al

    or ah, 20h ;; Either case of the letter

    cmp ah, 'a'

    jb .done

    cmp ah, 'z'

    ja .done

    and al, 1Fh

.done:

    clc

    ret

.none:

    stc

    ret

;;************************************************************************************

;; Canonical mode. Keys are gathered into a line, edited and echoed as they come,
;; and the line is handed out once Enter or Ctrl+D ends it, over as many reads as
;; it takes
;;
;; Input/Output: as Hexagon.Kernel.Dev.TTY.read

Hexagon.Kernel.Dev.TTY.readLine:

    push ebx
    push ecx
    push esi
    push edi
    push ebp

;; Each VT's line lives in a block allocated on its first canonical read

    call Hexagon.Kern.Sched.disablePreemption

    cmp dword[.state + edx * 4], 0

    jne .haveState

    pushad

    mov ebx, .stateSize

    call Hexagon.Arch.Mm.malloc ;; EBX = block, or EAX = 0

    cmp eax, 0

    je .allocated

    mov byte[ebx + .length], 0
    mov byte[ebx + .position], 0
    mov byte[ebx + .ready], 0

    mov dword[.state + edx * 4], ebx

.allocated:

    popad

.haveState:

    call Hexagon.Kern.Sched.enablePreemption

    mov ebp, dword[.state + edx * 4]

    cmp ebp, 0

    je .noMemory

.nextKey:

    cmp byte[ds:ebp + .ready], 0

    jne .deliver

    call Hexagon.Kernel.Dev.Keyboard.Keyboard.waitKeyboard ;; AL = character, AH = code

    call Hexagon.Kernel.Dev.TTY.findSequence

    jnc .nextKey ;; Arrows, Home, End and Delete do nothing in a line

    call Hexagon.Kernel.Dev.TTY.byteOfKey

    jc .nextKey

    movzx ebx, byte[ds:ebp + .length]

    cmp al, 10

    je .endOfLine

    cmp al, 04h ;; Ctrl+D

    je .endOfFile

    cmp al, 08h

    je .erase

    cmp al, 7Fh

    je .erase

    cmp al, 17h ;; Ctrl+W

    je .eraseWord

    cmp al, 15h ;; Ctrl+U

    je .eraseLine

    cmp al, 9

    je .append

    cmp al, ' '

    jb .nextKey ;; Any other control character

.append:

    cmp ebx, .maxLength - 1

    jae .nextKey ;; The last place is kept for the end of the line

    mov byte[ds:ebp + ebx], al

    inc byte[ds:ebp + .length]

    lea esi, [ebp + ebx]

    call .echo

    jmp .nextKey

.endOfLine:

    mov byte[ds:ebp + ebx], 10

    inc byte[ds:ebp + .length]

    lea esi, [ebp + ebx]

    call .echo

    mov byte[ds:ebp + .ready], 1

    jmp .deliver

.endOfFile:

    xor esi, esi

    cmp ebx, 0

    je .done ;; Nothing typed, which reads as the end of the file

    mov byte[ds:ebp + .ready], 1

    jmp .deliver

.erase:

    call .eraseOne

    jmp .nextKey

.eraseWord:

    movzx ebx, byte[ds:ebp + .length]

    cmp ebx, 0

    je .nextKey

    cmp byte[ds:ebp + ebx - 1], ' '

    jne .wordCharacters

    call .eraseOne

    jmp .eraseWord

.wordCharacters:

    movzx ebx, byte[ds:ebp + .length]

    cmp ebx, 0

    je .nextKey

    cmp byte[ds:ebp + ebx - 1], ' '

    je .nextKey

    call .eraseOne

    jmp .wordCharacters

.eraseLine:

    cmp byte[ds:ebp + .length], 0

    je .nextKey

    call .eraseOne

    jmp .eraseLine

.deliver:

    xor esi, esi ;; Bytes handed out

.copyByte:

    movzx ebx, byte[ds:ebp + .position]

    cmp bl, byte[ds:ebp + .length]

    jae .lineDone

    cmp esi, ecx

    jae .done

    mov al, byte[ds:ebp + ebx]
    mov byte[edi + esi], al

    inc esi

    inc byte[ds:ebp + .position]

    jmp .copyByte

.lineDone:

    mov byte[ds:ebp + .ready], 0
    mov byte[ds:ebp + .length], 0
    mov byte[ds:ebp + .position], 0

.done:

    mov eax, esi

    pop ebp
    pop edi
    pop esi
    pop ecx
    pop ebx

    clc

    ret

.noMemory:

    xor eax, eax

    pop ebp
    pop edi
    pop esi
    pop ecx
    pop ebx

    stc

    ret

;; Takes the last byte off the line, and off the screen
;;
;; Input: EBP - Line, EDX - VT

.eraseOne:

    cmp byte[ds:ebp + .length], 0

    je .nothingToErase

    dec byte[ds:ebp + .length]

    mov esi, .eraseEcho

    push ecx

    mov ecx, 3

    call .echoBytes

    pop ecx

.nothingToErase:

    ret

;; Shows ESI's byte, or ECX bytes through .echoBytes, when the tty echoes
;;
;; Input: EDX - VT

.echo:

    push ecx

    mov ecx, 1

    call .echoBytes

    pop ecx

    ret

.echoBytes:

    test byte[Hexagon.TTY.mode + edx], Hexagon.TTY.Modes.echo

    jz .noEcho

    call Hexagon.Kernel.Dev.Console.Terminal.write

.noEcho:

    ret

.eraseEcho: db 8, ' ', 8

;; Offsets into one VT's line

.length    = 256
.position  = 257
.ready     = 258 ;; Ended, and being handed out
.stateSize = 260

.maxLength = 255 ;; Bytes a line may hold, its end included, as MAX_CANON in BSD

.state: times Hexagon.Console.VT.count dd 0 ;; Each VT's block, 0 until its first line
