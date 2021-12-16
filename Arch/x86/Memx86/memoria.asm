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
;;
;;                    Este arquivo faz parte do Kernel Hexagon® 
;;
;;************************************************************************************

use16

;;************************************************************************************

;; Obtem a quantidade total de memória instalada em ambiente de modo real

Hexagon.Kernel.Arch.x86.Memx86.Memoria.obterMemoriaTotal:

	push edx
	push ecx
	push ebx

	xor eax, eax
	xor ebx, ebx
	
	mov ax, 0xE801
	
	xor dx, dx
	xor cx, cx
	
	int 15h
	
	jnc .processar
	
	xor eax, eax
	
	jmp .fim         ;; Erro                                  

.quantificar:

	mov si, ax
	
	or si, bx
	jne .quantificar
	
	mov ax, cx
	mov bx, dx

.processar:

	cmp ax, 0x3C00
	jb .abaixoDe16MB
	
	movzx eax, bx
	
	add eax, 100h
	
	shl eax, 16      ;; EAX = EAX * 65536
	
	jmp .fim

.abaixoDe16MB:

	shl eax, 10      ;; EAX = EAX * 1024

.fim:

	pop ebx
	pop ecx
	pop edx
	
	mov dword[Hexagon.Memoria.memoriaTotal], eax ;; Fornecer memória total, em bytes
	
	ret
