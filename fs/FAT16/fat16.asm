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

;;************************************************************************************
;;
;;            Information relevant to understanding the FAT file system
;;                                (specifically FAT16B)
;;
;; FAT16B for Hexagon version 1.2
;;
;; - Each entry in the root directory is 32 bytes in size:
;; - 11 of these, initials, reserve the file name. If the first character has been replaced by
;;   a space (' '), it has been "deleted", and should not be displayed manipulated by the file
;;   system or by Hexagon itself.
;; - The initial cluster of a file is added to the entry in the root directory.
;;   By reading the content of the indicated cluster, we have the location of the next
;;   cluster in the chain.
;;   Both the initial and obtained values ​​must be used for the physical calculation of the
;;   address on disk, loading the value of bytes per cluster at once. An example:
;;   If the starting cluster is ten, this cluster's address is converted to a starting LBA
;;   address, carrying as many bytes per cluster as necessary on a case-by-case basis.
;;   Going to the entry of the tenth cluster in the FAT, it will be possible to obtain
;;   the number of the next cluster in the chain. Again, this cluster address is converted
;;   to physical address and n bytes are loaded into memory. Returning to FAT, reading the
;;   cluster number input, the next one can be obtained. If the cluster value is 0xFFF8,
;;   it is not a cluster number in the chain, but rather that this is the last cluster in
;;   the chain and the reading can now be completed.
;; - Some attributes are checked by this version of Hexagon's FAT16B driver. Information
;;   is read that would indicate the presence of a subdirectory or volume label.
;;   For now, this information is not used. However, code for manipulating directories is
;;   already being written, and one day this function will be incorporated.
;; - To facilitate development, the standard structures and variables for FAT-type systems
;;   are declared in the body of the Virtual File System, and are instantiated here, as they
;;   may be in future FAT12 and FAT32 systems, for example.
;; - Values ​​not described in constants will not be used in the code, to increase
;;   understanding. The constants associated with the instance must be used, such as input
;;   attributes and values ​​found in the inputs. Only values ​​of 0 and 1 can be used in
;;   logical operations. The rest of the values ​​must come from the constants and data
;;   already identified with their meaning, such as Hexagon.VFS.FAT.FAT16B.unlinkedAttribute,
;;   for example, indicating the initial character code that indicates that the file was
;;   deleted (space).
;;
;;************************************************************************************

;;************************************************************************************

directoryStack:
times 32 dd 0  ; Espaço para 32 endereços LBA (4 bytes cada)
stackIndex:
dd 0  ; Inicializa o índice da pilha com 0

;; Structure used to manipulate FAT16B volumes, based on the FAT template provided by VFS

Hexagon.VFS.FAT16B Hexagon.VFS.FAT

;;************************************************************************************

;; Determine the size of the current directory, in sectors and in entries.
;; The root directory has a fixed size; a subdirectory is a single cluster
;;
;; Output:
;;
;; EAX - Sectors used by the current directory
;; ECX - Total entries in the current directory

Hexagon.Kernel.FS.FAT16.getCurrentDirGeometry:

    push ebx

    mov eax, dword[Hexagon.VFS.FAT16B.currentDirLBA]
    mov ebx, dword[Hexagon.VFS.FAT16B.rootDir]

    cmp eax, ebx
    jne .subdirectory

;; In the root directory, use the fixed root directory size

    movzx eax, word[Hexagon.VFS.FAT16B.rootDirSize]
    movzx ecx, word[Hexagon.VFS.FAT16B.rootEntries]

    jmp .end

.subdirectory:

;; Subdirectories occupy a single cluster

    movzx eax, byte[Hexagon.VFS.FAT16B.sectorsPerCluster]

    mov ecx, dword[Hexagon.VFS.FAT16B.clusterSize]
    shr ecx, 5 ;; Entries per cluster (32 bytes each)

.end:

    pop ebx

    ret

;;************************************************************************************

;; Converts the name in FAT format to a name in the 8.3 standard
;;
;; Input:
;;
;; ESI - Pointer to 11-character name
;;
;; Output:
;;
;; NOTICE! The name will be changed!
;; CF defined if file name is invalid

Hexagon.Kernel.FS.FAT16.FATnameToFilename:

    push eax
    push ebx
    push ecx
    push edi
    push esi

;; Check empty filename

    cmp byte[esi], 0
    je .invalidFilename ;; If the string is empty

    cmp byte[esi+8], ' '
    jne .thisIsExtension

    call Hexagon.Libkern.String.trimString

    jmp .success

.thisIsExtension:

;; Clear buffer from previous operation

    mov ax, ' '
    mov ecx, 12
    mov edi, .filenameBuffer + 500h ;; Clear temporary buffer

    cld

    rep stosb

;; Copy name to temporary buffer

    pop esi ;; Restore ESI

    push esi

    mov edi, .filenameBuffer + 500h ;; Correct address based on segment
    mov ecx, 11

    rep movsb ;; Copy (ECX) bytes from ESI to EDI

;; Get filename without extension

    mov esi, .filenameBuffer
    mov byte[esi+8], 0

    call Hexagon.Libkern.String.trimString

;; Add dot

    call Hexagon.Libkern.String.stringSize

    mov byte[esi+eax], '.'

;; Get extension

    pop esi

    push esi ;; Restore ESI

    add esi, 8

    mov byte[esi+3], 0

    call Hexagon.Libkern.String.trimString

    mov ebx, eax ;; Save filename size (without extension)

    call Hexagon.Libkern.String.stringSize

;; Put file name and extension together

    lea edi, [.filenameBuffer + 500h + ebx + 1]

    mov ecx, eax

    rep movsb ;; Move (ECX) bytes from ESI to EDI

;; Copy temporary buffer to address

    pop esi

    push esi

    mov edi, esi

;; Correct address with segment base (physical address = address + segment base)

    add edi, 500h ;; ES segment based on 500h

    mov esi, .filenameBuffer
    mov ecx, 12

    rep movsb

    pop esi

    push esi

    add eax, ebx ;; Filename size + extension size

    inc eax ;; Add size of '.'

    mov byte[esi+eax], 0

.success:

    pop esi

    push esi

    clc ;; Clear Carry

    jmp .end

.invalidFilename:

    stc ;; Set Carry

.end:

    pop esi
    pop edi
    pop ecx
    pop ebx
    pop eax

    ret

.filenameBuffer: times 12 db ' '

;;************************************************************************************

;; Convert file name in 8.3 standard to FAT format
;;
;; Input:
;;
;; ESI - Filename
;;
;; Output:
;;
;; NOTICE! The name will be modified directly at the address indicated by ESI!
;; CF defined if file name is invalid

Hexagon.Kernel.FS.FAT16.filenameToFATName:

    push eax
    push ebx
    push ecx
    push edx
    push edi
    push esi

;; Check for empty string

    cmp byte[esi], 0
    je .invalidFilename ;; If the string is empty

;; Check dot

    mov al, '.' ;; Character to find

    call Hexagon.Libkern.String.findCharacterInString

    jnc .dot

    call Hexagon.Libkern.String.stringSize

    cmp eax, 8 ;; More than eight characters are not allowed in 8.3 format
    ja .invalidFilename

    call Hexagon.Libkern.String.toUppercase

    mov ecx, 11
    sub ecx, eax

    mov edx, eax

    pop esi

    push esi

    push es

    push ds ;; Kernel data segment
    pop es

;; Make sure the name has exactly 11 characters

    mov edi, esi

    add edi, eax

    mov al, ' '

    rep stosb

    pop es

    clc

    jmp .end

.dot:

    push eax

;; Clear temporary buffer from previous operation

    mov al, ' '
    mov ecx, 11
    mov edi, .filenameBuffer + 500h ;; Clear temporary buffer

    cld

    rep stosb

    pop eax

    cmp al, 1
    ja .invalidFilename ;; If the dot occurs more than once

    call Hexagon.Libkern.String.toUppercase ;; All FAT file names are capitalized

;; Check position of '.'

    mov ebx, 0 ;; EBX is the point position counter in the string

.findDotLoop:

    mov al, byte[esi]

    cmp al, '.'
    je .dotFound

    inc esi
    inc ebx

    jmp .findDotLoop

.dotFound:

    cmp ebx, 8
    ja .invalidFilename ;; If the file name has more than 8 characters

    cmp ebx, 1
    jb .invalidFilename ;; If the file name has less than 1 character

;; Save filename to a temporary buffer (no extension)

    pop esi ;; Restore ESI

    push esi

;; Correct address with segment base (physical address = address + segment base)

    mov edi, .filenameBuffer + 500h
    mov ecx, ebx

    cld

    rep movsb ;; Move (ECX) ESI characters to buffer

