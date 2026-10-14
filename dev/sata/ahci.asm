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
;;                       SATA AHCI 1.0+ Storage Device Driver
;;
;; Native 32-bit storage driver using AHCI MMIO and DMA transfers via PRDT.
;;
;;************************************************************************************

;; AHCI Generic Host Control Register Offsets (relative to ABAR)

Hexagon.AHCI.HBA.CAP = 000h ;; Host Capabilities
Hexagon.AHCI.HBA.GHC = 004h ;; Global Host Control
Hexagon.AHCI.HBA.IS  = 008h ;; Interrupt Status
Hexagon.AHCI.HBA.PI  = 00Ch ;; Ports Implemented
Hexagon.AHCI.HBA.VS  = 010h ;; Version

;; Global Host Control Bits

Hexagon.AHCI.GHC.HR = 1           ;; Bit 0: HBA Reset
Hexagon.AHCI.GHC.IE = 2           ;; Bit 1: Interrupt Enable
Hexagon.AHCI.GHC.AE = 80000000h   ;; Bit 31: AHCI Enable

;; AHCI Port Register Offsets (relative to ABAR + 0x100 + port * 0x80)

Hexagon.AHCI.PORT.CLB  = 000h ;; Command List Base Address (1K aligned)
Hexagon.AHCI.PORT.CLBU = 004h ;; Command List Base Address Upper
Hexagon.AHCI.PORT.FB   = 008h ;; FIS Base Address (256 bytes aligned)
Hexagon.AHCI.PORT.FBU  = 00Ch ;; FIS Base Address Upper
Hexagon.AHCI.PORT.IS   = 010h ;; Port Interrupt Status
Hexagon.AHCI.PORT.IE   = 014h ;; Port Interrupt Enable
Hexagon.AHCI.PORT.CMD  = 018h ;; Port Command and Status
Hexagon.AHCI.PORT.TFD  = 020h ;; Task File Data
Hexagon.AHCI.PORT.SIG  = 024h ;; Signature
Hexagon.AHCI.PORT.SSTS = 028h ;; SATA Status
Hexagon.AHCI.PORT.SCTL = 02Ch ;; SATA Control
Hexagon.AHCI.PORT.SERR = 030h ;; SATA Error
Hexagon.AHCI.PORT.SACT = 034h ;; SATA Active
Hexagon.AHCI.PORT.CI   = 038h ;; Command Issue

;; Port Command Register Bits

Hexagon.AHCI.CMD.ST  = 0001h  ;; Start processing command list
Hexagon.AHCI.CMD.SUD = 0002h  ;; Spin-up device
Hexagon.AHCI.CMD.POD = 0004h  ;; Power on device
Hexagon.AHCI.CMD.FRE = 0010h  ;; FIS Receive Enable
Hexagon.AHCI.CMD.FR  = 4000h  ;; FIS Receive Running
Hexagon.AHCI.CMD.CR  = 8000h  ;; Command List Running

;; ATA Commands

Hexagon.AHCI.ATA.READ_DMA      = 0C8h
Hexagon.AHCI.ATA.WRITE_DMA     = 0CAh
Hexagon.AHCI.ATA.READ_DMA_EXT  = 25h
Hexagon.AHCI.ATA.WRITE_DMA_EXT = 35h
Hexagon.AHCI.ATA.IDENTIFY      = 0ECh

;; FIS Types

Hexagon.AHCI.FIS.TYPE_REG_H2D = 27h

;; Signatures

Hexagon.AHCI.SIG_ATA   = 00000101h ;; SATA Drive
Hexagon.AHCI.SIG_ATAPI = 0EB140101h ;; SATAPI Drive

Hexagon.AHCI.maxDrives = 4

;; Global AHCI driver state

Hexagon.AHCI.present:     db 0
Hexagon.AHCI.abar:        dd 0
Hexagon.AHCI.drivesCount: dd 0

;; Table of detected AHCI drives: port number for drive index 0..3

