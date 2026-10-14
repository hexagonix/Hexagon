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

;;************************************************************************************

Hexagon.Dmesg:

.bootDate:
db "System initialization: ", 0
.dateSource:
db " [CMOS]", 0
.hexagonIdentifier:
db "[Hexagon] ", 0
.userIdentifierOpen:
db "[PID: ", 0
.userIdentifierClose:
db "] ", 0
.newLine: db 10, 0

Hexagon.Dmesg.Priorities:

;; Kernel priority list:
;;
;; 0 - Stop the execution of the current process and display a message (to be implemented).
;; 1 - Do not interrupt processing and only display the message, interrupting the execution
;;     of any process (to be implemented).
;; 2 - Display the message only if a utility makes a request call (to be implemented).
;; 3 - Message relevant only to the kernel (to be implemented).
;; 4 - Send the message only via serial, for debugging purposes (verbose).
;; 5 - Send the message via default output and serially.

.p0 = 0
.p1 = 1
.p2 = 2
.p3 = 3
.p4 = 4
.p5 = 5

;; Kernel-only log history, matching BSD's msgbuf: every message Hexagon
;; itself logs, regardless of priority, also lands here for hx.sysctl to
;; read back. Messages logged by userland through this same createMessage
;; are never appended, see createMessage's own branches below

Hexagon.Kern.Dmesg.Buffer.size = 2000h ;; 8192 bytes

;; Mm.malloc'd on the first message logged, and not reserved in the
;; kernel image, so the binary does not carry these 8192 bytes unused on
;; systems that never log anything

Hexagon.Kern.Dmesg.Buffer.pointer:      dd 0
Hexagon.Kern.Dmesg.Buffer.writeIndex:   dd 0
Hexagon.Kern.Dmesg.Buffer.totalWritten: dd 0

;;************************************************************************************

Hexagon.Kern.Dmesg.startLog:

    mov esi, Hexagon.Info.aboutHexagon

    call Hexagon.Kernel.Dev.Console.Console.printString

    call Hexagon.Kern.Dmesg.dateToLog

    call Hexagon.Kern.Dmesg.hourToLog

    ret

;;************************************************************************************

Hexagon.Kern.Dmesg.dateToLog:

    push eax
    push ebx
    push esi

    mov esi, Hexagon.Dmesg.bootDate

    call Hexagon.Kernel.Dev.Console.Console.printString

    call Hexagon.Arch.CMOS.CMOS.getCMOSData

    mov al, [Hexagon.Arch.CMOS.day]

    call Hexagon.Libkern.String.BCDToASCII

    push eax

    call Hexagon.Kernel.Dev.Console.Console.printCharacter

    pop eax

    mov al, ah

    call Hexagon.Kernel.Dev.Console.Console.printCharacter

    mov al, '/'

    call Hexagon.Kernel.Dev.Console.Console.printCharacter

    mov al, [Hexagon.Arch.CMOS.month]

    call Hexagon.Libkern.String.BCDToASCII

    push eax

    call Hexagon.Kernel.Dev.Console.Console.printCharacter

    pop eax

    mov al, ah

    call Hexagon.Kernel.Dev.Console.Console.printCharacter

    mov al, '/'

    call Hexagon.Kernel.Dev.Console.Console.printCharacter

    mov al, [Hexagon.Arch.CMOS.century]

    call Hexagon.Libkern.String.BCDToASCII

    push eax

    call Hexagon.Kernel.Dev.Console.Console.printCharacter

    pop eax

    mov al, ah

    call Hexagon.Kernel.Dev.Console.Console.printCharacter

    mov al, [Hexagon.Arch.CMOS.year]

    call Hexagon.Libkern.String.BCDToASCII

    push eax

    call Hexagon.Kernel.Dev.Console.Console.printCharacter

    pop eax

    mov al, ah

    call Hexagon.Kernel.Dev.Console.Console.printCharacter

    pop esi
    pop ebx
    pop eax

    ret

;;************************************************************************************

