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

;;************************************************************************************
;;
;;                Controle e execução de processos do kernel Hexagon
;;
;; Aqui existem rotinas para a alocação de memória para um novo processo, o
;; carregamento de uma imagem executável válida, sua interpretação, sua execução
;; e término.
;;
;;************************************************************************************

;;************************************************************************************
;;
;;               Hexagon process manager return (error) codes
;;
;;                      Standardized return interface
;;
;;************************************************************************************

;;|=================================================================================|
;;| Code | Error name                     | Error reason                            |
;;|=================================================================================|
;;| 00h  | No errors in the process       | No invalid parameters                   |
;;| 01h  | Image not found on disk        |                    -                    |
;;| 02h  | Error loading image            |                    -                    |
;;| 03h  | Process limit reached          |                    -                    |
;;| 04h  | Invalid image - non-HAPP image |                    -                    |
;;|=================================================================================|

;;************************************************************************************
;;
;; Attention! This module makes calls to Hexagon memory management functions
;;
;;************************************************************************************

;;************************************************************************************
;;
;; Hexagon process management
;;
;;************************************************************************************

use32

;;************************************************************************************

struc Hexagon.Processes.Tasks
{

.emptyProcess: ;; Contents of an empty process
times 13 db ' '

}

;;************************************************************************************

Hexagon.Processes Hexagon.Processes.Tasks

;;************************************************************************************
;;
;;                    Hexagon Process Control Block (H-PCB)
;;
;;************************************************************************************

virtual at Hexagon.Heap.PCBs ;; This object is located at the defined position

Hexagon.Processes.PCB.esp: ;; Process Control Block
times Hexagon.Processes.PCB.processLimit dd 0
.pointer: dd 0 ;; Pointer to the process stack


Hexagon.Processes.PCB.size:  ;; Memory mapping block
times Hexagon.Processes.PCB.processLimit dd 0
.pointer: dd 0 ;; Pointer to the process's memory address

Hexagon.Processes.PCB:
.errorCode:         dd 0 ;; Error code issued by the last process
.processBaseMemory: dd 0 ;; Process loading base address, provided by the allocator
.endMode:           db 0 ;; Mark whether the process should remain resident or not
.processLocked:     dd 0 ;; Marks whether the process can be terminated by a key or combination
.processLimit        = 31 ;; Limit number of loaded processes (n-1)
.processCount:      dd 0 ;; Number of processes currently on the execution stack
.PID:               dd 0 ;; PID
.lastProcessSize:   dd 0 ;; Size of last process
.returnCode:        db 0 ;; Records error codes in process operations
.currentPID:        dd 0 ;; Current PID
.counter:           db 0 ;; Process counter
.resident:          db 0 ;; Whether the process will be resident (future)
.incompatibleImage: db 0 ;; Mark if an image is incompatible
.entryHAPP:         dd 0 ;; HAPP image entry point
.imageType:         db 0 ;; Image executable type
.imageSize: ;; Size of the current program on the execution stack
times Hexagon.Processes.PCB.processLimit -1  dd 0
.processName: ;; Stores the process name
times 11 db 0

end virtual

;;************************************************************************************

;; Unlock the process stack, allowing the user to terminate the process

Hexagon.Kern.Proc.unlock:

    mov word[Hexagon.Processes.PCB.processLocked], 0h

    ret

;;************************************************************************************

;; Lock the foreground process, preventing it from exiting the execution stack

Hexagon.Kern.Proc.lock:

    mov word[Hexagon.Processes.PCB.processLocked], 01h

    ret

;;************************************************************************************

Hexagon.Kern.Proc.setupScheduler:

    logHexagon Hexagon.Verbose.heapKernel, Hexagon.Dmesg.Priorities.p5

    push es

;; Let's start the kernel heap memory area that will store the name of running processes,
;; applying the formatting expected by the functions that manage these fields

    push ds
    pop es

    mov edx, 13*Hexagon.Processes.PCB.processLimit
    mov ebx, 0

.loop:

    mov esi, .space
    mov edi, Hexagon.Heap.ProcTab
    add edi, ebx
    mov ecx, 1

    rep movsb

    dec edx
    inc ebx

    cmp edx, 0
    jne .loop

    pop es

    mov esi, Hexagon.Heap.ProcTab

    mov ebx, 13*Hexagon.Processes.PCB.processLimit

    mov byte[esi+ebx], 0