Hexagon.AHCI.drivesPort: times Hexagon.AHCI.maxDrives db 0FFh

;; This driver is synchronous, always waiting for a command to finish and never
;; leaving two in flight, so one shared command list, FIS and table set is safe
;; to reuse across every drive. Each port is repointed at it during initPort

;; Set by readSectors/writeSectors from the caller's DL (an AHCI drive index
;; 0-3, already translated from a BIOS-style drive number by disk.asm, same
;; convention Hexagon.Dev.ATA uses) before EDX gets reused for the port's
;; MMIO base address

Hexagon.AHCI.activeDrive: db 0

Hexagon.AHCI.currentPort: db 0

;;************************************************************************************

;; Detects and initializes the SATA AHCI Host Controller
;;
;; Output:
;;   CF = 0 if AHCI controller and at least 1 SATA drive found
;;   CF = 1 if no AHCI controller or drive found

Hexagon.Dev.SATA.AHCI.setupAHCI:

    push es
    push ds

    mov ax, 10h
    mov ds, ax          ;; DS = kernel data selector

    mov ax, 18h
    mov es, ax          ;; ES = 18h (Base 0h)

    mov byte[Hexagon.AHCI.present], 0
    mov dword[Hexagon.AHCI.drivesCount], 0

;; Search for PCI Mass Storage Controller (Class 01h), SATA (Subclass 06h), AHCI (ProgIF 01h)

    mov ah, 01h         ;; Mass Storage
    mov al, 06h         ;; Serial ATA
    mov bl, 01h         ;; AHCI 1.0

    call Hexagon.Dev.PCI.findDevice

    jc .notFound

;; ESI points to Hexagon.PCI.Device record

    call Hexagon.Dev.PCI.enableBusMaster

;; Read ABAR (BAR5)

    mov eax, dword[esi + Hexagon.PCI.Device.bar5]

    and eax, 0FFFFFFF0h ;; Mask memory flags

    mov dword[Hexagon.AHCI.abar], eax

;; 1. HBA Reset

    mov edx, dword[Hexagon.AHCI.abar]
    mov eax, dword[es:edx + Hexagon.AHCI.HBA.GHC]

    or eax, Hexagon.AHCI.GHC.HR or Hexagon.AHCI.GHC.AE
    mov dword[es:edx + Hexagon.AHCI.HBA.GHC], eax

    mov ecx, 1000000

.waitHBAReset:

    mov eax, dword[es:edx + Hexagon.AHCI.HBA.GHC]

    test eax, Hexagon.AHCI.GHC.HR
    jz .hbaResetDone

    dec ecx

    jnz .waitHBAReset

.hbaResetDone:

;; Enable AHCI mode in HBA Global Host Control

    mov eax, dword[es:edx + Hexagon.AHCI.HBA.GHC]

    or eax, Hexagon.AHCI.GHC.AE

    mov dword[es:edx + Hexagon.AHCI.HBA.GHC], eax

    mov byte[Hexagon.AHCI.present], 1

    logHexagon Hexagon.AHCI.Verbose.found, Hexagon.Dmesg.Priorities.p4

;; Probe all implemented ports

    call Hexagon.Dev.SATA.AHCI.probePorts

    cmp dword[Hexagon.AHCI.drivesCount], 0
    je .noDrives

    logHexagon Hexagon.AHCI.Verbose.ready, Hexagon.Dmesg.Priorities.p4

    pop ds
    pop es

    clc

    ret

.noDrives:
.notFound:

    pop ds
    pop es

    stc

    ret

Hexagon.AHCI.Verbose:

.found:     db "AHCI: SATA controller initialized.", 0
.ready:     db "AHCI: Native SATA driver active and ready.", 0
.sataDrive: db "AHCI: SATA hard drive detected on port.", 0

;;************************************************************************************

;; Probes implemented ports in the AHCI controller

