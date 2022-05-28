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

;; Arquitetura do Hexagon® 
;;
;; A arquitetura pode ser:
;;
;; 1 - i386
;; 2 - x86_x64
;; 3... Outras arquiteturas (futuras implementações?)

Hexagon.Arquitetura.suporte = 1 ;; Arquitetura desta imagem

Hexagon.Versao.definicao equ "9.3"

Hexagon.Versao:

.numeroVersao     = 9
.numeroSubversao  = 3
.caractereRevisao = "?"
.nomeKernel:      db "Hexagon(R)", 0

Hexagon.Info:

.sobreHexagon:    db 10, 10
                  db "Kernel Hexagon(R) versao ", Hexagon.Versao.definicao, 10
                  db "Copyright (C) 2016-2022 Felipe Miguel Nery Lunkes", 10
                  db "Todos os direitos reservados.", 0

;;************************************************************************************

;; Retorna para os aplicativos solicitantes os número de versão e subversão do Sistema
;;
;; Saída:
;; 
;; EAX - Número da versão do Sistema
;; EBX - Número da subversão do Sistema
;; CH  - Revisão
;; EDX - Arquitetura
;; ESI - String de nome

Hexagon.Kernel.Kernel.Versao.retornarVersao:

	mov eax, Hexagon.Versao.numeroVersao
	mov ebx, Hexagon.Versao.numeroSubversao
	mov ch, Hexagon.Versao.caractereRevisao
    mov edx, Hexagon.Arquitetura.suporte
	mov esi, Hexagon.Versao.nomeKernel
	
	ret
    