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
                                                                
;;************************************************************************************
;;
;;                    Este arquivo faz parte do Kernel Hexagon® 
;;
;;************************************************************************************

use32

;;************************************************************************************

;; Inicializa o timer, utilizando os parâmetros apropriados

Hexagon.Kernel.Arch.x86.Timer.Timer.iniciarTimer:

;; Definir frequência do contador
    
    mov eax, 100            ;; Definir frequência para 1.19 mhz / EAX
    
    out 0x40, al            ;; Primeiro enviar byte menos significante
    
    mov al, ah              ;; Agora o byte mais significante 
    
    out 0x40, al
    
    logHexagon Hexagon.Verbose.timer, Hexagon.Relatorio.Prioridades.p5

    ret

;;************************************************************************************
    
;; Pausa a execução de uma tarefa durante o tempo especificado
;;
;; Entrada:
;;
;; ECX - Tempo para gerar atraso, em unidades de contagem

Hexagon.Kernel.Arch.x86.Timer.Timer.causarAtraso:

    pusha
    
    sti                  ;; Habilitar as interrupções para que se possa atualizar o contador
    
    mov ebx, dword[manipuladorTimer.contagemTimer]

.aguardarUm:    ;; Vamos aguardar até o contador mudar

    cmp ebx, dword[manipuladorTimer.contagemTimer]
    je .aguardarUm
    
.aguardarMudanca:

    cmp ebx, dword[manipuladorTimer.contagemTimer]
    je .aguardarMudanca  ;; Enquanto o contador não tiver seu valor alterado, continue aqui
    
    dec ecx
    
    mov ebx, dword[manipuladorTimer.contagemTimer]

    cmp ecx, 0
    ja .aguardarUm       ;; Se não tiver acabado, continue contando...
    
    popa        
    
    ret

;;************************************************************************************
