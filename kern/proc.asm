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

struc Hexagon.Gerenciamento.Tarefas maxProcessos
{

.codigoErro:             dd 0           ;; Código de erro emitido pelo último processo
.enderecoAplicativos:    dd 0           ;; Endereço base de carregamento de aplicativos, fornececido pelo alocador
.modoTerminar:           db 0           ;; Marca se o aplicativo deve ficar residente ou não
.processoBloqueado:      dd 0           ;; Marca se o aplicativo pode ser finalizado por uma tecla ou combinação
.limiteProcessos         = maxProcessos ;; Número limite de processos carregados
.contagemProcessos:      dd 0           ;; Número de processos atualmente na pilha de execução
.PID:                    dd 0           ;; PID
.tamanhoUltimoPrograma:  dd 0           ;; Tamanho do último aplicativo
.tamanhoImagem: times maxProcessos dd 0 ;; Tamanho do programa atual na pilha de execução
.codigoRetorno:          db 0           ;; Registra os códigos de erro em operações de processos
.nomeProcesso:  times 11 db 0           ;; Armazena o nome do processo
.processoAtual: times 12 db 0           ;; Nome do processo atual
.PIDAtual:               dd 0           ;; PID atual
.processoVazio: times 13 db ' '         ;; Conteúdo de um processo vazio
.contador:               db 0           ;; Contador de processos
.residente:              db 0           ;; Se o processo será residente (futuro)
.imagemIncompativel:     db 0
.entradaHAPP:            dd 0
.tipoImagem:             db 0

}

;;************************************************************************************

Hexagon.Processos Hexagon.Gerenciamento.Tarefas 22 ;; 21 processos por enquanto (n-1)

;;************************************************************************************
;;
;;                      Bloco de Controle de Processo do Hexagon
;;
;;************************************************************************************

virtual at Hexagon.InfoProcessos

Hexagon.Processos.BCP.esp: ;; Bloco de Controle de Processo
times Hexagon.Processos.limiteProcessos dd 0
.ponteiro: ;; Ponteiro para a pilha do processo
dd 0

Hexagon.Processos.BCP.tamanho:  ;; Bloco de mapeamento de memória
times Hexagon.Processos.limiteProcessos dd 0
.ponteiro: ;; Ponteiro para o endereço de memória do processo
dd 0

end virtual

;;************************************************************************************

;; Destravar a pilha de processos, permitindo o fechamento do aplicativo pelo usuário

Hexagon.Kernel.Kernel.Proc.destravar:

    mov word[Hexagon.Processos.processoBloqueado], 0h

    ret

;;************************************************************************************

;; Travar o processo em primeiro plano, impedindo sua saída da pilha de execução

Hexagon.Kernel.Kernel.Proc.travar:

    mov word[Hexagon.Processos.processoBloqueado], 01h

    ret

;;************************************************************************************

Hexagon.Kernel.Kernel.Proc.iniciarEscalonador:

    logHexagon Hexagon.Verbose.heapKernel, Hexagon.Dmesg.Prioridades.p5

    push es

;; Vamos iniciar a área de memória do heap do kernel que vai armazenar o nome dos
;; processos em execução

    push ds
    pop es

    mov edx, 13*Hexagon.Processos.limiteProcessos
    mov ebx, 0

.loop:

    mov esi, .espaco
    mov edi, Hexagon.TabelaProcessos
    add edi, ebx
    mov ecx, 1

    rep movsb

    dec edx
    inc ebx

    cmp edx, 0
    jne .loop

    pop es

    mov esi, Hexagon.TabelaProcessos

    mov ebx, 13*Hexagon.Processos.limiteProcessos

    mov byte[esi+ebx], 0

;; Pronto, tudo feito para a área de armazenamento do nome dos processos, vamos continuar

    mov dword[Hexagon.Processos.PIDAtual], 0

    mov dword[Hexagon.Processos.PID], 0

    mov dword[Hexagon.Processos.contagemProcessos], 0

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

    mov dword[Hexagon.Processos.enderecoAplicativos], ebx

    ret

;;************************************************************************************

;; Permite encerrar um processo atualmente em execução pelo sistema, caso esse encerramento
;; seja possível

Hexagon.Kernel.Kernel.Proc.matarProcesso:

;; Terminar processo atual em execução

