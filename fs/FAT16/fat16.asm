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
;;       Informações relevantes para o entendimento do Sistema de Arquivos FAT
;;                              (especificamente FAT16B)
;;
;;                           FAT16B para Hexagon versão 1.2
;;
;; - Cada entrada no diretório raiz tem 32 bytes de tamanho:
;;   - 11 destes, iniciais, reservam o nome do arquivo. Caso o primeiro caractere
;;     tenha sido trocado por espaço (' '), ele foi "deletado", e não deve ser exibido
;;     manipulado pelo Sistema de Arquivos ou pelo próprio Hexagon.
;; - O cluster inicial de um arquivo é adicionado no entrada no diretório raiz. Ao ler
;;   o conteúdo do cluster indicado, temos a localização do próximo cluster na cadeia.
;;   Tanto o valor inicial como o obtido devem ser utilizados para o cálculo físico do
;;   endereço no disco, carregando o valor de bytes por cluster de uma vez. Um exemplo:
;;   Se o cluster inicial for dez, o endereço deste cluster é convertido em um endereço
;;   LBA inicial, carregando quantos bytes por cluster forem necessários, caso a caso.
;;   Indo até a entrada do décimo cluster na FAT, será possível obter o número do próximo
;;   cluster na cadeia. Novamente, esse endereço de cluster é convertido em endereço físico
;;   e n bytes são carregados para a memória. Voltando a FAT, lendo a entrada do número do
;;   cluster, o próximo pode ser obtido. Caso o valor do cluster seja 0xFFF8, não se trata
;;   de um número de cluster na cadeia, mas sim que este é o último cluster na cadeia e a
;;   leitura já pode ser finalizada.
;; - Alguns atributos são verificados por essa versão do driver FAT16B do Hexagon. São
;;   lidas informações que indicariam a presença de um subdiretório ou rótulo do volume. Por
;;   ora, essas informações não são usadas. Entretanto, código para a manipulação de
;;   diretórios já está sendo escrito, e um dia essa função será incorporada.
;; - Para facilitar o desenvolvimento, as estruturas e variáveis padrão para sistemas do tipo
;;   FAT estão declaradas no corpo do Sistema de Arquivos Virtual, e são instanciadas aqui,
;;   como poderão ser em futuros sistemas FAT12 e FAT32, por exemplo.
;; - Valores soltos não serão utilizados no código, para aumentar a compreensão. Devem ser
;;   utilizadas as constantes associadas com a instância, como atributos de entrada e valores
;;   encontrados nas entradas. Apenas valores de 0 e 1 podem ser utilizados em operações
;;   lógicas. O resto dos valores devem vir das contantes e dados identificados já com seu
;;   significado, como Hexagon.VFS.FAT.FAT16B.atributoDeletado, por exemplo, indicando o
;;   código do caractere inicial que indica que o arquivo foi excluído (espaço).
;;
;;************************************************************************************

;;************************************************************************************

;; Estrutura utilizada para a manipulação de volumes FAT16B, baseada no template
;; para FAT fornecida pelo VFS

Hexagon.VFS.FAT16B Hexagon.VFS.FAT

;;************************************************************************************

;; Converte o nome no formato FAT a um nome no padrão 8.3
;;
;; Entrada:
;;
;; ESI - Ponteiro para o nome com 11 caracteres
;;
;; Saída:
;;
;; AVISO! O nome será modificado
;; CF definido caso o nome do arquivo seja inválido

Hexagon.Kernel.FS.FAT16.nomeFATParaNomeArquivo:

    push eax
    push ebx
    push ecx
    push edi
    push esi

;; Checar nome vazio

    cmp byte[esi], 0
    je .nomeArquivoInvalido ;; Se a string estiver vazia

    cmp byte[esi+8], ' '
    jne .issoEExtensao

    call Hexagon.Kernel.Lib.String.cortarString

    jmp .sucesso

.issoEExtensao:

;; Limpar buffer da operação anterior

    mov ax, ' '
    mov ecx, 12
    mov edi, .bufferNomeDeArquivo + 500h ;; Limpar buffer temporário

    cld

    rep stosb

;; Copiar nome para buffer temporário

    pop esi ;; Restaurar ESI

    push esi

    mov edi, .bufferNomeDeArquivo + 500h ;; Corrigir endereço com base do segmento
    mov ecx, 11

    rep movsb ;; Copiar (ECX) bytes de ESI para EDI

;; Obter nome de arquivo sem extensão

    mov esi, .bufferNomeDeArquivo
    mov byte[esi+8], 0

    call Hexagon.Kernel.Lib.String.cortarString

;; Adicionar ponto

    call Hexagon.Kernel.Lib.String.tamanhoString

    mov byte[esi+eax], '.'

;; Obter extensão

    pop esi

    push esi ;; Restaurar ESI

    add esi, 8

    mov byte[esi+3], 0

    call Hexagon.Kernel.Lib.String.cortarString

    mov ebx, eax ;; Salvar tamanho do nome de arquivo (sem extensão)

    call Hexagon.Kernel.Lib.String.tamanhoString

;; Colocar nome de arquivo e extensão juntos

    lea edi, [.bufferNomeDeArquivo + 500h + ebx + 1]

    mov ecx, eax

    rep movsb ;; Mover (ECX) bytes de ESI para EDI

;; Copiar buffer temporário para o endereço

    pop esi

    push esi

    mov edi, esi

