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

use32

;; Emite um som utilizando o alto-falante interno do computador
;;
;; Entrada:
;;
;; AX - Tom à ser reproduzido

Hexagon.Kernel.Dev.Universal.Som.Som.emitirSom:       ;; Mova para AX o tom a ser emitido pelo sistema

    pushad

	mov cx, ax	 ;; Som a ser emitido		

	mov al, 182  ;; Dado a ser enviado
	
	out 43h, al  
	
	mov ax, cx		
	
	out 42h, al
	
	mov al, ah
	
	out 42h, al

	in al, 61h		
	
	or al, 03h
	
	out 61h, al

	popad
	
	ret
	
;;*******************************************************************
	
;; Desabilita o alto-falante interno do computador
	
Hexagon.Kernel.Dev.Universal.Som.Som.desligarSom:    ;; Desliga o alto-falante interno do computador

	pushad

	in al, 61h
	
	and al, 0FCh
	
	out 61h, al

	popad
	
	ret	
	
;;*******************************************************************