;; Now check extension

    pop esi ;; Restore ESI

    push esi

    add esi, ebx ;; EBX for filename length
    add esi, 1   ;; 1 byte for the character '.'

    call Hexagon.Libkern.String.stringSize ;; Check extension size

    cmp eax, 1
    jb .invalidFilename ;; If the extension is less than 1 character in length

    cmp eax, 3
    ja .invalidFilename ;; If the extension is more than 3 characters in length

;; Save extension to a temporary buffer

    mov edi, .filenameBuffer + 500h + 8
    mov ecx, eax

    cld

    rep movsb ;; Move (ECX) ESI characters to buffer

.success:

;; Save buffer at position indicated by ESI

    pop esi ;; Save ESI

    push esi

    mov edi, esi

;; Correct address with segment base (physical address = address + segment base)

    add edi, 500h

    mov esi, .filenameBuffer
    mov ecx, 11

    cld

    rep movsb ;; Move (ECX) characters from buffer to ESI

    clc ;; Clear Carry

    jmp .end

.invalidFilename:

    stc ;; Set Carry

.end:

    pop esi
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax

    ret

.filenameBuffer: times 11 db ' '

;;************************************************************************************

;; Rename an existing file on volume
;;
;; Input:
;;
;; ESI - Source filename
;; EDI - Destination filename
;;
;; Output:
;;
;; CF set on error or cleared on success

Hexagon.Kernel.FS.FAT16.renameFileFAT16B:

    pushad

    clc

;; Resolve the source path once. The current directory stays parked at its
;; parent for the whole operation, restored at the end

    mov eax, dword[Hexagon.VFS.FAT16B.currentDirLBA]
    mov dword[.savedDirLBA], eax
    mov eax, dword[stackIndex]
    mov dword[.savedStackIndex], eax

    push edi ;; Destination path, needed once the source is resolved

    call Hexagon.Kernel.FS.FAT16.resolvePathFAT16B ;; ESI = last path component

    jc .failure

    mov edi, .sourceName
    mov ecx, 13

    cld

    rep movsb

    pop edi ;; Destination path

;; Only the last component of the destination is used; renaming across
;; directories is not supported

    mov byte[.destName], 0

    mov esi, edi

.destComponentLoop:

    call Hexagon.Kernel.FS.FAT16.nextPathComponent

    jnc .destCopy

    cmp eax, 0
    je .destComponentDone ;; Destination path simply ended

    jmp .failure ;; A component was too long to be valid

.destCopy:

    push esi

    mov esi, edi
    mov edi, .destName
    mov ecx, 13

    cld

    rep movsb

    pop esi

    jmp .destComponentLoop

.destComponentDone:

;; Check if the source file exists

    mov esi, .sourceName

    call Hexagon.Kernel.FS.FAT16.fileExistsFAT16B

    jc .failure

    push ebx ;; Source entry pointer

    mov esi, .destName

    call Hexagon.Kernel.FS.FAT16.fileExistsFAT16B

    pop ebx

    jnc .failure

    push ebx

    mov esi, .destName

    call Hexagon.Kernel.FS.FAT16.filenameToFATName

    pop ebx

;; In EBX, the pointer to the entry in the root directory

    mov edi, ebx

;; Correct address with segment base (physical address = address + segment base)

    add edi, 500h

    mov ecx, 11

    rep movsb ;; Move (ECX) times string in ESI to EDI

;; Write modified root directory to volume

    call Hexagon.Kernel.FS.FAT16.getCurrentDirGeometry ;; EAX = sectors to write
    mov esi, dword[Hexagon.VFS.FAT16B.currentDirLBA] ;; LBA of the root directory
    mov cx, 50h ;; Segment
    mov edi, Hexagon.Heap.DiskCache + 20000 ;; Offset
    mov dl, byte[Hexagon.Dev.Gen.Disk.Control.currentDisk]

    call Hexagon.Kernel.Dev.i386.Disk.Disk.writeSectors

    jc .failure

.end:

;; Restore the directory we were in before resolving the path

    mov eax, dword[.savedDirLBA]
    mov dword[Hexagon.VFS.FAT16B.currentDirLBA], eax
    mov eax, dword[.savedStackIndex]
    mov dword[stackIndex], eax

    popad

    ret

.failure:

    stc ;; Set Carry

    jmp .end

.sourceName:       times 13 db 0
.destName:         times 13 db 0
.savedDirLBA:      dd 0
.savedStackIndex:  dd 0

;;************************************************************************************

;; Check if a file exists on the volume
;;
;; Input:
;;
;; ESI - Filename to check
;;
;; Output:
;;
;; EAX - File size in bytes
;; EBX - Pointer to entry in the root directory
;; CF defined if the file does not exist or has an invalid name

Hexagon.Kernel.FS.FAT16.fileExistsFAT16B:

    push ecx
    push edx
    push edi
    push esi

    mov eax, dword[Hexagon.VFS.FAT16B.currentDirLBA]
    mov dword[.savedDirLBA], eax
    mov eax, dword[stackIndex]
    mov dword[.savedStackIndex], eax

    call Hexagon.Kernel.FS.FAT16.resolvePathFAT16B ;; ESI = last path component

    jc .failure

    call Hexagon.Libkern.String.stringSize

    cmp eax, 12
    ja .failure ;; In case of invalid filename

    inc eax ;; Filename including 0

;; Copy file name to temporary buffer

    mov edi, .filenameBuffer + 500h
    mov ecx, eax ;; Filename size

    cld

    rep movsb ;; Move (ECX) string in ESI to EDI

;; Make name compatible with FAT

    mov esi, .filenameBuffer

    call Hexagon.Kernel.FS.FAT16.filenameToFATName

    jc .failure ;; In case of invalid filename

;; Load root directory to volume

    call Hexagon.Kernel.FS.FAT16.getCurrentDirGeometry ;; EAX = sectors to read
    mov esi, dword[Hexagon.VFS.FAT16B.currentDirLBA] ;; LBA of the root directory
    mov cx, 50h ;; Segment
    mov edi, Hexagon.Heap.DiskCache + 20000 ;; Offset
    mov dl, byte[Hexagon.Dev.Gen.Disk.Control.currentDisk]

    call Hexagon.Kernel.Dev.i386.Disk.Disk.readSectors

;; Search name in all entries

    call Hexagon.Kernel.FS.FAT16.getCurrentDirGeometry ;; ECX = total folders or files
    mov edx, ecx
    mov ebx, Hexagon.Heap.DiskCache + 500h + 20000

    cld ;; Clear direction flag

.findFileLoop:

    mov ecx, 11 ;; 11 characters in file name
    mov edi, ebx
    mov esi, .filenameBuffer

    rep cmpsb ;; Compares (ECX) characters between EDI and ESI

    je .fileFound

    add ebx, 32

    dec edx

    jnz .findFileLoop

    jmp .failure ;; File not found

.fileFound:

    mov eax, dword[es:ebx+28] ;; File size

;; Correct address with segment base (physical address = address + segment base)

    sub ebx, 500h ;; ES segment

.operationSuccess:

    clc ;; Clear Carry

    jmp .end

.failure:

    stc ;; Set Carry

    jmp .end

.end:

;; Restore the directory we were in before resolving the path, since a
;; simple existence check must not move the shell's current directory

    mov eax, dword[.savedDirLBA]
    mov dword[Hexagon.VFS.FAT16B.currentDirLBA], eax
    mov eax, dword[.savedStackIndex]
    mov dword[stackIndex], eax

    pop esi
    pop edi
    pop edx
    pop ecx

    ret

.filenameBuffer:    times 13 db ' '
.savedDirLBA:       dd 0
.savedStackIndex:   dd 0

;;************************************************************************************

;; Load file into memory
;;
;; Input:
;;
;; ESI - Name of the file to load
;; EDI - Address of the file to be loaded
;;
;; Output:
;;
;; EAX - File size in bytes
;; CF defined in case of file not found or invalid name

Hexagon.Kernel.FS.FAT16.loadFileFAT16B:

    push ebx
    push ecx
    push edx
    push edi
    push esi

    mov dword[.loadAddress], edi

;; Check if the file exists and get the first cluster of it

    call Hexagon.Kernel.FS.FAT16.fileExistsFAT16B

    jc .failure

    mov [.fileSize], eax ;; Save file size

    mov ax, word[ebx+26]   ;; EBX is the pointer to the entry in the root directory
    mov word[.cluster], ax ;; Save the first cluster

;; Load FAT from volume to get file clusters

    movzx eax, word[Hexagon.VFS.FAT16B.sectorsPerFAT] ;; Sectors to read
    mov esi, dword[Hexagon.VFS.FAT16B.FAT] ;; FAT LBA
    mov ecx, 50h ;; Segment
    mov edi, Hexagon.Heap.DiskCache + 20000 ;; Offset

    mov dl, byte[Hexagon.Dev.Gen.Disk.Control.currentDisk]

    call Hexagon.Kernel.Dev.i386.Disk.Disk.readSectors

    mov ebp, dword[Hexagon.VFS.FAT16B.clusterSize] ;; Save cluster size
    mov cx,  00h ;; Real mode segment
    mov edi, dword[.loadAddress] ;; Offset

