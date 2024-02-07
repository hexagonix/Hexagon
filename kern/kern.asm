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

;; Kernel Hexagon
;;
;; Daqui em diante, o ambiente de operação é o modo protegido
;;
;; Componente executivo do kernel

use32

align 4

;; Aqui vamos incluir macros para facilitar a organização e modificação do código

include "libkern/macros.s"                 ;; Macros

;;************************************************************************************
;;
;; Arquivos que compõem o Hexagon
;;
;;************************************************************************************

;; Versão do Hexagon

include "kern/versao.asm"             ;; Contêm informações de versão do Hexagon

;; Serviços do Hexagon

include "kern/uname.asm"              ;; Versão do Hexagon
include "kern/syscall.asm"            ;; Manipulador de interrupção do Hexagon
include "kern/systab.asm"             ;; Tabela com as chamadas de sistema
include "libkern/graficos.asm"        ;; Funções para gráficos do Hexagon
include "kern/servicos.asm"           ;; Rotinas de interrupção e manipuladores de IRQs

;; Usuários e outras utilidades

include "kern/dmesg.asm"              ;; Funções para manipulação de mensagens do kernel
include "kern/panico.asm"             ;; Funções para exibição e identificação de erros do Hexagon
include "kern/usuarios.asm"           ;; Gerenciamento de permissões e usuários

;; Gerenciamento de dispositivos do Hexagon

include "arch/gen/mm.asm"             ;; Gerenciamento de memória do Hexagon
include "arch/i386/mm/mm.asm"         ;; Gerenciamento de memória dependentes de arquitetura
include "dev/i386/disco/disco.asm"    ;; Funções para ler e escrever em discos rígidos do Hexagon
include "dev/gen/console/console.asm" ;; Gerenciamento de vídeo do Hexagon
include "dev/gen/teclado/teclado.asm" ;; Funções necessárias para o uso do teclado
include "arch/i386/cpu/cpu.asm"       ;; IDT, GDT e procedimentos para definir modo real e protegido
include "arch/i386/BIOS/BIOS.asm"     ;; Interrupções do BIOS em modo real
include "arch/i386/APM/apm.asm"       ;; Implementação APM do Hexagon
include "dev/gen/snd/som.asm"         ;; Controle de som do Hexagon
include "dev/gen/PS2/PS2.asm"         ;; Controle de portas PS/2 do Hexagon
include "arch/i386/timer/timer.asm"   ;; Manipulação de timer do Hexagon
include "fs/vfs.asm"                  ;; Sistema de arquivos virtual (VFS) para Hexagon
include "dev/gen/mouse/mouse.asm"     ;; Funções para mouse PS/2 do Hexagon
include "dev/gen/lpt/lpt.asm"         ;; Funções de manipulação de impressora
include "dev/gen/COM/serial.asm"      ;; Funções para manipulação de portas seriais em modo protegido
include "arch/i386/CMOS/cmos.asm"     ;; Funções para manipulação de data e hora
include "dev/dev.asm"                 ;; Funções de gerenciamento e abstração de Hardware do Hexagon

;; Processos, modelo de processo e de imagens executáveis

include "kern/proc.asm"               ;; Funções para a manipulação de processos
include "libkern/HAPP.asm"            ;; Funções para tratamento de imagens HAPP
include "kern/init.asm"               ;; Função para ir para o modo usuário

;; Sistemas de arquivos suportados pelo Hexagon

include "fs/FAT16/fat16.asm"          ;; Manipulação de arquivos no sistema de arquivos FAT16

;; Bibliotecas do Hexagon

include "libkern/string.asm"          ;; Funções para manipulação de caracteres
include "libkern/num.asm"             ;; Funções de geração e alimentação de números aleatórios
include "libkern/relogio.asm"         ;; Interface de relógio em tempo real

;; Aqui temos um stub que previne a execução da imagem do Hexagon diretamente pelo usuário, o que
;; poderia causar problemas visto a natureza da imagem (ser um kernel, não um processo comum)

include "libkern/stubHAPP.asm"        ;; Stub para prevenir execução acidental da imagem do Hexagon

