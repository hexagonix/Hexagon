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

;; Useful information for using graphical mode
;; Hexagon graphics mode implementation

;; Graphics mode implementation is based on VESA 3.0 specifications.

;; View VESA 3.0 specifications for more information
;; VBE = VESA BIOS Extensions

use32

;;************************************************************************************

Hexagon.Console:

.default = 118h

.userMode:            db 0
.graphicMode:         db 0
.consoleSize:         dd 0
.modeVBE:             dw .default
.maxColumns:          dw 0
.maxRows:             dw 0
.bitsPerPixel:        db 0
.bytesPerPixel:       dd 0
.bytesPerRow:         dd 0
.bytesPerRowGraphics: dd 0

;; Use the settings in libkern/macros.s to define the color
;; scheme applied at startup

.defaultBackgroundColor = HEXAGONIX_BLOSSOM_CINZA
.defaultFontColor       = HEXAGONIX_BLOSSOM_AMARELO

.backgroundColor:      dd .defaultBackgroundColor
.fontColor:            dd .defaultFontColor
.backgroundThemeColor: dd .defaultBackgroundColor
.fontThemeColor:       dd .defaultFontColor

Hexagon.Console.Resolution:

.x: dw 1024
.y: dw 768

Hexagon.Console.Memory:

;; Memory addresses for video operations

.mainConsoleBuffer:      dd 100000h
.secondaryConsoleBuffer: dd 100000h
.kernelConsoleBuffer:    dd 300000h
.addressLFB: dd 0 ;; LFB (Linear Frame Buffer) address

Hexagon.Console.textMode:

.defaultColor = 0xF0
.maxRows      = 24 ;; Counting from 0
.maxColumns   = 79 ;; Counting from 0
.videoMemory  = 0xB8000

.currentColor:  db .defaultColor
.cursor.X:      db 0
.cursor.Y:      db 0

;;************************************************************************************

;; Defines the resolution to be used for display
;;
;; Input:
;;
;; EAX - Number relating to the resolution to be used
;; 1 - Resolution of 800x600 pixels
;; 2 - Resolution of 1024x768 pixels
;; 3 - Change to text mode

Hexagon.Kernel.Dev.Gen.Console.Console.setResolution:

    cmp eax, 01h ;; 800x600 pixels
    je .graphicMode1

    cmp eax, 02h ;; 1024x768
    je .graphicMode2

    cmp eax, 03h ;; Text mode
    je .textMode

    jmp .end

.graphicMode1: ;; Resolution of 800x600 pixels according to VESA 3.0 specification

    mov word[Hexagon.Console.modeVBE], 0x115

    call Hexagon.Kernel.Dev.Gen.Console.Console.setGraphicMode

    jmp .end

.graphicMode2: ;; Resolution of 1024x768 pixels according to VESA 3.0 specification

    mov word[Hexagon.Console.modeVBE], 0x118

    call Hexagon.Kernel.Dev.Gen.Console.Console.setGraphicMode

    jmp .end

.textMode:

    call Hexagon.Kernel.Dev.Gen.Console.Console.setTextMode

.end:

    ret

;;************************************************************************************

;; Returns the number relative to the current resolution of the video
;;
;; Output:
;;
;; EAX - Number relative to the resolution currently used
;; 1 - Resolution of 800x600 pixels
;; 2 - Resolution of 1024x768 pixels

Hexagon.Kernel.Dev.Gen.Console.Console.getResolution:

    mov ax, word[Hexagon.Console.modeVBE]

    cmp ax, 115h
    je .graphicMode1

    cmp ax, 118h
    je .graphicMode2

    ret

.graphicMode1:

    mov eax, 1

    ret

.graphicMode2:

    mov eax, 2

    ret

;;************************************************************************************

Hexagon.Kernel.Dev.Gen.Console.Console.setTextMode:

    push eax

    mov ah, 0 ;; Function to set video mode
    mov al, 3 ;; Video in text mode

    call Hexagon.Kernel.Arch.i386.BIOS.BIOS.int10h ;; Call real mode BIOS interrupt

    mov ax, 1003h
    mov bx, 0

    call Hexagon.Kernel.Arch.i386.BIOS.BIOS.int10h ;; Turn off blinking

    mov byte[Hexagon.Console.graphicMode], 0

    call Hexagon.Kernel.Dev.Gen.Console.Console.clearConsole

    pop eax

    ret

;;************************************************************************************

;; Configure graphics mode
;;
;; Output:
;;
;; ESI - Pointer to video memory