;; Okay, everything done for the process name storage area, let's continue

    mov dword[Hexagon.Processes.PCB.currentPID], 0

    mov dword[Hexagon.Processes.PCB.PID], 0

    mov dword[Hexagon.Processes.PCB.processCount], 0

    logHexagon Hexagon.Verbose.scheduler, Hexagon.Dmesg.Priorities.p5

;; Now a function to start PCBs
;; This function can be performed, but the use of the new PCBs is still under development

    ;; call Hexagon.Kern.Proc.setupPCB

    ret

.space: db ' '

;;************************************************************************************

;; Now the memory space allocated to the processes will be saved in
;; the Hexagon process scheduler control structure

Hexagon.Kern.Proc.configureProcessAllocation:

    mov dword[Hexagon.Processes.PCB.processBaseMemory], ebx

    ret

;;************************************************************************************

;; Allows you to terminate a process currently running by the system, if such
;; termination is possible

Hexagon.Kern.Proc.kill:

;; End current running process

;; First, you must check whether the function of ending a process in the foreground using
;; a key combination or the special "Kill process" key is enabled by the system.
;; This is a security measure that aims to prevent the closure of vital processes, such as the
;; login manager, for example.

;; If the function is disabled, the occurrence will be ignored

    cmp dword[Hexagon.Processes.PCB.processLocked], 1
    je .end

    cmp byte[Hexagon.Processes.PCB.processCount], 0 ;; There is no process to be closed
    je .end

match =YES, VERBOSE
{

    mov esi, Hexagon.Verbose.Services.killProcess
    mov ebx, Hexagon.Dmesg.Priorities.p5

    call Hexagon.Kern.Dmesg.createMessage

}

    push ds
    pop es

    pop eax

    mov ax, 18h
    mov es, ax

    mov eax, dword[Hexagon.Console.fontColor]
    mov ebx, dword[Hexagon.Console.backgroundColor]

;; Set default console color

    call Hexagon.Kernel.Dev.Gen.Console.Console.setConsoleColor

;; Update video buffer (secondary console -> main console)
;; This update is not mandatory, it is only useful for utilities that use double buffering

    ;; call Hexagon.Kernel.Dev.Gen.Console.Console.updateConsole

;; Use main console

    call Hexagon.Kernel.Dev.Gen.Console.Console.useMainConsole

;; Scroll console

    call Hexagon.Kernel.Dev.Gen.Console.Console.scrollConsole

    mov al, 20h

    out 20h, al

    call Hexagon.Kern.Proc.exit

    ret

.end:

    ret

;;************************************************************************************

;; Configures a new Hexagon process to run immediately
;;
;; Input:
;;
;; ESI - Buffer containing the name of the file to be executed
;; EDI - Program arguments (if they exist)
;; EAX - 0 if no argument exists
;;
;; Output:
;;
;; CF - Set in case of error or file not found
;;      Cleared on success

Hexagon.Kern.Proc.exec:

    pusha

;; Now the limit of loaded processes will be checked.
;; If there are already many processes in memory, another one will be prevented from loading

.checkLimit:

    push eax

    mov eax, [Hexagon.Processes.PCB.processCount]

;; If the number of loaded processes is less than the limit, proceed with the loading.
;; Otherwise, prevent loading by returning an error

    cmp eax, Hexagon.Processes.PCB.processLimit - 1 ;; Limit number of loaded processes
    jl .limitAvailable

    pop eax

    jmp Hexagon.Kern.Proc.maxNumberProcessesReached

.limitAvailable:

;; Check if there are arguments for the process to be loaded

    pop eax

    cmp eax, 0
    je .noArguments

    push esi

    push es

    mov esi, edi

    call Hexagon.Libkern.String.stringSize

    mov ecx, eax

    inc ecx

    push 18h ;; Kernel linear segment
    pop es

;; Copy arguments to a known address

    mov esi, edi

    mov edi, Hexagon.Heap.ArgProc

    rep movsb ;; Copy (ECX) characters from ESI to EDI

    pop es

    pop esi

    jmp .checkImage

.noArguments:

    mov byte[gs:Hexagon.Heap.ArgProc], 0

.checkImage:

    push esi

    call Hexagon.Kernel.FS.VFS.fileExists

    pop esi

    push eax

    jc .missingImage

    call Hexagon.Libkern.HAPP.checkHAPPImage

    cmp byte[Hexagon.Libkern.HAPP.imageHAPPHeader.incompatibleImage], 01h
    je .incompatibleImage

    cmp byte[Hexagon.Libkern.HAPP.imageHAPPHeader.incompatibleImage], 02h
    je .missingImage

    jmp Hexagon.Kern.Proc.addProcess

