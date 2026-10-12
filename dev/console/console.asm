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

;; Useful information for using graphical mode
;; Hexagon graphics mode implementation

;; Graphics mode implementation is based on VESA 3.0 specifications.

;; View VESA 3.0 specifications for more information
;; VBE = VESA BIOS Extensions

use32

;;************************************************************************************

Hexagon.Console:

.userMode:            db 0
.graphicMode:         db 0
.consoleSize:         dd 0
.maxColumns:          dw 0
.maxRows:             dw 0
.bitsPerPixel:        db 0
.bytesPerPixel:       dd 0
.bytesPerRow:         dd 0
.bytesPerRowGraphics: dd 0

;; Snapshot of bytesPerRow/Resolution.y/bytesPerPixel taken by
;; setResolution right before a mode change overwrites the live globals
;; above, so invalidateInactiveVTBuffers can still copy a VT's old
;; content into its freshly resized buffer afterward

.previous.bytesPerRow:    dd 0
.previous.rows:           dd 0
.previous.bytesPerPixel:  dd 0

;; Use the settings in libkern/macros.s to define the color
;; scheme applied at startup

.defaultBackgroundColor = HEXAGONIX_BLOSSOM_CINZA
.defaultFontColor       = HEXAGONIX_BLOSSOM_AMARELO

.backgroundColor:      dd .defaultBackgroundColor
.fontColor:            dd .defaultFontColor
.backgroundThemeColor: dd .defaultBackgroundColor
.fontThemeColor:       dd .defaultFontColor

Hexagon.Console.Resolution:

.x: dw 1024
.y: dw 768

Hexagon.Console.Memory:

;; Memory addresses for video operations

.addressLFB: dd 0  ;; LFB (Linear Frame Buffer) address
.physicalLFB: dd 0 ;; The one real hardware framebuffer address, captured once and never reassigned

;; Virtual terminals. VT.buffer is each VT's shadow of the screen while it is
;; not the active one, allocated lazily and never from the keyboard ISR. The
;; active VT has no shadow and draws straight through addressLFB. VT.backBuffer
;; is unrelated, a process's own double-buffering scratch

Hexagon.Console.VT.count = 8

Hexagon.Console.VT.buffer:
times Hexagon.Console.VT.count dd 0

;; The pointer Mm.malloc returned for each VT.buffer entry, before the 16-byte
;; alignment rounding VT.buffer stores instead, and the size requested. Mm.free
;; needs both back unchanged to release the right block

Hexagon.Console.VT.mallocBase:
times Hexagon.Console.VT.count dd 0

Hexagon.Console.VT.mallocSize:
times Hexagon.Console.VT.count dd 0

Hexagon.Console.VT.backBuffer:
times Hexagon.Console.VT.count dd 0

Hexagon.Console.VT.foregroundSlot:
times Hexagon.Console.VT.count dd 0xFFFFFFFF

Hexagon.Console.VT.locked:
times Hexagon.Console.VT.count db 0

;; Which Console.resolutionGeneration each VT.buffer entry was allocated under.
;; A mismatch means it is still sized for a mode the console has moved on from,
;; and the current stride would overrun it. Checked before any non-zero entry
;; is trusted

Hexagon.Console.VT.bufferGeneration:
times Hexagon.Console.VT.count dd 0

Hexagon.Console.activeVT: dd 0 ;; Which VT is on the physical LFB and owns keyboard input

;; Bumped by Console.switchVT on every real switch. Console.Memory.addressLFB
;; is one shared global, resolved once per process and not on every draw,
;; so a process running from before a switch would keep drawing through a stale
;; one. Every drawing syscall calls Console.ensureCurrentVT, which re-resolves
;; only when this differs from the caller's own recorded generation

Hexagon.Console.generation: dd 0

;; Bumped by Console.setupConsole once the console's geometry settles on
;; what the loader handed over. Console.VT.bufferGeneration stamps which of
;; these each VT's own VT.buffer entry was actually sized for

Hexagon.Console.resolutionGeneration: dd 0

Hexagon.Console.textMode:

.defaultColor = 0x0F ;; White text, black background
.maxRows      = 24 ;; Counting from 0
.maxColumns   = 79 ;; Counting from 0
.videoMemory  = 0xB8000

.currentColor:  db .defaultColor

;; One slot per VT (Hexagon.Console.VT.count). The graphics-mode cursor
;; code below indexes these by Console.resolveCallerTTY. The legacy VGA
;; text-mode path further down still touches slot 0 alone

.cursor.X:
times Hexagon.Console.VT.count db 0
.cursor.Y:
times Hexagon.Console.VT.count db 0

;;************************************************************************************

;; Snapshots bytesPerRow/Resolution.y/bytesPerPixel into Console.previous.*
;; right before a mode change overwrites the live globals, so
;; invalidateInactiveVTBuffers can still know each VT's old row layout
;; afterward, to copy as much of its old content forward as still fits

Hexagon.Kernel.Dev.Console.Console.snapshotPreviousGeometry:

    push eax

    mov eax, dword[Hexagon.Console.bytesPerRow]
    mov dword[Hexagon.Console.previous.bytesPerRow], eax

    movzx eax, word[Hexagon.Console.Resolution.y]
    mov dword[Hexagon.Console.previous.rows], eax

    mov eax, dword[Hexagon.Console.bytesPerPixel]
    mov dword[Hexagon.Console.previous.bytesPerPixel], eax

    pop eax

    ret

;;************************************************************************************

;; Fills Hexagon.Console.consoleSize bytes at ESI, a flat kernel-linear
;; buffer pointer such as one of Console.VT.buffer's entries, with
;; Console.backgroundColor, so a freshly (re)allocated VT starts from the
;; console's actual background instead of whatever blankBuffer's own
;; zero-fill or leftover content would otherwise show
;;
;; Input: 
;;
;; ESI - flat buffer pointer, preserved

Hexagon.Kernel.Dev.Console.Console.clearBufferToBackground:

    push eax
    push ebx
    push ecx
    push edx
    push esi

    mov eax, dword[Hexagon.Console.consoleSize]
    mov ebx, dword[Hexagon.Console.bytesPerPixel]

    xor edx, edx

    div ebx ;; EAX = pixel count

    mov ecx, eax
    mov edx, dword[Hexagon.Console.backgroundColor]

.fillLoop:

    mov dword[esi], edx

    add esi, ebx

    loop .fillLoop

    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax

    ret

;;************************************************************************************

;; Copies the overlapping top-left rows of an old, differently-sized VT
;; buffer into a freshly (re)allocated one, so a resolution change
;; preserves as much of what was already on screen as still fits, instead
;; of showing a blank VT. Copies raw bytes per row, using Console.previous.*
;; (the old layout, snapshotted by snapshotPreviousGeometry before the mode
;; change) for the source stride and the current live Console globals (the
;; new layout) for the destination stride. Skipped entirely if bytesPerPixel
;; changed between the two modes, since a raw byte copy would misalign
;; every pixel. The caller's own clearBufferToBackground already left the
;; destination in a sane state for that case
;;
;; Input:
;;
;; ESI - old buffer (flat)
;; EDI - new buffer (flat)

Hexagon.Kernel.Dev.Console.Console.copyResizedBuffer:

    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi

    mov eax, dword[Hexagon.Console.bytesPerPixel]
    cmp eax, dword[Hexagon.Console.previous.bytesPerPixel]
    jne .done

    mov eax, dword[Hexagon.Console.bytesPerRow]
    mov ebx, dword[Hexagon.Console.previous.bytesPerRow]

    cmp eax, ebx
    jbe .rowWidthChosen

    mov eax, ebx

.rowWidthChosen: ;; EAX = bytes to copy per row (the smaller of old/new bytesPerRow)

    mov edx, eax

    movzx eax, word[Hexagon.Console.Resolution.y]
    mov ebx, dword[Hexagon.Console.previous.rows]

    cmp eax, ebx
    jbe .rowCountChosen

    mov eax, ebx

