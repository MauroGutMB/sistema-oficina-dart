# Oficina Atividade

App Flutter (Android/desktop Linux) que consome a API de Serviços Mecânicos deste repositório pra fazer o CRUD de clientes, veículos, peças, serviços e ordens de serviço — a versão mobile do mesmo sistema que o [CLI em Dart](../cli) e o [Postman](../oficina.postman_collection.json) já testam.

Veja o [README na raiz do repositório](../README.md) pra contexto do projeto (API, banco, CLI) e a seção "App mobile em Flutter" de lá pra instruções rápidas de execução.

## Estrutura

```
lib/
  api_client.dart       cliente HTTP (http package), com timeout e tratamento de erro
  app_settings.dart      tema (claro/escuro) e URL da API, persistidos com shared_preferences
  navigation.dart         lista de seções do CRUD, compartilhada entre a home e o menu lateral
  home_page.dart          dashboard inicial (grade com as 5 seções)
  models/                 Cliente, Veiculo, Peca, Servico, Ordem (espelham o schema da API)
  screens/                uma tela por seção do CRUD, mais a tela de Conexão
  widgets/
    app_drawer.dart        menu lateral (seções, conexão, tema)
    oficina_scaffold.dart   Scaffold compartilhado (AppBar + drawer + refresh) usado pelas seções
    list_states.dart        estados de lista vazia/erro, reutilizados nas 5 telas
    async_helpers.dart      feedback de erro/sucesso e validadores de formulário
```

## Rodando

Pré-requisito: a API rodando (`node api/server.ts` na raiz do repo — veja o README principal).

```bash
flutter pub get
flutter devices     # confere o dispositivo/emulador conectado
flutter run         # ou "flutter run -d <id>" se houver mais de um dispositivo
```

### Conectando num celular físico via adb

```bash
adb reverse tcp:3000 tcp:3000
```

Isso faz `http://localhost:3000` no celular apontar pro `localhost:3000` do computador — não precisa saber o IP da máquina. Precisa refazer o `adb reverse` toda vez que o cabo/conexão wireless cair.

A URL da API é configurável a qualquer momento pela tela **Conexão** (menu lateral) — útil pra trocar entre `localhost` (com `adb reverse`), o IP da rede Wi-Fi, ou `10.0.2.2` (emulador padrão do Android Studio), sem precisar recompilar.

### Testes e build

```bash
flutter analyze
flutter test
flutter build apk --debug     # gera o APK em build/app/outputs/flutter-apk/
flutter build linux --debug   # build desktop, útil pra testar sem dispositivo Android
```
