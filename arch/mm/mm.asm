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

Hexagon.Arch.Memory.kernelReservedMemory  = 3545728
Hexagon.Arch.Memory.processReservedMemory = 16777216

struc Hexagon.Arch.Memory initialAddress
{

.initialAddress  = initialAddress
.totalMemory:    dd 0 ;; Stores the total memory obtained, in bytes
.addressBPB:     dd 0 ;; BIOS Parameter Block memory address

;; Hexagon.init copies the 512 bytes Boot/Saturno left resident at boot into
;; this buffer once, then repoints .addressBPB here. Saturno's own copy
;; isn't reserved from the kernel's allocator, and Hexagon.Heap.DiskCache
;; is close enough to overlap and zero its start

.BPBCopy:        rb 512
.usedMemory:     dd 0 ;; Stores the amount of memory used by user processes
.bytesAllocated: dd 0 ;; Bytes allocated

}

;; Every block carries this header, allocated or free, and its size covers the
;; header itself. That is what lets Hexagon.Arch.Mm.free work from the pointer
;; alone, instead of believing whatever size the caller reports back, and what
;; will let the arena be walked block by block to find everything one process
;; still holds

Hexagon.Arch.Mm.Block.size     = 0 ;; Whole block, header included
Hexagon.Arch.Mm.Block.owner    = 4 ;; Who holds it, one of the two values below
Hexagon.Arch.Mm.Block.previous = 8 ;; Free blocks only, and in address order
Hexagon.Arch.Mm.Block.next     = 12 ;; Free blocks only

Hexagon.Arch.Mm.Block.headerSize = 8

;; A free block has to be able to hold its own list pointers, so nothing
;; smaller than this can be described and split off

Hexagon.Arch.Mm.Block.minimumSize = 16

;; The owner field carries a fixed stamp in its upper bits and who holds the
;; block in its lowest byte. Bounds alone cannot tell a real header from any
;; other address in the arena, and a process's own image lives in the arena
;; too: hx.free adds the caller's base to whatever pointer it is given, so a
;; wild pointer lands inside it and would otherwise have Mm.free reading a
;; size and a next pointer out of that process's own code

Hexagon.Arch.Mm.Block.stamp    = 0A55A5A00h
Hexagon.Arch.Mm.Block.slotMask = 0FFh

Hexagon.Arch.Mm.Block.kernel = 0FFh ;; Held by the kernel, and not a process's
                                    ;; to free. Same value
                                    ;; Hexagon.Scheduler.current carries when
                                    ;; no process is running

;; Free blocks carry no stamp at all, so the check that refuses a wild pointer
;; is the same one that refuses freeing a block twice