Hexagon.Dev.SATA.AHCI.probePorts:

    pushad
    push es
    push ds

    mov ax, 10h
    mov ds, ax
    mov ax, 18h
    mov es, ax

    mov edx, dword[Hexagon.AHCI.abar]
    mov eax, dword[es:edx + Hexagon.AHCI.HBA.PI] ;; Ports Implemented bitmask

    xor ecx, ecx ;; Port index 0..31

.portLoop:

    test eax, 1
    jz .nextPort

    push eax
    push ecx

    
    mov byte[Hexagon.AHCI.currentPort], cl
    
    call Hexagon.Dev.SATA.AHCI.initPort
    
    pop ecx
    pop eax

.nextPort:

    shr eax, 1
    
    inc ecx
    
    cmp ecx, 32
    jb .portLoop

    pop ds
    pop es
    
    popad
    
    ret

;;************************************************************************************

;; Initializes an individual AHCI port (Hexagon.AHCI.currentPort). Points
;; that port's own CLB/FB at the single shared buffer set, same for every
;; port. See the comment on Hexagon.AHCI.activeDrive

Hexagon.Dev.SATA.AHCI.initPort:

    pushad
    push es
    push ds

    mov ax, 10h
    mov ds, ax
    mov ax, 18h
    mov es, ax

;; Calculate Port register base: ABAR + 0x100 + port * 0x80

    movzx edx, byte[Hexagon.AHCI.currentPort]

    shl edx, 7

    add edx, 100h
    add edx, dword[Hexagon.AHCI.abar]

;; 1. Check if device is physically connected on this port:
;; PxSSTS.DET (bits 3:0) must be 3 (device present and Phy communication established)

    mov eax, dword[es:edx + Hexagon.AHCI.PORT.SSTS]

    and eax, 0Fh

    cmp eax, 3
    jne .portDone

;; 2. Stop command engine (ST = 0, FRE = 0)

    mov eax, dword[es:edx + Hexagon.AHCI.PORT.CMD]

    and eax, not (Hexagon.AHCI.CMD.ST or Hexagon.AHCI.CMD.FRE)

    mov dword[es:edx + Hexagon.AHCI.PORT.CMD], eax

;; Wait for CR and FR to clear

    mov ecx, 100000

.waitEngineStop:

    mov eax, dword[es:edx + Hexagon.AHCI.PORT.CMD]

    test eax, Hexagon.AHCI.CMD.CR or Hexagon.AHCI.CMD.FR
    jz .engineStopped

    dec ecx

    jnz .waitEngineStop

.engineStopped:

;; 2. Set Command List Base (1K aligned physical address)

    mov eax, Hexagon.Heap.AHCI.CommandList
    mov dword[es:edx + Hexagon.AHCI.PORT.CLB], eax
    mov dword[es:edx + Hexagon.AHCI.PORT.CLBU], 0

;; 3. Set Received FIS Base (256 bytes aligned physical address)

    mov eax, Hexagon.Heap.AHCI.ReceivedFIS
    mov dword[es:edx + Hexagon.AHCI.PORT.FB], eax
    mov dword[es:edx + Hexagon.AHCI.PORT.FBU], 0

;; Switch ES to the kernel data selector for clearing structures

    push ds

    pop es

;; 4. Clear Command List memory (1024 bytes)

    mov edi, Hexagon.Heap.AHCI.CommandList
    mov ecx, 256 ;; 256 dwords = 1024 bytes

    xor eax, eax

    cld

    rep stosd

;; 5. Clear Received FIS memory (256 bytes)

    mov edi, Hexagon.Heap.AHCI.ReceivedFIS
    mov ecx, 64 ;; 64 dwords = 256 bytes

    xor eax, eax

    rep stosd

;; 6. Clear Command Table memory (256 bytes)

    mov edi, Hexagon.Heap.AHCI.CommandTable
    mov ecx, 64 ;; 64 dwords = 256 bytes

    xor eax, eax

    rep stosd

