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

use32

;;************************************************************************************

;; Este módulo do Hexagon é responsável por carregar, obter informações do arquivo
;; carregado e determinar se o formato corresponde à especificação HAPP. Em caso
;; afirmativo, deve extrair do cabeçalho da imagem informações necessárias para
;; configurar o ambiente de execução e iniciar o processo à partir do ponto de entrada.
;; As funções abaixo são responsáveis apenas pela avaliação da imagem, enquanto a
;; manipulação e execução do processo ficam a cargo do gerenciador e escalonador de
;; processos. As dependências de versão do Hexagon também são checadas aqui. Este
;; arquivo também tem a estrutura de manipulação de imagens HAPP que são utilizadas em
;; outras áreas do kernel.

;;************************************************************************************

;; Documentação da imagem HAPP para Hexagon
;;
;; Um arquivo no formato HAPP contêm uma imagem binária executável desenvolvida para ser
;; carregada e executada sobre o Hexagon. Essa imagem deve apresentar um cabeçalho, que
;; declara uma série de informações que serão utilizadas pelo kernel para o carregamento,
;; resolução de dependências e execução correta.
;;
;; De acordo com a especificação HAPP2 (HAPP 2.0), os campos do cabeçalho são:
;;
;; Número | Parâmetro                        | Tamanho do parâmetro | Conteúdo (fixo ou variável)
;;
;; #1       Assinatura HAPP                    4 bytes                "HAPP"
;; #2       Arquitetura de destino da imagem   1 byte                 i386 = 01h
;; #3       Versão mínima do Hexagon           1 byte                 0 para qualquer ou número correspondente
;; #4       Subversão mínima do Hexagon        1 byte                 0 para qualquer ou número correspondente
;; #5       Ponto de entrada (offset)          1 dword                Offset do ponto de entrada dentro da imagem
;; #6       Tipo da imagem                     1 byte                 Imagem executável estática = 01h
;; #7       Campo reservado                    1 dword                Reservado para uso do sistema
;; #8       Campo reservado                    1 byte                 Reservado para uso do sistema
;; #9       Campo reservado                    1 byte                 Reservado para uso do sistema
;; #10      Campo reservado                    1 byte                 Reservado para uso do sistema
;; #11      Campo reservado                    1 dword                Reservado para uso do sistema
;; #12      Campo reservado                    1 dword                Reservado para uso do sistema
;; #13      Campo reservado                    1 dword                Reservado para uso do sistema
;; #14      Campo reservado                    1 dword                Reservado para uso do sistema
;; #15      Campo reservado                    1 word                 Reservado para uso do sistema
;; #16      Campo reservado                    1 word                 Reservado para uso do sistema
;; #17      Campo reservado                    1 word                 Reservado para uso do sistema
;;
;; Para a especificação HAPP2 (HAPP 2.1), novos campos serão já reservados e já podem ser implementados
;; nas imagens de aplicativos. Os campos aumentaram para serem utilizados em futuras implementações
;; multitarefa, que exigem o armazenamento do conteúdo dos registradores para salvar o contexto de
;; execução ao trocar entre processos. O número de campos é exagerado mas garante a compatibilidade
;; para necessidades futuras do sistema. As definições de cada campo já se encontram na especificação
;; abaixo. Existem dois campos extras, com um byte e com uma qword, para armazenamento de dados
;; pertinentes ao processo, juntamente aos campos de #7 a #17, que estão reservados mas já serão
;; distribuídos na especificação HAPP2 (HAPP 2.2).
;;
;; Número | Parâmetro                        | Tamanho do parâmetro | Conteúdo (fixo ou variável)
;;
;; #18      Registrador EAX                    1 dword                Reservado para uso do sistema
;; #19      Registrador EBX                    1 dword                Reservado para uso do sistema
;; #20      Registrador ECX                    1 dword                Reservado para uso do sistema
;; #21      Registrador EDX                    1 dword                Reservado para uso do sistema
;; #22      Registrador EDI                    1 dword                Reservado para uso do sistema
;; #23      Registrador ESI                    1 dword                Reservado para uso do sistema
;; #24      Registrador CS                     1 dword                Reservado para uso do sistema
;; #25      Registrador DS                     1 dword                Reservado para uso do sistema
;; #26      Registrador ES                     1 dword                Reservado para uso do sistema
;; #27      Registrador FS                     1 dword                Reservado para uso do sistema
;; #28      Registrador GS                     1 dword                Reservado para uso do sistema
;; #29      Registrador EFLAGS                 1 dword                Reservado para uso do sistema
;; #30      Registrador EIP                    1 dword                Reservado para uso do sistema
;; #31      Registrador EBP                    1 dword                Reservado para uso do sistema
;; #32      Registrador ESP                    1 dword                Reservado para uso do sistema
;; #33      Registrador SS                     1 dword                Reservado para uso do sistema
;; #34      Número de arquivos abertos         1 dword                Reservado para uso do sistema
;; #35      Identificador do processo (PID)    1 dword                Reservado para uso do sistema
;; #36      Campo reservado                    1 word                 Reservado para uso do sistema
;; #37      Campo reservado                    1 qword                Reservado para uso do sistema
;;
;; O processo tem acesso a estes campos, e haverá uma cópia dos campos #18 a #34 em área de memória
;; reservada do kernel, uma vez que o processo poderia intencionalmente alterar valores e dados
;; de segmento para forçar acesso a áreas de memória que não foram atribuídas a ele. Estes campos
;; serão preenchidos pelo sistema e copiados (a estrutura) para o heap do kernel. O processo poderá
;; ler e editar mas a cópia já foi trasnferida para o heap do kernel, e de lá serão lidos os dados
;; para reestabelecer o contexto do processo.
;;
;; Etapas:
;;
;; Execução do processo -> Cópia da estrutura inicial para o heap do kernel e inicialização ->
;; Solicitação de troca de contexto -> Gravação do contexto nos campos #18 a #37 no espaço do aplicativo
;; e na estrutura no heap do kernel (#1 a #20).
;;
;; O processo conseguirá obter dados do contexto e da localização em memória, mas não conseguirá
;; alterar os valores de forma a interferir no funcionamento do sistema. Isso pode ser útil para
;; manipulação de dados de memória intra processo, servindo apenas de referência para o processo,
;; mas não para qualquer outro fim que burle a segurança da segmentação da GDT.
;;
;; Os campos reservados são marcados para uso do sistema. Eles poderão ser utilizados pelo sistema
;; para reservados dados em troca de contexto futuramente, por exemplo, durante a multitarefa.

;; Essa é a estrutura inicial que deve seguir as especificações HAPP em vigor.
;; Especificação utilizada: HAPP2 (HAPP 2.0)

struc Hexagon.Gerenciamento.Imagem.HAPP

{

.codigoErro:             dd 0 ;; Código de erro emitido pelo último processo
.arquiteturaImagem:      db 0 ;; Arquitetura da imagem
.imagemIncompativel:     db 0 ;; Imagem incompatível?
.versaoMinima:           db 0 ;; Versão mínima do Hexagon necessária a execução (dependência)
.subVersaoMinima:        db 0 ;; Subversão (ou revisão) do Hexagon necessária a execução (dependência)
.entradaHAPP:            dd 0 ;; Endereço de entrada do código da imagem
.tipoImagem:             db 0 ;; Tipo executável da imagem
.saidaHAPP:              dd 0 ;; Código de saída do código da imagem (futuro)
.reservado1:             db 0 ;; Reservado (Byte)
.reservado2:             db 0 ;; Reservado (Byte)
.reservado3:             db 0 ;; Reservado (Byte)
.reservado4:             dd 0 ;; Reservado (Dword)
.reservado5:             dd 0 ;; Reservado (Dword)
.reservado6:             dd 0 ;; Reservado (Dword)
.reservado7:             db 0 ;; Reservado (Byte)
.reservado8:             dw 0 ;; Reservado (Word)
.reservado9:             dw 0 ;; Reservado (Word)
.reservado10:            dw 0 ;; Reservado (Word)

}

;;************************************************************************************

;; Será criado o "objeto" Hexagon.Imagem.Executavel.HAPP para uso pelo kernel, que será
;; preenchido com dados da imagem nas funções abaixo e lido e manipulado também pelas
;; funções de gerenciamento virtual e escalonamento de processos. O escalonador obtêm
;; o ponto de entrada e manipula os dados do cabeçalho em memória

;; Esse objeto estará localizado em uma área reservada de memória do kernel

virtual at Hexagon.Heap.Temp

Hexagon.Imagem.Executavel.HAPP Hexagon.Gerenciamento.Imagem.HAPP

end virtual

;;************************************************************************************

;; Essa função realizada a análise da imagem executável do aplicativo, verificando se
;; ela apresenta o cabeçalho válido, se a arquitetura é a suportada pelo sistema e se
;; os números de versionalização do kernel são os necessários para a execução da imagem.
;; Em caso negativo, a imagem será marcada como inválida e não será executada, retornando
;; ao processo que solicitou o carregamento o código de erro 3.

Hexagon.Kernel.Lib.HAPP.verificarImagemHAPP:

;; Vamos salvar o nome do arquivo para a função que chamou

    push esi

;; O arquivo existe em disco? Precisamos dos dados de tamanho

    call Hexagon.Kernel.FS.VFS.arquivoExiste

    push eax

    mov edi, Hexagon.Heap.Temp + 1000 ;; Usar o heap do kernel

;; Vamos carregar a imagem para começar as análises

    call Hexagon.Kernel.FS.VFS.carregarArquivo

    jc .imagemAusente

;; Vamos começar a checagem do cabeçalho executável da imagem carregada
;; Pronto, agora devemos iniciar a análise da imagem

    mov edi, Hexagon.Heap.Temp + 1000 ;; Usar o heap do kernel

;; Vamos verificar os 4 bytes do "número mágico" do cabeçalho

    cmp byte[edi+0], "H" ;; H de HAPP
    jne .cabecalhoInvalido

    cmp byte[edi+1], "A" ;; A de HAPP
    jne .cabecalhoInvalido

    cmp byte[edi+2], "P" ;; P de HAPP
    jne .cabecalhoInvalido

    cmp byte[edi+3], "P" ;; P de HAPP
    jne .cabecalhoInvalido

;; Se chegamos até aqui, temos o cabeçalho no arquivo, devemos checar o restante dos campos,
;; como as versões mínimas do kernel necessárias para a execução, bem como a arquitetura

;; Vamos checar se a arquitetura da imagem é a mesma do Hexagon

    cmp byte[edi+4], Hexagon.Arquitetura.suporte ;; Arquitetura suportada
    jne .cabecalhoInvalido

    mov ah, byte[edi+4]
    mov byte[Hexagon.Imagem.Executavel.HAPP.arquiteturaImagem], ah

;; Pronto, agora vamos chegar as versões do kernel necessárias como dependências da imagem

    cmp byte[edi+5], Hexagon.Versao.numeroVersao ;; Versão declarada do kernel
    jg .cabecalhoInvalido ;; A imagem requer uma versão do Hexagon superior a essa

    cmp byte[edi+5], Hexagon.Versao.numeroVersao ;; Versão declarada do kernel
    jl .cabecalhoValido ;; A imagem requer uma versão do Hexagon superior a essa

    mov ah, byte[edi+5]
    mov byte[Hexagon.Imagem.Executavel.HAPP.versaoMinima], ah

    cmp byte[edi+6], Hexagon.Versao.numeroSubversao ;; Subversão declarada do kernel
    jg .cabecalhoInvalido ;; A imagem requer uma versão do Hexagon superior a essa

.cabecalhoValido:

    mov ah, byte[edi+6]
    mov byte[Hexagon.Imagem.Executavel.HAPP.subVersaoMinima], ah

;; Agora vamos obter o ponto de entrada. O Hexagon não precisa mais conhecer o ponto exato de
;; entrada da imagem, ele está indicado no cabeçalho HAPP. Agora, não importa mais a ordem do código,
;; o Hexagon encontrará o ponto de entrada (offset) relativo da imagem, caso ele esteja declarada no
;; cabeçalho.

    mov eax, dword[edi+7]
    mov dword[Hexagon.Imagem.Executavel.HAPP.entradaHAPP], eax

;; Os tipos de imagem podem ser (01h) imagens executáveis e (02h e 03h) bibliotecas
;; estáticas ou dinâminas (implementações futuras)

;; Primeiro, vamos avaliar se a imagem está em um formato executável funcional. Imagens do kernel podem
;; ter um número de tipo de imagem diferente, para impedir a execução direta

    cmp byte[edi+11], 03h
    ja .tipoExecutavelInvalido

;; Se tudo estiver certo, vamos prosseguir com a verificação da imagem

    mov ah, byte[edi+11]
    mov byte[Hexagon.Imagem.Executavel.HAPP.tipoImagem], ah

;; Se tudo certo com o cabeçalho, marcar que a imagem pode ser executada

    mov byte[Hexagon.Imagem.Executavel.HAPP.imagemIncompativel], 00h ;; Marcar imagem como compatível

    jmp .final ;; Vamos continuar sem marcar erro na imagem

.cabecalhoInvalido: ;; Algo no cabeçalho está inválido, então a imagem não pode ser executada

    mov byte[Hexagon.Imagem.Executavel.HAPP.imagemIncompativel], 01h ;; Marcar como inválida

    jmp .final ;; Pular para o final da função

.imagemAusente:

    mov byte[Hexagon.Imagem.Executavel.HAPP.imagemIncompativel], 02h ;; Marcar erro durante o carregamento

    jmp .final

.tipoExecutavelInvalido:

    mov byte[Hexagon.Imagem.Executavel.HAPP.imagemIncompativel], 03h

    jmp .final

.final:

    pop eax
    pop esi

    ret
