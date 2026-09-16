import 'package:flutter/material.dart';

import '../api_client.dart';
import '../app_settings.dart';
import '../models.dart';
import '../widgets/async_helpers.dart';
import '../widgets/list_states.dart';
import '../widgets/oficina_scaffold.dart';

class VeiculosScreen extends StatefulWidget {
  const VeiculosScreen({super.key, required this.api, required this.settings});

  final ApiClient api;
  final AppSettings settings;

  @override
  State<VeiculosScreen> createState() => _VeiculosScreenState();
}

class _VeiculosScreenState extends State<VeiculosScreen> {
  late Future<List<Veiculo>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _carregar();
  }

  Future<List<Veiculo>> _carregar() async {
    final json = await widget.api.get('/veiculos') as List;
    return json.map((e) => Veiculo.fromJson(e)).toList();
  }

  Future<void> _recarregar() {
    final futuro = _carregar();
    setState(() => _futuro = futuro);
    return futuro;
  }

  Future<void> _remover(Veiculo veiculo) async {
    final ok = await executarComFeedback(context, () async {
      await widget.api.delete('/veiculos/${veiculo.id}');
    });
    if (ok && mounted) {
      mostrarSucesso(context, 'Veículo removido.');
      _recarregar();
    }
  }

  Future<void> _abrirFormularioCriar() async {
    final criado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FormularioVeiculo(api: widget.api),
    );
    if (criado == true) _recarregar();
  }

  @override
  Widget build(BuildContext context) {
    return OficinaScaffold(
      titulo: 'Veículos',
      api: widget.api,
      settings: widget.settings,
      secaoAtual: 'Veículos',
      onRefresh: _recarregar,
      body: RefreshIndicator(
        onRefresh: _recarregar,
        child: FutureBuilder<List<Veiculo>>(
          future: _futuro,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ErroLista(mensagem: '${snapshot.error}', onTentarNovamente: _recarregar);
            }
            final veiculos = snapshot.data ?? [];
            if (veiculos.isEmpty) {
              return const VazioLista(mensagem: 'Nenhum veículo cadastrado.');
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: veiculos.length,
              itemBuilder: (context, i) {
                final v = veiculos[i];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.directions_car)),
                  title: Text('${v.placa} · ${v.modelo}'),
                  subtitle: Text(
                    'Ano: ${v.ano} · Dono: ${v.cliente?.nome ?? 'cliente #${v.clienteId}'}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmarRemocao(v),
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

  void _confirmarRemocao(Veiculo v) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover veículo'),
        content: Text('Remover o veículo "${v.placa}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _remover(v);
            },
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }
}

class _FormularioVeiculo extends StatefulWidget {
  const _FormularioVeiculo({required this.api});

  final ApiClient api;

  @override
  State<_FormularioVeiculo> createState() => _FormularioVeiculoState();
}

class _FormularioVeiculoState extends State<_FormularioVeiculo> {
  final _formKey = GlobalKey<FormState>();
  final _modelo = TextEditingController();
  final _ano = TextEditingController();
  final _placa = TextEditingController();
  final _clienteId = TextEditingController();
  bool _enviando = false;

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);

    final veiculo = Veiculo(
      modelo: _modelo.text.trim(),
      ano: int.parse(_ano.text.trim()),
      placa: _placa.text.trim(),
      clienteId: int.parse(_clienteId.text.trim()),
    );

    final ok = await executarComFeedback(context, () async {
      await widget.api.post('/veiculos', veiculo.toJson());
    });

    if (!mounted) return;
    setState(() => _enviando = false);
    if (ok) {
      mostrarSucesso(context, 'Veículo criado.');
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
            Text('Novo veículo', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            TextFormField(
              controller: _modelo,
              decoration: const InputDecoration(labelText: 'Modelo'),
              validator: obrigatorio,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _ano,
              decoration: const InputDecoration(labelText: 'Ano'),
              keyboardType: TextInputType.number,
              validator: numeroObrigatorio,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _placa,
              decoration: const InputDecoration(labelText: 'Placa'),
              validator: obrigatorio,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _clienteId,
              decoration: const InputDecoration(labelText: 'ID do cliente dono'),
              keyboardType: TextInputType.number,
              validator: numeroObrigatorio,
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
