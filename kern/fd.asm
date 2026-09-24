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
;; Hexagon per-process descriptors
;;
;; Each slot of Hexagon.Processes.Table holds Hexagon.Kern.FD.limit descriptors,
;; inherited from whoever created the process and closed when it ends, as BSD's
;; filedesc does. An entry is one dword:
;;
;;   bits 0-15  - Device id, as in Hexagon.Dev.deviceCodes
;;   bits 16-23 - Device class, 0 for a free descriptor
;;   bits 24-31 - Reserved, always 0
;;
;;************************************************************************************

use32

Hexagon.Kern.FD.limit = 8

;; Device id of the controlling terminal, resolved from Hexagon.Processes.Table.tty
;; on every operation and not when the descriptor is made, so 0, 1 and 2 follow
;; a process that claims another VT

Hexagon.Kern.FD.controllingTTY = 0FFFFh

Hexagon.Kern.FD.outputClass = 04h

Hexagon.Kern.FD.controllingEntry = (Hexagon.Kern.FD.outputClass shl 16) or Hexagon.Kern.FD.controllingTTY

;;************************************************************************************

;; Gives a new slot its descriptors, a copy of its creator's own. With no
;; creator, as for the first process the kernel starts, 0, 1 and 2 name the
;; controlling terminal and the rest are free
;;
;; Input:
;;
;; EDX - New slot
;; EBX - Creator's slot, 0xFF for none

Hexagon.Kern.FD.inherit:

    push eax
    push ecx
    push esi
    push edi

    imul edi, edx, Hexagon.Kern.FD.limit * 4
    add edi, Hexagon.Processes.Table.fd

    mov ecx, Hexagon.Kern.FD.limit

    cmp ebx, 0xFF

    je .noCreator

    imul esi, ebx, Hexagon.Kern.FD.limit * 4
    add esi, Hexagon.Processes.Table.fd

.copyEntry:

    mov eax, dword[esi]
    mov dword[edi], eax

    add esi, 4
    add edi, 4

    loop .copyEntry

    jmp .end

.noCreator:

    mov dword[edi], Hexagon.Kern.FD.controllingEntry
    mov dword[edi + 4], Hexagon.Kern.FD.controllingEntry
    mov dword[edi + 8], Hexagon.Kern.FD.controllingEntry

    add edi, 12

    sub ecx, 3

.clearEntry:

    mov dword[edi], 0

    add edi, 4

    loop .clearEntry

.end:

    pop edi
    pop esi
    pop ecx
    pop eax

    ret

;;************************************************************************************

;; Releases every descriptor a slot still holds, for a process that is ending
;;
;; Input:
;;
;; EDX - Slot

Hexagon.Kern.FD.closeAll:

    push ecx
    push edi

    imul edi, edx, Hexagon.Kern.FD.limit * 4
    add edi, Hexagon.Processes.Table.fd

    mov ecx, Hexagon.Kern.FD.limit

.closeEntry:

    mov dword[edi], 0

    add edi, 4

    loop .closeEntry

    pop edi
    pop ecx

    ret