;; Corrigir endereço com a base do segmento (endereço físico = endereço + base do segmento)

    add edi, 500h ;; Segmento ES com base em 500h

    mov esi, .bufferNomeDeArquivo
    mov ecx, 12

    rep movsb

    pop esi

    push esi

    add eax, ebx ;; Tamanho do nome de arquivo + tamanho da extensão

    inc eax ;; Adicionar tamanho de '.'

    mov byte[esi+eax], 0

.sucesso:

    pop esi

    push esi

    clc ;; Limpar Carry

    jmp .fim

.nomeArquivoInvalido:

    stc ;; Definir Carry

.fim:

    pop esi
    pop edi
    pop ecx
    pop ebx
    pop eax

    ret

.bufferNomeDeArquivo: times 12 db ' '

;;************************************************************************************

;; Converter nome de arquivo no padrão 8.3 para formato FAT
;;
;; Entrada:
;;
;; ESI - Nome de arquivo
;;
;; Saída:
;;
;; AVISO! O nome será modificado diretamente no endereço apontado por ESI
;; CF definido caso o nome do arquivo seja inválido

Hexagon.Kernel.FS.FAT16.nomeArquivoParaFAT:

    push eax
    push ebx
    push ecx
    push edx
    push edi
    push esi

;; Checar por string vazia

    cmp byte[esi], 0
    je .nomeArquivoInvalido ;; Se a string estiver vazia

;; Checar ponto

    mov al, '.' ;; Caractere para encontrar

    call Hexagon.Kernel.Lib.String.encontrarCaractereNaString

    jnc .ponto

    call Hexagon.Kernel.Lib.String.tamanhoString

    cmp eax, 8 ;; Mais de oito caracteres não são permitidos no formato 8.3
    ja .nomeArquivoInvalido

    call Hexagon.Kernel.Lib.String.stringParaMaiusculo

    mov ecx, 11
    sub ecx, eax

    mov edx, eax

    pop esi

    push esi

    push es

    push ds ;; Segmento de dados do kernel
    pop es

;; Ter certeza que o nome possui exatamente 11 caracteres

    mov edi, esi

    add edi, eax

    mov al, ' '

    rep stosb

    pop es

    clc

    jmp .fim

.ponto:

    push eax

;; Limpar o buffer temporário da operação anterior

    mov al, ' '
    mov ecx, 11
    mov edi, .bufferNomeDeArquivo + 500h ;; Limpar buffer temporário

    cld

    rep stosb

    pop eax

    cmp al, 1
    ja .nomeArquivoInvalido ;; Se o ponto ocorrer mais de uma vez

    call Hexagon.Kernel.Lib.String.stringParaMaiusculo ;; Todos os nomes de arquivo FAT são em maiúsculo

;; Checar posição do '.'

    mov ebx, 0 ;; EBX é o contador da posição do ponto na string

.encontrarPontoLoop:

    mov al, byte[esi]

    cmp al, '.'
    je .pontoEncontrado

    inc esi
    inc ebx

    jmp .encontrarPontoLoop

.pontoEncontrado:

    cmp ebx, 8
    ja .nomeArquivoInvalido ;; Se o nome do arquivo apresenta mais de 8 caracteres

    cmp ebx, 1
    jb .nomeArquivoInvalido ;; Se o nome de arquivo apresenta menos de 1 caractere

;; Salvar o nome do arquivo em um buffer temporário (sem extensão)

    pop esi ;; Restaurar ESI

    push esi

;; Corrigir endereço com a base do segmento (endereço físico = endereço + base do segmento)

    mov edi, .bufferNomeDeArquivo + 500h
    mov ecx, ebx

    cld

    rep movsb ;; Move (ECX) caracteres de ESI para o buffer

;; Agora checar extensão

    pop esi ;; Restaurar ESI

    push esi

    add esi, ebx ;; EBX para o tamanho do nome do arquivo
    add esi, 1   ;; 1 byte para o caractere '.'

    call Hexagon.Kernel.Lib.String.tamanhoString ;; Checar tamanho da extensão

    cmp eax, 1
    jb .nomeArquivoInvalido ;; Se a extensão tem menos de 1 caractere de tamanho

    cmp eax, 3
    ja .nomeArquivoInvalido ;; Se a extensão tem mais de 3 caracteres de tamanho

;; Salvar extensão em um buffer temporário

    mov edi, .bufferNomeDeArquivo + 500h + 8
    mov ecx, eax

    cld

    rep movsb ;; Move (ECX) caracteres de ESI para o buffer

.sucesso:

;; Salvar buffer na posição indicada por ESI

    pop esi ;; Salvar ESI

    push esi

    mov edi, esi

;; Corrigir endereço com a base do segmento (endereço físico = endereço + base do segmento)

    add edi, 500h

    mov esi, .bufferNomeDeArquivo
    mov ecx, 11

    cld

    rep movsb ;; Mover (ECX) caracteres do buffer para ESI

    clc ;; Limpar Carry

    jmp .fim

.nomeArquivoInvalido:

    stc ;; Definir Carry

.fim:

    pop esi
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax

    ret

.bufferNomeDeArquivo: times 11 db ' '

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

Hexagon.Kernel.FS.FAT16.renomearArquivoFAT16B:

    pushad

    clc

    push edi