.rowCountChosen: ;; EAX = rows to copy (the smaller of old/new row count)

    mov ecx, eax

    cmp ecx, 0
    je .done

.rowLoop:

    push ecx
    push esi
    push edi

    mov ecx, edx ;; Bytes to copy this row

    push ds
    push es

    mov ax, 18h ;; Kernel linear segment, both source and destination are already flat pointers
    mov ds, ax
    mov es, ax

    cld

    rep movsb

    pop es
    pop ds

    pop edi
    pop esi
    pop ecx

    add esi, dword[Hexagon.Console.previous.bytesPerRow] ;; Next old row
    add edi, dword[Hexagon.Console.bytesPerRow] ;; Next new row

    loop .rowLoop

.done:

    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax

    ret

;;************************************************************************************

;; Allocates and 16-byte-aligns a fresh Console.consoleSize buffer for VT
;; index ECX, updating VT.buffer, VT.mallocBase, VT.mallocSize and
;; VT.bufferGeneration together so they can never drift apart. Does not
;; touch whatever was tracked for this VT before this call. See
;; Console.reallocateVTBuffer for the common case that also releases it.
;; Ordinary syscall context only, never the keyboard ISR (Mm.malloc must
;; never run from there)
;;
;; Input:
;;
;; ECX - VT index, preserved
;;
;; Output:
;;
;; EAX - 0 on failure (VT.buffer/mallocBase also left 0), nonzero
;;       on success, with EBX left holding the same aligned pointer
;;      stored into VT.buffer

Hexagon.Kernel.Dev.Console.Console.allocateVTBuffer:

    push ecx
    push edx
    push esi
    push edi

    pushfd
    cli

    call Hexagon.Kern.Sched.disablePreemption

    mov edi, ecx ;; VT index, kept safe. ECX becomes Mm.malloc's own scratch/return

    mov ebx, dword[Hexagon.Console.consoleSize]
   
    add ebx, 15 ;; Room to align below, see Console.useMainConsole

    mov dword[Hexagon.Console.VT.mallocSize + edi * 4], ebx

    call Hexagon.Arch.Mm.malloc ;; EBX = allocated pointer, not EAX, see useMainConsole

    cmp eax, 0
    je .failed

    mov dword[Hexagon.Console.VT.mallocBase + edi * 4], ebx

    add ebx, 15
   
    and ebx, 0xFFFFFFF0

    mov dword[Hexagon.Console.VT.buffer + edi * 4], ebx

    mov edx, dword[Hexagon.Console.resolutionGeneration]
    mov dword[Hexagon.Console.VT.bufferGeneration + edi * 4], edx

    jmp .done

.failed:

    mov dword[Hexagon.Console.VT.buffer + edi * 4], 0
    mov dword[Hexagon.Console.VT.mallocBase + edi * 4], 0

.done:

    call Hexagon.Kern.Sched.enablePreemption

    popfd

    pop edi
    pop esi
    pop edx
    pop ecx

    ret

;;************************************************************************************

;; Frees any block already tracked in VT.mallocBase/VT.mallocSize for VT
;; index ECX, then allocates a fresh one via Console.allocateVTBuffer.
;; Used by every site that does not itself need the old content to still
;; be intact afterward. Console.invalidateInactiveVTBuffers calls
;; Console.allocateVTBuffer directly instead, so it can copy the old
;; content into the new buffer before releasing the old one itself
;;
;; Input: 
;;
;; ECX - VT index, preserved
;;
;; Output: same as Console.allocateVTBuffer

Hexagon.Kernel.Dev.Console.Console.reallocateVTBuffer:

    push ecx
    push edx
    push edi

    mov edi, ecx

    mov edx, dword[Hexagon.Console.VT.mallocBase + edi * 4]

    cmp edx, 0
    je .noOldBlock

    push eax
    push ecx

    mov ebx, edx
    mov ecx, dword[Hexagon.Console.VT.mallocSize + edi * 4]

    call Hexagon.Arch.Mm.free

    pop ecx
    pop eax

.noOldBlock:

    call Hexagon.Kernel.Dev.Console.Console.allocateVTBuffer

    pop edi
    pop edx
    pop ecx

    ret

;;************************************************************************************

;; A mode change leaves every inactive VT's shadow buffer sized for the old
;; console, which the new stride would overrun. Each one that exists gets a
;; fresh buffer here, with as much of its old content as still fits copied
;; forward, and the old block freed once that copy has read it
;;
;; This runs eagerly, and not on each VT's next use, because the Ctrl+Fn
;; guard in the keyboard ISR refuses any VT whose buffer is not allocated and
;; can never call Mm.malloc itself. VT.backBuffer has no such dependency and is
;; reset to 0 for a later lazy retry
;;
;; Console.generation is bumped too, so every process re-resolves its cached
;; addressLFB before its next draw instead of drawing into a fresh alias

Hexagon.Kernel.Dev.Console.Console.invalidateInactiveVTBuffers:

    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi

;; Several separate Mm.malloc calls happen below with interrupts enabled
;; in between, the same reentrancy concern Console.switchVT's own doc
;; comment already covers: a timer tick landing here can preempt into
;; another process that also calls malloc/free, corrupting the shared
;; free-list out from under this loop

    pushfd
    cli

    call Hexagon.Kern.Sched.disablePreemption

    xor ecx, ecx

.loop:

    cmp ecx, dword[Hexagon.Console.activeVT]
    je .next

    mov dword[Hexagon.Console.VT.backBuffer + ecx * 4], 0

    mov edi, dword[Hexagon.Console.VT.buffer + ecx * 4] ;; EDI = old aligned buffer, 0 if never allocated

    cmp edi, 0
    je .next ;; Never claimed or switched to. Nothing real to reallocate

    mov edx, dword[Hexagon.Console.VT.mallocBase + ecx * 4] ;; Old raw pointer, saved before allocateVTBuffer overwrites it
    mov esi, dword[Hexagon.Console.VT.mallocSize + ecx * 4] ;; Old raw size, same reason

    call Hexagon.Kernel.Dev.Console.Console.allocateVTBuffer

    cmp eax, 0
    je .allocFailed ;; Best effort: leave it 0, a later claim/switch can still allocate it lazily

    push edx ;; Old raw pointer, needed again below, once the copy has clobbered edx
    push esi ;; Old raw size, same reason

    mov esi, ebx ;; New buffer, cleared first

    call Hexagon.Kernel.Dev.Console.Console.clearBufferToBackground

    mov esi, edi ;; Old buffer, the copy's source
    mov edi, ebx ;; New buffer, the copy's destination

    call Hexagon.Kernel.Dev.Console.Console.copyResizedBuffer

    pop esi
    pop edx

;; Only now, once the copy above is done reading it, is the old block
;; actually freed

    cmp edx, 0
    je .next

    push ecx

    mov ebx, edx
    mov ecx, esi

    call Hexagon.Arch.Mm.free

    pop ecx

    jmp .next

.allocFailed:

;; allocateVTBuffer's own failure path already zeroed VT.mallocBase and
;; VT.buffer for this VT. EDX/ESI still hold what this VT actually owns
;; from before that call, so put them back, or that block is leaked
;; for good

    mov dword[Hexagon.Console.VT.mallocBase + ecx * 4], edx
    mov dword[Hexagon.Console.VT.mallocSize + ecx * 4], esi

.next:

    inc ecx

    cmp ecx, Hexagon.Console.VT.count

    jb .loop

    inc dword[Hexagon.Console.generation]

    call Hexagon.Kern.Sched.enablePreemption

    popfd

    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax

    ret

;;************************************************************************************

;; Returns the number relative to the current resolution of the video
;;
;; Output:
;;
;; EAX - Number relative to the resolution currently used
;;       1 - Resolution of 800x600 pixels
;;       2 - Resolution of 1024x768 pixels

Hexagon.Kernel.Dev.Console.Console.getResolution:

    movzx eax, word[Hexagon.Console.Resolution.x]

    cmp eax, 800
    je .graphicMode1

    cmp eax, 1024
    je .graphicMode2

    ret

