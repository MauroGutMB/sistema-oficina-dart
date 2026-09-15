# Atividade 1 - Programação pra Dispositivos Móveis 

Aplicação do aprendizado da linguagem dart para desenvolver uma aplicação crud em dart, com o o objetivo de praticar a criação de classes, métodos, atributos e a manipulação de dados. 

O trabalho consiste em desenvolver um sistema de oficina mecânica, que permita o cadastro de clientes, veículos, peças e serviços, além de gerenciar ordens de serviço e estoque.

## Aluno Responsável
Mauro Gutemberg Magalhães Barros

## Sistema escolhido
Sistema 4 - Oficina Mecânica

---
```
4. 🔧 Sistema de Oficina Mecânica
A oficina mantém um estoque de peças de diferentes marcas, valores e quantidades.
Eventualmente uma peça esgota e atinge o ponto de reposição, ou é descontinuada;
novos itens são adquiridos e há diversos serviços oferecidos, cada um com seu valor de mão de obra,
sendo necessário manter o cadastro de peças e serviços sempre atualizado.

Os clientes trazem seus veículos para reparo.
Primeiro é necessário cadastrá-los e registrar os veículos vinculados.
Depois, o veículo é avaliado e abre-se uma Ordem de Serviço (OS) com o diagnóstico inicial,
o valor varia conforme as peças necessárias e as horas de mão de obra. Antes de iniciar,
a oficina apresenta o orçamento, que o cliente precisa aprovar;
apenas as peças aprovadas e disponíveis em estoque são reservadas.

Ao finalizar, define-se a OS como concluída, registra-se data/hora de entrega e dá-se baixa no
estoque das peças usadas, somando peças + mão de obra. Se durante a execução surgirem problemas
adicionais, eles vão para nova aprovação e somam ao total;
se um serviço orçado não for necessário, seu valor é descontado do total final.
```
---
packages utilizados
```
atividade_ppdm@1.0.0 /home/maurogutmb/ifpi/Atividade_ppdm
├── @prisma/adapter-mariadb@7.10.0
├── @prisma/client@7.10.0
├── @types/express@5.0.6
├── @types/node@26.5.1
├── dotenv@17.4.2
├── express@5.2.1
├── mysql2@3.24.4
├── prisma@7.10.0
├── tsx@4.23.13
└── typescript@7.0.2
```
