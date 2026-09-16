import 'package:flutter/material.dart';

import '../api_client.dart';
import '../app_settings.dart';
import '../models.dart';
import '../widgets/async_helpers.dart';
import '../widgets/list_states.dart';
import '../widgets/oficina_scaffold.dart';

class OrdensScreen extends StatefulWidget {
  const OrdensScreen({super.key, required this.api, required this.settings});

  final ApiClient api;
  final AppSettings settings;

  @override
  State<OrdensScreen> createState() => _OrdensScreenState();
}

class _OrdensScreenState extends State<OrdensScreen> {
  late Future<List<Ordem>> _futuro;
  String _consulta = '';

  @override
  void initState() {
    super.initState();
    _futuro = _carregar();
  }

  Future<List<Ordem>> _carregar() async {
    final json = await widget.api.get('/ordens') as List;
    return json.map((e) => Ordem.fromJson(e)).toList();
  }

  Future<void> _recarregar() {
    final futuro = _carregar();
    setState(() { _futuro = futuro; });
    return futuro;
  }

  Future<void> _aprovar(Ordem o) async {
    final ok = await executarComFeedback(context, () async {
      await widget.api.patch('/ordens/${o.id}/aprovar');
    });
    if (ok && mounted) {
      mostrarSucesso(context, 'Ordem aprovada.');
      _recarregar();
    }
  }

  Future<void> _concluir(Ordem o) async {
    final ok = await executarComFeedback(context, () async {
      await widget.api.patch('/ordens/${o.id}/concluir');
    });
    if (ok && mounted) {
      mostrarSucesso(context, 'Ordem concluída.');
      _recarregar();
    }
  }

  Future<void> _cancelar(Ordem o) async {
    final ok = await executarComFeedback(context, () async {
      await widget.api.delete('/ordens/${o.id}');
    });
    if (ok && mounted) {
      mostrarSucesso(context, 'Ordem cancelada. Peças reservadas voltaram ao estoque.');
      _recarregar();
    }
  }

