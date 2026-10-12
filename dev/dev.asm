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

.hd0: ;; First hard drive
db "hd0", 0
.hd1: ;; Second hard drive
db "hd1", 0
.hd2: ;; Third hard drive
db "hd2", 0
.hd3: ;; Fourth hard drive
db "hd3", 0

;; Serial ports

.com1: ;; First serial port
db "com1", 0
.com2: ;; Second serial port
db "com2", 0
.com3:  ;; Third serial port
db "com3", 0
.com4: ;; Fourth serial port
db "com4", 0

;; Parallel ports

.lpt0: ;; First parallel port
db "lpt0", 0
.lpt1: ;; Second parallel port
db "lpt1", 0
.lpt2: ;; Third parallel port
db "lpt2", 0

;; Console

.tty: ;; Whatever VT the calling process already has, like Unix's /dev/tty
db "tty", 0
.tty0: ;; Main console
db "tty0", 0
.tty1: ;; VT1
db "tty1", 0
.tty2: ;; VT2
db "tty2", 0
.tty3: ;; VT3
db "tty3", 0
.tty4: ;; VT4
db "tty4", 0
.tty5: ;; VT5
db "tty5", 0
.tty6: ;; VT6
db "tty6", 0
.tty7: ;; VT7
db "tty7", 0

.au0: ;; Internal speaker
db "au0", 0

;; Input devices

.mouse0: ;; Mouse connected to the computer
db "mouse0", 0
.kbd0: ;; Keyboard connected to the computer
db "kbd0", 0

;; Processors:

.cpu0: ;; Main processor
db "cpu0", 0

Hexagon.Dev.DeviceClasses:

.block:    db 01h
.serial:   db 02h
.parallel: db 03h
.output:   db 04h
.proc:     db 05h

;;************************************************************************************

;; Devices registered by their own driver as they're attached, exposing
;; them under /dev.
;;
;; malloc'd (Hexagon.Dev.Registry.base, filled by allocateRegistry). Below
;; is only the field layout, every access goes through .base

virtual at 0

Hexagon.Dev.Registry.names:
times Hexagon.Dev.Registry.limit * 8 db 0

;; Hexagon.Dev.DeviceClasses value. For .block, .major/.minor below
;; identify the disk slot and partition index. Every other type leaves
;; them at 0, unused so far

Hexagon.Dev.Registry.types:
times Hexagon.Dev.Registry.limit db 0