;; Checar se o arquivo já existe

    call Hexagon.Kernel.FS.FAT16.arquivoExisteFAT16B

    jc .falha

    pop edi

    mov esi, edi

    push ebx

    call Hexagon.Kernel.FS.FAT16.arquivoExisteFAT16B

    pop ebx

    jnc .falha

    push ebx

    call Hexagon.Kernel.FS.FAT16.nomeArquivoParaFAT

    pop ebx

;; Em EBX, o ponteiro para a entrada no diretório raiz

    mov edi, ebx

;; Corrigir endereço com a base do segmento (endereço físico = endereço + base do segmento)

    add edi, 500h

    mov ecx, 11

    rep movsb ;; Mover (ECX) vezes a string em ESI para EDI

;; Escrever diretório raiz modificado no disco

    movzx eax, word[Hexagon.VFS.FAT16B.tamanhoDirRaiz] ;; Setores para escrever
    mov esi, dword[Hexagon.VFS.FAT16B.dirRaiz] ;; LBA diretório raiz
    mov cx, 50h ;; Segmento
    mov edi, Hexagon.Heap.CacheDisco + 20000 ;; Deslocamento
    mov dl, byte[Hexagon.Dev.Gen.Disco.Controle.driveAtual]

    call Hexagon.Kernel.Dev.i386.Disco.Disco.escreverSetores

    jc .falha

.fim:

    popad

    ret

.falha:

    stc ;; Definir Carry

    jmp .fim

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
;; CF definido caso o arquivo não exista ou tenha nome inválido

Hexagon.Kernel.FS.FAT16.arquivoExisteFAT16B:

    push ecx
    push edx
    push edi
    push esi

    call Hexagon.Kernel.Lib.String.tamanhoString

    cmp eax, 12
    ja .falha ;; Em caso de nome inválido

    inc eax ;; Nome de arquivo incluindo 0

;; Copiar nome de arquivo para buffer temporário

    mov edi, .bufferNomeDeArquivo + 500h
    mov ecx, eax ;; Tamanho do nome de arquivo

    cld

    rep movsb ;; Mover (ECX) string em ESI para EDI

;; Tornar nome compatível com FAT

    mov esi, .bufferNomeDeArquivo

    call Hexagon.Kernel.FS.FAT16.nomeArquivoParaFAT

    jc .falha ;; Em caso de nome inválido

;; Carregar diretório raiz no disco

    movzx eax, word[Hexagon.VFS.FAT16B.tamanhoDirRaiz] ;; Setores para carregar
    mov esi, dword[Hexagon.VFS.FAT16B.dirRaiz] ;; LBA do diretório raiz
    mov cx, 50h ;; Segmento
    mov edi, Hexagon.Heap.CacheDisco + 20000 ;; Deslocamento
    mov dl, byte[Hexagon.Dev.Gen.Disco.Controle.driveAtual]

    call Hexagon.Kernel.Dev.i386.Disco.Disco.lerSetores

;; Procurar nome em todas as entradas

    movzx edx, word[Hexagon.VFS.FAT16B.entradasRaiz] ;; Total de pastas ou arquivos no diretório raiz
    mov ebx, Hexagon.Heap.CacheDisco + 500h + 20000

    cld ;; Limpar bandeira de direção

.loopBuscaArquivo:

    mov ecx, 11 ;; 11 caracteres no nome de arquivo
    mov edi, ebx
    mov esi, .bufferNomeDeArquivo

    rep cmpsb ;; Compara (ECX) caracteres entre EDI e ESI

    je .arquivoEncontrado

    add ebx, 32

    dec edx

    jnz .loopBuscaArquivo

    jmp .falha ;; Arquivo não encontrado

.arquivoEncontrado:

    mov eax, dword[es:ebx+28] ;; Tamanho do arquivo

;; Corrigir endereço com a base do segmento (endereço físico = endereço + base do segmento)

    sub ebx, 500h ;; Segmento ES

.sucessoOperacao:

    clc ;; Limpar Carry

    jmp .fim

.falha:

    stc ;; Definir Carry

    jmp .fim

.fim:

    pop esi
    pop edi
    pop edx
    pop ecx

    ret

.bufferNomeDeArquivo: times 13 db ' '

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
;; CF definido em caso de arquivo não encontrado ou nome inválido

Hexagon.Kernel.FS.FAT16.carregarArquivoFAT16B:

    push ebx
    push ecx
    push edx
    push edi
    push esi

    mov dword[.enderecoCarregamento], edi

;; Checar se o arquivo existe e obter o primeiro cluster do mesmo

    call Hexagon.Kernel.FS.FAT16.arquivoExisteFAT16B

    jc .falha

    mov [.tamanhoArquivo], eax ;; Salvar tamanho do arquivo

    mov ax, word[ebx+26]   ;; EBX é o ponteiro para a entrada no diretório raiz
    mov word[.cluster], ax ;; Salvar o primeiro cluster

;; Carregar FAT do disco para obter os cluster do arquivo

    movzx eax, word[Hexagon.VFS.FAT16B.setoresPorFAT] ;; Setores para carregar
    mov esi, dword[Hexagon.VFS.FAT16B.FAT] ;; LBA da FAT
    mov ecx, 50h ;; Segmento
    mov edi, Hexagon.Heap.CacheDisco + 20000 ;; Deslocamento

    mov dl, byte[Hexagon.Dev.Gen.Disco.Controle.driveAtual]

    call Hexagon.Kernel.Dev.i386.Disco.Disco.lerSetores

    mov ebp, dword[Hexagon.VFS.FAT16B.tamanhoCluster] ;; Salvar tamanho do cluster
    mov cx,  00h ;; Segmento de modo real
    mov edi, dword[.enderecoCarregamento] ;; Deslocamento

