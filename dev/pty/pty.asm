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
;; Hexagon pseudoterminals
;;
;; Pairs of devices, as pty(4) in BSD. What the manager writes is read on the
;; subsidiary through the line discipline of its tty unit, and what the
;; subsidiary writes, its echo included, is read on the manager
;;
;;************************************************************************************

use32

Hexagon.PTY.count = Hexagon.TTY.ptyCount

;; Device ids, ptyp0 to ptyp7 for the managers, then ttyp0 to ttyp7 for the
;; subsidiaries

Hexagon.PTY.firstManager    = 60h
Hexagon.PTY.firstSubsidiary = Hexagon.PTY.firstManager + Hexagon.PTY.count

Hexagon.PTY.nameSize = 6 ;; Of each name in Hexagon.Dev.Devices, from .ptyp0 on

;; Each pair has two rings in one block. Input is written by the manager and read
;; by the subsidiary, output the other way round

Hexagon.PTY.ringSize = 1024

Hexagon.PTY.Ring.input  = 0
Hexagon.PTY.Ring.output = 1

;; Sides, numbered as the ring each one writes

Hexagon.PTY.Side.manager    = 0
Hexagon.PTY.Side.subsidiary = 1

;; One pair. Each ring has its head and the bytes it holds, 8 bytes after the
;; other ring's

Hexagon.PTY.Pair.block            = 0 ;; Both rings, 0 while the pair is free
Hexagon.PTY.Pair.head             = 4
Hexagon.PTY.Pair.used             = 8
Hexagon.PTY.Pair.managers         = 20 ;; Descriptors holding each side
Hexagon.PTY.Pair.subsidiaries     = 24
Hexagon.PTY.Pair.subsidiaryOpened = 28 ;; No end for the manager before a subsidiary
Hexagon.PTY.Pair.columns          = 32 ;; Window size, a word each
Hexagon.PTY.Pair.rows             = 34
Hexagon.PTY.Pair.sizeShift        = 6 ;; A power of two, so unitOf divides by shifting
Hexagon.PTY.Pair.size             = 1 shl Hexagon.PTY.Pair.sizeShift

if Hexagon.PTY.Pair.rows + 2 > Hexagon.PTY.Pair.size
    err
end if

;; What a new session's window measures until its manager says otherwise

Hexagon.PTY.defaultColumns = 80
Hexagon.PTY.defaultRows    = 25

Hexagon.PTY.pairs:
times Hexagon.PTY.count * Hexagon.PTY.Pair.size db 0

;;************************************************************************************

;; Lists both sides of every pair under /dev. Called by
;; Hexagon.Kernel.Dev.Dev.registerDevices

Hexagon.Kernel.Dev.PTY.registerDevices:

    mov esi, Hexagon.Dev.Devices.ptyp0
    mov ecx, Hexagon.PTY.count * 2

.register:

    push ecx
    push esi

    mov al, 06h ;; Hexagon.Dev.DeviceClasses.pty
    mov bl, 0
    mov cl, 0

    call Hexagon.Kernel.Dev.Dev.registerDevice

    pop esi
    pop ecx

    add esi, Hexagon.PTY.nameSize

    loop .register

    ret

;;************************************************************************************

;; Input:
;;
;; ESI - Name
;;
;; Output:
;;
;; BX - Device id, CF set if the name is a side of a pty

Hexagon.Kernel.Dev.PTY.deviceOfName:

    push ecx
    push edi

    mov edi, Hexagon.Dev.Devices.ptyp0

    xor ecx, ecx

.check:

    call Hexagon.Libkern.String.compareWordsInString

    jc .found

    add edi, Hexagon.PTY.nameSize

    inc ecx

    cmp ecx, Hexagon.PTY.count * 2

    jb .check

    pop edi
    pop ecx

    clc

    ret

.found:

    lea ebx, [ecx + Hexagon.PTY.firstManager]

    pop edi
    pop ecx

    stc

    ret