  Future<void> _abrirFormularioCriar() async {
    final criado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FormularioOrdem(api: widget.api),
    );
    if (criado == true) _recarregar();
  }

  @override
  Widget build(BuildContext context) {
    return OficinaScaffold(
      titulo: 'Ordens de serviço',
      api: widget.api,
      settings: widget.settings,
      secaoAtual: 'Ordens de serviço',
      searchHint: 'Pesquisar por placa, cliente ou status...',
      onSearchChanged: (valor) => setState(() => _consulta = valor),
      body: RefreshIndicator(
        onRefresh: _recarregar,
        child: FutureBuilder<List<Ordem>>(
          future: _futuro,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ErroLista(mensagem: '${snapshot.error}', onTentarNovamente: _recarregar);
            }
            final ordens = (snapshot.data ?? [])
                .where(
                  (o) => combinaPesquisa(_consulta, [
                    o.veiculo?.placa,
                    o.veiculo?.cliente?.nome,
                    o.status,
                  ]),
                )
                .toList();
            if (ordens.isEmpty) {
              return VazioLista(
                mensagem: _consulta.isEmpty
                    ? 'Nenhuma ordem cadastrada.'
                    : 'Nenhuma ordem encontrada pra "$_consulta".',
              );
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: ordens.length,
              itemBuilder: (context, i) => _OrdemTile(
                ordem: ordens[i],
                onAprovar: _aprovar,
                onConcluir: _concluir,
                onCancelar: _cancelar,
              ),
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

class _OrdemTile extends StatelessWidget {
  const _OrdemTile({
    required this.ordem,
    required this.onAprovar,
    required this.onConcluir,
    required this.onCancelar,
  });

  final Ordem ordem;
  final void Function(Ordem) onAprovar;
  final void Function(Ordem) onConcluir;
  final void Function(Ordem) onCancelar;

  Color _corStatus(BuildContext context) {
    switch (ordem.status) {
      case 'aberta':
        return Colors.orange;
      case 'aprovada':
        return Colors.blue;
      case 'concluida':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final placa = ordem.veiculo?.placa ?? 'veículo #${ordem.veiculoId}';

    return ExpansionTile(
      leading: CircleAvatar(
        backgroundColor: _corStatus(context),
        child: const Icon(Icons.receipt_long, color: Colors.white),
      ),
      title: Text('Ordem #${ordem.id} · $placa'),
      subtitle: Text(
        'Status: ${ordem.status} · Total: R\$${ordem.valorTotal.toStringAsFixed(2)}',
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (ordem.dataHoraAbertura != null)
                Text('Aberta em: ${ordem.dataHoraAbertura!.toLocal()}'),
              if (ordem.dataHoraConclusao != null)
                Text('Concluída em: ${ordem.dataHoraConclusao!.toLocal()}'),
              const SizedBox(height: 8),
              if (ordem.itens.isNotEmpty) const Text('Peças:', style: TextStyle(fontWeight: FontWeight.bold)),
              for (final item in ordem.itens)
                Text(
                  '  ${item.quantidade}x ${item.peca?.marca ?? 'peça #${item.pecaId}'} '
                  '(R\$${item.valorUnitario?.toStringAsFixed(2) ?? '-'} cada)',
                ),
              if (ordem.servicos.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Serviços:', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              for (final item in ordem.servicos)
                Text(
                  '  ${item.servico?.nome ?? 'serviço #${item.servicoId}'} '
                  '(R\$${item.valorUnitario?.toStringAsFixed(2) ?? '-'})',
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            children: [
              if (ordem.status == 'aberta')
                TextButton(onPressed: () => onAprovar(ordem), child: const Text('Aprovar')),
              if (ordem.status == 'aprovada')
                TextButton(onPressed: () => onConcluir(ordem), child: const Text('Concluir')),
              if (ordem.status != 'concluida')
                TextButton(
                  onPressed: () => onCancelar(ordem),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Cancelar'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ItemPecaRascunho {
  final controllerId = TextEditingController();
  final controllerQtd = TextEditingController();
}

class _FormularioOrdem extends StatefulWidget {
  const _FormularioOrdem({required this.api});

  final ApiClient api;

  @override
  State<_FormularioOrdem> createState() => _FormularioOrdemState();
}

class _FormularioOrdemState extends State<_FormularioOrdem> {
  final _formKey = GlobalKey<FormState>();
  final _placa = TextEditingController();
  final List<_ItemPecaRascunho> _itens = [];
  final List<TextEditingController> _servicoIds = [];
  bool _enviando = false;

  @override
  void dispose() {
    _placa.dispose();
    for (final i in _itens) {
      i.controllerId.dispose();
      i.controllerQtd.dispose();
    }
    for (final s in _servicoIds) {
      s.dispose();
    }
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final itens = <Map<String, dynamic>>[];
    for (final item in _itens) {
      final pecaId = int.tryParse(item.controllerId.text.trim());
      final quantidade = int.tryParse(item.controllerQtd.text.trim());
      if (pecaId != null && quantidade != null) {
        itens.add({'pecaId': pecaId, 'quantidade': quantidade});
      }
    }

    final servicoIds = _servicoIds
        .map((c) => int.tryParse(c.text.trim()))
        .whereType<int>()
        .toList();

    if (itens.isEmpty && servicoIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione ao menos uma peça ou um serviço.')),
      );
      return;
    }

    setState(() => _enviando = true);

    final ok = await executarComFeedback(context, () async {
      await widget.api.post('/ordens', {
        'placa': _placa.text.trim(),
        'itens': itens,
        'servicoIds': servicoIds,
      });
    });

    if (!mounted) return;
    setState(() => _enviando = false);
    if (ok) {
      mostrarSucesso(context, 'Ordem aberta.');
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
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Nova ordem de serviço', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              TextFormField(
                controller: _placa,
                decoration: const InputDecoration(labelText: 'Placa do veículo'),
                validator: obrigatorio,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('Peças', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => setState(() => _itens.add(_ItemPecaRascunho())),
                  ),
                ],
              ),
              for (var i = 0; i < _itens.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _itens[i].controllerId,
                          decoration: const InputDecoration(labelText: 'ID da peça'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _itens[i].controllerQtd,
                          decoration: const InputDecoration(labelText: 'Quantidade'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => setState(() => _itens.removeAt(i)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Serviços', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => setState(() => _servicoIds.add(TextEditingController())),
                  ),
                ],
              ),
              for (var i = 0; i < _servicoIds.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _servicoIds[i],
                          decoration: const InputDecoration(labelText: 'ID do serviço'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => setState(() => _servicoIds.removeAt(i)),
                      ),
                    ],
                  ),
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
                    : const Text('Abrir ordem'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
