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

;;*********************************************************************
;;
;;                    Hexagon ACPI implementation
;;
;;*********************************************************************

;; Hexagon.Arch.ACPI.setupACPI fills every field below in at boot.
;; Hexagon.Arch.ACPI.shutdown only reads them back. When .available
;; stays 0, no RSDP, FADT or \_S5 package was found to shut down through

Hexagon.Arch.ACPI:

.available: db 0

.pm1aControlPort: dw 0
.pm1bControlPort: dw 0
.hasPM1b: db 0

.sleepTypeA: db 0
.sleepTypeB: db 0

;;************************************************************************************

;; Verifies an ACPI table's standard checksum: every byte across its length
;; must sum to zero, modulo 256
;;
;; Input:
;;
;; ESI - Physical address of the table (ES must already address flat memory)
;; ECX - Number of bytes to sum
;;
;; Output:
;;
;; CF - Clear if the checksum is valid, set otherwise
;;
;; Preserves EAX, ECX and ESI

Hexagon.Arch.ACPI.checksumOK:

    push eax
    push ecx
    push esi

    xor eax, eax

.sumLoop:

    add al, byte[es:esi]

    inc esi

    loop .sumLoop

    cmp al, 0

    pop esi
    pop ecx
    pop eax

    jne .bad

    clc

    ret

.bad:

    stc

    ret

;;************************************************************************************

;; Locates the Root System Description Pointer by scanning the two memory
;; ranges the ACPI specification reserves for it: the EBDA's first 1 KB,
;; then 0E0000h to 0FFFFFh
;;
;; Output:
;;
;; EBX - Physical address of the RSDP, if found
;; CF - Set if no RSDP could be located

Hexagon.Arch.ACPI.findRSDP:

    mov ax, 18h ;; A flat, zero-based segment, so physical and linear addresses match
    mov es, ax

    movzx ebx, word[es:40Eh] ;; EBDA segment, from the BIOS Data Area
    
    shl ebx, 4

    mov ecx, 40h ;; 1 KB of EBDA, in 16-byte steps

    call .scanRange

    jnc .found

    mov ebx, 0E0000h ;; Fall back to the BIOS read-only memory area
    mov ecx, 2000h   ;; 0E0000h to 0FFFFFh, in 16-byte steps

    call .scanRange

    jnc .found

    stc

    ret

.found:

    clc

    ret

;; Walks EBX forward in 16-byte steps, ECX times, until a checksum-valid
;; RSDP is found
;;
;; Output:
;;
;; EBX - Address of the RSDP
;; CF - Set if the range was exhausted without a match

.scanRange:

    cmp byte[es:ebx+0], "R"
    jne .next

    cmp byte[es:ebx+1], "S"
    jne .next
    
    cmp byte[es:ebx+2], "D"
    jne .next
    
    cmp byte[es:ebx+3], " "
    jne .next
    
    cmp byte[es:ebx+4], "P"
    jne .next
    
    cmp byte[es:ebx+5], "T"
    jne .next
    
    cmp byte[es:ebx+6], "R"
    jne .next
    
    cmp byte[es:ebx+7], " "
    jne .next

    push ecx

    mov esi, ebx
    mov ecx, 20 ;; The ACPI 1.0 RSDP checksum only covers its first 20 bytes

    call Hexagon.Arch.ACPI.checksumOK

    pop ecx

    jnc .matchFound

.next:

    add ebx, 16

    loop .scanRange

    stc

    ret

.matchFound:

    clc

    ret

;;************************************************************************************

;; Reads the RsdtAddress field of the RSDP EBX points to, then walks the
;; RSDT looking for the FADT ("FACP" signature)
;;
;; Input:
;;
;; EBX - Physical address of the RSDP
;;
;; Output:
;;
;; EBX - Physical address of the FADT
;; CF - Set if the RSDT is invalid or has no FADT entry

