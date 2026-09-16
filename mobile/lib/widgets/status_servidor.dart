import 'package:flutter/material.dart';

import '../api_client.dart';
import '../app_settings.dart';
import '../screens/settings_screen.dart';

/// Componente da home que mostra se a API configurada está respondendo
/// agora. Verde com ✓ quando conecta, vermelho com ✗ quando falha — e
/// tocar nele sempre leva pra tela de Conexão pra ajustar a URL.
class StatusServidor extends StatefulWidget {
  const StatusServidor({super.key, required this.api, required this.settings});

  final ApiClient api;
  final AppSettings settings;

  @override
  State<StatusServidor> createState() => _StatusServidorState();
}

class _StatusServidorState extends State<StatusServidor> {
  bool? _conectado; // null = ainda verificando

  @override
  void initState() {
    super.initState();
    _verificar();
  }

  Future<void> _verificar() async {
    setState(() => _conectado = null);
    final ok = await widget.api.testarConexao();
    if (!mounted) return;
    setState(() => _conectado = ok);
  }

  void _abrirConexao() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(api: widget.api, settings: widget.settings),
      ),
    );
    // ao voltar da tela de Conexão, reflete se a URL configurada mudou
    if (mounted) _verificar();
  }

  @override
  Widget build(BuildContext context) {
    final verificando = _conectado == null;
    final conectado = _conectado == true;
    final escuro = Theme.of(context).brightness == Brightness.dark;

    final Color corFundo;
    final Color corConteudo;
    if (verificando) {
      corFundo = Theme.of(context).colorScheme.surfaceContainerHighest;
      corConteudo = Theme.of(context).colorScheme.onSurfaceVariant;
    } else if (conectado) {
      corFundo = escuro ? Colors.green.shade900.withValues(alpha: 0.4) : Colors.green.shade100;
      corConteudo = escuro ? Colors.greenAccent.shade100 : Colors.green.shade900;
    } else {
      corFundo = escuro ? Colors.red.shade900.withValues(alpha: 0.4) : Colors.red.shade100;
      corConteudo = escuro ? Colors.redAccent.shade100 : Colors.red.shade900;
    }

    return Card(
      color: corFundo,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _abrirConexao,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (verificando)
                SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: corConteudo),
                )
              else
                Icon(conectado ? Icons.check_circle : Icons.cancel, color: corConteudo),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  verificando
                      ? 'Verificando conexão com a API...'
                      : (conectado
                          ? 'Conectado à API'
                          : 'Falha na conexão. Toque para ajustar a URL'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: corConteudo, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
