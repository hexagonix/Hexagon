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

;; Sends data via serial port
;;
;; Input:
;;
;; SI - Pointer to the buffer containing the data to be sent
;;
;; The following function is used to transfer data over the open serial port

Hexagon.Kernel.Dev.Gen.COM.Serial.sendViaSerial:

    lodsb ;; Load the next character to be sent

    or al, al ;; Compares the character with the end of the message
    jz .done ;; If equal to end, jump to .done

    call Hexagon.Kernel.Dev.Gen.COM.Serial.performSend

    jc near .error

;; If it is not finished, return to the function and load the next character

    jmp Hexagon.Kernel.Dev.Gen.COM.Serial.sendViaSerial

.done: ;; If it's over...

    ret ;; Return

.error:

    stc

    ret

;;************************************************************************************

;; Blocks data from being sent via the serial port until it is ready.
;; If ready, send a byte
;;
;; Input:
;;
;; AL - Byte to send
;; BX - Register containing port number

Hexagon.Kernel.Dev.Gen.COM.Serial.performSend:

    pusha

    push ax ;; Save user input

    mov bx, word[Hexagon.Kernel.Dev.Gen.COM.Serial.Ports.currentSerialPort]

.waitSend:

    mov dx, bx

    add dx, 5 ;; Port + 5

    in al, dx

    test al, 00100000b ;; Bit 5 of the Line Status Register
                       ;; Empty transmitter wait register

    jz .waitSend ;; While not empty...

    pop ax ;; Restore user input

    mov dx, bx ;; Open port

    out dx, al ;; Send data to the requested port

    popa

    ret

;;************************************************************************************

;; Initializes and opens a specific serial port requested by the system for
;; reading and writing
;;
;; Input:
;;
;; BX - Register containing port number

Hexagon.Kernel.Dev.Gen.COM.Serial.setupSerialPort:

    mov bx, word[Hexagon.Kernel.Dev.Gen.COM.Serial.Ports.currentSerialPort]

    pusha

    push ds

    push cs
    pop ds

    mov al, 0
    mov dx, bx

    inc dx ;; Port + 1

    out dx, al ;; Disable interrupts

    mov dx, bx

    add dx, 3 ;; Port + 3

    mov al, 10000000b

    out dx, al ;; Enable DLAB (most significant bit), so that it is possible to
               ;; start defining the transmission rate divider

;; Bits 7-7: Enable DLAB
;; Bits 6-6: Stop transmission while 1
;; Bits 3-5: Parity (0=none)
;; Bits 2-2: Stop bit count (0=1 stop bit)
;; Bits 0-1: Character size (5 to 8)

    mov al, 12
    mov dx, bx ;; Port + 0

    out dx, al ;; Least significant byte of the divisor

    mov al, 0

    mov dx, bx

    add dx, 1 ;; Port + 1

    out dx, al ;; Most significant byte of the divider
               ;; This produces a rate of 115200/12 = 9600

    mov al, 11000111b
    mov dx, bx

    add dx, 2 ;; Port + 2

    out dx, al ;; 14 byte handler, enable FIFOs
               ;; Clear received FIFO, clear transmitted FIFO

;; Bits 7-6: Interrupt handler level
;; Bits 5-5: Enable 64-byte FIFO
;; Bits 4-4: Reserved
;; Bits 3-3: Mode selector
;; Bits 2-2: Clear transmitted FIFO
;; Bits 1-1: Clear received FIFO
;; Bits 0-0: Enable FIFOs

    mov al, 00000011b
    mov dx, bx

    add dx, 3 ;; Port + 3

    out dx, al

;; Disable DLAB, and set:
;;
;; - 8-bit size character
;; - No parity
;; - 1 stop bit

;; Bits 7-7: Enable DLAB
;; Bits 6-6: Stop transmission while 1
;; Bits 3-5: Parity (0=none)
;; Bits 2-2: Stop bit count (0=1 stop bit)
;; Bits 0-1: Character size (5 to 8)

    mov al, 00001011b
    mov dx, bx

    add dx, 4 ;; Port + 4

    out dx, al ;; Enable auxiliary output 2 (also called "enable IRQ")

;; Bits 7-6: Reserved
;; Bits 5-5: Automatic Flow Control Enabled
;; Bits 4-4: Loopback Mode
;; Bits 3-3: Auxiliary Output 2
;; Bits 2-2: Auxiliary Output 1
;; Bits 1-1: Request to send (RTS)
;; Bits 0-0: Data Terminal Ready (DTR)

    in al, 21h ;; Read IRQ mask bits from main PIC

    and al, 11101111b ;; Enable IRQ4, leaving all other IRQs unchanged

    out 21h, al ;; Write IRQ mask bits to main PIC

    mov al, 1
    mov dx, bx

    add dx, 1 ;; Port + 1

    out dx, al ;; Enable interrupts

    pop ds

    popa

    ret

;;************************************************************************************

;; Initialize the first serial port for debugging and sending messages

Hexagon.Kernel.Dev.Gen.COM.Serial.setupCOM1:

    push eax
    push ebx
    push ecx

    mov bx, word[Hexagon.Kernel.Dev.Gen.COM.Serial.Ports.currentSerialPort]
    mov word[Hexagon.Kernel.Dev.Gen.COM.Serial.Ports.previousSerialPort], bx

    mov bx, Hexagon.Dev.deviceCodes.com1
    mov word[Hexagon.Kernel.Dev.Gen.COM.Serial.Ports.currentSerialPort], bx

    call Hexagon.Kernel.Dev.Gen.COM.Serial.setupSerialPort

    mov bx, word[Hexagon.Kernel.Dev.Gen.COM.Serial.Ports.previousSerialPort]
    mov word[Hexagon.Kernel.Dev.Gen.COM.Serial.Ports.currentSerialPort], bx

    pop ecx
    pop ebx
    pop eax

    logHexagon Hexagon.Verbose.serial, Hexagon.Dmesg.Prioridades.p5

    ret

;;************************************************************************************

Hexagon.Kernel.Dev.Gen.COM.Serial.Ports:

.currentSerialPort:  db 0
.previousSerialPort: db 0