.missingImage:

    pop eax

;; The image containing the executable code was not found on disk

    stc ;; Inform the process that called the function of the absence of the image

    popa ;; Restore the stack

    mov byte[Hexagon.Processes.PCB.returnCode], 01h

    mov eax, 01h ;; Send error code

    ret

.incompatibleImage:

    pop eax

;; A imagem que contêm o código executável não apresenta um formato compatível

    stc ;; Inform the process that called the function of the absence of the image

    popa ;; Restore the stack

    mov byte[Hexagon.Processes.PCB.returnCode], 04h

    mov eax, 04h ;; Send error code

    ret

;;************************************************************************************

;; Loads an executable from disk and runs it immediately
;;
;; Arguments must be passed through the stack
;;
;; Input:
;;
;; EAX - Size of the image containing the executable code

Hexagon.Kern.Proc.addProcess:

;; Data passed through the stack will be restored

    pop eax

    push eax

    mov ebx, dword[Hexagon.Processes.PCB.PID]
    inc ebx
    mov dword[Hexagon.Processes.PCB.imageSize+ebx*4], eax

    call Hexagon.Arch.Gen.Mm.confirmMemoryUsage

    pop ebx

    add ebx, [Hexagon.Processes.PCB.lastProcessSize]

    mov eax, [Hexagon.Processes.PCB.size.pointer]

    add eax, Hexagon.Processes.PCB.size

    mov dword[eax], ebx

    mov dword[Hexagon.Processes.PCB.lastProcessSize], ebx

    add dword[Hexagon.Processes.PCB.size.pointer], 4

    add dword[Hexagon.Processes.PCB.processBaseMemory], ebx

    mov edi, dword[Hexagon.Processes.PCB.processBaseMemory]

;; Correct address with segment base (physical address = address + segment base)

    sub edi, 500h

    push esi

    call Hexagon.Kernel.FS.VFS.openFile

    pop esi

    jc .loadImageError

    mov byte[Hexagon.Processes.PCB.returnCode], 00h ;; Remove the error flag

    call Hexagon.Kern.Proc.linkProcessStack

    jmp Hexagon.Kern.Proc.executeProcess

.loadImageError:

;; An error occurred while loading the image present on volume

    stc ;; Inform the process that called the function of the occurrence of an error

    popa ;; Restore the stack

    mov byte[Hexagon.Processes.PCB.returnCode], 02h

    mov eax, 02h ;; Send error code

    ret

;;************************************************************************************

;; After the image has been loaded to the appropriate address, and the process has been
;; configured for its stack and execution information, the process will run.
;; To do so, it must be registered with the GDT and have its execution configured

Hexagon.Kern.Proc.executeProcess:

;; Now we must calculate the program's code and data base addresses,
;; placing them in the program's GDT entry

    mov eax, dword[Hexagon.Processes.PCB.processBaseMemory]
    mov edx, eax
    and eax, 0xFFFF

    mov word[GDT.userCode+2], ax ;; Base
    mov word[GDT.userData+2], ax ;; Base

    mov eax, edx
    shr eax, 16
    and eax, 0xFF

    mov byte[GDT.userCode+4], al ;; Base
    mov byte[GDT.userData+4], al ;; Base

    mov eax, edx
    shr eax, 24
    and eax, 0xFF

    mov byte[GDT.userCode+7], al ;; Base
    mov byte[GDT.userData+7], al ;; Base

    lgdt[GDTReg] ;; Load the GDT containing the process entry

    mov eax, [Hexagon.Processes.PCB.esp.pointer]

    add eax, Hexagon.Processes.PCB.esp

    mov dword[eax], esp

    add dword[Hexagon.Processes.PCB.esp.pointer], 4

    call Hexagon.Kern.Proc.calculateArgumentsAddress

    sti ;; Make sure interrupts are available

    pushfd   ;; Flags
    push 30h ;; User environment code segment (process)
    push dword [Hexagon.Libkern.HAPP.imageHAPPHeader.entryHAPP] ;; Image entry point

    inc dword[Hexagon.Processes.PCB.processCount]
    inc dword[Hexagon.Processes.PCB.PID]

    mov ax, 38h ;; User environment data segment (process)
    mov ds, ax

    iret

;;************************************************************************************

;; Function that receives control after the process ends and performs the necessary
;; operations to remove it from the execution stack

