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
;;                Controle e execução de processos do kernel Hexagon
;;
;; Aqui existem rotinas para a alocação de memória para um novo processo, o
;; carregamento de uma imagem executável válida, sua interpretação, sua execução
;; e término.
;;
;;************************************************************************************

;;************************************************************************************
;;
;;               Hexagon process manager return (error) codes
;;
;;                      Standardized return interface
;;
;;************************************************************************************

;;|=================================================================================|
;;| Code | Error name                     | Error reason                            |
;;|=================================================================================|
;;| 00h  | No errors in the process       | No invalid parameters                   |
;;| 01h  | Image not found on disk        |                    -                    |
;;| 02h  | Error loading image            |                    -                    |
;;| 03h  | Process limit reached          |                    -                    |
;;| 04h  | Invalid image - non-HAPP image |                    -                    |
;;|=================================================================================|

;;************************************************************************************
;;
;; Attention! This module makes calls to Hexagon memory management functions
;;
;;************************************************************************************

;;************************************************************************************
;;
;; Hexagon process management
;;
;;************************************************************************************

use32

;;************************************************************************************
;;
;;                         Hexagon unified process table
;;
;; Every process the kernel knows about gets one slot here, whether started by
;; the blocking hx.exec or the non-blocking hx.spawn. hx.exec still blocks its
;; caller exactly as before: the caller's own slot just sits in the BLOCKED
;; state until its child exits, instead of the child being a nested call on
;; the raw CPU stack, so Hexagon.Kern.Sched.maybeSchedule can round-robin
;; between an exec chain and independently spawned processes uniformly
;;
;;************************************************************************************

virtual at Hexagon.Heap.ProcessTable

Hexagon.Processes.Table.state:
times Hexagon.Processes.Table.limit db 0

Hexagon.Processes.Table.pid:
times Hexagon.Processes.Table.limit dd 0 ;; Persistent PID, never reused while the slot is in use

Hexagon.Processes.Table.parentSlot:
times Hexagon.Processes.Table.limit dd 0 ;; Slot to wake on exit (hx.exec only). 0xFFFFFFFF = none

Hexagon.Processes.Table.parentPID:
times Hexagon.Processes.Table.limit dd 0 ;; PID of whoever created this process, spawn included; 0 = none

Hexagon.Processes.Table.base:
times Hexagon.Processes.Table.limit dd 0 ;; Allocated physical base (own block per process)

Hexagon.Processes.Table.size:
times Hexagon.Processes.Table.limit dd 0 ;; Total allocated size, needed later to free it

Hexagon.Processes.Table.entry:
times Hexagon.Processes.Table.limit dd 0 ;; HAPP entry point; only meaningful before the first dispatch

Hexagon.Processes.Table.esp:
times Hexagon.Processes.Table.limit dd 0 ;; Saved stack pointer while not running; 0 = never dispatched

Hexagon.Processes.Table.wakeTick:
times Hexagon.Processes.Table.limit dd 0 ;; Absolute tick target while in States.sleeping

Hexagon.Processes.Table.argBase:
times Hexagon.Processes.Table.limit dd 0 ;; Alloc process arguments buffer, own life as the process; 0 = none

Hexagon.Processes.Table.envBase:
times Hexagon.Processes.Table.limit dd 0 ;; Alloc process environment buffer, own life as the process; 0 = none

Hexagon.Processes.Table.userId:
times Hexagon.Processes.Table.limit dd 0 ;; This process's own user id, inherited from its parent at creation

Hexagon.Processes.Table.userLoggedIn:
times Hexagon.Processes.Table.limit db 0 ;; Whether userId above should be trusted, same reasoning inherited

Hexagon.Processes.Table.realUserId:
times Hexagon.Processes.Table.limit dd 0 ;; Who actually started this process, untouched by a setuid override

Hexagon.Processes.Table.cwd:
times Hexagon.Processes.Table.limit*64 db 0 ;; This process's own current directory, inherited from its parent

Hexagon.Processes.Table.previousCwd:
times Hexagon.Processes.Table.limit*64 db 0 ;; Directory a "cd -" style swap would return to, also inherited

;; Process name, space-padded, for hx.getProcesses.
;; Holds the kernel-resolved absolute path, not whatever string the caller of
;; hx.exec/hx.spawn originally passed in

Hexagon.Processes.Table.name:
times Hexagon.Processes.Table.limit*64 db 0 

Hexagon.Processes.Table.tty:
times Hexagon.Processes.Table.limit dd 0 ;; VT index this process is attached to, inherited from its parent

Hexagon.Processes.Table.savedForegroundSlot:
times Hexagon.Processes.Table.limit dd 0 ;; Own VT's foregroundSlot value before hx.exec handed it to a child

;; This process's own last-resolved draw target, restored on top of the
;; shared Console.Memory.addressLFB global by Console.ensureCurrentVT
;; whenever another process has since overwritten it

;; Page directory this process runs under, 0 while it shares the kernel's own.
;; pagingBlock is what Mm.malloc actually handed back, kept because the
;; directory itself is the 4 KB aligned address inside that block

Hexagon.Processes.Table.pageDirectory:
times Hexagon.Processes.Table.limit dd 0

Hexagon.Processes.Table.pagingBlock:
times Hexagon.Processes.Table.limit dd 0

Hexagon.Processes.Table.pagingSize:
times Hexagon.Processes.Table.limit dd 0

;; Stack the processor switches to when this process traps in from user level,
;; carved from the same block as its directory

Hexagon.Processes.Table.kernelStack:
times Hexagon.Processes.Table.limit dd 0

Hexagon.Processes.Table.addressLFB:
times Hexagon.Processes.Table.limit dd 0 

;; Never matches Console.generation until this slot has
;; actually resolved its own draw target at least once

Hexagon.Processes.Table.addressLFBGeneration:
times Hexagon.Processes.Table.limit dd 0xFFFFFFFF

Hexagon.Processes.Table.nextPID: dd 0 ;; Monotonic counter, next PID to hand out

Hexagon.Processes.Table.byteSize = $ - Hexagon.Heap.ProcessTable ;; Real size, so Hexagon.Heap.Temp never has to guess a gap

Hexagon.Processes.Table.limit = 40

end virtual

Hexagon.Processes.Table.States.free     = 0
Hexagon.Processes.Table.States.ready    = 1
Hexagon.Processes.Table.States.running  = 2
Hexagon.Processes.Table.States.blocked  = 3
Hexagon.Processes.Table.States.zombie   = 4
Hexagon.Processes.Table.States.sleeping = 5

;; Permanently owned by Hexagon.Kern.Sched.idleSlot, never anyone else's.
;; Deliberately distinct from States.ready so the ordinary round robin scans
;; in Hexagon.Kern.Sched.maybeSchedule/Hexagon.Kern.Sched.sleep skip straight
;; over it instead of giving it a turn on equal footing with real work. Only
;; Hexagon.Kern.Proc.exit's own "nothing else is READY" fallback looks for it

Hexagon.Processes.Table.States.idle     = 6

;; Claimed by Hexagon.Kern.Proc.exec/spawn's own "findSlot" the instant a free
;; slot is picked, since populating it is disk I/O bound and runs with
;; interrupts on. A second exec landing in that window would otherwise see the
;; same slot free and claim it too. Neither findSlot nor maybeSchedule matches
;; this state, so that caller waits for a different slot

Hexagon.Processes.Table.States.reserved = 7

Hexagon.Processes.Table.stackSize = 16384 ;; Dedicated stack space carved out of each process's own block

Hexagon.Kern.Proc.maxArgumentsLength = 2000 ;; Longer arguments are truncated to fit Hexagon.Processes.Table.argBase's allocation

Hexagon.Kern.Proc.maxEnvironmentLength = 2000 ;; Bytes, not variable count; Hexagon.Processes.Table.envBase's allocation

;; What Hexagon.Kern.Proc.getErrorCode reports for a process the processor
;; itself faulted on, terminated by Hexagon.Kern.Services and not by an
;; hx.exit it made itself

Hexagon.Kern.Proc.faultExitCode = 6

;; What a call answers with when the buffer the caller named is not one it could
;; reach by itself. See Hexagon.Arch.Paging.rangeIsCallerWritable

Hexagon.Kern.Proc.badAddress = 7

;; Kernel's own boot-time stack, saved across the very first hx.exec (called
;; directly by Hexagon.Kern.Init.startUserMode, before any process exists to
;; own a table slot of its own)

Hexagon.Kern.Proc.bootCallerESP: dd 0

;; Slot of the very first process the kernel ever launched (the one whose
;; hx.exec blocked Hexagon.Kern.Proc.bootCallerESP above, not a table slot).
;; Hexagon.Kern.Proc.exit needs this to tell that process apart from a
;; spawned process, since hx.spawn also leaves parentSlot at 0xFFFFFFFF for
;; every process it creates, having no blocking caller to record either

Hexagon.Kern.Proc.bootChildSlot: dd 0xFFFFFFFF

;; Error code reported by the last process to exit, read back via hx.getErrorCode

Hexagon.Kern.Proc.lastErrorCode: dd 0

;; Attribute byte of the image exec/spawn is currently loading, set right
;; after their own Hexagon.Kernel.FS.VFS.fileExists call and consumed by
;; Hexagon.Kern.Proc.registerSlot's setuid check. cli stays in effect for
;; this whole span (see .checkImage), so nothing else can interleave here

Hexagon.Kern.Proc.pendingAttribute: db 0

;;************************************************************************************

;; Unlock the caller's own VT, allowing its foreground process to be
;; terminated by the "Kill process" key. Locking is per-VT (Hexagon.Console.
;; VT.locked), not global, so this affects the caller's console alone

Hexagon.Kern.Proc.unlock:

    movzx ecx, byte[Hexagon.Scheduler.current]

    cmp ecx, 0xFF
    jne .knownCaller

    xor eax, eax ;; Kernel boot context has no slot. Defaults to VT0

    jmp .setLock

.knownCaller:

    mov eax, dword[Hexagon.Processes.Table.tty + ecx * 4]

