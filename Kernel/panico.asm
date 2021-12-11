;;************************************************************************************
;;
;;    
;;        %#@$%    &@$%$                  Kernel Hexagon®
;;        #$@$@    #@#@$
;;        @#@$%    %#$#%
;;        @#$@$    #@#$@
;;        #@#$$#$#%!@#@#     Copyright © 2016-2021 Felipe Miguel Nery Lunkes
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
;;                  Copyright © 2016-2021 Felipe Miguel Nery Lunkes                
;;                          Todos os direitos reservados.                    
;;                                                                   
;;************************************************************************************
;;
;;                    Este arquivo faz parte do Kernel Hexagon® 
;;
;;************************************************************************************

use32

;;************************************************************************************

Hexagon.Panico:

.cabecalhoPanico:  db 10, 10, "Panico no Kernel: ", 0	
.cabecalhoOops:    db 10, 10, "Kernel Oops: ", 0	 
.erroReiniciar:    db "Reinicie seu computador para continuar.", 0	
.erroNaoFatal:     db "Pressione qualquer tecla para continuar...", 0
.erroDesconhecido: db 10, 10, "A gravidade do erro nao foi fornecida ou e desconhecida pelo Sistema.", 10, 10, 0		 
	
;;************************************************************************************

;; Exibe mensagem de erro na tela e solicita o reinício do computador 
;;
;; Entrada:
;;
;; EAX - O erro é fatal? (0 para não e 1 para sim)
;; ESI - Mensagem de erro complementar 

Hexagon.Kernel.Kernel.Panico.panico:

	push esi
	push eax
	
	call Hexagon.Kernel.Kernel.Panico.prepararPanico
	
	mov esi, Hexagon.Info.sobreHexagon
	
	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirString
	
	pop eax
	
	cmp eax, 0         ;; Caso o erro não seja fatal, o controle pode ser devolvido à função que chamou 
	je .naoFatal
	
	cmp eax, 1
	je .fatal
	
	jmp .desconhecido

.fatal:
	
	mov esi, Hexagon.Panico.cabecalhoPanico
	
	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirString

match =SIM, VERBOSE {

	mov ebx, Hexagon.Relatorio.Prioridades.p4

	call Hexagon.Kernel.Kernel.Relatorio.criarMensagemHexagon

}

	pop esi
	
	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirString

match =SIM, VERBOSE {

	mov ebx, Hexagon.Relatorio.Prioridades.p4

	call Hexagon.Kernel.Kernel.Relatorio.criarMensagemHexagon

}

	mov esi, Hexagon.Panico.erroReiniciar
	
	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirString
	
	hlt
	
	jmp $

.naoFatal:

	mov esi, Hexagon.Panico.cabecalhoOops
	
	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirString

match =SIM, VERBOSE {

	mov ebx, Hexagon.Relatorio.Prioridades.p4

	call Hexagon.Kernel.Kernel.Relatorio.criarMensagemHexagon

}

	pop esi
	
	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirString

match =SIM, VERBOSE {

	mov ebx, Hexagon.Relatorio.Prioridades.p4

	call Hexagon.Kernel.Kernel.Relatorio.criarMensagemHexagon

}

	mov esi, Hexagon.Panico.erroNaoFatal
	
	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirString
	
	call Hexagon.Kernel.Dev.Universal.Teclado.Teclado.aguardarTeclado
	
	ret
	
.desconhecido:

    mov esi, Hexagon.Panico.erroDesconhecido

    call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirString

    ret	
	
;;************************************************************************************

;; Rotina que prepara a saída de vídeo padrão para a exibição de informações em caso de
;; erro grave no Sistema

Hexagon.Kernel.Kernel.Panico.prepararPanico:

	mov esi, Hexagon.Dev.Dispositivos.vd1 ;; Primeiro, Hexagon.Kernel.Dev.Dev.fechar vd1

	call Hexagon.Kernel.Dev.Dev.fechar

	mov esi, Hexagon.Dev.Dispositivos.vd0 ;; Abrir a saída de vídeo padrão

	call Hexagon.Kernel.Dev.Dev.abrir

	mov eax, 0xFFFFFF  ;; BRANCO_ANDROMEDA
	mov ebx, 0x4682B4  ;; AZUL_METALICO
	
	call Hexagon.Kernel.Dev.Universal.Console.Console.definirCorTexto
	
	call Hexagon.Kernel.Dev.Universal.Console.Console.limparConsole    ;; Limpar saída de vídeo padrão
	
	mov dx, 0
	
	call Hexagon.Kernel.Dev.Universal.Console.Console.posicionarCursor

	ret                ;; Retornar à rotina principal
			   