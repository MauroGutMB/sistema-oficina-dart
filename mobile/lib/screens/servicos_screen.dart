import 'package:flutter/material.dart';

import '../api_client.dart';
import '../app_settings.dart';
import '../models.dart';
import '../widgets/async_helpers.dart';
import '../widgets/list_states.dart';
import '../widgets/oficina_scaffold.dart';

class ServicosScreen extends StatefulWidget {
  const ServicosScreen({super.key, required this.api, required this.settings});

  final ApiClient api;
  final AppSettings settings;

  @override
  State<ServicosScreen> createState() => _ServicosScreenState();
}

class _ServicosScreenState extends State<ServicosScreen> {
  late Future<List<Servico>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _carregar();
  }

  Future<List<Servico>> _carregar() async {
    final json = await widget.api.get('/servicos') as List;
    return json.map((e) => Servico.fromJson(e)).toList();
  }

  Future<void> _recarregar() {
    final futuro = _carregar();
    setState(() => _futuro = futuro);
    return futuro;
  }

  Future<void> _remover(Servico servico) async {
    final ok = await executarComFeedback(context, () async {
      await widget.api.delete('/servicos/${servico.id}');
    });
    if (ok && mounted) {
      mostrarSucesso(context, 'Serviço removido.');
      _recarregar();
    }
  }

  Future<void> _abrirFormularioCriar() async {
    final criado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FormularioServico(api: widget.api),
    );
    if (criado == true) _recarregar();
  }

  @override
  Widget build(BuildContext context) {
    return OficinaScaffold(
      titulo: 'Serviços',
      api: widget.api,
      settings: widget.settings,
      secaoAtual: 'Serviços',
      onRefresh: _recarregar,
      body: RefreshIndicator(
        onRefresh: _recarregar,
        child: FutureBuilder<List<Servico>>(
          future: _futuro,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ErroLista(mensagem: '${snapshot.error}', onTentarNovamente: _recarregar);
            }
            final servicos = snapshot.data ?? [];
            if (servicos.isEmpty) {
              return const VazioLista(mensagem: 'Nenhum serviço cadastrado.');
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: servicos.length,
              itemBuilder: (context, i) {
                final s = servicos[i];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.build)),
                  title: Text(s.nome),
                  subtitle: Text(
                    'R\$${s.valor.toStringAsFixed(2)}'
                    '${s.descricao != null && s.descricao!.isNotEmpty ? ' · ${s.descricao}' : ''}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmarRemocao(s),
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

  void _confirmarRemocao(Servico s) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover serviço'),
        content: Text('Remover "${s.nome}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _remover(s);
            },
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }
}

class _FormularioServico extends StatefulWidget {
  const _FormularioServico({required this.api});

  final ApiClient api;

  @override
  State<_FormularioServico> createState() => _FormularioServicoState();
}

class _FormularioServicoState extends State<_FormularioServico> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _valor = TextEditingController();
  final _descricao = TextEditingController();
  bool _enviando = false;

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);

    final servico = Servico(
      nome: _nome.text.trim(),
      valor: double.parse(_valor.text.trim().replaceAll(',', '.')),
      descricao: _descricao.text.trim(),
    );

    final ok = await executarComFeedback(context, () async {
      await widget.api.post('/servicos', servico.toJson());
    });

    if (!mounted) return;
    setState(() => _enviando = false);
    if (ok) {
      mostrarSucesso(context, 'Serviço criado.');
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
            Text('Novo serviço', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            TextFormField(
              controller: _nome,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: obrigatorio,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _valor,
              decoration: const InputDecoration(labelText: 'Valor da mão de obra'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: numeroObrigatorio,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descricao,
              decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
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
