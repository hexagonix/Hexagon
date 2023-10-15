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

;; Ponto de entrada do Kernel Hexagon

;; Neste momento, o ambiente de operação é o modo real

;; Especificações de inicialização do Hexagon
;;
;; Parâmetros que devem ser fornecidos pelo HBoot (ou gerenciador compatível):
;;
;; Os parâmetros devem ser fornecidos nos registradores, em valor absoluto ou endereço
;; de memória para estrutura, como árvore de dispositivos, ou variáveis
;;
;; BL  - Código da unidade de unicialização
;; CX  - Memória total reconhecida pelo HBoot
;; AX  - Endereço da árvore de dispositivos de 16 bits
;; EBP - Ponteiro para o BPB (BIOS Parameter Block)
;; ESI - Linha de comando para o Hexagon
;; EDI - Endereço da árvore de dispositivos de 32 bits

use16

cabecalhoHexagon:

.assinatura:      db "HAPP" ;; Assinatura
.arquitetura:     db 01h    ;; Arquitetura (i386 = 01h)
.versaoMinima:    db 00h    ;; Versão mínima do Hexagon (não nos interessa aqui)
.subversaoMinima: db 00h    ;; Subversão mínima do Hexagon (não nos interessa aqui)
.pontoEntrada:    dd Hexagon.Kernel.Lib.HAPP.execucaoIndevida ;; Offset do ponto de entrada
.tipoExecutavel:  db 01h    ;; Esta é uma imagem executável
.reservado0:      dd 0      ;; Reservado (Dword)
.reservado1:      db 0      ;; Reservado (Byte)
.reservado2:      db 0      ;; Reservado (Byte)
.reservado3:      db 0      ;; Reservado (Byte)
.reservado4:      dd 0      ;; Reservado (Dword)
.reservado5:      dd 0      ;; Reservado (Dword)
.reservado6:      dd 0      ;; Reservado (Dword)
.reservado7:      db 0      ;; Reservado (Byte)
.reservado8:      dw 0      ;; Reservado (Word)
.reservado9:      dw 0      ;; Reservado (Word)
.reservado10:     dw 0      ;; Reservado (Word)

;; Primeiramente, os segmentos do Kernel em modo real serão definidos

    mov ax, 50h
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

;; Definir pilha para este modo de operação

    cli

    mov ax, 0x5000
    mov ss, ax
    mov sp, 0

;; Salvar informações importantes provenientes da inicialização. Estes dados dizem respeito
;; ao disco utilizado na inicialização. Futuros dados poderão ser salvos do modo real para
;; uso no ambiente protegido. Os dados de inicialização são disponibilizados pelo HBoot, como
;; valores brutos ou como endereços para estruturas com parâmetros que devem ser processados
;; no ambiente protegido do Hexagon

;; Irá armazenar o volume onde o sistema foi iniciado (não pode ser alterado)

    mov byte[Hexagon.Dev.Gen.Disco.Controle.driveBoot], bl

;; Salvar o endereço do BPB (BIOS Parameter Block) do volume utilizado para a inicialização

    mov dword[Hexagon.Memoria.enderecoBPB], ebp

;; Armazenar o tamanho da memória RAM disponível, fornecido pelo Carregador de Inicialização do Hexagon

    mov word[Hexagon.Memoria.memoriaCMOS], cx

;; Agora vamos salvar a localização da estrutura de parâmetros fornecida pelo HBoot

    mov dword[Hexagon.Boot.Parametros.linhaComando], esi

;; Agora vamos arrumar a casa para entrar em modo protegido e ir para o ponto de entrada de fato do
;; Hexagon, iniciando de fato o kernel

;; Habilitar A20, necessário para endereçamento de 4 GB de memória RAM e para entrar em modo protegido

    call Hexagon.Kernel.Arch.i386.CPU.CPU.ativarA20 ;; Ativar A20, necessário para o modo protegido

    call Hexagon.Kernel.Arch.i386.Mm.Mm.obterMemoriaTotal ;; Obtem o total de memória instalada

    call Hexagon.Kernel.Arch.i386.CPU.CPU.irPara32 ;; Configurar modo protegido 32 bits

;; Agora o código de modo protegido será executado (já estamos em 32 bits!)

use32

    jmp Hexagon.init ;; Vamos agora para o ponto de entrada do Hexagon em modo protegido

include "kern.asm" ;; Incluir o restante do Kernel, em ambiente de modo protegido
