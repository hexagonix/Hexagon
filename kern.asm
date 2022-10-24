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
;; Copyright (C) 2016-2022 Felipe Miguel Nery Lunkes
;; Todos os direitos reservados.

;; Kernel Hexagon®
;;
;; Daqui em diante, o ambiente de operação é o modo protegido
;;
;; Componente executivo do Kernel                   

use32

;; Aqui vamos incluir macros para facilitar a organização e modificação do código

include "libkern/macros.s"                       ;; Macros

align 4

;;************************************************************************************
;;
;; Arquivos e funções que compõem o Kernel Hexagon®
;;
;;************************************************************************************

;; Versão do Hexagon®

include "kern/versao.asm"                         ;; Contém informações de versão do Hexagon®

;; Serviços do Hexagon®

include "API/api.asm"                             ;; Manipulador de interrupção do Hexagon®
include "libkern/graficos.asm"                    ;; Funções para gráficos do Hexagon®
include "API/servicos.asm"                        ;; Rotinas de interrupção e manipuladores de IRQs

;; Usuários e outras utilidades

include "kern/relatorio.asm"                     ;; Funções para manipulação de mensagens do Kernel
include "kern/panico.asm"                        ;; Funções para exibição e identificação de erros do Hexagon®  
include "kern/usuarios.asm"                      ;; Funções de gerenciamento de permissões e usuários

;; Gerenciamento de Dispositivos do Hexagon®

include "dev/Universal/Teclado/teclado.asm"      ;; Funções necessárias para o uso do teclado
include "arch/x86/Procx86/procx86.asm"           ;; IDT, GDT e procedimentos para definir modo real e protegido
include "arch/x86/BIOS/BIOS.asm"                 ;; Interrupções do BIOS em modo real
include "dev/Universal/Console/console.asm"      ;; Funções de gerenciamento de vídeo do Hexagon®
include "arch/x86/APM/energia.asm"               ;; Implementação APM do Hexagon®
include "dev/Universal/Som/som.asm"              ;; Funções para controle de som do Hexagon®
include "dev/Universal/PS2/PS2.asm"              ;; Funções para controle de portas PS/2 do Hexagon®
include "arch/x86/Timer/timer.asm"                ;; Funções para manipulação de timer do Hexagon®   
include "dev/x86/Disco/disco.asm"                ;; Funções para ler e escrever em discos rígidos do Hexagon®
include "fs/vfs.asm"                             ;; Sistema de arquivos virtual (VFS) para Hexagon®
include "dev/Universal/Mouse/mouse.asm"          ;; Funções para mouse PS/2 do Hexagon®
include "dev/Universal/Impressora/impressora.asm";; Funções de manipulação de impressora
include "dev/Universal/COM/serial.asm"           ;; Funções para manipulação de portas seriais em modo protegido
include "arch/x86/CMOS/cmos.asm"                 ;; Funções para manipulação de data e hora  
include "dev/dev.asm"                            ;; Funções de gerenciamento e abstração de Hardware do Hexagon®
include "arch/Universal/memoria.asm"             ;; Funções para gerenciamento de memória do Hexagon® 
include "arch/x86/Memx86/memoria.asm"            ;; Diagnóstico de memória instalada no dispositivo

;; Processos, modelo de processo e de imagens executáveis

include "kern/proc.asm"                          ;; Funções para a manipulação de processos
include "libkern/HAPP.asm"                       ;; Funções para tratamento de imagens HAPP

;; Sistemas de arquivos suportados pelo Hexagon®

include "fs/FAT16/fat16.asm"                     ;; Rotinas para manipulação de arquivos no sistema de arquivos FAT16

;; Bibliotecas do Hexagon®

include "libkern/string.asm"                     ;; Funções para manipulação de String
include "libkern/num.asm"                        ;; Funções de geração e alimentação de números aleatórios
include "libkern/relogio.asm"                    ;; Interface de relógio em tempo real

;; Aqui temos um stub que previne a execução da imagem do Hexagon® diretamente pelo usuário, o que poderia
;; causar problemas visto a natureza da imagem (ser um Kernel, não um processo comum)

include "libkern/stubHAPP.asm"                   ;; Stub para prevenir execução acidental da imagem

;; Fonte padrão do Sistema

include "libkern/fonte.asm"                      ;; Fontes e serviços de texto para modo gráfico do Hexagon®

;; Mensagens do Hexagon® para verbose, caso seja desejado o suporte a verbose. Em caso negativo, o
;; arquivo estará em branco

include "kern/verbose.asm"                       ;; Contém as mensagens para verbose exclusivas do Hexagon®

;; Aqui temos as variáveis, constantes e funções para interpretar parâmetros passados pelo HBoot

include "kern/parametros.asm"                    ;; Código de análise e processamento de parâmetros

