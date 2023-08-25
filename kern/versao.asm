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
;;                         Kernel Hexagon® - Hexagon® kernel         
;;
;;                  Copyright © 2015-2023 Felipe Miguel Nery Lunkes
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

;; Arquitetura do Hexagon® 
;;
;; A arquitetura pode ser:
;;
;; 1 - i386
;; 2 - x86_x64
;; 3... Outras arquiteturas (futuras implementações?)

Hexagon.Arquitetura.suporte = 1 ;; Arquitetura desta imagem

Hexagon.Versao.definicao equ "1.3.8-beta"

Hexagon.Versao:

.numeroVersao     = 1   ;; Número principal de versão do Hexagon
.numeroSubversao  = 3   ;; Número de subversão (secundária) do Hexagon
.caractereRevisao = "8" ;; Adicionar caractere de revisão, caso necessário, entre aspas (funciona como caractere)

.nomeKernel:      db "Hexagon", 0 ;; Nome fornecido ao espaço de usuário
.build:           db __stringdia, "/", __stringmes, "/", __stringano, " "
                  db __stringhora, ":", __stringminuto, ":", __stringsegundo, " GMT", 0

Hexagon.Info:

.sobreHexagon:    db 10, 10
                  db "Hexagon(R) kernel version ", Hexagon.Versao.definicao, 10
                  db "Copyright (C) 2015-", __stringano, " Felipe Miguel Nery Lunkes", 10
                  db "All rights reserved.", 0

;;************************************************************************************

;; Retorna para os aplicativos solicitantes os número de versão e subversão do Sistema
;;
;; Saída:
;; 
;; EAX - Número da versão do Sistema
;; EBX - Número da subversão do Sistema
;; CH  - Revisão
;; EDX - Arquitetura
;; ESI - String de nome do kernel
;; EDI - Build do kernel

align 4

Hexagon.Kernel.Kernel.Versao.retornarVersao:

    mov eax, Hexagon.Versao.numeroVersao
    mov ebx, Hexagon.Versao.numeroSubversao
    mov ch, Hexagon.Versao.caractereRevisao
    mov edx, Hexagon.Arquitetura.suporte
    mov esi, Hexagon.Versao.nomeKernel
    mov edi, Hexagon.Versao.build
    
    ret
    