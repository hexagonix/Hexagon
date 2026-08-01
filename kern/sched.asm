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

    logHexagon Hexagon.Verbose.scheduler, Hexagon.Dmesg.Priorities.p5

    ret

;;************************************************************************************
;;
;;                     Round-robin scheduler over Hexagon.Processes.Table
;;
;;************************************************************************************

Hexagon.Scheduler.current: db 0xFF ;; 0xFF = kernel boot context, else a Hexagon.Processes.Table index
Hexagon.Scheduler.ticks:   dd 0
Hexagon.Scheduler.sliceLength = 5  ;; Timer ticks per time-slice

;;************************************************************************************

;; Reprograms the user code/data segment base in the GDT
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

    lgdt[GDTReg]

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

    mov eax, dword[Hexagon.Processes.Table.base + ebx * 4]

    call Hexagon.Kern.Sched.setUserSegmentBase

    mov ecx, dword[Hexagon.Processes.Table.size + ebx * 4]

    add eax, ecx
    sub eax, 4 ;; Small headroom from the very top of the block

    mov esp, eax ;; Top of this process's own allocated block

    call Hexagon.Kern.Proc.calculateArgumentsAddress ;; EDI = arguments address for the new process

    sti ;; Make sure interrupts are available

    pushfd   ;; Flags

    push 30h ;; User environment code segment (process)
    push dword[Hexagon.Processes.Table.entry + ebx * 4] ;; Image entry point

    mov ax, 38h ;; User environment data segment (process)
    mov ds, ax

    iret

;;************************************************************************************

;; Called from Hexagon.Kern.Services.timerHandler, via "call", once per
;; time-slice. At that point EAX and DS are already saved on the current
;; stack and ds already points at the kernel data segment. Looks for the next
;; READY process in round-robin order. Ends with a plain "ret" either way:
;; with nothing else ready, that returns to the caller normally; when
;; switching, it returns into whatever context is being resumed, at the same
;; point in its own earlier call to this function, using the stack-swap
;; itself to carry the CPU state across

Hexagon.Kern.Sched.maybeSchedule:

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

;; timerCounter is a plain 32 bit counter, incremented once per tick with no
;; special handling at the top. After roughly 497 days of uptime at 100 Hz
;; it silently wraps from FFFFFFFFh back to 0, the same way any fixed width
;; counter does. A wakeTick recorded just before that wrap (say FFFFFFF0h
;; plus a 100 tick sleep, landing on 54h once the add itself wraps) would
;; look, to a plain unsigned comparison, like it has already been reached
;; the moment timerCounter is still sitting at FFFFFFF1h, since FFFFFFF1h
;; is numerically far greater than 54h. The process would wake almost
;; immediately instead of waiting out its real 99 remaining ticks
;;
;; Subtracting instead of comparing sidesteps this. timerCounter minus
;; wakeTick is computed the same way regardless of whether either value has
;; wrapped, since 32 bit subtraction is itself circular, modulo 2^32. What
;; changes is how the result is read afterward. FFFFFFF1h minus 54h is
;; FFFFFF9Dh, which read as an unsigned number looks enormous, but read as
;; signed two's complement is exactly -99, the correct remaining distance.
;; jl reads it that way, jumping while the signed result is still negative
;; and falling through once it reaches zero. jl is used rather than js
;; because it checks SF against OF rather than the sign bit alone, which
;; also covers the case where the subtraction itself overflows as signed
;; arithmetic
;;
;; This only holds while the true distance between the two values stays
;; under half the counter's range, 2^31 ticks, around 248 days. Past that
;; point a circular comparison can no longer tell which direction is really
;; closer. Every sleep requested through Hexagon.Kern.Sched.sleep is on the
;; order of seconds, nowhere near that limit

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

    mov byte[Hexagon.Processes.Table.state + edx], Hexagon.Processes.Table.States.ready
    mov byte[Hexagon.Processes.Table.state + ebx], Hexagon.Processes.Table.States.running

    mov byte[Hexagon.Scheduler.current], bl

    cmp dword[Hexagon.Processes.Table.esp + ebx * 4], 0
    jne .resumeSlot

    jmp Hexagon.Kern.Sched.dispatchSlot ;; First ever dispatch of this slot

.resumeSlot:

    mov eax, dword[Hexagon.Processes.Table.base+ebx*4]

    call Hexagon.Kern.Sched.setUserSegmentBase

    mov esp, dword[Hexagon.Processes.Table.esp+ebx*4]

    popa

    ret

.noSwitch:

    popa

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

;; Table.esp[edx] above is a clean, pusha-only frame now, exactly what the
;; ordinary wake path in Hexagon.Kern.Sched.maybeSchedule expects to resume
;; through later, so interrupts can safely come back on here

    sti

    cmp dword[Hexagon.Processes.Table.esp + ebx * 4], 0
    jne .resumeSlot

    jmp Hexagon.Kern.Sched.dispatchSlot ;; First ever dispatch of this slot

.resumeSlot:

    mov eax, dword[Hexagon.Processes.Table.base + ebx * 4]

    call Hexagon.Kern.Sched.setUserSegmentBase

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
