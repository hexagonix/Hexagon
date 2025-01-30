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

Hexagon.Arch.Gen.Memory.kernelReservedMemory  = 3545728
Hexagon.Arch.Gen.Memory.processReservedMemory = 16777216

struc Hexagon.Arch.Gen.Memory initialAddress
{

.initialAddress  = initialAddress
.memoryCMOS:     dw 0 ;; Stores the amount of memory obtained at startup
.totalMemory:    dd 0 ;; Stores the total memory obtained, in bytes
.addressBPB:     dd 0 ;; BIOS Parameter Block memory address
.usedMemory:     dd 0 ;; Stores the amount of memory used by user processes
.bytesAllocated: dd 0 ;; Bytes allocated

}

struc Hexagon.Arch.Gen.Memory.Allocator processSpaceSize
{

.firstFreeBlock  dd 0
.previousPointer dd 0
.blockSize       dd 0
.nextPointer     dd 0
.initialReserved = processSpaceSize
.processReserved dd .initialReserved

}

;; Create instances of structures, with appropriate names that indicate their location
;;
;; Currently, 3 Mb are reserved for Hexagon and its structures and 16 Mb reserved for
;; loading executables into memory.
;; This information is available when creating the instantiated object and can be changed.
;; The first instance determines where the memory space that can be used by processes begins,
;; after the space reserved for the kernel.
;; The second determines the size of memory to be allocated to the processes. So, this area is
;; allocated and is managed by the kernel.

Hexagon.Memory           Hexagon.Arch.Gen.Memory Hexagon.Arch.Gen.Memory.kernelReservedMemory
Hexagon.Memory.Allocator Hexagon.Arch.Gen.Memory.Allocator Hexagon.Arch.Gen.Memory.processReservedMemory

;;************************************************************************************

;; Returns the amount of memory used by processes
;;
;; Output:
;;
;; EAX - Amount of memory used by processes on the stack
;; EBX - Total memory found and available for use, in bytes
;; ECX - Total memory found and available for use, in Mbytes (less precise)
;; EDX - Memory reserved for Hexagon, in bytes
;; ESI - Total allocated memory (reserved+processes), in kbytes

Hexagon.Arch.Gen.Mm.memoryUse:

    push ds ;; Kernel data segment
    pop es

    mov eax, dword[Hexagon.Memory.usedMemory]

    mov ebx, dword[Hexagon.Memory.totalMemory]

.provideMB: ;; Also provide the total amount in Mbytes

    mov ecx, dword[Hexagon.Memory.totalMemory]

    shr ecx, 10 ;; ECX = ECX/1024

    shr ecx, 10 ;; ECX = ECX/1024

.provideReservedMemory:

    mov edx, Hexagon.Arch.Gen.Memory.kernelReservedMemory

.provideAllocatedMemory:

;; Add Hexagon reserved memory

    push eax
    push ebx

    mov eax, Hexagon.Arch.Gen.Memory.kernelReservedMemory

;; Convert from bytes to kbytes now

    shr eax, 10 ;; EAX/1024
    shr eax, 10 ;; EAX/1024

    mov ebx, dword[Hexagon.Memory.usedMemory]
    add ebx, eax
    mov esi, ebx

    pop ebx
    pop eax

    ret

;;************************************************************************************

;; Confirms the use of a given amount of memory for user processes
;;
;; Input:
;;
;; EAX - Amount of memory to be used

Hexagon.Arch.Gen.Mm.confirmMemoryUsage:

    add dword[Hexagon.Memory.usedMemory], eax

    ret

;;************************************************************************************

;; Releases the use of a certain amount of memory for user processes
;;
;; Input:
;;
;; EAX - Amount of memory to be freed

Hexagon.Arch.Gen.Mm.freeMemoryUsage:

    sub dword[Hexagon.Memory.usedMemory], eax

    ret

;;************************************************************************************

Hexagon.Arch.Gen.Mm.initMemory:

;; Firstly, the starting address for allocating processes and data will be after the
;; space reserved for the kernel and its structures

    mov ebx, Hexagon.Memory.initialAddress ;; After the reserved space

;; Total free memory after the address, until the end of detected memory.
;; This will be the allocation area

    mov ecx, [Hexagon.Memory.totalMemory]

    sub ecx, Hexagon.Memory.initialAddress

    call Hexagon.Arch.Gen.Mm.configMemory ;; Start the memory handler

