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
;;                     Hexagon kernel process scheduler
;;
;; This is the round-robin scheduler, responsible for choosing which process
;; runs next and performing the context switch between ready processes in
;; Hexagon.Processes.Table
;;
;;************************************************************************************

;;************************************************************************************
;;
;; Hexagon process scheduling
;;
;;************************************************************************************

use32

;;************************************************************************************

Hexagon.Kern.Sched.setupScheduler:

    logHexagon Hexagon.Verbose.heapKernel, Hexagon.Dmesg.Priorities.p5

    push ds
    pop es

    mov edi, Hexagon.Processes.Table.state
    mov ecx, Hexagon.Processes.Table.limit
    mov al, Hexagon.Processes.Table.States.free

    rep stosb

    mov dword[Hexagon.Processes.Table.nextPID], 0

    mov byte[Hexagon.Scheduler.current], 0xFF

    call Hexagon.Kern.Sched.installIdle

    logHexagon Hexagon.Verbose.scheduler, Hexagon.Dmesg.Priorities.p5

    ret

;;************************************************************************************
;;
;;                     Round-robin scheduler over Hexagon.Processes.Table
;;
;;************************************************************************************

Hexagon.Scheduler.current: db 0xFF ;; 0xFF = kernel boot context, else a Hexagon.Processes.Table index
Hexagon.Scheduler.ticks:   dd 0
Hexagon.Scheduler.sliceLength = 1  ;; Timer ticks per time-slice

;; maybeSchedule refuses to switch away from the running process while this is
;; non-zero, so a preemption cannot land mid-swap of a mount's working copy. A
;; nesting depth and not a boolean, since these calls nest and clearing it
;; to 0 would end an outer caller's protection at the first nested return

Hexagon.Scheduler.preemptionDisabled: db 0

;; Input: none. Output: none. Clobbers nothing. Safe to call while already
;; disabled. Each call needs a matching Hexagon.Kern.Sched.enablePreemption
;; to actually re-enable it

Hexagon.Kern.Sched.disablePreemption:

    inc byte[Hexagon.Scheduler.preemptionDisabled]

    ret

;; Input: none. Output: none. Clobbers nothing. Only re-enables preemption
;; once every matching Hexagon.Kern.Sched.disablePreemption call has had
;; its own matching enablePreemption

Hexagon.Kern.Sched.enablePreemption:

    dec byte[Hexagon.Scheduler.preemptionDisabled]

    ret

;;************************************************************************************

;; Reprograms the user code/data segment base in the GDT
;;
;; The processor caches a descriptor when its selector is loaded, so what makes
;; this take effect is the iret back to user level, and the segment registers
;; restored on the way there, not the table being reloaded
;;
;; Input:
;;
;; EAX - New base address (preserved across the call)

Hexagon.Kern.Sched.setUserSegmentBase:

    push eax
    push edx

    mov edx, eax
    and eax, 0xFFFF

    mov word[GDT.userCode + 2], ax
    mov word[GDT.userData + 2], ax

    mov eax, edx

    shr eax, 16
    and eax, 0xFF

    mov byte[GDT.userCode + 4], al
    mov byte[GDT.userData + 4], al

    mov eax, edx

    shr eax, 24
    and eax, 0xFF

    mov byte[GDT.userCode + 7], al
    mov byte[GDT.userData + 7], al

    pop edx
    pop eax

    ret

;;************************************************************************************

;; Builds a fresh iret frame for a slot's very first dispatch and jumps into
;; it. Shared by Hexagon.Kern.Proc.exec (launching a fresh child) and
;; Hexagon.Kern.Sched.maybeSchedule (first dispatch of a spawned process).
;; Never returns to its caller. Reached with a plain "jmp", not "call"
;;
;; Input:
;;
;; EBX - Slot index to dispatch

Hexagon.Kern.Sched.dispatchSlot:

;; Callers arrive with Hexagon.Scheduler.current already naming this slot while
;; ESP is still on the stack they came in on. A timer landing before the iret
;; below would save that foreign ESP into this slot, leaving two processes on
;; one stack. The frame below carries its own EFLAGS, so masking costs nothing

    cli

    mov eax, dword[Hexagon.Processes.Table.base + ebx * 4]

    call Hexagon.Kern.Sched.setUserSegmentBase

    mov eax, ebx

    call Hexagon.Arch.Paging.switchSpace ;; Its own directory, and the stack a trap lands on

