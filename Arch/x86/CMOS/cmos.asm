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

;; Variáveis onde os dados obtidos do CMOS serão armazenados

Hexagon.Arch.x86.CMOS:

.seculo     db 0
.ano        db 0
.mes        db 0
.dia        db 0
.hora       db 0
.minuto     db 0
.segundo    db 0
.diaSemana  db 0

;;************************************************************************************

;; Essa função é solicitada pelo manipulador do timer a cada intervalo de tempo, mantendo
;; o relógio em tempo real do Hexagon® atualizado.

Hexagon.Kernel.Arch.x86.CMOS.CMOS.atualizarDadosCMOS:

    push ax

    mov al, 0x00         ;; Obter o byte de segundos
        
    out 0x70, al
       
    in al, 0x71
       
    mov [Hexagon.Arch.x86.CMOS.segundo], al    ;; Armazenar essa informação

    mov al, 0x02         ;; Obter o byte de minutos
       
    out 0x70, al
       
    in al, 0x71
      
    mov [Hexagon.Arch.x86.CMOS.minuto], al

    mov al, 0x04         ;; Obter o byte de horas
       
    out 0x70, al
       
    in al, 0x71
       
    mov [Hexagon.Arch.x86.CMOS.hora], al

    mov al, 0x06         ;; Obter o byte de dia da semana
       
    out 0x70, al
       
    in al, 0x71
       
    mov [Hexagon.Arch.x86.CMOS.diaSemana], al

    mov al, 0x07         ;; Obter o byte de dia
        
    out 0x70, al
        
    in al, 0x71
        
    mov [Hexagon.Arch.x86.CMOS.dia], al

    mov al, 0x08         ;; Obter o byte de mês 
       
    out 0x70, al
       
    in al, 0x71
       
    mov [Hexagon.Arch.x86.CMOS.mes], al

    mov al, 0x09         ;; Obter o byte de ano
       
    out 0x70, al
       
    in al, 0x71
       
    mov [Hexagon.Arch.x86.CMOS.ano], al

    mov al, 0x32         ;; Obter o byte de século
        
    out 0x70, al
        
    in al, 0x71
        
    mov [Hexagon.Arch.x86.CMOS.seculo], al

    pop ax
        
    ret

;;************************************************************************************

;; Chamado por instâncias do Hexagon® para obtenção direta, independente de atualização
;; por timer. Função com nome mantido para garantir compatibilidade com o código fonte

Hexagon.Kernel.Arch.x86.CMOS.CMOS.obterDadosCMOS:

    call Hexagon.Kernel.Arch.x86.CMOS.CMOS.atualizarDadosCMOS
    
    ret

