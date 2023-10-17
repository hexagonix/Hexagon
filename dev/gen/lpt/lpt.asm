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

use32

;; Inicializa a porta paralela, utilizando o número da porta fornecido

Hexagon.Kernel.Dev.Gen.LPT.LPT.iniciarPortaParalela:

    pusha

;; Reiniciar porta através do registrador de controle (base+2)

    mov dx, word[portaParalelaAtual]

    add dx, 2 ;; Registro de controle (base+2)

    in al, dx

    mov al, 00001100b

;; Bit 2 - Reiniciar porta
;; Bit 3 - Selecionar dispositivo
;; Bit 5 - Habilitar porta bi-direcional

    out dx, al ;; Enviar sinal de reinício

    popa

    ret

;;************************************************************************************

;; Função que permite o envio de dados para uma porta paralela

Hexagon.Kernel.Dev.Gen.LPT.LPT.enviarPortaParalela:

    lodsb ;; Carrega o próximo caractere à ser enviado

    or al, al ;; Compara o caractere com o fim da mensagem
    jz .pronto ;; Se igual ao fim, pula para .pronto

;; Chama função que irá executar a entrada e saída

    call Hexagon.Kernel.Dev.Gen.LPT.LPT.realizarEnvioPortaParalela

    jc .falhaImpressora

;; Se não tiver acabado, volta à função e carrega o próximo caractere

    jmp Hexagon.Kernel.Dev.Gen.LPT.LPT.enviarPortaParalela

.pronto: ;; Se tiver acabado...

    ret ;; Retorna ao processo que o chamou

.falhaImpressora:

    stc ;; Definir Carry

    ret

;;************************************************************************************

;; Enviar dados para a porta paralela
;;
;; Entrada:
;;
;; AL - byte para enviar

Hexagon.Kernel.Dev.Gen.LPT.LPT.realizarEnvioPortaParalela:

    pusha

    push ax ;; Salvar o byte fornecido em AL

;; Reiniciar porta através do registrador de controle (base+2)

    mov dx, word[portaParalelaAtual]

    add dx, 2 ;; Registro de controle (base+2)

    in al, dx

    mov al, 00001100b

;; Bit 2 - Reiniciar porta
;; Bit 3 - Selecionar dispositivo
;; Bit 5 - Habilitar porta bi-direcional

    out dx, al ;; Enviar sinal de reinício

;; Enviar dados para a porta via registrador de dados (base+0)

    pop ax ;; Restaurar dado passado em AL

    mov dx, word[portaParalelaAtual]

    out dx, al ;; Enviar dados

;; Enviar sinalização para registrador de controle (base+2), mostrando que os dados
;; estão disponíveis

    mov dx, word [portaParalelaAtual]

    add dx, 2

    mov al, 1

;; Bit 0 - sinal

    out dx, al ;; Enviar

    popa

    ret

;;************************************************************************************

portaParalelaAtual dw 0 ;; Armazena o endereço de entrada e saída do dispositivo
