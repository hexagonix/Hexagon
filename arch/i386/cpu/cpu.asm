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
;;                 Copyright (c) 2015-2023 Felipe Miguel Nery Lunkes
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
;;                     Este arquivo faz parte do kernel Hexagon
;;
;;************************************************************************************

struc Hexagon.Arch.i386.Regs

{

.registradorAX:    dw 0
.registradorBX:    dw 0
.registradorCX:    dw 0
.registradorDX:    dw 0
.registradorSI:    dw 0
.registradorDI:    dw 0
.registradorEBP:   dd 0
.registradorESP:   dd 0
.registradorFlags: dd 0

}

;;************************************************************************************

;; Comuta o processador para o modo protegido 32 bits

Hexagon.Kernel.Arch.i386.CPU.CPU.irPara32:

use16

    cli

    pop bp ;; Endereço de retorno

;; Carregar descriptores

    lgdt[GDTReg] ;; Carregar GDT

    lidt[IDTReg] ;; Carregar IDT

;; Agora iremos entrar em modo protegido

    mov eax, cr0
    or eax, 1 ;; Comutar para modo protegido - bit 1
    mov cr0, eax

;; Retornar

    push 0x08 ;; Novo CS
    push bp ;; Novo IP

    retf

;;************************************************************************************

use32

;; Comuta o processador de volta ao modo real

Hexagon.Kernel.Arch.i386.CPU.CPU.irPara16:

    cli ;; Limpar interrupções

    pop edx ;; Salvar local de retorno em EDX

    jmp 0x20:Hexagon.Kernel.Arch.i386.CPU.CPU.modoProtegido16 ;; Carregar CS com seletor 0x20

;; Para ir ao modo real 16 bits, temos de passar pelo modo protegido 16 bits

use16

Hexagon.Kernel.Arch.i386.CPU.CPU.modoProtegido16:

    mov ax, 0x28 ;; 0x28 é o seletor de modo protegido 16-bit
    mov ss, ax
    mov sp, 0x5000 ;; Pilha

    mov eax, cr0
    and eax, 0xfffffffe ;; Limpar bit de ativação do modo protegido em cr0
    mov cr0, eax ;; Desativar modo 32 bits

    jmp 0x50:Hexagon.Kernel.Arch.i386.CPU.CPU.modoReal ;; Carregar CS e IP

Hexagon.Kernel.Arch.i386.CPU.CPU.modoReal:

;; Carregar registradores de segmento com valores de 16 bits

    mov ax, 0x50
    mov ds, ax
    mov ax, 0x6000
    mov ss, ax
    mov ax, 0
    mov es, ax
    mov sp, 0

    cli

    lidt[.idtR] ;; Carregar tabela de vetores de interrupção de modo real

    sti

    push 0x50
    push dx ;; Retornar para a localização presente em EDX

    retf ;; Iniciar modo real

;; Tabela de vetores de interrupção de modo real

.idtR:  dw 0xffff ;; Limite
        dd 0      ;; Base

;;************************************************************************************

Hexagon.Kernel.Arch.i386.CPU.CPU.ativarA20:

match =A20NAOSEGURO, A20
{

;; Aqui temos um método para checar se o A20 está habilitado. Entretanto, o código
;; parece gerar erros dependendo da plataforma (máquina física, KVM, etc)

 .testarA20:

    mov edi, 0x112345 ;; Endereço par
    mov esi, 0x012345 ;; Endereço ímpar
    mov [esi], esi    ;; Os dois endereços apresentam valores diferentes
    mov [edi], edi

;; Se A20 não definido, os dois ponteiros apontarão para 0x012345, que contêm 0x112345 (EDI)

    cmpsd ;; Comparar para ver se são equivalentes

    jne .A20Pronto ;; Se não, o A20 já está habilitado

}

;; Aqui temos o método mais seguro de ativar a linha A20

.habilitarA20:

    mov ax, 0x2401 ;; Solicitar a ativação do A20

    int 15h ;; Interrupção do BIOS

.A20Pronto:

    ret

;;************************************************************************************

use32

Hexagon.Kernel.Arch.i386.CPU.CPU.configurarProcessador:

;; Habilitar SSE

    mov eax, cr0
    or eax, 10b ;; Monitor do coprocessador
    and ax, 1111111111111011b ;; Desativar emulação do coprocessador
    mov cr0, eax

    mov eax, cr4

;; Exceções de ponto flutuante

    or ax, 001000000000b
    or ax, 010000000000b
    mov cr4, eax

;; Agora vamos iniciar a unidade de ponto flutuante

    finit
    fwait

    ret

;;************************************************************************************

Hexagon.Kernel.Arch.i386.CPU.CPU.identificarProcessador:

    mov esi, codigoDispositivos.proc0

    mov edi, 0x80000002

    mov ecx, 3

.loopIdentificar:

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

    loop .loopIdentificar

    mov eax, 0
    mov [esi+1], eax

    ret

;;************************************************************************************

use32

;;************************************************************************************
;;
;;            GDT (Tabela de Descriptores Global - Global Descriptor Table)
;;
;;************************************************************************************

;; O alinhamento aqui deve ser de 32

align 32

GDT:

    dd 0, 0 ;; Descriptor nulo

