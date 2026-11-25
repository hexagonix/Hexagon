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
;; 6 - Pseudoterminais
;;
;;************************************************************************************

use32

Hexagon.Dev.Control:

.file: db 0

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

;; Pseudoterminals, managers then subsidiaries, each name 6 bytes long

.ptyp0:
db "ptyp0", 0
.ptyp1:
db "ptyp1", 0
.ptyp2:
db "ptyp2", 0
.ptyp3:
db "ptyp3", 0
.ptyp4:
db "ptyp4", 0
.ptyp5:
db "ptyp5", 0
.ptyp6:
db "ptyp6", 0
.ptyp7:
db "ptyp7", 0
.ttyp0:
db "ttyp0", 0
.ttyp1:
db "ttyp1", 0
.ttyp2:
db "ttyp2", 0
.ttyp3:
db "ttyp3", 0
.ttyp4:
db "ttyp4", 0
.ttyp5:
db "ttyp5", 0
.ttyp6:
db "ttyp6", 0
.ttyp7:
db "ttyp7", 0

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
.pty:      db 06h

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

Hexagon.Dev.Registry.limit = 56

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
    call Hexagon.Kernel.Dev.PTY.registerDevices

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

;; Dispatch table for the six device classes in Hexagon.Dev.DeviceClasses.
;; attach runs once, at boot. open/read/write/close/ioctl run per caller, and
;; reference whenever a descriptor is copied, by hx.dup2 or into a new process

Hexagon.Dev.Switch.attach    = 0
Hexagon.Dev.Switch.open      = 4
Hexagon.Dev.Switch.read      = 8
Hexagon.Dev.Switch.write     = 12
Hexagon.Dev.Switch.close     = 16
Hexagon.Dev.Switch.ioctl     = 20
Hexagon.Dev.Switch.reference = 24
Hexagon.Dev.Switch.rowSize   = 28

Hexagon.Dev.Switch:

dd Hexagon.Kernel.Dev.Dev.Switch.Block.attach
dd Hexagon.Kernel.Dev.Dev.Switch.Block.open
dd Hexagon.Kernel.Dev.Dev.Switch.Block.read
dd Hexagon.Kernel.Dev.Dev.Switch.Block.write
dd Hexagon.Kernel.Dev.Dev.Switch.Block.close
dd Hexagon.Kernel.Dev.Dev.Switch.notSupportedIoctl
dd Hexagon.Kernel.Dev.Dev.Switch.noReference

dd Hexagon.Kernel.Dev.Dev.Switch.Serial.attach
dd Hexagon.Kernel.Dev.Dev.Switch.Serial.open
dd Hexagon.Kernel.Dev.Dev.Switch.Serial.read
dd Hexagon.Kernel.Dev.Dev.Switch.Serial.write
dd Hexagon.Kernel.Dev.Dev.Switch.Serial.close
dd Hexagon.Kernel.Dev.Dev.Switch.notSupportedIoctl
dd Hexagon.Kernel.Dev.Dev.Switch.noReference

dd Hexagon.Kernel.Dev.Dev.Switch.Parallel.attach
dd Hexagon.Kernel.Dev.Dev.Switch.Parallel.open
dd Hexagon.Kernel.Dev.Dev.Switch.Parallel.read
dd Hexagon.Kernel.Dev.Dev.Switch.Parallel.write
dd Hexagon.Kernel.Dev.Dev.Switch.Parallel.close
dd Hexagon.Kernel.Dev.Dev.Switch.notSupportedIoctl
dd Hexagon.Kernel.Dev.Dev.Switch.noReference

dd Hexagon.Kernel.Dev.Dev.Switch.Output.attach
dd Hexagon.Kernel.Dev.Dev.Switch.Output.open
dd Hexagon.Kernel.Dev.Dev.Switch.Output.read
dd Hexagon.Kernel.Dev.Dev.Switch.Output.write
dd Hexagon.Kernel.Dev.Dev.Switch.Output.close
dd Hexagon.Kernel.Dev.Dev.Switch.Output.ioctl
dd Hexagon.Kernel.Dev.Dev.Switch.Output.reference

