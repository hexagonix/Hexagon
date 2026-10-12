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
;;                         Native ATA/IDE Storage Driver
;;
;; 32-bit protected mode native driver for ATA/IDE controllers (Primary/Secondary channels).
;; Operates in LBA28/LBA48 PIO mode directly accessing I/O ports 0x1F0-0x1F7 / 0x170-0x177.
;; Eliminates any BIOS int 13h dependency for legacy and virtualized storage.
;;
;;************************************************************************************

Hexagon.ATA.PRIMARY_IO_BASE    = 1F0h
Hexagon.ATA.PRIMARY_CTRL_BASE  = 3F6h
Hexagon.ATA.SECONDARY_IO_BASE  = 170h
Hexagon.ATA.SECONDARY_CTRL_BASE = 376h

;; Register Offsets relative to IO_BASE

Hexagon.ATA.REG_DATA       = 0
Hexagon.ATA.REG_ERROR      = 1
Hexagon.ATA.REG_FEATURES   = 1
Hexagon.ATA.REG_SECCOUNT   = 2
Hexagon.ATA.REG_LBA_LO     = 3
Hexagon.ATA.REG_LBA_MID    = 4
Hexagon.ATA.REG_LBA_HI     = 5
Hexagon.ATA.REG_DRIVE_HEAD = 6
Hexagon.ATA.REG_STATUS     = 7
Hexagon.ATA.REG_COMMAND    = 7

;; Commands

Hexagon.ATA.CMD_READ_SECTORS     = 20h
Hexagon.ATA.CMD_READ_SECTORS_EXT = 24h
Hexagon.ATA.CMD_WRITE_SECTORS    = 30h
Hexagon.ATA.CMD_WRITE_SECTORS_EXT= 34h
Hexagon.ATA.CMD_IDENTIFY         = 0ECh
Hexagon.ATA.CMD_FLUSH_CACHE      = 0E7h

;; Status Register Bits

Hexagon.ATA.STATUS_ERR = 01h ;; Error
Hexagon.ATA.STATUS_DRQ = 08h ;; Data Request Ready
Hexagon.ATA.STATUS_DF  = 20h ;; Drive Fault
Hexagon.ATA.STATUS_RDY = 40h ;; Ready
Hexagon.ATA.STATUS_BSY = 80h ;; Busy

Hexagon.ATA.maxDrives = 4

Hexagon.ATA.present:     db 0
Hexagon.ATA.drivesCount: dd 0

;; Table of drive presence (1 = present, 0 = absent) for drives 0..3
;; Drive 0 = Primary Master
;; Drive 1 = Primary Slave
;; Drive 2 = Secondary Master
;; Drive 3 = Secondary Slave

Hexagon.ATA.drivesTable: times Hexagon.ATA.maxDrives db 0

;; IDENTIFY data lands in Hexagon.Heap.ATA.IdentifyBuffer (kern/kern.asm),
;; not a buffer local to this file. See that reservation's own comment

Hexagon.ATA.activeDrive:  db 0
Hexagon.ATA.activeDriveW: db 0

;;************************************************************************************

;; Initializes and probes all 4 ATA channels/drives
;;
;; Output:
;;   CF = 0 if at least 1 ATA drive is found
;;   CF = 1 if no ATA drives found

Hexagon.Dev.ATA.setupATA:

    mov byte[Hexagon.ATA.present], 0
    mov dword[Hexagon.ATA.drivesCount], 0

    xor ebx, ebx

.probeAllDrives:

    push ebx

    mov dl, bl ;; Drive index 0..3

    call Hexagon.Dev.ATA.identifyDrive

    pop ebx

    jnc .driveFound

    mov byte[Hexagon.ATA.drivesTable + ebx], 0

    jmp .nextDrive

.driveFound:

    mov byte[Hexagon.ATA.drivesTable + ebx], 1

    inc dword[Hexagon.ATA.drivesCount]

    push ebx

    mov esi, dword[.driveLogNames + ebx * 4]
    mov ebx, Hexagon.Dmesg.Priorities.p4

    call Hexagon.Kern.Dmesg.createMessage

    pop ebx

.nextDrive:

    inc ebx

    cmp ebx, 4
    jb .probeAllDrives

