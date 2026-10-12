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
;;
;;************************************************************************************
;;
;;                     This file is part of the Hexagon kernel
;;
;;************************************************************************************

use32

;;************************************************************************************
;;
;;                                PCI Bus Subsystem
;;
;; Provides PCI configuration space read/write via I/O ports 0xCF8 / 0xCFC,
;; bus scanning, device registry, and driver lookup, such as for SATA AHCI or IDE.
;;
;;************************************************************************************

Hexagon.PCI.CONFIG_ADDRESS = 0CF8h
Hexagon.PCI.CONFIG_DATA    = 0CFCh

Hexagon.PCI.maxDevices = 32

;; Device information record field layout

virtual at 0

Hexagon.PCI.Device.bus:        db ?
Hexagon.PCI.Device.device:     db ?
Hexagon.PCI.Device.function:   db ?
Hexagon.PCI.Device.headerType: db ?
Hexagon.PCI.Device.vendorId:   dw ?
Hexagon.PCI.Device.deviceId:   dw ?
Hexagon.PCI.Device.classCode:  db ?
Hexagon.PCI.Device.subclass:   db ?
Hexagon.PCI.Device.progIF:     db ?
Hexagon.PCI.Device.revision:   db ?
Hexagon.PCI.Device.bar0:       dd ?
Hexagon.PCI.Device.bar1:       dd ?
Hexagon.PCI.Device.bar2:       dd ?
Hexagon.PCI.Device.bar3:       dd ?
Hexagon.PCI.Device.bar4:       dd ?
Hexagon.PCI.Device.bar5:       dd ?
Hexagon.PCI.Device.irqLine:    db ?
Hexagon.PCI.Device.irqPin:     db ?
Hexagon.PCI.Device.valid:      db ?
Hexagon.PCI.Device.pad:        db ?

Hexagon.PCI.Device.size = $

end virtual

;; Device registry data

Hexagon.PCI.devicesCount: dd 0
Hexagon.PCI.devicesTable: 
times Hexagon.PCI.maxDevices * Hexagon.PCI.Device.size db 0

;;************************************************************************************

;; Reads a 32-bit dword from PCI configuration space
;;
;; Input:
;;   BL = Bus (0..255)
;;   BH = Device / Slot (0..31)
;;   CL = Function (0..7)
;;   CH = Register offset (0..255, dword aligned)
;;
;; Output:
;;   EAX = 32-bit configuration data

Hexagon.Dev.PCI.readConfigDword:

    push edx
    push ebx
    push ecx

    movzx eax, bl ;; Bus
    
    shl eax, 16

    movzx edx, bh ;; Device
    
    and edx, 1Fh
    
    shl edx, 11
    
    or eax, edx

    movzx edx, cl ;; Function
    
    and edx, 07h
    
    shl edx, 8
    
    or eax, edx

    movzx edx, ch ;; Offset
    
    and edx, 0FCh
    
    or eax, edx

    or eax, 80000000h ;; Enable bit (Bit 31)

    mov dx, Hexagon.PCI.CONFIG_ADDRESS
    
    out dx, eax

    mov dx, Hexagon.PCI.CONFIG_DATA
    
    in eax, dx

    pop ecx
    pop ebx
    pop edx

    ret

;;************************************************************************************

;; Writes a 32-bit dword to PCI configuration space
;;
;; Input:
;;   BL = Bus (0..255)
;;   BH = Device / Slot (0..31)
;;   CL = Function (0..7)
;;   CH = Register offset (0..255, dword aligned)
;;   EAX = 32-bit value to write

Hexagon.Dev.PCI.writeConfigDword:

    push edx
    push ebx
    push ecx
    push eax ;; Save value to write

    movzx eax, bl ;; Bus

    shl eax, 16

    movzx edx, bh ;; Device
    
    and edx, 1Fh
    
    shl edx, 11
    
    or eax, edx

    movzx edx, cl ;; Function
    
    and edx, 07h
    
    shl edx, 8
    
    or eax, edx

    movzx edx, ch ;; Offset
    
    and edx, 0FCh
    
    or eax, edx

    or eax, 80000000h ;; Enable bit

    mov dx, Hexagon.PCI.CONFIG_ADDRESS

    out dx, eax

    pop eax ;; Restore value to write

    mov dx, Hexagon.PCI.CONFIG_DATA
    
    out dx, eax

    pop ecx
    pop ebx
    pop edx

    ret