.graphicMode1:

    mov eax, 1

    ret

.graphicMode2:

    mov eax, 2

    ret

;;************************************************************************************

;; Get video information
;;
;; Output:
;;
;; EAX - Resolution of X (bits 0-15), Y (bits 16-31)
;; EBX - Columns (bits 0-7), Rows (8-15), Bits per Pixel (16-23)
;; EDX - Buffer starting address
;; CF defined when in text mode

Hexagon.Kernel.Dev.Console.Console.getConsoleInfo:

    cmp byte[Hexagon.Console.graphicMode], 0
    je .textModeVideo

.graphicModeVideo:

    push ecx

    mov bl, byte[Hexagon.Console.bitsPerPixel]
    
    shl ebx, 8

    mov bl, byte[Hexagon.Console.maxRows]

    inc bl ;; Counting from 1

    shl ebx, 8

    mov bl, byte[Hexagon.Console.maxColumns]

    inc bl ;; Counting from 1

    mov ax, word[Hexagon.Console.Resolution.y]
    
    shl eax, 16
    
    mov ax, word[Hexagon.Console.Resolution.x]

    mov edx, dword[Hexagon.Console.Memory.addressLFB]

    pop ecx

    clc

    ret

.textModeVideo:

    mov bl, Hexagon.Console.textMode.maxColumns+1
    mov bh, Hexagon.Console.textMode.maxRows+1

    and ebx, 0xFFFF

    mov eax, 0
    mov edx, Hexagon.Console.textMode.videoMemory

    stc

    ret

;;************************************************************************************

;; Clean the console

Hexagon.Kernel.Dev.Console.Console.clearConsole:

    call Hexagon.Kernel.Dev.Console.Console.ensureCurrentVT

    cmp byte[Hexagon.Console.graphicMode], 1 ;; Check graphics mode
    je .graphicsMode

.textMode:

    xor edx, edx

    call Hexagon.Kernel.Dev.Console.Console.positionCursor

    mov edi, Hexagon.Console.textMode.videoMemory
    mov ecx, (Hexagon.Console.textMode.maxRows+1) * (Hexagon.Console.textMode.maxColumns+1)
    mov ah, byte[Hexagon.Console.textMode.currentColor] ;; Color
    mov al, ' ' ;; Character to fill the screen

    rep stosw ;; Loop to fill (clear) video memory

    jmp .end

align 16

.graphicsMode:

    mov ebx, Hexagon.Console.defaultBackgroundColor

    cmp dword[Hexagon.Console.backgroundColor], ebx
    je .clearBySSE

    mov esi, dword[Hexagon.Console.Memory.addressLFB]

    mov eax, dword[Hexagon.Console.consoleSize]
    mov ebx, dword[Hexagon.Console.bytesPerPixel]

    xor edx, edx

    div ebx

    mov ecx, eax

    mov ebx, dword[Hexagon.Console.bytesPerPixel]
    mov edx, dword[Hexagon.Console.backgroundColor]

.clearLoop:

    mov dword[esi], edx

    add esi, ebx

    loop .clearLoop

    xor dx, dx

    call Hexagon.Kernel.Dev.Console.Console.positionCursor

    ret

.clearBySSE:

    mov edi, dword[Hexagon.Console.Memory.addressLFB]

    movdqa xmm0, [.clearBytes]

    mov ecx, dword[Hexagon.Console.consoleSize]
    
    shr ecx, 7

    push ds

    mov ax, 18h ;; Kernel linear segment
    mov ds, ax

.loop:

    movdqa [edi+00], xmm0
    movdqa [edi+16], xmm0
    movdqa [edi+32], xmm0
    movdqa [edi+48], xmm0
    movdqa [edi+64], xmm0
    movdqa [edi+80], xmm0
    movdqa [edi+96], xmm0
    movdqa [edi+112], xmm0

    add edi, 128

    loop .loop

    pop ds

    xor dx, dx

    call Hexagon.Kernel.Dev.Console.Console.positionCursor

.end:

    ret

align 16

.clearBytes: times 4 dd Hexagon.Console.defaultBackgroundColor

;;************************************************************************************

;; Clear specific row on screen
;;
;; Output:
;;
;; AL - Row to clean

Hexagon.Kernel.Dev.Console.Console.clearRow:

    call Hexagon.Kernel.Dev.Console.Console.ensureCurrentVT ;; Preserves EAX/EBX/ECX itself

    cmp byte[Hexagon.Console.graphicMode], 1
    je .graphicsMode

    push eax
    push ecx
    push edx
    push edi

    push es

    push 18h ;; Kernel linear segment
    pop es

    mov dl, 0
    mov dh, al

    call Hexagon.Kernel.Dev.Console.Console.positionCursor

    movzx eax, al ;; Calculate position
    mov ecx, 160

    xor edx, edx

    mul cx

    mov edi, Hexagon.Console.textMode.videoMemory
    
    add edi, eax

    shr ecx, 2 ;; Divide ECX by 4

    mov ah, [Hexagon.Console.textMode.currentColor] ;; Color
    mov al, ' '

    shl eax, 16
    
    mov ah, [Hexagon.Console.textMode.currentColor] ;; Color
    mov al, ' '

    rep stosd

    pop es

    pop edi
    pop edx
    pop ecx
    pop eax

    ret

.graphicsMode:

    push eax
    push ebx
    push ecx
    push edx
    push esi

    xor dl, dl

    mov dh, al

    call Hexagon.Kernel.Dev.Console.Console.positionCursor

    mov esi, dword[Hexagon.Console.Memory.addressLFB]

    and eax, 0xFF

    mov ebx, Hexagon.Libkern.Font.height

    mul ebx

    mov ebx, dword[Hexagon.Console.bytesPerRow]

    mul ebx

    add esi, eax

    movzx eax, word[Hexagon.Console.bytesPerRow]
    mov ebx, Hexagon.Libkern.Font.height

    mul ebx

    mov ebx, dword[Hexagon.Console.bytesPerPixel]

    xor edx, edx

    div ebx

    mov ecx, eax

    mov ebx, dword[Hexagon.Console.bytesPerPixel]
    mov edx, dword[Hexagon.Console.backgroundColor]

.clearLoop:

    mov dword[esi], edx
    add esi, ebx

    loop .clearLoop

    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax

    ret

;;************************************************************************************

;; Scroll down

Hexagon.Kernel.Dev.Console.Console.scrollConsole:

    call Hexagon.Kernel.Dev.Console.Console.ensureCurrentVT

    push eax
    push ecx
    push edx
    push esi
    push edi

    push ds
    push es

    cmp byte[Hexagon.Console.graphicMode], 1
    je .graphicsMode

.textMode:

;; Move all screen content one line up

    mov ax, 18h ;; Kernel linear segment
    mov es, ax
    mov ds, ax

    mov esi, Hexagon.Console.textMode.videoMemory
    mov edi, Hexagon.Console.textMode.videoMemory-160 ;; One row above
    mov ecx, 2000

    rep movsw ;; Repeat ECX times (mov word[ES:EDI], word[DS:ESI])

    mov ax, 10h ;; Kernel data segment
    mov ds, ax

    mov eax, Hexagon.Console.textMode.maxRows ;; Clear last row

    call Hexagon.Kernel.Dev.Console.Console.clearRow

    jmp .end

.graphicsMode:

    mov esi, dword[Hexagon.Console.Memory.addressLFB]

    mov edi, esi

    sub edi, dword[Hexagon.Console.bytesPerRowGraphics]

    mov ecx, [Hexagon.Console.consoleSize]

    shr ecx, 7 ;; Divide by 128

    mov ax, 18h ;; Kernel linear segment
    mov es, ax
    mov ds, ax

