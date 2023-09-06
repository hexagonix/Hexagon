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

Hexagon.Arch.Gen.Memoria.memoriaReservadaHexagon = 16777216

struc Hexagon.Arch.Gen.Memoria enderecoInicial
{

.enderecoInicial    = enderecoInicial
.memoriaCMOS:       dw 0 ;; Armazena a quantidade de memória obtida na inicialização
.memoriaTotal:      dd 0 ;; Armazena a memória total obtida, em bytes
.enderecoBPB:       dd 0 ;; Endereço em memória do BIOS Parameter Block
.memoriaUsada:      dd 0 ;; Armazena a quantidade de memória usada por processos do usuário
.bytesAlocados:     dd 0 ;; Bytes alocados

}

struc Hexagon.Arch.Gen.Memoria.Alocador tamanhoEspacoProcessos
{

.primeiroBlocoLivre dd 0
.ponteiroAnterior   dd 0
.tamanhoBloco       dd 0
.proximoPonteiro    dd 0
.reservadoInicial   = tamanhoEspacoProcessos
.reservadoProcessos dd .reservadoInicial

}

;; Criar instâncias das estruturas, com os nomes adequados que indiquem sua localização
;;
;; Atualmente, 16 Mb reservados para o Hexagon e suas estruturas e 16 Mb reservados para
;; o carregamentos de executáveis na memória. Essas informações estão disponíveis no
;; ato de se criar o objeto instanciado e pode ser alterado. A primeira instância determina
;; onde começa o espaço de memória que pode ser utilizado pelos processos, após o espaço
;; reservado ao Kernel. Já a segunda, determina qual o tamanho de memória a ser alocada para
;; os processos. Então, essa área é alocada e é gerenciada pelo Kernel.

Hexagon.Memoria          Hexagon.Arch.Gen.Memoria Hexagon.Arch.Gen.Memoria.memoriaReservadaHexagon
Hexagon.Memoria.Alocador Hexagon.Arch.Gen.Memoria.Alocador Hexagon.Arch.Gen.Memoria.memoriaReservadaHexagon

;;************************************************************************************

align 4

;; Retorna a quantidade de memória utilizada pelos processos
;;
;; Saída:
;;
;; EAX - Quantidade de memória utilizada pelos processos na pilha
;; EBX - Memória total encontrada e disponível para uso, em bytes
;; ECX - Memória total encontrada e disponível para uso, em Mbytes (menos preciso)
;; EDX - Memória reservada ao Hexagon, em bytes
;; ESI - Memória total alocada (reservado+processos), em kbytes

Hexagon.Kernel.Arch.Gen.Mm.usoMemoria:

    push ds
    pop es

    mov eax, dword[Hexagon.Memoria.memoriaUsada]

    mov ebx, dword[Hexagon.Memoria.memoriaTotal]

.fornecerMB:    ;; Fornecer também a quantidade total em Mbytes

    mov ecx, dword[Hexagon.Memoria.memoriaTotal]

    shr ecx, 10 ;; ECX = ECX / 1024

    shr ecx, 10 ;; ECX = ECX / 1024

.fornecerMemoriaReservada:

    mov edx, Hexagon.Arch.Gen.Memoria.memoriaReservadaHexagon

.fornecerMemoriaAlocada:

;; Adicionar a memória resevada do Hexagon

    push eax
    push ebx

    mov eax, Hexagon.Arch.Gen.Memoria.memoriaReservadaHexagon

;; Converter de bytes para kbytes agora

    shr eax, 10 ;; EAX/1024
    shr eax, 10 ;; EAX/1024

    mov ebx, dword[Hexagon.Memoria.memoriaUsada]
    add ebx, eax
    mov esi, ebx

    pop ebx
    pop eax

    ret

;;************************************************************************************

;; Confirma o uso de determinada quantidade de memória para processos do usuário
;;
;; Entrada:
;;
;; EAX - Quantidade de memória à ser utilizada

Hexagon.Kernel.Arch.Gen.Mm.confirmarUsoMemoria:

    add dword[Hexagon.Memoria.memoriaUsada], eax

    ret

;;************************************************************************************