;; Reset primary and secondary channels back to master (0xA0)

    mov dx, Hexagon.ATA.PRIMARY_IO_BASE + Hexagon.ATA.REG_DRIVE_HEAD
    mov al, 0A0h

    out dx, al

    mov dx, Hexagon.ATA.SECONDARY_IO_BASE + Hexagon.ATA.REG_DRIVE_HEAD
    mov al, 0A0h

    out dx, al

    call Hexagon.Dev.ATA.ioDelay

    cmp dword[Hexagon.ATA.drivesCount], 0
    je .noDrives

    mov byte[Hexagon.ATA.present], 1

    logHexagon Hexagon.ATA.Verbose.ready, Hexagon.Dmesg.Priorities.p4

    clc

    ret

.noDrives:

    stc

    ret

.driveLogNames:
dd Hexagon.ATA.Verbose.drive0
dd Hexagon.ATA.Verbose.drive1
dd Hexagon.ATA.Verbose.drive2
dd Hexagon.ATA.Verbose.drive3

Hexagon.ATA.Verbose:

.ready:  db "ATA: Native IDE/ATA driver active and ready.", 0
.drive0: db "ATA: Drive found on Primary Master (hd0).", 0
.drive1: db "ATA: Drive found on Primary Slave (hd1).", 0
.drive2: db "ATA: Drive found on Secondary Master (hd2).", 0
.drive3: db "ATA: Drive found on Secondary Slave (hd3).", 0

;;************************************************************************************

;; Probes and identifies an ATA drive (DL = drive 0..3)
;;
;; Output:
;;   CF = 0 if drive answered ATA IDENTIFY
;;   CF = 1 if no response / error / ATAPI

Hexagon.Dev.ATA.identifyDrive:

    pushad

    mov bl, dl ;; BL = drive index (0..3)

    call Hexagon.Dev.ATA.getChannelPorts ;; EDX = IO base

;; Select drive: Master = 0xA0, Slave = 0xB0

    mov al, 0A0h

    test bl, 1
    jz .sendHead

    mov al, 0B0h

.sendHead:

    push edx

    add dx, Hexagon.ATA.REG_DRIVE_HEAD

    out dx, al

    pop edx

    call Hexagon.Dev.ATA.ioDelay ;; 400ns delay

;; Quick latch check: write 0x55/0xAA to SecCount/LBA_LO

    push edx

    add dx, Hexagon.ATA.REG_SECCOUNT

    mov al, 55h

    out dx, al
    
    inc dx ;; REG_LBA_LO
    
    mov al, 0AAh
    
    out dx, al

    dec dx ;; REG_SECCOUNT

    in al, dx
    
    cmp al, 55h
    jne .latchFail

    inc dx ;; REG_LBA_LO
    
    in al, dx
    
    cmp al, 0AAh
    jne .latchFail

    pop edx
    
    jmp .latchOk

.latchFail:
    
    pop edx
    
    jmp .identError

.latchOk:

;; Reset sector count and LBA registers to 0

    push edx
    
    add dx, Hexagon.ATA.REG_SECCOUNT
    
    mov al, 0
    
    out dx, al
    
    inc dx ;; REG_LBA_LO
    
    out dx, al
    
    inc dx ;; REG_LBA_MID
    
    out dx, al
    
    inc dx ;; REG_LBA_HI
    
    out dx, al
    
    pop edx

;; Send IDENTIFY command (0xEC) to command register
    
    push edx
    
    add dx, Hexagon.ATA.REG_COMMAND
    
    mov al, Hexagon.ATA.CMD_IDENTIFY
    
    out dx, al
    
    pop edx

    call Hexagon.Dev.ATA.ioDelay ;; 400ns delay after command

;; Read status
    
    push edx
    
    add dx, Hexagon.ATA.REG_STATUS
    
    in al, dx
    
    pop edx

    cmp al, 0 ;; Status 0 means no drive
    je .identError
    
    cmp al, 0FFh ;; Status 0xFF means floating bus / no drive
    je .identError

    call Hexagon.Dev.ATA.waitNotBusy ;; Wait for BSY to clear
    
    jc .identError

;; Check LBA_MID and LBA_HI to verify not ATAPI / SATA
    
    push edx
    
    add dx, Hexagon.ATA.REG_LBA_MID
    
    in al, dx
    
    mov ah, al
    
    inc dx ;; REG_LBA_HI
    
    in al, dx
    
    pop edx

    cmp ax, 0
    jne .identError ;; Non-zero means ATAPI or SATA bridge

    call Hexagon.Dev.ATA.waitDRQ ;; Wait for DRQ or ERR

    jc .identError

;; Read 256 words (512 bytes) of IDENTIFY data
    
    push es
    
    mov ax, 18h ;; Flat data segment (base 0)
    mov es, ax
    
    cld
    mov edi, Hexagon.Heap.ATA.IdentifyBuffer
    mov ecx, 256
    
    rep insw
    
    pop es

    popad
    
    clc
    
    ret