.codigoKernel:

    dw 0xFFFF    ;; Limite (0:15)
    dw 0x0500    ;; Base (0:15)
    db 0         ;; Base (16:23)
    db 10011010b ;; Presente=1, Privilégio=00, Reservado=1, Executável=1, C=0, L&E=1, Acessado=0
    db 11001111b ;; Granularidade=1, Tamanho=1, Reservado=00, Limite (16:19)
    db 0         ;; Base (24:31)

;; Descriptor de dados com base em 500h

.dadosKernel:

    dw 0xFFFF    ;; Limite (0:15)
    dw 0x0500    ;; Base (0:15)
    db 0         ;; Base (16:23)
    db 10010010b ;; Presente=1, Privilégio=00, Reservado=1, Executável=0, D=0, W=1, Acessado=0
    db 11001111b ;; Granularidade=1, Tamanho=1, Reservado=00, Limite (16:19)
    db 0         ;; Base (24:31)

;; Descriptor de dados com base em 0h

.linearKernel:

    dw 0xFFFF    ;; Limite (0:15)
    dw 0         ;; Base (0:15)
    db 0         ;; Base (16:23)
    db 10010010b ;; Presente=1, Privilégio=00, Reservado=1, Executável=0, D=0, W=1, Acessado=0
    db 11001111b ;; Granularidade=1, Tamanho=1, Reservado=00, Limite (16:19)
    db 0         ;; Base (24:31)

;; Descriptor de código para modo protegido 16 bits

.codigoMP16:

    dw 0xFFFF    ;; Limite (0:15)
    dw 0x0500    ;; Base (0:15)
    db 0         ;; Base (16:23)
    db 10011010b ;; Presente=1, Privilégio=00, Reservado=1, Executável=1, C=0, L&E=1, Acessado=0
    db 0         ;; Granularidade=1, Tamanho=1, Reservado=00, Limite (16:19)
    db 0         ;; Base (24:31)

;; Descriptor de dados para modo protegido 16 bits

.dadosPM16:

    dw 0xFFFF    ;; Limite (0:15)
    dw 0         ;; Base (0:15)
    db 0         ;; Base (16:23)
    db 10010010b ;; Presente=1, Privilégio=00, Reservado=1, Executável=0, D=0, W=1, Acessado=0
    db 0         ;; Granularidade=1, Tamanho=1, Reservado=00, Limite (16:19)
    db 0         ;; Base (24:31)

;; Código do programa

.codigoPrograma:

    dw 0xFFFF    ;; Limite (0:15)
    dw 0         ;; Base (0:15)
    db 0         ;; Base (16:23)
    db 10011010b ;; Presente=1, Privilégio=00, Reservado=1, Executável=1, C=0, L&E=1, Acessado=0
    db 11001111b ;; Granularidade=1, Tamanho=1, Reservado=00, Limite (16:19)
    db 0         ;; Base (24:31)

;; Dados do programa

.dadosPrograma:

    dw 0xFFFF    ;; Limite (0:15)
    dw 0         ;; Base (0:15)
    db 0         ;; Base (16:23)
    db 10010010b ;; Presente=1, Privilégio=00, Reservado=1, Executável=0, D=0, W=1, Acessado=0
    db 11001111b ;; Granularidade=1, Tamanho=1, Reservado=00, Limite (16:19)
    db 0         ;; Base (24:31)

;; TSS (Task State Segment)

.TSS:

    dw 104       ;; Limite inferior
    dw TSS       ;; Base
    db 0         ;; Base
    db 11101001b ;; Acesso
    db 0         ;; Bandeiras e limite superior
    db 0         ;; Base

terminoGDT:

GDTReg:

.tamanho: dw terminoGDT - GDT - 1 ;; Tamanho GDT - 1
.local:   dd GDT+0x500 ;; Deslocamento da GDT

;;************************************************************************************

;;************************************************************************************
;;
;;     IDT (Tabela de Descriptores de Interrupção - Interrupt Descriptor Table)
;;
;;************************************************************************************

;; Primeiramente todas as interrupções serão redirecionadas para naoManipulado durante a inicialização
;; do Sistema. Após, as interrupções do Sistema serão instaladas, sobrescrevendo naoManipulado.

align 32

IDT: times 256 dw naoManipulado, 0x0008, 0x8e00, 0

;; naoManipulado: deslocamento (0:15)
;; 0x0008:  0x08 é um seletor
;; 0x8e00:  8 é Presente=1, Privilégio=00, Tamanho=1, e é interrupção 386, 00 é reservado
;; 0:       Offset (16:31)

terminoIDT:

IDTReg:

.tamanho: dw terminoIDT - IDT - 1 ;; Tamanho IDT - 1
.local:   dd IDT+0x500 ;; Deslocamento da IDT

;;************************************************************************************

;;************************************************************************************
;;
;;     TSS (Segmento de Estado da Tarefa - Task State Segment)
;;
;;************************************************************************************

align 32

TSS:

    .tssAnterior dd 0
    .esp0        dd 0x10000 ;; Pilha do Kernel
    .ss0         dd 0x10    ;; Segmento da pilha do Kernel
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
    .es          dd 0x10 ;; Segmento de dados do Kernel
    .cs          dd 0x08
    .ss          dd 0x10
    .ds          dd 0x10
    .fs          dd 0x10
    .gs          dd 0x10
    .ldt         dd 0
    .ldtr        dw 0
    .mapaIO      dw 104
