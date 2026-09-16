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

## Endpoints

A API sobe em `http://localhost:3000`.

* `/clientes` - Métodos: GET, POST, DELETE
  * `/clientes/:id` - Métodos: GET, DELETE
* `/veiculos` - Métodos: GET, POST, DELETE
  * `/veiculos/:id` - Métodos: GET, DELETE
* `/pecas` - Métodos: GET, POST, PATCH
  * `/pecas/:id` - Métodos: GET
  * `/pecas/repor` - Métodos: GET
  * `/pecas/:id/repor` - Métodos: PATCH
  * `/pecas/:id/descontinuar` - Métodos: PATCH
* `/servicos` - Métodos: GET, POST, DELETE
  * `/servicos/:id` - Métodos: GET, DELETE
* `/ordens` - Métodos: GET, POST, PATCH, DELETE
  * `/ordens/:id` - Métodos: GET, DELETE
  * `/ordens/:id/aprovar` - Métodos: PATCH
  * `/ordens/:id/concluir` - Métodos: PATCH

## Como executar

Pré-requisitos: Node.js e MariaDB instalados.

```bash
# 1. dependências
npm install

# 2. banco de dados (no MariaDB)
CREATE DATABASE oficina CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

# 3. variáveis de ambiente
cp .env.example .env   # e preencha os valores

# 4. tabelas e client do Prisma
npx prisma migrate dev

# 5. servidor
node api/server.ts
```

## Testando a API

### Collection do Postman

O arquivo `oficina.postman_collection.json` traz todos os endpoints prontos, agrupados por recurso e com corpos de exemplo já preenchidos.

Para usar: no Postman, **Import** → selecione o arquivo. A URL base fica na variável `{{baseUrl}}` da collection, com valor padrão `http://localhost:3000`.

Sugestão de ordem para um teste completo, já que os recursos dependem uns dos outros:

1. Criar cliente
2. Criar veículo (usando o `id` do cliente em `clienteId`)
3. Criar peça e criar serviço
4. Abrir ordem (com a `placa` do veículo e o `pecaId` da peça)
5. Listar peças — a quantidade deve ter caído, confirmando a baixa no estoque
6. Aprovar ordem e depois concluir ordem

Vale testar também os caminhos de erro, que é onde as regras de negócio aparecem: concluir uma ordem ainda não aprovada (400), abrir ordem com quantidade acima do estoque (400), cadastrar CPF repetido (409), remover cliente que possui veículos (409).

### Script de limpeza do banco

O `limpar-banco.sh` esvazia as tabelas entre uma bateria de testes e outra, sem precisar recriar o banco na mão.

```bash
chmod +x limpar-banco.sh   # só na primeira vez

./limpar-banco.sh          # esvazia as tabelas
./limpar-banco.sh --seed   # esvazia e insere dados de exemplo
./limpar-banco.sh --reset  # derruba tudo e reaplica as migrations
```

O modo padrão usa `TRUNCATE`, que também reinicia os ids em 1 — assim os exemplos da collection do Postman continuam válidos a cada rodada.

O `--seed` deixa o banco com 2 clientes, 2 veículos, 3 peças e 3 serviços. Os dados foram escolhidos para exercitar as regras: uma das peças já está abaixo do ponto de reposição (aparece em `/pecas/repor`) e outra está descontinuada (deve ser recusada ao abrir uma ordem).

O `--reset` chama o `prisma migrate reset` e é o modo a usar depois de alterar o `schema.prisma`.

O script lê as credenciais do `.env`, então ele depende do arquivo estar preenchido.

### CLI em Dart

O diretório `cli/` traz um cliente de terminal em Dart que consome a API acima: um menu interativo pra listar, criar, remover e disparar as ações de negócio (repor/descontinuar peça, abrir/aprovar/concluir/cancelar ordem) sem precisar do Postman.

```bash
# com a API já rodando em outro terminal (node api/server.ts)
cd cli
dart pub get
dart run main.dart
```

Por padrão o CLI aponta pra `http://localhost:3000`. Pra usar outra URL, defina `OFICINA_API_URL` antes de rodar:

```bash
OFICINA_API_URL=http://localhost:4000 dart run main.dart
```

### App mobile em Flutter

O diretório `mobile/` traz o app **Oficina Atividade**, um cliente Flutter que consome a mesma API pra fazer o CRUD completo (clientes, veículos, peças, serviços e ordens de serviço) direto do celular ou do desktop.

Principais telas e recursos:

- Menu lateral arrastável com acesso a todas as seções, à tela de conexão e ao alternador de tema.
- Modo claro/escuro, seguindo o sistema por padrão e ajustável manualmente.
- Listar, criar e remover em cada seção, mais as ações específicas de peça (repor estoque, descontinuar, filtrar as que estão no ponto de reposição) e de ordem (aprovar, concluir, cancelar).
- Tela de **Conexão**, pra configurar a URL da API em tempo real sem recompilar o app.

```bash
# com a API já rodando (node api/server.ts)
cd mobile
flutter pub get
flutter run              # detecta automaticamente um dispositivo/emulador conectado
```

Por padrão o app aponta pra `http://localhost:3000` — ideal pra rodar no desktop (Linux) ou num emulador Android com `adb reverse`:

```bash
adb reverse tcp:3000 tcp:3000   # com o celular conectado via adb
```

Se preferir outro endereço (rede Wi-Fi, emulador padrão do Android Studio via `10.0.2.2`, etc.), dá pra mudar a URL a qualquer momento pela tela de Conexão no menu lateral do app, sem precisar reinstalar.

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
