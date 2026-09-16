import 'package:flutter/material.dart';

/// Estado vazio de uma lista, sempre roláveis (AlwaysScrollableScrollPhysics)
/// para que o gesto de puxar-para-atualizar funcione mesmo sem itens.
class VazioLista extends StatelessWidget {
  const VazioLista({super.key, required this.mensagem});

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Center(child: Text(mensagem, style: Theme.of(context).textTheme.bodyLarge)),
      ],
    );
  }
}

/// Estado de erro de uma lista, com botão para tentar de novo.
class ErroLista extends StatelessWidget {
  const ErroLista({super.key, required this.mensagem, required this.onTentarNovamente});

  final String mensagem;
  final VoidCallback onTentarNovamente;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Icon(Icons.cloud_off, size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 12),
              Text(mensagem, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onTentarNovamente,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
