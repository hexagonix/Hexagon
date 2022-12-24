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

;; Gerar número pseudo aleatório
;;
;; Entrada:
;;
;; EAX - Máximo
;;
;; Saída:
;;
;; EAX - Número gerado

Hexagon.Kernel.Lib.Num.obterAleatorio:

    mov ecx, eax
    
    mov eax, [.numeroAleatorio]

    push ecx

    movzx ecx, byte[Hexagon.Arch.x86.CMOS.hora]

    add eax, ecx

    movzx ecx, byte[Hexagon.Arch.x86.CMOS.minuto]

    add eax, ecx

    movzx ecx, byte[Hexagon.Arch.x86.CMOS.segundo]

    add eax, ecx

    pop ecx

    mov ebx, 9FA3204Ah
    
    mul ebx
    
    add eax, 15EA5h

    mov [.numeroAleatorio], eax
    
    mov ebx, 10000h
    mov edx, 0
    
    div ebx
    
    mov ebx, ecx
    mov edx, 0
    
    div ebx
    
    mov eax, edx ;; Resto da divisão
    
    ret
    
.numeroAleatorio:   dd 1
    
;;************************************************************************************

;; Alimentar o gerador de números aleatórios
;;
;; Entrada:
;;
;; EAX - Número

Hexagon.Kernel.Lib.Num.alimentarAleatorios:

    mov [Hexagon.Kernel.Lib.Num.obterAleatorio.numeroAleatorio], eax

    ret
    
;;************************************************************************************

;; Realiza a conversão de BCD para binário
;; 
;; Entrada:
;;
;; AL - Valor em BCD
;;
;; Saída:
;;
;; AL - Valor em binário

Hexagon.Kernel.Lib.Num.BCDParaBinario:

    push ebx
    
    mov bl, al    ;; BL = AL mod 16
    and bl, 0x0F 
    shr al, 4     ;; AL = AL / 16
    mov bh, 10
    
    mul bh        ;; Multiplicar por 10
    
    add al, bl    ;; Adicionar a produto a AL
    
    pop ebx
    
    ret