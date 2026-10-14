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

;; Walks the HXBI block HBoot left behind. Panics outright on a bad
;; signature, since nothing here has a fallback left to try
;;
;; Input:
;;
;; EBX - Physical address of the HXBI block

Hexagon.HXBI.parse:

    push eax
    push ecx
    push edx
    push esi
    push edi

    cmp dword[ebx], "HXBI"

    jne .badBlock

    cmp dword[ebx + 4], 1 ;; Only revision 1 of the block exists so far

    jne .badBlock

    mov edx, 16 ;; Cursor, right after the fixed 16-byte header

.nextTag:

;; A tag stream that runs past the size the block claims for itself is
;; malformed, so stop at that boundary and do not read whatever follows

    cmp edx, dword[ebx + 8]
    jae .done

    mov eax, dword[ebx + edx] ;; Tag type

    cmp eax, 0
    je .done

    cmp eax, 2
    je .memoryMap

    cmp eax, 3
    je .bootDevice

    cmp eax, 4
    je .commandLine

    cmp eax, 5
    je .framebuffer

    jmp .advance

.memoryMap:

    lea esi, [ebx + edx + 8] ;; entrySize/entryCount fields

    mov edi, dword[esi + 4] ;; entryCount

    add esi, 8 ;; First entry

    xor eax, eax ;; Running total, in bytes

.memEntryLoop:

    cmp edi, 0
    je .memEntryDone

    cmp dword[esi + 16], 1 ;; type == usable

    jne .memEntrySkip

    add eax, dword[esi + 8] ;; Length's low dword only, this kernel is 32-bit only

.memEntrySkip:

    add esi, 20
    dec edi

    jmp .memEntryLoop

.memEntryDone:

    mov dword[Hexagon.Memory.totalMemory], eax

    jmp .advance

.bootDevice:

    lea esi, [ebx + edx + 8]

    mov al, byte[esi]
    mov byte[Hexagon.Dev.Disk.Control.bootDisk], al

    lea eax, [esi + 4] ;; The embedded boot sector, right after driveNumber/reserved
    
    mov dword[Hexagon.Memory.addressBPB], eax

    jmp .advance

.commandLine:

    lea esi, [ebx + edx + 8]

    mov edi, Hexagon.Boot.Parameters.commandLine
    mov ecx, 256

.copyCommandLine:

    mov al, byte[esi]
    mov byte[edi], al

    inc esi
    inc edi

    loop .copyCommandLine

    jmp .advance

.framebuffer:

    lea esi, [ebx + edx + 8]

    mov eax, dword[esi] ;; Low dword of the address only, this kernel is 32-bit
    mov dword[Hexagon.Boot.Framebuffer.address], eax

    mov eax, dword[esi + 8]
    mov dword[Hexagon.Boot.Framebuffer.pitch], eax

    mov eax, dword[esi + 12]
    mov dword[Hexagon.Boot.Framebuffer.width], eax

    mov eax, dword[esi + 16]
    mov dword[Hexagon.Boot.Framebuffer.height], eax

    mov al, byte[esi + 20]
    mov byte[Hexagon.Boot.Framebuffer.bpp], al

    jmp .advance

.advance:

    mov ecx, dword[ebx + edx + 4] ;; This tag's own size, header included

    add ecx, 3

    and ecx, not 3 ;; Every tag starts on a 4-byte boundary

;; Anything smaller than a bare header would leave the cursor where it is
;; and walk the same tag forever

    cmp ecx, 8
    jb .badBlock

    add edx, ecx

    jmp .nextTag

.done:

    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax

    ret

.badBlock:

    mov esi, Hexagon.Verbose.HXBI.invalidBlock

    call Hexagon.Kern.Panic.panic
