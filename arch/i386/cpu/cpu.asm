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
;;                 Copyright (c) 2015-2025 Felipe Miguel Nery Lunkes
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
;; Copyright (c) 2015-2025, Felipe Miguel Nery Lunkes
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

struc Hexagon.Arch.i386.Regs

{

.registerAX:    dw 0
.registerBX:    dw 0
.registerCX:    dw 0
.registerDX:    dw 0
.registerSI:    dw 0
.registerDI:    dw 0
.registerEBP:   dd 0
.registerESP:   dd 0
.registerFlags: dd 0

}

;;************************************************************************************

;; Switches the processor to 32-bit protected mode

Hexagon.Arch.i386.CPU.CPU.goToProtectedMode32:

use16

    cli

    pop bp ;; Return address

;; Load descriptors

    lgdt[GDTReg] ;; Load GDT

    lidt[IDTReg] ;; Load IDT

;; Now we will enter protected mode

    mov eax, cr0
    or eax, 1 ;; Switch to protected mode - bit 1
    mov cr0, eax

;; Return

    push 08h ;; Kernel code segment
    push bp  ;; Return address (first instruction in 32-bit mode)

    retf ;; Go to 32-bit code

;;************************************************************************************

use32

;; Switches the processor back to real mode

Hexagon.Arch.i386.CPU.CPU.goToRealMode:

    cli ;; Clear interrupts

    pop edx ;; Save return location in EDX

    jmp 20h:Hexagon.Arch.i386.CPU.CPU.protectedMode16 ;; Load CS with 20h selector

;; To go to 16-bit real mode, we have to go through 16-bit protected mode

use16

Hexagon.Arch.i386.CPU.CPU.protectedMode16:

    mov ax, 28h ;; 28h is the 16-bit protected mode data selector
    mov ss, ax
    mov sp, 5000h ;; Stack

    mov eax, cr0
    and eax, 0xFFFFFFFE ;; Clear protected mode enable bit in cr0
    mov cr0, eax ;; Disable 32-bit mode

    jmp 50h:Hexagon.Arch.i386.CPU.CPU.realMode ;; Load CS and IP pair (segment:instruction)

Hexagon.Arch.i386.CPU.CPU.realMode:

;; Load segment registers with 16-bit values

    mov ax, 50h ;; Real mode thread to use (thread used by the kernel)
    mov ds, ax
    mov ax, 6000h ;; Stack
    mov ss, ax
    mov ax, 0
    mov es, ax
    mov sp, 0

    cli

    lidt[.idtR] ;; Load real mode interrupt vector table

    sti

    push 50h ;; Code segment to be used
    push dx  ;; Return to the location present in EDX (first instruction in real mode)

    retf ;; Start real mode (go to 16-bit real mode code)

;; Real mode interrupt vector table (the 0-based mode limit)

.idtR:  dw 0xFFFF ;; Limit (operation mode limit)
        dd 0      ;; Base (zero base, no offset)

;;************************************************************************************

Hexagon.Arch.i386.CPU.CPU.enableA20Gate:

match =A20_NOT_SAFE, A20
{

;; Here we have a method to check if the A20 is enabled

.testA20:

    mov edi, 112345h ;; Even address
    mov esi, 012345h ;; Odd address
    mov [esi], esi   ;; The two addresses have different values
    mov [edi], edi

;; If A20 not activated, the two hands will point to 012345h, which contain 112345h (EDI)

    cmpsd ;; Compare to see if they are equivalent

    jne .done ;; If not, the A20 is already enabled

}

;; Here we have the safest method of activating the A20 line

.enableA20:

    mov ax, 2401h ;; Request A20 activation

    int 15h ;; BIOS Interrupt

.done:

    ret

;;************************************************************************************

use32

Hexagon.Arch.i386.CPU.CPU.setupProcessor:

;; Enable SSE

    mov eax, cr0
    or eax, 10b ;; Coprocessor monitor
    and ax, 1111111111111011b ;; Disable coprocessor emulation
    mov cr0, eax

    mov eax, cr4

;; Floating Point Exceptions

    or ax, 001000000000b
    or ax, 010000000000b
    mov cr4, eax

;; Now let's start the floating point unit

    finit
    fwait

    ret

;;************************************************************************************

;; This function obtains information from the installed processor and saves it in
;; a buffer that will be used at various points by kernel functions or copied to the
;;  user environment, to be used by processes

Hexagon.Arch.i386.CPU.CPU.identifyProcessor:

    mov esi, Hexagon.Dev.deviceCodes.proc0

    mov edi, 80000002h

    mov ecx, 3

.identifyLoop:

    push ecx

    mov eax, edi

    cpuid

    mov [esi], eax
    mov [esi+4], ebx
    mov [esi+8], ecx
    mov [esi+12], edx

    add esi, 16

    inc edi

    pop ecx

    loop .identifyLoop

    mov eax, 0
    mov [esi+1], eax

    ret

;;************************************************************************************

;;************************************************************************************
;;
;;                         GDT (Global Descriptor Table)
;;
;;************************************************************************************

;; The alignment here should be 32

align 32

;; Each GDT entry is 8 bytes, with the limit, the selector base (where the selector starts
;; in physical memory), the access bytes and the flags

GDT:

    dd 0, 0 ;; Null descriptor - Selector 00h

;; Physical address = address + base of the respective selector