;; Encontrar cluster e carregar a cadeia de clusters

.loopCarregamentoClusters:

;; Converter endereço lógico [cluster] para LBA (endereço físico)
;;
;; Fórmula:
;;
;;((cluster - 2) * setoresPorCluster) + areaDeDados

    movzx esi, word[.cluster]

    sub esi, 2

    movzx eax, byte[Hexagon.VFS.FAT16B.setoresPorCluster]

    xor edx, edx ;; DX = 0

    mul esi ;; (cluster - 2) * setoresPorCluster

    mov esi, eax

    add esi, dword[Hexagon.VFS.FAT16B.areaDeDados]

    movzx ax, byte[Hexagon.VFS.FAT16B.setoresPorCluster] ;; Total de setores para carregar

    mov dl, byte[Hexagon.Dev.Gen.Disco.Controle.driveAtual]

;; Carregar o cluster para um buffer temporário

    push edi

;; Corrigir endereço com a base do segmento (endereço físico = endereço + base do segmento)

    mov edi, Hexagon.Heap.CacheDisco + 500h

    call Hexagon.Kernel.Dev.i386.Disco.Disco.lerSetores

    pop edi

;; Copiar o cluster para a sua localização original

    push edi

;; Corrigir endereço com a base do segmento (endereço físico = endereço + base do segmento)

    add edi, 500h

    mov esi, Hexagon.Heap.CacheDisco
    mov ecx, ebp ;; EBP possui os bytes por setor

    cld

    rep movsb ;; Mover (ECX) bytes de ESI para EDI

    pop edi

;; Obter próximo cluster na tabela FAT

    movzx ebx, word[.cluster]

    shl ebx, 1 ;; BX * 2 (2 bytes na entrada)

    add ebx, Hexagon.Heap.CacheDisco + 20000 ;; Localização da FAT

    mov si, word[ebx] ;; SI contém o próximo cluster

    mov word[.cluster], si ;; Salvar

;; 0xFFF8 é o marcador de fim de arquivo (End Of File - EOF)

    cmp si, Hexagon.VFS.FAT16B.atributoUltimoCluster ;; EOF?
    jae .sucessoOperacao

;; Adicionar espaço vazio para próximo cluster

    add edi, ebp ;; EBP contém bytes por cluster

    jmp .loopCarregamentoClusters

.sucessoOperacao:

    mov eax, [.tamanhoArquivo]

    clc ;; Limpar Carry

    jmp .fim

.falha:

    stc ;; Definir Carry

    jmp .fim

.fim:

    pop esi
    pop edi
    pop edx
    pop ecx
    pop ebx

    ret

.cluster               dw 0
.enderecoCarregamento: dd 0
.tamanhoArquivo:       dd 0

;;************************************************************************************

;; Obter a lista de arquivos no diretório raiz
;;
;; Saída:
;;
;; ESI - Ponteiro para a lista de arquivos
;; EAX - Número de arquivos total

Hexagon.Kernel.FS.FAT16.listarArquivosFAT16B:

    clc

    push ebx
    push ecx
    push edx
    push edi

;; Carregar diretório raiz

    movzx eax, word[Hexagon.VFS.FAT16B.tamanhoDirRaiz] ;; Setores para carregar
    mov esi, dword[Hexagon.VFS.FAT16B.dirRaiz] ;; LBA do diretório raiz
    mov cx, 50h ;; Segmento
    mov edi, Hexagon.Heap.CacheDisco + 20000 ;; Deslocamento
    mov dl, byte[Hexagon.Dev.Gen.Disco.Controle.driveAtual]

    call Hexagon.Kernel.Dev.i386.Disco.Disco.lerSetores

    jc .erroLista

;; Construir a lista
;; Corrigir endereço com a base do segmento (endereço físico = endereço + base do segmento)

    mov edx, Hexagon.Heap.CacheDisco + 500h ;; Índice na nova lista
    mov ebx, 0 ;; Contador de arquivos
    mov esi, Hexagon.Heap.CacheDisco + 20000 ;; Deslocamento no diretório raiz

    sub esi, 32

.loopConstruirLista:

    add esi, 32 ;; Próxima entrada (32 bytes por entrada)

;; Vamos checar alguns atributos da entrada, como se se trata de um diretório
;; ou ainda um rótulo de volume. Por hora, caso se trata destas entrada, iremos
;; pular, até o suporte ser completado.

    mov al, byte[esi+11] ;; Atributos do arquivo

    bt ax, Hexagon.VFS.FAT16B.bitDiretorio ;; Se subdiretório, pule
    jc .loopConstruirLista

    bt ax, Hexagon.VFS.FAT16B.bitNomeVolume ;; Se rótulo do volume, pule
    jc .loopConstruirLista

