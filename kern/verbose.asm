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

;; As mensagens só serão adicionadas ao Hexagon® em caso de ativação da verbose em
;; tempo de montagem. Se o símbolo não for definido, o Kernel não terá suporte a 
;; verbose direta, mas continuará com a função para o mecanismo de mensagem. 

;;************************************************************************************

use32

match =SIM, VERBOSE {
    
Hexagon.Verbose:

.Hexagon:           db "Bem-vindo ao Hexagon(R)", 10
                    db "Copyright (C) 2016-", __stringano, " Felipe Miguel Nery Lunkes", 10, 10, 0
.versao:            db "Versao do kernel Hexagon(R): ", Hexagon.Versao.definicao, 0
.travando:          db "Habilitando diretrizes de usuario e seguranca...", 0
.timer:             db "Iniciando e configurando o timer (119 Hz)...", 0
.escalonador:       db "Iniciando o escalonador de memoria...", 0
.teclado:           db "O servico de gerenciamento de teclado foi iniciado.", 0 
.mouse:             db "O servico de gerenciamento de mouse foi iniciado.", 0
.serial:            db "O servico de gerenciamento de portas seriais esta sendo iniciado...", 0
.definirVolume:     db "O Hexagon esta procurando o volume principal para montagem...", 0
.inicioMontagem:    db "O volume ", 0
.montagemRealizada: db " foi marcado para montagem em /.", 0
.sistemaArquivos:   db "O volume montado e formatado como (FSID): ", 0
.rotuloVolume:      db "O rotulo do volume e: ", 0
.sucessoMontagem:   db "Volume montado em / com sucesso.", 0
.init:              db "Procurando /init...", 0
.semInit:           db "/init nao encontrado na raiz do volume. Tentando /sh...", 0
.modoUsuario:       db "Indo para o modo usuario...", 0
.memoriaTotal:      db "Memoria total instalada e disponivel: ", 0
.megabytes:         db " Mb (", 0
.bytes:             db " bytes).", 0
.initEncontrado:    db "PID 1: iniciando /init.", 0
.initNaoEncontrado: db "PID 1: procurando /sh...", 0
.desligando:        db "Finalizando e congelando CPU...", 0
.novaLinha:         db 10, 0
.opcodeInvalido:    db "Opcode invalido encontrado no ambiente de execucao. Falha.", 0

Hexagon.Verbose.APM:

.servicoAPM:             db "Solicitando servico de gerenciamento de energia...", 0
.desligamentoAPM:        db "Solicitando desligamento...", 0
.reinicioAPM:            db "Solicitando reinicio...", 0
.erroAPM:                db "Ocorreu um erro na solicitacao de servico de gerenciamento de energia.", 0
.erroComandoAPM:         db "Ocorreu um erro no comando fornecido ao gerenciamento de energia.", 0
.erroConexaoAPM:         db "Ocorreu um erro na conexao ao servico de gerenciamento de energia.", 0
.sucessoDesligamentoAPM: db "Sucesso na solicitacao ao sistema de gerenciamento de energia.", 0
.erroInstalacaoAPM:      db "Erro na instalacao do servico de gerenciamento de energia do Hexagon (R)", 0

Hexagon.Verbose.Servicos:

.matarProcesso: db "O processo em execucao com este PID foi terminado pelo Hexagon a pedido do usuario.", 0

Hexagon.Verbose.Disco:

.erroLerMBR:            db "Erro ao ler o MBR do volume.", 0
.erroLerBPB:            db "Erro ao tentar ler o BPB do volume.", 0
.erroReiniciarDisco:    db "Erro ao solicitar o reinicio do disco.", 0
.erroDiscoNaoDetectado: db "O disco/volume solicitado nao foi detectado ou esta offline.", 0
.erroGeralLeitura:      db "Erro geral ao tentar ler setores no volume.", 0
.erroSemMidia:          db "O disco/volume solicitado nao esta online.", 0
.erroProtegidoEscrita:  db "O volume esta protegido contra escrita. Falha ao tentar gravar setores.", 0
.erroDiscoNaoPronto:    db "O disco/volume nao esta pronto.", 0
.erroEmUso:             db "O volume ja esta em uso pelo Hexagon ou outro processo.", 0
.erroEscrita:           db "Erro ao escrever no volume.", 0
.erroGeralEscrita:      db "Erro geral ao tentar escrever setores no volume.", 0

}
