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
;;                     Este arquivo faz parte do kernel Hexagon
;;
;;************************************************************************************

;;************************************************************************************
;;
;;                Controle e execução de processos do kernel Hexagon
;;
;; Aqui existem rotinas para a alocação de memória para um novo processo, o
;; carregamento de uma imagem executável válida, sua interpretação, sua execução
;; e término.
;;
;;************************************************************************************

;;************************************************************************************
;;
;;          Códigos de retorno (erro) do gerenciador de processos do Hexagon
;;
;;                           Interface padronizada de retorno
;;
;;************************************************************************************

;;|==================================================================================|
;;| Código |             Nome do erro             |          Motivo do erro          |
;;|==================================================================================|
;;|  00h   |        Nenhum erro no processo       |    Nenhum parâmetro inválido     |
;;|  01h   |    Imagem não encontrada no disco    |                -                 |
;;|  02h   |        Erro ao carregar imagem       |                -                 |
;;|  03h   |     Limite de processos atingido     |                -                 |
;;|  04h   |  Imagem inválida - imagem não HAPP   |                -                 |
;;|==================================================================================|

;;************************************************************************************
;;
;;    Este módulo faz chamadas a funções de gerenciamento de memória do Hexagon
;;
;;************************************************************************************

;;************************************************************************************
;;
;;                         Controle de Processos do Hexagon
;;
;;************************************************************************************

use32

;;************************************************************************************

struc Hexagon.Gerenciamento.Tarefas
{

.processoVazio: ;; Conteúdo de um processo vazio
times 13 db ' '

}

;;************************************************************************************

Hexagon.Processos Hexagon.Gerenciamento.Tarefas

;;************************************************************************************
;;
;;                      Bloco de Controle de Processo do Hexagon
;;
;;************************************************************************************

virtual at Hexagon.Heap.BCPs ;; Este objeto está localizado na posição definida

Hexagon.Processos.BCP.esp: ;; Bloco de Controle de Processo
times Hexagon.Processos.BCP.limiteProcessos dd 0
.ponteiro: dd 0 ;; Ponteiro para a pilha do processo


Hexagon.Processos.BCP.tamanho:  ;; Bloco de mapeamento de memória
times Hexagon.Processos.BCP.limiteProcessos dd 0
.ponteiro: dd 0 ;; Ponteiro para o endereço de memória do processo

Hexagon.Processos.BCP:
.codigoErro:            dd 0 ;; Código de erro emitido pelo último processo
.baseProcessos:         dd 0 ;; Endereço base de carregamento de processos, fornececido pelo alocador
.modoTerminar:          db 0 ;; Marca se o processo deve ficar residente ou não
.processoBloqueado:     dd 0 ;; Marca se o processo pode ser finalizado por uma tecla ou combinação
.limiteProcessos        = 31 ;; Número limite de processos carregados (n-1)
.contagemProcessos:     dd 0 ;; Número de processos atualmente na pilha de execução
.PID:                   dd 0 ;; PID
.tamanhoUltimoProcesso: dd 0 ;; Tamanho do último processo
.codigoRetorno:         db 0 ;; Registra os códigos de erro em operações de processos
.PIDAtual:              dd 0 ;; PID atual
.contador:              db 0 ;; Contador de processos
.residente:             db 0 ;; Se o processo será residente (futuro)
.imagemIncompativel:    db 0 ;; Marca se uma imagem é incompatível
.entradaHAPP:           dd 0 ;; Entrada da imagem HAPP
.tipoImagem:            db 0 ;; Tipo executável da imagem
.tamanhoImagem: ;; Tamanho do programa atual na pilha de execução
times Hexagon.Processos.BCP.limiteProcessos -1  dd 0
.nomeProcesso: ;; Armazena o nome do processo
times 11 db 0

end virtual

;;************************************************************************************

;; Destravar a pilha de processos, permitindo o encerramento do processo pelo usuário

Hexagon.Kernel.Kernel.Proc.destravar:

    mov word[Hexagon.Processos.BCP.processoBloqueado], 0h

    ret

;;************************************************************************************

;; Travar o processo em primeiro plano, impedindo sua saída da pilha de execução

Hexagon.Kernel.Kernel.Proc.travar:

    mov word[Hexagon.Processos.BCP.processoBloqueado], 01h

    ret

;;************************************************************************************

