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

;;************************************************************************************
;;
;; Informações importantes para uso com a interface de dispositivos Hexagon
;;
;;************************************************************************************
;;
;; Classes de dispositivos utilizadas para designar dispositivo para E/S
;;
;; 1 - Dispositivo de bloco (armazenamento - HDs e outras mídias)
;; 2 - Portas seriais
;; 3 - Portas paralelas (impressoras)
;; 4 - Dispositivos de saída (vídeo e som)
;; 5 - Processador(es)
;;
;;************************************************************************************

use32

Hexagon.Dev.Control:

.deviceId:    dw 0
.openDevice:  db 0
.deviceClass: db 0
.isOpen:      db 0
.file:        db 0

Hexagon.Dev.Devices:

;; Storage devices

.hd0:
db "hd0", 0 ;; First hard drive
.hd1:
db "hd1", 0 ;; Second hard drive
.hd2:
db "hd2", 0 ;; Third hard drive
.hd3:
db "hd3", 0 ;; Fourth hard drive

;; Serial ports

.com1:
db "com1", 0 ;; First serial port
.com2:
db "com2", 0 ;; Second serial port
.com3:
db "com3", 0 ;; Third serial port
.com4:
db "com4", 0 ;; Fourth serial port

;; Parallel ports

.lpt0:
db "lpt0", 0 ;; First parallel port
.lpt1:
db "ltp1", 0 ;; Second parallel port
.lpt2:
db "lpt2", 0 ;; Third parallel port

;; Consoles

.tty0:
db "tty0", 0 ;; Main console
.tty1:
db "tty1", 0 ;; First virtual console
.tty2:
db "tty2", 0 ;; Kernel data dump console

.au0:
db "au0", 0 ;; Internal speaker

;; Input devices

.mouse0:
db "mouse0", 0 ;; Mouse connected to the computer
.kbd0:
db "kbd0", 0 ;; Keyboard connected to the computer

;; Processors:

.proc0:
db "proc0", 0 ;; Main processor

Hexagon.Dev.DeviceClasses:

.block:    db 01h
.serial:   db 02h
.parallel: db 03h
.output:   db 04h
.proc:     db 05h

;;************************************************************************************

;; Closes communication with a device

Hexagon.Kernel.Dev.Dev.close:

    mov byte[Hexagon.Dev.Control.isOpen], 0
    mov word[Hexagon.Dev.Control.deviceClass], 0

    push ebx

    mov bx, word[Hexagon.Dev.Control.deviceId]

    cmp bx, word[Hexagon.Dev.deviceCodes.au0]
    je .au0

    pop ebx

    jmp .finish

.au0:

    pop ebx

    call Hexagon.Kernel.Dev.Gen.Snd.Snd.stopSound

    jmp .finish

.finish:

    mov byte[Hexagon.Dev.Control.deviceId], 00h

    ret

;;************************************************************************************

;; Send data to certain open device. Data will be sent to the open device.
;; In case of error or device not opened, return error
;;
;; Input:
;;
;; ESI - Pointer to the buffer containing the data to be sent
;;
;; Output:
;;
;; CF set in case of error

Hexagon.Kernel.Dev.Dev.write:

    cmp byte[Hexagon.Dev.Control.isOpen], 0
    je .deviceNotOpen

    push eax
    push esi

    mov dl, byte[Hexagon.Dev.Control.deviceClass]

    cmp dl, 01h
    je .storage

    cmp dl, 02h
    je .serialPorts

    cmp dl, 03h
    je .parallelPorts

    cmp dl, 04h
    je .output

    cmp dl, 05h
    je .processors

    stc

    ret

.storage:

    pop esi
    pop eax

    call Hexagon.Kernel.Dev.Dev.close

    ret ;; Not currently supported

.serialPorts:

    pop esi
    pop eax

    call Hexagon.Kernel.Dev.Gen.COM.Serial.sendViaSerial

    jc .erro

    call Hexagon.Kernel.Dev.Dev.close

    ret

.parallelPorts:

    pop esi
    pop eax

    call Hexagon.Kernel.Dev.Gen.LPT.LPT.sendViaParallelPort

    jc .erro

    call Hexagon.Kernel.Dev.Dev.close

    ret

.output:

    pop esi
    pop eax

    mov bx, word[Hexagon.Dev.Control.deviceId]

    cmp word[Hexagon.Dev.deviceCodes.au0], bx
    je .au0

    call Hexagon.Kernel.Dev.Dev.close

    ret