;; Fonte padrão do sistema

include "libkern/fonte.asm"           ;; Fontes e serviços de texto para modo gráfico do Hexagon

;; Mensagens do Hexagon para verbose, caso seja desejado o suporte a verbose. Em caso negativo, o
;; arquivo estará em branco

include "kern/verbose.asm"            ;; Contém as mensagens para verbose exclusivas do Hexagon

;; Aqui temos as variáveis, constantes e funções para interpretar parâmetros passados pelo HBoot

include "kern/parametros.asm"         ;; Código de análise e processamento de parâmetros

;;************************************************************************************

;; Ponto de entrada do Hexagon - Inicialização do kernel

;; Aqui será realizada a configuração inicial do ambiente do kernel

Hexagon.init:

;; Primeiramente os registradores de segmento e da pilha serão configurados

    mov ax, 10h
    mov ds, ax
    mov ax, 18h ;; ES com base em 0
    mov ss, ax
    mov fs, ax
    mov gs, ax
    mov es, ax
    mov esp, 10000h ;; Definir ponteiro de pilha

    cli

;; Aqui começa o processo de autoconfiguração do kernel, incluindo a enumeração e inicialização
;; dos dispostivos compatíveis presentes. As tabelas e estruturas de controle do Hexagon também
;; serão inicializadas aqui

Hexagon.Autoconfig:

    call Hexagon.Kernel.Arch.i386.CPU.CPU.identifyProcessor ;; Identifica o processador instalado

    call Hexagon.Kernel.Arch.i386.CPU.CPU.setupProcessor ;; Configura a operação do processador

    call Hexagon.Kernel.Arch.Gen.Mm.initMemory ;; Inicia o alocador de memória do Hexagon

    call Hexagon.Kernel.Dev.Gen.Teclado.Teclado.iniciarTeclado ;; Iniciar o serviço de teclado do Hexagon

    call Hexagon.Kernel.Dev.Gen.Mouse.Mouse.iniciarMouse ;; Iniciar o serviço de mouse do Hexagon

    call Hexagon.Kernel.Dev.Gen.Console.Console.configurarConsole ;; Configura a resolução e configurações padrão de vídeo

    call Hexagon.Kernel.Kernel.Dmesg.iniciarRelatorio ;; Inicia o relatório de componentes do Hexagon

;;************************************************************************************

;; Aqui se iniciam as mensagens de aviso junto à inicialização do Hexagon

    call Hexagon.Kernel.Dev.Gen.COM.Serial.iniciarSerial ;; Iniciar corretamente a interface serial

    call Hexagon.Kernel.Dev.Gen.Console.Console.limparConsole

    kprint Hexagon.Verbose.Hexagon

    logHexagon Hexagon.Verbose.versao, Hexagon.Dmesg.Prioridades.p5

    kprint Hexagon.Dmesg.identificadorHexagon

    call Hexagon.Kernel.Kernel.Dmesg.dataParaRelatorio

    call Hexagon.Kernel.Kernel.Dmesg.horaParaRelatorio

    kprint Hexagon.Verbose.novaLinha

    kprint Hexagon.Dmesg.identificadorHexagon

    kprint Hexagon.Verbose.totalMemory

    call Hexagon.Kernel.Arch.Gen.Mm.memoryUse

    mov eax, ecx

    call Hexagon.Kernel.Dev.Gen.Console.Console.imprimirDecimal

    kprint Hexagon.Verbose.megabytes

    call Hexagon.Kernel.Arch.Gen.Mm.memoryUse

    mov eax, ebx

    call Hexagon.Kernel.Dev.Gen.Console.Console.imprimirDecimal

    kprint Hexagon.Verbose.bytes

    kprint Hexagon.Verbose.novaLinha