;; 7. Initialize Command Header 0 pointing to CommandTable

    mov edi, Hexagon.Heap.AHCI.CommandList
    mov dword[edi + 0], 5 or (1 shl 16) ;; CFL=5, PRDTL=1
    mov dword[edi + 4], 0 ;; PRDBC=0
    mov dword[edi + 8], Hexagon.Heap.AHCI.CommandTable ;; CTBA
    mov dword[edi + 12], 0 ;; CTBAU

;; Restore ES to 18h (Base 0h Linear) for MMIO

    mov ax, 18h
    mov es, ax

;; Recalculate EDX

    movzx edx, byte[Hexagon.AHCI.currentPort]

    shl edx, 7

    add edx, 100h
    add edx, dword[Hexagon.AHCI.abar]

;; 8. Clear SATA errors (PxSERR) and interrupts (PxIS)

    mov dword[es:edx + Hexagon.AHCI.PORT.SERR], 0FFFFFFFFh
    mov dword[es:edx + Hexagon.AHCI.PORT.IS], 0FFFFFFFFh

;; 9. Power on and spin up device on this port

    mov eax, dword[es:edx + Hexagon.AHCI.PORT.CMD]

    or eax, Hexagon.AHCI.CMD.SUD or Hexagon.AHCI.CMD.POD

    mov dword[es:edx + Hexagon.AHCI.PORT.CMD], eax

;; 10. Start FIS reception (FRE = 1)

    mov eax, dword[es:edx + Hexagon.AHCI.PORT.CMD]

    or eax, Hexagon.AHCI.CMD.FRE

    mov dword[es:edx + Hexagon.AHCI.PORT.CMD], eax

;; Wait for device not BSY and not DRQ before enabling ST. Real spin-up
;; after SUD/POD is not instant on real hardware or a faithful emulator,
;; unlike QEMU's own AHCI model. A port that never becomes ready is
;; skipped, not started blind

    mov ecx, 100000000

.waitPortReady:

    mov eax, dword[es:edx + Hexagon.AHCI.PORT.TFD]

    test eax, 88h
    jz .startPortEngine

    dec ecx

    jnz .waitPortReady

    jmp .portDone

.startPortEngine:

;; 11. Start command processing (ST = 1)

    mov eax, dword[es:edx + Hexagon.AHCI.PORT.CMD]

    or eax, Hexagon.AHCI.CMD.ST

    mov dword[es:edx + Hexagon.AHCI.PORT.CMD], eax

;; 12. Check Signature (PxSIG): skip if ATAPI (CD-ROM)

    mov eax, dword[es:edx + Hexagon.AHCI.PORT.SIG]

    cmp eax, Hexagon.AHCI.SIG_ATAPI
    je .portDone

;; SATA drive confirmed! Record in driver table

    mov eax, dword[Hexagon.AHCI.drivesCount]

    cmp eax, Hexagon.AHCI.maxDrives
    jae .portDone

    mov cl, byte[Hexagon.AHCI.currentPort]
    mov byte[Hexagon.AHCI.drivesPort + eax], cl
   
    inc dword[Hexagon.AHCI.drivesCount]

    logHexagon Hexagon.AHCI.Verbose.sataDrive, Hexagon.Dmesg.Priorities.p4

.portDone:

    pop ds
    pop es
   
    popad
   
    ret

;;************************************************************************************

;; Reads sectors from a SATA drive via AHCI DMA (LBA48)
;;
;; Input:
;;   EAX = Number of sectors (count)
;;   ESI = LBA (starting sector)
;;   EDI = Destination buffer offset
;;   CX  = Real-mode style segment (such as 50h, 00h)
;;   DL  = AHCI drive index (0-3)
;;
;; Output:
;;   CF  = 0 on success, 1 on error
;;   EBX = 0 on success, error code on failure

Hexagon.Dev.SATA.AHCI.readSectors:

    pushad
    push es
    push ds

    mov bx, 10h
    mov ds, bx ;; Ensure DS is the kernel data selector
    mov es, bx ;; Ensure ES is the kernel data selector

    cmp eax, 0
    je .readError ;; Nothing to do, and a 0 count would encode as -1 in the PRDT's DBC field below

    cmp byte[Hexagon.AHCI.present], 1
    jne .readError

    cmp dword[Hexagon.AHCI.drivesCount], 0
    je .readError

    mov byte[Hexagon.AHCI.activeDrive], dl ;; DL is about to be clobbered below