Hexagon.Kernel.Kernel.Proc.iniciarEscalonador:

    logHexagon Hexagon.Verbose.heapKernel, Hexagon.Dmesg.Prioridades.p5

    push es

;; Vamos iniciar a área de memória do heap do kernel que vai armazenar o nome dos
;; processos em execução, aplicando a formatação esperada pelas funções que gerenciam
;; esses campos

    push ds
    pop es

    mov edx, 13*Hexagon.Processos.BCP.limiteProcessos
    mov ebx, 0

.loop:

    mov esi, .espaco
    mov edi, Hexagon.Heap.ProcTab
    add edi, ebx
    mov ecx, 1

    rep movsb

    dec edx
    inc ebx

    cmp edx, 0
    jne .loop

    pop es

    mov esi, Hexagon.Heap.ProcTab

    mov ebx, 13*Hexagon.Processos.BCP.limiteProcessos

    mov byte[esi+ebx], 0

;; Pronto, tudo feito para a área de armazenamento do nome dos processos, vamos continuar

    mov dword[Hexagon.Processos.BCP.PIDAtual], 0

    mov dword[Hexagon.Processos.BCP.PID], 0

    mov dword[Hexagon.Processos.BCP.contagemProcessos], 0

    logHexagon Hexagon.Verbose.escalonador, Hexagon.Dmesg.Prioridades.p5

;; Agora, uma função para iniciar os BCPs
;; Essa função pode ser executada, mas o uso dos novos BCPs ainda está em desenvolvimento

    ;; call Hexagon.Kernel.Kernel.Proc.iniciarBCP

    ret

.espaco: db ' '

;;************************************************************************************

;; Agora o espaço de memória alocado para os processos será salvo na estrutura de controle
;; do escalonador de processos do Hexagon

Hexagon.Kernel.Kernel.Proc.configurarAlocacaoProcessos:

    mov dword[Hexagon.Processos.BCP.baseProcessos], ebx

    ret

;;************************************************************************************

;; Permite encerrar um processo atualmente em execução pelo sistema, caso esse encerramento
;; seja possível

Hexagon.Kernel.Kernel.Proc.matarProcesso:

;; Terminar processo atual em execução

;; Primeiro deve-se checar se a função de terminar um processo em primeiro plano com o uso
;; de combinação de teclas ou a tecla especial "Matar processo" está habilitada por parte do
;; sistema. Isso é uma medida de segurança que visa prevenir o fechamento de processos vitais
;; como o gerenciador de login, por exemplo.

;; Caso a função esteja desabilitada, a ocorrência será ignorada

    cmp dword[Hexagon.Processos.BCP.processoBloqueado], 1
    je .fim

    cmp byte[Hexagon.Processos.BCP.contagemProcessos], 0 ;; Não exite processo para ser fechado
    je .fim

match =SIM, VERBOSE
{

    mov esi, Hexagon.Verbose.Servicos.matarProcesso
    mov ebx, Hexagon.Dmesg.Prioridades.p5

    call Hexagon.Kernel.Kernel.Dmesg.criarMensagemHexagon

}

    push ds
    pop es

    pop eax

    mov ax, 18h
    mov es, ax

    mov eax, dword[Hexagon.Console.corFonte]
    mov ebx, dword[Hexagon.Console.corFundo]

;; Definir cor padrão do console

    call Hexagon.Kernel.Dev.Gen.Console.Console.definirCorConsole

;; Atualizar buffer de vídeo (console seundário -> console principal)
;; Essa atualização não é obrigatória, só é útil para utilitários que
;; utilizam double buffering

    ;; call Hexagon.Kernel.Dev.Gen.Console.Console.atualizarConsole

;; Usar console principal

    call Hexagon.Kernel.Dev.Gen.Console.Console.usarConsolePrincipal

;; Rolar console

    call Hexagon.Kernel.Dev.Gen.Console.Console.rolarConsole

    mov al, 20h

    out 20h, al

    call Hexagon.Kernel.Kernel.Proc.encerrarProcesso

    ret

.fim:

    ret

;;************************************************************************************

;; Configura um novo processo Hexagon para execução imediata
;;
;; Entrada:
;;
;; ESI - Buffer contendo o nome do arquivo à ser executado
;; EDI - Argumentos do programa (caso eles existam)
;; EAX - 0 caso nenhum argumento exista
;;
;; Saída:
;;
;; CF - Definido em caso de erro ou arquivo não encontrado
;;      Limpo em caso de sucesso

