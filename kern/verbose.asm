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
                                                                
;;************************************************************************************
;;
;;                    Este arquivo faz parte do Kernel Hexagon® 
;;
;;************************************************************************************

;; As mensagens só serão adicionadas ao Hexagon® em caso de ativação da verbose em
;; tempo de montagem. Se o símbolo não for definido, o Kernel não terá suporte a 
;; verbose direta, mas continuará com a função para o mecanismo de mensagem. 

;;************************************************************************************

use32

match =SIM, VERBOSE {
    
Hexagon.Verbose:

.Hexagon:           db "Welcome to Hexagon(R)", 10
                    db "Copyright (C) 2016-", __stringano, " Felipe Miguel Nery Lunkes", 10
                    db "All rights reserved.", 10, 10, 0
.versao:            db "Hexagon(R) kernel version: ", Hexagon.Versao.definicao, 0
.travando:          db "Enabling user and security guidelines...", 0
.timer:             db "Starting and setting up the timer (119 Hz)...", 0
.escalonador:       db "Starting and setting up the scheduler...", 0
.teclado:           db "The keyboard management service has started.", 0 
.mouse:             db "The mouse management service has started.", 0
.serial:            db "The serial port management service is starting...", 0
.definirVolume:     db "Hexagon is looking for a volume to mount...", 0
.inicioMontagem:    db "The volume ", 0
.montagemRealizada: db " has been marked for mounting on /.", 0
.sistemaArquivos:   db "The mounted volume is formatted as (FSID): ", 0
.rotuloVolume:      db "The volume label is: ", 0
.sucessoMontagem:   db "Volume successfully mounted on /.", 0
.init:              db "Looking for /init...", 0
.semInit:           db "/init not found at the root of the volume. Trying /sh...", 0
.modoUsuario:       db "Going to user mode...", 0
.memoriaTotal:      db "Total memory installed and available: ", 0
.megabytes:         db " Mb (", 0
.bytes:             db " bytes).", 0
.initEncontrado:    db "PID 1: starting /init.", 0
.initNaoEncontrado: db "PID 1: looking for /sh...", 0
.desligando:        db "Shuting down and halting the CPU...", 0
.novaLinha:         db 10, 0
.opcodeInvalido:    db "Invalid opcode found at runtime. Failure.", 0

Hexagon.Verbose.APM:

.reinicioAPM:            db "Requesting restart...", 0
.servicoAPM:             db "Requesting power management service...", 0
.desligamentoAPM:        db "Requesting shutdown...", 0
.erroAPM:                db "An error occurred in the power management service request.", 0
.erroComandoAPM:         db "An error occurred in the command given to power management service.", 0
.erroConexaoAPM:         db "There was an error connecting to the power management service.", 0
.sucessoDesligamentoAPM: db "Success in requesting the power management system.", 0
.erroInstalacaoAPM:      db "Error installing Hexagon(R) power management service.", 0

Hexagon.Verbose.Servicos:

.matarProcesso: db "The process running with this PID was terminated by Hexagon.", 0

Hexagon.Verbose.Disco:

.erroLerMBR:            db "Error reading volume MBR.", 0
.erroLerBPB:            db "Error trying to read volume BPB.", 0
.erroReiniciarDisco:    db "Error requesting disk restart.", 0
.erroDiscoNaoDetectado: db "The requested disk/volume is not detected or is offline.", 0
.erroGeralLeitura:      db "General error when trying to read sectors on the volume.", 0
.erroSemMidia:          db "The requested disk/volume is not online.", 0
.erroProtegidoEscrita:  db "The volume is write protected. Failed to write sectors.", 0
.erroDiscoNaoPronto:    db "The disk/volume is not ready.", 0
.erroEmUso:             db "The volume is already in use by Hexagon or another process.", 0
.erroEscrita:           db "Error writing to volume.", 0
.erroGeralEscrita:      db "General error when trying to write sectors to the volume.", 0

}
