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

;;************************************************************************************

;; Hexagonix default color scheme
;; The scheme present here is a reduced version of the one found in "lib/fasm/console.s",
;; with the necessary color schemes for initialization. Customizations will be carried out
;; by the utilities

;; Blossom Theme for Hexagon (only color scheme required)

HEXAGONIX_BLOSSOM_CINZA   = 0x29282928
HEXAGONIX_BLOSSOM_AMARELO = 0x00C7B898
HEXAGONIX_BLOSSOM_AZUL    = 0x004682B4

;; Classic Theme (deprecated)

HEXAGONIX_CLASSICO_PRETO  = 0x00000000
HEXAGONIX_CLASSICO_BRANCO = 0xFFFFFFFF

;;************************************************************************************

;; Here we have some useful macros for Hexagon

macro logHexagon message, priority
{

    mov esi, message
    mov ebx, priority

    call Hexagon.Kern.Dmesg.createMessage

}

macro kprint string
{

    mov esi, string

    call Hexagon.Kernel.Dev.Gen.Console.Console.printString

}

;;************************************************************************************

;; Now, function for encoding build date

;; The code below extracts and creates strings with information about the Hexagon build

__actualTime      = %t
__quadYearValue   = (__actualTime+31536000)/126230400
__quadYearRest    = (__actualTime+31536000)-(126230400*__quadYearValue)
__quadYearSection = __quadYearRest/31536000
__year            = 1969+(__quadYearValue*4)+__quadYearSection-(__quadYearSection shr 2)
__leapYear        = __quadYearSection/3
__yearSeconds     = __quadYearRest-31536000*(__quadYearSection-__quadYearSection/4)
__yearDay         = __yearSeconds/86400
__yearDayTemp     = __yearDay

if (__yearDayTemp>=(59+__leapYear))

  __yearDayTemp  = __yearDayTemp+3-__leapYear

end if

if (__yearDayTemp>=123)

  __yearDayTemp = __yearDayTemp+1

end if

if (__yearDayTemp>=185)

  __yearDayTemp = __yearDayTemp+1

end if

if (__yearDayTemp>=278)

  __yearDayTemp = __yearDayTemp+1

end if

if (__yearDayTemp>=340)

  __yearDayTemp = __yearDayTemp+1

end if

__month       = __yearDayTemp/31+1
__day         = __yearDayTemp-__month*31+32
__daySeconds  = __yearSeconds-__yearDay*86400
__hour        = __daySeconds/3600
__hourSeconds = __daySeconds-__hour*3600
__minute      = __hourSeconds/60
__second      = __hourSeconds-__minute*60

__stringYear    equ (__year/1000+'0'),((__year mod 1000)/100+'0'),((__year mod 100)/10+'0'),((__year mod 10)+'0')
__stringMonth   equ (__month/10+'0'),((__month mod 10)+'0')
__stringDay     equ (__day/10+'0'),((__day mod 10)+'0')
__stringHour    equ (__hour/10+'0'),((__hour mod 10)+'0')
__stringMinutes equ (__minute/10+'0'),((__minute mod 10)+'0')
__stringSeconds equ (__second/10+'0'),((__second mod 10)+'0')