.copy:

    prefetchnta [esi+0]
    prefetchnta [esi+32]
    prefetchnta [esi+64]
    prefetchnta [esi+96]

    movdqa xmm0, [esi+0]
    movdqa xmm1, [esi+16]
    movdqa xmm2, [esi+32]
    movdqa xmm3, [esi+48]
    movdqa xmm4, [esi+64]
    movdqa xmm5, [esi+80]
    movdqa xmm6, [esi+96]
    movdqa xmm7, [esi+112]

    movdqa [edi+0], xmm0
    movdqa [edi+16], xmm1
    movdqa [edi+32], xmm2
    movdqa [edi+48], xmm3
    movdqa [edi+64], xmm4
    movdqa [edi+80], xmm5
    movdqa [edi+96], xmm6
    movdqa [edi+112], xmm7

    add edi, 128
    add esi, 128

    loop .copy

    mov ax, 10h ;; Kernel data segment
    mov ds, ax

    movzx eax, word[Hexagon.Console.maxRows]

    call Hexagon.Kernel.Dev.Console.Console.clearRow

.end:

    pop es
    pop ds

    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax

    ret

;;************************************************************************************

;; Dispatcher to send content to the console
;;
;; Input:
;;
;; EAX - Numerical content
;; EBX - Entry type, which can be:
;;  01 - Decimal integer
;;  02 - Hexadecimal integer
;;  03 - Binary integer
;;  04 - String
;; ESI - Pointer to the string to be printed

Hexagon.Kernel.Dev.Console.Console.print:

;; Mode 05h (draw one character at an explicit DL/DH, no cursor involved)
;; is dispatched before ensureCurrentVT below, not after like every other
;; mode: ensureCurrentVT only preserves EAX/EBX/ECX for its caller, not
;; EDX, and putCharacterBitmap needs DL/DH intact. It already calls
;; ensureCurrentVT itself, so nothing is skipped by going straight there

    cmp ebx, 05h
    je Hexagon.Libkern.Graphics.putCharacterBitmap

    call Hexagon.Kernel.Dev.Console.Console.ensureCurrentVT ;; Preserves EAX/EBX/ECX itself

    cmp ebx, 01h
    je Hexagon.Kernel.Dev.Console.Console.printDecimal

    cmp ebx, 02h
    je Hexagon.Kernel.Dev.Console.Console.printHexadecimal

    cmp ebx, 03h
    je Hexagon.Kernel.Dev.Console.Console.printBinary

    cmp ebx, 04h
    je Hexagon.Kernel.Dev.Console.Console.printString

    stc

    ret

;;************************************************************************************

;; Print an integer
;;
;; Input:
;;
;; EAX - Integer

Hexagon.Kernel.Dev.Console.Console.printDecimal:

    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi

;; Check if negative

    cmp eax, 0
    jge .positive

.negative:

    push eax

    mov al, '-' ;; Print "-"

    call Hexagon.Kernel.Dev.Console.Console.printCharacter

    pop eax

    neg eax

.positive:

;; Convert integer to string to be able to print

    mov ebx, 10  ;; Decimals are in base 10
    xor ecx, ecx ;; mov ECX, 0

.convertLoop:

    xor edx, edx ;; mov EDX, 0

    div ebx

    add dl, 30h ;; Convert to ASCII

    push edx

    inc ecx

    or eax, eax ;; cmp EAX, 0
    jne .convertLoop

    mov edx, esi

.printLoop:

    pop eax

    call Hexagon.Kernel.Dev.Console.Console.printCharacter

    loop .printLoop

.end:

    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax

    ret

;;************************************************************************************

;; Print an integer as binary
;;
;; Input:
;;
;; EAX - Integer

Hexagon.Kernel.Dev.Console.Console.printBinary:

    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi

;; Check for negative

    cmp eax, 0
    jge .positive

.negative:

    push eax

    mov al, '-' ;; Print "-"

    call Hexagon.Kernel.Dev.Console.Console.printCharacter

    pop eax

    neg eax

.positive:

;; Convert integer to string so it can be printed

    mov ebx, 2   ;; Binary numbers have base 2

    xor ecx, ecx ;; mov ECX, 0

.convertLoop:

    xor edx, edx ;; mov EDX, 0

    div ebx

    add dl, 30h ;; Convert this to ASCII

    push edx

    inc ecx

    or eax, eax ;; cmp EAX, 0
    jne .convertLoop

    mov edx, esi

.printLoop:

    pop eax

    call Hexagon.Kernel.Dev.Console.Console.printCharacter

    loop .printLoop

.end:

    mov al, 'b'

    call Hexagon.Kernel.Dev.Console.Console.printCharacter

    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax

    ret

;;************************************************************************************

;; Print an integer as hexadecimal
;;
;; Input:
;;
;; EAX - Integer

Hexagon.Kernel.Dev.Console.Console.printHexadecimal:

    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi

;; Check for negative

    cmp eax, 0
    jge .positive

.negative:

    push eax

    mov al, '-' ;; Print "-"

    call Hexagon.Kernel.Dev.Console.Console.printCharacter

    pop eax

    neg eax

.positive:

    push eax

    mov al, '0'

    call Hexagon.Kernel.Dev.Console.Console.printCharacter

    mov al, 'x'

    call Hexagon.Kernel.Dev.Console.Console.printCharacter

    pop eax

;; Convert integer to hexadecimal

    mov ebx, 16  ;; Hexadecimal numbers have base 16

    xor ecx, ecx ;; mov ECX, 0

.convertLoop:

    xor edx, edx ;; mov EDX, 0

    div ebx

    add dl, 30h

    cmp dl, 39h
    ja .add

    jmp short .next

.add:

    add dl, 7 ;; Convert this to ASCII

.next:

    push edx

    inc ecx

    or eax, eax ;; cmp EAX, 0
    jne .convertLoop

    mov edx, esi

.printLoop:

    pop eax

    call Hexagon.Kernel.Dev.Console.Console.printCharacter

    loop .printLoop

.end:

    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax

    ret

;;************************************************************************************

;; Performs the same function as Hexagon.Kernel.Dev.Console.Console.printCharacter,
;; but does not move the cursor
;;
;; Input:
;;
;; AL - Character

Hexagon.Kernel.Dev.Console.Console.printCharacterBase:

    cmp byte[Hexagon.Console.graphicMode], 1
    je Hexagon.Kernel.Dev.Console.Console.printCharacterGraphicMode

    mov dl, byte[Hexagon.Console.textMode.cursor.X]
    mov dh, byte[Hexagon.Console.textMode.cursor.Y]

    cmp al, 10 ;; Caractere de nova linha
    je .newLine

    cmp al, 9
    je .tab

    cmp al, ' ' ;; First printable character
    jb .notPrintable

    cmp al, '~' ;; Last printable character
    ja .notPrintable

    jmp .next

.tab:

    mov al, ' '

    jmp .next

.newLine:

    inc dh

    mov dl, 0
    mov al, 0xFF

    jmp .next

.notPrintable:

    mov al, 0xFF

.next:

;; Fix X and Y

    cmp dh, Hexagon.Console.textMode.maxRows
    jna .yOK

    call Hexagon.Kernel.Dev.Console.Console.scrollConsole

    mov dh, Hexagon.Console.textMode.maxRows

.yOK:

    cmp dl, Hexagon.Console.textMode.maxColumns
    jna .xOK

    mov dl, 0

    inc dh

.xOK:

    push edx
    push eax

;; Calculate character position on screen

    mov eax, 0
    mov al, dl
    shl ax, 1    ;; Multiply X by 2
    mov edi, eax ;; Add this to the index
    mov al, (Hexagon.Console.textMode.maxColumns+1) * 2 ;; Counting from 1

    mul dh ;; Multiply Y by maxColumns*2

    add edi, eax ;; Add this to the index

    pop eax

;; Put character

    pop edx

    cmp al, 0xFF
    je .characterNotPrintable

    inc dl

    mov ah, byte[Hexagon.Console.textMode.currentColor]

;; If the character already exists

    cmp word[Hexagon.Console.textMode.videoMemory + edi], ax
    je .end

    mov word[Hexagon.Console.textMode.videoMemory + edi], ax