.au0:

    call Hexagon.Kernel.Dev.Gen.Snd.Snd.playSound

    ret

.processors:

    pop esi
    pop eax

    call Hexagon.Kernel.Dev.Dev.close

    ret

.deviceNotOpen:

    stc

    ret

.erro:

    call Hexagon.Kernel.Dev.Dev.close

    stc

    ret

;;************************************************************************************

;; Opens a read/write channel with a specific requested device.
;; It also opens a common file present in the file system
;;
;; Input:
;;
;; ESI - Pointer to the buffer containing the device name
;; EDI - Load address, in case of file on disk
;;
;; Output:
;;
;; EAX - Device class
;; CF set in case of error

Hexagon.Kernel.Dev.Dev.open:

    push edi
    push esi

    call Hexagon.Kernel.Dev.Dev.convertDeviceNameToDevice

    pop esi
    pop edi

    push bx

;; Check if it is marked as a possible common file present on the file system

    cmp byte[Hexagon.Dev.Control.file], 1
    je .file

;; If not, proceed with opening a device

    mov byte[Hexagon.Dev.Control.deviceClass], dl

    cmp dl, 01h
    je .storage

    cmp dl, 02h
    je .serialPorts

    cmp dl, 03h
    je .parallelPorts

    cmp dl, 04h
    je .output

    cmp dl, 05h
    je .processors

    stc

    ret

;; For storage, outputs may be different
;;
;; Output:
;;
;; EAX - Generic Error Code/User Permission
;; EBX - Error code returned by disk management

.storage:

    pop bx

    clc

    push eax

    cmp dword[ordemKernel], ordemKernelExecutar
    je .storageAuthenticated

.storageVerifyPermissions:

    call Hexagon.Kernel.Kernel.Usuarios.verificarPermissoes

    cmp eax, 03h ;; Group code for standard user
    je .storagePermissionDenied

.storageAuthenticated:

    pop eax

    mov byte[Hexagon.Dev.Gen.Disco.Controle.driveAtual], ah

    call Hexagon.Kernel.FS.VFS.definirSistemaArquivos

    jc .notFoundError

    call Hexagon.Kernel.FS.VFS.iniciarSistemaArquivos

    jc .openingError

    push ebx ;; Contains the disk operation error code

    mov byte[Hexagon.Dev.Control.isOpen], 1

    call Hexagon.Kernel.Dev.Dev.close

;; Provide the user who requested the mount the return code for the operation

    pop ebx

    mov eax, dword[Hexagon.Dev.Control.deviceClass]

    jmp .return

.storagePermissionDenied:

    pop eax

    mov eax, 05h

    stc

    jmp .return

.notFoundError:

    mov byte[Hexagon.Dev.Control.isOpen], 0
    mov eax, 06h ;;Device not found

    jmp .return

.openingError:

;; The error code for disk operations is already in EBX, in case of
;; a call to open a volume

    mov byte[Hexagon.Dev.Control.isOpen], 0
    mov eax, dword[Hexagon.Dev.Control.deviceClass]

    jmp .return

.serialPorts:

    pop bx

    mov word[Hexagon.Kernel.Dev.Gen.COM.Serial.Ports.currentSerialPort], bx

    call Hexagon.Kernel.Dev.Gen.COM.Serial.setupSerialPort

    jc .openingError

    mov byte[Hexagon.Dev.Control.isOpen], 1

    mov eax, dword[Hexagon.Dev.Control.deviceClass]

    jmp .return

.parallelPorts:

    pop bx

    mov word[Hexagon.Kernel.Dev.Gen.LPT.LPT.currentParallelPort], bx

    call Hexagon.Kernel.Dev.Gen.LPT.LPT.setupParallelPort

    jc .openingError

    mov byte[Hexagon.Dev.Control.isOpen], 1

    mov eax, dword[Hexagon.Dev.Control.deviceClass]

    jmp .return

.output:

    pop bx

    mov eax, dword[Hexagon.Dev.Control.deviceClass]

    cmp bx, [Hexagon.Dev.deviceCodes.tty0]
    je .tty0

    cmp bx, [Hexagon.Dev.deviceCodes.tty1]
    je .tty1

    cmp bx, [Hexagon.Dev.deviceCodes.tty2]
    je .tty2

    cmp bx, [Hexagon.Dev.deviceCodes.au0]
    je .au0

    jmp .return