dd Hexagon.Kernel.Dev.Dev.Switch.Proc.attach
dd Hexagon.Kernel.Dev.Dev.Switch.Proc.open
dd Hexagon.Kernel.Dev.Dev.Switch.Proc.read
dd Hexagon.Kernel.Dev.Dev.Switch.Proc.write
dd Hexagon.Kernel.Dev.Dev.Switch.Proc.close
dd Hexagon.Kernel.Dev.Dev.Switch.notSupportedIoctl
dd Hexagon.Kernel.Dev.Dev.Switch.noReference

dd Hexagon.Kernel.Dev.Dev.Switch.PTY.attach
dd Hexagon.Kernel.Dev.PTY.open
dd Hexagon.Kernel.Dev.PTY.read
dd Hexagon.Kernel.Dev.PTY.write
dd Hexagon.Kernel.Dev.PTY.close
dd Hexagon.Kernel.Dev.PTY.ioctl
dd Hexagon.Kernel.Dev.PTY.reference

;; For the classes with nothing to count

Hexagon.Kernel.Dev.Dev.Switch.noReference:

    ret

;; Shared "not supported" stub for every class's ioctl slot besides output and pty

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

Hexagon.Kernel.Dev.Dev.Switch.PTY.attach:

    ret

;;************************************************************************************

;; Resolves a descriptor of the running process into the device behind it. The
;; controlling terminal becomes the caller's own VT
;;
;; Input:
;;
;; EAX - Descriptor
;;
;; Output:
;;
;; EAX - Device id, or Hexagon.Kern.FD.badDescriptor with CF set
;; EBP - Row of Hexagon.Dev.Switch for the device's class

Hexagon.Kernel.Dev.Dev.resolveDescriptor:

    call Hexagon.Kern.FD.lookup

    jc .end

    call Hexagon.Kernel.Dev.Dev.classRow

    and eax, 0FFFFh

    cmp eax, Hexagon.Kern.FD.controllingTTY

    jne .resolved

    push ecx

    movzx ecx, byte[Hexagon.Scheduler.current]

    mov ecx, dword[Hexagon.Processes.Table.tty + ecx * 4]

    movzx eax, word[Hexagon.Dev.deviceCodes.tty0 + ecx * 2]

    pop ecx

.resolved:

    clc

.end:

    ret

;;************************************************************************************

;; Input:
;;
;; EAX - Descriptor entry, as kern/fd.asm lays it out
;;
;; Output:
;;
;; EBP - Row of Hexagon.Dev.Switch for its class

Hexagon.Kernel.Dev.Dev.classRow:

    mov ebp, eax

    shr ebp, 16

    and ebp, 0FFh

    dec ebp

    imul ebp, ebp, Hexagon.Dev.Switch.rowSize

    add ebp, Hexagon.Dev.Switch

    ret

;;************************************************************************************

;; Closes a descriptor, letting its class release the device first
;;
;; Input:
;;
;; EAX - Descriptor
;;
;; Output:
;;
;; CF set if the descriptor is not open

Hexagon.Kernel.Dev.Dev.close:

    push ebp
    push eax

    call Hexagon.Kernel.Dev.Dev.resolveDescriptor

    jc .badDescriptor

    call dword[ds:ebp + Hexagon.Dev.Switch.close]

    pop eax

    call Hexagon.Kern.FD.release

    pop ebp

    clc

    ret

.badDescriptor:

    add esp, 4

    pop ebp

    stc

    ret

;; Same as above for a descriptor entry of any slot, for a process that is
;; ending
;;
;; Input:
;;
;; EAX - Descriptor entry

Hexagon.Kernel.Dev.Dev.closeEntry:

    push eax
    push ebp

    call Hexagon.Kernel.Dev.Dev.classRow

    and eax, 0FFFFh

    call dword[ds:ebp + Hexagon.Dev.Switch.close]

    pop ebp
    pop eax

    ret

;; Tells the class of a descriptor entry that one more descriptor holds it
;;
;; Input:
;;
;; EAX - Descriptor entry

Hexagon.Kernel.Dev.Dev.referenceEntry:

    push eax
    push ebp

    call Hexagon.Kernel.Dev.Dev.classRow

    and eax, 0FFFFh

    call dword[ds:ebp + Hexagon.Dev.Switch.reference]

    pop ebp
    pop eax

    ret

;;************************************************************************************

;; Every class close handler takes the device id in EAX

