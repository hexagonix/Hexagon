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

;;************************************************************************************

Hexagon.Panico:

.cabecalhoPanico:
db 10, 10, "Kernel Panic: ", 0
.cabecalhoOops:
db 10, 10, "Kernel Oops: ", 0
.erroReiniciar:
db "Restart your computer to continue.", 0
.erroNaoFatal:
db "Press any key to continue...", 0
.erroDesconhecido:
db 10, 10, "The severity of the error was not provided or is unknown by the Hexagon.", 10, 10, 0

;;************************************************************************************

;; Exibe mensagem de erro na tela e solicita o reinício do computador
;;
;; Entrada:
;;
;; EAX - O erro é fatal? (0 para não e 1 para sim)
;; ESI - Mensagem de erro complementar

Hexagon.Kernel.Kernel.Panico.panico:

    push esi
    push eax

    call Hexagon.Kernel.Kernel.Panico.prepararPanico

    kprint Hexagon.Info.sobreHexagon

    pop eax

    cmp eax, 0 ;; Caso o erro não seja fatal, o controle pode ser devolvido à função que chamou
    je .naoFatal

    cmp eax, 1
    je .fatal

    jmp .desconhecido

.fatal:

    kprint Hexagon.Panico.cabecalhoPanico

    logHexagon Hexagon.Panico.cabecalhoPanico, Hexagon.Dmesg.Prioridades.p4

    pop esi

    call Hexagon.Kernel.Dev.Gen.Console.Console.imprimirString

    mov ebx, Hexagon.Dmesg.Prioridades.p4

    call Hexagon.Kernel.Kernel.Dmesg.criarMensagemHexagon

    kprint Hexagon.Panico.erroReiniciar

    hlt

    jmp $

.naoFatal:

    kprint Hexagon.Panico.cabecalhoOops

    logHexagon Hexagon.Panico.cabecalhoOops, Hexagon.Dmesg.Prioridades.p4

    call Hexagon.Kernel.Kernel.Dmesg.criarMensagemHexagon

    pop esi

    call Hexagon.Kernel.Dev.Gen.Console.Console.imprimirString

    mov ebx, Hexagon.Dmesg.Prioridades.p4

    call Hexagon.Kernel.Kernel.Dmesg.criarMensagemHexagon

    kprint Hexagon.Panico.erroNaoFatal

    call Hexagon.Kernel.Dev.Gen.Teclado.Teclado.aguardarTeclado

    ret

.desconhecido:

    kprint Hexagon.Panico.erroDesconhecido

    ret

;;************************************************************************************

;; Rotina que prepara a saída de vídeo padrão para a exibição de informações em caso de
;; erro grave no Sistema

Hexagon.Kernel.Kernel.Panico.prepararPanico:

    mov esi, Hexagon.Dev.Dispositivos.vd1 ;; Primeiro, Hexagon.Kernel.Dev.Dev.fechar vd1

    call Hexagon.Kernel.Dev.Dev.fechar

    mov esi, Hexagon.Dev.Dispositivos.vd0 ;; Abrir a saída de vídeo padrão

    call Hexagon.Kernel.Dev.Dev.abrir

    mov eax, 0xFFFFFF ;; BRANCO_ANDROMEDA
    mov ebx, 0x4682B4 ;; AZUL_METALICO

    call Hexagon.Kernel.Dev.Gen.Console.Console.definirCorTexto

    call Hexagon.Kernel.Dev.Gen.Console.Console.limparConsole ;; Limpar saída de vídeo padrão

    mov dx, 0

    call Hexagon.Kernel.Dev.Gen.Console.Console.posicionarCursor

    ret ;; Retornar à rotina principal
