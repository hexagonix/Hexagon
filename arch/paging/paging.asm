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

;; Paging, in the shape Hexagon uses it: segmentation still does the relocation
;; of a process, and paging is here for protection and for growing a process's
;; own space without needing physically contiguous frames
;;
;; The kernel's own space is mapped one to one, so every address the kernel
;; already computes stays the address the machine sees, and buffers handed to
;; a device for DMA need no translation

;; Page directory entry bits

Hexagon.Arch.Paging.Entry.present    = 1 shl 0
Hexagon.Arch.Paging.Entry.writable   = 1 shl 1
Hexagon.Arch.Paging.Entry.user       = 1 shl 2
Hexagon.Arch.Paging.Entry.largePage  = 1 shl 7 ;; 4 MB page, no page table under it

Hexagon.Arch.Paging.largePageSize = 400000h ;; 4 MB
Hexagon.Arch.Paging.directoryEntries = 1024

;; What each process gets as the stack the processor switches to when a trap
;; arrives from user level, named by SS0 and ESP0 in the TSS

Hexagon.Arch.Paging.kernelStackSize = 4096

;;************************************************************************************

;; Builds the kernel's own page directory and turns paging on. Every one of the
;; 1024 entries maps 4 MB one to one, covering the whole 4 GB address space,
;; which keeps memory mapped hardware (the AHCI ABAR, the video framebuffer)
;; reachable at the addresses the drivers already use
;;
;; Runs supervisor only. A process's own directory, built later, is what carries
;; user accessible entries

Hexagon.Arch.Paging.setupKernelPaging:

    pushad

    push ds
    pop es

    mov edi, Hexagon.Heap.PageDirectory

    mov eax, Hexagon.Arch.Paging.Entry.present or Hexagon.Arch.Paging.Entry.writable or Hexagon.Arch.Paging.Entry.largePage

    mov ecx, Hexagon.Arch.Paging.directoryEntries

.fillDirectory:

    mov dword[es:edi], eax

    add eax, Hexagon.Arch.Paging.largePageSize ;; Next 4 MB of physical memory

    add edi, 4

    dec ecx

    jnz .fillDirectory

;; 4 MB pages only exist while CR4's own size extension bit is set, so it goes
;; in before the directory is ever consulted

    mov eax, cr4
    or eax, 10h ;; PSE
    mov cr4, eax

    mov eax, Hexagon.Heap.PageDirectory
    mov cr3, eax

    mov eax, cr0
    or eax, 80000000h ;; PG
    mov cr0, eax

    popad

    ret

;;************************************************************************************

;; Builds a page directory for one process. Every entry of the kernel's own
;; directory is copied in first, so kernel code runs identically whichever
;; directory is loaded, and the process's own range is then remapped with 4 KB
;; pages so that only the pages it actually owns carry the user bit
;;
;; Input:
;;
;; EBX - Physical base of the process's block
;; ECX - Size of that block, in bytes
;;
;; Output:
;;
;; EAX - Page directory, or 0 if there was not enough memory for one
;; EBX - Block Mm.malloc handed back, to be freed with it
;; ECX - Size of that block
;; EDX - Top of this process's own kernel stack, carved from the same block
;;
;; The scratch below is static, and the caller reaches here from a system call,
;; which runs with interrupts on. Two processes creating a process at the same
;; time would otherwise build their spaces on top of each other's state, and
;; walk away sharing a kernel stack. Mm.malloc's own pushfd/cli restores to
;; masked, and does not force interrupts back on, so it nests safely in here

Hexagon.Arch.Paging.createProcessSpace:

    pushfd
    cli

    push esi
    push edi
    push ebp

    mov dword[.base], ebx
    mov dword[.size], ecx

;; A range can straddle more than one 4 MB region, and each one it touches
;; needs a separate table to describe

    mov eax, ebx
    add eax, ecx
    dec eax
    shr eax, 22

    mov edx, ebx
    shr edx, 22

    sub eax, edx
    inc eax

    mov dword[.regions], eax

