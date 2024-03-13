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
.root       = 777
.supervisor = 699
.default    = 555

Hexagon.Users.Groups:

.Hexagon    = 00h
.root       = 01h
.supervisor = 02h
.default    = 03h
.admin      = 04h

;;************************************************************************************

;; Defines the username and its respective id
;;
;; Input:
;;
;; EAX - Logged in user id (provided by login manager)
;; ESI - Logged in username

Hexagon.Kern.Users.setUser:

    push eax

    push esi

    push ds
    pop es

    call Hexagon.Libkern.String.stringSize

    cmp eax, 32
    jl .validName

    stc

    ret

.validName:

    mov ecx, eax

    inc ecx

;; Copy username

    mov edi, Hexagon.Users.username

    pop esi

    rep movsb ;; Copy (ECX) characters from ESI to EDI

    pop eax

    mov dword [Hexagon.Users.userId], eax

    mov byte[Hexagon.Users.userLoggedIn], 01h

    ret

;;************************************************************************************

;; Returns the name of the logged in user to the process, as well as the user id
;;
;; Output:
;;
;; ESI - Logged in and registered username
;; EAX - Logged in user id

Hexagon.Kern.Users.getUser:

    cmp byte[Hexagon.Users.userLoggedIn], 00h
    je .fim

    mov esi, Hexagon.Users.username ;; Send username
    mov eax, [Hexagon.Users.userId] ;; Send the user's group id

.fim:

    ret

;;************************************************************************************

Hexagon.Kern.Users.checkUser:


;;************************************************************************************

Hexagon.Kern.Users.codeUser:


;;************************************************************************************

Hexagon.Kern.Users.validateUser:


;;************************************************************************************

Hexagon.Kern.Users.getUserPermissions:

    mov eax, [Hexagon.Users.userId]

    cmp eax, Hexagon.Users.ID.root
    je .usuarioRaiz

    cmp eax, Hexagon.Users.ID.supervisor
    je .supervisor

    mov eax, Hexagon.Users.Groups.default

    ret

.usuarioRaiz:

    mov eax, Hexagon.Users.Groups.root

    ret

.supervisor:

    mov eax, Hexagon.Users.Groups.supervisor

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
;; root        |   777   | Reading, writing and execution (total)   | root
;; supervisor  |   699   | Reading, writing and executing (debug)   | root
;; Other names |   555   | Reading, writing and execution (partial) | Common
;;
;; Names are not taken into account (except root, for login services).
;; What Hexagon will validate are the ids, where the common user id may vary, but always
;; starting with the number 555 and ending with 699, at most.

Hexagon.Users.userId: dd 0 ;; Will store the id of the currently logged in user

Hexagon.Users.username: ;; Will store the name of the currently logged in user
times 32 db 0

Hexagon.Users.userLoggedIn: db 0 ;; Stores whether or not the login was performed

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
