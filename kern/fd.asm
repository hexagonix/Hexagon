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
;;   bits 24-31 - Flags of this descriptor, Hexagon.Kern.FD.Flags
;;
;; Whatever names a device reads only the low 24 bits, so a flag never changes
;; which device an entry is
;;
;;************************************************************************************

use32

Hexagon.Kern.FD.limit = 16

Hexagon.Kern.FD.Flags.nonBlocking  = 80000000h ;; Reads and writes return instead of waiting
Hexagon.Kern.FD.Flags.closeOnSpawn = 40000000h ;; Not handed to a new process, as FD_CLOEXEC
Hexagon.Kern.FD.Flags.all          = 0FF000000h

;; hx.ioctl commands every descriptor takes, out of the range of any class,
;; as FIONBIO in BSD

Hexagon.Kern.FD.Commands.nonBlocking  = 100h ;; ECX = 1 to set, 0 to clear
Hexagon.Kern.FD.Commands.closeOnSpawn = 101h ;; The same, as FIOCLEX and FIONCLEX

;; Device id of the controlling terminal, resolved from Hexagon.Processes.Table.tty
;; on every operation and not when the descriptor is made, so 0, 1 and 2 follow
;; a process that claims another VT

Hexagon.Kern.FD.controllingTTY = 0FFFFh

Hexagon.Kern.FD.outputClass = 04h

Hexagon.Kern.FD.controllingEntry = (Hexagon.Kern.FD.outputClass shl 16) or Hexagon.Kern.FD.controllingTTY

;; Error codes, as the system calls return them

Hexagon.Kern.FD.badDescriptor    = 9
Hexagon.Kern.FD.noFreeDescriptor = 10
Hexagon.Kern.FD.wouldBlock       = 11

;;************************************************************************************

;; Gives a new slot its descriptors, a copy of its creator's own, apart from
;; those marked Hexagon.Kern.FD.Flags.closeOnSpawn, which it gets free. With no
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

    mov byte[Hexagon.Processes.Table.nonBlocking + edx], 0
    mov byte[Hexagon.Processes.Table.wouldBlock + edx], 0

    imul edi, edx, Hexagon.Kern.FD.limit * 4
    add edi, Hexagon.Processes.Table.fd

    mov ecx, Hexagon.Kern.FD.limit

    cmp ebx, 0xFF

    je .noCreator

    imul esi, ebx, Hexagon.Kern.FD.limit * 4
    add esi, Hexagon.Processes.Table.fd

.copyEntry:

    mov eax, dword[esi]

    test eax, Hexagon.Kern.FD.Flags.closeOnSpawn

    jz .inherited

    xor eax, eax

.inherited:

    mov dword[edi], eax

    cmp eax, 0

    je .copied

    call Hexagon.Kernel.Dev.Dev.referenceEntry

.copied:

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

    push eax
    push ecx
    push edi

    imul edi, edx, Hexagon.Kern.FD.limit * 4
    add edi, Hexagon.Processes.Table.fd

    mov ecx, Hexagon.Kern.FD.limit

.closeEntry:

    mov eax, dword[edi]

    cmp eax, 0

    je .nextEntry

    call Hexagon.Kernel.Dev.Dev.closeEntry

    mov dword[edi], 0

.nextEntry:

    add edi, 4

    loop .closeEntry

    pop edi
    pop ecx
    pop eax

    ret

;;************************************************************************************

;; Takes the lowest free descriptor of the running process
;;
;; Input:
;;
;; EAX - Entry to store
;;
;; Output:
;;
;; EAX - Descriptor, or an error code with CF set

Hexagon.Kern.FD.allocate:

    push ecx
    push edi

    movzx edi, byte[Hexagon.Scheduler.current]

    cmp edi, 0xFF

    je .noneFree

    imul edi, edi, Hexagon.Kern.FD.limit * 4
    add edi, Hexagon.Processes.Table.fd

    xor ecx, ecx

