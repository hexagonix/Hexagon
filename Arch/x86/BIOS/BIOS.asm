;;************************************************************************************
;;
;;    
;;        %#@$%    &@$%$                  Kernel Hexagon®
;;        #$@$@    #@#@$
;;        @#@$%    %#$#%
;;        @#$@$    #@#$@
;;        #@#$$#$#%!@#@#     Copyright © 2016-2022 Felipe Miguel Nery Lunkes
;;        @#@%!@&$#&$#@#             Todos os direitos reservados
;;        !@$%#    @&$%#
;;        @$#!%    #&*@&
;;        $#$#%    &%$#@
;;        @#!$$    !#@#@
;;
;;
;;************************************************************************************
;;                                                                                  
;;                                 Kernel Hexagon®          
;;                                                                   
;;                  Copyright © 2016-2022 Felipe Miguel Nery Lunkes                
;;                          Todos os direitos reservados.                    
;;                                                                   
;;************************************************************************************
;;
;;                    Este arquivo faz parte do Kernel Hexagon® 
;;
;;************************************************************************************

use32

;;************************************************************************************

Hexagon.Arch.x86.BIOS Hexagon.Arch.x86.Regs

;;************************************************************************************

Hexagon.Kernel.Arch.x86.BIOS.BIOS.int10h:

use32
    
    cli
    
    mov word[Hexagon.Arch.x86.BIOS.registradorAX], ax
    mov word[Hexagon.Arch.x86.BIOS.registradorBX], bx
    mov word[Hexagon.Arch.x86.BIOS.registradorCX], cx
    mov word[Hexagon.Arch.x86.BIOS.registradorDX], dx
    mov word[Hexagon.Arch.x86.BIOS.registradorDI], di
    mov word[Hexagon.Arch.x86.BIOS.registradorSI], si
    mov dword[Hexagon.Arch.x86.BIOS.registradorEBP], ebp
    mov dword[Hexagon.Arch.x86.BIOS.registradorESP], esp

    push eax
    push edx
    
    call Hexagon.Kernel.Arch.x86.Procx86.Procx86.irPara16 ;; Ir para o modo real para solicitar os serviços BIOS
    
use16

    mov ax, word[Hexagon.Arch.x86.BIOS.registradorAX]
    mov bx, word[Hexagon.Arch.x86.BIOS.registradorBX]
    mov cx, word[Hexagon.Arch.x86.BIOS.registradorCX]
    mov dx, word[Hexagon.Arch.x86.BIOS.registradorDX]
    mov si, word[Hexagon.Arch.x86.BIOS.registradorSI]
    mov di, word[Hexagon.Arch.x86.BIOS.registradorDI]
    
    int 10h
    
    call Hexagon.Kernel.Arch.x86.Procx86.Procx86.irPara32 ;; Voltar para o modo protegido, para a segurança!
    
use32

    mov ax, 0x10
    mov ds, ax
    mov ax, 0x18  ;; Definir a base de ES, SS e GS base para 0
    mov ss, ax
    mov es, ax  
    mov gs, ax
    mov esp, dword[Hexagon.Arch.x86.BIOS.registradorESP]
    
    sub esp, 4*2
    
    pop edx
    pop eax

    mov ebp, dword[Hexagon.Arch.x86.BIOS.registradorEBP]
    
    sti
    
    ret

;;************************************************************************************

Hexagon.Kernel.Arch.x86.BIOS.BIOS.int13h:

use32
    
    cli
    
    mov word[Hexagon.Arch.x86.BIOS.registradorAX], ax
    mov word[Hexagon.Arch.x86.BIOS.registradorBX], bx
    mov word[Hexagon.Arch.x86.BIOS.registradorCX], cx
    mov word[Hexagon.Arch.x86.BIOS.registradorDX], dx
    mov word[Hexagon.Arch.x86.BIOS.registradorDI], di
    mov word[Hexagon.Arch.x86.BIOS.registradorSI], si
    mov dword[Hexagon.Arch.x86.BIOS.registradorEBP], ebp
    mov dword[Hexagon.Arch.x86.BIOS.registradorESP], esp

    push eax
    push edx
    
    call Hexagon.Kernel.Arch.x86.Procx86.Procx86.irPara16
    