;; Input:
;;
;; AX - Device id
;;
;; Output:
;;
;; ESI - Its name, CF set if it is not a side of a pty

Hexagon.Kernel.Dev.PTY.nameOfDevice:

    movzx esi, ax

    sub esi, Hexagon.PTY.firstManager

    cmp esi, Hexagon.PTY.count * 2

    jae .none

    imul esi, esi, Hexagon.PTY.nameSize

    add esi, Hexagon.Dev.Devices.ptyp0

    clc

    ret

.none:

    stc

    ret

;;************************************************************************************

;; Input:
;;
;; AX - Device id
;;
;; Output:
;;
;; EBX - Its pair
;; EDX - Its side

Hexagon.Kernel.Dev.PTY.pairOf:

    movzx ebx, ax

    sub ebx, Hexagon.PTY.firstManager

    mov edx, Hexagon.PTY.Side.manager

    cmp ebx, Hexagon.PTY.count

    jb .manager

    sub ebx, Hexagon.PTY.count

    mov edx, Hexagon.PTY.Side.subsidiary

.manager:

    imul ebx, ebx, Hexagon.PTY.Pair.size

    add ebx, Hexagon.PTY.pairs

    ret

;; Input: EBX - Pair. Output: EDX - Its subsidiary's tty unit

Hexagon.Kernel.Dev.PTY.unitOf:

    mov edx, ebx

    sub edx, Hexagon.PTY.pairs

    shr edx, Hexagon.PTY.Pair.sizeShift

    add edx, Hexagon.TTY.firstPty

    ret

;; Input: EDX - Tty unit of a subsidiary. Output: EBX - Its pair

Hexagon.Kernel.Dev.PTY.pairOfUnit:

    lea ebx, [edx - Hexagon.TTY.firstPty]

    imul ebx, ebx, Hexagon.PTY.Pair.size

    add ebx, Hexagon.PTY.pairs

    ret

;;************************************************************************************

;; A manager starts a session on a free pair and allocates its rings. A subsidiary
;; joins the session of an open manager
;;
;; Input:
;;
;; BX - Device id
;;
;; Output:
;;
;; EAX - Error code, with CF set

Hexagon.Kernel.Dev.PTY.open:

    push ebx
    push edx

    mov eax, ebx

    call Hexagon.Kernel.Dev.PTY.pairOf

    call Hexagon.Kern.Sched.disablePreemption

    cmp edx, Hexagon.PTY.Side.subsidiary

    je .subsidiary

;; One manager at a time, and only once the subsidiaries of the last session are gone

    cmp dword[ebx + Hexagon.PTY.Pair.managers], 0

    jne .refused

    cmp dword[ebx + Hexagon.PTY.Pair.subsidiaries], 0

    jne .refused

    push ebx

    mov ebx, Hexagon.PTY.ringSize * 2

    call Hexagon.Arch.Mm.malloc ;; EBX = block, or EAX = 0

    mov edx, ebx

    pop ebx

    cmp eax, 0

    je .refused

    mov dword[ebx + Hexagon.PTY.Pair.block], edx

    xor eax, eax

    mov dword[ebx + Hexagon.PTY.Pair.head], eax
    mov dword[ebx + Hexagon.PTY.Pair.used], eax
    mov dword[ebx + Hexagon.PTY.Pair.head + 8], eax
    mov dword[ebx + Hexagon.PTY.Pair.used + 8], eax
    mov dword[ebx + Hexagon.PTY.Pair.subsidiaryOpened], eax

    mov word[ebx + Hexagon.PTY.Pair.columns], Hexagon.PTY.defaultColumns
    mov word[ebx + Hexagon.PTY.Pair.rows], Hexagon.PTY.defaultRows

    mov dword[ebx + Hexagon.PTY.Pair.managers], 1

    call Hexagon.Kernel.Dev.PTY.unitOf

    call Hexagon.Kernel.Dev.TTY.resetUnit

    jmp .opened

