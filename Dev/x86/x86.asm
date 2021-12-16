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

;; Os códigos à seguir são dependentes de arquitetura

codigoDispositivos:

;; Dispositivos de armazenamento

.hd0:    db 80h
.hd1:    db 81h
.hd2:    db 82h
.hd3:    db 83h

;; Portas seriais

.com1:   dw 3F8h
.com2:   dw 2F8h
.com3:   dw 3E8h
.com4:   dw 2E8h

;; Portas paralelas e impressoras

.imp0:   dw 3BCh
.imp1:   dw 378h
.imp2:   dw 278h

;; Dispositivos de saída

.vd0:    dw 44h ;; Vídeo
.vd1:    dw 45h ;; Vídeo
.vd2:    dw 46h ;; Vídeo

;; Dispositivos de entrada

.mouse0: dw 51h
.tecla0: dw 52h

;; Processadores:

.proc0: times 100 db 0

;; Dispositivo de som

.au0:    dw 10h ;; Áudio
