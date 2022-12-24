;;************************************************************************************
;;
;;    
;;        %#@$%    &@$%$                  Kernel Hexagon®
;;        #$@$@    #@#@$
;;        @#@$%    %#$#%
;;        @#$@$    #@#$@
;;        #@#$$#$#%!@#@#     Copyright © 2016-2023 Felipe Miguel Nery Lunkes
;;        @#@%!@&$#&$#@#             Todos os direitos reservados
;;        !@$%#    @&$%#
;;        @$#!%    #&*@&
;;        $#$#%    &%$#@          Licenciado sob licença BSD-3-Clause
;;        @#!$$    !#@#@
;;
;;
;;************************************************************************************
;;
;; Este arquivo é licenciado sob licença BSD-3-Clause. Observe o arquivo de licença 
;; disponível no repositório para mais informações sobre seus direitos e deveres ao 
;; utilizar qualquer trecho deste arquivo.
;;
;; BSD 3-Clause License
;;
;; Copyright (c) 2015-2023, Felipe Miguel Nery Lunkes
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
;;                    Este arquivo faz parte do Kernel Hexagon® 
;;
;;************************************************************************************

;;************************************************************************************
;;
;;          Controle e execução de processos do Kernel Hexagon® - Novos BCPs
;;
;; Aqui existem rotinas para a alocação de memória para um novo processo, o
;; carregamento de uma imagem executável válida, sua interpretação, sua execução
;; e término.
;;
;;************************************************************************************

;; Campos necessários para cada BCP:
;;
;; PID: dword (4 bytes) 0, 1, 2, 3
;; PPID: dword (4 bytes) 4, 5, 6, 7
;; Endereço: dword (4 bytes) 8, 9, 10, 11
;; EIP: dword (4 bytes) 12, 13, 14, 15
;; Status: byte (1 byte) 16
;; Entrada: dword (4 bytes) 17, 18, 19, 20
;; Pilha: dword (4 bytes) 21, 22, 23, 24

Hexagon.Kernel.Kernel.Proc.tamanhoBCP equ 38

Hexagon.Kernel.Kernel.Proc.BCPs: dd 0
Hexagon.Kernel.Kernel.Proc.PID:  dd 0
Hexagon.Kernel.Kernel.Proc.PPID: dd 0
Hexagon.Kernel.Kernel.Proc.Mem:  dd 0
Hexagon.Kernel.Kernel.Proc.Tam:  dd 0

;;************************************************************************************

Hexagon.Kernel.Kernel.Proc.iniciarBCP:

;; Vamos alocar memória para os BCPs
;;
;; A conta é simples, devemos multiplicar o tamanho de cada BCP pelo número de processos

    mov eax, 25
    mov ecx, Hexagon.Kernel.Kernel.Proc.tamanhoBCP
    
    mul ecx 

    mov ebx, eax

    call Hexagon.Kernel.Arch.Universal.Memoria.alocarMemoria

    mov dword[Hexagon.Kernel.Kernel.Proc.BCPs], ebx

    ret

;;************************************************************************************

;; Entrada:
;;
;; EAX - PID (novo)
;; EBX - PPID 
;; ECX - Tamanho da imagem
;;
;; Saída:
;; 
;; Entrada no BCP para o processo atual
;; EAX - Endereço de memória para carregamento da imagem

Hexagon.Kernel.Kernel.Proc.incluirProcesso:

    mov dword[Hexagon.Kernel.Kernel.Proc.PID], eax
    mov dword[Hexagon.Kernel.Kernel.Proc.PPID], ebx
    mov dword[Hexagon.Kernel.Kernel.Proc.Tam], ecx

.alocarMemoria:

    mov ecx, dword[Hexagon.Kernel.Kernel.Proc.Tam]

    mov ebx, ecx

    call Hexagon.Kernel.Arch.Universal.Memoria.alocarMemoria

    mov dword[Hexagon.Kernel.Kernel.Proc.Mem], ebx ;; Salvar o endereço de entrada do processo

    mov eax, dword[Hexagon.Kernel.Kernel.Proc.PID] ;; EAX contêm o deslocamento
    
    mov ebx, 38 ;; EBX contêm o tamanho de cada BCP
    
    mul ebx   ; ;; EAX passa a ter o deslocamento dentro da tabela de BCPs  
    
    mov ebx, dword[Hexagon.Kernel.Kernel.Proc.BCPs]

    add ebx, eax ;; Agora já temos o endereço do BCP para o PID atual

    mov ecx, dword[Hexagon.Kernel.Kernel.Proc.Mem]
    mov dword[ebx+7], ecx ;; Adicionar no BCP o endereço do processo

.obterEntrada:

    mov ecx, dword[Hexagon.Imagem.Executavel.HAPP.entradaHAPP]
    mov dword[ebx+17], ecx ;; Adicionar no BCP o endereço do processo

.retornar:

    mov eax, dword[Hexagon.Kernel.Kernel.Proc.Mem] ;; Retornar o endereço de memória base

    ret 

