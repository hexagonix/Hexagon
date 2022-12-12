;;************************************************************************************
;;
;;    
;;        %#@$%    &@$%$                  Kernel Hexagon®
;;        #$@$@    #@#@$
;;        @#@$%    %#$#%
;;        @#$@$    #@#$@
;;        #@#$$#$#%!@#@#     Copyright © 2016-2022 Felipe Miguel Nery Lunkes
;;        @#@%!@&$#&$#@#             Todos os direitos reservados
;;        !@$%#    @&$%#
;;        @$#!%    #&*@&
;;        $#$#%    &%$#@          Licenciado sob licença BSD-3-Clause
;;        @#!$$    !#@#@
;;
;;
;;************************************************************************************
;;
;; Este arquivo é licenciado sob licença BSD-3-Clause. Observe o arquivo de licença 
;; disponível no repositório para mais informações sobre seus direitos e deveres ao 
;; utilizar qualquer trecho deste arquivo.
;;
;; BSD 3-Clause License
;;
;; Copyright (c) 2015-2022, Felipe Miguel Nery Lunkes
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

Hexagon.API.Controle:

.ultimaChamada:  dd 0
.chamadaAtual:   dd 0
.chamadaSistema: db 0 ;; Armazena se uma chamada foi ou não realizada

;;************************************************************************************

;; Manipulador de interrupção do Sistema Operacional Hexagonix®
;;
;; Saída:
;;
;;  EBP = 0xABC12345 em caso de função não disponível
;;  CF definido em caso de função não disponível
    
Hexagon.API.API.manipuladorHexagon:

    push ebp
    
    mov ebp, esp
    
    push 0x10                  ;; Segmento do Kernel
    pop ds

    mov [.es], es
    
    push 0x18
    pop es
    
    cld
    
    mov dword[.eax], eax
    
    add esi, dword[Hexagon.Processos.enderecoAplicativos]
    
    sub esi, 0x500
    
    add edi, dword[Hexagon.Processos.enderecoAplicativos]

    sub edi, 0x500

    pop eax                    ;; Limpar pilha
    
    mov dword[.ebp], eax
    
    pop eax
    
    mov dword[.eip], eax

    pop eax
    
    mov dword[.cs], eax

    pop eax                    ;; Bandeira
    
    pop eax                    ;; Chamada solicitada, armazenada na pilha
    
    mov dword[.parametro], eax ;; Chamada do sistema

    mov dword[Hexagon.API.Controle.chamadaAtual], eax

    mov eax, dword[.eax]

    mov ebp, dword[ds:.parametro]
    
    cmp ebp, dword[.totalChamadas]
    ja .chamadaIndisponivel
    
    mov byte[Hexagon.API.Controle.chamadaSistema], 01h ;; Uma chamada foi sim solicitada

    sti
    
    call dword[Hexagon.API.API.servicosHexagon.tabela+ebp*4]
    
.fim:

    sti

    mov byte[Hexagon.API.Controle.chamadaSistema], 00h  ;; Desmarcar a solicitação de chamada de Sistema
    
    push eax

    mov eax, dword[Hexagon.API.Controle.chamadaAtual]
    mov dword[Hexagon.API.Controle.ultimaChamada], eax

    pop eax

    pushfd
    
    push dword[.cs]
    push dword[.eip]
    
    sub esi, dword[Hexagon.Processos.enderecoAplicativos]

    add esi, 0x500
    
    sub edi, dword[Hexagon.Processos.enderecoAplicativos]

    add edi, 0x500

    mov es, [.es]
    
    push 0x38
    pop ds

    iret
    
.chamadaIndisponivel:

    mov ebp, 0xABC12345
    
    stc
    
    jmp .fim
    
.eflags:    dd 0
.parametro: dd 0
.eax:       dd 0
.cs:        dd 0
.es:        dw 0
.eip:       dd 0
.ebp:       dd 0

.totalChamadas: dd 68

;;************************************************************************************

;; Manipulador de interrupção do Sistema Operacional Hexagonix®
;;
;; Saída:
;;
;;  EBP = 0xABC12345 em caso de função não disponível
;;  CF definido em caso de função não disponível
    
Hexagon.API.API.manipuladorHexagonV2:

    push ebp
    
    mov ebp, esp
    
    push 0x10                  ;; Segmento do Kernel
    pop ds

    mov [.es], es
    
    push 0x18
    pop es
    
    cld
    
    mov dword[.eax], eax

    pop eax                    ;; Limpar pilha
    
    mov dword[.ebp], eax
    
    pop eax
    
    mov dword[.eip], eax

    pop eax
    
    mov dword[.cs], eax

    pop eax                    ;; Bandeira

    pop eax                    ;; EDI

    mov dword[.regEDI], eax ;; Chamada do sistema

    pop eax                    ;; ESI

    mov dword[.regESI], eax ;; Chamada do sistema

    pop eax                    ;; Chamada solicitada, armazenada na pilha
    
    mov dword[.parametro], eax ;; Chamada do sistema

    mov dword[Hexagon.API.Controle.chamadaAtual], eax

    mov eax, dword[.eax]
    mov edi, dword[.regEDI]
    mov esi, dword[.regESI]

    mov ebp, dword[ds:.parametro]
    
    cmp ebp, dword[.totalChamadas]
    ja .chamadaIndisponivel
    
    mov byte[Hexagon.API.Controle.chamadaSistema], 01h ;; Uma chamada foi sim solicitada

    sti
    
    call dword[Hexagon.API.API.servicosHexagon.tabela+ebp*4]
    