;; Now, the space reserved for processes will be defined, using the established standard
;; Hexagon.Memory.Allocator.initialReserved

    mov ebx, Hexagon.Memory.Allocator.initialReserved

    call Hexagon.Arch.Gen.Mm.malloc ;; Allocate memory to processes

    call Hexagon.Kern.Proc.configureProcessAllocation ;; Save the address used for allocation

    ret

;;************************************************************************************

;; Start memory
;;
;; Input:
;;
;; EBX - Start of free memory
;; ECX - Total free memory size

Hexagon.Arch.Gen.Mm.configMemory:

    push ecx

    mov [Hexagon.Memory.Allocator.firstFreeBlock], ebx

    sub ecx, ebx

    mov [Hexagon.Memory.Allocator.blockSize], ecx
    mov [Hexagon.Memory.Allocator.previousPointer], 0
    mov [Hexagon.Memory.Allocator.nextPointer], 0

    mov ecx, [Hexagon.Memory.Allocator.previousPointer]
    mov [ebx], ecx

    mov ecx, [Hexagon.Memory.Allocator.blockSize]
    mov [ebx+4], ecx

    mov ecx, [Hexagon.Memory.Allocator.nextPointer]
    mov [ebx+8], ecx

    pop ecx

    ret

;;************************************************************************************

;; Allocate memory
;;
;; Input:
;;
;; EBX - Size of requested memory, in bytes
;;
;; Exit:
;;
;; EAX - 0 if failed
;; EBX - Pointer to allocated memory, if successful

Hexagon.Arch.Gen.Mm.malloc:

    push ecx
    push edx

    mov eax, [Hexagon.Memory.Allocator.firstFreeBlock]

.loop:

    mov ecx, [eax]
    mov [Hexagon.Memory.Allocator.previousPointer], ecx

    mov ecx, [eax+4]
    mov [Hexagon.Memory.Allocator.blockSize], ecx

    mov ecx, [eax+8]
    mov [Hexagon.Memory.Allocator.nextPointer], ecx

    cmp [Hexagon.Memory.Allocator.blockSize], ebx
    jae .blockFound

    cmp [Hexagon.Memory.Allocator.nextPointer], 0
    je .error

    mov eax, [Hexagon.Memory.Allocator.nextPointer]

    jmp .loop

.error:

    xor eax, eax

    jmp .end

.blockFound:

    mov ecx, [Hexagon.Memory.Allocator.blockSize]

    sub ecx, ebx

    jz .equal

    cmp [Hexagon.Memory.Allocator.nextPointer], 0
    jne .nextPointerExists

    cmp [Hexagon.Memory.Allocator.previousPointer], 0
    jne .previousnotNextPointer

;; No other free blocks exist. Add another and move the first free block pointer there

    mov ecx, eax ;; Move address to ECX

    add ecx, ebx

    mov dword [ecx], 0 ;; Set previous block to 0
    mov edx, [Hexagon.Memory.Allocator.blockSize]

    sub edx, ebx ;; Remaining space on EDX

    mov [ecx+4], edx ;; Save to header
    mov dword [ecx+8], 0 ;; No pointer to next block

    mov [Hexagon.Memory.Allocator.firstFreeBlock], ecx
    mov ebx, eax ;; EAX unchanged

    jmp .end

;; The next block is not available/exists.
;; This way, a new header at the end of the requested size must be created, with the free size,
;; in addition to updating the next pointer in the previous header

.previousnotNextPointer:

    mov ecx, eax ;; Move address to ECX

    add ecx, ebx ;; Add to blocksize what was requested

    mov edx, [Hexagon.Memory.Allocator.previousPointer] ;; Set pointer to previous header in new
    mov [ecx], edx                ;; Set new header to 0
    mov edx, [Hexagon.Memory.Allocator.blockSize]

    sub edx, ebx ;; Previous space in EDX

    mov [ecx+4], edx ;; Save in new header
    mov dword [ecx+8], 0 ;; No next pointer

    mov [Hexagon.Memory.Allocator.previousPointer+8], ecx
    mov ebx, eax

    jmp .end

;; The previous and next blocks exist, so make a new header at the end of the requested block
;; with the free space.
;; Move data from next block to new one and add block size, updating all previous and next
;; pointers to 3 blocks