Hexagon.Kernel.Dev.Gen.Console.Console.setGraphicMode:

    push eax
    push ebx
    push ecx
    push edi

    mov ax, word[Hexagon.Console.modeVBE] ;; The default is 1024*768*24

    mov cx, ax ;; CX: way to obtain information
    mov ax, 0x4F01 ;; Function to obtain video information
    mov di, Hexagon.Heap.VBE + 500h ;; Address where data is stored

    call Hexagon.Kernel.Arch.i386.BIOS.BIOS.int10h ;; Call BIOS interrupt in real mode

    mov esi, dword[Hexagon.Heap.VBE+40] ;; Pointer to the base of the video memory
    mov dword[Hexagon.Console.Memory.addressLFB], esi

    or cx, 100000000000000b ;; Set bit 14 to get linear frame buffer

    mov bx, cx
    mov ax, 0x4F02 ;; Function to set video mode

    call Hexagon.Kernel.Arch.i386.BIOS.BIOS.int10h ;; Call BIOS interrupt in real mode

    mov ax, word[Hexagon.Heap.VBE+16]
    mov word[Hexagon.Console.bytesPerRow], ax

    mov al, byte[Hexagon.Heap.VBE+25] ;; Get bits per pixel

    cmp al, 0
    jne .bitsPerPixelOK

    mov al, 24

.bitsPerPixelOK:

    mov byte[Hexagon.Console.bitsPerPixel], al ;; Save bits per pixel
    shr al, 3 ;; Divide by 8
    mov byte[Hexagon.Console.bytesPerPixel], al

    mov ax, word[Hexagon.Heap.VBE+18] ;; Get resolution

    cmp ax, 0
    jne .xResOK

    mov ax, 1024

.xResOK:

    mov word[Hexagon.Console.Resolution.x], ax ;; Save resolution
    mov ax, word[Hexagon.Heap.VBE+20] ;; Get resolution Y

    cmp ax, 0
    jne .yResOK

    mov ax, 768

.yResOK:

    mov word[Hexagon.Console.Resolution.y], ax ;; Save resolution Y

    movzx eax, word[Hexagon.Console.Resolution.x]
    mov ebx, Hexagon.Fontes.largura

    xor edx, edx

    div ebx

    dec ax ;; Counting from 0

    mov word[Hexagon.Console.maxColumns], ax

    movzx eax, word[Hexagon.Console.Resolution.y]
    mov ebx, Hexagon.Fontes.altura

    xor edx, edx

    div ebx

    dec ax ;; Counting from 0

    mov word[Hexagon.Console.maxRows], ax

    mov byte[Hexagon.Console.graphicMode], 1

    mov eax, dword[Hexagon.Console.bytesPerRow]
    movzx ebx, word[Hexagon.Console.Resolution.y]

    mul ebx

    mov dword[Hexagon.Console.consoleSize], eax

    mov eax, dword[Hexagon.Console.bytesPerRow]
    mov ebx, Hexagon.Fontes.altura

    mul ebx

    mov dword[Hexagon.Console.bytesPerRowGraphics], eax

    mov eax, [Hexagon.Console.Memory.addressLFB]
    mov [Hexagon.Console.Memory.mainConsoleBuffer], eax ;; Save original address

    call Hexagon.Kernel.Dev.Gen.Console.Console.clearConsole

    pop edi
    pop ecx
    pop ebx
    pop eax

    ret

;;************************************************************************************

;; Get video information
;;
;; Output:
;;
;; EAX - Resolution of X (bits 0-15), Y (bits 16-31)
;; EBX - Columns (bits 0-7), Rows (8-15), Bits per Pixel (16-23)
;; EDX - Buffer starting address
;; CF defined when in text mode

Hexagon.Kernel.Dev.Gen.Console.Console.getConsoleInfo:

    cmp byte[Hexagon.Console.graphicMode], 0
    je .textModeVideo

.graphicModeVideo:

    push ecx

    mov bl, byte[Hexagon.Console.bitsPerPixel]
    shl ebx, 8

    mov bl, byte[Hexagon.Console.maxRows]

    inc bl ;; Counting from 1

    shl ebx, 8

    mov bl, byte[Hexagon.Console.maxColumns]

    inc bl ;; Counting from 1

    mov ax, word[Hexagon.Console.Resolution.y]
    shl eax, 16
    mov ax, word[Hexagon.Console.Resolution.x]

    mov edx, dword[Hexagon.Console.Memory.addressLFB]

    pop ecx

    clc

    ret

.textModeVideo:

    mov bl, Hexagon.Console.textMode.maxColumns+1
    mov bh, Hexagon.Console.textMode.maxRows+1

    and ebx, 0xFFFF

    mov eax, 0
    mov edx, Hexagon.Console.textMode.videoMemory

    stc

    ret

