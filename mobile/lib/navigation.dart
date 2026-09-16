import 'package:flutter/material.dart';

import 'api_client.dart';
import 'app_settings.dart';
import 'screens/clientes_screen.dart';
import 'screens/ordens_screen.dart';
import 'screens/pecas_screen.dart';
import 'screens/servicos_screen.dart';
import 'screens/veiculos_screen.dart';

/// Uma seção do CRUD, usada tanto pelos cartões da home quanto pelo menu
/// lateral — mantém as duas listas sempre em sincronia.
class Secao {
  const Secao(this.titulo, this.icone, this.builder);

  final String titulo;
  final IconData icone;
  final Widget Function(ApiClient api, AppSettings settings) builder;
}

final secoes = <Secao>[
  Secao(
    'Clientes',
    Icons.person_outline,
    (api, settings) => ClientesScreen(api: api, settings: settings),
  ),
  Secao(
    'Veículos',
    Icons.directions_car_outlined,
    (api, settings) => VeiculosScreen(api: api, settings: settings),
  ),
  Secao(
    'Peças',
    Icons.settings_outlined,
    (api, settings) => PecasScreen(api: api, settings: settings),
  ),
  Secao(
    'Serviços',
    Icons.build_outlined,
    (api, settings) => ServicosScreen(api: api, settings: settings),
  ),
  Secao(
    'Ordens de serviço',
    Icons.receipt_long_outlined,
    (api, settings) => OrdensScreen(api: api, settings: settings),
  ),
];
