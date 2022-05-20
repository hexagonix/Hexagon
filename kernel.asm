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

;; Kernel Hexagon®

;; Daqui em diante, o ambiente de operação é o modo protegido

;; Componente executivo do Kernel

use32					

;;************************************************************************************
;;
;; Arquivos e funções que compõem o Kernel Hexagon®
;;
;;************************************************************************************

;; Versão do Hexagon®

include "Kernel/versao.asm"                       ;; Contém informações de versão do Hexagon®

;; Serviços do Hexagon®

include "API/api.asm"		                      ;; Manipulador de interrupção do Hexagon®
include "Lib/graficos.asm"	                      ;; Funções para gráficos do Hexagon®
include "API/servicos.asm"	                      ;; Rotinas de interrupção e manipuladores de IRQs

;; Usuários e outras utilidades

include "Kernel/relatorio.asm"                    ;; Funções para manipulação de mensagens do Kernel
include "Kernel/panico.asm"                       ;; Funções para exibição e identificação de erros do Hexagon®  
include "Kernel/usuarios.asm"                     ;; Funções de gerenciamento de permissões e usuários

;; Gerenciamento de Dispositivos do Hexagon®

align 32 

include "Dev/Universal/Teclado/teclado.asm"	      ;; Funções necessárias para o uso do teclado
include "Arch/x86/Procx86/procx86.asm"	          ;; IDT, GDT e procedimentos para definir modo real e protegido
include "Arch/x86/BIOS/BIOS.asm"		          ;; Interrupções do BIOS em modo real
include "Dev/Universal/Console/console.asm"	      ;; Funções de gerenciamento de vídeo do Hexagon®
include "Arch/x86/APM/energia.asm"                ;; Implementação APM do Hexagon®
include "Dev/Universal/Som/som.asm"               ;; Funções para controle de som do Hexagon®
include "Dev/Universal/PS2/PS2.asm"               ;; Funções para controle de portas PS/2 do Hexagon®
include "Arch/x86/Timer/timer.asm"                ;; Funções para manipulação de timer do Hexagon®   
include "Dev/x86/Disco/disco.asm"		          ;; Funções para ler e escrever em discos rígidos do Hexagon®
include "FS/vfs.asm"                              ;; Sistema de arquivos virtual (VFS) para Hexagon®
include "Dev/Universal/Mouse/mouse.asm"		      ;; Funções para mouse PS/2 do Hexagon®
include "Dev/Universal/Impressora/impressora.asm" ;; Funções de manipulação de impressora
include "Dev/Universal/COM/serial.asm"            ;; Funções para manipulação de portas seriais em modo protegido
include "Arch/x86/CMOS/cmos.asm"                  ;; Funções para manipulação de data e hora  
include "Dev/dev.asm"                             ;; Funções de gerenciamento e abstração de Hardware do Hexagon®
include "Arch/Universal/memoria.asm"              ;; Funções para gerenciamento de memória do Hexagon® 
include "Arch/x86/Memx86/memoria.asm"             ;; Diagnóstico de memória instalada no dispositivo

;; Processos, modelo de processo e de imagens executáveis

include "Kernel/proc.asm"                         ;; Funções para a manipulação de processos
include "Lib/HAPP.asm"                            ;; Funções para tratamento de imagens HAPP

;; Sistemas de arquivos suportados pelo Hexagon®

include "FS/FAT16/fat16.asm"                      ;; Rotinas para manipulação de arquivos no sistema de arquivos FAT16

;; Bibliotecas do Hexagon®

include "Lib/string.asm"	                      ;; Funções para manipulação de String
include "Lib/num.asm"                             ;; Funções de geração e alimentação de números aleatórios
include "Lib/relogio.asm"                         ;; Interface de relógio em tempo real

;; Aqui temos um stub que previne a execução da imagem do Hexagon® diretamente pelo usuário, o que poderia
;; causar problemas visto a natureza da imagem (ser um Kernel, não um processo comum)

include "Lib/stubHAPP.asm"                       ;; Stub para prevenir execução acidental da imagem

;; Fonte padrão do Sistema

include "Lib/fonte.asm"	                         ;; Fontes e serviços de texto para modo gráfico do Hexagon®

;; Mensagens do Hexagon® para verbose, caso seja desejado o suporte a verbose. Em caso negativo, o
;; arquivo estará em branco

include "Kernel/verbose.asm"                     ;; Contém as mensagens para verbose exclusivas do Hexagon®

;; Aqui temos as variáveis, constantes e funções para interpretar parâmetros passados pelo HBoot