;;************************************************************************************

;; Clean the console

Hexagon.Kernel.Dev.Gen.Console.Console.clearConsole:

    cmp byte[Hexagon.Console.graphicMode], 1 ;; Check graphics mode
    je .graphicsMode

.textMode:

    xor edx, edx

    call Hexagon.Kernel.Dev.Gen.Console.Console.positionCursor

    mov edi, Hexagon.Console.textMode.videoMemory
    mov ecx, (Hexagon.Console.textMode.maxRows+1) * (Hexagon.Console.textMode.maxColumns+1)
    mov ah, byte[Hexagon.Console.textMode.currentColor] ;; Color
    mov al, ' ' ;; Character to fill the screen

    rep stosw ;; Loop to fill (clear) video memory

    jmp .end

align 16

.graphicsMode:

    mov ebx, Hexagon.Console.defaultBackgroundColor

    cmp dword[Hexagon.Console.backgroundColor], ebx
    je .clearBySSE

    mov esi, dword[Hexagon.Console.Memory.addressLFB]

    mov eax, dword[Hexagon.Console.consoleSize]
    mov ebx, dword[Hexagon.Console.bytesPerPixel]
    xor edx, edx

    div ebx

    mov ecx, eax

    mov ebx, dword[Hexagon.Console.bytesPerPixel]
    mov edx, dword[Hexagon.Console.backgroundColor]

.clearLoop:

    mov dword[gs:esi], edx

    add esi, ebx

    loop .clearLoop

    mov dx, 0

    call Hexagon.Kernel.Dev.Gen.Console.Console.positionCursor

    ret

.clearBySSE:

    mov edi, dword[Hexagon.Console.Memory.addressLFB]

    movdqa xmm0, [.clearBytes]

    mov ecx, dword[Hexagon.Console.consoleSize]
    shr ecx, 7

    push ds

    mov ax, 18h ;; Kernel linear segment
    mov ds, ax

.loop:

    movdqa [edi+00], xmm0
    movdqa [edi+16], xmm0
    movdqa [edi+32], xmm0
    movdqa [edi+48], xmm0
    movdqa [edi+64], xmm0
    movdqa [edi+80], xmm0
    movdqa [edi+96], xmm0
    movdqa [edi+112], xmm0

    add edi, 128

    loop .loop

    pop ds

    mov dx, 0

    call Hexagon.Kernel.Dev.Gen.Console.Console.positionCursor

.end:

    ret

align 16

.clearBytes: times 4 dd Hexagon.Console.defaultBackgroundColor

;;************************************************************************************

;; Clear specific row on screen
;;
;; Output:
;;
;; AL - Row to clean

Hexagon.Kernel.Dev.Gen.Console.Console.clearRow:

    cmp byte[Hexagon.Console.graphicMode], 1
    je .graphicsMode

    push eax
    push ecx
    push edx
    push edi

    push es

    push 18h ;; Kernel linear segment
    pop es

    mov dl, 0
    mov dh, al

    call Hexagon.Kernel.Dev.Gen.Console.Console.positionCursor

    movzx eax, al ;; Calculate position
    mov ecx, 160

    xor edx, edx

    mul cx

    mov edi, Hexagon.Console.textMode.videoMemory
    add edi, eax

    shr ecx, 2 ;; Divide ECX by 4

    mov ah, [Hexagon.Console.textMode.currentColor] ;; Color
    mov al, ' '
    shl eax, 16
    mov ah, [Hexagon.Console.textMode.currentColor] ;; Color
    mov al, ' '

    rep stosd

    pop es

    pop edi
    pop edx
    pop ecx
    pop eax

    ret

.graphicsMode:

    push eax
    push ebx
    push ecx
    push edx
    push esi

    xor dl, dl
    mov dh, al

    call Hexagon.Kernel.Dev.Gen.Console.Console.positionCursor

    mov esi, dword[Hexagon.Console.Memory.addressLFB]

    and eax, 0xFF
    mov ebx, Hexagon.Fontes.altura

    mul ebx

    mov ebx, dword[Hexagon.Console.bytesPerRow]

    mul ebx

    add esi, eax

    movzx eax, word[Hexagon.Console.bytesPerRow]
    mov ebx, Hexagon.Fontes.altura

    mul ebx

    mov ebx, dword[Hexagon.Console.bytesPerPixel]
    xor edx, edx

    div ebx

    mov ecx, eax

    mov ebx, dword[Hexagon.Console.bytesPerPixel]
    mov edx, dword[Hexagon.Console.backgroundColor]

.clearLoop:

    mov dword[gs:esi], edx
    add esi, ebx

    loop .clearLoop

    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax

    ret

