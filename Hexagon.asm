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

;; Ponto de entrada do Kernel Hexagon®

;; Neste momento, o ambiente de operação é o modo real

;; Especificações de inicialização do Hexagon®
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
;; ESI - Linha de comando para o Hexagon®
;; EDI - Endereço da árvore de dispositivos de 32 bits

use16				

cabecalhoHexagon:

.assinatura:      db "HAPP" ;; Assinatura
.arquitetura:     db 01h    ;; Arquitetura (i386 = 01h)
.versaoMinima:    db 00h    ;; Versão mínima do Hexagon® (não nos interessa aqui)
.subversaoMinima: db 00h    ;; Subversão mínima do Hexagon® (não nos interessa aqui)
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
;; no ambiente protegido do Hexagon®
	
;; Irá armazenar o volume onde o sistema foi iniciado (não pode ser alterado)

	mov byte[Hexagon.Dev.Universal.Disco.Controle.driveBoot], bl

;; Salvar o endereço do BPB (BIOS Parameter Block) do volume utilizado para a inicialização 

	mov dword[Hexagon.Memoria.enderecoBPB], ebp
	
;; Armazenar o tamanho da memória RAM disponível, fornecido pelo Carregador de Inicialização do Hexagon®
	
	mov word[Hexagon.Memoria.memoriaCMOS], cx 

;; Agora vamos salvar a localização da estrutura de parâmetros fornecida pelo HBoot

	mov dword[Hexagon.Boot.Parametros.linhaComando], esi

;; Agora vamos arrumar a casa para entrar em modo protegido e ir para o ponto de entrada de fato do
;; Hexagon®, iniciando de fato o kernel

;; Habilitar A20, necessário para endereçamento de 4 GB de memória RAM e para entrar em modo protegido
	
	call Hexagon.Kernel.Arch.x86.Procx86.Procx86.ativarA20        ;; Ativar A20, necessário para o modo protegido

	call Hexagon.Kernel.Arch.x86.Memx86.Memoria.obterMemoriaTotal ;; Obtem o total de memória instalada
		
	call Hexagon.Kernel.Arch.x86.Procx86.Procx86.irPara32         ;; Configurar modo protegido 32 bits
 
;; Agora o código de modo protegido será executado (já estamos em 32 bits!)

use32 

	jmp Hexagon.init  ;; Vamos agora para o ponto de entrada do Hexagon® em modo protegido

include "kernel.asm"  ;; Incluir o restante do Kernel, em ambiente de modo protegido
