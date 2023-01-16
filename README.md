<p align="center">
<img src="https://github.com/hexagonix/Doc/blob/main/Img/banner.png">
</p>

<div align="center">

![](https://img.shields.io/github/license/hexagonix/Hexagon.svg)
![](https://img.shields.io/github/stars/hexagonix/Hexagon.svg)
![](https://img.shields.io/github/issues/hexagonix/Hexagon.svg)
![](https://img.shields.io/github/issues-closed/hexagonix/Hexagon.svg)
![](https://img.shields.io/github/issues-pr/hexagonix/Hexagon.svg)
![](https://img.shields.io/github/issues-pr-closed/hexagonix/Hexagon.svg)
![](https://img.shields.io/github/downloads/hexagonix/Hexagon/total.svg)
![](https://img.shields.io/github/release/hexagonix/Hexagon.svg)
[![](https://img.shields.io/twitter/follow/hexagonixOS.svg?style=social&label=Follow%20%40HexagonixOS)](https://twitter.com/hexagonixOS)

</div>

<!-- Vai funcionar como <hr> -->

<img src="https://github.com/hexagonix/Doc/blob/main/Img/hr.png" width="100%" height="2px" />

# Escolha o idioma/choose language

<details title="Português (Brasil)" align='left'>
<summary align='left'>:brazil: Português (Brasil)</summary>

## Kernel Hexagon

<p align="center">
<img src="https://github.com/hexagonix/Doc/blob/main/Img/LogoHexagon.png" width="200" height="200">
</p>

<div align="justify">

O Hexagon é um `núcleo` (kernel) monolítico executado em `modo protegido` 32-bit, desenvolvido puramente em Assembly para a arquitetura PC (x86). É um kernel escrito do zero, visando a velocidade e a compatibilidade de harware moderno, mas também sendo capaz de ser executado em hardware mais antigo (Pentium III ou superiores, com 32 MB de memória RAM ou mais). No momento, garante um ambiente monoutilizador, apesar do uso de terminais virtuais, e monotarefa, apesar da capacidade de carregar, manter em memória e controlar mais de um processo por vez, em uma pilha de execução de ordem cronológica. Futuramente o kernel poderá receber suporte a execução de múltiplos processos em multitarefa preemptiva. O Hexagon foi projetado para ser um kernel Unix-like e compõe a base do `Hexagonix`, embora independente deste. Ele executa imagens executáveis no formato `HAPP`, desenvolvido exclusivamente para o Hexagon. Ele também implementa uma API bastante sofisticada acessível através de uma chamada de sistema padronizada e documentada, como você pode ver abaixo.

Algumas características do Hexagon:

- [x] Suporte a processadores x86 (Pentium III ou superiores);
- [x] Suporte a dispositivos com 32 MB de memória RAM ou mais;
- [x] Suporte a ambiente de usuário;
- [x] Chamada de sistema com 68 funções sofisticadas acessadas pelo ambiente de usuário;
- [x] Formato binário executável próprio (HAPP);
- [x] Unix-like;
- [x] Completamente escrito em Assembly x86;
- [x] Self-hosting (o montador usado para construir o Hexagon pode ser executado sobre ele);
- [x] Sistema de arquivos virtual;
- [x] Abstração de dispositivos;
- [x] Suporte total a leitura e escrita em sistemas de arquivos FAT16;
- [x] Suporte a gráficos VESA VBE e em múltiplas resoluções;
- [x] Suporte a modo texto;
- [x] Motor de renderização de fontes gráficas, que podem ser alteradas pelo usuário;
- [x] Suporte a relógio em tempo real;
- [x] Suporte a portas seriais e paralelas (comunicação serial, debug e impressão);
- [x] Compatível com carregador de inicialização próprio (Hexagon Boot - HBoot);
- [x] Suporte a usuários e permissões.

Outras características que estão sendo desenvolvidas:

- [ ] Procura e enumeração de todos os dispositivos PCI;
- [ ] Multitarefa preemptiva.

> Você pode ajudar a implementar as funções em desenvolvimento acima!

> **Este arquivo não fornece informações técnicas sobre o kernel Hexagon. Para acessar a documentação técnica completa, clique [aqui](https://github.com/hexagonix/Doc/blob/main/Hexagon/README.pt.md)**
</div>

</details>

<details title="English" align='left'>
<summary align='left'>:uk: English</summary>

## Hexagon kernel

<p align="center">
<img src="https://github.com/hexagonix/Doc/blob/main/Img/LogoHexagon.png" width="200" height="200">
</p>

<div align="justify">

Hexagon is a monolithic `kernel` running in 32-bit `protected mode`, developed purely in Assembly for the PC (x86) architecture. It is a kernel written from scratch, aiming for the speed and compatibility of modern hardware, but also being able to run on older hardware (Pentium III or higher, with 32 MB of RAM or more). At the moment, it guarantees a single-user environment, despite the use of virtual terminals, and single-tasking, despite the ability to load, keep in memory and control more than one process at a time, in a chronological order execution stack. In the future, the kernel may support the execution of multiple processes in preemptive multitasking. Hexagon was designed to be a Unix-like kernel and forms the basis of `Hexagonix`, albeit independently of it. It runs executable images in the `HAPP` format, developed exclusively for Hexagon. It also implements a very sophisticated API accessible through a standardized and documented system call, as you can see below.

Some features of Hexagon:

- [x] Support for x86 processors (Pentium III or higher);
- [x] Support for devices with 32 MB of RAM or more;
- [x] User environment support;
- [x] System call with 68 sophisticated functions accessed by the user environment;
- [x] Own executable binary format (HAPP);
- [x] Unix-like;
- [x] Completely written in x86 Assembly;
- [x] Self-hosting (the assembler used to build the Hexagon can run on top of it);
- [x] Virtual file system;
- [x] Device abstraction;
- [x] Full support for reading and writing on FAT16 file systems;
- [x] VESA VBE and multi-resolution graphics support;
- [x] Text mode support;
- [x] Graphic font rendering engine, which can be changed by the user;
- [x] Real-time clock support;
- [x] Support for serial and parallel ports (serial communication, debug and printing);
- [x] Supports own boot loader (Hexagon Boot - HBoot);
- [x] Support for users and permissions.

Other features being developed:

- [ ] Search and enumeration of all PCI devices;
- [ ] Preemptive multitasking.

> You can help implement the above development functions!

> **This file does not provide technical information about the Hexagon kernel. To access the complete technical documentation, click [here](https://github.com/hexagonix/Doc/tree/main/Hexagon/README.en.md)**

</div>

</details>

<details title="Hexagon License" align='left'>
<br>
<summary align='left'>Licença do Hexagon/Hexagon License</summary>

<div align="justify">

Hexagonix Operating System

BSD 3-Clause License

Copyright (c) 2015-2023, Felipe Miguel Nery Lunkes<br>
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

</div>

</details>