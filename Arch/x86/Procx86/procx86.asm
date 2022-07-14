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

struc Hexagon.Arch.x86.Regs 

{

.registradorAX:    dw 0
.registradorBX:    dw 0
.registradorCX:    dw 0
.registradorDX:    dw 0
.registradorSI:    dw 0
.registradorDI:    dw 0
.registradorEBP:   dd 0
.registradorESP:   dd 0
.registradorFlags: dd 0

}

;;************************************************************************************

;; Comuta o processador para o modo protegido 32 bits

Hexagon.Kernel.Arch.x86.Procx86.Procx86.irPara32:

use16	
				
	cli

	pop bp          ;; Endereço de retorno
	
;; Carregar descriptores

	lgdt[GDTReg]    ;; Carregar GDT
	
	lidt[IDTReg]    ;; Carregar IDT

;; Agora iremos entrar em modo protegido

	mov eax, cr0
	or eax, 1       ;; Comutar para modo protegido - bit 1
	mov cr0, eax

;; Retornar

	push 0x08       ;; Novo CS
	push bp         ;; Novo IP
	
	retf

;;************************************************************************************

use32

;; Comuta o processador de volta ao modo real

Hexagon.Kernel.Arch.x86.Procx86.Procx86.irPara16:				
	
	cli			             ;; Limpar interrupções
	
	pop edx		             ;; Salvar local de retorno em EDX
	
	jmp 0x20:Hexagon.Kernel.Arch.x86.Procx86.Procx86.modoProtegido16 ;; Carregar CS com seletor 0x20

;; Para ir ao modo real 16 bits, temos de passar pelo modo protegido 16 bits

use16				

Hexagon.Kernel.Arch.x86.Procx86.Procx86.modoProtegido16:

	mov ax, 0x28		;; 0x28 é o seletor de modo protegido 16-bit
	mov ss, ax	
	mov sp, 0x5000		;; Pilha

	mov eax, cr0
	and eax, 0xfffffffe	;; Limpar bit de ativação do modo protegido em cr0
	mov cr0, eax		;; Desativar modo 32 bits

	jmp 0x50:Hexagon.Kernel.Arch.x86.Procx86.Procx86.modoReal	;; Carregar CS e IP

Hexagon.Kernel.Arch.x86.Procx86.Procx86.modoReal:

;; Carregar registradores de segmento com valores de 16 bits

	mov ax, 0x50
	mov ds, ax
	mov ax, 0x6000
	mov ss, ax
	mov ax, 0
	mov es, ax
	mov sp, 0
	
	cli
	
	lidt[.idtR]		    ;; Carregar tabela de vetores de interrupção de modo real
	
	sti
	
	push 0x50
	push dx			    ;; Retornar para a localização presente em EDX
	
	retf			    ;; Iniciar modo real

;; Tabela de vetores de interrupção de modo real

.idtR:	dw 0xffff       ;; Limite
     	dd 0            ;; Base

;;************************************************************************************
		
Hexagon.Kernel.Arch.x86.Procx86.Procx86.ativarA20:  

match =A20NAOSEGURO, A20
{

;; Aqui temos um método para checar se o A20 está habilitado. Entretanto, o código
;; parece gerar erros dependendo da plataforma (máquina física, KVM, etc)

 .testarA20:
	
	mov edi, 0x112345  ;; Endereço par
	mov esi, 0x012345  ;; Endereço ímpar
	mov [esi], esi     ;; Os dois endereços apresentam valores diferentes
	mov [edi], edi     

;; Se A20 não definido, os dois ponteiros apontarão para 0x012345, que contêm 0x112345 (EDI) 

	cmpsd             ;; Comparar para ver se são equivalentes
	
	jne .A20Pronto    ;; Se não, o A20 já está habilitado

}

;; Aqui temos o método mais seguro de ativar a linha A20

.habilitarA20:

	mov ax, 0x2401  ;; Solicitar a ativação do A20
        
	int 15h         ;; Interrupção do BIOS

.A20Pronto:

	ret

;;************************************************************************************
		
use32					

Hexagon.Kernel.Arch.x86.Procx86.Procx86.configurarProcessador:

;; Habilitar SSE
	
	mov eax, cr0
	or eax, 10b			      ;; Monitor do coprocessador
	and ax, 1111111111111011b ;; Desativar emulação do coprocessador
	mov cr0, eax
	
	mov eax, cr4
	
;; Exceções de ponto flutuante
	
	or ax, 001000000000b
	or ax, 010000000000b
	mov cr4, eax

;; Agora vamos iniciar a unidade de ponto flutuante 
	
	finit
	fwait 

	ret

;;************************************************************************************

Hexagon.Kernel.Arch.x86.Procx86.Procx86.identificarProcessador:
 
	mov esi, codigoDispositivos.proc0

	mov edi, 0x80000002

	mov ecx, 3

.loopIdentificar:

	push ecx
	
	mov eax, edi
	
	cpuid
	
	mov [esi], eax
	mov [esi+4], ebx
	mov [esi+8], ecx
	mov [esi+12], edx

	add esi, 16
	
	inc edi
	
	pop ecx
	
	loop .loopIdentificar	
	
	mov eax, 0
	mov [esi+1], eax
	
	ret

;;************************************************************************************

use32

;;************************************************************************************
;;
;;            GDT (Tabela de Descriptores Global - Global Descriptor Table)
;;
;;************************************************************************************

;; O alinhamento aqui deve ser de 32

align 32

GDT:	 

	dd 0, 0       ;; Descriptor nulo

.codigoKernel: 

	dw 0xFFFF  	  ;; Limite (0:15)	
	dw 0x0500	  ;; Base (0:15)
	db 0		  ;; Base (16:23)	
	db 10011010b  ;; Presente=1, Privilégio=00, Reservado=1, Executável=1, C=0, L&E=1, Acessado=0
	db 11001111b  ;; Granularidade=1, Tamanho=1, Reservado=00, Limite (16:19)
	db 0		  ;; Base (24:31)

