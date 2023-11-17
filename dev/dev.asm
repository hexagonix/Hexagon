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

;;************************************************************************************
;;
;; Informações importantes para uso com a interface de dispositivos Hexagon
;;
;;************************************************************************************
;;
;; Classes de dispositivos utilizadas para designar dispositivo para E/S
;;
;; 1 - Dispositivo de bloco (armazenamento - HDs e outras mídias)
;; 2 - Portas seriais
;; 3 - Portas paralelas (impressoras)
;; 4 - Dispositivos de saída (vídeo e som)
;; 5 - Processador(es)
;;
;;************************************************************************************

use32

Hexagon.Dev.Controle:

.idDispositivo:     dw 0
.dispositivoAberto: db 0
.classeDispositivo: db 0
.aberto:            db 0
.arquivo:           db 0

Hexagon.Dev.Dispositivos:

;; Dispositivos de armazenamento

.hd0:
db "hd0", 0 ;; Primeiro disco rígido
.hd1:
db "hd1", 0 ;; Segundo disco rígido
.hd2:
db "hd2", 0 ;; Terceiro disco rígido
.hd3:
db "hd3", 0 ;; Quarto disco rígido

;; Portas seriais

.com1:
db "com1", 0 ;; Primeira porta serial
.com2:
db "com2", 0 ;; Segunda porta serial
.com3:
db "com3", 0 ;; Terceira porta serial
.com4:
db "com4", 0 ;; Quarta porta serial

;; Portas paralelas e impressoras

.imp0:
db "imp0", 0 ;; Primeira porta paralela
.imp1:
db "imp1", 0 ;; Segunda porta paralela
.imp2:
db "imp2", 0 ;; Terceira porta paralela

;; Dispositivos de saída

.tty0:
db "tty0", 0 ;; Console padrão
.tty1:
db "tty1", 0 ;; Console secundário (buffer)
.tty2:
db "tty2", 0 ;; Console de despejo de dados do kernel

.au0:
db "au0", 0 ;; Alto-falante interno

;; Dispositivos de entrada

.mouse0:
db "mouse0", 0 ;; Mouse conectado ao computador
.tecla0:
db "tecla0", 0 ;; Teclado conectado ao computador

;; Processadores:

.proc0:
db "proc0", 0 ;; Processador principal

Hexagon.Dev.Classes:

.bloco:     db 01h
.seriais:   db 02h
.paralelos: db 03h
.saida:     db 04h
.proc:      db 05h

;;************************************************************************************

;; Fecha a comunicação com um dispositivo

Hexagon.Kernel.Dev.Dev.fechar:

    mov byte[Hexagon.Dev.Controle.aberto], 0
    mov word[Hexagon.Dev.Controle.classeDispositivo], 0

    push ebx

    mov bx, word[Hexagon.Dev.Controle.idDispositivo]

    cmp bx, word[Hexagon.Dev.codigoDispositivos.au0]
    je .au0

    pop ebx

    jmp .finalizar

.au0:

    pop ebx

    call Hexagon.Kernel.Dev.Gen.Som.Som.desligarSom

    jmp .finalizar

.finalizar:

    mov byte[Hexagon.Dev.Controle.idDispositivo], 00h

    ret

;;************************************************************************************

;; Enviar dados para determinado dispositivo aberto. Os dados serão enviados para o dispositivo
;; aberto. Em caso de erro ou dispositivo não aberto, retornar erro
;;
;; Entrada:
;;
;; ESI - Ponteiro para o buffer que contêm os dados à serem enviados
;;
;; Saída:
;;
;; CF definido em caso de erro

Hexagon.Kernel.Dev.Dev.escrever:

    cmp byte[Hexagon.Dev.Controle.aberto], 0
    je .dispositivoNaoAberto

    push eax
    push esi

    mov dl, byte[Hexagon.Dev.Controle.classeDispositivo]

    cmp dl, 01h
    je .armazenamento

    cmp dl, 02h
    je .portasSeriais

    cmp dl, 03h
    je .portasParalelas

    cmp dl, 04h
    je .saida

    cmp dl, 05h
    je .processadores

    stc

    ret

