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

;; Hexagon Kernel
;;
;; From now on, the operating environment is protected mode
;;
;; Kernel executive component

use32

align 4

;; Here we will include macros to facilitate the organization and modification of the code

include "libkern/macros.s"                 ;; Macros

;;************************************************************************************
;;
;; Files with Hexagon components
;;
;;************************************************************************************

;; Hexagon version

include "kern/version.asm"              ;; Contains Hexagon version information

;; Hexagon services

include "kern/uname.asm"                ;; Hexagon version
include "kern/syscall.asm"              ;; Hexagon interrupt handler
include "kern/systab.asm"               ;; Table with system calls
include "libkern/graphics.asm"          ;; Functions for Hexagon graphics resources
include "kern/services.asm"             ;; Interrupt routines and IRQ handlers

;; Users and other utilities

include "kern/dmesg.asm"                ;; Functions for handling kernel messages
include "kern/panic.asm"                ;; Functions for displaying and identifying Hexagon errors
include "kern/users.asm"                ;; Permissions and user management

;; Hexagon device management

include "arch/gen/mm.asm"               ;; Hexagon memory management
include "arch/i386/mm/mm.asm"           ;; Architecture-dependent memory management
include "dev/i386/disk/disk.asm"        ;; Functions for reading and writing to hard drives
include "dev/gen/console/console.asm"   ;; Hexagon video management
include "dev/gen/keyboard/keyboard.asm" ;; Functions required to use the keyboard
include "arch/i386/cpu/cpu.asm"         ;; IDT, GDT and processor management
include "arch/i386/BIOS/BIOS.asm"       ;; BIOS interrupts in real mode
include "arch/i386/APM/apm.asm"         ;; Hexagon APM implementation
include "dev/gen/snd/snd.asm"           ;; Hexagon sound management
include "dev/gen/PS2/PS2.asm"           ;; Hexagon PS/2 port management
include "arch/i386/timer/timer.asm"     ;; Hexagon timer manipulation
include "fs/vfs.asm"                    ;; Virtual File System (VFS) for Hexagon
include "dev/gen/mouse/mouse.asm"       ;; Functions for Hexagon PS/2 mouse
include "dev/gen/lpt/lpt.asm"           ;; Parallel port handling functions
include "dev/gen/COM/serial.asm"        ;; Functions for handling serial ports in protected mode
include "arch/i386/CMOS/cmos.asm"       ;; Functions for manipulating date and time
include "dev/dev.asm"                   ;; Hardware management and abstraction functions

;; Processes, process model and executable images

include "kern/proc.asm"                 ;; Functions for handling processes
include "libkern/HAPP.asm"              ;; Functions for HAPP image processing
include "kern/init.asm"                 ;; Function to start user mode

;; Filesystems supported by Hexagon

include "fs/FAT16/fat16.asm"            ;; File handling in FAT16 file system

;; Hexagon kernel libraries

include "libkern/string.asm"            ;; Functions for character manipulation
include "libkern/num.asm"               ;; Random number generation and feeding functions
include "libkern/clock.asm"             ;; Real-time clock interface

;; Here we have a stub that prevents the Hexagon image from running directly by the user,
;; which could cause problems given the nature of the image (being a kernel, not a common process)

include "libkern/stubHAPP.asm"          ;; Stub to prevent accidental execution of the Hexagon image

;; System default font

include "libkern/font.asm"              ;; Fonts and text services for Hexagon graphics mode

;; Hexagon messages for verbose, if verbose support is desired. If not, the file will be blank

include "kern/verbose.asm"              ;; Contains the Hexagon-exclusive verbose messages

;; Here we have the variables, constants and functions to interpret parameters passed by HBoot

include "kern/parameters.asm"           ;; Parameter analysis and processing code

;;************************************************************************************

;; Hexagon Entry Point - Kernel Boot

;; Here the initial configuration of the kernel environment will be carried out

Hexagon.init:

;; First the segment and stack registers will be configured

    mov ax, 10h
    mov ds, ax
    mov ax, 18h ;; ES with base at 0
    mov ss, ax
    mov fs, ax
    mov gs, ax
    mov es, ax
    mov esp, 10000h ;; Set stack pointer

    cli

;; Here begins the kernel self-configuration process, including the enumeration and
;; initialization of the compatible devices present.
;; Hexagon tables and control structures will also be initialized here

Hexagon.Autoconfig:

    call Hexagon.Arch.i386.CPU.CPU.identifyProcessor ;; Identifies the installed processor

    call Hexagon.Arch.i386.CPU.CPU.setupProcessor ;; Configures processor operation

    call Hexagon.Arch.Gen.Mm.initMemory ;; Starts the Hexagon memory allocator

    call Hexagon.Kernel.Dev.Gen.Keyboard.Keyboard.setupKeyboard ;; Start the Hexagon keyboard service

    call Hexagon.Kernel.Dev.Gen.Mouse.Mouse.setupMouse ;; Start the Hexagon mouse service

    call Hexagon.Kernel.Dev.Gen.Console.Console.setupConsole ;; Configures default video resolution and settings

    call Hexagon.Kern.Dmesg.startLog ;; Start Hexagon component report

;;************************************************************************************