.fim:

    sti

    mov byte[Hexagon.API.Controle.chamadaSistema], 00h  ;; Desmarcar a solicitação de chamada de Sistema
    
    push eax

    mov eax, dword[Hexagon.API.Controle.chamadaAtual]
    mov dword[Hexagon.API.Controle.ultimaChamada], eax

    pop eax

    pushfd
    
    push dword[.cs]
    push dword[.eip]

    mov es, [.es]
    
    push 0x38
    pop ds

    iret
    
.chamadaIndisponivel:

    mov ebp, 0xABC12345
    
    stc
    
    jmp .fim
    
.eflags:    dd 0
.parametro: dd 0
.regESI:    dd 0
.regEDI:    dd 0
.eax:       dd 0
.cs:        dd 0
.es:        dw 0
.eip:       dd 0
.ebp:       dd 0

.totalChamadas: dd 68

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

    push dword[Hexagon.API.API.manipuladorHexagon.eip]
    push dword[Hexagon.API.API.manipuladorHexagon.cs]
    
    call Hexagon.Kernel.Kernel.Proc.criarProcesso
    
    pop dword[Hexagon.API.API.manipuladorHexagon.cs]
    pop dword[Hexagon.API.API.manipuladorHexagon.eip]
    
    ret

;;************************************************************************************

;;************************************************************************************
;;
;; Chamadas de sistema do Hexagon®
;;
;;************************************************************************************

Hexagon.API.API.servicosHexagon:

.tabela:

;; Gerenciamento de memória e processos

    dd Hexagon.Kernel.API.API.Nulo                                     ;; 0 - função nula, apenas retorna
    dd Hexagon.Kernel.Arch.Universal.Memoria.alocarMemoria             ;; 1
    dd Hexagon.Kernel.Arch.Universal.Memoria.liberarMemoria            ;; 2
    dd Hexagon.Kernel.API.API.criarNovoProcesso                        ;; 3
    dd Hexagon.Kernel.Kernel.Proc.encerrarProcesso                     ;; 4
    dd Hexagon.Kernel.Kernel.Proc.obterPID                             ;; 5
    dd Hexagon.Kernel.Arch.Universal.Memoria.usoMemoria                ;; 6
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
    dd Hexagon.Kernel.Arch.x86.Timer.Timer.causarAtraso                ;; 25
    dd Hexagon.Kernel.API.API.intalarInterrupcao                      ;; 26

;; Gerenciamento de energia do Hexagon®

    dd Hexagon.Kernel.Arch.x86.APM.Energia.reiniciarPC                 ;; 27
    dd Hexagon.Kernel.Arch.x86.APM.Energia.desligarPC                  ;; 28

;; Funções de saída em vídeo e gráficos do Hexagon®

    dd Hexagon.Kernel.Dev.Universal.Console.Console.imprimir           ;; 29
    dd Hexagon.Kernel.Dev.Universal.Console.Console.limparConsole      ;; 30
    dd Hexagon.Kernel.Dev.Universal.Console.Console.limparLinha        ;; 31
    dd Hexagon.Kernel.API.API.Nulo                                     ;; 32
    dd Hexagon.Kernel.Dev.Universal.Console.Console.rolarParaBaixo     ;; 33
    dd Hexagon.Kernel.Dev.Universal.Console.Console.posicionarCursor   ;; 34
    dd Hexagon.Kernel.Lib.Graficos.colocarPixel                        ;; 35
    dd Hexagon.Kernel.API.API.desenharBloco                            ;; 36
    dd Hexagon.Kernel.Dev.Universal.Console.Console.imprimirCaractere  ;; 37
    dd Hexagon.Kernel.Dev.Universal.Console.Console.definirCorTexto    ;; 38
    dd Hexagon.Kernel.Dev.Universal.Console.Console.obterCorTexto      ;; 39
    dd Hexagon.Kernel.Dev.Universal.Console.Console.obterInfoVideo     ;; 40
    dd Hexagon.Kernel.Lib.Graficos.atualizarTela                       ;; 41
    dd Hexagon.Kernel.Dev.Universal.Console.Console.definirResolucao   ;; 42
    dd Hexagon.Kernel.Dev.Universal.Console.Console.obterResolucao     ;; 43
    dd Hexagon.Kernel.Dev.Universal.Console.Console.obterCursor        ;; 44

;; Serviços de entrada por teclado do Hexagon®

    dd Hexagon.Kernel.Dev.Universal.Teclado.Teclado.aguardarTeclado    ;; 45
    dd Hexagon.Kernel.Dev.Universal.Teclado.Teclado.obterString        ;; 46
    dd Hexagon.Kernel.Dev.Universal.Teclado.Teclado.obterEstadoTeclas  ;; 47
    dd Hexagon.Kernel.Dev.Universal.Console.Console.alterarFonte       ;; 48
    dd Hexagon.Kernel.Dev.Universal.Teclado.Teclado.alterarLeiaute     ;; 49    

;; Serviços de entrada de mouse PS/2 do Hexagon®

    dd Hexagon.Kernel.Dev.Universal.Mouse.Mouse.aguardarMouse          ;; 50
    dd Hexagon.Kernel.Dev.Universal.Mouse.Mouse.obterDoMouse           ;; 51
    dd Hexagon.Kernel.Dev.Universal.Mouse.Mouse.configurarMouse        ;; 52

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

    dd Hexagon.Kernel.Dev.Universal.Som.Som.emitirSom                  ;; 64
    dd Hexagon.Kernel.Dev.Universal.Som.Som.desligarSom                ;; 65

;; Serviço de mensagens do Hexagon®

    dd Hexagon.Kernel.Kernel.Relatorio.criarMensagemHexagon            ;; 66

;; Serviço de relógio em tempo real do Hexagon®

    dd Hexagon.Kernel.Lib.Relogio.retornarData                         ;; 67
    dd Hexagon.Kernel.Lib.Relogio.retornarHora                         ;; 68
 
;;************************************************************************************