.nextPointerExists:

    cmp [Hexagon.Memory.Allocator.previousPointer], 0
    je .nextNotPrevious

    mov ecx, eax

    add ecx, ebx

    mov edx, [Hexagon.Memory.Allocator.previousPointer]
    mov [ecx], edx
    mov edx, [Hexagon.Memory.Allocator.blockSize]

    sub edx, ebx

    mov ebx, [Hexagon.Memory.Allocator.nextPointer+4]

    add edx, ebx

    mov [ecx+4], edx
    mov edx, [Hexagon.Memory.Allocator.nextPointer] ;; Address of the next free block

    cmp dword [edx], 0
    je .notNextPointer

    mov dword [edx], ecx
    mov dword [ecx+8], edx ;; Address to next pointer

    mov [Hexagon.Memory.Allocator.previousPointer+8], ecx
    mov ebx, eax

    jmp .end

.notNextPointer:

    mov dword [edx], 0
    mov dword [ecx+8], 0
    mov [Hexagon.Memory.Allocator.previousPointer+8], ecx
    mov ebx, eax

    jmp .end

;; The first free block has been allocated. Do the same as before, skipping the previous block
;; and moving the pointer to the next free block

.nextNotPrevious:

    mov ecx, eax

    add ecx, ebx

    mov dword [ecx], 0
    mov edx, [Hexagon.Memory.Allocator.blockSize]

    sub edx, ebx

    mov ebx, [Hexagon.Memory.Allocator.nextPointer+4]

    add edx, ebx

    mov [ecx+4], edx
    mov edx, [Hexagon.Memory.Allocator.nextPointer]

    cmp dword [edx], 0
    je .notNext

    mov dword [edx], ecx
    mov dword [ecx+8], edx

    mov [Hexagon.Memory.Allocator.firstFreeBlock], ecx ;; Zero and update first free block
    mov ebx, eax

    jmp .end

.notNext:

    mov dword [edx], 0
    mov ecx, [ecx+8]
    mov dword [ecx], 0
    mov [Hexagon.Memory.Allocator.previousPointer+8], ecx
    mov ebx, eax

    jmp .end

.equal:

    cmp [Hexagon.Memory.Allocator.nextPointer], 0
    jne .nextPointerExists2

    cmp [Hexagon.Memory.Allocator.previousPointer], 0
    jne .previousnotNextPointer2

    mov [Hexagon.Memory.Allocator.firstFreeBlock], 0
    mov ebx, eax

    jmp .end

.previousnotNextPointer2:

    mov dword [Hexagon.Memory.Allocator.previousPointer+8], 0
    mov ebx, eax

    jmp .end

.nextPointerExists2:

    cmp [Hexagon.Memory.Allocator.previousPointer], 0
    je .nextNotPrevious2

    mov ecx, [Hexagon.Memory.Allocator.previousPointer]
    mov edx, [Hexagon.Memory.Allocator.nextPointer]
    mov [ecx+8], edx
    mov [edx], ecx
    mov ebx, eax

    jmp .end

.nextNotPrevious2:

    mov ecx, [eax+8] ;; Get address from next header
    mov dword [ecx], 0 ;; Set previous header to 0 and update
    mov [Hexagon.Memory.Allocator.firstFreeBlock], ecx ;; Also update the first free block
    mov ebx, eax

.end:

    pop edx
    pop ecx

    ret

;;************************************************************************************

;; Frees allocated memory
;;
;; Input:
;;
;; EBX - Pointer to previously allocated memory
;; ECX - Size of previously allocated memory, in bytes

Hexagon.Arch.Gen.Mm.free:

    push eax
    push ebx
    push ecx
    push edx

    cmp ebx, [Hexagon.Memory.Allocator.firstFreeBlock]
    jb .newFirstFree

    cmp [Hexagon.Memory.Allocator.firstFreeBlock], 0
    je .newFirstFree

;; The block we want is between two free blocks or before the last free block, somewhere.
;; Search by EBX - address, so we know where the pointers to the previous or next blocks are,
;; to know if they can be merged

    mov eax, [Hexagon.Memory.Allocator.firstFreeBlock] ;; Current free block
    mov edx, [eax+8] ;; Next free block

.nextPosition:

    cmp edx, 0 ;; Check next
    je .blockFoundAtEnd ;; Is there a free block

    cmp ebx, edx ;; Is EBX below EDX?
    jb .blockFoundBetween ;; EBX found in the middle

    mov eax, edx ;; Update pointers to another loop
    mov edx, [eax+8]

    jmp .nextPosition