;;************************************************************************************

;; Scroll down

Hexagon.Kernel.Dev.Gen.Console.Console.scrollConsole:

    push eax
    push ecx
    push edx
    push esi
    push edi

    push ds
    push es

    cmp byte[Hexagon.Console.graphicMode], 1
    je .graphicsMode

.textMode:

;; Move all screen content one line up

    mov ax, 18h ;; Kernel linear segment
    mov es, ax
    mov ds, ax

    mov esi, Hexagon.Console.textMode.videoMemory
    mov edi, Hexagon.Console.textMode.videoMemory-160 ;; One row above
    mov ecx, 2000

    rep movsw ;; Repeat ECX times (mov word[ES:EDI], word[DS:ESI])

    mov ax, 10h ;; Kernel data segment
    mov ds, ax

    mov eax, Hexagon.Console.textMode.maxRows ;; Clear last row

    call Hexagon.Kernel.Dev.Gen.Console.Console.clearRow

    jmp .end

.graphicsMode:

    mov esi, dword[Hexagon.Console.Memory.addressLFB]

    mov edi, esi

    sub edi, dword[Hexagon.Console.bytesPerRowGraphics]

    mov ecx, [Hexagon.Console.consoleSize]
    shr ecx, 7 ;; Divide by 128

    mov ax, 18h ;; Kernel linear segment
    mov es, ax
    mov ds, ax

.copy:

    prefetchnta [esi+0]
    prefetchnta [esi+32]
    prefetchnta [esi+64]
    prefetchnta [esi+96]

    movdqa xmm0, [esi+0]
    movdqa xmm1, [esi+16]
    movdqa xmm2, [esi+32]
    movdqa xmm3, [esi+48]
    movdqa xmm4, [esi+64]
    movdqa xmm5, [esi+80]
    movdqa xmm6, [esi+96]
    movdqa xmm7, [esi+112]

    movdqa [edi+0], xmm0
    movdqa [edi+16], xmm1
    movdqa [edi+32], xmm2
    movdqa [edi+48], xmm3
    movdqa [edi+64], xmm4
    movdqa [edi+80], xmm5
    movdqa [edi+96], xmm6
    movdqa [edi+112], xmm7

    add edi, 128
    add esi, 128

    loop .copy

    mov ax, 10h ;; Kernel data segment
    mov ds, ax

    movzx eax, word[Hexagon.Console.maxRows]

    call Hexagon.Kernel.Dev.Gen.Console.Console.clearRow

.end:

    pop es
    pop ds

    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax

    ret

;;************************************************************************************

;; Dispatcher to send content to the console
;;
;; Input:
;;
;; EAX - Numerical content
;; EBX - Entry type, which can be:
;;  01 - Decimal integer
;;  02 - Hexadecimal integer
;;  03 - Binary integer
;;  04 - String
;; ESI - Pointer to the string to be printed

Hexagon.Kernel.Dev.Gen.Console.Console.print:

    cmp ebx, 01h
    je Hexagon.Kernel.Dev.Gen.Console.Console.printDecimal

    cmp ebx, 02h
    je Hexagon.Kernel.Dev.Gen.Console.Console.printHexadecimal

    cmp ebx, 03h
    je Hexagon.Kernel.Dev.Gen.Console.Console.printBinary

    cmp ebx, 04h
    je Hexagon.Kernel.Dev.Gen.Console.Console.printString

    stc

    ret

;;************************************************************************************

;; Print an integer
;;
;; Input:
;;
;; EAX - Integer

Hexagon.Kernel.Dev.Gen.Console.Console.printDecimal:

    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi

;; Check if negative

    cmp eax, 0
    jge .positive

.negative:

    push eax

    mov al, '-' ;; Print "-"

    call Hexagon.Kernel.Dev.Gen.Console.Console.printCharacter

    pop eax

    neg eax

.positive:

;; Convert integer to string to be able to print

    mov ebx, 10  ;; Decimals are in base 10
    xor ecx, ecx ;; mov ECX, 0

.convertLoop:

    xor edx, edx ;; mov EDX, 0

    div ebx

    add dl, 30h ;; Convert to ASCII

    push edx

    inc ecx

    or eax, eax ;; cmp EAX, 0
    jne .convertLoop

    mov edx, esi

.printLoop:

    pop eax

    call Hexagon.Kernel.Dev.Gen.Console.Console.printCharacter

    loop .printLoop

.end:

    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax

    ret

;;************************************************************************************

;; Print an integer as binary
;;
;; Input:
;;
;; EAX - Integer

Hexagon.Kernel.Dev.Gen.Console.Console.printBinary:

    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi

