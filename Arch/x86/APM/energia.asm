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

use32

;;************************************************************************************

Hexagon.Arch.x86.APM:

.status: db 0

;;************************************************************************************

Hexagon.Kernel.Arch.x86.APM.Energia.desligarPC:

match =SIM, VERBOSE
{

    mov esi, Hexagon.Verbose.APM.servicoAPM
    mov ebx, Hexagon.Relatorio.Prioridades.p5 

    call Hexagon.Kernel.Kernel.Relatorio.criarMensagemHexagon

    mov esi, Hexagon.Verbose.APM.desligamentoAPM
    mov ebx, Hexagon.Relatorio.Prioridades.p5 

    call Hexagon.Kernel.Kernel.Relatorio.criarMensagemHexagon

}

;;*********************************************************************/
;;
;;             Parte da implementação APM do Hexagon®
;;
;;          Copyright © 2016-2022 Felipe Miguel Nery Lunkes
;;
;;*********************************************************************/

;;*********************************************************************/
;;
;; Esta função pode retornar códigos de erro, os quais se seguem:
;;
;;
;; Retorno em AX - código de erro:
;;
;; 0 = Falha na instalação do Driver
;; 1 = Falha na conexão de interface de Modo Real
;; 2 = Driver APM versão 1.2 não suportado
;; 3 = Falha ao alterar o status para "off"
;;
;;*********************************************************************/

    push bx
    push cx

    mov ax, 5300h       ;; Função de checagem da instalação
    mov bx, 0           ;; O ID do dispositivo (APM BIOS)
    
    call Hexagon.Kernel.Arch.x86.BIOS.BIOS.int15h           ;; Chamar interrupção APM
    
    jc APM_falha_instalacao

    mov ax, 5301h       ;; Função de interface de conexão em modo real
    mov bx, 0           ;; O ID do dispositivo (APM BIOS)
    
    call Hexagon.Kernel.Arch.x86.BIOS.BIOS.int15h           ;; Chamar interrupção APM
    
    jc APM_falha_conexao

    mov ax, 530Eh       ;; Função de seleção de versão do Driver
    mov bx, 0           ;; O ID do dispositivo (APM BIOS)
    mov cx, 0102h       ;; Selecionar APM versão 1.2
                        ;; A funcionalidade está presente após a versão 1.2
    call Hexagon.Kernel.Arch.x86.BIOS.BIOS.int15h           ;; Chamar interrupção APM
    
    jc APM_falha_selecionar_versao

    mov ax, 5307h       ;; Função de definir estado
    mov cx, 0003h       ;; Estado de desligar
    mov bx, 0001h       ;; Todos os dispositivos tem ID 1
    
    call Hexagon.Kernel.Arch.x86.BIOS.BIOS.int15h           ;; Chamar interrupção APM
    
;; Caso o sistema não desligue de forma apropriada, serão retornados códigos de erro ao
;; programa que chamou a função de desligamento.
    
APM_falha_comando:      ;; Chamado caso o comando de desligamento (código 3) não seja executado

match =SIM, VERBOSE
{

    mov esi, Hexagon.Verbose.APM.erroComandoAPM
    mov ebx, Hexagon.Relatorio.Prioridades.p5 

    call Hexagon.Kernel.Kernel.Relatorio.criarMensagemHexagon

}

    mov ax, 3
    
    jmp APM_desligamento_ok

APM_falha_instalacao:   ;; Chamado caso ocorra falha na instalação

match =SIM, VERBOSE
{

    mov esi, Hexagon.Verbose.APM.erroInstalacaoAPM
    mov ebx, Hexagon.Relatorio.Prioridades.p5 

    call Hexagon.Kernel.Kernel.Relatorio.criarMensagemHexagon

}

    mov ax, 0
    
    jmp APM_desligamento_ok
    
APM_falha_conexao:      ;; Chamado caso ocorra falha na conexão de interface de Modo Real

match =SIM, VERBOSE
{

    mov esi, Hexagon.Verbose.APM.erroConexaoAPM
    mov ebx, Hexagon.Relatorio.Prioridades.p5 

    call Hexagon.Kernel.Kernel.Relatorio.criarMensagemHexagon

}

    mov ax, 1
    
    jmp APM_desligamento_ok
    
APM_falha_selecionar_versao: ;; Chamado quando a versão APM é inferior a 1.2

    mov ax, 2
    
APM_desligamento_ok:    ;; Retorna a função que a chamou

match =SIM, VERBOSE
{

    mov esi, Hexagon.Verbose.APM.sucessoDesligamentoAPM
    mov ebx, Hexagon.Relatorio.Prioridades.p5 

    call Hexagon.Kernel.Kernel.Relatorio.criarMensagemHexagon

}

    pop cx
    pop bx
    
    stc
    
    ret

;;************************************************************************************
    
;; Reiniciar o computador

Hexagon.Kernel.Arch.x86.APM.Energia.reiniciarPC:

match =SIM, VERBOSE
{

    mov esi, Hexagon.Verbose.APM.reinicioAPM
    mov ebx, Hexagon.Relatorio.Prioridades.p5 

    call Hexagon.Kernel.Kernel.Relatorio.criarMensagemHexagon

}

.aguardarLoop:

    in al, 0x64     ;; 0x64 é o registrador de estado
    
    bt ax, 1        ;; Checar segundo bit até se tornar 0
    jnc .OK
    
    jmp .aguardarLoop
    
.OK:

    mov al, 0xfe
    
    out 0x64, al

    cli
    
    jmp $
    
    ret

;;************************************************************************************
