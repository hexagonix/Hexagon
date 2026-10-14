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
include "kern/hxbi.asm"                 ;; Reads the HXBI block HBoot hands off in EBX
include "kern/users.asm"                ;; Permissions and user management

;; Hexagon device management

include "arch/mm/mm.asm"                ;; Hexagon memory management
include "arch/paging/paging.asm"         ;; Identity mapped kernel space and paging control
include "dev/pci/pci.asm"               ;; PCI bus enumeration (detection/log only for now)

include "dev/sata/ahci.asm"             ;; Native SATA AHCI storage device driver

include "dev/ata/ata.asm"               ;; Native ATA/IDE storage device driver
include "dev/disk/disk.asm"             ;; Functions for reading and writing to hard drives
include "dev/cpu/cpu.asm"               ;; Registers the CPU as a device (cpu0)
include "dev/console/console.asm"       ;; Hexagon video management
include "dev/keyboard/keyboard.asm"     ;; Functions required to use the keyboard
include "arch/cpu/cpu.asm"              ;; IDT, GDT and processor management
include "kern/power.asm"                ;; Power management dispatch (reboot, shutdown)
include "arch/acpi/acpi.asm"            ;; Hexagon ACPI implementation
include "dev/snd/snd.asm"               ;; Hexagon sound management
include "dev/ps2/ps2.asm"               ;; Hexagon PS/2 port management
include "arch/timer/timer.asm"          ;; Hexagon timer manipulation
include "fs/vfs.asm"                    ;; Virtual File System (VFS) for Hexagon
include "dev/mouse/mouse.asm"           ;; Functions for Hexagon PS/2 mouse
include "dev/lpt/lpt.asm"               ;; Parallel port handling functions
include "dev/serial/serial.asm"         ;; Functions for handling serial ports in protected mode
include "arch/cmos/cmos.asm"            ;; Functions for manipulating date and time
include "dev/dev.asm"                   ;; Hardware management and abstraction functions

;; Processes, process model and executable images

include "kern/proc.asm"                 ;; Functions for handling processes
include "kern/sched.asm"                ;; Round robin scheduler and context switch
include "libkern/HAPP.asm"              ;; Functions for HAPP image processing
include "kern/init.asm"                 ;; Functions to start user mode and first process

;; Filesystems supported by Hexagon

include "fs/fat16/fat16.asm"            ;; File handling in FAT16 file system
include "fs/devfs/devfs.asm"            ;; Synthetic /dev filesystem

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

;; Hexagon Entry Point

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

;; Anchored to the malloc arena's own start instead of a flat literal, so
;; the boot stack keeps a fixed distance from Hexagon.Heap regardless of how
;; large the kernel image grows

    mov esp, Hexagon.Arch.Memory.kernelReservedMemory - 1000h

    cli

;; Boot/Saturno's resident VBR sector isn't reserved from the kernel's own
;; allocator, and Hexagon.Heap.DiskCache lands close enough to overlap and
;; zero its start during a normal mount. Copy it into a kernel-owned buffer
;; here, before any disk activity, and read the copy from now on

    mov esi, dword[Hexagon.Memory.addressBPB]
    mov edi, Hexagon.Memory.BPBCopy

    mov ecx, 512

.copyBPB:

    mov al, byte[esi]
    mov byte[edi], al

    inc esi
    inc edi

    loop .copyBPB

    mov dword[Hexagon.Memory.addressBPB], Hexagon.Memory.BPBCopy

;; Here begins the kernel self-configuration process, including the enumeration and
;; initialization of the compatible devices present.
;; Hexagon tables and control structures will also be initialized here

Hexagon.Autoconfig:

    call Hexagon.Arch.CPU.CPU.identifyProcessor ;; Identifies the installed processor

    call Hexagon.Arch.CPU.CPU.setupProcessor ;; Configures processor operation

    call Hexagon.Arch.CPU.CPU.maskATAInterrupts ;; Prevent an unmasked secondary-PIC IRQ from storming into nullHandler

    call Hexagon.Arch.Mm.initMemory ;; Starts the Hexagon memory allocator

    call Hexagon.Arch.Paging.setupKernelPaging ;; Maps the kernel's own space one to one and turns paging on

    call Hexagon.Kernel.Dev.Dev.allocateRegistry ;; Allocates the registry table

    call Hexagon.Kernel.Dev.Dev.registerDevices ;; Registers cpu0, tty0-tty7, au0 and com1

    call Hexagon.Kernel.Dev.Keyboard.Keyboard.setupKeyboard ;; Start the Hexagon keyboard service

    call Hexagon.Kernel.Dev.Mouse.Mouse.setupMouse ;; Start the Hexagon mouse service