.tty0: ;; Main console

    call Hexagon.Kernel.Dev.Gen.Console.Console.useMainConsole

    jmp .return

.tty1: ;; First virtual console

    call Hexagon.Kernel.Dev.Gen.Console.Console.useSecondaryConsole

    jmp .return

.tty2: ;; Kernel data dump console

    mov ebx, 1h

    call Hexagon.Kernel.Dev.Gen.Console.Console.updateConsole

    jmp .return

.au0: ;; Computer internal speaker

    jmp .return

.processors:

    pop bx

    mov eax, dword[Hexagon.Dev.Control.deviceClass]

    mov esi, Hexagon.Dev.deviceCodes.proc0

    jmp .return

.file:

    pop bx

    mov byte[Hexagon.Dev.Control.file], 0

    call Hexagon.Kernel.FS.VFS.carregarArquivo

    jmp .return

.return:

    ret

;;************************************************************************************

;; Convert a device name according to convention to a number or physical
;;  address of a device.
;; It is also used to distinguish between device names and common file name
;; present in the file system
;;
;; Input:
;;
;; ESI - Pointer to the buffer containing the name
;; EAX - Device Class (future use)
;;
;; Output:
;;
;; AH  - Device number for use by the kernel
;; BX  - Copy of AH into a 16-bit register
;; DL  - Device Class
;; ECX - Copy of AH into a 32-bit register

Hexagon.Kernel.Dev.Dev.convertDeviceNameToDevice:

    mov edi, Hexagon.Dev.Devices.hd0
    call Hexagon.Kernel.Lib.String.compararPalavrasNaString
    jc .hd0

    mov edi, Hexagon.Dev.Devices.hd1
    call Hexagon.Kernel.Lib.String.compararPalavrasNaString
    jc .hd1

    mov edi, Hexagon.Dev.Devices.hd2
    call Hexagon.Kernel.Lib.String.compararPalavrasNaString
    jc .hd2

    mov edi, Hexagon.Dev.Devices.hd3
    call Hexagon.Kernel.Lib.String.compararPalavrasNaString
    jc .hd3

    mov edi, Hexagon.Dev.Devices.com1
    call Hexagon.Kernel.Lib.String.compararPalavrasNaString
    jc .com1

    mov edi, Hexagon.Dev.Devices.com2
    call Hexagon.Kernel.Lib.String.compararPalavrasNaString
    jc .com2

    mov edi, Hexagon.Dev.Devices.com3
    call Hexagon.Kernel.Lib.String.compararPalavrasNaString
    jc .com3

    mov edi, Hexagon.Dev.Devices.com4
    call Hexagon.Kernel.Lib.String.compararPalavrasNaString
    jc .com4

    mov edi, Hexagon.Dev.Devices.lpt0
    call Hexagon.Kernel.Lib.String.compararPalavrasNaString
    jc .lpt0

    mov edi, Hexagon.Dev.Devices.lpt1
    call Hexagon.Kernel.Lib.String.compararPalavrasNaString
    jc .lpt1

    mov edi, Hexagon.Dev.Devices.lpt2
    call Hexagon.Kernel.Lib.String.compararPalavrasNaString
    jc .lpt2

    mov edi, Hexagon.Dev.Devices.tty0
    call Hexagon.Kernel.Lib.String.compararPalavrasNaString
    jc .tty0

    mov edi, Hexagon.Dev.Devices.tty1
    call Hexagon.Kernel.Lib.String.compararPalavrasNaString
    jc .tty1

    mov edi, Hexagon.Dev.Devices.tty2
    call Hexagon.Kernel.Lib.String.compararPalavrasNaString
    jc .tty2

    mov edi,Hexagon.Dev.Devices.au0
    call Hexagon.Kernel.Lib.String.compararPalavrasNaString
    jc .au0

    mov edi, Hexagon.Dev.Devices.mouse0
    call Hexagon.Kernel.Lib.String.compararPalavrasNaString
    jc .mouse0

    mov edi, Hexagon.Dev.Devices.kbd0
    call Hexagon.Kernel.Lib.String.compararPalavrasNaString
    jc .kbd0

    mov edi, Hexagon.Dev.Devices.proc0
    call Hexagon.Kernel.Lib.String.compararPalavrasNaString
    jc .proc0