.checkEntry:

    cmp dword[edi + ecx * 4], 0

    je .found

    inc ecx

    cmp ecx, Hexagon.Kern.FD.limit

    jb .checkEntry

.noneFree:

    mov eax, Hexagon.Kern.FD.noFreeDescriptor

    pop edi
    pop ecx

    stc

    ret

.found:

    mov dword[edi + ecx * 4], eax

    mov eax, ecx

    pop edi
    pop ecx

    clc

    ret

;;************************************************************************************

;; Reads one of the running process's descriptors
;;
;; Input:
;;
;; EAX - Descriptor
;;
;; Output:
;;
;; EAX - Its entry, or Hexagon.Kern.FD.badDescriptor with CF set

Hexagon.Kern.FD.lookup:

    push edi

    movzx edi, byte[Hexagon.Scheduler.current]

    cmp edi, 0xFF

    je .bad

    cmp eax, Hexagon.Kern.FD.limit

    jae .bad

    imul edi, edi, Hexagon.Kern.FD.limit * 4
    add edi, Hexagon.Processes.Table.fd

    mov eax, dword[edi + eax * 4]

    cmp eax, 0

    je .bad

    pop edi

    clc

    ret

.bad:

    mov eax, Hexagon.Kern.FD.badDescriptor

    pop edi

    stc

    ret

;;************************************************************************************

;; Frees one of the running process's descriptors
;;
;; Input:
;;
;; EAX - Descriptor, already checked by Hexagon.Kern.FD.lookup

Hexagon.Kern.FD.release:

    push edi

    movzx edi, byte[Hexagon.Scheduler.current]

    imul edi, edi, Hexagon.Kern.FD.limit * 4
    add edi, Hexagon.Processes.Table.fd

    mov dword[edi + eax * 4], 0

    pop edi

    ret

;;************************************************************************************

;; Makes a descriptor name what another one does, closing it first if it was
;; open, as BSD's dup2
;;
;; Input:
;;
;; EAX - Descriptor to copy
;; EBX - Descriptor to make a copy of it
;;
;; Output:
;;
;; EAX - EBX's descriptor, or Hexagon.Kern.FD.badDescriptor with CF set

Hexagon.Kern.FD.dup2:

    push ebx
    push ecx
    push edi

    cmp ebx, Hexagon.Kern.FD.limit

    jae .bad

    mov ecx, eax ;; The descriptor to copy, kept for the comparison below

    call Hexagon.Kern.FD.lookup ;; EAX = its entry

    jc .bad

    cmp ecx, ebx

    je .same

    push eax
    push ebx
    push ecx

    mov eax, ebx

    call Hexagon.Kernel.Dev.Dev.close ;; Nothing to do when it was not open

    pop ecx
    pop ebx
    pop eax

    movzx edi, byte[Hexagon.Scheduler.current]

    imul edi, edi, Hexagon.Kern.FD.limit * 4
    add edi, Hexagon.Processes.Table.fd

    and eax, not Hexagon.Kern.FD.Flags.all ;; The copy starts with no flags, as in BSD

    mov dword[edi + ebx * 4], eax

    call Hexagon.Kernel.Dev.Dev.referenceEntry

.same:

    mov eax, ebx

    pop edi
    pop ecx
    pop ebx

    clc

    ret

.bad:

    mov eax, Hexagon.Kern.FD.badDescriptor

    pop edi
    pop ecx
    pop ebx

    stc

    ret

;;************************************************************************************

;; Sets or clears a flag of one of the running process's descriptors
;;
;; Input:
;;
;; EAX - Descriptor
;; EDX - Flag, from Hexagon.Kern.FD.Flags
;; ECX - 1 to set it, 0 to clear it
;;
;; Output:
;;
;; CF set and EAX = Hexagon.Kern.FD.badDescriptor if the descriptor is not open