;; Find cluster and load cluster chain

.loopLoadClusters:

;; Convert logical address (cluster) to LBA (physical address)
;;
;; Formula:
;;
;;((cluster - 2) * sectorsPerCluster) + dataArea

    movzx esi, word[.cluster]

    sub esi, 2

    movzx eax, byte[Hexagon.VFS.FAT16B.sectorsPerCluster]

    xor edx, edx ;; DX = 0

    mul esi ;; (cluster - 2) * sectorsPerCluster

    mov esi, eax

    add esi, dword[Hexagon.VFS.FAT16B.dataArea]

    movzx ax, byte[Hexagon.VFS.FAT16B.sectorsPerCluster] ;; Total sectors to load

    mov dl, byte[Hexagon.Dev.Gen.Disk.Control.currentDisk]

;; Load the cluster into a temporary buffer

    push edi

;; Correct address with segment base (physical address = address + segment base)

    mov edi, Hexagon.Heap.DiskCache + 500h

    call Hexagon.Kernel.Dev.i386.Disk.Disk.readSectors

    pop edi

;; Copy the cluster to its original location

    push edi

;; Correct address with segment base (physical address = address + segment base)

    add edi, 500h

    mov esi, Hexagon.Heap.DiskCache
    mov ecx, ebp ;; EBP has the bytes per sector

    cld

    rep movsb ;; Move (ECX) bytes from ESI to EDI

    pop edi

;; Get next cluster in FAT table

    movzx ebx, word[.cluster]

    shl ebx, 1 ;; BX * 2 (2 bytes on entry)

    add ebx, Hexagon.Heap.DiskCache + 20000 ;; FAT location

    mov si, word[ebx] ;; SI contains the next cluster

    mov word[.cluster], si ;; Save

;; 0xFFF8 is the end of file marker (End Of File - EOF)

    cmp si, Hexagon.VFS.FAT16B.lastClusterAttribute ;; EOF?
    jae .operationSuccess

;; Add empty space for next cluster

    add edi, ebp ;; EBP contains bytes per cluster

    jmp .loopLoadClusters

.operationSuccess:

    mov eax, [.fileSize]

    clc ;; Clear Carry

    jmp .end

.failure:

    stc ;; Set Carry

    jmp .end

.end:

    pop esi
    pop edi
    pop edx
    pop ecx
    pop ebx

    ret

.cluster      dw 0
.loadAddress: dd 0
.fileSize:    dd 0

;;************************************************************************************

;; Get the list of files in the root directory
;;
;; Input:
;;
;; ESI - Pointer to file list
;; EAX - Total number of files

Hexagon.Kernel.FS.FAT16.listFilesFAT16B:

    clc

    push ebx
    push ecx
    push edx
    push edi

;; Configure directorySize

    call Hexagon.Kernel.FS.FAT16.getCurrentDirGeometry ;; EAX = sectors to read

;; Load root directory

    mov esi, dword[Hexagon.VFS.FAT16B.currentDirLBA] ;; LBA of the root directory
    mov cx, 50h ;; Segment
    mov edi, Hexagon.Heap.DiskCache + 20000 ;; Offset
    mov dl, byte[Hexagon.Dev.Gen.Disk.Control.currentDisk]

    call Hexagon.Kernel.Dev.i386.Disk.Disk.readSectors

    jc .listError

;; Build the list
;; Correct address with segment base (physical address = address + segment base)

    mov edx, Hexagon.Heap.DiskCache + 500h ;; Index in new list
    mov ebx, 0 ;; File counter
    mov esi, Hexagon.Heap.DiskCache + 20000 ;; Offset in the root directory

    sub esi, 32

.buildListLoop:

    add esi, 32 ;; Next entry (32 bytes per entry)

    mov byte[.separatorConfig], Hexagon.VFS.FAT16B.filenameSeparator

;; Let's check some attributes of the entry, such as whether it is a directory or a volume label.
;; For now, if we are talking about these entries, we will skip until the support is completed.

    mov al, byte[esi+11] ;; File attributes

    bt ax, Hexagon.VFS.FAT16B.directoryBit ;; If subdirectory, mark as subdirectory
    jc .markAsSubdirectory

    bt ax, Hexagon.VFS.FAT16B.volumeNameBit ;; If volume label, skip
    jc .buildListLoop

;; Now let's get more information about the entry

    cmp byte[esi+11], Hexagon.VFS.FAT16B.longFilenameAttribute ;; If long filename, skip
    je .buildListLoop

    cmp byte[esi], Hexagon.VFS.FAT16B.unlinkedAttribute ;; If file deleted, skip
    je .buildListLoop

;; Check for current directory '.' and skip it

    mov al, byte[esi]
    cmp al, '.'
    je .buildListLoop ;; Skip if it is '.' (current directory)

;; If this is the last file, we don't want to look any further in the directory for something
;; that doesn't exist ;-)

    cmp byte[esi], 0   ;; If last file, finish
    je .finishList

    jmp .continueProcessing

.markAsSubdirectory:

    mov byte[.separatorConfig], Hexagon.VFS.FAT16B.directorySeparator

.continueProcessing:

    call Hexagon.Kernel.FS.FAT16.FATnameToFilename ;; Convert name to 8.3 format

;; Add filename entry to list

    call Hexagon.Libkern.String.trimString

    call Hexagon.Libkern.String.stringSize ;; Find entry size

    cmp eax, 0
    je .buildListLoop

    push esi

    mov edi, edx
    mov ecx, eax ;; EAX is the size of the first string

    rep movsb ;; Move (ECX) bytes from ESI to EDI

    pop esi

;; Add a separator between filenames, useful for list manipulation

    push ebx

    mov bh, [.separatorConfig]

    mov byte[es:edx+eax], bh

    pop ebx

    inc eax ;; String size + 1 character
    inc ebx ;; Update file counter

    add edx, eax ;; Update index in list

    jmp .buildListLoop ;; Get next files

.finishList:

;; Correct address with segment base (physical address = address + segment base)

    mov byte[edx-500h], 0 ;; End of string

    mov esi, Hexagon.Heap.DiskCache
    mov eax, ebx

    jmp .end

.listError:

    stc

.end:

    pop edi
    pop edx
    pop ecx
    pop ebx

    ret

.separatorConfig: db 0

;;************************************************************************************

;; Save file to volume
;;
;; Input:
;;
;; ESI - Pointer to filename
;; EDI - Pointer to data
;; EAX - File size (in bytes)
;;
;; Output:
;;
;; CF defined in case of error or already existing file

Hexagon.Kernel.FS.FAT16.saveFileFAT16B:

    push eax
    push ebx
    push ecx
    push edx
    push edi
    push esi

    mov ebp, edi ;; Save EDI
    mov dword[.fileSize], eax ;; Save file size

;; Resolve the path once. The current directory stays parked at the parent
;; directory for the whole operation, restored at the end

    mov eax, dword[Hexagon.VFS.FAT16B.currentDirLBA]
    mov dword[.savedDirLBA], eax
    mov eax, dword[stackIndex]
    mov dword[.savedStackIndex], eax

    call Hexagon.Kernel.FS.FAT16.resolvePathFAT16B ;; ESI = last path component

    jc .failure

    mov edi, .resolvedName
    mov ecx, 13

    cld

    rep movsb

;; Create new file

    mov esi, .resolvedName

    call Hexagon.Kernel.FS.FAT16.createEmptyFileFAT16B

    jc .failure ;; If file already exists, return

;; Load FAT from volume

    movzx eax, word[Hexagon.VFS.FAT16B.sectorsPerFAT] ;; Sectors to read
    mov esi, dword[Hexagon.VFS.FAT16B.FAT] ;; LBA of the root directory
    mov ecx, 50h ;; Segment
    mov edi, Hexagon.Heap.DiskCache + 20000 ;; Offset

    mov dl, byte[Hexagon.Dev.Gen.Disk.Control.currentDisk]

    call Hexagon.Kernel.Dev.i386.Disk.Disk.readSectors

;; Calculate number of clusters needed
;;
;; Formula:
;;
;; Number required = .fileSize / sizeCluster

    mov eax, dword[.fileSize]
    mov ebx, dword[Hexagon.VFS.FAT16B.clusterSize]
    mov edx, 0

    div ebx ;; .fileSize / clusterSize

    inc eax

    mov dword[.clustersRequired], eax

    mov ecx, eax ;; Loop counter

    mov esi, Hexagon.Heap.DiskCache + 20000

    add esi, (3*2) ;; Reserved clusters

    mov edx, 3 ;; Logical cluster counter
    mov edi, Hexagon.Heap.DiskCache + 500h ;; Pointer to the list of free clusters
    mov eax, 0

