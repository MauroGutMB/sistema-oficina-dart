import 'package:flutter/material.dart';

import '../api_client.dart';
import '../app_settings.dart';
import '../models.dart';
import '../widgets/async_helpers.dart';
import '../widgets/list_states.dart';
import '../widgets/oficina_scaffold.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key, required this.api, required this.settings});

  final ApiClient api;
  final AppSettings settings;

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  late Future<List<Cliente>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _carregar();
  }

  Future<List<Cliente>> _carregar() async {
    final json = await widget.api.get('/clientes') as List;
    return json.map((e) => Cliente.fromJson(e)).toList();
  }

  /// Retorna o Future para que o RefreshIndicator espere o carregamento
  /// terminar antes de esconder o indicador.
  Future<void> _recarregar() {
    final futuro = _carregar();
    setState(() => _futuro = futuro);
    return futuro;
  }

  Future<void> _remover(Cliente cliente) async {
    final ok = await executarComFeedback(context, () async {
      await widget.api.delete('/clientes/${cliente.id}');
    });
    if (ok && mounted) {
      mostrarSucesso(context, 'Cliente removido.');
      _recarregar();
    }
  }

  Future<void> _abrirFormularioCriar() async {
    final criado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FormularioCliente(api: widget.api),
    );
    if (criado == true) _recarregar();
  }

  @override
  Widget build(BuildContext context) {
    return OficinaScaffold(
      titulo: 'Clientes',
      api: widget.api,
      settings: widget.settings,
      secaoAtual: 'Clientes',
      onRefresh: _recarregar,
      body: RefreshIndicator(
        onRefresh: _recarregar,
        child: FutureBuilder<List<Cliente>>(
          future: _futuro,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _erro(snapshot.error);
            }
            final clientes = snapshot.data ?? [];
            if (clientes.isEmpty) {
              return const VazioLista(mensagem: 'Nenhum cliente cadastrado.');
            }
            return ListView.builder(
              // sempre "arrastável", mesmo com poucos itens, senão o gesto de
              // puxar para atualizar não é reconhecido.
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: clientes.length,
              itemBuilder: (context, i) {
                final c = clientes[i];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(c.nome),
                  subtitle: Text(
                    'CPF: ${c.cpf}'
                    '${c.telefone != null ? ' · Tel: ${c.telefone}' : ''}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmarRemocao(c),
                  ),
                  onTap: () => _mostrarDetalhes(c),
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

  Widget _erro(Object? error) => ErroLista(mensagem: '$error', onTentarNovamente: _recarregar);

  void _confirmarRemocao(Cliente c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover cliente'),
        content: Text('Remover "${c.nome}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _remover(c);
            },
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  void _mostrarDetalhes(Cliente c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(c.nome),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CPF: ${c.cpf}'),
            Text('Telefone: ${c.telefone ?? '-'}'),
            Text('Endereço: ${c.endereco ?? '-'}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
        ],
      ),
    );
  }
}

class _FormularioCliente extends StatefulWidget {
  const _FormularioCliente({required this.api});

  final ApiClient api;

  @override
  State<_FormularioCliente> createState() => _FormularioClienteState();
}

class _FormularioClienteState extends State<_FormularioCliente> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _cpf = TextEditingController();
  final _telefone = TextEditingController();
  final _endereco = TextEditingController();
  bool _enviando = false;

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);

    final cliente = Cliente(
      nome: _nome.text.trim(),
      cpf: _cpf.text.trim(),
      telefone: _telefone.text.trim(),
      endereco: _endereco.text.trim(),
    );

    final ok = await executarComFeedback(context, () async {
      await widget.api.post('/clientes', cliente.toJson());
    });

    if (!mounted) return;
    setState(() => _enviando = false);
    if (ok) {
      mostrarSucesso(context, 'Cliente criado.');
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
            Text('Novo cliente', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            TextFormField(
              controller: _nome,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: obrigatorio,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _cpf,
              decoration: const InputDecoration(labelText: 'CPF'),
              validator: obrigatorio,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _telefone,
              decoration: const InputDecoration(labelText: 'Telefone (opcional)'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _endereco,
              decoration: const InputDecoration(labelText: 'Endereço (opcional)'),
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
