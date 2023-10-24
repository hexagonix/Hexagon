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
;;                 Copyright (c) 2015-2023 Felipe Miguel Nery Lunkes
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
;; Copyright (c) 2015-2023, Felipe Miguel Nery Lunkes
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
;;                     Este arquivo faz parte do kernel Hexagon
;;
;;************************************************************************************

use32

;;************************************************************************************
;;
;; Erros de entrada e saída em disquetes
;;
;; Erro | Descrição do erro
;; -----------------------------------------------------------------------------------
;;
;; 00h  | Sem erro na operação anterior
;; 01h  | Comando inválido: comando incorreto para o controlador
;; 02h  | Endereço inválido
;; 03h  | Protegido contra escrita: impossível escrever no disquete
;; 04h  | ID do setor inválido ou não encontrado
;;
;; 06h  | A troca de disquete está ativa
;;
;; 08h  | Falha no DMA
;; 09h  | DMA: impossível escrever além do limite de 64 Kbytes
;;
;; 0ch  | Tipo de mídia não disponível
;; 10h  | CRC inválido: Cyclical Redundancy Code não concorda com os dados
;; 20h  | Falha no controlador de disquete
;; 31h  | Não existe mídia no drive
;; 40h  | Trilha solicitada não encontrada
;; 80h  | Time-out
;;
;;************************************************************************************
;;
;; Erros de entrada e saída em discos rígidos
;;
;; Retornados apenas se DL > 7fH (requisições para discos rígidos)
;;
; Erro | Descrição do erro
;; -----------------------------------------------------------------------------------
;;
;; 00h  | Sem erro na operação anterior
;; 01h  | Comando inválido: comando incorreto para o controlador
;; 02h  | Endereço inválido
;; 03h  | Protegido contra escrita: impossível escrever no disquete
;; 04h  | ID do setor inválido ou não encontrado
;; 05h  | Falha ao reiniciar
;;
;; 07h  | Falha no parâmetro de atividade do disco
;; 08h  | Falha no DMA
;; 09h  | DMA: impossível escrever além do limite de 64 Kbytes
;; 0Ah  | Bandeira de setor danificado encontrada
;; 0Bh  | Cilindro defeituoso encontrado
;;
;; 0Dh  | Número de setores inválido no formato
;; 0Eh  | Indicador de endereço de controle de dados encontrado
;; 0Fh  | Nível de arbitragem DMA fora do intervalo
;; 10h  | ECC ou CRC incorretos
;; 11h  | Erro de dados corrigidos do ECC
;; 20h  | Falha no controlador de disco rígido
;; 31h  | Não existe mídia no drive
;; 40h  | Trilha solicitada não encontrada
;; 80h  | Time-out
;; AAh  | Drive não pronto
;; B3h  | Volume em uso
;; BBh  | Erro indefinido
;; CCh  | Falha de escrita no drive selecionado
;; E0h  | Estado de erro
;; FFh  | Falha na operação de sentido
;;
;;************************************************************************************

;; Estruturas de uso exclusivo para manipulação global de volumes

struc Hexagon.Dev.Gen.Disco.Geral
{

.semErro          = 00h
.comandoInvalido  = 01h
.enderecoInvalido = 02h
.protegidoEscrita = 03h
.setorInvalido    = 04h
.falhaReiniciar   = 05h
.falhaAtividade   = 07h
.falhaDMA         = 08h
.limiteDMA        = 09h
.setorDanificado  = 0Ah
.erroCilindro     = 0Bh
.numSetInvalido   = 0x0D
.falhaControlador = 20h
.semMidia         = 31h
.timeOut          = 80h
.driveNaoPronto   = 0xAA
.volumeEmUso      = 0xB3
.erroDesconhecido = 0xBB
.falhaEscrita     = 0xCC
.estadoErro       = 0xE0
.falhaOperacao    = 0xFF

}

struc Hexagon.Dev.Gen.Disco.HD
{

.semErro          = 00h
.protegidoEscrita = 01h
.erroLeitura      = 02h
.discoEmUso       = 03h
.semMidia         = 04h
.erroDesconhecido = 05h
.falhaOperacao    = 06h
.erroAutenticacao = 07h
.discoNaoPronto   = 08h

}

struc Hexagon.Dev.Gen.Disco.Controle
{

.driveAtual: db 0
.driveBoot:  db 0

}

