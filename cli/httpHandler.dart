/*
Cliente HTTP genérico usado pelo CLI para falar com a API de Serviços
Mecânicos. Centraliza a montagem da requisição, o envio do corpo em JSON
e a leitura da resposta, convertendo respostas de erro (4xx/5xx) em
ApiException com a mensagem que a API devolveu em `erro`.
*/

import 'dart:convert';
import 'dart:io';

class ApiException implements Exception {
  final int statusCode;
  final String mensagem;

  ApiException(this.statusCode, this.mensagem);

  @override
  String toString() => 'Erro $statusCode: $mensagem';
}

class ApiClient {
  final String baseUrl;
  final HttpClient _client = HttpClient();

  ApiClient({String? baseUrl})
    : baseUrl =
          baseUrl ??
          Platform.environment['OFICINA_API_URL'] ??
          'http://localhost:3000';

  Future<dynamic> get(String path) => _enviar('GET', path);

  Future<dynamic> post(String path, [Map<String, dynamic>? corpo]) =>
      _enviar('POST', path, corpo: corpo);

  Future<dynamic> patch(String path, [Map<String, dynamic>? corpo]) =>
      _enviar('PATCH', path, corpo: corpo);

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

  void close() => _client.close(force: true);
}