;;************************************************************************************

Hexagon.Kernel.Kernel.Proc.iniciarProcesso:
    
    pusha

;; Agora o limite de aplicativos carregados será verificado. Caso já existam 
;; muitos processos em memória, o carregamento de um outro será impedido

.verificarLimite:

    push eax
    
    mov eax, [Hexagon.Processos.contagemProcessos]

;; Caso o número de processos carregados seja menos que o limite, proceder
;; com o carregamento. Caso contrário, impedir o carregamento retornando
;; um erro
    
    cmp eax, Hexagon.Processos.limiteProcessos ;; Número limite de processos carregados
    jl .limiteDisponivel    
                             
    pop eax
    
    jmp Hexagon.Kernel.Kernel.Proc.numeroMaximoProcessosAtingido

.limiteDisponivel:
    
;; Verificar se existem argumentos para o processo à ser carregado

    pop eax
    
    cmp eax, 0
    je .semArgumentos
    
    push esi
    
    push es
    
    mov esi, edi
    
    call Hexagon.Kernel.Lib.String.tamanhoString
    
    mov ecx, eax
    
    inc ecx
    
    push 0x18
    pop es

;; Copiar argumentos para um endereço conhecido
    
    mov esi, edi
    
    mov edi, Hexagon.ArgumentosProcesso

    rep movsb       ;; Copiar (ECX) caracteres de ESI para EDI
    
    pop es
    
    pop esi
    
    jmp .verificarImagem
    
.semArgumentos:

    mov byte[gs:Hexagon.ArgumentosProcesso], 0
    
.verificarImagem:

    ; cmp byte[Hexagon.Imagem.Executavel.HAPP.imagemIncompativel], 00h

    push esi

    call Hexagon.Kernel.FS.VFS.arquivoExiste
    
    mov dword[Hexagon.Kernel.Kernel.Proc.Tam], eax ;; Vamos salvar o tamanho da imagem

    pop esi 

    push eax
    push ebx

    jc .imagemAusente
    
    call Hexagon.Kernel.Lib.HAPP.verificarImagemHAPP

    cmp byte[Hexagon.Imagem.Executavel.HAPP.imagemIncompativel], 01h
    je .imagemIncompativel

    cmp byte[Hexagon.Imagem.Executavel.HAPP.imagemIncompativel], 02h
    je .imagemAusente

    jmp .continuarProcessamento

.imagemAusente:

    pop ebx
    pop eax

;; A imagem que contêm o código executável não foi localizada no disco

    stc          ;; Informar, ao processo que chamou a função, da ausência da imagem
    
    popa         ;; Restaurar a pilha
    
    mov byte[Hexagon.Processos.codigoRetorno], 01h
    
    mov eax, 01h ;; Enviar código de erro
    
    ret

.imagemIncompativel:

    pop ebx
    pop eax

;; A imagem que contêm o código executável não apresenta um formato compatível

    stc          ;; Informar, ao processo que chamou a função, da ausência da imagem
    
    popa         ;; Restaurar a pilha
    
    mov byte[Hexagon.Processos.codigoRetorno], 04h
    
    mov eax, 04h ;; Enviar código de erro
    
    ret

.continuarProcessamento:

    mov eax, dword[Hexagon.Processos.PID]
    mov ebx, dword 0
    mov ecx, dword[Hexagon.Kernel.Kernel.Proc.Tam]

    call Hexagon.Kernel.Kernel.Proc.incluirProcesso

    mov dword[Hexagon.Kernel.Kernel.Proc.Mem], eax

;; Serão restaurados dados passados pela pilha

    pop ebx
    pop eax

    mov ebx, eax

    mov dword[Hexagon.Processos.tamanhoPrograma], ebx
    
    push eax
    push ebx
    
    mov eax, dword[Hexagon.Kernel.Kernel.Proc.Tam]
    
    call Hexagon.Kernel.Arch.Universal.Memoria.confirmarUsoMemoria
    
    pop ebx
    pop eax

    mov edi, dword[Hexagon.Kernel.Kernel.Proc.Mem]
    
    sub edi, 0x500
    
    push esi
    
    call Hexagon.Kernel.FS.VFS.carregarArquivo
        
    pop esi
    
    jc .erroCarregandoImagem
    
    mov byte[Hexagon.Processos.codigoRetorno], 00h ;; Remover o sinalizador de erro
    
    call Hexagon.Kernel.Kernel.Proc.adicionarProcessoPilha
    
    jmp .continuarExecutando
    
.erroCarregandoImagem:

;; Um erro ocorreu durante o carregamento da imagem presente no disco

    stc                          ;; Informar, ao processo que chamou a função, da ocorrência de erro
    
    popa                         ;; Restaurar a pilha
    
    mov byte[Hexagon.Processos.codigoRetorno], 02h 
    
    mov eax, 02h                 ;; Enviar código de erro
    
    ret

.continuarExecutando:

    popa 

