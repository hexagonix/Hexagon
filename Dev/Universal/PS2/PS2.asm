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

;; Enviar dados ou comandos para o controlador PS/2
;;
;; Entrada:
;;
;; AL - Comando

Hexagon.Kernel.Dev.Universal.PS2.PS2.enviarPS2:

	xchg bl, al		;; Salvar AL

	call Hexagon.Kernel.Dev.Universal.PS2.PS2.esperarEscritaPS2
	
	mov al, 0xD4	;; Estamos enviando um comando
	
	out 0x64, al

	call Hexagon.Kernel.Dev.Universal.PS2.PS2.esperarEscritaPS2	
	
	xchg bl, al		;; Obter AL de novo
	
	out 0x60, al

	ret

;;************************************************************************************

;; Esperar o controlador PS/2 para escrever

Hexagon.Kernel.Dev.Universal.PS2.PS2.esperarEscritaPS2:

	push eax
	
.aguardarLoop:

	in al, 0x64		;; 0x64 é o registrador de estado
	
	bt ax, 1		;; Checar segundo bit para torná-lo 0
	jnc .OK
	
	jmp .aguardarLoop
	
.OK:

	pop eax
	
	ret

;;************************************************************************************

;; Esperar o controlador PS/2 para ler	

Hexagon.Kernel.Dev.Universal.PS2.PS2.esperarLeituraPS2:

	push eax
	
.aguardarLoop:

	in al, 0x64	
	
	bt ax, 0		;; Checar primeiro bit para torná-lo 1
	jc .OK
	
	jmp .aguardarLoop
	
.OK:

	pop eax
	
	ret

;;************************************************************************************
