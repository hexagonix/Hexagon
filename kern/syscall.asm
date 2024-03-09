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

Hexagon.Syscall.Control:

.lastSystemCall:    dd 0
.currentSystemCall: dd 0
.systemCall:        db 0 ;; Stores whether or not a call was made
.eflags:            dd 0
.parameter:         dd 0
.eax:               dd 0
.cs:                dd 0
.es:                dw 0
.eip:               dd 0
.ebp:               dd 0
.totalCalls:        dd 68

;;************************************************************************************

;; Hexagonix Interrupt Handler
;;
;; Output:
;;
;; EBP = 0xABC12345 in case of function not available
;; CF defined in case of function not available

Hexagon.Syscall.Syscall.hexagonHandler:

    push ebp

    mov ebp, esp

    push 10h ;; Kernel data segment
    pop ds

    mov [Hexagon.Syscall.Control.es], es

    push 18h ;; Kernel linear segment
    pop es

    cld

    mov dword[Hexagon.Syscall.Control.eax], eax

    add esi, dword[Hexagon.Processos.BCP.baseProcessos]

;; Correct address with segment base (physical address = address + segment base)

    sub esi, 500h

    add edi, dword[Hexagon.Processos.BCP.baseProcessos]

;; Correct address with segment base (physical address = address + segment base)

    sub edi, 500h

    pop eax ;; Clear stack

    mov dword[Hexagon.Syscall.Control.ebp], eax

    pop eax

    mov dword[Hexagon.Syscall.Control.eip], eax

    pop eax

    mov dword[Hexagon.Syscall.Control.cs], eax

    pop eax ;; Flags

    pop eax ;; Requested call, stored on stack

    mov dword[Hexagon.Syscall.Control.parameter], eax ;; System call

    mov dword[Hexagon.Syscall.Control.currentSystemCall], eax

    mov eax, dword[Hexagon.Syscall.Control.eax]

    mov ebp, dword[ds:Hexagon.Syscall.Control.parameter]

    cmp ebp, dword[Hexagon.Syscall.Control.totalCalls]
    ja .unavailableCall

    mov byte[Hexagon.Syscall.Control.systemCall], 01h ;; A call was requested

    sti

    call dword[Hexagon.Syscall.Syscall.servicosHexagon.tabela+ebp*4]

.end:

    sti

;; Clear system call request

    mov byte[Hexagon.Syscall.Control.systemCall], 00h

    push eax

    mov eax, dword[Hexagon.Syscall.Control.currentSystemCall]
    mov dword[Hexagon.Syscall.Control.lastSystemCall], eax

    pop eax

    pushfd

    push dword[Hexagon.Syscall.Control.cs]
    push dword[Hexagon.Syscall.Control.eip]

    sub esi, dword[Hexagon.Processos.BCP.baseProcessos]

;; Correct address with segment base (physical address = address + segment base)

    add esi, 500h

    sub edi, dword[Hexagon.Processos.BCP.baseProcessos]

;; Correct address with segment base (physical address = address + segment base)

    add edi, 500h

    mov es, [Hexagon.Syscall.Control.es]

    push 38h ;; User environment data segment (processes)
    pop ds

    iret

.unavailableCall:

    mov ebp, 0xABC12345

    stc

    jmp .end

;;************************************************************************************

Hexagon.Syscall.Syscall.nullSystemCall:

    mov ebp, 0xABC12345

    stc

    ret

;;************************************************************************************

Hexagon.Syscall.Syscall.installInterruption:

    cli

    call Hexagon.Int.installISR

    ret

;;************************************************************************************

Hexagon.Syscall.Syscall.createProcess:

;; Save instruction pointer and code segment

    push dword[Hexagon.Syscall.Control.eip]
    push dword[Hexagon.Syscall.Control.cs]

    call Hexagon.Kernel.Kernel.Proc.criarProcesso

;; Restore instruction pointer and code segment

    pop dword[Hexagon.Syscall.Control.cs]
    pop dword[Hexagon.Syscall.Control.eip]

    ret
