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
;;                    Hexagon.Processes.Table - unified process table
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
times Hexagon.Processes.Table.limit db 0 ;; Hexagon.Processes.Table.States.*

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

Hexagon.Processes.Table.name:
times Hexagon.Processes.Table.limit*13 db 0 ;; Process name, space-padded, for ps/hx.getProcesses

Hexagon.Processes.Table.nextPID: dd 0 ;; Monotonic counter, next PID to hand out

Hexagon.Processes.Table.limit = 16

end virtual

Hexagon.Processes.Table.States.free     = 0
Hexagon.Processes.Table.States.ready    = 1
Hexagon.Processes.Table.States.running  = 2
Hexagon.Processes.Table.States.blocked  = 3
Hexagon.Processes.Table.States.zombie   = 4
Hexagon.Processes.Table.States.sleeping = 5

Hexagon.Processes.Table.stackSize = 16384 ;; Dedicated stack space carved out of each process's own block

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

;; Marks whether the currently running process can be terminated by a key
;; combination (the "Kill process" key), a safeguard against closing vital
;; processes such as the login application

Hexagon.Kern.Proc.processLocked: dd 0

;;************************************************************************************

;; Unlock the current process, allowing the user to terminate it

Hexagon.Kern.Proc.unlock:

    mov dword[Hexagon.Kern.Proc.processLocked], 0

    ret

;;************************************************************************************

;; Lock the current process, preventing it from being terminated by a key combination

Hexagon.Kern.Proc.lock:

    mov dword[Hexagon.Kern.Proc.processLocked], 1

    ret

;;************************************************************************************

;; Allows you to terminate a process currently running by the system, if such
;; termination is possible

Hexagon.Kern.Proc.killForegroundProcess:

;; End current running process

;; First, you must check whether the function of ending a process in the foreground using
;; a key combination or the special "Kill process" key is enabled by the system.
;; This is a security measure that aims to prevent the closure of vital processes, such as the
;; login application, for example.

;; If the function is disabled, the occurrence will be ignored

    cmp dword[Hexagon.Kern.Proc.processLocked], 1
    je .end

    cmp byte[Hexagon.Scheduler.current], 0xFF ;; There is no process to be closed
    je .end

match =YES, VERBOSE
{

    mov esi, Hexagon.Verbose.Services.killProcess
    mov ebx, Hexagon.Dmesg.Priorities.p5

    call Hexagon.Kern.Dmesg.createMessage

}

    push ds
    pop es

    pop eax

    mov ax, 18h
    mov es, ax

    mov eax, dword[Hexagon.Console.fontColor]
    mov ebx, dword[Hexagon.Console.backgroundColor]

;; Set default console color

    call Hexagon.Kernel.Dev.Gen.Console.Console.setConsoleColor

;; Update video buffer (secondary console -> main console)
;; This update is not mandatory, it is only useful for utilities that use double buffering

    ;; call Hexagon.Kernel.Dev.Gen.Console.Console.updateConsole

;; Use main console

    call Hexagon.Kernel.Dev.Gen.Console.Console.useMainConsole

;; Scroll console

    call Hexagon.Kernel.Dev.Gen.Console.Console.scrollConsole

    mov al, 20h

    out 20h, al

    call Hexagon.Kern.Proc.exit

    ret

.end:

    ret

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

Hexagon.Kern.Proc.exec:

    pusha

;; Find a free slot in the process table, doubles as the process-limit check

    xor ecx, ecx

.findSlot:

    cmp ecx, Hexagon.Processes.Table.limit
    jae .limitReached

    cmp byte[Hexagon.Processes.Table.state + ecx], Hexagon.Processes.Table.States.free
    je .slotFound

    inc ecx

    jmp .findSlot

.slotFound:

    push ecx ;; Remember the new slot index across everything below