;;************************************************************************************

;; Reads a 16-bit word from PCI configuration space
;;
;; Input:
;;   BL = Bus, BH = Device, CL = Function, CH = Register offset
;;
;; Output:
;;   AX = 16-bit configuration word

Hexagon.Dev.PCI.readConfigWord:

    push ecx

    call Hexagon.Dev.PCI.readConfigDword

    pop ecx

    test ch, 2
    jz .lowWord

    shr eax, 16

.lowWord:

    and eax, 0FFFFh

    ret

;;************************************************************************************

;; Writes a 16-bit word to PCI configuration space
;;
;; Input:
;;   BL = Bus, BH = Device, CL = Function, CH = Register offset, AX = 16-bit value

Hexagon.Dev.PCI.writeConfigWord:

    push edx
    push ebx
    push ecx
    push eax ;; Save 16-bit value in AX

    movzx eax, bl ;; Bus

    shl eax, 16

    movzx edx, bh ;; Device
    
    and edx, 1Fh
    
    shl edx, 11
    
    or eax, edx

    movzx edx, cl ;; Function
    
    and edx, 07h
    
    shl edx, 8
    
    or eax, edx

    movzx edx, ch ;; Offset
    
    and edx, 0FCh
    
    or eax, edx

    or eax, 80000000h ;; Enable bit

    mov dx, Hexagon.PCI.CONFIG_ADDRESS

    out dx, eax

    pop eax ;; Restore AX (16-bit word)
    
    movzx edx, ch
    
    and edx, 2
    
    add dx, Hexagon.PCI.CONFIG_DATA
    
    out dx, ax

    pop ecx
    pop ebx
    pop edx

    ret

;;************************************************************************************

;; Reads an 8-bit byte from PCI configuration space
;;
;; Input:
;;   BL = Bus, BH = Device, CL = Function, CH = Register offset
;;
;; Output:
;;   AL = 8-bit configuration byte

Hexagon.Dev.PCI.readConfigByte:

    push ecx

    call Hexagon.Dev.PCI.readConfigDword

    pop ecx

    mov cl, ch
    and cl, 3
    
    shl cl, 3 ;; CL = (offset & 3) * 8
    shr eax, cl

    and eax, 0FFh

    ret

;;************************************************************************************

;; Scans all PCI buses and populates the device table
;;
;; Scans host bridge and all accessible buses/slots/functions.

Hexagon.Dev.PCI.scanBus:

    mov dword[Hexagon.PCI.devicesCount], 0

;; First check host bridge at Bus 0, Device 0, Function 0

    xor ebx, ebx ;; BL = Bus 0, BH = Device 0
    xor ecx, ecx ;; CL = Function 0, CH = 0 (offset 0)

    call Hexagon.Dev.PCI.readConfigWord ;; AX = Vendor ID

    cmp ax, 0FFFFh
    je .done ;; No PCI bus present

;; Check if host bridge is multi-function (Header type bit 7)

    mov ch, 0Eh ;; Offset 0Eh: Header Type
    call Hexagon.Dev.PCI.readConfigByte

    test al, 80h ;; Multi-function?
    jz .singleBus

;; Multi-function host controller: scan functions 0..7 as buses 0..7
    
    xor ecx, ecx

.multiBusLoop:

    push ecx

    mov bl, cl ;; Bus number = function number

    call Hexagon.Dev.PCI.scanSingleBus

    pop ecx

    inc cl

    cmp cl, 8
    jb .multiBusLoop

    jmp .done

.singleBus:

    xor bl, bl;; Bus 0

    call Hexagon.Dev.PCI.scanSingleBus

.done:

    ret

;;************************************************************************************

;; Scans a single PCI bus (BL = Bus number)

Hexagon.Dev.PCI.scanSingleBus:

    push ebx
    push ecx

    xor bh, bh ;; Device 0..31