;; Primeiro deve-se checar se a função de terminar um processo em primeiro plano com o uso
;; de combinação de teclas ou a tecla especial "Matar processo" (F1) está habilitada
;; por parte do sistema. Isso é uma medida de segurança que visa prevenir o fechamento de
;; processos vitais como o gerenciador de login, por exemplo.

    cmp dword[Hexagon.Processos.processoBloqueado], 1 ;; Caso a função esteja desabilitada, a ocorrência será ignorada
    je .fim

    cmp byte[Hexagon.Processos.contagemProcessos], 0 ;; Não exite processo para ser fechado
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

    mov ax, 0x18
    mov es, ax

    mov eax, dword[Hexagon.Graficos.corFonte]
    mov ebx, dword[Hexagon.Graficos.corFundo]

    call Hexagon.Kernel.Dev.Gen.Console.Console.definirCorTexto

    call Hexagon.Kernel.Lib.Graficos.atualizarTela

    call Hexagon.Kernel.Lib.Graficos.usarBufferVideo1

    call Hexagon.Kernel.Dev.Gen.Console.Console.rolarParaBaixo

    mov al, 0x20

    out 0x20, al

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

;; Agora o limite de aplicativos carregados será verificado. Caso já existam
;; muitos processos em memória, o carregamento de um outro será impedido

.verificarLimite:

    push eax

    mov eax, [Hexagon.Processos.contagemProcessos]

;; Caso o número de processos carregados seja menos que o limite, proceder
;; com o carregamento. Caso contrário, impedir o carregamento retornando
;; um erro

    cmp eax, Hexagon.Processos.limiteProcessos - 1 ;; Número limite de processos carregados
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

    push 0x18
    pop es

;; Copiar argumentos para um endereço conhecido

    mov esi, edi

    mov edi, Hexagon.ArgumentosProcesso

    rep movsb ;; Copiar (ECX) caracteres de ESI para EDI

    pop es

    pop esi

    jmp .verificarImagem

.semArgumentos:

    mov byte[gs:Hexagon.ArgumentosProcesso], 0

.verificarImagem:

    ;; cmp byte[Hexagon.Imagem.Executavel.HAPP.imagemIncompativel], 00h

    push esi

    call Hexagon.Kernel.FS.VFS.arquivoExiste

    pop esi

    push eax
    push ebx

    jc .imagemAusente

    call Hexagon.Kernel.Lib.HAPP.verificarImagemHAPP

    cmp byte[Hexagon.Imagem.Executavel.HAPP.imagemIncompativel], 01h
    je .imagemIncompativel

    cmp byte[Hexagon.Imagem.Executavel.HAPP.imagemIncompativel], 02h
    je .imagemAusente

    jmp Hexagon.Kernel.Kernel.Proc.adicionarProcesso

.imagemAusente:

    pop ebx
    pop eax

;; A imagem que contêm o código executável não foi localizada no disco

    stc ;; Informar, ao processo que chamou a função, da ausência da imagem

    popa ;; Restaurar a pilha

    mov byte[Hexagon.Processos.codigoRetorno], 01h

    mov eax, 01h ;; Enviar código de erro

    ret

.imagemIncompativel:

    pop ebx
    pop eax

;; A imagem que contêm o código executável não apresenta um formato compatível

    stc ;; Informar, ao processo que chamou a função, da ausência da imagem

    popa ;; Restaurar a pilha

    mov byte[Hexagon.Processos.codigoRetorno], 04h

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

    pop ebx
    pop eax

    push eax
    push ebx

    mov ebx, dword[Hexagon.Processos.PID]
    inc ebx
    mov dword[Hexagon.Processos.tamanhoImagem+ebx*4], eax

    call Hexagon.Kernel.Arch.Gen.Mm.confirmarUsoMemoria

    pop ebx
    pop eax

    add ebx, [Hexagon.Processos.tamanhoUltimoPrograma]

    mov eax, [Hexagon.Processos.BCP.tamanho.ponteiro]

    add eax, Hexagon.Processos.BCP.tamanho

    mov dword[eax], ebx

    mov dword[Hexagon.Processos.tamanhoUltimoPrograma], ebx

    add dword[Hexagon.Processos.BCP.tamanho.ponteiro], 4

    cmp dword[Hexagon.Processos.BCP.tamanho.ponteiro], 4 * Hexagon.Processos.limiteProcessos
    ja Hexagon.Kernel.Kernel.Proc.numeroMaximoProcessosAtingido

    add dword[Hexagon.Processos.enderecoAplicativos], ebx

    mov edi, dword[Hexagon.Processos.enderecoAplicativos]

    sub edi, 500h

    push esi

    call Hexagon.Kernel.FS.VFS.carregarArquivo

    pop esi

    jc .erroCarregandoImagem

    mov byte[Hexagon.Processos.codigoRetorno], 00h ;; Remover o sinalizador de erro

    call Hexagon.Kernel.Kernel.Proc.adicionarProcessoPilha

    jmp Hexagon.Kernel.Kernel.Proc.executarProcesso

.erroCarregandoImagem:

;; Um erro ocorreu durante o carregamento da imagem presente no disco

    stc ;; Informar, ao processo que chamou a função, da ocorrência de erro

    popa ;; Restaurar a pilha

    mov byte[Hexagon.Processos.codigoRetorno], 02h

    mov eax, 02h ;; Enviar código de erro

    ret