;; Agora, vamos obter mais informações sobre a entrada

    cmp byte[esi+11], Hexagon.VFS.FAT16B.atributoLFN ;; Se nome de arquivo longo, pule
    je .loopConstruirLista ;; Em caso de nome longo, pule a entrada (por hora)

    cmp byte[esi], Hexagon.VFS.FAT16B.atributoDeletado ;; Se arquivo deletado, pule
    je .loopConstruirLista ;; Em caso de arquivo deletado, pule a entrada

    cmp byte[esi], 0   ;; Se último arquivo, termine
    je .finalizarLista ;; Se este for o último arquivo, não vamos querer procurar mais
                       ;; no diretório atrás de algo que não existe ;-)

    call Hexagon.Kernel.FS.FAT16.nomeFATParaNomeArquivo ;; Converter nome para formato 8.3

;; Adicionar entrada de nome de arquivo na lista

    call Hexagon.Kernel.Lib.String.tamanhoString ;; Encontrar tamanho da entrada

    push esi

    mov edi, edx
    mov ecx, eax ;; EAX é o tamanho da primeira string

    rep movsb ;; Move (ECX) bytes de ESI para EDI

    pop esi

;; Adicionar um espaço entre os nomes de arquivo, útil para a manipulação da lista

    mov byte[es:edx+eax], ' '

    inc eax ;; Tamanho da string + 1 caractere
    inc ebx ;; Atualizar contador de arquivos

    add edx, eax ;; Atualizar índice na lista

    jmp .loopConstruirLista ;; Obter próximos arquivos

.finalizarLista:

;; Corrigir endereço com a base do segmento (endereço físico = endereço + base do segmento)

    mov byte[edx-500h], 0 ;; Fim da string

    mov esi, Hexagon.Heap.CacheDisco
    mov eax, ebx

    jmp .fim

.erroLista:

    stc

.fim:

    pop edi
    pop edx
    pop ecx
    pop ebx

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
;; CF definido em caso de erro ou arquivo já existente

Hexagon.Kernel.FS.FAT16.salvarArquivoFAT16B:

    push eax
    push ebx
    push ecx
    push edx
    push edi
    push esi

    mov ebp, edi ;; Salvar EDI
    mov dword[.tamanhoArquivo], eax ;; Salvar tamanho do arquivo

;; Criar novo arquivo

    call Hexagon.Kernel.FS.FAT16.novoArquivoFAT16B

    jc .falha ;; Se arquivo já existir, retorne

;; Carregar FAT do disco

    movzx eax, word[Hexagon.VFS.FAT16B.setoresPorFAT] ;; Setores para carregar
    mov esi, dword[Hexagon.VFS.FAT16B.FAT] ;; LBA do diretório raiz
    mov ecx, 50h ;; Segmento
    mov edi, Hexagon.Heap.CacheDisco + 20000 ;; Deslocamento

    mov dl, byte[Hexagon.Dev.Gen.Disco.Controle.driveAtual]

    call Hexagon.Kernel.Dev.i386.Disco.Disco.lerSetores

;; Calcular número de clusteres necessários
;;
;; Fórmula:
;;
;; Número requerido = .tamanhoArquivo / tamanhoCluster

    mov eax, dword[.tamanhoArquivo]
    mov ebx, dword[Hexagon.VFS.FAT16B.tamanhoCluster]
    mov edx, 0

    div ebx ;; .tamanhoArquivo / tamanhoCluster

    inc eax

    mov dword[.clustersNecessarios], eax

    mov ecx, eax ;; Contador do loop

    mov esi, Hexagon.Heap.CacheDisco + 20000

    add esi, (3*2) ;; Clusters reservados

    mov edx, 3 ;; Contador de clusters lógicos
    mov edi, Hexagon.Heap.CacheDisco + 500h ;; Ponteiro para a lista de clusters livres
    mov eax, 0

;; Obter lista de clusters livres da FAT

.encontrarClustersLivresLoop:

    mov ax, word[esi] ;; Carregar entrada FAT

    or ax, ax ;; Comparar AX com 0
    jz .clusterLivreEncontrado

    add esi, 2 ;; Próxima entrada FAT

    inc edx

    jmp .encontrarClustersLivresLoop

.clusterLivreEncontrado:

;; Armazenar clusters livres em uma lista

    mov word[esi], 0xFFFF

    mov ax, dx

    stosw ;; mov word[ES:EDI], AX & add EDI, 2

    loop .encontrarClustersLivresLoop

    movzx edx, word[Hexagon.Heap.CacheDisco]

    push edx ;; Cluster livre

;; Tudo requer uma lista de clusters livres

;; Criar cadeia de clusters na FAT

    mov ecx, dword[.clustersNecessarios]
    mov esi, Hexagon.Heap.CacheDisco ;; Lista de clusters livres (words)

.criarCadeiaClusters:

    mov dx, word[esi] ;; Cluster atual

    mov edi, Hexagon.Heap.CacheDisco + 20000 ;; Endereço da FAT
    shl dx, 1 ;; Multiplicar por 2

    add di, dx ;; EDI é o ponteiro da atual entrada FAT

    cmp ecx, 1 ;; Feito
    je .cadeiaClustersPronta

    mov ax, word[esi+2] ;; Próximo cluster
    mov word[edi], ax ;; Salvar próximo cluster da tabela FAT

    add esi, 2 ;; Próximo cluster livre

    loop .criarCadeiaClusters

.cadeiaClustersPronta:

    mov word[edi], 0xFFFF ;; 0xFFFF indica último cluster