use16

    mov bx, word[Hexagon.Arch.x86.BIOS.registradorBX]
    mov cx, word[Hexagon.Arch.x86.BIOS.registradorCX]
    mov dx, word[Hexagon.Arch.x86.BIOS.registradorDX]
    mov si, word[Hexagon.Arch.x86.BIOS.registradorSI]
    mov di, word[Hexagon.Arch.x86.BIOS.registradorDI]
    mov ax, word[Hexagon.Arch.x86.BIOS.registradorAX]
    
    int 13h
    
    pushf
    
    pop ax
    
    mov word[Hexagon.Arch.x86.BIOS.registradorFlags], ax ;; Salvar flags (para checagem de erros)
    mov word[Hexagon.Arch.x86.BIOS.registradorAX], ax
    
    call Hexagon.Kernel.Arch.x86.Procx86.Procx86.irPara32
    
use32

    mov ax, 0x10
    mov ds, ax
    mov ax, 0x18                   ;; Definir base de ES, GS e SS para 0
    mov ss, ax
    mov gs, ax
    mov es, ax  
    mov esp, dword[Hexagon.Arch.x86.BIOS.registradorESP]
    
    sub esp, 4*2
    
    pop edx
    pop eax

    mov ebp, dword[Hexagon.Arch.x86.BIOS.registradorEBP]

    pushfd
    
    pop eax
    
    or ax, word[Hexagon.Arch.x86.BIOS.registradorFlags]
    
    push eax
    
    popfd
    
    mov ax, word[Hexagon.Arch.x86.BIOS.registradorAX]
    
    sti
    
    ret

;;************************************************************************************
    
Hexagon.Kernel.Arch.x86.BIOS.BIOS.int15h:

use32
    
    cli
    
    mov word[Hexagon.Arch.x86.BIOS.registradorAX], ax
    mov word[Hexagon.Arch.x86.BIOS.registradorBX], bx
    mov word[Hexagon.Arch.x86.BIOS.registradorCX], cx
    mov word[Hexagon.Arch.x86.BIOS.registradorDX], dx
    mov word[Hexagon.Arch.x86.BIOS.registradorDI], di
    mov word[Hexagon.Arch.x86.BIOS.registradorSI], si
    mov dword[Hexagon.Arch.x86.BIOS.registradorEBP], ebp
    mov dword[Hexagon.Arch.x86.BIOS.registradorESP], esp

    push eax
    push edx
    
    call Hexagon.Kernel.Arch.x86.Procx86.Procx86.irPara16
    
use16

    mov ax, word[Hexagon.Arch.x86.BIOS.registradorAX]
    mov bx, word[Hexagon.Arch.x86.BIOS.registradorBX]
    mov cx, word[Hexagon.Arch.x86.BIOS.registradorCX]
    mov dx, word[Hexagon.Arch.x86.BIOS.registradorDX]
    mov si, word[Hexagon.Arch.x86.BIOS.registradorSI]
    mov di, word[Hexagon.Arch.x86.BIOS.registradorDI]
    
    int 15h
    
    call Hexagon.Kernel.Arch.x86.Procx86.Procx86.irPara32
    
use32

    mov ax, 0x10
    mov ds, ax
    mov ax, 0x18            ;; Definir a base de ES, SS e GS base para 0
    mov ss, ax
    mov es, ax  
    mov gs, ax
    mov esp, dword[Hexagon.Arch.x86.BIOS.registradorESP]
    
    sub esp, 4*2
    
    pop edx
    pop eax

    mov ebp, dword[Hexagon.Arch.x86.BIOS.registradorEBP]
    
    sti
    
    ret

;;************************************************************************************