;; Disk slot (0-3, Hexagon.Disks.Table's own index), valid for .block entries

Hexagon.Dev.Registry.majors:
times Hexagon.Dev.Registry.limit db 0

;; Partition index (0-3), or 0FFh for "no explicit partition, use the
;; first supported one", valid for .block entries

Hexagon.Dev.Registry.minors:
times Hexagon.Dev.Registry.limit db 0

Hexagon.Dev.Registry.byteSize = $

Hexagon.Dev.Registry.limit = 40

end virtual

Hexagon.Dev.Registry.base:  dd 0
Hexagon.Dev.Registry.count: dd 0

;;************************************************************************************

;; Allocates Hexagon.Dev.Registry and points .base at it. Must run once at
;; boot, after Hexagon.Arch.Mm.initMemory and before any driver tries
;; to register a device
;;
;; Output: empty

Hexagon.Kernel.Dev.Dev.allocateRegistry:

    pushad

    mov ebx, Hexagon.Dev.Registry.byteSize

    call Hexagon.Arch.Mm.malloc


    mov dword[Hexagon.Dev.Registry.base], ebx

    popad

    ret

;;************************************************************************************

;; Calls every built-in device's own registerDevices, right after
;; Hexagon.Kernel.Dev.Dev.allocateRegistry and before any driver's own
;; hardware setup runs. Registration only needs the registry table to
;; exist, not the underlying hardware to already be configured, so it is
;; kept separate from (and earlier than) each driver's own setup flow

Hexagon.Kernel.Dev.Dev.registerDevices:

    call Hexagon.Kernel.Dev.CPU.CPU.registerDevices
    call Hexagon.Kernel.Dev.Console.Console.registerDevices
    call Hexagon.Kernel.Dev.Snd.Snd.registerDevices
    call Hexagon.Kernel.Dev.Serial.Serial.registerDevices

    ret

;;************************************************************************************

;; Registers a device by name, so it can be listed under /dev. Kernel
;; internal, not a syscall: every caller is already device or driver
;; initialization code. Reregistering an existing name is a no-op
;;
;; Input:
;;
;; ESI - Device name (NUL terminated, same convention as Hexagon.Dev.Devices)
;; AL  - Hexagon.Dev.DeviceClasses value
;; BL  - Major (disk slot, for .block entries, 0 otherwise)
;; CL  - Minor (partition index, for .block entries, 0 otherwise)

Hexagon.Kernel.Dev.Dev.registerDevice:

;; Stashed here before anything below reuses EAX/ECX for its own purposes

    mov byte[.newType], al
    mov byte[.newMajor], bl
    mov byte[.newMinor], cl

    push eax
    push ecx
    push edx
    push edi
    push es

;; stosb below is hardwired to ES:EDI, and ES may be the kernel linear
;; segment this deep into a call chain, and not kernel data

    mov ax, 10h
    mov es, ax

    xor ecx, ecx

.checkLoop:

    cmp ecx, dword[Hexagon.Dev.Registry.count]
    jae .add

    mov edi, dword[Hexagon.Dev.Registry.base]

    imul edx, ecx, 8

    add edi, edx

    call Hexagon.Libkern.String.compareWordsInString

    jc .done

    inc ecx

    jmp .checkLoop

.add:

    cmp ecx, Hexagon.Dev.Registry.limit
    jae .done ;; Table full, best effort

    mov edi, dword[Hexagon.Dev.Registry.base]

    imul edx, ecx, 8

    add edi, edx

.copyLoop:

    lodsb

    stosb

    cmp al, 0
    jne .copyLoop

    mov edi, dword[Hexagon.Dev.Registry.base]
    
    add edi, Hexagon.Dev.Registry.types
    add edi, ecx

    mov al, byte[.newType]
    
    stosb

    mov edi, dword[Hexagon.Dev.Registry.base]
    
    add edi, Hexagon.Dev.Registry.majors
    add edi, ecx

    mov al, byte[.newMajor]
    
    stosb

    mov edi, dword[Hexagon.Dev.Registry.base]
    
    add edi, Hexagon.Dev.Registry.minors
    add edi, ecx

    mov al, byte[.newMinor]
    
    stosb

    inc dword[Hexagon.Dev.Registry.count]

.done:

    pop es
    pop edi
    pop edx
    pop ecx
    pop eax

    ret

.newType:  db 0
.newMajor: db 0
.newMinor: db 0

;;************************************************************************************

;; Dispatch table for the five device classes in Hexagon.Dev.DeviceClasses.
;; attach runs once, at boot. open/read/write/close/ioctl run per caller

Hexagon.Dev.Switch.attach  = 0
Hexagon.Dev.Switch.open    = 4
Hexagon.Dev.Switch.read    = 8
Hexagon.Dev.Switch.write   = 12
Hexagon.Dev.Switch.close   = 16
Hexagon.Dev.Switch.ioctl   = 20
Hexagon.Dev.Switch.rowSize = 24

Hexagon.Dev.Switch:

dd Hexagon.Kernel.Dev.Dev.Switch.Block.attach
dd Hexagon.Kernel.Dev.Dev.Switch.Block.open
dd Hexagon.Kernel.Dev.Dev.Switch.Block.read
dd Hexagon.Kernel.Dev.Dev.Switch.Block.write
dd Hexagon.Kernel.Dev.Dev.Switch.Block.close
dd Hexagon.Kernel.Dev.Dev.Switch.notSupportedIoctl

dd Hexagon.Kernel.Dev.Dev.Switch.Serial.attach
dd Hexagon.Kernel.Dev.Dev.Switch.Serial.open
dd Hexagon.Kernel.Dev.Dev.Switch.Serial.read
dd Hexagon.Kernel.Dev.Dev.Switch.Serial.write
dd Hexagon.Kernel.Dev.Dev.Switch.Serial.close
dd Hexagon.Kernel.Dev.Dev.Switch.notSupportedIoctl

dd Hexagon.Kernel.Dev.Dev.Switch.Parallel.attach
dd Hexagon.Kernel.Dev.Dev.Switch.Parallel.open
dd Hexagon.Kernel.Dev.Dev.Switch.Parallel.read
dd Hexagon.Kernel.Dev.Dev.Switch.Parallel.write
dd Hexagon.Kernel.Dev.Dev.Switch.Parallel.close
dd Hexagon.Kernel.Dev.Dev.Switch.notSupportedIoctl

dd Hexagon.Kernel.Dev.Dev.Switch.Output.attach
dd Hexagon.Kernel.Dev.Dev.Switch.Output.open
dd Hexagon.Kernel.Dev.Dev.Switch.Output.read
dd Hexagon.Kernel.Dev.Dev.Switch.Output.write
dd Hexagon.Kernel.Dev.Dev.Switch.Output.close
dd Hexagon.Kernel.Dev.Dev.Switch.Output.ioctl

dd Hexagon.Kernel.Dev.Dev.Switch.Proc.attach
dd Hexagon.Kernel.Dev.Dev.Switch.Proc.open
dd Hexagon.Kernel.Dev.Dev.Switch.Proc.read
dd Hexagon.Kernel.Dev.Dev.Switch.Proc.write
dd Hexagon.Kernel.Dev.Dev.Switch.Proc.close
dd Hexagon.Kernel.Dev.Dev.Switch.notSupportedIoctl

;; Shared "not supported" stub for every class's ioctl slot besides output

Hexagon.Kernel.Dev.Dev.Switch.notSupportedIoctl:

    stc

    ret

;;************************************************************************************

;; A disk's own geometry is read fresh on every mount, so the block class
;; needs no one-time hardware setup

Hexagon.Kernel.Dev.Dev.Switch.Block.attach:

    ret

;; A physical port isn't known to have anything connected until the first
;; open, so setup happens there instead of here, guarded to run once. com1
;; is the one port known at boot, since debug logging depends on it

Hexagon.Kernel.Dev.Dev.Switch.Serial.attach:

    call Hexagon.Kernel.Dev.Serial.Serial.setupCOM1

    mov byte[Hexagon.Dev.Switch.Serial.initializedCom1], 1

    ret

;; Same reasoning as Hexagon.Kernel.Dev.Dev.Switch.Serial.attach, but no
;; parallel port is known to exist at boot

Hexagon.Kernel.Dev.Dev.Switch.Parallel.attach:

    ret

Hexagon.Kernel.Dev.Dev.Switch.Output.attach:

    call Hexagon.Kernel.Dev.Console.Console.setupConsole

    ret

Hexagon.Kernel.Dev.Dev.Switch.Proc.attach:

    ret

;;************************************************************************************

;; Closes communication with a device, dispatching to the open class's own
;; close handler first, while Hexagon.Dev.Control.deviceClass still names it

Hexagon.Kernel.Dev.Dev.close:

    movzx eax, byte[Hexagon.Dev.Control.deviceClass]

    cmp eax, 1
    jb .noClass

    cmp eax, 5
    ja .noClass

    dec eax
    
    imul eax, eax, Hexagon.Dev.Switch.rowSize
    
    add eax, Hexagon.Dev.Switch.close
    add eax, Hexagon.Dev.Switch

    call dword[eax]

.noClass:

    mov byte[Hexagon.Dev.Control.isOpen], 0
    mov word[Hexagon.Dev.Control.deviceClass], 0
    mov byte[Hexagon.Dev.Control.deviceId], 00h

    ret

;;************************************************************************************

Hexagon.Kernel.Dev.Dev.Switch.Block.close:

    ret

Hexagon.Kernel.Dev.Dev.Switch.Serial.close:

    ret

Hexagon.Kernel.Dev.Dev.Switch.Parallel.close:

    ret

;; The internal speaker is the only output device that needs anything done
;; on close

Hexagon.Kernel.Dev.Dev.Switch.Output.close:

    push ebx

    mov bx, word[Hexagon.Dev.Control.deviceId]

    cmp bx, word[Hexagon.Dev.deviceCodes.au0]
    jne .done

    call Hexagon.Kernel.Dev.Snd.Snd.stopSound

.done:

    pop ebx

    ret

Hexagon.Kernel.Dev.Dev.Switch.Proc.close:

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

    movzx eax, byte[Hexagon.Dev.Control.deviceClass]

    cmp eax, 1
    jb .invalidClass

    cmp eax, 5
    ja .invalidClass

    dec eax
    imul eax, eax, Hexagon.Dev.Switch.rowSize
    add eax, Hexagon.Dev.Switch.write
    add eax, Hexagon.Dev.Switch

    jmp dword[eax] ;; The class handler pops eax/esi itself and returns straight to write's own caller

.invalidClass:

    pop esi
    pop eax

    stc

    ret

.deviceNotOpen:

    stc

    ret

;;************************************************************************************

;; Disk writes aren't supported through this generic channel. A mounted
;; filesystem talks to the block driver directly

Hexagon.Kernel.Dev.Dev.Switch.Block.write:

    pop esi
    pop eax

    call Hexagon.Kernel.Dev.Dev.close

    ret

Hexagon.Kernel.Dev.Dev.Switch.Serial.write:

    pop esi
    pop eax

    call Hexagon.Kernel.Dev.Serial.Serial.sendViaSerial

    jc .error

    call Hexagon.Kernel.Dev.Dev.close

    ret

.error:

    call Hexagon.Kernel.Dev.Dev.close

    stc

    ret

Hexagon.Kernel.Dev.Dev.Switch.Parallel.write:

    pop esi
    pop eax

    call Hexagon.Kernel.Dev.LPT.LPT.sendViaParallelPort

    jc .error

    call Hexagon.Kernel.Dev.Dev.close

    ret

.error:

    call Hexagon.Kernel.Dev.Dev.close

    stc

    ret

Hexagon.Kernel.Dev.Dev.Switch.Output.write:

    pop esi
    pop eax

    mov bx, word[Hexagon.Dev.Control.deviceId]

    cmp word[Hexagon.Dev.deviceCodes.au0], bx
    je .au0

    call Hexagon.Kernel.Dev.Dev.close

    ret

.au0:

    call Hexagon.Kernel.Dev.Snd.Snd.playSound

    ret

Hexagon.Kernel.Dev.Dev.Switch.Proc.write:

    pop esi
    pop eax

    call Hexagon.Kernel.Dev.Dev.close

    ret

;;************************************************************************************

;; Reads data from the currently open device into a caller-supplied buffer.
;; No class has a real byte-stream source wired up yet, so every class
;; reports "not supported" for now, the same clean failure a caller gets
;; for a class that doesn't exist at all
;;
;; Input:
;;
;; EDI - Buffer to receive the data
;; ECX - Maximum bytes to read
;;
;; Output:
;;
;; EAX - Bytes actually read
;; CF set if nothing is open, or the open device's class has no reader

Hexagon.Kernel.Dev.Dev.read:

    cmp byte[Hexagon.Dev.Control.isOpen], 0
    je .deviceNotOpen

    movzx eax, byte[Hexagon.Dev.Control.deviceClass]

    cmp eax, 1
    jb .deviceNotOpen

    cmp eax, 5
    ja .deviceNotOpen

    dec eax
   
    imul eax, eax, Hexagon.Dev.Switch.rowSize
   
    add eax, Hexagon.Dev.Switch.read
    add eax, Hexagon.Dev.Switch

    jmp dword[eax]

.deviceNotOpen:

    xor eax, eax

    stc

    ret

;;************************************************************************************

;; Device-specific control that doesn't fit read/write's byte-stream shape,
;; dispatched to the open device's own class handler
;;
;; Input:
;;
;; EBX - Command
;; ECX - Argument for the command
;;
;; Output:
;;
;; CF set if nothing is open, or the class has no handler for this command

Hexagon.Kernel.Dev.Dev.ioctl:

    cmp byte[Hexagon.Dev.Control.isOpen], 0
    je .deviceNotOpen

    movzx eax, byte[Hexagon.Dev.Control.deviceClass]

    cmp eax, 1
    jb .deviceNotOpen

    cmp eax, 5
    ja .deviceNotOpen

    dec eax
    
    imul eax, eax, Hexagon.Dev.Switch.rowSize
    
    add eax, Hexagon.Dev.Switch.ioctl
    add eax, Hexagon.Dev.Switch

    jmp dword[eax]

.deviceNotOpen:

    stc

    ret

;;************************************************************************************

Hexagon.Kernel.Dev.Dev.Switch.Block.read:

    xor eax, eax

    stc

    ret

Hexagon.Kernel.Dev.Dev.Switch.Serial.read:

    xor eax, eax

    stc

    ret

Hexagon.Kernel.Dev.Dev.Switch.Parallel.read:

    xor eax, eax

    stc

    ret

Hexagon.Kernel.Dev.Dev.Switch.Output.read:

    xor eax, eax

    stc

    ret

Hexagon.Kernel.Dev.Dev.Switch.Proc.read:

    xor eax, eax

    stc

    ret

;;************************************************************************************

;; hx.open's own syscall entry. The file-opening path underneath this runs
;; Hexagon.Kernel.FS.VFS.resolveMount, which answers with ESI on a buffer inside
;; the kernel image, and hexagonHandler translates ESI on the way back out, so a
;; caller at user level would be handed an address it cannot read a byte of
;;
;; Input/output: as Hexagon.Kernel.Dev.Dev.open, ESI aside

Hexagon.Kernel.Dev.Dev.openSyscall:

    push esi

;; A file's bytes land at the caller's own EDI, at CPL 0, and a file larger
;; than that buffer would be copied straight past it. ECX bounds the range to
;; check when the caller named a cap, and the file's size has to be asked for
;; when it did not. A device is left alone, its EDI being no such buffer

    push eax
    push ebx
    push ecx
    push edi

    cmp ecx, 0

    jne .checkRange

    push esi

    call Hexagon.Kernel.FS.VFS.fileExists ;; EAX = size, EBX = device class, CF = nothing there

    pop esi

    jc .withoutCheck

    cmp ebx, 0

    jne .withoutCheck ;; A device node, not a file being loaded

    mov ecx, eax

.checkRange:

    mov ebx, edi

    call Hexagon.Arch.Paging.rangeIsCallerWritable

    jc .badBuffer

.withoutCheck:

    pop edi
    pop ecx
    pop ebx
    pop eax

    call Hexagon.Kernel.Dev.Dev.open

    pop esi

    ret

.badBuffer:

    pop edi
    pop ecx
    pop ebx
    pop eax

    pop esi

    mov eax, Hexagon.Kern.Proc.badAddress

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
;; ECX - Byte cap on a file read, 0 for the whole file. Honored by
;;       Hexagon.Kernel.FS.FAT16.loadFileFAT16B underneath the file-opening
;;       path, so every caller sets it: 0 as it has always been, or a real cap
;;       when the caller only needs a file's first bytes and should not have
;;       to size a buffer for the whole thing. That buffer has to hold one
;;       byte more than the cap, for the terminator behind the data
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

;; A devfs entry with no open() support, such as a disk
;; partition node. Falling through to .file here would send this same
;; name back into Hexagon.Kernel.FS.VFS.openFile, which resolves straight
;; back into devfs and calls this routine again, recursing forever

    cmp byte[Hexagon.Dev.Control.file], 2
    je .notSupportedDevice

;; If not, proceed with opening a device

    mov byte[Hexagon.Dev.Control.deviceClass], dl

;; EBP, not EAX, computes the jump target, since the class handler needs
;; AH/ECX intact. EBP itself is saved here and restored before the jump,
;; since open's own caller may rely on it surviving the call

    mov dword[.savedEBP], ebp

    movzx ebp, dl

    cmp ebp, 1
    jb .invalidClass

    cmp ebp, 5
    ja .invalidClass

    dec ebp
    
    imul ebp, ebp, Hexagon.Dev.Switch.rowSize
    
    add ebp, Hexagon.Dev.Switch.open
    add ebp, Hexagon.Dev.Switch

;; EBP used bare as a base register addresses through SS, not DS, so the
;; segment must be forced explicitly to reach this DS-relative table

    mov ebp, dword[ds:ebp] ;; EBP now holds the class handler's real address
    mov dword[.handlerAddress], ebp

    mov ebp, dword[.savedEBP]

    jmp dword[.handlerAddress] ;; The class handler pops bx itself and returns straight to open's own caller

.invalidClass:

    mov ebp, dword[.savedEBP]

    pop bx

    stc

    ret

.savedEBP:       dd 0
.handlerAddress: dd 0

.file:

    pop bx

    mov byte[Hexagon.Dev.Control.file], 0

    call Hexagon.Kernel.FS.VFS.openFile

    ret

;; Same "not supported on DEVFS" code Hexagon.Kernel.FS.VFS.createFile and
;; friends already return for their own unsupported DEVFS operations

.notSupportedDevice:

    pop bx

    mov byte[Hexagon.Dev.Control.file], 0

    mov eax, 200h ;; VFS.invalidFS, lib/fasm/errors.s

    stc

    ret

;;************************************************************************************

;; Opening a disk by name never parses its filesystem, the same way opening
;; a raw block special file in BSD does not. Only mount() does that,
;; talking to the block driver directly
;;
;; Output:
;;
;; EAX - Generic Error Code/User Permission

Hexagon.Kernel.Dev.Dev.Switch.Block.open:

    pop bx

    clc

    cmp dword[kernelExecute], kernelExecutePermission
    je .storageAuthenticated

.storageVerifyPermissions:

    call Hexagon.Kern.Users.getUserPermissions

    cmp eax, 03h ;; Group code for standard user
    je .storagePermissionDenied

.storageAuthenticated:

    mov byte[Hexagon.Dev.Control.isOpen], 1

    mov eax, dword[Hexagon.Dev.Control.deviceClass]

;; The permission check above falls through here via a cmp whose own
;; result (comparing a passing group code against the denied one) is not
;; itself the outcome being reported, so CF needs restating explicitly

    clc

    ret

.storagePermissionDenied:

    mov eax, 05h

    stc

    ret

;;************************************************************************************

Hexagon.Kernel.Dev.Dev.Switch.Serial.open:

    pop bx

    mov word[Hexagon.Kernel.Dev.Serial.Serial.Ports.currentSerialPort], bx

;; Real hardware setup only needs to happen once per port, not on every
;; open. com1 is already set up by Hexagon.Kernel.Dev.Dev.Switch.Serial.attach

    cmp bx, word[Hexagon.Dev.deviceCodes.com1]
    je .checkCom1

    cmp bx, word[Hexagon.Dev.deviceCodes.com2]
    je .checkCom2

    cmp bx, word[Hexagon.Dev.deviceCodes.com3]
    je .checkCom3

    cmp bx, word[Hexagon.Dev.deviceCodes.com4]
    je .checkCom4

    jmp .setup

.checkCom1:

    cmp byte[Hexagon.Dev.Switch.Serial.initializedCom1], 0
    jne .skipSetup

    mov byte[Hexagon.Dev.Switch.Serial.initializedCom1], 1

    jmp .setup

.checkCom2:

    cmp byte[Hexagon.Dev.Switch.Serial.initializedCom2], 0
    jne .skipSetup

    mov byte[Hexagon.Dev.Switch.Serial.initializedCom2], 1

    jmp .setup

.checkCom3:

    cmp byte[Hexagon.Dev.Switch.Serial.initializedCom3], 0
    jne .skipSetup

    mov byte[Hexagon.Dev.Switch.Serial.initializedCom3], 1

    jmp .setup

.checkCom4:

    cmp byte[Hexagon.Dev.Switch.Serial.initializedCom4], 0
    jne .skipSetup

    mov byte[Hexagon.Dev.Switch.Serial.initializedCom4], 1

.setup:

    call Hexagon.Kernel.Dev.Serial.Serial.setupSerialPort

    jc .openingError

.skipSetup:

    mov byte[Hexagon.Dev.Control.isOpen], 1

;; Only registered here, on a successful open, since there's no way to
;; know up front which serial ports actually have something connected

    mov ax, bx
    mov dl, byte[Hexagon.Dev.Control.deviceClass]

    call Hexagon.Kernel.Dev.Dev.convertDeviceToDeviceName

    mov al, dl
    mov bl, 0
    mov cl, 0

    call Hexagon.Kernel.Dev.Dev.registerDevice

    mov eax, dword[Hexagon.Dev.Control.deviceClass]

;; Hexagon.Kernel.Dev.Dev.registerDevice reports on its internal name
;; dedup through CF, a signal this open() call has no business forwarding
;; to its own caller

    clc

    ret

.openingError:

    mov byte[Hexagon.Dev.Control.isOpen], 0
    mov eax, dword[Hexagon.Dev.Control.deviceClass]

    ret

Hexagon.Dev.Switch.Serial.initializedCom1: db 0
Hexagon.Dev.Switch.Serial.initializedCom2: db 0
Hexagon.Dev.Switch.Serial.initializedCom3: db 0
Hexagon.Dev.Switch.Serial.initializedCom4: db 0

;;************************************************************************************

Hexagon.Kernel.Dev.Dev.Switch.Parallel.open:

    pop bx

    mov word[Hexagon.Kernel.Dev.LPT.LPT.currentParallelPort], bx

;; Same once-per-port reasoning as Hexagon.Kernel.Dev.Dev.Switch.Serial.open

    cmp bx, word[Hexagon.Dev.deviceCodes.lpt0]
    je .checkLpt0

    cmp bx, word[Hexagon.Dev.deviceCodes.lpt1]
    je .checkLpt1

    cmp bx, word[Hexagon.Dev.deviceCodes.lpt2]
    je .checkLpt2

    jmp .setup

.checkLpt0:

    cmp byte[Hexagon.Dev.Switch.Parallel.initializedLpt0], 0
    jne .skipSetup

    mov byte[Hexagon.Dev.Switch.Parallel.initializedLpt0], 1

    jmp .setup

.checkLpt1:

    cmp byte[Hexagon.Dev.Switch.Parallel.initializedLpt1], 0
    jne .skipSetup

    mov byte[Hexagon.Dev.Switch.Parallel.initializedLpt1], 1

    jmp .setup

.checkLpt2:

    cmp byte[Hexagon.Dev.Switch.Parallel.initializedLpt2], 0
    jne .skipSetup

    mov byte[Hexagon.Dev.Switch.Parallel.initializedLpt2], 1

.setup:

    call Hexagon.Kernel.Dev.LPT.LPT.setupParallelPort

    jc .openingError

.skipSetup:

    mov byte[Hexagon.Dev.Control.isOpen], 1

;; Only registered here, on a successful open, same reasoning as the
;; serial ports above

    mov ax, bx
    mov dl, byte[Hexagon.Dev.Control.deviceClass]

    call Hexagon.Kernel.Dev.Dev.convertDeviceToDeviceName

    mov al, dl
    mov bl, 0
    mov cl, 0

    call Hexagon.Kernel.Dev.Dev.registerDevice

    mov eax, dword[Hexagon.Dev.Control.deviceClass]

;; Hexagon.Kernel.Dev.Dev.registerDevice reports on its internal name
;; dedup through CF, a signal this open() call has no business forwarding
;; to its own caller

    clc

    ret

.openingError:

    mov byte[Hexagon.Dev.Control.isOpen], 0
    mov eax, dword[Hexagon.Dev.Control.deviceClass]

    ret

Hexagon.Dev.Switch.Parallel.initializedLpt0: db 0
Hexagon.Dev.Switch.Parallel.initializedLpt1: db 0
Hexagon.Dev.Switch.Parallel.initializedLpt2: db 0

;;************************************************************************************

;; Opening a console has no side effects, the same as every other
;; class. Activating one is hx.ioctl command 1 and claiming it is command 3,
;; so merely opening a tty node cannot steal that VT from its owner

Hexagon.Kernel.Dev.Dev.Switch.Output.open:

    pop bx

    mov byte[Hexagon.Dev.Control.isOpen], 1

    clc

    mov eax, dword[Hexagon.Dev.Control.deviceClass]

    ret

;;************************************************************************************

;; Claims a VT: makes the caller its home VT and foreground owner, lazily
;; allocating its own buffer if needed (ordinary syscall context only, never
;; the keyboard ISR), and clears the target VT to the console's background
;; color so a freshly-claimed VT doesn't show stale content. tty0 is the one
;; exception to the clear, keeping its boot log on screen the way a real Unix
;; console does. Called from Output.ioctl command 3
;;
;; Input: ECX - target VT index (0-7)

Hexagon.Kernel.Dev.Dev.Switch.Output.claimVT:

    push ebx
    push edx

    movzx edx, byte[Hexagon.Scheduler.current]

;; This process's own VT up to now (often 0) may never have had a buffer
;; allocated either, and an ISR-driven Ctrl+Fn can never switch away from it
;; later: Hexagon.Kern.Services.keyboardHandler silently refuses to switch to
;; or from a VT that is not allocated

    push ecx

    mov ecx, dword[Hexagon.Processes.Table.tty + edx * 4]

    call Hexagon.Kernel.Dev.Dev.ensureVTBuffer

    pop ecx

    mov dword[Hexagon.Processes.Table.tty + edx * 4], ecx
    mov dword[Hexagon.Console.VT.foregroundSlot + ecx * 4], edx

    call Hexagon.Kernel.Dev.Dev.ensureVTBuffer ;; The target VT itself

;; Claiming a VT starts it from the console's background color, and not
;; whatever the last terminal on it left behind. The cursor position is one
;; value shared by every VT, so resetting it here would displace whatever
;; another VT draws next

    push ecx
    push esi

    cmp ecx, 0
    je .skipClear ;; tty0 keeps its boot/debug log visible, never cleared on claim

    mov esi, dword[Hexagon.Console.VT.buffer + ecx * 4]

    cmp esi, 0
    je .skipClear

    call Hexagon.Kernel.Dev.Console.Console.clearBufferToBackground

.skipClear:

    pop esi
    pop ecx

    pop edx
    pop ebx

    ret

;;************************************************************************************

;; Resolves Hexagon.Dev.Control.deviceId into a VT index, if it names one of
;; tty0..tty7
;;
;; Output: ECX - VT index (0-7), CF clear if resolved. CF set otherwise
;; (not a tty device at all), ECX unchanged

Hexagon.Kernel.Dev.Dev.Switch.Output.resolveTTYIndex:

    mov ax, word[Hexagon.Dev.Control.deviceId]

    cmp ax, word[Hexagon.Dev.deviceCodes.tty0]
    je .isTTY0
    
    cmp ax, word[Hexagon.Dev.deviceCodes.tty1]
    je .isTTY1
    
    cmp ax, word[Hexagon.Dev.deviceCodes.tty2]
    je .isTTY2
    
    cmp ax, word[Hexagon.Dev.deviceCodes.tty3]
    je .isTTY3
    
    cmp ax, word[Hexagon.Dev.deviceCodes.tty4]
    je .isTTY4
    
    cmp ax, word[Hexagon.Dev.deviceCodes.tty5]
    je .isTTY5
    
    cmp ax, word[Hexagon.Dev.deviceCodes.tty6]
    je .isTTY6
    
    cmp ax, word[Hexagon.Dev.deviceCodes.tty7]
    je .isTTY7

    stc

    ret

.isTTY0: 

    mov ecx, 0
    
    clc
    
    ret

.isTTY1:

    mov ecx, 1
    
    clc
    
    ret

.isTTY2: 
    
    mov ecx, 2
    
    clc
    
    ret

.isTTY3: 

    mov ecx, 3
    
    clc
    
    ret

.isTTY4: 

    mov ecx, 4
    
    clc
    
    ret

.isTTY5: 

    mov ecx, 5
    
    clc
    
    ret

.isTTY6: 

    mov ecx, 6
    
    clc
    
    ret

.isTTY7: 

    mov ecx, 7
    
    clc
    
    ret

;;************************************************************************************

;; Allocates and blanks Hexagon.Console.VT.buffer[ECX] when it is missing or
;; sized for an older resolution. Ordinary syscall context only, never the
;; keyboard ISR, since Mm.malloc must not run from there
;;
;; Input/Output: ECX - VT index, preserved

Hexagon.Kernel.Dev.Dev.ensureVTBuffer:

    push eax
    push ebx
    push edi

    cmp dword[Hexagon.Console.VT.buffer + ecx * 4], 0
    je .allocate

    mov eax, dword[Hexagon.Console.VT.bufferGeneration + ecx * 4]
    
    cmp eax, dword[Hexagon.Console.resolutionGeneration]
    je .ready ;; Already allocated, and still sized for the current resolution

.allocate:

    call Hexagon.Kernel.Dev.Console.Console.reallocateVTBuffer

    cmp eax, 0
    je .ready ;; Best effort: leave it 0, a later attempt can still allocate it

    mov edi, ebx

    call Hexagon.Kernel.Dev.Console.Console.blankBuffer

.ready:

    pop edi
    pop ebx
    pop eax

    ret

;;************************************************************************************

;; EBX - Command (1 = activate console, 2 = activate as foreground VT,
;;       3 = claim the open tty as the caller's own VT)
;; ECX - Argument for command 1 (console index: 0 main, 1 secondary).
;;       Commands 2 and 3 take no argument, the target VT is whichever
;;       tty device is currently open, resolved by Output.resolveTTYIndex

Hexagon.Kernel.Dev.Dev.Switch.Output.ioctl:

    cmp ebx, 1
    je .activateConsole

    cmp ebx, 2
    je .activateVT

    cmp ebx, 3
    je .claim

    stc

    ret

.claim:

    call Hexagon.Kernel.Dev.Dev.Switch.Output.resolveTTYIndex

    jc .end ;; The currently open device isn't a tty at all

    call Hexagon.Kernel.Dev.Dev.Switch.Output.claimVT

    clc

    ret

.activateVT:

    call Hexagon.Kernel.Dev.Dev.Switch.Output.resolveTTYIndex

    jc .end ;; The currently open device isn't a tty at all

    mov ebx, ecx

    call Hexagon.Kernel.Dev.Console.Console.switchVT

    clc

    ret

.end:

    stc

    ret

.activateConsole:

    cmp ecx, 0
    je .activateMain

    cmp ecx, 1
    je .activateSecondary

    stc

    ret

.activateMain:

    call Hexagon.Kernel.Dev.Console.Console.useMainConsole

    clc

    ret

.activateSecondary:

    call Hexagon.Kernel.Dev.Console.Console.useSecondaryConsole

    clc

    ret

;;************************************************************************************

Hexagon.Kernel.Dev.Dev.Switch.Proc.open:

    pop bx

    mov eax, dword[Hexagon.Dev.Control.deviceClass]

;; The processor name Hexagon.Arch.CPU.CPU.identifyProcessor read out of CPUID
;; at boot is copied into the buffer the caller opened the device with, since
;; it lives in kernel memory a caller at user level cannot read. EDI is
;; Hexagon.Kernel.Dev.Dev.open's own load address, unused by a device until now

    push esi
    push edi
    push es

    push ds
    pop es

    cld

    mov esi, Hexagon.Dev.deviceCodes.cpu0

.copyName:

    lodsb

    stosb

    cmp al, 0

    jne .copyName

    pop es
    pop edi
    pop esi

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
;; Hexagon.Dev.Control.file: 1 if ESI didn't match any device and may be a
;;       common file, 2 if it matched a Hexagon.Dev.Registry entry with no
;;       open() support (such as a disk partition node), 0 (left
;;       untouched) if AH/BX/DL/ECX above identify a real device to open

Hexagon.Kernel.Dev.Dev.convertDeviceNameToDevice:

    mov edi, Hexagon.Dev.Devices.hd0
    call Hexagon.Libkern.String.compareWordsInString
    jc .hd0

    mov edi, Hexagon.Dev.Devices.hd1
    call Hexagon.Libkern.String.compareWordsInString
    jc .hd1

    mov edi, Hexagon.Dev.Devices.hd2
    call Hexagon.Libkern.String.compareWordsInString
    jc .hd2

    mov edi, Hexagon.Dev.Devices.hd3
    call Hexagon.Libkern.String.compareWordsInString
    jc .hd3

    mov edi, Hexagon.Dev.Devices.com1
    call Hexagon.Libkern.String.compareWordsInString
    jc .com1

    mov edi, Hexagon.Dev.Devices.com2
    call Hexagon.Libkern.String.compareWordsInString
    jc .com2

    mov edi, Hexagon.Dev.Devices.com3
    call Hexagon.Libkern.String.compareWordsInString
    jc .com3

    mov edi, Hexagon.Dev.Devices.com4
    call Hexagon.Libkern.String.compareWordsInString
    jc .com4

    mov edi, Hexagon.Dev.Devices.lpt0
    call Hexagon.Libkern.String.compareWordsInString
    jc .lpt0

    mov edi, Hexagon.Dev.Devices.lpt1
    call Hexagon.Libkern.String.compareWordsInString
    jc .lpt1

    mov edi, Hexagon.Dev.Devices.lpt2
    call Hexagon.Libkern.String.compareWordsInString
    jc .lpt2

    mov edi, Hexagon.Dev.Devices.tty
    call Hexagon.Libkern.String.compareWordsInString
    jc .tty

    mov edi, Hexagon.Dev.Devices.tty0
    call Hexagon.Libkern.String.compareWordsInString
    jc .tty0

    mov edi, Hexagon.Dev.Devices.tty1
    call Hexagon.Libkern.String.compareWordsInString
    jc .tty1

    mov edi, Hexagon.Dev.Devices.tty2
    call Hexagon.Libkern.String.compareWordsInString
    jc .tty2

    mov edi, Hexagon.Dev.Devices.tty3
    call Hexagon.Libkern.String.compareWordsInString
    jc .tty3

    mov edi, Hexagon.Dev.Devices.tty4
    call Hexagon.Libkern.String.compareWordsInString
    jc .tty4

    mov edi, Hexagon.Dev.Devices.tty5
    call Hexagon.Libkern.String.compareWordsInString
    jc .tty5

    mov edi, Hexagon.Dev.Devices.tty6
    call Hexagon.Libkern.String.compareWordsInString
    jc .tty6

    mov edi, Hexagon.Dev.Devices.tty7
    call Hexagon.Libkern.String.compareWordsInString
    jc .tty7

    mov edi,Hexagon.Dev.Devices.au0
    call Hexagon.Libkern.String.compareWordsInString
    jc .au0

    mov edi, Hexagon.Dev.Devices.mouse0
    call Hexagon.Libkern.String.compareWordsInString
    jc .mouse0

    mov edi, Hexagon.Dev.Devices.kbd0
    call Hexagon.Libkern.String.compareWordsInString
    jc .kbd0

    mov edi, Hexagon.Dev.Devices.cpu0
    call Hexagon.Libkern.String.compareWordsInString
    jc .cpu0

;; None of the fixed names above matched. Check Hexagon.Dev.Registry for a
;; dynamically registered entry, such as a disk partition node, before
;; falling through to the file case, which would recurse back here forever

    push ecx
    push edx
    push edi

    xor ecx, ecx

.registryLoop:

    cmp ecx, dword[Hexagon.Dev.Registry.count]
    jae .registryNotFound

    mov edi, dword[Hexagon.Dev.Registry.base]

    imul edx, ecx, 8

    add edi, edx

    call Hexagon.Libkern.String.compareWordsInString

    jc .registryFound

    inc ecx

    jmp .registryLoop

.registryFound:

    pop edi
    pop edx
    pop ecx

    mov byte[Hexagon.Dev.Control.file], 2 ;; Mark as a registered device with no open() support

    ret

.registryNotFound:

    pop edi
    pop edx
    pop ecx

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

.tty:

;; Bare "tty", meaning whatever VT the calling process already has, the
;; same as Unix's own /dev/tty resolves to the exact same deviceId and
;; class a request for the matching ttyN below would

    movzx ecx, byte[Hexagon.Scheduler.current]

    cmp ecx, 0xFF
    jne .callerVTKnown

    xor edx, edx ;; Kernel boot context has no slot: VT0

    jmp .haveCallerVT

.callerVTKnown:

    mov edx, dword[Hexagon.Processes.Table.tty + ecx * 4]

.haveCallerVT:

    mov ah, dl

    mov bx, word[Hexagon.Dev.deviceCodes.tty0 + edx * 2]
    mov word[Hexagon.Dev.Control.deviceId], bx
    movzx ecx, bx

    mov dl, 04h

    ret

.tty0:

    mov ah, 00h
    mov bx, word [Hexagon.Dev.deviceCodes.tty0]
    mov word[Hexagon.Dev.Control.deviceId], bx

;; Was a bare dword read
;; past this word-sized field, harmless before tty1's own code was
;; declared immediately after it, not once it was

    movzx ecx, word [Hexagon.Dev.deviceCodes.tty0]
    mov dl, 04h

    ret

.tty1:

    mov ah, 01h
    mov bx, word [Hexagon.Dev.deviceCodes.tty1]
    mov word[Hexagon.Dev.Control.deviceId], bx
    movzx ecx, word [Hexagon.Dev.deviceCodes.tty1]
    mov dl, 04h

    ret

.tty2:

    mov ah, 02h
    mov bx, word [Hexagon.Dev.deviceCodes.tty2]
    mov word[Hexagon.Dev.Control.deviceId], bx
    movzx ecx, word [Hexagon.Dev.deviceCodes.tty2]
    mov dl, 04h

    ret

.tty3:

    mov ah, 03h
    mov bx, word [Hexagon.Dev.deviceCodes.tty3]
    mov word[Hexagon.Dev.Control.deviceId], bx
    movzx ecx, word [Hexagon.Dev.deviceCodes.tty3]
    mov dl, 04h

    ret

.tty4:

    mov ah, 04h
    mov bx, word [Hexagon.Dev.deviceCodes.tty4]
    mov word[Hexagon.Dev.Control.deviceId], bx
    movzx ecx, word [Hexagon.Dev.deviceCodes.tty4]
    mov dl, 04h

    ret

.tty5:

    mov ah, 05h
    mov bx, word [Hexagon.Dev.deviceCodes.tty5]
    mov word[Hexagon.Dev.Control.deviceId], bx
    movzx ecx, word [Hexagon.Dev.deviceCodes.tty5]
    mov dl, 04h

    ret

.tty6:

    mov ah, 06h
    mov bx, word [Hexagon.Dev.deviceCodes.tty6]
    mov word[Hexagon.Dev.Control.deviceId], bx
    movzx ecx, word [Hexagon.Dev.deviceCodes.tty6]
    mov dl, 04h

    ret

.tty7:

    mov ah, 07h
    mov bx, word [Hexagon.Dev.deviceCodes.tty7]
    mov word[Hexagon.Dev.Control.deviceId], bx
    movzx ecx, word [Hexagon.Dev.deviceCodes.tty7]
    mov dl, 04h

    ret

.au0:

    mov ah, byte [Hexagon.Dev.deviceCodes.au0]
    mov bx, word [Hexagon.Dev.deviceCodes.au0]
    mov word[Hexagon.Dev.Control.deviceId], bx
    mov dl, 04h

    ret

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

.cpu0:

    mov ah, 00h
    mov bx, word [Hexagon.Dev.deviceCodes.cpu0]
    mov word[Hexagon.Dev.Control.deviceId], bx
    movzx ecx, word [Hexagon.Dev.deviceCodes.cpu0]
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

    cmp ax, word [Hexagon.Dev.deviceCodes.tty0]
    je .tty0

    cmp ax, word [Hexagon.Dev.deviceCodes.tty1]
    je .tty1

    cmp ax, word [Hexagon.Dev.deviceCodes.tty2]
    je .tty2

    cmp ax, word [Hexagon.Dev.deviceCodes.tty3]
    je .tty3

    cmp ax, word [Hexagon.Dev.deviceCodes.tty4]
    je .tty4

    cmp ax, word [Hexagon.Dev.deviceCodes.tty5]
    je .tty5

    cmp ax, word [Hexagon.Dev.deviceCodes.tty6]
    je .tty6

    cmp ax, word [Hexagon.Dev.deviceCodes.tty7]
    je .tty7

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

.tty3:

    mov esi, Hexagon.Dev.Devices.tty3

    ret

.tty4:

    mov esi, Hexagon.Dev.Devices.tty4

    ret

.tty5:

    mov esi, Hexagon.Dev.Devices.tty5

    ret

.tty6:

    mov esi, Hexagon.Dev.Devices.tty6

    ret

.tty7:

    mov esi, Hexagon.Dev.Devices.tty7

    ret

.processors:

    cmp ax, 00h
    je .cpu0

    stc

    ret

.cpu0:

    mov esi, Hexagon.Dev.Devices.cpu0

    ret

;;************************************************************************************

;; Numbers and port addresses each device is known by, which the registration
;; above hands out

Hexagon.Dev.deviceCodes:

;; Storage Devices

.hd0: db 80h
.hd1: db 81h
.hd2: db 82h
.hd3: db 83h

;; Serial ports

.com1: dw 3F8h
.com2: dw 2F8h
.com3: dw 3E8h
.com4: dw 2E8h

;; Parallel ports

.lpt0: dw 3BCh
.lpt1: dw 378h
.lpt2: dw 278h

;; Output devices

.tty0: dw 44h ;; Console
.tty1: dw 45h ;; VT1
.tty2: dw 46h ;; VT2
.tty3: dw 47h ;; VT3
.tty4: dw 48h ;; VT4
.tty5: dw 49h ;; VT5
.tty6: dw 4Ah ;; VT6
.tty7: dw 4Bh ;; VT7

;; Input devices

.mouse0: dw 51h
.kbd0: dw 52h

;; Processors

.cpu0: times 100 db 0

;; Sound device

.au0: dw 10h ;; Audio