.identError:

    popad
    
    stc
    
    ret

;;************************************************************************************

;; Reads sectors from ATA drive (DL = drive 0..3)
;;
;; Input:
;;   EAX = LBA (32-bit)
;;   ECX = Sector count (1..256)
;;   EDI = Destination memory buffer (physical address)
;;   DL  = Drive index (0..3)
;;
;; Output:
;;   CF  = 0 on success, 1 on error

Hexagon.Dev.ATA.readSectors:

    pushad
    push es

;; A 0 here would make every "decrement remaining, then test" loop below
;; wrap to 0xFFFFFFFF on its first pass instead of ever seeing zero, a
;; multi-billion-iteration spin with interrupts held off the whole time.
;; A genuine zero-sector request has nothing to do anyway, so it is
;; simplest to just skip all of that machinery

    cmp ecx, 0
    je .zeroSectors

    mov byte[Hexagon.ATA.activeDrive], dl
    mov ebp, ecx ;; EBP = remaining sector count
    mov ebx, eax ;; EBX = current LBA, captured before AX is clobbered below

    mov ax, 18h  ;; Flat segment (base 0)
    mov es, ax

;; A timer tick landing mid-transfer here is a bare PIO poll loop away from
;; a caller that assumed a near-instant call. Held off for the whole
;; transfer, restored on every exit below

    pushfd

    cli

;; One ATA command transfers up to 256 sectors, the count register wrapping
;; 0 to mean 256, with the drive advancing LBA and reasserting DRQ for each
;; one. Only an oversized request needs a second command, handled below

.commandLoop:

    mov dl, byte[Hexagon.ATA.activeDrive]
    
    call Hexagon.Dev.ATA.getChannelPorts ;; EDX = IO base

    mov esi, ebp ;; ESI = sectors for this command, capped to 256
    
    cmp esi, 256
    jbe .countOk
    
    mov esi, 256

.countOk:

;; 1. Select Drive and top 4 bits of LBA: 0xE0 | (slave << 4) | (LBA >> 24 & 0xF)

    push edx
    
    add dx, Hexagon.ATA.REG_DRIVE_HEAD
    
    mov eax, ebx
    
    shr eax, 24
    and al, 0Fh
    
    or al, 0E0h
    test byte[Hexagon.ATA.activeDrive], 1
    
    jz .headOkR
    
    or al, 10h ;; Slave bit

.headOkR:

    out dx, al
    
    pop edx

    call Hexagon.Dev.ATA.ioDelay ;; 400ns delay after drive selection

;; 2. Wait for drive to not be busy
    
    call Hexagon.Dev.ATA.waitNotBusy
    
    jc .readErr

;; 3. Set sector count (256 truncates to AL = 0, the correct encoding)
    
    push edx
    
    add dx, Hexagon.ATA.REG_SECCOUNT
    
    mov eax, esi
    
    out dx, al

;; 4. Set LBA low, mid, high
    
    inc dx ;; LBA_LO (1F3h)
    
    mov al, bl
    
    out dx, al

    inc dx ;; LBA_MID (1F4h)
    
    mov al, bh
    
    out dx, al

    inc dx ;; LBA_HI (1F5h)
    
    mov eax, ebx
    
    shr eax, 16
    
    out dx, al

;; 5. Send READ SECTORS command (0x20)
    
    add dx, 2 ;; REG_COMMAND (1F7h)
    
    mov al, Hexagon.ATA.CMD_READ_SECTORS
    
    out dx, al
    
    pop edx

    call Hexagon.Dev.ATA.ioDelay ;; 400ns delay after command issue

    push esi ;; This command's own sector count, used as the transfer loop counter

.sectorTransferLoop:

;; 6. Wait for DRQ, once per sector
    
    call Hexagon.Dev.ATA.waitDRQ
    
    jc .readErrInner

;; 7. Read 256 words (512 bytes) from DATA register (1F0h)
    
    push edx
    
    mov ecx, 256
    
    rep insw ;; Reads directly into [ES:EDI] and advances EDI by 512
    
    pop edx

    inc ebx        ;; Next LBA (bookkeeping; the drive advances its own internal LBA itself)
    dec dword[esp] ;; This command's remaining sectors
    
    jnz .sectorTransferLoop

    pop eax      ;; Discard the now-zero inner counter
    
    sub ebp, esi ;; ESI untouched by the transfer loop above, still this command's count
    
    jnz .commandLoop

    popfd
    pop es
    popad
    
    clc
    
    ret

