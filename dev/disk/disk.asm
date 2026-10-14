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

;;************************************************ ***********************************
;;
;; Input and output errors on floppy disks
;;
;; Error | Error description
;; -----------------------------------------------------------------------------------
;;
;; 00h | No error in previous operation
;; 01h | Invalid command: incorrect command for controller
;; 02h | Invalid address
;; 03h | Write protected: impossible to write to floppy disk
;; 04h | Invalid or not found sector ID
;;
;; 06h | Floppy disk swap is active
;;
;; 08h | DMA failure
;; 09h | DMA: impossible to write beyond the 64 Kbyte limit
;;
;; 0ch | Media type not available
;; 10h | Invalid CRC: Cyclical Redundancy Code does not agree with the data
;; 20h | Floppy disk controller failure
;; 31h | There is no media in the drive
;; 40h | Requested trail not found
;; 80h | Time-out
;;
;;************************************************************************************
;;
;; Input and output errors on hard drives
;;
;; Returned only if DL > 7FH (requests to hard drives)
;;
;; Error | Error description
;; -----------------------------------------------------------------------------------
;;
;; 00h | No error in previous operation
;; 01h | Invalid command: Incorrect command for controller
;; 02h | Invalid address
;; 03h | Write protected: impossible to write to floppy disk
;; 04h | Invalid or not found sector ID
;; 05h | Failed to restart
;;
;; 07h | Disk activity parameter failure
;; 08h | DMA failure
;; 09h | DMA: impossible to write beyond the 64 Kbyte limit
;; 0Ah | Damaged sector flag found
;; 0Bh | Defective cylinder found
;;
;; 0Dh | Invalid number of sectors in format
;; 0Eh | Data Control Address Found Indicator
;; 0Fh | DMA Arbitrage Level Out of Range
;; 10h | Incorrect ECC or CRC
;; 11h | ECC corrected data error
;; 20h | Hard disk controller failure
;; 31h | There is no media in the drive
;; 40h | Requested trail not found
;; 80h | Time-out
;; AAh | Drive not ready
;; B3h | Volume in use
;; BBh | Undefined error
;; CCh | Write failure to selected drive
;; E0h | Error state
;; FFh | Sense operation failed
;;
;;************************************************************************************

;; Exclusive-use structures for global volume manipulation

struc Hexagon.Dev.Disk.HardDisk
{

.withoutError        = 00h
.writeProtected      = 01h
.writeError          = 02h
.busyVolume          = 03h
.noMedia             = 04h
.unknownError        = 05h
.operationFailure    = 06h
.authenticationError = 07h
.volumeNotReady      = 08h

}

struc Hexagon.Dev.Disk.Control
{

.currentDisk:  db 0
.bootDisk:     db 0
.diskGeometry: dd 0 ;; BIOS Parameter Block

}

Hexagon.Dev.Disk.HardDisk.IO Hexagon.Dev.Disk.HardDisk
Hexagon.Dev.Disk.Control Hexagon.Dev.Disk.Control

;;************************************************************************************

;; Table of hard disks detected at boot (hd0-hd3), filled by
;; Hexagon.Kernel.Dev.Disk.Disk.detectDisks. Independent of whichever
;; disk is currently mounted (Hexagon.Dev.Disk.Control.currentDisk).
;;
;; malloc'd (Hexagon.Disks.Table.base, filled by allocateTables).
;; Below is only the field layout, every access goes through .base.

virtual at 0

Hexagon.Disks.Table.present:
times Hexagon.Disks.Table.limit db 0 ;; 1 if a hard disk answered at this slot's drive number

Hexagon.Disks.Table.drive:
times Hexagon.Disks.Table.limit db 0 ;; BIOS drive number (80h-83h)

Hexagon.Disks.Table.byteSize = $

Hexagon.Disks.Table.limit = 4

end virtual

Hexagon.Disks.Table.base: dd 0

;;************************************************************************************

