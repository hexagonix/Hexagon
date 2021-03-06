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

;;************************************************************************************
;;
;; Erros de entrada e saída em disquetes
;;
;; Erro | Descrição do erro
;; -----------------------------------------------------------------------------------
;;
;; 00h  | Sem erro na operação anterior
;; 01h  | Comando inválido: comando incorreto para o controlador
;; 02h  | Endereço inválido
;; 03h  | Protegido contra escrita: impossível escrever no disquete
;; 04h  | ID do setor inválido ou não encontrado
;;
;; 06h  | A troca de disquete está ativa
;;
;; 08h  | Falha no DMA
;; 09h  | DMA: impossível escrever além do limite de 64 Kbytes
;;
;; 0ch  | Tipo de mídia não disponível
;; 10h  | CRC inválido: Cyclical Redundancy Code não concorda com os dados
;; 20h  | Falha no controlador de disquete
;; 31h  | Não existe mídia no drive
;; 40h  | Trilha solicitada não encontrada
;; 80h  | Time-out
;;
;;************************************************************************************
;;
;; Erros de entrada e saída em discos rígidos
;;
;; Retornados apenas se DL > 7fH (requisições para discos rígidos)
;;
; Erro | Descrição do erro
;; -----------------------------------------------------------------------------------
;;
;; 00h  | Sem erro na operação anterior
;; 01h  | Comando inválido: comando incorreto para o controlador
;; 02h  | Endereço inválido
;; 03h  | Protegido contra escrita: impossível escrever no disquete
;; 04h  | ID do setor inválido ou não encontrado
;; 05h  | Falha ao reiniciar
;;
;; 07h  | Falha no parâmetro de atividade do disco
;; 08h  | Falha no DMA
;; 09h  | DMA: impossível escrever além do limite de 64 Kbytes
;; 0Ah  | Bandeira de setor danificado encontrada
;; 0Bh  | Cilindro defeituoso encontrado
;;
;; 0Dh  | Número de setores inválido no formato
;; 0Eh  | Indicador de endereço de controle de dados encontrado
;; 0Fh  | Nível de arbitragem DMA fora do intervalo
;; 10h  | ECC ou CRC incorretos
;; 11h  | Erro de dados corrigidos do ECC
;; 20h  | Falha no controlador de disco rígido
;; 31h  | Não existe mídia no drive
;; 40h  | Trilha solicitada não encontrada
;; 80h  | Time-out
;; AAh  | Drive não pronto
;; B3h  | Volume em uso
;; BBh  | Erro indefinido
;; CCh  | Falha de escrita no drive selecionado
;; E0h  | Estado de erro
;; FFh  | Falha na operação de sentido
;;
;;************************************************************************************

;; Estruturas de uso exclusivo para manipulação global de volumes

Hexagon.Disco:

.codigoOperacao:   db 0
.erroDisco:        db "O Hexagon(R) nao conseguiu acessar o disco solicitado.", 10, 10
                   db 10, 10, "Um erro desconhecido impediu o Hexagon(R) de acessar o disco de maneira adequada.", 10
                   db "Para prevenir perda de dados, o Sistema foi finalizado.", 10
                   db "Este problema pode ser pontual. E nao se preocupe, seus dados estao intactos.", 10
                   db "Se algo de errado aconteceu, por favor utilize o disco de instalacao do Sistema para", 10
                   db "corrigir possiveis erros no disco.", 10, 10, 0

struc Hexagon.Disco.Geral
{

.semErro          = 00h
.comandoInvalido  = 01h
.enderecoInvalido = 02h
.protegidoEscrita = 03h
.setorInvalido    = 04h
.falhaReiniciar   = 05h 
.falhaAtividade   = 07h
.falhaDMA         = 08h
.limiteDMA        = 09h
.setorDanificado  = 0Ah
.erroCilindro     = 0Bh
.numSetInvalido   = 0x0D
.falhaControlador = 20h
.semMidia         = 31h
.timeOut          = 80h
.driveNaoPronto   = 0xAA
.volumeEmUso      = 0xB3
.erroDesconhecido = 0xBB
.falhaEscrita     = 0xCC
.estadoErro       = 0xE0
.falhaOperacao    = 0xFF

}

