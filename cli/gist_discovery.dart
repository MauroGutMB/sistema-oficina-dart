/*
Detecta automaticamente a URL da API publicada no gist pelo
expor-api-rede.sh, pra quem não fixou OFICINA_API_URL na mão. Mesma ideia
usada na tela de Conexão automática do app mobile.
*/

import 'dart:convert';
import 'dart:io';

const _gistRawUrl =
    'https://gist.githubusercontent.com/MauroGutMB/f82d8d6aaf68df1bfba2a2bc4eba52eb/raw/gistfile1.txt';

/// Busca a URL publicada no gist e confere se ela está respondendo agora.
/// Devolve null se o gist não trouxer uma URL válida ou se ela não responder
/// dentro do tempo limite — nesses casos quem chamar deve cair pro padrão.
Future<String?> descobrirUrlViaGist({
  Duration tempoLimite = const Duration(seconds: 3),
}) async {
  final urlDoGist = await _buscarConteudoDoGist(tempoLimite);
  if (urlDoGist == null) return null;

  final alcancavel = await _urlResponde(urlDoGist, tempoLimite);
  return alcancavel ? urlDoGist : null;
}

Future<String?> _buscarConteudoDoGist(Duration tempoLimite) async {
  final client = HttpClient();
  try {
    // query pra furar o cache da CDN do GitHub, que segura o raw por uns
    // minutos depois de cada atualização do gist.
    final uri = Uri.parse(
      '$_gistRawUrl?t=${DateTime.now().millisecondsSinceEpoch}',
    );
    final request = await client.getUrl(uri).timeout(tempoLimite);
    final response = await request.close().timeout(tempoLimite);
    if (response.statusCode != 200) return null;

    final conteudo = (await response.transform(utf8.decoder).join()).trim();
    if (!conteudo.startsWith('http')) return null; // "offline" ou vazio
    return conteudo;
  } catch (_) {
    return null;
  } finally {
    client.close(force: true);
  }
}

Future<bool> _urlResponde(String url, Duration tempoLimite) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url)).timeout(tempoLimite);
    final response = await request.close().timeout(tempoLimite);
    return response.statusCode < 500;
  } catch (_) {
    return false;
  } finally {
    client.close(force: true);
  }
}