Hexagon.Arch.ACPI.findFADT:

    mov ebx, dword[es:ebx+16] ;; RsdtAddress, offset 16 into the RSDP

    cmp byte[es:ebx+0], "R"
    jne .notFound
    
    cmp byte[es:ebx+1], "S"
    jne .notFound
    
    cmp byte[es:ebx+2], "D"
    jne .notFound
    
    cmp byte[es:ebx+3], "T"
    jne .notFound

    push esi
    push ecx

    mov esi, ebx
    mov ecx, dword[es:ebx+4] ;; RSDT header length, also the checksum span

    call Hexagon.Arch.ACPI.checksumOK

    pop ecx
    pop esi

    jc .notFound

    mov ecx, dword[es:ebx+4]
    
    sub ecx, 36 ;; Past the fixed header, what remains is 4-byte pointers
    
    shr ecx, 2

    lea esi, [ebx+36]

.walkLoop:

    cmp ecx, 0
    je .notFound

    mov ebx, dword[es:esi]

    cmp byte[es:ebx+0], "F"
    jne .nextEntry
    
    cmp byte[es:ebx+1], "A"
    jne .nextEntry
    
    cmp byte[es:ebx+2], "C"
    jne .nextEntry
    
    cmp byte[es:ebx+3], "P"
    jne .nextEntry

    clc

    ret

.nextEntry:

    add esi, 4

    dec ecx

    jmp .walkLoop

.notFound:

    stc

    ret

;;************************************************************************************

;; Locates the FADT and the DSDT's \_S5 package at boot, then switches the
;; machine into ACPI mode if it is not in it already. Hexagon.Arch.ACPI.shutdown
;; depends entirely on what this leaves in the fields above

Hexagon.Arch.ACPI.setupACPI:

    call Hexagon.Arch.ACPI.findRSDP

    jc .noACPI

    call Hexagon.Arch.ACPI.findFADT ;; Reads the RSDP left in EBX, returns the FADT in EBX

    jc .noACPI

    push esi
    push ecx

    mov esi, ebx
    mov ecx, dword[es:ebx+4]

    call Hexagon.Arch.ACPI.checksumOK

    pop ecx
    pop esi

    jc .noACPI

    mov edx, dword[es:ebx+64] ;; PM1a_CNT_BLK
    mov word[Hexagon.Arch.ACPI.pm1aControlPort], dx

    mov edx, dword[es:ebx+68] ;; PM1b_CNT_BLK, 0 on machines that have none
    mov word[Hexagon.Arch.ACPI.pm1bControlPort], dx

    cmp edx, 0
    je .noPM1b

    mov byte[Hexagon.Arch.ACPI.hasPM1b], 1

.noPM1b:

    call .enableACPIMode ;; EBX still addresses the FADT for SMI_CMD/ACPI_ENABLE

    mov edx, dword[es:ebx+40] ;; DSDT physical address

    call .parseS5

    jc .noACPI

    mov byte[Hexagon.Arch.ACPI.available], 1

    ret

.noACPI:

match =YES, VERBOSE
{

    mov esi, Hexagon.Verbose.ACPI.unavailable
    mov ebx, Hexagon.Dmesg.Priorities.p5

    call Hexagon.Kern.Dmesg.createMessage

}

    ret

;; If the machine isn't in ACPI mode yet, requests the switch through
;; SMI_CMD and waits for SCI_EN in PM1a_CNT. Some firmware has no SMI
;; mechanism or is in ACPI mode already, and PM1_CNT still accepts the write
;;
;; Input:
;;
;; EBX - Physical address of the FADT

.enableACPIMode:

    mov dx, word[Hexagon.Arch.ACPI.pm1aControlPort]

    in ax, dx

    test ax, 1 ;; SCI_EN
    jnz .alreadyEnabled

    mov eax, dword[es:ebx+48] ;; SMI_CMD

    cmp eax, 0
    je .alreadyEnabled ;; No SMI mechanism to ask through

    mov dx, ax

    mov al, byte[es:ebx+52] ;; ACPI_ENABLE value

    out dx, al

    mov ecx, 0FFFFFh ;; Bounded wait, since waiting forever here isn't safe

.waitSCI:

    mov dx, word[Hexagon.Arch.ACPI.pm1aControlPort]

    in ax, dx

    test ax, 1
    jnz .alreadyEnabled

    loop .waitSCI

.alreadyEnabled:

    ret

;; Scans the DSDT pointed to by EDX for the \_S5 package and pulls out
;; SLP_TYPa/SLP_TYPb, the sleep-type values PM1_CNT needs for a real S5
;; transition. They live in AML bytecode, not a fixed table field
;;
;; Input:
;;
;; EDX - Physical address of the DSDT
;;
;; Output:
;;
;; CF - Set if the DSDT or its \_S5 package couldn't be parsed