;;************************************************************************************

;; Ponto de entrada do Hexagon® - Inicialização do kernel

Hexagon.init:                   ;; Agora as estruturas do Kernel serão inicializadas

;; Primeiramente os registradores de segmento e da pilha serão configurados

    mov ax, 0x10
    mov ds, ax
    mov ax, 0x18                ;; ES com base em 0
    mov ss, ax
    mov fs, ax
    mov gs, ax
    mov es, ax  
    mov esp, 0x10000            ;; Definir ponteiro de pilha

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

    call Hexagon.Kernel.Dev.Universal.Console.Console.limparConsole

    kprint Hexagon.Verbose.Hexagon
    
    logHexagon Hexagon.Verbose.versao, Hexagon.Relatorio.Prioridades.p5

    kprint Hexagon.Relatorio.identificadorHexagon

    call Hexagon.Kernel.Kernel.Relatorio.dataParaRelatorio

    call Hexagon.Kernel.Kernel.Relatorio.horaParaRelatorio

    kprint Hexagon.Verbose.novaLinha

    kprint Hexagon.Relatorio.identificadorHexagon

    kprint Hexagon.Verbose.memoriaTotal

    call Hexagon.Kernel.Arch.Universal.Memoria.usoMemoria

    mov eax, ecx

    call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirDecimal

    kprint Hexagon.Verbose.megabytes

    call Hexagon.Kernel.Arch.Universal.Memoria.usoMemoria

    mov eax, ebx

    call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirDecimal

    kprint Hexagon.Verbose.bytes

    kprint Hexagon.Verbose.novaLinha

;;************************************************************************************
    
    logHexagon Hexagon.Verbose.teclado, Hexagon.Relatorio.Prioridades.p5

    logHexagon Hexagon.Verbose.mouse, Hexagon.Relatorio.Prioridades.p5 

;;************************************************************************************

    call Hexagon.Kernel.Arch.x86.Timer.Timer.iniciarTimer ;; Inicializa o serviço de timer do Sistema

    logHexagon Hexagon.Verbose.timer, Hexagon.Relatorio.Prioridades.p5

;;************************************************************************************

    call Hexagon.Kernel.Kernel.Proc.iniciarEscalonador ;; Inicia o escalonador de processos do Hexagon®

    logHexagon Hexagon.Verbose.escalonador, Hexagon.Relatorio.Prioridades.p5

;;************************************************************************************

    call Hexagon.Kernel.Dev.Universal.COM.Serial.iniciarCOM1 ;; Iniciar primeira porta serial para debug 

    logHexagon Hexagon.Verbose.serial, Hexagon.Relatorio.Prioridades.p5 

;;************************************************************************************

    call Hexagon.Kernel.FS.VFS.definirVolume ;; Define o volume com base em informações da inicialização   

    logHexagon Hexagon.Verbose.definirVolume, Hexagon.Relatorio.Prioridades.p5 

;;************************************************************************************

    call Hexagon.Kernel.FS.VFS.definirSistemaArquivos ;; Define o sistema de arquivos à ser utilizado para o volume
    
    kprint Hexagon.Relatorio.identificadorHexagon

    kprint Hexagon.Verbose.inicioMontagem 
    
    call Hexagon.Kernel.FS.VFS.obterVolume ;; Obter o identificador do volume

    call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirString ;; Exibir

    kprint Hexagon.Verbose.montagemRealizada 
    
    kprint Hexagon.Verbose.novaLinha
    
;;************************************************************************************

    call Hexagon.Kernel.FS.VFS.iniciarSistemaArquivos ;; Inicializa as estruturas do sistema de arquivos do volume
    
    kprint Hexagon.Relatorio.identificadorHexagon

    kprint Hexagon.Verbose.sistemaArquivos 
    
    call Hexagon.Kernel.FS.VFS.obterVolume

    push esi
    push edi
    
    mov al, ah 
    xor ah, ah

    call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirHexadecimal

    mov al, 10

    call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirCaractere

    kprint Hexagon.Relatorio.identificadorHexagon

    kprint Hexagon.Verbose.rotuloVolume 
    
    pop edi
    pop esi

    mov esi, edi

    call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirString

    mov al, 10

    call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirCaractere

;;************************************************************************************

    mov esi, "/"

    call Hexagon.Kernel.FS.Dir.definirPontodeMontagem 

    call Hexagon.Kernel.FS.VFS.montarVolume ;; Monta o volume padrão utilizado para a inicialização

    logHexagon Hexagon.Verbose.sucessoMontagem, Hexagon.Relatorio.Prioridades.p5

;;************************************************************************************

    call instalarInterrupcoes ;; Instala os manipuladores de interrupção do Hexagon
    
;; Primeiramente, deve-se impedir que o usuário mate processos com uma tecla especial, impedindo
;; que qualquer processo relevante, como o de login, seja finalizado prematuramente