Hexagon.Kern.Dmesg.hourToLog:

    push eax
    push ebx
    push esi

    mov al, ' '

    call Hexagon.Kernel.Dev.Console.Console.printCharacter

    call Hexagon.Arch.CMOS.CMOS.getCMOSData

    mov al, [Hexagon.Arch.CMOS.hour]

    call Hexagon.Libkern.String.BCDToASCII

    push eax

    call Hexagon.Kernel.Dev.Console.Console.printCharacter

    pop eax

    mov al, ah

    call Hexagon.Kernel.Dev.Console.Console.printCharacter

    mov al, ':'

    call Hexagon.Kernel.Dev.Console.Console.printCharacter

    mov al, [Hexagon.Arch.CMOS.minute]

    call Hexagon.Libkern.String.BCDToASCII

    push eax

    call Hexagon.Kernel.Dev.Console.Console.printCharacter

    pop eax

    mov al, ah

    call Hexagon.Kernel.Dev.Console.Console.printCharacter

    mov al, ':'

    call Hexagon.Kernel.Dev.Console.Console.printCharacter

    mov al, [Hexagon.Arch.CMOS.second]

    call Hexagon.Libkern.String.BCDToASCII

    push eax

    call Hexagon.Kernel.Dev.Console.Console.printCharacter

    pop eax

    mov al, ah

    call Hexagon.Kernel.Dev.Console.Console.printCharacter

    mov esi, Hexagon.Dmesg.dateSource

    call Hexagon.Kernel.Dev.Console.Console.printString

    pop esi
    pop ebx
    pop eax

    ret

;;************************************************************************************

;; This function is responsible for receiving and displaying a message originating
;; from Hexagon itself or as a relevant alert from daemons or applications
;;
;; Input:
;;
;; ESI - Complete message to be displayed
;; EAX - Code, if any
;; EBX - Priority

;; If the priority is greater than or equal to 4, messages will only be sent via
;; the serial port.

Hexagon.Kern.Dmesg.createMessage:

;; Hexagon.Kernel.Dev.Dev.open/write below track which device is open via
;; global state (Hexagon.Dev.Control.*), and Hexagon.Syscall.Control.systemCall
;; is also read here. None of that is safe to interleave between two
;; processes, so this whole function runs with interrupts disabled

    pushfd
    cli

    cmp ebx, Hexagon.Dmesg.Priorities.p4
    je .justSerialOutput

    cmp ebx, 05h
    je .defaultSent

    popfd

    ret ;; Only this options are valid for now

.defaultSent:

    push esi

    cmp byte[Hexagon.Syscall.Control.systemCall], 01h
    je .userProcess

.hexagonMessage:

    mov esi, Hexagon.Dmesg.hexagonIdentifier

    push esi

    call Hexagon.Kern.Dmesg.messageToSerial

    call Hexagon.Kernel.Dev.Console.Console.printString

    pop esi

    call Hexagon.Kern.Dmesg.appendToBuffer

    pop esi ;; The message text itself, pushed at .defaultSent above

    push esi

    call Hexagon.Kern.Dmesg.messageToSerial

    call Hexagon.Kernel.Dev.Console.Console.printString

    pop esi

    call Hexagon.Kern.Dmesg.appendToBuffer

    mov esi, Hexagon.Dmesg.newLine

    push esi

    call Hexagon.Kern.Dmesg.messageToSerial

    call Hexagon.Kernel.Dev.Console.Console.printString

    pop esi

    call Hexagon.Kern.Dmesg.appendToBuffer

    popfd

    ret

.userProcess:

    mov esi, Hexagon.Dmesg.userIdentifierOpen

    call Hexagon.Kern.Dmesg.messageToSerial

    call Hexagon.Kernel.Dev.Console.Console.printString

;; The process PID will be displayed on the screen

    call Hexagon.Kern.Proc.getPID

    mov edi, Hexagon.Kern.Dmesg.pidString

    call Hexagon.Libkern.String.integetToString ;; Transform into a string

    mov esi, Hexagon.Kern.Dmesg.pidString

    call Hexagon.Kern.Dmesg.messageToSerial

    call Hexagon.Kernel.Dev.Console.Console.printString

    mov esi, Hexagon.Dmesg.userIdentifierClose

    call Hexagon.Kern.Dmesg.messageToSerial

    call Hexagon.Kernel.Dev.Console.Console.printString

    jmp .messageReceived

.messageReceived:

    pop esi

    call Hexagon.Kern.Dmesg.messageToSerial

    call Hexagon.Kernel.Dev.Console.Console.printString

    mov esi, Hexagon.Dmesg.newLine

    call Hexagon.Kern.Dmesg.messageToSerial

    call Hexagon.Kernel.Dev.Console.Console.printString

    popfd

    ret

