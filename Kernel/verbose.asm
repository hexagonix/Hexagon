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
;;        $#$#%    &%$#@
;;        @#!$$    !#@#@
;;
;;
;;************************************************************************************
;;                                                                                  
;;                                 Kernel Hexagon®          
;;                                                                   
;;                  Copyright © 2016-2022 Felipe Miguel Nery Lunkes                
;;                          Todos os direitos reservados.                    
;;                                                                   
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
                    db "Copyright (C) 2016-2022 Felipe Miguel Nery Lunkes", 10, 10, 0
.versao:            db "Versao do Kernel Hexagon(R): ", Hexagon.Versao.definicao, 0
.travando:          db "Habilitando diretrizes de usuario e seguranca...", 0
.timer:             db "Iniciando e configurando o timer (119 Hz)...", 0
.escalonador:       db "Iniciando o escalonador de memoria...", 0
.teclado:           db "O servico de manipulacao de teclado esta sendo iniciado...", 0 
.mouse:             db "O servico de manipulacao de mouse esta sendo iniciado...", 0
.serial:            db "O servico de manipulacao de portas seriais esta sendo iniciado...", 0
.definirVolume:     db "O Hexagon esta procurando o volume principal para montagem...", 0
.montagemAceita:    db "O volume ", 0
.montagemRealizada: db " foi marcado para montagem em /.", 0
.sistemaArquivos:   db "O volume montado e formatado como (FSID): ", 0
.rotuloVolume:      db "O rotulo do volume e: ", 0
.sucessoMontagem:   db "Volume montado em / com sucesso.", 0
.init:              db "Procurando /init.app ou /sh.app...", 0
.semInit:           db "/init.app nao encontrado na raiz do disco. Tentando /sh.app...", 0
.modoUsuario:       db "Indo para o modo usuario...", 0
.memoriaTotal:      db "Memoria total instalada e disponivel: ", 0
.megabytes:         db " Mb (", 0
.bytes:             db " bytes).", 0
.initEncontrado:    db "PID 1: entregando o controle para /init.app.", 0
.initNaoEncontrado: db "PID 1: procurando /sh.app...", 0
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

.matarProcesso: db "O processo em execucao com este PID foi terminado pelo Hexagon(R) a pedido do usuario.", 0

Hexagon.Verbose.Disco:

.erroLerMBR:            db "Erro ao ler o MBR do volume.", 0
.erroLerBPB:            db "Erro ao tentar ler o BPB do volume.", 0
.erroReiniciarDisco:    db "Erro ao solicitar o reinicio do disco.", 0
.erroDiscoNaoDetectado: db "O disco/volume solicitado nao foi detectado ou esta online.", 0
.erroGeralLeitura:      db "Erro geral ao tentar ler setores no volume.", 0
.erroSemMidia:          db "O disco/volume solicitado nao esta online.", 0
.erroProtegidoEscrita:  db "O volume esta protegido contra escrita. Falha ao tentar gravar setores.", 0
.erroDiscoNaoPronto:    db "O disco/volume nao esta pronto.", 0
.erroEmUso:             db "O volume ja esta em uso pelo Hexagon(R) ou outro processo.", 0
.erroEscrita:           db "Erro ao escrever no volume.", 0
.erroGeralEscrita:      db "Erro geral ao tentar escrever setores no volume.", 0

}
