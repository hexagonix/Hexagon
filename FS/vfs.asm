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
;;        $#$#%    &%$#@          Licenciado sob licença BSD-3-Clause
;;        @#!$$    !#@#@
;;
;;
;;************************************************************************************
;;
;; Este arquivo é licenciado sob licença BSD-3-Clause. Observe o arquivo de licença 
;; disponível no repositório para mais informações sobre seus direitos e deveres ao 
;; utilizar qualquer trecho deste arquivo.
;;
;; Copyright (C) 2016-2022 Felipe Miguel Nery Lunkes
;; Todos os direitos reservados.
                                                                  
;;************************************************************************************
;;
;;                    Este arquivo faz parte do Kernel Hexagon® 
;;
;;************************************************************************************

use32

;;************************************************************************************

;; Códigos dos Sistemas de Arquivo suportados

align 32

;; Códigos para os principais Sistemas de Arquivos, suportados ou não

Hexagon.VFS.FS:

.FAT12    = 01h ;; FAT12 (Futuro)
.FAT16    = 04h ;; FAT16 (< 32 MB)
.FAT16B   = 06h ;; FAT16B (FAT16B) - Suportado
.FAT16LBA = 0Eh ;; FAT16 (LBA)

Hexagon.VFS.Controle:

.tipoSistemaArquivos: db 0 ;; Armazena qual sistema de arquivos está presente no volume  
.rotuloVolume:        db 0
.serialVolume:        db 0

;; Estrutura com as variáveis e constantes comuns para sistemas do tipo FAT
;; Compatível com FAT12, FAT16 e FAT32. Deve ser instanciada em cada aplicação

struc Hexagon.VFS.FAT
{

.bytesPorSetor:        dw 0       ;; Número de bytes por setor
.setoresPorCluster:    db 0       ;; Setores em um cluster
.setoresReservados:    dw 0       ;; Setores reservaos após o setor de inicialização
.totalFATs:            db 0       ;; Número de tabelas FAT
.entradasRaiz:         dw 0       ;; Total de arquivos e pastas no diretório raiz
.setoresPorFAT:        dw 0       ;; Setores usados para armazenar a FAT
.totalSetores:         dd 0       ;; Setores no disco
.tamanhoDirRaiz:       dw 0       ;; Tamanho em setores do diretório raiz
.dirRaiz:              dd 0       ;; Endereço LBA do diretório raiz
.tamanhoFATs:          dw 0       ;; Tamanho em setores da(s) FAT(s)
.FAT:                  dd 0       ;; Endereço LBA da FAT
.areaDeDados:          dd 0       ;; Endereço LBA do início da área de dados
.tamanhoCluster:       dd 0       ;; Tamanho do cluster, em bytes
.atributoOculto        equ 00h    ;; Atributo de um arquivo oculto
.atributoSistema       equ 04h    ;; Atributo de um arquivo marcado como de sistema
.atributoDiretorio     equ 10h    ;; Atributo de um diretório
.atributoLFN           equ 0x0f   ;; Atributo de um nome de arquivo longo (Long File Name)
.atributoDeletado      equ 0xE5   ;; Atributo de arquivo deletado/entrada livre
.atributoUltimoCluster equ 0xFFF8 ;; Atributo de último cluster na cadeia
.bitDiretorio          equ 04h    ;; Bit de um diretório = .atributoDiretorio, mas para bit check
.bitNomeVolume         equ 03h    ;; Bit de um nome (rótulo) de volume

}

;; Estruturas de gerenciamento de arquivos e pontos de montagem do Hexagon®

include "FS/dir.asm"

;;************************************************************************************

;; Criar novo arquivo vazio
;;
;; Entrada:
;; 
;; ESI - Ponteiro para o nome de arquivo
;;
;; Saída:
;;
;; EDI - Ponteiro para a entrada no diretório raiz
;; EAX contendo o código de erro, se cabível
;; CF definido caso o arquivo já exista no disco

Hexagon.Kernel.FS.VFS.novoArquivo:

    call Hexagon.Kernel.Kernel.Usuarios.verificarPermissoes
    
    cmp eax, 03h ;; Código de grupo para usuário padrão
    je .permissaoNegada
    
    mov ah, byte[Hexagon.VFS.Controle.tipoSistemaArquivos]
    
    cmp ah, Hexagon.VFS.FS.FAT16B
    je .novoArquivoFAT16B
    
    ret