.subsidiary:

    cmp dword[ebx + Hexagon.PTY.Pair.managers], 0

    je .refused

    inc dword[ebx + Hexagon.PTY.Pair.subsidiaries]

    mov dword[ebx + Hexagon.PTY.Pair.subsidiaryOpened], 1

.opened:

    call Hexagon.Kern.Sched.enablePreemption

    pop edx
    pop ebx

    clc

    ret

.refused:

    call Hexagon.Kern.Sched.enablePreemption

    pop edx
    pop ebx

    mov eax, 05h ;; IO.operationDenied

    stc

    ret

;;************************************************************************************

;; The rings are freed once no descriptor holds either side
;;
;; Input:
;;
;; AX - Device id

Hexagon.Kernel.Dev.PTY.close:

    push ebx
    push edx

    call Hexagon.Kernel.Dev.PTY.pairOf

    call Hexagon.Kern.Sched.disablePreemption

    cmp edx, Hexagon.PTY.Side.subsidiary

    je .subsidiary

    dec dword[ebx + Hexagon.PTY.Pair.managers]

    jmp .closed

.subsidiary:

    dec dword[ebx + Hexagon.PTY.Pair.subsidiaries]

.closed:

    cmp dword[ebx + Hexagon.PTY.Pair.managers], 0

    jne .done

    cmp dword[ebx + Hexagon.PTY.Pair.subsidiaries], 0

    jne .done

    cmp dword[ebx + Hexagon.PTY.Pair.block], 0

    je .done

    push ebx

    mov ebx, dword[ebx + Hexagon.PTY.Pair.block]

    call Hexagon.Arch.Mm.free

    pop ebx

    mov dword[ebx + Hexagon.PTY.Pair.block], 0

.done:

    call Hexagon.Kern.Sched.enablePreemption

    pop edx
    pop ebx

    ret

;; Input: AX - Device id

Hexagon.Kernel.Dev.PTY.reference:

    push ebx
    push edx

    call Hexagon.Kernel.Dev.PTY.pairOf

    cmp edx, Hexagon.PTY.Side.subsidiary

    je .subsidiary

    inc dword[ebx + Hexagon.PTY.Pair.managers]

    jmp .done

.subsidiary:

    inc dword[ebx + Hexagon.PTY.Pair.subsidiaries]

.done:

    pop edx
    pop ebx

    ret

;;************************************************************************************

;; The manager reads what the subsidiary wrote, waiting for at least one byte. The
;; subsidiary reads through the line discipline of its unit
;;
;; Input:
;;
;; AX  - Device id
;; EDI - Buffer
;; ECX - Maximum bytes, at least 1
;;
;; Output:
;;
;; EAX - Bytes read, 0 at the end of the file

Hexagon.Kernel.Dev.PTY.read:

    push ebx
    push edx

    call Hexagon.Kernel.Dev.PTY.pairOf

    cmp edx, Hexagon.PTY.Side.subsidiary

    je .subsidiary

    push esi

    xor esi, esi ;; Bytes read

    mov edx, Hexagon.PTY.Ring.output

    call Hexagon.Kernel.Dev.PTY.getByte

    jc .copied ;; The subsidiary is gone and left nothing

.copyByte:

    mov byte[edi + esi], al

    inc esi

    cmp esi, ecx

    jae .copied

    call Hexagon.Kernel.Dev.PTY.ringGet

    jnc .copyByte

.copied:

    mov eax, esi

    pop esi
    pop edx
    pop ebx

    clc

    ret

.subsidiary:

    call Hexagon.Kernel.Dev.PTY.unitOf

    call Hexagon.Kernel.Dev.TTY.read

    pop edx
    pop ebx

    ret

;;************************************************************************************

;; The manager writes into the subsidiary's input and the subsidiary into the
;; manager's output, waiting while the ring is full. Once the side reading it is
;; gone, what is left is thrown away. A descriptor that may not wait writes what
;; fits
;;
;; Input:
;;
;; AX  - Device id
;; ESI - Bytes
;; ECX - How many
;;
;; Output:
;;
;; EAX - Bytes written

