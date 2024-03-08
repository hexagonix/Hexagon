;;************************************************************************************
;;
;; 88       88
;; 88       88
;; 88       88  ,adPPPba, 8b,     ,d8 ,adPPPPba,  ,adPPPb,d8  ,adPPPba,    ,dPPPba,
;; 88PPPPPPP88 a8P     88  `P8, ,8P'  ""     `P8 a8"    `P88 a8"     "8a 88P'   `"88
;; 88       88 8PP"""""""    )888(    ,adPPPPP88 8b       88 8b       d8 88       88
;; 88       88 '8b,   ,aa  ,d8" "8b,  88,    ,88 "8a,   ,d88 "8a,   ,a8" 88       88
;; 88       88  `"Pbbd8"' 8P'     `P8 `"8bbdP"P8  `"PbbdP"P8  `"PbbdP"'  88       88
;;                                                aa,    ,88
;;                                                 "P8bbdP"
;;
;;                          Kernel Hexagon - Hexagon kernel
;;
;;                 Copyright (c) 2015-2024 Felipe Miguel Nery Lunkes
;;                Todos os direitos reservados - All rights reserved.
;;
;;************************************************************************************
;;
;; Português:
;;
;; O Hexagon, Hexagonix e seus componentes são licenciados sob licença BSD-3-Clause.
;; Leia abaixo a licença que governa este arquivo e verifique a licença de cada repositório
;; para obter mais informações sobre seus direitos e obrigações ao utilizar e reutilizar
;; o código deste ou de outros arquivos.
;;
;; English:
;;
;; The Hexagon, the Hexagonix and its components are licensed under a BSD-3-Clause license.
;; Read below the license that governs this file and check each repository's license for
;; obtain more information about your rights and obligations when using and reusing
;; the code of this or other files.
;;
;;************************************************************************************
;;
;; BSD 3-Clause License
;;
;; Copyright (c) 2015-2024, Felipe Miguel Nery Lunkes
;; All rights reserved.
;;
;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions are met:
;;
;; 1. Redistributions of source code must retain the above copyright notice, this
;;    list of conditions and the following disclaimer.
;;
;; 2. Redistributions in binary form must reproduce the above copyright notice,
;;    this list of conditions and the following disclaimer in the documentation
;;    and/or other materials provided with the distribution.
;;
;; 3. Neither the name of the copyright holder nor the names of its
;;    contributors may be used to endorse or promote products derived from
;;    this software without specific prior written permission.
;;
;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
;; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
;; DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
;; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
;; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
;; SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
;; CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
;; OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
;; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;;
;; $HexagonixOS$

;;************************************************************************************
;;
;;                     This file is part of the Hexagon kernel
;;
;;************************************************************************************

use32

;; Códigos dos Sistemas de Arquivo suportados

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
.atributoLFN           equ 0x0F   ;; Atributo de um nome de arquivo longo (Long File Name)
.atributoDeletado      equ 0xE5   ;; Atributo de arquivo deletado/entrada livre
.atributoUltimoCluster equ 0xFFF8 ;; Atributo de último cluster na cadeia
.bitDiretorio          equ 04h    ;; Bit de um diretório = .atributoDiretorio, mas para bit check
.bitNomeVolume         equ 03h    ;; Bit de um nome (rótulo) de volume

}

;; Estruturas de gerenciamento de arquivos e pontos de montagem do Hexagon

include "fs/dir.asm"

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

;; Renomear um arquivo existente no disco
;;
;; Entrada:
;;
;; ESI - Nome de arquivo da fonte
;; EDI - Nome de arquivo do destino
;;
;; Saída:
;;
;; CF definido em caso de erro ou limpo em caso de sucesso

Hexagon.Kernel.FS.VFS.renomearArquivo:

    mov ah, byte[Hexagon.VFS.Controle.tipoSistemaArquivos]

    cmp ah, Hexagon.VFS.FS.FAT16B
    je .renomearArquivoFAT16B

    ret

.renomearArquivoFAT16B:

    call Hexagon.Kernel.FS.FAT16.renomearArquivoFAT16B

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

    mov ah, byte[Hexagon.Dev.Gen.Disk.Control.bootDisk]

    mov dl, 01h ;; Classe de dispositivo de armazenamento

    call Hexagon.Kernel.Dev.Dev.convertDeviceToDeviceName ;; Converter para nome de dispositivo

;; Habilitar os privilégios do kernel para solicitação privilegiada

    mov dword[ordemKernel], ordemKernelExecutar

    call Hexagon.Kernel.Dev.Dev.open ;; Abrir o dispositivo para leitura/escrita com privilégios

;; Desabilitar os privilégios do kernel, uma vez que já não são necessários

    mov dword[ordemKernel], ordemKernelDesativada

    ret

;;************************************************************************************

;; Define o sistema de arquivos presente no disco atual, obtendo a informação adequada
;; no MBR (Master Boot Record)

Hexagon.Kernel.FS.VFS.definirSistemaArquivos:

    call Hexagon.Kernel.Dev.i386.Disk.Disk.readMBR

    jc .restaurarVolume

    mov byte[Hexagon.VFS.Controle.tipoSistemaArquivos], ah

    jmp .finalizar

.restaurarVolume:

    mov dl, byte [Hexagon.Dev.Gen.Disk.Control.bootDisk]
    mov byte [Hexagon.Dev.Gen.Disk.Control.currentDisk], dl

    call Hexagon.Kernel.FS.VFS.iniciarSistemaArquivos

    stc

.finalizar:

    ret

;;************************************************************************************

;; Inicializa o sistema de arquivos do disco montado, para uso com o sistema

Hexagon.Kernel.FS.VFS.iniciarSistemaArquivos:

    call Hexagon.Kernel.Dev.i386.Disk.Disk.testVolume

    jc .volumeAusente

.volumePresente:

    mov ah, byte[Hexagon.VFS.Controle.tipoSistemaArquivos]

    cmp ah, Hexagon.VFS.FS.FAT16B
    je .iniciarFAT16B

    clc

    ret

.volumeAusente:

    mov ah, byte[Hexagon.Dev.Gen.Disk.Control.bootDisk]
    mov byte[Hexagon.Dev.Gen.Disk.Control.currentDisk], ah

    mov ah, byte[Hexagon.VFS.Controle.tipoSistemaArquivos]

    cmp ah, Hexagon.VFS.FS.FAT16B
    je .volumeDesconectadoFAT16B

    stc

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

Hexagon.Kernel.FS.VFS.definirVolumeBoot:

;; Irá armazenar o volume a ser utilizado pelo sistema (pode ser alterado)

    mov dl, byte[Hexagon.Dev.Gen.Disk.Control.bootDisk]
    mov byte[Hexagon.Dev.Gen.Disk.Control.currentDisk], dl

    logHexagon Hexagon.Verbose.definirVolume, Hexagon.Dmesg.Prioridades.p5

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

    mov ah, byte[Hexagon.Dev.Gen.Disk.Control.currentDisk] ;; Número do dispositivo de armazenamento
    mov dl, [Hexagon.Dev.DeviceClasses.block] ;; Classe do dispositivo

    call Hexagon.Kernel.Dev.Dev.convertDeviceToDeviceName

    mov edi, Hexagon.VFS.Controle.rotuloVolume
    mov ah, byte[Hexagon.VFS.Controle.tipoSistemaArquivos]

    ret