.zeroSectors:

    pop es
    popad
    
    clc
    
    ret

.readErrInner:

    pop eax ;; Discard this command's pushed sector counter

.readErr:

    popfd

    pop es
    popad
    
    stc
    
    ret

;;************************************************************************************

;; Writes sectors to ATA drive (DL = drive 0..3)
;;
;; Input:
;;   EAX = LBA (32-bit)
;;   ECX = Sector count (1..256)
;;   ESI = Source memory buffer (physical address)
;;   DL  = Drive index (0..3)
;;
;; Output:
;;   CF  = 0 on success, 1 on error

Hexagon.Dev.ATA.writeSectors:

    pushad
    push ds

;; See Hexagon.Dev.ATA.readSectors for why a zero count can't be allowed
;; anywhere near the "decrement remaining, then test" loops below

    cmp ecx, 0
    je .zeroSectors

    mov ebp, ecx ;; EBP = remaining sector count
    mov ebx, eax ;; EBX = current LBA, captured before AX is clobbered below

    mov ax, 18h  ;; Flat segment (base 0)
    mov ds, ax

;; Stored only after DS is flat, matching every later read of
;; Hexagon.ATA.activeDriveW below (.commandLoop included)

    mov byte[Hexagon.ATA.activeDriveW], dl

;; See Hexagon.Dev.ATA.readSectors for why this transfer runs with
;; interrupts held off

    pushfd
    cli

;; See Hexagon.Dev.ATA.readSectors for why this batches up to 256 sectors
;; into a single command instead of reissuing one per sector. ESI is the
;; source data pointer here (advanced automatically by outsw), not free
;; like Hexagon.Dev.ATA.readSectors' ESI, so this command's own sector
;; count lives on the stack instead

.commandLoop:

    mov dl, byte[Hexagon.ATA.activeDriveW]
    
    call Hexagon.Dev.ATA.getChannelPorts ;; EDX = IO base

;; 1. Select Drive and top 4 bits of LBA
    
    push edx
    
    add dx, Hexagon.ATA.REG_DRIVE_HEAD
    
    mov eax, ebx
    
    shr eax, 24
    
    and al, 0Fh
    
    or al, 0E0h
    
    test byte[Hexagon.ATA.activeDriveW], 1
    jz .headOkW
    
    or al, 10h

.headOkW:
    
    out dx, al
    
    pop edx

    call Hexagon.Dev.ATA.ioDelay ;; 400ns delay

;; 2. Wait for drive to not be busy
    
    call Hexagon.Dev.ATA.waitNotBusy
    
    jc .writeErr

;; This command's own sector count, capped to 256, kept in EDI and not
;; EAX: Hexagon.Dev.ATA.waitDRQ clobbers AL with the status register on
;; every poll, which silently corrupted this counter when it lived in EAX

    mov edi, ebp

    cmp edi, 256
    jbe .countOkW
    
    mov edi, 256

.countOkW:
    
    push edi ;; This command's count, kept until the ebp subtraction at the end

;; 3. Set sector count (256 truncates to AL = 0, the correct encoding)
    
    push edx
    
    add dx, Hexagon.ATA.REG_SECCOUNT
    
    mov al, byte[esp + 4] ;; +4 past the just-pushed edx, reaching this command's count
    
    out dx, al

;; 4. Set LBA low, mid, high
    
    inc dx ;; LBA_LO
    
    mov al, bl
    
    out dx, al

    
    inc dx ;; LBA_MID
    
    mov al, bh
    
    out dx, al

    
    inc dx ;; LBA_HI
    
    mov eax, ebx
    
    shr eax, 16
    
    out dx, al

;; 5. Send WRITE SECTORS command (0x30)
    
    add dx, 2 ;; REG_COMMAND
    
    mov al, Hexagon.ATA.CMD_WRITE_SECTORS
    
    out dx, al
    
    pop edx

    call Hexagon.Dev.ATA.ioDelay ;; 400ns delay after command issue

.sectorTransferLoopW:

;; 6. Wait for DRQ, once per sector
    
    call Hexagon.Dev.ATA.waitDRQ
    
    jc .writeErrInner

;; 7. Write 256 words (512 bytes) to DATA register
    
    push edx
    
    mov ecx, 256
    
    rep outsw ;; Writes directly from [DS:ESI] and advances ESI by 512
    
    pop edx

    inc ebx   ;; Next LBA (bookkeeping; the drive advances its own internal LBA itself)
    dec edi
    
    jnz .sectorTransferLoopW

