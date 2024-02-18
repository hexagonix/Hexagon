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

Hexagon.Int:

.interrupcaoHexagon  = 80h ;; Interrupção do Hexagon
.interrupcaoTimer    = 08h ;; Interrupção reservada ao timer
.interrupcaoTeclado  = 09h ;; Interrupção reservada ao teclado
.interrupcaoMouse    = 74h ;; Interrupção reservada ao dispositivo apontador

;;************************************************************************************

;; Instala as rotinas de interrupção do Hexagon (ISR - Interrupt Service Routine)

Hexagon.Int.instalarInterrupcoes:

;; Instalar os manipuladores de IRQs

    mov dword[ordemKernel], ordemKernelExecutar

    mov esi, Hexagon.Int.manipuladorTimer ;; IRQ 0
    mov eax, Hexagon.Int.interrupcaoTimer ;; Número da interrupção

    call Hexagon.Int.instalarISR

    mov esi, Hexagon.Int.manipuladorTeclado ;; IRQ 1
    mov eax, Hexagon.Int.interrupcaoTeclado ;; Número da interrupção

    call Hexagon.Int.instalarISR

    mov esi, Hexagon.Int.manipuladorMousePS2 ;; IRQ 12
    mov eax, Hexagon.Int.interrupcaoMouse    ;; Número da interrupção

    call Hexagon.Int.instalarISR

;; Instalar o manipulador de chamadas do Hexagon

    mov esi, Hexagon.Syscall.Syscall.manipuladorHexagon ;; Serviços do Hexagon
    mov eax, Hexagon.Int.interrupcaoHexagon ;; Número da interrupção

    call Hexagon.Int.instalarISR

    sti ;; Habilitar interrupções

    mov dword[ordemKernel], ordemKernelDesativada

    ret ;; Tudo pronto

;;************************************************************************************

;; IRQ 0 - Manipulador do Timer

;; A cada interrupção do timer, será incromentado o contador. Este contador pode
;; ser utilizado para temporizar operações de entrada e saída, assim como causar
;; atraso em diversas aplicações do Sistema e de aplicativos.

Hexagon.Int.manipuladorTimer:

    push eax

    push ds

    mov ax, 10h ;; Kernel data segment
    mov ds, ax

;; Atualizar o relógio em tempo real a cada intervalo

    call Hexagon.Kernel.Arch.i386.CMOS.CMOS.updateCMOSData

    inc dword[.contagemTimer] ;; Incrementa o contador
    inc dword[.contadorRelativo]

    mov al, 20h

    out 20h, al

    pop ds
    pop eax

    iret

.contagemTimer:    dd 0 ;; Este conteúdo é utilizado
.contadorRelativo: dd 0

;;************************************************************************************

;; Manipuladores de interrupção

;; IRQ 1 - Interrupção de teclado

Hexagon.Int.manipuladorTeclado:

    push eax
    push ebx

    push ds

    mov ax, 10h ;; Kernel data segment
    mov ds, ax

    xor eax,eax

    in al, 60h

    cmp al, Hexagon.Keyboard.keyCodes.F1 ;; Tecla F1
    je .terminarTarefa

;; Checar se a tecla Control foi pressionada

    cmp al, Hexagon.Keyboard.keyCodes.ctrl
    je .controlPressionada

    cmp al, 29+128
    je .controlLiberada

;; Checar pressionamento da tecla Shift

    cmp al, Hexagon.Keyboard.keyCodes.shiftD ;; Tecla shift da direita
    je .shiftPressionado

    cmp al, Hexagon.Keyboard.keyCodes.shiftE ;; Tecla shift da esquerda
    je .shiftPressionado

    cmp al, 54+128 ;; Tecla shift direita liberada
    je .shiftLiberado

    cmp al, 42+128 ;; Tecla shift esquerda liberada
    je .shiftLiberado

    jmp .outraTecla

.controlPressionada:

    or dword[keyStatus], 0x00000001

    jmp .naoArmazenar

.controlLiberada:

    and dword[keyStatus], 0xFFFFFFFE

    jmp .naoArmazenar

.shiftPressionado:

    or dword[keyStatus], 0x00000002

    mov byte[.sinalShift], 1 ;; Shift pressionada

    jmp .naoArmazenar

.shiftLiberado:

    and dword[keyStatus], 0xFFFFFFFD

    mov byte[.sinalShift], 0

    jmp .naoArmazenar

.outraTecla:

    jmp .fim

;;************************************************************************************

.terminarTarefa:

    call Hexagon.Kernel.Kernel.Proc.matarProcesso

;;************************************************************************************

