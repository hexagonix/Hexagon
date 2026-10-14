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

Hexagon.Kern.Services:

.gpFaultInterrupt   = 0Dh ;; General Protection Fault handler
.pageFaultInterrupt = 0Eh ;; Page Fault handler
.hexagonInterrupt   = 80h ;; Hexagon services
.timerInterrupt     = 08h ;; Interrupt reserved for timer
.keyboardInterrupt  = 09h ;; Interrupt reserved for keyboard
.mouseInterrupt     = 74h ;; Interrupt reserved for pointing device

;;************************************************************************************

;; Installs Hexagon interrupt service routines (ISR) and hardware interruptions

Hexagon.Kern.Services.installInterruptions:

;; Install IRQ handlers

    mov dword[kernelExecute], kernelExecutePermission

;; Install real #GP/#PF handlers

    mov esi, Hexagon.Kern.Services.generalProtectionFaultHandler
    mov eax, Hexagon.Kern.Services.gpFaultInterrupt

    call Hexagon.Kern.Services.installISR

    mov esi, Hexagon.Kern.Services.pageFaultHandler
    mov eax, Hexagon.Kern.Services.pageFaultInterrupt

    call Hexagon.Kern.Services.installISR

;; Every gate is laid out for ring 0 alone. The system call is the one a
;; process itself has to be able to raise, so its own gate is opened to
;; user level. The rest stay shut, and an application raising one takes a
;; #GP instead of entering the kernel

    mov word[IDT + Hexagon.Kern.Services.hexagonInterrupt * 8 + 4], 0EE00h

    mov esi, Hexagon.Kern.Services.timerHandler ;; IRQ 0
    mov eax, Hexagon.Kern.Services.timerInterrupt ;; Interrupt number

    call Hexagon.Kern.Services.installISR

    mov esi, Hexagon.Kern.Services.keyboardHandler ;; IRQ 1
    mov eax, Hexagon.Kern.Services.keyboardInterrupt ;; Interrupt number

    call Hexagon.Kern.Services.installISR

    mov esi, Hexagon.Kern.Services.PS2MouseHandler ;; IRQ 12
    mov eax, Hexagon.Kern.Services.mouseInterrupt ;; Interrupt number

    call Hexagon.Kern.Services.installISR

;; Install the Hexagon services handler

    mov esi, Hexagon.Kern.Syscall.hexagonHandler ;; Hexagon services
    mov eax, Hexagon.Kern.Services.hexagonInterrupt ;; Interrupt number

    call Hexagon.Kern.Services.installISR

    sti ;; Enable interrupts

    mov dword[kernelExecute], kernelExecuteDisabled

    ret ;; All done

;;************************************************************************************

;; IRQ 0 - Timer Handler

;; With each interruption of the timer, the counter will be increased.
;; This counter can be used to time input and output operations, as well as
;; cause delays in various system and user processes

Hexagon.Kern.Services.timerHandler:

    push eax

;; ES goes with DS, for a reason DS alone does not cover: this handler can
;; return through another process's frame, and the iret back to user level
;; nulls any data segment that process cannot reach, leaving it to take a #GP
;; on its next write through ES

    push ds
    push es

    mov ax, 10h ;; Kernel data segment
    mov ds, ax

    mov ax, 18h ;; Kernel linear segment
    mov es, ax

;; Update real-time clock every interval

    call Hexagon.Arch.CMOS.CMOS.updateCMOSData

    inc dword[.timerCounter] ;; Increment the counter
    inc dword[.relativeCounter]

    mov al, 20h

    out 20h, al ;; Sent unconditionally and up front. Hexagon.Kern.Sched.maybeSchedule
                ;; below may switch to a different context and not return here
                ;; for a while, and IRQ0 needs to be re-armed regardless

    inc dword[Hexagon.Scheduler.ticks]

    cmp dword[Hexagon.Scheduler.ticks], Hexagon.Scheduler.sliceLength
    jb .noSchedule

    mov dword[Hexagon.Scheduler.ticks], 0

    call Hexagon.Kern.Sched.maybeSchedule

.noSchedule:

    pop es
    pop ds

    pop eax

    iret