;; Check for negative

    cmp eax, 0
    jge .positive

.negative:

    push eax

    mov al, '-' ;; Print "-"

    call Hexagon.Kernel.Dev.Gen.Console.Console.printCharacter

    pop eax

    neg eax

.positive:

;; Convert integer to string so it can be printed

    mov ebx, 2   ;; Binary numbers have base 2
    xor ecx, ecx ;; mov ECX, 0

.convertLoop:

    xor edx, edx ;; mov EDX, 0

    div ebx

    add dl, 30h ;; Convert this to ASCII

    push edx

    inc ecx

    or eax, eax ;; cmp EAX, 0
    jne .convertLoop

    mov edx, esi

.printLoop:

    pop eax

    call Hexagon.Kernel.Dev.Gen.Console.Console.printCharacter

    loop .printLoop

.end:

    mov al, 'b'

    call Hexagon.Kernel.Dev.Gen.Console.Console.printCharacter

    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax

    ret

;;************************************************************************************

;; Print an integer as hexadecimal
;;
;; Input:
;;
;; EAX - Integer

Hexagon.Kernel.Dev.Gen.Console.Console.printHexadecimal:

    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi

;; Check for negative

    cmp eax, 0
    jge .positive

.negative:

    push eax

    mov al, '-' ;; Print "-"

    call Hexagon.Kernel.Dev.Gen.Console.Console.printCharacter

    pop eax

    neg eax

.positive:

    push eax

    mov al, '0'

    call Hexagon.Kernel.Dev.Gen.Console.Console.printCharacter

    mov al, 'x'

    call Hexagon.Kernel.Dev.Gen.Console.Console.printCharacter

    pop eax

;; Convert integer to hexadecimal

    mov ebx, 16  ;; Hexadecimal numbers have base 16
    xor ecx, ecx ;; mov ECX, 0

.convertLoop:

    xor edx, edx ;; mov EDX, 0

    div ebx

    add dl, 30h

    cmp dl, 39h
    ja .add

    jmp short .next

.add:

    add dl, 7 ;; Convert this to ASCII

.next:

    push edx

    inc ecx

    or eax, eax ;; cmp EAX, 0
    jne .convertLoop

    mov edx, esi

.printLoop:

    pop eax

    call Hexagon.Kernel.Dev.Gen.Console.Console.printCharacter

    loop .printLoop

.end:

    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax

    ret

;;************************************************************************************

;; Performs the same function as Hexagon.Kernel.Dev.Gen.Console.Console.printCharacter,
;; but does not move the cursor
;;
;; Input:
;;
;; AL - Character

Hexagon.Kernel.Dev.Gen.Console.Console.printCharacterBase:

    cmp byte[Hexagon.Console.graphicMode], 1
    je Hexagon.Kernel.Dev.Gen.Console.Console.printCharacterGraphicMode

    mov dl, byte[Hexagon.Console.textMode.cursor.X]
    mov dh, byte[Hexagon.Console.textMode.cursor.Y]

    cmp al, 10 ;; Caractere de nova linha
    je .newLine

    cmp al, 9
    je .tab

    cmp al, ' ' ;; First printable character
    jb .notPrintable

    cmp al, '~' ;; Last printable character
    ja .notPrintable

    jmp .next

.tab:

    mov al, ' '

    jmp .next

.newLine:

    inc dh

    mov dl, 0
    mov al, 0xFF

    jmp .next

.notPrintable:

    mov al, 0xFF

.next:

;; Fix X and Y

    cmp dh, Hexagon.Console.textMode.maxRows
    jna .yOK

    call Hexagon.Kernel.Dev.Gen.Console.Console.scrollConsole

    mov dh, Hexagon.Console.textMode.maxRows

.yOK:

    cmp dl, Hexagon.Console.textMode.maxColumns
    jna .xOK

    mov dl, 0

    inc dh

.xOK:

    push edx
    push eax

;; Calculate character position on screen

    mov eax, 0
    mov al, dl
    shl ax, 1    ;; Multiply X by 2
    mov edi, eax ;; Add this to the index
    mov al, (Hexagon.Console.textMode.maxColumns+1) * 2 ;; Counting from 1

    mul dh ;; Multiply Y by maxColumns*2

    add edi, eax ;; Add this to the index

    pop eax

;; Put character

    pop edx

    cmp al, 0xFF
    je .characterNotPrintable

    inc dl

    mov ah, byte[Hexagon.Console.textMode.currentColor]

;; If the character already exists

    cmp word[gs:Hexagon.Console.textMode.videoMemory + edi], ax
    je .end

    mov word[gs:Hexagon.Console.textMode.videoMemory + edi], ax