Hexagon.Arch.Mm.Block.free = 0FFFFFFFFh
struc Hexagon.Arch.Memory.Allocator processSpaceSize
{

.firstFreeBlock  dd 0
.arenaStart      dd 0 ;; Bounds Hexagon.Arch.Mm.free checks a pointer against
.arenaEnd        dd 0 ;; before trusting the header it is about to read

;; Bytes each slot is holding, indexed by the owner byte a block header
;; carries, which is why this is 256 entries and not the process table's own
;; limit: the allocator answers for what it handed out, and knows a slot only
;; as that byte

.perSlot         rd 256
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

Hexagon.Memory           Hexagon.Arch.Memory Hexagon.Arch.Memory.kernelReservedMemory
Hexagon.Memory.Allocator Hexagon.Arch.Memory.Allocator Hexagon.Arch.Memory.processReservedMemory

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

Hexagon.Arch.Mm.memoryUse:

    push ds ;; Kernel data segment
    pop es

    mov eax, dword[Hexagon.Memory.usedMemory]

    mov ebx, dword[Hexagon.Memory.totalMemory]

.provideMB: ;; Also provide the total amount in Mbytes

    mov ecx, dword[Hexagon.Memory.totalMemory]

    shr ecx, 10 ;; ECX = ECX/1024

    shr ecx, 10 ;; ECX = ECX/1024

.provideReservedMemory:

    mov edx, Hexagon.Arch.Memory.kernelReservedMemory

.provideAllocatedMemory:

;; Add Hexagon reserved memory

    push eax
    push ebx

    mov eax, Hexagon.Arch.Memory.kernelReservedMemory

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

Hexagon.Arch.Mm.confirmMemoryUsage:

    add dword[Hexagon.Memory.usedMemory], eax

    ret

;;************************************************************************************

;; Releases the use of a certain amount of memory for user processes
;;
;; Input:
;;
;; EAX - Amount of memory to be freed

Hexagon.Arch.Mm.freeMemoryUsage:

    sub dword[Hexagon.Memory.usedMemory], eax

    ret

;;************************************************************************************

Hexagon.Arch.Mm.initMemory:

;; Firstly, the starting address for allocating processes and data will be after the
;; space reserved for the kernel and its structures

    mov ebx, Hexagon.Memory.initialAddress ;; After the reserved space

;; Total free memory after the address, until the end of detected memory.
;; This will be the allocation area

    mov ecx, [Hexagon.Memory.totalMemory]

    sub ecx, Hexagon.Memory.initialAddress

    call Hexagon.Arch.Mm.configMemory ;; Start the memory handler

;; Each process is allocated its own memory individually by
;; Hexagon.Kern.Proc.addProcess

    ret

;;************************************************************************************

;; Start memory
;;
;; Input:
;;
;; EBX - Start of free memory
;; ECX - Total free memory size

Hexagon.Arch.Mm.configMemory:

;; The block header written at EBX goes through ES, forced to the kernel
;; linear selector here, since a caller at user level leaves ES on its
;; data segment. Hexagon.Memory.Allocator.* are kernel globals reached
;; through DS as usual

    push es
    push ecx
    push edx

    mov ax, 18h
    mov es, ax

    sub ecx, ebx

;; The arena begins life as a single free block covering all of it, and every
;; block that ever exists is carved out of this one, so the chain of headers
;; stays contiguous from here to the end of memory

    mov [Hexagon.Memory.Allocator.firstFreeBlock], ebx
    mov [Hexagon.Memory.Allocator.arenaStart], ebx

    mov edx, ebx

    add edx, ecx

    mov [Hexagon.Memory.Allocator.arenaEnd], edx

    mov [es:ebx + Hexagon.Arch.Mm.Block.size], ecx
    mov dword[es:ebx + Hexagon.Arch.Mm.Block.owner], Hexagon.Arch.Mm.Block.free
    mov dword[es:ebx + Hexagon.Arch.Mm.Block.previous], 0
    mov dword[es:ebx + Hexagon.Arch.Mm.Block.next], 0

    pop edx
    pop ecx

    pop es

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
;;
;; The block comes out stamped as the kernel's. Anything handing memory to a
;; process stamps it afterwards, so that forgetting to do so leaks a block
;; instead of letting a process free memory that was never its own

;;************************************************************************************

Hexagon.Arch.Mm.malloc:

    push edx

    xor edx, edx ;; No alignment asked for

    call Hexagon.Arch.Mm.mallocAligned

    pop edx

    ret

;;************************************************************************************

;; Allocates memory whose first byte lands on a boundary the caller names,
;; which is what anything the processor reads directly needs: a page directory
;; and its tables have to be 4 KB aligned, and a block whose pages are opened
;; to a process alone has to start where a page does
;;
;; Doing it here, and not in each caller, is what keeps the header eight
;; bytes behind the pointer, since the bytes left in front are split off as a
;; free block of their own, and not swallowed as slack
;;
;; Input:
;;
;; EBX - Size of requested memory, in bytes
;; EDX - Alignment, a power of two; 4 or less asks for nothing in particular
;;
;; Exit:
;;
;; EAX - 0 if failed
;; EBX - Pointer to allocated memory, if successful

Hexagon.Arch.Mm.mallocAligned:

;; The free-list below is a single global structure with no per-call locking.
;; Disable interrupts for the duration of the call so a timer preemption can't
;; run malloc/free again on top of an already in-progress update and corrupt it

    pushfd
    cli

;; Every [reg + N] header dereference below goes through ES, forced to the
;; kernel linear selector here, since a caller at user level leaves ES on its
;; own data segment. Hexagon.Memory.Allocator.* are kernel globals reached
;; through DS as usual

    push es
    push ecx
    push edx
    push esi
    push edi
    push ebp

    mov ax, 18h
    mov es, ax

    mov ebp, edx ;; Alignment, needed all the way through the search below

;; What the caller asked for, plus the header, rounded so that every header
;; after this one stays aligned, and never smaller than a block that has to
;; hold its own list pointers once it is freed

    add ebx, Hexagon.Arch.Mm.Block.headerSize + 3
    jc .error ;; A request within a few bytes of 4 Gb, which wrapped just above

    and ebx, not 3

    cmp ebx, Hexagon.Arch.Mm.Block.minimumSize
    jae .search

    mov ebx, Hexagon.Arch.Mm.Block.minimumSize

.search:

    mov eax, [Hexagon.Memory.Allocator.firstFreeBlock]

.nextCandidate:

    cmp eax, 0
    je .error

;; EDI is what would have to be left in front of this block for the memory to
;; begin where the caller asked. It counts against the block's own size, so a
;; block only fits if it holds the head and the request both

    xor edi, edi

    cmp ebp, 4
    jbe .headMeasured ;; Nothing finer than the header's own alignment

    mov ecx, ebp

    dec ecx ;; The alignment as a mask

    mov edx, eax

    add edx, Hexagon.Arch.Mm.Block.headerSize ;; Where the memory would begin
    add edx, ecx

    not ecx

    and edx, ecx ;; Carried up to the boundary asked for

    mov edi, edx

    sub edi, Hexagon.Arch.Mm.Block.headerSize
    sub edi, eax

    jz .headMeasured

;; What is left in front has to be able to describe itself, so a head too
;; small to be a block by itself takes the following boundary instead

    cmp edi, Hexagon.Arch.Mm.Block.minimumSize
    jae .headMeasured

    add edi, ebp

.headMeasured:

    mov ecx, edi

    add ecx, ebx

    cmp [es:eax + Hexagon.Arch.Mm.Block.size], ecx
    jae .blockFound

    mov eax, [es:eax + Hexagon.Arch.Mm.Block.next]

    jmp .nextCandidate

.error:

    xor eax, eax

    jmp .end

;; ESI and EDI are the neighbours this block has in the free list, and EDX
;; becomes whatever takes its place there: the remainder left over by the
;; split below, or nothing at all when there is no remainder to speak of

.blockFound:

    cmp edi, 0
    je .headSplit

;; The head becomes a free block where this one stood, keeping its place in the
;; list, and what follows becomes a second free block. Everything below then
;; works on a block that starts where the caller's memory has to start, with no
;; special case for it

    mov ecx, [es:eax + Hexagon.Arch.Mm.Block.size]

    sub ecx, edi

    mov edx, [es:eax + Hexagon.Arch.Mm.Block.next]

    mov [es:eax + Hexagon.Arch.Mm.Block.size], edi

    mov esi, eax ;; The head, which the new block follows

    add eax, edi

    mov [es:eax + Hexagon.Arch.Mm.Block.size], ecx
    mov dword[es:eax + Hexagon.Arch.Mm.Block.owner], Hexagon.Arch.Mm.Block.free
    mov [es:eax + Hexagon.Arch.Mm.Block.previous], esi
    mov [es:eax + Hexagon.Arch.Mm.Block.next], edx

    mov [es:esi + Hexagon.Arch.Mm.Block.next], eax

    cmp edx, 0
    je .headSplit

    mov [es:edx + Hexagon.Arch.Mm.Block.previous], eax

.headSplit:

    mov esi, [es:eax + Hexagon.Arch.Mm.Block.previous]
    mov edi, [es:eax + Hexagon.Arch.Mm.Block.next]

    mov ecx, [es:eax + Hexagon.Arch.Mm.Block.size]

    sub ecx, ebx

    cmp ecx, Hexagon.Arch.Mm.Block.minimumSize
    jb .wholeBlock

    mov edx, eax

    add edx, ebx

    mov [es:edx + Hexagon.Arch.Mm.Block.size], ecx
    mov dword[es:edx + Hexagon.Arch.Mm.Block.owner], Hexagon.Arch.Mm.Block.free
    mov [es:edx + Hexagon.Arch.Mm.Block.previous], esi
    mov [es:edx + Hexagon.Arch.Mm.Block.next], edi

    mov [es:eax + Hexagon.Arch.Mm.Block.size], ebx

    jmp .unlink

;; What is left over could not hold a header, so it goes to the
;; caller as slack inside its own block instead of becoming a gap that
;; nothing can ever describe or merge again

.wholeBlock:

    xor edx, edx

;; Take the block out of the free list, putting the remainder in its place
;; when there is one, and joining its two neighbours directly when there is not

.unlink:

    cmp esi, 0
    je .newHead

    cmp edx, 0
    je .previousToNext

    mov [es:esi + Hexagon.Arch.Mm.Block.next], edx

    jmp .repairNext

.previousToNext:

    mov [es:esi + Hexagon.Arch.Mm.Block.next], edi

    jmp .repairNext

.newHead:

    cmp edx, 0
    je .headToNext

    mov [Hexagon.Memory.Allocator.firstFreeBlock], edx

    jmp .repairNext

.headToNext:

    mov [Hexagon.Memory.Allocator.firstFreeBlock], edi

.repairNext:

    cmp edi, 0
    je .allocated

    cmp edx, 0
    je .nextToPrevious

    mov [es:edi + Hexagon.Arch.Mm.Block.previous], edx

    jmp .allocated

.nextToPrevious:

    mov [es:edi + Hexagon.Arch.Mm.Block.previous], esi

.allocated:

    mov dword[es:eax + Hexagon.Arch.Mm.Block.owner], Hexagon.Arch.Mm.Block.stamp or Hexagon.Arch.Mm.Block.kernel

;; What the arena actually gave away, header and rounding included, rather
;; than what was asked for. Hexagon.Arch.Mm.free reads the same field back,
;; so the two can no longer disagree about how much to account for

    push eax

    mov eax, [es:eax + Hexagon.Arch.Mm.Block.size]

    call Hexagon.Arch.Mm.confirmMemoryUsage

    pop eax

;; The caller never sees the header, and must not: for a block a process ends
;; up owning, it is the header that says how big the block is and whose it is

    add eax, Hexagon.Arch.Mm.Block.headerSize

    mov ebx, eax

.end:

    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx

    pop es

    popfd

    ret

;;************************************************************************************

;; Frees allocated memory
;;
;; Input:
;;
;; EBX - Pointer previously returned by Hexagon.Arch.Mm.malloc
;; ECX - Ignored. The block's own header is what says how big it is, and
;;       the parameter stays only so callers written against the older
;;       contract keep assembling

Hexagon.Arch.Mm.free:

;; Same reentrancy concern as malloc: this manipulates the same global free-list

    pushfd
    cli

    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi

;; Every [reg + N] header dereference below goes through ES, forced to the
;; kernel linear selector here, since a caller at user level leaves ES on its
;; own data segment. Hexagon.Memory.Allocator.* are kernel globals reached
;; through DS as usual

    push es

    mov ax, 18h
    mov es, ax

;; Resolving the pointer, and refusing anything that did not come from here,
;; is blockExtent's job. EBX comes back as the block itself and EDX its size

    call Hexagon.Arch.Mm.blockExtent

    jc .refuse

    mov ecx, [es:ebx + Hexagon.Arch.Mm.Block.owner]

;; Off the tally of whoever was holding it, while the owner is still readable

    and ecx, Hexagon.Arch.Mm.Block.slotMask

    cmp ecx, Hexagon.Arch.Mm.Block.kernel
    je .heldByTheKernel

    sub [Hexagon.Memory.Allocator.perSlot + ecx * 4], edx

.heldByTheKernel:

    mov dword[es:ebx + Hexagon.Arch.Mm.Block.owner], Hexagon.Arch.Mm.Block.free

;; The list is kept in address order, so the two merges below have
;; to look only at the block's immediate neighbours. ESI ends up as the free block
;; before this one and EDI as the one after

    xor esi, esi

    mov edi, [Hexagon.Memory.Allocator.firstFreeBlock]

.locate:

    cmp edi, 0
    je .insert

    cmp edi, ebx
    ja .insert

    mov esi, edi
    mov edi, [es:edi + Hexagon.Arch.Mm.Block.next]

    jmp .locate

.insert:

    mov [es:ebx + Hexagon.Arch.Mm.Block.previous], esi
    mov [es:ebx + Hexagon.Arch.Mm.Block.next], edi

    cmp esi, 0
    je .becomesHead

    mov [es:esi + Hexagon.Arch.Mm.Block.next], ebx

    jmp .linkNext

.becomesHead:

    mov [Hexagon.Memory.Allocator.firstFreeBlock], ebx

.linkNext:

    cmp edi, 0
    je .mergeBackward

    mov [es:edi + Hexagon.Arch.Mm.Block.previous], ebx

;; Absorb the block that follows, when this one ends exactly where it starts

    mov eax, ebx

    add eax, [es:ebx + Hexagon.Arch.Mm.Block.size]

    cmp eax, edi
    jne .mergeBackward

    mov eax, [es:edi + Hexagon.Arch.Mm.Block.size]

    add [es:ebx + Hexagon.Arch.Mm.Block.size], eax

    mov eax, [es:edi + Hexagon.Arch.Mm.Block.next]
    mov [es:ebx + Hexagon.Arch.Mm.Block.next], eax

    cmp eax, 0
    je .mergeBackward

    mov [es:eax + Hexagon.Arch.Mm.Block.previous], ebx

;; And be absorbed by the block before, on the same test. Going forward first
;; means one freed between two free blocks comes out as a single block rather
;; than as two

.mergeBackward:

    cmp esi, 0
    je .end

    mov eax, esi

    add eax, [es:esi + Hexagon.Arch.Mm.Block.size]

    cmp eax, ebx
    jne .end

    mov eax, [es:ebx + Hexagon.Arch.Mm.Block.size]

    add [es:esi + Hexagon.Arch.Mm.Block.size], eax

    mov eax, [es:ebx + Hexagon.Arch.Mm.Block.next]
    mov [es:esi + Hexagon.Arch.Mm.Block.next], eax

    cmp eax, 0
    je .end

    mov [es:eax + Hexagon.Arch.Mm.Block.previous], esi

    jmp .end

.refuse:

    xor edx, edx ;; Nothing was freed, so nothing goes back to the accounting

.end:

    pop es

    mov eax, edx

    call Hexagon.Arch.Mm.freeMemoryUsage

    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax

    popfd

    ret

;;************************************************************************************

;; Records which process holds a block, so that everything it still holds can
;; be found again by owner alone. Called after the allocation and not
;; passed into it, because what the kernel allocates on a new process's behalf
;; is allocated while its parent is the one running
;;
;; Input:
;;
;; EBX - Pointer Hexagon.Arch.Mm.malloc returned
;; EAX - Slot that holds it

Hexagon.Arch.Mm.setBlockOwner:

    pushfd
    cli

    push ebx
    push ecx
    push edx

    push es

    mov cx, 18h
    mov es, cx

    sub ebx, Hexagon.Arch.Mm.Block.headerSize

;; Same reasoning as in Mm.free: a pointer that never came from malloc has no
;; header in front of it, and this would be writing over whatever does sit there

    cmp ebx, [Hexagon.Memory.Allocator.arenaStart]
    jb .end

    cmp ebx, [Hexagon.Memory.Allocator.arenaEnd]
    jae .end

    mov ecx, [es:ebx + Hexagon.Arch.Mm.Block.owner]

    mov edx, ecx

    and edx, not Hexagon.Arch.Mm.Block.slotMask

    cmp edx, Hexagon.Arch.Mm.Block.stamp
    jne .end

    mov edx, [es:ebx + Hexagon.Arch.Mm.Block.size]

;; What the block accounts for moves with it, off whoever was holding it and
;; onto whoever is taking it. The kernel's own blocks are not counted against
;; anyone, so neither side of the move applies to them

    and ecx, Hexagon.Arch.Mm.Block.slotMask

    cmp ecx, Hexagon.Arch.Mm.Block.kernel
    je .hadNoProcess

    sub [Hexagon.Memory.Allocator.perSlot + ecx * 4], edx

.hadNoProcess:

    mov ecx, eax

    and ecx, Hexagon.Arch.Mm.Block.slotMask

    cmp ecx, Hexagon.Arch.Mm.Block.kernel
    je .stamp

    add [Hexagon.Memory.Allocator.perSlot + ecx * 4], edx

.stamp:

    or ecx, Hexagon.Arch.Mm.Block.stamp

    mov [es:ebx + Hexagon.Arch.Mm.Block.owner], ecx

.end:

    pop es

    pop edx
    pop ecx
    pop ebx

    popfd

    ret

;;************************************************************************************

;; Resolves a pointer this allocator handed out into the block behind it, and
;; refuses anything else. Split out of Mm.free because whoever is about to free
;; a block may need to know how far it runs first, and asking twice would mean
;; two places deciding what a valid pointer is
;;
;; Input:
;;
;; EBX - Pointer as the caller received it
;;
;; Output:
;;
;; EBX - The block's own start, unchanged if refused
;; EDX - The block's size, in bytes
;; CF  - Set if the pointer was not one of ours, or names a block already free

Hexagon.Arch.Mm.blockExtent:

    push eax
    push ecx

    push es

    mov cx, 18h
    mov es, cx

    cmp ebx, 0
    je .refuse

    sub ebx, Hexagon.Arch.Mm.Block.headerSize

;; A pointer this function never handed out would have everything below follow
;; whatever happens to sit in front of it, so the address is checked against
;; the arena before it is read at all

    cmp ebx, [Hexagon.Memory.Allocator.arenaStart]
    jb .refuseAndRestore

    cmp ebx, [Hexagon.Memory.Allocator.arenaEnd]
    jae .refuseAndRestore

;; Only a header this allocator wrote carries the stamp. Anything else, a
;; pointer that never came from malloc or one already given back, is refused
;; before a single other field of it is believed

    mov eax, dword[es:ebx + Hexagon.Arch.Mm.Block.owner]

    and eax, not Hexagon.Arch.Mm.Block.slotMask

    cmp eax, Hexagon.Arch.Mm.Block.stamp
    jne .refuseAndRestore

    mov edx, [es:ebx + Hexagon.Arch.Mm.Block.size]

    cmp edx, Hexagon.Arch.Mm.Block.minimumSize
    jb .refuseAndRestore

    mov eax, ebx

    add eax, edx

    cmp eax, [Hexagon.Memory.Allocator.arenaEnd]
    ja .refuseAndRestore

    pop es

    pop ecx
    pop eax

    clc

    ret

.refuseAndRestore:

    add ebx, Hexagon.Arch.Mm.Block.headerSize ;; Approximately what came in, so
                                              ;; a refused pointer is not left
                                              ;; pointing at a header it failed

.refuse:

    pop es

    pop ecx
    pop eax

    stc

    ret

;;************************************************************************************

;; How much a process is holding, counted as the blocks were handed out and
;; given back, not by walking the arena, since this is asked for in a
;; loop by anything watching the system
;;
;; Input:
;;
;; EAX - Slot
;;
;; Output:
;;
;; EAX - Bytes that slot holds

Hexagon.Arch.Mm.memoryUsedBySlot:

    and eax, Hexagon.Arch.Mm.Block.slotMask

    mov eax, [Hexagon.Memory.Allocator.perSlot + eax * 4]

    ret

;;************************************************************************************

;; Frees every block a process still holds. What it takes through hx.malloc is
;; its own to give back and nothing obliges it to: an application that simply
;; exits, or one killed by Ctrl+C or by a fault it caused, would otherwise
;; leave those blocks held until the machine is restarted
;;
;; Input:
;;
;; EAX - Slot whose blocks are to be released

Hexagon.Arch.Mm.freeProcessBlocks:

    pushfd
    cli

    push eax
    push ebx
    push ecx
    push esi

    push es

    mov cx, 18h
    mov es, cx

    and eax, Hexagon.Arch.Mm.Block.slotMask
    or eax, Hexagon.Arch.Mm.Block.stamp

    mov esi, eax ;; The owner field a block of this process carries

;; Freeing a block merges it with whichever neighbours are free, so neither
;; the block just freed nor the one after it is still a header afterwards,
;; and the walk cannot simply carry on from where it was. It starts over
;; instead, which terminates because every pass gives one block back

.restart:

    mov ebx, [Hexagon.Memory.Allocator.arenaStart]

.nextBlock:

    cmp ebx, [Hexagon.Memory.Allocator.arenaEnd]
    jae .done

    mov ecx, [es:ebx + Hexagon.Arch.Mm.Block.size]

;; A size malloc could not have written means the chain no longer describes
;; the arena, and going on would be reading whatever happens to be ahead

    cmp ecx, Hexagon.Arch.Mm.Block.minimumSize
    jb .done

    test ecx, 3
    jnz .done

    cmp [es:ebx + Hexagon.Arch.Mm.Block.owner], esi
    jne .skip

    add ebx, Hexagon.Arch.Mm.Block.headerSize ;; Mm.free takes the pointer the process was given

    call Hexagon.Arch.Mm.free

    jmp .restart

.skip:

    add ebx, ecx

    jmp .nextBlock

.done:

    pop es

    pop esi
    pop ecx
    pop ebx
    pop eax

    popfd

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

Hexagon.Arch.Mm.dilateMemorySpace:

    mov ebx, eax
    mov ecx, eax

    push ecx

    call Hexagon.Arch.Mm.malloc

    pop ecx

    add dword[Hexagon.Memory.Allocator.processReserved], ecx

;; The malloc above already added this block to Hexagon.Memory.usedMemory.
;; It is growing the allocator's own backing pool, not memory a process is
;; actually holding, so cancel that back out here

    mov eax, ecx

    call Hexagon.Arch.Mm.freeMemoryUsage

    ret

