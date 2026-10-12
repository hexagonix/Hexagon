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

;; Supported filesystem codes

;; Codes for the main filesystems, supported or not

Hexagon.VFS.FS:

.FAT12    = 01h ;; FAT12 (Future)
.FAT16    = 04h ;; FAT16 (< 32 MB)
.FAT16B   = 06h ;; FAT16B (FAT16B) - Supported
.FAT16LBA = 0Eh ;; FAT16 (LBA)
.DEVFS    = 0FFh ;; Virtual filesystem (/dev), no real media behind it

Hexagon.VFS.Control:

.filesystemType: db 0 ;; Stores which filesystem is present on the volume
.volumeLabel:
times 12 db 0
.volumeSerial:
times 8 db 0

;; Real byte size of Hexagon.VFS.Control. Used to size the
;; filesystemType/volumeLabel portion of a mount save or restore.

Hexagon.VFS.Control.size = $ - Hexagon.VFS.Control

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
.currentDirLBA:        dd 0       ;; LBA of the actual directory
.prevDirLBA:           dd 0       ;; LBA of the previous directory
.sizeFATs:             dw 0       ;; Size in sectors of the FAT(s)
.FAT:                  dd 0       ;; LBA address of FAT
.dataArea:             dd 0       ;; LBA address of the start of the data area
.clusterSize:          dd 0       ;; Cluster size, in bytes
.maxFiles:             dd 1000    ;; Number of files per directory
.hiddenAttribute       equ 00h    ;; Attribute of a hidden file
.systemAttribute       equ 04h    ;; Attribute of a file marked as system file
.setuidAttribute       equ 02h    ;; Combined with .systemAttribute, grants root on exec
.directoryAttribute    equ 10h    ;; Attribute of a directory
.longFilenameAttribute equ 0x0F   ;; Attribute of a long filename (Long File Name)
.unlinkedAttribute     equ 0xE5   ;; Deleted file/free entry attribute
.lastClusterAttribute  equ 0xFFF8 ;; Last cluster in chain attribute
.directoryBit          equ 04h    ;; Bit of a directory = .directoryAttribute, but for bit check
.volumeNameBit         equ 03h    ;; Bit of a volume name (label)
.filenameSeparator     equ 90h    ;; Character used to separate filenames in lists
.directorySeparator    equ 80h    ;; Character used to separate directories in lists

}

;;************************************************************************************

;; Checks whether Hexagon has a filesystem driver for a given filesystem code.
;; Of the codes in Hexagon.VFS.FS, only FAT16B is actually implemented today
;;
;; Input:
;;
;; AL - Filesystem code (Hexagon.VFS.FS)
;;
;; Output:
;;
;; CF set if unsupported

Hexagon.Kernel.FS.VFS.isFilesystemSupported:

    cmp al, Hexagon.VFS.FS.FAT16B
    je .supported

    stc

    ret

.supported:

    clc

    ret

;;************************************************************************************

;; Hexagon file management structures and mount points

include "fs/dir.asm"

;;************************************************************************************

;; Allocates Hexagon.Mounts.Table and points .base at it (see that table's
;; own comment for why it's malloc'd instead of living in Hexagon.Heap).
;; Must run once at boot, after Hexagon.Arch.Mm.initMemory and before
;; Hexagon.Kernel.FS.VFS.registerBootMount
;;
;; Output: empty

Hexagon.Kernel.FS.VFS.allocateMountTable:

    pushad

    push es

    mov ebx, Hexagon.Mounts.Table.byteSize

    call Hexagon.Arch.Mm.malloc

;; Mm.malloc does not clear the memory it hands back, so every slot's own
;; inUse byte starts out as whatever was physically there before, not
;; necessarily 0. Left unzeroed, a slot nobody ever mounted into can still
;; read as in use, showing up as a phantom entry in hx.getMounts

    mov edi, ebx ;; Still flat here, before the  adjustment below

    mov ax, 18h ;; Kernel linear segment, needed to reach this flat pointer
    mov es, ax

    mov ecx, Hexagon.Mounts.Table.byteSize

    xor al, al

    cld

    rep stosb

;; Every segment is based at 0, so Mm.malloc's pointer is already what the
;; [Table.field + reg] accesses below expect


    mov dword[Hexagon.Mounts.Table.base], ebx

    pop es

    popad

    ret

;;************************************************************************************

;; Ensures the mount owning a given path (absolute or, for a relative path,
;; the current directory) has its FAT16 instance loaded into the live
;; Hexagon.VFS.FAT16B working copy, swapping another mount's state out first
;; if needed. Every other register is preserved
;;
;; Input:
;;
;; ESI - Path (absolute or relative)
;;
;; Output:
;;
;; ESI - Path with the matched mount's own path prefix stripped, still
;;       starting with '/' so the FAT16 driver's own absolute-path handling
;;       still applies within that mount

Hexagon.Kernel.FS.VFS.resolveMount:

    pushad

    mov dword[.realPath], esi

;; Normalizes the path (joins it with the current directory if relative,
;; collapses "." and "..") before matching a mount. FAT16 below then sees
;; only a plain downward path already inside the mount that owns it,
;; so it never needs to cross a mount boundary by itself.

    call .buildJoinedPath ;; ESI (given path) -> .joined, absolute but not yet normalized
    call .normalizePath   ;; .joined -> .normalizedPath, "." and ".." collapsed

    mov esi, .normalizedPath

    call .findLongestMount ;; EAX = matched slot, ECX = that mount's own path length

    mov dword[.matchedLength], ecx

    cmp eax, dword[Hexagon.Mounts.loadedSlot]
    je .loaded

    call .swapTo ;; EAX = target slot in

.loaded:

    mov esi, .normalizedPath
    mov ecx, dword[.matchedLength]

    cmp ecx, 1
    je .adjusted ;; Root ("/") is already what the FAT16 driver expects

    add esi, ecx

    cmp byte[esi], 0
    jne .adjusted

    mov esi, .rootRemainder ;; Landed exactly on the mount point; that mount's own root

.adjusted:

    mov dword[.result], esi

    popad

    mov esi, dword[.result]

    ret

;; Input: ESI - Path (absolute, or relative to the current directory)
;; Output: .joined - an absolute path (cwd-joined if the input was
;;         relative), not yet normalized, may still contain "." or ".."

.buildJoinedPath:

    mov dword[.rawInput], esi

    cmp byte[esi], '/'
    je .copyRawAbsolute

    movzx esi, byte[Hexagon.Scheduler.current]
    imul esi, 64
    add esi, Hexagon.Processes.Table.cwd

    mov edi, .joined
    xor ecx, ecx

.copyCwdLoop:

    mov al, byte[esi + ecx]

    cmp al, 0
    je .cwdDone

    cmp ecx, 126
    jae .cwdDone

    mov byte[edi + ecx], al

    inc ecx

    jmp .copyCwdLoop

.cwdDone:

;; Skip the separator if the current directory is already just "/", so this
;; doesn't produce a doubled leading slash

    cmp ecx, 1
    jne .addSeparator

    cmp byte[edi], '/'
    je .copyRawRelative

.addSeparator:

    cmp ecx, 128
    jae .copyRawRelative

    mov byte[edi + ecx], '/'

    inc ecx

.copyRawRelative:

    mov esi, dword[.rawInput]

.copyRawLoop:

    mov al, byte[esi]

    mov byte[edi + ecx], al

    cmp al, 0
    je .buildDone

    inc esi
    inc ecx

    cmp ecx, 129
    jb .copyRawLoop

    mov byte[edi + ecx], 0 ;; Out of room. Truncate instead of overflowing .joined

    jmp .buildDone

.copyRawAbsolute:

    mov esi, dword[.rawInput]
    mov edi, .joined
    xor ecx, ecx

.copyAbsLoop:

    mov al, byte[esi + ecx]

    mov byte[edi + ecx], al

    cmp al, 0
    je .buildDone

    inc ecx

    cmp ecx, 129
    jb .copyAbsLoop

    mov byte[edi + ecx], 0

.buildDone:

    ret

.rawInput: dd 0

;; Input: .joined - absolute path, possibly with "." or ".." components
;; Output: .normalizedPath - the same path with "." and ".." collapsed,
;;         always starting with '/'

.normalizePath:

    push esi
    push edi
    push eax
    push ecx

    mov byte[.normalizedPath], '/'
    mov byte[.normalizedPath + 1], 0
    mov dword[.normalizedLen], 1

    mov esi, .joined

.normalizeLoop:

;; ES is still kernelLinear here, as nextPathComponent's own write needs

    call Hexagon.Kernel.FS.FAT16.nextPathComponent

    jc .normalizeDone ;; Nothing more to fold in

    cmp byte[edi], '.'
    jne .appendComponent

    cmp byte[edi + 1], 0
    je .normalizeLoop ;; "." stays put

    cmp byte[edi + 1], '.'
    jne .appendComponent

    cmp byte[edi + 2], 0
    jne .appendComponent

    call .popComponent

    jmp .normalizeLoop

.appendComponent:

    call .appendComponentToNormalized

    jmp .normalizeLoop