Hexagon.Kernel.Dev.Dev.Switch.Block.close:

    ret

Hexagon.Kernel.Dev.Dev.Switch.Serial.close:

    ret

Hexagon.Kernel.Dev.Dev.Switch.Parallel.close:

    ret

;; The internal speaker is the only output device that needs anything done
;; on close, and only once no descriptor holds it any more

Hexagon.Kernel.Dev.Dev.Switch.Output.close:

    cmp ax, word[Hexagon.Dev.deviceCodes.au0]

    jne .done

    dec dword[Hexagon.Dev.Switch.Output.au0References]

    jnz .done

    call Hexagon.Kernel.Dev.Snd.Snd.stopSound

.done:

    ret

Hexagon.Kernel.Dev.Dev.Switch.Output.reference:

    cmp ax, word[Hexagon.Dev.deviceCodes.au0]

    jne .done

    inc dword[Hexagon.Dev.Switch.Output.au0References]

.done:

    ret

Hexagon.Dev.Switch.Output.au0References: dd 0 ;; Descriptors holding the internal speaker

Hexagon.Kernel.Dev.Dev.Switch.Proc.close:

    ret

;;************************************************************************************

;; Sends bytes to the device behind a descriptor
;;
;; Input:
;;
;; EAX - Descriptor
;; ESI - Buffer
;; ECX - Bytes to send
;;
;; Output:
;;
;; EAX - Bytes sent, or an error code with CF set

Hexagon.Kernel.Dev.Dev.write:

;; The bytes are read at CPL 0, so the caller must be able to reach them itself

    push ebx

    mov ebx, esi

    call Hexagon.Arch.Paging.rangeIsCallerWritable

    pop ebx

    jc .badBuffer

    call Hexagon.Kern.FD.beginCall

    push ebp

    call Hexagon.Kernel.Dev.Dev.resolveDescriptor

    jc .end

    call dword[ds:ebp + Hexagon.Dev.Switch.write]

.end:

    call Hexagon.Kern.FD.endCall

    pop ebp

    ret

.badBuffer:

    mov eax, Hexagon.Kern.Proc.badAddress

    ret

;;************************************************************************************

;; Every class write handler takes the device id in EAX and ESI/ECX as above

;; Disk writes aren't supported through this generic channel. A mounted
;; filesystem talks to the block driver directly

Hexagon.Kernel.Dev.Dev.Switch.Block.write:

    stc

    ret

;; The port is driver state shared by every caller, so nothing may preempt
;; between choosing it and the last byte

Hexagon.Kernel.Dev.Dev.Switch.Serial.write:

    push ecx
    push esi

    call Hexagon.Kern.Sched.disablePreemption

    mov word[Hexagon.Kernel.Dev.Serial.Serial.Ports.currentSerialPort], ax

    jecxz .done

.sendByte:

    lodsb

    call Hexagon.Kernel.Dev.Serial.Serial.performSend

    loop .sendByte

.done:

    call Hexagon.Kern.Sched.enablePreemption

    pop esi
    pop ecx

    mov eax, ecx

    clc

    ret

Hexagon.Kernel.Dev.Dev.Switch.Parallel.write:

    push ecx
    push esi

    call Hexagon.Kern.Sched.disablePreemption

    mov word[Hexagon.Kernel.Dev.LPT.LPT.currentParallelPort], ax

    jecxz .done

.sendByte:

    lodsb

    call Hexagon.Kernel.Dev.LPT.LPT.send

    loop .sendByte

.done:

    call Hexagon.Kern.Sched.enablePreemption

    pop esi
    pop ecx

    mov eax, ecx

    clc

    ret

Hexagon.Kernel.Dev.Dev.Switch.Output.write:

    push edx
    push ecx

    call Hexagon.Kernel.Dev.Dev.Switch.Output.resolveTTYIndex

    jc .notSupported

;; Another process's VT may never have been drawn on yet

    movzx edx, byte[Hexagon.Scheduler.current]

    cmp ecx, dword[Hexagon.Processes.Table.tty + edx * 4]

    je .ownTTY

    call Hexagon.Kernel.Dev.Dev.ensureVTBuffer

.ownTTY:

    mov edx, ecx ;; VT

    pop ecx