Hexagon.Kernel.Kernel.Proc.criarProcesso:

    pusha

;; Agora o limite de processos carregados será verificado. Caso já existam
;; muitos processos em memória, o carregamento de um outro será impedido

.verificarLimite:

    push eax

    mov eax, [Hexagon.Processos.BCP.contagemProcessos]

;; Caso o número de processos carregados seja menos que o limite, proceder
;; com o carregamento. Caso contrário, impedir o carregamento retornando
;; um erro

    cmp eax, Hexagon.Processos.BCP.limiteProcessos - 1 ;; Número limite de processos carregados
    jl .limiteDisponivel

    pop eax

    jmp Hexagon.Kernel.Kernel.Proc.numeroMaximoProcessosAtingido

.limiteDisponivel:

;; Verificar se existem argumentos para o processo à ser carregado

    pop eax

    cmp eax, 0
    je .semArgumentos

    push esi

    push es

    mov esi, edi

    call Hexagon.Kernel.Lib.String.tamanhoString

    mov ecx, eax

    inc ecx

    push 18h ;; Segmento linear do kernel
    pop es

;; Copiar argumentos para um endereço conhecido

    mov esi, edi

    mov edi, Hexagon.Heap.ArgProc

    rep movsb ;; Copiar (ECX) caracteres de ESI para EDI

    pop es

    pop esi

    jmp .verificarImagem

.semArgumentos:

    mov byte[gs:Hexagon.Heap.ArgProc], 0

.verificarImagem:

    push esi

    call Hexagon.Kernel.FS.VFS.arquivoExiste

    pop esi

    push eax

    jc .imagemAusente

    call Hexagon.Kernel.Lib.HAPP.verificarImagemHAPP

    cmp byte[Hexagon.Imagem.Executavel.HAPP.imagemIncompativel], 01h
    je .imagemIncompativel

    cmp byte[Hexagon.Imagem.Executavel.HAPP.imagemIncompativel], 02h
    je .imagemAusente

    jmp Hexagon.Kernel.Kernel.Proc.adicionarProcesso

.imagemAusente:

    pop eax

;; A imagem que contêm o código executável não foi localizada no disco

    stc ;; Informar, ao processo que chamou a função, da ausência da imagem

    popa ;; Restaurar a pilha

    mov byte[Hexagon.Processos.BCP.codigoRetorno], 01h

    mov eax, 01h ;; Enviar código de erro

    ret

.imagemIncompativel:

    pop eax

;; A imagem que contêm o código executável não apresenta um formato compatível

    stc ;; Informar, ao processo que chamou a função, da ausência da imagem

    popa ;; Restaurar a pilha

    mov byte[Hexagon.Processos.BCP.codigoRetorno], 04h

    mov eax, 04h ;; Enviar código de erro

    ret

;;************************************************************************************

;; Carrega um executável presente no disco e o executa imediatamente
;;
;; Os argumentos devem ser passados pela pilha
;;
;; Entrada:
;;
;; EAX - Tamanho da imagem que contêm o código executável

Hexagon.Kernel.Kernel.Proc.adicionarProcesso:

;; Serão restaurados dados passados pela pilha

    pop eax

    push eax

    mov ebx, dword[Hexagon.Processos.BCP.PID]
    inc ebx
    mov dword[Hexagon.Processos.BCP.tamanhoImagem+ebx*4], eax

    call Hexagon.Kernel.Arch.Gen.Mm.confirmarUsoMemoria

    pop ebx

    add ebx, [Hexagon.Processos.BCP.tamanhoUltimoProcesso]

    mov eax, [Hexagon.Processos.BCP.tamanho.ponteiro]

    add eax, Hexagon.Processos.BCP.tamanho

    mov dword[eax], ebx

    mov dword[Hexagon.Processos.BCP.tamanhoUltimoProcesso], ebx

    add dword[Hexagon.Processos.BCP.tamanho.ponteiro], 4

    add dword[Hexagon.Processos.BCP.baseProcessos], ebx

    mov edi, dword[Hexagon.Processos.BCP.baseProcessos]

;; Corrigir endereço com a base do segmento (endereço físico = endereço + base do segmento)

    sub edi, 500h

    push esi

    call Hexagon.Kernel.FS.VFS.carregarArquivo

    pop esi

    jc .erroCarregandoImagem

    mov byte[Hexagon.Processos.BCP.codigoRetorno], 00h ;; Remover o sinalizador de erro

    call Hexagon.Kernel.Kernel.Proc.adicionarProcessoPilha

    jmp Hexagon.Kernel.Kernel.Proc.executarProcesso