;; kbd0/mouse0 are not registered here. Their device class has no working
;; branch in Hexagon.Kernel.Dev.Dev.open, so hx.open always fails for them

    call Hexagon.Kernel.Dev.Dev.Switch.Block.attach
    call Hexagon.Kernel.Dev.Dev.Switch.Parallel.attach
    call Hexagon.Kernel.Dev.Dev.Switch.Proc.attach

    call Hexagon.Kernel.Dev.Dev.Switch.Output.attach ;; Configures default video resolution and settings

    call Hexagon.Kern.Dmesg.startLog ;; Start Hexagon report

;;************************************************************************************

;; This is where the warning messages start when Hexagon starts up

    call Hexagon.Kernel.Dev.Serial.Serial.setupSerialPort ;; Correctly starts the serial interface

    call Hexagon.Kernel.Dev.Console.Console.clearConsole

    kprint Hexagon.Verbose.Hexagon

    logHexagon Hexagon.Verbose.version, Hexagon.Dmesg.Priorities.p5

    kprint Hexagon.Dmesg.hexagonIdentifier

    call Hexagon.Kern.Dmesg.dateToLog

    call Hexagon.Kern.Dmesg.hourToLog

    kprint Hexagon.Verbose.newLine

    kprint Hexagon.Dmesg.hexagonIdentifier

    kprint Hexagon.Verbose.totalMemory

    call Hexagon.Arch.Mm.memoryUse

    mov eax, ecx

    call Hexagon.Kernel.Dev.Console.Console.printDecimal

    kprint Hexagon.Verbose.megabytes

    call Hexagon.Arch.Mm.memoryUse

    mov eax, ebx

    call Hexagon.Kernel.Dev.Console.Console.printDecimal

    kprint Hexagon.Verbose.bytes

    kprint Hexagon.Verbose.newLine

;;************************************************************************************

    logHexagon Hexagon.Verbose.keyboard, Hexagon.Dmesg.Priorities.p5

    logHexagon Hexagon.Verbose.mouse, Hexagon.Dmesg.Priorities.p5

    logHexagon Hexagon.Verbose.pci, Hexagon.Dmesg.Priorities.p5

    call Hexagon.Dev.PCI.setupPCI ;; Scans and logs devices on the PCI bus

    logHexagon Hexagon.Verbose.acpi, Hexagon.Dmesg.Priorities.p5

    call Hexagon.Arch.ACPI.setupACPI ;; Locates the ACPI tables needed to shut down later

    call Hexagon.Arch.Timer.Timer.setupTimer ;; Initializes the Hexagon timer service

    call Hexagon.Kern.Sched.setupScheduler ;; Starts the Hexagon process scheduler

    call Hexagon.Kernel.Dev.Serial.Serial.setupCOM1 ;; Start first serial port for debugging

;;************************************************************************************

    call Hexagon.Kernel.Dev.Disk.Disk.allocateTables

    call Hexagon.Dev.SATA.AHCI.setupAHCI ;; Initialize native SATA AHCI controller and drives

    call Hexagon.Dev.ATA.setupATA ;; Initialize native ATA/IDE controller and drives

    call Hexagon.Kernel.FS.VFS.allocateMountTable

    call Hexagon.Kernel.Dev.Disk.Disk.detectDisks

    call Hexagon.Kernel.Dev.Disk.Disk.detectPartitions

    call Hexagon.Kernel.Dev.Disk.Disk.logDetectionSummary

;;************************************************************************************

    call Hexagon.Kernel.FS.VFS.setBootVolume ;; Sets volume based on boot information

;;************************************************************************************

    call Hexagon.Kernel.FS.VFS.setFilesystem ;; Defines the filesystem to be used for the volume

    call Hexagon.Kernel.FS.VFS.getVolume ;; ESI = device name ("hd0")

    mov edi, Hexagon.Heap.Temp

    push esi

    mov esi, Hexagon.Verbose.startMounting

.buildMountLinePrefix:

    mov al, byte[esi]

    cmp al, 0
    je .buildMountLinePrefixDone

    mov byte[edi], al

    inc esi
    inc edi

    jmp .buildMountLinePrefix

.buildMountLinePrefixDone:

    pop esi

.buildMountLineDevice:

    mov al, byte[esi]

    cmp al, 0
    je .buildMountLineDeviceDone

    mov byte[edi], al

    inc esi
    inc edi

    jmp .buildMountLineDevice

.buildMountLineDeviceDone:

    mov byte[edi], 'p'
    inc edi
    mov byte[edi], '0'
    inc edi

    mov esi, Hexagon.Verbose.mountPointDefined

