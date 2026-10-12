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

;; Devfs: a synthetic filesystem mounted at /dev (Hexagon.Kernel.FS.VFS.mount's
;; "devfs" pseudo-device, see vfs.asm), listing devices Hexagon already knows
;; about instead of files on real media

;; Builds the devfs entry list, following the list-builder contract on
;; Hexagon.Kernel.FS.VFS.listFiles. Every entry uses 90h (filenameSeparator,
;; an equ not forward-referenceable here), since devfs has no subdirectories.
;;
;; Output:
;;
;; ESI - Kernel-owned list
;; EAX - Entry count
;; CF  - Never set here, there's no disk I/O to fail on

Hexagon.Kernel.FS.DEVFS.listFilesDevFS:

    push ebx
    push ecx
    push edx
    push edi
    push es

;; See Hexagon.Kernel.FS.VFS.listFiles for why every filesystem's own list
;; builder resets ES right before using stosb/movsb, instead of assuming
;; whatever the caller happened to leave it at

    mov ax, 10h
    mov es, ax

    mov edi, Hexagon.DEVFS.listBuffer

    xor ebx, ebx ;; Entry counter
    xor ecx, ecx ;; Index into Hexagon.Dev.Registry

.entryLoop:

    cmp ecx, dword[Hexagon.Dev.Registry.count]
    jae .finish

    mov edx, dword[Hexagon.Dev.Registry.base]

    imul eax, ecx, 8

    add edx, eax

    mov esi, edx

    call .appendEntry

    inc ecx

    jmp .entryLoop

.finish:

    mov byte[edi], 0 ;; Terminate the whole list

    mov esi, Hexagon.DEVFS.listBuffer
    mov eax, ebx

    clc

    pop es
    pop edi
    pop edx
    pop ecx
    pop ebx

    ret

;; Copies one NUL-terminated name (ESI) into the list being built at EDI,
;; replacing the NUL with the filename separator, then advances EDI past it
;; and counts the entry in EBX
;;
;; Input: ESI - Name to append, EDI - Current write position in the list
;; Output: EDI advanced past the appended entry, EBX incremented, ESI clobbered

.appendEntry:

.copyChar:

    lodsb

    cmp al, 0
    je .terminated

    stosb

    jmp .copyChar

.terminated:

    mov byte[edi], 90h ;; Hexagon.VFS.FAT.filenameSeparator

    inc edi
    inc ebx

    ret

Hexagon.DEVFS.listBuffer:
times 512 db 0

;;************************************************************************************

;; Looks up a single devfs entry by name
;;
;; Input:
;;
;; ESI - Path component to look up, still carrying the leading '/' that
;;       Hexagon.Kernel.FS.VFS.resolveMount always leaves on a mount's own
;;       remainder
;;
;; Output:
;;
;; EAX - 0 (devfs entries carry no meaningful size)
;; EBX - Pointer to a scratch record with the attribute byte at offset 11
;;       (the same offset Hexagon.Kernel.FS.VFS.mount's own mount-point
;;       check reads), set to 10h for "/dev" itself and 0 for every entry
;;       under it, since devfs has no real subdirectories yet. Offsets
;;       12/13/14 carry the matched entry's Hexagon.Dev.Registry type/
;;       major/minor, left 0 for "/dev" itself
;; CF  - Set if nothing matches

Hexagon.Kernel.FS.DEVFS.fileExistsDevFS:

    push ecx
    push edx
    push edi

    cmp byte[esi], '/'
    jne .notFound ;; resolveMount always leaves a leading '/' here

    cmp byte[esi + 1], 0
    jne .lookupEntry

    mov byte[.record + 11], 10h ;; "/dev" itself, reported as a directory

;; Cleared explicitly instead of left holding whatever a previous lookup on
;; this same static buffer wrote there, since "/dev" itself is not a device

    mov byte[.record + 12], 0
    mov byte[.record + 13], 0
    mov byte[.record + 14], 0

    jmp .foundRecord

.lookupEntry:

    inc esi ;; Skip the leading '/'

    xor ecx, ecx

.entryLoop:

    cmp ecx, dword[Hexagon.Dev.Registry.count]
    jae .notFound

    mov edi, dword[Hexagon.Dev.Registry.base]

    imul edx, ecx, 8

    add edi, edx

    call Hexagon.Libkern.String.compareWordsInString

    jc .found

    inc ecx

    jmp .entryLoop

.found:

    mov byte[.record + 11], 0 ;; Not a directory

    mov edi, dword[Hexagon.Dev.Registry.base]

    add edi, Hexagon.Dev.Registry.types

    mov al, byte[edi + ecx]
    mov byte[.record + 12], al

    mov edi, dword[Hexagon.Dev.Registry.base]

    add edi, Hexagon.Dev.Registry.majors

    mov al, byte[edi + ecx]
    mov byte[.record + 13], al

    mov edi, dword[Hexagon.Dev.Registry.base]

    add edi, Hexagon.Dev.Registry.minors
    
    mov al, byte[edi + ecx]
    mov byte[.record + 14], al

.foundRecord:

    xor eax, eax
    mov ebx, .record

    clc

    jmp .done

.notFound:

    stc

.done:

    pop edi
    pop edx
    pop ecx

    ret

.record: times 32 db 0
