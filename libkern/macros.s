;;************************************************************************************
;;
;;    
;;        %#@$%    &@$%$                  Kernel Hexagon®
;;        #$@$@    #@#@$
;;        @#@$%    %#$#%
;;        @#$@$    #@#$@
;;        #@#$$#$#%!@#@#     Copyright © 2015-2023 Felipe Miguel Nery Lunkes
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
;; BSD 3-Clause License
;;
;; Copyright (c) 2015-2023, Felipe Miguel Nery Lunkes
;; All rights reserved.
;; 
;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions are met:
;; 
;; 1. Redistributions of source code must retain the above copyright notice, this
;;    list of conditions and the following disclaimer.
;;
;; 2. Redistributions in binary form must reproduce the above copyright notice,
;;    this list of conditions and the following disclaimer in the documentation
;;    and/or other materials provided with the distribution.
;;
;; 3. Neither the name of the copyright holder nor the names of its
;;    contributors may be used to endorse or promote products derived from
;;    this software without specific prior written permission.
;; 
;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
;; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
;; DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
;; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
;; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
;; SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
;; CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
;; OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
;; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;;
;; $HexagonixOS$

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