include "Kernel/parametros.asm"                  ;; Código de análise e processamento de parâmetros

;;************************************************************************************

;; Ponto de entrada do Hexagon® - Inicialização do kernel

Hexagon.init:                   ;; Agora as estruturas do Kernel serão inicializadas

;; Primeiramente os registradores de segmento e da pilha serão configurados

	mov ax, 0x10
	mov ds, ax
	mov ax, 0x18			    ;; ES com base em 0
	mov ss, ax
	mov fs, ax
	mov gs, ax
	mov es, ax	
	mov esp, 0x10000		    ;; Definir ponteiro de pilha

	cli

;; Agora os serviços e estruturas do Kernel serão inicializados

	call Hexagon.Kernel.Arch.x86.Procx86.Procx86.identificarProcessador ;; Identifica o processador instalado
	
	call Hexagon.Kernel.Arch.x86.Procx86.Procx86.configurarProcessador ;; Configura a operação do processador

	call Hexagon.Kernel.Arch.Universal.Memoria.iniciarMemoria ;; Inicia o alocador de memória do Hexagon®

	call Hexagon.Kernel.Dev.Universal.Teclado.Teclado.iniciarTeclado ;; Iniciar o serviço de teclado do Hexagon®

	call Hexagon.Kernel.Dev.Universal.Mouse.Mouse.iniciarMouse ;; Iniciar o serviço de mouse do Hexagon®

	call Hexagon.Kernel.Lib.Graficos.configurarVideo ;; Configura a resolução e configurações padrão de vídeo

	call Hexagon.Kernel.Kernel.Relatorio.iniciarRelatorio ;; Inicia o relatório de componentes do Hexagon®
	
;;************************************************************************************

;; Aqui se iniciam as mensagens de aviso do Hexagon®

match =SIM, VERBOSE {

	call Hexagon.Kernel.Dev.Universal.Console.Console.limparConsole

	mov esi, Hexagon.Verbose.Hexagon

	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirString
	
	mov esi, Hexagon.Verbose.versao 
	mov ebx, Hexagon.Relatorio.Prioridades.p5

	call Hexagon.Kernel.Kernel.Relatorio.criarMensagemHexagon

	mov esi, Hexagon.Relatorio.identificadorHexagon

	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirString

	call Hexagon.Kernel.Kernel.Relatorio.dataParaRelatorio

	call Hexagon.Kernel.Kernel.Relatorio.horaParaRelatorio

	mov esi, Hexagon.Verbose.novaLinha

	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirString

	mov esi, Hexagon.Relatorio.identificadorHexagon

	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirString

	mov esi, Hexagon.Verbose.memoriaTotal

	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirString

	call Hexagon.Kernel.Arch.Universal.Memoria.usoMemoria

	mov eax, ecx

	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirDecimal

	mov esi, Hexagon.Verbose.megabytes

	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirString

	call Hexagon.Kernel.Arch.Universal.Memoria.usoMemoria

	mov eax, ebx

	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirDecimal

	mov esi, Hexagon.Verbose.bytes

	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirString

	mov esi, Hexagon.Verbose.novaLinha

	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirString

}

;;************************************************************************************

match =SIM, VERBOSE {
	
	mov esi, Hexagon.Verbose.teclado 
	mov ebx, Hexagon.Relatorio.Prioridades.p5
	
	call Hexagon.Kernel.Kernel.Relatorio.criarMensagemHexagon

	
	mov esi, Hexagon.Verbose.mouse
	mov ebx, Hexagon.Relatorio.Prioridades.p5 
	
	call Hexagon.Kernel.Kernel.Relatorio.criarMensagemHexagon

}

;;************************************************************************************

	call Hexagon.Kernel.Arch.x86.Timer.Timer.iniciarTimer ;; Inicializa o serviço de timer do Sistema

match =SIM, VERBOSE {

	mov esi, Hexagon.Verbose.timer 
	mov ebx, Hexagon.Relatorio.Prioridades.p5
	
	call Hexagon.Kernel.Kernel.Relatorio.criarMensagemHexagon

}

;;************************************************************************************

	call Hexagon.Kernel.Kernel.Proc.iniciarEscalonador ;; Inicia o escalonador de processos do Hexagon®

match =SIM, VERBOSE {
	
	mov esi, Hexagon.Verbose.escalonador 
	mov ebx, Hexagon.Relatorio.Prioridades.p5
	
	call Hexagon.Kernel.Kernel.Relatorio.criarMensagemHexagon

}

;;************************************************************************************

	call Hexagon.Kernel.Dev.Universal.COM.Serial.iniciarCOM1 ;; Iniciar primeira porta serial para debug 

