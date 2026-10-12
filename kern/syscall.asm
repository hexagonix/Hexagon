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

Hexagon.Syscall.Control:

.systemCall:        db 0 ;; Stores whether or not a call was made
.totalCalls:        dd 70

;;************************************************************************************

;; Hexagonix Interrupt Handler
;;
;; Output:
;;
;; EBP = 0xABC12345 in case of function not available
;; CF defined in case of function not available

Hexagon.Kern.Syscall.hexagonHandler:

    push ebp ;; Save caller's EBP
    push ds  ;; Save caller's DS
    push es  ;; Save caller's ES

    push 10h ;; Kernel data segment
    pop ds

    push 18h ;; Kernel linear segment
    pop es

    cld

    push eax

    call Hexagon.Kern.Sched.getCurrentProcessBase ;; EAX = base of whichever process is running now

    add esi, eax
    add edi, eax

;; The number was pushed on the caller's own stack, which the processor left
;; behind when it switched to this one on the way in. The frame records where
;; that stack was, and EAX still carries the base it is measured from

    mov ebp, dword[esp + 28] ;; Caller's own ESP, pointing at the number

    add ebp, eax

    mov ebp, dword[ebp] ;; The requested call itself

    pop eax

    cmp ebp, dword[Hexagon.Syscall.Control.totalCalls]
    ja .unavailableCall

    mov byte[Hexagon.Syscall.Control.systemCall], 01h ;; A call was requested

    sti

    call dword[Hexagon.Kern.Syscall.hexagonServices.table + ebp * 4]

.end:

    push ebp ;; Save returned EBP (such as from nullSystemCall)
    pushfd   ;; Save returned flags (including CF)

    mov byte[Hexagon.Syscall.Control.systemCall], 00h

    push eax

    call Hexagon.Kern.Sched.getCurrentProcessBase ;; EAX = base of whichever process is running now

    mov ebp, eax

    pop eax

    sub esi, ebp
    sub edi, ebp

    pop ebp ;; Pop returned flags into EBP

    test ebp, 1 ;; Check CF in returned flags
    jz .cfClear

    or dword[esp + 24], 1 ;; Set CF in caller's saved EFLAGS
    jmp .cfDone

.cfClear:

    and dword[esp + 24], 0xFFFFFFFE ;; Clear CF in caller's saved EFLAGS

.cfDone:

    pop ebp ;; EBP = returned EBP
    
    cmp ebp, 0xABC12345
    je .keepReturnedEBP
    
    mov ebp, dword[esp + 8] ;; Restore caller's original EBP

.keepReturnedEBP:

    pop es
    pop ds

    add esp, 4 ;; Discard saved EBP slot

.returnToUser:

;; The caller pushed the call number on its own stack, and it is still sitting
;; there. Returning one dword past it is what drops it, so an application never
;; has to clean up after its own call

    add dword[esp + 12], 4 ;; Caller's own ESP, as the frame recorded it

    iret

.unavailableCall:

    push eax

    call Hexagon.Kern.Sched.getCurrentProcessBase

    mov ebp, eax

    pop eax

    sub esi, ebp
    sub edi, ebp

    or dword[esp + 20], 1 ;; Set CF in caller's saved EFLAGS

    pop es
    pop ds
    
    add esp, 4 ;; Discard saved EBP

    mov ebp, 0xABC12345

    jmp .returnToUser

;;************************************************************************************

Hexagon.Kern.Syscall.nullSystemCall:

    mov ebp, 0xABC12345

    stc

    ret

;;************************************************************************************

;; hx.malloc's own registered syscall entry, in place of calling
;; Hexagon.Arch.Mm.malloc directly. Mm.malloc operates on genuine
;; flat addresses, while a caller's own DS is based at its
;; Hexagon.Processes.Table.base. Handed back unchanged, a plain [ebx] in the
;; caller would land at Table.base past the block, so the pointer is
;; translated here the way hexagonHandler already translates ESI and EDI
;;
;; Input/output: same as Hexagon.Arch.Mm.malloc (EBX size in, EAX/EBX
;; pointer out)

