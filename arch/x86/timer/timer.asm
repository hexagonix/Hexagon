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
;; BSD 3-Clause License
;;
;; Copyright (c) 2015-2022, Felipe Miguel Nery Lunkes
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