match =SIM, VERBOSE {
	
	mov esi, Hexagon.Verbose.serial
	mov ebx, Hexagon.Relatorio.Prioridades.p5 
	
	call Hexagon.Kernel.Kernel.Relatorio.criarMensagemHexagon

}

;;************************************************************************************

	call Hexagon.Kernel.FS.VFS.definirVolume ;; Define o volume com base em informações da inicialização   

match =SIM, VERBOSE {

	mov esi, Hexagon.Verbose.definirVolume
	mov ebx, Hexagon.Relatorio.Prioridades.p5 
	
	call Hexagon.Kernel.Kernel.Relatorio.criarMensagemHexagon

}

;;************************************************************************************

	call Hexagon.Kernel.FS.VFS.definirSistemaArquivos ;; Define o sistema de arquivos à ser utilizado para o volume

match =SIM, VERBOSE {
	
	mov esi, Hexagon.Relatorio.identificadorHexagon

	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirString

	mov esi, Hexagon.Verbose.montagemAceita 
	
	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirString

	call Hexagon.Kernel.FS.VFS.obterVolume

	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirString

	mov esi, Hexagon.Verbose.montagemRealizada 
	
	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirString

	mov esi, Hexagon.Verbose.novaLinha
	
	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirString

}

;;************************************************************************************

	call Hexagon.Kernel.FS.VFS.iniciarSistemaArquivos ;; Inicializa as estruturas do sistema de arquivos do volume

match =SIM, VERBOSE {
	
	mov esi, Hexagon.Relatorio.identificadorHexagon

	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirString

	mov esi, Hexagon.Verbose.sistemaArquivos 
	
	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirString

	call Hexagon.Kernel.FS.VFS.obterVolume

	push esi
	push edi
	
	mov al, ah 
	xor ah, ah

	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirHexadecimal

	mov al, 10

	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirCaractere

	mov esi, Hexagon.Relatorio.identificadorHexagon

	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirString

	mov esi, Hexagon.Verbose.rotuloVolume 
	
	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirString

	pop edi
	pop esi

	mov esi, edi

	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirString

	mov al, 10

	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirCaractere

}

;;************************************************************************************

	mov esi, "/"

	call Hexagon.Kernel.FS.Dir.definirPontodeMontagem 

	call Hexagon.Kernel.FS.VFS.montarVolume ;; Monta o volume padrão utilizado para a inicialização

match =SIM, VERBOSE {
	
	mov esi, Hexagon.Verbose.sucessoMontagem
	mov ebx, Hexagon.Relatorio.Prioridades.p5
	
	call Hexagon.Kernel.Kernel.Relatorio.criarMensagemHexagon

}	

;;************************************************************************************

	call instalarInterrupcoes ;; Instala os manipuladores de interrupção do Sistema
	
;; Primeiramente, deve-se impedir que o usuário mate processos com uma tecla especial, impedindo
;; que qualquer processo relevante, como o de login, seja finalizado prematuramente
	
	call Hexagon.Kernel.Kernel.Proc.travar ;; Impede que o usuário mate processos com uma tecla especial


match =SIM, VERBOSE {

	mov esi, Hexagon.Verbose.travando
	mov ebx, Hexagon.Relatorio.Prioridades.p5 

	call Hexagon.Kernel.Kernel.Relatorio.criarMensagemHexagon

}

;;************************************************************************************

iniciarComponentes:

match =SIM, VERBOSE {

	mov esi, Hexagon.Verbose.modoUsuario
	mov ebx, Hexagon.Relatorio.Prioridades.p5

	call Hexagon.Kernel.Kernel.Relatorio.criarMensagemHexagon

}

.iniciarInit:
	
;; Agora o Sistema tentará carregar o Inicializador do Sistema (Init) e, em caso de sucesso,
;; transferir o controle para ele, que finalizará a inicialização do Sistema
	
;; Primeiro, verificar se o arquivo existe no disco

match =SIM, VERBOSE {

	mov esi, Hexagon.Verbose.init
	mov ebx, Hexagon.Relatorio.Prioridades.p5 

	call Hexagon.Kernel.Kernel.Relatorio.criarMensagemHexagon

}

	mov esi, initHexagon

	call Hexagon.Kernel.FS.VFS.arquivoExiste

	jc .initNaoEncontrado