Hexagon.Kern.Syscall.malloc:

    push ecx
    push edx

;; What the caller gets begins on a page boundary and covers whole pages, so
;; that the pages opened to it hold nothing but its own block: no neighbour,
;; and not even this block's own header, which the allocator leaves behind in
;; the page in front. Page permissions are the only granularity there is, so
;; anything sharing a page with the caller would be handed to it as well

    add ebx, 0FFFh
    and ebx, not 0FFFh

    push ebx ;; The rounded size, which is exactly what gets opened below

    mov edx, 1000h

    call Hexagon.Arch.Mm.mallocAligned

    cmp eax, 0
    je .withoutMemory

;; Nothing of whoever held this memory before is this process's to read

    mov ecx, dword[esp] ;; The rounded size

    call Hexagon.Kern.Proc.clearForProcess

;; The block comes out of the kernel's own arena and not the caller's block,
;; so the pages it covers are opened to user level before the pointer goes back

    movzx edx, byte[Hexagon.Scheduler.current] ;; Whose the pages being opened are

    mov eax, dword[Hexagon.Processes.Table.pageDirectory + edx * 4]

    mov ecx, dword[esp] ;; The rounded size

    call Hexagon.Arch.Paging.openRangeToUser ;; EBX already carries the pointer

;; Recorded against the process, so that Hexagon.Kern.Proc.exit gives back
;; whatever the caller never did, however it happens to end

    mov eax, edx

    call Hexagon.Arch.Mm.setBlockOwner

    call Hexagon.Kern.Sched.getCurrentProcessBase ;; EAX = caller's own base

    sub ebx, eax

    mov eax, 1 ;; Anything but zero, which is what failure reports

    jmp .end

.withoutMemory:

    xor eax, eax

.end:

    add esp, 4 ;; The rounded size pushed above

    pop edx
    pop ecx

    ret

;;************************************************************************************

;; hx.free's own registered syscall entry, in place of calling
;; Hexagon.Arch.Mm.free directly. The caller has only the
;; process-relative pointer Hexagon.Kern.Syscall.malloc handed back above,
;; so it has to be translated back to the flat/physical frame Mm.free's own
;; free-list bookkeeping expects before freeing it, the exact reverse of
;; the malloc side
;;
;; Input/output: same as Hexagon.Arch.Mm.free (EBX pointer in, ECX ignored)

Hexagon.Kern.Syscall.free:

    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi

    call Hexagon.Kern.Sched.getCurrentProcessBase ;; EAX = caller's own base

    add ebx, eax

    mov edi, ebx ;; The pointer, in the frame the arena works in

;; Memory the caller has given back stops being reachable from it. Without
;; this a process would keep the pages of every block it ever freed, and be
;; holding them still when the arena hands the same memory to somebody else

    call Hexagon.Arch.Mm.blockExtent ;; EBX = the block, EDX = its size

    jc .justFree ;; Not ours to close, and Mm.free is about to refuse it too

    mov esi, ebx

    add esi, edx
    and esi, not 0FFFh ;; The last page boundary inside the block

    cmp esi, edi
    jbe .justFree ;; None of it was opened a page at a time

    mov ecx, esi

    sub ecx, edi ;; Exactly what was opened, and no more

    movzx edx, byte[Hexagon.Scheduler.current]

    mov eax, dword[Hexagon.Processes.Table.pageDirectory + edx * 4]

    mov ebx, edi

    call Hexagon.Arch.Paging.revokeRangeFromUser

.justFree:

    mov ebx, edi

    call Hexagon.Arch.Mm.free

    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax

    ret

;;************************************************************************************

Hexagon.Kern.Syscall.installInterruption:

    cli

    call Hexagon.Kern.Services.installISR

    ret
