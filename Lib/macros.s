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

;; Aqui temos alguns macros úteis para o Hexagon

macro logHexagon mensagem, prioridade 
{

    mov esi, mensagem
	mov ebx, prioridade

	call Hexagon.Kernel.Kernel.Relatorio.criarMensagemHexagon

}

macro kprint string
{

    mov esi, string 

    call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirString
    
}