.fim:

    mov ebx, .codigosEscaneamento
    add bl, byte[.codigosEscaneamento.indice]

    mov byte[ebx], al

    cmp byte[.codigosEscaneamento.indice], 31
    jl .incrementarIndice

    mov byte[.codigosEscaneamento.indice], -1

.incrementarIndice:

    inc byte[.codigosEscaneamento.indice]

.naoArmazenar:

    mov al, 20h

    out 20h, al

    pop ds

    pop ebx
    pop eax

    iret

.codigosEscaneamento:
times 32 db 0
.codigosEscaneamento.indice: db 0
.sinalShift: db 0

;; Bit 0: Tecla Control
;; Bit 1: Tecla Shift
;; Bit 2-31: Reservado

keyStatus: dd 0

;;************************************************************************************

;; IRQ 12 - Manipulador de Mouse PS/2

Hexagon.Int.manipuladorMousePS2:

    pusha

    cmp byte[.estado], 0
    je .pacoteDeDados

    cmp byte[.estado], 1
    je .pacoteX

    cmp byte[.estado], 2
    je .pacoteY

.pacoteDeDados:

    in al, 60h

    mov byte[.dados], al

    mov byte[.estado], 1

    jmp .finalizar

.pacoteX:

    in al, 60h

    mov byte[.deltaX], al

    mov byte[.estado], 2

    jmp .finalizar

.pacoteY:

    in al, 60h

    mov byte[.deltaY], al

    mov byte[.estado], 0

    mov byte[.alterado], 1

.fim:

    movzx eax, byte[Hexagon.Int.manipuladorMousePS2.deltaX] ;; DeltaX alterado em X
    movzx ebx, byte[Hexagon.Int.manipuladorMousePS2.deltaY] ;; DeltaY alterado em Y
    mov dl, byte[Hexagon.Int.manipuladorMousePS2.dados]

    bt dx, 4 ;; Checar se o mouse se moveu para a esquerda
    jnc .movimentoADireita

    xor eax, 0xFF ;; 255 - deltaX
    sub word[.mouseX], ax ;; MouseX - DeltaX

    jnc .xOK ;; Checar se MouseX é menor que 0
    mov word[.mouseX], 0 ;; Corrigir MouseX

    jmp .xOK

.movimentoADireita:

    add word[.mouseX], ax ;; MouseX + DeltaX

.xOK:

    bt dx, 5 ;; Checar se o mouse se moveu para baixo
    jnc .movimentoParaCima

    xor ebx, 0xFF ;; 255 - DeltaY
    sub word[.mouseY], bx ;; MouseY - DeltaY

    jnc .yOK ;; Checar se MouseY é menor que 0
    mov word[.mouseY], 0 ;; Corrigir MouseY

    jmp .yOK

.movimentoParaCima:

    add word[.mouseY], bx ;; MouseY + DeltaY

.yOK:

    movzx eax, word[.mouseX]
    movzx ebx, word[.mouseY]

;; Ter certeza que X e Y não são maiores que a resolução do vídeo

    cmp ax, word[Hexagon.Console.Resolution.x]
    jng .xNaoMaior

    mov ax, word[Hexagon.Console.Resolution.x]
    mov word[.mouseX], ax

.xNaoMaior:

    cmp bx, word[Hexagon.Console.Resolution.y]
    jng .yNaoMaior

    mov bx, word[Hexagon.Console.Resolution.y]
    mov word[.mouseY], bx

.yNaoMaior:

    push edx
    movzx edx, word[Hexagon.Console.Resolution.y]
    sub dx, word[.mouseY]
    mov ebx, edx
    pop edx

    mov dword[Hexagon.Kernel.Dev.Gen.Mouse.mouseX], eax
    mov dword[Hexagon.Kernel.Dev.Gen.Mouse.mouseY], ebx

.finalizar:

    mov al, 20h ;; Fim da interrupção

    out 20h, al
    out 0xA0, al

    popa

    iret

.estado:   db 0
.deltaX:   db 0
.deltaY:   db 0
.dados:    db 0
.alterado: db 0

align 32

.estadoMouse: dd 0
.mouseX:      dd 0
.mouseY:      dd 0

;;************************************************************************************

;; Manipulador especializado para touchpads - IRQ 12

Hexagon.Int.manipuladorTouchpad:

    push eax
    push edx

    cmp byte[.estado], 0
    je .pacote0

    cmp byte[.estado], 1
    je .pacote1

    cmp byte[.estado], 2
    je .pacote2

    cmp byte[.estado], 3
    je .pacote3

    cmp byte[.estado], 4
    je .pacote4

    cmp byte[.estado], 5
    je .pacote5

