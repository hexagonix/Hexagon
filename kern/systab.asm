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
;;                 Copyright (c) 2015-2026 Felipe Miguel Nery Lunkes
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
;; Copyright (c) 2015-2026, Felipe Miguel Nery Lunkes
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
    dd Hexagon.Kern.Syscall.malloc                                     ;; 1
    dd Hexagon.Kern.Syscall.free                                       ;; 2
    dd Hexagon.Kern.Proc.exec                                          ;; 3
    dd Hexagon.Kern.Proc.exit                                          ;; 4
    dd Hexagon.Kern.Proc.getPID                                        ;; 5
    dd Hexagon.Kern.Proc.spawn                                         ;; 6
    dd Hexagon.Kern.Proc.kill                                          ;; 7
    dd Hexagon.Arch.Gen.Mm.memoryUse                                   ;; 8
    dd Hexagon.Kern.Proc.getProcessTable                               ;; 9
    dd Hexagon.Kern.Proc.getErrorCode                                  ;; 10
    dd Hexagon.Kern.Proc.getenv                                        ;; 11
    dd Hexagon.Kern.Proc.setenv                                        ;; 12
    dd Hexagon.Kern.Proc.unsetenv                                      ;; 13
    dd Hexagon.Kern.Proc.environ                                       ;; 14

;; File and device management

    dd Hexagon.Kern.Syscall.open                                       ;; 15
    dd Hexagon.Kernel.Dev.Dev.write                                    ;; 16
    dd Hexagon.Kernel.Dev.Dev.close                                    ;; 17

;; Filesystem and volume management

    dd Hexagon.Kernel.FS.VFS.saveFile                                  ;; 18

;; hx.touch: creates an empty file with no content, unlike hx.create (18)
;; above, which writes content in one step

    dd Hexagon.Kernel.FS.VFS.createFile                                ;; 19
    dd Hexagon.Kernel.FS.VFS.unlinkFile                                ;; 20
    dd Hexagon.Kernel.FS.VFS.renameFile                                ;; 21
    dd Hexagon.Kernel.FS.VFS.listFiles                                 ;; 22
    dd Hexagon.Kernel.FS.VFS.fileExists                                ;; 23
    dd Hexagon.Kernel.FS.VFS.getVolume                                 ;; 24
    dd Hexagon.Kernel.FS.VFS.createDirectory                           ;; 25
    dd Hexagon.Kernel.FS.VFS.removeDirectory                           ;; 26
    dd Hexagon.Kernel.FS.VFS.changeDirectory                           ;; 27

;; User management

    dd Hexagon.Kern.Proc.lock                                          ;; 28
    dd Hexagon.Kern.Proc.unlock                                        ;; 29
    dd Hexagon.Kern.Users.setUser                                      ;; 30
    dd Hexagon.Kern.Users.getUser                                      ;; 31

;; Hexagon services

    dd Hexagon.Kern.Uname.uname                                        ;; 32
    dd Hexagon.Libkern.Num.getRandomNumber                             ;; 33
    dd Hexagon.Libkern.Num.feedRandomGenerator                         ;; 34
    dd Hexagon.Kern.Sched.sleep                                        ;; 35
    dd Hexagon.Kern.Syscall.installInterruption                        ;; 36

;; Hexagon power management

    dd Hexagon.Arch.i386.APM.reboot                                    ;; 37
    dd Hexagon.Arch.i386.APM.shutdown                                  ;; 38

;; Console output functions and Hexagon graphics

    dd Hexagon.Kernel.Dev.Gen.Console.Console.print                    ;; 39
    dd Hexagon.Kernel.Dev.Gen.Console.Console.clearConsole             ;; 40
    dd Hexagon.Kernel.Dev.Gen.Console.Console.clearRow                 ;; 41
    dd Hexagon.Kernel.Dev.Gen.Console.Console.scrollConsole            ;; 42
    dd Hexagon.Kernel.Dev.Gen.Console.Console.positionCursor           ;; 43
    dd Hexagon.Libkern.Graphics.putPixel                               ;; 44
    dd Hexagon.Libkern.Graphics.drawBlockSyscall                       ;; 45
    dd Hexagon.Kernel.Dev.Gen.Console.Console.printCharacter           ;; 46
    dd Hexagon.Kernel.Dev.Gen.Console.Console.setConsoleColor          ;; 47
    dd Hexagon.Kernel.Dev.Gen.Console.Console.getConsoleColor          ;; 48
    dd Hexagon.Kernel.Dev.Gen.Console.Console.getConsoleInfo           ;; 49
    dd Hexagon.Kernel.Dev.Gen.Console.Console.updateConsole            ;; 50
    dd Hexagon.Kernel.Dev.Gen.Console.Console.setResolution            ;; 51
    dd Hexagon.Kernel.Dev.Gen.Console.Console.getResolution            ;; 52
    dd Hexagon.Kernel.Dev.Gen.Console.Console.getCursor                ;; 53

;; Hexagon keyboard input services

    dd Hexagon.Kernel.Dev.Gen.Keyboard.Keyboard.waitKeyboard           ;; 54
    dd Hexagon.Kernel.Dev.Gen.Keyboard.Keyboard.getString              ;; 55
    dd Hexagon.Kernel.Dev.Gen.Keyboard.Keyboard.getSpecialKeysStatus   ;; 56
    dd Hexagon.Kernel.Dev.Gen.Console.Console.changeFont               ;; 57
    dd Hexagon.Kernel.Dev.Gen.Keyboard.Keyboard.changeLayout           ;; 58

;; Hexagon PS/2 mouse input services

    dd Hexagon.Kernel.Dev.Gen.Mouse.Mouse.waitMouseEvent               ;; 59
    dd Hexagon.Kernel.Dev.Gen.Mouse.Mouse.getFromMouse                 ;; 60
    dd Hexagon.Kernel.Dev.Gen.Mouse.Mouse.setMouse                     ;; 61

;; Hexagon data handling services

    dd Hexagon.Libkern.String.compareWordsInString                     ;; 62
    dd Hexagon.Libkern.String.removeCharacterInString                  ;; 63
    dd Hexagon.Libkern.String.insertCharacterInString                  ;; 64
    dd Hexagon.Libkern.String.stringSize                               ;; 65
    dd Hexagon.Libkern.String.isEqual                                  ;; 66
    dd Hexagon.Libkern.String.toUppercase                              ;; 67
    dd Hexagon.Libkern.String.toLowercase                              ;; 68
    dd Hexagon.Libkern.String.trimString                               ;; 69
    dd Hexagon.Libkern.String.findCharacterInString                    ;; 70
    dd Hexagon.Libkern.String.stringToInteger                          ;; 71
    dd Hexagon.Libkern.String.integetToString                          ;; 72

;; Hexagon sound output services

    dd Hexagon.Kernel.Dev.Gen.Snd.Snd.playSound                        ;; 73
    dd Hexagon.Kernel.Dev.Gen.Snd.Snd.stopSound                        ;; 74

;; Hexagon messaging service

    dd Hexagon.Kern.Dmesg.createMessage                                ;; 75

;; Hexagon real-time clock service

    dd Hexagon.Libkern.Clock.getDate                                   ;; 76
    dd Hexagon.Libkern.Clock.getTime                                   ;; 77

