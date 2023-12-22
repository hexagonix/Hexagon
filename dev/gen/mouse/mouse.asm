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

Hexagon.Mouse:

.mouseX: dd 0
.mouseY: dd 0

;;************************************************************************************

;; Inicializar o mouse PS/2

Hexagon.Kernel.Dev.Gen.Mouse.Mouse.iniciarMouse:

    push eax

;; Habilitar IRQ para o mouse

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.esperarEscritaPS2 ;; Esperar se PS/2 estiver ocupado

    mov al, 20h ;; Obter bit de status Compaq

    out 64h, al ;; 64h é o registrador de estado

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.esperarLeituraPS2

    in al, 60h

    or al, 2   ;; Definir segundo bit para 1 pra habilitar IRQ12
    mov bl, al ;; Salvar bit modificado

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.esperarEscritaPS2

    mov al, 60h ;; Definir byte de estado Compaq

    out 64h, al

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.esperarEscritaPS2

    mov al, bl ;; Enviar byte modificado

    out 60h, al

;; Habilitar dispositivo auxiliar (Mouse)

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.esperarEscritaPS2

    mov al, 0xA8 ;; Habilitar dispositivo auxiliar

    out 64h, al

;; Usar configurações padrão

    mov al, 0xF6 ;; Definir como padrão

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.enviarPS2

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.esperarLeituraPS2

    in al, 60h

;; Definir resolução

    mov al, 0xE8

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.enviarPS2

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.esperarLeituraPS2

    in al, 60h

    mov al, 3 ;; 8 contagens/mm

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.enviarPS2

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.esperarLeituraPS2

    in al, 60h

;; Habilitar pacotes

    mov al, 0xF4 ;; Habilitar pacotes

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.enviarPS2

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.esperarLeituraPS2

    in al, 60h

    mov ax, word[Hexagon.Console.Resolucao.y]
    mov word[Hexagon.Int.manipuladorMousePS2.mouseY], ax

    pop eax

    ret

;;************************************************************************************

;; Obter posição atual do mouse e estado dos botões
;;
;; Saída:
;;
;; EAX - Posição X do mouse
;; EBX - Posição Y do mouse
;; EDX - Botões do mouse (bit #0 = botão esquerdo, bit #1 = botão direito)

Hexagon.Kernel.Dev.Gen.Mouse.Mouse.obterDoMouse:

    mov eax, [Hexagon.Mouse.mouseX]
    mov ebx, [Hexagon.Mouse.mouseY]
    mov edx, 0 ;; byte[manipuladorMousePS2.dados]

    ret

;;************************************************************************************

;; Definir nova posição do mouse
;;
;; Entrada:
;;
;; EAX - Posição X do mouse
;; EBX - Posição Y do mouse

Hexagon.Kernel.Dev.Gen.Mouse.Mouse.configurarMouse:

    mov [Hexagon.Mouse.mouseX], eax
    mov [Hexagon.Mouse.mouseY], ebx
    mov byte[Hexagon.Int.manipuladorMousePS2.dados], 0

    ret

;;************************************************************************************

Hexagon.Kernel.Dev.Gen.Mouse.Mouse.iniciarTouchPad:

    push eax

    mov al, 0xF5 ;; Desativar

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.enviarPS2

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.esperarLeituraPS2

    in al, 60h

    mov al, 0xE8

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.enviarPS2

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.esperarLeituraPS2

    in al, 60h

    mov al, 0x03

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.enviarPS2

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.esperarLeituraPS2

    in al, 60h

    mov al, 0xE8

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.enviarPS2

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.esperarLeituraPS2

    in al, 60h

    mov al, 0x00

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.enviarPS2

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.esperarLeituraPS2

    in al, 60h

    mov al, 0xE8

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.enviarPS2

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.esperarLeituraPS2

    in al, 60h

    mov al, 00h

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.enviarPS2

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.esperarLeituraPS2

    in al, 60h

    mov al, 0xE8

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.enviarPS2

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.esperarLeituraPS2

    in al, 60h

    mov al, 01h

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.enviarPS2

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.esperarLeituraPS2

    in al, 60h

    mov al, 0xF3

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.enviarPS2

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.esperarLeituraPS2

    in al, 60h

    mov al, 0x14

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.enviarPS2

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.esperarLeituraPS2

    in al, 60h

    mov al, 0xF4 ;; Habilitar

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.enviarPS2

    call Hexagon.Kernel.Dev.Gen.PS2.PS2.esperarLeituraPS2

    in al, 60h

    mov esi, Hexagon.Int.manipuladorTouchpad ;; IRQ 12
    mov eax, 74h ;; Número da interrupção

    call Hexagon.Int.instalarISR

    pop eax

    ret

;;************************************************************************************

;; Aguardar por eventos do mouse e obter seus valores
;;
;; Saída:
;;
;; EAX - Posição X do mouse
;; EBX - Posição Y do mouse
;; EDX - Botões do mouse (bit #0 = botão esquerdo, bit #1 = botão direito)

;; Aguardar por eventos do mouse e obter seus valores
;;
;; Saída:
;;
;; EAX - Posição X do mouse
;; EBX - Posição Y do mouse
;; EDX - Botões do mouse (bit #0 = botão esquerdo, bit #1 = botão direito)

Hexagon.Kernel.Dev.Gen.Mouse.Mouse.aguardarMouse:

    sti

    mov byte[Hexagon.Int.manipuladorMousePS2.alterado], 0

.aguardar:

;; Checar se o estado do mouse foi alterado

    cmp byte[Hexagon.Int.manipuladorMousePS2.alterado], 1

    hlt

    jne .aguardar

    mov eax, [Hexagon.Mouse.mouseX]
    mov ebx, [Hexagon.Mouse.mouseY]
    movzx edx, byte[Hexagon.Int.manipuladorMousePS2.dados]

    ret