.armazenamento:

    pop esi
    pop eax

    call Hexagon.Kernel.Dev.Dev.fechar

    ret ;; Por enquanto, desativado!

.portasSeriais:

    pop esi
    pop eax

    call Hexagon.Kernel.Dev.Gen.COM.Serial.enviarSerial

    jc .erro

    call Hexagon.Kernel.Dev.Dev.fechar

    ret

.portasParalelas:

    pop esi
    pop eax

    call Hexagon.Kernel.Dev.Gen.LPT.LPT.enviarPortaParalela

    jc .erro

    call Hexagon.Kernel.Dev.Dev.fechar

    ret

.saida:

    pop esi
    pop eax

    mov bx, word[Hexagon.Dev.Controle.idDispositivo]

    cmp word[Hexagon.Dev.codigoDispositivos.au0], bx
    je .au0

    call Hexagon.Kernel.Dev.Dev.fechar

    ret

.au0:

    call Hexagon.Kernel.Dev.Gen.Som.Som.emitirSom

    ret

.processadores:

    pop esi
    pop eax

    call Hexagon.Kernel.Dev.Dev.fechar

    ret

.dispositivoNaoAberto:

    stc

    ret

.erro:

    call Hexagon.Kernel.Dev.Dev.fechar

    stc

    ret

;;************************************************************************************

;; Abre um canal de leitura/escrita com determinado dispositivo solicitado.
;; Também abre um arquivo comum presente no sistema de arquivos
;;
;; Entrada:
;;
;; ESI - Ponteiro para o buffer que contêm o nome convencionado
;; EDI - Endereço para carregamento, em caso de arquivo em disco
;;
;; Saída:
;;
;; EAX - Classe do dispositivo
;; CF definido em caso de erro

Hexagon.Kernel.Dev.Dev.abrir:

    push edi
    push esi

    call Hexagon.Kernel.Dev.Dev.converterDispositivo

    pop esi
    pop edi

    push bx

;; Verificar se está marcado como um possível arquivo comum, presente no sistema de arquivos

    cmp byte[Hexagon.Dev.Controle.arquivo], 1
    je .arquivo

;; Caso não, proceder com a abertura de um dispositivo

    mov byte[Hexagon.Dev.Controle.classeDispositivo], dl

    cmp dl, 01h
    je .armazenamento

    cmp dl, 02h
    je .portasSeriais

    cmp dl, 03h
    je .portasParalelas

    cmp dl, 04h
    je .saida

    cmp dl, 05h
    je .processadores

    stc

    ret

;; Para armazenamento, as saídas podem ser diferentes
;;
;; Saída:
;;
;; EAX - Código de erro genérico/permissão de usuário
;; EBX - Código de erro retornado pelo gerenciamento de disco

.armazenamento:

    pop bx

    clc

    push eax

    cmp dword[ordemKernel], ordemKernelExecutar
    je .armazenamentoAutenticado

.armazenamentoVerificarPermissoes:

    call Hexagon.Kernel.Kernel.Usuarios.verificarPermissoes

    cmp eax, 03h ;; Código de grupo para usuário padrão
    je .armazenamentoPermissaoNegada

.armazenamentoAutenticado:

    pop eax

    mov byte[Hexagon.Dev.Gen.Disco.Controle.driveAtual], ah

    call Hexagon.Kernel.FS.VFS.definirSistemaArquivos

    jc .erroNaoEncontrado

    call Hexagon.Kernel.FS.VFS.iniciarSistemaArquivos

    jc .erroAbertura

    push ebx ;; Contém o código de erro da operação de disco

    mov byte[Hexagon.Dev.Controle.aberto], 1

    call Hexagon.Kernel.Dev.Dev.fechar

    pop ebx  ;; Fornecer a quem solicitou a montagem do disco o código de retorno da operação

    mov eax, dword[Hexagon.Dev.Controle.classeDispositivo]

    jmp .retorno

