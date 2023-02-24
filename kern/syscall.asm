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

Hexagon.Syscall.Controle:

.ultimaChamada:  dd 0
.chamadaAtual:   dd 0
.chamadaSistema: db 0 ;; Armazena se uma chamada foi ou não realizada
.eflags:         dd 0
.parametro:      dd 0
.eax:            dd 0
.cs:             dd 0
.es:             dw 0
.eip:            dd 0
.ebp:            dd 0
.totalChamadas:  dd 68

;;************************************************************************************

;; Manipulador de interrupção do Sistema Operacional Hexagonix®
;;
;; Saída:
;;
;;  EBP = 0xABC12345 em caso de função não disponível
;;  CF definido em caso de função não disponível
    
Hexagon.Syscall.Syscall.manipuladorHexagon:

    push ebp
    
    mov ebp, esp
    
    push 0x10                  ;; Segmento do Kernel
    pop ds

    mov [Hexagon.Syscall.Controle.es], es
    
    push 0x18
    pop es
    
    cld
    
    mov dword[Hexagon.Syscall.Controle.eax], eax
    
    add esi, dword[Hexagon.Processos.enderecoAplicativos]
    
    sub esi, 0x500
    
    add edi, dword[Hexagon.Processos.enderecoAplicativos]

    sub edi, 0x500

    pop eax                    ;; Limpar pilha
    
    mov dword[Hexagon.Syscall.Controle.ebp], eax
    
    pop eax
    
    mov dword[Hexagon.Syscall.Controle.eip], eax

    pop eax
    
    mov dword[Hexagon.Syscall.Controle.cs], eax

    pop eax                    ;; Bandeira
    
    pop eax                    ;; Chamada solicitada, armazenada na pilha
    
    mov dword[Hexagon.Syscall.Controle.parametro], eax ;; Chamada do sistema

    mov dword[Hexagon.Syscall.Controle.chamadaAtual], eax

    mov eax, dword[Hexagon.Syscall.Controle.eax]

    mov ebp, dword[ds:Hexagon.Syscall.Controle.parametro]
    
    cmp ebp, dword[Hexagon.Syscall.Controle.totalChamadas]
    ja .chamadaIndisponivel
    
    mov byte[Hexagon.Syscall.Controle.chamadaSistema], 01h ;; Uma chamada foi sim solicitada

    sti
    
    call dword[Hexagon.Syscall.Syscall.servicosHexagon.tabela+ebp*4]
    
.fim:

    sti

    mov byte[Hexagon.Syscall.Controle.chamadaSistema], 00h  ;; Desmarcar a solicitação de chamada de Sistema
    
    push eax

    mov eax, dword[Hexagon.Syscall.Controle.chamadaAtual]
    mov dword[Hexagon.Syscall.Controle.ultimaChamada], eax

    pop eax

    pushfd
    
    push dword[Hexagon.Syscall.Controle.cs]
    push dword[Hexagon.Syscall.Controle.eip]
    
    sub esi, dword[Hexagon.Processos.enderecoAplicativos]

    add esi, 0x500
    
    sub edi, dword[Hexagon.Processos.enderecoAplicativos]

    add edi, 0x500

    mov es, [Hexagon.Syscall.Controle.es]
    
    push 0x38
    pop ds

    iret
    
.chamadaIndisponivel:

    mov ebp, 0xABC12345
    
    stc
    
    jmp .fim
    


;;************************************************************************************

;; Manipulador de interrupção para funções Unix-like
;;
;; Saída:
;;
;;  EBP = 0xABC12345 em caso de função não disponível
;;  CF definido em caso de função não disponível
    
Hexagon.Syscall.Syscall.manipuladorHXUnix:

    push ebp
    
    mov ebp, esp
    
    push 0x10                  ;; Segmento do Kernel
    pop ds

    mov [Hexagon.Syscall.Controle.es], es
    
    push 0x18
    pop es
    
    cld
    
    mov dword[Hexagon.Syscall.Controle.eax], eax
    
    add esi, dword[Hexagon.Processos.enderecoAplicativos]
    
    sub esi, 0x500
    
    add edi, dword[Hexagon.Processos.enderecoAplicativos]

    sub edi, 0x500

    pop eax                    ;; Limpar pilha
    
    mov dword[Hexagon.Syscall.Controle.ebp], eax
    
    pop eax
    
    mov dword[Hexagon.Syscall.Controle.eip], eax

    pop eax
    
    mov dword[Hexagon.Syscall.Controle.cs], eax

    pop eax                    ;; Bandeira
    
    pop eax                    ;; Chamada solicitada, armazenada na pilha
    
    mov dword[Hexagon.Syscall.Controle.parametro], eax ;; Chamada do sistema

    mov dword[Hexagon.Syscall.Controle.chamadaAtual], eax

    mov eax, dword[Hexagon.Syscall.Controle.eax]

    mov ebp, dword[ds:Hexagon.Syscall.Controle.parametro]
    
    cmp ebp, dword[Hexagon.Syscall.Controle.totalChamadas]
    ja .chamadaIndisponivel
    
    mov byte[Hexagon.Syscall.Controle.chamadaSistema], 01h ;; Uma chamada foi sim solicitada

    sti
    
    call dword[Hexagon.Syscall.Syscall.servicosHexagon.tabelaUnix+ebp*4]
    
.fim:

    sti

    mov byte[Hexagon.Syscall.Controle.chamadaSistema], 00h  ;; Desmarcar a solicitação de chamada de Sistema
    
    push eax

    mov eax, dword[Hexagon.Syscall.Controle.chamadaAtual]
    mov dword[Hexagon.Syscall.Controle.ultimaChamada], eax

    pop eax

    pushfd
    
    push dword[Hexagon.Syscall.Controle.cs]
    push dword[Hexagon.Syscall.Controle.eip]
    
    sub esi, dword[Hexagon.Processos.enderecoAplicativos]

    add esi, 0x500
    
    sub edi, dword[Hexagon.Processos.enderecoAplicativos]

    add edi, 0x500

    mov es, [Hexagon.Syscall.Controle.es]
    
    push 0x38
    pop ds

    iret
    
.chamadaIndisponivel:

    mov ebp, 0xABC12345
    
    stc
    
    jmp .fim

;;************************************************************************************

Hexagon.Kernel.API.API.desenharBloco:

    sub esi, dword[Hexagon.Processos.enderecoAplicativos]
    add esi, 0x500
    
    sub edi, dword[Hexagon.Processos.enderecoAplicativos]
    add edi, 0x500

    call Hexagon.Kernel.Lib.Graficos.desenharBloco

    add esi, dword[Hexagon.Processos.enderecoAplicativos]
    sub esi, 0x500
    
    add edi, dword[Hexagon.Processos.enderecoAplicativos]
    sub edi, 0x500
    
    ret

;;************************************************************************************
    
Hexagon.Kernel.API.API.Nulo:    
    
    mov ebp, 0xABC12345
    
    stc
    
    ret 

;;************************************************************************************
   
Hexagon.Kernel.API.API.intalarInterrupcao:

    cli
    
    call instalarISR
    
    ret

;;************************************************************************************
    
Hexagon.Kernel.API.API.criarNovoProcesso:

    push dword[Hexagon.Syscall.Controle.eip]
    push dword[Hexagon.Syscall.Controle.cs]
    
    call Hexagon.Kernel.Kernel.Proc.criarProcesso
    
    pop dword[Hexagon.Syscall.Controle.cs]
    pop dword[Hexagon.Syscall.Controle.eip]
    
    ret

;;************************************************************************************