.justSerialOutput:

    push esi

    cmp byte[Hexagon.Syscall.Control.systemCall], 01h
    je .userProcessSerialMessage

.hexagonSerialMessage:

    mov esi, Hexagon.Dmesg.hexagonIdentifier

    push esi

    call Hexagon.Kern.Dmesg.messageToSerial

    pop esi

    call Hexagon.Kern.Dmesg.appendToBuffer

    pop esi ;; The message text itself, pushed at .justSerialOutput above

    push esi

    call Hexagon.Kern.Dmesg.messageToSerial

    pop esi

    call Hexagon.Kern.Dmesg.appendToBuffer

    mov esi, Hexagon.Dmesg.newLine

    push esi

    call Hexagon.Kern.Dmesg.messageToSerial

    pop esi

    call Hexagon.Kern.Dmesg.appendToBuffer

    popfd

    ret

.userProcessSerialMessage:

    mov esi, Hexagon.Dmesg.userIdentifierOpen

    call Hexagon.Kern.Dmesg.messageToSerial

;; The process PID will be displayed on the screen

    call Hexagon.Kern.Proc.getPID

    mov edi, Hexagon.Kern.Dmesg.pidString

    call Hexagon.Libkern.String.integetToString ;; Transform into a string

    mov esi, Hexagon.Kern.Dmesg.pidString

    call Hexagon.Kern.Dmesg.messageToSerial

    mov esi, Hexagon.Dmesg.userIdentifierClose

    call Hexagon.Kern.Dmesg.messageToSerial

.serialMessageReceived:

    pop esi

    call Hexagon.Kern.Dmesg.messageToSerial

    mov esi, Hexagon.Dmesg.newLine

    call Hexagon.Kern.Dmesg.messageToSerial

    popfd

    ret

;;************************************************************************************

;; This function is responsible for sending the messages received by Hexagon to
;; the default serial port initialized during startup (COM1). Useful for runtime debugging
;;
;; Input:
;;
;; ESI - Full message to be displayed

Hexagon.Kern.Dmesg.messageToSerial:

    pushad

    mov esi, Hexagon.Dev.Devices.com1

    call Hexagon.Kernel.Dev.Dev.open

    mov esi, [esp + 4] ;; Restore original ESI from pushad's own stack layout (EDI, ESI, EBP, ESP, EBX, EDX, ECX, EAX)

    call Hexagon.Kernel.Dev.Dev.write

    popad

    ret

;;************************************************************************************

;; Appends a null-terminated message to the kernel log ring buffer, one byte
;; at a time, wrapping the write index once it reaches the buffer's end.
;; Lazily Mm.malloc's the buffer on the first call, since Mm.initMemory has
;; already run before Hexagon logs anything
;;
;; Input:
;;
;; ESI - Null-terminated message to append

Hexagon.Kern.Dmesg.appendToBuffer:

    pushad

    cmp dword[Hexagon.Kern.Dmesg.Buffer.pointer], 0
    jne .allocated

    mov ebx, Hexagon.Kern.Dmesg.Buffer.size

    call Hexagon.Arch.Mm.malloc

    cmp eax, 0
    je .end ;; Out of memory. This message is silently missing from the buffer

;; Already flat/physical, same as every other Mm.malloc return

    mov dword[Hexagon.Kern.Dmesg.Buffer.pointer], ebx 

.allocated:

;; ESI here is a plain kernel label, message text or one of Hexagon.Dmesg's
;; own identifiers, which DS already reaches. Only ES is overridden below,
;; for the ring buffer side of the copy

    push es

    mov ax, 18h ;; Kernel linear segment, needed to reach the malloc'd buffer directly
    mov es, ax

.nextByte:

    mov al, byte[esi]

    cmp al, 0
    je .doneWriting

    mov edi, dword[Hexagon.Kern.Dmesg.Buffer.pointer]
    add edi, dword[Hexagon.Kern.Dmesg.Buffer.writeIndex]

    mov byte[es:edi], al

    inc dword[Hexagon.Kern.Dmesg.Buffer.writeIndex]

    cmp dword[Hexagon.Kern.Dmesg.Buffer.writeIndex], Hexagon.Kern.Dmesg.Buffer.size
    jne .noWrap

    mov dword[Hexagon.Kern.Dmesg.Buffer.writeIndex], 0