.characterNotPrintable:

.end:

;; Update the cursor

    call Hexagon.Kernel.Dev.Gen.Console.Console.positionCursor

    ret

;;************************************************************************************

Hexagon.Kernel.Dev.Gen.Console.Console.printCharacterGraphicMode:

    call Hexagon.Kernel.Dev.Gen.Console.Console.getCursor

    cmp al, 9
    je .tab

    cmp al, 10
    je .return

    cmp al, '~'
    ja .notPrintable

    cmp al, ' '
    jl .notPrintable

    jmp .fixXandY

.tab:

    mov al, ' '

    jmp .fixXandY

.notPrintable:

    mov al, ' '

    jmp .fixXandY

.return:

    movzx eax, word[Hexagon.Kernel.Dev.Gen.Console.Console.positionCursorGraphicMode.previousX]
    movzx ebx, word[Hexagon.Kernel.Dev.Gen.Console.Console.positionCursorGraphicMode.previousY]

    push edx

    mov ecx, Hexagon.Fontes.altura
    mov edx, [Hexagon.Kernel.Dev.Gen.Console.Console.positionCursorGraphicMode.previousCursorColor]

.clearPreviousCursor:

    call Hexagon.Kernel.Lib.Graficos.colocarPixel

    inc ebx

    loop .clearPreviousCursor

    pop edx

    mov dl, 0

    inc dh

    mov al, 0 ;; Mark as unprintable

.fixXandY:

    cmp dl, byte[Hexagon.Console.maxColumns]
    jna .yOK

    mov dl, 0

    inc dh

.yOK:

    cmp dh, byte[Hexagon.Console.maxRows]
    jna .xOK

    call Hexagon.Kernel.Dev.Gen.Console.Console.scrollConsole

    mov dh, byte[Hexagon.Console.maxRows]
    mov dl, 0

.xOK:

    cmp al, 0
    je .next

.printable:

    push edx

    call Hexagon.Kernel.Lib.Graficos.colocarCaractereBitmap

    pop edx

    inc dl

    jmp .next

.next:

    mov byte[Hexagon.Console.textMode.cursor.X], dl
    mov byte[Hexagon.Console.textMode.cursor.Y], dh

    ret

;;************************************************************************************

;; Write a character at the cursor position
;;
;; Input:
;;
;; AL  - Character
;; EBX - 01h to position the cursor and other than that to not change the position

Hexagon.Kernel.Dev.Gen.Console.Console.printCharacter:

    pushad

    push ebx

    call Hexagon.Kernel.Dev.Gen.Console.Console.printCharacterBase

    pop ebx

    cmp ebx, 01h
    je .changeCursor

    jmp .end

.changeCursor:

    call Hexagon.Kernel.Dev.Gen.Console.Console.positionCursor

.end:

    popad

    ret

;;************************************************************************************

;; Get cursor position
;;
;; Output:
;;
;; DL - X
;; DH - Y

Hexagon.Kernel.Dev.Gen.Console.Console.getCursor:

    mov dl, byte[Hexagon.Console.textMode.cursor.X]
    mov dh, byte[Hexagon.Console.textMode.cursor.Y]

    ret

;;************************************************************************************

;; Move cursor to specific position
;;
;; Input:
;;
;; DL - X
;; DH - Y

Hexagon.Kernel.Dev.Gen.Console.Console.positionCursor:

    cmp byte[Hexagon.Console.graphicMode], 1
    je Hexagon.Kernel.Dev.Gen.Console.Console.positionCursorGraphicMode

    push eax
    push ebx
    push edx

    mov byte[Hexagon.Console.textMode.cursor.X], dl
    mov byte[Hexagon.Console.textMode.cursor.Y], dh

;; Fix X and Y

    cmp dh, Hexagon.Console.textMode.maxRows
    jna .yOK

    mov dh, Hexagon.Console.textMode.maxRows

.yOK:

    cmp dl, Hexagon.Console.textMode.maxColumns
    jna .xOK

    mov dl, Hexagon.Console.textMode.maxColumns

.xOK:

;; Now we must multiply Y by the total number of columns of X

    movzx eax, dh
    mov bl, Hexagon.Console.textMode.maxColumns+1 ;; Counting from 1

    mul bl ;; Multiplying Y by columns

    movzx ebx, dl
    add eax, ebx ;; Add X to this

    mov ebx, eax

    mov al, 0x0F
    mov dx, 0x3D4

    out dx, al

;; Send least significant byte to VGA port

    mov al, bl ;; BL is the least significant byte
    mov dx, 0x3D5 ;; VGA port

    out dx, al

    mov al, 0x0E
    mov dx, 0x3D4

    out dx, ax