Hexagon.Kernel.Dev.PTY.write:

    push ebx
    push edx
    push ebp

    call Hexagon.Kernel.Dev.PTY.pairOf ;; EDX = side, the same number as the ring it writes

    mov ebp, 1 ;; May give up when the ring is full

    call Hexagon.Kernel.Dev.PTY.putBytes

    cmp eax, 0

    je .done

    call Hexagon.Kern.FD.didTransfer

.done:

    pop ebp
    pop edx
    pop ebx

    clc

    ret

;;************************************************************************************

;; The subsidiary's side of its tty unit, for the line discipline
;;
;; subsidiaryGet: EDX - Unit. Output: AL - Next byte, CF set once the manager is gone
;; subsidiaryPut: EDX - Unit, ESI - Bytes, ECX - How many

Hexagon.Kernel.Dev.PTY.subsidiaryGet:

    push ebx
    push edx

    call Hexagon.Kernel.Dev.PTY.pairOfUnit

    mov edx, Hexagon.PTY.Ring.input

    call Hexagon.Kernel.Dev.PTY.getByte

    pop edx
    pop ebx

    ret

Hexagon.Kernel.Dev.PTY.subsidiaryPut:

    push ebx
    push edx

    push eax
    push ebp

    call Hexagon.Kernel.Dev.PTY.pairOfUnit

    mov edx, Hexagon.PTY.Ring.output

    xor ebp, ebp ;; The echo always waits for room

    call Hexagon.Kernel.Dev.PTY.putBytes

    pop ebp
    pop eax
    pop edx
    pop ebx

    ret

;;************************************************************************************

;; Commands 4 and 5 get and set the mode of the subsidiary's unit, on either side,
;; as in Hexagon.Kernel.Dev.Dev.Switch.Output.ioctl. Commands 6 and 7 get and set
;; the size of the window, which the manager sets for the program it runs
;;
;; Input:
;;
;; AX  - Device id
;; EBX - Command
;; ECX - Mode, for command 5. Columns, for command 7
;; EDX - Rows, for command 7
;;
;; Output:
;;
;; EAX - Mode, for command 4. Columns, for command 6
;; EBX - Rows, for command 6

Hexagon.Kernel.Dev.PTY.ioctl:

    push ebx
    push edx

    cmp ebx, 4

    je .getMode

    cmp ebx, 5

    je .setMode

    cmp ebx, 6

    je .getSize

    cmp ebx, 7

    je .setSize

    pop edx
    pop ebx

    stc

    ret

.getMode:

    call Hexagon.Kernel.Dev.PTY.pairOf
    call Hexagon.Kernel.Dev.PTY.unitOf

    movzx eax, byte[Hexagon.TTY.mode + edx]

    jmp .done

.setMode:

    call Hexagon.Kernel.Dev.PTY.pairOf
    call Hexagon.Kernel.Dev.PTY.unitOf

    mov eax, ecx

    and al, Hexagon.TTY.Modes.all

    mov byte[Hexagon.TTY.mode + edx], al

    jmp .done

.getSize:

    call Hexagon.Kernel.Dev.PTY.pairOf

    movzx eax, word[ebx + Hexagon.PTY.Pair.columns]
    movzx ebx, word[ebx + Hexagon.PTY.Pair.rows]

    pop edx

    add esp, 4 ;; EBX carries the rows back

    clc

    ret

.setSize:

    call Hexagon.Kernel.Dev.PTY.pairOf

    mov word[ebx + Hexagon.PTY.Pair.columns], cx

    mov edx, dword[esp] ;; The rows

    mov word[ebx + Hexagon.PTY.Pair.rows], dx

.done:

    pop edx
    pop ebx

    clc

    ret

;;************************************************************************************

;; Takes a byte from a ring, waiting while it is empty
;;
;; Input:
;;
;; EBX - Pair
;; EDX - Ring
;;
;; Output:
;;
;; AL - Byte, CF set once the ring is empty and the side writing it is gone