.normalizeDone:

    pop ecx
    pop eax
    pop edi
    pop esi

    ret

;; Removes the last '/'-delimited component from .normalizedPath, or does
;; nothing if it's already just "/". ".." beyond root stays at root.

.popComponent:

    push eax
    push ecx

    mov ecx, dword[.normalizedLen]

    cmp ecx, 1
    je .popDone

.popScan:

    dec ecx

    cmp byte[.normalizedPath + ecx], '/'
    jne .popScan

    cmp ecx, 0
    je .popFoundRoot

    mov dword[.normalizedLen], ecx
    mov byte[.normalizedPath + ecx], 0

    jmp .popDone

.popFoundRoot:

    mov dword[.normalizedLen], 1
    mov byte[.normalizedPath + 1], 0

.popDone:

    pop ecx
    pop eax

    ret

;; Input: EDI - null-terminated component (from nextPathComponent, so
;;        already capped to 12 characters) to append to .normalizedPath

.appendComponentToNormalized:

    push eax
    push ecx
    push esi

    mov esi, edi
    mov ecx, dword[.normalizedLen]

    cmp ecx, 1
    je .appendNoSeparator ;; Already just "/". No separator needed

    cmp ecx, 128
    jae .appendDone ;; No room even for a separator. Drop the rest silently

    mov byte[.normalizedPath + ecx], '/'

    inc ecx

.appendNoSeparator:

.appendCharLoop:

    mov al, byte[esi]

    cmp al, 0
    je .appendFinished

    cmp ecx, 129
    jae .appendFinished ;; Out of room. Truncate, do not overflow

    mov byte[.normalizedPath + ecx], al

    inc ecx
    inc esi

    jmp .appendCharLoop

.appendFinished:

    mov byte[.normalizedPath + ecx], 0
    mov dword[.normalizedLen], ecx

.appendDone:

    pop esi
    pop ecx
    pop eax

    ret

.realPath:       dd 0
.matchedLength:  dd 0
.result:         dd 0
.rootRemainder:  db "/", 0
.joined:         times 130 db 0
.normalizedPath: times 130 db 0
.normalizedLen:  dd 0

;; Input: ESI - Path to match (absolute, or the current directory)
;; Output: EAX - Matched mount slot; ECX - That mount's own path length

.findLongestMount:

    push ebx
    push edx
    push esi

    mov dword[.bestSlot], 0
    mov dword[.bestLength], 0

    mov ebx, 0

.nextSlot:

    cmp ebx, Hexagon.Mounts.Table.limit
    jae .searchDone

    mov edx, dword[Hexagon.Mounts.Table.base]

    cmp byte[edx + Hexagon.Mounts.Table.inUse + ebx], 0
    je .skipSlot

    mov edx, ebx
    shl edx, 6 ;; 64 bytes per path slot
    add edx, dword[Hexagon.Mounts.Table.base]
    add edx, Hexagon.Mounts.Table.path

    call .prefixMatches ;; ESI unchanged; EDX = candidate mount path; EAX = length or -1

    cmp eax, 0
    jl .skipSlot

    cmp eax, dword[.bestLength]
    jle .skipSlot

    mov dword[.bestLength], eax
    mov dword[.bestSlot], ebx

.skipSlot:

    inc ebx

    jmp .nextSlot

.searchDone:

    pop esi

    mov eax, dword[.bestSlot]
    mov ecx, dword[.bestLength]

    pop edx
    pop ebx

    ret

.bestSlot:  dd 0
.bestLength: dd 0

;; Input: ESI - Path, EDX - Candidate mount path (null-terminated)
;; Output: EAX - Length of EDX if it is a genuine prefix of ESI at a path
;;         component boundary, -1 otherwise. ESI/EDX unchanged

.prefixMatches:

    push ebx
    push esi
    push edx

    xor eax, eax

.compareLoop:

    mov bl, byte[edx]

    cmp bl, 0
    je .prefixEnded

    cmp bl, byte[esi]
    jne .noMatch

    inc esi
    inc edx
    inc eax

    jmp .compareLoop

.prefixEnded:

    cmp eax, 1
    je .done ;; Root ("/") always matches, whatever follows it

    cmp byte[esi], 0
    je .done

    cmp byte[esi], '/'
    je .done

.noMatch:

    mov eax, -1

.done:

    pop edx
    pop esi
    pop ebx

    ret

;; Saves the currently loaded mount's live state back to its own table
;; entry (if any is loaded), then loads the target mount's saved state into
;; the live working copy
;;
;; Input: EAX - Target mount slot to load

.swapTo:

;; Masked for the whole swap, and not only the copies, since a preempted
;; mid-copy would interleave two swaps against the same shared state.
;; Safe to mask since nothing here touches disk I/O or waits on an
;; interrupt.

    pushfd
    cli

    mov dword[.target], eax

    push esi
    push edi
    push ecx
    push es

;; The disk calls hand ES back on the kernel linear selector, and the
;; memcpys below write through ES:EDI, so ES is put on the kernel data
;; selector first

    mov ax, 10h
    mov es, ax

    mov ecx, dword[Hexagon.Mounts.loadedSlot]

    cmp ecx, 0xFFFFFFFF
    je .skipSave

;; Saves the loaded slot's live Control then FAT into its own
;; Hexagon.Mounts.Table.state entry, matching that field's own layout.
;; EDI needs no reset between the two copies, since FAT follows Control
;; directly in that same slot entry.

    imul ecx, Hexagon.VFS.Control.size + Hexagon.VFS.FAT.instanceSize

    mov edi, dword[Hexagon.Mounts.Table.base]

    add edi, Hexagon.Mounts.Table.state
    add edi, ecx

    mov esi, Hexagon.VFS.Control
    mov ecx, Hexagon.VFS.Control.size

    cld

    rep movsb

    mov esi, Hexagon.VFS.FAT16B
    mov ecx, Hexagon.VFS.FAT.instanceSize

    rep movsb

.skipSave:

;; Loads the target slot's saved Control then FAT, the mirror of the save
;; above. EDI needs the reset between copies here, not ESI.

    mov eax, dword[.target]

    imul eax, Hexagon.VFS.Control.size + Hexagon.VFS.FAT.instanceSize

    mov esi, dword[Hexagon.Mounts.Table.base]

    add esi, Hexagon.Mounts.Table.state
    add esi, eax

    mov edi, Hexagon.VFS.Control
    mov ecx, Hexagon.VFS.Control.size

    cld

    rep movsb

    mov edi, Hexagon.VFS.FAT16B
    mov ecx, Hexagon.VFS.FAT.instanceSize

    rep movsb

    mov eax, dword[.target]
    mov dword[Hexagon.Mounts.loadedSlot], eax

;; Every low-level FAT16 disk read/write pulls its drive number from
;; Control.currentDisk, so the swap isn't complete without this

    push ebx

    mov ebx, dword[Hexagon.Mounts.Table.base]
    mov al, byte[ebx + Hexagon.Mounts.Table.drive + eax]

    pop ebx

    mov byte[Hexagon.Dev.Disk.Control.currentDisk], al

    pop es
    pop ecx
    pop edi
    pop esi

    popfd

    ret

.target: dd 0

;;************************************************************************************

;; Registers the boot volume as mount slot 0 ("/"), saving the FAT16
;; instance state Hexagon.Kernel.FS.VFS.initFilesystem just populated. Must
;; run after initFilesystem and before any call that goes through
;; Hexagon.Kernel.FS.VFS.resolveMount
;;
;; Output: empty

Hexagon.Kernel.FS.VFS.registerBootMount:

    pushad
    push es

;; The disk read/write path resets ES to kernelLinear after every call, and
;; pushad/popad don't cover ES. Establishing the root volume just made
;; several such calls, so ES needs resetting before the rep movsb below

    mov ax, 10h
    mov es, ax

    mov edi, dword[Hexagon.Mounts.Table.base]

    mov byte[edi + Hexagon.Mounts.Table.inUse + 0], 1

    mov al, byte[Hexagon.Dev.Disk.Control.currentDisk]
    mov byte[edi + Hexagon.Mounts.Table.drive + 0], al

;; Gives the boot mount the same "hd0p0"-style deviceName hx.mount would
;; assign. The partition index is always 0, since Saturno/HBoot always
;; boot from a disk's first primary partition, so only the disk slot needs
;; looking up

    mov al, byte[Hexagon.Dev.Disk.Control.bootDisk]

    xor ebx, ebx
    mov edx, dword[Hexagon.Disks.Table.base]

.findBootDiskSlot:

    cmp ebx, Hexagon.Disks.Table.limit
    jae .noBootDiskSlot

    cmp byte[edx + Hexagon.Disks.Table.present + ebx], 0
    je .nextBootDiskSlot

    cmp byte[edx + Hexagon.Disks.Table.drive + ebx], al
    je .haveBootDiskSlot

.nextBootDiskSlot:

    inc ebx

    jmp .findBootDiskSlot

