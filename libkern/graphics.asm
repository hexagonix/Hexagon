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

;;************************************************************************************

;; Calculate pixel offset in video buffer
;;
;; Input:
;;
;; EAX - X
;; EBX - Y
;;
;; Output:
;;
;; ESI - Pixel address

Hexagon.Libkern.Graphics.calculatePixelOffset:

    push eax ;; X

    mov esi, dword[Hexagon.Console.Memory.addressLFB] ;; Pointer to video memory

    movzx eax, word[Hexagon.Console.bytesPerRow]

    mul ebx ;; Y * bytes per row

    add esi, eax

    pop eax ;; X

    movzx ebx, byte[Hexagon.Console.bytesPerPixel]

    mul ebx ;; X * bytes per pixel

    add esi, eax ;; ESI is a pointer to video memory

    ret

;;************************************************************************************

;; Display bitmap character in graphics mode
;;
;; Input:
;;
;; DL - Column
;; DH - Line (row)
;; AL - Character

Hexagon.Libkern.Graphics.putCharacterBitmap:

    push edx

    and eax, 0xFF
    sub eax, 32
    mov ebx, Hexagon.Libkern.Fonts.height

    mul ebx

    mov edi, Hexagon.Libkern.Fonts
    add edi, 04h
    add edi, eax

    pop edx

    push edx

    mov eax, Hexagon.Libkern.Fonts.width
    movzx ebx, dl

    mul ebx

    mov word[.x], ax

    pop edx

    mov eax, Hexagon.Libkern.Fonts.height
    movzx ebx, dh

    mul ebx

    mov word[.y], ax

    mov eax, Hexagon.Libkern.Fonts.width
    mov ebx, dword[Hexagon.Console.bytesPerPixel]

    mul ebx

    mov dword[.nextLine], eax

    movzx eax, word[.x]

    dec eax

    movzx ebx, word[.y]

    call Hexagon.Libkern.Graphics.calculatePixelOffset

    mov ecx, Hexagon.Libkern.Fonts.height

.putColumn:

    mov al, byte[edi]

    inc edi

    push ecx

    mov ecx, Hexagon.Libkern.Fonts.width

.putLine:

    bt ax, 7
    jc .putInForeground

.putInBackground:

    mov edx, dword[Hexagon.Console.backgroundColor]

    jmp .next

.putInForeground:

    mov edx, dword[Hexagon.Console.fontColor]

.next:

    add esi, dword[Hexagon.Console.bytesPerPixel]

    mov word[gs:esi], dx
    shr edx, 8
    mov byte[gs:esi+2], dh

    shl al, 1

    loop .putLine

    pop ecx

    add esi, dword[Hexagon.Console.bytesPerRow]
    sub esi, dword[.nextLine]

    loop .putColumn

.end:

    ret

.x:        dw 0
.y:        dw 0
.nextLine: dd 0

;;************************************************************************************

;; Put a pixel on the console
;;
;; Input:
;;
;; EAX - X
;; EBX - Y
;; EDX - Color in hexadecimal

Hexagon.Libkern.Graphics.putPixel:

    push eax
    push edx
    push ebx
    push esi

    push edx

    call Hexagon.Libkern.Graphics.calculatePixelOffset ;; Get pixel offset

    pop edx

    mov word[gs:esi], dx
    shr edx, 8
    mov byte[gs:esi+2], dh

.end:

    pop esi
    pop ebx
    pop edx
    pop eax

    ret

;;************************************************************************************

Hexagon.Libkern.Graphics.drawBlockSyscall:

    sub esi, dword[Hexagon.Processes.PCB.processBaseMemory]

;; Correct address with segment base (physical address = address + segment base)

    add esi, 500h

    sub edi, dword[Hexagon.Processes.PCB.processBaseMemory]

;; Correct address with segment base (physical address = address + segment base)

    add edi, 500h

    call Hexagon.Libkern.Graphics.drawBlock

    add esi, dword[Hexagon.Processes.PCB.processBaseMemory]

;; Correct address with segment base (physical address = address + segment base)

    sub esi, 500h

    add edi, dword[Hexagon.Processes.PCB.processBaseMemory]

;; Correct address with segment base (physical address = address + segment base)

    sub edi, 500h

    ret

;;************************************************************************************

;; Desenhar um bloco de cor específica
;;
;; Entrada:
;;
;; EAX - X
;; EBX - Y
;; ESI - Comprimento
;; EDI - Largura
;; EDX - Cor em hexadecimal

Hexagon.Libkern.Graphics.drawBlock:

    push eax
    push ebx
    push ecx

    cmp byte[Hexagon.Console.graphicMode], 1
    jne .end

    mov ecx, edi ;; Width

.y:

    push ecx

    mov ecx, esi ;; Length

.x:

    call Hexagon.Libkern.Graphics.putPixel

    inc eax

    loop .x

    pop ecx

    sub eax, esi

    inc ebx

    loop .y

.end:

    pop ecx
    pop ebx
    pop eax

    ret
