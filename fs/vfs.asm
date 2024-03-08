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

;; Supported filesystem codes

;; Codes for the main filesystems, supported or not

Hexagon.VFS.FS:

.FAT12    = 01h ;; FAT12 (Future)
.FAT16    = 04h ;; FAT16 (< 32 MB)
.FAT16B   = 06h ;; FAT16B (FAT16B) - Supported
.FAT16LBA = 0Eh ;; FAT16 (LBA)

Hexagon.VFS.Control:

.filesystemType: db 0 ;; Stores which filesystem is present on the volume
.volumeLabel:    db 0
.volumeSerial:   db 0

;; Structure with common variables and constants for FAT-type systems
;; Compatible with FAT12, FAT16 and FAT32. Must be instantiated in each application

struc Hexagon.VFS.FAT
{

.bytesPerSector:       dw 0       ;; Number of bytes per sector
.sectorsPerCluster:    db 0       ;; Sectors per cluster
.reservedSectors:      dw 0       ;; Reserve sectors after the boot sector
.totalFATs:            db 0       ;; Number of FAT tables
.rootEntries:          dw 0       ;; Total files and folders in the root directory
.sectorsPerFAT:        dw 0       ;; Sectors used to store FAT
.totalSectors:         dd 0       ;; Sectors on the disk
.rootDirSize:          dw 0       ;; Size in sectors of the root directory
.rootDir:              dd 0       ;; LBA address of the root directory
.sizeFATs:             dw 0       ;; Size in sectors of the FAT(s)
.FAT:                  dd 0       ;; LBA address of FAT
.dataArea:             dd 0       ;; LBA address of the start of the data area
.clusterSize:          dd 0       ;; Cluster size, in bytes
.hiddenAttribute       equ 00h    ;; Attribute of a hidden file
.systemAttribute       equ 04h    ;; Attribute of a file marked as system file
.directoryAttribute    equ 10h    ;; Attribute of a directory
.longFilenameAttribute equ 0x0F   ;; Attribute of a long filename (Long File Name)
.unlinkedAttribute     equ 0xE5   ;; Deleted file/free entry attribute
.lastClusterAttribute  equ 0xFFF8 ;; Last cluster in chain attribute
.directoryBit          equ 04h    ;; Bit of a directory = .directoryAttribute, but for bit check
.volumeNameBit         equ 03h    ;; Bit of a volume name (label)

}

;; Hexagon file management structures and mount points

include "fs/dir.asm"

;;************************************************************************************

;; Create new empty file
;;
;; Input:
;;
;; ESI - Pointer to filename
;;
;; Output:
;;
;; EDI - Pointer to entry in the root directory
;; EAX containing the error code, if applicable
;; CF defined if the file already exists on the disk

Hexagon.Kernel.FS.VFS.createFile:

    call Hexagon.Kernel.Kernel.Usuarios.verificarPermissoes

    cmp eax, 03h ;; Group code for default user
    je .permissionDenied

    mov ah, byte[Hexagon.VFS.Control.filesystemType]

    cmp ah, Hexagon.VFS.FS.FAT16B
    je .newFileFAT16B

    ret

.newFileFAT16B:

    call Hexagon.Kernel.FS.FAT16.createEmptyFileFAT16B

    ret

.permissionDenied:

    stc

    mov eax, 05h

    ret

;;************************************************************************************

;; Unlink a file from volume
;;
;; Input:
;;
;; ESI - Pointer to filename
;;
;; Output:
;;
;; EAX - Error code, if applicable
;;     - 05h for permission denied
;; CF defined if the file was not found or has an invalid name

Hexagon.Kernel.FS.VFS.unlinkFile:

    call Hexagon.Kernel.Kernel.Usuarios.verificarPermissoes

    cmp eax, 03h ;; Group code for default user
    je .permissionDenied

    mov ah, byte[Hexagon.VFS.Control.filesystemType]

    cmp ah, Hexagon.VFS.FS.FAT16B
    je .unlinkFileFAT16B

    ret

.unlinkFileFAT16B:

    call Hexagon.Kernel.FS.FAT16.unlinkFileFAT16B

    ret

.permissionDenied:

    stc

    mov eax, 05h

    ret

;;************************************************************************************

;; Save file to volume
;;
;; Input:
;;
;; ESI - Pointer to filename
;; EDI - Pointer to data
;; EAX - File size (in bytes)
;;
;; Output:
;;
;; EAX - Error code, if applicable
;; CF defined if the file was not found or has an invalid name

Hexagon.Kernel.FS.VFS.saveFile:

    pushad

    mov ah, byte[Hexagon.VFS.Control.filesystemType]

    cmp ah, Hexagon.VFS.FS.FAT16B
    je .saveFileFAT16B

    popad

    ret

.saveFileFAT16B:

    popad

    call Hexagon.Kernel.FS.FAT16.saveFileFAT16B

    ret

;;************************************************************************************

;; Obter a lista de arquivos no diretório raiz
;;
;; Saída:
;;
;; ESI - Ponteiro para a lista de arquivos
;; EAX - Número de arquivos total

Hexagon.Kernel.FS.VFS.listFiles:

    mov ah, byte[Hexagon.VFS.Control.filesystemType]

    cmp ah, Hexagon.VFS.FS.FAT16B
    je .listFilesFAT16B

    ret

.listFilesFAT16B:

    call Hexagon.Kernel.FS.FAT16.listFilesFAT16B

    ret

;;************************************************************************************

;; Rename an existing file on volume
;;
;; Input:
;;
;; ESI - Source filename
;; EDI - Destination filename
;;
;; Output:
;;
;; CF set on error or cleared on success