;; A process's arguments and environment live in the kernel's own arena rather
;; than in its block, so the pages holding them are opened to user level here,
;; where everything about the slot is finally in place

    mov eax, dword[Hexagon.Processes.Table.pageDirectory + ebx * 4]
    mov ecx, Hexagon.Kern.Proc.maxArgumentsLength

    push ebx

    mov edx, ebx ;; Whose the pages being opened are

    mov ebx, dword[Hexagon.Processes.Table.argBase + ebx * 4]

    call Hexagon.Arch.Paging.openRangeToUser

    pop ebx

    mov eax, dword[Hexagon.Processes.Table.pageDirectory + ebx * 4]
    mov ecx, Hexagon.Kern.Proc.maxEnvironmentLength

    push ebx

    mov edx, ebx ;; Whose the pages being opened are

    mov ebx, dword[Hexagon.Processes.Table.envBase + ebx * 4]

    call Hexagon.Arch.Paging.openRangeToUser

    pop ebx

    call Hexagon.Kern.Proc.calculateArgumentsAddress ;; EDI = arguments address for the new process

;; The process's stack lives inside its own segment, so this is an offset from
;; the base, and not the address the kernel itself would use

    mov ecx, dword[Hexagon.Processes.Table.size + ebx * 4]

    sub ecx, 4 ;; Small headroom from the very top of the block

;; Entering user level is a change of privilege, so the frame the IRET reads
;; carries the stack to switch to as well as where to resume

    push Hexagon.Arch.CPU.CPU.userDataSelector
    push ecx

;; Written out, and not taken from pushfd, which would hand the process the
;; masked flags this function runs under. IF set, IOPL 0, so a process cannot
;; touch the interrupt flag or an I/O port

    push 202h

    push Hexagon.Arch.CPU.CPU.userCodeSelector
    push dword[Hexagon.Processes.Table.entry + ebx * 4] ;; Image entry point

    mov ax, Hexagon.Arch.CPU.CPU.userDataSelector

    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    iret

;;************************************************************************************

;; Called from Hexagon.Kern.Services.timerHandler once per time-slice, with EAX
;; and DS already saved and DS on the kernel data segment. Looks for the next
;; READY process in round-robin order and ends with a plain "ret" either way,
;; which lands in the resumed context when it switched, carried by the stack

Hexagon.Kern.Sched.maybeSchedule:

    cmp byte[Hexagon.Scheduler.preemptionDisabled], 0
    jne .preemptionOff

    pusha

;; Wake any process whose Hexagon.Kern.Sched.sleep wait has expired,
;; promoting it back to READY so the round robin scan below picks it up
;; like any other ready process

    xor ebx, ebx

.wakeScan:

    cmp ebx, Hexagon.Processes.Table.limit
    jae .wakeScanDone

    cmp byte[Hexagon.Processes.Table.state + ebx], Hexagon.Processes.Table.States.sleeping
    jne .wakeScanNext

;; timerCounter wraps to 0 after about 497 days at 100 Hz, and a wakeTick
;; recorded just before that wrap is numerically far below it, which an
;; unsigned comparison reads as already reached
;;
;; Subtracting sidesteps that, since 32 bit subtraction is itself circular:
;; the difference read as signed is the real remaining distance. jl jumps
;; while it is still negative, and is used over js because it checks SF
;; against OF, covering a subtraction that overflows as signed arithmetic
;;
;; This holds while the two values stay within half the counter's range,
;; around 248 days, and every sleep here is on the order of seconds

    mov eax, dword[Hexagon.Kern.Services.timerHandler.timerCounter]
    sub eax, dword[Hexagon.Processes.Table.wakeTick + ebx * 4]

    jl .wakeScanNext

    mov byte[Hexagon.Processes.Table.state + ebx], Hexagon.Processes.Table.States.ready

.wakeScanNext:

    inc ebx

    jmp .wakeScan

.wakeScanDone:

    movzx edx, byte[Hexagon.Scheduler.current] ;; EDX = who is running now

    cmp edx, 0xFF
    je .noSwitch ;; Still in raw kernel-boot context, nothing to preempt yet

    mov ebx, edx ;; EBX = scan cursor

.scan:

    inc ebx

    cmp ebx, Hexagon.Processes.Table.limit
    jb .checkCandidate

    xor ebx, ebx

.checkCandidate:

;; Scanned all the way back to whoever is already running. Nobody else is
;; ready, stay put

    cmp ebx, edx
    je .noSwitch

    cmp byte[Hexagon.Processes.Table.state + ebx], Hexagon.Processes.Table.States.ready
    je .candidateValid

    jmp .scan

.candidateValid:

;; EBX = target slot to switch to, EDX = who is running now

    mov dword[Hexagon.Processes.Table.esp + edx * 4], esp