.setLock:

    mov byte[Hexagon.Console.VT.locked + eax], 0

    ret

;;************************************************************************************

;; Lock the caller's own VT, preventing its foreground process from being
;; terminated by the "Kill process" key. A safeguard against closing vital
;; processes

Hexagon.Kern.Proc.lock:

    movzx ecx, byte[Hexagon.Scheduler.current]

    cmp ecx, 0xFF
    jne .knownCaller

    xor eax, eax

    jmp .setLock

.knownCaller:

    mov eax, dword[Hexagon.Processes.Table.tty + ecx * 4]

.setLock:

    mov byte[Hexagon.Console.VT.locked + eax], 1

    ret

;;************************************************************************************

;; Terminates whichever process owns keyboard input on the active VT right
;; now (the "Kill process" key's target), if that VT isn't locked and
;; something is actually attached to it

Hexagon.Kern.Proc.killForegroundProcess:

    mov eax, dword[Hexagon.Console.activeVT]

    cmp byte[Hexagon.Console.VT.locked + eax], 1
    je .end

    mov ecx, dword[Hexagon.Console.VT.foregroundSlot + eax * 4]

    cmp ecx, 0xFFFFFFFF ;; Nothing owns the active VT right now
    je .end

    movzx edx, byte[Hexagon.Scheduler.current]

match =YES, VERBOSE
{

;; Hexagon.Kern.Dmesg.createMessage's own "[PID: N]" names whichever slot
;; Hexagon.Scheduler.current holds, so the real target is swapped in for this
;; one call. It preserves only ESI and flags, and ECX is the resolved kill
;; target still needed right after

    push ecx
    push edx

    mov byte[Hexagon.Scheduler.current], cl

    mov esi, Hexagon.Verbose.Services.killProcess
    mov ebx, Hexagon.Dmesg.Priorities.p4

    call Hexagon.Kern.Dmesg.createMessage

    pop edx
    pop ecx

    mov byte[Hexagon.Scheduler.current], dl

}

    cmp ecx, edx
    jne .thirdParty

;; This is the process the ISR interrupted, so resetting what is on screen
;; before tearing it down is meaningful. A third-party target skips it, since
;; forcing the console back mid-kill disrupts whoever is drawing right now

    mov ax, 18h ;; Kernel linear segment
    mov es, ax

    mov eax, dword[Hexagon.Console.fontColor]
    mov ebx, dword[Hexagon.Console.backgroundColor]

    call Hexagon.Kernel.Dev.Console.Console.setConsoleColor
    call Hexagon.Kernel.Dev.Console.Console.useMainConsole
    call Hexagon.Kernel.Dev.Console.Console.scrollConsole

.thirdParty:

;; EOI must fire before Hexagon.Kern.Proc.killSlot either way: its self-kill
;; branch swaps esp into a different process via Hexagon.Kern.Proc.exit and
;; never returns to this ISR frame, so there is no later chance to send it

    mov al, 20h

    out 20h, al

    jmp Hexagon.Kern.Proc.killSlot

.end:

    ret

;;************************************************************************************

;; Captures the kernel-resolved absolute path of the file about to run
;;
;; Output:
;;
;; ESI - This routine's own scratch buffer: the resolved absolute path,
;;       NUL-terminated, at most 63 characters (the last 63 of the
;;       resolved path, if it was longer)
;;
;; EAX, EBX, ECX, EDX, ES preserved

Hexagon.Kern.Proc.captureDisplayName:

    push eax
    push ebx
    push ecx
    push edx
    push es

;; A real cli/sti bracket, and not disablePreemption alone, closes the window
;; where a preempting process could overwrite resolveMount's shared
;; .normalizedPath before it's copied out below (same reasoning as getMounts)

    pushfd

    cli

    mov esi, Hexagon.Kernel.FS.VFS.resolveMount.normalizedPath

    call Hexagon.Libkern.String.stringSize ;; Preserves ESI. EAX = length

    cmp eax, 63
    jbe .withinLimit

    add esi, eax

    sub esi, 63 ;; Keep the last 63 characters. The executable's own name
                ;; at the end of the path matters more than its start

.withinLimit:

;; stosb writes through ES:EDI, and hexagonHandler leaves ES on the kernel
;; linear segment, while .name needs the kernel data segment

    push ds
    pop es

    mov edi, .name

    cld

.copyLoop:

    lodsb

    stosb

    cmp al, 0
    jne .copyLoop

    popfd

    pop es
    pop edx
    pop ecx
    pop ebx
    pop eax

    mov esi, .name

    ret

.name: times 64 db 0

;;************************************************************************************

;; Configures a new Hexagon process to run immediately, blocking the caller
;; until it exits (via Hexagon.Kern.Proc.exit)
;;
;; Input:
;;
;; ESI - Buffer containing the name of the file to be executed
;; EDI - Program arguments (if they exist)
;; EAX - 0 if no argument exists
;;
;; Output:
;;
;; CF - Set in case of error or file not found
;;      Cleared on success

;;************************************************************************************

Hexagon.Kern.Proc.exec:

    pusha

;; Find a free slot in the process table, doubles as the process-limit check.
;; Claimed with States.reserved the instant it's found (see the comment by
;; that state), under cli, so a second exec/spawn preempting in anywhere
;; during the rest of this function can never see this same slot as free too

    cli

    xor ecx, ecx

.findSlot:

    cmp ecx, Hexagon.Processes.Table.limit
    jae .limitReached

    cmp byte[Hexagon.Processes.Table.state + ecx], Hexagon.Processes.Table.States.free
    je .slotFound

    inc ecx

    jmp .findSlot

.slotFound:

    mov byte[Hexagon.Processes.Table.state + ecx], Hexagon.Processes.Table.States.reserved

    sti

    push ecx ;; Remember the new slot index across everything below

    push eax ;; Remember "has arguments" (0 = no) across the allocation below

;; A dedicated allocation, freed at Hexagon.Kern.Proc.exit, and not a
;; fixed shared address another hx.exec could stomp on. A process can read its
;; arguments at any point in its life, so the address has to stay its own

    mov ebx, Hexagon.Kern.Proc.maxArgumentsLength

    call Hexagon.Arch.Mm.malloc

    cmp eax, 0
    je .argAllocFailed

    mov ecx, Hexagon.Kern.Proc.maxArgumentsLength

    call Hexagon.Kern.Proc.clearForProcess

    mov ecx, dword[esp + 4] ;; New slot index, under the flag just pushed

    mov dword[Hexagon.Processes.Table.argBase + ecx * 4], ebx

;; Counted against this process from here on, and released with it

    push eax

    mov eax, ecx

    call Hexagon.Arch.Mm.setBlockOwner

    pop eax

    mov ebx, ecx ;; Keep the slot in EBX for the rest of the argument handling below

    pop eax ;; Restore "has arguments" flag

;; Check if there are arguments for the process to be loaded

    cmp eax, 0
    je .noArguments

    push esi

    mov esi, edi

    call Hexagon.Libkern.String.stringSize ;; Preserves EBX, ECX, ESI, EDI, ES; EAX = length

    mov ecx, eax

    inc ecx

;; Arguments longer than Hexagon.Kern.Proc.maxArgumentsLength are truncated
;; rather than overflowing past this process's own arguments allocation,
;; the same way Hexagon.Kern.Proc.getProcessTable caps process names to
;; their fixed field width

    cmp ecx, Hexagon.Kern.Proc.maxArgumentsLength
    jb .argLengthOk

    mov ecx, Hexagon.Kern.Proc.maxArgumentsLength - 1

.argLengthOk:

    push es

    push 18h ;; Kernel linear segment
    pop es

;; Copy arguments into this new child's own dedicated buffer, recorded in
;; Hexagon.Processes.Table.argBase above (EBX still holds its slot)

    mov esi, edi

    mov edi, dword[Hexagon.Processes.Table.argBase + ebx * 4]

    rep movsb ;; Copy (ECX) characters from ESI to EDI

    mov byte[es:edi], 0 ;; Guarantee NUL-termination even when truncated above

    pop es

    pop esi

    jmp .checkImage

.noArguments:

    mov edi, dword[Hexagon.Processes.Table.argBase + ebx * 4]

    mov byte[edi], 0

    jmp .checkImage

.argAllocFailed:

    pop eax ;; Discard the "has arguments" flag pushed above
    pop ecx ;; Slot index pushed at .slotFound

    mov byte[Hexagon.Processes.Table.state + ecx], Hexagon.Processes.Table.States.free

    popa

    mov dword[Hexagon.Kern.Proc.lastErrorCode], 05h

    stc

    mov eax, 05h

    ret

.checkImage:

    push esi

    call Hexagon.Kernel.FS.VFS.fileExists ;; EAX = file size, CF = not found

    mov byte[Hexagon.Kern.Proc.pendingAttribute], cl ;; Hexagon.Kern.Proc.registerSlot reads this for its own setuid check

    pop esi

    jc .missingImage

;; From here on, ESI is the kernel-resolved absolute path, not whatever
;; the caller passed

    cli

    call Hexagon.Kern.Proc.captureDisplayName

    push eax ;; Save the file size across checkHAPPImage

;; Hexagon.Libkern.HAPP.checkHAPPImage answers through one global scratch
;; buffer and struct, and entryHAPP is not consumed until
;; Hexagon.Kern.Proc.registerSlot, past a disk read. A second exec in that
;; window would hand this call another image's header, so the mask is held
;; through registerSlot. The success path ends at dispatchSlot, which has its
;; own "sti"; every other return has to supply one

    call Hexagon.Libkern.HAPP.checkHAPPImage

    cmp byte[Hexagon.Libkern.HAPP.imageHAPPHeader.incompatibleImage], 01h
    je .incompatibleImage

    cmp byte[Hexagon.Libkern.HAPP.imageHAPPHeader.incompatibleImage], 02h
    je .missingImage2

    pop eax ;; EAX = file size