Hexagon.Kernel.Dev.PTY.getByte:

    call Hexagon.Kern.Sched.disablePreemption

    call Hexagon.Kernel.Dev.PTY.ringGet

    jnc .got

    call Hexagon.Kernel.Dev.PTY.sideGone ;; A ring has the number of the side writing it

    jc .gone

    call Hexagon.Kern.FD.mayWait

    jc .gone ;; Returns as if gone, recorded as having had to wait

    call Hexagon.Kern.Sched.enablePreemption

    call Hexagon.Kernel.Dev.PTY.wait

    jmp Hexagon.Kernel.Dev.PTY.getByte

.got:

    call Hexagon.Kern.Sched.enablePreemption

    clc

    ret

.gone:

    call Hexagon.Kern.Sched.enablePreemption

    stc

    ret

;; Puts bytes into a ring, waiting while it is full. Stops once the side reading
;; it is gone, counting what is left as written, since it is thrown away
;;
;; Input:
;;
;; EBX - Pair
;; EDX - Ring
;; ESI - Bytes
;; ECX - How many
;; EBP - 1 to stop when the ring is full and the call may not wait, 0 to wait
;;
;; Output:
;;
;; EAX - Bytes written

Hexagon.Kernel.Dev.PTY.putBytes:

    push ecx
    push esi

    jecxz .done

.nextByte:

    mov al, byte[esi]

    cmp edx, Hexagon.PTY.Ring.input

    jne .check

    cmp al, 03h ;; Ctrl+C

    jne .check

    call Hexagon.Kernel.Dev.PTY.interrupt

    jnc .next

.check:

    call Hexagon.Kern.Sched.disablePreemption

    push edx

    xor edx, 1 ;; The other side

    call Hexagon.Kernel.Dev.PTY.sideGone

    pop edx

    jc .gone

    call Hexagon.Kernel.Dev.PTY.ringPut

    jnc .put

    call Hexagon.Kern.Sched.enablePreemption

    cmp ebp, 0

    je .wait

    call Hexagon.Kern.FD.mayWait

    jc .done ;; Full, and ECX holds what did not fit

.wait:

    call Hexagon.Kernel.Dev.PTY.wait

    jmp .check

.put:

    call Hexagon.Kern.Sched.enablePreemption

.next:

    inc esi

    loop .nextByte

    jmp .done

.gone:

    call Hexagon.Kern.Sched.enablePreemption

    xor ecx, ecx

.done:

    pop esi

    mov eax, dword[esp] ;; How many were asked for
    sub eax, ecx

    pop ecx

    ret

;; Ctrl+C from the manager, when the subsidiary's unit has ISIG. Ends the
;; processes that have the subsidiary as their descriptor 0, as SIGINT to the
;; foreground group would, and spares those waiting on a child, as a shell
;; outlives the command it ran. Input not read yet is dropped with it
;;
;; Input: EBX - Pair
;;
;; Output: CF set if the unit has no ISIG, and 03h is an ordinary byte

Hexagon.Kernel.Dev.PTY.interrupt:

    pushad

    call Hexagon.Kernel.Dev.PTY.unitOf

    test byte[Hexagon.TTY.mode + edx], Hexagon.TTY.Modes.isig

    jz .noSignal

    call Hexagon.Kern.Sched.disablePreemption

    mov dword[ebx + Hexagon.PTY.Pair.used], 0 ;; Of the input ring

    call Hexagon.Kernel.Dev.TTY.discardLine

    call Hexagon.Kern.Sched.enablePreemption

;; The descriptor entry of the subsidiary, as kern/fd.asm lays it out

    lea eax, [edx - Hexagon.TTY.firstPty + Hexagon.PTY.firstSubsidiary + (06h shl 16)]

    xor ecx, ecx

