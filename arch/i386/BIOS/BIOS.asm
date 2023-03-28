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
;;                         Kernel Hexagon® - Hexagon® kernel         
;;
;;                  Copyright © 2015-2023 Felipe Miguel Nery Lunkes
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
;; Copyright (c) 2015-2023, Felipe Miguel Nery Lunkes
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
;;                    Este arquivo faz parte do Kernel Hexagon® 
;;
;;************************************************************************************

use32

;;************************************************************************************

Hexagon.Arch.i386.BIOS Hexagon.Arch.i386.Regs

;;************************************************************************************

Hexagon.Kernel.Arch.i386.BIOS.BIOS.int10h:

use32
    
    cli
    
    mov word[Hexagon.Arch.i386.BIOS.registradorAX], ax
    mov word[Hexagon.Arch.i386.BIOS.registradorBX], bx
    mov word[Hexagon.Arch.i386.BIOS.registradorCX], cx
    mov word[Hexagon.Arch.i386.BIOS.registradorDX], dx
    mov word[Hexagon.Arch.i386.BIOS.registradorDI], di
    mov word[Hexagon.Arch.i386.BIOS.registradorSI], si
    mov dword[Hexagon.Arch.i386.BIOS.registradorEBP], ebp
    mov dword[Hexagon.Arch.i386.BIOS.registradorESP], esp

    push eax
    push edx
    
    call Hexagon.Kernel.Arch.i386.CPU.CPU.irPara16 ;; Ir para o modo real para solicitar os serviços BIOS
    
use16

    mov ax, word[Hexagon.Arch.i386.BIOS.registradorAX]
    mov bx, word[Hexagon.Arch.i386.BIOS.registradorBX]
    mov cx, word[Hexagon.Arch.i386.BIOS.registradorCX]
    mov dx, word[Hexagon.Arch.i386.BIOS.registradorDX]
    mov si, word[Hexagon.Arch.i386.BIOS.registradorSI]
    mov di, word[Hexagon.Arch.i386.BIOS.registradorDI]
    
    int 10h
    
    call Hexagon.Kernel.Arch.i386.CPU.CPU.irPara32 ;; Voltar para o modo protegido, para a segurança!
    
use32

    mov ax, 0x10
    mov ds, ax
    mov ax, 0x18  ;; Definir a base de ES, SS e GS base para 0
    mov ss, ax
    mov es, ax  
    mov gs, ax
    mov esp, dword[Hexagon.Arch.i386.BIOS.registradorESP]
    
    sub esp, 4*2
    
    pop edx
    pop eax

    mov ebp, dword[Hexagon.Arch.i386.BIOS.registradorEBP]
    
    sti
    
    ret

;;************************************************************************************

Hexagon.Kernel.Arch.i386.BIOS.BIOS.int13h:

use32
    
    cli
    
    mov word[Hexagon.Arch.i386.BIOS.registradorAX], ax
    mov word[Hexagon.Arch.i386.BIOS.registradorBX], bx
    mov word[Hexagon.Arch.i386.BIOS.registradorCX], cx
    mov word[Hexagon.Arch.i386.BIOS.registradorDX], dx
    mov word[Hexagon.Arch.i386.BIOS.registradorDI], di
    mov word[Hexagon.Arch.i386.BIOS.registradorSI], si
    mov dword[Hexagon.Arch.i386.BIOS.registradorEBP], ebp
    mov dword[Hexagon.Arch.i386.BIOS.registradorESP], esp

    push eax
    push edx
    
    call Hexagon.Kernel.Arch.i386.CPU.CPU.irPara16
    
use16

    mov bx, word[Hexagon.Arch.i386.BIOS.registradorBX]
    mov cx, word[Hexagon.Arch.i386.BIOS.registradorCX]
    mov dx, word[Hexagon.Arch.i386.BIOS.registradorDX]
    mov si, word[Hexagon.Arch.i386.BIOS.registradorSI]
    mov di, word[Hexagon.Arch.i386.BIOS.registradorDI]
    mov ax, word[Hexagon.Arch.i386.BIOS.registradorAX]
    
    int 13h
    
    pushf
    
    pop ax
    
    mov word[Hexagon.Arch.i386.BIOS.registradorFlags], ax ;; Salvar flags (para checagem de erros)
    mov word[Hexagon.Arch.i386.BIOS.registradorAX], ax
    
    call Hexagon.Kernel.Arch.i386.CPU.CPU.irPara32
    
use32

    mov ax, 0x10
    mov ds, ax
    mov ax, 0x18                   ;; Definir base de ES, GS e SS para 0
    mov ss, ax
    mov gs, ax
    mov es, ax  
    mov esp, dword[Hexagon.Arch.i386.BIOS.registradorESP]
    
    sub esp, 4*2
    
    pop edx
    pop eax

    mov ebp, dword[Hexagon.Arch.i386.BIOS.registradorEBP]

    pushfd
    
    pop eax
    
    or ax, word[Hexagon.Arch.i386.BIOS.registradorFlags]
    
    push eax
    
    popfd
    
    mov ax, word[Hexagon.Arch.i386.BIOS.registradorAX]
    
    sti
    
    ret

;;************************************************************************************
    
Hexagon.Kernel.Arch.i386.BIOS.BIOS.int15h:

use32
    
    cli
    
    mov word[Hexagon.Arch.i386.BIOS.registradorAX], ax
    mov word[Hexagon.Arch.i386.BIOS.registradorBX], bx
    mov word[Hexagon.Arch.i386.BIOS.registradorCX], cx
    mov word[Hexagon.Arch.i386.BIOS.registradorDX], dx
    mov word[Hexagon.Arch.i386.BIOS.registradorDI], di
    mov word[Hexagon.Arch.i386.BIOS.registradorSI], si
    mov dword[Hexagon.Arch.i386.BIOS.registradorEBP], ebp
    mov dword[Hexagon.Arch.i386.BIOS.registradorESP], esp

    push eax
    push edx
    
    call Hexagon.Kernel.Arch.i386.CPU.CPU.irPara16
    
use16

    mov ax, word[Hexagon.Arch.i386.BIOS.registradorAX]
    mov bx, word[Hexagon.Arch.i386.BIOS.registradorBX]
    mov cx, word[Hexagon.Arch.i386.BIOS.registradorCX]
    mov dx, word[Hexagon.Arch.i386.BIOS.registradorDX]
    mov si, word[Hexagon.Arch.i386.BIOS.registradorSI]
    mov di, word[Hexagon.Arch.i386.BIOS.registradorDI]
    
    int 15h
    
    call Hexagon.Kernel.Arch.i386.CPU.CPU.irPara32
    
use32

    mov ax, 0x10
    mov ds, ax
    mov ax, 0x18            ;; Definir a base de ES, SS e GS base para 0
    mov ss, ax
    mov es, ax  
    mov gs, ax
    mov esp, dword[Hexagon.Arch.i386.BIOS.registradorESP]
    
    sub esp, 4*2
    
    pop edx
    pop eax

    mov ebp, dword[Hexagon.Arch.i386.BIOS.registradorEBP]
    
    sti
    
    ret

;;************************************************************************************