;; Escrever tabela FAT no disco

    movzx eax, word[Hexagon.VFS.FAT16B.setoresPorFAT] ;; Setores para escrever
    mov esi, dword[Hexagon.VFS.FAT16B.FAT] ;; LBA do diretório raiz
    mov ecx, 50h ;; Segmento
    mov edi, Hexagon.Heap.CacheDisco + 20000 ;; Deslocamento

    mov dl, byte[Hexagon.Dev.Gen.Disco.Controle.driveAtual]

    call Hexagon.Kernel.Dev.i386.Disco.Disco.escreverSetores

    pop ecx ;; Cluster livre

;; Obter entrada no diretório raiz

    pop esi ;; Restaurar ESI

    push esi

    call Hexagon.Kernel.FS.FAT16.arquivoExisteFAT16B

    jc .falha

;; EBX é um ponteiro para a entrada no diretório raiz

    mov eax, dword[.tamanhoArquivo]
    mov dword[ebx+28], eax ;; Tamanho
    mov word[ebx+26], cx ;; Primeiro cluster

;; Escrever diretório raiz modificado no disco

    movzx eax, word[Hexagon.VFS.FAT16B.tamanhoDirRaiz] ;; Setores para escrever
    mov esi, dword[Hexagon.VFS.FAT16B.dirRaiz] ;; LBA diretório raiz
    mov cx, 50h ;; Segmento
    mov edi, Hexagon.Heap.CacheDisco + 20000 ;; Deslocamento
    mov dl, byte[Hexagon.Dev.Gen.Disco.Controle.driveAtual]

    call Hexagon.Kernel.Dev.i386.Disco.Disco.escreverSetores

;; Salvar dados nos clusters livres

    mov ebx, Hexagon.Heap.CacheDisco ;; Lista de clusters vazios
    movzx ecx, word[.clustersNecessarios]

;; Converter endereço lógico [cluster] para LBA
;;
;; Fórmula:
;;
;; ((cluster - 2) * setoresPorCluster) + areaDeDados

.escreverDadosNosClusters:

    push ecx

;; Copiar dados atuais para um buffer temporário

    mov esi, ebp
    mov edi, Hexagon.Heap.CacheDisco + 500h + 20000
    mov ecx, dword[Hexagon.VFS.FAT16B.tamanhoCluster]

    rep movsb

    movzx esi, word[ebx]

    sub esi, 2

    movzx eax, byte[Hexagon.VFS.FAT16B.setoresPorCluster]
    xor edx, edx ;; DX = 0

    mul esi ;; (cluster - 2) * setoresPorCluster

    mov esi, eax

    add esi, dword[Hexagon.VFS.FAT16B.areaDeDados]

    movzx ax, byte[Hexagon.VFS.FAT16B.setoresPorCluster] ;; Total de setores a escrever

    mov dl, byte[Hexagon.Dev.Gen.Disco.Controle.driveAtual]

;; Escrever buffer temporário

    mov edi, Hexagon.Heap.CacheDisco + 500h + 20000
    mov ecx, 0 ;; Segmento de modo real

    call Hexagon.Kernel.Dev.i386.Disco.Disco.escreverSetores

    pop ecx

    add ebp, dword[Hexagon.VFS.FAT16B.tamanhoCluster] ;; Próximo bloco de dados
    add ebx, 2 ;; Próximo cluster livre

    loop .escreverDadosNosClusters

.sucessoOperacao:

    clc ;; Limpar Carry

    jmp .fim

.falha:

    stc ;; Definir Carry

    jmp .fim

.fim:

    pop esi
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax

    ret

.tamanhoArquivo:      dd 0
.clustersNecessarios: dd 0

;;************************************************************************************

;; Remover um arquivo do disco
;;
;; Entrada:
;;
;; ESI - Ponteiro para o nome de arquivo

Hexagon.Kernel.FS.FAT16.deletarArquivoFAT16B:

    pushad

    call Hexagon.Kernel.FS.FAT16.arquivoExisteFAT16B

    jc .fim

;; A entrada do diretório raiz já está carregada, devido a Hexagon.Kernel.FS.FAT16.arquivoExisteFAT16B

    mov ax, word[ebx+26] ;; Obter o primeiro cluster
    mov word[.cluster], ax ;; Salvar

;; Marcar o arquivo como deletado

    mov byte[ebx], Hexagon.VFS.FAT16B.atributoDeletado

;; Escrever diretório raiz modificado no disco

    movzx eax, word[Hexagon.VFS.FAT16B.tamanhoDirRaiz] ;; Setores para escrever
    mov esi, dword[Hexagon.VFS.FAT16B.dirRaiz] ;; LBA do diretório raiz
    mov cx, 50h ;; Segmento
    mov edi, Hexagon.Heap.CacheDisco + 20000 ;; Deslocamento
    mov dl, byte[Hexagon.Dev.Gen.Disco.Controle.driveAtual]

    call Hexagon.Kernel.Dev.i386.Disco.Disco.escreverSetores

;; Limpar clusters alocados para o arquivo na FAT

;; Carregar FAT no disco

    movzx eax, word[Hexagon.VFS.FAT16B.setoresPorFAT] ;; Setores para carregar
    mov esi, dword[Hexagon.VFS.FAT16B.FAT] ;; LBA da FAT
    mov ecx, 50h ;; Segmento
    mov edi, Hexagon.Heap.CacheDisco + 20000 ;; Deslocamento

    mov dl, byte[Hexagon.Dev.Gen.Disco.Controle.driveAtual]

    call Hexagon.Kernel.Dev.i386.Disco.Disco.lerSetores

