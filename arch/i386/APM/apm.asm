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

;;*********************************************************************
;;
;;                    Hexagon APM implementation
;;
;;*********************************************************************

;;************************************************************************************

Hexagon.Arch.i386.APM:

.status: db 0

;;************************************************************************************

;; Restart the device

Hexagon.Kernel.Arch.i386.APM.reboot:

match =YES, VERBOSE
{

    mov esi, Hexagon.Verbose.APM.servicoAPM
    mov ebx, Hexagon.Dmesg.Prioridades.p5

    call Hexagon.Kernel.Kernel.Dmesg.criarMensagemHexagon

    mov esi, Hexagon.Verbose.APM.reinicioAPM
    mov ebx, Hexagon.Dmesg.Prioridades.p5

    call Hexagon.Kernel.Kernel.Dmesg.criarMensagemHexagon

}

.waitLoop:

    in al, 64h ;; 64h is the state register

    bt ax, 1 ;; Check second bit until it becomes 0
    jnc .end

    jmp .waitLoop

.end:

    mov al, 0xFE

    out 64h, al

    cli

    jmp $

    ret

;;************************************************************************************

Hexagon.Kernel.Arch.i386.APM.shutdown:

match =YES, VERBOSE
{

    mov esi, Hexagon.Verbose.APM.servicoAPM
    mov ebx, Hexagon.Dmesg.Prioridades.p5

    call Hexagon.Kernel.Kernel.Dmesg.criarMensagemHexagon

    mov esi, Hexagon.Verbose.APM.desligamentoAPM
    mov ebx, Hexagon.Dmesg.Prioridades.p5

    call Hexagon.Kernel.Kernel.Dmesg.criarMensagemHexagon

}

    call Hexagon.Kernel.Dev.i386.Disk.Disk.stopDisk ;; First, let's stop the disks

;;*********************************************************************
;;
;; This function can return error codes, which are as follows:
;;
;;
;; Return in AX - error code:
;;
;; 0 = Driver installation failed
;; 1 = Real Mode interface connection failure
;; 2 = APM driver version 1.2 not supported
;; 3 = Failed to change status to "off"
;;
;;*********************************************************************

    push bx
    push cx

    mov ax, 5300h ;; Installation check function
    mov bx, 0 ;; The device ID (APM BIOS)

    call Hexagon.Kernel.Arch.i386.BIOS.BIOS.int15h ;; Call APM interrupt

    jc .failedToInstallAPM

    mov ax, 5301h ;; Real mode connection interface function
    mov bx, 0 ;; The device ID (APM BIOS)

    call Hexagon.Kernel.Arch.i386.BIOS.BIOS.int15h ;; Call APM interrupt

    jc .failedToConnectAPM

    mov ax, 530Eh ;; Driver version selection function
    mov bx, 0     ;; The device ID (APM BIOS)
    mov cx, 0102h ;; Select APM version 1.2
                  ;; The functionality is present after version 1.2
    call Hexagon.Kernel.Arch.i386.BIOS.BIOS.int15h ;; Call APM interrupt

    jc .failedToSelectAPMVersion

    mov ax, 5307h ;; Set state function
    mov cx, 0003h ;; Power off state
    mov bx, 0001h ;; All devices have ID 1

    call Hexagon.Kernel.Arch.i386.BIOS.BIOS.int15h ;; Call APM interrupt

;; If the system does not shut down properly, error codes will be returned to the
;; program that called the shutdown function.

.commandFailure: ;; Called if the shutdown command (code 3) is not executed

match =YES, VERBOSE
{

    mov esi, Hexagon.Verbose.APM.erroComandoAPM
    mov ebx, Hexagon.Dmesg.Prioridades.p5

    call Hexagon.Kernel.Kernel.Dmesg.criarMensagemHexagon

}

    mov ax, 3

    jmp .desligamentoFalhouAPM

.failedToInstallAPM: ;; Called if installation fails

match =YES, VERBOSE
{

    mov esi, Hexagon.Verbose.APM.erroInstalacaoAPM
    mov ebx, Hexagon.Dmesg.Prioridades.p5

    call Hexagon.Kernel.Kernel.Dmesg.criarMensagemHexagon

}

    mov ax, 0

    jmp .desligamentoFalhouAPM

.failedToConnectAPM: ;; Called if the Real Mode interface connection fails

match =YES, VERBOSE
{

    mov esi, Hexagon.Verbose.APM.erroConexaoAPM
    mov ebx, Hexagon.Dmesg.Prioridades.p5

    call Hexagon.Kernel.Kernel.Dmesg.criarMensagemHexagon

}

    mov ax, 1

    jmp .desligamentoFalhouAPM

.failedToSelectAPMVersion: ;; Called when APM version is less than 1.2

    mov ax, 2

.desligamentoFalhouAPM: ;; Returns the function that called it

match =YES, VERBOSE
{

    mov esi, Hexagon.Verbose.APM.sucessoDesligamentoAPM
    mov ebx, Hexagon.Dmesg.Prioridades.p5

    call Hexagon.Kernel.Kernel.Dmesg.criarMensagemHexagon

}

    pop cx
    pop bx

    stc

    ret
