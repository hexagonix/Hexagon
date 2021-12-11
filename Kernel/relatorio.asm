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

Hexagon.Relatorio:

.dataInicio:                  db "Inicializacao do Sistema: ", 0
.infoData:                    db " [CMOS]", 0
.identificadorHexagon:        db "[Hexagon] ", 0
.identificadorUsuarioInicial: db "[PID: ", 0
.identificadorUsuarioFinal:   db "] ", 0
.novaLinha:                   db 10, 0

Hexagon.Relatorio.Prioridades:

;; Lista de prioridades do Kernel:
;;
;; 0 - Interromper a execução do processo atual e exibir uma mensagem (a ser implementado).
;; 1 - Não interromper o processamento e exibir a mensagem apenas, interrompendo a execução de
;;     qualquer processo (a ser implementado).
;; 2 - Exibir a mensagem apenas de algum utilitário realizar uma chamada de solicitação
;;     (a ser implementado).
;; 3 - Mensagem relevante apenas ao Kernel (a ser implementado).
;; 4 - Enviar a mensagem apenas via serial, para fins de debug (verbose).
;; 5 - Enviar a mensagem na saída padrão e por via serial.

.p0 = 0
.p1 = 1
.p2 = 2
.p3 = 3
.p4 = 4
.p5 = 5

;;************************************************************************************

Hexagon.Kernel.Kernel.Relatorio.iniciarRelatorio:

    call Hexagon.Kernel.Lib.Graficos.usarBufferKernel
    
    mov esi, Hexagon.Info.sobreHexagon
    
    call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirString
    
    call Hexagon.Kernel.Kernel.Relatorio.dataParaRelatorio
    
    call Hexagon.Kernel.Kernel.Relatorio.horaParaRelatorio
    
    call Hexagon.Kernel.Lib.Graficos.usarBufferVideo1
    
    ret
    
;;************************************************************************************

;; Esta função permite adicionar uma mensagem no relatório do Kernel

Hexagon.Kernel.Kernel.Relatorio.adicionarMensagem:

	call Hexagon.Kernel.Lib.Graficos.usarBufferKernel
	
	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirString
	
	call Hexagon.Kernel.Lib.Graficos.usarBufferVideo1
	
	ret

;;************************************************************************************

Hexagon.Kernel.Kernel.Relatorio.dataParaRelatorio:

	push eax
    push ebx
    push esi

    mov esi, Hexagon.Relatorio.dataInicio
    
    call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirString
                                     
    call Hexagon.Kernel.Arch.x86.CMOS.CMOS.obterDadosCMOS                         

    mov al, [Hexagon.Arch.x86.CMOS.dia]   
                         
    call BCDParaASCII
    
    push eax
        
    call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirCaractere
    
    pop eax
    
    mov al, ah
    
    call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirCaractere
    
    mov al, '/'
   
    call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirCaractere

    mov al, [Hexagon.Arch.x86.CMOS.mes]
    
    call BCDParaASCII
    
    push eax
      
    call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirCaractere
    
    pop eax
    
    mov al, ah
    
    call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirCaractere

    mov al, '/'
   
    call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirCaractere
   
    mov al, [Hexagon.Arch.x86.CMOS.seculo]
   
    call BCDParaASCII
   
    push eax
   
    call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirCaractere
   
    pop eax
   
    mov al, ah
   
    call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirCaractere
   
    mov al, [Hexagon.Arch.x86.CMOS.ano]
   
    call BCDParaASCII
   
    push eax
   
    call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirCaractere
   
    pop eax
   
    mov al, ah
   
    call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirCaractere
   
    pop esi   
    pop ebx   
    pop eax
       
    ret

;;************************************************************************************

Hexagon.Kernel.Kernel.Relatorio.horaParaRelatorio:

	push eax
    push ebx
    push esi

    mov al, ' '
    
    call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirCaractere
                                     
    call Hexagon.Kernel.Arch.x86.CMOS.CMOS.obterDadosCMOS                         

    mov al, [Hexagon.Arch.x86.CMOS.hora]   
                         
    call BCDParaASCII
    
    push eax
    
    call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirCaractere
    
    pop eax
    
    mov al, ah
    
    call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirCaractere
    
    mov al, ':'
   
    call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirCaractere

    mov al, [Hexagon.Arch.x86.CMOS.minuto]
    
    call BCDParaASCII
    
    push eax
      
    call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirCaractere
    
    pop eax
    
    mov al, ah
    
    call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirCaractere

    mov al, ':'
   
    call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirCaractere
   
    mov al, [Hexagon.Arch.x86.CMOS.segundo]
   
    call BCDParaASCII
   
    push eax
   
    call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirCaractere
   
    pop eax
   
    mov al, ah
   
    call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirCaractere
   
	mov esi, Hexagon.Relatorio.infoData
	
	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirString
	
    pop esi
    pop ebx
    pop eax
    
    ret