;; Bytes for a VT another process holds for itself are taken and not drawn

    call Hexagon.Kernel.Dev.Console.Console.mayDrawOn

    jc .taken

    call Hexagon.Kernel.Dev.Console.Terminal.write

.taken:

    pop edx

    mov eax, ecx

    clc

    ret

.notSupported:

    pop ecx
    pop edx

    stc

    ret

Hexagon.Kernel.Dev.Dev.Switch.Proc.write:

    stc

    ret

;;************************************************************************************

;; Reads bytes from the device behind a descriptor
;;
;; Input:
;;
;; EAX - Descriptor
;; EDI - Buffer to receive the data
;; ECX - Maximum bytes to read
;;
;; Output:
;;
;; EAX - Bytes actually read, or an error code with CF set

Hexagon.Kernel.Dev.Dev.read:

    jecxz .nothingAsked

;; The bytes are written at CPL 0, so the caller must be able to reach them itself

    push ebx

    mov ebx, edi

    call Hexagon.Arch.Paging.rangeIsCallerWritable

    pop ebx

    jc .badBuffer

    call Hexagon.Kern.FD.beginCall

    push ebp

    call Hexagon.Kernel.Dev.Dev.resolveDescriptor

    jc .end

    call dword[ds:ebp + Hexagon.Dev.Switch.read]

.end:

    call Hexagon.Kern.FD.endCall

    pop ebp

    ret

.nothingAsked:

    xor eax, eax

    clc

    ret

.badBuffer:

    mov eax, Hexagon.Kern.Proc.badAddress

    ret

;;************************************************************************************

;; Device-specific control that doesn't fit read/write's byte-stream shape,
;; dispatched to the class of the device behind a descriptor
;;
;; Input:
;;
;; EAX - Descriptor
;; EBX - Command
;; ECX - Argument for the command
;;
;; Output:
;;
;; CF set if the descriptor is not open, or its class has no such command
;;
;; Hexagon.Kern.FD.Commands are taken here for every descriptor, before its class

Hexagon.Kernel.Dev.Dev.ioctl:

    cmp ebx, Hexagon.Kern.FD.Commands.nonBlocking

    je .nonBlocking

    cmp ebx, Hexagon.Kern.FD.Commands.closeOnSpawn

    je .closeOnSpawn

    push ebp

    call Hexagon.Kernel.Dev.Dev.resolveDescriptor

    jc .end

    call dword[ds:ebp + Hexagon.Dev.Switch.ioctl]

.end:

    pop ebp

    ret

.nonBlocking:

    push edx

    mov edx, Hexagon.Kern.FD.Flags.nonBlocking

    call Hexagon.Kern.FD.setFlag

    pop edx

    ret

.closeOnSpawn:

    push edx

    mov edx, Hexagon.Kern.FD.Flags.closeOnSpawn

    call Hexagon.Kern.FD.setFlag

    pop edx

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

    push edx
    push ecx

    call Hexagon.Kernel.Dev.Dev.Switch.Output.callerTTY

    mov edx, ecx

    pop ecx

    jc .notSupported

    call Hexagon.Kernel.Dev.TTY.read

    pop edx

    clc

    ret

.notSupported:

    pop edx

    xor eax, eax

    stc

    ret

;; Only a tty's own processes may read it, since keys go to the foreground
;; process of the VT they were typed on
;;
;; Input: AX - Device id
;;
;; Output: ECX - VT index, CF set if the device is not the caller's own tty

Hexagon.Kernel.Dev.Dev.Switch.Output.callerTTY:

    call Hexagon.Kernel.Dev.Dev.Switch.Output.resolveTTYIndex

    jc .end

    push eax

    movzx eax, byte[Hexagon.Scheduler.current]

    cmp ecx, dword[Hexagon.Processes.Table.tty + eax * 4]

    pop eax

    je .end

    stc

.end:

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
;; EAX - Descriptor, for a device
;; CF set in case of error, with EAX holding its code

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