.novoArquivoFAT16B:

    call Hexagon.Kernel.FS.FAT16.novoArquivoFAT16B
    
    ret

.permissaoNegada:

    stc
    
    mov eax, 05h
    
    ret
    
;;************************************************************************************

;; Remover um arquivo do disco
;;
;; Entrada:
;;
;; ESI - Ponteiro para o nome de arquivo
;;
;; Saída:
;;
;; EAX - Código de erro, se cabível
;;     - 05h para permissão negada
;; CF definido caso o arquivo não tenha sido encontrado ou tenha nome inválido

Hexagon.Kernel.FS.VFS.deletarArquivo:

    call Hexagon.Kernel.Kernel.Usuarios.verificarPermissoes
    
    cmp eax, 03h ;; Código de grupo para usuário padrão
    je .permissaoNegada
    
    mov ah, byte[Hexagon.VFS.Controle.tipoSistemaArquivos]
    
    cmp ah, Hexagon.VFS.FS.FAT16B
    je .deletarArquivoFAT16B
    
    ret

.deletarArquivoFAT16B:

    call Hexagon.Kernel.FS.FAT16.deletarArquivoFAT16B
    
    ret

.permissaoNegada:

    stc
    
    mov eax, 05h
    
    ret
    
;;************************************************************************************

;; Salvar arquivo no disco
;;
;; Entrada:
;;
;; ESI - Ponteiro para o nome do arquivo
;; EDI - Ponteiro para os dados
;; EAX - Tamanho do arquivo (em bytes)
;;
;; Saída:
;;
;; EAX - Código de erro, se cabível
;; CF definido caso o arquivo não tenha sido encontrado ou tenha nome inválido

Hexagon.Kernel.FS.VFS.salvarArquivo:

    pushad
    
    mov ah, byte[Hexagon.VFS.Controle.tipoSistemaArquivos]
    
    cmp ah, Hexagon.VFS.FS.FAT16B
    je .salvarArquivoFAT16B
    
    popad
    
    ret

.salvarArquivoFAT16B:

    popad
    
    call Hexagon.Kernel.FS.FAT16.salvarArquivoFAT16B
    
    ret

;;************************************************************************************

;; Obter a lista de arquivos no diretório raiz
;; 
;; Saída:
;;
;; ESI - Ponteiro para a lista de arquivos
;; EAX - Número de arquivos total

Hexagon.Kernel.FS.VFS.listarArquivos:

    mov ah, byte[Hexagon.VFS.Controle.tipoSistemaArquivos]
    
    cmp ah, Hexagon.VFS.FS.FAT16B
    je .listarArquivosFAT16B
    
    ret

.listarArquivosFAT16B:

    call Hexagon.Kernel.FS.FAT16.listarArquivosFAT16B
    
    ret
    
;;************************************************************************************

;; Carregar arquivo na memória
;;
;; Entrada:
;;
;; ESI - Nome do arquivo para carregar
;; EDI - Endereço do arquivo a ser carregado
;;
;; Saída:
;;
;; EAX - Tamanho do arquivo em bytes
;; CF definido caso o arquivo não tenha sido encontrado ou tenha nome inválido
    
Hexagon.Kernel.FS.VFS.carregarArquivo:

    mov ah, byte[Hexagon.VFS.Controle.tipoSistemaArquivos]
    
    cmp ah, Hexagon.VFS.FS.FAT16B
    je .carregarArquivoFAT16B
    
    ret

.carregarArquivoFAT16B:

    call Hexagon.Kernel.FS.FAT16.carregarArquivoFAT16B
    
    ret
    
;;************************************************************************************

;; Checar se um arquivo existe no disco
;;
;; Entrada:
;;
;; ESI - Nome do arquivo para checar
;;
;; Saída:
;;
;; EAX - Tamanho do arquivo em bytes
;; EBX - Ponteiro para a entrada no diretório raiz
;; CF definido caso o arquivo não tenha sido encontrado ou tenha nome inválido

Hexagon.Kernel.FS.VFS.arquivoExiste:    
    
    mov ah, byte[Hexagon.VFS.Controle.tipoSistemaArquivos]
    
    cmp ah, Hexagon.VFS.FS.FAT16B
    je .arquivoExisteFAT16B
    
    ret

.arquivoExisteFAT16B:

    call Hexagon.Kernel.FS.FAT16.arquivoExisteFAT16B
    
    ret

