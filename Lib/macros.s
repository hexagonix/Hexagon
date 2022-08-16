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

;;************************************************************************************

;; Agora, função para codificação de data de build

;; O código abaixo extrai e cria strings com informações sobre a build do software

__tempoatual            = %t
__quadvalorano          = (__tempoatual+31536000)/126230400
__quadrestoano          = (__tempoatual+31536000)-(126230400*__quadvalorano)
__quadsecaoano          = __quadrestoano/31536000
__ano                   = 1969+(__quadvalorano*4)+__quadsecaoano-(__quadsecaoano shr 2)
__anobissexto           = __quadsecaoano/3
__segundosano           = __quadrestoano-31536000*(__quadsecaoano-__quadsecaoano/4)
__diaano                = __segundosano/86400
__diaanotemp            = __diaano

if (__diaanotemp>=(59+__anobissexto))

  __diaanotemp  = __diaanotemp+3-__anobissexto

end if

if (__diaanotemp>=123)

  __diaanotemp = __diaanotemp+1

end if

if (__diaanotemp>=185)

  __diaanotemp = __diaanotemp+1

end if

if (__diaanotemp>=278)

  __diaanotemp = __diaanotemp+1

end if

if (__diaanotemp>=340)

  __diaanotemp = __diaanotemp+1

end if

__mes          = __diaanotemp/31+1
__dia          = __diaanotemp-__mes*31+32
__segundosdia  = __segundosano-__diaano*86400
__hora         = __segundosdia/3600
__horasegundos = __segundosdia-__hora*3600
__minuto       = __horasegundos/60
__segundo      = __horasegundos-__minuto*60

__stringano     equ (__ano/1000+'0'),((__ano mod 1000)/100+'0'),((__ano mod 100)/10+'0'),((__ano mod 10)+'0')
__stringmes     equ (__mes/10+'0'),((__mes mod 10)+'0')
__stringdia     equ (__dia/10+'0'),((__dia mod 10)+'0')
__stringhora    equ (__hora/10+'0'),((__hora mod 10)+'0')
__stringminuto  equ (__minuto/10+'0'),((__minuto mod 10)+'0')
__stringsegundo equ (__segundo/10+'0'),((__segundo mod 10)+'0')

;;************************************************************************************