.proximoCluster:

;; Calcular próximo cluster

    mov edi, Hexagon.Heap.CacheDisco + 20000 ;; Tabela FAT
    movzx esi, word[.cluster]
    shl esi, 1 ;; Multiplica por 2

    add edi, esi

    mov ax, word[edi]

    mov word[.cluster], ax

    mov word[edi], 0 ;; Marcar cluster como livre

    cmp ax, Hexagon.VFS.FAT16B.atributoUltimoCluster ;; 0xFFF8 é marcador de fim de arquivo (EOF)
    jae .todosClustersDeletados

    jmp .proximoCluster

.todosClustersDeletados:

;; Escrever FAT no disco

    movzx eax, word[Hexagon.VFS.FAT16B.setoresPorFAT] ;; Setores para escrever
    mov esi, dword[Hexagon.VFS.FAT16B.FAT] ;; LBA da FAT
    mov ecx, 50h ;; Segmento
    mov edi, Hexagon.Heap.CacheDisco + 20000 ;; Deslocamento

    mov dl, byte[Hexagon.Dev.Gen.Disco.Controle.driveAtual]

    call Hexagon.Kernel.Dev.i386.Disco.Disco.escreverSetores

.fim:

    popad

    ret

.cluster: dw 0

;;************************************************************************************

Hexagon.Kernel.FS.FAT16.obterInfoFAT16B:

    mov ax, word[es:esi+8] ;; Bytes por setor
    mov word[Hexagon.VFS.FAT16B.bytesPorSetor], ax

    mov al, byte[es:esi+10] ;; Setores por cluster
    mov byte[Hexagon.VFS.FAT16B.setoresPorCluster], al

    mov ax, word[es:esi+11] ;; Setores reservados
    mov word[Hexagon.VFS.FAT16B.setoresReservados], ax

    mov al, byte[es:esi+13] ;; Número de tabelas FAT
    mov byte[Hexagon.VFS.FAT16B.totalFATs], al

    mov ax, word[es:esi+14] ;; Entradas no diretório raiz
    mov word[Hexagon.VFS.FAT16B.entradasRaiz], ax

    mov ax, word[es:esi+19] ;; Setores por FAT
    mov word[Hexagon.VFS.FAT16B.setoresPorFAT], ax

    mov eax, dword[es:esi+29] ;; Total de setores
    mov dword[Hexagon.VFS.FAT16B.totalSetores], eax

    mov eax, dword[es:esi+36] ;; Serial do volume
    mov dword[Hexagon.VFS.Controle.serialVolume], eax

    mov byte[Hexagon.VFS.Controle.serialVolume+4], 0

;; Obter o rótulo do volume utilizado

    mov eax, dword[es:esi+40] ;; Rótulo do volume
    mov dword[Hexagon.VFS.Controle.rotuloVolume], eax

    mov eax, dword[es:esi+44] ;; Rótulo do volume
    mov dword[Hexagon.VFS.Controle.rotuloVolume+4], eax

    mov eax, dword[es:esi+48] ;; Rótulo do volume
    mov dword[Hexagon.VFS.Controle.rotuloVolume+8], eax

;; Agora devemos terminar a "string" de rótulo do volume

    mov byte[Hexagon.VFS.Controle.rotuloVolume+11], 0

;; Calcular o tamanho do diretório raiz
;;
;; Fórmula:
;;
;; Tamanho  = (entradasRaiz * 32) / bytesPorSetor

    mov ax, word[Hexagon.VFS.FAT16B.entradasRaiz]
    shl ax, 5 ;; Multiplicar por 32
    mov bx, word[Hexagon.VFS.FAT16B.bytesPorSetor]
    xor dx, dx ;; DX = 0

    div bx ;; AX = AX / BX

    mov word[Hexagon.VFS.FAT16B.tamanhoDirRaiz], ax ;; Salvar o tamanho do diretório raiz

;; Calcular o tamanho de todas as tabelas FAT
;;
;; Fórmula:
;;
;; Tamanho  = totalFATs * setoresPorFAT

    mov ax, word[Hexagon.VFS.FAT16B.setoresPorFAT]
    movzx bx, byte[Hexagon.VFS.FAT16B.totalFATs]
    xor dx, dx ;; DX = 0

    mul bx ;; AX = AX * BX

    mov word[Hexagon.VFS.FAT16B.tamanhoFATs], ax ;; Salvar tamanho da(s) FAT(s)

;; Calcular endereço da área de dados
;;
;; Fórmula:
;;
;; setoresReservados + tamanhoFATs + tamanhoDirRaiz

    movzx eax, word[Hexagon.VFS.FAT16B.setoresReservados]

    add ax, word[Hexagon.VFS.FAT16B.tamanhoFATs]
    add ax, word[Hexagon.VFS.FAT16B.tamanhoDirRaiz]

    mov dword[Hexagon.VFS.FAT16B.areaDeDados], eax

;; Calcular endereço LBA do diretório raiz
;;
;; Fórmula:
;;
;; LBA  = setoresReservados + tamanhoFATs

    movzx esi, word[Hexagon.VFS.FAT16B.setoresReservados]
    add si, word[Hexagon.VFS.FAT16B.tamanhoFATs]
    mov dword[Hexagon.VFS.FAT16B.dirRaiz], esi

