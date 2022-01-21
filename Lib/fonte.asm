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

;;************************************************************************************
;;
;;          Fonte Atomic em modo gráfico para Sistema Operacional Andromeda®
;;
;;                  Última tualização da fonte padrão: 03/12/2017
;;
;;************************************************************************************

Hexagon.Fontes:

.largura = 8
.altura	 = 16

.espacoFonte:   ;; Área protegida para o carregamento de novas fontes

;;************************************************************************************

;; Agora vamos incluir aqui uma fonte padrão, em formato de fonte Hexagonix®

include "../../Fontes/hint.asm"

;;************************************************************************************

.reservado:       ;; Espaço reservado para fontes com mais caracteres

times 512 db 0
