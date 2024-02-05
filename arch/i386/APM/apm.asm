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

;;*********************************************************************
;;
;;                   Implementação APM do Hexagon
;;
;;          Copyright (c) 2016-2024 Felipe Miguel Nery Lunkes
;;
;;*********************************************************************

;;************************************************************************************

Hexagon.Arch.i386.APM:

.status: db 0

;;************************************************************************************

;; Reiniciar o computador

Hexagon.Kernel.Arch.i386.APM.Energia.reiniciarPC:

match =YES, VERBOSE
{

    mov esi, Hexagon.Verbose.APM.servicoAPM
    mov ebx, Hexagon.Dmesg.Prioridades.p5

    call Hexagon.Kernel.Kernel.Dmesg.criarMensagemHexagon

    mov esi, Hexagon.Verbose.APM.reinicioAPM
    mov ebx, Hexagon.Dmesg.Prioridades.p5

    call Hexagon.Kernel.Kernel.Dmesg.criarMensagemHexagon

}

.aguardarLoop:

    in al, 64h ;; 64h é o registrador de estado

    bt ax, 1 ;; Checar segundo bit até se tornar 0
    jnc .OK

    jmp .aguardarLoop

.OK:

    mov al, 0xFE

    out 64h, al

    cli

    jmp $

    ret

;;************************************************************************************

Hexagon.Kernel.Arch.i386.APM.Energia.desligarPC:

match =YES, VERBOSE
{

    mov esi, Hexagon.Verbose.APM.servicoAPM
    mov ebx, Hexagon.Dmesg.Prioridades.p5

    call Hexagon.Kernel.Kernel.Dmesg.criarMensagemHexagon

    mov esi, Hexagon.Verbose.APM.desligamentoAPM
    mov ebx, Hexagon.Dmesg.Prioridades.p5

    call Hexagon.Kernel.Kernel.Dmesg.criarMensagemHexagon

}

    call Hexagon.Kernel.Dev.i386.Disco.Disco.pararDisco ;; Primeiro, vamos parar os discos

;;*********************************************************************
;;
;; Esta função pode retornar códigos de erro, os quais se seguem:
;;
;;
;; Retorno em AX - código de erro:
;;
;; 0 = Falha na instalação do Driver
;; 1 = Falha na conexão de interface de Modo Real
;; 2 = Driver APM versão 1.2 não suportado
;; 3 = Falha ao alterar o status para "off"
;;
;;*********************************************************************

    push bx
    push cx

    mov ax, 5300h ;; Função de checagem da instalação
    mov bx, 0 ;; O ID do dispositivo (APM BIOS)

    call Hexagon.Kernel.Arch.i386.BIOS.BIOS.int15h ;; Chamar interrupção APM

    jc .falhaAoInstalarAPM

    mov ax, 5301h ;; Função de interface de conexão em modo real
    mov bx, 0 ;; O ID do dispositivo (APM BIOS)

    call Hexagon.Kernel.Arch.i386.BIOS.BIOS.int15h ;; Chamar interrupção APM

    jc .falhaAoConectarAPM

    mov ax, 530Eh ;; Função de seleção de versão do Driver
    mov bx, 0     ;; O ID do dispositivo (APM BIOS)
    mov cx, 0102h ;; Selecionar APM versão 1.2
                  ;; A funcionalidade está presente após a versão 1.2
    call Hexagon.Kernel.Arch.i386.BIOS.BIOS.int15h ;; Chamar interrupção APM

    jc .falhaSelecionarVersaoAPM

    mov ax, 5307h ;; Função de definir estado
    mov cx, 0003h ;; Estado de desligar
    mov bx, 0001h ;; Todos os dispositivos tem ID 1

    call Hexagon.Kernel.Arch.i386.BIOS.BIOS.int15h ;; Chamar interrupção APM

;; Caso o sistema não desligue de forma apropriada, serão retornados códigos de erro ao
;; programa que chamou a função de desligamento.

.falhaComandoAPM: ;; Chamado caso o comando de desligamento (código 3) não seja executado

match =YES, VERBOSE
{

    mov esi, Hexagon.Verbose.APM.erroComandoAPM
    mov ebx, Hexagon.Dmesg.Prioridades.p5

    call Hexagon.Kernel.Kernel.Dmesg.criarMensagemHexagon

}

    mov ax, 3

    jmp .desligamentoFalhouAPM

.falhaAoInstalarAPM: ;; Chamado caso ocorra falha na instalação

match =YES, VERBOSE
{

    mov esi, Hexagon.Verbose.APM.erroInstalacaoAPM
    mov ebx, Hexagon.Dmesg.Prioridades.p5

    call Hexagon.Kernel.Kernel.Dmesg.criarMensagemHexagon

}

    mov ax, 0

    jmp .desligamentoFalhouAPM

.falhaAoConectarAPM: ;; Chamado caso ocorra falha na conexão de interface de Modo Real

match =YES, VERBOSE
{

    mov esi, Hexagon.Verbose.APM.erroConexaoAPM
    mov ebx, Hexagon.Dmesg.Prioridades.p5

    call Hexagon.Kernel.Kernel.Dmesg.criarMensagemHexagon

}

    mov ax, 1

    jmp .desligamentoFalhouAPM

.falhaSelecionarVersaoAPM: ;; Chamado quando a versão APM é inferior a 1.2

    mov ax, 2

.desligamentoFalhouAPM: ;; Retorna a função que a chamou

match =YES, VERBOSE
{

    mov esi, Hexagon.Verbose.APM.sucessoDesligamentoAPM
    mov ebx, Hexagon.Dmesg.Prioridades.p5

    call Hexagon.Kernel.Kernel.Dmesg.criarMensagemHexagon

}

    pop cx
    pop bx

    stc

    ret