.checkSlot:

    cmp ecx, Hexagon.Processes.Table.limit

    jae .done

    cmp cl, byte[Hexagon.Scheduler.current]

    je .nextSlot

    cmp byte[Hexagon.Processes.Table.state + ecx], Hexagon.Processes.Table.States.ready

    je .checkInput

    cmp byte[Hexagon.Processes.Table.state + ecx], Hexagon.Processes.Table.States.sleeping

    jne .nextSlot ;; Free, or blocked on a child

.checkInput:

    imul edi, ecx, Hexagon.Kern.FD.limit * 4

    mov edx, dword[Hexagon.Processes.Table.fd + edi]

    and edx, not Hexagon.Kern.FD.Flags.all

    cmp edx, eax

    jne .nextSlot

    push eax
    push ecx

    call Hexagon.Kern.Proc.killSlot

    pop ecx
    pop eax

.nextSlot:

    inc ecx

    jmp .checkSlot

.done:

    popad

    clc

    ret

.noSignal:

    popad

    stc

    ret

;; Gives the processor away for a tick

Hexagon.Kernel.Dev.PTY.wait:

    push ecx

    mov ecx, 1

    call Hexagon.Kern.Sched.sleep

    pop ecx

    ret

;; Input: EBX - Pair, EDX - Side. Output: CF set if no descriptor holds it any more

Hexagon.Kernel.Dev.PTY.sideGone:

    cmp edx, Hexagon.PTY.Side.subsidiary

    je .subsidiary

    cmp dword[ebx + Hexagon.PTY.Pair.managers], 0

    je .gone

    clc

    ret

.subsidiary:

    cmp dword[ebx + Hexagon.PTY.Pair.subsidiaryOpened], 0

    je .present

    cmp dword[ebx + Hexagon.PTY.Pair.subsidiaries], 0

    je .gone

.present:

    clc

    ret

.gone:

    stc

    ret

;;************************************************************************************

;; ringGet: EBX - Pair, EDX - Ring. Output: AL - Oldest byte, CF set if empty
;; ringPut: EBX - Pair, EDX - Ring, AL - Byte. Output: CF set if full

Hexagon.Kernel.Dev.PTY.ringGet:

    push esi
    push edi

    call Hexagon.Kern.Sched.disablePreemption

    lea edi, [ebx + edx * 8] ;; This ring's head and count

    cmp dword[edi + Hexagon.PTY.Pair.used], 0

    je .empty

    imul esi, edx, Hexagon.PTY.ringSize

    add esi, dword[ebx + Hexagon.PTY.Pair.block]
    add esi, dword[edi + Hexagon.PTY.Pair.head]

    mov al, byte[esi]

    mov esi, dword[edi + Hexagon.PTY.Pair.head]

    inc esi

    and esi, Hexagon.PTY.ringSize - 1

    mov dword[edi + Hexagon.PTY.Pair.head], esi

    dec dword[edi + Hexagon.PTY.Pair.used]

    call Hexagon.Kern.Sched.enablePreemption

    pop edi
    pop esi

    clc

    ret

.empty:

    call Hexagon.Kern.Sched.enablePreemption

    pop edi
    pop esi

    stc

    ret

Hexagon.Kernel.Dev.PTY.ringPut:

    push esi
    push edi

    call Hexagon.Kern.Sched.disablePreemption

    lea edi, [ebx + edx * 8]

    mov esi, dword[edi + Hexagon.PTY.Pair.used]

    cmp esi, Hexagon.PTY.ringSize

    jae .full

    add esi, dword[edi + Hexagon.PTY.Pair.head]

    and esi, Hexagon.PTY.ringSize - 1

    push edx

    imul edx, edx, Hexagon.PTY.ringSize

    add esi, edx

    pop edx

    add esi, dword[ebx + Hexagon.PTY.Pair.block]

    mov byte[esi], al

    inc dword[edi + Hexagon.PTY.Pair.used]

    call Hexagon.Kern.Sched.enablePreemption

    pop edi
    pop esi

    clc

    ret

.full:

    call Hexagon.Kern.Sched.enablePreemption

    pop edi
    pop esi

    stc

    ret