Hexagon.Kern.Proc.exit:

;; First, store the error code of the process to be terminated

    mov [Hexagon.Processes.PCB.errorCode], eax

    mov ax, 10h
    mov ds, ax

    cmp byte[Hexagon.Console.graphicMode], 0
    je .noGraphicMode

.noGraphicMode:

    cmp ebx, 00h
    je .continue

    cmp ebx, 1234h
    je .terminateAndStayResident

.terminateAndStayResident:

    mov byte[Hexagon.Processes.PCB.endMode], 01h

.continue:

    mov eax, [Hexagon.Processes.PCB.esp.pointer]

    add eax, Hexagon.Processes.PCB.esp
    sub eax, 4

    mov esp, dword[eax]

;; Address of the function that will remove permissions from the process

    mov eax, Hexagon.Kern.Proc.removeProcess

    push 08h ;; Kernel code segment
    push eax ;; retf return address

    retf ;; Go to this function now, switching the context

;;************************************************************************************

;; Removes the process's credentials and permissions from the system execution
;; stack and GDT, transferring control back to the kernel

Hexagon.Kern.Proc.removeProcess:

    call Hexagon.Kern.Proc.unlinkProcessStack

    mov ax, 10h ;; Kernel data segment
    mov ds, ax

    mov eax, [Hexagon.Processes.PCB.size.pointer]

    add eax, Hexagon.Processes.PCB.size

    sub eax, 4

    mov ebx, dword[eax]

    sub dword[Hexagon.Processes.PCB.processBaseMemory], ebx

    sub dword[Hexagon.Processes.PCB.size.pointer], 4

    mov eax, dword[Hexagon.Memory.bytesAllocated]

    sub dword[Hexagon.Processes.PCB.processBaseMemory], eax

    mov dword[Hexagon.Memory.bytesAllocated], 0

;; Now we must calculate the program's code and data base addresses,
;; placing them in the program's GDT entry

    mov eax, dword[Hexagon.Processes.PCB.processBaseMemory]
    mov edx, eax
    and eax, 0xFFFF

    mov word[GDT.userCode+2], ax
    mov word[GDT.userData+2], ax

    mov eax, edx
    shr eax, 16
    and eax, 0xFF

    mov byte[GDT.userCode+4], al
    mov byte[GDT.userData+4], al

    mov eax, edx
    shr eax, 24
    and eax, 0xFF

    mov byte[GDT.userCode+7], al
    mov byte[GDT.userData+7], al

    lgdt[GDTReg]

    sub dword[Hexagon.Processes.PCB.esp.pointer], 4

    push eax
    push ebx

    mov ebx, dword[Hexagon.Processes.PCB.PID]
    mov eax, dword[Hexagon.Processes.PCB.imageSize+ebx*4]
    mov dword[Hexagon.Processes.PCB.imageSize+ebx*4], 00h

    call Hexagon.Arch.Gen.Mm.freeMemoryUsage

    pop ebx
    pop eax

    dec dword[Hexagon.Processes.PCB.processCount]
    dec dword[Hexagon.Processes.PCB.PID]

    cmp byte[Hexagon.Processes.PCB.endMode], 01h
    je .starResident

    clc

    jmp short .end

.starResident:

    mov ebx, dword[Hexagon.Processes.PCB.PID]

    mov eax, [Hexagon.Processes.PCB.processBaseMemory]
    add eax, [Hexagon.Processes.PCB.imageSize+ebx*4]

    mov byte[Hexagon.Processes.PCB.endMode], 00h

    clc

    jmp short .end

.end:

    clc

    popa

.checkReturn:

    clc

    mov ah, [Hexagon.Processes.PCB.returnCode]

    cmp ah, 00h
    je .finish

    stc

.finish:

    mov eax, [Hexagon.Processes.PCB.returnCode]

    ret

;;************************************************************************************

;; Handler that returns error code for when the process limit is reached

Hexagon.Kern.Proc.maxNumberProcessesReached:

;; An error occurred while loading the image present on volume

    stc ;; Inform the process that called the function of the occurrence of an error

    popa ;; Restore the stack

    mov byte[Hexagon.Processes.PCB.returnCode], 03h

    mov eax, 03h ;; Send error code

    ret

;;************************************************************************************

;; Returns its PID to the process
;;
;; Output:
;;
;; EAX - Process PID

Hexagon.Kern.Proc.getPID:

    mov eax, dword[Hexagon.Processes.PCB.PID]

    ret