;; The idle slot (PID 0) must never be in the States.ready state. If that were to happen,
;; it would enter the list of processes contending for the scheduler, which must not occur.
;; In this scenario, when a process exits and no other process is waiting or ready,
;; the idle process should execute. Its state is changed to State.running,
;; but when it is preempted to run another ready process, its status must not
;; be changed to States.ready, but rather back to States.idle,
;; so that it does not compete with the other processes.

    cmp edx, Hexagon.Kern.Sched.idleSlot
    je .outgoingWasIdle

    mov byte[Hexagon.Processes.Table.state + edx], Hexagon.Processes.Table.States.ready

    jmp .outgoingDone

.outgoingWasIdle:

    mov byte[Hexagon.Processes.Table.state + edx], Hexagon.Processes.Table.States.idle

.outgoingDone:

    mov byte[Hexagon.Processes.Table.state + ebx], Hexagon.Processes.Table.States.running

    mov byte[Hexagon.Scheduler.current], bl

    cmp dword[Hexagon.Processes.Table.esp + ebx * 4], 0
    jne .resumeSlot

    jmp Hexagon.Kern.Sched.dispatchSlot ;; First ever dispatch of this slot

.resumeSlot:

    mov eax, dword[Hexagon.Processes.Table.base + ebx * 4]

    call Hexagon.Kern.Sched.setUserSegmentBase

    mov eax, ebx

    call Hexagon.Arch.Paging.switchSpace

    mov esp, dword[Hexagon.Processes.Table.esp + ebx * 4]

    popa

    ret

.noSwitch:

    popa

    ret

.preemptionOff:

    ret

;;************************************************************************************

;; Slot 0 is permanently reserved for the idle loop below, installed once at
;; boot by Hexagon.Kern.Sched.installIdle, before init (PID 1) ever runs.
;; Unlike every other slot, it is never hx.spawn/hx.exec'd from a HAPP file
;; on disk and never exits, but is simply always there, in
;; Hexagon.Processes.Table.States.idle, as the last-resort candidate
;; Hexagon.Kern.Proc.exit's own "nothing else is READY" fallback dispatches

Hexagon.Kern.Sched.idleSlot = 0

Hexagon.Kern.Sched.idleName:
db "idle", 0

;; The idle loop itself, never reached through Hexagon.Kern.Sched.dispatchSlot,
;; which treats Table.entry as an offset into a relocated image and patches the
;; user descriptors to match. This is a fixed address in the kernel's own code,
;; so Hexagon.Kern.Sched.installIdle seeds the synthetic frame below for an
;; ordinary "ret" to land on. Once running it is preempted and resumed like any
;; other process

Hexagon.Kern.Sched.idleLoop:

.spin:

    sti

    hlt

    jmp .spin

;; Dedicated stack for Hexagon.Kern.Sched.idleLoop, with a ready-made resume
;; frame at the top: 8 dummy registers in popa's load order, then idleLoop's
;; own address where "ret" expects one. The first dispatch therefore loads
;; zeroes and lands on the loop, exactly as every later resume does

Hexagon.Kern.Sched.idleStack:
times 480 db 0
Hexagon.Kern.Sched.idleFrame:
dd 0, 0, 0, 0, 0, 0, 0, 0
dd Hexagon.Kern.Sched.idleLoop
Hexagon.Kern.Sched.idleStackTop:

;; Installs the idle loop into Hexagon.Kern.Sched.idleSlot, once, from
;; Hexagon.Kern.Sched.setupScheduler. Bypasses Hexagon.Kern.Proc.registerSlot,
;; which expects a HAPP image loaded from disk, and keeps PID 0 forever rather
;; than consuming the next one

Hexagon.Kern.Sched.installIdle:

    push ds
    pop es

    mov byte[Hexagon.Processes.Table.state + Hexagon.Kern.Sched.idleSlot], Hexagon.Processes.Table.States.idle

    mov dword[Hexagon.Processes.Table.pid + Hexagon.Kern.Sched.idleSlot * 4], 0
    mov dword[Hexagon.Processes.Table.parentSlot + Hexagon.Kern.Sched.idleSlot * 4], 0xFFFFFFFF
    mov dword[Hexagon.Processes.Table.parentPID + Hexagon.Kern.Sched.idleSlot * 4], 0

;; Table.base and Table.esp are loaded straight into ESP and passed to
;; setUserSegmentBase, which treat them as flat addresses. Every segment is
;; based at 0, so the kernel-image labels below are already exactly that

    mov dword[Hexagon.Processes.Table.base + Hexagon.Kern.Sched.idleSlot * 4], Hexagon.Kern.Sched.idleStack
    mov dword[Hexagon.Processes.Table.size + Hexagon.Kern.Sched.idleSlot * 4], Hexagon.Kern.Sched.idleStackTop - Hexagon.Kern.Sched.idleStack
    mov dword[Hexagon.Processes.Table.entry + Hexagon.Kern.Sched.idleSlot * 4], Hexagon.Kern.Sched.idleLoop
    mov dword[Hexagon.Processes.Table.esp + Hexagon.Kern.Sched.idleSlot * 4], Hexagon.Kern.Sched.idleFrame

    mov edi, Hexagon.Kern.Sched.idleSlot
    imul edi, 64
    add edi, Hexagon.Processes.Table.name

    mov esi, Hexagon.Kern.Sched.idleName
    mov ecx, 64

