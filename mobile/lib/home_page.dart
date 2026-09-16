import 'package:flutter/material.dart';

import 'api_client.dart';
import 'app_settings.dart';
import 'navigation.dart';
import 'widgets/app_drawer.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.api, required this.settings});

  final ApiClient api;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Oficina Mecânica')),
      drawer: AppDrawer(api: api, settings: settings),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.05,
        children: [
          for (final secao in secoes)
            _CartaoSecao(
              secao: secao,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => secao.builder(api, settings)),
              ),
            ),
        ],
      ),
    );
  }
}

class _CartaoSecao extends StatelessWidget {
  const _CartaoSecao({required this.secao, required this.onTap});

  final Secao secao;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: scheme.primaryContainer,
                child: Icon(secao.icone, size: 28, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(height: 12),
              Text(
                secao.titulo,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