;; If not, proceed with opening a device. The descriptor is taken before
;; the class handler touches the hardware, and given back if it fails

    pop bx

    cmp dl, 1

    jb .invalidClass

    cmp dl, 6

    ja .invalidClass

    movzx eax, dl
    shl eax, 16
    mov ax, bx

    call Hexagon.Kern.FD.allocate

    jc .end

    push ebp
    push eax

    movzx ebp, dl

    dec ebp

    imul ebp, ebp, Hexagon.Dev.Switch.rowSize

    add ebp, Hexagon.Dev.Switch

    call dword[ds:ebp + Hexagon.Dev.Switch.open] ;; BX = device id, DL = class

    jc .openFailed

    pop eax
    pop ebp

    clc

.end:

    ret

.openFailed:

    xchg eax, dword[esp] ;; EAX = descriptor, the class's error code kept

    call Hexagon.Kern.FD.release

    pop eax
    pop ebp

    stc

    ret

.invalidClass:

    mov eax, 05h

    stc

    ret

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

    clc

    cmp dword[kernelExecute], kernelExecutePermission
    je .storageAuthenticated

.storageVerifyPermissions:

    call Hexagon.Kern.Users.getUserPermissions

    cmp eax, 03h ;; Group code for standard user
    je .storagePermissionDenied

.storageAuthenticated:

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

;; Only registered here, on a successful open, since there's no way to
;; know up front which serial ports actually have something connected

    mov ax, bx

    call Hexagon.Kernel.Dev.Dev.convertDeviceToDeviceName

    mov al, dl
    mov bl, 0
    mov cl, 0

    call Hexagon.Kernel.Dev.Dev.registerDevice

;; Hexagon.Kernel.Dev.Dev.registerDevice reports on its internal name
;; dedup through CF, a signal this open() call has no business forwarding
;; to its own caller

    clc

    ret

.openingError:

    mov eax, 05h

    ret

Hexagon.Dev.Switch.Serial.initializedCom1: db 0
Hexagon.Dev.Switch.Serial.initializedCom2: db 0
Hexagon.Dev.Switch.Serial.initializedCom3: db 0
Hexagon.Dev.Switch.Serial.initializedCom4: db 0

;;************************************************************************************

Hexagon.Kernel.Dev.Dev.Switch.Parallel.open:

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

;; Only registered here, on a successful open, same reasoning as the
;; serial ports above

    mov ax, bx

    call Hexagon.Kernel.Dev.Dev.convertDeviceToDeviceName

    mov al, dl
    mov bl, 0
    mov cl, 0

    call Hexagon.Kernel.Dev.Dev.registerDevice

;; Hexagon.Kernel.Dev.Dev.registerDevice reports on its internal name
;; dedup through CF, a signal this open() call has no business forwarding
;; to its own caller

    clc

    ret

.openingError:

    mov eax, 05h

    ret

Hexagon.Dev.Switch.Parallel.initializedLpt0: db 0
Hexagon.Dev.Switch.Parallel.initializedLpt1: db 0
Hexagon.Dev.Switch.Parallel.initializedLpt2: db 0

;;************************************************************************************

;; Opening a console has no side effects, the same as every other
;; class. Activating one is hx.ioctl command 1 and claiming it is command 3,
;; so merely opening a tty node cannot steal that VT from its owner

Hexagon.Kernel.Dev.Dev.Switch.Output.open:

    cmp bx, word[Hexagon.Dev.deviceCodes.au0]

    jne .done

    inc dword[Hexagon.Dev.Switch.Output.au0References]

.done:

    clc

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

;; Resolves a device id into a VT index, if it names one of tty0..tty7
;;
;; Input: AX - Device id
;;
;; Output: ECX - VT index (0-7), CF clear if resolved. CF set otherwise
;; (not a tty device at all), ECX unchanged

Hexagon.Kernel.Dev.Dev.Switch.Output.resolveTTYIndex:

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
;;       3 = claim the open tty as the caller's own VT, 4 = get the mode of
;;       the tty, 5 = set it, 6 = get the size of its window, 8 = hold it
;;       for the caller alone, ECX = 1, or let go of it, ECX = 0)
;; ECX - Argument for command 1 (console index: 0 main, 1 secondary), or the
;;       mode for command 5, as Hexagon.TTY.Modes. Commands 2 and 3 take no
;;       argument, the target VT is the tty behind the descriptor
;; EAX - Device id, from Hexagon.Kernel.Dev.Dev.ioctl
;;
;; Output: EAX - Mode, for command 4. EAX - Columns, EBX - Rows, for command 6

