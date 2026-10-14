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

;; Hexagon kernel entry point

;; Hexagon Boot Specifications
;;
;; HBoot (or a compatible manager) enters the kernel in 32-bit protected
;; mode, with the A20 line already enabled and EBX holding the physical
;; address of an HXBI block. Everything the kernel needs to know about the
;; machine it booted on is a tag inside that block
;;
;; The entry point is the first byte after the header below, so a loader
;; only needs the header's own fixed size to find it

use32

;; Hexagon is loaded at 500h and its descriptors are based at 0, so a label
;; here already carries the address the machine sees

org 500h

hexagonHeader:

.signature:     db "HAPP" ;; Image signature
.architecture:  db 01h    ;; Architecture (i386 = 01h)
.minVersion:    db 00h    ;; Minimum version of Hexagon (we don't care here)
.minSubversion: db 00h    ;; Minimal subversion of Hexagon (we don't care here)
.entryPoint:    dd Hexagon.Libkern.HAPP.denyExecution - 500h ;; Entry point offset, image relative
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

;; Reached directly from HBoot, already in 32-bit protected mode, with EBX
;; holding the physical address of an HXBI block. HBoot's own descriptors
;; got the CPU this far, so Hexagon's own GDT/IDT go in before anything
;; here touches a single one of its labels

Hexagon.initFromHXBI:

;; The stack HBoot hands over is its own real-mode one, now read through a
;; base-0 selector, so it points at the low physical addresses the kernel
;; image itself occupies. The boot stack goes in before the first call here

    mov esp, Hexagon.Arch.Memory.kernelReservedMemory - 1000h

    call Hexagon.Arch.CPU.CPU.installGDT

    mov ax, 10h
    mov ds, ax
    mov ax, 18h
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    call Hexagon.HXBI.parse

    jmp Hexagon.init

include "kern.asm" ;; Include the rest of the kernel, in a protected mode environment