Hexagon.Dev.Gen.Disco.Codigos  Hexagon.Dev.Gen.Disco.Geral
Hexagon.Dev.Gen.Disco.HD.IO    Hexagon.Dev.Gen.Disco.HD
Hexagon.Dev.Gen.Disco.Controle Hexagon.Dev.Gen.Disco.Controle

Hexagon.Dev.Gen.Disco:

.codigoOperacao: db 0

;;************************************************************************************

align 4

;; Para os discos em uso no sistema
;;
;; Entrada e saída: vazio

Hexagon.Kernel.Dev.i386.Disco.Disco.pararDisco:

    call Hexagon.Kernel.Dev.i386.Disco.Disco.reiniciarDisco

    ret

;;************************************************************************************

;; Criar instâncias das estruturas, com os nomes adequados que indiquem sua localização

;; Obtêm da MBR (Master Boot Record) informações úteis a respeito do disco
;;
;; Saída:
;;
;; AH - Código da partição
;; Outros dados podem ser armazenados em variáveis apropriadas, futuramente

Hexagon.Kernel.Dev.i386.Disco.Disco.lerMBR:

    push ds
    pop es

;; Primeiro devemos carregar a MBR na memória

    mov eax, 01h ;; Número de setores para ler
    mov esi, 00h ;; LBA do setor inicial
    mov cx, 0x50 ;; Segmento
    mov edi, Hexagon.Heap.CacheDisco+20000 ;; Deslocamento
    mov dl, byte[Hexagon.Dev.Gen.Disco.Controle.driveAtual]

    call Hexagon.Kernel.Dev.i386.Disco.Disco.lerSetores

    jc .erro

    mov ebx, Hexagon.Heap.CacheDisco + 500h + 20000

    add ebx, 0x1BE ;; Deslocamento da primeira partição

    mov ah, byte[es:ebx+04h] ;; Contém o sistema de arquivos

    jmp .fim

.erro:

    stc

.fim:

    ret

;;************************************************************************************

;; Obter o BPB (BIOS Parameter Block) do disco para a memória
;;
;; Saída:
;;
;; Nada, carrega diretamente em 0000:7C00h

Hexagon.Kernel.Dev.i386.Disco.Disco.lerBPB:

    push ds
    pop es

;; Primeiro devemos carregar a MBR na memória

    mov eax, 01h
    mov esi, 00h
    mov cx, 0x2000 ;; Segmento
    mov edi, 0x7C00 ;; Deslocamento
    mov dl, byte[Hexagon.Dev.Gen.Disco.Controle.driveAtual]

    call Hexagon.Kernel.Dev.i386.Disco.Disco.lerSetores

    jc .erro

    jmp .fim

.erro:

    stc

.fim:

    ret

;;************************************************************************************

;; Reinicia determinado disco fornecido como parâmetro
;;
;; Entrada:
;;
;; DL - Código do disco
;;
;; Saída:
;;
;; EAX - 01h caso algum erro tenha ocorrido no processo

Hexagon.Kernel.Dev.i386.Disco.Disco.reiniciarDisco:

    mov ah, 00h

    call Hexagon.Kernel.Arch.i386.BIOS.BIOS.int13h

    jc .erro

    jmp .fim

.erro:

    stc

    mov eax, 01h

.fim:

    ret

;;************************************************************************************

;; Detecta se existe um disco rígido ou removível conectado ao computador. Pode ser
;; utilizada para verificar se o disco solicitado está disponível para montagem
;;
;; Entrada:
;;
;; EAX - 00h se para utilizar o disco padrão
;; DL  - Código do disco, para verificar outro volume
;;
;; Saída:
;;
;; AH - 00h para não instalado, 01h para falha ao detectar alteração de disco, 02h para falha
;;      em detectar alteração de disquete e 03h para disco rígido
;; CF defindo em caso de erro, com AH com o código de erro BIOS

Hexagon.Kernel.Dev.i386.Disco.Disco.detectarDisco:

    clc

;; Vamos chamar o BIOS para solicitar esta informação

    mov ah, 15h

    cmp eax, 00h
    je .discoPadrao

    jmp .continuar

.discoPadrao:

    mov dl, byte[Hexagon.Dev.Gen.Disco.Controle.driveAtual]

.continuar:

    mov al, 0xFF
    mov cx, 0xFFFF

    call Hexagon.Kernel.Arch.i386.BIOS.BIOS.int13h

    jc .erro

    jmp .fim

