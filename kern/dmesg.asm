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
;;                 Copyright (c) 2015-2024 Felipe Miguel Nery Lunkes
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
;; Copyright (c) 2015-2024, Felipe Miguel Nery Lunkes
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

;;************************************************************************************

Hexagon.Kernel.Kernel.Dmesg.startLog:

    call Hexagon.Kernel.Dev.Gen.Console.Console.useKernelConsole

    mov esi, Hexagon.Info.aboutHexagon

    call Hexagon.Kernel.Dev.Gen.Console.Console.printString

    call Hexagon.Kernel.Kernel.Dmesg.dateToLog

    call Hexagon.Kernel.Kernel.Dmesg.hourToLog

    call Hexagon.Kernel.Dev.Gen.Console.Console.useMainConsole

    ret

;;************************************************************************************

;; This function allows you to add a message to the kernel log

Hexagon.Kernel.Kernel.Dmesg.addMessage:

    call Hexagon.Kernel.Dev.Gen.Console.Console.useKernelConsole

    call Hexagon.Kernel.Dev.Gen.Console.Console.printString

    call Hexagon.Kernel.Dev.Gen.Console.Console.useMainConsole

    ret

;;************************************************************************************

Hexagon.Kernel.Kernel.Dmesg.dateToLog:

    push eax
    push ebx
    push esi

    mov esi, Hexagon.Dmesg.bootDate

    call Hexagon.Kernel.Dev.Gen.Console.Console.printString

    call Hexagon.Kernel.Arch.i386.CMOS.CMOS.getCMOSData

    mov al, [Hexagon.Arch.i386.CMOS.day]

    call Hexagon.Kernel.Lib.String.BCDParaASCII

    push eax

    call Hexagon.Kernel.Dev.Gen.Console.Console.printCharacter

    pop eax

    mov al, ah

    call Hexagon.Kernel.Dev.Gen.Console.Console.printCharacter

    mov al, '/'

    call Hexagon.Kernel.Dev.Gen.Console.Console.printCharacter

    mov al, [Hexagon.Arch.i386.CMOS.month]

    call Hexagon.Kernel.Lib.String.BCDParaASCII

    push eax

    call Hexagon.Kernel.Dev.Gen.Console.Console.printCharacter

    pop eax

    mov al, ah

    call Hexagon.Kernel.Dev.Gen.Console.Console.printCharacter

    mov al, '/'

    call Hexagon.Kernel.Dev.Gen.Console.Console.printCharacter

    mov al, [Hexagon.Arch.i386.CMOS.century]

    call Hexagon.Kernel.Lib.String.BCDParaASCII

    push eax

    call Hexagon.Kernel.Dev.Gen.Console.Console.printCharacter

    pop eax

    mov al, ah

    call Hexagon.Kernel.Dev.Gen.Console.Console.printCharacter

    mov al, [Hexagon.Arch.i386.CMOS.year]

    call Hexagon.Kernel.Lib.String.BCDParaASCII

    push eax

    call Hexagon.Kernel.Dev.Gen.Console.Console.printCharacter

    pop eax

    mov al, ah

    call Hexagon.Kernel.Dev.Gen.Console.Console.printCharacter

    pop esi
    pop ebx
    pop eax

    ret

;;************************************************************************************

Hexagon.Kernel.Kernel.Dmesg.hourToLog:

    push eax
    push ebx
    push esi

    mov al, ' '

    call Hexagon.Kernel.Dev.Gen.Console.Console.printCharacter

    call Hexagon.Kernel.Arch.i386.CMOS.CMOS.getCMOSData

    mov al, [Hexagon.Arch.i386.CMOS.hour]

    call Hexagon.Kernel.Lib.String.BCDParaASCII

    push eax

    call Hexagon.Kernel.Dev.Gen.Console.Console.printCharacter

    pop eax

    mov al, ah

    call Hexagon.Kernel.Dev.Gen.Console.Console.printCharacter

    mov al, ':'

    call Hexagon.Kernel.Dev.Gen.Console.Console.printCharacter

    mov al, [Hexagon.Arch.i386.CMOS.minute]

    call Hexagon.Kernel.Lib.String.BCDParaASCII

    push eax

    call Hexagon.Kernel.Dev.Gen.Console.Console.printCharacter

    pop eax

    mov al, ah

    call Hexagon.Kernel.Dev.Gen.Console.Console.printCharacter

    mov al, ':'

    call Hexagon.Kernel.Dev.Gen.Console.Console.printCharacter

    mov al, [Hexagon.Arch.i386.CMOS.second]

    call Hexagon.Kernel.Lib.String.BCDParaASCII

    push eax

    call Hexagon.Kernel.Dev.Gen.Console.Console.printCharacter

    pop eax

    mov al, ah

    call Hexagon.Kernel.Dev.Gen.Console.Console.printCharacter

    mov esi, Hexagon.Dmesg.dateSource

    call Hexagon.Kernel.Dev.Gen.Console.Console.printString

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