;; Agora devemos calcular os endereços base de código e dados do programa, os colocando 
;; na entrada da GDT do programa

    mov eax, dword[Hexagon.Kernel.Kernel.Proc.Mem]
    mov edx, eax
    and eax, 0xffff
    
    mov word[GDT.codigoPrograma+2], ax
    mov word[GDT.dadosPrograma+2], ax

    mov eax, edx
    shr eax, 16
    and eax, 0xff

    mov byte[GDT.codigoPrograma+4], al
    mov byte[GDT.dadosPrograma+4], al
    
    mov eax, edx
    shr eax, 24
    and eax, 0xff
    
    mov byte[GDT.codigoPrograma+7], al
    mov byte[GDT.dadosPrograma+7], al

    lgdt[GDTReg]    ;; Carregar a GDT contendo a entrada do processo

;; Aqui deve-se salvar o ESP do processo anterior

    mov eax, dword[Hexagon.Kernel.Kernel.Proc.PID] ;; EAX contêm o deslocamento
    
    dec eax 

    mov ebx, 38 ;; EBX contêm o tamanho de cada BCP
    
    mul ebx   ; ;; EAX passa a ter o deslocamento dentro da tabela de BCPs  
    
    mov ebx, dword[Hexagon.Kernel.Kernel.Proc.BCPs]

    add ebx, eax ;; Agora já temos o endereço do BCP para o PID atual

    mov ecx, dword[Hexagon.Kernel.Kernel.Proc.Mem]
    mov dword[ebx+21], esp ;; Adicionar no BCP o endereço da pilha

    sti ;; Ter certeza que as interrupções estão disponíveis
    
    pushfd    ;; Bandeiras
    push 0x30 ;; Novo CS
    push dword [Hexagon.Imagem.Executavel.HAPP.entradaHAPP] ;; Ponto de entrada da imagem
    
    inc dword[Hexagon.Processos.contagemProcessos]

    inc dword[Hexagon.Processos.PID]
    
    mov edi, Hexagon.ArgumentosProcesso
    
    mov ax, 0x38 ;; Segmento de dados
    mov ds, ax
    
    iret
    
;;************************************************************************************

;; Remove as credenciais e permissões do processo da pilha de execução do Sistema e da
;; GDT, transferindo o controle novamente ao Kernel

Hexagon.Kernel.Kernel.Proc.terminarProcesso:
    
    call Hexagon.Kernel.Kernel.Proc.removerProcessoPilha
        
    dec dword[Hexagon.Processos.contagemProcessos]  

    dec dword[Hexagon.Processos.PID]    

    mov ax, 0x10
    mov ds, ax
    
    mov eax, dword[Hexagon.Kernel.Kernel.Proc.PID] ;; EAX contêm o deslocamento
    
    dec eax 
    dec eax

    mov ebx, 38 ;; EBX contêm o tamanho de cada BCP
    
    mul ebx   ; ;; EAX passa a ter o deslocamento dentro da tabela de BCPs  
    
    mov ebx, dword[Hexagon.Kernel.Kernel.Proc.BCPs]

    add ebx, eax ;; Agora já temos o endereço do BCP para o PID atual

    mov ecx, dword[Hexagon.Kernel.Kernel.Proc.Mem]
    
    mov esp, dword[ebx+21];; Adicionar do BCP o endereço da pilha


;; Agora devemos restaurar a pilha do processo anterior, bem como seu endereço

;; Agora devemos calcular os endereços base de código e dados do programa, os colocando
;;  na entrada da GDT do programa

    mov eax, dword[ebx+7]
    mov edx, eax
    and eax, 0xffff
    
    mov word[GDT.codigoPrograma+2], ax  
    mov word[GDT.dadosPrograma+2], ax   

    mov eax, edx
    shr eax, 16
    and eax, 0xff

    mov byte[GDT.codigoPrograma+4], al
    mov byte[GDT.dadosPrograma+4], al
    
    mov eax, edx
    shr eax, 24
    and eax, 0xff
    
    mov byte[GDT.codigoPrograma+7], al
    mov byte[GDT.dadosPrograma+7], al

    lgdt[GDTReg]

    mov eax, dword[Hexagon.Kernel.Kernel.Proc.Tam]
    
    call Hexagon.Kernel.Arch.Universal.Memoria.liberarUsoMemoria
    
    cmp byte[Hexagon.Processos.modoTerminar], 01h
    je .ficarResidente
    
    clc
        
    jmp short .fim

.ficarResidente:

    mov eax, [Hexagon.Processos.enderecoAplicativos]
    add eax, [Hexagon.Processos.tamanhoPrograma]
    
    mov byte[Hexagon.Processos.modoTerminar], 00h
        
    clc
    
    jmp short .fim
    
.fim:

    clc
    
    popa

.verificarRetorno:
    
    clc
    
    mov ah, [Hexagon.Processos.codigoRetorno]
    
    cmp ah, 00h
    je .finalizar
    
    stc

.finalizar:
    
    mov eax, [Hexagon.Processos.codigoRetorno]
    
    ret

;;************************************************************************************
    