;;************************************************************************************

Hexagon.Kern.Proc.linkProcessStack:

    mov dword[Hexagon.Processes.PCB.processName], esi

    push ds ;; Kernel data segment
    pop es

    mov eax, dword[Hexagon.Processes.PCB.processCount]

    mov ebx, 14

    mul ebx ;; EAX contain the offset

    inc ebx

    mov edi, Hexagon.Heap.ProcTab

    add edi, eax

    push edi

    mov esi, [Hexagon.Processes.PCB.processName]

    call Hexagon.Libkern.String.stringSize

    mov ecx, eax

;; Copy process name

    mov esi, dword[Hexagon.Processes.PCB.processName]

    pop edi

    rep movsb ;; Copy (ECX) characters from ESI to EDI

    mov byte[edi+1], ' '

    ret

;;************************************************************************************

;; Calculates the effective address of the memory block containing the process arguments.
;; This block is always mapped to a kernel temporary dump region for process arguments.
;; This address is directly relative to the location of the current process in memory
;;
;; Input:
;;
;; Anything
;;
;; Output:
;;
;; EDI - relative address (offset) in memory of the memory block with the process arguments

Hexagon.Kern.Proc.calculateArgumentsAddress:

;; Address resolution documentation for the parameters that will be passed to the new process:
;;
;; First, we get the structure offset within the kernel address.
;; This value should be close to the size in bytes of the file containing the kernel.
;; This value is relative to the kernel, not the memory segment.
;; To obtain the effective address, we take the offset in relation to the kernel and subtract it
;; from the base address of the process, generating an offset in relation to the memory segment.
;; In this case, we have a negative address, as the kernel is in a lower memory region than the
;; process region.
;; When resolving addresses, a two's complement is made with the negative value (a possible and
;; probable value of −2C9C6E is represented as 6392h or 25490), being used as an offset in the
;; ES segment, forming the logical address ES:25490, which would point correctly to the structure
;; in the kernel that contains the process arguments.
;; This way, the process with the offset at EDI = -2C9C6E can correctly point to the expected
;; area in the kernel.
;;
;; More information about the process (effective address calculation - offset):
;;
;; The architecture treats addresses with symmetry at 0, and normally kernel addresses (with a
;; smaller offset in relation to the beginning of memory) appear as negative addresses for the
;; user environment, as observed in this case.
;; The architecture supports negative offsets relative to the segment (via two's complement),
;; performing transparent translation to a physical address.
;; In the case below, we will have a negative offset pointing to a previous region of memory
;; that will be translated into a logical address that will, in turn, be translated into a physical
;; address by the processor using the table present in the GDT

    mov edi, Hexagon.Heap.ArgProc ;; Offset, inside the kernel

    sub edi, dword[Hexagon.Processes.PCB.processBaseMemory] ;; Get effective address (offset)

    ret

;;************************************************************************************

Hexagon.Kern.Proc.unlinkProcessStack:

    push ds ;; Kernel data segment
    pop es

    mov eax, dword[Hexagon.Processes.PCB.processCount]

    dec eax

    mov ebx, 14

    mul ebx ;; EAX contain the offset

    inc ebx

    mov edi, Hexagon.Heap.ProcTab

    add edi, eax

    push edi

    mov esi, Hexagon.Processes.emptyProcess

    mov eax, 13

    mov ecx, eax

;; Copy process name

    mov esi, Hexagon.Processes.emptyProcess

    pop edi

    rep movsb ;; Copy (ECX) characters from ESI to EDI

    mov byte[edi+1], ' '

    ret

;;************************************************************************************

Hexagon.Kern.Proc.getProcessTable:

;; Let's get the running processes

    push ds ;; Kernel data segment
    pop es

.loop:

    mov esi, Hexagon.Heap.ProcTab
    mov edi, Hexagon.Heap.Temp
    mov ecx, 13*Hexagon.Processes.PCB.processLimit

    rep movsb

    mov esi, Hexagon.Heap.Temp

    mov ebx, 13*Hexagon.Processes.PCB.processLimit

    mov byte[esi+ebx], 0

    mov esi, Hexagon.Heap.Temp

    call Hexagon.Libkern.String.trimString

    mov eax, dword[Hexagon.Processes.PCB.processCount]

.end:

    ret

;;************************************************************************************

Hexagon.Kern.Proc.getErrorCode:

    mov eax, [Hexagon.Processes.PCB.errorCode]

    ret