;; Check if there are arguments for the process to be loaded

    cmp eax, 0
    je .noArguments

    push esi
    push es

    mov esi, edi

    call Hexagon.Libkern.String.stringSize

    mov ecx, eax

    inc ecx

    push 18h ;; Kernel linear segment
    pop es

;; Copy arguments to a known address

    mov esi, edi

    mov edi, Hexagon.Heap.ArgProc

    rep movsb ;; Copy (ECX) characters from ESI to EDI

    pop es

    pop esi

    jmp .checkImage

.noArguments:

    mov byte[gs:Hexagon.Heap.ArgProc], 0

.checkImage:

    push esi

    call Hexagon.Kernel.FS.VFS.fileExists ;; EAX = file size, CF = not found

    pop esi

    jc .missingImage

    push eax ;; Save the file size across checkHAPPImage

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

    movzx ecx, byte[Hexagon.Scheduler.current]

    cmp ecx, 0xFF
    je .blockBootCaller

    mov byte[Hexagon.Processes.Table.state + ecx], Hexagon.Processes.Table.States.blocked
    mov dword[Hexagon.Processes.Table.esp + ecx * 4], esp

    mov dword[Hexagon.Processes.Table.parentSlot + edx * 4], ecx

    jmp .blocked

.blockBootCaller:

    mov dword[Hexagon.Kern.Proc.bootCallerESP], esp
    mov dword[Hexagon.Kern.Proc.bootChildSlot], edx

.blocked:

    mov byte[Hexagon.Processes.Table.state + edx], Hexagon.Processes.Table.States.running

    mov byte[Hexagon.Scheduler.current], dl

    mov ebx, edx

    jmp Hexagon.Kern.Sched.dispatchSlot ;; Builds the child's iret frame and never returns here

.missingImage:

    pop ecx ;; Discard the slot index, nothing was allocated

    popa

    mov dword[Hexagon.Kern.Proc.lastErrorCode], 01h

    stc

    mov eax, 01h

    ret

.missingImage2:

    pop eax ;; Discard the saved file size
    pop ecx ;; Discard the slot index

    popa

    mov dword[Hexagon.Kern.Proc.lastErrorCode], 01h

    stc

    mov eax, 01h

    ret

.incompatibleImage:

    pop eax ;; Discard the saved file size
    pop ecx ;; Discard the slot index

    popa

    mov dword[Hexagon.Kern.Proc.lastErrorCode], 04h

    stc

    mov eax, 04h

    ret

.allocOrLoadFailed:

    popa

    mov dword[Hexagon.Kern.Proc.lastErrorCode], 02h

    stc

    mov eax, 02h

    ret

.limitReached:

    popa

    mov dword[Hexagon.Kern.Proc.lastErrorCode], 03h

    stc

    mov eax, 03h

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

;; Free this process's own memory block (individually allocated in Hexagon.Kern.Proc.exec/spawn)

    mov ebx, dword[Hexagon.Processes.Table.base + edx * 4]
    mov ecx, dword[Hexagon.Processes.Table.size + edx * 4]

    push ebx
    push ecx

    call Hexagon.Arch.Gen.Mm.free

    pop ecx
    pop ebx

    push ecx

    mov eax, ecx

    call Hexagon.Arch.Gen.Mm.freeMemoryUsage

    pop ecx

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

    mov ebx, edx

.scanNext:

    inc ebx

    cmp ebx, Hexagon.Processes.Table.limit
    jb .checkNext

    xor ebx, ebx

.checkNext:

    cmp ebx, edx
    je .resumeBoot ;; Nothing else is READY either, fall back to the boot context

    cmp byte[Hexagon.Processes.Table.state + ebx], Hexagon.Processes.Table.States.ready
    je .scheduleNext

    jmp .scanNext

.scheduleNext:

    mov byte[Hexagon.Scheduler.current], bl

    cmp dword[Hexagon.Processes.Table.esp + ebx * 4], 0
    jne .resumeNext

    jmp Hexagon.Kern.Sched.dispatchSlot ;; First ever dispatch of this slot

