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

;; Structure used to manipulate FAT16B volumes, based on the FAT template provided by VFS

Hexagon.VFS.FAT16B Hexagon.VFS.FAT

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

    push edi

;; Check if the file already exists

    call Hexagon.Kernel.FS.FAT16.fileExistsFAT16B

    jc .failure

    pop edi

    mov esi, edi

    push ebx

    call Hexagon.Kernel.FS.FAT16.fileExistsFAT16B

    pop ebx

    jnc .failure

    push ebx

    call Hexagon.Kernel.FS.FAT16.filenameToFATName

    pop ebx

;; In EBX, the pointer to the entry in the root directory

    mov edi, ebx

;; Correct address with segment base (physical address = address + segment base)

    add edi, 500h

    mov ecx, 11

    rep movsb ;; Move (ECX) times string in ESI to EDI

;; Write modified root directory to volume

    movzx eax, word[Hexagon.VFS.FAT16B.rootDirSize] ;; Sectors to write
    mov esi, dword[Hexagon.VFS.FAT16B.rootDir] ;; LBA of the root directory
    mov cx, 50h ;; Segment
    mov edi, Hexagon.Heap.DiskCache + 20000 ;; Offset
    mov dl, byte[Hexagon.Dev.Gen.Disk.Control.currentDisk]

    call Hexagon.Kernel.Dev.i386.Disk.Disk.writeSectors

    jc .failure

.end:

    popad

    ret

.failure:

    stc ;; Set Carry

    jmp .end

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

    movzx eax, word[Hexagon.VFS.FAT16B.rootDirSize] ;; Sectors to read
    mov esi, dword[Hexagon.VFS.FAT16B.rootDir] ;; LBA of the root directory
    mov cx, 50h ;; Segment
    mov edi, Hexagon.Heap.DiskCache + 20000 ;; Offset
    mov dl, byte[Hexagon.Dev.Gen.Disk.Control.currentDisk]

    call Hexagon.Kernel.Dev.i386.Disk.Disk.readSectors

;; Search name in all entries

    movzx edx, word[Hexagon.VFS.FAT16B.rootEntries] ;; Total folders or files in the root directory
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

    pop esi
    pop edi
    pop edx
    pop ecx

    ret

.filenameBuffer: times 13 db ' '

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

;; Load root directory

    movzx eax, word[Hexagon.VFS.FAT16B.rootDirSize] ;; Sectors to read
    mov esi, dword[Hexagon.VFS.FAT16B.rootDir] ;; LBA of the root directory
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

;; Let's check some attributes of the entry, such as whether it is a directory or a volume label.
;; For now, if we are talking about these entries, we will skip until the support is completed.

    mov al, byte[esi+11] ;; File attributes

    bt ax, Hexagon.VFS.FAT16B.directoryBit ;; If subdirectory, skip
    jc .buildListLoop

    bt ax, Hexagon.VFS.FAT16B.volumeNameBit ;; If volume label, skip
    jc .buildListLoop

;; Now let's get more information about the entry

    cmp byte[esi+11], Hexagon.VFS.FAT16B.longFilenameAttribute ;; If long filename, skip
    je .buildListLoop

    cmp byte[esi], Hexagon.VFS.FAT16B.unlinkedAttribute ;; If file deleted, skip
    je .buildListLoop

;; If this is the last file, we don't want to look any further in the directory for something
;; that doesn't exist ;-)

    cmp byte[esi], 0   ;; If last file, finish
    je .finishList

    call Hexagon.Kernel.FS.FAT16.FATnameToFilename ;; Convert name to 8.3 format

;; Add filename entry to list

    call Hexagon.Libkern.String.stringSize ;; Find entry size

    push esi

    mov edi, edx
    mov ecx, eax ;; EAX is the size of the first string

    rep movsb ;; Move (ECX) bytes from ESI to EDI

    pop esi

;; Add a space between filenames, useful for list manipulation

    mov byte[es:edx+eax], ' '

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

;; Create new file

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

    pop esi ;; Restore ESI

    push esi

    call Hexagon.Kernel.FS.FAT16.fileExistsFAT16B

    jc .failure

;; EBX is a pointer to the entry in the root directory

    mov eax, dword[.fileSize]
    mov dword[ebx+28], eax ;; Size
    mov word[ebx+26], cx ;; First sector

;; Write modified root directory to volume

    movzx eax, word[Hexagon.VFS.FAT16B.rootDirSize] ;; Sectors to write
    mov esi, dword[Hexagon.VFS.FAT16B.rootDir] ;; LBA of the root directory
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

    pop esi
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax

    ret

.fileSize:         dd 0
.clustersRequired: dd 0

;;************************************************************************************

;; Unlink a file from volume
;;
;; Input:
;;
;; ESI - Pointer to filename

Hexagon.Kernel.FS.FAT16.unlinkFileFAT16B:

    pushad

    call Hexagon.Kernel.FS.FAT16.fileExistsFAT16B

    jc .end

;; The root directory entry is already loaded, due to Hexagon.Kernel.FS.FAT16.fileExistsFAT16B

    mov ax, word[ebx+26] ;; Get first cluster
    mov word[.cluster], ax ;; Save

;; Mark the file as deleted

    mov byte[ebx], Hexagon.VFS.FAT16B.unlinkedAttribute

;; Write modified root directory to volume

    movzx eax, word[Hexagon.VFS.FAT16B.rootDirSize] ;; Sectors to write
    mov esi, dword[Hexagon.VFS.FAT16B.rootDir] ;; LBA of the root directory
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

    popad

    ret

.cluster: dw 0

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

;; Get the label of the volume used

    mov eax, dword[es:esi+40] ;; Volume label
    mov dword[Hexagon.VFS.Control.volumeLabel], eax

    mov eax, dword[es:esi+44] ;; Volume label
    mov dword[Hexagon.VFS.Control.volumeLabel+4], eax

    mov eax, dword[es:esi+48] ;; Volume label
    mov dword[Hexagon.VFS.Control.volumeLabel+8], eax

;; Now we must finish the volume label string

    mov byte[Hexagon.VFS.Control.volumeLabel+11], 0

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

;; Check if the file already exists

    call Hexagon.Kernel.FS.FAT16.fileExistsFAT16B

    jnc .failure

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

    movzx eax, word[Hexagon.VFS.FAT16B.rootDirSize] ;; Sectors to read
    mov esi, dword[Hexagon.VFS.FAT16B.rootDir] ;; LBA of root directory
    mov cx, 50h ;; Segment
    mov edi, Hexagon.Heap.DiskCache + 20000 ;; Offset
    mov dl, byte[Hexagon.Dev.Gen.Disk.Control.currentDisk]

    call Hexagon.Kernel.Dev.i386.Disk.Disk.readSectors

    mov edi, Hexagon.Heap.DiskCache + 20000
    movzx ecx, word[Hexagon.VFS.FAT16B.rootEntries]

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

    movzx eax, word[Hexagon.VFS.FAT16B.rootDirSize] ;; Sectors to write
    mov esi, dword[Hexagon.VFS.FAT16B.rootDir] ;; LBA of the root directory
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

    popad

    ret

.filenameBuffer: times 13 db ' '

;;************************************************************************************

;; Initialize the volumes

Hexagon.Kernel.FS.FAT16.initVolumeFAT16B:

;; Obtain information from BPB and store system structures

    call Hexagon.Kernel.Dev.i386.Disk.Disk.readBPB

    jc .error

    mov esi, dword[Hexagon.Memory.addressBPB]

    call Hexagon.Kernel.FS.FAT16.getFilesystemInfoFAT16B

    clc

    ret

.error:

    stc

    ret
