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

;; Realiza o envio de dados via porta serial
;;
;; Entrada:
;;
;; SI - Ponteiro para o buffer que contêm os dados a serem enviados

Hexagon.Kernel.Dev.Universal.COM.Serial.enviarSerial:    ;; Esse método é usado para transferir dados pela Porta Serial aberta

    lodsb        ;; Carrega o próximo caractere à ser enviado

    or al, al    ;; Compara o caractere com o fim da mensagem
    jz .pronto   ;; Se igual ao fim, pula para .pronto

    call Hexagon.Kernel.Dev.Universal.COM.Serial.serialRealizarEnvio

    jc near .erro

    jmp Hexagon.Kernel.Dev.Universal.COM.Serial.enviarSerial ;; Se não tiver acabado, volta à função e carrega o próximo caractere

.pronto:             ;; Se tiver acabado...

    ret              ;; Retorna a função que o chamou

.erro:

    stc

    ret

;;************************************************************************************
    
;; Bloqueia o envio de dados pela porta serial até  a mesma estar pronta
;; Se pronta, envia um byte
;;
;; Entrada:
;;
;; AL - Byte para enviar
;; BX - Registro contendo o número da porta

Hexagon.Kernel.Dev.Universal.COM.Serial.serialRealizarEnvio:

    pusha
    
    push ax     ;; Salvar entrada do usuário
    
    mov bx, word[portaSerialAtual]
    
serialAguardarEnviar:

    mov dx, bx
    
    add dx, 5   ;; Porta + 5
    
    in al, dx
    
    test al, 00100000b      ;; Bit 5 do Registro de status da linha (Line Status Register)
                            ;; "Registro de espera do transmissor vazio"
                        
    jz serialAguardarEnviar ;; Enquanto não vazio...
    
    pop ax     ;; Restaurar entrada do usuário
    
    mov dx, bx ;; Porta aberta
    
    out dx, al ;; Enviar dados à porta solicitada
    
    popa
    
    ret

;;************************************************************************************

;; Inicializa e abre para leitura e escrita uma determinada porta serial solicitada pelo sistema
;;
;; Entrada:
;;  
;; BX - Registro contendo o número da porta

Hexagon.Kernel.Dev.Universal.COM.Serial.iniciarSerial:

    mov bx, word[portaSerialAtual]
    
    pusha
    
    push ds
    
    push cs
    pop ds
    
    mov al, 0
    mov dx, bx
    
    inc dx          ;; Porta + 1
    
    out dx, al      ;; Desativar interrupções

    mov dx, bx

    add dx, 3       ;; Porta + 3

    mov al, 10000000b   
    
    out dx, al      ;; Habilitar o DLAB (bit mais significativo), para que seja possível
                    ;; iniciar a definição do divisor da taxa de transmissão

;; Bits 7-7 : Habilitar DLAB
;; Bits 6-6 : Parar transmissão enquanto 1
;; Bits 3-5 : Paridade (0=nenhum)
;; Bits 2-2 : Contagem de bit de parada (0=1 bit de parada)
;; Bits 0-1 : Tamanho do caractere (5 a 8)

    mov al, 12
    mov dx, bx      ;; Porta + 0
    
    out dx, al      ;; Byte menos significativo do divisor
    
    mov al, 0
    
    mov dx, bx

    add dx, 1       ;; Porta + 1
    
    out dx, al      ;; Byte mais significante do divisor
                    ;; Isto produz uma taxa de 115200/12 = 9600

    mov al, 11000111b
    mov dx, bx

    add dx, 2       ;; Porta + 2
    
    out dx, al      ;; Manipulador de 14 bytes, habilitar FIFOs
                    ;; Limpar FIFO recebido, limpar FIFO transmitido

;; Bits 7-6 : Nível do manipulador de interrupção
;; Bits 5-5 : Habilitar FIFO de 64 bytes
;; Bits 4-4 : Reservado
;; Bits 3-3 : Seletor de modo DNA
;; Bits 2-2 : Limpar FIFO transmitido
;; Bits 1-1 : Limpar FIFO recebido
;; Bits 0-0 : Habilitar FIFOs
                
    mov al, 00000011b
    mov dx, bx

    add dx, 3       ;; Porta + 3
    
    out dx, al      
    
;; Desativar DLAB, e definir:
;;
;;  - Caractere de tamanho de 8 bits
;;  - Sem paridade
;;  - 1 bit de parada
                    
;; Bits 7-7 : Habilitar DLAB
;; Bits 6-6 : Parar transmissão enquanto 1
;; Bits 3-5 : Paridade (0=nenhum)
;; Bits 2-2 : Contagem de bit de parada (0=1 bit de parada)
;; Bits 0-1 : Tamanho do caractere (5 a 8)

    mov al, 00001011b
    mov dx, bx

    add dx, 4       ;; Porta + 4
    
    out dx, al      ;; Habilitar saída auxiliar 2 (também chamado de "ativar IRQ")

;; Bits 7-6 - Reservado
;; Bits 5-5 - Controle de fluxo automático ativado
;; Bits 4-4 - Modo de loopback
;; Bits 3-3 - Saída auxiliar 2
;; Bits 2-2 - Saída auxiliar 1
;; Bits 1-1 - Solicitação para enviar (RTS)
;; Bits 0-0 - Terminal de dados pronto (DTR)
    
    in al, 21h          ;; Ler bits de máscara IRQ do PIC principal
    
    and al, 11101111b   ;; Habilitar IRQ4, mantendo todos os outros IRQs inalterados
    
    out 21h, al         ;; Escrever bits de máscara de IRQ para PIC principal
    
    mov al, 1
    mov dx, bx

    add dx, 1           ;; Porta + 1
    
    out dx, al          ;; Habilitar interrupções
    
    pop ds
    
    popa
    
    ret

;;************************************************************************************

;; Inicializar a primeira porta serial para debug e emissão de mensagens

Hexagon.Kernel.Dev.Universal.COM.Serial.iniciarCOM1:

    push eax
    push ebx
    push ecx

    mov bx, word[portaSerialAtual]
    mov word[portaSerialAnterior], bx

    mov bx, codigoDispositivos.com1 
    mov word[portaSerialAtual], bx

    call Hexagon.Kernel.Dev.Universal.COM.Serial.iniciarSerial

    mov bx, word[portaSerialAnterior]
    mov word[portaSerialAtual], bx

    pop ecx
    pop ebx
    pop eax

    ret

;;************************************************************************************

portaSerialAtual:    db 0   
portaSerialAnterior: db 0
