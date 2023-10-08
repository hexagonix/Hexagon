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

Hexagon.Teclado.Unix.Codigo:

.EOL = 10h

;;************************************************************************************

;; Obter tamanho de uma string
;;
;; Entrada:
;;
;; ESI - String
;;
;; Saída:
;;
;; EAX - Tamanho da String

Hexagon.Kernel.Lib.String.tamanhoString:

    push ecx
    push esi
    push edi
    push es

    push ds ;; ES = DS
    pop es

    mov edi, esi

    or ecx, 0xffffffff

    xor al, al

    cld ;; Limpar direção

    repne scasb ;; Procurar fim da string em EDI

    or eax, 0xffffffff

    sub eax, ecx

    dec eax ;; Não incluindo caractere 0

    pop es
    pop edi
    pop esi
    pop ecx

    ret

;;************************************************************************************

;; Comparar primeiras palavras de duas strings
;;
;; Entrada:
;;
;; ESI - Primeira string
;; EDI - Segunda string
;;
;; Saída:
;;
;; Carry definido se as strings são iguais

Hexagon.Kernel.Lib.String.compararPalavrasNaString:

    push eax
    push esi
    push edi

.loopComparar:

    mov al, byte[esi]

    cmp al, ' '
    je .igual

    cmp al, byte[edi]
    jne .naoIgual

    cmp byte[edi], 0
    je .igual

    inc esi

    inc edi

    jmp .loopComparar

.naoIgual:

    clc

    jmp .fim

.igual:

    cmp byte[edi], 0
    jne .naoIgual

    stc

.fim:

    pop edi
    pop esi
    pop eax

    ret

;;************************************************************************************

;; Comparar duas strings
;;
;; Entrada:
;;
;; ESI - Primeira string
;; EDI - Segunda string
;;
;; Saída:
;;
;; Carry definido se as strings forem iguais

Hexagon.Kernel.Lib.String.compararString:

    push eax
    push esi
    push edi

.loopComparar:

    mov al, byte[edi]

    cmp al, 0 ;; Fim da string
    je .igual

    cmp al, byte[esi]
    jne .naoIgual

    inc esi

    inc edi

    jmp .loopComparar

.naoIgual:

    clc

    jmp .fim

.igual:

    stc

.fim:

    pop edi
    pop esi
    pop eax

    ret

;;************************************************************************************

;; Converter uma string para maiúsculo
;;
;; Entrada:
;;
;; ESI - String

Hexagon.Kernel.Lib.String.stringParaMaiusculo:

    push eax
    push ecx
    push esi

    mov al, byte[esi]

    cmp al, 0
    je .fim

    call Hexagon.Kernel.Lib.String.tamanhoString

    mov ecx, eax

.loopConverter:

    mov al, byte[esi]

.checar1:

    cmp al, 'a' ;; Checar se o caractere é minúsculo
    jae .checar2

    inc esi

    loop .loopConverter

    jmp .fim

.checar2:

    cmp al, 'z' ;; Checar se o caractere é minúsculo
    jbe .ok

    inc esi

    loop .loopConverter

    jmp .fim

.ok:

    sub al, ' ' ;; Converter se o caractere for minúsculo
    mov byte[esi], al

    inc esi

    loop .loopConverter

.fim:

    pop esi
    pop ecx
    pop eax

    ret

;;************************************************************************************

;; Converter uma string para minúsculo
;;
;; Entrada:
;;
;; ESI - String

Hexagon.Kernel.Lib.String.stringParaMinusculo:

    push eax
    push ecx
    push esi

    mov al, byte[esi]

    cmp al, 0
    je .fim

    call Hexagon.Kernel.Lib.String.tamanhoString

    mov ecx, eax

.loopConverter:

    mov al, byte[esi]

.checar1:

    cmp al, 'A' ;; Checar se o caractere está em maiúsculo
    jae .checar2

    inc esi

    loop .loopConverter

    jmp .fim

.checar2:

    cmp al, 'Z' ;; Checar se o caractere está em maiúsculo
    jbe .ok

    inc esi

    loop .loopConverter

    jmp .fim

.ok:

    add al, ' ' ;; Converter se o caractere está em maiúsculo
    mov byte[esi], al

    inc esi

    loop .loopConverter

.fim:

    pop esi
    pop ecx
    pop eax

    ret

;;************************************************************************************

;; Remover espaços em branco do início ao fim da string
;;
;; Entrada:
;;
;; ESI - String