;; This is where the warning messages start when Hexagon starts up

    call Hexagon.Kernel.Dev.Gen.COM.Serial.setupSerialPort ;; Correctly start the serial interface

    call Hexagon.Kernel.Dev.Gen.Console.Console.clearConsole

    kprint Hexagon.Verbose.Hexagon

    logHexagon Hexagon.Verbose.version, Hexagon.Dmesg.Priorities.p5

    kprint Hexagon.Dmesg.hexagonIdentifier

    call Hexagon.Kern.Dmesg.dateToLog

    call Hexagon.Kern.Dmesg.hourToLog

    kprint Hexagon.Verbose.newLine

    kprint Hexagon.Dmesg.hexagonIdentifier

    kprint Hexagon.Verbose.totalMemory

    call Hexagon.Arch.Gen.Mm.memoryUse

    mov eax, ecx

    call Hexagon.Kernel.Dev.Gen.Console.Console.printDecimal

    kprint Hexagon.Verbose.megabytes

    call Hexagon.Arch.Gen.Mm.memoryUse

    mov eax, ebx

    call Hexagon.Kernel.Dev.Gen.Console.Console.printDecimal

    kprint Hexagon.Verbose.bytes

    kprint Hexagon.Verbose.newLine

;;************************************************************************************

    logHexagon Hexagon.Verbose.keyboard, Hexagon.Dmesg.Priorities.p5

    logHexagon Hexagon.Verbose.mouse, Hexagon.Dmesg.Priorities.p5

    call Hexagon.Arch.i386.Timer.Timer.setupTimer ;; Initializes the Hexagon timer service

    call Hexagon.Kern.Proc.setupScheduler ;; Starts the Hexagon process scheduler

    call Hexagon.Kernel.Dev.Gen.COM.Serial.setupCOM1 ;; Start first serial port for debugging

    call Hexagon.Kernel.FS.VFS.setBootVolume ;; Sets volume based on boot information

;;************************************************************************************

    call Hexagon.Kernel.FS.VFS.setFilesystem ;; Defines the filesystem to be used for the volume

    kprint Hexagon.Dmesg.hexagonIdentifier

    kprint Hexagon.Verbose.startMounting

    call Hexagon.Kernel.FS.VFS.getVolume ;; Get the volume identifier

    call Hexagon.Kernel.Dev.Gen.Console.Console.printString ;; Display

    kprint Hexagon.Verbose.mountPointDefined

    kprint Hexagon.Verbose.newLine

;;************************************************************************************

    call Hexagon.Kernel.FS.VFS.initFilesystem ;; Initializes the volume's filesystem structures

    kprint Hexagon.Dmesg.hexagonIdentifier

    kprint Hexagon.Verbose.filesystem

    call Hexagon.Kernel.FS.VFS.getVolume

    push esi
    push edi

    mov al, ah
    xor ah, ah

    call Hexagon.Kernel.Dev.Gen.Console.Console.printHexadecimal

    mov al, 10

    call Hexagon.Kernel.Dev.Gen.Console.Console.printCharacter

    kprint Hexagon.Dmesg.hexagonIdentifier

    kprint Hexagon.Verbose.volumeLabel

    pop edi
    pop esi

    mov esi, edi

    call Hexagon.Kernel.Dev.Gen.Console.Console.printString

    mov al, 10

    call Hexagon.Kernel.Dev.Gen.Console.Console.printCharacter

;;************************************************************************************

    mov esi, "/"

    call Hexagon.Kernel.FS.Dir.setMountPoint

    call Hexagon.Kernel.FS.VFS.mountVolume ;; Mounts the default volume used for booting

    logHexagon Hexagon.Verbose.mountSuccess, Hexagon.Dmesg.Priorities.p5

;;************************************************************************************

    call Hexagon.Kern.Services.installInterruptions ;; Installs Hexagon interrupt handlers

;; Firstly, the user must be prevented from killing processes with a special key,
;; preventing any relevant process, such as login, from being terminated prematurely

;; Prevents the user from killing processes with a special key

    call Hexagon.Kern.Proc.lock

    logHexagon Hexagon.Verbose.locking, Hexagon.Dmesg.Priorities.p5

;;************************************************************************************

Hexagon.userMode:

;; Now, we must go to user mode, running the first process, init.
;; If init is not present on the volume, try running the default shell

    call Hexagon.Kern.Init.startUserMode

;;************************************************************************************

Hexagon.Heap: ;; Kernel heap

Hexagon.Heap.DiskGeometry = Hexagon.Heap              + 0           ;; Disk geometry
Hexagon.Heap.VBE          = Hexagon.Heap.DiskGeometry + 512         ;; Video control block
Hexagon.Heap.DiskCache    = Hexagon.Heap.VBE          + 90000       ;; Disk cache
Hexagon.Heap.PCBs         = Hexagon.Heap.DiskCache    + 200000      ;; Process control block
Hexagon.Heap.ProcTab      = Hexagon.Heap.PCBs         + 5000        ;; Process table
Hexagon.Heap.ArgProc      = Hexagon.Heap.ProcTab      + 5000 + 500h ;; Arguments of a process
Hexagon.Heap.Temp         = Hexagon.Heap.ArgProc      + 2000        ;; Temporary kernel data