;; No cache flush here: fat16.asm calls writeSectors many times per file
;; (FAT entries, directory entry, each cluster). A flush per call, each
;; with its own wait-not-busy, paid for a real fsync-class cost on every
;; one of those instead of once per file

    pop eax   ;; This command's original count, pushed above
   
    sub ebp, eax
    jnz .commandLoop

    popfd

    pop ds
    popad

    clc
    
    ret

.zeroSectors:

    pop ds
    popad
    
    clc
    
    ret

.writeErrInner:

    pop eax ;; Discard this command's pushed sector count

.writeErr:

    popfd

    pop ds
    popad
    
    stc
    
    ret

;;************************************************************************************

;; Flushes the drive's own write cache to physical media. Meant to be
;; called rarely and deliberately (unmount, shutdown, reboot), not after
;; every write. See Hexagon.Dev.ATA.writeSectors' own comment on why not
;;
;; Input:
;;
;; DL - ATA drive index (0-3)
;;
;; Output:
;;
;; CF set on error

Hexagon.Dev.ATA.flushCache:

    pushad

    mov byte[.targetDrive], dl

    call Hexagon.Dev.ATA.getChannelPorts ;; EDX = IO base; DL no longer the drive index past this point

    push edx
    
    add dx, Hexagon.ATA.REG_DRIVE_HEAD
    
    mov al, 0E0h
    
    test byte[.targetDrive], 1
    jz .headOk
    
    or al, 10h

.headOk:
    
    out dx, al
    
    pop edx

    call Hexagon.Dev.ATA.ioDelay
    call Hexagon.Dev.ATA.waitNotBusy
    
    jc .error

    push edx
    
    add dx, Hexagon.ATA.REG_COMMAND
    
    mov al, Hexagon.ATA.CMD_FLUSH_CACHE
    
    out dx, al
    
    pop edx

    call Hexagon.Dev.ATA.ioDelay
    call Hexagon.Dev.ATA.waitNotBusy
    
    jc .error

    popad
    
    clc
    
    ret

.error:

    popad
    
    stc
    
    ret

.targetDrive: db 0

;;************************************************************************************

;; Returns IO base port for drive index (DL = 0..3) in EDX

Hexagon.Dev.ATA.getChannelPorts:

    cmp dl, 2
    jae .secondary

    mov edx, Hexagon.ATA.PRIMARY_IO_BASE
    ret

.secondary:

    mov edx, Hexagon.ATA.SECONDARY_IO_BASE
    ret

;;************************************************************************************

;; Waits until BSY bit in Status register clears
;; EDX = IO base port

Hexagon.Dev.ATA.waitNotBusy:

    push ecx
    push edx

;; A bare status-register poll has no per-iteration delay, so a small count
;; expires in microseconds, far short of a drive still spinning up from cold.
;; This generous, bounded count stands in for a real wall-clock timeout

    add dx, Hexagon.ATA.REG_STATUS

    mov ecx, 1000000

.waitLoop:

    in al, dx

    test al, Hexagon.ATA.STATUS_BSY
    jz .notBusy

    dec ecx

    jnz .waitLoop

    pop edx
    pop ecx

    stc
    
    ret

.notBusy:

    pop edx
    pop ecx
    
    clc
    
    ret

;;************************************************************************************

;; Waits until DRQ is set and BSY is cleared
;; EDX = IO base port

Hexagon.Dev.ATA.waitDRQ:

    push ecx
    push edx

;; A bare status-register poll has no per-iteration delay, so a small count
;; expires in microseconds, far short of a drive still spinning up from cold.
;; This generous, bounded count stands in for a real wall-clock timeout

    add dx, Hexagon.ATA.REG_STATUS

    mov ecx, 1000000

.waitLoop:

    in al, dx
    
    test al, Hexagon.ATA.STATUS_BSY
    jnz .retry

    test al, Hexagon.ATA.STATUS_ERR or Hexagon.ATA.STATUS_DF
    jnz .error

    test al, Hexagon.ATA.STATUS_DRQ
    jnz .ready

.retry:

    dec ecx
    
    jnz .waitLoop

.error:

    pop edx
    pop ecx
    
    stc
    
    ret

.ready:

    pop edx
    pop ecx
    
    clc
    
    ret

;;************************************************************************************

;; I/O delay (400ns by reading status port 4 times)

Hexagon.Dev.ATA.ioDelay:

    push edx
    push eax

    add dx, Hexagon.ATA.REG_STATUS
    
    in al, dx
    in al, dx
    in al, dx
    in al, dx

    pop eax
    pop edx
    
    ret