.buildMountLineSuffix:

    mov al, byte[esi]

    mov byte[edi], al

    cmp al, 0
    je .buildMountLineDone

    inc esi
    inc edi

    jmp .buildMountLineSuffix

.buildMountLineDone:

    logHexagon Hexagon.Heap.Temp, Hexagon.Dmesg.Priorities.p5

;;************************************************************************************

;; Hexagon.Kernel.FS.VFS.setFilesystem and .initFilesystem above already
;; fully establish the root volume by talking to the boot disk directly,
;; the same way a real root mount never goes through a generic device-open
;; dispatch. Nothing past this point opens the boot disk again

    call Hexagon.Kernel.FS.VFS.initFilesystem ;; Initializes the volume's filesystem structures

;;************************************************************************************

    mov esi, "/"

    call Hexagon.Kernel.FS.Dir.setMountPoint

    call Hexagon.Kernel.FS.VFS.registerBootMount ;; Registers "/" as mount slot 0

;;************************************************************************************

    call Hexagon.Kern.Services.installInterruptions ;; Install Hexagon interrupt handlers

;; Firstly, the user must be prevented from killing processes with a special key,
;; preventing any relevant process from being terminated prematurely

;; Prevents the user from killing processes with a special key

    call Hexagon.Kern.Proc.lock

;;************************************************************************************

Hexagon.userMode:

;; Now, we must go to user mode, running the first process, init.
;; If init is not present on the volume, try running the default shell

    call Hexagon.Kern.Init.startUserMode

;;************************************************************************************

;; Word-aligned so every Hexagon.Heap.* region starts on an even physical
;; address, since AHCI's PRDT requires bit 0 of a DMA buffer's address to
;; be 0.

align 2

Hexagon.Heap: ;; Kernel heap

Hexagon.Heap.DiskGeometry  = Hexagon.Heap + 0 ;; Disk geometry
Hexagon.Heap.DiskCache     = Hexagon.Heap.DiskGeometry + 512 ;; Disk cache
Hexagon.Heap.ProcessTable  = Hexagon.Heap.DiskCache + Hexagon.Disk.DiskCache.maxSize
Hexagon.Heap.Temp          = Hexagon.Heap.ProcessTable + Hexagon.Processes.Table.byteSize ;; Temporary kernel data

;; Budget for Hexagon.Heap.Temp's own scratch uses (HAPP header checks, font
;; loading), covering the largest offsets any of them add to it today, with
;; headroom for new ones added later

Hexagon.Heap.TempSize = 8192

;; AHCI and native ATA structures, reserved here and not as inline buffers
;; in their own driver files, so an overlap shows up against Hexagon.Heap.End
;; like any other region. CLB, FB and CTBA are read by the controller itself,
;; so their alignment is a requirement on the address these constants carry

Hexagon.Heap.AHCI.CommandList     = (Hexagon.Heap.Temp + Hexagon.Heap.TempSize + 1023) and (not 1023)
Hexagon.Heap.AHCI.CommandListSize = 1024 ;; 1024-byte aligned, per AHCI spec

Hexagon.Heap.AHCI.ReceivedFIS     = Hexagon.Heap.AHCI.CommandList + Hexagon.Heap.AHCI.CommandListSize
Hexagon.Heap.AHCI.ReceivedFISSize = 256 ;; 256-byte aligned; CommandList is 1024-aligned and exactly 1024 bytes long

Hexagon.Heap.AHCI.CommandTable     = Hexagon.Heap.AHCI.ReceivedFIS + Hexagon.Heap.AHCI.ReceivedFISSize
Hexagon.Heap.AHCI.CommandTableSize = 256 ;; 128-byte aligned, as the offset from CommandList (1280) is a multiple of 128

Hexagon.Heap.ATA.IdentifyBuffer     = Hexagon.Heap.AHCI.CommandTable + Hexagon.Heap.AHCI.CommandTableSize
Hexagon.Heap.ATA.IdentifyBufferSize = 512 ;; PIO, no DMA alignment requirement

;; The kernel's own page directory. CR3 only accepts a 4 KB aligned address,
;; so this is rounded up instead of following the region above directly

Hexagon.Heap.PageDirectory     = (Hexagon.Heap.ATA.IdentifyBuffer + Hexagon.Heap.ATA.IdentifyBufferSize + 4095) and (not 4095)
Hexagon.Heap.PageDirectorySize = 4096

Hexagon.Heap.End = Hexagon.Heap.PageDirectory + Hexagon.Heap.PageDirectorySize

if Hexagon.Heap.End >= Hexagon.Arch.Memory.kernelReservedMemory - 1000h
    err
end if