;; Libera o uso de determinada quantidade de memória para processos do usuário
;;
;; Entrada:
;;
;; EAX - Quantidade de memória à ser liberada

Hexagon.Kernel.Arch.Gen.Mm.liberarUsoMemoria:

    sub dword[Hexagon.Memoria.memoriaUsada], eax

    ret

;;************************************************************************************

Hexagon.Kernel.Arch.Gen.Mm.iniciarMemoria:

;; Primeiramente, o endereço inicial para a alocação de processos e dados se dará após os 16 Mb
;; reservados para o Kernel e estruturas dele

    mov ebx, Hexagon.Memoria.enderecoInicial ;; Após os 16 MB iniciais reservados

;; Total de memória livre após o endereço, até o final da memória detectada. Essa será a área
;; de alocação

    mov ecx, [Hexagon.Memoria.memoriaTotal]

    sub ecx, [Hexagon.Memoria.enderecoInicial]

    call Hexagon.Kernel.Arch.Gen.Mm.configurarMemoria                   ;; Iniciar o manipulador de memória

;; Agora, o espaço reservado para os processos será definido, utilizando o padrão estabelecido
;; Hexagon.Memoria.Alocador.reservadoInicial

    mov ebx, [Hexagon.Memoria.Alocador.reservadoProcessos]

    call Hexagon.Kernel.Arch.Gen.Mm.alocarMemoria                       ;; Alocar memória para os processos

    call Hexagon.Kernel.Kernel.Proc.configurarAlocacaoProcessos ;; Salvar o endereço usado para a alocação

    ret

;;************************************************************************************

;; Iniciar a memória
;;
;; Entrada:
;;
;; EBX - Início da memória livre
;; ECX - Tamanho total da memória livre

Hexagon.Kernel.Arch.Gen.Mm.configurarMemoria:

    push ecx

    mov [Hexagon.Memoria.Alocador.primeiroBlocoLivre], ebx

    sub ecx, ebx

    mov [Hexagon.Memoria.Alocador.tamanhoBloco], ecx
    mov [Hexagon.Memoria.Alocador.ponteiroAnterior], 0
    mov [Hexagon.Memoria.Alocador.proximoPonteiro], 0

    mov ecx, [Hexagon.Memoria.Alocador.ponteiroAnterior]
    mov [ebx], ecx

    mov ecx, [Hexagon.Memoria.Alocador.tamanhoBloco]
    mov [ebx+4], ecx

    mov ecx, [Hexagon.Memoria.Alocador.proximoPonteiro]
    mov [ebx+8], ecx

    pop ecx

    ret

;;************************************************************************************

;; Alocar memória
;;
;; Entrada:
;;
;; EBX - Tamanho da memória solicitada, em bytes
;;
;; Saída:
;;
;; EAX - 0 se falha
;; EBX - Ponteiro para a memória alocada, se sucesso

Hexagon.Kernel.Arch.Gen.Mm.alocarMemoria:

    push ecx
    push edx

    mov eax, [Hexagon.Memoria.Alocador.primeiroBlocoLivre]

.loop:

    mov ecx, [eax]
    mov [Hexagon.Memoria.Alocador.ponteiroAnterior], ecx

    mov ecx, [eax+4]
    mov [Hexagon.Memoria.Alocador.tamanhoBloco], ecx

    mov ecx, [eax+8]
    mov [Hexagon.Memoria.Alocador.proximoPonteiro], ecx

    cmp [Hexagon.Memoria.Alocador.tamanhoBloco], ebx
    jae .blocoEncontrado

    cmp [Hexagon.Memoria.Alocador.proximoPonteiro], 0
    je .erro

    mov eax, [Hexagon.Memoria.Alocador.proximoPonteiro]

    jmp .loop

.erro:

    xor eax, eax

    jmp .fim

.blocoEncontrado:

    mov ecx, [Hexagon.Memoria.Alocador.tamanhoBloco]

    sub ecx, ebx

    jz .igual

    cmp [Hexagon.Memoria.Alocador.proximoPonteiro], 0
    jne .proximoExiste

    cmp [Hexagon.Memoria.Alocador.ponteiroAnterior], 0
    jne .anteriorNaoProximo