;; Get list of FAT free clusters

.findFreeClustersLoop:

    mov ax, word[esi] ;; Load FAT input

    or ax, ax ;; Compare AX with 0
    jz .freeClusterFound

    add esi, 2 ;; FAT next entry

    inc edx

    jmp .findFreeClustersLoop

.freeClusterFound:

;; Store free clusters in a list

    mov word[esi], 0xFFFF

    mov ax, dx

    stosw ;; mov word[ES:EDI], AX & add EDI, 2

    loop .findFreeClustersLoop

    movzx edx, word[Hexagon.Heap.DiskCache]

    push edx ;; Free cluster

;; Everything requires a list of free clusters

;; Create cluster chain in FAT

    mov ecx, dword[.clustersRequired]
    mov esi, Hexagon.Heap.DiskCache ;; List of free clusters (words)

.createClusterChain:

    mov dx, word[esi] ;; Current cluster

    mov edi, Hexagon.Heap.DiskCache + 20000 ;; FAT address
    shl dx, 1 ;; Multiply by 2

    add di, dx ;; EDI is the pointer of the current FAT entry

    cmp ecx, 1 ;; Done
    je .clusterChainReady

    mov ax, word[esi+2] ;; Next cluster
    mov word[edi], ax ;; Save next FAT table cluster

    add esi, 2 ;; Next free cluster

    loop .createClusterChain

.clusterChainReady:

    mov word[edi], 0xFFFF ;; 0xFFFF indicates last cluster

;; Write FAT table to volume

    movzx eax, word[Hexagon.VFS.FAT16B.sectorsPerFAT] ;; Sectors to write
    mov esi, dword[Hexagon.VFS.FAT16B.FAT] ;; LBA of the root directory
    mov ecx, 50h ;; Segment
    mov edi, Hexagon.Heap.DiskCache + 20000 ;; Offset

    mov dl, byte[Hexagon.Dev.Gen.Disk.Control.currentDisk]

    call Hexagon.Kernel.Dev.i386.Disk.Disk.writeSectors

    pop ecx ;; Free cluster

;; Get entry into root directory

    mov esi, .resolvedName

    call Hexagon.Kernel.FS.FAT16.fileExistsFAT16B

    jc .failure

;; EBX is a pointer to the entry in the root directory

    mov eax, dword[.fileSize]
    mov dword[ebx+28], eax ;; Size
    mov word[ebx+26], cx ;; First sector

;; Write modified root directory to volume

    call Hexagon.Kernel.FS.FAT16.getCurrentDirGeometry ;; EAX = sectors to write
    mov esi, dword[Hexagon.VFS.FAT16B.currentDirLBA] ;; LBA of the root directory
    mov cx, 50h ;; Segment
    mov edi, Hexagon.Heap.DiskCache + 20000 ;; Offset
    mov dl, byte[Hexagon.Dev.Gen.Disk.Control.currentDisk]

    call Hexagon.Kernel.Dev.i386.Disk.Disk.writeSectors

;; Save data to free clusters

    mov ebx, Hexagon.Heap.DiskCache ;; Free cluster list
    movzx ecx, word[.clustersRequired]

;; Convert logical address (cluster) to LBA
;;
;; Formula:
;;
;; ((cluster - 2) * sectorsPerCluster) + dataArea

.writeDataToClusters:

    push ecx

;; Copy current data to a temporary buffer

    mov esi, ebp
    mov edi, Hexagon.Heap.DiskCache + 500h + 20000
    mov ecx, dword[Hexagon.VFS.FAT16B.clusterSize]

    rep movsb

    movzx esi, word[ebx]

    sub esi, 2

    movzx eax, byte[Hexagon.VFS.FAT16B.sectorsPerCluster]
    xor edx, edx ;; DX = 0

    mul esi ;; (cluster - 2) * sectorsPerCluster

    mov esi, eax

    add esi, dword[Hexagon.VFS.FAT16B.dataArea]

    movzx ax, byte[Hexagon.VFS.FAT16B.sectorsPerCluster] ;; Total sectors to write

    mov dl, byte[Hexagon.Dev.Gen.Disk.Control.currentDisk]

;; Write temporary buffer

    mov edi, Hexagon.Heap.DiskCache + 500h + 20000
    mov ecx, 0 ;; Real mode segment

    call Hexagon.Kernel.Dev.i386.Disk.Disk.writeSectors

    pop ecx

    add ebp, dword[Hexagon.VFS.FAT16B.clusterSize] ;; Next data block
    add ebx, 2 ;; Next free cluster

    loop .writeDataToClusters

.operationSuccess:

    clc ;; Clear Carry

    jmp .end

.failure:

    stc ;; Set Carry

    jmp .end

.end:

;; Restore the directory we were in before resolving the path

    mov eax, dword[.savedDirLBA]
    mov dword[Hexagon.VFS.FAT16B.currentDirLBA], eax
    mov eax, dword[.savedStackIndex]
    mov dword[stackIndex], eax

    pop esi
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax

    ret

.fileSize:         dd 0
.clustersRequired: dd 0
.resolvedName:     times 13 db 0
.savedDirLBA:      dd 0
.savedStackIndex:  dd 0

;;************************************************************************************

;; Unlink a file from volume
;;
;; Input:
;;
;; ESI - Pointer to filename

Hexagon.Kernel.FS.FAT16.unlinkFileFAT16B:

    pushad

;; Resolve the path once. The current directory stays parked at the parent
;; directory for the whole operation, restored at the end

    mov eax, dword[Hexagon.VFS.FAT16B.currentDirLBA]
    mov dword[.savedDirLBA], eax
    mov eax, dword[stackIndex]
    mov dword[.savedStackIndex], eax

    call Hexagon.Kernel.FS.FAT16.resolvePathFAT16B ;; ESI = last path component

    jc .end

    mov edi, .resolvedName
    mov ecx, 13

    cld

    rep movsb

    mov esi, .resolvedName

    call Hexagon.Kernel.FS.FAT16.fileExistsFAT16B

    jc .end

;; The root directory entry is already loaded, due to Hexagon.Kernel.FS.FAT16.fileExistsFAT16B

    mov ax, word[ebx+26] ;; Get first cluster
    mov word[.cluster], ax ;; Save

;; Mark the file as deleted

    mov byte[ebx], Hexagon.VFS.FAT16B.unlinkedAttribute

;; Write modified root directory to volume

    call Hexagon.Kernel.FS.FAT16.getCurrentDirGeometry ;; EAX = sectors to write
    mov esi, dword[Hexagon.VFS.FAT16B.currentDirLBA] ;; LBA of the root directory
    mov cx, 50h ;; Segment
    mov edi, Hexagon.Heap.DiskCache + 20000 ;; Offset
    mov dl, byte[Hexagon.Dev.Gen.Disk.Control.currentDisk]

    call Hexagon.Kernel.Dev.i386.Disk.Disk.writeSectors

;; Clear clusters allocated to the file in FAT

;; Load FAT to volume

    movzx eax, word[Hexagon.VFS.FAT16B.sectorsPerFAT] ;; Sectors to read
    mov esi, dword[Hexagon.VFS.FAT16B.FAT] ;; FAT LBA
    mov ecx, 50h ;; Segment
    mov edi, Hexagon.Heap.DiskCache + 20000 ;; Offset

    mov dl, byte[Hexagon.Dev.Gen.Disk.Control.currentDisk]

    call Hexagon.Kernel.Dev.i386.Disk.Disk.readSectors

.nextCluster:

;; Calcular próximo cluster

    mov edi, Hexagon.Heap.DiskCache + 20000 ;; FAT table
    movzx esi, word[.cluster]
    shl esi, 1 ;; Multiply by 2

    add edi, esi

    mov ax, word[edi]

    mov word[.cluster], ax

    mov word[edi], 0 ;; Mark cluster as free

    cmp ax, Hexagon.VFS.FAT16B.lastClusterAttribute ;; 0xFFF8 is end of file marker (EOF)
    jae .allClustersDeleted

    jmp .nextCluster

.allClustersDeleted:

;; Write FAT to volume

    movzx eax, word[Hexagon.VFS.FAT16B.sectorsPerFAT] ;; Sectors to write
    mov esi, dword[Hexagon.VFS.FAT16B.FAT] ;; FAT LAB
    mov ecx, 50h ;; Segment
    mov edi, Hexagon.Heap.DiskCache + 20000 ;; Offset

    mov dl, byte[Hexagon.Dev.Gen.Disk.Control.currentDisk]

    call Hexagon.Kernel.Dev.i386.Disk.Disk.writeSectors

.end:

;; Restore the directory we were in before resolving the path

    mov eax, dword[.savedDirLBA]
    mov dword[Hexagon.VFS.FAT16B.currentDirLBA], eax
    mov eax, dword[.savedStackIndex]
    mov dword[stackIndex], eax

    popad

    ret

.cluster:          dw 0
.resolvedName:     times 13 db 0
.savedDirLBA:      dd 0
.savedStackIndex:  dd 0

;;************************************************************************************

Hexagon.Kernel.FS.FAT16.getFilesystemInfoFAT16B:

    mov ax, word[es:esi+8] ;; Bytes per sector
    mov word[Hexagon.VFS.FAT16B.bytesPerSector], ax

    mov al, byte[es:esi+10] ;; Sectors per cluster
    mov byte[Hexagon.VFS.FAT16B.sectorsPerCluster], al

    mov ax, word[es:esi+11] ;; Reserved sectors
    mov word[Hexagon.VFS.FAT16B.reservedSectors], ax

    mov al, byte[es:esi+13] ;; Number of FAT tables
    mov byte[Hexagon.VFS.FAT16B.totalFATs], al

    mov ax, word[es:esi+14] ;; Entries in the root directory
    mov word[Hexagon.VFS.FAT16B.rootEntries], ax

    mov ax, word[es:esi+19] ;; Sectors per FAT
    mov word[Hexagon.VFS.FAT16B.sectorsPerFAT], ax

    mov eax, dword[es:esi+29] ;; Total sectors
    mov dword[Hexagon.VFS.FAT16B.totalSectors], eax

    mov eax, dword[es:esi+36] ;; Volume serial
    mov dword[Hexagon.VFS.Control.volumeSerial], eax

    mov byte[Hexagon.VFS.Control.volumeSerial+4], 0

;; Calculate root directory size
;;
;; Formula:
;;
;; Size = (root entries * 32) / bytesPerSector

    mov ax, word[Hexagon.VFS.FAT16B.rootEntries]
    shl ax, 5 ;; Multiply by 32
    mov bx, word[Hexagon.VFS.FAT16B.bytesPerSector]
    xor dx, dx ;; DX = 0

    div bx ;; AX = AX / BX

    mov word[Hexagon.VFS.FAT16B.rootDirSize], ax ;; Save root directory size

;; Calculate size of all FAT tables
;;
;; Formula:
;;
;; Size = totalFATs * sectorsPerFAT

    mov ax, word[Hexagon.VFS.FAT16B.sectorsPerFAT]
    movzx bx, byte[Hexagon.VFS.FAT16B.totalFATs]
    xor dx, dx ;; DX = 0

    mul bx ;; AX = AX * BX

    mov word[Hexagon.VFS.FAT16B.sizeFATs], ax ;; Save size of FAT(s)

;; Calculate data area address
;;
;; Formula:
;;
;; reservedSectors + sizeFATs + rootDirSize

    movzx eax, word[Hexagon.VFS.FAT16B.reservedSectors]

    add ax, word[Hexagon.VFS.FAT16B.sizeFATs]
    add ax, word[Hexagon.VFS.FAT16B.rootDirSize]

    mov dword[Hexagon.VFS.FAT16B.dataArea], eax

;; Calculate LBA address of root directory
;;
;; Formula:
;;
;; LBA = reservedSectors + sizeFATs

    movzx esi, word[Hexagon.VFS.FAT16B.reservedSectors]
    add si, word[Hexagon.VFS.FAT16B.sizeFATs]
    mov dword[Hexagon.VFS.FAT16B.rootDir], esi
    mov dword[Hexagon.VFS.FAT16B.prevDirLBA], esi
    mov dword[Hexagon.VFS.FAT16B.currentDirLBA], esi

;; Calculate LBA address from FAT table
;;
;; Formula:
;;
;; LBA = reservedSectors

    movzx esi, word[Hexagon.VFS.FAT16B.reservedSectors]
    mov dword[Hexagon.VFS.FAT16B.FAT], esi

;; Calculate cluster size in bytes
;;
;; Formula:
;;
;; sectorsByCluster * bytesBySector

    movzx eax, byte[Hexagon.VFS.FAT16B.sectorsPerCluster]
    movzx ebx, word[Hexagon.VFS.FAT16B.bytesPerSector]
    xor edx, edx

    mul ebx ;; AX = AX * BX

    mov dword[Hexagon.VFS.FAT16B.clusterSize], eax

    ret

;;************************************************************************************

Hexagon.Kernel.FS.FAT16.getVolumeLabelFAT16B:

    mov ebx, dword[Hexagon.Dev.Gen.Disk.Control.diskGeometry]

;; Get the label of the volume used

    mov eax, dword[ebx+43] ;; Volume label
    mov dword[Hexagon.VFS.Control.volumeLabel], eax

    mov eax, dword[ebx+47] ;; Volume label
    mov dword[Hexagon.VFS.Control.volumeLabel+4], eax

    mov eax, dword[ebx+51] ;; Volume label
    mov dword[Hexagon.VFS.Control.volumeLabel+8], eax

;; Now we must finish the volume label string

    mov byte[Hexagon.VFS.Control.volumeLabel+11], 0

    ret

;;************************************************************************************

;; Create new empty file
;;
;; Input:
;;
;; ESI - Pointer to filename
;;
;; Output:
;;
;; EDI - Pointer to entry in the root directory
;; CF defined if file already exists

Hexagon.Kernel.FS.FAT16.createEmptyFileFAT16B:

    pushad

    mov eax, dword[Hexagon.VFS.FAT16B.currentDirLBA]
    mov dword[.savedDirLBA], eax
    mov eax, dword[stackIndex]
    mov dword[.savedStackIndex], eax

;; Check if the file already exists

    call Hexagon.Kernel.FS.FAT16.fileExistsFAT16B

    jnc .failure

;; Resolve the path. The current directory stays parked at the parent
;; directory for the rest of the operation, restored at the end

    call Hexagon.Kernel.FS.FAT16.resolvePathFAT16B ;; ESI = last path component

    jc .failure

    call Hexagon.Libkern.String.stringSize

    cmp eax, 12
    ja .failure ;; In case of invalid filename

    inc eax ;; Filename including 0

;; Copy filename to a temporary buffer

    mov edi, .filenameBuffer + 500h
    mov ecx, eax ;; Filename size

    cld

    rep movsb ;; Move (ECX) times string in ESI to EDI

;; Convert to FAT compatible filename

    mov esi, .filenameBuffer

    call Hexagon.Kernel.FS.FAT16.filenameToFATName

    jc .failure ;; In case of invalid filename

    push esi

;; Load root directory from volume

    call Hexagon.Kernel.FS.FAT16.getCurrentDirGeometry ;; EAX = sectors to read
    mov esi, dword[Hexagon.VFS.FAT16B.currentDirLBA] ;; LBA of root directory
    mov cx, 50h ;; Segment
    mov edi, Hexagon.Heap.DiskCache + 20000 ;; Offset
    mov dl, byte[Hexagon.Dev.Gen.Disk.Control.currentDisk]

    call Hexagon.Kernel.Dev.i386.Disk.Disk.readSectors

    mov edi, Hexagon.Heap.DiskCache + 20000

    call Hexagon.Kernel.FS.FAT16.getCurrentDirGeometry ;; ECX = total entries

;; Search for empty entry in root directory

.findFreeEntryLoop:

    cmp byte[edi], Hexagon.VFS.FAT16B.unlinkedAttribute ;; File deleted
    je .emptyEntryFound

    cmp byte[edi], 0 ;; Empty entry
    je .emptyEntryFound

    add edi, 32

    loop .findFreeEntryLoop

.emptyEntryNotFound:

    jmp .failure

.emptyEntryFound:

;; Copy filename to root directory buffer

    pop esi ;; Restore ESI

    mov ecx, 11 ;; Filename size

    push edi

;; Correct address with segment base (physical address = address + segment base)

    add edi, 500h ;; ES segment

    rep movsb ;; Move (ECX) bytes from ESI to EDI

    pop edi ;; Restore EDI

    push edi

;; Clear other fields of the file entry in the root directory, starting from the filename

    add edi, 500h + 11 ;; Skip to end of filename
    mov ecx, 32 - 11   ;; Do this for 32 bytes of input minus the first 11 of the name
    mov al, 0

    cld

    rep stosb ;; mov AL in (ECX) EDI bytes

;; Write modified root directory to volume

    call Hexagon.Kernel.FS.FAT16.getCurrentDirGeometry ;; EAX = sectors to write
    mov esi, dword[Hexagon.VFS.FAT16B.currentDirLBA] ;; LBA of the root directory
    mov cx, 50h ;; Segment
    mov edi, Hexagon.Heap.DiskCache + 20000 ;; Offset
    mov dl, byte[Hexagon.Dev.Gen.Disk.Control.currentDisk]

    call Hexagon.Kernel.Dev.i386.Disk.Disk.writeSectors

    pop esi ;; Pointer to root directory entry

