import 'package:flutter/material.dart';

import '../api_client.dart';
import '../app_settings.dart';
import '../models.dart';
import '../widgets/async_helpers.dart';
import '../widgets/list_states.dart';

class _Resultado {
  const _Resultado({required this.icone, required this.titulo, required this.subtitulo});

  final IconData icone;
  final String titulo;
  final String subtitulo;
}

class _Acervo {
  const _Acervo(this.clientes, this.veiculos, this.pecas, this.servicos, this.ordens);

  final List<Cliente> clientes;
  final List<Veiculo> veiculos;
  final List<Peca> pecas;
  final List<Servico> servicos;
  final List<Ordem> ordens;
}

/// Pesquisa livre que busca em todas as seções ao mesmo tempo (clientes,
/// veículos, peças, serviços e ordens) e junta tudo numa lista só, com o
/// tipo de cada resultado marcado pelo ícone.
class BuscaGeralScreen extends StatefulWidget {
  const BuscaGeralScreen({super.key, required this.api, required this.settings});

  final ApiClient api;
  final AppSettings settings;

  @override
  State<BuscaGeralScreen> createState() => _BuscaGeralScreenState();
}

class _BuscaGeralScreenState extends State<BuscaGeralScreen> {
  late Future<_Acervo> _futuro;
  final _controller = TextEditingController();
  String _consulta = '';

  @override
  void initState() {
    super.initState();
    _futuro = _carregarTudo();
  }

  Future<_Acervo> _carregarTudo() async {
    final resultados = await Future.wait([
      widget.api.get('/clientes'),
      widget.api.get('/veiculos'),
      widget.api.get('/pecas'),
      widget.api.get('/servicos'),
      widget.api.get('/ordens'),
    ]);

    return _Acervo(
      (resultados[0] as List).map((e) => Cliente.fromJson(e)).toList(),
      (resultados[1] as List).map((e) => Veiculo.fromJson(e)).toList(),
      (resultados[2] as List).map((e) => Peca.fromJson(e)).toList(),
      (resultados[3] as List).map((e) => Servico.fromJson(e)).toList(),
      (resultados[4] as List).map((e) => Ordem.fromJson(e)).toList(),
    );
  }

  Future<void> _recarregar() {
    final futuro = _carregarTudo();
    setState(() { _futuro = futuro; });
    return futuro;
  }

  List<_Resultado> _filtrar(_Acervo acervo) {
    final resultados = <_Resultado>[];

    for (final c in acervo.clientes) {
      if (combinaPesquisa(_consulta, [c.nome, c.cpf, c.telefone])) {
        resultados.add(
          _Resultado(icone: Icons.person_outline, titulo: c.nome, subtitulo: 'Cliente · CPF ${c.cpf}'),
        );
      }
    }

    for (final v in acervo.veiculos) {
      if (combinaPesquisa(_consulta, [v.placa, v.modelo, v.cliente?.nome])) {
        resultados.add(
          _Resultado(
            icone: Icons.directions_car_outlined,
            titulo: '${v.placa} · ${v.modelo}',
            subtitulo: 'Veículo · Dono: ${v.cliente?.nome ?? 'cliente #${v.clienteId}'}',
          ),
        );
      }
    }

    for (final p in acervo.pecas) {
      if (combinaPesquisa(_consulta, [p.marca])) {
        resultados.add(
          _Resultado(
            icone: Icons.settings_outlined,
            titulo: p.marca,
            subtitulo: 'Peça · R\$${p.valor.toStringAsFixed(2)}'
                '${p.descontinuada ? ' · descontinuada' : ''}',
          ),
        );
      }
    }

    for (final s in acervo.servicos) {
      if (combinaPesquisa(_consulta, [s.nome, s.descricao])) {
        resultados.add(
          _Resultado(
            icone: Icons.build_outlined,
            titulo: s.nome,
            subtitulo: 'Serviço · R\$${s.valor.toStringAsFixed(2)}',
          ),
        );
      }
    }

    for (final o in acervo.ordens) {
      if (combinaPesquisa(_consulta, [o.veiculo?.placa, o.veiculo?.cliente?.nome, o.status])) {
        final placa = o.veiculo?.placa ?? 'veículo #${o.veiculoId}';
        resultados.add(
          _Resultado(
            icone: Icons.receipt_long_outlined,
            titulo: 'Ordem #${o.id} · $placa',
            subtitulo: 'Ordem · Status: ${o.status} · R\$${o.valorTotal.toStringAsFixed(2)}',
          ),
        );
      }
    }

    return resultados;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Pesquisar em tudo...',
            border: InputBorder.none,
          ),
          onChanged: (valor) => setState(() => _consulta = valor),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _recarregar,
        child: FutureBuilder<_Acervo>(
          future: _futuro,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ErroLista(mensagem: '${snapshot.error}', onTentarNovamente: _recarregar);
            }

            if (_consulta.trim().isEmpty) {
              return const VazioLista(mensagem: 'Digite algo pra pesquisar em todas as seções.');
            }

            final resultados = _filtrar(snapshot.data!);
            if (resultados.isEmpty) {
              return VazioLista(mensagem: 'Nada encontrado pra "$_consulta".');
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: resultados.length,
              itemBuilder: (context, i) {
                final r = resultados[i];
                return ListTile(
                  leading: CircleAvatar(child: Icon(r.icone)),
                  title: Text(r.titulo),
                  subtitle: Text(r.subtitulo),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