struc Hexagon.Disco.HD
{

.semErro          = 00h
.protegidoEscrita = 01h
.erroLeitura      = 02h
.discoEmUso       = 03h
.semMidia         = 04h
.erroDesconhecido = 05h
.falhaOperacao    = 06h
.erroAutenticacao = 07h
.discoNaoPronto   = 08h

}

struc Hexagon.Disco.Controle
{

.driveAtual: db 0
.driveBoot:  db 0

}

;; Criar instâncias das estruturas, com os nomes adequados que indiquem sua localização

Hexagon.Dev.Universal.Disco.Codigos  Hexagon.Disco.Geral
Hexagon.Dev.Universal.Disco.HD.IO    Hexagon.Disco.HD
Hexagon.Dev.Universal.Disco.Controle Hexagon.Disco.Controle

;;************************************************************************************  

;; Obtêm da MBR (Master Boot Record) informações úteis a respeito do disco
;;
;; Saída:
;;
;; AH - Código da partição
;; Outros dados podem ser armazenados em variáveis apropriadas, futuramente

Hexagon.Kernel.Dev.x86.Disco.Disco.lerMBR:

    push ds 
    pop es

;; Primeiro devemos carregar a MBR na memória

    mov eax, 01h                    ;; Número de setores para ler
    mov esi, 00h                    ;; LBA do setor inicial
    mov cx, 0x50                    ;; Segmento
    mov edi, Hexagon.CacheDisco+20000 ;; Deslocamento
    mov dl, byte[Hexagon.Dev.Universal.Disco.Controle.driveAtual]

    call Hexagon.Kernel.Dev.x86.Disco.Disco.lerSetores

    jc .erro

    mov ebx, Hexagon.CacheDisco + 0x500 + 20000

    add ebx, 0x1BE ;; Deslocamento da primeira partição

    mov ah, byte[es:ebx+04h]        ;; Contém o sistema de arquivos

    jmp .fim

.erro:

    stc

.fim:

    ret

;;************************************************************************************

;; Obter o BPB (BIOS Parameter Block) do disco para a memória
;;
;; Saída:
;;
;; Nada, carrega diretamente em 0000:7C00h

Hexagon.Kernel.Dev.x86.Disco.Disco.lerBPB:

    push ds 
    pop es

;; Primeiro devemos carregar a MBR na memória

    mov eax, 01h
    mov esi, 00h
    mov cx, 0x2000                  ;; Segmento
    mov edi, 0x7C00                 ;; Deslocamento
    mov dl, byte[Hexagon.Dev.Universal.Disco.Controle.driveAtual]

    call Hexagon.Kernel.Dev.x86.Disco.Disco.lerSetores

    jc .erro

    jmp .fim

.erro:

    stc

.fim:

    ret

;;************************************************************************************

;; Reinicia determinado disco fornecido como parâmetro
;;
;; Entrada:
;;
;; DL - Código do disco
;;
;; Saída:
;;
;; EAX - 01h caso algum erro tenha ocorrido no processo

Hexagon.Kernel.Dev.x86.Disco.Disco.reiniciarDisco:

    mov ah, 00h

    call Hexagon.Kernel.Arch.x86.BIOS.BIOS.int13h

    jc .erro

    jmp .fim

.erro:

    stc

    mov eax, 01h

.fim:

    ret

;;************************************************************************************

;; Detecta se existe um disco rígido ou removível conectado ao computador. Pode ser
;; utilizada para verificar se o disco solicitado está disponível para montagem
;;
;; Entrada:
;;
;; EAX - 00h se para utilizar o disco padrão
;; DL  - Código do disco, para verificar outro volume
;;
;; Saída:
;;
;; AH - 00h para não instalado, 01h para falha ao detectar alteração de disco, 02h para falha
;;      em detectar alteração de disquete e 03h para disco rígido
;; CF defindo em caso de erro, com AH com o código de erro BIOS

Hexagon.Kernel.Dev.x86.Disco.Disco.detectarDisco:

    clc

;; Vamos chamar o BIOS para solicitar esta informação

    mov ah, 15h

    cmp eax, 00h
    je .discoPadrao

    jmp .continuar

.discoPadrao:

    mov dl, byte[Hexagon.Dev.Universal.Disco.Controle.driveAtual]

.continuar:

    mov al, 0xFF
    mov cx, 0xFFFF

    call Hexagon.Kernel.Arch.x86.BIOS.BIOS.int13h

    jc .erro

    jmp .fim

.erro:

;; A tabela de erros BIOS deve ser observada

    stc

.fim:

    ret     

;;************************************************************************************

;; Carregar setor do disco usando funções extendidas BIOS
;;
;; Entrada:
;;
;; EAX - Número de setores
;; ESI - LBA
;; EDI - Buffer de destino
;; CX  - Segmento de modo real
;; DL  - Drive
;;
;; Saída:
;;
;; EBX - Código de retorno da operação de disco executada, como em Hexagon.HD.IO, acima
                
Hexagon.Kernel.Dev.x86.Disco.Disco.lerSetores:

    push eax
    push esi

    mov dword[.PED.totalSetores], eax ;; Total de setores para carregar
    mov dword[.PED.LBA], esi          ;; Endereço de Bloco Linear (Linear Block Addres - LBA)

    mov eax, edi
    shr eax, 4
    
    add cx, ax
    
    and edi, 0xf
    
    mov word[.PED.segmento], cx       ;; Segmento de modo real
    mov word[.PED.deslocamento], di
        
    mov esi, .PED
    mov ah, 0x42                      ;; Leitura extendida BIOS
    
    call Hexagon.Kernel.Arch.x86.BIOS.BIOS.int13h                         ;; Serviços de disco do BIOS BIOS
    
    jnc .semErro
    
.verificarErro:

    cmp ah, Hexagon.Dev.Universal.Disco.Codigos.enderecoInvalido
    je .semMidia
    
    cmp ah, Hexagon.Dev.Universal.Disco.Codigos.setorInvalido
    je .semMidia
    
    cmp ah, Hexagon.Dev.Universal.Disco.Codigos.falhaAtividade
    je .semMidia
    
    cmp ah, Hexagon.Dev.Universal.Disco.Codigos.falhaControlador
    je .semMidia
    
    cmp al, Hexagon.Dev.Universal.Disco.Codigos.semMidia
    je .semMidia

    cmp al, Hexagon.Dev.Universal.Disco.Codigos.timeOut
    je .errosGerais
    
    jmp .errosGerais ;; Imprimir erro e aguardar reinício
    
.errosGerais:

    mov esi, Hexagon.Disco.erroDisco
    
    mov eax, 1
    
    call Hexagon.Kernel.Kernel.Panico.panico
    
.semMidia:
    
    mov dl, byte [Hexagon.Dev.Universal.Disco.Controle.driveBoot]
    mov byte [Hexagon.Dev.Universal.Disco.Controle.driveAtual], dl
    
    call Hexagon.Kernel.FS.VFS.iniciarSistemaArquivos
    
    mov byte[Hexagon.Disco.codigoOperacao], Hexagon.Dev.Universal.Disco.HD.IO.semMidia

    stc
    
    jmp .finalizar

.semErro:

    mov byte[Hexagon.Disco.codigoOperacao], Hexagon.Dev.Universal.Disco.HD.IO.semErro

.finalizar:

    pop esi
    pop eax
    
    movzx ebx, byte[Hexagon.Disco.codigoOperacao] ;; Fornecer em EBX o código de retorno da operação

    ret

;; PED = Pacote de Endereço de Disco. Do termo em inglês DAP (Disk Address Packet)
    
.PED:
.PED.tamanho:       db 16
.PED.reservado:     db 0
.PED.totalSetores:  dw 0
.PED.deslocamento:  dw 0x0000
.PED.segmento:      dw 0
.PED.LBA:           dd 0
                    dd 0

;;************************************************************************************

;; Escrever setores no disco utilizando funções extendidas BIOS
;;
;; Entrada:
;;
;; EAX - Número de setores
;; ESI - LBS
;; EDI - Buffer para escrever
;; CX  - Segmento de modo real
;; DL  - Drive
;;
;; Saída:
;;
;; EBX - Código de retorno da operação de disco executada, como em Hexagon.HD.IO, acima

Hexagon.Kernel.Dev.x86.Disco.Disco.escreverSetores:

    push eax
    push esi
    
    mov dword[.PED.totalSetores], eax ;; Total de setores para escrever
    mov dword[.PED.LBA], esi          ;; LBA
    
    mov eax, edi
    shr eax, 4
    
    add cx, ax
    
    and edi, 0xf
    
    mov word[.PED.deslocamento], di
    mov word[.PED.segmento], cx       ;; Segmento de modo real
    
    mov esi, .PED
    mov ah, 0x43                      ;; Escrita extendida BIOS
    mov al, 0

    call Hexagon.Kernel.Arch.x86.BIOS.BIOS.int13h                         ;; Serviços de disco BIOS
    
    jnc .semErro