.characterNotPrintable:

.end:

;; Update the cursor

    call Hexagon.Kernel.Dev.Console.Console.positionCursor

    ret

;;************************************************************************************

Hexagon.Kernel.Dev.Console.Console.printCharacterGraphicMode:

;; Resolved once here, and not re-resolved in .next:/.return: below.
;; Incoming EDX isn't otherwise used yet (getCursor overwrites it next), so
;; nothing needs saving or restoring first

    call Hexagon.Kernel.Dev.Console.Console.resolveCallerTTY ;; EDX = caller's VT
    
    mov byte[.callerVT], dl

    call Hexagon.Kernel.Dev.Console.Console.getCursor

    cmp al, 9
    je .tab

    cmp al, 10
    je .return

    cmp al, '~'
    ja .notPrintable

    cmp al, ' '
    jl .notPrintable

    jmp .fixXandY

.tab:

    mov al, ' '

    jmp .fixXandY

.notPrintable:

    mov al, ' '

    jmp .fixXandY

.return:

    movzx esi, byte[.callerVT]

    movzx eax, word[Hexagon.Kernel.Dev.Console.Console.positionCursorGraphicMode.previousX + esi * 2]
    movzx ebx, word[Hexagon.Kernel.Dev.Console.Console.positionCursorGraphicMode.previousY + esi * 2]

    push edx

    mov ecx, Hexagon.Libkern.Font.height
    mov edx, [Hexagon.Kernel.Dev.Console.Console.positionCursorGraphicMode.previousCursorColor + esi * 4]

.clearPreviousCursor:

    call Hexagon.Libkern.Graphics.putPixel

    inc ebx

    loop .clearPreviousCursor

    pop edx

    mov dl, 0

    inc dh

    mov al, 0 ;; Mark as unprintable

.fixXandY:

    cmp dl, byte[Hexagon.Console.maxColumns]
    jna .yOK

    mov dl, 0

    inc dh

.yOK:

    cmp dh, byte[Hexagon.Console.maxRows]
    jna .xOK

    call Hexagon.Kernel.Dev.Console.Console.scrollConsole

    mov dh, byte[Hexagon.Console.maxRows]
    mov dl, 0

.xOK:

    cmp al, 0
    je .next

.printable:

    push edx

    call Hexagon.Libkern.Graphics.putCharacterBitmap

    pop edx

    inc dl

    jmp .next

.next:

    movzx esi, byte[.callerVT]

    mov byte[Hexagon.Console.textMode.cursor.X + esi], dl
    mov byte[Hexagon.Console.textMode.cursor.Y + esi], dh

    ret

.callerVT: db 0

;;************************************************************************************

;; Write a character at the cursor position
;;
;; Input:
;;
;; AL  - Character
;; EBX - 01h to position the cursor and other than that to not change the position

Hexagon.Kernel.Dev.Console.Console.printCharacter:

    pushad

    call Hexagon.Kernel.Dev.Console.Console.ensureCurrentVT

    push ebx

    call Hexagon.Kernel.Dev.Console.Console.printCharacterBase

    pop ebx

    cmp ebx, 01h
    je .changeCursor

    jmp .end

.changeCursor:

    call Hexagon.Kernel.Dev.Console.Console.positionCursor

.end:

    popad

    ret

;;************************************************************************************

;; Get cursor position
;;
;; Output:
;;
;; DL - X
;; DH - Y

Hexagon.Kernel.Dev.Console.Console.getCursor:

    push esi

    call Hexagon.Kernel.Dev.Console.Console.resolveCallerTTY ;; EDX = caller's VT
    
    movzx esi, dl

    mov dl, byte[Hexagon.Console.textMode.cursor.X + esi]
    mov dh, byte[Hexagon.Console.textMode.cursor.Y + esi]

    pop esi

    ret

;;************************************************************************************

;; Move cursor to specific position
;;
;; Input:
;;
;; DL - X
;; DH - Y

Hexagon.Kernel.Dev.Console.Console.positionCursor:

    cmp byte[Hexagon.Console.graphicMode], 1
    je Hexagon.Kernel.Dev.Console.Console.positionCursorGraphicMode

    push eax
    push ebx
    push edx

    mov byte[Hexagon.Console.textMode.cursor.X], dl
    mov byte[Hexagon.Console.textMode.cursor.Y], dh

;; Fix X and Y

    cmp dh, Hexagon.Console.textMode.maxRows
    jna .yOK

    mov dh, Hexagon.Console.textMode.maxRows

.yOK:

    cmp dl, Hexagon.Console.textMode.maxColumns
    jna .xOK

    mov dl, Hexagon.Console.textMode.maxColumns

.xOK:

;; Now we must multiply Y by the total number of columns of X

    movzx eax, dh
    mov bl, Hexagon.Console.textMode.maxColumns+1 ;; Counting from 1

    mul bl ;; Multiplying Y by columns

    movzx ebx, dl
    add eax, ebx ;; Add X to this

    mov ebx, eax

    mov al, 0x0F
    mov dx, 0x3D4

    out dx, al

;; Send least significant byte to VGA port

    mov al, bl ;; BL is the least significant byte
    mov dx, 0x3D5 ;; VGA port

    out dx, al

    mov al, 0x0E
    mov dx, 0x3D4

    out dx, ax

;; Send most significant byte to VGA port

    mov al, bh    ;; BH is the most significant byte
    mov dx, 0x3D5 ;; VGA port

    out dx, al

    pop edx
    pop ebx
    pop eax

    ret

;;************************************************************************************

Hexagon.Kernel.Dev.Console.Console.positionCursorGraphicMode:

    push eax
    push ebx
    push ecx
    push edx
    push esi

    push edx ;; incoming DL/DH, resolveCallerTTY below clobbers EDX

    call Hexagon.Kernel.Dev.Console.Console.resolveCallerTTY ;; EDX = caller's VT
    movzx esi, dl

    pop edx

    mov byte[Hexagon.Console.textMode.cursor.X + esi], dl
    mov byte[Hexagon.Console.textMode.cursor.Y + esi], dh

    push edx

    mov eax, Hexagon.Libkern.Font.width
    movzx ebx, dl

    mul ebx

    mov word[.x], ax

    pop edx

    mov eax, Hexagon.Libkern.Font.height
    movzx ebx, dh

    mul ebx

    mov word[.y], ax

    movzx eax, word[.previousX + esi * 2]
    movzx ebx, word[.previousY + esi * 2]

    mov ecx, Hexagon.Libkern.Font.height
    mov edx, dword[.previousCursorColor + esi * 4]

.clearPreviousCursor:

    call Hexagon.Libkern.Graphics.putPixel

    inc ebx

    loop .clearPreviousCursor

    mov bx, word[.x]
    mov word[.previousX + esi * 2], bx

    mov bx, word[.y]
    mov word[.previousY + esi * 2], bx

    mov edx, dword[Hexagon.Console.backgroundColor]
    mov dword[.previousCursorColor + esi * 4], edx

    movzx eax, word[.x]
    movzx ebx, word[.y]

    mov ecx, Hexagon.Libkern.Font.height
    mov edx, dword[Hexagon.Console.fontColor]

.drawCursor:

    call Hexagon.Libkern.Graphics.putPixel

    inc ebx

    loop .drawCursor

    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax

    ret

.previousX:
times Hexagon.Console.VT.count dw 0
.previousY:
times Hexagon.Console.VT.count dw 0
.previousCursorColor:
times Hexagon.Console.VT.count dd Hexagon.Console.defaultBackgroundColor
.x: dw 0
.y: dw 0

;;************************************************************************************

;; Print a string ending in 0 at the cursor position
;;
;; Input:
;;
;; ESI - String

Hexagon.Kernel.Dev.Console.Console.printString:

    push esi
    push eax
    push ecx

;; Check for null

    cmp byte[esi], 0
    je .end

;; Get string size

    call Hexagon.Libkern.String.stringSize

    mov ecx, eax

;; Write all characters

