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

;; As mensagens só serão adicionadas ao Hexagon em caso de ativação da verbose em
;; tempo de montagem. Se o símbolo não for definido, o kernel não terá suporte a
;; verbose direta, mas continuará com a função para o mecanismo de mensagem.

;;************************************************************************************

use32

align 4

match =YES, VERBOSE {

Hexagon.Verbose:

.Hexagon:
db "Welcome to Hexagon", 10
db "Copyright (C) 2015-", __stringYear, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 10, 10, 0
.version:
db "Hexagon kernel version: ", Hexagon.Version.definition, 0
.locking:
db "Enabling user and security guidelines...", 0
.timer:
db "Starting and setting up the timer (119 Hz)...", 0
.scheduler:
db "Starting and setting up the scheduler...", 0
.heapKernel:
db "Setting up the kernel heap...", 0
.keyboard:
db "The keyboard management service has started.", 0
.mouse:
db "The mouse management service has started.", 0
.serial:
db "The serial port management service is starting...", 0
.setVolume:
db "Hexagon is looking for a volume to mount...", 0
.startMounting:
db "The volume ", 0
.mountPointDefined:
db " has been marked for mounting on /.", 0
.filesystem:
db "The mounted volume is formatted as (FSID): ", 0
.volumeLabel:
db "The volume label is: ", 0
.mountSuccess:
db "Volume successfully mounted on /.", 0
.init:
db "Looking for /init...", 0
.withoutInit:
db "/init not found at the root of the volume. Trying /sh...", 0
.userMode:
db "Going to user mode...", 0
.totalMemory:
db "Total memory installed and available: ", 0
.megabytes:
db " Mb (", 0
.bytes:
db " bytes).", 0
.initFound:
db "PID 1: starting /init.", 0
.initNotFound:
db "PID 1: looking for /sh...", 0
.shuttingDow:
db "Shuting down and halting the CPU...", 0
.newLine:
db 10, 0
.invalidOpcode:
db "Invalid opcode found at runtime. Failure.", 0

;;************************************************************************************

Hexagon.Verbose.APM:

.rebootAPM:
db "Requesting restart...", 0
.serviceAPM:
db "Requesting power management service...", 0
.shutdownAPM:
db "Requesting shutdown...", 0
.errorAPM:
db "An error occurred in the power management service request.", 0
.commandErrorAPM:
db "An error occurred in the command given to power management service.", 0
.connectionErrorAPM:
db "There was an error connecting to the power management service.", 0
.shutdownSuccessAPM:
db "Success in requesting the power management system.", 0
.instalationErrorAPM:
db "Error installing Hexagon power management service.", 0

;;************************************************************************************

Hexagon.Verbose.Services:

.killProcess:
db "The process running with this PID was terminated by Hexagon.", 0

;;************************************************************************************

Hexagon.Verbose.Disk:

.diskError:
db "Hexagon was unable to access the requested disk.", 10, 10
db 10, 10, "An unknown error prevented Hexagon from accessing the disk properly.", 10
db "To prevent data loss, system has been terminated.", 10
db "This problem could be one-off. And don't worry, your data is intact.", 10
db "If something went wrong, please use the system installation disk for correct possible", 10
db "disk errors.", 10, 10, 0
.readErrorMBR:
db "Error reading volume MBR.", 0
.writeErrorMBR:
db "Error trying to read volume BPB.", 0
.resetDiskError:
db "Error requesting disk restart.", 0
.diskNotDetectedError:
db "The requested disk/volume is not detected or is offline.", 0
.generalReadError:
db "General error when trying to read sectors on the volume.", 0
.noMediaError:
db "The requested disk/volume is not online.", 0
.writeProtectedError:
db "The volume is write protected. Failed to write sectors.", 0
.diskNotReadyError:
db "The disk/volume is not ready.", 0
.diskBusyError:
db "The volume is already in use by Hexagon or another process.", 0
.writeError:
db "Error writing to volume.", 0
.generalWriteError:
db "General error when trying to write sectors to the volume.", 0

;;************************************************************************************

Hexagon.Verbose.Init:

.withoutInit:
db "A critical component (init) was not found on the boot volume.", 10, 10
db "Make sure the 'init' file or equivalent is present on the system volume.", 10
db "If not present, use the original installation media to correct this problem.", 10, 10, 0
.componentExited:
db "A critical component (init) terminated unexpectedly.", 10, 10
db "Some unexpected error caused a system component to terminate.", 10
db "This problem prevents the system from running properly and to avoid any more serious problem or the", 10
db "loss of your data, the system has halted.", 10, 0
.withoutShell:
db "The default shell (/sh) was not found on this volume.", 10, 10
db "Make sure the default shell is present on the system volume and try again.", 10
db "If not present, use the installation disc to correct this problem.", 10, 10, 0
.shellExited:
db "The shell terminated unexpectedly.", 10, 10
db "Some unexpected error caused the shell to terminate.", 10
db "This problem prevents the system from running properly and to avoid any more serious problem or the", 10
db "loss of your data, the system has halted.", 10, 0

}