;;************************************************************************************

;; Após a imagem ter sido carregada no endereço apropriado, e o processo ter sido
;; configurado quanto à sua pilha e informações de execução, o processo será executado.
;; Para tanto, deve ser registrado na GDT e ter sua execução configurada

Hexagon.Kernel.Kernel.Proc.executarProcesso:

;; Agora devemos calcular os endereços base de código e dados do programa, os colocando
;; na entrada da GDT do programa

    mov eax, dword[Hexagon.Processos.enderecoAplicativos]
    mov edx, eax
    and eax, 0xffff

    mov word[GDT.codigoProcessos+2], ax
    mov word[GDT.dadosProcessos+2], ax

    mov eax, edx
    shr eax, 16
    and eax, 0xff

    mov byte[GDT.codigoProcessos+4], al
    mov byte[GDT.dadosProcessos+4], al

    mov eax, edx
    shr eax, 24
    and eax, 0xff

    mov byte[GDT.codigoProcessos+7], al
    mov byte[GDT.dadosProcessos+7], al

    lgdt[GDTReg] ;; Carregar a GDT contendo a entrada do processo

    mov eax, [Hexagon.Processos.BCP.esp.ponteiro]

    add eax, Hexagon.Processos.BCP.esp

    mov dword[eax], esp

    add dword[Hexagon.Processos.BCP.esp.ponteiro], 4

    cmp dword[Hexagon.Processos.BCP.esp.ponteiro], 4*Hexagon.Processos.limiteProcessos
    ja Hexagon.Kernel.Kernel.Proc.numeroMaximoProcessosAtingido

    sti ;; Ter certeza que as interrupções estão disponíveis

    pushfd ;; Bandeiras
    push 0x30 ;; Novo CS
    push dword [Hexagon.Imagem.Executavel.HAPP.entradaHAPP] ;; Ponto de entrada da imagem

    inc dword[Hexagon.Processos.contagemProcessos]
    inc dword[Hexagon.Processos.PID]

    mov edi, Hexagon.ArgumentosProcesso

    sub edi, dword[Hexagon.Processos.enderecoAplicativos]

    mov ax, 0x38 ;; Segmento de dados
    mov ds, ax

    iret

;;************************************************************************************

;; Função que recebe o controle após o término do processo e realiza as operações necessárias
;; para removê-lo da pilha de execução

Hexagon.Kernel.Kernel.Proc.encerrarProcesso:

;; Primeiramente, armazenar o código de erro do processo à ser finalizado

    mov [Hexagon.Processos.codigoErro], eax

    mov ax, 0x10
    mov ds, ax

    cmp byte[Hexagon.Video.modoGrafico], 0
    je naoModoGrafico

naoModoGrafico:

    cmp ebx, 00h
    je .continuar

    cmp ebx, 1234h
    je .terminarFicarResidente

.terminarFicarResidente:

    mov byte[Hexagon.Processos.modoTerminar], 01h

.continuar:

    mov eax, [Hexagon.Processos.BCP.esp.ponteiro]

    add eax, Hexagon.Processos.BCP.esp
    sub eax, 4

    mov esp, dword[eax]

    mov eax, Hexagon.Kernel.Kernel.Proc.removerProcesso ;; Endereço da função que removerá as permissões do processo

    push 0x08
    push eax

    retf ;; Ir à essa função agora, trocando o contexto

;;************************************************************************************

;; Remove as credenciais e permissões do processo da pilha de execução do sistema e da
;; GDT, transferindo o controle novamente ao kernel

Hexagon.Kernel.Kernel.Proc.removerProcesso:

    call Hexagon.Kernel.Kernel.Proc.removerProcessoPilha

    mov ax, 0x10
    mov ds, ax

    mov eax, [Hexagon.Processos.BCP.tamanho.ponteiro]

    add eax, Hexagon.Processos.BCP.tamanho

    sub eax, 4

    mov ebx, dword[eax]

    sub dword[Hexagon.Processos.enderecoAplicativos], ebx

    sub dword[Hexagon.Processos.BCP.tamanho.ponteiro], 4

    mov eax, dword[Hexagon.Memoria.bytesAlocados]

    sub dword[Hexagon.Processos.enderecoAplicativos], eax

    mov dword[Hexagon.Memoria.bytesAlocados], 0