;; The directory, one table per region, and a kernel stack for the process to
;; trap onto once it runs at user level

    shl eax, 12
    add eax, 1000h + Hexagon.Arch.Paging.kernelStackSize

    mov dword[.blockSize], eax

    mov ebx, eax

    mov edx, 1000h ;; CR3 keeps only the top 20 bits of the directory's address

    call Hexagon.Arch.Mm.mallocAligned ;; EBX = block, EAX = 0 if there was none

    cmp eax, 0
    je .withoutMemory

    mov dword[.block], ebx
    mov dword[.directory], ebx

;; Start from the kernel's own map, so anything outside this process's range
;; stays reachable to the kernel exactly as before

    push ds
    pop es

    mov esi, Hexagon.Heap.PageDirectory
    mov edi, ebx
    mov ecx, Hexagon.Arch.Paging.directoryEntries

    cld

    rep movsd

    mov ebp, 0 ;; Region being described

.describeRegion:

    mov eax, dword[.regions]

    cmp ebp, eax
    jae .spaceReady

;; This region's own table sits after the directory, one 4 KB table per region

    mov edi, dword[.directory]
    add edi, 1000h

    mov eax, ebp
    shl eax, 12

    add edi, eax

    mov dword[.table], edi

;; The region's first address, and from it the address of each of its 1024
;; pages in turn

    mov eax, dword[.base]
    shr eax, 22
    add eax, ebp
    shl eax, 22

    mov dword[.pageAddress], eax

    mov ecx, 1024

.describePage:

    mov eax, dword[.pageAddress]

    mov edx, eax
    or edx, Hexagon.Arch.Paging.Entry.present or Hexagon.Arch.Paging.Entry.writable

;; Only the pages the process owns are reachable from user level, the rest of
;; the region staying mapped for the kernel alone. A block begins and ends
;; mid-page, so the pages at either end are granted whole, shared with whatever
;; the allocator put next to them

    mov esi, dword[.base]
    and esi, not 0FFFh

    cmp eax, esi
    jb .storePage

    mov esi, dword[.base]
    add esi, dword[.size]
    add esi, 0FFFh
    and esi, not 0FFFh

    cmp eax, esi
    jae .storePage

    or edx, Hexagon.Arch.Paging.Entry.user

.storePage:

    mov dword[es:edi], edx

    add edi, 4

    add dword[.pageAddress], 1000h

    dec ecx

    jnz .describePage

;; Replace the region's 4 MB entry with the table just built. The user bit here
;; only lets the processor consult the table, each page decides for itself

    mov edi, dword[.directory]

    mov eax, dword[.base]
    shr eax, 22
    add eax, ebp

    shl eax, 2

    add edi, eax

    mov eax, dword[.table]
    or eax, Hexagon.Arch.Paging.Entry.present or Hexagon.Arch.Paging.Entry.writable or Hexagon.Arch.Paging.Entry.user

    mov dword[es:edi], eax

    inc ebp

    jmp .describeRegion

.spaceReady:

;; The kernel stack sits past the directory and its tables, and grows down from
;; the end of what was reserved for it

    mov edx, dword[.directory]
    add edx, 1000h

    mov eax, dword[.regions]
    shl eax, 12

    add edx, eax
    add edx, Hexagon.Arch.Paging.kernelStackSize
    sub edx, 4

    mov eax, dword[.directory]
    mov ebx, dword[.block]
    mov ecx, dword[.blockSize]

    pop ebp
    pop edi
    pop esi

    popfd

    ret

.withoutMemory:

    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx

    pop ebp
    pop edi
    pop esi

    popfd

    ret

.base:        dd 0
.size:        dd 0
.regions:     dd 0
.block:       dd 0
.blockSize:   dd 0
.directory:   dd 0
.table:       dd 0
.pageAddress: dd 0

;;************************************************************************************

;; Puts one slot's own space in front of the processor: its page directory, and
;; the stack a trap from user level lands on. A slot with no directory of its
;; own, such as the idle loop, runs under the kernel's
;;
;; Input:
;;
;; EAX - Slot index

