;;************************************************************************************
;;
;;    
;;        %#@$%    &@$%$                  Kernel Hexagon®
;;        #$@$@    #@#@$
;;        @#@$%    %#$#%
;;        @#$@$    #@#$@
;;        #@#$$#$#%!@#@#     Copyright © 2016-2023 Felipe Miguel Nery Lunkes
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