.resumeNext:

    mov eax, dword[Hexagon.Processes.Table.base + ebx * 4]

    call Hexagon.Kern.Sched.setUserSegmentBase

    mov esp, dword[Hexagon.Processes.Table.esp + ebx * 4]

    mov byte[Hexagon.Processes.Table.state + ebx], Hexagon.Processes.Table.States.running

    popa

    xor eax, eax

    clc

    ret

.resumeParent:

    mov byte[Hexagon.Processes.Table.state + ecx], Hexagon.Processes.Table.States.ready

    mov byte[Hexagon.Scheduler.current], cl

    mov esp, dword[Hexagon.Processes.Table.esp + ecx * 4]

    mov eax, dword[Hexagon.Processes.Table.base + ecx * 4]

    push ecx

    call Hexagon.Kern.Sched.setUserSegmentBase

    pop ecx

    mov byte[Hexagon.Processes.Table.state + ecx], Hexagon.Processes.Table.States.running

    popa

    xor eax, eax

    clc

    ret

.resumeBoot:

    mov byte[Hexagon.Scheduler.current], 0xFF

    mov esp, dword[Hexagon.Kern.Proc.bootCallerESP]

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

    mov edi, Hexagon.Heap.ArgProc ;; Offset, inside the kernel

    sub edi, eax ;; Get effective address (offset)

    pop eax

    ret

;;************************************************************************************

;; Hexagon.Kern.Proc.getProcessTable emits into Hexagon.Heap.Temp a 4-byte
;; record size, followed by one record per Hexagon.Processes.Table slot that
;; isn't FREE, in slot order, each shaped like this:
;;
;; +0  dd PID
;; +4  dd Parent PID (0 = launched directly by the kernel, no parent process)
;; +8  db State (Hexagon.Processes.Table.States.*)
;; +9  db Name, NUL-terminated within a fixed 13-byte field
;;
;; The record size travels with the data instead of being a constant the
;; caller has to already know, so ps/top don't need to be rebuilt in lockstep
;; whenever the record shape changes here

Hexagon.Kern.Proc.getProcessTable.recordSize = 22

;; Output:
;;
;; EAX - Number of records
;; ESI - Hexagon.Heap.Temp: a dd record size, followed by that many records

Hexagon.Kern.Proc.getProcessTable:

    push ds ;; Kernel data segment
    pop es

    mov edi, Hexagon.Heap.Temp

    mov dword[edi], Hexagon.Kern.Proc.getProcessTable.recordSize

    add edi, 4

    xor ecx, ecx ;; ECX = slot index
    xor edx, edx ;; EDX = record count

.loop:

    cmp ecx, Hexagon.Processes.Table.limit
    jae .done

    cmp byte[Hexagon.Processes.Table.state + ecx], Hexagon.Processes.Table.States.free
    je .next

    push ecx

    mov eax, dword[Hexagon.Processes.Table.pid + ecx * 4]

    stosd

    mov eax, dword[Hexagon.Processes.Table.parentPID + ecx * 4]

    stosd

    mov al, byte[Hexagon.Processes.Table.state + ecx]

    stosb

;; Find the real length of this slot's name, capped at 12 so a NUL
;; terminator always fits within the fixed 13-byte name field

    mov esi, ecx

    imul esi, 13

    add esi, Hexagon.Processes.Table.name

    xor ebx, ebx

.measureName:

    cmp ebx, 12
    jae .measured

    cmp byte[esi + ebx], ' '
    je .measured

    inc ebx

    jmp .measureName

.measured:

    mov ecx, ebx

    rep movsb ;; Copy the real name characters

    mov ecx, 13
    sub ecx, ebx

    xor al, al

    rep stosb ;; NUL-terminate and pad out the rest of the name field

    pop ecx

    inc edx

.next:

    inc ecx

    jmp .loop