;; ESI = filename, EAX = size -> EBX =base, ECX =size, CF =error

    call Hexagon.Kern.Proc.allocateAndLoadImage

    pop edx ;; EDX = new slot index

    jc .allocOrLoadFailed

;; EDX = slot, EBX = base, ECX = size, ESI = filename -> EAX = new pid

    call Hexagon.Kern.Proc.registerSlot

;; Block whoever is calling us until this child exits. The caller is either
;; itself a table slot (a normal nested hx.exec) or, for the very first
;; hx.exec, the kernel's own boot code, which has no slot of its own

;; registerSlot left EDX as States.ready, so a timer landing before
;; Hexagon.Scheduler.current moves to it would dispatch the child and undo the
;; caller's own States.blocked below, resuming it mid-hx.exec on a slot
;; somebody else is by then using. dispatchSlot stays masked to its own iret

    cli

    movzx ecx, byte[Hexagon.Scheduler.current]

    cmp ecx, 0xFF
    je .blockBootCaller

    mov byte[Hexagon.Processes.Table.state + ecx], Hexagon.Processes.Table.States.blocked
    mov dword[Hexagon.Processes.Table.esp + ecx * 4], esp

    mov dword[Hexagon.Processes.Table.parentSlot + edx * 4], ecx

;; The caller's own VT gains this child as its foreground process for as
;; long as this blocking hx.exec lasts. The caller's own value is restored
;; at .resumeParent once the child exits

    mov eax, dword[Hexagon.Processes.Table.tty + ecx * 4]
    mov ebx, dword[Hexagon.Console.VT.foregroundSlot + eax * 4]
    mov dword[Hexagon.Processes.Table.savedForegroundSlot + ecx * 4], ebx
    mov dword[Hexagon.Console.VT.foregroundSlot + eax * 4], edx

    jmp .blocked

.blockBootCaller:

    mov dword[Hexagon.Kern.Proc.bootCallerESP], esp
    mov dword[Hexagon.Kern.Proc.bootChildSlot], edx

;; This child is the kernel's own one-time boot-exec, with no interactive
;; caller waiting on it, and it never exits. Claiming VT0's foreground here
;; would leave Hexagon.Console.VT.foregroundSlot stuck on it forever, so
;; nothing later could ever become the foreground reader. Leave it untouched

.blocked:

    mov byte[Hexagon.Processes.Table.state + edx], Hexagon.Processes.Table.States.running

    mov byte[Hexagon.Scheduler.current], dl

    mov ebx, edx

    jmp Hexagon.Kern.Sched.dispatchSlot ;; Builds the child's iret frame and never returns here

.missingImage:

    pop edx ;; Slot index, pushed at .slotFound

    call .freeArgBase

    popa

    mov dword[Hexagon.Kern.Proc.lastErrorCode], 01h

    sti ;; cli now starts before Hexagon.Kernel.FS.VFS.fileExists above, which
        ;; can land here on a missing file before ever reaching the
        ;; existing "sti" further down this function

    stc

    mov eax, 01h

    ret

.missingImage2:

    pop eax ;; Discard the saved file size
    pop edx ;; Slot index, pushed at .slotFound

    call .freeArgBase

    sti

    popa

    mov dword[Hexagon.Kern.Proc.lastErrorCode], 01h

    stc

    mov eax, 01h

    ret

.incompatibleImage:

    pop eax ;; Discard the saved file size
    pop edx ;; Slot index, pushed at .slotFound

    call .freeArgBase

    sti

    popa

    mov dword[Hexagon.Kern.Proc.lastErrorCode], 04h

    stc

    mov eax, 04h

    ret

.allocOrLoadFailed:

;; EDX is already the slot index here, popped above at "pop edx ;; EDX = new slot index"

    call .freeArgBase

    sti

    popa

    mov dword[Hexagon.Kern.Proc.lastErrorCode], 02h

    stc

    mov eax, 02h

    ret

;; Frees the arguments buffer Hexagon.Kern.Proc.exec allocates for this new
;; slot up front, at .slotFound, before it's known whether the image itself
;; can even be loaded, and releases the slot itself back to States.free
;; (still States.reserved from .slotFound, since Hexagon.Kern.Proc.registerSlot
;; never ran on any path that reaches here). Every error path from here
;; through .allocOrLoadFailed calls this. Without it the argBase allocation
;; would leak (a later hx.exec reusing this slot would allocate a fresh
;; buffer into Hexagon.Processes.Table.argBase and overwrite this pointer
;; with no record of it left to free), and the slot itself would stay
;; States.reserved forever, never usable again
;;
;; Input:
;;
;; EDX - Slot index whose argBase to free

.freeArgBase:

    mov ebx, dword[Hexagon.Processes.Table.argBase + edx * 4]

    mov ecx, Hexagon.Kern.Proc.maxArgumentsLength

    call Hexagon.Arch.Mm.free

    mov dword[Hexagon.Processes.Table.argBase + edx * 4], 0

    mov byte[Hexagon.Processes.Table.state + edx], Hexagon.Processes.Table.States.free

    ret

.limitReached:

;; The findSlot scan above never reached its own "sti" at .slotFound

    sti

    popa

    mov dword[Hexagon.Kern.Proc.lastErrorCode], 03h

    stc

    mov eax, 03h

    ret

;;************************************************************************************

;; Fills a range with zero before it is handed to a process
;;
;; Memory coming back out of the arena still holds whatever the process that
;; had it last left there, and a process reads its own image and the slack past
;; it without having written to it first. Anything not cleared here reaches the
;; next one as data, a password among it
;;
;; Input:
;;
;; EBX - First address, in the kernel's own flat frame
;; ECX - Bytes to clear

Hexagon.Kern.Proc.clearForProcess:

    push eax
    push ecx
    push edx
    push edi

    push es

    mov ax, 18h
    mov es, ax

    mov edi, ebx
    mov edx, ecx

    xor eax, eax

    shr ecx, 2

    cld

    rep stosd

    mov ecx, edx

    and ecx, 3

    rep stosb

    pop es

    pop edi
    pop edx
    pop ecx
    pop eax

    ret

;;************************************************************************************

;; Function that receives control after the process ends and performs the necessary
;; operations to remove it from the process table
;;
;; Input:
;;
;; EAX - Error code reported by the exiting process, kept for hx.getErrorCode

Hexagon.Kern.Proc.exit:

    mov ax, 10h ;; Kernel data segment
    mov ds, ax

    mov dword[Hexagon.Kern.Proc.lastErrorCode], eax

    movzx edx, byte[Hexagon.Scheduler.current] ;; EDX = my own slot

;; Masks interrupts for the whole cleanup sequence, and not the
;; States.free write alone, since a preemption anywhere in here would
;; resurrect this process as a ghost entry. Safe to nest around
;; Hexagon.Arch.Mm.free's own pushfd/popfd, which restores to masked
;; and does not force interrupts back on.

    cli

;; Free this process's own memory block (individually allocated in Hexagon.Kern.Proc.exec/spawn)

    mov ebx, dword[Hexagon.Processes.Table.base + edx * 4]
    mov ecx, dword[Hexagon.Processes.Table.size + edx * 4]

    push ebx
    push ecx

    call Hexagon.Arch.Mm.free ;; Now accounts for Hexagon.Memory.usedMemory itself

    pop ecx
    pop ebx

;; The directory and the tables that described that block go with it

    push edx

    mov ebx, dword[Hexagon.Processes.Table.pagingBlock + edx * 4]
    mov ecx, dword[Hexagon.Processes.Table.pagingSize + edx * 4]

    call Hexagon.Arch.Paging.destroyProcessSpace

    pop edx

    mov dword[Hexagon.Processes.Table.pageDirectory + edx * 4], 0
    mov dword[Hexagon.Processes.Table.pagingBlock + edx * 4], 0

;; Free this process's own arguments buffer, recorded per slot and not
;; living at a fixed address

    mov ebx, dword[Hexagon.Processes.Table.argBase + edx * 4]

    cmp ebx, 0
    je .noArgBaseToFree

    mov ecx, Hexagon.Kern.Proc.maxArgumentsLength

    call Hexagon.Arch.Mm.free

    mov dword[Hexagon.Processes.Table.argBase + edx * 4], 0

.noArgBaseToFree:

    mov ebx, dword[Hexagon.Processes.Table.envBase + edx * 4]

    cmp ebx, 0
    je .noEnvBaseToFree

    mov ecx, Hexagon.Kern.Proc.maxEnvironmentLength

    call Hexagon.Arch.Mm.free

    mov dword[Hexagon.Processes.Table.envBase + edx * 4], 0

.noEnvBaseToFree:

;; And whatever this process took through hx.malloc and never gave back. The
;; Ctrl+C path and a fault it caused both come through here as well, so this
;; is what keeps a process that was killed, and not asked to stop, from
;; holding its buffers until the machine is restarted

    mov eax, edx

    call Hexagon.Arch.Mm.freeProcessBlocks

;; Still under the cli from function entry. Hexagon.Scheduler.current keeps
;; pointing at edx all the way through the parentSlot/bootChildSlot checks
;; below that decide who to resume next.

    mov byte[Hexagon.Processes.Table.state + edx], Hexagon.Processes.Table.States.free

;; Resume whoever is blocked waiting for this process, if anyone, either the
;; parent slot that called hx.exec, or the kernel's own boot code for the
;; very first process, using the exact same esp-restore mechanism
;; Hexagon.Kern.Sched.maybeSchedule already uses to resume any other process

    mov ecx, dword[Hexagon.Processes.Table.parentSlot + edx * 4]

    cmp ecx, 0xFFFFFFFF
    jne .resumeParent

;; Nobody has parentSlot pointing here to be woken. This is either the very
;; first process the kernel ever launched, which should return into the
;; kernel's own boot stack, or a process hx.spawn created, which never had a
;; blocking caller to record in the first place

    cmp edx, dword[Hexagon.Kern.Proc.bootChildSlot]
    je .resumeBoot

;; A spawned process exited with nobody waiting on it. Hand off to whichever
;; other process is READY next, exactly like a normal preemption would.
;; There is no specific caller context to return to here