Hexagon.Kernel.Kernel.Dmesg.createMessage:

    cmp ebx, Hexagon.Dmesg.Priorities.p4
    je .justSerialOutput

    cmp ebx, 05h
    je .defaultSent

    ret ;; Por enquanto, só essas opções são válidas

.defaultSent:

    push esi

    cmp byte[Hexagon.Syscall.Control.systemCall], 01h
    je .userProcess

.hexagonMessage:

    mov esi, Hexagon.Dmesg.hexagonIdentifier

    call Hexagon.Kernel.Kernel.Dmesg.messageToSerial

    call Hexagon.Kernel.Dev.Gen.Console.Console.printString

    jmp .messageReceived

.userProcess:

    mov esi, Hexagon.Dmesg.userIdentifierOpen

    call Hexagon.Kernel.Kernel.Dmesg.messageToSerial

    call Hexagon.Kernel.Dev.Gen.Console.Console.printString

;; The process PID will be displayed on the screen

    movzx eax, word[Hexagon.Processes.PCB.PID] ;; Get PID

    call Hexagon.Kernel.Lib.String.paraString ;; Transform into a string

    call Hexagon.Kernel.Kernel.Dmesg.messageToSerial

    call Hexagon.Kernel.Dev.Gen.Console.Console.printString

    mov esi, Hexagon.Dmesg.userIdentifierClose

    call Hexagon.Kernel.Kernel.Dmesg.messageToSerial

    call Hexagon.Kernel.Dev.Gen.Console.Console.printString

    jmp .messageReceived

.messageReceived:

    pop esi

    call Hexagon.Kernel.Kernel.Dmesg.messageToSerial

    call Hexagon.Kernel.Dev.Gen.Console.Console.printString

    mov esi, Hexagon.Dmesg.newLine

    call Hexagon.Kernel.Kernel.Dmesg.messageToSerial

    call Hexagon.Kernel.Dev.Gen.Console.Console.printString

    ret

.justSerialOutput:

    push esi

    cmp byte[Hexagon.Syscall.Control.systemCall], 01h
    je .userProcessSerialMessage

.hexagonSerialMessage:

    mov esi, Hexagon.Dmesg.hexagonIdentifier

    call Hexagon.Kernel.Kernel.Dmesg.messageToSerial

    jmp .serialMessageReceived

.userProcessSerialMessage:

    mov esi, Hexagon.Dmesg.userIdentifierOpen

    call Hexagon.Kernel.Kernel.Dmesg.messageToSerial

;; The process PID will be displayed on the screen

    movzx eax, word[Hexagon.Processes.PCB.PID] ;; Get PID

    call Hexagon.Kernel.Lib.String.paraString ;; Transform into a string

    call Hexagon.Kernel.Kernel.Dmesg.messageToSerial

    mov esi, Hexagon.Dmesg.userIdentifierClose

    call Hexagon.Kernel.Kernel.Dmesg.messageToSerial

.serialMessageReceived:

    pop esi

    call Hexagon.Kernel.Kernel.Dmesg.messageToSerial

    mov esi, Hexagon.Dmesg.newLine

    call Hexagon.Kernel.Kernel.Dmesg.messageToSerial

    ret

;;************************************************************************************

;; This function is responsible for sending the messages received by Hexagon to
;; the default serial port initialized during startup (COM1). Useful for runtime debugging
;;
;; Input:
;;
;; ESI - Full message to be displayed

Hexagon.Kernel.Kernel.Dmesg.messageToSerial:

;; First, save the message already present in ESI for future use
;; in Hexagon.Kernel.Kernel.Dmesg.createMessage

    push esi

    mov esi, Hexagon.Dev.Devices.com1

    call Hexagon.Kernel.Dev.Dev.open

    pop esi
    push esi

    call Hexagon.Kernel.Dev.Dev.write

    pop esi

    ret