.pacote0:

    mov al, 0

    call Hexagon.Kernel.Dev.Gen.Console.Console.clearRow

    in al, 60h

    movzx eax, al
    mov dl, 0
    mov dh, 0

    call Hexagon.Kernel.Dev.Gen.Console.Console.printBinary

    mov byte[.estado], 1

    jmp .fim

.pacote1:

    mov al, 1

    call Hexagon.Kernel.Dev.Gen.Console.Console.clearRow

    in al, 60h

    mov bl, al

    and al, 1111b
    movzx eax, al
    shl eax, 8
    mov word[.X], ax

    mov al, bl
    and al, 11110000b
    movzx eax, al
    shl eax, 4
    mov word[.Y], ax

    mov al, bl
    movzx eax, al
    mov dl, 0
    mov dh, 1

    call Hexagon.Kernel.Dev.Gen.Console.Console.printBinary

    mov byte[.estado], 2

    jmp .fim

.pacote2:

    mov al, 2

    call Hexagon.Kernel.Dev.Gen.Console.Console.clearRow

    in al, 60h

    movzx eax, al
    mov dl, 0
    mov dh, 2

    call Hexagon.Kernel.Dev.Gen.Console.Console.printDecimal

    mov byte[.estado], 3

    jmp .fim

.pacote3:

    mov al, 3

    call Hexagon.Kernel.Dev.Gen.Console.Console.clearRow

    in al, 60h

    mov bl, al

    movzx eax, al
    and eax, 00010000b
    shl eax, 8
    or word[.X], ax

    mov al, bl

    movzx eax, al
    and eax, 00100000b
    shl eax, 7
    or word[.Y], ax

    mov al, bl

    movzx eax, al
    mov dl, 0
    mov dh, 3

    call Hexagon.Kernel.Dev.Gen.Console.Console.printBinary

    mov byte[.estado], 4

    jmp .fim

.pacote4:

    mov al, 4

    call Hexagon.Kernel.Dev.Gen.Console.Console.clearRow

    in al, 60h

    movzx ax, al
    or word[.X], ax

    movzx eax, word[.X]

;; sub EAX, 1000

    mov dl, 0
    mov dh, 4

    call Hexagon.Kernel.Dev.Gen.Console.Console.printDecimal

    mov byte[.estado], 5

    jmp .fim

.pacote5:

    mov al, 5

    call Hexagon.Kernel.Dev.Gen.Console.Console.clearRow

    in al, 60h

    movzx ax, al
    or word[.Y], ax

    movzx eax, word[.Y]

;; sub EAX, 1000

    mov dl, 0
    mov dh, 5

    call Hexagon.Kernel.Dev.Gen.Console.Console.printDecimal

    mov byte[.estado], 0

    jmp .fim

.fim:

    mov al, 20h ;; Fim da interrupção

    out 20h, al

    out 20h, al

    pop edx
    pop eax

    iret

.estado: db 0
.X:      dw 0
.Y:      dw 0
.Z:      db 0

;;************************************************************************************

;; Manipulador para outras interrupções, quando as mesmas não estiverem disponíveis

Hexagon.Int.nullHandler:

    push eax

    mov al, 20h

    out 20h, al

    pop eax

    iret

;;************************************************************************************

;; Instala um manipulador de interrupção ou manipulador IRQ
;;
;; Entrada:
;;
;; EAX - Número da interrupção
;; ESI - Rotina de interrupção

Hexagon.Int.instalarISR:

    push eax
    push ebp

;; Primeiramente vamos verificar se o pedido de instalação de interrupção partiu
;; do Hexagon, observando a variável que registra essas solicitações previlegiadas

    cmp dword[ordemKernel], ordemKernelExecutar ;; Caso sim, ignorar medidas de discriminação
    je .instalar

;; Caso a solicitação tenha partido do usuário ou aplicativo, verificar se os valores
;; passados poderiam sobrescrever as interrupções instaladas previamente pelo Hexagon

    cmp eax, Hexagon.Int.interrupcaoHexagon ;; Tentativa de substituir a chamada do Hexagon
    je .negar ;; Negar instalação

    cmp eax, Hexagon.Int.interrupcaoTimer ;; Tentativa de alterar a interrupção de timer
    je .negar ;; Negar instalação

    cmp eax, Hexagon.Int.interrupcaoTeclado ;; Tentativa de alterar a interrupção de teclado
    je .negar ;; Negar instalação

    cmp eax, Hexagon.Int.interrupcaoMouse ;; Tentativa de alterar a interrupção de mouse
    je .negar ;; Negar instalação

.instalar:

    mov ebp, eax
    mov eax, esi

    mov word[IDT+ebp*8], ax
    shr eax, 16

    mov word[IDT+ebp*8+6], ax

    jmp .fim

.negar:

    stc

    mov eax, 01h

.fim:

    pop ebp
    pop eax

    ret