;; Hexagon.Scheduler.current still names this slot, which the state=free write
;; above turned into stale garbage. A timer-driven maybeSchedule would preempt
;; it as an ordinary process, saving its ESP there and marking it READY again.
;; Interrupts stay off until the scan below settles on someone real, which can
;; take up to about a second parked in Hexagon.Kern.Sched.idleSlot

    cli

    mov ebx, edx

.scanNext:

    inc ebx

    cmp ebx, Hexagon.Processes.Table.limit
    jb .checkNext

    xor ebx, ebx

.checkNext:

    cmp ebx, edx
    je .useIdleSlot ;; Nothing else is READY either. Everyone still around
                    ;; (init, typically) is presumably just asleep in
                    ;; Hexagon.Kern.Sched.sleep, not gone, so this is not the
                    ;; boot child exiting

    cmp byte[Hexagon.Processes.Table.state + ebx], Hexagon.Processes.Table.States.ready
    je .scheduleNext

    jmp .scanNext

.useIdleSlot:

;; Dispatch Hexagon.Kern.Sched.idleSlot exactly like any other READY
;; candidate below. It is never itself in States.ready (see the comment by
;; States.idle), which is what keeps it out of everyone else's round robin,
;; but it is always available as this last resort

    mov ebx, Hexagon.Kern.Sched.idleSlot

.scheduleNext:

    mov byte[Hexagon.Scheduler.current], bl

    cmp dword[Hexagon.Processes.Table.esp + ebx * 4], 0
    jne .resumeNext

    jmp Hexagon.Kern.Sched.dispatchSlot ;; First ever dispatch of this slot

.resumeNext:

    mov eax, dword[Hexagon.Processes.Table.base + ebx * 4]

    call Hexagon.Kern.Sched.setUserSegmentBase

    mov eax, ebx

    call Hexagon.Arch.Paging.switchSpace

    mov esp, dword[Hexagon.Processes.Table.esp + ebx * 4]

    mov byte[Hexagon.Processes.Table.state + ebx], Hexagon.Processes.Table.States.running

;; Re-enable interrupts now that Hexagon.Scheduler.current (set above, in
;; .scheduleNext) points at ebx instead of the freed slot this fallback
;; started from, per the "cli" before .scanNext. dispatchSlot, the other
;; place .scheduleNext can lead to, already has its own "sti"

    sti

    popa

    xor eax, eax

    clc

    ret

.resumeParent:

;; Interrupts stay off until state[ecx] reaches States.running below. A timer
;; landing in this window finds Hexagon.Scheduler.current already on ecx while
;; it is still States.ready, and either abandons the rest of this path or saves
;; the exiting child's own esp into the parent's slot

    cli

    mov byte[Hexagon.Processes.Table.state + ecx], Hexagon.Processes.Table.States.ready

    mov byte[Hexagon.Scheduler.current], cl

    mov esp, dword[Hexagon.Processes.Table.esp + ecx * 4]

;; Restore this VT's foregroundSlot to what it held before this child took
;; over, mirroring the handoff in Hexagon.Kern.Proc.exec. No push/pop here:
;; esp already points at the parent's own saved frame, about to be consumed
;; by popa below, so only plain register moves are safe until then

    mov eax, dword[Hexagon.Processes.Table.tty + ecx * 4]
    mov ebx, dword[Hexagon.Processes.Table.savedForegroundSlot + ecx * 4]
    mov dword[Hexagon.Console.VT.foregroundSlot + eax * 4], ebx

    mov eax, dword[Hexagon.Processes.Table.base + ecx * 4]

    push ecx

    call Hexagon.Kern.Sched.setUserSegmentBase

    pop ecx

    push ecx

    mov eax, ecx

    call Hexagon.Arch.Paging.switchSpace

    pop ecx

    mov byte[Hexagon.Processes.Table.state + ecx], Hexagon.Processes.Table.States.running

    sti

    popa

    xor eax, eax

    clc

    ret

.resumeBoot:

    mov byte[Hexagon.Scheduler.current], 0xFF

    mov esp, dword[Hexagon.Kern.Proc.bootCallerESP]

;; No foreground restore here, unlike .resumeParent. The boot-exec of
;; /init never claimed VT0's foreground in the first place (see
;; Hexagon.Kern.Proc.exec's own .blockBootCaller), so there is nothing to
;; give back

;; Re-enable interrupts now that Hexagon.Scheduler.current is 0xFF (raw
;; kernel-boot context) and no longer this now-free slot, per the cli before
;; the States.free write above

    sti

    popa

    xor eax, eax

    clc

    ret

;;************************************************************************************

;; Returns its PID to the process
;;
;; Output:
;;
;; EAX - Process PID, or 0 if no process is running

Hexagon.Kern.Proc.getPID:

    push ebx

    movzx ebx, byte[Hexagon.Scheduler.current]

    cmp ebx, 0xFF
    je .none

    mov eax, dword[Hexagon.Processes.Table.pid + ebx * 4]

    jmp .end

.none:

    xor eax, eax

.end:

    pop ebx

    ret

;;************************************************************************************

;; Calculates the effective address of the memory block containing the process arguments.
;; This block is always mapped to a kernel temporary dump region for process arguments.
;; This address is directly relative to the location of the current process in memory
;;
;; Input:
;;
;; Anything
;;
;; Output:
;;
;; EDI - relative address (offset) in memory of the memory block with the process arguments

Hexagon.Kern.Proc.calculateArgumentsAddress:

;; Address resolution documentation for the parameters that will be passed to the new process:
;;
;; First, we get the structure offset within the kernel address.
;; This value should be close to the size in bytes of the file containing the kernel.
;; This value is relative to the kernel, not the memory segment.
;; To obtain the effective address, we take the offset in relation to the kernel and subtract it
;; from the base address of the process, generating an offset in relation to the memory segment.
;; In this case, we have a negative address, as the kernel is in a lower memory region than the
;; process region.
;; When resolving addresses, a two's complement is made with the negative value (a possible and
;; probable value of −2C9C6E is represented as 6392h or 25490), being used as an offset in the
;; ES segment, forming the logical address ES:25490, which would point correctly to the structure
;; in the kernel that contains the process arguments.
;; This way, the process with the offset at EDI = -2C9C6E can correctly point to the expected
;; area in the kernel.
;;
;; More information about the process (effective address calculation - offset):
;;
;; The architecture treats addresses with symmetry at 0, and normally kernel addresses (with a
;; smaller offset in relation to the beginning of memory) appear as negative addresses for the
;; user environment, as observed in this case.
;; The architecture supports negative offsets relative to the segment (via two's complement),
;; performing transparent translation to a physical address.
;; In the case below, we will have a negative offset pointing to a previous region of memory
;; that will be translated into a logical address that will, in turn, be translated into a physical
;; address by the processor using the table present in the GDT

    push eax

    call Hexagon.Kern.Sched.getCurrentProcessBase

    movzx edi, byte[Hexagon.Scheduler.current]

    mov edi, dword[Hexagon.Processes.Table.argBase + edi * 4] ;; This process's own allocated arguments buffer

    sub edi, eax ;; Get effective address (offset)

    pop eax

    ret

;;************************************************************************************

;; Hexagon.Kern.Proc.getProcessTable copies into the caller's own buffer a
;; 4-byte record size, followed by one record per Hexagon.Processes.Table
;; slot that isn't FREE, in slot order, each shaped like this:
;;
;; +0  dd PID
;; +4  dd Parent PID (0 = launched directly by the kernel, no parent process)
;; +8  db State (Hexagon.Processes.Table.States.*)
;; +9  Name, NUL-terminated within a fixed 64-byte field
;; +73 db VT index (Hexagon.Processes.Table.tty)
;; +74 dd Bytes the process is holding
;;
;; The record size travels with the data, so a field appended at the end
;; leaves anything built against the shorter layout still stepping correctly

Hexagon.Kern.Proc.getProcessTable.recordSize = 78 ;; 4 + 4 + 1 + 64 + 1 + 4

;; Input:
;;
;; ESI - Caller's own buffer
;; ECX - Size of that buffer, in bytes
;;
;; Output:
;;
;; EAX - Number of records written, if the buffer was big enough (CF clear)
;; EAX - Exact buffer size needed, in bytes, if it wasn't (CF set). Nothing
;;       is written in that case, and the caller is expected to hx.free its
;;       buffer, hx.malloc exactly EAX bytes, and retry
;; CF  - Set if the caller's buffer was too small

Hexagon.Kern.Proc.getProcessTable:

;; The caller's own buffer, written into at CPL 0 where paging refuses nothing,
;; so it is checked against what this process can reach first

    push ebx

    mov ebx, esi

    call Hexagon.Arch.Paging.rangeIsCallerWritable

    pop ebx

    jc .badBuffer

    push ebx
    push ecx
    push edx

;; preemptionDisabled alone does not stop another process's own
;; concurrent int 80h from entering hexagonHandler. A real cli/sti
;; bracket closes that window, and here also keeps the counting and
;; writing passes consistent with each other

    pushfd

    cli

    push es

    mov ax, 10h
    mov es, ax

;; First pass: count live slots (not free, not reserved) without writing
;; anything, so the exact buffer size needed is known before deciding
;; whether the caller's own buffer is big enough

    xor ebx, ebx ;; EBX = slot index
    xor edx, edx ;; EDX = live count

.countLoop:

    cmp ebx, Hexagon.Processes.Table.limit
    jae .counted

    cmp byte[Hexagon.Processes.Table.state + ebx], Hexagon.Processes.Table.States.free
    je .countNext

    cmp byte[Hexagon.Processes.Table.state + ebx], Hexagon.Processes.Table.States.reserved
    je .countNext

    inc edx

.countNext:

    inc ebx

    jmp .countLoop

.counted:

    mov dword[.liveCount], edx

    mov eax, edx

    imul eax, Hexagon.Kern.Proc.getProcessTable.recordSize

    add eax, 4 ;; Leading record-size dd

    cmp eax, ecx

    ja .tooSmall

;; Second pass: write the records for real

    mov edi, esi

    mov dword[edi], Hexagon.Kern.Proc.getProcessTable.recordSize

    add edi, 4

    cld

    xor ebx, ebx ;; EBX = slot index

.loop:

    cmp ebx, Hexagon.Processes.Table.limit
    jae .done

    cmp byte[Hexagon.Processes.Table.state + ebx], Hexagon.Processes.Table.States.free
    je .next

;; Skip slots States.reserved by a concurrent exec/spawn's findSlot: claimed,
;; but with base/pid/name not populated yet, so nothing here is meaningful
;; to show a caller of hx.getProcesses yet either

    cmp byte[Hexagon.Processes.Table.state + ebx], Hexagon.Processes.Table.States.reserved
    je .next

    mov eax, dword[Hexagon.Processes.Table.pid + ebx * 4]

    stosd

    mov eax, dword[Hexagon.Processes.Table.parentPID + ebx * 4]

    stosd

    mov al, byte[Hexagon.Processes.Table.state + ebx]

    stosb

;; Find the real length of this slot's name, capped at 63 so a NUL
;; terminator always fits within the 64-byte field. ESI is dead here
;; (only EDI carries state between slots), free to reuse as a read pointer

    mov esi, ebx

    imul esi, 64

    add esi, Hexagon.Processes.Table.name

    xor edx, edx

.measureName:

    cmp edx, 63
    jae .measured

    cmp byte[esi + edx], ' '
    je .measured

    inc edx

    jmp .measureName

.measured:

    push edx ;; Real length, needed again below after rep movsb consumes ECX

    mov ecx, edx

    rep movsb ;; Copy the real name characters

    pop ecx

    mov edx, 64

    sub edx, ecx

    mov ecx, edx

    xor al, al

    rep stosb ;; NUL-terminate and pad out the rest of the name field

;; Appended after name so pid/parentPID/state/name keep their existing offsets

    mov al, byte[Hexagon.Processes.Table.tty + ebx * 4]

    stosb

;; Everything this process holds, from the allocator's own tally: its image
;; and stack, its arguments and environment, the tables that map it, and
;; whatever it took through hx.malloc

    mov eax, ebx

    call Hexagon.Arch.Mm.memoryUsedBySlot

    stosd

.next:

    inc ebx

    jmp .loop

.done:

    mov eax, dword[.liveCount]

    pop es

    popfd

    pop edx
    pop ecx
    pop ebx

    clc

    ret
.badBuffer:

    mov eax, Hexagon.Kern.Proc.badAddress

    stc

    ret


.tooSmall:

;; EAX already holds the exact size needed, computed above before this
;; branch was taken

    pop es

    popfd

    pop edx
    pop ecx
    pop ebx

    stc

    ret

.liveCount: dd 0

;;************************************************************************************

Hexagon.Kern.Proc.getErrorCode:

    mov eax, [Hexagon.Kern.Proc.lastErrorCode]

    ret

;;************************************************************************************

;; Allocates memory for and loads an executable image, without registering it
;; anywhere or starting it. Used by Hexagon.Kern.Proc.exec and Hexagon.Kern.Proc.spawn
;;
;; Input:
;;
;; EAX - Exact declared file size (from Hexagon.Kernel.FS.VFS.fileExists)
;; ESI - Filename (already validated to exist and be a compatible HAPP image)
;;
;; Output:
;;
;; EBX - Allocated physical base (on success)
;; ECX - Total allocated size, including margins and stack (on success).
;;       The caller must remember this, it is needed later by
;;       Hexagon.Arch.Mm.free
;; CF  - Set on error (out of memory, or the image failed to load)

Hexagon.Kern.Proc.allocateAndLoadImage:

    push edx

    xor edx, edx

    div dword[Hexagon.VFS.FAT16B.clusterSize] ;; EAX = clusters (floor), EDX = remainder

    cmp edx, 0
    je .imageSizeAligned

    inc eax ;; Round up to the next whole cluster

.imageSizeAligned:

    mul dword[Hexagon.VFS.FAT16B.clusterSize] ;; EAX = size rounded up to a whole cluster

    pop edx

;; Room past the image for whatever it declares but emits no bytes for, as
;; much as its own header asks for and not a byte more. An image that asks for
;; nothing gets nothing: the kernel used to hand every one of them 64 KB in
;; case it read a file into a bare label past its own end, and each image now
;; says for itself whether it does

    add eax, dword[Hexagon.Libkern.HAPP.imageHAPPHeader.bssSize]

    add eax, Hexagon.Processes.Table.stackSize ;; Dedicated stack for this process

    push eax ;; Remember the total size across the calls below

    mov ebx, eax

    call Hexagon.Arch.Mm.malloc

    cmp eax, 0
    je .allocError

;; Nothing of whoever held this block before is this process's to read

    mov ecx, dword[esp] ;; The total size pushed above

    call Hexagon.Kern.Proc.clearForProcess

    push ebx ;; Remember the allocated base across the openFile call

    mov edi, ebx

;; Correct address with segment base (physical address = address + segment base)


    push esi

    xor ecx, ecx ;; Load the whole image, uncapped

    call Hexagon.Kernel.FS.VFS.openFile

    pop esi

    jc .loadError

    pop ebx ;; Base

    pop ecx ;; Total size

    clc

    ret

.loadError:

    pop ebx ;; Base
    pop ecx ;; Total size

    push ebx
    push ecx

    call Hexagon.Arch.Mm.free ;; Avoid leaking the block for an image that failed to load

    pop ecx
    pop ebx

    stc

    ret

.allocError:

    pop eax ;; Discard the size pushed above, nothing was allocated

    stc

    ret

;;************************************************************************************

;; Fills in a freshly-found, free table slot with a newly loaded process.
;; Common to both Hexagon.Kern.Proc.exec and Hexagon.Kern.Proc.spawn. Leaves
;; the slot READY either way. hx.exec additionally blocks its caller and
;; dispatches the slot immediately right after calling this
;;
;; Input:
;;
;; EDX - Slot index (already confirmed free)
;; EBX - Allocated physical base
;; ECX - Total allocated size
;; ESI - Display name, the kernel-resolved absolute path of the executed file
;;
;; Output:
;;
;; EAX - PID assigned to the new process

Hexagon.Kern.Proc.registerSlot:

;; The name-copy loop below writes through ES:EDI. A caller at user level
;; leaves ES on its data segment, based at that process, so ES has to be
;; realigned with DS before writing into Hexagon.Processes.Table

    push ds
    pop es

;; States.ready is written only once every other field below is in place.
;; The timer stays enabled through a syscall, so a tick landing before
;; base/entry/pid/name are written would have maybeSchedule dispatch the slot
;; off whatever still sits in them

    mov dword[Hexagon.Processes.Table.base + edx * 4], ebx

;; Counted against this process from here on, and released with it

    push eax

    mov eax, edx

    call Hexagon.Arch.Mm.setBlockOwner

    pop eax
    mov dword[Hexagon.Processes.Table.size + edx * 4], ecx

;; A space of this process's own, so only the pages it owns are reachable from
;; user level. A slot without one shares the kernel's directory, which still
;; runs correctly, only without the separation

    push edx ;; The slot, since createProcessSpace answers in four registers

    call Hexagon.Arch.Paging.createProcessSpace ;; EAX = directory, EBX/ECX = block to free with it, EDX = its kernel stack

    push edx ;; The kernel stack, until the slot is back in EDX

    mov edx, dword[esp + 4]

    mov dword[Hexagon.Processes.Table.pageDirectory + edx * 4], eax
    mov dword[Hexagon.Processes.Table.pagingBlock + edx * 4], ebx

;; Counted against this process from here on, and released with it

    push eax

    mov eax, edx

    call Hexagon.Arch.Mm.setBlockOwner

    pop eax
    mov dword[Hexagon.Processes.Table.pagingSize + edx * 4], ecx

    pop eax

    mov dword[Hexagon.Processes.Table.kernelStack + edx * 4], eax

    add esp, 4 ;; The slot, already back in EDX


    mov eax, dword[Hexagon.Libkern.HAPP.imageHAPPHeader.entryHAPP]
    mov dword[Hexagon.Processes.Table.entry + edx * 4], eax

    mov dword[Hexagon.Processes.Table.esp + edx * 4], 0 ;; Never dispatched yet

;; Hexagon.Kern.Proc.calculateArgumentsAddress computes an address from this
;; field however the process was created, so it must never be left at 0. A
;; spawned process has no arguments and gets an empty buffer here

    cmp dword[Hexagon.Processes.Table.argBase + edx * 4], 0
    jne .argBaseReady

    push ebx

    mov ebx, Hexagon.Kern.Proc.maxArgumentsLength

    call Hexagon.Arch.Mm.malloc

    cmp eax, 0
    je .argBaseSkip ;; Best effort; leave it 0 on out-of-memory and do not fail an already-loaded process

    mov ecx, Hexagon.Kern.Proc.maxArgumentsLength

    call Hexagon.Kern.Proc.clearForProcess

    mov dword[Hexagon.Processes.Table.argBase + edx * 4], ebx

;; Counted against this process from here on, and released with it

    push eax

    mov eax, edx

    call Hexagon.Arch.Mm.setBlockOwner

    pop eax

    mov byte[ebx], 0 ;; Empty arguments string

.argBaseSkip:

    pop ebx

.argBaseReady:

;; Every new process gets its own environment, whether created by exec or
;; spawn, inherited as a copy of the calling process's own environment.
;; Best effort, same reasoning as the argBase fallback above: the image is
;; already loaded and committed by this point, so out-of-memory here just
;; means an empty environment instead of failing the whole exec/spawn

    push ebx

    mov ebx, Hexagon.Kern.Proc.maxEnvironmentLength

    call Hexagon.Arch.Mm.malloc

    cmp eax, 0
    je .envBaseSkip

    mov ecx, Hexagon.Kern.Proc.maxEnvironmentLength

    call Hexagon.Kern.Proc.clearForProcess

    mov dword[Hexagon.Processes.Table.envBase + edx * 4], ebx

;; Counted against this process from here on, and released with it

    push eax

    mov eax, edx

    call Hexagon.Arch.Mm.setBlockOwner

    pop eax

    call Hexagon.Kern.Proc.copyCallerEnvironment ;; EDX = new slot, whose envBase is now allocated

.envBaseSkip:

    pop ebx

    inc dword[Hexagon.Processes.Table.nextPID]

    mov eax, dword[Hexagon.Processes.Table.nextPID]

    mov dword[Hexagon.Processes.Table.pid + edx * 4], eax

;; Record who created this process: 0 if launched directly by the kernel at
;; boot, otherwise whoever is currently running. Kept for spawned processes too

;; Only hx.exec fills this in for real

    mov dword[Hexagon.Processes.Table.parentSlot + edx * 4], 0xFFFFFFFF

    movzx ecx, byte[Hexagon.Scheduler.current]

    cmp ecx, 0xFF
    je .noParent

    mov ecx, dword[Hexagon.Processes.Table.pid + ecx * 4]

    jmp .parentKnown

.noParent:

    xor ecx, ecx

.parentKnown:

    mov dword[Hexagon.Processes.Table.parentPID + edx * 4], ecx

;; Every new process inherits its own user id from whoever created it, the
;; same copy-on-creation model already used for its environment above. With
;; no parent, it starts out already logged in as root instead

;; EAX holds the new PID from here until the "EAX = new PID" pop further
;; down this function. The whole user id/setuid block below is pushed
;; around it instead of using EAX itself, unlike everything above it

    push eax

    movzx ebx, byte[Hexagon.Scheduler.current]

    cmp ebx, 0xFF
    je .noParentUser

    mov ecx, dword[Hexagon.Processes.Table.userId + ebx * 4]
    mov eax, dword[Hexagon.Processes.Table.realUserId + ebx * 4] ;; EBX still the parent's slot here
    mov bl, byte[Hexagon.Processes.Table.userLoggedIn + ebx]

    jmp .parentUserKnown

.noParentUser:

    xor ecx, ecx ;; Hexagon.Users.ID.root
    xor eax, eax ;; Real id matches, same reasoning
    mov bl, 1

.parentUserKnown:

    mov dword[Hexagon.Processes.Table.userId + edx * 4], ecx
    mov byte[Hexagon.Processes.Table.userLoggedIn + edx], bl
    mov dword[Hexagon.Processes.Table.realUserId + edx * 4], eax

;; A binary marked both root-protected and setuid grants root to whoever runs
;; it, overriding what was inherited above, while realUserId stays untouched.
;; 06h is the system and setuid attributes, whose struc is not instantiated
;; this early in the build

    movzx eax, byte[Hexagon.Kern.Proc.pendingAttribute]

    and eax, 06h

    cmp eax, 06h
    jne .notSetuid

    mov dword[Hexagon.Processes.Table.userId + edx * 4], 0
    mov byte[Hexagon.Processes.Table.userLoggedIn + edx], 1

.notSetuid:

    pop eax ;; Restores the new PID this block was pushed around

;; Every new process inherits its own current and previous directory from
;; whoever created it, defaulting to "/" with no parent. ESI is saved
;; across this, it's still needed again below

    push esi

    movzx ebx, byte[Hexagon.Scheduler.current]

    cmp ebx, 0xFF
    je .noParentCwd

    mov esi, ebx
    imul esi, 64
    add esi, Hexagon.Processes.Table.cwd

    mov edi, edx
    imul edi, 64
    add edi, Hexagon.Processes.Table.cwd

    mov ecx, 64

    rep movsb

    mov esi, ebx
    imul esi, 64
    add esi, Hexagon.Processes.Table.previousCwd

    mov edi, edx
    imul edi, 64
    add edi, Hexagon.Processes.Table.previousCwd

    mov ecx, 64

    rep movsb

    jmp .cwdKnown

.noParentCwd:

    mov edi, edx
    imul edi, 64
    add edi, Hexagon.Processes.Table.cwd

    mov byte[edi], '/'
    mov byte[edi + 1], 0

.cwdKnown:

;; Every new process also inherits which VT it's attached to, mirroring cwd
;; above. ebx still holds the parent slot (or 0xFF) from the check above

    cmp ebx, 0xFF
    je .noParentTTY

    mov ecx, dword[Hexagon.Processes.Table.tty + ebx * 4]

    jmp .ttyKnown

.noParentTTY:

    xor ecx, ecx

.ttyKnown:

    mov dword[Hexagon.Processes.Table.tty + edx * 4], ecx

;; Force this slot's own draw-target cache to resolve fresh on its first
;; use, regardless of whatever generation number a previous occupant of
;; this same slot left behind

    mov dword[Hexagon.Processes.Table.addressLFBGeneration + edx * 4], 0xFFFFFFFF

    pop esi

;; Copy the process name into the table (for hx.getProcesses). ESI is
;; already captureDisplayName's own scratch: a NUL-terminated, at most
;; 64-byte, kernel-resolved absolute path

    push eax

    mov edi, edx

    imul edi, 64

    add edi, Hexagon.Processes.Table.name

    mov ecx, 64

.copyNameLoop:

    lodsb

    cmp al, 0
    je .padName

    stosb

    loop .copyNameLoop

    jmp .nameCopied

.padName:

    mov al, ' '

    rep stosb

.nameCopied:

    pop eax ;; EAX = new PID

;; Everything else about this slot is now in place, so this is the point
;; where it actually becomes visible to maybeSchedule/getProcessTable

    mov byte[Hexagon.Processes.Table.state + edx], Hexagon.Processes.Table.States.ready

    ret

;;************************************************************************************

;; hx.getTTY: tells the calling process which VT it's attached to, the same
;; way real Unix's ttyname() does
;;
;; Output:
;;
;; EAX - VT index (0-7)

Hexagon.Kern.Proc.getTTY:

    movzx eax, byte[Hexagon.Scheduler.current]

    mov eax, dword[Hexagon.Processes.Table.tty + eax * 4]

    ret

;;************************************************************************************

;; Fills a freshly allocated envBase with a copy of the calling process's
;; own environment, bounded by Hexagon.Kern.Proc.maxEnvironmentLength. The
;; very first hx.exec has no calling process slot yet
;; (Hexagon.Scheduler.current is still 0xFF at boot) and gets an empty
;; environment instead
;;
;; Input:
;;
;; EDX - New slot index (Hexagon.Processes.Table.envBase already allocated)

Hexagon.Kern.Proc.copyCallerEnvironment:

    pushad

;; Hexagon.Processes.Table.envBase holds an Mm.malloc pointer, so ES goes on
;; the kernel linear selector here, the same convention every other raw
;; allocation in the kernel is written through

    push es

    mov ax, 18h
    mov es, ax

    mov edi, dword[Hexagon.Processes.Table.envBase + edx * 4]

    cmp byte[Hexagon.Scheduler.current], 0xFF
    je .emptyEnvironment

    movzx eax, byte[Hexagon.Scheduler.current]

    mov esi, dword[Hexagon.Processes.Table.envBase + eax * 4]

    mov ecx, Hexagon.Kern.Proc.maxEnvironmentLength

;; rep movsb's source defaults to ds:[esi], and esi is the caller's own
;; envBase, just as flat/physical as edi's, so ds needs the same 18h
;; forced on it as es above, only for the copy itself

    push ds

    mov ax, 18h
    mov ds, ax

    cld

    rep movsb

    pop ds

    jmp .end

.emptyEnvironment:

    mov byte[es:edi], 0 ;; Terminates the current entry (none)
    mov byte[es:edi + 1], 0 ;; Terminates the whole block

.end:

    pop es

    popad

    ret

;;************************************************************************************

;; Creates a new process without blocking the caller. Fully validated,
;; allocated and loaded, then left READY in the process table for
;; Hexagon.Kern.Sched.maybeSchedule to dispatch when it sees fit
;;
;; Input:
;;
;; ESI - Buffer containing the name of the file to be executed
;; EDI - Program arguments (if they exist)
;; EAX - 0 if no argument exists
;;
;; Output:
;;
;; EAX - PID of the new process (on success)
;; CF  - Set on error (process limit reached, image not found or
;;       incompatible, out of memory)

Hexagon.Kern.Proc.spawn:

;; EAX/EDI mean nothing to Hexagon.Kernel.FS.VFS.fileExists or anything else
;; below until the argument buffer is actually allocated, well after. Both
;; are stashed here and not carried through in registers across calls whose
;; own preservation isn't guaranteed

    mov dword[.hasArguments], eax
    mov dword[.arguments], edi

    push esi

    call Hexagon.Kernel.FS.VFS.fileExists ;; EAX = file size, CF = not found

    mov byte[Hexagon.Kern.Proc.pendingAttribute], cl ;; Hexagon.Kern.Proc.registerSlot reads this for its own setuid check

    pop esi

    jc .missingImage

;; From here on, ESI is the kernel-resolved absolute path

    cli

    call Hexagon.Kern.Proc.captureDisplayName

    push eax ;; Save the file size across checkHAPPImage

;; Hexagon.Libkern.HAPP.checkHAPPImage answers through one global scratch
;; buffer and struct, and entryHAPP is not consumed until
;; Hexagon.Kern.Proc.registerSlot, past a disk read. The mask is held through
;; registerSlot and closed on every path that returns without reaching it

    call Hexagon.Libkern.HAPP.checkHAPPImage

    cmp byte[Hexagon.Libkern.HAPP.imageHAPPHeader.incompatibleImage], 01h
    je .incompatibleImage

    cmp byte[Hexagon.Libkern.HAPP.imageHAPPHeader.incompatibleImage], 02h
    je .missingImage2

;; Find a free slot in the process table. Claimed with States.reserved the
;; instant it's found (see the comment by that state), already covered by
;; the same cli as above, so no separate one is needed here anymore

    xor ecx, ecx

.findSlot:

    cmp ecx, Hexagon.Processes.Table.limit
    jae .limitReached

    cmp byte[Hexagon.Processes.Table.state + ecx], Hexagon.Processes.Table.States.free
    je .slotFound

    inc ecx

    jmp .findSlot

.slotFound:

    mov byte[Hexagon.Processes.Table.state + ecx], Hexagon.Processes.Table.States.reserved

    pop eax ;; Restore the file size

    push ecx ;; Remember the free slot index across everything below

;; Give this new process its own arguments buffer, the same reasoning as
;; Hexagon.Kern.Proc.exec's own identical block: a dedicated allocation
;; freed at Hexagon.Kern.Proc.exit, not a fixed shared address

    push eax ;; Save the file size across this allocation

    mov ebx, Hexagon.Kern.Proc.maxArgumentsLength

    call Hexagon.Arch.Mm.malloc

    cmp eax, 0
    je .argAllocFailed

    mov ecx, Hexagon.Kern.Proc.maxArgumentsLength

    call Hexagon.Kern.Proc.clearForProcess

    mov ecx, dword[esp + 4] ;; Free slot index, under the file size just pushed

    mov dword[Hexagon.Processes.Table.argBase + ecx * 4], ebx

;; Counted against this process from here on, and released with it

    push eax

    mov eax, ecx

    call Hexagon.Arch.Mm.setBlockOwner

    pop eax

    mov ebx, ecx ;; Keep the slot in EBX for the rest of the argument handling below

    pop eax ;; Restore the file size

    cmp dword[.hasArguments], 0
    je .noArguments

    push esi

    mov esi, dword[.arguments]

    call Hexagon.Libkern.String.stringSize ;; Preserves EBX, ECX, ESI, EDI, ES. EAX = length

    mov ecx, eax

    inc ecx

    cmp ecx, Hexagon.Kern.Proc.maxArgumentsLength
    jb .argLengthOk

    mov ecx, Hexagon.Kern.Proc.maxArgumentsLength - 1

.argLengthOk:

    push es

    push 18h ;; Kernel linear segment
    pop es

    mov esi, dword[.arguments]

    mov edi, dword[Hexagon.Processes.Table.argBase + ebx * 4]

    rep movsb ;; Copy (ECX) characters from ESI to EDI

    mov byte[es:edi], 0 ;; Guarantee NUL-termination even when truncated above

    pop es

    pop esi

    jmp .argumentsReady

.noArguments:

    mov edi, dword[Hexagon.Processes.Table.argBase + ebx * 4]

    mov byte[edi], 0

.argumentsReady:

    call Hexagon.Kern.Proc.allocateAndLoadImage ;; EBX = base, ECX = total size, CF = error

    pop edx ;; EDX = free slot index

    jc .allocOrLoadFailed

;; EDX = slot, EBX = base, ECX = size, ESI = filename -> EAX = new pid

    call Hexagon.Kern.Proc.registerSlot

    sti

    clc

    ret

.missingImage:

    sti ;; cli now starts before Hexagon.Kernel.FS.VFS.fileExists above, which
        ;; can land here on a missing file before ever reaching
        ;; .missingImage2's own "sti" below

    stc

    mov eax, 01h

    ret

.missingImage2:

    pop eax ;; Discard the saved file size

    sti

    stc

    mov eax, 01h

    ret

.incompatibleImage:

    pop eax ;; Discard the saved file size

    sti

    stc

    mov eax, 04h

    ret

.limitReached:

    pop eax ;; Discard the saved file size

    sti

    stc

    mov eax, 03h

    ret

.allocOrLoadFailed:

;; EDX is already the slot index here. Hexagon.Kern.Proc.registerSlot never
;; ran on this path, so the slot claimed at .slotFound (States.reserved)
;; needs to go back to States.free itself, or it would stay reserved and
;; unusable forever

    mov byte[Hexagon.Processes.Table.state + edx], Hexagon.Processes.Table.States.free

    sti

    stc

    mov eax, 02h

    ret

.argAllocFailed:

    pop eax ;; Discard the file size pushed for this allocation attempt
    pop ecx ;; Slot index pushed at .slotFound

    mov byte[Hexagon.Processes.Table.state + ecx], Hexagon.Processes.Table.States.free

    sti

    stc

    mov eax, 02h

    ret

.hasArguments: dd 0
.arguments:    dd 0

;;************************************************************************************

;; Terminates an arbitrary process by PID, requested through hx.kill. Unlike
;; Hexagon.Kern.Proc.killForegroundProcess (the Ctrl-C hotkey handler, which
;; always targets whichever process is currently in the foreground), this
;; looks the target up in Hexagon.Processes.Table and can be called from any
;; process against any other
;;
;; Input:
;;
;; EBX - Target PID
;;
;; Output:
;;
;; CF - Set on error (no process with this PID). EAX = 05h
;;      Cleared on success

Hexagon.Kern.Proc.kill:

    xor ecx, ecx

.findSlot:

    cmp ecx, Hexagon.Processes.Table.limit
    jae .notFound

    cmp byte[Hexagon.Processes.Table.state + ecx], Hexagon.Processes.Table.States.free
    je .next

    cmp dword[Hexagon.Processes.Table.pid + ecx * 4], ebx
    je .slotFound

.next:

    inc ecx

    jmp .findSlot

.slotFound:

    jmp Hexagon.Kern.Proc.killSlot

.notFound:

    stc

    mov eax, 05h

    ret

;;************************************************************************************

;; Tears down a specific, already-resolved process slot. Shared by
;; Hexagon.Kern.Proc.kill (PID lookup above) and Hexagon.Kern.Proc.
;; killForegroundProcess (VT.foregroundSlot lookup)
;;
;; Input: ECX - slot to terminate

Hexagon.Kern.Proc.killSlot:

;; Slot 0 is the permanent idle process, never allocated like a real process.
;; Tearing it down here would free a bogus base/size and erase the scheduler's
;; last-resort fallback, so refuse exactly like an unknown PID instead

    cmp ecx, Hexagon.Kern.Sched.idleSlot
    je .notFound

    movzx edx, byte[Hexagon.Scheduler.current]

    cmp ecx, edx
    jne .killOther

;; Killing the caller itself, same as a plain hx.exit, never returns here

    xor eax, eax

    jmp Hexagon.Kern.Proc.exit

.killOther:

    mov edx, ecx ;; EDX = slot to terminate

;; EDX is a third-party slot, which can still legitimately be States.ready
;; right up to the state=free write below. A timer landing between the
;; Hexagon.Arch.Mm.free call and that write would dispatch it straight off
;; memory this function is in the middle of freeing

    cli

    mov ebx, dword[Hexagon.Processes.Table.base + edx * 4]
    mov ecx, dword[Hexagon.Processes.Table.size + edx * 4]

    push ebx
    push ecx

    call Hexagon.Arch.Mm.free ;; Now accounts for Hexagon.Memory.usedMemory itself

    pop ecx
    pop ebx

;; The directory and the tables that described that block go with it

    push edx

    mov ebx, dword[Hexagon.Processes.Table.pagingBlock + edx * 4]
    mov ecx, dword[Hexagon.Processes.Table.pagingSize + edx * 4]

    call Hexagon.Arch.Paging.destroyProcessSpace

    pop edx

    mov dword[Hexagon.Processes.Table.pageDirectory + edx * 4], 0
    mov dword[Hexagon.Processes.Table.pagingBlock + edx * 4], 0

;; Its arguments, its environment, and whatever it took through hx.malloc and
;; never gave back, none of which a killed process reaches Hexagon.Kern.Proc.exit
;; to release. They have to go before the state write below, while the slot
;; still names this process, since a block records its owner as a slot

    mov ebx, dword[Hexagon.Processes.Table.argBase + edx * 4]

    cmp ebx, 0
    je .noArgBaseToFree

    mov ecx, Hexagon.Kern.Proc.maxArgumentsLength

    call Hexagon.Arch.Mm.free

    mov dword[Hexagon.Processes.Table.argBase + edx * 4], 0

.noArgBaseToFree:

    mov ebx, dword[Hexagon.Processes.Table.envBase + edx * 4]

    cmp ebx, 0
    je .noEnvBaseToFree

    mov ecx, Hexagon.Kern.Proc.maxEnvironmentLength

    call Hexagon.Arch.Mm.free

    mov dword[Hexagon.Processes.Table.envBase + edx * 4], 0

.noEnvBaseToFree:

    mov eax, edx

    call Hexagon.Arch.Mm.freeProcessBlocks

    mov byte[Hexagon.Processes.Table.state + edx], Hexagon.Processes.Table.States.free

    sti

;; A child this process exec'd still points its parentSlot here, and its own
;; hx.exit would resume this slot through a base and esp whose memory was just
;; freed above. Sever the link so exit treats it as an orphan, the path
;; hx.spawn'd processes with no blocking caller already take

    xor ebx, ebx

.severChildren:

    cmp ebx, Hexagon.Processes.Table.limit
    jae .wakeParent

    cmp dword[Hexagon.Processes.Table.parentSlot + ebx * 4], edx
    jne .nextChild

    mov dword[Hexagon.Processes.Table.parentSlot + ebx * 4], 0xFFFFFFFF

.nextChild:

    inc ebx

    jmp .severChildren

.wakeParent:

;; If the process being killed was its own VT's current foreground process,
;; that VT's foreground must revert to whoever handed it off, mirroring what
;; Hexagon.Kern.Proc.exit's own resumeParent/resumeBoot do. This path
;; tears the slot down directly instead of going through exit, so nothing
;; else restores it

    mov ecx, dword[Hexagon.Processes.Table.parentSlot + edx * 4]

    mov eax, dword[Hexagon.Processes.Table.tty + edx * 4]

    cmp dword[Hexagon.Console.VT.foregroundSlot + eax * 4], edx
    jne .parentCheck

    cmp ecx, 0xFFFFFFFF
    je .bootForegroundCheck

    mov ebx, dword[Hexagon.Processes.Table.savedForegroundSlot + ecx * 4]
    mov dword[Hexagon.Console.VT.foregroundSlot + eax * 4], ebx

    jmp .parentCheck

.bootForegroundCheck:

    cmp edx, dword[Hexagon.Kern.Proc.bootChildSlot]
    jne .parentCheck

;; /init itself, killed while somehow also its own VT's foreground owner.
;; Only possible if it ever claims one itself, see
;; Hexagon.Kern.Proc.exec's own .blockBootCaller, which deliberately never
;; does this on its behalf. Nothing to hand back to, just clear it

    mov dword[Hexagon.Console.VT.foregroundSlot + eax * 4], 0xFFFFFFFF

.parentCheck:

;; A caller blocked on this process is woken by marking it READY, for
;; Hexagon.Kern.Sched.maybeSchedule to resume in round-robin order. Swapping
;; ESP the way Hexagon.Kern.Proc.exit does would hijack this caller's own
;; stack, so the resumed hx.exec gets no injected success result

    cmp ecx, 0xFFFFFFFF
    je .done

    mov byte[Hexagon.Processes.Table.state + ecx], Hexagon.Processes.Table.States.ready

.done:

    clc

    ret

.notFound:

    stc

    mov eax, 05h

    ret

;;************************************************************************************

;; Looks up a variable in the calling process's own environment
;;
;; Input:
;;
;; ESI - Variable name (NUL-terminated, no '=')
;;
;; Output:
;;
;; ESI - Pointer to the value (NUL-terminated), if found
;; CF - Set if not found

Hexagon.Kern.Proc.getenv:

    push ebx
    push edi
    push es

    mov [.wantedName], esi

    push ds
    pop es

    movzx eax, byte[Hexagon.Scheduler.current]

    mov esi, dword[Hexagon.Processes.Table.envBase + eax * 4]

.entryLoop:

    cmp byte[es:esi], 0
    je .notFound ;; Double NUL: end of the block

    mov edi, dword[.wantedName]

.compareLoop:

    mov bl, byte[es:esi]
    mov al, byte[edi]

    cmp al, 0
    jne .compareChar

;; The wanted name ran out, so a match requires the stored entry to hit '='
;; at exactly this point

    cmp bl, '='
    je .found

    jmp .skipEntry

.compareChar:

    cmp bl, al
    jne .skipEntry

    inc esi
    inc edi

    jmp .compareLoop

.skipEntry:

;; Not a match: advance ESI to just past this entry's own NUL terminator

    cmp byte[es:esi], 0
    je .entryDone

    inc esi

    jmp .skipEntry

.entryDone:

    inc esi

    jmp .entryLoop

.found:

    inc esi ;; ESI sits on the stored entry's '='; the value starts right after it

    clc

    jmp .scanDone

.notFound:

    stc

.scanDone:

    pop es

.end:

    pop edi
    pop ebx

    ret

.wantedName: dd 0

;;************************************************************************************

;; Removes a variable from an environment block if present, compacting the
;; bytes after it back over the gap left behind. Shared by
;; Hexagon.Kern.Proc.setenv (replacing an existing entry) and
;; Hexagon.Kern.Proc.unsetenv
;;
;; Input:
;;
;; ESI - Variable name to remove
;; EDI - Environment block to modify in place
;;
;; Output:
;;
;; CF - Set if the variable wasn't found (block left unchanged)

Hexagon.Kern.Proc.removeEnvEntry:

    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push es

    mov [.wantedName], esi
    mov [.block], edi

    push ds
    pop es

;; First pass: find where the block's own terminating NUL sits, needed
;; below to know how many bytes to shift regardless of how many entries
;; follow the one being removed

    mov ebx, edi

.measureLoop:

    cmp byte[es:ebx], 0
    je .measured

.measureSkip:

    cmp byte[es:ebx], 0
    je .measureSkipped

    inc ebx

    jmp .measureSkip

.measureSkipped:

    inc ebx

    jmp .measureLoop

.measured:

    mov [.blockEnd], ebx

;; Second pass: find the entry matching .wantedName, the same "read up to
;; '=' or diverge" scan Hexagon.Kern.Proc.getenv uses

    mov ebx, dword[.block]

.entryLoop:

    cmp byte[es:ebx], 0
    je .notFound ;; Reached the terminating NUL without a match

    mov esi, ebx
    mov edi, dword[.wantedName]

.matchLoop:

    mov al, byte[es:esi]
    mov dl, byte[edi]

    cmp dl, 0
    jne .matchChar

    cmp al, '='
    je .found

    jmp .nextEntry

.matchChar:

    cmp al, dl
    jne .nextEntry

    inc esi
    inc edi

    jmp .matchLoop

.nextEntry:

.skip:

    cmp byte[es:ebx], 0
    je .skipped

    inc ebx

    jmp .skip

.skipped:

    inc ebx

    jmp .entryLoop

.found:

;; EBX = start of the matched entry. ESI is already inside it, from the
;; scan above, so advance it to just past the entry's own NUL

.findEntryEnd:

    cmp byte[es:esi], 0
    je .entryEndFound

    inc esi

    jmp .findEntryEnd

.entryEndFound:

    inc esi ;; ESI = start of whatever comes after the matched entry

    mov ecx, dword[.blockEnd]
    sub ecx, esi
    inc ecx ;; +1 to also shift the block's own terminating NUL

    mov edi, ebx ;; Destination: where the matched entry started

.shiftLoop:

    cmp ecx, 0
    je .removed

    mov al, byte[es:esi]

    mov byte[es:edi], al

    inc esi
    inc edi

    dec ecx

    jmp .shiftLoop

.removed:

    clc

    jmp .end

.notFound:

    stc

.end:

    pop es
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax

    ret

.wantedName: dd 0
.block:      dd 0
.blockEnd:   dd 0

;;************************************************************************************

;; Inserts or replaces a variable in the calling process's own environment.
;; Removes any existing entry with the same name first
;;
;; Input:
;;
;; ESI - Variable name (NUL-terminated, no '=')
;; EDI - Value (NUL-terminated)
;;
;; Output:
;;
;; CF - Set if the new value doesn't fit within
;;      Hexagon.Kern.Proc.maxEnvironmentLength. Any existing entry with
;;      this name is still removed either way, so the environment is
;;      always left well-formed, just possibly without this variable

Hexagon.Kern.Proc.setenv:

    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push es

    mov [.wantedName], esi
    mov [.newValue], edi

    movzx eax, byte[Hexagon.Scheduler.current]

    mov edi, dword[Hexagon.Processes.Table.envBase + eax * 4]
    mov esi, dword[.wantedName]

    call Hexagon.Kern.Proc.removeEnvEntry ;; CF ignored: a no-op if not already present

    push ds
    pop es

;; Find the (possibly just-shortened) block's terminating NUL again, the
;; same measuring pass as Hexagon.Kern.Proc.removeEnvEntry

    mov ebx, dword[Hexagon.Processes.Table.envBase + eax * 4]

.measureLoop:

    cmp byte[es:ebx], 0
    je .measured

.measureSkip:

    cmp byte[es:ebx], 0
    je .measureSkipped

    inc ebx

    jmp .measureSkip

.measureSkipped:

    inc ebx

    jmp .measureLoop

.measured:

;; EBX = where the new entry starts. Track the remaining budget as we
;; write, one byte at a time, so a name/value that doesn't fit is caught
;; instead of overflowing Hexagon.Processes.Table.envBase's allocation.
;; The -1 reserves room for the block's own terminating NUL, written last

    mov edx, ebx
    sub edx, dword[Hexagon.Processes.Table.envBase + eax * 4]

    mov ecx, Hexagon.Kern.Proc.maxEnvironmentLength
    sub ecx, edx
    dec ecx ;; ECX = room left, minus the block's own terminating NUL

    mov edi, ebx
    mov esi, dword[.wantedName]

.appendName:

    mov al, byte[esi]

    cmp al, 0
    je .appendEquals

    cmp ecx, 0
    je .doesNotFit

    mov byte[es:edi], al

    inc esi
    inc edi
    dec ecx

    jmp .appendName

.appendEquals:

    cmp ecx, 0
    je .doesNotFit

    mov byte[es:edi], '='

    inc edi
    dec ecx

    mov esi, dword[.newValue]

.appendValue:

    mov al, byte[esi]

    cmp ecx, 0
    je .doesNotFit

    mov byte[es:edi], al

    inc esi
    inc edi
    dec ecx

    cmp al, 0
    jne .appendValue

    mov byte[es:edi], 0 ;; Block's own terminating NUL, right after the entry's

    clc

    jmp .end

.doesNotFit:

;; Leave what was written so far terminated, so the block stays
;; well-formed even though this entry didn't make it in

    mov byte[es:edi], 0

    stc

.end:

    pop es
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax

    ret

.wantedName: dd 0
.newValue:   dd 0

;;************************************************************************************

;; Removes a variable from the calling process's own environment
;;
;; Input:
;;
;; ESI - Variable name to remove
;;
;; Output:
;;
;; CF - Set if the variable wasn't found

Hexagon.Kern.Proc.unsetenv:

    push eax
    push edi

    movzx eax, byte[Hexagon.Scheduler.current]

    mov edi, dword[Hexagon.Processes.Table.envBase + eax * 4]

    call Hexagon.Kern.Proc.removeEnvEntry

    pop edi
    pop eax

    ret

;;************************************************************************************

;; Returns the calling process's whole environment block
;;
;; Output:
;;
;; ESI - Pointer to the raw, double-NUL-terminated environment block
;; EAX - Number of variables in it

Hexagon.Kern.Proc.environ:

    push ebx
    push es

    push ds
    pop es

    movzx ebx, byte[Hexagon.Scheduler.current]

    mov esi, dword[Hexagon.Processes.Table.envBase + ebx * 4]

    mov ebx, esi

    xor eax, eax

.entryLoop:

    cmp byte[es:ebx], 0
    je .end

    inc eax

.skip:

    cmp byte[es:ebx], 0
    je .skipped

    inc ebx

    jmp .skip

.skipped:

    inc ebx

    jmp .entryLoop

.end:

    pop es

    pop ebx

    ret