;; This name may refer to a common file!
;; Then the system will try to open it!

    mov byte[Hexagon.Dev.Control.file], 1 ;; Mark as possibly a file

    ret

.hd0:

    mov ah, byte [Hexagon.Dev.deviceCodes.hd0]
    mov byte[Hexagon.Dev.Control.deviceId], ah
    movzx ecx, byte [Hexagon.Dev.deviceCodes.hd0]
    mov dl, 01h

    ret

.hd1:

    mov ah, byte [Hexagon.Dev.deviceCodes.hd1]
    mov byte[Hexagon.Dev.Control.deviceId], ah
    movzx ecx, byte [Hexagon.Dev.deviceCodes.hd1]
    mov dl, 01h

    ret

.hd2:

    mov ah, byte [Hexagon.Dev.deviceCodes.hd2]
    mov byte[Hexagon.Dev.Control.deviceId], ah
    movzx ecx, byte [Hexagon.Dev.deviceCodes.hd2]
    mov dl, 01h

    ret

.hd3:

    mov ah, byte [Hexagon.Dev.deviceCodes.hd3]
    mov byte[Hexagon.Dev.Control.deviceId], ah
    movzx ecx, byte [Hexagon.Dev.deviceCodes.hd3]
    mov dl, 01h

    ret

.com1:

    mov ah, 00h
    mov bx, word [Hexagon.Dev.deviceCodes.com1]
    mov word[Hexagon.Dev.Control.deviceId], bx
    movzx ecx, word [Hexagon.Dev.deviceCodes.com1]
    mov dl, 02h

    ret

.com2:

    mov ah, 01h
    mov bx, word [Hexagon.Dev.deviceCodes.com2]
    mov word[Hexagon.Dev.Control.deviceId], bx
    movzx ecx, word [Hexagon.Dev.deviceCodes.com2]
    mov dl, 02h

    ret

.com3:

    mov ah, 02h
    mov bx, word [Hexagon.Dev.deviceCodes.com3]
    mov word[Hexagon.Dev.Control.deviceId], bx
    movzx ecx, word [Hexagon.Dev.deviceCodes.com3]
    mov dl, 02h

    ret

.com4:

    mov ah, 03h
    mov bx, word [Hexagon.Dev.deviceCodes.com4]
    mov word[Hexagon.Dev.Control.deviceId], bx
    movzx ecx, word [Hexagon.Dev.deviceCodes.com4]
    mov dl, 02h

    ret

.lpt0:

    mov bx, word [Hexagon.Dev.deviceCodes.lpt0]
    mov word[Hexagon.Dev.Control.deviceId], bx
    movzx ecx, word [Hexagon.Dev.deviceCodes.lpt0]
    mov dl, 03h

    ret

.lpt1:

    mov bx, word [Hexagon.Dev.deviceCodes.lpt1]
    mov word[Hexagon.Dev.Control.deviceId], bx
    movzx ecx, word [Hexagon.Dev.deviceCodes.lpt1]
    mov dl, 03h

    ret

.lpt2:

    mov bx, word [Hexagon.Dev.deviceCodes.lpt2]
    mov word[Hexagon.Dev.Control.deviceId], bx
    movzx ecx, word [Hexagon.Dev.deviceCodes.lpt2]
    mov dl, 03h

    ret

.tty0:

    mov ah, 00h
    mov bx, word [Hexagon.Dev.deviceCodes.tty0]
    mov word[Hexagon.Dev.Control.deviceId], bx
    mov ecx, [Hexagon.Dev.deviceCodes.tty0]
    mov dl, 04h

    ret

.tty1:

    mov ah, 01h
    mov bx, word [Hexagon.Dev.deviceCodes.tty1]
    mov word[Hexagon.Dev.Control.deviceId], bx
    mov ecx, [Hexagon.Dev.deviceCodes.tty1]
    mov dl, 04h

    ret

.tty2:

    mov ah, 02h
    mov bx, word [Hexagon.Dev.deviceCodes.tty2]
    mov word[Hexagon.Dev.Control.deviceId], bx
    mov ecx, [Hexagon.Dev.deviceCodes.tty2]
    mov dl, 04h

    ret

.au0:

    mov ah, byte [Hexagon.Dev.deviceCodes.au0]
    mov bx, word [Hexagon.Dev.deviceCodes.au0]
    mov word[Hexagon.Dev.Control.deviceId], bx
    mov dl, 04h