;; Nenhum outro bloco livre existe. Adicionar outro e mover o ponteiro de primeiro
;; bloco livre para lá

    mov ecx, eax                  ;; Mover o endereço para ECX

    add ecx, ebx

    mov dword [ecx], 0            ;; Definir bloco anterior para 0
    mov edx, [Hexagon.Memoria.Alocador.tamanhoBloco]

    sub edx, ebx                  ;; Espaço restante em EDX

    mov [ecx+4], edx              ;; Salvar no cabeçalho
    mov dword [ecx+8], 0          ;; Sem ponteiro para o próximo bloco

    mov [Hexagon.Memoria.Alocador.primeiroBlocoLivre], ecx
    mov ebx, eax                  ;; EAX inalterado

    jmp .fim

;; O próximo bloco não está disponível/existe. Desta forma, um novo cabeçalho no
;; fim do tamanho solicitado deve ser criado, com o tamanho livre, além da atualização
;; do próximo ponteiro no cabeçalho anterior

.anteriorNaoProximo:

    mov ecx, eax                  ;; Mover o endereço para ECX

    add ecx, ebx                  ;; Adicionar a tamanhoBloco o que foi solicitado

    mov edx, [Hexagon.Memoria.Alocador.ponteiroAnterior] ;; Definir o ponteiro para o cabeçalho anterior no novo
    mov [ecx], edx                ;; Definir novo cabeçalho para 0
    mov edx, [Hexagon.Memoria.Alocador.tamanhoBloco]

    sub edx, ebx                  ;; Espaço anterior em EDX

    mov [ecx+4], edx              ;; Salvar no novo cabeçalho
    mov dword [ecx+8], 0          ;; Sem próximo ponteiro

    mov [Hexagon.Memoria.Alocador.ponteiroAnterior+8], ecx
    mov ebx, eax

    jmp .fim

;; O bloco anterior e o próximo existem, então fazer novo cabeçalho
;; no fim do bloco requisitado com o espaço livre. Mover dados do próximo
;; bloco para um novo e adicionar o tamanho do bloco, atualizando todos os
;; ponteiros anteriores e próximos para 3 blocos

.proximoExiste:

    cmp [Hexagon.Memoria.Alocador.ponteiroAnterior], 0
    je .proximoMasNaoAnterior

    mov ecx, eax

    add ecx, ebx

    mov edx, [Hexagon.Memoria.Alocador.ponteiroAnterior]
    mov [ecx], edx
    mov edx, [Hexagon.Memoria.Alocador.tamanhoBloco]

    sub edx, ebx

    mov ebx, [Hexagon.Memoria.Alocador.proximoPonteiro+4]

    add edx, ebx

    mov [ecx+4], edx
    mov edx, [Hexagon.Memoria.Alocador.proximoPonteiro] ;; Endereço do próximo bloco livre

    cmp dword [edx], 0
    je .naoOProximo

    mov dword [edx], ecx
    mov dword [ecx+8], edx        ;; Endereço para o próximo ponteiro

    mov [Hexagon.Memoria.Alocador.ponteiroAnterior+8], ecx
    mov ebx, eax

    jmp .fim

.naoOProximo:

    mov dword [edx], 0
    mov dword [ecx+8], 0
    mov [Hexagon.Memoria.Alocador.ponteiroAnterior+8], ecx
    mov ebx, eax

    jmp .fim

;; O primeiro bloco livre foi alocado. Fazer o mesmo que antes, ignorando o bloco anterior
;; e movendo o ponteiro de próximo bloco livre

.proximoMasNaoAnterior:

    mov ecx, eax

    add ecx, ebx

    mov dword [ecx], 0
    mov edx, [Hexagon.Memoria.Alocador.tamanhoBloco]

    sub edx, ebx

    mov ebx, [Hexagon.Memoria.Alocador.proximoPonteiro+4]

    add edx, ebx

    mov [ecx+4], edx
    mov edx, [Hexagon.Memoria.Alocador.proximoPonteiro]

    cmp dword [edx], 0
    je .naoProximo

    mov dword [edx], ecx
    mov dword [ecx+8], edx

    mov [Hexagon.Memoria.Alocador.primeiroBlocoLivre], ecx ;; Zerar e atualizar primeiro bloco livre
    mov ebx, eax

    jmp .fim

