;;************************************************************************************
;;
;;    
;;        %#@$%    &@$%$                  Kernel Hexagon®
;;        #$@$@    #@#@$
;;        @#@$%    %#$#%
;;        @#$@$    #@#$@
;;        #@#$$#$#%!@#@#     Copyright © 2016-2021 Felipe Miguel Nery Lunkes
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
;;                  Copyright © 2016-2021 Felipe Miguel Nery Lunkes                
;;                          Todos os direitos reservados.                    
;;                                                                   
;;************************************************************************************
;;
;;                    Este arquivo faz parte do Kernel Hexagon® 
;;
;;************************************************************************************

use32

;;************************************************************************************

Hexagon.Kernel.Lib.Relogio.retornarData:                      

    movzx eax, [Hexagon.Arch.x86.CMOS.dia]
    movzx ebx, [Hexagon.Arch.x86.CMOS.mes]
    movzx ecx, [Hexagon.Arch.x86.CMOS.seculo]
    movzx edx, [Hexagon.Arch.x86.CMOS.ano]
    movzx esi, [Hexagon.Arch.x86.CMOS.diaSemana]

    ret

;;************************************************************************************

Hexagon.Kernel.Lib.Relogio.retornarHora:

    movzx eax, [Hexagon.Arch.x86.CMOS.hora]
    movzx ebx, [Hexagon.Arch.x86.CMOS.minuto]
    movzx ecx, [Hexagon.Arch.x86.CMOS.segundo]

    ret