.armazenamentoPermissaoNegada:

    pop eax

    mov eax, 05h

    stc

    jmp .retorno

.erroNaoEncontrado:

    mov byte[Hexagon.Dev.Controle.aberto], 0
    mov eax, 06h ;; Dispositivo não encontrado

    jmp .retorno

.erroAbertura:

;; O código de erro para operações de disco já está em EBX, em caso de chamada
;; para abertura de um volume

    mov byte[Hexagon.Dev.Controle.aberto], 0
    mov eax, dword[Hexagon.Dev.Controle.classeDispositivo]

    jmp .retorno

.portasSeriais:

    pop bx

    mov word[portaSerialAtual], bx

    call Hexagon.Kernel.Dev.Gen.COM.Serial.iniciarSerial

    jc .erroAbertura

    mov byte[Hexagon.Dev.Controle.aberto], 1

    mov eax, dword[Hexagon.Dev.Controle.classeDispositivo]

    jmp .retorno

.portasParalelas:

    pop bx

    mov word[portaParalelaAtual], bx

    call Hexagon.Kernel.Dev.Gen.LPT.LPT.iniciarPortaParalela

    jc .erroAbertura

    mov byte[Hexagon.Dev.Controle.aberto], 1

    mov eax, dword[Hexagon.Dev.Controle.classeDispositivo]

    jmp .retorno

.saida:

    pop bx

    mov eax, dword[Hexagon.Dev.Controle.classeDispositivo]

    cmp bx, [Hexagon.Dev.codigoDispositivos.tty0]
    je .tty0

    cmp bx, [Hexagon.Dev.codigoDispositivos.tty1]
    je .tty1

    cmp bx, [Hexagon.Dev.codigoDispositivos.tty2]
    je .tty2

    cmp bx, [Hexagon.Dev.codigoDispositivos.au0]
    je .au0

    jmp .retorno

.tty0: ;; Console principal

    call Hexagon.Kernel.Lib.Graficos.usarBufferVideo1

    jmp .retorno

.tty1: ;; Primeiro console virtual

    call Hexagon.Kernel.Lib.Graficos.usarBufferVideo2

    jmp .retorno

.tty2: ;; Console de despejo de dados do kernel

    mov ebx, 1h

    call Hexagon.Kernel.Lib.Graficos.atualizarConsole

    jmp .retorno

.au0: ;; Alto-falante interno do computador

    jmp .retorno

.processadores:

    pop bx

    mov eax, dword[Hexagon.Dev.Controle.classeDispositivo]

    mov esi, Hexagon.Dev.codigoDispositivos.proc0

    jmp .retorno

.arquivo:

    pop bx

    mov byte[Hexagon.Dev.Controle.arquivo], 0

    call Hexagon.Kernel.FS.VFS.carregarArquivo

    jmp .retorno

.retorno:

    ret

;;************************************************************************************

;; Converter um nome de dispositivo segundo convenção para um número ou endereço.
;; Também é utilizado para distinguir entre nomes de dispositivos e nome de arquivo
;; comum, presente no sistema de arquivos
;;
;; Entrada:
;;
;; ESI - Ponteiro para o buffer que contêm o nome convencionado
;; EAX - Classe do dispositivo (Uso futuro)
;;
;; Saída:
;;
;; AH - Número do dispositivo para uso pelo kernel
;; BX - Cópia de AH em um registrador 16 bits
;; ECX - Cópia de AH em um registrador 32 bits
;; DL - Classe do dispositivo

