import 'package:flutter/material.dart';

import 'api_client.dart';
import 'app_settings.dart';
import 'navigation.dart';
import 'screens/relatorios_screen.dart';
import 'widgets/app_drawer.dart';
import 'widgets/status_servidor.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.api, required this.settings});

  final ApiClient api;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final secoesGrade = secoes.where((s) => s.titulo != 'Ordens de serviço');
    final secaoOrdens = secoes.firstWhere((s) => s.titulo == 'Ordens de serviço');

    void abrir(Secao secao) => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => secao.builder(api, settings)),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Oficina Mecânica')),
      drawer: AppDrawer(api: api, settings: settings),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.05,
            children: [
              for (final secao in secoesGrade)
                _CartaoSecao(secao: secao, onTap: () => abrir(secao)),
            ],
          ),
          const SizedBox(height: 12),
          _CartaoDestaque(
            icone: Icons.summarize_outlined,
            titulo: 'Relatórios',
            corFundoClaro: Colors.amber.shade300,
            corFundoEscuro: Colors.amber.shade800.withValues(alpha: 0.45),
            corConteudoClaro: Colors.amber.shade900,
            corConteudoEscuro: Colors.amberAccent.shade100,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RelatoriosScreen(api: api, settings: settings)),
            ),
          ),
          const SizedBox(height: 12),
          _CartaoDestaque(
            icone: secaoOrdens.icone,
            titulo: secaoOrdens.titulo,
            corFundoClaro: Colors.green.shade200,
            corFundoEscuro: Colors.green.shade800.withValues(alpha: 0.45),
            corConteudoClaro: Colors.green.shade900,
            corConteudoEscuro: Colors.greenAccent.shade100,
            onTap: () => abrir(secaoOrdens),
          ),
          const SizedBox(height: 12),
          StatusServidor(api: api, settings: settings),
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

/// Cartão retangular (ocupa a largura toda, as duas colunas da grade) pra
/// destacar uma seção específica com uma cor chamativa própria — usado por
/// Relatórios (amarelo) e Ordens de serviço (verde).
class _CartaoDestaque extends StatelessWidget {
  const _CartaoDestaque({
    required this.icone,
    required this.titulo,
    required this.onTap,
    required this.corFundoClaro,
    required this.corFundoEscuro,
    required this.corConteudoClaro,
    required this.corConteudoEscuro,
  });

  final IconData icone;
  final String titulo;
  final VoidCallback onTap;
  final Color corFundoClaro;
  final Color corFundoEscuro;
  final Color corConteudoClaro;
  final Color corConteudoEscuro;

  @override
  Widget build(BuildContext context) {
    final escuro = Theme.of(context).brightness == Brightness.dark;
    final corFundo = escuro ? corFundoEscuro : corFundoClaro;
    final corConteudo = escuro ? corConteudoEscuro : corConteudoClaro;

    return Card(
      color: corFundo,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: corConteudo.withValues(alpha: 0.18),
                child: Icon(icone, size: 26, color: corConteudo),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: corConteudo, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