.operationSuccess:

    clc ;; Clear Carry

    jmp .end

.failure:

    stc ;; Set Carry

    jmp .end

.end:

;; Restore the directory we were in before resolving the path

    mov eax, dword[.savedDirLBA]
    mov dword[Hexagon.VFS.FAT16B.currentDirLBA], eax
    mov eax, dword[.savedStackIndex]
    mov dword[stackIndex], eax

    popad

    ret

.filenameBuffer:   times 13 db ' '
.savedDirLBA:      dd 0
.savedStackIndex:  dd 0

;;************************************************************************************

;; Create a new, empty directory
;;
;; Input:
;;
;; ESI - Path of the directory to create
;;
;; Output:
;;
;; CF set if the name already exists, an intermediate path component is
;; invalid, or there is no free cluster left for the new directory

Hexagon.Kernel.FS.FAT16.createDirectoryFAT16B:

    pushad

    mov eax, dword[Hexagon.VFS.FAT16B.currentDirLBA]
    mov dword[.savedDirLBA], eax
    mov eax, dword[stackIndex]
    mov dword[.savedStackIndex], eax

;; Check if a file or directory with this name already exists

    call Hexagon.Kernel.FS.FAT16.fileExistsFAT16B

    jnc .failure

;; Resolve the path down to the parent directory

    call Hexagon.Kernel.FS.FAT16.resolvePathFAT16B ;; ESI = last path component

    jc .failure

    mov edi, .dirName
    mov ecx, 13

    cld

    rep movsb

;; Remember the parent's own cluster number now, needed for the new
;; directory's ".." entry. 0 means the parent is the root directory

    mov eax, dword[Hexagon.VFS.FAT16B.currentDirLBA]

    cmp eax, dword[Hexagon.VFS.FAT16B.rootDir]
    je .parentIsRoot

    sub eax, dword[Hexagon.VFS.FAT16B.dataArea]

    xor edx, edx
    movzx ebx, byte[Hexagon.VFS.FAT16B.sectorsPerCluster]

    div ebx ;; EAX = (LBA - dataArea) / sectorsPerCluster

    add eax, 2 ;; Data clusters begin at cluster 2

    jmp .parentClusterReady

.parentIsRoot:

    xor eax, eax

.parentClusterReady:

    mov dword[.parentCluster], eax

;; Create the entry itself, as an empty file for now

    mov esi, .dirName

    call Hexagon.Kernel.FS.FAT16.createEmptyFileFAT16B

    jc .failure

;; Find a free cluster in the FAT for the new directory's own content

    movzx eax, word[Hexagon.VFS.FAT16B.sectorsPerFAT] ;; Sectors to read
    mov esi, dword[Hexagon.VFS.FAT16B.FAT] ;; FAT LBA
    mov ecx, 50h ;; Segment
    mov edi, Hexagon.Heap.DiskCache + 20000 ;; Offset
    mov dl, byte[Hexagon.Dev.Gen.Disk.Control.currentDisk]

    call Hexagon.Kernel.Dev.i386.Disk.Disk.readSectors

    mov esi, Hexagon.Heap.DiskCache + 20000

    add esi, (3*2) ;; Reserved clusters

    mov edx, 3 ;; Logical cluster counter

.findFreeClusterLoop:

    mov ax, word[esi]

    or ax, ax
    jz .freeClusterFound

    add esi, 2
    inc edx

    jmp .findFreeClusterLoop

.freeClusterFound:

    mov word[esi], 0xFFFF ;; The new directory is a single cluster

    mov dword[.newCluster], edx

;; Write the FAT back with the new cluster marked

    movzx eax, word[Hexagon.VFS.FAT16B.sectorsPerFAT] ;; Sectors to write
    mov esi, dword[Hexagon.VFS.FAT16B.FAT] ;; FAT LBA
    mov ecx, 50h ;; Segment
    mov edi, Hexagon.Heap.DiskCache + 20000 ;; Offset
    mov dl, byte[Hexagon.Dev.Gen.Disk.Control.currentDisk]

    call Hexagon.Kernel.Dev.i386.Disk.Disk.writeSectors

;; Point the parent's entry at the new cluster and mark it as a directory

    mov esi, .dirName

    call Hexagon.Kernel.FS.FAT16.fileExistsFAT16B

    jc .failure

    mov byte[ebx+11], Hexagon.VFS.FAT16B.directoryAttribute

    mov eax, dword[.newCluster]
    mov word[ebx+26], ax ;; First cluster

;; Write modified parent directory to volume

    call Hexagon.Kernel.FS.FAT16.getCurrentDirGeometry ;; EAX = sectors to write
    mov esi, dword[Hexagon.VFS.FAT16B.currentDirLBA] ;; LBA of the parent directory
    mov cx, 50h ;; Segment
    mov edi, Hexagon.Heap.DiskCache + 20000 ;; Offset
    mov dl, byte[Hexagon.Dev.Gen.Disk.Control.currentDisk]

    call Hexagon.Kernel.Dev.i386.Disk.Disk.writeSectors

;; Build the new cluster's content: "." and ".." entries, the rest zeroed

    mov edi, Hexagon.Heap.DiskCache + 500h + 20000
    mov ecx, dword[Hexagon.VFS.FAT16B.clusterSize]
    mov al, 0

    cld

    rep stosb

    mov edi, Hexagon.Heap.DiskCache + 500h + 20000
    mov esi, .dotEntry
    mov ecx, 11

    rep movsb ;; EDI now at the attribute byte of the "." entry

    mov byte[edi], Hexagon.VFS.FAT16B.directoryAttribute

    mov eax, dword[.newCluster]
    mov word[edi + 15], ax ;; First cluster (offset 26, 11 already consumed)

    mov edi, Hexagon.Heap.DiskCache + 500h + 20000 + 32
    mov esi, .dotDotEntry
    mov ecx, 11

    rep movsb ;; EDI now at the attribute byte of the ".." entry

    mov byte[edi], Hexagon.VFS.FAT16B.directoryAttribute

    mov eax, dword[.parentCluster]
    mov word[edi + 15], ax ;; First cluster (0 if the parent is the root)

;; Write the new cluster to disk

    mov eax, dword[.newCluster]

    sub eax, 2

    movzx ebx, byte[Hexagon.VFS.FAT16B.sectorsPerCluster]

    xor edx, edx

    mul ebx ;; EAX = (cluster - 2) * sectorsPerCluster

    add eax, dword[Hexagon.VFS.FAT16B.dataArea]

    mov esi, eax

    movzx ax, byte[Hexagon.VFS.FAT16B.sectorsPerCluster]

    mov edi, Hexagon.Heap.DiskCache + 500h + 20000
    mov ecx, 0 ;; Real mode segment
    mov dl, byte[Hexagon.Dev.Gen.Disk.Control.currentDisk]

    call Hexagon.Kernel.Dev.i386.Disk.Disk.writeSectors

    jc .failure

.operationSuccess:

    clc

    jmp .end

.failure:

    stc

.end:

;; Restore the directory we were in before resolving the path

    mov eax, dword[.savedDirLBA]
    mov dword[Hexagon.VFS.FAT16B.currentDirLBA], eax
    mov eax, dword[.savedStackIndex]
    mov dword[stackIndex], eax

    popad

    ret

.dotEntry:         db ".", " ", " ", " ", " ", " ", " ", " ", " ", " ", " "
.dotDotEntry:      db ".", ".", " ", " ", " ", " ", " ", " ", " ", " ", " "
.dirName:          times 13 db 0
.parentCluster:    dd 0
.newCluster:       dd 0
.savedDirLBA:      dd 0
.savedStackIndex:  dd 0

;;************************************************************************************

;; Remove an empty directory
;;
;; Input:
;;
;; ESI - Path of the directory to remove
;;
;; Output:
;;
;; CF set if the path is invalid, the name isn't a directory, or the
;; directory still has entries other than "." and ".."

Hexagon.Kernel.FS.FAT16.removeDirectoryFAT16B:

    pushad

    mov eax, dword[Hexagon.VFS.FAT16B.currentDirLBA]
    mov dword[.savedDirLBA], eax
    mov eax, dword[stackIndex]
    mov dword[.savedStackIndex], eax

    call Hexagon.Kernel.FS.FAT16.resolvePathFAT16B ;; ESI = last path component

    jc .failure

    mov edi, .dirName
    mov ecx, 13

    cld

    rep movsb

    mov esi, .dirName

    call Hexagon.Kernel.FS.FAT16.fileExistsFAT16B

    jc .failure

    test byte[ebx+11], Hexagon.VFS.FAT16B.directoryAttribute
    jz .failure ;; Not a directory

    mov ax, word[ebx+26]
    mov word[.targetCluster], ax