.printStringLoop:

    lodsb ;; mov AL, byte[ESI] & inc ESI

    call Hexagon.Kernel.Dev.Console.Console.printCharacter

    loop .printStringLoop

.end:

    pop ecx
    pop eax
    pop esi

    ret

;;************************************************************************************

;; Change the console color scheme
;;
;; Input:
;;
;; EAX - Font color (RGB hex)
;; EBX - Background color (RGB hex)
;; ECX - 1234h to change the default theme based on what was entered
;;
;; Text mode must be black and white only

Hexagon.Kernel.Dev.Console.Console.setConsoleColor:

    cmp byte[Hexagon.Console.graphicMode], 1
    je .graphicsMode

.textModeVideo:

    mov byte[Hexagon.Console.textMode.currentColor], Hexagon.Console.textMode.defaultColor

    ret

.graphicsMode:

    mov dword[Hexagon.Console.fontColor], eax
    mov dword[Hexagon.Console.backgroundColor], ebx

    cmp ecx, 1234h
    je .setTheme

    jmp .end

.setTheme:

    mov dword[Hexagon.Console.fontThemeColor], eax
    mov dword[Hexagon.Console.backgroundThemeColor], ebx

.end:

    ret

;;************************************************************************************

;; Get the console color scheme
;;
;; Output:
;;
;; EAX - Foreground (RGB hex)
;; EBX - Background (RGB hex)
;; ECX - Color defined for the font according to the chosen theme
;; EDX - Color set for the background according to the theme

Hexagon.Kernel.Dev.Console.Console.getConsoleColor:

    cmp byte[Hexagon.Console.graphicMode], 1
    je .graphicsMode

.textModeVideo:

    mov al, Hexagon.Console.textMode.defaultColor

    ret

.graphicsMode:

    mov eax, dword[Hexagon.Console.fontColor]
    mov ebx, dword[Hexagon.Console.backgroundColor]

    mov ecx, dword[Hexagon.Console.fontThemeColor]
    mov edx, dword[Hexagon.Console.backgroundThemeColor]

    ret

;;************************************************************************************

;; Changes the font used to display information in the console, validating the determined
;; maximum size of 2 Kb
;;
;; Input:
;;
;; ESI - Pointer to the buffer containing the font filename
;;
;; Output:
;;
;; EAX - Error code:
;;  01h for source not found
;;  02h for unsupported source
;;
;; CF set in case of error

Hexagon.Kernel.Dev.Console.Console.changeFont:

    call Hexagon.Kernel.FS.VFS.fileExists

    jc .fileNotFound

    mov ebx, 2000

    cmp eax, ebx
    jng .continue

    jmp .incompatibleFont

.continue:

    mov edi, Hexagon.Heap.Temp + 500

    xor ecx, ecx ;; Load the whole font, uncapped

    call Hexagon.Kernel.FS.VFS.openFile

    cmp byte[edi+0], "H"
    jne .incompatibleFont

    cmp byte[edi+1], "F"
    jne .incompatibleFont

    cmp byte[edi+2], "N"
    jne .incompatibleFont

    cmp byte[edi+3], "T"
    jne .incompatibleFont

    mov edi, Hexagon.Libkern.Font.fontBuffer

    xor ecx, ecx ;; Load the whole font, uncapped

    call Hexagon.Kernel.FS.VFS.openFile

    ret

.fileNotFound:

    stc

    mov eax, 01h

    ret

.incompatibleFont:

    stc

    mov eax, 02h

    ret

;;************************************************************************************