;; Calcular endereço LBA da tabela FAT
;;
;; Fórmula:
;;
;; LBA  = setoresReservados

    movzx esi, word[Hexagon.VFS.FAT16B.setoresReservados]
    mov dword[Hexagon.VFS.FAT16B.FAT], esi

;; Calcular o tamanho do cluster em bytes
;;
;; Fórmula:
;;
;; setoresPorCluster * bytesPorSetor

    movzx eax, byte[Hexagon.VFS.FAT16B.setoresPorCluster]
    movzx ebx, word[Hexagon.VFS.FAT16B.bytesPorSetor]
    xor edx, edx

    mul ebx ;; AX = AX * BX

    mov dword[Hexagon.VFS.FAT16B.tamanhoCluster], eax

    ret

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
;; CF definido em caso de arquivo já existir

Hexagon.Kernel.FS.FAT16.novoArquivoFAT16B:

    pushad

;; Checar se o arquivo já existe

    call Hexagon.Kernel.FS.FAT16.arquivoExisteFAT16B

    jnc .falha

    call Hexagon.Kernel.Lib.String.tamanhoString

    cmp eax, 12
    ja .falha ;; Em caso de nome inválido

    inc eax ;; Nome de arquivo incluindo 0

;; Copiar o nome de arquivo para um buffer temporário

    mov edi, .bufferNomeDeArquivo + 500h
    mov ecx, eax ;; Tamanho do nome de arquivo

    cld

    rep movsb ;; Mover (ECX) vezes a string em ESI para EDI

;; Converter para nome de arquivo compatível FAT

    mov esi, .bufferNomeDeArquivo

    call Hexagon.Kernel.FS.FAT16.nomeArquivoParaFAT

    jc .falha ;; Em caso de nome de arquivo inválido

    push esi

;; Carregar diretório raiz do disco

    movzx eax, word[Hexagon.VFS.FAT16B.tamanhoDirRaiz] ;; Setores para carregar
    mov esi, dword[Hexagon.VFS.FAT16B.dirRaiz] ;; LBA diretório raiz
    mov cx, 50h ;; Segmento
    mov edi, Hexagon.Heap.CacheDisco + 20000 ;; Deslocamento
    mov dl, byte[Hexagon.Dev.Gen.Disco.Controle.driveAtual]

    call Hexagon.Kernel.Dev.i386.Disco.Disco.lerSetores

    mov edi, Hexagon.Heap.CacheDisco + 20000
    movzx ecx, word[Hexagon.VFS.FAT16B.entradasRaiz]

;; Procurar entrada vazia no diretório raiz

.encontrarEntradaVaziaLoop:

    cmp byte[edi], Hexagon.VFS.FAT16B.atributoDeletado ;; Arquivo deletado
    je .entradaVaziaEncontrada

    cmp byte[edi], 0 ;; Entrada não usada
    je .entradaVaziaEncontrada

    add edi, 32

    loop .encontrarEntradaVaziaLoop

.entradaVaziaNaoEncontrada:

    jmp .falha

.entradaVaziaEncontrada:

;; Copiar nome de arquivo para o buffer de diretório raiz

    pop esi ;; Restaurar ESI

    mov ecx, 11 ;; Tamanho do nome de arquivo

    push edi

;; Corrigir endereço com a base do segmento (endereço físico = endereço + base do segmento)

    add edi, 500h ;; Segmento ES

    rep movsb ;; Move (ECX) bytes de ESI para EDI

    pop edi ;; Restaurar EDI

    push edi

;; Limpar outros campos da entrada do arquivo no diretório raiz, a partir do nome do arquivo

    add edi, 500h + 11 ;; Pular para o término do nome do arquivo
    mov ecx, 32 - 11   ;; Fazer isso para 32 bytes de entrada menos os primeiros 11 do nome
    mov al, 0

    cld

    rep stosb ;; mov AL em (ECX) bytes de EDI

;; Escrever diretório raiz modificado no disco

    movzx eax, word[Hexagon.VFS.FAT16B.tamanhoDirRaiz] ;; Setores para escrever
    mov esi, dword[Hexagon.VFS.FAT16B.dirRaiz] ;; LBA do diretório raiz
    mov cx, 50h ;; Segmento
    mov edi, Hexagon.Heap.CacheDisco + 20000 ;; Deslocamento
    mov dl, byte[Hexagon.Dev.Gen.Disco.Controle.driveAtual]

    call Hexagon.Kernel.Dev.i386.Disco.Disco.escreverSetores

    pop esi ;; Ponteiro para a entrada do diretório raiz

.sucessoOperacao:

    clc ;; Limpar Carry

    jmp .fim

.falha:

    stc ;; Definir Carry

    jmp .fim

.fim:

    popad

    ret

.bufferNomeDeArquivo: times 13 db ' '

;;************************************************************************************

;; Inicializa os discos

Hexagon.Kernel.FS.FAT16.iniciarVolumeFAT16B:

;; Obter informações da BPB e armazenarem estruturas do sistema

    call Hexagon.Kernel.Dev.i386.Disco.Disco.lerBPB

    mov esi, dword[Hexagon.Memoria.enderecoBPB]

    call Hexagon.Kernel.FS.FAT16.obterInfoFAT16B

    ret
