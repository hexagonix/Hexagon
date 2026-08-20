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
;; Must run once at boot, after Hexagon.Arch.Gen.Mm.initMemory and before
;; Hexagon.Kernel.FS.VFS.registerBootMount
;;
;; Output: empty

Hexagon.Kernel.FS.VFS.allocateMountTable:

    pushad

    mov ebx, Hexagon.Mounts.Table.byteSize

    call Hexagon.Arch.Gen.Mm.malloc

;; Mm.malloc's pointer is flat. Kernel code here addresses memory through
;; DS, based at 500h, so this subtracts it once up front.

    sub ebx, 500h
    mov dword[Hexagon.Mounts.Table.base], ebx

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
;; collapses "." and "..") before matching a mount. FAT16 below then only
;; ever sees a plain downward path already inside the mount that owns it,
;; so it never needs to cross a mount boundary on its own.

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

    mov esi, Hexagon.VFS.Directory.currentDirectory
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

    mov byte[edi + ecx], 0 ;; Out of room. Truncate rather than overflow .joined

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
    jae .appendFinished ;; Out of room. Truncate rather than overflow

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

;; Masked for the whole swap, not just the copies, since a preempted
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

;; int13h resets ES to kernelLinear after every call, and rep movsb writes
;; through ES:EDI. Without this reset, the memcpys below would write 500h
;; too low, into unrelated kernel memory.

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

    mov byte[Hexagon.Dev.Gen.Disk.Control.currentDisk], al

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

;; int13h resets ES to kernelLinear after every call, and pushad/popad
;; don't cover ES. mountVolume just made several such calls, so ES needs
;; resetting before the rep movsb below.

    mov ax, 10h
    mov es, ax

    mov edi, dword[Hexagon.Mounts.Table.base]

    mov byte[edi + Hexagon.Mounts.Table.inUse + 0], 1

    mov al, byte[Hexagon.Dev.Gen.Disk.Control.currentDisk]
    mov byte[edi + Hexagon.Mounts.Table.drive + 0], al

;; Gives the boot mount the same "hd0p0"-style deviceName hx.mount would
;; assign. The partition index is always 0, since Saturno/HBoot only ever
;; boot from a disk's first primary partition, so only the disk slot needs
;; looking up.

    mov al, byte[Hexagon.Dev.Gen.Disk.Control.bootDisk]

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
;; mount. The disk's first supported partition is used. The mount point
;; must already exist as a directory.
;;
;; Input:
;;
;; ESI - Device name (such as "hd1")
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

    call .matchDiskName ;; ESI is still the device name here

    jc .noDevice

    push edx

    mov edx, dword[Hexagon.Disks.Table.base]

    cmp byte[edx + Hexagon.Disks.Table.present + eax], 0

    pop edx

    je .noDevice

    call .findSupportedPartition ;; Input: EAX = disk slot. Output: EAX = partition slot

    jc .noDevice

    mov dword[.partitionSlot], eax

;; Validate the mount point: must exist and be a directory

    mov esi, dword[.mountPath]

    call Hexagon.Kernel.FS.VFS.fileExists

    jc .badMountPoint

;; The mount point is stored below by whatever form the caller gave it in.
;; resolveMount, called by fileExists just above, already normalized it
;; into an absolute, "."/".."-free path - use that instead of the raw
;; argument, or a relative mount point (missing its leading '/') would
;; never match anything in Hexagon.Kernel.FS.VFS.resolveMount's own prefix
;; matching later, silently leaving this mount unreachable

    mov dword[.mountPath], Hexagon.Kernel.FS.VFS.resolveMount.normalizedPath

;; Must still fit a slot once normalized

    mov esi, dword[.mountPath]

    call Hexagon.Libkern.String.stringSize

    cmp eax, 63
    jae .badMountPoint

;; 10h (Hexagon.VFS.FAT.directoryAttribute) written directly: that field is
;; an "equ" text macro, scoped to its struc, not forward-referenceable from
;; here the way a real symbol would be

    test byte[ebx + 11], 10h

    jz .badMountPoint

;; Find a free mount slot

    call .findFreeSlot

    jc .noFreeSlots

    mov dword[.newSlot], eax

;; .loadPartitionBPB below overwrites the live working copy. Whichever
;; mount is currently loaded needs its state saved into its own table slot
;; first, the same save .swapTo does, since this new mount becomes the
;; loaded slot directly below without ever going through .swapTo itself.

    mov eax, dword[Hexagon.Mounts.loadedSlot]

    cmp eax, 0xFFFFFFFF
    je .noPreviousToSave

    push ecx
    push es