.copyName:

    lodsb

    cmp al, 0
    je .padName

    stosb

    loop .copyName

    jmp .named

.padName:

    mov al, ' '

    rep stosb

.named:

    ret

;;************************************************************************************

;; Puts the calling process to sleep for the given number of ticks without
;; occupying a round robin slot the whole time. Hexagon.Kern.Sched.maybeSchedule
;; wakes it back up once Hexagon.Kern.Services.timerHandler.timerCounter
;; reaches the requested tick, promoting it back to READY on its own next pass
;;
;; Input:
;;
;; ECX - Ticks to sleep, in counting units

Hexagon.Kern.Sched.sleep:

    pusha

;; Keep the scan and the state transition below atomic against a concurrent,
;; timer-driven Hexagon.Kern.Sched.maybeSchedule. hexagonHandler always
;; enables interrupts before reaching any syscall routine, so a plain "sti"
;; further down is enough to put them back the way they were found

    cli

    movzx edx, byte[Hexagon.Scheduler.current] ;; EDX = own slot

    add ecx, dword[Hexagon.Kern.Services.timerHandler.timerCounter] ;; ECX = absolute wake tick

    mov ebx, edx ;; EBX = scan cursor

.scan:

    inc ebx

    cmp ebx, Hexagon.Processes.Table.limit
    jb .checkCandidate

    xor ebx, ebx

.checkCandidate:

;; Scanned the whole table without finding anyone else ready. Sleeping here
;; would leave nothing running at all, so wait it out directly instead

    cmp ebx, edx
    je .noCandidate

    cmp byte[Hexagon.Processes.Table.state + ebx], Hexagon.Processes.Table.States.ready
    je .candidateFound

    jmp .scan

.noCandidate:

    sti

.busyWait:

;; Signed difference, same wraparound-safe comparison used by the wake scan
;; in Hexagon.Kern.Sched.maybeSchedule

    mov eax, dword[Hexagon.Kern.Services.timerHandler.timerCounter]
    sub eax, ecx

    jl .busyWait

    popa

    ret

.candidateFound:

;; EBX = target slot to switch to, EDX = own slot, ECX = own wake tick

    mov dword[Hexagon.Processes.Table.wakeTick + edx * 4], ecx
    mov dword[Hexagon.Processes.Table.esp + edx * 4], esp

    mov byte[Hexagon.Processes.Table.state + edx], Hexagon.Processes.Table.States.sleeping
    mov byte[Hexagon.Processes.Table.state + ebx], Hexagon.Processes.Table.States.running

    mov byte[Hexagon.Scheduler.current], bl

;; Table.esp[edx] is a clean pusha-only frame now, which is what
;; Hexagon.Kern.Sched.maybeSchedule's own wake path resumes through
;;
;; Interrupts stay masked from here: Hexagon.Scheduler.current already names the
;; incoming slot while ESP is still on this one's stack, and a timer in that gap
;; would leave the two sharing it

    cmp dword[Hexagon.Processes.Table.esp + ebx * 4], 0
    jne .resumeSlot

    jmp Hexagon.Kern.Sched.dispatchSlot ;; First ever dispatch of this slot

.resumeSlot:

    mov eax, dword[Hexagon.Processes.Table.base + ebx * 4]

    call Hexagon.Kern.Sched.setUserSegmentBase

    mov eax, ebx

    call Hexagon.Arch.Paging.switchSpace

    mov esp, dword[Hexagon.Processes.Table.esp + ebx * 4]

    popa

    ret

;;************************************************************************************

;; Returns the physical base address of whichever process is actually
;; running right now. Hexagon.Kern.Syscall.hexagonHandler uses this to
;; translate ESI/EDI, and Hexagon.Libkern.Graphics.drawBlockSyscall uses it
;; the same way for graphics coordinates
;;
;; Output:
;;
;; EAX - Base address, or 0 if no process is running

Hexagon.Kern.Sched.getCurrentProcessBase:

    push ebx

    movzx ebx, byte[Hexagon.Scheduler.current]

    cmp ebx, 0xFF
    je .none

    mov eax, dword[Hexagon.Processes.Table.base + ebx * 4]

    jmp .end

.none:

    xor eax, eax

.end:

    pop ebx

    ret