.mouse0:

    mov ah, 00h
    mov bx, [Hexagon.Dev.deviceCodes.mouse0]
    mov word[Hexagon.Dev.Control.deviceId], bx
    mov dl, 00h

    ret

.kbd0:

    mov ah, 00h
    mov bx, word [Hexagon.Dev.deviceCodes.kbd0]
    mov word[Hexagon.Dev.Control.deviceId], bx
    mov dl, 00h

    ret

.proc0:

    mov ah, 00h
    mov bx, word [Hexagon.Dev.deviceCodes.proc0]
    mov word[Hexagon.Dev.Control.deviceId], bx
    movzx ecx, word [Hexagon.Dev.deviceCodes.proc0]
    mov dl, 05h

    ret

;;************************************************************************************

;; Convert a device number or physical address to a device name
;;
;; Input:
;;
;; AH - Device number (storage case)
;; AX - Device number (serial ports, parallel ports, video devices and processors)
;; DL - Device class (1 for storage, 2 for serial ports, 3 for parallel ports,
;;       4 for output devices and 5 for processors)
;;
;; Output:
;;
;; ESI - Buffer containing the file/device name

Hexagon.Kernel.Dev.Dev.convertDeviceToDeviceName:

    cmp dl, 1
    je .storage

    cmp dl, 2
    je .serial

    cmp dl, 3
    je .paralelas

    cmp dl, 4
    je .output

    cmp dl, 5
    je .processors

    stc ;; In case of invalid class

    ret

.storage:

    cmp ah, byte [Hexagon.Dev.deviceCodes.hd0]
    je .hd0

    cmp ah, byte [Hexagon.Dev.deviceCodes.hd1]
    je .hd1

    cmp ah, byte [Hexagon.Dev.deviceCodes.hd2]
    je .hd2

    cmp ah, byte [Hexagon.Dev.deviceCodes.hd3]
    je .hd3

    stc

    ret

.hd0:

    mov esi, Hexagon.Dev.Devices.hd0

    ret

.hd1:

    mov esi, Hexagon.Dev.Devices.hd1

    ret

.hd2:

    mov esi, Hexagon.Dev.Devices.hd2

    ret

.hd3:

    mov esi, Hexagon.Dev.Devices.hd3

    ret

.serial:

    cmp ax, word [Hexagon.Dev.deviceCodes.com1]
    je .com1

    cmp ax, word [Hexagon.Dev.deviceCodes.com2]
    je .com2

    cmp ax, word [Hexagon.Dev.deviceCodes.com3]
    je .com3

    cmp ax, word [Hexagon.Dev.deviceCodes.com4]
    je .com4

    stc

    ret

.com1:

    mov esi, Hexagon.Dev.Devices.com1

    ret

.com2:

    mov esi, Hexagon.Dev.Devices.com2

    ret

.com3:

    mov esi, Hexagon.Dev.Devices.com3

    ret

.com4:

    mov esi, Hexagon.Dev.Devices.com4

    ret

.paralelas:

    cmp ax, word [Hexagon.Dev.deviceCodes.lpt0]
    je .lpt0

    cmp ax, word [Hexagon.Dev.deviceCodes.lpt1]
    je .lpt1

    cmp ax, word [Hexagon.Dev.deviceCodes.lpt2]
    je .lpt2

    stc

    ret

.lpt0:

    mov esi, Hexagon.Dev.Devices.lpt0

    ret

.lpt1:

    mov esi, Hexagon.Dev.Devices.lpt1

    ret

.lpt2:

    mov esi, Hexagon.Dev.Devices.lpt2

    ret

.output:

    cmp ax, Hexagon.Dev.deviceCodes.tty0
    je .tty0

    cmp ax, Hexagon.Dev.deviceCodes.tty1
    je .tty1

    cmp ax, Hexagon.Dev.deviceCodes.tty2
    je .tty2

    stc

    ret

.tty0:

    mov esi, Hexagon.Dev.Devices.tty0

    ret

.tty1:

    mov esi, Hexagon.Dev.Devices.tty1

    ret

.tty2:

    mov esi, Hexagon.Dev.Devices.tty2

    ret

.processors:

    cmp ax, 00h
    je .proc0

    stc

    ret

.proc0:

    mov esi, Hexagon.Dev.Devices.proc0

    ret

;;************************************************************************************

;; Include architecture-dependent device codes

include "i386/i386.asm"
;; include "amd64/amd64.asm"