;; Read the target directory's own cluster to make sure it has nothing in
;; it besides "." and ".."

    movzx eax, word[.targetCluster]

    sub eax, 2

    movzx ebx, byte[Hexagon.VFS.FAT16B.sectorsPerCluster]

    xor edx, edx

    mul ebx ;; EAX = (cluster - 2) * sectorsPerCluster

    add eax, dword[Hexagon.VFS.FAT16B.dataArea]

    mov esi, eax

    movzx ax, byte[Hexagon.VFS.FAT16B.sectorsPerCluster]

    mov cx, 50h ;; Segment
    mov edi, Hexagon.Heap.DiskCache + 20000 ;; Offset
    mov dl, byte[Hexagon.Dev.Gen.Disk.Control.currentDisk]

    call Hexagon.Kernel.Dev.i386.Disk.Disk.readSectors

    mov edi, Hexagon.Heap.DiskCache + 20000

    mov ecx, dword[Hexagon.VFS.FAT16B.clusterSize]
    shr ecx, 5 ;; Entries per cluster

.checkEmptyLoop:

    cmp byte[edi], 0
    je .isEmpty ;; No entry was ever used beyond this point

    cmp byte[edi], Hexagon.VFS.FAT16B.unlinkedAttribute
    je .nextEntry

    cmp byte[edi], '.'
    jne .failure ;; A real name means the directory still has content

.nextEntry:

    add edi, 32

    loop .checkEmptyLoop

.isEmpty:

;; Free the target's cluster in the FAT

    movzx eax, word[Hexagon.VFS.FAT16B.sectorsPerFAT] ;; Sectors to read
    mov esi, dword[Hexagon.VFS.FAT16B.FAT] ;; FAT LBA
    mov ecx, 50h ;; Segment
    mov edi, Hexagon.Heap.DiskCache + 20000 ;; Offset
    mov dl, byte[Hexagon.Dev.Gen.Disk.Control.currentDisk]

    call Hexagon.Kernel.Dev.i386.Disk.Disk.readSectors

    movzx esi, word[.targetCluster]
    shl esi, 1 ;; Multiply by 2

    add esi, Hexagon.Heap.DiskCache + 20000

    mov word[esi], 0 ;; Mark cluster as free

    movzx eax, word[Hexagon.VFS.FAT16B.sectorsPerFAT] ;; Sectors to write
    mov esi, dword[Hexagon.VFS.FAT16B.FAT] ;; FAT LBA
    mov ecx, 50h ;; Segment
    mov edi, Hexagon.Heap.DiskCache + 20000 ;; Offset
    mov dl, byte[Hexagon.Dev.Gen.Disk.Control.currentDisk]

    call Hexagon.Kernel.Dev.i386.Disk.Disk.writeSectors

;; Look up the parent's entry again, since the FAT read above reused the
;; same buffer and the old pointer into it is no longer valid

    mov esi, .dirName

    call Hexagon.Kernel.FS.FAT16.fileExistsFAT16B

    jc .failure

    mov byte[ebx], Hexagon.VFS.FAT16B.unlinkedAttribute

    call Hexagon.Kernel.FS.FAT16.getCurrentDirGeometry ;; EAX = sectors to write
    mov esi, dword[Hexagon.VFS.FAT16B.currentDirLBA] ;; LBA of the parent directory
    mov cx, 50h ;; Segment
    mov edi, Hexagon.Heap.DiskCache + 20000 ;; Offset
    mov dl, byte[Hexagon.Dev.Gen.Disk.Control.currentDisk]

    call Hexagon.Kernel.Dev.i386.Disk.Disk.writeSectors

    jc .failure

.operationSuccess:

    clc

    jmp .end

.failure:

    stc

.end:

;; Restore the directory we were in before resolving the path

    mov eax, dword[.savedDirLBA]
    mov dword[Hexagon.VFS.FAT16B.currentDirLBA], eax
    mov eax, dword[.savedStackIndex]
    mov dword[stackIndex], eax

    popad

    ret

.dirName:          times 13 db 0
.targetCluster:    dw 0
.savedDirLBA:      dd 0
.savedStackIndex:  dd 0

;;************************************************************************************

;; Initialize the volumes

Hexagon.Kernel.FS.FAT16.initVolumeFAT16B:

;; Obtain information from BPB and store system structures

    call Hexagon.Kernel.Dev.i386.Disk.Disk.readBPB

    jc .error

    mov esi, dword[Hexagon.Memory.addressBPB]

    call Hexagon.Kernel.FS.FAT16.getFilesystemInfoFAT16B

    call Hexagon.Kernel.FS.FAT16.getVolumeLabelFAT16B

    clc

    jmp .end

.error:

    stc

.end:

    ret

;;************************************************************************************

;; Changes the actual directory to any supplied path, absolute or relative,
;; possibly with several '/'-separated components
;;
;; Input:
;;
;;  ESI - Path to the directory
;;
;; Output:
;;
;;  CF set if the path is empty or any component doesn't exist or isn't a
;;  directory. On error, the current directory is left unchanged

Hexagon.Kernel.FS.FAT16.changeDirectoryFAT16B:

    push eax
    push ebx
    push ecx
    push edx

;; Save current state in case a component in the middle of the path fails;
;; a "cd" either changes to the whole path or doesn't change anything

    mov eax, dword[Hexagon.VFS.FAT16B.currentDirLBA]
    mov dword[.savedDirLBA], eax
    mov eax, dword[stackIndex]
    mov dword[.savedStackIndex], eax

    cmp byte[esi], 0
    je .invalid ;; Empty path

    cmp byte[esi], '/'
    jne .walkLoop

;; Absolute path: start from the root

    mov eax, dword[Hexagon.VFS.FAT16B.rootDir]
    mov dword[Hexagon.VFS.FAT16B.currentDirLBA], eax
    mov dword[stackIndex], 0

.walkLoop:

    call Hexagon.Kernel.FS.FAT16.nextPathComponent

    jnc .descend

    cmp eax, 0
    je .finished ;; Path simply ended, we are where we need to be

    jmp .rollback ;; A component was too long to be valid

.descend:

    push esi

    mov esi, edi

    call Hexagon.Kernel.FS.FAT16.descendOneComponentFAT16B

    pop esi

    jc .rollback

    jmp .walkLoop

.finished:

    clc

    jmp .end

.rollback:

    mov eax, dword[.savedDirLBA]
    mov dword[Hexagon.VFS.FAT16B.currentDirLBA], eax
    mov eax, dword[.savedStackIndex]
    mov dword[stackIndex], eax

.invalid:

    stc

.end:

    pop edx
    pop ecx
    pop ebx
    pop eax

    ret

.savedDirLBA:      dd 0
.savedStackIndex:  dd 0

;;************************************************************************************

;; Extracts the next '/'-delimited component from a path string. Meant to be
;; called repeatedly with the ESI it returns, until it signals CF
;;
;; Input:
;;
;; ESI - Pointer into the path
;;
;; Output:
;;
;; ESI - Advanced past this component, positioned at the next separator or
;;       at the end of the string
;; EDI - Pointer to a null-terminated buffer holding the component
;; EAX - 0 if the path simply ended, 1 if a component was too long to be
;;       a valid FAT16 name (only meaningful when CF is set)
;; CF set if there was no component left to extract

Hexagon.Kernel.FS.FAT16.nextPathComponent:

    push ecx
    push edx

.skipSeparators:

    cmp byte[esi], '/'
    jne .checkEnd

    inc esi

    jmp .skipSeparators

.checkEnd:

    cmp byte[esi], 0
    je .noComponent

;; Measure the component length

    mov edx, esi

.measureLoop:

    mov al, byte[edx]

    cmp al, 0
    je .measured

    cmp al, '/'
    je .measured

    inc edx

    jmp .measureLoop

.measured:

    mov ecx, edx
    sub ecx, esi ;; ECX = component length

    cmp ecx, 12
    ja .invalidComponent

;; Copy the component to a private buffer

    mov edi, .componentBuffer

    cld

    rep movsb ;; Advances ESI and EDI by ECX bytes

    mov byte[edi], 0 ;; Null terminator

    mov edi, .componentBuffer

    clc

    jmp .end

.invalidComponent:

    mov esi, edx ;; Still advance past the oversized component

    mov eax, 1

    stc

    jmp .end

.noComponent:

    mov eax, 0

    stc

.end:

    pop edx
    pop ecx

    ret

.componentBuffer: times 13 db 0

;;************************************************************************************

;; Walks all but the last component of a path, leaving the current directory
;; positioned at the parent of the target. Does not persist navigation
;; state on its own; callers that must not move the shell's current
;; directory are expected to save and restore Hexagon.VFS.FAT16B.currentDirLBA
;; and stackIndex around this call
;;
;; Input:
;;
;; ESI - Path to resolve (a leading '/' makes it absolute)
;;
;; Output:
;;
;; ESI - Pointer to the last path component (the target name itself)
;; CF set if an intermediate component doesn't exist or isn't a directory,
;; or if the path is empty