Hexagon.Kernel.Lib.String.cortarString:

    push eax
    push ebx
    push ecx
    push esi
    push edi

    push es

    push ds ;; ES = DS
    pop es

;; Primeiro precisamos tirar os espaços da esquerda e depois da direita

    cmp byte[esi], 0 ;; Se string vazia, sair
    je .fim

    call Hexagon.Kernel.Lib.String.tamanhoString ;; Obter tamanho da string SI em EAX

    mov ecx, eax ;; Colocar isso em ECX para usar em loop

    push esi ;; Salvar posição na string para uso futuro
    push ecx ;; Salvar tamanho da string para uso futuro

    xor ebx, ebx ;; EBX é um contador de espaços em branco

    cld ;; Da esquerda para a direita, então limpando a bandeira de direção

.cortarDaEsquerda:

    lodsb

    cmp al, ' '
    je .cortarEsquerda

    jmp short .semEspacoEsquerda

.cortarEsquerda:

    inc ebx

    mov byte[esi-1], 0 ;; Preencher espaços com 0

    loop .cortarDaEsquerda

.semEspacoEsquerda:

    pop ecx ;; Restaurar o tamanho da string
    pop esi ;; Restaurar posição na string

    push esi
    push ecx

    mov edi, esi
    add esi, ebx ;; Adicionar total de espaços em branco

    rep movsb ;; Mover string para nova posição

    pop ecx

    sub ecx, ebx

    pop esi

    add esi, ecx

    dec esi

    std ;; Definir direção para decrementar da direita para a esquerda

.cortarDaDireita:

    lodsb

    cmp al, ' '
    je .cortarDireita

    jmp short .semEspacoDireita

.cortarDireita:

    mov byte[esi+1], 0 ;; Preencher os espaços com 0

    loop .cortarDaDireita

    jmp .fim

.semEspacoDireita:

.fim:

    cld

    pop es
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop eax

    ret

;;************************************************************************************

;; Converter decimal inteiro ASCII para inteiro
;;
;; Entrada:
;;
;; ESI - String
;;
;; Saída:
;;
;; EAX - Inteiro
;; CF definido em caso de número incorreto

Hexagon.Kernel.Lib.String.stringParaInteiro:

    push ebx
    push ecx
    push edx
    push esi

    mov dword[.numero], 0

    mov al, '-'

    call Hexagon.Kernel.Lib.String.encontrarCaractereNaString

    cmp eax, 1
    ja .negativo

.positivo:

    mov byte[.bandeiraNegativo], 0

    jmp .proximo

.negativo:

    inc esi

    mov byte[.bandeiraNegativo], 1

.proximo:

    call Hexagon.Kernel.Lib.String.tamanhoString ;; Encontrar tamanho da string

    mov ecx, eax ;; Usar a contagem no loop
    add esi, eax

    dec esi

    mov ebx, 0
    mov eax, 1

.loopConverter:

    mov bl, byte[esi]

    dec esi

    sub bl, 0x30

    cmp bl, 9
    ja .numeroInvalido

    mov edx, 10

    mul edx

    push eax

    mul ebx

    add dword[.numero], eax

    pop eax

    loop .loopConverter

    mov ebx, 10
    mov eax, dword[.numero]
    mov edx, 0

    div ebx ;; Dividir por 10

    mov dword[.numero], 0

.bemSucedido:

    cmp byte[.bandeiraNegativo], 0
    je .fim1

    neg eax

.fim1:

    clc

    jmp short .fim

.numeroInvalido:

    mov eax, 0

    stc

.fim:

    pop esi
    pop edx
    pop ecx
    pop ebx

    ret

.numero: dd 0
.bandeiraNegativo: db 0

;;************************************************************************************

;; Encontrar um caractere particular em uma string
;;
;; Entrada:
;;
;; ESI - String
;; AL  - Caractere para procurar
;;
;; Saída:
;;
;; CF definido se caractere não encontrado
;; EAX - Número de ocorrências desse caractere

Hexagon.Kernel.Lib.String.encontrarCaractereNaString:

    push ebx
    push ecx
    push edx
    push esi

    mov bl, al
    xor ecx, ecx

.loopEncontrarLoop:

    lodsb

    or al, al ;; cmp AL, 0 (último caractere)
    jz .proximo

    cmp al, bl ;; Caractere encontrado
    jne .loopEncontrarLoop

    inc ecx ;; Contador

    jmp .loopEncontrarLoop