.deviceLoop:

    push ebx

    xor cl, cl ;; Function 0
    xor ch, ch ;; Offset 0 (Vendor ID)

    call Hexagon.Dev.PCI.readConfigWord

    cmp ax, 0FFFFh
    je .nextDevice ;; No device present at this slot

;; Device found! Register function 0

    call Hexagon.Dev.PCI.registerDevice

;; Check Header Type (Offset 0x0E) to see if device is multi-function

    mov ch, 0Eh

    call Hexagon.Dev.PCI.readConfigByte

    test al, 80h
    jz .checkBridge ;; Single-function device

;; Multi-function device: scan functions 1..7
    
    mov cl, 1

.funcLoop:

    push ecx

    xor ch, ch ;; Offset 0

    call Hexagon.Dev.PCI.readConfigWord

    cmp ax, 0FFFFh
    je .nextFunc

    call Hexagon.Dev.PCI.registerDevice

.nextFunc:

    pop ecx

    inc cl

    cmp cl, 8
    jb .funcLoop

.checkBridge:

;; Check if device is a PCI-to-PCI Bridge (Header Type 0x01)

    mov ch, 0Eh
    
    call Hexagon.Dev.PCI.readConfigByte
    
    and al, 7Fh

    cmp al, 01h
    jne .nextDevice

;; Read Secondary Bus Number from bridge (Offset 0x19)
    
    mov ch, 19h
    
    call Hexagon.Dev.PCI.readConfigByte

    cmp al, 0
    je .nextDevice

    push ebx
    
    mov bl, al ;; Secondary bus
    
    call Hexagon.Dev.PCI.scanSingleBus
    
    pop ebx

.nextDevice:

    pop ebx

    inc bh
    
    cmp bh, 32
    jb .deviceLoop

    pop ecx
    pop ebx

    ret

;;************************************************************************************

;; Registers a discovered PCI function into Hexagon.PCI.devicesTable
;;
;; Input:
;;   BL = Bus, BH = Device, CL = Function

Hexagon.Dev.PCI.registerDevice:

    push eax
    push ebx
    push ecx
    push edx
    push edi

    mov eax, dword[Hexagon.PCI.devicesCount]
    
    cmp eax, Hexagon.PCI.maxDevices
    jae .tableFull

    imul edi, eax, Hexagon.PCI.Device.size
    
    add edi, Hexagon.PCI.devicesTable

;; Save Bus, Device, Function
   
    mov byte[edi + Hexagon.PCI.Device.bus], bl
    mov byte[edi + Hexagon.PCI.Device.device], bh
    mov byte[edi + Hexagon.PCI.Device.function], cl

;; Read Vendor ID & Device ID (Offset 0x00)
    
    mov ch, 00h
    
    call Hexagon.Dev.PCI.readConfigDword
    
    mov word[edi + Hexagon.PCI.Device.vendorId], ax
    
    shr eax, 16
    
    mov word[edi + Hexagon.PCI.Device.deviceId], ax

;; Read Revision ID, Prog IF, Subclass, Class Code (Offset 0x08)
    
    mov ch, 08h
    
    call Hexagon.Dev.PCI.readConfigDword
    
    mov byte[edi + Hexagon.PCI.Device.revision], al
    
    shr eax, 8
    
    mov byte[edi + Hexagon.PCI.Device.progIF], al
    
    shr eax, 8
    
    mov byte[edi + Hexagon.PCI.Device.subclass], al
    
    shr eax, 8
    
    mov byte[edi + Hexagon.PCI.Device.classCode], al

;; Read Header Type (Offset 0x0C)
    
    mov ch, 0Ch
    
    call Hexagon.Dev.PCI.readConfigDword
    
    shr eax, 16
    
    mov byte[edi + Hexagon.PCI.Device.headerType], al