Hexagon.Kernel.FS.FAT16.resolvePathFAT16B:

    push ebx
    push ecx
    push edx

    cmp byte[esi], '/'
    jne .fetchFirst

    mov eax, dword[Hexagon.VFS.FAT16B.rootDir]
    mov dword[Hexagon.VFS.FAT16B.currentDirLBA], eax
    mov dword[stackIndex], 0

.fetchFirst:

    call Hexagon.Kernel.FS.FAT16.nextPathComponent

    jc .invalid ;; Empty path has no target

    push esi ;; Save the path cursor

    mov esi, edi
    mov edi, .currentComponent

    call .copy13

    pop esi

.walkLoop:

;; Look ahead: is there another component after .currentComponent?

    call Hexagon.Kernel.FS.FAT16.nextPathComponent

    jnc .haveNext

    cmp eax, 0
    je .targetReady ;; No more components, .currentComponent is the target

    jmp .invalid ;; The next component was too long to be valid

.haveNext:

    push esi

    mov esi, edi
    mov edi, .nextComponent

    call .copy13

    pop esi

;; .currentComponent is an intermediate directory; descend into it

    push esi

    mov esi, .currentComponent

    call Hexagon.Kernel.FS.FAT16.descendOneComponentFAT16B

    pop esi

    jc .invalid

;; The next component becomes the current one

    push esi

    mov esi, .nextComponent
    mov edi, .currentComponent

    call .copy13

    pop esi

    jmp .walkLoop

.targetReady:

    mov esi, .currentComponent

    clc

    jmp .end

.invalid:

    stc

.end:

    pop edx
    pop ecx
    pop ebx

    ret

.copy13:

    push ecx

    mov ecx, 13

    cld

    rep movsb

    pop ecx

    ret

.currentComponent: times 13 db 0
.nextComponent:     times 13 db 0

;;************************************************************************************

;; Descends into a single, already-split directory name (not a full path).
;; Handles "." and ".." as well as a plain name lookup
;;
;; Input:
;;
;;  ESI - Directory name (string, no '/' allowed)
;;
;; Output:
;;
;;   CF set if the name doesn't exist or isn't a directory

Hexagon.Kernel.FS.FAT16.descendOneComponentFAT16B:

    mov [.directoryName], esi

    clc

    mov ebx, esi ;; Directory name
    mov al, [ebx]

    cmp al, '.'
    jne .convertNameToFAT16Entry

    inc ebx

    mov al, [ebx]

    cmp al, '.'
    jne .singleDot

.goToPreviousDirectory:

;; If we reach here, change to previous directory ("..")
;; If already on root directory, return

    mov eax, dword[Hexagon.VFS.FAT16B.currentDirLBA]

    cmp eax, dword[Hexagon.VFS.FAT16B.rootDir]
    je .alreadyAtRoot

;; ".." -> change back to previous directory

    call Hexagon.Kernel.FS.FAT16.popDirectory

    clc

    ret

.convertNameToFAT16Entry:

    mov [.directoryName], esi

    call Hexagon.Kernel.FS.FAT16.filenameToFATName

    jc .changeDirectoryError

.getEntries:

;; Read the sectors of the current directory

    call Hexagon.Kernel.FS.FAT16.getCurrentDirGeometry ;; EAX = sectors, ECX = entries
    push ecx
    mov esi, dword[Hexagon.VFS.FAT16B.currentDirLBA]
    mov ecx, 50h
    mov edi, Hexagon.Heap.DiskCache + 20000
    mov dl, byte[Hexagon.Dev.Gen.Disk.Control.currentDisk]

    call Hexagon.Kernel.Dev.i386.Disk.Disk.readSectors

    mov edi, Hexagon.Heap.DiskCache + 20000
    pop ecx
    xor edx, edx

.checkDirectoryLoop:

    mov esi, [.directoryName]

    call Hexagon.Kernel.FS.FAT16.compareNamesInRootDirectory

    jc .nextEntry

;; If is not a directory, keep searching

    test byte [edi + 11], Hexagon.VFS.FAT16B.directoryAttribute
    jz .nextEntry

;; If found, mark the directory as available

    mov edx, 01h

    jmp .directoryFound

.nextEntry:

    add edi, 32

    loop .checkDirectoryLoop

;; If not found, error

    jmp .changeDirectoryError

.directoryFound:

;; Save current directory address as previous directory address
;; and in directory stack

    push edi
    push esi

    call Hexagon.Kernel.FS.FAT16.pushDirectory

    pop esi
    pop edi

;; If stack is full, we cannot go further

    jc .changeDirectoryError

    mov esi, edi ;; In EDI, the entry

;; In FAT16, only the cluster low (position 26) is important to
;; calculate the directory LBA address

    movzx eax, word[esi + 26] ;; Cluster low

    cmp eax, 00h
    jne .validClusterFotSubdirectory

;; If cluster = 0 -> we are in the root directory or an error occurred.
;; When an error occurred, restore root directory to make system usable.
;; Cluster = 0 also represents the ".." reference for the root directory
;; on a subdirectory in root (example: ".." in "/directory"). Subdirectories
;; created on another subdirectories have ".." referencing the parent directory.

    mov eax, [Hexagon.VFS.FAT16B.rootDir]

    jmp .updateCurrentDir

.validClusterFotSubdirectory:

;; EAX = cluster - 2. In FAT16, data clusters begin in the second cluster.
;; The second cluster is the first fisical area to store data, because clusters
;; 0 and 1 are reserved and not used to store data (like entries in directory)

    sub eax, 2

    movzx ebx, byte[Hexagon.VFS.FAT16B.sectorsPerCluster]

    xor edx, edx

    mul ebx ;; EAX = cluster offset in sectors

    add eax, [Hexagon.VFS.FAT16B.dataArea]  ;; Add the base of the data area

.updateCurrentDir:

;; We now have the LBA address of the directory requested. Change the current
;; directory reference and return

    mov dword[Hexagon.VFS.FAT16B.currentDirLBA], eax

    clc

    ret

.singleDot:

;; When requesting ".", we do not need to do anything but return

    clc

    ret

.alreadyAtRoot:

;; If already on root directory, any request to ".." is invalid

    clc

    ret

.changeDirectoryError:

    stc

    ret

.directoryName: dd 0

;;************************************************************************************

;; Compare FAT16 entry with directory name (in FAT16 format) and determine if
;; are equal or not

Hexagon.Kernel.FS.FAT16.compareNamesInRootDirectory:

    push ecx
    push esi
    push edi

    mov ecx, 11

.loop:

    mov al, [edi]

    cmp al, [esi]
    jne .notEqual

    inc edi
    inc esi

    loop .loop

    pop edi
    pop esi
    pop ecx

    clc

    ret

.notEqual:

    pop edi
    pop esi
    pop ecx

    stc

    ret

;;************************************************************************************

;; Store current directory in stack before changing to a new one

Hexagon.Kernel.FS.FAT16.pushDirectory:

    mov eax, [Hexagon.VFS.FAT16B.currentDirLBA]
    mov ebx, stackIndex  ;; Stack pointer
    mov ecx, [ebx] ;; Load stack index

    cmp ecx, 32  ;; Verify stack capacity
    je .stackFull

    mov edi, directoryStack ;; Load stack

    lea edi, [edi + ecx * 4] ;; Get position from stack

    mov [edi], eax ;; Store directory address in stack

    mov [Hexagon.VFS.FAT16B.prevDirLBA], eax

    inc dword[ebx] ;; Increment counter

    clc

    ret

.stackFull:

    stc

    ret

;;************************************************************************************

;; Restores current directory in stack after returning to previous directory

Hexagon.Kernel.FS.FAT16.popDirectory:

    mov ebx, stackIndex ;; Load stack pointer

    dec dword[ebx] ;; Decrease counter

    mov ecx, [ebx] ;; Load stack index

    cmp ecx, 00h ;; If empty, go to the root directory
    je .stackEmpty

    mov edi, directoryStack ;; Load stack

    lea edi, [edi + ecx * 4] ;; Go to position on the top of the stack

    mov eax, [Hexagon.VFS.FAT16B.currentDirLBA]
    mov [Hexagon.VFS.FAT16B.prevDirLBA], eax

    mov eax, [edi] ;; Get previous directory entry
    mov [Hexagon.VFS.FAT16B.currentDirLBA], eax ;; Update directory

    clc

    ret

.stackEmpty:

    mov eax, [Hexagon.VFS.FAT16B.rootDir]
    mov [Hexagon.VFS.FAT16B.currentDirLBA], eax ;; Update current directory with root

    ret