.proximo:

    mov eax, ecx

    or eax, eax ;; cmp EDX, 0
    jz .naoEncontrado

    clc

    jmp .fim

.naoEncontrado:

    stc

.fim:

    pop esi
    pop edx
    pop ecx
    pop ebx

    ret

;;************************************************************************************

;; Remover um caractere de uma posição específica na string
;;
;; Entrada:
;;
;; ESI - String
;; EAX - Posição do caractere

Hexagon.Kernel.Lib.String.removerCaractereNaString:

    push esi
    push edx

    mov edx, eax

    call Hexagon.Kernel.Lib.String.tamanhoString

    cmp edx, eax ;; EAX tem o tamanho da string
    ja .fim

    inc eax ;; Incluindo o último caractere nulo

    add esi, edx

    push es

    push ds ;; DS = ES
    pop es

    mov edi, esi

    inc esi ;; Próximo caractere

    mov ecx, eax

    cld ;; Limpar direção

    rep movsb ;; Mover (ECX) caracteres de ESI para EDI

    pop es
    pop edx
    pop esi

.fim:

    ret

;;************************************************************************************

;; Inserir um caractere em posição específica da string
;;
;; Entrada:
;;
;; ESI - String
;; EDX - Posição do caractere
;; AL  - Caractere para inserir
;;
;; O buffer da string tem que ter taamnho suficiente!

Hexagon.Kernel.Lib.String.inserirCaractereNaString:

    push eax
    push ebx
    push ecx
    push edi

    mov ebx, eax ;; Salvar caractere

    push esi

;; Criar espaço para incluir o caractere

    call Hexagon.Kernel.Lib.String.tamanhoString

    push eax ;; EAX tem o tamanho da string

    add esi, eax

    inc esi ;; Incluindo caractere nulo

    push es

    push ds ;; ES = DS
    pop es

    std ;; Direção reversa em rep movsb

    add esi, edx

    dec esi

    mov edi, esi

    dec esi

    mov ecx, eax

    rep movsb ;; Mover (ECX) caracteres de ESI para EDI

    pop es

    pop eax
    pop esi

;; Inserir o caractere aqui

    mov byte[esi+edx], bl ;; BL tem o caractere
    mov byte[esi+eax+1],0 ;; Criar o fim da string

    cld

    pop edi
    pop ecx
    pop ebx
    pop eax

    ret

;;************************************************************************************

;; Converte um número inteiro em uma string
;;
;; Entrada:
;;
;; EAX - Inteiro
;;
;; Saída:
;;
;; ESI - Ponteiro com o conteúdo

Hexagon.Kernel.Lib.String.paraString:

    push es

    push ds ;; DS = ES
    pop es

    push eax
    push ecx
    push edx
    push esi
    push edi

;; Checar se negativo

    cmp eax, 0
    jge .positivo

.negativo:

    push eax

    mov al, '-' ;; Imprimir menos

    call Hexagon.Kernel.Dev.Gen.Console.Console.imprimirCaractere

    pop eax

    neg eax

.positivo:

;; Converter inteiro para string para poder imprimir

    mov ebx, 10  ;; Decimais estão na base 10
    xor ecx, ecx ;; mov ECX, 0

.loopConverter:

    xor edx, edx ;; mov EDX, 0

    div ebx

    add dl, 0x30 ;; Converter para ASCII

    push edx

    inc ecx

    or eax, eax ;; cmp EAX, 0
    jne .loopConverter

    mov edx, esi

    mov edx, 0

    mov ebx, .buffer

.loopImprimir:

    pop eax

    mov [ebx+edx], eax

    inc edx

    loop .loopImprimir

.fim:

    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax

    mov esi, .buffer

    pop es

    ret

.buffer: times 16 db 0

;;************************************************************************************

;; Realiza a conversão de BCD para ASCII
;;
;; Entrada:
;;
;; AL - Valor em BCD
;;
;; Saída:
;;
;; AX - Valor em ASCII

Hexagon.Kernel.Lib.String.BCDParaASCII:

    push ecx

    mov ah, al
    and ax, 0xF00F ;; Mascarar bits
    shr ah, 4      ;; Deslocar para direita AH para obter BCD desempacotado
    or ax, 0x3030  ;; Combinar com 30 para obter ASCII
    xchg ah, al    ;; Trocar por convenção ASCII

    pop ecx

    ret

;;************************************************************************************