;; Read BAR0..BAR5 (Offsets 0x10, 0x14, 0x18, 0x1C, 0x20, 0x24)
    
    mov ch, 10h
    
    call Hexagon.Dev.PCI.readConfigDword
    
    mov dword[edi + Hexagon.PCI.Device.bar0], eax

    mov ch, 14h
    
    call Hexagon.Dev.PCI.readConfigDword
    
    mov dword[edi + Hexagon.PCI.Device.bar1], eax

    mov ch, 18h
    
    call Hexagon.Dev.PCI.readConfigDword
    
    mov dword[edi + Hexagon.PCI.Device.bar2], eax

    mov ch, 1Ch
    
    call Hexagon.Dev.PCI.readConfigDword
    
    mov dword[edi + Hexagon.PCI.Device.bar3], eax

    mov ch, 20h
    
    call Hexagon.Dev.PCI.readConfigDword
    
    mov dword[edi + Hexagon.PCI.Device.bar4], eax

    mov ch, 24h
    
    call Hexagon.Dev.PCI.readConfigDword
    
    mov dword[edi + Hexagon.PCI.Device.bar5], eax

;; Read Interrupt Line & PIN (Offset 0x3C)
    
    mov ch, 3Ch
    
    call Hexagon.Dev.PCI.readConfigDword
    
    mov byte[edi + Hexagon.PCI.Device.irqLine], al
    
    shr eax, 8
    
    mov byte[edi + Hexagon.PCI.Device.irqPin], al

    mov byte[edi + Hexagon.PCI.Device.valid], 1

    inc dword[Hexagon.PCI.devicesCount]

.tableFull:

    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax

    ret

;;************************************************************************************

;; Finds a registered PCI device by Class Code, Subclass, and Prog IF
;;
;; Input:
;;   AH = Class Code, such as 01h for Mass Storage
;;   AL = Subclass, such as 06h for SATA or 01h for IDE
;;   BL = Prog IF, such as 01h for AHCI, or 0FFh for any Prog IF
;;
;; Output:
;;   ESI = Pointer to Hexagon.PCI.Device struct
;;   CF  = 0 if found, 1 if not found

Hexagon.Dev.PCI.findDevice:

    push eax
    push ebx
    push ecx
    push edx

    mov ecx, dword[Hexagon.PCI.devicesCount]

    cmp ecx, 0
    je .notFound

    mov esi, Hexagon.PCI.devicesTable

.searchLoop:

    cmp byte[esi + Hexagon.PCI.Device.valid], 1
    jne .next

;; Check Class Code
    
    cmp byte[esi + Hexagon.PCI.Device.classCode], ah
    jne .next

;; Check Subclass
    
    cmp byte[esi + Hexagon.PCI.Device.subclass], al
    jne .next

;; Check Prog IF (if not 0xFF wildcard)
    
    cmp bl, 0FFh
    je .found

    cmp byte[esi + Hexagon.PCI.Device.progIF], bl
    je .found

.next:

    add esi, Hexagon.PCI.Device.size
    
    dec ecx
    
    jnz .searchLoop

.notFound:

    pop edx
    pop ecx
    pop ebx
    pop eax

    xor esi, esi
    
    stc

    ret

.found:

    pop edx
    pop ecx
    pop ebx
    pop eax

    clc

    ret

;;************************************************************************************

;; Enables Bus Master and Memory Space access for a given PCI device
;;
;; Input:
;;   ESI = Pointer to Hexagon.PCI.Device struct

Hexagon.Dev.PCI.enableBusMaster:

    push eax
    push ebx
    push ecx
    push edx

    mov bl, byte[esi + Hexagon.PCI.Device.bus]
    mov bh, byte[esi + Hexagon.PCI.Device.device]
    mov cl, byte[esi + Hexagon.PCI.Device.function]
    mov ch, 04h ;; Command Register (Offset 0x04)

    mov eax, 00000007h  ;; Enable I/O (bit 0), Memory (bit 1), Bus Master (bit 2)
    
    call Hexagon.Dev.PCI.writeConfigDword

;; Read back Command register
    
    mov ch, 04h
    
    call Hexagon.Dev.PCI.readConfigWord

    mov edi, .logValue

    push ecx
    
    mov ecx, 4

.nibbleLoop:
    
    rol ax, 4
    
    mov dl, al
    
    and dl, 0Fh
    
    cmp dl, 10
    jb .digit
    
    add dl, 'A' - 10
    
    jmp .store

.digit:
    
    add dl, '0'

