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

;; Inicializa a porta paralela, utilizando o número da porta fornecido

Hexagon.Kernel.Dev.Universal.Impressora.Impressora.iniciarImpressora:
    
    pusha
    
;; Reiniciar porta através do registrador de controle (base+2)
    
    mov dx, word[portaParalelaAtual]
    
    add dx, 2           ;; Registro de controle (base+2)
    
    in al, dx
    
    mov al, 00001100b   
    
;; Bit 2 - Reiniciar porta
;; Bit 3 - Selecionar impressora
;; Bit 5 - Habilitar porta bi-direcional

    out dx, al          ;; Enviar sinal de reinício
    
    popa
        
    ret

;;************************************************************************************  

Hexagon.Kernel.Dev.Universal.Impressora.Impressora.enviarImpressora: ;; Função que permite o envio de dados para serem impressos em uma impressora paralela

    lodsb                      ;; Carrega o próximo caractere à ser enviado

    or al, al                  ;; Compara o caractere com o fim da mensagem
    jz .pronto                 ;; Se igual ao fim, pula para .pronto

    call Hexagon.Kernel.Dev.Universal.Impressora.Impressora.realizarEnvioImpressora ;; Chama  função que irá executar a entrada e saída

    jc .falhaImpressora

    jmp Hexagon.Kernel.Dev.Universal.Impressora.Impressora.enviarImpressora       ;; Se não tiver acabado, volta à função e carrega o próximo caractere

.pronto:                       ;; Se tiver acabado...

    ret                        ;; Retorna ao processo que o chamou  

.falhaImpressora:

    stc   ;; Definir Carry

    ret

;;************************************************************************************  

;; Enviar dados para a porta paralela onde a impressora deve estar conectada
;;
;; Entrada:
;;
;; AL - byte para enviar

Hexagon.Kernel.Dev.Universal.Impressora.Impressora.realizarEnvioImpressora:

    pusha
    
    push ax             ;; Salvar o byte fornecido em AL
    
;; Reiniciar porta através do registrador de controle (base+2)
    
    mov dx, word[portaParalelaAtual]
    
    add dx, 2           ;; Registro de controle (base+2)
    
    in al, dx
    
    mov al, 00001100b   
    
;; Bit 2 - Reiniciar porta
;; Bit 3 - Selecionar impressora
;; Bit 5 - Habilitar porta bi-direcional

    out dx, al          ;; Enviar sinal de reinício
    
;; Enviar dados para a porta via registrador de dados (base+0)
    
    pop ax              ;; Restaurar dado passado em AL
    
    mov dx, word[portaParalelaAtual]
    
    out dx, al          ;; Enviar dados
    
;; Enviar sinalização para registrador de controle (base+2), mostrando que os dados
;; estão disponíveis
    
    mov dx, word [portaParalelaAtual]
    
    add dx, 2

    mov al, 1           
    
;; Bit 0 - sinal
    
    out dx, al          ;; Enviar
    
    popa
    
    ret

;;************************************************************************************  

portaParalelaAtual dw 0         ;; Armazena o endereço de entrada e saída do dispositivo
