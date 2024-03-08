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

;;************************************************ ***********************************
;;
;; Input and output errors on floppy disks
;;
;; Error | Error description
;; -------------------------------------------------- ---------------------------------
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
;; 0ch  | Media type not available
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
; Error | Error description
;; -------------------------------------------------- ---------------------------------
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

struc Hexagon.Dev.Gen.Disk.General
{

.withoutError      = 00h
.invalidCommand    = 01h
.invalidAddress    = 02h
.writeProtected    = 03h
.invalidSector     = 04h
.resetFailure      = 05h
.activityFailure   = 07h
.DMAFailure        = 08h
.DMALimit          = 09h
.sectorDamaged     = 0Ah
.cylinderError     = 0Bh
.invalidNumSet     = 0x0D
.controllerFailure = 20h
.noMedia           = 31h
.timeOut           = 80h
.driveNotReady     = 0xAA
.busyVolume        = 0xB3
.unknownError      = 0xBB
.writeFailure      = 0xCC
.statusError       = 0xE0
.operationFailure  = 0xFF

}

struc Hexagon.Dev.Gen.Disk.HardDisk
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

struc Hexagon.Dev.Gen.Disk.Control
{

.currentDisk: db 0
.bootDisk:    db 0

}

Hexagon.Dev.Gen.Disk.Codes  Hexagon.Dev.Gen.Disk.General
Hexagon.Dev.Gen.Disk.HardDisk.IO Hexagon.Dev.Gen.Disk.HardDisk
Hexagon.Dev.Gen.Disk.Control Hexagon.Dev.Gen.Disk.Control

Hexagon.Dev.Gen.Disk:

.operationCode: db 0

;;************************************************************************************

align 4

;; Stop disks in use on the system
;;
;; Input and output: empty

Hexagon.Kernel.Dev.i386.Disk.Disk.stopDisk:

    call Hexagon.Kernel.Dev.i386.Disk.Disk.resetDisk

    ret

;;************************************************************************************

;; Obtain useful information about the disk from the MBR (Master Boot Record)
;;
;; Output:
;;
;; AH - Partition code
;; Other data can be stored in appropriate variables in the future

Hexagon.Kernel.Dev.i386.Disk.Disk.readMBR:

    push ds ;; Kernel data segment
    pop es

;; First we must load the MBR into memory

    mov eax, 01h ;; Number of sectors to read
    mov esi, 00h ;; Start LBA sector
    mov cx, 50h  ;; Segment
    mov edi, Hexagon.Heap.DiskCache + 20000 ;; Offset
    mov dl, byte[Hexagon.Dev.Gen.Disk.Control.currentDisk]

    call Hexagon.Kernel.Dev.i386.Disk.Disk.readSectors

    jc .error

    mov ebx, Hexagon.Heap.DiskCache + 500h + 20000

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
;; Nothing, load directly at 0000:7C00h

Hexagon.Kernel.Dev.i386.Disk.Disk.readBPB:

    push ds ;; Kernel data segment
    pop es

;; First we must load the MBR into memory

    mov eax, 01h
    mov esi, 00h
    mov cx, 2000h ;; Segment
    mov edi, 0x7C00 ;; Offset
    mov dl, byte[Hexagon.Dev.Gen.Disk.Control.currentDisk]

    call Hexagon.Kernel.Dev.i386.Disk.Disk.readSectors

    jc .error

    jmp .end

.error:

    stc

.end:

    ret

;;************************************************************************************

;; Restarts a given disk provided as a parameter
;;
;; Input:
;;
;; DL - Disk code
;;
;; Output:
;;
;; EAX - 01h if an error occurred in the process

Hexagon.Kernel.Dev.i386.Disk.Disk.resetDisk:

    mov ah, 00h

    call Hexagon.Kernel.Arch.i386.BIOS.BIOS.int13h

    jc .error

    jmp .end

.error:

    stc

    mov eax, 01h

.end:

    ret

;;************************************************************************************

;; Detects whether there is a hard or removable drive connected to the computer.
;; Can be used to check whether the requested disk is available for mounting
;;
;; Input:
;;
;; EAX - 00h if to use the default disk
;; DL  - Disk code, to check another volume
;;
;; Output:
;;
;; AH - 00h for not installed, 01h for failure to detect disk change
;;      02h for failure to detect floppy change and 03h for hard disk
;; CF setting on error, with AH with BIOS error code