;; Calculate absolute physical address: (CX * 16) + EDI

    movzx ebx, cx

    shl ebx, 4

    add ebx, edi;; EBX = Physical destination buffer address in RAM

;; Calculate this drive's own port register base in MMIO
    
    movzx eax, byte[Hexagon.AHCI.activeDrive]
    
    cmp eax, Hexagon.AHCI.maxDrives
    jae .readError
    
    movzx edx, byte[Hexagon.AHCI.drivesPort + eax]
    
    cmp edx, 0FFh ;; No drive was ever recorded at this index
    je .readError
    
    shl edx, 7
    
    add edx, 100h
    add edx, dword[Hexagon.AHCI.abar] ;; EDX = Port MMIO base address

;; Switch ES to 18h (Base 0h Linear) for MMIO

    mov ax, 18h
    mov es, ax

;; Wait until port is not busy (PxTFD.BSY == 0 and PxTFD.DRQ == 0)

    mov ecx, 10000000

.waitNotBusy:

    mov eax, dword[es:edx + Hexagon.AHCI.PORT.TFD]

    test eax, 88h
    jz .readyToCommand

    dec ecx

    jnz .waitNotBusy

    jmp .readError

.readyToCommand:

;; Switch ES to the kernel data selector for memory structures

    push ds
    pop es

;; 1. Clear Command Table memory (256 bytes)

    mov edi, Hexagon.Heap.AHCI.CommandTable
    mov ecx, 64

    xor eax, eax

    cld

    rep stosd

;; 2. Configure Command Header 0 (Read: Write bit W = 0)

    mov edi, Hexagon.Heap.AHCI.CommandList
    mov dword[edi + 0], 5 or (1 shl 16) ;; CFL=5, W=0 (Read), PRDTL=1
    mov dword[edi + 4], 0 ;; PRDBC = 0
    mov dword[edi + 8], Hexagon.Heap.AHCI.CommandTable ;; CTBA
    mov dword[edi + 12], 0 ;; CTBAU

;; 3. Configure PRDT Entry 0

    mov edi, Hexagon.Heap.AHCI.CommandTable + 80h ;; PRDT offset
    mov dword[edi + 0], ebx                       ;; DBA: Physical destination address
    mov dword[edi + 4], 0                         ;; DBAU
    mov dword[edi + 8], 0                         ;; Reserved

    mov eax, dword[esp + 36] ;; Original EAX (Sector count) from pushad
    
    shl eax, 9               ;; count * 512
    
    dec eax                  ;; (count * 512) - 1
    
    mov dword[edi + 12], eax ;; DBC (Interrupt bit 31 = 0)

;; 4. Setup Command FIS H2D (READ DMA EXT - 0x25)

    mov edi, Hexagon.Heap.AHCI.CommandTable
    mov byte[edi + 0], Hexagon.AHCI.FIS.TYPE_REG_H2D
    mov byte[edi + 1], 80h                           ;; Command bit set
    mov byte[edi + 2], Hexagon.AHCI.ATA.READ_DMA_EXT ;; 0x25 (READ DMA EXT)
    mov byte[edi + 3], 0                             ;; Features low

    mov eax, dword[esp + 12] ;; Original ESI (LBA) from pushad
    mov byte[edi + 4], al    ;; LBA 0..7
    mov byte[edi + 5], ah    ;; LBA 8..15
   
    shr eax, 16
    
    mov byte[edi + 6], al    ;; LBA 16..23
    mov byte[edi + 7], 40h   ;; Device (0x40 = LBA mode)
   
    shr eax, 8
   
    mov byte[edi + 8], al    ;; LBA 24..31
    mov byte[edi + 9], 0     ;; LBA 32..39
    mov byte[edi + 10], 0    ;; LBA 40..47
    mov byte[edi + 11], 0    ;; Features high

    mov eax, dword[esp + 36] ;; Sector count from pushad
    mov byte[edi + 12], al   ;; Count low
    mov byte[edi + 13], ah   ;; Count high
    mov byte[edi + 14], 0
    mov byte[edi + 15], 0

