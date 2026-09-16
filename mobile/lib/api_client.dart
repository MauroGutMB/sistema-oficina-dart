/*
Cliente HTTP genérico usado pelo app para falar com a API de Serviços
Mecânicos. Centraliza a montagem da requisição, o envio do corpo em JSON
e a leitura da resposta, convertendo respostas de erro (4xx/5xx) em
ApiException com a mensagem que a API devolveu em `erro`.
*/

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'app_settings.dart';

class ApiException implements Exception {
  final int statusCode;
  final String mensagem;

  ApiException(this.statusCode, this.mensagem);

  @override
  String toString() => mensagem;
}

class ApiClient {
  ApiClient(this.settings);

  final AppSettings settings;
  final http.Client _client = http.Client();
  static const _timeout = Duration(seconds: 8);

  // O URL é lido do AppSettings a cada chamada: editar nas configurações do
  // app atualiza a conexão na hora, sem precisar reiniciar.
  String get baseUrl => settings.apiUrl;

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
    final headers = {
      'Content-Type': 'application/json',
      // evita reaproveitar uma conexão TCP presa por trás de um túnel
      // instável (ex: adb reverse), que pode travar silenciosamente.
      'Connection': 'close',
      'Cache-Control': 'no-cache',
    };
    final body = corpo != null ? jsonEncode(corpo) : null;

    http.Response response;
    try {
      switch (metodo) {
        case 'GET':
          response = await _client.get(uri, headers: headers).timeout(_timeout);
        case 'POST':
          response =
              await _client.post(uri, headers: headers, body: body).timeout(_timeout);
        case 'PATCH':
          response =
              await _client.patch(uri, headers: headers, body: body).timeout(_timeout);
        case 'DELETE':
          response = await _client.delete(uri, headers: headers).timeout(_timeout);
        default:
          throw ArgumentError('Método HTTP não suportado: $metodo');
      }
    } on TimeoutException {
      throw ApiException(
        0,
        'A API não respondeu em $_timeout. Confira se o servidor está rodando e se '
        'o "adb reverse tcp:3000 tcp:3000" (ou a URL configurada) ainda está ativo.',
      );
    } on SocketException {
      throw ApiException(
        0,
        'Não foi possível conectar em $baseUrl. Verifique a URL da API nas '
        'configurações e a conexão (adb reverse/rede).',
      );
    } on HttpException catch (e) {
      throw ApiException(0, 'Falha de conexão: ${e.message}');
    }

    final respostaTexto = response.body;

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

  /// Faz uma checagem simples de conectividade, usada na tela de conexão.
  Future<bool> testarConexao() async {
    try {
      await _enviar('GET', '/clientes');
      return true;
    } catch (_) {
      return false;
    }
  }

  void close() => _client.close();
}
