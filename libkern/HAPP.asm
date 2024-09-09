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

;;************************************************************************************

;; This Hexagon module is responsible for loading, obtaining information from the loaded file,
;; and determining whether the format matches the HAPP specification.
;; If so, you must extract information from the image header necessary to configure the execution
;; environment and start the process from the entry point.
;; The functions below are only responsible for evaluating the image, while the manipulation and
;; execution of the process are the responsibility of the process manager and scheduler.
;; Hexagon version dependencies are also checked here.
;; This file also has the HAPP image manipulation structure that are used in other areas
;; of the kernel.

;;************************************************************************************

;; HAPP Image Documentation for Hexagon
;;
;; A HAPP format file contains an executable binary image designed to be loaded and run on
;; Hexagon.
;; This image must have a header, which declares a series of information that will be used
;; by the kernel for loading, dependency resolution and correct execution.
;;
;; According to the HAPP2 (HAPP 2.0) specification, the header fields are:
;;
;; Number |           Parameter           | Parameter size | Content (fixed or variable)
;; -------|-------------------------------|----------------|----------------------------
;; #1     | HAPP signature                | 4 bytes        | "HAPP"
;; #2     | Image target architecture     | 1 byte         | i386 = 01h
;; #3     | Minimum version of Hexagon    | 1 byte         | 0 for any or corresponding number
;; #4     | Minimal subversion of Hexagon | 1 byte         | 0 to any or corresponding number
;; #5     | Entry point (offset)          | 1 dword        | Entry point offset within the image
;; #6     | Image type                    | 1 byte         | Static executable image = 01h
;; #7     | Reserved field                | 1 dword        | Reserved for system use
;; #8     | Reserved field                | 1 byte         | Reserved for system use
;; #9     | Reserved field                | 1 byte         | Reserved for system use
;; #10    | Reserved field                | 1 byte         | Reserved for system use
;; #11    | Reserved field                | 1 dword        | Reserved for system use
;; #12    | Reserved field                | 1 dword        | Reserved for system use
;; #13    | Reserved field                | 1 dword        | Reserved for system use
;; #14    | Reserved field                | 1 dword        | Reserved for system use
;; #15    | Reserved field                | 1 word         | Reserved for system use
;; #16    | Reserved field                | 1 word         | Reserved for system use
;; #17    | Reserved field                | 1 word         | Reserved for system use
;;
;; For the HAPP2 specification (HAPP 2.1), new fields will already be reserved and can now be
;; implemented in application images.
;; The fields have been expanded to be used in future multitasking implementations, which require
;; storing the contents of registers to save the execution context when switching between
;; processes.
;; The number of fields is exaggerated but ensures compatibility for future system needs.
;; The definitions of each field are already found in the specification below.
;; There are two extra fields, with one byte and one qword, for storing data pertinent to the
;; process, along with fields #7 to #17, which are reserved but will already be distributed in
;; the HAPP2 specification (HAPP 2.2).
;;
;; Number |          Parameter          |   Parameter size   | Content (fixed or variable)
;; -------|-----------------------------|--------------------|-----------------------------
;; #18    | EAX register                | 1 dword            | eserved for system use
;; #19    | EBX register                | 1 dword            | Reserved for system use
;; #20    | ECX register                | 1 dword            | Reserved for system use
;; #21    | EDX register                | 1 dword            | Reserved for system use
;; #22    | EDI register                | 1 dword            | Reserved for system use
;; #23    | ESI register                | 1 dword            | Reserved for system use
;; #24    | CS register                 | 1 dword            | Reserved for system use
;; #25    | DS register                 | 1 dword            | Reserved for system use
;; #26    | ES register                 | 1 dword            | Reserved for system use
;; #27    | FS register                 | 1 dword            | Reserved for system use
;; #28    | GS register                 | 1 dword            | Reserved for system use
;; #29    | EFLAGS register             | 1 dword            | Reserved for system use
;; #30    | EIP register                | 1 dword            | Reserved for system use
;; #31    | EBP register                | 1 dword            | Reserved for system use
;; #32    | ESP register                | 1 dword            | Reserved for system use
;; #33    | SS register                 | 1 dword            | Reserved for system use
;; #34    | Number of open files        | 1 dword            | Reserved for system use
;; #35    | Process identifier (PID)    | 1 dword            | Reserved for system use
;; #36    | Reserved field              | 1 word             | Reserved for system use
;; #37    | Reserved field              | 1 qword            | Reserved for system use
;;
;; The process has access to these fields, and there will be a copy of fields #18 through #34 in
;; the kernel's reserved memory area, since the process could intentionally change thread values
;; ​​and data to force access to memory areas that were not attributed to him.
;; These fields will be filled in by the system and copied (the structure) to the kernel heap.
;; The process will be able to read and edit but the copy has already been transferred to the
;; kernel heap, and from there the data will be read to reestablish the process context.
;;
;; Etapas:
;;
;; Process execution -> copy of initial structure to kernel heap and initialization
;; -> context switch request -> write context to fields #18 to #37 in user space
;; and in kernel space (#1 to #20).
;;
;; The process will be able to obtain context and memory location data, but will not
;; be able to change the values ​​in a way that would interfere with the system operation.
;; This can be useful for manipulating intra-process memory data, serving only as a reference
;; for the process, but not for any other purpose that circumvents the security of GDT
;; segmentation.
;;
;; Reserved fields are marked for system use.
;; They may be used by the system to reserve data in context switching in the future,
;; for example, during multitasking.

;; This is the initial structure that must follow the current HAPP specifications.
;; Specification used: HAPP2 (HAPP 2.0)

struc Hexagon.Libkern.HAPP.controlStructure

{

.errorCode:         dd 0 ;; Error code issued by the last process
.imageArchitecture: db 0 ;; Image architecture
.incompatibleImage: db 0 ;; Incompatible image?
.minVersion:        db 0 ;; Minimum version of Hexagon required to run (dependency)
.minSubversion:     db 0 ;; Subversion (or revision) of Hexagon required for execution (dependency)
.entryHAPP:         dd 0 ;; Image entry point
.imageType:         db 0 ;; Image executable type
.exitCode:          dd 0 ;; Image code exit code (future)
.reserved1:         db 0 ;; Reserved (Byte)
.reserved2:         db 0 ;; Reserved (Byte)
.reserved3:         db 0 ;; Reserved (Byte)
.reserved4:         dd 0 ;; Reserved (Dword)
.reserved5:         dd 0 ;; Reserved (Dword)
.reserved6:         dd 0 ;; Reserved (Dword)
.reserved7:         db 0 ;; Reserved (Byte)
.reserved8:         dw 0 ;; Reserved (Word)
.reserved9:         dw 0 ;; Reserved (Word)
.reserved10:        dw 0 ;; Reserved (Word)

}

;;************************************************************************************

;; The Hexagon.Libkern.HAPP.imageHAPPHeader "object" will be created for use by the kernel,
;; which will be filled with image data in the functions below and also read and manipulated
;; by the virtual management and process scheduling functions.
;; The scheduler obtains the entry point and manipulates the header data in memory

;; This object will be located in a reserved area of ​​kernel memory

virtual at Hexagon.Heap.Temp

Hexagon.Libkern.HAPP.imageHAPPHeader Hexagon.Libkern.HAPP.controlStructure

end virtual

;;************************************************************************************

;; This function analyzes the application's executable image, checking whether it has
;; a valid header, whether the architecture is supported by the system and whether the kernel
;; version numbers are those required to execute the image.
;; If not, the image will be marked as invalid and will not be executed, returning error code
;; 3 to the process that requested loading.

Hexagon.Libkern.HAPP.checkHAPPImage:

;; Let's save the filename

    push esi

;; Does the file exist on the volume? We need the size of the file data

    call Hexagon.Kernel.FS.VFS.fileExists

    push eax

    mov edi, Hexagon.Heap.Temp + 1000 ;; Use kernel heap

;; Let's load the image to analyze the image header

    call Hexagon.Kernel.FS.VFS.openFile

    jc .imageNotFound

;; Let's start checking the executable header of the loaded image

    mov edi, Hexagon.Heap.Temp + 1000 ;; Use kernel heap

;; Let's check the 4 bytes of the "magic number" of the header

    cmp byte[edi+0], "H" ;; H of HAPP
    jne .invalidHeader

    cmp byte[edi+1], "A" ;; A of HAPP
    jne .invalidHeader

    cmp byte[edi+2], "P" ;; P of HAPP
    jne .invalidHeader

    cmp byte[edi+3], "P" ;; P of HAPP
    jne .invalidHeader

;; If we got this far, we have the header in the file. We must check the rest of the fields,
;; such as the minimum kernel versions required for execution, as well as the architecture

;; Let's check if the image architecture is the same as Hexagon

    cmp byte[edi+4], Hexagon.Arch.support ;; Supported architecture
    jne .invalidHeader

    mov ah, byte[edi+4]
    mov byte[Hexagon.Libkern.HAPP.imageHAPPHeader.imageArchitecture], ah

;; Okay, now let's get to the necessary kernel versions as image dependencies

    cmp byte[edi+5], Hexagon.Version.versionNumber ;; Declared kernel version
    jg .invalidHeader ;; The image requires a version of Hexagon higher than this

    cmp byte[edi+5], Hexagon.Version.versionNumber ;; Declared kernel version
    jl .validHeader ;; The image requires a version of Hexagon lower than this

    mov ah, byte[edi+5]
    mov byte[Hexagon.Libkern.HAPP.imageHAPPHeader.minVersion], ah

    cmp byte[edi+6], Hexagon.Version.subversionNumber ;; Declared subversion of the kernel
    jg .invalidHeader ;; The image requires a version of Hexagon higher than this

.validHeader:

    mov ah, byte[edi+6]
    mov byte[Hexagon.Libkern.HAPP.imageHAPPHeader.minSubversion], ah

;; Now let's get the entry point. Hexagon no longer needs to know the exact entry point
;; of the image, it is indicated in the HAPP header.
;; Now, the order of the code no longer matters, Hexagon will find the relative offset
;; of the image, if it is declared in the header.

    mov eax, dword[edi+7]
    mov dword[Hexagon.Libkern.HAPP.imageHAPPHeader.entryHAPP], eax

;; Image types can be (01h) executable images and (02h and 03h) static or dynamic libraries
;; (future implementations)

;; First, let's assess whether the image is in a working executable format.
;; Kernel images may have a different image type number, to prevent direct execution

    cmp byte[edi+11], 03h
    ja .invalidExecutableType

;; If everything is ok, let's proceed with the image check

    mov ah, byte[edi+11]
    mov byte[Hexagon.Libkern.HAPP.imageHAPPHeader.imageType], ah

;; If everything is ok with the header, check that the image can be executed

    mov byte[Hexagon.Libkern.HAPP.imageHAPPHeader.incompatibleImage], 00h ;; Mark image as compatible

    jmp .end ;; Let's continue without marking an error in the image

.invalidHeader: ;; Something in the header is invalid, so the image cannot be executed

    mov byte[Hexagon.Libkern.HAPP.imageHAPPHeader.incompatibleImage], 01h ;; Mark as invalid

    jmp .end ;; Skip to end of function

.imageNotFound:

    mov byte[Hexagon.Libkern.HAPP.imageHAPPHeader.incompatibleImage], 02h ;; Mark error while loading

    jmp .end

.invalidExecutableType:

    mov byte[Hexagon.Libkern.HAPP.imageHAPPHeader.incompatibleImage], 03h

    jmp .end

.end:

    pop eax
    pop esi

    ret
