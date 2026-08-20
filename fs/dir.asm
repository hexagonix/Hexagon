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

;; Variables, constants and structures required for managing Virtual File System directories

Hexagon.VFS.Directory:

.code:   db 0
.offset: db 0
.status: db 0
;; "/" by default, so a relative path resolved before the first real cd
;; still joins against a genuine NUL-terminated string.

.currentDirectory:
db "/", 0
times 62 db 0
.previousDirectory:
times 64 db 0
.pathSize equ 64

Hexagon.VFS.Mount:

.mountPoint:
times 64 db " "
.mountUser:
times 32 db 0
.status:    db 0
.userCode:  db 0
.lastError: db 0

;;************************************************************************************

;; Real mount table, replacing the single mount point above. Slot 0 is
;; always "/", registered by Hexagon.Kernel.FS.VFS.registerBootMount.
;;
;; malloc'd (Hexagon.Mounts.Table.base, filled by
;; Hexagon.Kernel.FS.VFS.allocateMountTable) rather than placed in the
;; kernel's own fixed Hexagon.Heap area - see Hexagon.Disks.Table in
;; dev/i386/disk/disk.asm for why. Below is only the field layout (byte
;; offsets, no storage of its own); every access goes through .base

Hexagon.Mounts.Table.limit = 8

virtual at 0

Hexagon.Mounts.Table.inUse:
times Hexagon.Mounts.Table.limit db 0

Hexagon.Mounts.Table.drive:
times Hexagon.Mounts.Table.limit db 0 ;; BIOS drive number backing this mount

Hexagon.Mounts.Table.path:
times Hexagon.Mounts.Table.limit * 64 db 0 ;; Mount point path, null-terminated

Hexagon.Mounts.Table.deviceName:
times Hexagon.Mounts.Table.limit * 8 db 0 ;; Device name given to hx.mount (such as "hd0p0"), null-terminated

;; Each slot: +0 saved Hexagon.VFS.Control (filesystemType/volumeLabel), then
;; +Hexagon.VFS.Control.size saved Hexagon.VFS.FAT16B

Hexagon.Mounts.Table.state:
times Hexagon.Mounts.Table.limit * (Hexagon.VFS.Control.size + Hexagon.VFS.FAT.instanceSize) db 0

Hexagon.Mounts.Table.byteSize = $

end virtual

Hexagon.Mounts.Table.base: dd 0

;; Slot currently loaded into the live Hexagon.VFS.FAT16B working copy.
;; 0xFFFFFFFF means nothing has been loaded yet (before boot registration)

Hexagon.Mounts.loadedSlot: dd 0xFFFFFFFF

;;************************************************************************************

;; Sets a current directory for use in the filesystem
;;
;; Input:
;;
;; ESI - Full path of the directory to be used.
;;       The path must be at least 1 or more characters long
;;
;; Output:
;;
;; EAX - Error code, of which:
;; - 01h: Directory not found in the File System.
;; - 02h: The directory name does not match the requirements.
;; - 03h: Unknown error during the request.
;; EBX - Size of given path
;; CF set in case of error

Hexagon.Kernel.FS.Dir.setCurrentDirectory:

    push es

;; hexagonHandler's own entry stub leaves ES at kernelLinear (base 0) for
;; every syscall; rep movsb's destination is always ES:EDI, never DS:EDI -
;; same bug, same fix, as every other kernel-image-data writer (see
;; Hexagon.Kernel.FS.VFS.registerBootMount's own comment on this)

    mov ax, 10h
    mov es, ax

    push esi ; First, save the path provided in the call

;; Now the given path length will be validated to check the requirement

    call Hexagon.Libkern.String.stringSize ;; Hexagon function to check the size of a string

    cmp eax, 2
    jg .continue ;; Greater than 2 (Character plus null)

    cmp eax, 65
    jl .continue ;; Less than 64

    pop esi

    mov ebx, eax
    mov eax, 02h

    stc

    jmp .end

.continue: ;; The requirements have been met, continue with the process

;; First, copy the path from current directory to previous directory

    mov esi, Hexagon.VFS.Directory.currentDirectory ;; Store this data

    call Hexagon.Libkern.String.stringSize

    mov ecx, eax

    inc ecx

;; Copy path now

    mov edi, Hexagon.VFS.Directory.previousDirectory

    mov esi, Hexagon.VFS.Directory.currentDirectory

    rep movsb ;; Copy (ECX) characters from ESI to EDI

;; Now, fill in the variable with the given value

    pop esi

    call Hexagon.Libkern.String.stringSize

    mov ecx, eax

    inc ecx

;; Now copy the given name to the appropriate location

    mov edi, Hexagon.VFS.Directory.currentDirectory

    rep movsb ;; Copy (ECX) characters from ESI to EDI

    clc

.end:

    pop es

    ret

;;************************************************************************************

;; Get the current directory value, to be used by the user and the
;; Virtual File System
;;
;; Output:
;;
;; ESI - Current directory path
;; EDI - Previous directory path (before last change)

Hexagon.Kernel.FS.Dir.getCurrentDirectory:

;; First, retrieve the current directory path for ESI

    mov esi, Hexagon.VFS.Directory.currentDirectory

;; Now the previous directory path, for EDI

    mov edi, Hexagon.VFS.Directory.previousDirectory

    ret

;;************************************************************************************

;; Sets the current mount point to a directory or the root of the volume
;;
;; Input:
;;
;; ESI - Path to current mount point on disk
;;
;; Output:
;;
;; EAX - Error code, of which:
;; - 01h: Directory not found in the filesystem.
;; - 02h: The directory name does not match the requirements.
;; - 03h: Unknown error during the request.
;; CF set in case of error

Hexagon.Kernel.FS.Dir.setMountPoint:

    push esi ;; First, save the path provided in the call

;; Now the given path length will be validated to check the requirement

    call Hexagon.Libkern.String.stringSize ;; Hexagon function to check the size of a string

    cmp eax, 2
    jg .continue ;; Greater than 2 (Character plus null)

    cmp eax, 65
    jl .continue ;; Less than 64

    pop esi

    stc

    mov eax, 01h

    jmp .end

.continue:

;; Now, fill in the variable with the given value

    pop esi

    call Hexagon.Libkern.String.stringSize

    mov ecx, eax

    inc ecx

;; Now copy the given name to the appropriate location

    mov edi, Hexagon.VFS.Mount.mountPoint

    rep movsb ;; Copy (ECX) characters from ESI to EDI

    clc

.end:

    ret

;;************************************************************************************

;; Get the current mount point (will be expanded when multiple points are supported by the kernel)
;;
;; Output:
;;
;; ESI - Mounting point
;; EDI - Volume mounted
;; EAX - Volume filesystem code

Hexagon.Kernel.FS.Dir.getMountPoint:

;; First, rescue the mounted physical volume, for EDI

    mov ah, byte[Hexagon.Dev.Gen.Disk.Control.currentDisk]

    mov dl, 01h ;; Storage device class

    call Hexagon.Kernel.Dev.Dev.convertDeviceToDeviceName ;; Convert to device name

    mov edi, esi

;; Now retrieve the mount point path for ESI

    mov esi, Hexagon.VFS.Mount.mountPoint

;; Restore the filesystem code

    mov eax, [Hexagon.VFS.Control.filesystemType]

    ret