Hexagon.Kernel.FS.VFS.renameFile:

    mov ah, byte[Hexagon.VFS.Control.filesystemType]

    cmp ah, Hexagon.VFS.FS.FAT16B
    je .renameFileFAT16B

    ret

.renameFileFAT16B:

    call Hexagon.Kernel.FS.FAT16.renameFileFAT16B

    ret

;;************************************************************************************

;; Load file into memory (open file)
;;
;; Input:
;;
;; ESI - Name of the file to load
;; EDI - Address of the file to be loaded
;;
;; Output:
;;
;; EAX - File size in bytes
;; CF defined if the file was not found or has an invalid name

Hexagon.Kernel.FS.VFS.openFile:

    mov ah, byte[Hexagon.VFS.Control.filesystemType]

    cmp ah, Hexagon.VFS.FS.FAT16B
    je .openFileFAT16B

    ret

.openFileFAT16B:

    call Hexagon.Kernel.FS.FAT16.loadFileFAT16B

    ret

;;************************************************************************************

;; Check if a file exists on the volume
;;
;; Input:
;;
;; ESI - Filename to check
;;
;; Output:
;;
;; EAX - File size in bytes
;; EBX - Pointer to entry in the root directory
;; CF defined if the file was not found or has an invalid name

Hexagon.Kernel.FS.VFS.fileExists:

    mov ah, byte[Hexagon.VFS.Control.filesystemType]

    cmp ah, Hexagon.VFS.FS.FAT16B
    je .fileExistsFAT16B

    ret

.fileExistsFAT16B:

    call Hexagon.Kernel.FS.FAT16.fileExistsFAT16B

    ret

;;************************************************************************************

Hexagon.Kernel.FS.VFS.mountVolume:

    mov ah, byte[Hexagon.Dev.Gen.Disk.Control.bootDisk]

    mov dl, 01h ;; Storage device class

    call Hexagon.Kernel.Dev.Dev.convertDeviceToDeviceName ;; Convert to device name

;; Enable kernel privileges for privileged request

    mov dword[ordemKernel], kernelExecutePermission

    call Hexagon.Kernel.Dev.Dev.open ;; Open device for read/write with privileges

;; Disable kernel privileges as they are no longer needed

    mov dword[ordemKernel], kernelExecuteDisabled

    ret

;;************************************************************************************

;; Defines the filesystem present on the current volume, obtaining the appropriate
;; information in the MBR (Master Boot Record)

Hexagon.Kernel.FS.VFS.setFilesystem:

    call Hexagon.Kernel.Dev.i386.Disk.Disk.readMBR

    jc .restoreVolume

    mov byte[Hexagon.VFS.Control.filesystemType], ah

    jmp .finish

.restoreVolume:

    mov dl, byte [Hexagon.Dev.Gen.Disk.Control.bootDisk]
    mov byte [Hexagon.Dev.Gen.Disk.Control.currentDisk], dl

    call Hexagon.Kernel.FS.VFS.initFilesystem

    stc

.finish:

    ret

;;************************************************************************************

;; Initializes the filesystem of the mounted volume, for use with the system

Hexagon.Kernel.FS.VFS.initFilesystem:

    call Hexagon.Kernel.Dev.i386.Disk.Disk.testVolume

    jc .volumeNotPresent

.volumePresent:

    mov ah, byte[Hexagon.VFS.Control.filesystemType]

    cmp ah, Hexagon.VFS.FS.FAT16B
    je .initFAT16B

    clc

    ret

.volumeNotPresent:

    mov ah, byte[Hexagon.Dev.Gen.Disk.Control.bootDisk]
    mov byte[Hexagon.Dev.Gen.Disk.Control.currentDisk], ah

    mov ah, byte[Hexagon.VFS.Control.filesystemType]

    cmp ah, Hexagon.VFS.FS.FAT16B
    je .volumeDisconnectedFAT16B

    stc

    ret

;;************************************************************************************
;;
;; Area for implementing implementation/recovery routines of supported filesystems
;;
;;************************************************************************************

.initFAT16B:

    push ebx

    call Hexagon.Kernel.FS.FAT16.initVolumeFAT16B

    pop ebx

    ret

.volumeDisconnectedFAT16B:

    call .initFAT16B

    stc

    ret

;;************************************************************************************

Hexagon.Kernel.FS.VFS.setBootVolume:

;; Will store the volume to be used by the system (can be changed)

    mov dl, byte[Hexagon.Dev.Gen.Disk.Control.bootDisk]
    mov byte[Hexagon.Dev.Gen.Disk.Control.currentDisk], dl

    logHexagon Hexagon.Verbose.definirVolume, Hexagon.Dmesg.Priorities.p5

    ret

;;************************************************************************************

;; Get the volume used by the system
;;
;; Output:
;;
;; DL  - Drive number (0x00, 0x01, 0x80, 0x81, 0x82, 0x83)
;; AH  - Filesystem type
;; ESI - Device name
;; EDI - Label of volume in use

Hexagon.Kernel.FS.VFS.getVolume:

    mov ah, byte[Hexagon.Dev.Gen.Disk.Control.currentDisk] ;; Storage device number
    mov dl, [Hexagon.Dev.DeviceClasses.block] ;; Device class

    call Hexagon.Kernel.Dev.Dev.convertDeviceToDeviceName

    mov edi, Hexagon.VFS.Control.volumeLabel
    mov ah, byte[Hexagon.VFS.Control.filesystemType]

    ret