.parseS5:

    mov ebx, edx

    cmp byte[es:ebx+0], "D"
    jne .s5Fail
    
    cmp byte[es:ebx+1], "S"
    jne .s5Fail
    
    cmp byte[es:ebx+2], "D"
    jne .s5Fail
    
    cmp byte[es:ebx+3], "T"
    jne .s5Fail

    push esi
    push ecx

    mov esi, ebx
    mov ecx, dword[es:ebx+4]

    call Hexagon.Arch.ACPI.checksumOK

    pop ecx
    pop esi

    jc .s5Fail

    mov ecx, dword[es:ebx+4]
    sub ecx, 36 ;; The AML bytecode following the 36-byte header

    lea esi, [ebx+36]

.findS5Loop:

    cmp ecx, 4
    jb .s5Fail ;; Not enough bytes left for another signature to fit

    cmp byte[es:esi+0], "_"
    jne .nextByte
    
    cmp byte[es:esi+1], "S"
    jne .nextByte
    
    cmp byte[es:esi+2], "5"
    jne .nextByte
    
    cmp byte[es:esi+3], "_"
    jne .nextByte

    jmp .s5Found

.nextByte:

    inc esi
    
    dec ecx

    jmp .findS5Loop

.s5Found:

;; Confirm this is really the \_S5 name declaration (NameOp, optionally
;; through the root path prefix) and not a stray byte sequence

    cmp byte[es:esi-1], 08h
    je .s5Confirmed

    cmp byte[es:esi-2], 08h
    jne .s5Fail
    
    cmp byte[es:esi-1], 5Ch ;; '\'
    jne .s5Fail

.s5Confirmed:

    cmp byte[es:esi+4], 12h ;; PackageOp must follow the name
    jne .s5Fail

    add esi, 5 ;; Past "_S5_" and the PackageOp byte

    movzx eax, byte[es:esi]

    shr eax, 6 ;; Top 2 bits of PkgLength's lead byte: how many bytes follow it

    add esi, eax
    add esi, 2 ;; PkgLength's own lead byte, then the NumElements byte

    cmp byte[es:esi], 0Ah ;; ByteConst prefix
    jne .readTypeA

    inc esi

.readTypeA:

    mov al, byte[es:esi]
    mov byte[Hexagon.Arch.ACPI.sleepTypeA], al

    inc esi

    cmp byte[es:esi], 0Ah
    jne .readTypeB

    inc esi

.readTypeB:

    mov al, byte[es:esi]
    mov byte[Hexagon.Arch.ACPI.sleepTypeB], al

    clc

    ret

.s5Fail:

    stc

    ret

;;************************************************************************************

;; Powers the machine off via ACPI's S5 sleep state, using the FADT/DSDT
;; values Hexagon.Arch.ACPI.setupACPI already found at boot. There is
;; no BIOS fallback left if that discovery failed

Hexagon.Arch.ACPI.shutdown:

match =YES, VERBOSE
{

    mov esi, Hexagon.Verbose.ACPI.shutdownACPI
    mov ebx, Hexagon.Dmesg.Priorities.p5

    call Hexagon.Kern.Dmesg.createMessage

}

    call Hexagon.Kernel.Dev.Disk.Disk.stopDisk ;; Every drive flushed before power actually goes away

    cmp byte[Hexagon.Arch.ACPI.available], 0
    je .noACPI

    movzx eax, byte[Hexagon.Arch.ACPI.sleepTypeA]

    shl eax, 10    
    or eax, 2000h ;; SLP_EN, bit 13 of PM1_CNT

    mov dx, word[Hexagon.Arch.ACPI.pm1aControlPort]

    out dx, ax

    cmp byte[Hexagon.Arch.ACPI.hasPM1b], 0
    je .end

    movzx eax, byte[Hexagon.Arch.ACPI.sleepTypeB]

    shl eax, 10
    or eax, 2000h

    mov dx, word[Hexagon.Arch.ACPI.pm1bControlPort]

    out dx, ax

.end:

    cli

    jmp $

.noACPI:

    mov esi, Hexagon.Verbose.ACPI.unavailable

    call Hexagon.Kern.Panic.panic
