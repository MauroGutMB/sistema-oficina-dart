import 'package:flutter/material.dart';

import '../api_client.dart';
import '../app_settings.dart';
import '../models.dart';
import '../widgets/csv_export.dart';
import '../widgets/list_states.dart';

class _Relatorio {
  const _Relatorio({
    required this.titulo,
    required this.resumo,
    required this.arquivo,
    required this.cabecalho,
    required this.linhas,
    this.nota,
  });

  final String titulo;
  final String resumo;
  final String arquivo;
  final List<String> cabecalho;
  final List<List<Object?>> linhas;
  final String? nota;
}

class _Acervo {
  const _Acervo(this.clientes, this.veiculos, this.pecas, this.servicos, this.ordens);

  final List<Cliente> clientes;
  final List<Veiculo> veiculos;
  final List<Peca> pecas;
  final List<Servico> servicos;
  final List<Ordem> ordens;
}

class RelatoriosScreen extends StatefulWidget {
  const RelatoriosScreen({super.key, required this.api, required this.settings});

  final ApiClient api;
  final AppSettings settings;

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> {
  late Future<_Acervo> _futuro;

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

  List<_Relatorio> _montarRelatorios(_Acervo a) {
    // agrupamentos O(n), pra aguentar bem uma base grande (--seed-nuke)
    final ordensPorVeiculo = <int, List<Ordem>>{};
    for (final o in a.ordens) {
      ordensPorVeiculo.putIfAbsent(o.veiculoId, () => []).add(o);
    }

    final veiculosPorCliente = <int, List<Veiculo>>{};
    for (final v in a.veiculos) {
      veiculosPorCliente.putIfAbsent(v.clienteId, () => []).add(v);
    }

    final usoPeca = <int, (int vezes, int quantidade)>{};
    for (final o in a.ordens) {
      for (final item in o.itens) {
        final atual = usoPeca[item.pecaId] ?? (0, 0);
        usoPeca[item.pecaId] = (atual.$1 + 1, atual.$2 + item.quantidade);
      }
    }

    final usoServico = <int, (int vezes, double receita)>{};
    for (final o in a.ordens) {
      for (final item in o.servicos) {
        final atual = usoServico[item.servicoId] ?? (0, 0.0);
        final valor = item.valorUnitario ?? item.servico?.valor ?? 0;
        usoServico[item.servicoId] = (atual.$1 + 1, atual.$2 + valor);
      }
    }

    double totalOrdens(List<Ordem>? lista) =>
        (lista ?? const []).fold(0.0, (soma, o) => soma + o.valorTotal);

    // ---------- relatório por cliente ----------
    final relatorioClientes = <List<Object?>>[];
    for (final c in a.clientes) {
      final veiculosDoCliente = veiculosPorCliente[c.id] ?? const <Veiculo>[];
      final ordensDoCliente = veiculosDoCliente.expand(
        (v) => ordensPorVeiculo[v.id] ?? const <Ordem>[],
      );
      relatorioClientes.add([
        c.nome,
        c.cpf,
        veiculosDoCliente.length,
        ordensDoCliente.length,
        totalOrdens(ordensDoCliente.toList()).toStringAsFixed(2),
      ]);
    }

    // ---------- relatório por veículo ----------
    final relatorioVeiculos = <List<Object?>>[];
    for (final v in a.veiculos) {
      final ordensDoVeiculo = ordensPorVeiculo[v.id] ?? const [];
      relatorioVeiculos.add([
        v.placa,
        v.modelo,
        v.cliente?.nome ?? 'cliente #${v.clienteId}',
        ordensDoVeiculo.length,
        totalOrdens(ordensDoVeiculo).toStringAsFixed(2),
      ]);
    }

    // ---------- relatório por peça ----------
    final relatorioPecas = <List<Object?>>[];
    for (final p in a.pecas) {
      final uso = usoPeca[p.id] ?? (0, 0);
      relatorioPecas.add([
        p.marca,
        p.valor.toStringAsFixed(2),
        p.quantidade,
        uso.$1,
        uso.$2,
        p.descontinuada ? 'sim' : 'não',
      ]);
    }

    // ---------- relatório por serviço ----------
    final relatorioServicos = <List<Object?>>[];
    for (final s in a.servicos) {
      final uso = usoServico[s.id] ?? (0, 0.0);
      relatorioServicos.add([s.nome, s.valor.toStringAsFixed(2), uso.$1, uso.$2.toStringAsFixed(2)]);
    }

    // ---------- ganhos ----------
    final porStatus = <String, List<Ordem>>{};
    for (final o in a.ordens) {
      porStatus.putIfAbsent(o.status, () => []).add(o);
    }
    final relatorioGanhos = <List<Object?>>[];
    var totalGeral = 0.0;
    for (final status in ['aberta', 'aprovada', 'concluida']) {
      final lista = porStatus[status] ?? const [];
      final total = totalOrdens(lista);
      totalGeral += total;
      relatorioGanhos.add([status, lista.length, total.toStringAsFixed(2)]);
    }
    relatorioGanhos.add(['TOTAL', a.ordens.length, totalGeral.toStringAsFixed(2)]);

    return [
      _Relatorio(
        titulo: 'Por cliente',
        resumo: '${a.clientes.length} clientes',
        arquivo: 'relatorio_clientes.csv',
        cabecalho: const ['Cliente', 'CPF', 'Veículos', 'Ordens', 'Total gasto (R\$)'],
        linhas: relatorioClientes,
      ),
      _Relatorio(
        titulo: 'Por veículo',
        resumo: '${a.veiculos.length} veículos',
        arquivo: 'relatorio_veiculos.csv',
        cabecalho: const ['Placa', 'Modelo', 'Dono', 'Ordens', 'Total gasto (R\$)'],
        linhas: relatorioVeiculos,
      ),
      _Relatorio(
        titulo: 'Por peça',
        resumo: '${a.pecas.length} peças cadastradas',
        arquivo: 'relatorio_pecas.csv',
        cabecalho: const [
          'Marca',
          'Valor unitário (R\$)',
          'Estoque atual',
          'Vezes usada em ordens',
          'Quantidade total usada',
          'Descontinuada',
        ],
        linhas: relatorioPecas,
      ),
      _Relatorio(
        titulo: 'Por serviço',
        resumo: '${a.servicos.length} serviços cadastrados',
        arquivo: 'relatorio_servicos.csv',
        cabecalho: const ['Serviço', 'Valor (R\$)', 'Vezes prestado', 'Receita total (R\$)'],
        linhas: relatorioServicos,
      ),
      _Relatorio(
        titulo: 'Ganhos',
        resumo: 'Total geral: R\$${totalGeral.toStringAsFixed(2)}',
        arquivo: 'relatorio_ganhos.csv',
        cabecalho: const ['Status da ordem', 'Quantidade de ordens', 'Total (R\$)'],
        linhas: relatorioGanhos,
        nota: 'Considera o valor de todas as ordens por status, isso inclui as '
            'ainda abertas/aprovadas, que são receita prevista, não realizada.',
      ),
    ];
  }

  Future<void> _exportar(_Relatorio r) async {
    try {
      final caminho = await exportarCsv(r.arquivo, [r.cabecalho, ...r.linhas]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV salvo em: $caminho'), backgroundColor: Colors.green.shade700),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao exportar: $e'), backgroundColor: Colors.red.shade700),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Relatórios')),
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

            final relatorios = _montarRelatorios(snapshot.data!);

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: relatorios.length,
              itemBuilder: (context, i) => _CartaoRelatorio(
                relatorio: relatorios[i],
                onExportar: () => _exportar(relatorios[i]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CartaoRelatorio extends StatelessWidget {
  const _CartaoRelatorio({required this.relatorio, required this.onExportar});

  final _Relatorio relatorio;
  final VoidCallback onExportar;

  static const _limitePreview = 30;

  @override
  Widget build(BuildContext context) {
    final linhasPreview = relatorio.linhas.take(_limitePreview).toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        title: Text(relatorio.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(relatorio.resumo),
        children: [
          if (relatorio.nota != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(relatorio.nota!, style: Theme.of(context).textTheme.bodySmall),
            ),
          if (relatorio.linhas.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Sem dados pra esse relatório ainda.'),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DataTable(
                columns: [for (final coluna in relatorio.cabecalho) DataColumn(label: Text(coluna))],
                rows: [
                  for (final linha in linhasPreview)
                    DataRow(cells: [for (final campo in linha) DataCell(Text('$campo'))]),
                ],
              ),
            ),
          if (relatorio.linhas.length > _limitePreview)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Mostrando $_limitePreview de ${relatorio.linhas.length} — exporte o CSV pra ver tudo.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onExportar,
                icon: const Icon(Icons.download),
                label: const Text('Exportar CSV'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