.kernelCode: ;; Selector 08h

    dw 0xFFFF    ;; Limit (0:15)
    dw 500h      ;; Base (0:15)
    db 0         ;; Base (16:23)
    db 10011010b ;; Present=1, Privilege=00, Reserved=1, Executable=1, C=0, L&E=1, Accessed=0
    db 11001111b ;; Granularity=1, Size=1, Reserved=00, Limit (16:19)
    db 0         ;; Base (24:31)

;; 500h-based data descriptor

.kernelData: ;; Selector 10h

    dw 0xFFFF    ;; Limit (0:15)
    dw 500h      ;; Base (0:15)
    db 0         ;; Base (16:23)
    db 10010010b ;; Present=1, Privilege=00, Reserved=1, Executable=0, D=0, W=1, Accessed=0
    db 11001111b ;; Granularity=1, Size=1, Reserved=00, Limit (16:19)
    db 0         ;; Base (24:31)

;; 0h-based data descriptor

.kernelLinear: ;; Selector 18h

    dw 0xFFFF    ;; Limit (0:15)
    dw 0         ;; Base (0:15)
    db 0         ;; Base (16:23)
    db 10010010b ;; Present=1, Privilege=00, Reserved=1, Executable=0, D=0, W=1, Accessed=0
    db 11001111b ;; Granularity=1, Size=1, Reserved=00, Limit (16:19)
    db 0         ;; Base (24:31)

;; Code descriptor for 16-bit protected mode

.pm16Code: ;; Selector 20h

    dw 0xFFFF    ;; Limit (0:15)
    dw 0500h     ;; Base (0:15)
    db 0         ;; Base (16:23)
    db 10011010b ;; Present=1, Privilege=00, Reserved=1, Executable=1, C=0, L&E=1, Accessed=0
    db 0         ;; Granularity=1, Size=1, Reserved=00, Limit (16:19)
    db 0         ;; Base (24:31)

;; Data descriptor for 16-bit protected mode

.pm16Data: ;; Selector 28h

    dw 0xFFFF    ;; Limit (0:15)
    dw 0         ;; Base (0:15)
    db 0         ;; Base (16:23)
    db 10010010b ;; Present=1, Privilege=00, Reserved=1, Executable=0, D=0, W=1, Accessed=0
    db 0         ;; Granularity=1, Size=1, Reserved=00, Limit (16:19)
    db 0         ;; Base (24:31)

;; User code

.userCode: ;; Selector 30h -> Selector used for the user process code area

    dw 0xFFFF    ;; Limit (0:15)
    dw 0         ;; Base (0:15)
    db 0         ;; Base (16:23)
    db 10011010b ;; Present=1, Privilege=00, Reserved=1, Executable=1, C=0, L&E=1, Accessed=0
    db 11001111b ;; Granularity=1, Size=1, Reserved=00, Limit (16:19)
    db 0         ;; Base (24:31)

;; User data

.userData: ;; Selector 38h -> Selector for the process data area

    dw 0xFFFF    ;; Limit (0:15)
    dw 0         ;; Base (0:15)
    db 0         ;; Base (16:23)
    db 10010010b ;; Present=1, Privilege=00, Reserved=1, Executable=0, D=0, W=1, Accessed=0
    db 11001111b ;; Granularity=1, Size=1, Reserved=00, Limit (16:19)
    db 0         ;; Base (24:31)

;; TSS (Task State Segment)

.TSS:

    dw 104       ;; Inferior limit
    dw TSS       ;; Base
    db 0         ;; Base
    db 11101001b ;; Access
    db 0         ;; Flags and upper limit
    db 0         ;; Base

endGDT:

GDTReg:

.size:
dw endGDT - GDT - 1 ;; GDT size - 1
.location:
dd GDT + 500h ;; GDT offset

;;************************************************************************************

;;************************************************************************************
;;
;;                          IDT (Interrupt Descriptor Table)
;;
;;************************************************************************************

;; Firstly, all interrupts will be redirected to nullHandler during system startup.
;; Afterwards, system interrupts will be installed, overriding nullHandler.

align 32

IDT: times 256 dw Hexagon.Kern.Services.nullHandler, 0x0008, 0x8e00, 0

;; nullHandler: offset (0:15)
;; 0x0008:  0x08 is a selector
;; 0x8e00:  8 is Present=1, Privilege=00, Size=1, and it's interrupt 386, 00 is reserved
;; 0:       Offset (16:31)

endIDT:

IDTReg:

.size:
dw endIDT - IDT - 1 ;; IDT size - 1
.location:
dd IDT + 500h ;; IDT offset

;;************************************************************************************

;;************************************************************************************
;;
;;                              TSS (Task State Segment)
;;
;;************************************************************************************

align 32

TSS:

    .tssAnterior dd 0
    .esp0        dd 10000h ;; Kernel stack
    .ss0         dd 10h    ;; Kernel stack segment
    .esp1        dd 0
    .ss1         dd 0
    .esp2        dd 0
    .ss2         dd 0
    .cr3         dd 0
    .eip         dd 0
    .eflags      dd 0
    .eax         dd 0
    .ecx         dd 0
    .edx         dd 0
    .ebx         dd 0
    .esp         dd 0
    .ebp         dd 0
    .esi         dd 0
    .edi         dd 0
    .es          dd 10h ;; Kernel data segment
    .cs          dd 08h
    .ss          dd 10h
    .ds          dd 10h
    .fs          dd 10h
    .gs          dd 10h
    .ldt         dd 0
    .ldtr        dw 0
    .mapaIO      dw 104
