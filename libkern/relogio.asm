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