Hexagon.Arch.Paging.switchSpace:

    push eax
    push ebx

    mov ebx, dword[Hexagon.Processes.Table.kernelStack + eax * 4]
    mov dword[TSS.esp0], ebx

    mov eax, dword[Hexagon.Processes.Table.pageDirectory + eax * 4]

    cmp eax, 0
    jne .load

    mov eax, Hexagon.Heap.PageDirectory

.load:

    mov cr3, eax

    pop ebx
    pop eax

    ret

;;************************************************************************************

;; Gives back the memory one process's page directory and tables occupied
;;
;; Input:
;;
;; EBX - Block Hexagon.Arch.Paging.createProcessSpace returned
;; ECX - Size of that block

Hexagon.Arch.Paging.destroyProcessSpace:

    cmp ebx, 0
    je .nothingToFree

;; Giving a directory back while the processor still runs on it lets the
;; allocator write free-list links over its first entries. Step onto the
;; kernel's own map first, since whoever is dispatched next loads its own
;; directory anyway. A process killed from outside is running on somebody
;; else's directory, which this leaves alone

    push eax
    push edx

    mov eax, cr3

    cmp eax, ebx
    jb .notLoaded

    mov edx, ebx

    add edx, ecx

    cmp eax, edx
    jae .notLoaded

    mov eax, Hexagon.Heap.PageDirectory

    mov cr3, eax

.notLoaded:

    pop edx
    pop eax

    call Hexagon.Arch.Mm.free

.nothingToFree:

    ret

;;************************************************************************************

;; Says whether a range is one the running process could reach by itself, by
;; walking its directory exactly the way Hexagon.Arch.Paging.openRangeToUser
;; writes it. The answer therefore agrees by construction with whatever was
;; opened to that process: its own block, its arguments, its environment and
;; every hx.malloc block, with no separate bookkeeping to keep in step
;;
;; This is what stands between a buffer a caller names and the kernel writing
;; into it at CPL 0, where paging no longer refuses anything
;;
;; Input:
;;
;; EBX - First address of the range, in the kernel's own flat frame, as
;;       hexagonHandler already translated it
;; ECX - Its size in bytes
;;
;; Output:
;;
;; CF - Set if the caller named no buffer at all, or if any page of the range is
;;      not present, writable and reachable at user level. Clear otherwise

Hexagon.Arch.Paging.rangeIsCallerWritable:

    push eax
    push ebx
    push ecx
    push edx
    push esi

    movzx esi, byte[Hexagon.Scheduler.current]

    cmp esi, 0xFF
    je .accept ;; Kernel boot context, with no directory and no user level to answer for

    mov eax, dword[Hexagon.Processes.Table.pageDirectory + esi * 4]

    cmp eax, 0
    je .accept ;; Shares the kernel's own directory, so it never runs at user level

;; hexagonHandler adds the process's base to EDI on every call, so a caller that
;; passed nothing at all arrives here naming exactly its own base. That is the
;; HAPP header of the image itself: never a real buffer, always a mistake

    cmp ebx, dword[Hexagon.Processes.Table.base + esi * 4]
    je .refuse

    cmp ecx, 0

    je .accept ;; Nothing to write, nothing to check

;; One past the last page of the range, then the first, the same rounding
;; openRangeToUser uses so the two never disagree about an edge

    add ecx, ebx
    add ecx, 0FFFh
    and ecx, not 0FFFh

    and ebx, not 0FFFh

.checkPage:

    cmp ebx, ecx

    jae .accept

    mov edx, ebx

    shr edx, 22

    mov esi, eax

    lea esi, [esi + edx * 4]

    mov edx, dword[esi]

    test edx, Hexagon.Arch.Paging.Entry.largePage
    jz .throughTable

;; Nothing finer than the whole region describes this address

    and edx, Hexagon.Arch.Paging.Entry.present or Hexagon.Arch.Paging.Entry.writable or Hexagon.Arch.Paging.Entry.user

    cmp edx, Hexagon.Arch.Paging.Entry.present or Hexagon.Arch.Paging.Entry.writable or Hexagon.Arch.Paging.Entry.user
    jne .refuse

    jmp .nextPage

.throughTable:

;; The region's table only lets the processor consult it, and each page still
;; decides for itself, so both have to say yes

    test edx, Hexagon.Arch.Paging.Entry.present or Hexagon.Arch.Paging.Entry.user
    jz .refuse

    and edx, not 0FFFh

    mov esi, ebx

    shr esi, 12
    
    and esi, 3FFh

    lea esi, [edx + esi * 4]

    mov edx, dword[esi]

    and edx, Hexagon.Arch.Paging.Entry.present or Hexagon.Arch.Paging.Entry.writable or Hexagon.Arch.Paging.Entry.user

    cmp edx, Hexagon.Arch.Paging.Entry.present or Hexagon.Arch.Paging.Entry.writable or Hexagon.Arch.Paging.Entry.user
    jne .refuse

.nextPage:

    add ebx, 1000h

    jmp .checkPage

.refuse:

    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax

    stc

    ret

.accept:

    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax

    clc

    ret

;;************************************************************************************

;; Opens a range to user level inside one process's own directory. Used for the
;; buffers a process is handed but which live in the kernel's own arena, outside
;; its block: its arguments and its environment
;;
;; A region described by a large page is granted whole, since that is the only
;; granularity it has. One already broken into a table is granted page by page
;;
;; Input:
;;
;; EAX - Page directory of the process, 0 for none
;; EBX - First address of the range
;; ECX - Its size, in bytes

;; Closes a range that was opened to user level, page by page, so that memory
;; a process has given back stops being reachable from it. A region still
;; described by a 4 MB entry is left exactly as it is: there is nothing there
;; but the whole region to close, and closing it would take with it everything
;; else the process holds in those four megabytes
;;
;; Input:
;;
;; EAX - Page directory
;; EBX - First address of the range
;; ECX - Size of the range, in bytes

Hexagon.Arch.Paging.revokeRangeFromUser:

    cmp eax, 0
    je .nothingToClose

    cmp ebx, 0
    je .nothingToClose

    cmp ecx, 0
    je .nothingToClose

    pushad

    push ds
    pop es

    mov esi, eax ;; Directory

    add ecx, ebx
    add ecx, 0FFFh
    and ecx, not 0FFFh ;; One past the last page of the range

    and ebx, not 0FFFh ;; Its first page

.closePage:

    cmp ebx, ecx
    jae .closed

    mov edx, ebx

    shr edx, 22

    lea edi, [esi + edx * 4]

    mov eax, dword[es:edi]

    test eax, Hexagon.Arch.Paging.Entry.largePage
    jnz .nextPage

    and eax, not 0FFFh ;; The table this region is described by

    mov edx, ebx

    shr edx, 12

    and edx, 3FFh ;; This page's own entry in it

    lea edi, [eax + edx * 4]

    mov eax, dword[es:edi]

    and eax, not Hexagon.Arch.Paging.Entry.user

    mov dword[es:edi], eax

.nextPage:

;; The translation the process has been using carries the user bit it was
;; loaded with, and would go on working until something else evicted it

    invlpg [ebx]

    add ebx, 1000h

    jmp .closePage

.closed:

    popad

.nothingToClose:

    ret

;;************************************************************************************

;; Replaces the 4 MB entry describing a region with a table of 1024 pages that
;; maps exactly the same memory, so that a range inside it can be granted page
;; by page. Without this there is nothing finer than the whole region to grant,
;; and opening a block of a few kilobytes would open four megabytes of the
;; kernel's arena along with it
;;
;; The table is an ordinary allocation stamped with the process it is for, so
;; Hexagon.Kern.Proc.exit's own sweep releases it with everything else the
;; process holds, and no separate bookkeeping has to remember it
;;
;; Input:
;;
;; EAX - Page directory
;; EBX - Any address inside the region to split
;; EDX - Slot the directory belongs to
;;
;; Output:
;;
;; CF - Set if there was no memory for a table, leaving the region as it was

Hexagon.Arch.Paging.splitLargePage:

    pushad

    push ds
    pop es

    mov ebp, eax ;; Directory

    shr ebx, 22 ;; Region

    mov esi, ebx

    lea edi, [ebp + esi * 4]

    mov eax, dword[es:edi]

    test eax, Hexagon.Arch.Paging.Entry.largePage
    jz .alreadySplit ;; A table describes it already, nothing to do

    push edx ;; The slot, across the allocation below

    mov ebx, 1000h