Hexagon.Kernel.Dev.i386.Disk.Disk.detectDisk:

    clc

;; Let's call the BIOS to request this information

    mov ah, 15h

    cmp eax, 00h
    je .defaultDisk

    jmp .continue

.defaultDisk:

    mov dl, byte[Hexagon.Dev.Gen.Disk.Control.currentDisk]

.continue:

    mov al, 0xFF
    mov cx, 0xFFFF

    call Hexagon.Kernel.Arch.i386.BIOS.BIOS.int13h

    jc .error

    jmp .end

.error:

;; The BIOS error table must be observed

    stc

.end:

    ret

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
;; EBX - Return code from executed disk operation (Hexagon.Dev.Gen.Disk.HardDisk)

Hexagon.Kernel.Dev.i386.Disk.Disk.readSectors:

    push eax
    push esi

    mov dword[.DAP.totalSectors], eax ;; Total sectors to load
    mov dword[.DAP.LBA], esi ;; Linear Block Addres - LBA

    mov eax, edi
    shr eax, 4

    add cx, ax

    and edi, 0xF

    mov word[.DAP.segment], cx ;; Real mode segment
    mov word[.DAP.offset], di

    mov esi, .DAP
    mov ah, 42h ;; BIOS extended reading

    call Hexagon.Kernel.Arch.i386.BIOS.BIOS.int13h ;; BIOS disk services

    jnc .withoutError

.checkError:

    cmp ah, Hexagon.Dev.Gen.Disk.Codes.invalidAddress
    je .noMedia

    cmp ah, Hexagon.Dev.Gen.Disk.Codes.invalidSector
    je .noMedia

    cmp ah, Hexagon.Dev.Gen.Disk.Codes.activityFailure
    je .noMedia

    cmp ah, Hexagon.Dev.Gen.Disk.Codes.controllerFailure
    je .noMedia

    cmp al, Hexagon.Dev.Gen.Disk.Codes.noMedia
    je .noMedia

    cmp al, Hexagon.Dev.Gen.Disk.Codes.timeOut
    je .generalError

    jmp .generalError ;; Print error and wait for restart

.generalError:

    mov esi, Hexagon.Verbose.Disco.erroDisco

    mov eax, 1

    call Hexagon.Kernel.Kernel.Panico.panico

.noMedia:

    mov dl, byte [Hexagon.Dev.Gen.Disk.Control.bootDisk]
    mov byte [Hexagon.Dev.Gen.Disk.Control.currentDisk], dl

    call Hexagon.Kernel.FS.VFS.iniciarSistemaArquivos

    mov byte[Hexagon.Dev.Gen.Disk.operationCode], Hexagon.Dev.Gen.Disk.HardDisk.IO.noMedia

    stc

    jmp .finish

.withoutError:

    mov byte[Hexagon.Dev.Gen.Disk.operationCode], Hexagon.Dev.Gen.Disk.HardDisk.IO.withoutError

.finish:

    pop esi
    pop eax

    movzx ebx, byte[Hexagon.Dev.Gen.Disk.operationCode] ;; Provide the operation return code in EBX

    ret

;; DAP (Disk Address Packet)

.DAP:
.DAP.size:         db 16
.DAP.reserved:     db 0
.DAP.totalSectors: dw 0
.DAP.offset:       dw 0000h
.DAP.segment:      dw 0
.DAP.LBA:          dd 0
                   dd 0

;;************************************************************************************

;; Write sectors to disk using extended BIOS functions
;;
;; Input:
;;
;; EAX - Number of sectors
;; ESI - LBS
;; EDI - Write buffer
;; CX  - Real mode segment
;; DL  - Drive
;;
;; Output:
;;
;; EBX - Return code from performed disk operation (Hexagon.Dev.Gen.Disk.HardDisk)