.timerCounter:    dd 0 ;; This content is used
.relativeCounter: dd 0

;;************************************************************************************

;; Interrupt handlers

;; IRQ 1 - Keyboard interrupt

Hexagon.Kern.Services.keyboardHandler:

    push eax
    push ebx

;; ES goes with DS, same reasoning as the timer handler above

    push ds
    push es

    mov ax, 10h ;; Kernel data segment
    mov ds, ax

    mov ax, 18h ;; Kernel linear segment
    mov es, ax

    xor eax,eax

    in al, 60h

;; "Kill process" hotkey is Ctrl+C, like a real terminal's SIGINT, not a bare
;; key. A single mis-pressed key cannot close the foreground process by
;; accident, and F1 itself stays free of any overlap with Ctrl+F1..F8

    cmp al, Hexagon.Keyboard.keyCodes.c
    jne .notKillCombo

    test dword[keyStatus], 0x00000001 ;; Ctrl currently held?
    jnz .killCurrentProcess

.notKillCombo:

;; Ctrl+F1..F8: switch VT (F1->0 ... F8->7). No special-casing needed
;; against Ctrl+C above, since they are entirely different keys

    cmp al, Hexagon.Keyboard.keyCodes.F1
    jb .notSwitchVT

    cmp al, Hexagon.Keyboard.keyCodes.F8
    ja .notSwitchVT

    test dword[keyStatus], 0x00000001 ;; Ctrl currently held?
    jnz .switchVTRequested

.notSwitchVT:

;; Check if the Control key was pressed

    cmp al, Hexagon.Keyboard.keyCodes.ctrl
    je .controlKeyPressed

    cmp al, 29 + 128
    je .controlKeyReleased

;; Check if the Shift key was pressed

    cmp al, Hexagon.Keyboard.keyCodes.shiftR ;; Right shift key
    je .shiftKeyPressed

    cmp al, Hexagon.Keyboard.keyCodes.shiftL ;; Left shift key
    je .shiftKeyPressed

    cmp al, 54 + 128 ;; Right shift key released
    je .shiftKeyReleased

    cmp al, 42 + 128 ;; Left shift key released
    je .shiftKeyReleased

    jmp .anotherKey

.controlKeyPressed:

    or dword[keyStatus], 0x00000001

    jmp .doNotStore

.controlKeyReleased:

    and dword[keyStatus], 0xFFFFFFFE

    jmp .doNotStore

.shiftKeyPressed:

    or dword[keyStatus], 0x00000002

    mov byte[.shiftKeyStatus], 1 ;; Shift pressed

    jmp .doNotStore

.shiftKeyReleased:

    and dword[keyStatus], 0xFFFFFFFD

    mov byte[.shiftKeyStatus], 0

    jmp .doNotStore

.anotherKey:

    jmp .end

;;************************************************************************************

.killCurrentProcess:

    call Hexagon.Kern.Proc.killForegroundProcess

