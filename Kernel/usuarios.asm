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

;;************************************************************************************
;;
;;     Controle de usuários e políticas de segurança e acesso do Kernel Hexagon®
;;
;; Este arquivo contém todas as funções de manipulação de usuários, assim como as variáveis
;; relacionadas à estas tarefas. Também contém variáveis de controle de acesso por parte de
;; usuários e sinalizadores de solicitações realizadas pelo Hexagon®, além de definições e
;; padronização de códigos para políticas de segurança. Este é o núcleo de segurança e 
;; proteção de sistema do Hexagon®.
;;
;;************************************************************************************

use32

;;************************************************************************************

Hexagon.Usuarios.ID:

.Hexagon    = 000
.root       = 777
.supervisor = 699
.padrao     = 555

Hexagon.Usuarios.Grupos:

.Hexagon    = 00h
.root       = 01h
.supervisor = 02h
.padrao     = 03h
.admin      = 04h

;;************************************************************************************

;; Define o nome do usuário e seu respectivo ID
;;
;; Entrada:
;;
;; EAX - ID do usuário logado (fornecido por gerenciador de login)
;; ESI - Nome do usuário logado

Hexagon.Kernel.Kernel.Usuarios.definirUsuario:
	
	push eax
	
	push esi
	
	push ds
	pop es
	
	call Hexagon.Kernel.Lib.String.tamanhoString
	
	cmp eax, 32
	jl .nomeValido
	
	stc
	
	ret
	
.nomeValido:
	
	mov ecx, eax
	
	inc ecx
	
;; Copiar o nome do usuário
	
	mov edi, nomeUsuario
	
	pop esi

	rep movsb		;; Copiar (ECX) caracteres de ESI para EDI
	
	pop eax
	
	mov dword [IDUsuario], eax
	
	mov byte[loginFeito], 01h
	
	ret

;;************************************************************************************

;; Retorna para o processo o nome do usuário logado, assim como o ID do usuário
;;
;; Saída:
;;
;; ESI - Nome do usuário logado e registrado
;; EAX - ID do usuário logado

Hexagon.Kernel.Kernel.Usuarios.obterUsuario:

	cmp byte[loginFeito], 00h
	je .fim
	
	mov esi, nomeUsuario ;; Enviar o nome do usuário
	mov eax, [IDUsuario] ;; Enviar o ID de grupo do usuário

.fim:
	
	ret
	
;;************************************************************************************

Hexagon.Kernel.Kernel.Usuarios.verificarUsuario:


;;************************************************************************************

Hexagon.Kernel.Kernel.Usuarios.codificarUsuario:


;;************************************************************************************

Hexagon.Kernel.Kernel.Usuarios.validarUsuario:


;;************************************************************************************

Hexagon.Kernel.Kernel.Usuarios.verificarPermissoes:

	mov eax, [IDUsuario]
	
	cmp eax, Hexagon.Usuarios.ID.root
	je .usuarioRaiz
	
	cmp eax, Hexagon.Usuarios.ID.supervisor
	je .supervisor
	
	mov eax, Hexagon.Usuarios.Grupos.padrao
	
	ret
	
.usuarioRaiz:

	mov eax, Hexagon.Usuarios.Grupos.root
	
	ret
	
.supervisor:

	mov eax, Hexagon.Usuarios.Grupos.supervisor
	
	ret

;;************************************************************************************

;; O sistema de permissões do Sistema trabalha com IDs de usuário. Cada tipo de usuário
;; apresenta um ID específico que será utilizado para verificar a validade de operações
;; solicitadas pelo usuário logado. Os IDs válidos são os designados à seguir:
;;
;; Nome de usuário | ID de usuário |               Permissões               | Tipo de conta
;;
;; Hexagon           000                  Total (Hardware, Software)         Kernel
;; root              777             Leitura, escrita e execução (total)      Raiz
;; supervisor        699             Leitura, escrita e execução (debug)      Raiz
;; Outros nomes      555             Leitura, escrita e execução (parcial)    Comum
;;
;; Os nomes não são levados em conta (exceto root, para serviços de login). O que o Sistema
;; validará são os IDs, onde o de usuário comum pode variar, mas sempre iniciando no número
;; 555 e terminando em 699, no máximo.

IDUsuario:            dd 0 ;; Armazenará o ID do usuário atualmente logado

nomeUsuario: times 32 db 0 ;; Armazenará o nome do usuário atualmente logado

loginFeito:           db 0 ;; Armazena se o login foi ou não realizado

;; O Sistema também poderá alter o estado de permissão de operações solicitadas pelo usuário
;; ou processos. Essas permissões serão armazenadas nas variáveis abaixo.

leitura:  db 0
escrita:  db 0
execucao: db 0

;; Para que o Kernel possa burlar medidas de segurança que distinguam usuários ou valores de entrada
;; e consiga executar qualquer função nele alocada, será utilizada uma variável que indica se a ordem
;; de execução da função partiu do próprio Kernel ou não. Apenas as funções que fazem distinção de
;; privilégios e também de valores de entrada devem ler/gravar nessa variável. 
;; Os valores utilizados também são padronizados, como abaixo.
;;
;; Nome objeto                          | Código |               Tipo de acesso               |
;;
;; ordemKernelDesativada                    00h      O Kernel não está solicitando operações
;;                                                   que demandem acesso restrito ou análise
;; ordemKernelExecutar                      01h           Executar a função solicitada   
;; ordemKernelNegar                         02h       Impedir a execução de qualquer função
;;                                                             até mudança de estado
;; ordemKernelDebug                         04h           Usar futuramente para depuração
;; 
;; O sinalizador ordemKernelExecutar é análogo ao login realizado com a conta de usuário
;; raiz (root), permitindo a realização de tarefas com prerrogativas. Entretanto, permite o
;; acesso a dados e funções não expostas ou permitidas ao usuário raiz.

ordemKernelDesativada = 00h ;; Evidencia que a chamada não foi realizada pelo Hexagon®
ordemKernelExecutar   = 01h ;; Este sinalizador é compatível com o usuário raiz (root)
ordemKernelNegar      = 02h ;; Nega a execução de *QUALQUER* função compatível solicitada
ordemKernelDebug      = 04h ;; Usada para depuração de funções compatíveis

ordemKernel: dd 0 ;; Usado como chave de acesso para executar qualquer função privilegiada