;; Send most significant byte to VGA port

    mov al, bh    ;; BH is the most significant byte
    mov dx, 0x3D5 ;; VGA port

    out dx, al

    pop edx
    pop ebx
    pop eax

    ret

;;************************************************************************************

Hexagon.Kernel.Dev.Gen.Console.Console.positionCursorGraphicMode:

    push eax
    push ebx
    push ecx
    push edx

    mov byte[Hexagon.Console.textMode.cursor.X], dl
    mov byte[Hexagon.Console.textMode.cursor.Y], dh

    push edx

    mov eax, Hexagon.Fontes.largura
    movzx ebx, dl

    mul ebx

    mov word[.x], ax

    pop edx

    mov eax, Hexagon.Fontes.altura
    movzx ebx, dh

    mul ebx

    mov word[.y], ax

    movzx eax, word[.previousX]
    movzx ebx, word[.previousY]

    mov ecx, Hexagon.Fontes.altura
    mov edx, [.previousCursorColor]

.clearPreviousCursor:

    call Hexagon.Kernel.Lib.Graficos.colocarPixel

    inc ebx

    loop .clearPreviousCursor

    movzx eax, word[.x]
    movzx ebx, word[.y]

    mov word[.previousX], ax
    mov word[.previousY], bx

    mov edx, dword[Hexagon.Console.backgroundColor]
    mov dword[.previousCursorColor], edx

    mov ecx, Hexagon.Fontes.altura
    mov edx, dword[Hexagon.Console.fontColor]

.drawCursor:

    call Hexagon.Kernel.Lib.Graficos.colocarPixel

    inc ebx

    loop .drawCursor

    pop edx
    pop ecx
    pop ebx
    pop eax

    ret

.previousX: dw 0
.previousY: dw 0
.previousCursorColor: dd Hexagon.Console.defaultBackgroundColor
.x: dw 0
.y: dw 0

;;************************************************************************************

;; Print a string ending in 0 at the cursor position
;;
;; Input:
;;
;; ESI - String

Hexagon.Kernel.Dev.Gen.Console.Console.printString:

    push esi
    push eax
    push ecx

;; Check for null

    cmp byte[esi], 0
    je .end

;; Get string size

    call Hexagon.Kernel.Lib.String.tamanhoString

    mov ecx, eax

;; Write all characters

.printStringLoop:

    lodsb ;; mov AL, byte[ESI] & inc ESI

    call Hexagon.Kernel.Dev.Gen.Console.Console.printCharacter

    loop .printStringLoop

.end:

    pop ecx
    pop eax
    pop esi

    ret

;;************************************************************************************

;; Change the console color scheme
;;
;; Input:
;;
;; EAX - Font color (RGB hex)
;; EBX - Background color (RGB hex)
;; ECX - 1234h to change the default theme based on what was entered
;;
;; Text mode must be black and white only

Hexagon.Kernel.Dev.Gen.Console.Console.setConsoleColor:

    cmp byte[Hexagon.Console.graphicMode], 1
    je .graphicsMode

.textModeVideo:

    mov byte[Hexagon.Console.textMode.currentColor], Hexagon.Console.textMode.defaultColor

    ret

.graphicsMode:

    mov dword[Hexagon.Console.fontColor], eax
    mov dword[Hexagon.Console.backgroundColor], ebx

    cmp ecx, 1234h
    je .setTheme

    jmp .end

.setTheme:

    mov dword[Hexagon.Console.fontThemeColor], eax
    mov dword[Hexagon.Console.backgroundThemeColor], ebx

.end:

    ret

;;************************************************************************************

;; Get the console color scheme
;;
;; Output:
;;
;; EAX - Foreground (RGB hex)
;; EBX - Background (RGB hex)
;; ECX - Color defined for the font according to the chosen theme
;; EDX - Color set for the background according to the theme

Hexagon.Kernel.Dev.Gen.Console.Console.getConsoleColor:

    cmp byte[Hexagon.Console.graphicMode], 1
    je .graphicsMode

.textModeVideo:

    mov al, Hexagon.Console.textMode.defaultColor

    ret

.graphicsMode:

    mov eax, dword[Hexagon.Console.fontColor]
    mov ebx, dword[Hexagon.Console.backgroundColor]

    mov ecx, dword[Hexagon.Console.fontThemeColor]
    mov edx, dword[Hexagon.Console.backgroundThemeColor]

    ret

;;************************************************************************************