;; A directory entry keeps only the top 20 bits of the address it points at, so
;; the table has to begin on a 4 KB boundary

    mov edx, 1000h

    call Hexagon.Arch.Mm.mallocAligned

    cmp eax, 0
    je .withoutMemory

    pop edx ;; The slot

    mov eax, edx

    call Hexagon.Arch.Mm.setBlockOwner ;; EBX still the pointer, and preserved

;; Every page of the region, mapped exactly where the 4 MB entry mapped it and
;; with the same permissions. None of them is reachable at user level yet: the
;; caller grants what it asked for and nothing else

    mov edi, ebx

    mov eax, esi
    shl eax, 22 ;; The region's first address

    or eax, Hexagon.Arch.Paging.Entry.present or Hexagon.Arch.Paging.Entry.writable

    mov ecx, 1024

    cld

.describePage:

    mov dword[es:edi], eax

    add edi, 4

    add eax, 1000h

    dec ecx

    jnz .describePage

;; The user bit on the directory entry only lets the processor consult the
;; table, exactly as in createProcessSpace. Each page decides for itself

    lea edi, [ebp + esi * 4]

    mov eax, ebx
    or eax, Hexagon.Arch.Paging.Entry.present or Hexagon.Arch.Paging.Entry.writable or Hexagon.Arch.Paging.Entry.user

    mov dword[es:edi], eax

.alreadySplit:

    popad

    clc

    ret

.withoutMemory:

    pop edx

    popad

    stc

    ret

;;************************************************************************************

Hexagon.Arch.Paging.openRangeToUser:

    cmp eax, 0
    je .nothingToOpen

    cmp ebx, 0
    je .nothingToOpen

    pushad

    push ds
    pop es

    mov ebp, edx ;; Slot, kept in a register and not a static: this runs with
                 ;; interrupts on and two processes can be inside it at once

    mov esi, eax ;; Directory

    add ecx, ebx
    add ecx, 0FFFh
    and ecx, not 0FFFh ;; One past the last page of the range

    and ebx, not 0FFFh ;; Its first page

.openPage:

    cmp ebx, ecx
    jae .opened

    mov edx, ebx

    shr edx, 22

    mov edi, esi
    
    lea edi, [edi + edx * 4]

    mov eax, dword[es:edi]

    test eax, Hexagon.Arch.Paging.Entry.largePage
    jz .throughTable

;; Break the region up so that only the pages asked for are granted. If there
;; was no memory for the table, the whole region is opened as it used to be:
;; the allocation the caller is in the middle of matters more than the reach
;; it hands out, and Hexagon.Arch.Paging.revokeRangeFromUser knows to leave a
;; region in that state alone and not close four megabytes at once

    push eax
    push ebx
    push ecx

    mov eax, esi
    mov edx, ebp

    call Hexagon.Arch.Paging.splitLargePage

    pop ecx
    pop ebx
    pop eax

    jc .openWholeRegion

    mov edi, esi

    mov edx, ebx

    shr edx, 22

    lea edi, [edi + edx * 4]

    mov eax, dword[es:edi]

    jmp .throughTable

.openWholeRegion:

    or eax, Hexagon.Arch.Paging.Entry.user

    mov dword[es:edi], eax

    jmp .nextPage

.throughTable:

    and eax, not 0FFFh ;; The table this region is described by

    mov edx, ebx

    shr edx, 12
    
    and edx, 3FFh ;; This page's own entry in it

    lea edi, [eax + edx * 4]

    mov eax, dword[es:edi]

    or eax, Hexagon.Arch.Paging.Entry.user

    mov dword[es:edi], eax

.nextPage:

;; A translation is cached with the permissions it carried when it was loaded,
;; and the kernel's own access to this page moments ago is enough to have
;; loaded one without the user bit. Both callers open a range inside the
;; directory the processor is running on right now, so this is the space the
;; stale entry lives in

    invlpg [ebx]

    add ebx, 1000h

    jmp .openPage

.opened:

    popad

.nothingToOpen:

    ret