;; Switch ES to 18h (Base 0h Linear) for MMIO
 
    mov ax, 18h
    mov es, ax

;; Recalculate this drive's own port register base in MMIO

    movzx eax, byte[Hexagon.AHCI.activeDrive]
    movzx edx, byte[Hexagon.AHCI.drivesPort + eax]

    shl edx, 7

    add edx, 100h
    add edx, dword[Hexagon.AHCI.abar]

;; Clear port interrupts and errors before issuing command

    mov dword[es:edx + Hexagon.AHCI.PORT.IS], 0FFFFFFFFh
    mov dword[es:edx + Hexagon.AHCI.PORT.SERR], 0FFFFFFFFh

;; 5. Issue command: Set bit 0 in PxCI

    mov dword[es:edx + Hexagon.AHCI.PORT.CI], 1

;; 6. Wait for command completion (PxCI bit 0 cleared)

    mov ecx, 20000000

.waitComplete:

    mov eax, dword[es:edx + Hexagon.AHCI.PORT.CI]

    test eax, 1
    jz .checkStatus

    dec ecx

    jnz .waitComplete

    jmp .readError

.checkStatus:

    mov eax, dword[es:edx + Hexagon.AHCI.PORT.TFD]

;; Check for errors in Task File Data (PxTFD.ERR)

    test eax, 01h
    jnz .readError

    pop ds
    pop es
    popad

    xor ebx, ebx

    clc

    ret

.readError:

    pop ds
    pop es
    popad

    mov ebx, 01h

    stc

    ret

;;************************************************************************************

;; Writes sectors to a SATA drive via AHCI DMA (LBA48)
;;
;; Input:
;;   EAX = Number of sectors (count)
;;   ESI = LBA (starting sector)
;;   EDI = Source buffer offset
;;   CX  = Real-mode style segment (such as 50h, 00h)
;;   DL  = AHCI drive index (0-3)
;;
;; Output:
;;   CF  = 0 on success, 1 on error
;;   EBX = 0 on success, error code on failure

Hexagon.Dev.SATA.AHCI.writeSectors:

    pushad
    push es
    push ds

    mov bx, 10h
    mov ds, bx ;; Ensure DS is the kernel data selector
    mov es, bx ;; Ensure ES is the kernel data selector

    cmp eax, 0
    je .writeError ;; Nothing to do, and a 0 count would encode as -1 in the PRDT's DBC field below

    cmp byte[Hexagon.AHCI.present], 1
    jne .writeError

    cmp dword[Hexagon.AHCI.drivesCount], 0
    je .writeError

    mov byte[Hexagon.AHCI.activeDrive], dl ;; DL is about to be clobbered below

;; Calculate absolute physical address: (CX * 16) + EDI

    movzx ebx, cx

    shl ebx, 4

    add ebx, edi;; EBX = Physical source buffer address in RAM

;; Calculate this drive's own port register base in MMIO

    movzx eax, byte[Hexagon.AHCI.activeDrive]

    cmp eax, Hexagon.AHCI.maxDrives
    jae .writeError

    movzx edx, byte[Hexagon.AHCI.drivesPort + eax]

    cmp edx, 0FFh ;; No drive was ever recorded at this index
    je .writeError

    shl edx, 7

    add edx, 100h
    add edx, dword[Hexagon.AHCI.abar]

;; Switch ES to 18h (Base 0h Linear) for MMIO

    mov ax, 18h
    mov es, ax

;; Wait until port is not busy

    mov ecx, 10000000

.waitNotBusyW:

    mov eax, dword[es:edx + Hexagon.AHCI.PORT.TFD]

    test eax, 88h
    jz .readyToCommandW

    dec ecx

    jnz .waitNotBusyW

    jmp .writeError