;; Descriptor de dados com base em 500h

.dadosKernel: 

	dw 0xFFFF	  ;; Limite (0:15)	
	dw 0x0500	  ;; Base (0:15)
	db 0		  ;; Base (16:23)	
	db 10010010b  ;; Presente=1, Privilégio=00, Reservado=1, Executável=0, D=0, W=1, Acessado=0
	db 11001111b  ;; Granularidade=1, Tamanho=1, Reservado=00, Limite (16:19)
	db 0		  ;; Base (24:31)

;; Descriptor de dados com base em 0h

.linearKernel: 

	dw 0xFFFF	  ;; Limite (0:15)	
	dw 0		  ;; Base (0:15)
	db 0		  ;; Base (16:23)	
	db 10010010b  ;; Presente=1, Privilégio=00, Reservado=1, Executável=0, D=0, W=1, Acessado=0
	db 11001111b  ;; Granularidade=1, Tamanho=1, Reservado=00, Limite (16:19)
	db 0		  ;; Base (24:31)

;; Descriptor de código para modo protegido 16 bits

.codigoMP16:     

	dw 0xFFFF	  ;; Limite (0:15)	
	dw 0x0500	  ;; Base (0:15)
	db 0		  ;; Base (16:23)	
	db 10011010b  ;; Presente=1, Privilégio=00, Reservado=1, Executável=1, C=0, L&E=1, Acessado=0
	db 0		  ;; Granularidade=1, Tamanho=1, Reservado=00, Limite (16:19)
	db 0		  ;; Base (24:31)

;; Descriptor de dados para modo protegido 16 bits

.dadosPM16:	     

	dw 0xFFFF	  ;; Limite (0:15)	
	dw 0		  ;; Base (0:15)
	db 0		  ;; Base (16:23)	
	db 10010010b  ;; Presente=1, Privilégio=00, Reservado=1, Executável=0, D=0, W=1, Acessado=0
	db 0		  ;; Granularidade=1, Tamanho=1, Reservado=00, Limite (16:19)
	db 0		  ;; Base (24:31)

;; Código do programa

.codigoPrograma: 

	dw 0xFFFF	  ;; Limite (0:15)	
	dw 0		  ;; Base (0:15)
	db 0		  ;; Base (16:23)	
	db 10011010b  ;; Presente=1, Privilégio=00, Reservado=1, Executável=1, C=0, L&E=1, Acessado=0
	db 11001111b  ;; Granularidade=1, Tamanho=1, Reservado=00, Limite (16:19)
	db 0		  ;; Base (24:31)

;; Dados do programa

.dadosPrograma:	

	dw 0xFFFF	  ;; Limite (0:15)	
	dw 0		  ;; Base (0:15)
	db 0		  ;; Base (16:23)	
	db 10010010b  ;; Presente=1, Privilégio=00, Reservado=1, Executável=0, D=0, W=1, Acessado=0
	db 11001111b  ;; Granularidade=1, Tamanho=1, Reservado=00, Limite (16:19)
	db 0		  ;; Base (24:31)

;; TSS (Task State Segment)

.TSS:

	dw 104        ;; Limite inferior
	dw TSS        ;; Base
	db 0          ;; Base
	db 11101001b  ;; Acesso
	db 0          ;; Bandeiras e limite superior
	db 0          ;; Base

terminoGDT:
	            
GDTReg: 

.tamanho: dw terminoGDT - GDT - 1 ;; Tamanho GDT - 1
.local:	  dd GDT+0x500            ;; Deslocamento da GDT

;;************************************************************************************

;;************************************************************************************
;;
;;     IDT (Tabela de Descriptores de Interrupção - Interrupt Descriptor Table)
;;
;;************************************************************************************

;; Primeiramente todas as interrupções serão redirecionadas para naoManipulado durante a inicialização
;; do Sistema. Após, as interrupções do Sistema serão instaladas, sobrescrevendo naoManipulado.

align 32

IDT: times 256 dw naoManipulado, 0x0008, 0x8e00, 0 

;; naoManipulado: deslocamento (0:15)
;; 0x0008:	0x08 é um seletor
;; 0x8e00:	8 é Presente=1, Prévilégio=00, Tamanho=1, e é interrupção 386, 00 é reservado
;; 0:		Offset (16:31)

terminoIDT:

IDTReg: 

.tamanho: dw terminoIDT - IDT - 1  ;; Tamanho IDT - 1
.local:	  dd IDT+0x500             ;; Deslocamento da IDT

;;************************************************************************************

;;************************************************************************************
;;
;;     TSS (Segmento de Estado da Tarefa - Task State Segment)
;;
;;************************************************************************************

align 32

TSS:

	.tssAnterior dd 0
	.esp0        dd 0x10000	;; Pilha do Kernel
	.ss0         dd 0x10	;; Segmento da pilha do Kernel
	.esp1        dd 0
	.ss1         dd 0
	.esp2        dd 0
	.ss2         dd 0
	.cr3         dd 0
	.eip         dd 0
	.eflags      dd 0
	.eax         dd 0
	.ecx         dd 0
	.edx         dd 0
	.ebx         dd 0
	.esp         dd 0
	.ebp         dd 0
	.esi         dd 0
	.edi         dd 0
	.es          dd 0x10    ;; Segmento de dados do Kernel
	.cs          dd 0x08
	.ss          dd 0x10
	.ds          dd 0x10
	.fs          dd 0x10
	.gs          dd 0x10
	.ldt         dd 0
	.ldtr        dw 0
	.mapaIO      dw 104			