;;************************************************************************************

;; Essa função é responsável por receber e exibir uma mensagem originada no próprio
;; Hexagon® ou como um alerta relevante de daemons ou aplicativos

;; Entrada:
;;
;; ESI - Mensagem completa a ser exibida
;; EAX - Código, se houver
;; EBX - Prioridade

;; Se a prioridade for superior ou igual a 4, as mensagens serão enviadas apenas via porta serial.

Hexagon.Kernel.Kernel.Relatorio.criarMensagemHexagon:

    cmp ebx, Hexagon.Relatorio.Prioridades.p4
    je .apenasSaidaSerial

    cmp ebx, 05h
    je .envioPadrao

    ret ;; Por enquanto, só essas opções são válidas

.envioPadrao:

	push esi

    cmp byte[Hexagon.API.Controle.chamadaSistema], 01h
    je .processoUsuario

.mensagemHexagon:

	mov esi, Hexagon.Relatorio.identificadorHexagon
	
    call mensagemHexagonParaSerial

	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirString

    jmp .mensagemRecebida

.processoUsuario:

    mov esi, Hexagon.Relatorio.identificadorUsuarioInicial
	
    call mensagemHexagonParaSerial

    call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirString

;; O PID do processo será exibido na tela

    movzx eax, word[Hexagon.Processos.PID] ;; Obter o PID

    call Hexagon.Kernel.Lib.String.paraString ;; Transformar em uma string
    
    call mensagemHexagonParaSerial

    call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirString

    mov esi, Hexagon.Relatorio.identificadorUsuarioFinal
	
    call mensagemHexagonParaSerial

	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirString

    jmp .mensagemRecebida

.mensagemRecebida:

	pop esi

    call mensagemHexagonParaSerial

	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirString

    mov esi, Hexagon.Relatorio.novaLinha

    call mensagemHexagonParaSerial

	call Hexagon.Kernel.Dev.Universal.Console.Console.imprimirString

	ret

.apenasSaidaSerial:

    push esi

    cmp byte[Hexagon.API.Controle.chamadaSistema], 01h
    je .serialProcessoUsuario

.serialMensagemHexagon:

	mov esi, Hexagon.Relatorio.identificadorHexagon
	
    call mensagemHexagonParaSerial

    jmp .serialMensagemRecebida

.serialProcessoUsuario:

    mov esi, Hexagon.Relatorio.identificadorUsuarioInicial
	
    call mensagemHexagonParaSerial

;; O PID do processo será exibido na tela

    movzx eax, word[Hexagon.Processos.PID] ;; Obter o PID

    call Hexagon.Kernel.Lib.String.paraString ;; Transformar em uma string

    call mensagemHexagonParaSerial

    mov esi, Hexagon.Relatorio.identificadorUsuarioFinal
	
    call mensagemHexagonParaSerial

.serialMensagemRecebida:

    pop esi

    call mensagemHexagonParaSerial

    mov esi, Hexagon.Relatorio.novaLinha

    call mensagemHexagonParaSerial

    ret

;;************************************************************************************

;; Essa função é responsável por enviar as mensagens recebida pelo Hexagon para a porta
;; serial padrão inicializada durante a inicialização (COM1). Útil para debug em tempo de
;; execução

;; Entrada:
;;
;; ESI - Mensagem completa a ser exibida

mensagemHexagonParaSerial:

    push esi ;; Primeiro, salvar a mensagem já presente em ESI para uso futuro em
             ;; Hexagon.Kernel.Kernel.Relatorio.criarMensagemHexagon
    
    mov esi, Hexagon.Dev.Dispositivos.com1

    call Hexagon.Kernel.Dev.Dev.abrir

    pop esi
    push esi

    call Hexagon.Kernel.Dev.Dev.escrever

    pop esi

    ret

;;************************************************************************************