.erroCarregandoImagem:

;; Um erro ocorreu durante o carregamento da imagem presente no disco

    stc ;; Informar, ao processo que chamou a função, da ocorrência de erro

    popa ;; Restaurar a pilha

    mov byte[Hexagon.Processos.BCP.codigoRetorno], 02h

    mov eax, 02h ;; Enviar código de erro

    ret

;;************************************************************************************

;; Após a imagem ter sido carregada no endereço apropriado, e o processo ter sido
;; configurado quanto à sua pilha e informações de execução, o processo será executado.
;; Para tanto, deve ser registrado na GDT e ter sua execução configurada

Hexagon.Kernel.Kernel.Proc.executarProcesso:

;; Agora devemos calcular os endereços base de código e dados do programa, os colocando
;; na entrada da GDT do programa

    mov eax, dword[Hexagon.Processos.BCP.baseProcessos]
    mov edx, eax
    and eax, 0xFFFF

    mov word[GDT.codigoProcessos+2], ax ;; Base
    mov word[GDT.dadosProcessos+2], ax  ;; Base

    mov eax, edx
    shr eax, 16
    and eax, 0xFF

    mov byte[GDT.codigoProcessos+4], al ;; Base
    mov byte[GDT.dadosProcessos+4], al  ;; Base

    mov eax, edx
    shr eax, 24
    and eax, 0xFF

    mov byte[GDT.codigoProcessos+7], al ;; Base
    mov byte[GDT.dadosProcessos+7], al  ;; Base

    lgdt[GDTReg] ;; Carregar a GDT contendo a entrada do processo

    mov eax, [Hexagon.Processos.BCP.esp.ponteiro]

    add eax, Hexagon.Processos.BCP.esp

    mov dword[eax], esp

    add dword[Hexagon.Processos.BCP.esp.ponteiro], 4

    call Hexagon.Kernel.Kernel.Proc.calcularEnderecoArgumentos

    sti ;; Ter certeza que as interrupções estão disponíveis

    pushfd   ;; Flags
    push 30h ;; Segmento de código do ambiente do usuário (processo)
    push dword [Hexagon.Imagem.Executavel.HAPP.entradaHAPP] ;; Ponto de entrada da imagem

    inc dword[Hexagon.Processos.BCP.contagemProcessos]
    inc dword[Hexagon.Processos.BCP.PID]

    mov ax, 38h ;; Segmento de dados do ambiente de usuário (processo)
    mov ds, ax

    iret

;;************************************************************************************

;; Função que recebe o controle após o término do processo e realiza as operações necessárias
;; para removê-lo da pilha de execução

Hexagon.Kernel.Kernel.Proc.encerrarProcesso:

;; Primeiramente, armazenar o código de erro do processo à ser finalizado

    mov [Hexagon.Processos.BCP.codigoErro], eax

    mov ax, 10h
    mov ds, ax

    cmp byte[Hexagon.Console.modoGrafico], 0
    je naoModoGrafico

naoModoGrafico:

    cmp ebx, 00h
    je .continuar

    cmp ebx, 1234h
    je .terminarFicarResidente

.terminarFicarResidente:

    mov byte[Hexagon.Processos.BCP.modoTerminar], 01h

.continuar:

    mov eax, [Hexagon.Processos.BCP.esp.ponteiro]

    add eax, Hexagon.Processos.BCP.esp
    sub eax, 4

    mov esp, dword[eax]

;; Endereço da função que removerá as permissões do processo

    mov eax, Hexagon.Kernel.Kernel.Proc.removerProcesso

    push 08h ;; Segmento de código do kernel
    push eax ;; Endereço de retorno de retf

    retf ;; Ir à essa função agora, trocando o contexto

;;************************************************************************************

;; Remove as credenciais e permissões do processo da pilha de execução do sistema e da
;; GDT, transferindo o controle novamente ao kernel

