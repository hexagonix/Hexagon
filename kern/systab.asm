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

use32

Hexagon.Kern.Syscall.hexagonServices:

.table:

;; Memory and process management

    dd Hexagon.Kern.Syscall.nullSystemCall                             ;; 0 - null function
    dd Hexagon.Arch.Gen.Mm.malloc                                      ;; 1
    dd Hexagon.Arch.Gen.Mm.free                                        ;; 2
    dd Hexagon.Kern.Proc.exec                                          ;; 3
    dd Hexagon.Kern.Proc.exit                                          ;; 4
    dd Hexagon.Kern.Proc.getPID                                        ;; 5
    dd Hexagon.Arch.Gen.Mm.memoryUse                                   ;; 6
    dd Hexagon.Kern.Proc.getProcessTable                               ;; 7
    dd Hexagon.Kern.Proc.getErrorCode                                  ;; 8

;; File and device management

    dd Hexagon.Kernel.Dev.Dev.open                                     ;; 9
    dd Hexagon.Kernel.Dev.Dev.write                                    ;; 10
    dd Hexagon.Kernel.Dev.Dev.close                                    ;; 11

;; Filesystem and volume management

    dd Hexagon.Kernel.FS.VFS.createFile                                ;; 12
    dd Hexagon.Kernel.FS.VFS.saveFile                                  ;; 13
    dd Hexagon.Kernel.FS.VFS.unlinkFile                                ;; 14
    dd Hexagon.Kernel.FS.VFS.renameFile                                ;; 15
    dd Hexagon.Kernel.FS.VFS.listFiles                                 ;; 16
    dd Hexagon.Kernel.FS.VFS.fileExists                                ;; 17
    dd Hexagon.Kernel.FS.VFS.getVolume                                 ;; 18

;; User management

    dd Hexagon.Kern.Proc.lock                                          ;; 19
    dd Hexagon.Kern.Proc.unlock                                        ;; 20
    dd Hexagon.Kern.Users.setUser                                      ;; 21
    dd Hexagon.Kern.Users.getUser                                      ;; 22

;; Hexagon services

    dd Hexagon.Kern.Uname.uname                                        ;; 23
    dd Hexagon.Libkern.Num.getRandomNumber                             ;; 24
    dd Hexagon.Libkern.Num.feedRandomGenerator                         ;; 25
    dd Hexagon.Arch.i386.Timer.Timer.sleep                             ;; 26
    dd Hexagon.Kern.Syscall.installInterruption                        ;; 27

;; Hexagon power management

    dd Hexagon.Arch.i386.APM.reboot                                    ;; 28
    dd Hexagon.Arch.i386.APM.shutdown                                  ;; 29

;; Console output functions and Hexagon graphics

    dd Hexagon.Kernel.Dev.Gen.Console.Console.print                    ;; 30
    dd Hexagon.Kernel.Dev.Gen.Console.Console.clearConsole             ;; 31
    dd Hexagon.Kernel.Dev.Gen.Console.Console.clearRow                 ;; 32
    dd Hexagon.Kernel.Dev.Gen.Console.Console.scrollConsole            ;; 33
    dd Hexagon.Kernel.Dev.Gen.Console.Console.positionCursor           ;; 34
    dd Hexagon.Libkern.Graphics.putPixel                               ;; 35
    dd Hexagon.Libkern.Graphics.drawBlockSyscall                       ;; 36
    dd Hexagon.Kernel.Dev.Gen.Console.Console.printCharacter           ;; 37
    dd Hexagon.Kernel.Dev.Gen.Console.Console.setConsoleColor          ;; 38
    dd Hexagon.Kernel.Dev.Gen.Console.Console.getConsoleColor          ;; 39
    dd Hexagon.Kernel.Dev.Gen.Console.Console.getConsoleInfo           ;; 40
    dd Hexagon.Kernel.Dev.Gen.Console.Console.updateConsole            ;; 41
    dd Hexagon.Kernel.Dev.Gen.Console.Console.setResolution            ;; 42
    dd Hexagon.Kernel.Dev.Gen.Console.Console.getResolution            ;; 43
    dd Hexagon.Kernel.Dev.Gen.Console.Console.getCursor                ;; 44

;; Hexagon keyboard input services

    dd Hexagon.Kernel.Dev.Gen.Keyboard.Keyboard.waitKeyboard           ;; 45
    dd Hexagon.Kernel.Dev.Gen.Keyboard.Keyboard.getString              ;; 46
    dd Hexagon.Kernel.Dev.Gen.Keyboard.Keyboard.getSpecialKeysStatus   ;; 47
    dd Hexagon.Kernel.Dev.Gen.Console.Console.changeFont               ;; 48
    dd Hexagon.Kernel.Dev.Gen.Keyboard.Keyboard.changeLayout           ;; 49

;; Hexagon PS/2 mouse input services

    dd Hexagon.Kernel.Dev.Gen.Mouse.Mouse.waitMouseEvent               ;; 50
    dd Hexagon.Kernel.Dev.Gen.Mouse.Mouse.getFromMouse                 ;; 51
    dd Hexagon.Kernel.Dev.Gen.Mouse.Mouse.setMouse                     ;; 52

;; Hexagon data handling services

    dd Hexagon.Libkern.String.compareWordsInString                     ;; 53
    dd Hexagon.Libkern.String.removeCharacterInString                  ;; 54
    dd Hexagon.Libkern.String.insertCharacterInString                  ;; 55
    dd Hexagon.Libkern.String.stringSize                               ;; 56
    dd Hexagon.Libkern.String.isEqual                                  ;; 57
    dd Hexagon.Libkern.String.toUppercase                              ;; 58
    dd Hexagon.Libkern.String.toLowercase                              ;; 59
    dd Hexagon.Libkern.String.trimString                               ;; 60
    dd Hexagon.Libkern.String.findCharacterInString                    ;; 61
    dd Hexagon.Libkern.String.stringToInteger                          ;; 62
    dd Hexagon.Libkern.String.integetToString                          ;; 63

;; Hexagon sound output services

    dd Hexagon.Kernel.Dev.Gen.Snd.Snd.playSound                        ;; 64
    dd Hexagon.Kernel.Dev.Gen.Snd.Snd.stopSound                        ;; 65

;; Hexagon messaging service

    dd Hexagon.Kern.Dmesg.createMessage                                ;; 66

;; Hexagon real-time clock service

    dd Hexagon.Libkern.Clock.getDate                                   ;; 67
    dd Hexagon.Libkern.Clock.getTime                                   ;; 68

;; Extended (Dormin development branch) syscalls

    dd Hexagon.Kernel.FS.VFS.changeDirectory