Hexagon.Kernel.Dev.i386.Disk.Disk.writeSectors:

    push eax
    push esi

    mov dword[.DAP.totalSectors], eax ;; Total sectors to write
    mov dword[.DAP.LBA], esi ;; LBA

    mov eax, edi
    shr eax, 4

    add cx, ax

    and edi, 0xF

    mov word[.DAP.offset], di
    mov word[.DAP.segment], cx ;; Real mode segment

    mov esi, .DAP
    mov ah, 43h ;; BIOS extended writing
    mov al, 0

    call Hexagon.Kernel.Arch.i386.BIOS.BIOS.int13h ;; BIOS disk services

    jnc .withoutError

.checkError:

    cmp ah, Hexagon.Dev.Gen.Disk.Codes.invalidAddress
    je .noMedia

    cmp ah, Hexagon.Dev.Gen.Disk.Codes.writeProtected
    je .writeProtected

    cmp ah, Hexagon.Dev.Gen.Disk.Codes.driveNotReady
    je .volumeNotReady

    cmp ah, Hexagon.Dev.Gen.Disk.Codes.busyVolume
    je .busyVolume

    cmp ah, Hexagon.Dev.Gen.Disk.Codes.writeFailure
    je .writeFailure

    cmp ah, Hexagon.Dev.Gen.Disk.Codes.invalidSector
    je .noMedia

    cmp al, Hexagon.Dev.Gen.Disk.Codes.activityFailure
    je .noMedia

    cmp al, Hexagon.Dev.Gen.Disk.Codes.controllerFailure
    je .noMedia

    cmp al, Hexagon.Dev.Gen.Disk.Codes.noMedia
    je .noMedia

    cmp al, Hexagon.Dev.Gen.Disk.Codes.timeOut
    je .generalError

    jmp .generalError ;; Print error and wait for restart

.writeProtected:

    stc

    mov byte[Hexagon.Dev.Gen.Disk.operationCode], Hexagon.Dev.Gen.Disk.HardDisk.IO.writeProtected

    ret

.volumeNotReady:

    stc

    mov byte[Hexagon.Dev.Gen.Disk.operationCode], Hexagon.Dev.Gen.Disk.HardDisk.IO.volumeNotReady

    ret

.busyVolume:

    stc

    mov byte[Hexagon.Dev.Gen.Disk.operationCode], Hexagon.Dev.Gen.Disk.HardDisk.IO.busyVolume

    ret

.writeFailure:

    stc

    mov byte[Hexagon.Dev.Gen.Disk.operationCode], Hexagon.Dev.Gen.Disk.HardDisk.IO.operationFailure

    ret

.generalError:

    mov esi, Hexagon.Verbose.Disco.erroDisco

    mov eax, 1

    call Hexagon.Kernel.Kernel.Panico.panico

.noMedia:

    mov dl, byte [Hexagon.Dev.Gen.Disk.Control.bootDisk]
    mov byte [Hexagon.Dev.Gen.Disk.Control.currentDisk], dl

    call Hexagon.Kernel.FS.VFS.iniciarSistemaArquivos

    mov byte[Hexagon.Dev.Gen.Disk.operationCode], Hexagon.Dev.Gen.Disk.HardDisk.IO.noMedia

    stc

    jmp .finish

.withoutError:

    mov byte[Hexagon.Dev.Gen.Disk.operationCode], Hexagon.Dev.Gen.Disk.HardDisk.IO.withoutError

.finish:

    pop esi
    pop eax

    movzx ebx, byte[Hexagon.Dev.Gen.Disk.operationCode];; Provide the operation return code in EBX

    ret

;; DAP (Disk Address Packet)

.DAP:
.DAP.size:         db 16
.DAP.reserved:     db 0
.DAP.totalSectors: dw 0
.DAP.offset:       dw 0000h
.DAP.segment:      dw 0
.DAP.LBA:          dd 0
                   dd 0

;;************************************************************************************

;; Tests a certain volume to verify its presence.
;; If it is not present, an error will be set, as per (Hexagon.Dev.Gen.Disk.HardDisk)

Hexagon.Kernel.Dev.i386.Disk.Disk.testVolume:

    mov eax, 1
    mov esi, 01
    mov cx, 50h ;; Segment
    mov edi, Hexagon.Heap.DiskCache + 20000 ;; Offset
    mov dl, byte[Hexagon.Dev.Gen.Disk.Control.currentDisk]

    call Hexagon.Kernel.Dev.i386.Disk.Disk.readSectors

    ret
