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