;; hexagonHandler leaves ES at kernelLinear for every syscall, and rep
;; movsb writes through ES:EDI. Same fix as every other
;; Hexagon.Mounts.Table.state writer.

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

;; .loadPartitionBPB's own int13h calls reset ES to kernelLinear. Both
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

    mov byte[Hexagon.Dev.Gen.Disk.Control.currentDisk], al

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

;; Copy the device name into the slot, capped to 7 chars + NUL so it
;; always fits within the fixed 8-byte field, NUL-padding the rest, the
;; same approach as Hexagon.Kern.Proc.getProcessTable's own name field

    mov edi, dword[Hexagon.Mounts.Table.base]

    add edi, Hexagon.Mounts.Table.deviceName

    mov eax, ebx

    shl eax, 3
    add edi, eax

    mov esi, dword[.deviceName]

    push ebx

    xor ebx, ebx

.measureDeviceName:

    cmp ebx, 7
    jae .deviceNameMeasured

    cmp byte[esi + ebx], 0
    je .deviceNameMeasured

    inc ebx

    jmp .measureDeviceName

.deviceNameMeasured:

    mov ecx, ebx

    rep movsb ;; Copy the real device name characters

    mov ecx, 8
    sub ecx, ebx

    xor al, al

    rep stosb ;; NUL-terminate and pad out the rest of the device name field

    pop ebx

    mov edx, dword[Hexagon.Mounts.Table.base]
    mov byte[edx + Hexagon.Mounts.Table.inUse + ebx], 1

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

;; Input: ESI - Device name: either a whole disk ("hd0".."hd3") or one of
;;        its up to 4 MBR primary partitions ("hd0p0".."hd3p3")
;; Output: EAX - Disk slot (0-3); .explicitPartition - the partition index
;;         (0-3) from a "pN" suffix, or 0xFFFFFFFF if the name named the
;;         whole disk; CF set if the name doesn't match this convention at
;;         all (.explicitPartition is left unchanged on this path)

.matchDiskName:

    mov dword[.explicitPartition], 0xFFFFFFFF

    mov al, byte[esi]

    cmp al, 'h'
    jne .noMatch

    mov al, byte[esi+1]

    cmp al, 'd'
    jne .noMatch

    mov al, byte[esi+2]

    cmp al, '0'
    jb .noMatch

    cmp al, '3'
    ja .noMatch

    movzx eax, al

    sub eax, '0' ;; EAX = disk slot

    cmp byte[esi+3], 0
    je .wholeDisk ;; Just "hd0".."hd3", no partition suffix

    cmp byte[esi+3], 'p'
    jne .noMatch

    mov cl, byte[esi+4] ;; Not ah/al. EAX already holds the disk slot to return

    cmp cl, '0'
    jb .noMatch

    cmp cl, '3'
    ja .noMatch

    cmp byte[esi+5], 0
    jne .noMatch ;; Only a single digit (0-3) is a valid partition index here

    movzx ecx, cl

    sub ecx, '0'

    mov dword[.explicitPartition], ecx

.wholeDisk:

    clc

    ret

.noMatch:

    stc

    ret

.explicitPartition: dd 0xFFFFFFFF