;;************************************************************************************

    logHexagon Hexagon.Verbose.teclado, Hexagon.Dmesg.Prioridades.p5

    logHexagon Hexagon.Verbose.mouse, Hexagon.Dmesg.Prioridades.p5

    call Hexagon.Kernel.Arch.i386.Timer.Timer.setupTimer ;; Inicializa o serviço de timer do sistema

    call Hexagon.Kernel.Kernel.Proc.iniciarEscalonador ;; Inicia o escalonador de processos do Hexagon

    call Hexagon.Kernel.Dev.Gen.COM.Serial.iniciarCOM1 ;; Iniciar primeira porta serial para debug

    call Hexagon.Kernel.FS.VFS.definirVolumeBoot ;; Define o volume com base em informações da inicialização

;;************************************************************************************

    call Hexagon.Kernel.FS.VFS.definirSistemaArquivos ;; Define o sistema de arquivos à ser utilizado para o volume

    kprint Hexagon.Dmesg.identificadorHexagon

    kprint Hexagon.Verbose.inicioMontagem

    call Hexagon.Kernel.FS.VFS.obterVolume ;; Obter o identificador do volume

    call Hexagon.Kernel.Dev.Gen.Console.Console.imprimirString ;; Exibir

    kprint Hexagon.Verbose.montagemRealizada

    kprint Hexagon.Verbose.novaLinha

;;************************************************************************************

    call Hexagon.Kernel.FS.VFS.iniciarSistemaArquivos ;; Inicializa as estruturas do sistema de arquivos do volume

    kprint Hexagon.Dmesg.identificadorHexagon

    kprint Hexagon.Verbose.sistemaArquivos

    call Hexagon.Kernel.FS.VFS.obterVolume

    push esi
    push edi

    mov al, ah
    xor ah, ah

    call Hexagon.Kernel.Dev.Gen.Console.Console.imprimirHexadecimal

    mov al, 10

    call Hexagon.Kernel.Dev.Gen.Console.Console.imprimirCaractere

    kprint Hexagon.Dmesg.identificadorHexagon

    kprint Hexagon.Verbose.rotuloVolume

    pop edi
    pop esi

    mov esi, edi

    call Hexagon.Kernel.Dev.Gen.Console.Console.imprimirString

    mov al, 10

    call Hexagon.Kernel.Dev.Gen.Console.Console.imprimirCaractere

;;************************************************************************************

    mov esi, "/"

    call Hexagon.Kernel.FS.Dir.definirPontodeMontagem

    call Hexagon.Kernel.FS.VFS.montarVolume ;; Monta o volume padrão utilizado para a inicialização

    logHexagon Hexagon.Verbose.sucessoMontagem, Hexagon.Dmesg.Prioridades.p5

;;************************************************************************************

    call Hexagon.Int.instalarInterrupcoes ;; Instala os manipuladores de interrupção do Hexagon

;; Primeiramente, deve-se impedir que o usuário mate processos com uma tecla especial, impedindo
;; que qualquer processo relevante, como o de login, seja finalizado prematuramente

;; Impede que o usuário mate processos com uma tecla especial

    call Hexagon.Kernel.Kernel.Proc.travar

    logHexagon Hexagon.Verbose.travando, Hexagon.Dmesg.Prioridades.p5

;;************************************************************************************

Hexagon.ModoUsuario:

;; Agora, devemos ir para o modo usuário, executando o primeiro processo, init. Caso
;; init não esteja presente no volume, tentar executar o shell padrão

    call Hexagon.Init.iniciarModoUsuario

;;************************************************************************************

Hexagon.Heap:

Hexagon.Heap.VBE        = Hexagon.Heap            + 0           ;; Bloco de controle de vídeo
Hexagon.Heap.CacheDisco = Hexagon.Heap.VBE        + 1200        ;; Buffer de disco
Hexagon.Heap.BCPs       = Hexagon.Heap.CacheDisco + 200000      ;; Blocos de controle de processos
Hexagon.Heap.ProcTab    = Hexagon.Heap.BCPs       + 5000        ;; Tabela de processos
Hexagon.Heap.ArgProc    = Hexagon.Heap.ProcTab    + 5000 + 500h ;; Argumentos de um processo
Hexagon.Heap.Temp       = Hexagon.Heap.ArgProc    + 2000        ;; Dados temporários