.naoProximo:

    mov dword [edx], 0
    mov ecx, [ecx+8]
    mov dword [ecx], 0
    mov [Hexagon.Memoria.Alocador.ponteiroAnterior+8], ecx
    mov ebx, eax

    jmp .fim

.igual:

    cmp [Hexagon.Memoria.Alocador.proximoPonteiro], 0
    jne .proximoExiste2

    cmp [Hexagon.Memoria.Alocador.ponteiroAnterior], 0
    jne .anteriorNaoProximo2

    mov [Hexagon.Memoria.Alocador.primeiroBlocoLivre], 0
    mov ebx, eax

    jmp .fim

.anteriorNaoProximo2:

    mov dword [Hexagon.Memoria.Alocador.ponteiroAnterior+8], 0
    mov ebx, eax

    jmp .fim

.proximoExiste2:

    cmp [Hexagon.Memoria.Alocador.ponteiroAnterior], 0
    je .proximoMasNaoAnterior2

    mov ecx, [Hexagon.Memoria.Alocador.ponteiroAnterior]
    mov edx, [Hexagon.Memoria.Alocador.proximoPonteiro]
    mov [ecx+8], edx
    mov [edx], ecx
    mov ebx, eax

    jmp .fim

.proximoMasNaoAnterior2:

    mov ecx, [eax+8]              ;; Obter endereço do próximo cabeçalho
    mov dword [ecx], 0            ;; Definir cabeçalho anterior para 0 e atualizar
    mov [Hexagon.Memoria.Alocador.primeiroBlocoLivre], ecx ;; Atualizar também o primeiro bloco livre
    mov ebx, eax

.fim:

    pop edx
    pop ecx

    ret

;;************************************************************************************

;; Libera a memória alocada
;;
;; Entrada:
;;
;; EBX - Ponteiro para a memória previamente alocada
;; ECX - Tamanho da memória alocada anteriormente, em bytes

Hexagon.Kernel.Arch.Gen.Mm.liberarMemoria:

    push eax
    push ebx
    push ecx
    push edx

    cmp ebx, [Hexagon.Memoria.Alocador.primeiroBlocoLivre]
    jb .novoPrimeiroLivre

    cmp [Hexagon.Memoria.Alocador.primeiroBlocoLivre], 0
    je .novoPrimeiroLivre

;; O bloco que queremos esta entre dois blocos livres ou antes do último bloco livre,
;; em algum lugar. Procurar por EBX - endereço, para que saibamos onde estão os
;; ponteiros para os blocos anterior ou próximo, para saber se podem ser mesclados

    mov eax, [Hexagon.Memoria.Alocador.primeiroBlocoLivre] ;; Bloco livre atual
    mov edx, [eax+8]                ;; Próximo bloco livre

.encontrarPosicao:

    cmp edx, 0                      ;; Checar o próximo
    je .blocoEncontradoFimRAM       ;; Existe bloco livre

    cmp ebx, edx                    ;; EBX está abaixo de EDX?
    jb .blocoEncontradoEntre        ;; EBX encontrado no meio

    mov eax, edx                    ;; Atualizar ponteiros para outro loop
    mov edx, [eax+8]

    jmp .encontrarPosicao

;; O bloco está entre outros dois blocos

.blocoEncontradoEntre:

    mov [ebx], eax         ;; Criar cabeçalho
    mov [ebx+4], ecx
    mov [ebx+8], edx

    mov [eax+8], ebx       ;; Atualizar cabeçalho anterior
    mov [edx], ebx         ;; Atualizar próximo cabeçalho

;; Checar se os blocos podem ser mescaldos

    add ecx, ebx

    cmp edx, ecx
    jne .mesclarApenasPrimeiro

    push eax

    add eax, [eax+4]

    cmp ebx, eax

    pop eax

    jne .mesclarApenasUltimo