;; Impede que o usuário mate processos com uma tecla especial

    call Hexagon.Kernel.Kernel.Proc.travar 

    logHexagon Hexagon.Verbose.travando, Hexagon.Relatorio.Prioridades.p5 

;;************************************************************************************

iniciarComponentes:

    logHexagon Hexagon.Verbose.modoUsuario, Hexagon.Relatorio.Prioridades.p5

.iniciarInit:
    
;; Agora o Hexagon tentará carregar o init e, em caso de sucesso, transferir o controle para
;; ele, que finalizará a inicialização do sistema em modo usuário
    
;; Primeiro, verificar se o arquivo existe no volume

    logHexagon Hexagon.Verbose.init, Hexagon.Relatorio.Prioridades.p5 

    mov esi, initHexagon

    call Hexagon.Kernel.FS.VFS.arquivoExiste

    jc .initNaoEncontrado

    logHexagon Hexagon.Verbose.initEncontrado, Hexagon.Relatorio.Prioridades.p5

    mov eax, 0                 ;; Não fornecer argumentos
    mov esi, initHexagon       ;; Nome do arquivo
    
    clc
    
    call Hexagon.Kernel.Kernel.Proc.criarProcesso ;; Solicitar o carregamento do init

    logHexagon Hexagon.Verbose.semInit, Hexagon.Relatorio.Prioridades.p5

    jnc .fimInit

.initNaoEncontrado:            ;; O init não pôde ser localizado
    
;; Por enquanto, o Hexagon tentará carregar o shell padrão do sistema

    logHexagon Hexagon.Verbose.initNaoEncontrado, Hexagon.Relatorio.Prioridades.p5

    mov eax, 0                 ;; Não fornecer argumentos
    mov esi, shellHexagon      ;; Nome do arquivo
    
    clc
    
    call Hexagon.Kernel.Kernel.Proc.criarProcesso ;; Solicitar o carregamento do shell padrão

    jnc .fimShell
    
.fimInit:                      ;; Imprimir mensagem e finalizar o sistema

    mov esi, semInit
    
    mov eax, 1

    call Hexagon.Kernel.Kernel.Panico.panico

.fimShell:

    mov esi, shellFinalizado
    
    mov eax, 1

    call Hexagon.Kernel.Kernel.Panico.panico ;; Solicitar montagem de tela de erro
    
;;************************************************************************************
     
initHexagon:          db "init", 0 ;; Nome de arquivo do init
shellHexagon:         db "sh", 0   ;; Nome do shell padrão
           
semInit:              db "Um componente critico (init) nao foi encontrado no volume de inicializacao.", 10, 10
                      db "Certifique-se que o arquivo 'init' ou equivalente esteja presente no volume do sistema.", 10
                      db "Caso nao esteja presente, utilize o disco de instalacao original para corrigir este problema.", 10, 10, 0
         
componenteFinalizado: db "Um componente critico (init) foi finalizado de forma inesperada.", 10, 10
                      db "Algum erro inesperado fez com que um componente do sistema fosse finalizado.", 10
                      db "Este pequeno problema impede a execucao do sistema de maneira adequada e, para evitar qualquer", 10
                      db "problema mais grave ou a perda de seus dados, o sistema foi finalizado.", 10, 0

;;************************************************************************************
;;
;; AVISO! Esta porção de código pode ser removida com o tempo.
;; 
;; - Futuramente, o sistema não poderá ser utilizado sem o carregamento de init.
;; - Por enquanto, ao não localizar o init, o Hexagon tentará carregar o shell.
;;
;;************************************************************************************

semShell:             db "O shell padrao (/sh) nao foi localizado neste volume.", 10, 10
                      db "Certifique-se que o shell padrao esteja presente no volume do sistema e tente novamente.", 10
                      db "Caso nao esteja presente, utilize o disco de instalacao original para corrigir este problema.", 10, 10, 0
         
shellFinalizado:      db "O shell do sistema foi finalizado de forma inesperada.", 10, 10
                      db 10, "Algum erro inesperado fez com que o shell do sistema fosse finalizado.", 10
                      db "Este pequeno problema impede a execucao do sistema de maneira adequada e, para evitar qualquer", 10
                      db "problema mais grave ou a perda de seus dados, o sistema foi finalizado.", 10, 0
                     
;;************************************************************************************

Hexagon.FimCodigo:

Hexagon.BlocoModoVBE       = Hexagon.FimCodigo + 0      
Hexagon.CacheDisco         = Hexagon.FimCodigo + 1024          ;; Buffer de disco para carregar setores
Hexagon.ArgumentosProcesso = Hexagon.FimCodigo + 60000 + 0x500 ;; Espaço de armazenamento dos argumentos de um aplicativo