match =SIM, VERBOSE {

	mov esi, Hexagon.Verbose.initEncontrado
	mov ebx, Hexagon.Relatorio.Prioridades.p5

	call Hexagon.Kernel.Kernel.Relatorio.criarMensagemHexagon

}

	mov eax, 0			       ;; Não fornecer argumentos
	mov esi, initHexagon       ;; Nome do arquivo
	
	clc
	
	call Hexagon.Kernel.Kernel.Proc.criarProcesso ;; Solicitar o carregamento do Inicializador do Sistema (Init)

match =SIM, VERBOSE {

	mov esi, Hexagon.Verbose.semInit
	mov ebx, Hexagon.Relatorio.Prioridades.p5

	call Hexagon.Kernel.Kernel.Relatorio.criarMensagemHexagon

}

	jnc .fimInit

.initNaoEncontrado:            ;; O Inicializador do Sistema (Init) não pôde ser localizado
	
;; Por enquanto, o Sistema tentará carregar o Shell padrão do Sistema

match =SIM, VERBOSE {

	mov esi, Hexagon.Verbose.initNaoEncontrado
	mov ebx, Hexagon.Relatorio.Prioridades.p5

	call Hexagon.Kernel.Kernel.Relatorio.criarMensagemHexagon

}

    mov eax, 0                 ;; Não fornecer argumentos
	mov esi, shellHexagon      ;; Nome do arquivo
	
	clc
	
	call Hexagon.Kernel.Kernel.Proc.criarProcesso ;; Solicitar o carregamento do Shell padrão

	jnc .fimShell
	
.fimInit:                      ;; Imprimir mensagem e finalizar o sistema

	mov esi, componenteFinalizado
	
	mov eax, 1

	call Hexagon.Kernel.Kernel.Panico.panico

.fimShell:

	mov esi, shellFinalizado
	
    mov eax, 1

	call Hexagon.Kernel.Kernel.Panico.panico ;; Solicitar montagem de tela de erro
	
;;************************************************************************************
	 
initHexagon:          db "init.app", 0 ;; Nome do arquivo que contêm o Inicializador do Sistema (init)
shellHexagon:         db "sh.app", 0   ;; Nome do Shell padrão
		   
semInit:              db "Um componente critico do Sistema (Inicializador do Sistema (init)) nao foi encontrado no disco.", 10, 10
		              db 10, "Certifique-se que o arquivo 'init.app' ou equivalente esteja presente neste disco do sistema", 10
	                  db "Caso nao esteja presente, utilize o disco de instalacao original do sistema para corrigir este problema.", 10, 10, 0
		 
componenteFinalizado: db "Um componente critico do Sistema foi finalizado de forma inesperada.", 10
                      db 10, "Algum erro inesperado fez com que um componente do Sistema fosse finalizado.", 10, 10
                      db "Este pequeno problema impede a execucao do sistema de maneira adequada e, para evitar qualquer", 10, 10
    		          db "problema mais grave ou a perda de seus dados, o Sistema foi finalizado.", 10, 10
			          db "O Sistema pede desculpas por qualquer inconveniente causado.", 10, 10, 10, 0

;;************************************************************************************
;;
;; AVISO! Esta porção de código pode ser removida com o tempo.
;; 
;; - Futuramente, o Sistema não poderá ser utilizado sem o carregamento de init.
;; - Por enquanto, ao não localizar o Inicializador do Sistema (Init), o Sistema tentará 
;;   carregar o Shell.
;;
;;************************************************************************************

semShell:             db "O Shell padrao (/sh.app) para o Sistema nao foi localizado.", 10, 10
		              db 10, 10, "Certifique-se que o Shell padrao esteja presente neste disco do Sistema e tente novamente.", 10
	                  db "Caso nao esteja presente, utilize o disco de instalacao original do Sistema para corrigir este problema.", 10, 10, 0
		 
shellFinalizado:      db "O Shell do Sistema foi finalizado de forma inesperada.", 10, 10
                      db 10, "Algum erro inesperado fez com que o Shell do Sistema fosse finalizado.", 10, 10
                      db "Este pequeno problema impede a execucao do sistema de maneira adequada e, para evitar qualquer", 10, 10
				      db "problema mais grave ou a perda de seus dados, o Sistema foi finalizado.", 10, 10
				      db "O Sistema pede desculpas por qualquer inconveniente causado.", 10, 10, 10, 0

;;************************************************************************************

Hexagon.FimCodigo:

Hexagon.BlocoModoVBE	   = Hexagon.FimCodigo + 0		
Hexagon.CacheDisco	       = Hexagon.FimCodigo + 1024	       ;; Buffer de disco para carregar setores
Hexagon.ArgumentosProcesso = Hexagon.FimCodigo + 60000 + 0x500 ;; Espaço de armazenamento dos argumentos de um aplicativo
