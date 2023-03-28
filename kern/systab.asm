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
;; Chamadas de sistema do Hexagon®
;;
;;************************************************************************************

Hexagon.Syscall.Syscall.servicosHexagon:

.tabela:

;; Gerenciamento de memória e processos

    dd Hexagon.Kernel.API.API.Nulo                                     ;; 0 - função nula, apenas retorna
    dd Hexagon.Kernel.Arch.Gen.Mm.alocarMemoria                        ;; 1
    dd Hexagon.Kernel.Arch.Gen.Mm.liberarMemoria                       ;; 2
    dd Hexagon.Kernel.API.API.criarNovoProcesso                        ;; 3
    dd Hexagon.Kernel.Kernel.Proc.encerrarProcesso                     ;; 4
    dd Hexagon.Kernel.Kernel.Proc.obterPID                             ;; 5
    dd Hexagon.Kernel.Arch.Gen.Mm.usoMemoria                           ;; 6
    dd Hexagon.Kernel.Kernel.Proc.obterListaProcessos                  ;; 7
    dd Hexagon.Kernel.Kernel.Proc.obterCodigoErro                      ;; 8

;; Gerenciamento de arquivos e dispositivos

    dd Hexagon.Kernel.Dev.Dev.abrir                                    ;; 9
    dd Hexagon.Kernel.Dev.Dev.escrever                                 ;; 10
    dd Hexagon.Kernel.Dev.Dev.fechar                                   ;; 11

;; Gerenciamento do Sistema de Arquivos e de volumes

    dd Hexagon.Kernel.FS.VFS.novoArquivo                               ;; 12
    dd Hexagon.Kernel.FS.VFS.salvarArquivo                             ;; 13
    dd Hexagon.Kernel.FS.VFS.deletarArquivo                            ;; 14
    dd Hexagon.Kernel.FS.VFS.listarArquivos                            ;; 15
    dd Hexagon.Kernel.FS.VFS.arquivoExiste                             ;; 16
    dd Hexagon.Kernel.FS.VFS.obterVolume                               ;; 17

;; Gerenciamento de usuários

    dd Hexagon.Kernel.Kernel.Proc.travar                               ;; 18
    dd Hexagon.Kernel.Kernel.Proc.destravar                            ;; 19
    dd Hexagon.Kernel.Kernel.Usuarios.definirUsuario                   ;; 20
    dd Hexagon.Kernel.Kernel.Usuarios.obterUsuario                     ;; 21

;; Serviços oferecidos pelo Hexagon®

    dd Hexagon.Kernel.Kernel.Versao.retornarVersao                     ;; 22
    dd Hexagon.Kernel.Lib.Num.obterAleatorio                           ;; 23
    dd Hexagon.Kernel.Lib.Num.alimentarAleatorios                      ;; 24
    dd Hexagon.Kernel.Arch.i386.Timer.Timer.causarAtraso                ;; 25
    dd Hexagon.Kernel.API.API.intalarInterrupcao                       ;; 26

;; Gerenciamento de energia do Hexagon®

    dd Hexagon.Kernel.Arch.i386.APM.Energia.reiniciarPC                 ;; 27
    dd Hexagon.Kernel.Arch.i386.APM.Energia.desligarPC                  ;; 28

;; Funções de saída em vídeo e gráficos do Hexagon®

    dd Hexagon.Kernel.Dev.Gen.Console.Console.imprimir           ;; 29
    dd Hexagon.Kernel.Dev.Gen.Console.Console.limparConsole      ;; 30
    dd Hexagon.Kernel.Dev.Gen.Console.Console.limparLinha        ;; 31
    dd Hexagon.Kernel.API.API.Nulo                                     ;; 32
    dd Hexagon.Kernel.Dev.Gen.Console.Console.rolarParaBaixo     ;; 33
    dd Hexagon.Kernel.Dev.Gen.Console.Console.posicionarCursor   ;; 34
    dd Hexagon.Kernel.Lib.Graficos.colocarPixel                        ;; 35
    dd Hexagon.Kernel.API.API.desenharBloco                            ;; 36
    dd Hexagon.Kernel.Dev.Gen.Console.Console.imprimirCaractere  ;; 37
    dd Hexagon.Kernel.Dev.Gen.Console.Console.definirCorTexto    ;; 38
    dd Hexagon.Kernel.Dev.Gen.Console.Console.obterCorTexto      ;; 39
    dd Hexagon.Kernel.Dev.Gen.Console.Console.obterInfoVideo     ;; 40
    dd Hexagon.Kernel.Lib.Graficos.atualizarTela                       ;; 41
    dd Hexagon.Kernel.Dev.Gen.Console.Console.definirResolucao   ;; 42
    dd Hexagon.Kernel.Dev.Gen.Console.Console.obterResolucao     ;; 43
    dd Hexagon.Kernel.Dev.Gen.Console.Console.obterCursor        ;; 44

