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
;;                 Copyright (c) 2015-2025 Felipe Miguel Nery Lunkes
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
;; Copyright (c) 2015-2025, Felipe Miguel Nery Lunkes
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

Hexagon.Kern.Init.startUserMode:

    logHexagon Hexagon.Verbose.userMode, Hexagon.Dmesg.Priorities.p5

.startInit:

;; Now Hexagon will try to load init and, if successful, transfer control to it,
;; which will finish booting the system in user mode

;; First, check if the file exists on the volume

    logHexagon Hexagon.Verbose.init, Hexagon.Dmesg.Priorities.p5

    mov esi, Hexagon.Init.Const.initHexagon

    call Hexagon.Kernel.FS.VFS.fileExists

    jc .initNotFound

    logHexagon Hexagon.Verbose.initFound, Hexagon.Dmesg.Priorities.p5

    mov eax, 0 ;; Do not provide arguments
    mov esi, Hexagon.Init.Const.initHexagon ;; Filename

    clc

    call Hexagon.Kern.Proc.exec ;; Request init loading

    logHexagon Hexagon.Verbose.withoutInit, Hexagon.Dmesg.Priorities.p5

    jnc .endInit

.initNotFound: ;; init could not be located

;; For now, Hexagon will attempt to load the system's default shell

    logHexagon Hexagon.Verbose.initNotFound, Hexagon.Dmesg.Priorities.p5

    mov eax, 0 ;; Do not provide arguments
    mov esi, Hexagon.Init.Const.shellHexagon ;; Filename

    clc

    call Hexagon.Kern.Proc.exec ;; Request loading default shell

    jnc .endShell

.endInit: ;; Print message and close the system

    mov esi, Hexagon.Verbose.Init.withoutInit

    mov eax, 1

    call Hexagon.Kern.Panic.panic

    jmp .end

.endShell:

    mov esi, Hexagon.Verbose.Init.shellExited

    mov eax, 1

    call Hexagon.Kern.Panic.panic ;; Request error screen

.end:

    ret ;; We'll never get this far

;;************************************************************************************

Hexagon.Init.Const:

.initHexagon: ;; Name of the init image on the volume
db "init", 0
.shellHexagon: ;; Default shell name
db "sh", 0
