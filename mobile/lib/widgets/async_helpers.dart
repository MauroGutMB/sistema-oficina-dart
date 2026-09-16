import 'package:flutter/material.dart';

import '../api_client.dart';

/// Executa [acao] tratando erros da API de forma amigável, mostrando um
/// SnackBar em caso de falha. Retorna true se [acao] terminou sem erro.
Future<bool> executarComFeedback(
  BuildContext context,
  Future<void> Function() acao,
) async {
  try {
    await acao();
    return true;
  } on ApiException catch (e) {
    if (context.mounted) _mostrarErro(context, e.mensagem);
  } catch (e) {
    if (context.mounted) _mostrarErro(context, 'Não foi possível conectar à API: $e');
  }
  return false;
}

void _mostrarErro(BuildContext context, String mensagem) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(mensagem), backgroundColor: Colors.red.shade700),
  );
}

void mostrarSucesso(BuildContext context, String mensagem) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(mensagem), backgroundColor: Colors.green.shade700),
  );
}

String? obrigatorio(String? valor) =>
    (valor == null || valor.trim().isEmpty) ? 'Campo obrigatório' : null;

String? numeroObrigatorio(String? valor) {
  if (valor == null || valor.trim().isEmpty) return 'Campo obrigatório';
  if (num.tryParse(valor.replaceAll(',', '.')) == null) return 'Número inválido';
  return null;
}

/// Testa se algum dos [campos] contém [consulta] (sem diferenciar
/// maiúsculas/minúsculas). Consulta vazia sempre combina — assim as telas
/// de lista podem usar isso direto no filtro sem checar o caso vazio antes.
bool combinaPesquisa(String consulta, Iterable<String?> campos) {
  final alvo = consulta.trim().toLowerCase();
  if (alvo.isEmpty) return true;
  return campos.any((campo) => campo != null && campo.toLowerCase().contains(alvo));
}
