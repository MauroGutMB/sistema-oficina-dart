import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Gera um CSV a partir de [linhas] (a primeira devendo ser o cabeçalho) e
/// salva no diretório de documentos do app, devolvendo o caminho completo.
Future<String> exportarCsv(String nomeArquivo, List<List<Object?>> linhas) async {
  final dir = await getApplicationDocumentsDirectory();
  final conteudo = linhas.map(_linhaCsv).join('\r\n');
  final arquivo = File('${dir.path}/$nomeArquivo');
  await arquivo.writeAsString(conteudo);
  return arquivo.path;
}

String _linhaCsv(List<Object?> campos) {
  return campos.map((campo) {
    final texto = (campo ?? '').toString();
    if (texto.contains(',') || texto.contains('"') || texto.contains('\n')) {
      return '"${texto.replaceAll('"', '""')}"';
    }
    return texto;
  }).join(',');
}