Hexagon.Kernel.Kernel.Proc.removerProcesso:

    call Hexagon.Kernel.Kernel.Proc.removerProcessoPilha

    mov ax, 10h ;; Segmento de dados do kernel
    mov ds, ax

    mov eax, [Hexagon.Processos.BCP.tamanho.ponteiro]

    add eax, Hexagon.Processos.BCP.tamanho

    sub eax, 4

    mov ebx, dword[eax]

    sub dword[Hexagon.Processos.BCP.baseProcessos], ebx

    sub dword[Hexagon.Processos.BCP.tamanho.ponteiro], 4

    mov eax, dword[Hexagon.Memoria.bytesAlocados]

    sub dword[Hexagon.Processos.BCP.baseProcessos], eax

    mov dword[Hexagon.Memoria.bytesAlocados], 0

;; Agora devemos calcular os endereços base de código e dados do programa, os colocando
;; na entrada da GDT do programa

    mov eax, dword[Hexagon.Processos.BCP.baseProcessos]
    mov edx, eax
    and eax, 0xFFFF

    mov word[GDT.codigoProcessos+2], ax
    mov word[GDT.dadosProcessos+2], ax

    mov eax, edx
    shr eax, 16
    and eax, 0xFF

    mov byte[GDT.codigoProcessos+4], al
    mov byte[GDT.dadosProcessos+4], al

    mov eax, edx
    shr eax, 24
    and eax, 0xFF

    mov byte[GDT.codigoProcessos+7], al
    mov byte[GDT.dadosProcessos+7], al

    lgdt[GDTReg]

    sub dword[Hexagon.Processos.BCP.esp.ponteiro], 4

    push eax
    push ebx

    mov ebx, dword[Hexagon.Processos.BCP.PID]
    mov eax, dword[Hexagon.Processos.BCP.tamanhoImagem+ebx*4]
    mov dword[Hexagon.Processos.BCP.tamanhoImagem+ebx*4], 00h

    call Hexagon.Kernel.Arch.Gen.Mm.liberarUsoMemoria

    pop ebx
    pop eax

    dec dword[Hexagon.Processos.BCP.contagemProcessos]
    dec dword[Hexagon.Processos.BCP.PID]

    cmp byte[Hexagon.Processos.BCP.modoTerminar], 01h
    je .ficarResidente

    clc

    jmp short .fim

.ficarResidente:

    mov ebx, dword[Hexagon.Processos.BCP.PID]

    mov eax, [Hexagon.Processos.BCP.baseProcessos]
    add eax, [Hexagon.Processos.BCP.tamanhoImagem+ebx*4]

    mov byte[Hexagon.Processos.BCP.modoTerminar], 00h

    clc

    jmp short .fim

.fim:

    clc

    popa

.verificarRetorno:

    clc

    mov ah, [Hexagon.Processos.BCP.codigoRetorno]

    cmp ah, 00h
    je .finalizar

    stc

.finalizar:

    mov eax, [Hexagon.Processos.BCP.codigoRetorno]

    ret

;;************************************************************************************

;; Manipulador que retorna código de erro para quando o limite de processos for atingido

Hexagon.Kernel.Kernel.Proc.numeroMaximoProcessosAtingido:

;; Um erro ocorreu durante o carregamento da imagem presente no disco

    stc ;; Informar, ao processo que chamou a função, da ocorrência de erro

    popa ;; Restaurar a pilha

    mov byte[Hexagon.Processos.BCP.codigoRetorno], 03h

    mov eax, 03h ;; Enviar código de erro

    ret

;;************************************************************************************

;; Retorna ao processo o seu PID
;;
;; Saída:
;;
;; EAX - PID do processo

Hexagon.Kernel.Kernel.Proc.obterPID:

    mov eax, dword[Hexagon.Processos.BCP.PID]

    ret

;;************************************************************************************

Hexagon.Kernel.Kernel.Proc.adicionarProcessoPilha:

    mov dword[Hexagon.Processos.BCP.nomeProcesso], esi

    push ds ;; Segmento de dados do kernel
    pop es

    mov eax, dword[Hexagon.Processos.BCP.contagemProcessos]

    mov ebx, 14

    mul ebx ;; EAX contêm o deslocamento

    inc ebx

    mov edi, Hexagon.Heap.ProcTab

    add edi, eax

    push edi

    mov esi, [Hexagon.Processos.BCP.nomeProcesso]

    call Hexagon.Kernel.Lib.String.tamanhoString

    mov ecx, eax

;; Copiar o nome do processo

    mov esi, dword[Hexagon.Processos.BCP.nomeProcesso]

    pop edi

    rep movsb ;; Copiar (ECX) caracteres de ESI para EDI

    mov byte[edi+1], ' '

    ret