;; Use main console (the caller's own VT front). Straight to the physical LFB
;; while the caller's VT is the active one, exactly like the single-console
;; case. Otherwise its own shadow, allocated lazily if needed

Hexagon.Kernel.Dev.Console.Console.useMainConsole:

    push ecx
    push edx

    call Hexagon.Kernel.Dev.Console.Console.resolveCallerTTY ;; EDX = caller's VT

    cmp edx, dword[Hexagon.Console.activeVT]
    jne .background

    mov eax, dword[Hexagon.Console.Memory.physicalLFB]

    jmp .done

.background:

    cmp dword[Hexagon.Console.VT.buffer + edx * 4], 0
    jne .shadowReady

    mov ebx, dword[Hexagon.Console.consoleSize]

;; Room to round the pointer up to a 16-byte boundary. The
;; console's own blit and clear loops use movdqa, which faults
;; with a #GP on anything less aligned

    add ebx, 15

;; EBX = allocated pointer, not EAX. EAX is
;; only a success flag, clobbered by malloc's
;; own accounting call before it returns

    call Hexagon.Arch.Mm.malloc

    cmp eax, 0   ;; Allocation failed: draw straight through to the physical LFB
    jne .allocOk ;; instead of storing a bogus pointer and corrupting memory

    mov eax, dword[Hexagon.Console.Memory.physicalLFB]

    jmp .done

.allocOk:

    add ebx, 15
    and ebx, 0xFFFFFFF0

;; Mm.malloc's own return is already flat/physical, same frame as addressLFB and every
;; other console buffer, no translation needed

    mov dword[Hexagon.Console.VT.buffer + edx * 4], ebx

.shadowReady:

    mov eax, dword[Hexagon.Console.VT.buffer + edx * 4]

.done:

    mov [Hexagon.Console.Memory.addressLFB], eax

    call Hexagon.Kernel.Dev.Console.Console.cacheAddressLFB

    pop edx
    pop ecx

    ret

;;************************************************************************************

;; Caches Hexagon.Console.Memory.addressLFB (assumed just resolved by the
;; caller, still sitting in EAX) as the calling process's own
;; last-resolved draw target, at the generation it was resolved. Used by
;; both useMainConsole and useSecondaryConsole so that whichever one a
;; process explicitly selected last (via hx.ioctl) is what
;; Console.ensureCurrentVT restores on that process's next drawing
;; syscall. Without this, ensureCurrentVT's own "restore my cached
;; value" branch has nothing to restore yet on a process's
;; first-ever draw (Hexagon.Kern.Proc.registerSlot forces a stale
;; generation for every fresh slot), falls back to re-resolving through
;; useMainConsole unconditionally, and silently undoes a prior
;; useSecondaryConsole call
;;
;; Input: EAX - the value just written to Hexagon.Console.Memory.addressLFB

Hexagon.Kernel.Dev.Console.Console.cacheAddressLFB:

    push eax
    push ecx

    movzx ecx, byte[Hexagon.Scheduler.current]

    cmp ecx, 0xFF
    je .noSlot ;; Kernel boot context has no slot, nothing to cache into

    mov dword[Hexagon.Processes.Table.addressLFB + ecx * 4], eax

    mov eax, dword[Hexagon.Console.generation]
    mov dword[Hexagon.Processes.Table.addressLFBGeneration + ecx * 4], eax

.noSlot:

    pop ecx
    pop eax

    ret

;;************************************************************************************

;; Cheap per-syscall guard against a stale Console.Memory.addressLFB,
;; call at the top of every drawing syscall (print, clearConsole, putPixel,
;; and so on), before that global is actually read. See
;; Hexagon.Console.generation for the full reasoning

Hexagon.Kernel.Dev.Console.Console.ensureCurrentVT:

;; Callers include syscalls like putPixel that carry real parameters in EBX
;; (Console.useMainConsole below uses EBX itself as malloc scratch and never
;; restores it), so EBX has to be saved here too, along with EAX/ECX

    push eax
    push ebx
    push ecx

    movzx ecx, byte[Hexagon.Scheduler.current]

    cmp ecx, 0xFF
    je .noSlot ;; Kernel boot context has no slot, resolve every time, rare and cheap

    mov eax, dword[Hexagon.Console.generation]

    cmp eax, dword[Hexagon.Processes.Table.addressLFBGeneration + ecx * 4]
    jne .stale

;; Up to date for this process, but Console.Memory.addressLFB is a single
;; shared global, some other process may have pointed it at its own
;; console (main or secondary) since. Always restore this process's own
;; last-resolved value before drawing

    mov eax, dword[Hexagon.Processes.Table.addressLFB + ecx * 4]
    mov dword[Hexagon.Console.Memory.addressLFB], eax

    jmp .end

.stale:

    call Hexagon.Kernel.Dev.Console.Console.useMainConsole ;; Refreshes the shared global and this process's own cache (useMainConsole calls cacheAddressLFB itself)

    jmp .end

.noSlot:

    call Hexagon.Kernel.Dev.Console.Console.useMainConsole

.end:

    pop ecx
    pop ebx
    pop eax

    ret

;;************************************************************************************

;; Use secondary console (the caller's own VT back buffer, double
;; buffering), allocated lazily on first use

Hexagon.Kernel.Dev.Console.Console.useSecondaryConsole:

    push edx

    call Hexagon.Kernel.Dev.Console.Console.resolveCallerTTY ;; EDX = caller's VT

    cmp dword[Hexagon.Console.VT.backBuffer + edx * 4], 0
    jne .backBufferReady

    mov ebx, dword[Hexagon.Console.consoleSize]
    add ebx, 15 ;; Room to align below, see Console.useMainConsole

    call Hexagon.Arch.Mm.malloc ;; EBX = allocated pointer, not EAX, see useMainConsole

    cmp eax, 0 ;; Allocation failed: leave addressLFB untouched, so nothing
    je .end    ;; stores a bogus pointer and corrupts memory

    add ebx, 15
    and ebx, 0xFFFFFFF0

    mov dword[Hexagon.Console.VT.backBuffer + edx * 4], ebx

.backBufferReady:

    mov eax, dword[Hexagon.Console.VT.backBuffer + edx * 4]
    mov [Hexagon.Console.Memory.addressLFB], eax

    call Hexagon.Kernel.Dev.Console.Console.cacheAddressLFB

.end:

    pop edx

    ret

;;************************************************************************************

;; Resolves the calling process's own VT index
;;
;; Output: EDX - VT index

Hexagon.Kernel.Dev.Console.Console.resolveCallerTTY:

    push ecx

    movzx ecx, byte[Hexagon.Scheduler.current]

    cmp ecx, 0xFF
    jne .knownCaller

    xor edx, edx ;; Kernel boot context has no slot, VT0

    jmp .resolved

.knownCaller:

    mov edx, dword[Hexagon.Processes.Table.tty + ecx * 4]

.resolved:

    pop ecx

    ret

;;************************************************************************************

;; Copy buffer to video memory

Hexagon.Kernel.Dev.Console.Console.updateConsole:

    cmp byte[Hexagon.Console.graphicMode], 1
    jne .nothingToDo

;; Deciding which VT is active and then blitting into it are two separate
;; steps, and Ctrl+Fn's switchVT runs from the keyboard IRQ, without
;; this, it can land between the two and flip this VT's own back buffer
;; straight onto whatever VT switchVT just made active, bleeding stale
;; content across the switch

    pushfd
    cli

    push edx

    call Hexagon.Kernel.Dev.Console.Console.resolveCallerTTY ;; EDX = caller's VT

;; Nothing to flip if this VT never actually drew into a back buffer (never
;; called Console.useSecondaryConsole, which is what allocates it)

    cmp dword[Hexagon.Console.VT.backBuffer + edx * 4], 0
    je .nothingToDoPopped

    mov esi, dword[Hexagon.Console.VT.backBuffer + edx * 4]

;; Flip straight onto the physical LFB when this is the active VT (the
;; visible, fast path, same as the single-console case); otherwise into
;; this VT's own shadow, allocated lazily if needed, with no visible
;; side effect until that VT is actually switched to

    cmp edx, dword[Hexagon.Console.activeVT]
    jne .background

    mov edi, dword[Hexagon.Console.Memory.physicalLFB]

    jmp .targetReady

.background:

    cmp dword[Hexagon.Console.VT.buffer + edx * 4], 0
    je .allocateShadow

    mov eax, dword[Hexagon.Console.VT.bufferGeneration + edx * 4]
    cmp eax, dword[Hexagon.Console.resolutionGeneration]
    je .shadowReady ;; Already allocated, and still sized for the current resolution

.allocateShadow:

    mov ecx, edx ;; reallocateVTBuffer's own VT-index input

    call Hexagon.Kernel.Dev.Console.Console.reallocateVTBuffer

    cmp eax, 0 ;; Allocation failed: nothing safe to flip into, skip the blit
    je .nothingToDoPopped ;; a bogus pointer here would corrupt memory

.shadowReady:

    mov edi, dword[Hexagon.Console.VT.buffer + edx * 4]

.targetReady:

    pop edx

    call Hexagon.Kernel.Dev.Console.Console.blitBuffer

    popfd

    ret

.nothingToDoPopped:

    pop edx

    popfd

.nothingToDo:

    ret

;;************************************************************************************

;; Blits Hexagon.Console.consoleSize bytes, ESI (source) -> EDI
;; (destination), both already flat kernel-linear addresses. Shared by
;; Console.updateConsole and Console.switchVT

Hexagon.Kernel.Dev.Console.Console.blitBuffer:

;; Hexagon.Console.consoleSize is a kernel global and has to be read before
;; the segment switch below. ESI and EDI are allocation pointers, which the
;; loop itself reaches through the kernel linear selector

    push ecx

    mov ecx, dword[Hexagon.Console.consoleSize]
    shr ecx, 7 ;; Divide by 128

    push eax
    push es
    push ds

    mov ax, 18h ;; Kernel linear segment
    mov es, ax
    mov ds, ax

.blitLoop:

    prefetchnta [esi+128]
    prefetchnta [esi+160]
    prefetchnta [esi+192]
    prefetchnta [esi+224]

    movdqa xmm0, [esi+0]
    movdqa xmm1, [esi+16]
    movdqa xmm2, [esi+32]
    movdqa xmm3, [esi+48]
    movdqa xmm4, [esi+64]
    movdqa xmm5, [esi+80]
    movdqa xmm6, [esi+96]
    movdqa xmm7, [esi+112]

    movdqa [edi+0], xmm0
    movdqa [edi+16], xmm1
    movdqa [edi+32], xmm2
    movdqa [edi+48], xmm3
    movdqa [edi+64], xmm4
    movdqa [edi+80], xmm5
    movdqa [edi+96], xmm6
    movdqa [edi+112], xmm7

    add edi, 128
    add esi, 128

    loop .blitLoop

    pop ds
    pop es
    pop eax
    pop ecx

    ret

;;************************************************************************************

;; Zero-fills Hexagon.Console.consoleSize bytes at EDI, already a flat
;; kernel-linear address

Hexagon.Kernel.Dev.Console.Console.blankBuffer:

    push eax
    push ecx
    push es

    mov ax, 18h ;; Kernel linear segment
    mov es, ax

    cld

    xor eax, eax
    mov ecx, dword[Hexagon.Console.consoleSize]

    rep stosb

    pop es
    pop ecx
    pop eax

    ret

;;************************************************************************************

;; Switches the physical LFB to a different VT: saves the outgoing VT's
;; current on-screen content into its own shadow (allocated the first time
;; it is ever switched away from), then restores the incoming VT's own
;; shadow onto the physical LFB (allocated and blanked the first time
;; anything ever switches to that VT). Neither allocation ever happens from
;; the keyboard ISR, its own caller switches only to an already
;; claimed VT, see Hexagon.Kern.Services.keyboardHandler
;;
;; Input: EBX - target VT index

Hexagon.Kernel.Dev.Console.Console.switchVT:

    cmp ebx, dword[Hexagon.Console.activeVT]
    je .noop

    cmp ebx, Hexagon.Console.VT.count
    jae .noop

    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi

;; Saving the outgoing VT, allocating the incoming one and blitting it touch
;; the shared free list across several Mm.malloc calls with interrupts on in
;; between, and a process preempting into malloc there can be handed a buffer
;; this function is about to claim as well
;;
;; This keeps the scheduler off, not the keyboard IRQ, so a Ctrl+Fn press can
;; still reenter this function from the ISR

    pushfd

    cli

    call Hexagon.Kern.Sched.disablePreemption

    mov edx, dword[Hexagon.Console.activeVT] ;; EDX = outgoing VT

    cmp dword[Hexagon.Console.VT.buffer + edx * 4], 0
    je .allocateOutgoing

    mov eax, dword[Hexagon.Console.VT.bufferGeneration + edx * 4]
    
    cmp eax, dword[Hexagon.Console.resolutionGeneration]
    je .outgoingReady ;; Already allocated, and still sized for the current resolution

;; Sized for a resolution the console has since moved on from, most likely
;; because this VT has stayed the active one, untouched, since before the
;; last mode change. Reallocate, since saving into it would use the wrong
;; stride

.allocateOutgoing:

    push ebx ;; EBX (target VT index) is about to become reallocateVTBuffer's own output

    mov ecx, edx ;; reallocateVTBuffer's own VT-index input

    call Hexagon.Kernel.Dev.Console.Console.reallocateVTBuffer

    pop ebx ;; restore target VT index

    cmp eax, 0
    je .allocFailedOutgoing ;; Nothing safe to save the outgoing VT into, so abort the switch

.outgoingReady:

    mov esi, dword[Hexagon.Console.Memory.physicalLFB]
    mov edi, dword[Hexagon.Console.VT.buffer + edx * 4]

    call Hexagon.Kernel.Dev.Console.Console.blitBuffer

    cmp dword[Hexagon.Console.VT.buffer + ebx * 4], 0
    je .allocateIncoming

    mov eax, dword[Hexagon.Console.VT.bufferGeneration + ebx * 4]
    
    cmp eax, dword[Hexagon.Console.resolutionGeneration]
    je .incomingReady ;; Already allocated, and still sized for the current resolution

.allocateIncoming:

    mov ecx, ebx ;; ECX = target VT index, reallocateVTBuffer's own input (and it preserves ECX)

    call Hexagon.Kernel.Dev.Console.Console.reallocateVTBuffer

    cmp eax, 0
    je .allocFailedIncoming ;; Nothing safe to bring the incoming VT up on, so abort the switch

    push edi
    
    mov edi, ebx ;; New buffer, reallocateVTBuffer's own output
    mov ebx, ecx ;; restore target VT index, preserved in ECX across the call
    
    call Hexagon.Kernel.Dev.Console.Console.blankBuffer
    
    pop edi

.incomingReady:

    mov esi, dword[Hexagon.Console.VT.buffer + ebx * 4]
    mov edi, dword[Hexagon.Console.Memory.physicalLFB]

    call Hexagon.Kernel.Dev.Console.Console.blitBuffer

    mov dword[Hexagon.Console.activeVT], ebx

    inc dword[Hexagon.Console.generation] ;; Every process's cached draw target is now stale

    mov eax, dword[Hexagon.Console.Memory.physicalLFB]
    mov dword[Hexagon.Console.Memory.addressLFB], eax

    call Hexagon.Kern.Sched.enablePreemption

    popfd

    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax

    ret

.allocFailedOutgoing:

    call Hexagon.Kern.Sched.enablePreemption

    popfd

    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax

    ret

.allocFailedIncoming:

    call Hexagon.Kern.Sched.enablePreemption

    popfd

    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax

    ret

.noop:

    ret

;;************************************************************************************

;; Configures the console during startup from the mode HBoot already set,
;; as the HXBI block reports it back. A block that carries no framebuffer at all
;; leaves the machine in the text mode it booted in

Hexagon.Kernel.Dev.Console.Console.setupConsole:

    push eax
    push ebx
    push edx

    cmp dword[Hexagon.Boot.Framebuffer.address], 0

    je .textMode

    mov eax, dword[Hexagon.Boot.Framebuffer.address]
    mov dword[Hexagon.Console.Memory.addressLFB], eax
    mov dword[Hexagon.Console.Memory.physicalLFB], eax

    mov eax, dword[Hexagon.Boot.Framebuffer.pitch]
    mov dword[Hexagon.Console.bytesPerRow], eax

    mov ax, word[Hexagon.Boot.Framebuffer.width]
    mov word[Hexagon.Console.Resolution.x], ax

    mov ax, word[Hexagon.Boot.Framebuffer.height]
    mov word[Hexagon.Console.Resolution.y], ax

    movzx eax, byte[Hexagon.Boot.Framebuffer.bpp]
    mov byte[Hexagon.Console.bitsPerPixel], al

    shr eax, 3 ;; Divide by 8

    mov dword[Hexagon.Console.bytesPerPixel], eax

;; The console's own character grid, from the font the kernel draws with

    movzx eax, word[Hexagon.Console.Resolution.x]
    mov ebx, Hexagon.Libkern.Font.width

    xor edx, edx

    div ebx

    dec ax ;; Counting from 0

    mov word[Hexagon.Console.maxColumns], ax

    movzx eax, word[Hexagon.Console.Resolution.y]
    mov ebx, Hexagon.Libkern.Font.height

    xor edx, edx

    div ebx

    dec ax ;; Counting from 0

    mov word[Hexagon.Console.maxRows], ax

    mov eax, dword[Hexagon.Console.bytesPerRow]
    movzx ebx, word[Hexagon.Console.Resolution.y]

    mul ebx

    mov dword[Hexagon.Console.consoleSize], eax

    mov eax, dword[Hexagon.Console.bytesPerRow]
    mov ebx, Hexagon.Libkern.Font.height

    mul ebx

    mov dword[Hexagon.Console.bytesPerRowGraphics], eax

    mov byte[Hexagon.Console.graphicMode], 1

    jmp .done

.textMode:

    mov byte[Hexagon.Console.graphicMode], 0

.done:

    inc dword[Hexagon.Console.resolutionGeneration]

    call Hexagon.Kernel.Dev.Console.Console.clearConsole

    pop edx
    pop ebx
    pop eax

    ret

;;************************************************************************************

;; Registers tty0-tty7. Unlike serial and parallel ports, which register
;; lazily on first open, all 8 VTs are known upfront, so registering them at
;; boot lists every one, and not only those already opened. Called by
;; Hexagon.Kernel.Dev.Dev.registerDevices, since the registry only needs to
;; exist, not the console hardware to be configured

Hexagon.Kernel.Dev.Console.Console.registerDevices:

    mov esi, Hexagon.Dev.Devices.tty0
    mov al, 04h ;; Hexagon.Dev.DeviceClasses.output
    mov bl, 0
    mov cl, 0

    call Hexagon.Kernel.Dev.Dev.registerDevice

    mov esi, Hexagon.Dev.Devices.tty1
    mov al, 04h
    mov bl, 0
    mov cl, 0

    call Hexagon.Kernel.Dev.Dev.registerDevice

    mov esi, Hexagon.Dev.Devices.tty2
    mov al, 04h
    mov bl, 0
    mov cl, 0

    call Hexagon.Kernel.Dev.Dev.registerDevice

    mov esi, Hexagon.Dev.Devices.tty3
    mov al, 04h
    mov bl, 0
    mov cl, 0

    call Hexagon.Kernel.Dev.Dev.registerDevice

    mov esi, Hexagon.Dev.Devices.tty4
    mov al, 04h
    mov bl, 0
    mov cl, 0

    call Hexagon.Kernel.Dev.Dev.registerDevice

    mov esi, Hexagon.Dev.Devices.tty5
    mov al, 04h
    mov bl, 0
    mov cl, 0

    call Hexagon.Kernel.Dev.Dev.registerDevice

    mov esi, Hexagon.Dev.Devices.tty6
    mov al, 04h
    mov bl, 0
    mov cl, 0

    call Hexagon.Kernel.Dev.Dev.registerDevice

    mov esi, Hexagon.Dev.Devices.tty7
    mov al, 04h
    mov bl, 0
    mov cl, 0
    
    call Hexagon.Kernel.Dev.Dev.registerDevice

    ret
