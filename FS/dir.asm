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

;;************************************************************************************

;; Variáveis, contantes e estruturas necessárias para o gerenciamento de 
;; diretórios do Sistema de Arquivos Virtual

Hexagon.VFS.Diretorio:

.codigo:                     db 0
.deslocamento:               db 0
.estado:                     db 0
.diretorioAtual: times 64    db " "
.diretorioAnterior: times 64 db 0
.tamanhoCaminho              equ 64

Hexagon.VFS.Montagem:

.pontoMontagem: times 64   db " "
.usuarioMontagem: times 32 db 0
.estado:                   db 0
.codigoUsuario:            db 0
.ultimoErro:               db 0

;;************************************************************************************

;; Define um diretório  atual para uso no Sistema de Arquivos
;; 
;; Entrada:
;;
;; ESI - Caminho completo do diretório à ser utilizado. O caminho deve ter 1 ou mais
;; caracteres, no mínimo
;;
;; Saída:
;;
;; EAX - Código de erro, dos quais:
;;       - 01h: Diretório não encontrado no Sistema de Arquivos.
;;       - 02h: O nome de diretório não bate com as exigências.
;;       - 03h: Erro desconhecido durante a requisição.
;; EBX - Tamanho do caminho fornecido
;; CF definido em caso de erro

Hexagon.Kernel.FS.Dir.definirDiretorioAtual:

    push esi ;; Primeiro, salvar o caminho fornecido na chamada

;; Agora o tamanho do caminho fornecido será validado para verificar a exigência

    call Hexagon.Kernel.Lib.String.tamanhoString ;; Função do Hexagon® para verificar o tamanho de uma string

    cmp eax, 2
    jg .continuar ;; Maior que 2 (Caractere mais null)

    cmp eax, 65
    jl .continuar ;; Menor que 64

    pop esi

    mov ebx, eax
    mov eax, 02h

    stc

    jmp .fim

.continuar: ;; As exigências foram sanadas, continuar com o processo

;; Primeiro, copiar o caminho do diretório atual para diretório anterior

    mov esi, Hexagon.VFS.Diretorio.diretorioAtual ;; Armazena esse dado

    call Hexagon.Kernel.Lib.String.tamanhoString

    mov ecx, eax
    
    inc ecx
    
;; Copiar o caminho agora
    
    mov edi, Hexagon.VFS.Diretorio.diretorioAnterior
    
    mov esi, Hexagon.VFS.Diretorio.diretorioAtual

    rep movsb       ;; Copiar (ECX) caracteres de ESI para EDI
    
;; Agora sim, preencher a variável com o valor fornecido

    pop esi

    call Hexagon.Kernel.Lib.String.tamanhoString

    mov ecx, eax
    
    inc ecx
    
;; Copiar agora o nome fornecido para o local adequado
    
    mov edi, Hexagon.VFS.Diretorio.diretorioAtual
    
    rep movsb       ;; Copiar (ECX) caracteres de ESI para EDI
    
    clc

.fim:

    ret

;;************************************************************************************

;; Obtêm o valor de diretório atual, para ser utilizado pelo usuário e pelo
;; Sistema de Arquivos Virtual
;;
;; Saída:
;;
;; ESI - Caminho do diretório atual
;; EDI - Caminho do diretório anterior (antes da última alteração)

Hexagon.Kernel.FS.Dir.obterDiretorioAtual:

;; Primeiro, resgatar o caminho de diretório atual para ESI

    mov esi, Hexagon.VFS.Diretorio.diretorioAtual

;; Agora, o caminho do diretório anterior, para EDI

    mov edi, Hexagon.VFS.Diretorio.diretorioAnterior

    ret

;;************************************************************************************

;; Define o ponto de montagem atual em um diretório ou na raiz do disco
;;
;; Entrada:
;;
;; ESI - Caminho para o ponto de montagem atual no disco
;; 
;; Saída:
;;
;; EAX - Código de erro, dos quais:
;;       - 01h: Diretório não encontrado no Sistema de Arquivos.
;;       - 02h: O nome de diretório não bate com as exigências.
;;       - 03h: Erro desconhecido durante a requisição.
;; CF definido em caso de erro

Hexagon.Kernel.FS.Dir.definirPontodeMontagem:

    push esi ;; Primeiro, salvar o caminho fornecido na chamada

;; Agora o tamanho do caminho fornecido será validado para verificar a exigência

    call Hexagon.Kernel.Lib.String.tamanhoString ;; Função do Hexagon® para verificar o tamanho de uma string

    cmp eax, 2
    jg .continuar ;; Maior que 2 (Caractere mais null)

    cmp eax, 65
    jl .continuar ;; Menor que 64

    pop esi

    stc

    mov eax, 01h

    jmp .fim

.continuar:

;; Agora sim, preencher a variável com o valor fornecido

    pop esi

    call Hexagon.Kernel.Lib.String.tamanhoString

    mov ecx, eax
    
    inc ecx
    
;; Copiar agora o nome fornecido para o local adequado
    
    mov edi, Hexagon.VFS.Montagem.pontoMontagem
    
    rep movsb       ;; Copiar (ECX) caracteres de ESI para EDI

    clc
    
.fim:

    ret

;;************************************************************************************

;; Obtêm o ponto de montagem atual (será expandido quando múltiplos pontos forem
;; suportados pelo Kernel)
;;
;; Saída:
;;
;; ESI - Ponto de montagem
;; EDI - Volume físico montado
;; EAX - Código do Sistema de Arquivos do volume

Hexagon.Kernel.FS.Dir.obterPontodeMontagem:

;; Primeiro, resgatar o volume físico montado, para EDI

    mov ah, byte[Hexagon.Dev.Universal.Disco.Controle.driveAtual]
    
    mov dl, 01h                 ;; Classe de dispositivo de armazenamento
    
    call Hexagon.Kernel.Dev.Dev.paraDispositivo ;; Converter para nome de dispositivo

    mov edi, esi

;; Agora, resgatar o caminho do ponto de montagem para ESI

    mov esi, Hexagon.VFS.Montagem.pontoMontagem

;; Resgatar também o código do Sistema de Arquivos

    mov eax, [Hexagon.VFS.Controle.tipoSistemaArquivos]

    ret

;;************************************************************************************