Hexagon.Kernel.Dev.Dev.converterDispositivo:

    mov edi, Hexagon.Dev.Dispositivos.hd0
    call Hexagon.Kernel.Lib.String.compararPalavrasNaString
    jc .hd0

    mov edi, Hexagon.Dev.Dispositivos.hd1
    call Hexagon.Kernel.Lib.String.compararPalavrasNaString
    jc .hd1

    mov edi, Hexagon.Dev.Dispositivos.hd2
    call Hexagon.Kernel.Lib.String.compararPalavrasNaString
    jc .hd2

    mov edi, Hexagon.Dev.Dispositivos.hd3
    call Hexagon.Kernel.Lib.String.compararPalavrasNaString
    jc .hd3

    mov edi, Hexagon.Dev.Dispositivos.com1
    call Hexagon.Kernel.Lib.String.compararPalavrasNaString
    jc .com1

    mov edi, Hexagon.Dev.Dispositivos.com2
    call Hexagon.Kernel.Lib.String.compararPalavrasNaString
    jc .com2

    mov edi, Hexagon.Dev.Dispositivos.com3
    call Hexagon.Kernel.Lib.String.compararPalavrasNaString
    jc .com3

    mov edi, Hexagon.Dev.Dispositivos.com4
    call Hexagon.Kernel.Lib.String.compararPalavrasNaString
    jc .com4

    mov edi, Hexagon.Dev.Dispositivos.imp0
    call Hexagon.Kernel.Lib.String.compararPalavrasNaString
    jc .imp0

    mov edi, Hexagon.Dev.Dispositivos.imp1
    call Hexagon.Kernel.Lib.String.compararPalavrasNaString
    jc .imp1

    mov edi, Hexagon.Dev.Dispositivos.imp2
    call Hexagon.Kernel.Lib.String.compararPalavrasNaString
    jc .imp2

    mov edi, Hexagon.Dev.Dispositivos.tty0
    call Hexagon.Kernel.Lib.String.compararPalavrasNaString
    jc .tty0

    mov edi, Hexagon.Dev.Dispositivos.tty1
    call Hexagon.Kernel.Lib.String.compararPalavrasNaString
    jc .tty1

    mov edi, Hexagon.Dev.Dispositivos.tty2
    call Hexagon.Kernel.Lib.String.compararPalavrasNaString
    jc .tty2

    mov edi,Hexagon.Dev.Dispositivos.au0
    call Hexagon.Kernel.Lib.String.compararPalavrasNaString
    jc .au0

    mov edi, Hexagon.Dev.Dispositivos.mouse0
    call Hexagon.Kernel.Lib.String.compararPalavrasNaString
    jc .mouse0

    mov edi, Hexagon.Dev.Dispositivos.tecla0
    call Hexagon.Kernel.Lib.String.compararPalavrasNaString
    jc .tecla0

    mov edi, Hexagon.Dev.Dispositivos.proc0
    call Hexagon.Kernel.Lib.String.compararPalavrasNaString
    jc .proc0

;; Este nome pode fazer referência a um arquivo comum!
;; Então o sistema tentará realizar a abertura do mesmo!

    mov byte[Hexagon.Dev.Controle.arquivo], 1 ;; Marcar como sendo possivelmente um arquivo

    ret

.hd0:

    mov ah, byte [Hexagon.Dev.codigoDispositivos.hd0]
    mov byte[Hexagon.Dev.Controle.idDispositivo], ah
    movzx ecx, byte [Hexagon.Dev.codigoDispositivos.hd0]
    mov dl, 01h

    ret

.hd1:

    mov ah, byte [Hexagon.Dev.codigoDispositivos.hd1]
    mov byte[Hexagon.Dev.Controle.idDispositivo], ah
    movzx ecx, byte [Hexagon.Dev.codigoDispositivos.hd1]
    mov dl, 01h

    ret

.hd2:

    mov ah, byte [Hexagon.Dev.codigoDispositivos.hd2]
    mov byte[Hexagon.Dev.Controle.idDispositivo], ah
    movzx ecx, byte [Hexagon.Dev.codigoDispositivos.hd2]
    mov dl, 01h

    ret

.hd3:

    mov ah, byte [Hexagon.Dev.codigoDispositivos.hd3]
    mov byte[Hexagon.Dev.Controle.idDispositivo], ah
    movzx ecx, byte [Hexagon.Dev.codigoDispositivos.hd3]
    mov dl, 01h

    ret