;; O anterior e o próximo podem ser mescaldos

    mov ecx, [ebx+4]        ;; Obter o tamanho do bloco atual

    add [eax+4], ecx        ;; Adicionar isso ao tamanho do anterior

    mov ecx, [edx+4]        ;; Obter o tamanho do próximo bloco

    add [eax+4], ecx        ;; Adicionar isso ao tamanho anterior

    mov ecx, [edx+8]        ;; Obter o próximo ponteiro
    mov [eax+8], ecx        ;; Armazená-lo

    cmp ecx, 0
    je .fim

    mov [ecx], eax

    jmp .fim

.mesclarApenasPrimeiro:

    cmp ebx, eax
    jne .fim

    mov ecx, [ebx+4]        ;; Obter o tamanho do bloco atual

    add [eax+4], ecx        ;; Adicionar isso ao tamanho do anterior

    mov [edx], eax          ;; Atualizar o anterior e o próximo ponteiros
    mov [eax+8], edx

    jmp .fim

.mesclarApenasUltimo:

    cmp edx, ecx
    jne .fim

    mov ecx, [edx+4]

    add [ebx+4], ecx

    mov ecx, [edx+8]
    mov [ebx+8], ecx

    cmp ecx, 0
    je .fim

    mov [ecx], ebx

    jmp .fim

;; O bloco está após todos os blocos livres

.blocoEncontradoFimRAM:

    mov [ebx], eax           ;; Criar cabeçalho
    mov [ebx+4], ecx
    mov [ebx+8], edx

    mov [eax+8], ebx         ;; Atualizar cabeçalho anterior

;; Checar se os blocos podem ser mesclados

    mov ecx, eax

    add ecx, [eax+4]

    cmp ebx, ecx
    jne .fim

    mov ecx, [ebx+4]

    add [eax+4], ecx

    mov ecx, [ebx+8]
    mov [eax+8], ecx

    jmp .fim

;; O bloco está antes dos outros livres

.novoPrimeiroLivre:

    mov dword [ebx], 0
    mov [ebx+4], ecx              ;; Criar o novo cabeçalho
    mov edx, [Hexagon.Memoria.Alocador.primeiroBlocoLivre]
    mov [ebx+8], edx

    mov edx, ebx

    add edx, [ebx+4]              ;; Checar se o primeiro bloco bate

    cmp edx, [Hexagon.Memoria.Alocador.primeiroBlocoLivre] ;; Posição atual + tamanhoBloco?
    je .mesclarPrimeiroLivre      ;; Se sim, mesclar os dois

    cmp [Hexagon.Memoria.Alocador.primeiroBlocoLivre], 0   ;; Se não, checar se o primeiro bloco existe
    je .cont1

    mov edx, [ebx+8]              ;; Se sim, atualizar o ponteiro anterior
    mov [edx], ebx

.cont1:

    mov [Hexagon.Memoria.Alocador.primeiroBlocoLivre], ebx ;; Se não, criar novo

    jmp .fim                      ;; Primeira limpeza

.mesclarPrimeiroLivre:            ;; Mesclar os dois primeiros

    mov edx, [ebx+8]              ;; Adicionar o tamanho do bloco com o anterior no novo
    mov ecx, [edx+4]

    add [ebx+4], ecx

    mov ecx, [edx+8]              ;; Obter o próximo ponteiro do bloco anterior
    mov [ebx+8], ecx

    cmp ecx, 0
    je .cont2

    mov [ecx], ebx                ;; Ataulizar isso mais o próximo

.cont2:

    mov [Hexagon.Memoria.Alocador.primeiroBlocoLivre], ebx ;; Atualizar o primeiro bloco livre

.fim:

    pop edx
    pop ecx
    pop ebx
    pop eax

    ret

;;************************************************************************************

align 32

;; Dilata o espaço de memória reservado aos processos. AVISO! Todos os dados após o espaço
;; anteriormente alocado serão perdido!
;;
;; Entrada:
;;
;; EAX - Tamanho em bytes para dilatar
;;
;; Saída:
;;
;; EAX - 0 se erro
;;
;; Essa é uma função exclusiva do Kernel!

dilatarEspacoMemoria:

    mov ebx, eax
    mov ecx, eax

    push ecx

    call Hexagon.Kernel.Arch.Gen.Mm.alocarMemoria

    pop ecx

    add dword[Hexagon.Memoria.Alocador.reservadoProcessos], ecx

    ret

;;************************************************************************************