;; Table of MBR primary partitions found on detected disks, filled by
;; Hexagon.Kernel.Dev.Disk.Disk.detectPartitions. A classic MBR has up
;; to 4 primary partitions, so this covers all 4 disks worst case. malloc'd

virtual at 0

Hexagon.Partitions.Table.present:
times Hexagon.Partitions.Table.limit db 0 ;; 1 if this MBR entry is used (a non-zero type byte)

Hexagon.Partitions.Table.diskSlot:
times Hexagon.Partitions.Table.limit db 0 ;; Index into Hexagon.Disks.Table

Hexagon.Partitions.Table.index:
times Hexagon.Partitions.Table.limit db 0 ;; Which of the disk's 4 primary MBR entries (0-3)

Hexagon.Partitions.Table.filesystemType:
times Hexagon.Partitions.Table.limit db 0 ;; Raw MBR partition type byte

Hexagon.Partitions.Table.supported:
times Hexagon.Partitions.Table.limit db 0 ;; 1 if Hexagon has a driver for filesystemType

Hexagon.Partitions.Table.startLBA:
times Hexagon.Partitions.Table.limit dd 0

Hexagon.Partitions.Table.totalSectors:
times Hexagon.Partitions.Table.limit dd 0

Hexagon.Partitions.Table.byteSize = $

Hexagon.Partitions.Table.limit = Hexagon.Disks.Table.limit * 4

end virtual

Hexagon.Partitions.Table.base: dd 0

;;************************************************************************************

;; Allocates Hexagon.Disks.Table and Hexagon.Partitions.Table and points .base
;; at each. Must run once at boot, after Hexagon.Arch.Mm.initMemory and
;; before Hexagon.Kernel.Dev.Disk.Disk.detectDisks
;;
;; Output: empty

Hexagon.Kernel.Dev.Disk.Disk.allocateTables:

    pushad

    mov ebx, Hexagon.Disks.Table.byteSize

    call Hexagon.Arch.Mm.malloc

;; Every segment is based at 0, so Mm.malloc's pointer is already what the
;; [Table.field + reg] accesses below expect


    mov dword[Hexagon.Disks.Table.base], ebx

    mov ebx, Hexagon.Partitions.Table.byteSize

    call Hexagon.Arch.Mm.malloc


    mov dword[Hexagon.Partitions.Table.base], ebx

    popad

    ret

;;************************************************************************************

Hexagon.Dev.Disk:

.operationCode: db 0

;; Budget reserved for FAT/root directory reads. Not yet enforced at every read site
Hexagon.Disk.DiskCache.maxSize = 200000

;;************************************************************************************

align 4

;; Stop disks in use on the system
;;
;; Input and output: empty

Hexagon.Kernel.Dev.Disk.Disk.stopDisk:

;; Every present ATA drive, and not only mounted ones (a raw /dev/hdN writer
;; wouldn't show up as a mount either), flushed before power actually goes
;; away

    cmp byte[Hexagon.ATA.present], 1
    jne .noATAToFlush

    push eax
    push edx

    xor eax, eax

.flushLoop:

    cmp byte[Hexagon.ATA.drivesTable + eax], 0
    je .nextDrive

    mov dl, al

    push eax

    call Hexagon.Dev.ATA.flushCache

    pop eax

.nextDrive:

    inc eax
    cmp eax, Hexagon.ATA.maxDrives

    jb .flushLoop

    pop edx
    pop eax

.noATAToFlush:

    ret

;;************************************************************************************

;; Obtain useful information about the disk from the MBR (Master Boot Record)
;;
;; Output:
;;
;; AH - Partition code
;; Other data can be stored in appropriate variables in the future

Hexagon.Kernel.Dev.Disk.Disk.readMBR:

    push ds ;; Kernel data segment
    pop es

;; First we must load the MBR into memory

    mov eax, 01h ;; Number of sectors to read
    mov esi, 00h ;; Start LBA sector
    mov cx, 0 ;; Destination is a flat address, no segment to fold in
    mov edi, Hexagon.Heap.DiskCache + 20000 ;; Offset
    mov dl, byte[Hexagon.Dev.Disk.Control.currentDisk]

    call Hexagon.Kernel.Dev.Disk.Disk.readSectors

    jc .error

    mov ebx, Hexagon.Heap.DiskCache + 20000

    add ebx, 0x1BE ;; Deslocamento da primeira partição

    mov ah, byte[es:ebx+04h] ;; Contains the file system

    jmp .end

.error:

    stc

.end:

    ret

;;************************************************************************************

;; Get BPB (BIOS Parameter Block) from disk to memory
;;
;; Output:
;;
;; Nothing, load directly at kernel memory

Hexagon.Kernel.Dev.Disk.Disk.readBPB:

    push ds ;; Kernel data segment
    pop es

;; First, load MBR into disk cache in kernel memory

    mov eax, 01h ;; Read one sector
    mov esi, 00h ;; Start LBA sector
    mov cx, 0 ;; Destination is a flat address, no segment to fold in
    mov edi, Hexagon.Heap.DiskCache ;; Offset
    mov dl, byte[Hexagon.Dev.Disk.Control.currentDisk] ;; Current volume

    call Hexagon.Kernel.Dev.Disk.Disk.readSectors

    jc .error

;; Check to MBR signatue (55AAh). If invalid, we don't load the right sector

    mov edi, Hexagon.Heap.DiskCache

    cmp word [es:edi+0x1FE], 0xAA55
    jne .error

;; Calculates the LBA of the boot sector of the first partition (MBR + 1 sector)

    mov esi, [es:edi+0x1BE+08h] ;; LBA bytes continues

;; Loads the BPB of the first partition directly into kernel memory

    mov eax, 01h ;; Read one sector
    mov cx, 0 ;; Destination is a flat address, no segment to fold in
    mov edi, Hexagon.Heap.DiskGeometry
    mov dl, byte[Hexagon.Dev.Disk.Control.currentDisk]

    call Hexagon.Kernel.Dev.Disk.Disk.readSectors

    mov dword[Hexagon.Dev.Disk.Control.diskGeometry], Hexagon.Heap.DiskGeometry

    jc .error

    jmp .end

.error:

    jmp $

    stc

.end:

    ret

;;************************************************************************************

;; Detects hard disks hd0-hd3 and records presence in Hexagon.Disks.Table.
;; A disk counts as present if its sector 0 can actually be read.
;; A real read is the only reliable signal here
;;
;; Output: empty

Hexagon.Kernel.Dev.Disk.Disk.detectDisks:

    pushad

    mov byte[.drive], 80h
    mov ebx, 0

    call .probeDrive

    mov byte[.drive], 81h
    mov ebx, 1

    call .probeDrive

    mov byte[.drive], 82h
    mov ebx, 2

    call .probeDrive

    mov byte[.drive], 83h
    mov ebx, 3

    call .probeDrive

    popad

    ret

;; Input:
;;
;; BL - Slot in Hexagon.Disks.Table for this drive (0-3)
;; .drive - BIOS drive number to probe (80h-83h), set by the caller

.probeDrive:

    push ebx ;; tryReadSector doesn't return anything through EBX, but be safe

    mov dl, byte[.drive]
    mov esi, 0 ;; Sector 0 (MBR). A successful read is enough to call it present
    mov cx, 0 ;; Destination is a flat address, no segment to fold in
    mov edi, Hexagon.Heap.DiskCache + 20000

    call Hexagon.Kernel.Dev.Disk.Disk.tryReadSector

    pop ebx

    jc .absent

    mov al, byte[.drive]
    mov edx, dword[Hexagon.Disks.Table.base]
    mov byte[edx + Hexagon.Disks.Table.drive + ebx], al
    mov byte[edx + Hexagon.Disks.Table.present + ebx], 1

;; Registers the whole disk itself, separate from its own partitions, so
;; mount can target "hd{slot}" without a partition suffix and get the
;; first supported one

    mov esi, dword[.hdNames + ebx * 4]

    mov al, 01h ;; Hexagon.Dev.DeviceClasses.block
    mov cl, 0FFh ;; No explicit partition, use the first supported one

    call Hexagon.Kernel.Dev.Dev.registerDevice

    ret

.absent:

    mov edx, dword[Hexagon.Disks.Table.base]
    mov byte[edx + Hexagon.Disks.Table.present + ebx], 0

    ret

.drive: db 0
.hdNames:
dd Hexagon.Dev.Devices.hd0
dd Hexagon.Dev.Devices.hd1
dd Hexagon.Dev.Devices.hd2
dd Hexagon.Dev.Devices.hd3

;;************************************************************************************

;; Reads a single sector without Hexagon.Kernel.Dev.Disk.Disk.readSectors'
;; panic and volume-reset error handling, meant for probing a disk that
;; answered detectDisk but might still fail to read
;;
;; Input:
;;
;; DL  - Drive
;; ESI - LBA
;; EDI - Destination buffer
;; CX  - Real mode segment
;;
;; Output:
;;
;; CF set on any failure

Hexagon.Kernel.Dev.Disk.Disk.tryReadSector:

    push eax
    push esi

;; See Hexagon.Kernel.Dev.Disk.Disk.readSectors for the DL translation

    cmp byte[Hexagon.AHCI.present], 1
    jne .tryAHCIDone_tryRead

    movzx ebx, dl

    sub ebx, 80h
    
    cmp ebx, Hexagon.AHCI.maxDrives
    jae .tryAHCIDone_tryRead

    cmp byte[Hexagon.AHCI.drivesPort + ebx], 0FFh
    je .tryAHCIDone_tryRead

    push ecx
    push edx
    push eax

    mov eax, 1   ;; Single sector (EAX = count, ESI already holds the LBA,
                 ;; matching Hexagon.Dev.SATA.AHCI.readSectors' own convention)
    mov dl, bl   ;; DL = AHCI drive index 0-3

    call Hexagon.Dev.SATA.AHCI.readSectors

    mov ax, 18h ;; Flat ES, this subsystem's own post-call convention
    mov es, ax

    pop eax

    jc .ahciFailed_tryRead

    pop edx
    pop ecx
    pop esi
    pop eax

    clc

    ret

.ahciFailed_tryRead:

    pop edx
    pop ecx

.tryAHCIDone_tryRead:

    cmp byte[Hexagon.ATA.present], 1
    jne .tryReadFailed

    movzx ebx, dl
    sub ebx, 80h
    cmp ebx, Hexagon.ATA.maxDrives
    jae .tryReadFailed

    cmp byte[Hexagon.ATA.drivesTable + ebx], 0
    je .tryReadFailed

    push ecx
    push edx

;; CX names the segment EDI is an offset into, folded in as a real-mode
;; segment would be. The ATA driver writes through a flat ES, so the delta
;; is applied explicitly, before ECX becomes the sector count below

    movzx eax, cx
   
    shl eax, 4
   
    push eax ;; CX*16 delta, subtracted back off EDI below regardless of outcome
   
    add edi, eax

    mov ecx, 1   ;; Single sector
    mov eax, esi ;; EAX = LBA
    mov dl, bl   ;; DL = ATA drive index 0-3

    call Hexagon.Dev.ATA.readSectors

    pop eax
    sub edi, eax

;; Hexagon.Dev.ATA.readSectors leaves ES exactly as it found it, while this
;; subsystem's own convention is to hand it back on the kernel linear
;; selector. Match that so callers need no code path per driver

    mov ax, 18h
    mov es, ax

    jc .ataFailed

    pop edx
    pop ecx
    pop esi
    pop eax

    clc

    ret

.ataFailed:

    pop edx
    pop ecx

.tryReadFailed:

    pop esi
    pop eax

    stc

    ret

;;************************************************************************************

;; Reads the MBR of every disk marked present in Hexagon.Disks.Table and
;; records its primary partitions (up to 4 per disk) in
;; Hexagon.Partitions.Table, including whether Hexagon has a driver for each
;; one's filesystem type. Leaves Hexagon.Dev.Disk.Control untouched
;;
;; Output: empty

Hexagon.Kernel.Dev.Disk.Disk.detectPartitions:

    pushad

    mov dword[.nextSlot], 0

    mov ebx, 0
    call .scanDisk

    mov ebx, 1
    call .scanDisk

    mov ebx, 2
    call .scanDisk

    mov ebx, 3
    call .scanDisk

    popad

    ret

;; Input:
;;
;; BL - Slot in Hexagon.Disks.Table to scan for partitions

.scanDisk:

    mov edx, dword[Hexagon.Disks.Table.base]

    cmp byte[edx + Hexagon.Disks.Table.present + ebx], 0
    je .doneDisk

    mov dl, byte[edx + Hexagon.Disks.Table.drive + ebx]
    mov byte[.driveNumber], dl

    push ebx

    mov dl, byte[.driveNumber]
    mov esi, 0 ;; MBR is always LBA 0
    mov cx, 0 ;; Destination is a flat address, no segment to fold in
    mov edi, Hexagon.Heap.DiskCache + 20000

    call Hexagon.Kernel.Dev.Disk.Disk.tryReadSector

    pop ebx

    jc .doneDisk ;; Answered detectDisk, but its MBR isn't readable

    cmp word[Hexagon.Heap.DiskCache + 20000 + 0x1FE], 0xAA55
    jne .doneDisk ;; No valid partition table

    mov byte[.entry], 0

.nextEntry:

    cmp byte[.entry], 4
    jae .doneDisk

    movzx esi, byte[.entry]

    shl esi, 4 ;; 16 bytes per entry
    add esi, Hexagon.Heap.DiskCache + 20000 + 0x1BE

    cmp byte[esi + 4], 0 ;; Partition type. 0 means an unused entry
    je .skipEntry

    push ebx ;; logHexagon inside .recordPartition clobbers EBX

    call .recordPartition

    pop ebx

.skipEntry:

    inc byte[.entry]

    jmp .nextEntry

.doneDisk:

    ret

;; Input:
;;
;; ESI - Pointer to this partition's 16-byte MBR entry (type at +4, LBA
;;       start at +8, sector count at +12)
;; BL  - Disk slot this partition belongs to (Hexagon.Disks.Table)
;; .entry (static) - Which of the disk's 4 primary entries (0-3)

.recordPartition:

    mov edi, dword[.nextSlot]

    cmp edi, Hexagon.Partitions.Table.limit
    jae .full

    mov edx, dword[Hexagon.Partitions.Table.base]

    mov byte[edx + Hexagon.Partitions.Table.present + edi], 1
    mov byte[edx + Hexagon.Partitions.Table.diskSlot + edi], bl

    mov al, byte[.entry]
    mov byte[edx + Hexagon.Partitions.Table.index + edi], al

    mov al, byte[esi + 4]
    mov byte[edx + Hexagon.Partitions.Table.filesystemType + edi], al

    mov eax, dword[esi + 8]
    mov dword[edx + Hexagon.Partitions.Table.startLBA + edi * 4], eax

    mov eax, dword[esi + 12]
    mov dword[edx + Hexagon.Partitions.Table.totalSectors + edi * 4], eax

    mov al, byte[esi + 4]

    call Hexagon.Kernel.FS.VFS.isFilesystemSupported ;; Doesn't touch EDX

    jc .unsupported

    mov byte[edx + Hexagon.Partitions.Table.supported + edi], 1

    jmp .recorded

.unsupported:

    mov byte[edx + Hexagon.Partitions.Table.supported + edi], 0

    logHexagon Hexagon.Verbose.Disk.partitionUnsupported, Hexagon.Dmesg.Priorities.p5

.recorded:

    mov ecx, edi

    mov edi, .deviceName

    call Hexagon.Kernel.Dev.Disk.Disk.buildPartitionName

    mov esi, .deviceName

    mov al, 01h ;; Hexagon.Dev.DeviceClasses.block
    mov bl, byte[edx + Hexagon.Partitions.Table.diskSlot + ecx]
    mov cl, byte[edx + Hexagon.Partitions.Table.index + ecx]

    call Hexagon.Kernel.Dev.Dev.registerDevice

    inc dword[.nextSlot]

.full:

    ret

.entry: db 0
.nextSlot: dd 0
.driveNumber: db 0
.deviceName: times 8 db 0

;;************************************************************************************

;; Builds "hd{disk slot}p{partition index}" for one Hexagon.Partitions.Table
;; entry into a caller-supplied buffer, NUL terminated
;;
;; Input:
;;
;; ECX - Index into Hexagon.Partitions.Table
;; EDI - Destination buffer (at least 6 bytes)

Hexagon.Kernel.Dev.Disk.Disk.buildPartitionName:

    push eax
    push edx

    mov edx, dword[Hexagon.Partitions.Table.base]

    mov byte[edi + 0], 'h'
    mov byte[edi + 1], 'd'

    movzx eax, byte[edx + Hexagon.Partitions.Table.diskSlot + ecx]
    
    add al, '0'
    
    mov byte[edi + 2], al

    mov byte[edi + 3], 'p'

    movzx eax, byte[edx + Hexagon.Partitions.Table.index + ecx]
    
    add al, '0'
    
    mov byte[edi + 4], al

    mov byte[edi + 5], 0

    pop edx
    pop eax

    ret

;;************************************************************************************

;; Logs a one-line summary of every volume found.
;;
;; Output: empty

Hexagon.Kernel.Dev.Disk.Disk.logDetectionSummary:

    pushad

    mov edi, .summaryBuffer
    mov esi, .volumesLabel

.copyVolumesLabel:

    lodsb

    cmp al, 0
    je .volumesLabelDone

    mov byte[edi], al

    inc edi

    jmp .copyVolumesLabel

.volumesLabelDone:

    mov dword[.listStart], edi

    xor ebx, ebx

    mov edx, dword[Hexagon.Partitions.Table.base]

.volumesLoop:

    cmp ebx, Hexagon.Partitions.Table.limit
    jae .volumesDone

    cmp byte[edx + Hexagon.Partitions.Table.present + ebx], 0
    je .volumesNext

    cmp byte[edx + Hexagon.Partitions.Table.supported + ebx], 0
    je .volumesNext

    mov ecx, ebx

    call Hexagon.Kernel.Dev.Disk.Disk.buildPartitionName ;; Writes the name + NUL at EDI, preserves EAX/EDX/EBX/EDI

    add edi, 5

    mov byte[edi], ' '

    inc edi

.volumesNext:

    inc ebx

    jmp .volumesLoop

.volumesDone:

    cmp edi, dword[.listStart]
    je .volumesNoTrim

    dec edi

.volumesNoTrim:

    mov byte[edi], 0

    logHexagon .summaryBuffer, Hexagon.Dmesg.Priorities.p5

    popad

    ret

.listStart:    dd 0
.volumesLabel: db "Volumes detected: ", 0
.summaryBuffer:
times 128 db 0

;;************************************************************************************

;; Load disk sector using BIOS extended functions
;;
;; Input:
;;
;; EAX - Number of sectors
;; ESI - LBA
;; EDI - Destination buffer
;; CX  - Real mode segment
;; DL  - Drive
;;
;; Output:
;;
;; EBX - Return code from executed disk operation (Hexagon.Dev.Disk.HardDisk)

Hexagon.Kernel.Dev.Disk.Disk.readSectors:

    push eax
    push esi

;; DL is a BIOS-style drive number (80h-83h) here, matching
;; Hexagon.Disks.Table/Hexagon.Kernel.Dev.Disk.Disk.detectDisks

    cmp byte[Hexagon.AHCI.present], 1
    jne .tryAHCIDone_read

    movzx ebx, dl
    
    sub ebx, 80h
    
    cmp ebx, Hexagon.AHCI.maxDrives
    jae .tryAHCIDone_read

    cmp byte[Hexagon.AHCI.drivesPort + ebx], 0FFh
    je .tryAHCIDone_read

    push ecx
    push edx

    ;; EAX (sector count) and ESI (LBA) already match
    ;; Hexagon.Dev.SATA.AHCI.readSectors' own convention as-is

    mov dl, bl   ;; DL = AHCI drive index 0-3

    call Hexagon.Dev.SATA.AHCI.readSectors

    mov ax, 18h ;; Flat ES, this subsystem's own post-call convention
    mov es, ax

    pop edx ;; Restores DL to the original BIOS-style drive number
    pop ecx

    jnc .withoutError

.tryAHCIDone_read:

    cmp byte[Hexagon.ATA.present], 1
    jne .readFailed

    movzx ebx, dl
    sub ebx, 80h
    cmp ebx, Hexagon.ATA.maxDrives
    jae .readFailed

    cmp byte[Hexagon.ATA.drivesTable + ebx], 0
    je .readFailed

    push eax ;; Sector count, restored below regardless of outcome
    push ecx
    push edx

;; CX names the segment EDI is an offset into, folded in as a real-mode
;; segment would be. The ATA driver writes through a flat ES, so the delta
;; is applied explicitly, before ECX becomes the sector count below

    movzx eax, cx
    
    shl eax, 4
    
    push eax ;; CX*16 delta, subtracted back off EDI below regardless of outcome
    
    add edi, eax

    mov eax, dword[esp + 12] ;; Sector count, saved further down the stack above
    mov ecx, eax ;; ECX = sector count (Hexagon.Dev.ATA.readSectors' own convention)
    mov eax, esi ;; EAX = LBA
    mov dl, bl   ;; DL = ATA drive index 0-3

    call Hexagon.Dev.ATA.readSectors

    pop eax
    sub edi, eax

;; See Hexagon.Kernel.Dev.Disk.Disk.tryReadSector for why this matches
;; this subsystem's own post-call segment convention

    mov ax, 18h
    mov es, ax

    pop edx ;; Restores DL to the original BIOS-style drive number
    pop ecx
    pop eax

    jnc .withoutError

.readFailed:

    mov byte[Hexagon.Dev.Disk.operationCode], Hexagon.Dev.Disk.HardDisk.IO.operationFailure

    stc

    jmp .finish

.withoutError:

    mov byte[Hexagon.Dev.Disk.operationCode], Hexagon.Dev.Disk.HardDisk.IO.withoutError

.finish:

    pop esi
    pop eax

    movzx ebx, byte[Hexagon.Dev.Disk.operationCode] ;; Provide the operation return code in EBX

    ret

;;************************************************************************************

;; Writes sectors to disk via native ATA/AHCI
;;
;; Input:
;;
;; EAX - Number of sectors
;; ESI - LBA
;; EDI - Write buffer
;; CX  - Real mode segment
;; DL  - Drive
;;
;; Output:
;;
;; EBX - Return code from performed disk operation (Hexagon.Dev.Disk.HardDisk)

Hexagon.Kernel.Dev.Disk.Disk.writeSectors:

    push eax
    push esi

;; See Hexagon.Kernel.Dev.Disk.Disk.readSectors for the DL translation

    cmp byte[Hexagon.AHCI.present], 1
    jne .tryAHCIDone_write

    movzx ebx, dl
    
    sub ebx, 80h
    
    cmp ebx, Hexagon.AHCI.maxDrives
    jae .tryAHCIDone_write

    cmp byte[Hexagon.AHCI.drivesPort + ebx], 0FFh
    je .tryAHCIDone_write

    push ecx
    push edx

;; EAX (sector count) and ESI (LBA) already match
;; Hexagon.Dev.SATA.AHCI.writeSectors' own convention as-is

    mov dl, bl   ;; DL = AHCI drive index 0-3

    call Hexagon.Dev.SATA.AHCI.writeSectors

    mov ax, 18h ;; Flat ES, this subsystem's own post-call convention
    mov es, ax

    pop edx ;; Restores DL to the original BIOS-style drive number
    pop ecx

    jnc .withoutError

.tryAHCIDone_write:

    cmp byte[Hexagon.ATA.present], 1
    jne .writeFailed

    movzx ebx, dl
    
    sub ebx, 80h
    
    cmp ebx, Hexagon.ATA.maxDrives
    jae .writeFailed

    cmp byte[Hexagon.ATA.drivesTable + ebx], 0
    je .writeFailed

    push eax ;; Sector count [esp+16 below]
    push esi ;; LBA [esp+12 below]
    push edi ;; Source buffer, restored below
    push ecx
    push edx

;; CX names the segment ESI is an offset into, folded in as a real-mode
;; segment would be. The ATA driver reads through a flat DS, so the delta is
;; applied explicitly, into a fresh ESI and not the pushed one above

    movzx eax, cx
    
    shl eax, 4
    
    mov esi, edi
    add esi, eax

    mov eax, dword[esp + 16] ;; Original sector count, pushed above
    mov ecx, eax ;; ECX = sector count (Hexagon.Dev.ATA.writeSectors' own convention)

    mov eax, dword[esp + 12] ;; Original LBA, pushed above
    mov dl, bl   ;; DL = ATA drive index 0-3

    call Hexagon.Dev.ATA.writeSectors

;; See Hexagon.Kernel.Dev.Disk.Disk.tryReadSector for why this matches
;; this subsystem's own post-call segment convention

    mov ax, 18h
    mov es, ax

    pop edx
    pop ecx
    pop edi
    pop esi
    pop eax

    jnc .withoutError

.writeFailed:

    mov byte[Hexagon.Dev.Disk.operationCode], Hexagon.Dev.Disk.HardDisk.IO.operationFailure

    stc

    jmp .finish

.withoutError:

    mov byte[Hexagon.Dev.Disk.operationCode], Hexagon.Dev.Disk.HardDisk.IO.withoutError

.finish:

    pop esi
    pop eax

    movzx ebx, byte[Hexagon.Dev.Disk.operationCode];; Provide the operation return code in EBX

    ret

;;************************************************************************************

;; Flushes a disk's own write cache to physical media. Meant to be called
;; rarely and deliberately (unmount, shutdown, reboot), never after every
;; write. See Hexagon.Dev.ATA.flushCache's own comment
;;
;; Input:
;;
;; DL - BIOS-style drive number (80h, 81h, ...)
;;
;; Output:
;;
;; CF set on error (never set on the BIOS no-op path)

Hexagon.Kernel.Dev.Disk.Disk.flushDisk:

    push eax
    push ebx

    cmp byte[Hexagon.ATA.present], 1
    jne .notATA

    movzx ebx, dl
    
    sub ebx, 80h
    
    cmp ebx, Hexagon.ATA.maxDrives
    jae .notATA

    cmp byte[Hexagon.ATA.drivesTable + ebx], 0
    je .notATA

    mov dl, bl ;; DL = ATA drive index 0-3

    call Hexagon.Dev.ATA.flushCache

    pop ebx
    pop eax

    ret

.notATA:

    pop ebx
    pop eax

    clc

    ret

;;************************************************************************************

;; Tests a certain volume to verify its presence.
;; If it is not present, an error will be set, as per (Hexagon.Dev.Disk.HardDisk)

Hexagon.Kernel.Dev.Disk.Disk.testVolume:

    mov eax, 1
    mov esi, 01
    mov cx, 0 ;; Destination is a flat address, no segment to fold in
    mov edi, Hexagon.Heap.DiskCache + 20000 ;; Offset
    mov dl, byte[Hexagon.Dev.Disk.Control.currentDisk]

    call Hexagon.Kernel.Dev.Disk.Disk.readSectors

    ret