.haveBootDiskSlot:

    mov edi, dword[Hexagon.Mounts.Table.base]
    add edi, Hexagon.Mounts.Table.deviceName

    mov byte[edi + 0], 'h'
    mov byte[edi + 1], 'd'

    mov al, bl
    add al, '0'

    mov byte[edi + 2], al
    mov byte[edi + 3], 'p'
    mov byte[edi + 4], '0'
    mov byte[edi + 5], 0

.noBootDiskSlot:

    mov esi, .rootPath

    mov edi, dword[Hexagon.Mounts.Table.base]
    add edi, Hexagon.Mounts.Table.path

    mov ecx, 2 ;; "/" plus the null terminator

    cld

    rep movsb

;; Control first, then FAT, matching the layout Hexagon.Mounts.Table.state's
;; own comment documents, and what .swapTo itself later assumes

    mov esi, Hexagon.VFS.Control
    mov edi, dword[Hexagon.Mounts.Table.base]

    add edi, Hexagon.Mounts.Table.state

    mov ecx, Hexagon.VFS.Control.size

    rep movsb

    mov esi, Hexagon.VFS.FAT16B
    mov ecx, Hexagon.VFS.FAT.instanceSize

    rep movsb

    mov dword[Hexagon.Mounts.loadedSlot], 0

    pop es
    popad

    ret

.rootPath: db "/", 0

;;************************************************************************************

;; Mounts a disk's filesystem at a directory in the namespace. Only root may
;; mount. If the device path names a whole disk, its first supported
;; partition is used. The mount point must already exist as a directory.
;;
;; Reads the target partition's own BPB directly through .findSupportedPartition,
;; never through the generic device-open dispatch: the same reasoning the boot
;; mount itself follows
;;
;; Input:
;;
;; ESI - Device path (such as "/dev/hd1" or, relative to a devfs mount,
;;       "hd1p0"), or the reserved name "devfs"
;; EDI - Mount point path
;;
;; Output:
;;
;; EAX - Error code:
;;       01h - Permission denied
;;       02h - Device not found, or none of its partitions are supported
;;       03h - Mount point doesn't exist, isn't a directory, or its path is
;;             too long for a mount point
;;       04h - No free mount slots
;;       05h - Failed to read the partition's own BPB
;; CF set on error

Hexagon.Kernel.FS.VFS.mount:

    mov dword[.mountPath], edi ;; Save before EDI gets clobbered below
    mov dword[.deviceName], esi ;; Save before ESI gets clobbered below

    call Hexagon.Kern.Users.getUserPermissions

    cmp eax, 03h ;; Group code for default user
    jne .haveRoot

    mov eax, 01h

    stc

    ret

.haveRoot:

;; .loadPartitionBPB below writes straight into the shared working copy
;; before it is saved off, so this stays masked to avoid corrupting it if
;; another process's VFS call lands mid-write. See
;; Hexagon.Scheduler.preemptionDisabled

    call Hexagon.Kern.Sched.disablePreemption

    mov byte[.isDevFS], 0

;; "devfs" is a reserved device name for Hexagon.VFS.FS.DEVFS, a synthetic
;; mount with no partition or BPB behind it, checked before the real disk
;; name convention below

    mov edi, .devfsName

    call Hexagon.Libkern.String.compareWordsInString

    jc .mountDevFS

;; The device argument is resolved as a path, the same way any other path
;; is. A bare name only matches something when the current directory is
;; itself a devfs mount

    mov esi, dword[.deviceName]

    call Hexagon.Kernel.FS.VFS.fileExists

    jc .noDevice

    cmp byte[Hexagon.VFS.Control.filesystemType], Hexagon.VFS.FS.DEVFS
    jne .noDevice

;; Hexagon.Kernel.FS.VFS.fileExists above already returns the matched
;; entry's Hexagon.Dev.Registry class in EBX, major/minor packed in EDX

    cmp ebx, 01h ;; Hexagon.Dev.DeviceClasses.block
    jne .noDevice

    movzx eax, dh ;; Major: disk slot
    movzx edx, dl ;; Minor: partition index, or 0FFh for none

    cmp edx, 0FFh
    jne .explicitPartitionGiven

    mov edx, 0xFFFFFFFF ;; .findSupportedPartition's own "no explicit index" sentinel

.explicitPartitionGiven:

    mov dword[.explicitPartition], edx

    call .findSupportedPartition ;; Input: EAX = disk slot. Output: EAX = partition slot

    jc .noDevice

    mov dword[.partitionSlot], eax

    jmp .validateMountPoint

.mountDevFS:

    mov byte[.isDevFS], 1

.validateMountPoint:

;; Validate the mount point: must exist and be a directory

    mov esi, dword[.mountPath]

    call Hexagon.Kernel.FS.VFS.fileExists

    jc .badMountPoint

;; The normalized path resolveMount already produced is what gets stored, not
;; the raw argument. A relative mount point would never match
;; Hexagon.Kernel.FS.VFS.resolveMount's own prefix matching later, leaving the
;; mount silently unreachable

    mov dword[.mountPath], Hexagon.Kernel.FS.VFS.resolveMount.normalizedPath

;; Must still fit a slot once normalized

    mov esi, dword[.mountPath]

    call Hexagon.Libkern.String.stringSize

    cmp eax, 63
    jae .badMountPoint

;; 10h (Hexagon.VFS.FAT.directoryAttribute) written directly: that field is
;; an "equ" text macro, scoped to its struc, not forward-referenceable from
;; here the way a real symbol would be. ECX is the attribute byte
;; Hexagon.Kernel.FS.VFS.fileExists above already read out of the record

    test ecx, 10h

    jz .badMountPoint

;; Same device already mounted here succeeds as a no-op, so repeated
;; mount requests for it stay idempotent. A different device already
;; mounted here is refused, since a mount point backs one
;; volume at a time

    xor ebx, ebx

.checkExistingMount:

    cmp ebx, Hexagon.Mounts.Table.limit
    jae .noExistingMount

    mov edx, dword[Hexagon.Mounts.Table.base]

    cmp byte[edx + Hexagon.Mounts.Table.inUse + ebx], 0
    je .nextExistingMount

    mov edi, edx
    add edi, Hexagon.Mounts.Table.path

    mov eax, ebx

    shl eax, 6
    
    add edi, eax

    mov esi, dword[.mountPath]

    call Hexagon.Libkern.String.compareWordsInString

    jnc .nextExistingMount ;; Different mount point, not a conflict

    mov edi, edx
    
    add edi, Hexagon.Mounts.Table.deviceName

    mov eax, ebx
    
    shl eax, 5
    
    add edi, eax

    mov esi, dword[.deviceName]

    call Hexagon.Libkern.String.compareWordsInString

    jc .alreadyMounted

    jmp .mountPointBusy

.nextExistingMount:

    inc ebx

    jmp .checkExistingMount

.alreadyMounted:

    call Hexagon.Kern.Sched.enablePreemption

    xor eax, eax

    clc

    ret

.mountPointBusy:

    call Hexagon.Kern.Sched.enablePreemption

    mov eax, 06h

    stc

    ret

.noExistingMount:

;; Find a free mount slot

    call .findFreeSlot

    jc .noFreeSlots

    mov dword[.newSlot], eax

    cmp byte[.isDevFS], 0
    jne .devfsState

;; .loadPartitionBPB below overwrites the live working copy. Whichever
;; mount is currently loaded needs its state saved into its own table slot
;; first, the same save .swapTo does, since this new mount becomes the
;; loaded slot directly below without ever going through .swapTo itself

    mov eax, dword[Hexagon.Mounts.loadedSlot]

    cmp eax, 0xFFFFFFFF
    je .noPreviousToSave

    push ecx
    push es

;; hexagonHandler leaves ES at kernelLinear for every syscall, and rep
;; movsb writes through ES:EDI. Same fix as every other
;; Hexagon.Mounts.Table.state writer

    mov ax, 10h
    mov es, ax

    mov eax, dword[Hexagon.Mounts.loadedSlot]

    imul eax, Hexagon.VFS.Control.size + Hexagon.VFS.FAT.instanceSize

    mov edi, dword[Hexagon.Mounts.Table.base]

    add edi, Hexagon.Mounts.Table.state
    add edi, eax

    mov esi, Hexagon.VFS.Control
    mov ecx, Hexagon.VFS.Control.size

    cld

    rep movsb

    mov esi, Hexagon.VFS.FAT16B
    mov ecx, Hexagon.VFS.FAT.instanceSize

    rep movsb

    pop es
    pop ecx

.noPreviousToSave:

;; Read the partition's own BPB and populate the live working copy from it

    mov eax, dword[.partitionSlot]

    call .loadPartitionBPB

    jc .badBPB

;; .loadPartitionBPB's own disk reads reset ES to kernelLinear. Both
;; rep movsb below write through ES:EDI, so ES needs resetting first.

    push eax

    mov ax, 10h
    mov es, ax

    pop eax