;; killForegroundProcess can now return normally (a third-party kill, unlike
;; the old self-kill-only behavior, which never returned here at all since
;; it jumped straight into Hexagon.Kern.Proc.exit's stack swap). Either way,
;; F1's own scancode must never be stored as an ordinary keystroke

    jmp .doNotStore

;;************************************************************************************

.switchVTRequested:

    mov ebx, eax
    sub ebx, Hexagon.Keyboard.keyCodes.F1 ;; EBX = target VT index (0-7)

;; Neither the outgoing (currently active) nor the incoming (target) VT
;; may need Console.switchVT's own lazy allocation here, since Mm.malloc
;; must never run from inside this ISR. A VT nobody has ever switched
;; to/from yet (including VT0 itself, which isn't pre-allocated at boot)
;; is silently left alone, which avoids the risk

    cmp dword[Hexagon.Console.VT.buffer + ebx * 4], 0
    je .doNotStore

    mov eax, dword[Hexagon.Console.activeVT]

    cmp dword[Hexagon.Console.VT.buffer + eax * 4], 0
    je .doNotStore

;; No EOI before the call. switchVT returns normally, so re-arming IRQ1 here
;; would let a fast enough repeat keypress reenter this handler and run switchVT
;; a second time mid-blit. The EOI at .doNotStore, past that call, is the only
;; one this path needs

    call Hexagon.Kernel.Dev.Console.Console.switchVT

    jmp .doNotStore

;;************************************************************************************

.end:

;; The index is zero extended into a whole register, and not added to
;; the low byte of an address, which would silently wrap inside that byte and
;; store 256 bytes short of the array the moment either one moves far enough
;; up in the image

    movzx ebx, byte[.scanCodes.index]

    mov byte[ebx + .scanCodes], al

;; Tag this byte with whichever VT was actually on screen the instant it
;; was typed. The consumer trusts this tag over its own idea of "current"
;; activeVT, since those can disagree by the time this byte is read.
;; See Hexagon.Kernel.Dev.Keyboard.Keyboard.waitKeyboard

    push edx

    mov edx, dword[Hexagon.Console.activeVT]

    mov byte[ebx + .scanCodesVT], dl

    pop edx

    cmp byte[.scanCodes.index], 31
    jl .incrementIndex

    mov byte[.scanCodes.index], -1

.incrementIndex:

    inc byte[.scanCodes.index]

.doNotStore:

    mov al, 20h

    out 20h, al

    pop es
    pop ds

    pop ebx
    pop eax

    iret

.scanCodes:
times 32 db 0
.scanCodesVT:
times 32 db 0
.scanCodes.index: db 0
.shiftKeyStatus: db 0

;;************************************************************************************

;; Bit 0: Control key
;; Bit 1: Shift key
;; Bit 2-31: Reserved

keyStatus: dd 0

;;************************************************************************************

;; IRQ 12 - PS/2 Mouse Handler

Hexagon.Kern.Services.PS2MouseHandler:

    pusha

    push ds
    push es

;; Whatever this arrived on top of may perfectly well have been running at
;; user level, with its own segments loaded. Every variable below is the
;; kernel's own, and ES has to come back the way it was found for the same
;; reason the timer handler above spells out

    mov ax, 10h
    mov ds, ax

    mov ax, 18h
    mov es, ax

    cmp byte[.status], 0
    je .dataPackage

    cmp byte[.status], 1
    je .packageX

    cmp byte[.status], 2
    je .packageY

.dataPackage:

    in al, 60h

    mov byte[.data], al

    mov byte[.status], 1

    jmp .finish

.packageX:

    in al, 60h

    mov byte[.deltaX], al

    mov byte[.status], 2

    jmp .finish

.packageY:

    in al, 60h

    mov byte[.deltaY], al

    mov byte[.status], 0

    mov byte[.changed], 1

.end:

    movzx eax, byte[Hexagon.Kern.Services.PS2MouseHandler.deltaX] ;; DeltaX changed to X
    movzx ebx, byte[Hexagon.Kern.Services.PS2MouseHandler.deltaY] ;; DeltaY changed to Y
    mov dl, byte[Hexagon.Kern.Services.PS2MouseHandler.data]

    bt dx, 4 ;; Check if the mouse has moved to the left
    jnc .movementToTheRight

    xor eax, 0xFF ;; 255 - deltaX
    sub word[.mouseX], ax ;; MouseX - DeltaX

    jnc .xOK ;; Check if MouseX is less than 0
    mov word[.mouseX], 0 ;; Fix MouseX

    jmp .xOK

.movementToTheRight:

    add word[.mouseX], ax ;; MouseX + DeltaX

.xOK:

    bt dx, 5 ;; Check if the mouse has moved down
    jnc .upMovement

    xor ebx, 0xFF ;; 255 - DeltaY
    sub word[.mouseY], bx ;; MouseY - DeltaY

    jnc .yOK ;; Check if MouseY is less than 0
    mov word[.mouseY], 0 ;; Fix MouseY

    jmp .yOK

.upMovement:

    add word[.mouseY], bx ;; MouseY + DeltaY

.yOK:

    movzx eax, word[.mouseX]
    movzx ebx, word[.mouseY]

;; Make sure that X and Y are not greater than the video resolution

    cmp ax, word[Hexagon.Console.Resolution.x]
    jng .xNotGreater

    mov ax, word[Hexagon.Console.Resolution.x]
    mov word[.mouseX], ax

.xNotGreater:

    cmp bx, word[Hexagon.Console.Resolution.y]
    jng .yNotGreater

    mov bx, word[Hexagon.Console.Resolution.y]
    mov word[.mouseY], bx

.yNotGreater:

    push edx

    movzx edx, word[Hexagon.Console.Resolution.y]
    sub dx, word[.mouseY]
    mov ebx, edx

    pop edx

    mov dword[Hexagon.Kernel.Dev.Mouse.mouseX], eax
    mov dword[Hexagon.Kernel.Dev.Mouse.mouseY], ebx

.finish:

    mov al, 20h ;; End of interruption handling

    out 20h, al
    out 0xA0, al

    pop es
    pop ds

    popa

    iret

.status:   db 0
.deltaX:   db 0
.deltaY:   db 0
.data:     db 0
.changed:  db 0

align 32

.mouseStatus: dd 0
.mouseX:      dd 0
.mouseY:      dd 0

;;************************************************************************************

;; Specialized handler for touchpads - IRQ 12

Hexagon.Kern.Services.touchpadHandler:

    push eax
    push edx

    cmp byte[.status], 0
    je .package0

    cmp byte[.status], 1
    je .package1

    cmp byte[.status], 2
    je .package2

    cmp byte[.status], 3
    je .package3

    cmp byte[.status], 4
    je .package4

    cmp byte[.status], 5
    je .package5

.package0:

    mov al, 0

    call Hexagon.Kernel.Dev.Console.Console.clearRow

    in al, 60h

    movzx eax, al
    mov dl, 0
    mov dh, 0

    call Hexagon.Kernel.Dev.Console.Console.printBinary

    mov byte[.status], 1

    jmp .end

.package1:

    mov al, 1

    call Hexagon.Kernel.Dev.Console.Console.clearRow

    in al, 60h

    mov bl, al

    and al, 1111b

    movzx eax, al

    shl eax, 8

    mov word[.X], ax

    mov al, bl

    and al, 11110000b

    movzx eax, al

    shl eax, 4

    mov word[.Y], ax

    mov al, bl
    movzx eax, al
    mov dl, 0
    mov dh, 1

    call Hexagon.Kernel.Dev.Console.Console.printBinary

    mov byte[.status], 2

    jmp .end

.package2:

    mov al, 2

    call Hexagon.Kernel.Dev.Console.Console.clearRow

    in al, 60h

    movzx eax, al
    mov dl, 0
    mov dh, 2

    call Hexagon.Kernel.Dev.Console.Console.printDecimal

    mov byte[.status], 3

    jmp .end

.package3:

    mov al, 3

    call Hexagon.Kernel.Dev.Console.Console.clearRow

    in al, 60h

    mov bl, al

    movzx eax, al

    and eax, 00010000b

    shl eax, 8

    or word[.X], ax

    mov al, bl

    movzx eax, al

    and eax, 00100000b

    shl eax, 7

    or word[.Y], ax

    mov al, bl

    movzx eax, al
    mov dl, 0
    mov dh, 3

    call Hexagon.Kernel.Dev.Console.Console.printBinary

    mov byte[.status], 4

    jmp .end

.package4:

    mov al, 4

    call Hexagon.Kernel.Dev.Console.Console.clearRow

    in al, 60h

    movzx ax, al

    or word[.X], ax

    movzx eax, word[.X]

;; sub EAX, 1000

    mov dl, 0
    mov dh, 4

    call Hexagon.Kernel.Dev.Console.Console.printDecimal

    mov byte[.status], 5

    jmp .end

.package5:

    mov al, 5

    call Hexagon.Kernel.Dev.Console.Console.clearRow

    in al, 60h

    movzx ax, al
    or word[.Y], ax

    movzx eax, word[.Y]

;; sub EAX, 1000

    mov dl, 0
    mov dh, 5

    call Hexagon.Kernel.Dev.Console.Console.printDecimal

    mov byte[.status], 0

    jmp .end

.end:

    mov al, 20h ;; End of interrupt handling

    out 20h, al

    out 20h, al

    pop edx
    pop eax

    iret

.status: db 0
.X:      dw 0
.Y:      dw 0
.Z:      db 0

;;************************************************************************************

;; Handler for other interrupts, when they are not available. Every IDT
;; vector defaults to this handler, including IRQ8-15, so an unacknowledged
;; slave-PIC line needs its own EOI here too, besides the master's

Hexagon.Kern.Services.nullHandler:

    push eax

    mov al, 20h

    out 0A0h, al ;; Secondary PIC
    out 20h, al  ;; Primary PIC

    pop eax

    iret

;;************************************************************************************

;; Real handlers for #GP (13) and #PF (14). Unlike nullHandler, these
;; report the error code the CPU already put on the stack (plus CR2 for
;; #PF) and the faulting EIP, then panic, instead of silently iret-ing
;; back into whatever caused the fault

Hexagon.Kern.Services.generalProtectionFaultHandler:

    mov ax, 10h ;; Kernel data segment, regardless of what it was at fault time
    mov ds, ax

    mov ax, 18h ;; Kernel linear segment, likewise
    mov es, ax

    mov dword[Hexagon.Kern.Services.faultESP], esp ;; Before anything here touches the stack

    mov edi, Hexagon.Kern.Services.faultReport.address

    xor eax, eax ;; No faulting address here, unlike a page fault

    call Hexagon.Kern.Services.faultDigits

    mov edi, Hexagon.Kern.Services.faultReport.errorCode

    mov eax, dword[esp] ;; Error code (the CPU pushed this before entry)

    call Hexagon.Kern.Services.faultDigits

    mov edi, Hexagon.Kern.Services.faultReport.eip

    mov eax, dword[esp + 4] ;; Faulting EIP

    call Hexagon.Kern.Services.faultDigits

    mov edi, Hexagon.Kern.Services.faultReport.cs

    mov eax, dword[esp + 8]

    call Hexagon.Kern.Services.faultDigits

    call Hexagon.Kern.Services.faultContext

    mov esi, Hexagon.Kern.Services.faultReport
    mov ebx, Hexagon.Dmesg.Priorities.p4

    call Hexagon.Kern.Dmesg.createMessage

;; A fault raised against code at user level is that process's own problem, so
;; it is reported and terminated, while only a fault the kernel took leaves
;; nothing to carry on with. Hexagon.Kern.Proc.exit swaps to whoever was waiting
;; and never comes back, abandoning the frame this handler stands on

    test byte[esp + 8], 3 ;; The privilege level the saved CS carries

    jz .kernelFault

    mov esi, Hexagon.Verbose.Services.terminatedGeneralProtectionFault
    mov ebx, Hexagon.Dmesg.Priorities.p5

    call Hexagon.Kern.Dmesg.createMessage

    mov eax, Hexagon.Kern.Proc.faultExitCode

    jmp Hexagon.Kern.Proc.exit

.kernelFault:

    mov esi, Hexagon.Verbose.Services.generalProtectionFault

    call Hexagon.Kern.Panic.panic

Hexagon.Kern.Services.pageFaultHandler:

    mov ax, 10h
    mov ds, ax

    mov ax, 18h
    mov es, ax

    mov dword[Hexagon.Kern.Services.faultESP], esp ;; Before anything here touches the stack

    mov edi, Hexagon.Kern.Services.faultReport.address

    mov eax, cr2 ;; Faulting linear address

    call Hexagon.Kern.Services.faultDigits

    mov edi, Hexagon.Kern.Services.faultReport.errorCode

    mov eax, dword[esp] ;; Error code

    call Hexagon.Kern.Services.faultDigits

    mov edi, Hexagon.Kern.Services.faultReport.eip

    mov eax, dword[esp + 4] ;; Faulting EIP

    call Hexagon.Kern.Services.faultDigits

    mov edi, Hexagon.Kern.Services.faultReport.cs

    mov eax, dword[esp + 8]

    call Hexagon.Kern.Services.faultDigits

    call Hexagon.Kern.Services.faultContext

    mov esi, Hexagon.Kern.Services.faultReport
    mov ebx, Hexagon.Dmesg.Priorities.p4

    call Hexagon.Kern.Dmesg.createMessage

;; A fault raised against code at user level is that process's own problem, so
;; it is reported and terminated, while only a fault the kernel took leaves
;; nothing to carry on with. Hexagon.Kern.Proc.exit swaps to whoever was waiting
;; and never comes back, abandoning the frame this handler stands on

    test byte[esp + 8], 3 ;; The privilege level the saved CS carries

    jz .kernelFault

    mov esi, Hexagon.Verbose.Services.terminatedPageFault
    mov ebx, Hexagon.Dmesg.Priorities.p5

    call Hexagon.Kern.Dmesg.createMessage

    mov eax, Hexagon.Kern.Proc.faultExitCode

    jmp Hexagon.Kern.Proc.exit

.kernelFault:

    mov esi, Hexagon.Verbose.Services.pageFault

    call Hexagon.Kern.Panic.panic

;; The line both handlers above fill in and hand to the serial log. CS is in
;; it because it, alone, says whether the fault came from user level or from
;; the kernel itself, which is the first thing to know about either one

Hexagon.Kern.Services.faultReport:
db "cr2="
.address:   db "00000000"
db " code="
.errorCode: db "00000000"
db " eip="
.eip:       db "00000000"
db " cs="
.cs:        db "00000000"
db " esp="
.esp:       db "00000000"
db " slot="
.slot:      db "00000000"
db 0

Hexagon.Kern.Services.faultESP: dd 0

;; Where the fault landed and who was running. Between them they say whether a
;; kernel fault happened on the stack the running slot actually owns, which is
;; what matters first about a fault that reached a kernel frame

Hexagon.Kern.Services.faultContext:

    push eax
    push edi

    mov eax, dword[Hexagon.Kern.Services.faultESP]

    mov edi, Hexagon.Kern.Services.faultReport.esp

    call Hexagon.Kern.Services.faultDigits

    movzx eax, byte[Hexagon.Scheduler.current]

    mov edi, Hexagon.Kern.Services.faultReport.slot

    call Hexagon.Kern.Services.faultDigits

    pop edi
    pop eax

    ret

;; Writes EAX as eight hexadecimal digits over the eight bytes at EDI,
;; leaving EDI past them. The report goes out over the serial log rather
;; than through the console, since the console is perfectly capable of
;; being what faulted
;;
;; Input:
;;
;; EAX - Value to write
;; EDI - Where to write it

Hexagon.Kern.Services.faultDigits:

    push eax
    push ebx
    push ecx

    mov ebx, eax
    mov ecx, 8

.digit:

    rol ebx, 4

    mov al, bl
    and al, 0Fh

    add al, '0'

    cmp al, '9'

    jbe .store

    add al, 7 ;; A through F

.store:

    mov byte[edi], al

    inc edi

    dec ecx

    jnz .digit

    pop ecx
    pop ebx
    pop eax

    ret

;;************************************************************************************

;; Installs an interrupt handler or IRQ handler
;;
;; Input:
;;
;; EAX - Interrupt number
;; ESI - Interrupt routine

Hexagon.Kern.Services.installISR:

    push eax
    push ebp

;; First, let's check if the interrupt installation request came from Hexagon,
;; observing the variable that records these privileged requests

    cmp dword[kernelExecute], kernelExecutePermission ;; If yes, skip check and install
    je .install

;; If the request came from the user or application, check whether the values ​​passed could
;; overwrite the interrupts previously installed by Hexagon

    cmp eax, Hexagon.Kern.Services.hexagonInterrupt ;; Attempt to replace Hexagon call
    je .deny ;; Deny installation

    cmp eax, Hexagon.Kern.Services.timerInterrupt ;; Attempt to change timer interrupt
    je .deny ;; Deny installation

    cmp eax, Hexagon.Kern.Services.keyboardInterrupt ;; Attempting to change the keyboard interrupt
    je .deny ;; Deny installation

    cmp eax, Hexagon.Kern.Services.mouseInterrupt ;; Attempt to change mouse interrupt
    je .deny ;; Deny installation

.install:

    mov ebp, eax
    mov eax, esi

    mov word[IDT+ebp*8], ax
    shr eax, 16

    mov word[IDT+ebp*8+6], ax

    jmp .end

.deny:

    stc

    mov eax, 01h

.end:

    pop ebp
    pop eax

    ret