;;************************************************************************************

;; Calcula o endereço efetivo do bloco de memória que contêm os argumentos do processo.
;; Esse bloco está sempre mapeado em uma região de despejo temporário do kernel para os
;; argumentos de processos
;; Esse endereço é diretamente relativo à localização do processo atual na memória
;;
;; Entrada:
;;
;; Nada
;;
;; Saída:
;;
;; EDI - endereço relativo (offset) em memória do bloco de memória com os argumentos do
;;       processo

Hexagon.Kernel.Kernel.Proc.calcularEnderecoArgumentos:

;; Documentação da resolução de endereço para os parâmetros que serão passados ao novo processo:
;;
;; Primeiro, pegamos o offset da estrutura dentro do endereço do kernel. Esse valor deve estar
;; próximo do tamanho em bytes do arquivo que contêm o kernel. Esse valor é relativo ao kernel,
;; não ao segmento de memória. Para obtermos o endereço efetivo, pegamos o offset em relação
;; ao kernel e subtraímos pelo endreço base do processo, gerando um offset em relação ao segmento
;; de memória.
;; Neste caso, temos um endereço negativo, pois o kernel se encontra em uma região de memória
;; inferior à região do processo. Na resolução de endereços, é feito um complemento de dois com o
;; valor negativo (um valor possível e provavel de −2C9C6E é representado como 6392h ou 25490),
;; sendo utilizado como offset no segmento ES, formando o endereço lógico ES:25490, que apontaria
;; corretamente para a estrutura no kernel que contêm os argumentos do processo. Desta forma, o
;; processo com o offset em EDI = -2C9C6E consegue apontar corretamente para a área esperada
;; no kernel.
;;
;; Mais informações sobre o processo (cálculo de endereço efetivo - offset):
;;
;; A arquitetura trata com simetria em 0 os endereços, e normalmente endereços
;; do kernel (com offset menor em relação ao início da memória) aparecem como endereços negativos
;; para o ambiente de usuário, como é observado neste caso. A arquitetura suporta offsets negativos
;; relativos ao segmento (via complemento de dois), realizando a tradução transparente para um
;; endereço físico. No caso abaixo, teremos um offset negativo apontando para uma região anterior
;; da memória que será traduzido para um endereço lógico que será, por sua vez, traduzido em um
;; endereço físico pelo processador utilizando a tabela presente na GDT

    mov edi, Hexagon.Heap.ArgProc ;; Offset, dentro do kernel

    sub edi, dword[Hexagon.Processos.BCP.baseProcessos] ;; Obter endereço efetivo (offset)

    ret

;;************************************************************************************

Hexagon.Kernel.Kernel.Proc.removerProcessoPilha:

    push ds ;; Segmento de dados do kernel
    pop es

    mov eax, dword[Hexagon.Processos.BCP.contagemProcessos]

    dec eax

    mov ebx, 14

    mul ebx ;; EAX contêm o deslocamento

    inc ebx

    mov edi, Hexagon.Heap.ProcTab

    add edi, eax

    push edi

    mov esi, Hexagon.Processos.processoVazio

    mov eax, 13

    mov ecx, eax

;; Copiar o nome do processo

    mov esi, Hexagon.Processos.processoVazio

    pop edi

    rep movsb ;; Copiar (ECX) caracteres de ESI para EDI

    mov byte[edi+1], ' '

    ret

;;************************************************************************************

Hexagon.Kernel.Kernel.Proc.obterListaProcessos:

;; Vamos iniciar a área de memória do heap do kernel que vai armazenar o nome dos
;; processos em execução

    push ds ;; Segmento de dados do kernel
    pop es

.loop:

    mov esi, Hexagon.Heap.ProcTab
    mov edi, Hexagon.Heap.Temp
    mov ecx, 13*Hexagon.Processos.BCP.limiteProcessos

    rep movsb

    mov esi, Hexagon.Heap.Temp

    mov ebx, 13*Hexagon.Processos.BCP.limiteProcessos

    mov byte[esi+ebx], 0

    mov esi, Hexagon.Heap.Temp

    call Hexagon.Kernel.Lib.String.cortarString

    mov eax, dword[Hexagon.Processos.BCP.contagemProcessos]

.fim:

    ret

;;************************************************************************************

Hexagon.Kernel.Kernel.Proc.obterCodigoErro:

    mov eax, [Hexagon.Processos.BCP.codigoErro]

    ret