.erro:

;; A tabela de erros BIOS deve ser observada

    stc

.fim:

    ret

;;************************************************************************************

;; Carregar setor do disco usando funções extendidas BIOS
;;
;; Entrada:
;;
;; EAX - Número de setores
;; ESI - LBA
;; EDI - Buffer de destino
;; CX  - Segmento de modo real
;; DL  - Drive
;;
;; Saída:
;;
;; EBX - Código de retorno da operação de disco executada, como em Hexagon.HD.IO, acima

Hexagon.Kernel.Dev.i386.Disco.Disco.lerSetores:

    push eax
    push esi

    mov dword[.PED.totalSetores], eax ;; Total de setores para carregar
    mov dword[.PED.LBA], esi ;; Endereço de Bloco Linear (Linear Block Addres - LBA)

    mov eax, edi
    shr eax, 4

    add cx, ax

    and edi, 0xf

    mov word[.PED.segmento], cx ;; Segmento de modo real
    mov word[.PED.deslocamento], di

    mov esi, .PED
    mov ah, 0x42 ;; Leitura extendida BIOS

    call Hexagon.Kernel.Arch.i386.BIOS.BIOS.int13h ;; Serviços de disco do BIOS BIOS

    jnc .semErro

.verificarErro:

    cmp ah, Hexagon.Dev.Gen.Disco.Codigos.enderecoInvalido
    je .semMidia

    cmp ah, Hexagon.Dev.Gen.Disco.Codigos.setorInvalido
    je .semMidia

    cmp ah, Hexagon.Dev.Gen.Disco.Codigos.falhaAtividade
    je .semMidia

    cmp ah, Hexagon.Dev.Gen.Disco.Codigos.falhaControlador
    je .semMidia

    cmp al, Hexagon.Dev.Gen.Disco.Codigos.semMidia
    je .semMidia

    cmp al, Hexagon.Dev.Gen.Disco.Codigos.timeOut
    je .errosGerais

    jmp .errosGerais ;; Imprimir erro e aguardar reinício

.errosGerais:

    mov esi, Hexagon.Verbose.Disco.erroDisco

    mov eax, 1

    call Hexagon.Kernel.Kernel.Panico.panico

.semMidia:

    mov dl, byte [Hexagon.Dev.Gen.Disco.Controle.driveBoot]
    mov byte [Hexagon.Dev.Gen.Disco.Controle.driveAtual], dl

    call Hexagon.Kernel.FS.VFS.iniciarSistemaArquivos

    mov byte[Hexagon.Dev.Gen.Disco.codigoOperacao], Hexagon.Dev.Gen.Disco.HD.IO.semMidia

    stc

    jmp .finalizar

.semErro:

    mov byte[Hexagon.Dev.Gen.Disco.codigoOperacao], Hexagon.Dev.Gen.Disco.HD.IO.semErro

.finalizar:

    pop esi
    pop eax

    movzx ebx, byte[Hexagon.Dev.Gen.Disco.codigoOperacao] ;; Fornecer em EBX o código de retorno da operação

    ret

;; PED = Pacote de Endereço de Disco. Do termo em inglês DAP (Disk Address Packet)

.PED:
.PED.tamanho:      db 16
.PED.reservado:    db 0
.PED.totalSetores: dw 0
.PED.deslocamento: dw 0x0000
.PED.segmento:     dw 0
.PED.LBA:          dd 0
                   dd 0

;;************************************************************************************

;; Escrever setores no disco utilizando funções extendidas BIOS
;;
;; Entrada:
;;
;; EAX - Número de setores
;; ESI - LBS
;; EDI - Buffer para escrever
;; CX  - Segmento de modo real
;; DL  - Drive
;;
;; Saída:
;;
;; EBX - Código de retorno da operação de disco executada, como em Hexagon.HD.IO, acima

Hexagon.Kernel.Dev.i386.Disco.Disco.escreverSetores:

    push eax
    push esi

    mov dword[.PED.totalSetores], eax ;; Total de setores para escrever
    mov dword[.PED.LBA], esi ;; LBA

    mov eax, edi
    shr eax, 4

    add cx, ax

    and edi, 0xf

    mov word[.PED.deslocamento], di
    mov word[.PED.segmento], cx ;; Segmento de modo real

    mov esi, .PED
    mov ah, 0x43 ;; Escrita extendida BIOS
    mov al, 0

    call Hexagon.Kernel.Arch.i386.BIOS.BIOS.int13h ;; Serviços de disco BIOS

    jnc .semErro

