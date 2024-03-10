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

Hexagon.Arch.i386.BIOS Hexagon.Arch.i386.Regs

;;************************************************************************************

Hexagon.Arch.i386.BIOS.BIOS.int10h:

use32

    cli

    mov word[Hexagon.Arch.i386.BIOS.registerAX], ax
    mov word[Hexagon.Arch.i386.BIOS.registerBX], bx
    mov word[Hexagon.Arch.i386.BIOS.registerCX], cx
    mov word[Hexagon.Arch.i386.BIOS.registerDX], dx
    mov word[Hexagon.Arch.i386.BIOS.registerDI], di
    mov word[Hexagon.Arch.i386.BIOS.registerSI], si
    mov dword[Hexagon.Arch.i386.BIOS.registerEBP], ebp
    mov dword[Hexagon.Arch.i386.BIOS.registerESP], esp

    push eax
    push edx

    call Hexagon.Arch.i386.CPU.CPU.goToRealMode ;; Go to real mode to request BIOS services

use16

    mov ax, word[Hexagon.Arch.i386.BIOS.registerAX]
    mov bx, word[Hexagon.Arch.i386.BIOS.registerBX]
    mov cx, word[Hexagon.Arch.i386.BIOS.registerCX]
    mov dx, word[Hexagon.Arch.i386.BIOS.registerDX]
    mov si, word[Hexagon.Arch.i386.BIOS.registerSI]
    mov di, word[Hexagon.Arch.i386.BIOS.registerDI]

    int 10h

    call Hexagon.Arch.i386.CPU.CPU.goToProtectedMode32 ;; Return to protected mode, to safety!

use32

    mov ax, 10h ;; Kernel data segment
    mov ds, ax
    mov ax, 18h ;; Set ES, SS and GS segment base to 0 - kernel linear segment
    mov ss, ax
    mov es, ax
    mov gs, ax
    mov esp, dword[Hexagon.Arch.i386.BIOS.registerESP]

    sub esp, 4*2

    pop edx
    pop eax

    mov ebp, dword[Hexagon.Arch.i386.BIOS.registerEBP]

    sti

    ret

;;************************************************************************************

Hexagon.Arch.i386.BIOS.BIOS.int13h:

use32

    cli

    mov word[Hexagon.Arch.i386.BIOS.registerAX], ax
    mov word[Hexagon.Arch.i386.BIOS.registerBX], bx
    mov word[Hexagon.Arch.i386.BIOS.registerCX], cx
    mov word[Hexagon.Arch.i386.BIOS.registerDX], dx
    mov word[Hexagon.Arch.i386.BIOS.registerDI], di
    mov word[Hexagon.Arch.i386.BIOS.registerSI], si
    mov dword[Hexagon.Arch.i386.BIOS.registerEBP], ebp
    mov dword[Hexagon.Arch.i386.BIOS.registerESP], esp

    push eax
    push edx

    call Hexagon.Arch.i386.CPU.CPU.goToRealMode

use16

    mov bx, word[Hexagon.Arch.i386.BIOS.registerBX]
    mov cx, word[Hexagon.Arch.i386.BIOS.registerCX]
    mov dx, word[Hexagon.Arch.i386.BIOS.registerDX]
    mov si, word[Hexagon.Arch.i386.BIOS.registerSI]
    mov di, word[Hexagon.Arch.i386.BIOS.registerDI]
    mov ax, word[Hexagon.Arch.i386.BIOS.registerAX]

    int 13h

    pushf

    pop ax

    mov word[Hexagon.Arch.i386.BIOS.registerFlags], ax ;; Save flags (for error checking)
    mov word[Hexagon.Arch.i386.BIOS.registerAX], ax

    call Hexagon.Arch.i386.CPU.CPU.goToProtectedMode32

use32

    mov ax, 10h ;; Kernel data segment
    mov ds, ax
    mov ax, 18h ;; Set ES, SS and GS segment base to 0 - kernel linear segment
    mov ss, ax
    mov gs, ax
    mov es, ax
    mov esp, dword[Hexagon.Arch.i386.BIOS.registerESP]

    sub esp, 4*2

    pop edx
    pop eax

    mov ebp, dword[Hexagon.Arch.i386.BIOS.registerEBP]

    pushfd

    pop eax

    or ax, word[Hexagon.Arch.i386.BIOS.registerFlags]

    push eax

    popfd

    mov ax, word[Hexagon.Arch.i386.BIOS.registerAX]

    sti

    ret

;;************************************************************************************

Hexagon.Arch.i386.BIOS.BIOS.int15h:

use32

    cli

    mov word[Hexagon.Arch.i386.BIOS.registerAX], ax
    mov word[Hexagon.Arch.i386.BIOS.registerBX], bx
    mov word[Hexagon.Arch.i386.BIOS.registerCX], cx
    mov word[Hexagon.Arch.i386.BIOS.registerDX], dx
    mov word[Hexagon.Arch.i386.BIOS.registerDI], di
    mov word[Hexagon.Arch.i386.BIOS.registerSI], si
    mov dword[Hexagon.Arch.i386.BIOS.registerEBP], ebp
    mov dword[Hexagon.Arch.i386.BIOS.registerESP], esp

    push eax
    push edx

    call Hexagon.Arch.i386.CPU.CPU.goToRealMode

use16

    mov ax, word[Hexagon.Arch.i386.BIOS.registerAX]
    mov bx, word[Hexagon.Arch.i386.BIOS.registerBX]
    mov cx, word[Hexagon.Arch.i386.BIOS.registerCX]
    mov dx, word[Hexagon.Arch.i386.BIOS.registerDX]
    mov si, word[Hexagon.Arch.i386.BIOS.registerSI]
    mov di, word[Hexagon.Arch.i386.BIOS.registerDI]

    int 15h

    call Hexagon.Arch.i386.CPU.CPU.goToProtectedMode32

use32

    mov ax, 10h ;; Kernel data segment
    mov ds, ax
    mov ax, 18h ;; Set ES, SS and GS segment base to 0 - kernel linear segment
    mov ss, ax
    mov es, ax
    mov gs, ax
    mov esp, dword[Hexagon.Arch.i386.BIOS.registerESP]

    sub esp, 4*2

    pop edx
    pop eax

    mov ebp, dword[Hexagon.Arch.i386.BIOS.registerEBP]

    sti

    ret