;;************************************************************************************

Hexagon.Kernel.FS.VFS.montarVolume:

    mov ah, byte[Hexagon.Dev.Universal.Disco.Controle.driveBoot]
    
    mov dl, 01h                 ;; Classe de dispositivo de armazenamento
    
    call Hexagon.Kernel.Dev.Dev.paraDispositivo ;; Converter para nome de dispositivo

;; Habilitar os privilégios do Kernel para solicitação privilegiada

    mov dword[ordemKernel], ordemKernelExecutar 

    call Hexagon.Kernel.Dev.Dev.abrir ;; Abrir o dispositivo para leitura/escrita com privilégios

;; Desabilitar os privilégios do Kernel, uma vez que já não são necessários

    mov dword[ordemKernel], ordemKernelDesativada 

    ret

;;************************************************************************************
    
;; Define o sistema de arquivos presente no disco atual, obtendo a informação adequada 
;; no MBR (Master Boot Record)

Hexagon.Kernel.FS.VFS.definirSistemaArquivos:
    
    call Hexagon.Kernel.Dev.x86.Disco.Disco.lerMBR

    jc .restaurarVolume 

    mov byte[Hexagon.VFS.Controle.tipoSistemaArquivos], ah

    jmp .finalizar

.restaurarVolume:

    mov dl, byte [Hexagon.Dev.Universal.Disco.Controle.driveBoot]
    mov byte [Hexagon.Dev.Universal.Disco.Controle.driveAtual], dl
    
    call Hexagon.Kernel.FS.VFS.iniciarSistemaArquivos
    
.finalizar:

    ret

;;************************************************************************************
        
;; Inicializa o sistema de arquivos do disco montado, para uso com o Sistema

Hexagon.Kernel.FS.VFS.iniciarSistemaArquivos:   
    
    call Hexagon.Kernel.Dev.x86.Disco.Disco.testarVolume

    jc .volumeAusente

.volumePresente:

    mov ah, byte[Hexagon.VFS.Controle.tipoSistemaArquivos]
    
    cmp ah, Hexagon.VFS.FS.FAT16B
    je .iniciarFAT16B
    
    ret

.volumeAusente:

    mov ah, byte[Hexagon.Dev.Universal.Disco.Controle.driveBoot]
    mov byte[Hexagon.Dev.Universal.Disco.Controle.driveAtual], ah

    mov ah, byte[Hexagon.VFS.Controle.tipoSistemaArquivos]
    
    cmp ah, Hexagon.VFS.FS.FAT16B
    je .volumeDesconectadoFAT16B
    
    ret

;;************************************************************************************
;;
;; Área para implementação de rotinas de implementação/recuperação dos Sistemas de
;; Arquivo suportados
;;
;;************************************************************************************ 

.iniciarFAT16B:
    
    push ebx 

    call Hexagon.Kernel.FS.FAT16.iniciarVolumeFAT16B
    
    pop ebx 

    ret

.volumeDesconectadoFAT16B:
    
    call .iniciarFAT16B
    
    stc
    
    ret
    
;;************************************************************************************
    
Hexagon.Kernel.FS.VFS.definirVolume:

    mov dl, byte[Hexagon.Dev.Universal.Disco.Controle.driveBoot]
    
    mov byte[Hexagon.Dev.Universal.Disco.Controle.driveAtual], dl ;; Irá armazenar o volume a ser utilizado pelo sistema (pode ser alterado)
    
    ret

;;************************************************************************************

;; Obtêm o disco utilizado pelo sistema
;;
;; Saída: 
;;
;; DL - Número do drive (0x00, 0x01, 0x80, 0x81, 0x82, 0x83)
;; AH - Tipo de Sistema de Arquivos
;; ESI - Nome do dispositivo
;; EDI - Rótulo do volume em utilização

Hexagon.Kernel.FS.VFS.obterVolume:

    mov ah, byte[Hexagon.Dev.Universal.Disco.Controle.driveAtual] ;; Número do dispositivo de armazenamento
    mov dl, [Hexagon.Dev.Classes.bloco]           ;; Classe do dispositivo
    
    call Hexagon.Kernel.Dev.Dev.paraDispositivo

    mov edi, Hexagon.VFS.Controle.rotuloVolume
    mov ah, byte[Hexagon.VFS.Controle.tipoSistemaArquivos]

    ret

;;************************************************************************************