;; Agora devemos calcular os endereços base de código e dados do programa, os colocando
;; na entrada da GDT do programa

    mov eax, dword[Hexagon.Processos.enderecoAplicativos]
    mov edx, eax
    and eax, 0xffff

    mov word[GDT.codigoProcessos+2], ax
    mov word[GDT.dadosProcessos+2], ax

    mov eax, edx
    shr eax, 16
    and eax, 0xff

    mov byte[GDT.codigoProcessos+4], al
    mov byte[GDT.dadosProcessos+4], al

    mov eax, edx
    shr eax, 24
    and eax, 0xff

    mov byte[GDT.codigoProcessos+7], al
    mov byte[GDT.dadosProcessos+7], al

    lgdt[GDTReg]

    sub dword[Hexagon.Processos.BCP.esp.ponteiro], 4

    push eax
    push ebx

    mov ebx, dword[Hexagon.Processos.PID]
    mov eax, dword[Hexagon.Processos.tamanhoImagem+ebx*4]
    mov dword[Hexagon.Processos.tamanhoImagem+ebx], 00h

    call Hexagon.Kernel.Arch.Gen.Mm.liberarUsoMemoria

    pop ebx
    pop eax

    dec dword[Hexagon.Processos.contagemProcessos]
    dec dword[Hexagon.Processos.PID]

    cmp byte[Hexagon.Processos.modoTerminar], 01h
    je .ficarResidente

    clc

    jmp short .fim

.ficarResidente:

    mov ebx, dword[Hexagon.Processos.PID]

    mov eax, [Hexagon.Processos.enderecoAplicativos]
    add eax, [Hexagon.Processos.tamanhoImagem+ebx]

    mov byte[Hexagon.Processos.modoTerminar], 00h

    clc

    jmp short .fim

.fim:

    clc

    popa

.verificarRetorno:

    clc

    mov ah, [Hexagon.Processos.codigoRetorno]

    cmp ah, 00h
    je .finalizar

    stc

.finalizar:

    mov eax, [Hexagon.Processos.codigoRetorno]

    ret

;;************************************************************************************

;; Manipulador que retorna código de erro para quando o limite de processos for atingido

Hexagon.Kernel.Kernel.Proc.numeroMaximoProcessosAtingido:

;; Um erro ocorreu durante o carregamento da imagem presente no disco

    stc ;; Informar, ao processo que chamou a função, da ocorrência de erro

    popa ;; Restaurar a pilha

    mov byte[Hexagon.Processos.codigoRetorno], 03h

    mov eax, 03h ;; Enviar código de erro

    ret

;;************************************************************************************

;; Retorna ao processo o seu PID
;;
;; Saída:
;;
;; EAX - PID do processo

Hexagon.Kernel.Kernel.Proc.obterPID:

    mov eax, dword[Hexagon.Processos.PID]

    ret

;;************************************************************************************

Hexagon.Kernel.Kernel.Proc.adicionarProcessoPilha:

    mov dword[Hexagon.Processos.nomeProcesso], esi

    push ds
    pop es

    mov eax, dword[Hexagon.Processos.contagemProcessos]

    mov ebx, 14

    mul ebx ;; EAX contêm o deslocamento

    inc ebx

    mov edi, Hexagon.TabelaProcessos

    add edi, eax

    push edi

    mov esi, [Hexagon.Processos.nomeProcesso]

    call Hexagon.Kernel.Lib.String.tamanhoString

    mov ecx, eax

;; Copiar o nome do processo

    mov esi, dword[Hexagon.Processos.nomeProcesso]

    pop edi

    rep movsb ;; Copiar (ECX) caracteres de ESI para EDI

    mov byte[edi+1], ' '

;; Salvar agora em outra variável

    mov esi, [Hexagon.Processos.nomeProcesso]

    call Hexagon.Kernel.Lib.String.tamanhoString

    mov ecx, eax

;; Copiar o nome do processo

    mov esi, dword[Hexagon.Processos.nomeProcesso]

    mov edi, Hexagon.Processos.processoAtual

    rep movsb ;; Copiar (ECX) caracteres de ESI para EDI

    mov byte[edi+1], 0

    ret

;;************************************************************************************

Hexagon.Kernel.Kernel.Proc.removerProcessoPilha:

    push ds
    pop es

    mov eax, dword[Hexagon.Processos.contagemProcessos]

    dec eax

    mov ebx, 14

    mul ebx ;; EAX contêm o deslocamento

    inc ebx

    mov edi, Hexagon.TabelaProcessos

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

    push ds
    pop es

.loop:

    mov esi, Hexagon.TabelaProcessos
    mov edi, Hexagon.Lista
    mov ecx, 13*Hexagon.Processos.limiteProcessos

    rep movsb

    mov esi, Hexagon.Lista

    mov ebx, 13*Hexagon.Processos.limiteProcessos

    mov byte[esi+ebx], 0

    mov esi, Hexagon.Lista

    call Hexagon.Kernel.Lib.String.cortarString

    mov eax, dword[Hexagon.Processos.contagemProcessos]

.fim:

    ret

;;************************************************************************************

Hexagon.Kernel.Kernel.Proc.obterCodigoErro:

    mov eax, [Hexagon.Processos.codigoErro]

    ret