;; Saves the freshly populated live state into the new mount slot, Control
;; then FAT, matching Hexagon.Mounts.Table.state's own layout.

    mov eax, dword[.newSlot]
    mov edi, dword[Hexagon.Mounts.Table.base]

    add edi, Hexagon.Mounts.Table.state

    imul eax, Hexagon.VFS.Control.size + Hexagon.VFS.FAT.instanceSize

    add edi, eax

    mov esi, Hexagon.VFS.Control
    mov ecx, Hexagon.VFS.Control.size

    cld

    rep movsb

    mov esi, Hexagon.VFS.FAT16B
    mov ecx, Hexagon.VFS.FAT.instanceSize

    rep movsb

;; Record which drive backs this mount, and make it the loaded one

    mov eax, dword[.partitionSlot]
    mov edx, dword[Hexagon.Partitions.Table.base]
    movzx ebx, byte[edx + Hexagon.Partitions.Table.diskSlot + eax]
    mov edx, dword[Hexagon.Disks.Table.base]
    mov al, byte[edx + Hexagon.Disks.Table.drive + ebx]

    mov ebx, dword[.newSlot]
    mov edx, dword[Hexagon.Mounts.Table.base]
    mov byte[edx + Hexagon.Mounts.Table.drive + ebx], al

    mov dword[Hexagon.Mounts.loadedSlot], ebx

;; .swapTo normally sets this, but this slot is marked loaded directly here
;; instead of swapped in. Without it, the first operation on a freshly
;; mounted volume would still use the previously loaded drive.

    mov byte[Hexagon.Dev.Disk.Control.currentDisk], al

    jmp .copyMountPathAndName

;; Writes straight into the new slot, leaving the live working copy and
;; Hexagon.Mounts.loadedSlot untouched. The first real resolveMount into
;; /dev loads this slot for real, through .swapTo.

.devfsState:

    mov eax, dword[.newSlot]

    imul eax, Hexagon.VFS.Control.size + Hexagon.VFS.FAT.instanceSize

    mov edi, dword[Hexagon.Mounts.Table.base]

    add edi, Hexagon.Mounts.Table.state
    add edi, eax

;; hexagonHandler leaves ES at kernelLinear for every syscall, and stosb
;; below writes through ES:EDI

    mov ax, 10h
    mov es, ax

    mov byte[edi], Hexagon.VFS.FS.DEVFS ;; Hexagon.VFS.Control's first field

    inc edi

    mov ecx, Hexagon.VFS.Control.size + Hexagon.VFS.FAT.instanceSize
    dec ecx

    xor al, al

    cld
    rep stosb ;; The rest of this slot's state carries no real meaning

;; No real drive backs a devfs mount

    mov ebx, dword[.newSlot]
    mov edx, dword[Hexagon.Mounts.Table.base]
    mov byte[edx + Hexagon.Mounts.Table.drive + ebx], 0

.copyMountPathAndName:

;; Copy the mount point path into the slot

    mov edi, dword[Hexagon.Mounts.Table.base]

    add edi, Hexagon.Mounts.Table.path

    mov eax, ebx

    shl eax, 6
    add edi, eax

    mov esi, dword[.mountPath]

    call Hexagon.Libkern.String.stringSize

    mov ecx, eax

    inc ecx ;; Include the null terminator

    mov esi, dword[.mountPath]

    cld

    rep movsb

;; Copy the device name into the slot, capped to 31 chars + NUL so it
;; always fits within the fixed 32-byte field, NUL-padding the rest, the
;; same approach as Hexagon.Kern.Proc.getProcessTable's own name field

    mov edi, dword[Hexagon.Mounts.Table.base]

    add edi, Hexagon.Mounts.Table.deviceName

    mov eax, ebx

    shl eax, 5

    add edi, eax

    mov esi, dword[.deviceName]

    push ebx

    xor ebx, ebx

.measureDeviceName:

    cmp ebx, 31
    jae .deviceNameMeasured

    cmp byte[esi + ebx], 0
    je .deviceNameMeasured

    inc ebx

    jmp .measureDeviceName

.deviceNameMeasured:

    mov ecx, ebx

    rep movsb ;; Copy the real device name characters

    mov ecx, 32
    sub ecx, ebx

    xor al, al

    rep stosb ;; NUL-terminate and pad out the rest of the device name field

    pop ebx

    mov edx, dword[Hexagon.Mounts.Table.base]
    mov byte[edx + Hexagon.Mounts.Table.inUse + ebx], 1

;; Builds "Mounted <device> on <path>" into the shared Hexagon.Heap.Temp
;; scratch buffer, the same piecewise copy Hexagon.userMode already uses
;; for its own boot-time mount message, then logs it like any other
;; kernel message

    mov edi, Hexagon.Heap.Temp

    mov esi, Hexagon.Verbose.mounted

.buildMountedPrefix:

    mov al, byte[esi]

    cmp al, 0
    je .buildMountedPrefixDone

    mov byte[edi], al

    inc esi
    inc edi

    jmp .buildMountedPrefix

.buildMountedPrefixDone:

    mov esi, dword[.deviceName]

.buildMountedDevice:

    mov al, byte[esi]

    cmp al, 0
    je .buildMountedDeviceDone

    mov byte[edi], al

    inc esi
    inc edi

    jmp .buildMountedDevice

.buildMountedDeviceDone:

    mov esi, Hexagon.Verbose.mountedOn

.buildMountedOn:

    mov al, byte[esi]

    cmp al, 0
    je .buildMountedOnDone

    mov byte[edi], al

    inc esi
    inc edi

    jmp .buildMountedOn

.buildMountedOnDone:

    mov esi, dword[.mountPath]

.buildMountedPath:

    mov al, byte[esi]

    mov byte[edi], al

    cmp al, 0
    je .buildMountedDone

    inc esi
    inc edi

    jmp .buildMountedPath

.buildMountedDone:

;; A mount is a kernel-level event, recorded in Hexagon.Kern.Dmesg's own
;; buffer even when userland asked for it. createMessage would otherwise tag it
;; by the calling process and skip the buffer, so systemCall is cleared for
;; this one call. Serial and the buffer only, never the screen

    mov al, byte[Hexagon.Syscall.Control.systemCall]
    push eax

    mov byte[Hexagon.Syscall.Control.systemCall], 0

    logHexagon Hexagon.Heap.Temp, Hexagon.Dmesg.Priorities.p4

    pop eax
    mov byte[Hexagon.Syscall.Control.systemCall], al

    call Hexagon.Kern.Sched.enablePreemption

    xor eax, eax

    clc

    ret

.noDevice:

    call Hexagon.Kern.Sched.enablePreemption

    mov eax, 02h

    stc

    ret

.badMountPoint:

    call Hexagon.Kern.Sched.enablePreemption

    mov eax, 03h

    stc

    ret

.noFreeSlots:

    call Hexagon.Kern.Sched.enablePreemption

    mov eax, 04h

    stc

    ret

.badBPB:

    call Hexagon.Kern.Sched.enablePreemption

    mov eax, 05h

    stc

    ret

.partitionSlot: dd 0
.newSlot:       dd 0
.mountPath:     dd 0
.deviceName:    dd 0
.isDevFS:       db 0
.devfsName:     db "devfs", 0

;; Set from Hexagon.Dev.Registry's minor field by
;; Hexagon.Kernel.FS.VFS.mount before calling .findSupportedPartition below:
;; the partition index (0-3), or 0xFFFFFFFF for "no explicit partition, use
;; the first supported one"

.explicitPartition: dd 0xFFFFFFFF

