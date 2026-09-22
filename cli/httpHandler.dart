/*
Cliente HTTP genérico usado pelo CLI para falar com a API de Serviços
Mecânicos. Centraliza a montagem da requisição, o envio do corpo em JSON
e a leitura da resposta, convertendo respostas de erro (4xx/5xx) em
ApiException com a mensagem que a API devolveu em `erro`.
*/

import 'dart:convert';
import 'dart:io';

import 'api_como_servico.dart';

class ApiException implements Exception {
  final int statusCode;
  final String mensagem;

  ApiException(this.statusCode, this.mensagem);

  @override
  String toString() => 'Erro $statusCode: $mensagem';
}

class ApiClient implements ApiComoServico {
  final String baseUrl;
  final HttpClient _client = HttpClient();

  ApiClient({String? baseUrl})
    : baseUrl =
          baseUrl ??
          Platform.environment['OFICINA_API_URL'] ??
          'http://localhost:3000';

  @override
  String get origem => baseUrl;

  /// Checagem rápida de conectividade, usada pra decidir se essa URL serve
  /// antes de comprometer o CLI inteiro com ela.
  Future<bool> respondendo({Duration tempoLimite = const Duration(seconds: 3)}) async {
    try {
      await _enviar('GET', '/clientes').timeout(tempoLimite);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<dynamic> get(String path) => _enviar('GET', path);

  @override
  Future<dynamic> post(String path, [Map<String, dynamic>? corpo]) =>
      _enviar('POST', path, corpo: corpo);

  @override
  Future<dynamic> patch(String path, [Map<String, dynamic>? corpo]) =>
      _enviar('PATCH', path, corpo: corpo);

  @override
  Future<dynamic> delete(String path) => _enviar('DELETE', path);

  Future<dynamic> _enviar(
    String metodo,
    String path, {
    Map<String, dynamic>? corpo,
  }) async {
    final uri = Uri.parse('$baseUrl$path');

    HttpClientRequest request;
    switch (metodo) {
      case 'GET':
        request = await _client.getUrl(uri);
      case 'POST':
        request = await _client.postUrl(uri);
      case 'PATCH':
        request = await _client.patchUrl(uri);
      case 'DELETE':
        request = await _client.deleteUrl(uri);
      default:
        throw ArgumentError('Método HTTP não suportado: $metodo');
    }

    request.headers.contentType = ContentType.json;
    // evita reaproveitar uma conexão keep-alive que o servidor já fechou:
    // o Node derruba conexões ociosas depois de ~5s, mas o dart:io só
    // desiste delas depois de 15s, causando "Connection closed before
    // full header was received" quando o CLI demora entre requisições.
    request.persistentConnection = false;
    if (corpo != null) {
      request.write(jsonEncode(corpo));
    }

    final response = await request.close();
    final respostaTexto = await response.transform(utf8.decoder).join();

    if (respostaTexto.isEmpty) {
      if (response.statusCode >= 400) {
        throw ApiException(response.statusCode, 'A API não retornou detalhes do erro');
      }
      return null;
    }

    final decodificado = jsonDecode(respostaTexto);

    if (response.statusCode >= 400) {
      final mensagem = decodificado is Map && decodificado['erro'] != null
          ? decodificado['erro'].toString()
          : respostaTexto;
      throw ApiException(response.statusCode, mensagem);
    }

    return decodificado;
  }

  @override
  void close() => _client.close(force: true);
}
