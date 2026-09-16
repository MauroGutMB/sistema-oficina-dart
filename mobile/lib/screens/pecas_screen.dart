import 'package:flutter/material.dart';

import '../api_client.dart';
import '../app_settings.dart';
import '../models.dart';
import '../widgets/async_helpers.dart';
import '../widgets/list_states.dart';
import '../widgets/oficina_scaffold.dart';

class PecasScreen extends StatefulWidget {
  const PecasScreen({super.key, required this.api, required this.settings});

  final ApiClient api;
  final AppSettings settings;

  @override
  State<PecasScreen> createState() => _PecasScreenState();
}

class _PecasScreenState extends State<PecasScreen> {
  late Future<List<Peca>> _futuro;
  bool _somenteParaRepor = false;
  String _consulta = '';

  @override
  void initState() {
    super.initState();
    _futuro = _carregar();
  }

  Future<List<Peca>> _carregar() async {
    final json =
        await widget.api.get(_somenteParaRepor ? '/pecas/repor' : '/pecas') as List;
    return json.map((e) => Peca.fromJson(e)).toList();
  }

  Future<void> _recarregar() {
    final futuro = _carregar();
    setState(() { _futuro = futuro; });
    return futuro;
  }

  Future<void> _repor(Peca peca) async {
    final quantidade = await _pedirQuantidade(context);
    if (quantidade == null || !mounted) return;

    final ok = await executarComFeedback(context, () async {
      await widget.api.patch('/pecas/${peca.id}/repor', {'quantidade': quantidade});
    });
    if (ok && mounted) {
      mostrarSucesso(context, 'Estoque reposto.');
      _recarregar();
    }
  }

  Future<void> _descontinuar(Peca peca) async {
    final ok = await executarComFeedback(context, () async {
      await widget.api.patch('/pecas/${peca.id}/descontinuar');
    });
    if (ok && mounted) {
      mostrarSucesso(context, 'Peça descontinuada.');
      _recarregar();
    }
  }

  Future<void> _abrirFormularioCriar() async {
    final criado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FormularioPeca(api: widget.api),
    );
    if (criado == true) _recarregar();
  }

  Future<int?> _pedirQuantidade(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Repor estoque'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Quantidade a repor'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, int.tryParse(controller.text)),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OficinaScaffold(
      titulo: 'Peças',
      api: widget.api,
      settings: widget.settings,
      secaoAtual: 'Peças',
      searchHint: 'Pesquisar por marca...',
      onSearchChanged: (valor) => setState(() => _consulta = valor),
      appBarActions: [
        IconButton(
          tooltip: _somenteParaRepor ? 'Mostrar todas' : 'Mostrar só as a repor',
          icon: Icon(_somenteParaRepor ? Icons.filter_alt : Icons.filter_alt_outlined),
          onPressed: () => setState(() {
            _somenteParaRepor = !_somenteParaRepor;
            _futuro = _carregar();
          }),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: _recarregar,
        child: FutureBuilder<List<Peca>>(
          future: _futuro,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ErroLista(mensagem: '${snapshot.error}', onTentarNovamente: _recarregar);
            }
            final pecas = (snapshot.data ?? [])
                .where((p) => combinaPesquisa(_consulta, [p.marca]))
                .toList();
            if (pecas.isEmpty) {
              return VazioLista(
                mensagem: _consulta.isNotEmpty
                    ? 'Nenhuma peça encontrada pra "$_consulta".'
                    : (_somenteParaRepor
                        ? 'Nenhuma peça no ponto de reposição.'
                        : 'Nenhuma peça cadastrada.'),
              );
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: pecas.length,
              itemBuilder: (context, i) {
                final p = pecas[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: p.descontinuada ? Colors.grey : null,
                    child: const Icon(Icons.settings),
                  ),
                  title: Text(
                    p.marca,
                    style: p.descontinuada
                        ? const TextStyle(decoration: TextDecoration.lineThrough)
                        : null,
                  ),
                  subtitle: Text(
                    'R\$${p.valor.toStringAsFixed(2)} · Qtd: ${p.quantidade} · '
                    'Repor em: ${p.pontoReposicao}'
                    '${p.descontinuada ? ' · DESCONTINUADA' : ''}',
                  ),
                  trailing: p.descontinuada
                      ? null
                      : PopupMenuButton<String>(
                          onSelected: (acao) {
                            if (acao == 'repor') _repor(p);
                            if (acao == 'descontinuar') _descontinuar(p);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'repor', child: Text('Repor estoque')),
                            PopupMenuItem(value: 'descontinuar', child: Text('Descontinuar')),
                          ],
                        ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirFormularioCriar,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FormularioPeca extends StatefulWidget {
  const _FormularioPeca({required this.api});

  final ApiClient api;

  @override
  State<_FormularioPeca> createState() => _FormularioPecaState();
}

class _FormularioPecaState extends State<_FormularioPeca> {
  final _formKey = GlobalKey<FormState>();
  final _marca = TextEditingController();
  final _valor = TextEditingController();
  final _quantidade = TextEditingController();
  final _pontoReposicao = TextEditingController();
  bool _enviando = false;

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);

    final peca = Peca(
      marca: _marca.text.trim(),
      valor: double.parse(_valor.text.trim().replaceAll(',', '.')),
      quantidade: _quantidade.text.trim().isEmpty ? 0 : int.parse(_quantidade.text.trim()),
      pontoReposicao:
          _pontoReposicao.text.trim().isEmpty ? 0 : int.parse(_pontoReposicao.text.trim()),
    );

    final ok = await executarComFeedback(context, () async {
      await widget.api.post('/pecas', peca.toJson());
    });

    if (!mounted) return;
    setState(() => _enviando = false);
    if (ok) {
      mostrarSucesso(context, 'Peça criada.');
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Nova peça', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            TextFormField(
              controller: _marca,
              decoration: const InputDecoration(labelText: 'Marca'),
              validator: obrigatorio,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _valor,
              decoration: const InputDecoration(labelText: 'Valor'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: numeroObrigatorio,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _quantidade,
              decoration: const InputDecoration(labelText: 'Quantidade inicial (opcional)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _pontoReposicao,
              decoration: const InputDecoration(labelText: 'Ponto de reposição (opcional)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: _enviando ? null : _salvar,
              child: _enviando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
