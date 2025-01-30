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

;; Hexagon kernel entry point

;; At this time, the operation environment is the real mode

;; Hexagon Boot Specifications
;;
;; Parameters that must be provided by HBoot (or compatible manager):
;;
;; Parameters must be provided in registers, in absolute value or
;; memory address for structure, such as device tree, or variables
;;
;; BL  - Boot drive code
;; CX  - Total memory recognized by HBoot (available)
;; AX  - 16-bit device tree address
;; EBP - Pointer to BPB (BIOS Parameter Block)
;; ESI - Command line for Hexagon
;; EDI - 32-bit device tree address

use16

hexagonHeader:

.signature:     db "HAPP" ;; Image signature
.architecture:  db 01h    ;; Architecture (i386 = 01h)
.minVersion:    db 00h    ;; Minimum version of Hexagon (we don't care here)
.minSubversion: db 00h    ;; Minimal subversion of Hexagon (we don't care here)
.entryPoint:    dd Hexagon.Libkern.HAPP.denyExecution ;; Entry point offset
.execType:      db 01h    ;; This is an executable image
.reserved0:     dd 0      ;; Reserved (Dword)
.reserved1:     db 0      ;; Reserved (Byte)
.reserved2:     db 0      ;; Reserved (Byte)
.reserved3:     db 0      ;; Reserved (Byte)
.reserved4:     dd 0      ;; Reserved (Dword)
.reserved5:     dd 0      ;; Reserved (Dword)
.reserved6:     dd 0      ;; Reserved (Dword)
.reserved7:     db 0      ;; Reserved (Byte)
.reserved8:     dw 0      ;; Reserved (Word)
.reserved9:     dw 0      ;; Reserved (Word)
.reserved10:    dw 0      ;; Reserved (Word)

;; First, the real-mode kernel segments will be defined

    mov ax, 50h
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

;; Set stack for this mode of operation

    cli

    mov ax, 5000h
    mov ss, ax
    mov sp, 0

;; Save important information from startup.
;; This data concerns the boot disk.
;; Future data can be saved in real mode for use in the protected mode environment.
;; Boot data is made available by HBoot, either as raw values ​​or as addresses to structures
;; with parameters that must be processed in the Hexagon protected mode environment

;; Will store the volume where the system was booted (cannot be changed)

    mov byte[Hexagon.Dev.Gen.Disk.Control.bootDisk], bl

;; Save the BPB (BIOS Parameter Block) address of the volume used for boot

    mov dword[Hexagon.Memory.addressBPB], ebp

;; Store available RAM memory size provided by HBoot

    mov word[Hexagon.Memory.memoryCMOS], cx

;; Now let's save the location of the parameter structure provided by HBoot

    mov dword[Hexagon.Boot.Parameters.commandLine], esi

;; Now let's tidy up the house to enter protected mode and go to the actual Hexagon
;; entry point, actually starting the kernel

;; Enable A20, necessary to address 4 GB of RAM and to enter protected mode

    call Hexagon.Arch.i386.CPU.CPU.enableA20Gate ;; Enable A20, required for protected mode

    call Hexagon.Arch.i386.Mm.Mm.getInstalledMemory ;; Gets the total installed memory

    call Hexagon.Arch.i386.CPU.CPU.goToProtectedMode32 ;; Configure 32-bit protected mode

;; Now the protected mode code will run (we are already on 32-bit!)

use32

    jmp Hexagon.init ;; Let's now go to the Hexagon entry point in protected mode

include "kern.asm" ;; Include the rest of the kernel, in a protected mode environment
