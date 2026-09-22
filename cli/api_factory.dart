/*
Resolve qual backend o CLI vai usar, nessa ordem de prioridade:

  1. OFICINA_API_URL definida no ambiente -> usa ela direto (se não
     responder, é escolha explícita do usuário, então não cai pro SQLite).
  2. Uma URL publicada num gist (ver gist_discovery.dart) e que esteja
     respondendo agora — mesmo esquema da tela de Conexão automática do
     app mobile.
  3. http://localhost:3000, o padrão de sempre — só se estiver respondendo.
  4. Nenhuma API disponível -> cai pro SQLite local (sqlite_backend.dart).
*/

import 'dart:io';

import 'api_como_servico.dart';
import 'gist_discovery.dart';
import 'httpHandler.dart';
import 'sqlite_backend.dart';

Future<ApiComoServico> detectarApi() async {
  final doAmbiente = Platform.environment['OFICINA_API_URL'];
  if (doAmbiente != null) return ApiClient(baseUrl: doAmbiente);

  stdout.write('Detectando API automaticamente...');

  final urlDoGist = await descobrirUrlViaGist();
  if (urlDoGist != null) {
    print(' encontrada via gist: $urlDoGist');
    return ApiClient(baseUrl: urlDoGist);
  }

  final localhost = ApiClient(baseUrl: 'http://localhost:3000');
  if (await localhost.respondendo()) {
    print(' encontrada em http://localhost:3000.');
    return localhost;
  }
  localhost.close();

  print(' nenhuma API respondeu — usando um banco SQLite local.');
  final sqlite = SqliteApiClient.abrir();
  print('(dados salvos separadamente do banco da API; ${sqlite.origem})');
  return sqlite;
}