.noWrap:

    inc dword[Hexagon.Kern.Dmesg.Buffer.totalWritten]

    inc esi

    jmp .nextByte

.doneWriting:

    pop es

.end:

    popad

    ret

;;************************************************************************************

;; hx.sysctl's own entry point, a single place to read kernel-maintained
;; data selected by a function number instead of a dedicated syscall per
;; kind of data. Only function 1 exists so far, the kernel's own log
;; buffer above (userland messages excluded, see createMessage). Reading
;; it never resets writeIndex/totalWritten, so repeated calls always see
;; the same accumulated history
;;
;; Input:
;;
;; EBX - Function number
;; ESI - Caller's buffer
;; ECX - Caller's buffer size
;;
;; Output:
;;
;; EAX - Bytes copied
;; CF defined in case of unknown function number

Hexagon.Kern.Dmesg.sysctl:

;; The caller's own buffer, written into at CPL 0 where paging refuses nothing,
;; so the range is checked against what the process can reach first

    push ebx

    mov ebx, esi

    call Hexagon.Arch.Paging.rangeIsCallerWritable

    pop ebx

    jc .badBuffer

    cmp ebx, 1
    je .getKernelLog

    stc

    ret
.badBuffer:

    mov eax, Hexagon.Kern.Proc.badAddress

    stc

    ret


.getKernelLog:

    push ebx
    push ecx
    push edx
    push edi

    pushfd
    cli ;; Keeps writeIndex/totalWritten consistent with each other against
        ;; a concurrent createMessage call from another process

    mov edi, esi ;; Caller's buffer, translated by hexagonHandler and reached
                 ;; through ES 10h below, the same convention hx.getProcesses
                 ;; already uses for its own caller buffer

    xor eax, eax

    cmp dword[Hexagon.Kern.Dmesg.Buffer.pointer], 0
    je .noContentYet ;; Nothing logged yet, buffer never allocated

    mov edx, dword[Hexagon.Kern.Dmesg.Buffer.totalWritten]

    cmp edx, Hexagon.Kern.Dmesg.Buffer.size
    jb .notWrapped

;; The buffer has wrapped at least once. Chronological order starts at the
;; oldest byte still held, the one about to be overwritten next

    mov esi, dword[Hexagon.Kern.Dmesg.Buffer.pointer]
    add esi, dword[Hexagon.Kern.Dmesg.Buffer.writeIndex]

    mov edx, Hexagon.Kern.Dmesg.Buffer.size
    sub edx, dword[Hexagon.Kern.Dmesg.Buffer.writeIndex]

    call .copyBytes

    mov esi, dword[Hexagon.Kern.Dmesg.Buffer.pointer]
    mov edx, dword[Hexagon.Kern.Dmesg.Buffer.writeIndex]

    call .copyBytes

    jmp .copied

.notWrapped:

    mov esi, dword[Hexagon.Kern.Dmesg.Buffer.pointer]

    call .copyBytes

    jmp .copied

.noContentYet:

.copied:

    popfd

    pop edi
    pop edx
    pop ecx
    pop ebx

    clc

    ret

;; Copies up to EDX bytes from ESI (kernel linear, flat) into EDI (caller's
;; buffer, kernel data segment), capped by whatever room is still left in
;; the caller's own ECX-sized buffer. Advances EDI and EAX (running total),
;; leaves ECX/EDX spent by however much was actually copied

.copyBytes:

    mov ebx, ecx
   
    sub ebx, eax ;; Room still left in the caller's buffer
   
    jbe .copyBytesDone ;; No room left at all

    cmp edx, ebx
    jbe .copyBytesSized

    mov edx, ebx

.copyBytesSized:

    push ds
    push es

    mov bx, 18h
    mov ds, bx
    mov bx, 10h
    mov es, bx

.copyBytesLoop:

    cmp edx, 0
    je .copyBytesRestore

    mov bl, byte[esi]
    mov byte[es:edi], bl

    inc esi
    inc edi
    inc eax
    dec edx

    jmp .copyBytesLoop

.copyBytesRestore:

    pop es
    pop ds

.copyBytesDone:

    ret

;;************************************************************************************

;; Where the PID goes while a message naming it is being put together, since
;; Hexagon.Libkern.String.integetToString writes into a buffer of the caller's
;; supplies, and does not own one itself

Hexagon.Kern.Dmesg.pidString:
times 12 db 0