.readyToCommandW:

;; Switch ES to the kernel data selector for memory structures

    push ds
    pop es

;; 1. Clear Command Table memory (256 bytes)

    mov edi, Hexagon.Heap.AHCI.CommandTable
    mov ecx, 64

    xor eax, eax

    cld

    rep stosd

;; 2. Configure Command Header 0 (Write: Write bit W = 1 -> bit 6)

    mov edi, Hexagon.Heap.AHCI.CommandList
    mov dword[edi + 0], 5 or (1 shl 6) or (1 shl 16) ;; CFL=5, W=1, PRDTL=1
    mov dword[edi + 4], 0
    mov dword[edi + 8], Hexagon.Heap.AHCI.CommandTable
    mov dword[edi + 12], 0

;; 3. Configure PRDT Entry 0

    mov edi, Hexagon.Heap.AHCI.CommandTable + 80h
    mov dword[edi + 0], ebx ;; DBA: Physical source address
    mov dword[edi + 4], 0
    mov dword[edi + 8], 0

    mov eax, dword[esp + 36] ;; Original EAX (Sector count) from pushad
    
    shl eax, 9
    
    dec eax
    
    mov dword[edi + 12], eax ;; DBC

;; 4. Setup Command FIS H2D (WRITE DMA EXT - 0x35)

    mov edi, Hexagon.Heap.AHCI.CommandTable
    mov byte[edi + 0], Hexagon.AHCI.FIS.TYPE_REG_H2D
    mov byte[edi + 1], 80h                            ;; Command bit set
    mov byte[edi + 2], Hexagon.AHCI.ATA.WRITE_DMA_EXT ;; 0x35 (WRITE DMA EXT)
    mov byte[edi + 3], 0

    mov eax, dword[esp + 12] ;; Original ESI (LBA) from pushad
    mov byte[edi + 4], al
    mov byte[edi + 5], ah
    
    shr eax, 16
    
    mov byte[edi + 6], al
    mov byte[edi + 7], 40h ;; LBA mode
    
    shr eax, 8
    
    mov byte[edi + 8], al
    mov byte[edi + 9], 0
    mov byte[edi + 10], 0
    mov byte[edi + 11], 0

    mov eax, dword[esp + 36] ;; Count from pushad
    mov byte[edi + 12], al
    mov byte[edi + 13], ah
    mov byte[edi + 14], 0
    mov byte[edi + 15], 0

;; Switch ES to 18h (Base 0h Linear) for MMIO

    mov ax, 18h
    mov es, ax

;; Recalculate this drive's own port register base in MMIO

    movzx eax, byte[Hexagon.AHCI.activeDrive]
    movzx edx, byte[Hexagon.AHCI.drivesPort + eax]

    shl edx, 7

    add edx, 100h
    add edx, dword[Hexagon.AHCI.abar]

;; Clear port interrupts and errors before issuing command

    mov dword[es:edx + Hexagon.AHCI.PORT.IS], 0FFFFFFFFh
    mov dword[es:edx + Hexagon.AHCI.PORT.SERR], 0FFFFFFFFh

;; 5. Issue command: Set bit 0 in PxCI

    mov dword[es:edx + Hexagon.AHCI.PORT.CI], 1

;; 6. Wait for command completion (PxCI bit 0 cleared)

    mov ecx, 20000000

.waitCompleteW:

    mov eax, dword[es:edx + Hexagon.AHCI.PORT.CI]

    test eax, 1
    jz .checkStatusW

    dec ecx

    jnz .waitCompleteW

    jmp .writeError

.checkStatusW:

;; Check for errors in Task File Data (PxTFD.ERR)

    mov eax, dword[es:edx + Hexagon.AHCI.PORT.TFD]

    test eax, 01h
    jnz .writeError

    pop ds
    pop es
    popad

    xor ebx, ebx

    clc

    ret

.writeError:

    pop ds
    pop es
    popad

    mov ebx, 01h

    stc

    ret
