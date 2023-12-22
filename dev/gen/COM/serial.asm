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
;;                     Este arquivo faz parte do kernel Hexagon
;;
;;************************************************************************************

use32

;; Realiza o envio de dados via porta serial
;;
;; Entrada:
;;
;; SI - Ponteiro para o buffer que contêm os dados a serem enviados

;; A função a seguir é usada para transferir dados pela porta serial aberta

Hexagon.Kernel.Dev.Gen.COM.Serial.enviarSerial:

    lodsb ;; Carrega o próximo caractere à ser enviado

    or al, al ;; Compara o caractere com o fim da mensagem
    jz .pronto ;; Se igual ao fim, pula para .pronto

    call Hexagon.Kernel.Dev.Gen.COM.Serial.serialRealizarEnvio

    jc near .erro

;; Se não tiver acabado, volta à função e carrega o próximo caractere

    jmp Hexagon.Kernel.Dev.Gen.COM.Serial.enviarSerial

.pronto: ;; Se tiver acabado...

    ret ;; Retorna a função que o chamou

.erro:

    stc

    ret

;;************************************************************************************

;; Bloqueia o envio de dados pela porta serial até  a mesma estar pronta.
;; Se pronta, envia um byte
;;
;; Entrada:
;;
;; AL - Byte para enviar
;; BX - Registro contendo o número da porta

Hexagon.Kernel.Dev.Gen.COM.Serial.serialRealizarEnvio:

    pusha

    push ax ;; Salvar entrada do usuário

    mov bx, word[portaSerialAtual]

serialAguardarEnviar:

    mov dx, bx

    add dx, 5 ;; Porta + 5

    in al, dx

    test al, 00100000b ;; Bit 5 do Registro de status da linha (Line Status Register)
                       ;; "Registro de espera do transmissor vazio"

    jz serialAguardarEnviar ;; Enquanto não vazio...

    pop ax ;; Restaurar entrada do usuário

    mov dx, bx ;; Porta aberta

    out dx, al ;; Enviar dados à porta solicitada

    popa

    ret

;;************************************************************************************

;; Inicializa e abre para leitura e escrita uma determinada porta serial solicitada pelo sistema
;;
;; Entrada:
;;
;; BX - Registro contendo o número da porta

Hexagon.Kernel.Dev.Gen.COM.Serial.iniciarSerial:

    mov bx, word[portaSerialAtual]

    pusha

    push ds

    push cs
    pop ds

    mov al, 0
    mov dx, bx

    inc dx ;; Porta + 1

    out dx, al ;; Desativar interrupções

    mov dx, bx

    add dx, 3 ;; Porta + 3

    mov al, 10000000b

    out dx, al ;; Habilitar o DLAB (bit mais significativo), para que seja possível
               ;; iniciar a definição do divisor da taxa de transmissão

;; Bits 7-7 : Habilitar DLAB
;; Bits 6-6 : Parar transmissão enquanto 1
;; Bits 3-5 : Paridade (0=nenhum)
;; Bits 2-2 : Contagem de bit de parada (0=1 bit de parada)
;; Bits 0-1 : Tamanho do caractere (5 a 8)

    mov al, 12
    mov dx, bx ;; Porta + 0

    out dx, al ;; Byte menos significativo do divisor

    mov al, 0

    mov dx, bx

    add dx, 1 ;; Porta + 1

    out dx, al ;; Byte mais significante do divisor
               ;; Isto produz uma taxa de 115200/12 = 9600

    mov al, 11000111b
    mov dx, bx

    add dx, 2 ;; Porta + 2

    out dx, al ;; Manipulador de 14 bytes, habilitar FIFOs
               ;; Limpar FIFO recebido, limpar FIFO transmitido

;; Bits 7-6 : Nível do manipulador de interrupção
;; Bits 5-5 : Habilitar FIFO de 64 bytes
;; Bits 4-4 : Reservado
;; Bits 3-3 : Seletor de modo
;; Bits 2-2 : Limpar FIFO transmitido
;; Bits 1-1 : Limpar FIFO recebido
;; Bits 0-0 : Habilitar FIFOs

    mov al, 00000011b
    mov dx, bx

    add dx, 3 ;; Porta + 3

    out dx, al

;; Desativar DLAB, e definir:
;;
;;  - Caractere de tamanho de 8 bits
;;  - Sem paridade
;;  - 1 bit de parada

;; Bits 7-7 : Habilitar DLAB
;; Bits 6-6 : Parar transmissão enquanto 1
;; Bits 3-5 : Paridade (0=nenhum)
;; Bits 2-2 : Contagem de bit de parada (0=1 bit de parada)
;; Bits 0-1 : Tamanho do caractere (5 a 8)

    mov al, 00001011b
    mov dx, bx

    add dx, 4 ;; Porta + 4

    out dx, al ;; Habilitar saída auxiliar 2 (também chamado de "ativar IRQ")

;; Bits 7-6 - Reservado
;; Bits 5-5 - Controle de fluxo automático ativado
;; Bits 4-4 - Modo de loopback
;; Bits 3-3 - Saída auxiliar 2
;; Bits 2-2 - Saída auxiliar 1
;; Bits 1-1 - Solicitação para enviar (RTS)
;; Bits 0-0 - Terminal de dados pronto (DTR)

    in al, 21h ;; Ler bits de máscara IRQ do PIC principal

    and al, 11101111b ;; Habilitar IRQ4, mantendo todos os outros IRQs inalterados

    out 21h, al ;; Escrever bits de máscara de IRQ para PIC principal

    mov al, 1
    mov dx, bx

    add dx, 1 ;; Porta + 1

    out dx, al ;; Habilitar interrupções

    pop ds

    popa

    ret

;;************************************************************************************

;; Inicializar a primeira porta serial para debug e emissão de mensagens

Hexagon.Kernel.Dev.Gen.COM.Serial.iniciarCOM1:

    push eax
    push ebx
    push ecx

    mov bx, word[portaSerialAtual]
    mov word[portaSerialAnterior], bx

    mov bx, Hexagon.Dev.codigoDispositivos.com1
    mov word[portaSerialAtual], bx

    call Hexagon.Kernel.Dev.Gen.COM.Serial.iniciarSerial

    mov bx, word[portaSerialAnterior]
    mov word[portaSerialAtual], bx

    pop ecx
    pop ebx
    pop eax

    logHexagon Hexagon.Verbose.serial, Hexagon.Dmesg.Prioridades.p5

    ret

;;************************************************************************************

portaSerialAtual:    db 0
portaSerialAnterior: db 0