.com1:

    mov ah, 00h
    mov bx, word [Hexagon.Dev.codigoDispositivos.com1]
    mov word[Hexagon.Dev.Controle.idDispositivo], bx
    movzx ecx, word [Hexagon.Dev.codigoDispositivos.com1]
    mov dl, 02h

    ret

.com2:

    mov ah, 01h
    mov bx, word [Hexagon.Dev.codigoDispositivos.com2]
    mov word[Hexagon.Dev.Controle.idDispositivo], bx
    movzx ecx, word [Hexagon.Dev.codigoDispositivos.com2]
    mov dl, 02h

    ret

.com3:

    mov ah, 02h
    mov bx, word [Hexagon.Dev.codigoDispositivos.com3]
    mov word[Hexagon.Dev.Controle.idDispositivo], bx
    movzx ecx, word [Hexagon.Dev.codigoDispositivos.com3]
    mov dl, 02h

    ret

.com4:

    mov ah, 03h
    mov bx, word [Hexagon.Dev.codigoDispositivos.com4]
    mov word[Hexagon.Dev.Controle.idDispositivo], bx
    movzx ecx, word [Hexagon.Dev.codigoDispositivos.com4]
    mov dl, 02h

    ret

.imp0:

    mov bx, word [Hexagon.Dev.codigoDispositivos.imp0]
    mov word[Hexagon.Dev.Controle.idDispositivo], bx
    movzx ecx, word [Hexagon.Dev.codigoDispositivos.imp0]
    mov dl, 03h

    ret

.imp1:

    mov bx, word [Hexagon.Dev.codigoDispositivos.imp1]
    mov word[Hexagon.Dev.Controle.idDispositivo], bx
    movzx ecx, word [Hexagon.Dev.codigoDispositivos.imp1]
    mov dl, 03h

    ret

.imp2:

    mov bx, word [Hexagon.Dev.codigoDispositivos.imp2]
    mov word[Hexagon.Dev.Controle.idDispositivo], bx
    movzx ecx, word [Hexagon.Dev.codigoDispositivos.imp2]
    mov dl, 03h

    ret

.tty0:

    mov ah, 00h
    mov bx, word [Hexagon.Dev.codigoDispositivos.tty0]
    mov word[Hexagon.Dev.Controle.idDispositivo], bx
    mov ecx, [Hexagon.Dev.codigoDispositivos.tty0]
    mov dl, 04h

    ret

.tty1:

    mov ah, 01h
    mov bx, word [Hexagon.Dev.codigoDispositivos.tty1]
    mov word[Hexagon.Dev.Controle.idDispositivo], bx
    mov ecx, [Hexagon.Dev.codigoDispositivos.tty1]
    mov dl, 04h

    ret

.tty2:

    mov ah, 02h
    mov bx, word [Hexagon.Dev.codigoDispositivos.tty2]
    mov word[Hexagon.Dev.Controle.idDispositivo], bx
    mov ecx, [Hexagon.Dev.codigoDispositivos.tty2]
    mov dl, 04h

    ret

.au0:

    mov ah, byte [Hexagon.Dev.codigoDispositivos.au0]
    mov bx, word [Hexagon.Dev.codigoDispositivos.au0]
    mov word[Hexagon.Dev.Controle.idDispositivo], bx
    mov dl, 04h

.mouse0:

    mov ah, 00h
    mov bx, [Hexagon.Dev.codigoDispositivos.mouse0]
    mov word[Hexagon.Dev.Controle.idDispositivo], bx
    mov dl, 00h

    ret

.tecla0:

    mov ah, 00h
    mov bx, word [Hexagon.Dev.codigoDispositivos.tecla0]
    mov word[Hexagon.Dev.Controle.idDispositivo], bx
    mov dl, 00h

    ret

.proc0:

    mov ah, 00h
    mov bx, word [Hexagon.Dev.codigoDispositivos.proc0]
    mov word[Hexagon.Dev.Controle.idDispositivo], bx
    movzx ecx, word [Hexagon.Dev.codigoDispositivos.proc0]
    mov dl, 05h

    ret

;;************************************************************************************

