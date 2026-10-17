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

    push ebx
    push ecx
    push esi
    push edi

    cmp byte[.pendingCount + edx], 0

    jne .copy

.waitKey:

    call Hexagon.Kernel.Dev.Keyboard.Keyboard.waitKeyboard ;; AL = character, AH = code

    mov esi, .sequences

.findSequence:

    cmp byte[esi], 0

    je .plainByte

    cmp byte[esi], ah

    je .sequenceFound

    add esi, 5

    jmp .findSequence

.sequenceFound:

    mov eax, dword[esi + 1]
    mov dword[.pending + edx * 4], eax

    mov byte[.pendingCount + edx], 3

    cmp byte[esi + 4], 0

    je .queued

    mov byte[.pendingCount + edx], 4

    jmp .queued

.plainByte:

    cmp ah, Hexagon.Keyboard.keyCodes.esc

    jne .checkByte

    mov al, 27 ;; The layouts hold no character for it

.checkByte:

    cmp al, 0

    je .waitKey

    test dword[keyStatus], 1 ;; Ctrl held

    jz .queueByte

    mov ah, al

    or ah, 20h ;; Either case of the letter

    cmp ah, 'a'

    jb .queueByte

    cmp ah, 'z'

    ja .queueByte

    and al, 1Fh

.queueByte:

    cmp al, 0FFh

    je .waitKey

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