Hexagon.Kernel.Dev.Dev.Switch.Output.ioctl:

    cmp ebx, 1
    je .activateConsole

    cmp ebx, 2
    je .activateVT

    cmp ebx, 3
    je .claim

    cmp ebx, 4

    je .getMode

    cmp ebx, 5

    je .setMode

    cmp ebx, 6

    je .getSize

    cmp ebx, 8

    je .exclusive

    stc

    ret

;; Only the VT's foreground process may take it, and only its holder let it go

.exclusive:

    push ecx ;; 1 to take it, 0 to let it go

    call Hexagon.Kernel.Dev.Dev.Switch.Output.resolveTTYIndex

    pop eax

    jc .end

    push edx

    movzx edx, byte[Hexagon.Scheduler.current]

    cmp eax, 0

    je .letGo

    cmp dword[Hexagon.Console.VT.foregroundSlot + ecx * 4], edx

    jne .refused

    mov dword[Hexagon.Console.VT.exclusiveSlot + ecx * 4], edx

    pop edx

    clc

    ret

.letGo:

    cmp dword[Hexagon.Console.VT.exclusiveSlot + ecx * 4], edx

    jne .notHeld

    mov dword[Hexagon.Console.VT.exclusiveSlot + ecx * 4], 0xFFFFFFFF

.notHeld:

    pop edx

    clc

    ret

.refused:

    pop edx

    stc

    ret

;; Every VT has the geometry of the console

.getSize:

    push ecx

    call Hexagon.Kernel.Dev.Dev.Switch.Output.resolveTTYIndex

    pop ecx

    jc .end

    movzx eax, word[Hexagon.Console.maxColumns]
    movzx ebx, word[Hexagon.Console.maxRows]

    inc eax ;; Counting from 1
    inc ebx

    clc

    ret

.getMode:

    call Hexagon.Kernel.Dev.Dev.Switch.Output.resolveTTYIndex

    jc .end

    movzx eax, byte[Hexagon.TTY.mode + ecx]

    clc

    ret

.setMode:

    push ecx ;; The mode

    call Hexagon.Kernel.Dev.Dev.Switch.Output.resolveTTYIndex

    pop eax

    jc .end

    and al, Hexagon.TTY.Modes.all

    mov byte[Hexagon.TTY.mode + ecx], al

    clc

    ret

.claim:

    call Hexagon.Kernel.Dev.Dev.Switch.Output.resolveTTYIndex

    jc .end ;; Not a tty at all

    call Hexagon.Kernel.Dev.Dev.Switch.Output.claimVT

    clc

    ret

.activateVT:

    call Hexagon.Kernel.Dev.Dev.Switch.Output.resolveTTYIndex

    jc .end ;; Not a tty at all

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

    call Hexagon.Kernel.Dev.PTY.deviceOfName ;; BX = device id

    jc .pty

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
    movzx bx, ah
    movzx ecx, byte [Hexagon.Dev.deviceCodes.hd0]
    mov dl, 01h

    ret

.hd1:

    mov ah, byte [Hexagon.Dev.deviceCodes.hd1]
    movzx bx, ah
    movzx ecx, byte [Hexagon.Dev.deviceCodes.hd1]
    mov dl, 01h

    ret

.hd2:

    mov ah, byte [Hexagon.Dev.deviceCodes.hd2]
    movzx bx, ah
    movzx ecx, byte [Hexagon.Dev.deviceCodes.hd2]
    mov dl, 01h

    ret

.hd3:

    mov ah, byte [Hexagon.Dev.deviceCodes.hd3]
    movzx bx, ah
    movzx ecx, byte [Hexagon.Dev.deviceCodes.hd3]
    mov dl, 01h

    ret

.com1:

    mov ah, 00h
    mov bx, word [Hexagon.Dev.deviceCodes.com1]
    movzx ecx, word [Hexagon.Dev.deviceCodes.com1]
    mov dl, 02h

    ret

.com2:

    mov ah, 01h
    mov bx, word [Hexagon.Dev.deviceCodes.com2]
    movzx ecx, word [Hexagon.Dev.deviceCodes.com2]
    mov dl, 02h

    ret