.verificarErro:

    cmp ah, Hexagon.Dev.Gen.Disco.Codigos.enderecoInvalido
    je .semMidia

    cmp ah, Hexagon.Dev.Gen.Disco.Codigos.protegidoEscrita
    je .protegidoEscrita

    cmp ah, Hexagon.Dev.Gen.Disco.Codigos.driveNaoPronto
    je .discoNaoPronto

    cmp ah, Hexagon.Dev.Gen.Disco.Codigos.volumeEmUso
    je .discoEmUso

    cmp ah, Hexagon.Dev.Gen.Disco.Codigos.falhaEscrita
    je .falhaEscrita

    cmp ah, Hexagon.Dev.Gen.Disco.Codigos.setorInvalido
    je .semMidia

    cmp al, Hexagon.Dev.Gen.Disco.Codigos.falhaAtividade
    je .semMidia

    cmp al, Hexagon.Dev.Gen.Disco.Codigos.falhaControlador
    je .semMidia

    cmp al, Hexagon.Dev.Gen.Disco.Codigos.semMidia
    je .semMidia

    cmp al, Hexagon.Dev.Gen.Disco.Codigos.timeOut
    je .errosGerais

    jmp .errosGerais ;; Imprimir erro e aguardar reinício

.protegidoEscrita:

    stc

    mov byte[Hexagon.Dev.Gen.Disco.codigoOperacao], Hexagon.Dev.Gen.Disco.HD.IO.protegidoEscrita

    ret

.discoNaoPronto:

    stc

    mov byte[Hexagon.Dev.Gen.Disco.codigoOperacao], Hexagon.Dev.Gen.Disco.HD.IO.discoNaoPronto

    ret

.discoEmUso:

    stc

    mov byte[Hexagon.Dev.Gen.Disco.codigoOperacao], Hexagon.Dev.Gen.Disco.HD.IO.discoEmUso

    ret

.falhaEscrita:

    stc

    mov byte[Hexagon.Dev.Gen.Disco.codigoOperacao], Hexagon.Dev.Gen.Disco.HD.IO.falhaOperacao

    ret

.errosGerais:

    mov esi, Hexagon.Verbose.Disco.erroDisco

    mov eax, 1

    call Hexagon.Kernel.Kernel.Panico.panico

.semMidia:

    mov dl, byte [Hexagon.Dev.Gen.Disco.Controle.driveBoot]
    mov byte [Hexagon.Dev.Gen.Disco.Controle.driveAtual], dl

    call Hexagon.Kernel.FS.VFS.iniciarSistemaArquivos

    mov byte[Hexagon.Dev.Gen.Disco.codigoOperacao], Hexagon.Dev.Gen.Disco.HD.IO.semMidia

    stc

    jmp .finalizar

.semErro:

    mov byte[Hexagon.Dev.Gen.Disco.codigoOperacao], Hexagon.Dev.Gen.Disco.HD.IO.semErro

.finalizar:

    pop esi
    pop eax

    movzx ebx, byte[Hexagon.Dev.Gen.Disco.codigoOperacao] ;; Fornecer em EBX o código de retorno da operação

    ret

;; PED = Pacote de Endereço de Disco. Do termo em inglês DAP (Disk Address Packet)

.PED:
.PED.tamanho:      db 16
.PED.reservado:    db 0
.PED.totalSetores: dw 0
.PED.deslocamento: dw 0x0000
.PED.segmento:     dw 0
.PED.LBA:          dd 0
                   dd 0

;;************************************************************************************

;; Testa um determinado volume para verificar sua presença. Caso não esteja presente,
;; um erro será definido, conforme Hexagon.HD.IO

Hexagon.Kernel.Dev.i386.Disco.Disco.testarVolume:

    mov eax, 1
    mov esi, 01
    mov cx, 0x50 ;; Segmento
    mov edi, Hexagon.Heap.CacheDisco+20000 ;; Deslocamento
    mov dl, byte[Hexagon.Dev.Gen.Disco.Controle.driveAtual]

    call Hexagon.Kernel.Dev.i386.Disco.Disco.lerSetores

    ret