;; Converter um número ou endereço para um nome de dispositivo
;;
;; Entrada:
;;
;; AH - Número do dispositivo (Caso armazenamento)
;; AX - Número do dispositivo (Portas seriais, portas paralelas, dispositivos de vídeo e processadores)
;; DL - Classe do dispositivo (1 para armazenamento, 2 para portas seriais, 3 para portas paralelas,
;; 4 para dispositivos de saída e 5 para processadores)
;;
;; Saída:
;;
;; ESI - Buffer contendo o nome do arquivo/dispositivo

Hexagon.Kernel.Dev.Dev.paraDispositivo:

    cmp dl, 1
    je .armazenamento

    cmp dl, 2
    je .seriais

    cmp dl, 3
    je .paralelas

    cmp dl, 4
    je .saida

    cmp dl, 5
    je .processadores

    stc ;; Em caso de classe inválida

    ret

.armazenamento:

    cmp ah, byte [Hexagon.Dev.codigoDispositivos.hd0]
    je .hd0

    cmp ah, byte [Hexagon.Dev.codigoDispositivos.hd1]
    je .hd1

    cmp ah, byte [Hexagon.Dev.codigoDispositivos.hd2]
    je .hd2

    cmp ah, byte [Hexagon.Dev.codigoDispositivos.hd3]
    je .hd3

    stc

    ret

.hd0:

    mov esi, Hexagon.Dev.Dispositivos.hd0

    ret

.hd1:

    mov esi, Hexagon.Dev.Dispositivos.hd1

    ret

.hd2:

    mov esi, Hexagon.Dev.Dispositivos.hd2

    ret

.hd3:

    mov esi, Hexagon.Dev.Dispositivos.hd3

    ret

.seriais:

    cmp ax, word [Hexagon.Dev.codigoDispositivos.com1]
    je .com1

    cmp ax, word [Hexagon.Dev.codigoDispositivos.com2]
    je .com2

    cmp ax, word [Hexagon.Dev.codigoDispositivos.com3]
    je .com3

    cmp ax, word [Hexagon.Dev.codigoDispositivos.com4]
    je .com4

    stc

    ret

.com1:

    mov esi, Hexagon.Dev.Dispositivos.com1

    ret

.com2:

    mov esi, Hexagon.Dev.Dispositivos.com2

    ret

.com3:

    mov esi, Hexagon.Dev.Dispositivos.com3

    ret

.com4:

    mov esi, Hexagon.Dev.Dispositivos.com4

    ret

.paralelas:

    cmp ax, word [Hexagon.Dev.codigoDispositivos.imp0]
    je .imp0

    cmp ax, word [Hexagon.Dev.codigoDispositivos.imp1]
    je .imp1

    cmp ax, word [Hexagon.Dev.codigoDispositivos.imp2]
    je .imp2

    stc

    ret

.imp0:

    mov esi, Hexagon.Dev.Dispositivos.imp0

    ret

.imp1:

    mov esi, Hexagon.Dev.Dispositivos.imp1

    ret

.imp2:

    mov esi, Hexagon.Dev.Dispositivos.imp2

    ret

.saida:

    cmp ax, Hexagon.Dev.codigoDispositivos.tty0
    je .tty0

    cmp ax, Hexagon.Dev.codigoDispositivos.tty1
    je .tty1

    cmp ax, Hexagon.Dev.codigoDispositivos.tty2
    je .tty2

    stc

    ret

.tty0:

    mov esi, Hexagon.Dev.Dispositivos.tty0

    ret

.tty1:

    mov esi, Hexagon.Dev.Dispositivos.tty1

    ret

.tty2:

    mov esi, Hexagon.Dev.Dispositivos.tty2

    ret

.processadores:

    cmp ax, 00h
    je .proc0

    stc

    ret

.proc0:

    mov esi, Hexagon.Dev.Dispositivos.proc0

    ret

;;************************************************************************************

;; Incluir os códigos de dispositivos dependentes da arquitetura

include "i386/i386.asm"
;; include "amd64/amd64.asm"
