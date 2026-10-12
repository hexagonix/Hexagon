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

;; Returns Hexagon version and subversion numbers to requesting applications
;;
;; The two strings are written into a buffer the caller owns, and not named
;; by a pointer of the kernel's own, which is what a caller at user level could
;; not read at all and what would otherwise need an adapter between this and
;; the system call table
;;
;; Input:
;;
;; EDI - Caller's own buffer, at least Hexagon.Kern.Uname.bufferLength bytes.
;;       The kernel's name is written at the start of it and its build at
;;       Hexagon.Kern.Uname.buildOffset, both NUL terminated, so a caller
;;       reaches either one without walking the other
;;
;;       Always required, even by a caller that only wants the numbers. There is
;;       no "no buffer" value to pass: hexagonHandler adds the process base to
;;       EDI on every call, so a 0 arrives here as the base itself and the write
;;       would land on the caller's own image
;;
;; Output:
;;
;; EAX - Hexagon version number
;; EBX - Hexagon subversion number
;; ECX - Kernel revision
;; EDX - Architecture
;; EDI - Preserved

Hexagon.Kern.Uname.bufferLength = 96
Hexagon.Kern.Uname.buildOffset  = 48

Hexagon.Kern.Uname.uname:

;; The buffer is the caller's, and this writes into it at CPL 0, where paging
;; refuses nothing. Check it is one that caller could reach by itself first

    push ebx
    push ecx

    mov ebx, edi
    mov ecx, Hexagon.Kern.Uname.bufferLength

    call Hexagon.Arch.Paging.rangeIsCallerWritable

    pop ecx
    pop ebx

    jc .badBuffer

    push es
    push esi
    push edi

    push ds ;; stosb below writes through ES:EDI
    pop es

    cld

    mov esi, Hexagon.Version.kernelName

    call .copyString

    mov edi, dword[esp] ;; Back to the start of the buffer, then to the build's own half
    add edi, Hexagon.Kern.Uname.buildOffset

    mov esi, Hexagon.Version.kernelBuild

    call .copyString

    pop edi
    pop esi
    pop es

    mov eax, Hexagon.Version.versionNumber
    mov ebx, Hexagon.Version.subversionNumber
    mov ecx, Hexagon.Version.revision
    mov edx, Hexagon.Arch.support

    clc

    ret

.badBuffer:

    mov eax, Hexagon.Kern.Proc.badAddress

    stc

    ret

;; One NUL terminated string from ESI to EDI

.copyString:

    lodsb

    stosb

    cmp al, 0

    jne .copyString

    ret