;; The block is between two other blocks

.blockFoundBetween:

    mov [ebx], eax ;; Create header
    mov [ebx+4], ecx
    mov [ebx+8], edx

    mov [eax+8], ebx ;; Update previous header
    mov [edx], ebx ;; Update next header

;; Check if the blocks can be merged

    add ecx, ebx

    cmp edx, ecx
    jne .mergeOnlyFirst

    push eax

    add eax, [eax+4]

    cmp ebx, eax

    pop eax

    jne .mergeOnlyLast

;; The previous and next can be merged

    mov ecx, [ebx+4] ;; Get current block size

    add [eax+4], ecx ;; Add this to the size of the previous one

    mov ecx, [edx+4] ;; Get the size of the next block

    add [eax+4], ecx ;; Add this to the previous size

    mov ecx, [edx+8] ;; Get the next pointer
    mov [eax+8], ecx ;; Store it

    cmp ecx, 0
    je .end

    mov [ecx], eax

    jmp .end

.mergeOnlyFirst:

    cmp ebx, eax
    jne .end

    mov ecx, [ebx+4] ;; Get current block size

    add [eax+4], ecx ;; Add this to the size of the previous one

    mov [edx], eax ;; Update the previous and next pointers
    mov [eax+8], edx

    jmp .end

.mergeOnlyLast:

    cmp edx, ecx
    jne .end

    mov ecx, [edx+4]

    add [ebx+4], ecx

    mov ecx, [edx+8]
    mov [ebx+8], ecx

    cmp ecx, 0
    je .end

    mov [ecx], ebx

    jmp .end

;; The block is after all free blocks

.blockFoundAtEnd:

    mov [ebx], eax ;; Create header
    mov [ebx+4], ecx
    mov [ebx+8], edx

    mov [eax+8], ebx ;; Update previous header

;; Check if blocks can be merged

    mov ecx, eax

    add ecx, [eax+4]

    cmp ebx, ecx
    jne .end

    mov ecx, [ebx+4]

    add [eax+4], ecx

    mov ecx, [ebx+8]
    mov [eax+8], ecx

    jmp .end

;; The block is before the other free ones

.newFirstFree:

    mov dword [ebx], 0
    mov [ebx+4], ecx ;; Create the new header
    mov edx, [Hexagon.Memory.Allocator.firstFreeBlock]
    mov [ebx+8], edx

    mov edx, ebx

    add edx, [ebx+4] ;; Check if the first block hits

    cmp edx, [Hexagon.Memory.Allocator.firstFreeBlock] ;; Current position + blocksize?
    je .mergeFirstFree ;; If yes, merge the two

    cmp [Hexagon.Memory.Allocator.firstFreeBlock], 0 ;; If not, check if the first block exists
    je .cont1

    mov edx, [ebx+8] ;; If yes, update the previous pointer
    mov [edx], ebx

.cont1:

    mov [Hexagon.Memory.Allocator.firstFreeBlock], ebx ;; If not, create new

    jmp .end ;; First cleaning

.mergeFirstFree: ;; Merge the first two

    mov edx, [ebx+8] ;; Add the block size with the previous one into the new one
    mov ecx, [edx+4]

    add [ebx+4], ecx

    mov ecx, [edx+8] ;; Get the next pointer from the previous block
    mov [ebx+8], ecx

    cmp ecx, 0
    je .cont2

    mov [ecx], ebx ;; Update this in the next one

.cont2:

    mov [Hexagon.Memory.Allocator.firstFreeBlock], ebx ;; Update the first free block

.end:

    pop edx
    pop ecx
    pop ebx
    pop eax

    ret

;;************************************************************************************

align 32

;; Expands the memory space reserved for processes. NOTICE! All data after space
;; previously allocated will be lost!
;;
;; Input:
;;
;; EAX - Size in bytes to expand
;;
;; Output:
;;
;; EAX - 0 if error
;;
;; This is a kernel-exclusive function!

Hexagon.Arch.Gen.Mm.dilateMemorySpace:

    mov ebx, eax
    mov ecx, eax

    push ecx

    call Hexagon.Arch.Gen.Mm.malloc

    pop ecx

    add dword[Hexagon.Memory.Allocator.processReserved], ecx

    ret