.verificarErro:

    cmp ah, Hexagon.Dev.Universal.Disco.Codigos.enderecoInvalido
    je .semMidia
    
    cmp ah, Hexagon.Dev.Universal.Disco.Codigos.protegidoEscrita
    je .protegidoEscrita
    
    cmp ah, Hexagon.Dev.Universal.Disco.Codigos.driveNaoPronto
    je .discoNaoPronto
    
    cmp ah, Hexagon.Dev.Universal.Disco.Codigos.volumeEmUso
    je .discoEmUso
    
    cmp ah, Hexagon.Dev.Universal.Disco.Codigos.falhaEscrita
    je .falhaEscrita
    
    cmp ah, Hexagon.Dev.Universal.Disco.Codigos.setorInvalido
    je .semMidia
    
    cmp al, Hexagon.Dev.Universal.Disco.Codigos.falhaAtividade
    je .semMidia
    
    cmp al, Hexagon.Dev.Universal.Disco.Codigos.falhaControlador
    je .semMidia
    
    cmp al, Hexagon.Dev.Universal.Disco.Codigos.semMidia
    je .semMidia

    cmp al, Hexagon.Dev.Universal.Disco.Codigos.timeOut
    je .errosGerais
    
    jmp .errosGerais ;; Imprimir erro e aguardar reinício
    
.protegidoEscrita:

    stc

    mov byte[Hexagon.Disco.codigoOperacao], Hexagon.Dev.Universal.Disco.HD.IO.protegidoEscrita

    ret 
    
.discoNaoPronto:

    stc

    mov byte[Hexagon.Disco.codigoOperacao], Hexagon.Dev.Universal.Disco.HD.IO.discoNaoPronto

    ret 

.discoEmUso:

    stc

    mov byte[Hexagon.Disco.codigoOperacao], Hexagon.Dev.Universal.Disco.HD.IO.discoEmUso

    ret

.falhaEscrita:

    stc
  
    mov byte[Hexagon.Disco.codigoOperacao], Hexagon.Dev.Universal.Disco.HD.IO.falhaOperacao

    ret
    
.errosGerais:

    mov esi, Hexagon.Disco.erroDisco
    
    mov eax, 1
    
    call Hexagon.Kernel.Kernel.Panico.panico
    
.semMidia:
    
    mov dl, byte [Hexagon.Dev.Universal.Disco.Controle.driveBoot]
    mov byte [Hexagon.Dev.Universal.Disco.Controle.driveAtual], dl
    
    call Hexagon.Kernel.FS.VFS.iniciarSistemaArquivos
    
    mov byte[Hexagon.Disco.codigoOperacao], Hexagon.Dev.Universal.Disco.HD.IO.semMidia

    stc
    
    jmp .finalizar

.semErro:

    mov byte[Hexagon.Disco.codigoOperacao], Hexagon.Dev.Universal.Disco.HD.IO.semErro

.finalizar:

    pop esi
    pop eax
    
    movzx ebx, byte[Hexagon.Disco.codigoOperacao] ;; Fornecer em EBX o código de retorno da operação

    ret

;; PED = Pacote de Endereço de Disco. Do termo em inglês DAP (Disk Address Packet)
    
.PED:
.PED.tamanho:       db 16
.PED.reservado:     db 0
.PED.totalSetores:  dw 0
.PED.deslocamento:  dw 0x0000
.PED.segmento:      dw 0
.PED.LBA:           dd 0
                    dd 0
                    
;;************************************************************************************

;; Testa um determinado volume para verificar sua presença. Caso não esteja presente, 
;; um erro será definido, conforme Hexagon.HD.IO

Hexagon.Kernel.Dev.x86.Disco.Disco.testarVolume:

    mov eax, 1
    mov esi, 01
    mov cx, 0x50                    ;; Segmento
    mov edi, Hexagon.CacheDisco+20000   ;; Deslocamento
    mov dl, byte[Hexagon.Dev.Universal.Disco.Controle.driveAtual]
    
    call Hexagon.Kernel.Dev.x86.Disco.Disco.lerSetores

    ret

;;************************************************************************************