.store:
    
    mov byte[edi], dl
    
    inc edi
    
    loop .nibbleLoop
    
    pop ecx

    push esi
    
    mov esi, .logTemplate
    mov ebx, Hexagon.Dmesg.Priorities.p4
    
    call Hexagon.Kern.Dmesg.createMessage
    
    pop esi

    pop edx
    pop ecx
    pop ebx
    pop eax

    ret

.logTemplate: db "PCI: Command register = "
.logValue:    db "XXXX", 0

;;************************************************************************************

;; Logs all discovered PCI devices to kernel log buffer and serial (Priority 4)

Hexagon.Dev.PCI.logDevices:

    pushad

    mov ecx, dword[Hexagon.PCI.devicesCount]
    
    cmp ecx, 0
    je .done

    mov esi, Hexagon.PCI.devicesTable

.logLoop:

    push ecx
    push esi

    mov edi, .deviceLogBuffer

;; Prefix "PCI: "
    
    mov dword[edi], "PCI:"
    mov byte[edi + 4], " "
    
    add edi, 5

;; Bus (hex byte)
    
    mov al, byte[esi + Hexagon.PCI.Device.bus]
    
    call .appendHexByte

    mov byte[edi], ":"
    
    inc edi

;; Device (hex byte)
    
    mov al, byte[esi + Hexagon.PCI.Device.device]
    
    call .appendHexByte

    mov byte[edi], "."
    
    inc edi

;; Function (single hex char)
    
    mov al, byte[esi + Hexagon.PCI.Device.function]
    
    call .appendHexNibble

;; " [Class "
    
    mov dword[edi], " [cl"
    mov dword[edi + 4], "ass "
    
    add edi, 8

;; Class Code
    
    mov al, byte[esi + Hexagon.PCI.Device.classCode]
    
    call .appendHexByte

    mov byte[edi], ":"
    
    inc edi

;; Subclass
    
    mov al, byte[esi + Hexagon.PCI.Device.subclass]
    
    call .appendHexByte

    mov byte[edi], ":"
    
    inc edi

;; Prog IF
    
    mov al, byte[esi + Hexagon.PCI.Device.progIF]
    
    call .appendHexByte

;; "] Vendor "
    
    mov dword[edi], "] ve"
    mov dword[edi + 4], "ndor"
    mov byte[edi + 8], " "
    
    add edi, 9

;; Vendor ID (word)
    
    mov ax, word[esi + Hexagon.PCI.Device.vendorId]
    
    call .appendHexWord

;; " Device "
    
    mov dword[edi], " dev"
    mov dword[edi + 4], "ice "
    
    add edi, 8

;; Device ID (word)
    
    mov ax, word[esi + Hexagon.PCI.Device.deviceId]
    
    call .appendHexWord

;; NUL terminator
    
    mov byte[edi], 0

;; Log to dmesg buffer and serial with Priority 4 (p4)
    
    mov esi, .deviceLogBuffer
    mov ebx, Hexagon.Dmesg.Priorities.p4
    
    call Hexagon.Kern.Dmesg.createMessage

    pop esi
    pop ecx

    add esi, Hexagon.PCI.Device.size
    
    dec ecx
    
    jnz .logLoop

.done:

    popad
    
    ret

.appendHexNibble:
    
    push eax
    
    and al, 0Fh
    
    cmp al, 10
    jb .nibbleDigit
    
    add al, 'A' - 10
    
    jmp .nibbleStore

.nibbleDigit:
    
    add al, '0'

.nibbleStore:
    
    mov byte[edi], al
    
    inc edi
    
    pop eax
    
    ret

.appendHexByte:
    
    push eax
    
    shr al, 4
    
    call .appendHexNibble
    
    pop eax
    
    call .appendHexNibble
    
    ret

.appendHexWord:
    
    push eax
    
    mov al, ah
    
    call .appendHexByte
    
    pop eax
    
    call .appendHexByte
    
    ret

.deviceLogBuffer: times 80 db 0

;;************************************************************************************

;; PCI subsystem initialization
;;
;; Initializes PCI device table and scans for all attached devices.

Hexagon.Dev.PCI.setupPCI:

    call Hexagon.Dev.PCI.scanBus
    call Hexagon.Dev.PCI.logDevices

    ret