;; Input:
;;
;; EAX - Disk slot
;;
;; Output:
;;
;; EAX - The Hexagon.Partitions.Table entry on that disk matching
;;       .explicitPartition's index if one was set by .matchDiskName,
;;       otherwise the first entry present there Hexagon supports; CF set
;;       if none found (or the explicit one isn't present/supported)

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

    mov byte[Hexagon.Dev.Gen.Disk.Control.currentDisk], dl

    mov edi, dword[Hexagon.Partitions.Table.base]
    mov esi, dword[edi + Hexagon.Partitions.Table.startLBA + eax * 4]
    mov dword[.partitionStartLBA], esi

    mov cx, 50h
    mov edi, Hexagon.Heap.DiskGeometry

    call Hexagon.Kernel.Dev.i386.Disk.Disk.tryReadSector

    jc .fail

    mov dword[Hexagon.Dev.Gen.Disk.Control.diskGeometry], Hexagon.Heap.DiskGeometry

;; +500h reaches the buffer's real physical address here, same as readMBR.
;;
;; getFilesystemInfoFAT16B's own field offsets are relative to the BPB
;; proper, 3 bytes past the sector's leading jmp/nop. A raw sector read via
;; tryReadSector lands at the true sector start, so needs the same +3
;; applied explicitly here.

    mov esi, Hexagon.Heap.DiskGeometry + 500h + 3

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
    mov byte[ebx + Hexagon.Mounts.Table.inUse + eax], 0

    pop ebx

;; If the unmounted slot was the one currently loaded, nothing is loaded
;; anymore. The next resolveMount call will load whichever mount it needs

    cmp eax, dword[Hexagon.Mounts.loadedSlot]
    jne .done

    mov dword[Hexagon.Mounts.loadedSlot], 0xFFFFFFFF

.done:

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
;; caller supplies its own buffer rather than reading a kernel-cached one,
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
    imul esi, 8
    add esi, dword[Hexagon.Mounts.Table.base]
    add esi, Hexagon.Mounts.Table.deviceName

    push ecx

    mov ecx, 8

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

    call Hexagon.Kern.Users.getUserPermissions

    cmp eax, 03h ;; Group code for default user
    je .permissionDenied

;; A process preempted mid-operation here, resumed after some other process
;; swapped a different mount's state into the shared working copy, would
;; corrupt both. See Hexagon.Scheduler.preemptionDisabled

    call Hexagon.Kern.Sched.disablePreemption

    call Hexagon.Kernel.FS.VFS.resolveMount

    mov ah, byte[Hexagon.VFS.Control.filesystemType]

    cmp ah, Hexagon.VFS.FS.FAT16B
    je .newFileFAT16B

    call Hexagon.Kern.Sched.enablePreemption

    ret

.newFileFAT16B:

    call Hexagon.Kernel.FS.FAT16.createEmptyFileFAT16B

    call Hexagon.Kern.Sched.enablePreemption

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

    call Hexagon.Kern.Users.getUserPermissions

    cmp eax, 03h ;; Group code for default user
    je .permissionDenied

;; See Hexagon.Kernel.FS.VFS.createFile for why this stays masked across
;; the whole operation

    call Hexagon.Kern.Sched.disablePreemption

    call Hexagon.Kernel.FS.VFS.resolveMount

    mov ah, byte[Hexagon.VFS.Control.filesystemType]

    cmp ah, Hexagon.VFS.FS.FAT16B
    je .unlinkFileFAT16B

    call Hexagon.Kern.Sched.enablePreemption

    ret

.unlinkFileFAT16B:

    call Hexagon.Kernel.FS.FAT16.unlinkFileFAT16B

    call Hexagon.Kern.Sched.enablePreemption

    ret

.permissionDenied:

    stc

    mov eax, 05h

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

    call Hexagon.Kern.Users.getUserPermissions

    cmp eax, 03h ;; Group code for default user
    je .permissionDenied

;; See Hexagon.Kernel.FS.VFS.createFile for why this stays masked across
;; the whole operation

    call Hexagon.Kern.Sched.disablePreemption

    call Hexagon.Kernel.FS.VFS.resolveMount

    mov ah, byte[Hexagon.VFS.Control.filesystemType]

    cmp ah, Hexagon.VFS.FS.FAT16B
    je .newDirectoryFAT16B

    call Hexagon.Kern.Sched.enablePreemption

    ret

.newDirectoryFAT16B:

    call Hexagon.Kernel.FS.FAT16.createDirectoryFAT16B

    call Hexagon.Kern.Sched.enablePreemption

    ret

.permissionDenied:

    stc

    mov eax, 05h

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

    call Hexagon.Kern.Users.getUserPermissions

    cmp eax, 03h ;; Group code for default user
    je .permissionDenied

;; See Hexagon.Kernel.FS.VFS.createFile for why this stays masked across
;; the whole operation

    call Hexagon.Kern.Sched.disablePreemption

    call Hexagon.Kernel.FS.VFS.resolveMount

    mov ah, byte[Hexagon.VFS.Control.filesystemType]

    cmp ah, Hexagon.VFS.FS.FAT16B
    je .removeDirectoryFAT16B

    call Hexagon.Kern.Sched.enablePreemption

    ret

.removeDirectoryFAT16B:

    call Hexagon.Kernel.FS.FAT16.removeDirectoryFAT16B

    call Hexagon.Kern.Sched.enablePreemption

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

;; See Hexagon.Kernel.FS.VFS.createFile for why this stays masked across
;; the whole operation

    call Hexagon.Kern.Sched.disablePreemption

    call Hexagon.Kernel.FS.VFS.resolveMount ;; Must run before pushad, it adjusts ESI

    pushad

    mov ah, byte[Hexagon.VFS.Control.filesystemType]

    cmp ah, Hexagon.VFS.FS.FAT16B
    je .saveFileFAT16B

    popad

    call Hexagon.Kern.Sched.enablePreemption

    ret

.saveFileFAT16B:

    popad

    call Hexagon.Kernel.FS.FAT16.saveFileFAT16B

    call Hexagon.Kern.Sched.enablePreemption

    ret

;;************************************************************************************

;; Get file list from current directory
;;
;; Output:
;;
;; ESI - Pointer to the file/directory list
;; EAX - Number of total entries

Hexagon.Kernel.FS.VFS.listFiles:

;; No path argument. Always resolves against the current directory.

    mov esi, Hexagon.VFS.Directory.currentDirectory

;; See Hexagon.Kernel.FS.VFS.createFile for why this stays masked across
;; the whole operation

    call Hexagon.Kern.Sched.disablePreemption

    call Hexagon.Kernel.FS.VFS.resolveMount

    mov ah, byte[Hexagon.VFS.Control.filesystemType]

    cmp ah, Hexagon.VFS.FS.FAT16B
    je .listFilesFAT16B

    call Hexagon.Kern.Sched.enablePreemption

    ret

.listFilesFAT16B:

    call Hexagon.Kernel.FS.FAT16.listFilesFAT16B

    call Hexagon.Kern.Sched.enablePreemption

    ret

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

    call Hexagon.Kern.Sched.enablePreemption

    ret

.changeDirectoryFAT16B:

    call Hexagon.Kernel.FS.FAT16.changeDirectoryFAT16B

    jc .failed

;; Hexagon.VFS.Directory.currentDirectory only exists to tell resolveMount
;; which mount a later argument-less call (hx.listFiles, a relative cd)
;; should target. Synced from resolveMount's own normalized absolute path
;; rather than the caller's original argument, so a relative cd and a
;; "cd .." out of a mount keep it in sync just as well as an absolute cd.

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

    call Hexagon.Kern.Sched.enablePreemption

    ret

.renameFileFAT16B:

    call Hexagon.Kernel.FS.FAT16.renameFileFAT16B

    call Hexagon.Kern.Sched.enablePreemption

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

    call Hexagon.Kern.Sched.enablePreemption

    ret

.openFileFAT16B:

    call Hexagon.Kernel.FS.FAT16.loadFileFAT16B

    call Hexagon.Kern.Sched.enablePreemption

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

;; See Hexagon.Kernel.FS.VFS.createFile for why this stays masked across
;; the whole operation

    call Hexagon.Kern.Sched.disablePreemption

    call Hexagon.Kernel.FS.VFS.resolveMount

    mov ah, byte[Hexagon.VFS.Control.filesystemType]

    cmp ah, Hexagon.VFS.FS.FAT16B
    je .fileExistsFAT16B

    call Hexagon.Kern.Sched.enablePreemption

    ret

.fileExistsFAT16B:

    call Hexagon.Kernel.FS.FAT16.fileExistsFAT16B

    call Hexagon.Kern.Sched.enablePreemption

    ret

;;************************************************************************************

Hexagon.Kernel.FS.VFS.mountVolume:

    mov ah, byte[Hexagon.Dev.Gen.Disk.Control.bootDisk]

    mov dl, 01h ;; Storage device class

    call Hexagon.Kernel.Dev.Dev.convertDeviceToDeviceName ;; Convert to device name

;; Enable kernel privileges for privileged request

    mov dword[kernelExecute], kernelExecutePermission

    call Hexagon.Kernel.Dev.Dev.open ;; Open device for read/write with privileges

;; Disable kernel privileges as they are no longer needed

    mov dword[kernelExecute], kernelExecuteDisabled

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

    mov ah, byte[Hexagon.Dev.Gen.Disk.Control.currentDisk] ;; Storage device number
    mov dl, [Hexagon.Dev.DeviceClasses.block] ;; Device class

    call Hexagon.Kernel.Dev.Dev.convertDeviceToDeviceName

    xor eax, eax
    xor edi, edi

    mov edi, Hexagon.VFS.Control.volumeLabel
    mov ah, byte[Hexagon.VFS.Control.filesystemType]

    ret