.done:

    mov eax, edx

    mov esi, Hexagon.Heap.Temp

    ret

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
;;       Hexagon.Arch.Gen.Mm.free
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

    add eax, 65536 ;; appFileBuffer-style scratch margin, see below for why

;; Many existing apps (login, logind, sh, anything using verUtils.s) read a
;; configuration file straight into "appFileBuffer", a bare label plaE =ced right
;; after their own code with no reserved space of its own. They rely on free
;; slack past their own image at runtime. 64 KB comfortably covers this until
;; those apps reserve their own buffer space explicitly

    add eax, Hexagon.Processes.Table.stackSize ;; Dedicated stack for this process

    push eax ;; Remember the total size across the calls below

    mov ebx, eax

    call Hexagon.Arch.Gen.Mm.malloc

    cmp eax, 0
    je .allocError

    push ebx ;; Remember the allocated base across the openFile call

    mov edi, ebx

;; Correct address with segment base (physical address = address + segment base)

    sub edi, 500h

    push esi

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

    call Hexagon.Arch.Gen.Mm.free ;; Avoid leaking the block for an image that failed to load

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
;; the slot READY either way; hx.exec additionally blocks its caller and
;; dispatches the slot immediately right after calling this
;;
;; Input:
;;
;; EDX - Slot index (already confirmed free)
;; EBX - Allocated physical base
;; ECX - Total allocated size
;; ESI - Filename (used as the process's display name)
;;
;; Output:
;;
;; EAX - PID assigned to the new process

Hexagon.Kern.Proc.registerSlot:

;; The name-copy loop below writes through ES:EDI (stosb). hexagonHandler
;; leaves ES on the kernel linear segment (base 0), but Hexagon.Processes.Table
;; is addressed relative to the kernel data segment (base 500h), so ES needs
;; to be realigned with DS first or the name lands 500h bytes away from
;; where Hexagon.Kern.Proc.getProcessTable later reads it

    push ds
    pop es

    mov byte[Hexagon.Processes.Table.state + edx], Hexagon.Processes.Table.States.ready

    mov dword[Hexagon.Processes.Table.base + edx * 4], ebx
    mov dword[Hexagon.Processes.Table.size + edx * 4], ecx

    mov eax, dword[Hexagon.Libkern.HAPP.imageHAPPHeader.entryHAPP]
    mov dword[Hexagon.Processes.Table.entry + edx * 4], eax

    mov dword[Hexagon.Processes.Table.esp + edx * 4], 0 ;; Never dispatched yet

    push ebx
    push ecx

    mov eax, ecx

    call Hexagon.Arch.Gen.Mm.confirmMemoryUsage ;; Accounting

    pop ecx
    pop ebx

    inc dword[Hexagon.Processes.Table.nextPID]

    mov eax, dword[Hexagon.Processes.Table.nextPID]

    mov dword[Hexagon.Processes.Table.pid + edx * 4], eax

;; Record who created this process: 0 if launched directly by the kernel at
;; boot, otherwise whoever is currently running. Kept for spawned processes
;; too, purely so ps/debugging can trace where they came from

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

;; Copy the process name into the table (for ps/hx.getProcesses)

    push eax

    mov edi, edx

    imul edi, 13

    add edi, Hexagon.Processes.Table.name

    mov ecx, 13

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

    ret

;;************************************************************************************

;; Creates a new process without blocking the caller. Fully validated,
;; allocated and loaded, then left READY in the process table for
;; Hexagon.Kern.Sched.maybeSchedule to dispatch on its own schedule. Does not
;; support arguments yet, unlike hx.exec
;;
;; Input:
;;
;; ESI - Buffer containing the name of the file to be executed
;;
;; Output:
;;
;; EAX - PID of the new process (on success)
;; CF  - Set on error (process limit reached, image not found or
;;       incompatible, out of memory)

Hexagon.Kern.Proc.spawn:

    push esi

    call Hexagon.Kernel.FS.VFS.fileExists ;; EAX = file size, CF = not found

    pop esi

    jc .missingImage

    push eax ;; Save the file size across checkHAPPImage

    call Hexagon.Libkern.HAPP.checkHAPPImage

    cmp byte[Hexagon.Libkern.HAPP.imageHAPPHeader.incompatibleImage], 01h
    je .incompatibleImage

    cmp byte[Hexagon.Libkern.HAPP.imageHAPPHeader.incompatibleImage], 02h
    je .missingImage2

;; Find a free slot in the process table

    xor ecx, ecx

.findSlot:

    cmp ecx, Hexagon.Processes.Table.limit
    jae .limitReached

    cmp byte[Hexagon.Processes.Table.state + ecx], Hexagon.Processes.Table.States.free
    je .slotFound

    inc ecx

    jmp .findSlot

.slotFound:

    pop eax ;; Restore the file size

    push ecx ;; Remember the free slot index across allocateAndLoadImage

    call Hexagon.Kern.Proc.allocateAndLoadImage ;; EBX = base, ECX = total size, CF = error

    pop edx ;; EDX = free slot index

    jc .allocOrLoadFailed

;; EDX = slot, EBX = base, ECX = size, ESI = filename -> EAX = new pid

    call Hexagon.Kern.Proc.registerSlot

    clc

    ret

.missingImage:

    stc

    mov eax, 01h

    ret

.missingImage2:

    pop eax ;; Discard the saved file size

    stc

    mov eax, 01h

    ret

.incompatibleImage:

    pop eax ;; Discard the saved file size

    stc

    mov eax, 04h

    ret

.limitReached:

    pop eax ;; Discard the saved file size

    stc

    mov eax, 03h

    ret

.allocOrLoadFailed:

    stc

    mov eax, 02h

    ret

;;************************************************************************************

;; Terminates an arbitrary process by PID, requested through hx.kill. Unlike
;; Hexagon.Kern.Proc.killForegroundProcess (the F1 hotkey handler, which
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
;; CF - Set on error (no process with this PID); EAX = 05h
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

    movzx edx, byte[Hexagon.Scheduler.current]

    cmp ecx, edx
    jne .killOther

;; Killing the caller itself, same as a plain hx.exit, never returns here

    xor eax, eax

    jmp Hexagon.Kern.Proc.exit

.killOther:

    mov edx, ecx ;; EDX = slot to terminate

    mov ebx, dword[Hexagon.Processes.Table.base + edx * 4]
    mov ecx, dword[Hexagon.Processes.Table.size + edx * 4]

    push ebx
    push ecx

    call Hexagon.Arch.Gen.Mm.free

    pop ecx
    pop ebx

    push ecx

    mov eax, ecx

    call Hexagon.Arch.Gen.Mm.freeMemoryUsage

    pop ecx

    mov byte[Hexagon.Processes.Table.state + edx], Hexagon.Processes.Table.States.free

;; If the process being killed had itself exec'd a child that hasn't
;; finished yet (sh running the "kill" command that then targets sh's
;; own PID), that child's parentSlot still points at this slot. Left alone,
;; the child's own eventual hx.exit would resume this slot through the
;; base/esp it still remembers, even though the memory backing it was just
;; freed above and may belong to someone else by then. Sever the link so
;; exit treats it as an orphan instead, the same path already used for
;; hx.spawn'd processes with no blocking caller

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

;; If another process's hx.exec is BLOCKED waiting on this one, wake it by
;; marking it READY. Hexagon.Kern.Sched.maybeSchedule will resume it through
;; the normal round-robin path on its own next turn. This does not reproduce
;; Hexagon.Kern.Proc.exit's own resume trick (swapping ESP to jump straight
;; into the parent), which would hijack the caller's own stack here instead
;; of the killed process's, so the resumed hx.exec call does not get exit's
;; usual clean EAX=0/CF=0 "child succeeded" result injected into it

    mov ecx, dword[Hexagon.Processes.Table.parentSlot + edx * 4]

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