;; Serviços de entrada por teclado do Hexagon®

    dd Hexagon.Kernel.Dev.Gen.Teclado.Teclado.aguardarTeclado    ;; 45
    dd Hexagon.Kernel.Dev.Gen.Teclado.Teclado.obterString        ;; 46
    dd Hexagon.Kernel.Dev.Gen.Teclado.Teclado.obterEstadoTeclas  ;; 47
    dd Hexagon.Kernel.Dev.Gen.Console.Console.alterarFonte       ;; 48
    dd Hexagon.Kernel.Dev.Gen.Teclado.Teclado.alterarLeiaute     ;; 49    

;; Serviços de entrada de mouse PS/2 do Hexagon®

    dd Hexagon.Kernel.Dev.Gen.Mouse.Mouse.aguardarMouse          ;; 50
    dd Hexagon.Kernel.Dev.Gen.Mouse.Mouse.obterDoMouse           ;; 51
    dd Hexagon.Kernel.Dev.Gen.Mouse.Mouse.configurarMouse        ;; 52

;; Serviços de manipulação de dados do Hexagon®

    dd Hexagon.Kernel.Lib.String.compararPalavrasNaString              ;; 53
    dd Hexagon.Kernel.Lib.String.removerCaractereNaString              ;; 54 
    dd Hexagon.Kernel.Lib.String.inserirCaractereNaString              ;; 55
    dd Hexagon.Kernel.Lib.String.tamanhoString                         ;; 56
    dd Hexagon.Kernel.Lib.String.compararString                        ;; 57
    dd Hexagon.Kernel.Lib.String.stringParaMaiusculo                   ;; 58
    dd Hexagon.Kernel.Lib.String.stringParaMinusculo                   ;; 59
    dd Hexagon.Kernel.Lib.String.cortarString                          ;; 60
    dd Hexagon.Kernel.Lib.String.encontrarCaractereNaString            ;; 61
    dd Hexagon.Kernel.Lib.String.stringParaInteiro                     ;; 62
    dd Hexagon.Kernel.Lib.String.paraString                            ;; 63

;; Serviços de saída por som do Hexagon®

    dd Hexagon.Kernel.Dev.Gen.Som.Som.emitirSom                  ;; 64
    dd Hexagon.Kernel.Dev.Gen.Som.Som.desligarSom                ;; 65

;; Serviço de mensagens do Hexagon®

    dd Hexagon.Kernel.Kernel.Dmesg.criarMensagemHexagon            ;; 66

;; Serviço de relógio em tempo real do Hexagon®

    dd Hexagon.Kernel.Lib.Relogio.retornarData                         ;; 67
    dd Hexagon.Kernel.Lib.Relogio.retornarHora                         ;; 68

.tabelaUnix:

;; TODO:

;hx.malloc             = 1
;hx.mfree              = 2
;hx.spawn              = 3
;hx.exit               = 4
;hx.getpid             = 5
;hx.open               = 9
;hx.write              = 10
;hx.close              = 11
;hx.creat              = 13
;hx.unlink             = 14
;hx.indir              = 15
;hx.syslock            = 18
;hx.sysunlock          = 19
;hx.uname              = 22
;hx.sleep              = 25
;hx.putc               = 29
;hx.date               = 67
;hx.time               = 68

;;************************************************************************************