;; Input:
;;
;; EAX - Disk slot
;;
;; Output:
;;
;; EAX - The Hexagon.Partitions.Table entry on that disk matching
;;       .explicitPartition's index, if not 0xFFFFFFFF, otherwise the
;;       first entry present there Hexagon supports. CF set if none found
;;       (or the explicit one isn't present/supported)

.findSupportedPartition:

    push ebx
    push ecx
    push edx

    mov ecx, eax
    mov edx, dword[.explicitPartition]
    mov ebx, 0
    mov eax, dword[Hexagon.Partitions.Table.base]

.nextPartition:

    cmp ebx, Hexagon.Partitions.Table.limit
    jae .nonePartition

    cmp byte[eax + Hexagon.Partitions.Table.present + ebx], 0
    je .skipPartition

    push eax

    movzx eax, byte[eax + Hexagon.Partitions.Table.diskSlot + ebx]

    cmp eax, ecx

    pop eax

    jne .skipPartition

    cmp edx, 0xFFFFFFFF
    je .noExplicitIndex

    push eax

    movzx eax, byte[eax + Hexagon.Partitions.Table.index + ebx]

    cmp eax, edx

    pop eax

    jne .skipPartition

.noExplicitIndex:

    cmp byte[eax + Hexagon.Partitions.Table.supported + ebx], 0
    je .skipPartition

    mov eax, ebx

    pop edx
    pop ecx
    pop ebx

    clc

    ret

.skipPartition:

    inc ebx

    jmp .nextPartition

.nonePartition:

    pop edx
    pop ecx
    pop ebx

    stc

    ret

;; Output: EAX - First free (inUse=0) mount slot. CF set if the table is full

.findFreeSlot:

    push ebx
    push edx

    mov ebx, 0
    mov edx, dword[Hexagon.Mounts.Table.base]

.nextMountSlot:

    cmp ebx, Hexagon.Mounts.Table.limit
    jae .noneFree

    cmp byte[edx + Hexagon.Mounts.Table.inUse + ebx], 0
    je .foundFree

    inc ebx

    jmp .nextMountSlot

.foundFree:

    mov eax, ebx

    pop edx
    pop ebx

    clc

    ret

.noneFree:

    pop edx
    pop ebx

    stc

    ret

;; Reads a partition's own BPB via a safe, non-panicking sector read (does
;; not reach readSectors' panic/volume-reset paths) and populates the live
;; Hexagon.VFS.FAT16B working copy from it, the same way
;; Hexagon.Kernel.FS.FAT16.initVolumeFAT16B does for the boot volume
;;
;; Input:
;;
;; EAX - Slot in Hexagon.Partitions.Table
;;
;; Output:
;;
;; CF set if the BPB couldn't be read

.loadPartitionBPB:

    push ebx
    push ecx
    push edx
    push esi
    push edi

    mov edi, dword[Hexagon.Partitions.Table.base]
    movzx ebx, byte[edi + Hexagon.Partitions.Table.diskSlot + eax]

    mov edi, dword[Hexagon.Disks.Table.base]
    mov dl, byte[edi + Hexagon.Disks.Table.drive + ebx]

    mov byte[Hexagon.Dev.Disk.Control.currentDisk], dl

    mov edi, dword[Hexagon.Partitions.Table.base]
    mov esi, dword[edi + Hexagon.Partitions.Table.startLBA + eax * 4]
    mov dword[.partitionStartLBA], esi

    mov cx, 0 ;; Destination is a flat address, no segment to fold in
    mov edi, Hexagon.Heap.DiskGeometry

    call Hexagon.Kernel.Dev.Disk.Disk.tryReadSector

    jc .fail

    mov dword[Hexagon.Dev.Disk.Control.diskGeometry], Hexagon.Heap.DiskGeometry

;; getFilesystemInfoFAT16B's field offsets are relative to the BPB proper,
;; 3 bytes past the sector's leading jmp/nop, and a raw sector read lands at
;; the true sector start

    mov esi, Hexagon.Heap.DiskGeometry + 3

    call Hexagon.Kernel.FS.FAT16.getFilesystemInfoFAT16B
    call Hexagon.Kernel.FS.FAT16.getVolumeLabelFAT16B

;; getFilesystemInfoFAT16B's LBA fields are relative to this partition's
;; own BPB sector, not real disk LBAs. Adds the partition's start LBA to
;; make them absolute, since a mount has no other help doing so.

    mov eax, dword[.partitionStartLBA]

    add dword[Hexagon.VFS.FAT16B.rootDir], eax
    add dword[Hexagon.VFS.FAT16B.currentDirLBA], eax
    add dword[Hexagon.VFS.FAT16B.prevDirLBA], eax
    add dword[Hexagon.VFS.FAT16B.dataArea], eax
    add dword[Hexagon.VFS.FAT16B.FAT], eax

    clc

    jmp .done

.fail:

    stc

.done:

    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx

    ret

.partitionStartLBA: dd 0

;;************************************************************************************

;; Unmounts whatever is registered at a given mount point path. Only root
;; may unmount. Slot 0 ("/") can never be unmounted
;;
;; Input:
;;
;; ESI - Mount point path
;;
;; Output:
;;
;; EAX - Error code:
;;       01h - Permission denied
;;       02h - Nothing mounted at that path
;;       03h - Refusing to unmount "/"
;; CF set on error

Hexagon.Kernel.FS.VFS.unmount:

    call Hexagon.Kern.Users.getUserPermissions

    cmp eax, 03h
    jne .haveRoot

    mov eax, 01h

    stc

    ret

.haveRoot:

;; A process preempted between the two writes below, resumed after another
;; process's resolveMount ran against the half-updated table, would see an
;; inconsistent view. See Hexagon.Scheduler.preemptionDisabled

    call Hexagon.Kern.Sched.disablePreemption

;; Hexagon.Mounts.Table.path is always stored normalized (see
;; Hexagon.Kernel.FS.VFS.mount), so a relative or "."/".."-laden argument
;; here needs the same normalization before .findMountByPath's exact
;; string match has any chance of finding it

    call Hexagon.Kernel.FS.VFS.resolveMount.buildJoinedPath
    call Hexagon.Kernel.FS.VFS.resolveMount.normalizePath

    mov esi, Hexagon.Kernel.FS.VFS.resolveMount.normalizedPath

    call .findMountByPath

    jc .notFound

    cmp eax, 0
    je .isRoot

    push ebx

    mov ebx, dword[Hexagon.Mounts.Table.base]

;; Written to physical media before this mount's slot is torn down, not on
;; every write. See Hexagon.Dev.ATA.flushCache's own comment. EAX/EBX
;; preserved by flushDisk. EDX is not, but nothing below needs it

    mov dl, byte[ebx + Hexagon.Mounts.Table.drive + eax]

    call Hexagon.Kernel.Dev.Disk.Disk.flushDisk

    mov byte[ebx + Hexagon.Mounts.Table.inUse + eax], 0

    pop ebx

;; If the unmounted slot was the one currently loaded, nothing is loaded
;; anymore. The next resolveMount call will load whichever mount it needs

    cmp eax, dword[Hexagon.Mounts.loadedSlot]
    jne .done

    mov dword[Hexagon.Mounts.loadedSlot], 0xFFFFFFFF

.done:

;; Builds "Unmounted <path>" into the shared Hexagon.Heap.Temp scratch
;; buffer, same piecewise copy Hexagon.Kernel.FS.VFS.mount's own success
;; path uses, then logs it like any other kernel message

    mov edi, Hexagon.Heap.Temp

    mov esi, Hexagon.Verbose.unmounted

.buildUnmountedPrefix:

    mov al, byte[esi]

    cmp al, 0
    je .buildUnmountedPrefixDone

    mov byte[edi], al

    inc esi
    inc edi

    jmp .buildUnmountedPrefix

.buildUnmountedPrefixDone:

    mov esi, Hexagon.Kernel.FS.VFS.resolveMount.normalizedPath

.buildUnmountedPath:

    mov al, byte[esi]

    mov byte[edi], al

    cmp al, 0
    je .buildUnmountedDone

    inc esi
    inc edi

    jmp .buildUnmountedPath

.buildUnmountedDone:

;; Same reasoning as Hexagon.Kernel.FS.VFS.mount's own success path: force
;; the kernel-origin path so this reaches Hexagon.Kern.Dmesg's own buffer,
;; serial and the buffer only, no screen output

    mov al, byte[Hexagon.Syscall.Control.systemCall]
    push eax

    mov byte[Hexagon.Syscall.Control.systemCall], 0

    logHexagon Hexagon.Heap.Temp, Hexagon.Dmesg.Priorities.p4

    pop eax
    mov byte[Hexagon.Syscall.Control.systemCall], al

    call Hexagon.Kern.Sched.enablePreemption

    xor eax, eax

    clc

    ret

.isRoot:

    call Hexagon.Kern.Sched.enablePreemption

    mov eax, 03h

    stc

    ret

.notFound:

    call Hexagon.Kern.Sched.enablePreemption

    mov eax, 02h

    stc

    ret

;; Input:
;;
;; ESI - Path to match exactly
;;
;; Output:
;;
;; EAX - Matching in-use mount slot; CF set if none

.findMountByPath:

    push ebx
    push edx

    mov ebx, 0

.next:

    cmp ebx, Hexagon.Mounts.Table.limit
    jae .none

    mov edx, dword[Hexagon.Mounts.Table.base]

    cmp byte[edx + Hexagon.Mounts.Table.inUse + ebx], 0
    je .skip

    mov edx, ebx

    shl edx, 6

    add edx, dword[Hexagon.Mounts.Table.base]
    add edx, Hexagon.Mounts.Table.path

    call .stringsEqual

    jne .skip

    mov eax, ebx

    pop edx
    pop ebx

    clc

    ret

.skip:

    inc ebx

    jmp .next

.none:

    pop edx
    pop ebx

    stc

    ret

;; Input:
;;
;; ESI - string A, EDX - string B
;;
;; Output:
;;
;; ZF set if equal. ESI/EDX unchanged

.stringsEqual:

    push eax
    push ebx
    push esi
    push edx

.cmpLoop:

    mov al, byte[esi]
    mov bl, byte[edx]

    cmp al, bl
    jne .mismatch

    cmp al, 0
    je .matched

    inc esi
    inc edx

    jmp .cmpLoop

.matched:

;; ZF is set here, from the cmp al,0 above. The pops below don't touch flags

    pop edx
    pop esi
    pop ebx
    pop eax

    ret

.mismatch:

;; ZF is clear here, from the cmp al,bl above

    pop edx
    pop esi
    pop ebx
    pop eax

    ret

;;************************************************************************************

;; Lists every mount point currently in use. Unlike hx.getProcesses, the
;; caller supplies its own buffer and does not read a kernel-cached one,
;; matching BSD's getfsstat(2) instead.
;;
;; Input:
;;
;; ESI - Caller's own buffer, sized for Hexagon.Mounts.Table.limit records
;;       of Hexagon.Kernel.FS.VFS.getMounts.recordSize bytes each
;;
;; Output:
;;
;; EAX - Number of records written, in table slot order
;;
;; Record layout:
;;
;; +0  Mount point path, NUL-terminated (64 bytes)
;; +64 Device name, NUL-terminated (8 bytes)
;; +72 Filesystem type code (Hexagon.VFS.FS.*), 1 byte
;; +73 Volume label, NUL-terminated (12 bytes)

Hexagon.Kernel.FS.VFS.getMounts.recordSize = 85

;; filesystemType and .volumeLabel sit contiguous at Control's own start,
;; so 13 bytes covers exactly both.

Hexagon.Kernel.FS.VFS.getMounts.controlFieldsSize = 13

Hexagon.Kernel.FS.VFS.getMounts:

;; The caller's own buffer, written into at CPL 0 where paging refuses nothing,
;; so it is checked against the reach this process already has. The size
;; comes from this call's own contract, not from ECX, which is not an input here

    push ebx
    push ecx

    mov ebx, esi
    mov ecx, Hexagon.Mounts.Table.limit * Hexagon.Kernel.FS.VFS.getMounts.recordSize

    call Hexagon.Arch.Paging.rangeIsCallerWritable

    pop ecx
    pop ebx

    jc .badBuffer

    push ebx
    push ecx
    push edx

;; preemptionDisabled alone does not stop another already-runnable
;; process's own concurrent int 80h from entering hexagonHandler. A real
;; cli/sti bracket closes that window, the same as .swapTo uses for this
;; same shared state.

    pushfd
    cli

;; rep movsb writes through ES:EDI, and hexagonHandler leaves ES at
;; kernelLinear for every syscall. Same fix as registerBootMount's own ES
;; reset.

    push es

    mov ax, 10h
    mov es, ax

    mov edi, esi

    xor ebx, ebx ;; EBX = table slot index
    xor edx, edx ;; EDX = record count

.loop:

    cmp ebx, Hexagon.Mounts.Table.limit
    jae .done

    mov esi, dword[Hexagon.Mounts.Table.base]

    cmp byte[esi + Hexagon.Mounts.Table.inUse + ebx], 0
    je .next

    mov esi, ebx

    imul esi, 64
    
    add esi, dword[Hexagon.Mounts.Table.base]
    add esi, Hexagon.Mounts.Table.path

    push ecx

    mov ecx, 64

    cld
    rep movsb

    pop ecx

    mov esi, ebx
    imul esi, 32
    add esi, dword[Hexagon.Mounts.Table.base]
    add esi, Hexagon.Mounts.Table.deviceName

    push ecx

    mov ecx, 32

    rep movsb

    pop ecx

;; The loaded slot's own table entry is stale until it's next swapped out.
;; Reads from its live Hexagon.VFS.Control instead for that one slot.

    cmp ebx, dword[Hexagon.Mounts.loadedSlot]
    je .fromLive

    mov esi, ebx
    imul esi, Hexagon.VFS.Control.size + Hexagon.VFS.FAT.instanceSize
    add esi, dword[Hexagon.Mounts.Table.base]
    add esi, Hexagon.Mounts.Table.state

    jmp .haveControlSource

.fromLive:

    mov esi, Hexagon.VFS.Control

.haveControlSource:

    push ecx

    mov ecx, Hexagon.Kernel.FS.VFS.getMounts.controlFieldsSize

    rep movsb

    pop ecx

    inc edx

.next:

    inc ebx

    jmp .loop

.done:

    mov eax, edx

    pop es

    popfd

    pop edx
    pop ecx
    pop ebx

    ret
.badBuffer:

    mov eax, Hexagon.Kern.Proc.badAddress

    stc

    ret


;;************************************************************************************

;; Applies a Unix-style mode to a path. Only root may call this. What
;; the mode changes is up to the filesystem it lands on: FAT16B has no
;; owner or real permission bits, so it only derives whether the path
;; becomes root-only-write, its own SYSTEM attribute. DEVFS ignores the
;; call outright, a deliberate no-op and not an error
;;
;; Input:
;;
;; ESI - Path
;; EBX - Requested mode
;;
;; Output:
;;
;; EAX - Error code:
;;       01h - Permission denied
;;       02h - Path not found
;; CF set on error

Hexagon.Kernel.FS.VFS.chown:

    call Hexagon.Kern.Sched.disablePreemption

    call Hexagon.Kernel.FS.VFS.resolveMount

    mov ah, byte[Hexagon.VFS.Control.filesystemType]

    cmp ah, Hexagon.VFS.FS.FAT16B
    je .chownFAT16B

    cmp ah, Hexagon.VFS.FS.DEVFS
    je .ignored

    call Hexagon.Kern.Sched.enablePreemption

    ret

.chownFAT16B:

    call Hexagon.Kernel.FS.FAT16.chownFAT16B

    call Hexagon.Kern.Sched.enablePreemption

    ret

.ignored:

    call Hexagon.Kern.Sched.enablePreemption

    clc

    ret

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

;; A process preempted mid-operation here, resumed after some other process
;; swapped a different mount's state into the shared working copy, would
;; corrupt both. See Hexagon.Scheduler.preemptionDisabled

    call Hexagon.Kern.Sched.disablePreemption

    call Hexagon.Kernel.FS.VFS.resolveMount

    mov ah, byte[Hexagon.VFS.Control.filesystemType]

    cmp ah, Hexagon.VFS.FS.FAT16B
    je .newFileFAT16B

    cmp ah, Hexagon.VFS.FS.DEVFS
    je .notSupported

    call Hexagon.Kern.Sched.enablePreemption

    ret

.newFileFAT16B:

    call Hexagon.Kernel.FS.FAT16.createFileFAT16B

    call Hexagon.Kern.Sched.enablePreemption

    ret

;; DEVFS has no real files to create. Falling through to the generic case
;; below would silently return success instead

.notSupported:

    call Hexagon.Kern.Sched.enablePreemption

    stc

    mov eax, 200h ;; VFS.invalidFS, lib/fasm/errors.s

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

;; See Hexagon.Kernel.FS.VFS.createFile for why this stays masked across
;; the whole operation

    call Hexagon.Kern.Sched.disablePreemption

    call Hexagon.Kernel.FS.VFS.resolveMount

    mov ah, byte[Hexagon.VFS.Control.filesystemType]

    cmp ah, Hexagon.VFS.FS.FAT16B
    je .unlinkFileFAT16B

    cmp ah, Hexagon.VFS.FS.DEVFS
    je .notSupported

    call Hexagon.Kern.Sched.enablePreemption

    ret

.unlinkFileFAT16B:

    call Hexagon.Kernel.FS.FAT16.unlinkFileFAT16B

    call Hexagon.Kern.Sched.enablePreemption

    ret

;; See Hexagon.Kernel.FS.VFS.createFile.notSupported

.notSupported:

    call Hexagon.Kern.Sched.enablePreemption

    stc

    mov eax, 200h ;; VFS.invalidFS, lib/fasm/errors.s

    ret

;;************************************************************************************

;; Create a new, empty directory
;;
;; Input:
;;
;; ESI - Pointer to the path of the directory to create
;;
;; Output:
;;
;; EAX - Error code, if applicable
;;     - 05h for permission denied
;; CF defined if the directory already exists or the path is invalid

Hexagon.Kernel.FS.VFS.createDirectory:

;; See Hexagon.Kernel.FS.VFS.createFile for why this stays masked across
;; the whole operation

    call Hexagon.Kern.Sched.disablePreemption

    call Hexagon.Kernel.FS.VFS.resolveMount

    mov ah, byte[Hexagon.VFS.Control.filesystemType]

    cmp ah, Hexagon.VFS.FS.FAT16B
    je .newDirectoryFAT16B

    cmp ah, Hexagon.VFS.FS.DEVFS
    je .notSupported

    call Hexagon.Kern.Sched.enablePreemption

    ret

.newDirectoryFAT16B:

    call Hexagon.Kernel.FS.FAT16.createDirectoryFAT16B

    call Hexagon.Kern.Sched.enablePreemption

    ret

;; See Hexagon.Kernel.FS.VFS.createFile.notSupported

.notSupported:

    call Hexagon.Kern.Sched.enablePreemption

    stc

    mov eax, 200h ;; VFS.invalidFS, lib/fasm/errors.s

    ret

;;************************************************************************************

;; Remove an empty directory from volume
;;
;; Input:
;;
;; ESI - Pointer to the path of the directory to remove
;;
;; Output:
;;
;; EAX - Error code, if applicable
;;     - 05h for permission denied
;; CF defined if the directory was not found, isn't empty, or isn't a
;; directory

Hexagon.Kernel.FS.VFS.removeDirectory:

;; See Hexagon.Kernel.FS.VFS.createFile for why this stays masked across
;; the whole operation

    call Hexagon.Kern.Sched.disablePreemption

    call Hexagon.Kernel.FS.VFS.resolveMount

    mov ah, byte[Hexagon.VFS.Control.filesystemType]

    cmp ah, Hexagon.VFS.FS.FAT16B
    je .removeDirectoryFAT16B

    cmp ah, Hexagon.VFS.FS.DEVFS
    je .notSupported

    call Hexagon.Kern.Sched.enablePreemption

    ret

.removeDirectoryFAT16B:

    call Hexagon.Kernel.FS.FAT16.removeDirectoryFAT16B

    call Hexagon.Kern.Sched.enablePreemption

    ret

;; See Hexagon.Kernel.FS.VFS.createFile.notSupported

.notSupported:

    call Hexagon.Kern.Sched.enablePreemption

    stc

    mov eax, 200h ;; VFS.invalidFS, lib/fasm/errors.s

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

;; See Hexagon.Kernel.FS.VFS.createFile for why this stays masked across
;; the whole operation

    call Hexagon.Kern.Sched.disablePreemption

    call Hexagon.Kernel.FS.VFS.resolveMount ;; Must run before pushad, it adjusts ESI

    pushad

    mov ah, byte[Hexagon.VFS.Control.filesystemType]

    cmp ah, Hexagon.VFS.FS.FAT16B
    je .saveFileFAT16B

    cmp ah, Hexagon.VFS.FS.DEVFS
    je .notSupported

    popad

    call Hexagon.Kern.Sched.enablePreemption

    ret

.saveFileFAT16B:

    popad

    call Hexagon.Kernel.FS.FAT16.saveFileFAT16B

    call Hexagon.Kern.Sched.enablePreemption

    ret

;; See Hexagon.Kernel.FS.VFS.createFile.notSupported

.notSupported:

    popad

    call Hexagon.Kern.Sched.enablePreemption

    stc

    mov eax, 200h ;; VFS.invalidFS, lib/fasm/errors.s

    ret

;;************************************************************************************

;; Lists the files/directories in the current directory into the caller's
;; own buffer, matching Hexagon.Kernel.FS.VFS.getMounts's caller-owned-buffer
;; convention instead of handing back a kernel-cached pointer.
;;
;; Entries are separated by Hexagon.VFS.FAT16B.filenameSeparator (a file) or
;; .directorySeparator (a directory), the whole list NUL-terminated
;;
;; Every filesystem's own list builder must return ESI pointing at a
;; DS-reachable kernel buffer and EAX as the entry count. Building it with
;; stosb or movsb needs ES reset to kernelData right before, never assumed.
;;
;; Input:
;;
;; ESI - Caller's own buffer
;; ECX - Size of that buffer, in bytes
;;
;; Output:
;;
;; EAX - Number of entries written, if the buffer was big enough (CF clear)
;; EAX - Exact buffer size needed, in bytes, if it wasn't (CF set). Nothing
;;       is written in that case, and the caller is expected to hx.free its
;;       buffer, hx.malloc exactly EAX bytes, and retry
;; EAX - 0, if CF is set and EAX is also 0: a real filesystem error rather
;;       than an undersized buffer (a valid needed size is always at least
;;       1, for the terminating NUL alone). Retrying will not help
;; CF  - Set on either of the two failure cases above

Hexagon.Kernel.FS.VFS.listFiles:

;; The caller's buffer and size are parked here, since resolveMount needs ESI
;; for a path. It preserves every other register, so only ESI needs saving

    mov dword[.callerBuffer], esi
    mov dword[.callerSize], ecx

;; No path argument. Always resolves against the current directory.

    movzx esi, byte[Hexagon.Scheduler.current]
    imul esi, 64
    add esi, Hexagon.Processes.Table.cwd

;; See Hexagon.Kernel.FS.VFS.createFile for why this stays masked across
;; the whole operation

    call Hexagon.Kern.Sched.disablePreemption

    call Hexagon.Kernel.FS.VFS.resolveMount

    mov ah, byte[Hexagon.VFS.Control.filesystemType]

    cmp ah, Hexagon.VFS.FS.FAT16B
    je .listFilesFAT16B

    cmp ah, Hexagon.VFS.FS.DEVFS
    je .listFilesDevFS

    xor eax, eax

    stc

    call Hexagon.Kern.Sched.enablePreemption

    ret

.listFilesFAT16B:

;; listFilesFAT16B takes no path and trusts
;; Hexagon.VFS.FAT16B.currentDirLBA, which is per-mount state shared by every
;; process on it. Walk it to this process's own resolved cwd first, or the
;; listing is whatever directory somebody else last moved it to

    call Hexagon.Kernel.FS.FAT16.changeDirectoryFAT16B

    jc .hardError

    call Hexagon.Kernel.FS.FAT16.listFilesFAT16B ;; ESI = kernel list, EAX = entry count

    jmp .copyListToCaller

.listFilesDevFS:

    call Hexagon.Kernel.FS.DEVFS.listFilesDevFS ;; ESI = kernel list, EAX = entry count

.copyListToCaller:

    jc .hardError

    mov dword[.entryCount], eax

;; The built list is one NUL-terminated run of entries separated by non-NUL
;; bytes, which is the same shape as a plain string to stringSize's own scan

    call Hexagon.Libkern.String.stringSize

    inc eax ;; Include the terminating NUL itself in what gets copied

    cmp eax, dword[.callerSize]
    ja .tooSmall

    mov edi, dword[.callerBuffer]
    mov ecx, eax

;; rep movsb reads through DS and writes through ES:EDI. DS is already the
;; kernel data segment here, but hexagonHandler left ES on the kernel linear
;; segment, so it has to be realigned first

    push es

    mov ax, 10h
    mov es, ax

    cld
    rep movsb

    pop es

    mov eax, dword[.entryCount]

    clc

    jmp .done

.tooSmall:

;; EAX already holds the exact size needed, computed above

    stc

    jmp .done

.hardError:

    xor eax, eax

    stc

.done:

    call Hexagon.Kern.Sched.enablePreemption

    ret

.callerBuffer: dd 0
.callerSize:   dd 0
.entryCount:   dd 0

;;************************************************************************************

;; Changes the current work directory
;;
;; Input:
;;
;; ESI - Name of the directory
;;
;; Output:
;;
;; CF defined if the directory was not found or is invalid

Hexagon.Kernel.FS.VFS.changeDirectory:

;; See Hexagon.Kernel.FS.VFS.createFile for why this stays masked across
;; the whole operation

    call Hexagon.Kern.Sched.disablePreemption

    call Hexagon.Kernel.FS.VFS.resolveMount

    mov ah, byte[Hexagon.VFS.Control.filesystemType]

    cmp ah, Hexagon.VFS.FS.FAT16B
    je .changeDirectoryFAT16B

    cmp ah, Hexagon.VFS.FS.DEVFS
    je .changeDirectoryDevFS

    call Hexagon.Kern.Sched.enablePreemption

    ret

.changeDirectoryFAT16B:

    call Hexagon.Kernel.FS.FAT16.changeDirectoryFAT16B

    jc .failed

;; This process's own current directory only exists to tell resolveMount
;; which mount a later argument-less call (hx.listFiles, a relative cd)
;; should target. Synced from resolveMount's own normalized absolute path
;; and not the caller's original argument, so a relative cd and a
;; "cd .." out of a mount keep it in sync just as well as an absolute cd.

    mov esi, Hexagon.Kernel.FS.VFS.resolveMount.normalizedPath

    call Hexagon.Kernel.FS.Dir.setCurrentDirectory

    jmp .done

;; DEVFS has no real subdirectories yet, so the only path landing here is
;; "/dev" itself, resolved down to just "/" by resolveMount

.changeDirectoryDevFS:

    cmp byte[esi], '/'
    jne .failed

    cmp byte[esi+1], 0
    jne .failed

    mov esi, Hexagon.Kernel.FS.VFS.resolveMount.normalizedPath

    call Hexagon.Kernel.FS.Dir.setCurrentDirectory

    jmp .done

.failed:

    stc

.done:

    call Hexagon.Kern.Sched.enablePreemption

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

;; Only the source path picks the mount. Renaming across mounts isn't
;; supported yet, matching a plain Unix rename(2).
;;
;; See Hexagon.Kernel.FS.VFS.createFile for why this stays masked across
;; the whole operation

    call Hexagon.Kern.Sched.disablePreemption

    call Hexagon.Kernel.FS.VFS.resolveMount

    mov ah, byte[Hexagon.VFS.Control.filesystemType]

    cmp ah, Hexagon.VFS.FS.FAT16B
    je .renameFileFAT16B

    cmp ah, Hexagon.VFS.FS.DEVFS
    je .notSupported

    call Hexagon.Kern.Sched.enablePreemption

    ret

.renameFileFAT16B:

    call Hexagon.Kernel.FS.FAT16.renameFileFAT16B

    call Hexagon.Kern.Sched.enablePreemption

    ret

;; See Hexagon.Kernel.FS.VFS.createFile.notSupported

.notSupported:

    call Hexagon.Kern.Sched.enablePreemption

    stc

    mov eax, 200h ;; VFS.invalidFS, lib/fasm/errors.s

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

;; See Hexagon.Kernel.FS.VFS.createFile for why this stays masked across
;; the whole operation

    call Hexagon.Kern.Sched.disablePreemption

    call Hexagon.Kernel.FS.VFS.resolveMount

    mov ah, byte[Hexagon.VFS.Control.filesystemType]

    cmp ah, Hexagon.VFS.FS.FAT16B
    je .openFileFAT16B

    cmp ah, Hexagon.VFS.FS.DEVFS
    je .openFileDevFS

    call Hexagon.Kern.Sched.enablePreemption

    ret

.openFileFAT16B:

    call Hexagon.Kernel.FS.FAT16.loadFileFAT16B

    call Hexagon.Kern.Sched.enablePreemption

    ret

;; Re-enters device opening with the leading '/' stripped, since a device is
;; matched by its bare name alone. The name is confirmed against the devfs
;; registry first, or an unmatched one reaches Hexagon.Kernel.Dev.Dev.open's
;; "maybe it's a file" fallback, which calls back here and recurses forever

.openFileDevFS:

    push esi

    call Hexagon.Kernel.FS.DEVFS.fileExistsDevFS

    pop esi

    jc .notFoundDevFS

;; "/dev" itself, or any future subdirectory, isn't a device to open

    cmp byte[ebx + 11], 0 ;; Directory attribute, Hexagon.Kernel.FS.DEVFS.fileExistsDevFS's own record layout
    jne .notFoundDevFS

    inc esi ;; Skip the leading '/' resolveMount always leaves here

    call Hexagon.Kernel.Dev.Dev.open

    call Hexagon.Kern.Sched.enablePreemption

    ret

.notFoundDevFS:

    call Hexagon.Kern.Sched.enablePreemption

    mov eax, 6 ;; IO.notFound, lib/fasm/errors.s

    stc

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
;; EBX - Hexagon.Dev.DeviceClasses value, 0 if the path is not a device node
;;       (a plain file, a directory, or "/dev" itself)
;; ECX - Attribute byte (bit 10h set means the path is a directory, same
;;       meaning as Hexagon.VFS.FAT.directoryAttribute), undefined if CF is set
;; EDX - Device major (DH) and minor (DL), 0:0 if the path is not a device node
;; CF defined if the file was not found or has an invalid name

Hexagon.Kernel.FS.VFS.fileExists:

;; See Hexagon.Kernel.FS.VFS.createFile for why this stays masked across
;; the whole operation

    call Hexagon.Kern.Sched.disablePreemption

    call Hexagon.Kernel.FS.VFS.resolveMount

    mov ah, byte[Hexagon.VFS.Control.filesystemType]

    cmp ah, Hexagon.VFS.FS.FAT16B
    je .fileExistsFAT16B

    cmp ah, Hexagon.VFS.FS.DEVFS
    je .fileExistsDevFS

    call Hexagon.Kern.Sched.enablePreemption

    ret

.fileExistsFAT16B:

    call Hexagon.Kernel.FS.FAT16.fileExistsFAT16B

    jc .fileExistsFAT16BDone

;; EBX still points at fileExistsFAT16B's own directory entry here, so the
;; attribute byte has to be read out before EBX itself is overwritten below

    movzx ecx, byte[ebx + 11]

;; A FAT16 file is never a device node. mov, not xor: xor would clear CF,
;; wiping out fileExistsFAT16B's own not-found signal

    mov ebx, 0
    mov edx, 0

.fileExistsFAT16BDone:

    call Hexagon.Kern.Sched.enablePreemption

    ret

.fileExistsDevFS:

    call Hexagon.Kernel.FS.DEVFS.fileExistsDevFS

    jc .fileExistsDevFSDone

;; EBX still points at DEVFS.fileExistsDevFS's own record here, so every
;; field has to be read out before EBX itself becomes the class below.
;; EDX cleared first since only its low 16 bits (DH/DL) get written next

    xor edx, edx

    movzx ecx, byte[ebx + 11] ;; Attribute (bit 10h set for "/dev" itself)
    mov dh, byte[ebx + 13] ;; Major
    mov dl, byte[ebx + 14] ;; Minor
    movzx ebx, byte[ebx + 12] ;; Class

.fileExistsDevFSDone:

    call Hexagon.Kern.Sched.enablePreemption

    ret

;;************************************************************************************

;; Defines the filesystem present on the current volume, obtaining the appropriate
;; information in the MBR (Master Boot Record)

Hexagon.Kernel.FS.VFS.setFilesystem:

    call Hexagon.Kernel.Dev.Disk.Disk.readMBR

    jc .restoreVolume

    mov byte[Hexagon.VFS.Control.filesystemType], ah

    jmp .finish

.restoreVolume:

    mov dl, byte [Hexagon.Dev.Disk.Control.bootDisk]
    mov byte [Hexagon.Dev.Disk.Control.currentDisk], dl

    call Hexagon.Kernel.FS.VFS.initFilesystem

    stc

.finish:

    ret

;;************************************************************************************

;; Initializes the filesystem of the mounted volume, for use with the system

Hexagon.Kernel.FS.VFS.initFilesystem:

    call Hexagon.Kernel.Dev.Disk.Disk.testVolume

    jc .volumeNotPresent

.volumePresent:

    mov ah, byte[Hexagon.VFS.Control.filesystemType]

    cmp ah, Hexagon.VFS.FS.FAT16B
    je .initFAT16B

    clc

    ret

.volumeNotPresent:

    mov ah, byte[Hexagon.Dev.Disk.Control.bootDisk]
    mov byte[Hexagon.Dev.Disk.Control.currentDisk], ah

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

    mov dl, byte[Hexagon.Dev.Disk.Control.bootDisk]
    mov byte[Hexagon.Dev.Disk.Control.currentDisk], dl

    logHexagon Hexagon.Verbose.setVolume, Hexagon.Dmesg.Priorities.p5

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

    mov ah, byte[Hexagon.Dev.Disk.Control.currentDisk] ;; Storage device number
    mov dl, [Hexagon.Dev.DeviceClasses.block] ;; Device class

    call Hexagon.Kernel.Dev.Dev.convertDeviceToDeviceName

    xor eax, eax
    xor edi, edi

    mov edi, Hexagon.VFS.Control.volumeLabel
    mov ah, byte[Hexagon.VFS.Control.filesystemType]

    ret

;;************************************************************************************

;; Syscall entries for the filesystem calls above. Every routine below runs
;; Hexagon.Kernel.FS.VFS.resolveMount, which answers with ESI on a buffer
;; inside the kernel image, and Hexagon.Kern.Syscall.hexagonHandler translates
;; ESI on the way back out, so a caller at user level would be handed an
;; address it cannot read a byte of. The caller's own ESI goes back instead,
;; through a "pop" that leaves the CF these calls answer with alone
;;
;; Input/output: as the routine each one wraps, ESI aside

Hexagon.Kernel.FS.VFS.saveFileSyscall:

    push esi

    call Hexagon.Kernel.FS.VFS.saveFile

    pop esi

    ret

Hexagon.Kernel.FS.VFS.createFileSyscall:

    push esi

    call Hexagon.Kernel.FS.VFS.createFile

    pop esi

    ret

Hexagon.Kernel.FS.VFS.unlinkFileSyscall:

    push esi

    call Hexagon.Kernel.FS.VFS.unlinkFile

    pop esi

    ret

Hexagon.Kernel.FS.VFS.renameFileSyscall:

    push esi

    call Hexagon.Kernel.FS.VFS.renameFile

    pop esi

    ret

Hexagon.Kernel.FS.VFS.listFilesSyscall:

;; The listing is written into the caller's own buffer at CPL 0, so the range it
;; named is checked against what this process can reach itself

    push ebx

    mov ebx, esi

    call Hexagon.Arch.Paging.rangeIsCallerWritable

    pop ebx

    jc .badBuffer

    push esi

    call Hexagon.Kernel.FS.VFS.listFiles

    pop esi

    ret

.badBuffer:

    mov eax, Hexagon.Kern.Proc.badAddress

    stc

    ret

Hexagon.Kernel.FS.VFS.fileExistsSyscall:

    push esi

    call Hexagon.Kernel.FS.VFS.fileExists

    pop esi

    ret

Hexagon.Kernel.FS.VFS.createDirectorySyscall:

    push esi

    call Hexagon.Kernel.FS.VFS.createDirectory

    pop esi

    ret

Hexagon.Kernel.FS.VFS.removeDirectorySyscall:

    push esi

    call Hexagon.Kernel.FS.VFS.removeDirectory

    pop esi

    ret

Hexagon.Kernel.FS.VFS.changeDirectorySyscall:

    push esi

    call Hexagon.Kernel.FS.VFS.changeDirectory

    pop esi

    ret

Hexagon.Kernel.FS.VFS.mountSyscall:

    push esi

    call Hexagon.Kernel.FS.VFS.mount

    pop esi

    ret

Hexagon.Kernel.FS.VFS.unmountSyscall:

    push esi

    call Hexagon.Kernel.FS.VFS.unmount

    pop esi

    ret

Hexagon.Kernel.FS.VFS.chownSyscall:

    push esi

    call Hexagon.Kernel.FS.VFS.chown

    pop esi

    ret