Hexagon.Kern.FD.setFlag:

    push edx
    push edi

    movzx edi, byte[Hexagon.Scheduler.current]

    cmp edi, 0xFF

    je .bad

    cmp eax, Hexagon.Kern.FD.limit

    jae .bad

    imul edi, edi, Hexagon.Kern.FD.limit * 4
    add edi, Hexagon.Processes.Table.fd

    lea edi, [edi + eax * 4]

    cmp dword[edi], 0

    je .bad

    cmp ecx, 0

    je .clear

    or dword[edi], edx

    jmp .done

.clear:

    not edx

    and dword[edi], edx

.done:

    pop edi
    pop edx

    clc

    ret

.bad:

    mov eax, Hexagon.Kern.FD.badDescriptor

    pop edi
    pop edx

    stc

    ret

;;************************************************************************************

;; A read or write of the running process starts. Whether it may wait comes from
;; the descriptor, and is kept for the slot while the call lasts. Every register
;; is preserved
;;
;; Input:
;;
;; EAX - Descriptor

Hexagon.Kern.FD.beginCall:

    pushad

    movzx edx, byte[Hexagon.Scheduler.current]

    cmp edx, 0xFF

    je .done

    mov byte[Hexagon.Processes.Table.nonBlocking + edx], 0
    mov byte[Hexagon.Processes.Table.wouldBlock + edx], 0

    cmp eax, Hexagon.Kern.FD.limit

    jae .done ;; Reported by whoever resolves the descriptor

    imul edi, edx, Hexagon.Kern.FD.limit * 4

    test dword[Hexagon.Processes.Table.fd + edi + eax * 4], Hexagon.Kern.FD.Flags.nonBlocking

    jz .done

    mov byte[Hexagon.Processes.Table.nonBlocking + edx], 1

.done:

    popad

    ret

;; The call has ended. One that returned because it would have had to wait
;; answers Hexagon.Kern.FD.wouldBlock with CF set, whatever the class returned
;;
;; Input/Output: EAX and CF as the class left them

Hexagon.Kern.FD.endCall:

    pushfd
    push edx

    movzx edx, byte[Hexagon.Scheduler.current]

    cmp edx, 0xFF

    je .keep

    mov byte[Hexagon.Processes.Table.nonBlocking + edx], 0

    cmp byte[Hexagon.Processes.Table.wouldBlock + edx], 0

    je .keep

    mov byte[Hexagon.Processes.Table.wouldBlock + edx], 0

    pop edx
    popfd

    mov eax, Hexagon.Kern.FD.wouldBlock

    stc

    ret

.keep:

    pop edx
    popfd

    ret

;; Asked by whatever is about to wait for data or room. A call that may not wait
;; is marked as having had to, and the caller returns with what it has
;;
;; Output:
;;
;; CF set if the running process's call may not wait

Hexagon.Kern.FD.mayWait:

    push eax

    movzx eax, byte[Hexagon.Scheduler.current]

    cmp eax, 0xFF

    je .may

    cmp byte[Hexagon.Processes.Table.nonBlocking + eax], 0

    je .may

    mov byte[Hexagon.Processes.Table.wouldBlock + eax], 1

    pop eax

    stc

    ret

.may:

    pop eax

    clc

    ret

;; Something was read or written after all, so the call is not answered with
;; Hexagon.Kern.FD.wouldBlock. Every register and the flags are preserved

Hexagon.Kern.FD.didTransfer:

    pushfd
    push eax

    movzx eax, byte[Hexagon.Scheduler.current]

    cmp eax, 0xFF

    je .done

    mov byte[Hexagon.Processes.Table.wouldBlock + eax], 0

.done:

    pop eax
    popfd

    ret

;; Output: CF set if the running process's call returned because it would have
;; had to wait, as Hexagon.Kern.FD.mayWait records it

Hexagon.Kern.FD.hadToWait:

    push eax

    movzx eax, byte[Hexagon.Scheduler.current]

    cmp eax, 0xFF

    je .no

    cmp byte[Hexagon.Processes.Table.wouldBlock + eax], 0

    je .no

    pop eax

    stc

    ret

.no:

    pop eax

    clc

    ret