.com3:

    mov ah, 02h
    mov bx, word [Hexagon.Dev.deviceCodes.com3]
    movzx ecx, word [Hexagon.Dev.deviceCodes.com3]
    mov dl, 02h

    ret

.com4:

    mov ah, 03h
    mov bx, word [Hexagon.Dev.deviceCodes.com4]
    movzx ecx, word [Hexagon.Dev.deviceCodes.com4]
    mov dl, 02h

    ret

.lpt0:

    mov bx, word [Hexagon.Dev.deviceCodes.lpt0]
    movzx ecx, word [Hexagon.Dev.deviceCodes.lpt0]
    mov dl, 03h

    ret

.lpt1:

    mov bx, word [Hexagon.Dev.deviceCodes.lpt1]
    movzx ecx, word [Hexagon.Dev.deviceCodes.lpt1]
    mov dl, 03h

    ret

.lpt2:

    mov bx, word [Hexagon.Dev.deviceCodes.lpt2]
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
    movzx ecx, bx

    mov dl, 04h

    ret

.tty0:

    mov ah, 00h
    mov bx, word [Hexagon.Dev.deviceCodes.tty0]

;; Was a bare dword read
;; past this word-sized field, harmless before tty1's own code was
;; declared immediately after it, not once it was

    movzx ecx, word [Hexagon.Dev.deviceCodes.tty0]
    mov dl, 04h

    ret

.tty1:

    mov ah, 01h
    mov bx, word [Hexagon.Dev.deviceCodes.tty1]
    movzx ecx, word [Hexagon.Dev.deviceCodes.tty1]
    mov dl, 04h

    ret

.tty2:

    mov ah, 02h
    mov bx, word [Hexagon.Dev.deviceCodes.tty2]
    movzx ecx, word [Hexagon.Dev.deviceCodes.tty2]
    mov dl, 04h

    ret

.tty3:

    mov ah, 03h
    mov bx, word [Hexagon.Dev.deviceCodes.tty3]
    movzx ecx, word [Hexagon.Dev.deviceCodes.tty3]
    mov dl, 04h

    ret

.tty4:

    mov ah, 04h
    mov bx, word [Hexagon.Dev.deviceCodes.tty4]
    movzx ecx, word [Hexagon.Dev.deviceCodes.tty4]
    mov dl, 04h

    ret

.tty5:

    mov ah, 05h
    mov bx, word [Hexagon.Dev.deviceCodes.tty5]
    movzx ecx, word [Hexagon.Dev.deviceCodes.tty5]
    mov dl, 04h

    ret

.tty6:

    mov ah, 06h
    mov bx, word [Hexagon.Dev.deviceCodes.tty6]
    movzx ecx, word [Hexagon.Dev.deviceCodes.tty6]
    mov dl, 04h

    ret

.tty7:

    mov ah, 07h
    mov bx, word [Hexagon.Dev.deviceCodes.tty7]
    movzx ecx, word [Hexagon.Dev.deviceCodes.tty7]
    mov dl, 04h

    ret

.au0:

    mov ah, byte [Hexagon.Dev.deviceCodes.au0]
    mov bx, word [Hexagon.Dev.deviceCodes.au0]
    mov dl, 04h

    ret

.mouse0:

    mov ah, 00h
    mov bx, [Hexagon.Dev.deviceCodes.mouse0]
    mov dl, 00h

    ret

.kbd0:

    mov ah, 00h
    mov bx, word [Hexagon.Dev.deviceCodes.kbd0]
    mov dl, 00h

    ret

.cpu0:

    mov ah, 00h
    mov bx, word [Hexagon.Dev.deviceCodes.cpu0]
    movzx ecx, word [Hexagon.Dev.deviceCodes.cpu0]
    mov dl, 05h

    ret

.pty:

    mov ah, bl
    movzx ecx, bx
    mov dl, 06h

    ret

;;************************************************************************************

;; Convert a device number or physical address to a device name
;;
;; Input:
;;
;; AH - Device number (storage case)
;; AX - Device number (serial ports, parallel ports, video devices and processors)
;; DL - Device class (1 for storage, 2 for serial ports, 3 for parallel ports,
;;       4 for output devices, 5 for processors and 6 for pseudoterminals)
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

    cmp dl, 6
    je Hexagon.Kernel.Dev.PTY.nameOfDevice

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
