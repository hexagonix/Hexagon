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

;;************************************************************************************
;;
;; Hexagon kernel user control and security and access policies
;;
;; This file contains all user manipulation functions, as well as variables related to
;; these tasks.
;; It also contains user access control variables and flags for requests made by Hexagon,
;; as well as definitions and standardization of codes for security policies.
;; This is the core security and system protection of Hexagon.
;;
;;************************************************************************************

use32

;;************************************************************************************

Hexagon.Users.ID:

.Hexagon    = 000
.root       = 0
.default    = 1

Hexagon.Users.Groups:

.Hexagon    = 00h
.root       = 01h
.default    = 03h
.admin      = 04h

;;************************************************************************************

;; Registers the id of the user now logged in on the calling process. A
;; child created afterward inherits it, the same way it already inherits
;; its parent's environment
;;
;; Only root may switch to an arbitrary id. A non-root caller may only
;; switch back to its own real id. Either way, the real id moves with the
;; effective one, so switching away from root as root leaves no path back
;;
;; Input:
;;
;; EAX - Logged in user id
;;
;; Output:
;;
;; CF set on permission denied, id left unchanged

Hexagon.Kern.Users.setUser:

    push ebx
    push ecx

    mov ecx, eax ;; Requested id, saved across the call below

    call Hexagon.Kern.Users.getUserPermissions

    cmp eax, Hexagon.Users.Groups.root
    je .allowed

    movzx ebx, byte[Hexagon.Scheduler.current]

    cmp ecx, dword[Hexagon.Processes.Table.realUserId + ebx * 4]
    jne .denied

.allowed:

    movzx ebx, byte[Hexagon.Scheduler.current]

    mov dword[Hexagon.Processes.Table.userId + ebx * 4], ecx
    mov dword[Hexagon.Processes.Table.realUserId + ebx * 4], ecx

    mov byte[Hexagon.Processes.Table.userLoggedIn + ebx], 01h

    clc

    pop ecx
    pop ebx

    ret

.denied:

    stc

    pop ecx
    pop ebx

    ret

;;************************************************************************************

;; Returns the id of the logged in user to the calling process
;;
;; Output:
;;
;; EAX - Logged in (effective) user id
;; EBX - Real user id, the identity behind a setuid elevation, for
;;       userland to check authorization against who is really calling it

Hexagon.Kern.Users.getUser:

    push ecx

    movzx ecx, byte[Hexagon.Scheduler.current]

    cmp byte[Hexagon.Processes.Table.userLoggedIn + ecx], 00h
    je .fim

    mov eax, dword[Hexagon.Processes.Table.userId + ecx * 4]
    mov ebx, dword[Hexagon.Processes.Table.realUserId + ecx * 4]

.fim:

    pop ecx

    ret

;;************************************************************************************

Hexagon.Kern.Users.checkUser:

;;************************************************************************************

Hexagon.Kern.Users.codeUser:

;;************************************************************************************

Hexagon.Kern.Users.getUserGroup:

;;************************************************************************************

Hexagon.Kern.Users.validateUser:

;;************************************************************************************

Hexagon.Kern.Users.getUserPermissions:

    push ebx

    movzx ebx, byte[Hexagon.Scheduler.current]

    cmp byte[Hexagon.Processes.Table.userLoggedIn + ebx], 00h
    je .notLoggedIn

    mov eax, dword[Hexagon.Processes.Table.userId + ebx * 4]

    cmp eax, Hexagon.Users.ID.root
    je .rootUser

    mov eax, Hexagon.Users.Groups.default

    jmp .done

.notLoggedIn:

    mov eax, Hexagon.Users.Groups.default

    jmp .done

.rootUser:

    mov eax, Hexagon.Users.Groups.root

.done:

    pop ebx

    ret

;;************************************************************************************

;; Hexagon's permissions system works with user ids.
;; Each type of user has a specific id that will be used to check the validity of operations
;; requested by the logged in user.
;; Valid IDs are designated below:
;;
;; Username    | User ID |                 Permissions              | Account Type
;; ------------|---------|------------------------------------------|-------------
;; Hexagon     |   000   |        Total (Hardware, Software)        | Kernel
;; root        |   000   | Reading, writing and execution (total)   | root
;; Other names |  1..698 | Reading, writing and execution (partial) | Common
;;
;; Names are not taken into account (except root, for login services).
;; What Hexagon will validate are the ids, where the common user id may vary. Userland
;; account management assigns each new user the next unused id, starting at 1, so no
;; two accounts ever share a code.
;;
;; root and the kernel share id 000, but they are never confused with each other: the
;; kernel's own privileged operations bypass this permission system entirely rather
;; than going through Hexagon.Kern.Users.setUser.

Hexagon.Users.groupId: dd 0 ;; Will store the group id of the currently logged in user

;; Hexagon may also change the permission state of user-requested operations or processes.
;; These permissions will be stored in the variables below.

Hexagon.Users.Permissions.read:      db 0
Hexagon.Users.Permissions.write:     db 0
Hexagon.Users.Permissions.execution: db 0

;; So that the kernel can bypass security measures that distinguish users or input values ​​and be
;; able to execute any function allocated to it, a variable will be used that indicates whether
;; the order of execution of the function came from the kernel itself or not.
;; Only functions that distinguish privileges and input values ​​should read/write to this variable.
;; The values ​​used are also standardized, as below.
;;
;; Object name             | Code | Type of access
;; ------------------------|------|---------------
;; kernelExecuteDisabled   |  00h | The kernel is not requesting operations that require
;;                                  restricted access or analysis
;; kernelExecutePermission |  01h | Execute the requested function
;; orderKernelDeny         |  02h | Prevent the execution of any function until the state changes
;; orderKernelDebug        |  04h | Use in the future for debugging
;;
;; The kernelExecutePermission flag is analogous to logging in with the root user account,
;; allowing tasks to be performed with privileges.
;; However, it allows access to data and functions not exposed or permitted to the root user.

kernelExecuteDisabled   = 00h ;; Evidence that the call was not made by Hexagon
kernelExecutePermission = 01h ;; This flag is supported by the root user (root)
kernelExecuteDeny       = 02h ;; Denies execution of *ANY* requested supported function
kernelExecuteDebug      = 04h ;; Used for debugging supported functions

kernelExecute: dd 0 ;; Used as an access key to perform any privileged function