;; Changes the font used to display information in the console, validating the determined
;; maximum size of 2 Kb
;;
;; Input:
;;
;; ESI - Pointer to the buffer containing the font filename
;;
;; Output:
;;
;; EAX - Error code:
;;  01h for source not found
;;  02h for unsupported source
;;
;; CF set in case of error

Hexagon.Kernel.Dev.Gen.Console.Console.changeFont:

    call Hexagon.Kernel.FS.VFS.arquivoExiste

    jc .fileNotFound

    mov ebx, 2000

    cmp eax, ebx
    jng .continue

    jmp .incompatibleFont

.continue:

    mov edi, Hexagon.Heap.Temp + 500

    call Hexagon.Kernel.FS.VFS.carregarArquivo

    cmp byte[edi+0], "H"
    jne .incompatibleFont

    cmp byte[edi+1], "F"
    jne .incompatibleFont

    cmp byte[edi+2], "N"
    jne .incompatibleFont

    cmp byte[edi+3], "T"
    jne .incompatibleFont

    mov edi, Hexagon.Fontes.espacoFonte

    call Hexagon.Kernel.FS.VFS.carregarArquivo

    ret

.fileNotFound:

    stc

    mov eax, 01h

    ret

.incompatibleFont:

    stc

    mov eax, 02h

    ret

;;************************************************************************************

;; Use buffer for storing kernel messages and reports

Hexagon.Kernel.Dev.Gen.Console.Console.useKernelConsole:

    mov eax, [Hexagon.Console.Memory.addressLFB]
    mov [Hexagon.Console.Memory.mainConsoleBuffer], eax ;; Save original address

    mov eax, [Hexagon.Console.Memory.kernelConsoleBuffer]
    mov [Hexagon.Console.Memory.addressLFB], eax

    ret

;;************************************************************************************

;; Use main console (main buffer)

Hexagon.Kernel.Dev.Gen.Console.Console.useMainConsole:

    mov eax, [Hexagon.Console.Memory.mainConsoleBuffer]
    mov [Hexagon.Console.Memory.addressLFB], eax ;; Restore original address

    ret

;;************************************************************************************

;; Use secondary console (double buffering)

Hexagon.Kernel.Dev.Gen.Console.Console.useSecondaryConsole:

    mov eax, [Hexagon.Console.Memory.addressLFB]
    mov [Hexagon.Console.Memory.mainConsoleBuffer], eax ;; Save original address

    mov eax, [Hexagon.Console.Memory.secondaryConsoleBuffer]
    mov [Hexagon.Console.Memory.addressLFB], eax

    ret

;;************************************************************************************

;; Copy buffer to video memory

Hexagon.Kernel.Dev.Gen.Console.Console.updateConsole:

    cmp byte[Hexagon.Console.graphicMode], 1
    jne .nothingToDo

    mov eax, dword[Hexagon.Console.consoleSize]
    mov ecx, eax
    shr ecx, 7 ;; Divide by 128

    cmp ebx, 01h
    je .kernelBuffer

.userBuffer:

    mov edi, dword[Hexagon.Console.Memory.mainConsoleBuffer]
    mov esi, dword[Hexagon.Console.Memory.secondaryConsoleBuffer]

    jmp .continue

.kernelBuffer:

    mov edi, dword[Hexagon.Console.Memory.mainConsoleBuffer]
    mov esi, dword[Hexagon.Console.Memory.kernelConsoleBuffer]

.continue:

    push es
    push ds

    mov ax, 18h ;; Kernel linear segment
    mov es, ax
    mov ds, ax

.updateLoop:

    prefetchnta [esi+128]
    prefetchnta [esi+160]
    prefetchnta [esi+192]
    prefetchnta [esi+224]

    movdqa xmm0, [esi+0]
    movdqa xmm1, [esi+16]
    movdqa xmm2, [esi+32]
    movdqa xmm3, [esi+48]
    movdqa xmm4, [esi+64]
    movdqa xmm5, [esi+80]
    movdqa xmm6, [esi+96]
    movdqa xmm7, [esi+112]

    movdqa [edi+0], xmm0
    movdqa [edi+16], xmm1
    movdqa [edi+32], xmm2
    movdqa [edi+48], xmm3
    movdqa [edi+64], xmm4
    movdqa [edi+80], xmm5
    movdqa [edi+96], xmm6
    movdqa [edi+112], xmm7

    add edi, 128
    add esi, 128

    loop .updateLoop

    pop ds
    pop es

.nothingToDo:

    ret

;;************************************************************************************

;; Configures default console resolution and settings during startup

Hexagon.Kernel.Dev.Gen.Console.Console.setupConsole:

.graphicMode1:

    mov eax, 01h

    call Hexagon.Kernel.Dev.Gen.Console.Console.setResolution

    ret
