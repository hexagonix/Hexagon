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

Hexagon.Libkern.Keyboard.Unix.Codes:

.EOL = 10h

;;************************************************************************************

;; Get size of a string
;;
;; Input:
;;
;; ESI - String
;;
;; Output:
;;
;; EAX - String size

Hexagon.Libkern.String.stringSize:

    push ecx
    push esi
    push edi
    push es

    push ds ;; Kernel data segment
    pop es

    mov edi, esi

    or ecx, 0xFFFFFFFF

    xor al, al

    cld ;; Clear direction

    repne scasb ;; Search for end of string in EDI

    or eax, 0xFFFFFFFF

    sub eax, ecx

    dec eax ;; Not including character 0

    pop es
    pop edi
    pop esi
    pop ecx

    ret

;;************************************************************************************

;; Compare first words of two strings
;;
;; Input:
;;
;; ESI - First string
;; EDI - Second string
;;
;; Output:
;;
;; Carry defined if strings are equal

Hexagon.Libkern.String.compareWordsInString:

    push eax
    push esi
    push edi

.compareLoop:

    mov al, byte[esi]

    cmp al, ' '
    je .isEqual

    cmp al, byte[edi]
    jne .isNotEqual

    cmp byte[edi], 0
    je .isEqual

    inc esi

    inc edi

    jmp .compareLoop

.isNotEqual:

    clc

    jmp .end

.isEqual:

    cmp byte[edi], 0
    jne .isNotEqual

    stc

.end:

    pop edi
    pop esi
    pop eax

    ret

;;************************************************************************************

;; Compare two strings
;;
;; Input:
;;
;; ESI - First string
;; EDI - Second string
;;
;; Output:
;;
;; Carry defined if strings are equal

Hexagon.Libkern.String.isEqual:

    push eax
    push esi
    push edi

.compareLoop:

    mov al, byte[edi]

    cmp al, 0 ;; End of string
    je .isEqual

    cmp al, byte[esi]
    jne .isNotEqual

    inc esi

    inc edi

    jmp .compareLoop

.isNotEqual:

    clc

    jmp .end

.isEqual:

    stc

.end:

    pop edi
    pop esi
    pop eax

    ret

;;************************************************************************************

;; Convert a string to uppercase
;;
;; Input:
;;
;; ESI - String
;;
;; Output:
;;
;; ESI - Converted string

Hexagon.Libkern.String.toUppercase:

    push eax
    push ecx
    push esi

    mov al, byte[esi]

    cmp al, 0
    je .end

    call Hexagon.Libkern.String.stringSize

    mov ecx, eax

.convertLoop:

    mov al, byte[esi]

.check1:

    cmp al, 'a' ;; Check if the character is lowercase
    jae .check2

    inc esi

    loop .convertLoop

    jmp .end

.check2:

    cmp al, 'z' ;; Check if the character is lowercase
    jbe .ok

    inc esi

    loop .convertLoop

    jmp .end

.ok:

    sub al, ' ' ;; Convert if character is lowercase
    mov byte[esi], al

    inc esi

    loop .convertLoop

.end:

    pop esi
    pop ecx
    pop eax

    ret

;;************************************************************************************

;; Convert a string to lowercase
;;
;; Input:
;;
;; ESI - String
;;
;; Output:
;;
;; ESI - Converted string

Hexagon.Libkern.String.toLowercase:

    push eax
    push ecx
    push esi

    mov al, byte[esi]

    cmp al, 0
    je .end

    call Hexagon.Libkern.String.stringSize

    mov ecx, eax

.convertLoop:

    mov al, byte[esi]

.check1:

    cmp al, 'A' ;; Check if the character is uppercase
    jae .check2

    inc esi

    loop .convertLoop

    jmp .end

.check2:

    cmp al, 'Z' ;; Check if the character is uppercase
    jbe .ok

    inc esi

    loop .convertLoop

    jmp .end

.ok:

    add al, ' ' ;; Convert if character is uppercase
    mov byte[esi], al

    inc esi

    loop .convertLoop

.end:

    pop esi
    pop ecx
    pop eax

    ret

;;************************************************************************************

;; Remove whitespace from beginning to end of string
;;
;; Input:
;;
;; ESI - String

Hexagon.Libkern.String.trimString:

    push eax
    push ebx
    push ecx
    push esi
    push edi

    push es

    push ds ;; Kernel data segment
    pop es

;; First we need to remove the spaces from the left and then from the right

    cmp byte[esi], 0 ;; If empty string, exit
    je .end

    call Hexagon.Libkern.String.stringSize ;; Get string size in EAX

    mov ecx, eax ;; Put this in ECX to use in a loop

    push esi ;; Save position in string for future use
    push ecx ;; Save string size for future use

    xor ebx, ebx ;; EBX is a blank counter

    cld ;; From left to right, then clearing the direction flag

.cutFromLeft:

    lodsb

    cmp al, ' '
    je .cutLeft

    jmp short .noSpaceLeft

.cutLeft:

    inc ebx

    mov byte[esi-1], 0 ;; Fill spaces with 0

    loop .cutFromLeft

.noSpaceLeft:

    pop ecx ;; Restore string size
    pop esi ;; Restore position in string

    push esi
    push ecx

    mov edi, esi
    add esi, ebx ;; Add total blanks spaces

    rep movsb ;; Move string to new position

    pop ecx

    sub ecx, ebx

    pop esi

    add esi, ecx

    dec esi

    std ;; Set direction to decrement from right to left

.cutFromRight:

    lodsb

    cmp al, ' '
    je .cutRight

    jmp short .noSpaceRight

.cutRight:

    mov byte[esi+1], 0 ;; Fill spaces with 0

    loop .cutFromRight

    jmp .end

.noSpaceRight:

.end:

    cld

    pop es
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop eax

    ret

;;************************************************************************************

;; Convert ASCII integer decimal to integer
;;
;; Input:
;;
;; ESI - String
;;
;; Output:
;;
;; EAX - Integer
;; CF defined in case of incorrect number

Hexagon.Libkern.String.stringToInteger:

    push ebx
    push ecx
    push edx
    push esi

    mov dword[.number], 0

    mov al, '-'

    call Hexagon.Libkern.String.findCharacterInString

    cmp eax, 1
    ja .negative

.positive:

    mov byte[.negativeFlag], 0

    jmp .next

.negative:

    inc esi

    mov byte[.negativeFlag], 1

.next:

    call Hexagon.Libkern.String.stringSize ;; Get string size

    mov ecx, eax ;; Use counting in the loop
    add esi, eax

    dec esi

    mov ebx, 0
    mov eax, 1

.convertLoop:

    mov bl, byte[esi]

    dec esi

    sub bl, 30h

    cmp bl, 9
    ja .invalidNumber

    mov edx, 10

    mul edx

    push eax

    mul ebx

    add dword[.number], eax

    pop eax

    loop .convertLoop

    mov ebx, 10
    mov eax, dword[.number]
    mov edx, 0

    div ebx ;; Divide by 10

    mov dword[.number], 0

.successful:

    cmp byte[.negativeFlag], 0
    je .done

    neg eax

.done:

    clc

    jmp short .end

.invalidNumber:

    mov eax, 0

    stc

.end:

    pop esi
    pop edx
    pop ecx
    pop ebx

    ret

.number:       dd 0
.negativeFlag: db 0

;;************************************************************************************

;; Find a particular character in a string
;;
;; Input:
;;
;; ESI - String
;; AL  - Character to search for
;;
;; Output:
;;
;; EAX - Number of occurrences of this character
;; CF set if character not found

Hexagon.Libkern.String.findCharacterInString:

    push ebx
    push ecx
    push edx
    push esi

    mov bl, al
    xor ecx, ecx

.findLoop:

    lodsb

    or al, al ;; cmp AL, 0 (last character)
    jz .next

    cmp al, bl ;; Character found
    jne .findLoop

    inc ecx ;; Counter

    jmp .findLoop

.next:

    mov eax, ecx

    or eax, eax ;; cmp EDX, 0
    jz .notFound

    clc

    jmp .end

.notFound:

    stc

.end:

    pop esi
    pop edx
    pop ecx
    pop ebx

    ret

;;************************************************************************************

;; Remove a character from a specific position in the string
;;
;; Input:
;;
;; ESI - String
;; EAX - Character position

Hexagon.Libkern.String.removeCharacterInString:

    push esi
    push edx

    mov edx, eax

    call Hexagon.Libkern.String.stringSize

    cmp edx, eax ;; EAX is the size of the string
    ja .end

    inc eax ;; Including the last null character

    add esi, edx

    push es

    push ds ;; Kernel data segment
    pop es

    mov edi, esi

    inc esi ;; Next character

    mov ecx, eax

    cld ;; Clear direction

    rep movsb ;; Move (ECX) characters from ESI to EDI

    pop es
    pop edx
    pop esi

.end:

    ret

;;************************************************************************************

;; Insert a character in a specific position in the string
;;
;; Input:
;;
;; ESI - String
;; EDX - Character position
;; AL  - Character to insert
;;
;; The string buffer must be large enough!

Hexagon.Libkern.String.insertCharacterInString:

    push eax
    push ebx
    push ecx
    push edi

    mov ebx, eax ;; Save character

    push esi

;; Create space to include the character

    call Hexagon.Libkern.String.stringSize

    push eax ;; EAX is the size of the string

    add esi, eax

    inc esi ;; Including null character

    push es

    push ds ;; Kernel data segment
    pop es

    std ;; Reverse direction in rep movsb

    add esi, edx

    dec esi

    mov edi, esi

    dec esi

    mov ecx, eax

    rep movsb ;; Move (ECX) characters from ESI to EDI

    pop es

    pop eax
    pop esi

;; Insert character here

    mov byte[esi+edx], bl ;; BL has the character
    mov byte[esi+eax+1],0 ;; Create end of string

    cld

    pop edi
    pop ecx
    pop ebx
    pop eax

    ret

;;************************************************************************************

;; Converts an integer to a string
;;
;; Input:
;;
;; EAX - Integer
;;
;; Output:
;;
;; ESI - Pointer with content

Hexagon.Libkern.String.integetToString:

    push es

    push ds ;; Kernel data segment
    pop es

    push eax
    push ecx
    push edx
    push esi
    push edi

;; Check if negative

    cmp eax, 0
    jge .positive

.negative:

    push eax

    mov al, '-' ;; Print '-'

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

    add dl, 0x30 ;; Convert to ASCII

    push edx

    inc ecx

    or eax, eax ;; cmp EAX, 0
    jne .convertLoop

    mov edx, esi

    mov edx, 0

    mov ebx, .buffer

.printLoop:

    pop eax

    mov [ebx+edx], eax

    inc edx

    loop .printLoop

.end:

    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax

    mov esi, .buffer

    pop es

    ret

.buffer:
times 16 db 0

;;************************************************************************************

;; Performs BCD to ASCII (character) conversion
;;
;; Input:
;;
;; AL - Value in BCD
;;
;; Output:
;;
;; AX - Value in ASCII (character)

Hexagon.Libkern.String.BCDToASCII:

    push ecx

    mov ah, al

    and ax, 0xF00F ;; Mask bits
    shr ah, 4      ;; Shift right AH to get unwrapped BCD
    or ax, 3030h   ;; Match 30 to get ASCII
    xchg ah, al    ;; Swap for ASCII convention

    pop ecx

    ret
