/*
API de Serviços Mecânicos v1.0 - CLI de controle via terminal
Endpoints consumidos (ver README.md na raiz do projeto):

/clientes - Métodos: GET, POST, DELETE
/clientes/:id - Métodos: GET, DELETE
/veiculos - Métodos: GET, POST, DELETE
/veiculos/:id - Métodos: GET, DELETE
/pecas - Métodos: GET, POST
/pecas/:id - Métodos: GET
/pecas/repor - Métodos: GET
/pecas/:id/repor - Métodos: PATCH
/pecas/:id/descontinuar - Métodos: PATCH
/servicos - Métodos: GET, POST, DELETE
/servicos/:id - Métodos: GET, DELETE
/ordens - Métodos: GET, POST, DELETE
/ordens/:id - Métodos: GET, DELETE
/ordens/:id/aprovar - Métodos: PATCH
/ordens/:id/concluir - Métodos: PATCH
*/

import 'dart:io';

import 'httpHandler.dart';
import 'models.dart';

Future<void> main() async {
  final api = ApiClient();

  print('=== CLI da Oficina Mecânica ===');
  print('API: ${api.baseUrl}\n');

  var executando = true;
  while (executando) {
    print('\n--- Menu principal ---');
    print('1. Clientes');
    print('2. Veículos');
    print('3. Peças');
    print('4. Serviços');
    print('5. Ordens de serviço');
    print('0. Sair');


    switch (lerLinha('Escolha uma opção: ')) {
      case '1':
        await menuClientes(api);
      case '2':
        await menuVeiculos(api);
      case '3':
        await menuPecas(api);
      case '4':
        await menuServicos(api);
      case '5':
        await menuOrdens(api);
      case '0':
        executando = false;
      default:
        print('Opção inválida.');
    }
  }

  api.close();
  print('Até mais!');
}

// ---------- helpers de entrada ----------

String lerLinha(String prompt) {
  sleep(Duration(milliseconds: 450));
  stdout.write(prompt);
  return stdin.readLineSync()?.trim() ?? '';
}

String? lerOpcional(String prompt) {
  final valor = lerLinha(prompt);
  return valor.isEmpty ? null : valor;
}

int lerInt(String prompt) {
  while (true) {
    final valor = int.tryParse(lerLinha(prompt));
    if (valor != null) return valor;
    print('Digite um número inteiro válido.');
  }
}

int? lerIntOpcional(String prompt) {
  final valor = lerLinha(prompt);
  if (valor.isEmpty) return null;
  final numero = int.tryParse(valor);
  if (numero == null) print('Valor inválido, ignorando.');
  return numero;
}

double lerDouble(String prompt) {
  while (true) {
    final valor = double.tryParse(lerLinha(prompt).replaceAll(',', '.'));
    if (valor != null) return valor;
    print('Digite um número válido.');
  }
}

/// Executa uma ação da API tratando erros de forma amigável.
Future<void> executar(Future<void> Function() acao) async {
  try {
    await acao();
  } on ApiException catch (e) {
    print('✗ $e');
  } on SocketException {
    print('✗ Não foi possível conectar à API. Verifique se ela está rodando.');
  } catch (e) {
    print('✗ Erro inesperado: $e');
  }
}

void listar(String titulo, List itens) {
  print('\n$titulo (${itens.length}):');
  if (itens.isEmpty) {
    print('  (nenhum registro encontrado)');
    return;
  }
  for (final item in itens) {
    print(item);
  }
}

// ---------- clientes ----------

Future<void> menuClientes(ApiClient api) async {
  print('\n--- Clientes ---');
  print('1. Listar');
  print('2. Buscar por ID');
  print('3. Criar');
  print('4. Remover');
  print('0. Voltar');

  switch (lerLinha('Escolha uma opção: ')) {
    case '1':
      await executar(() async {
        final json = await api.get('/clientes') as List;
        listar('Clientes', json.map((e) => Cliente.fromJson(e)).toList());
      });
    case '2':
      final id = lerInt('ID do cliente: ');
      await executar(() async {
        final json = await api.get('/clientes/$id');
        print(Cliente.fromJson(json));
      });
    case '3':
      final nome = lerLinha('Nome: ');
      final cpf = lerLinha('CPF: ');
      final telefone = lerOpcional('Telefone (opcional): ');
      final endereco = lerOpcional('Endereço (opcional): ');
      await executar(() async {
        final cliente = Cliente(
          nome: nome,
          cpf: cpf,
          telefone: telefone,
          endereco: endereco,
        );
        final json = await api.post('/clientes', cliente.toJson());
        print('✓ Cliente criado: ${Cliente.fromJson(json)}');
      });
    case '4':
      final id = lerInt('ID do cliente a remover: ');
      await executar(() async {
        await api.delete('/clientes/$id');
        print('✓ Cliente #$id removido.');
      });
    case '0':
      return;
    default:
      print('Opção inválida.');
  }
}

// ---------- veiculos ----------

Future<void> menuVeiculos(ApiClient api) async {
  print('\n--- Veículos ---');
  print('1. Listar');
  print('2. Buscar por ID');
  print('3. Criar');
  print('4. Remover');
  print('0. Voltar');

  switch (lerLinha('Escolha uma opção: ')) {
    case '1':
      await executar(() async {
        final json = await api.get('/veiculos') as List;
        listar('Veículos', json.map((e) => Veiculo.fromJson(e)).toList());
      });
    case '2':
      final id = lerInt('ID do veículo: ');
      await executar(() async {
        final json = await api.get('/veiculos/$id');
        print(Veiculo.fromJson(json));
      });
    case '3':
      final modelo = lerLinha('Modelo: ');
      final ano = lerInt('Ano: ');
      final placa = lerLinha('Placa: ');
      final clienteId = lerInt('ID do cliente dono do veículo: ');
      await executar(() async {
        final veiculo = Veiculo(
          modelo: modelo,
          ano: ano,
          placa: placa,
          clienteId: clienteId,
        );
        final json = await api.post('/veiculos', veiculo.toJson());
        print('✓ Veículo criado: ${Veiculo.fromJson(json)}');
      });
    case '4':
      final id = lerInt('ID do veículo a remover: ');
      await executar(() async {
        await api.delete('/veiculos/$id');
        print('✓ Veículo #$id removido.');
      });
    case '0':
      return;
    default:
      print('Opção inválida.');
  }
}

// ---------- pecas ----------

Future<void> menuPecas(ApiClient api) async {
  print('\n--- Peças ---');
  print('1. Listar');
  print('2. Buscar por ID');
  print('3. Listar peças a repor');
  print('4. Criar');
  print('5. Repor estoque');
  print('6. Descontinuar');
  print('0. Voltar');

  switch (lerLinha('Escolha uma opção: ')) {
    case '1':
      await executar(() async {
        final json = await api.get('/pecas') as List;
        listar('Peças', json.map((e) => Peca.fromJson(e)).toList());
      });
    case '2':
      final id = lerInt('ID da peça: ');
      await executar(() async {
        final json = await api.get('/pecas/$id');
        print(Peca.fromJson(json));
      });
    case '3':
      await executar(() async {
        final json = await api.get('/pecas/repor') as List;
        listar('Peças no ponto de reposição', json.map((e) => Peca.fromJson(e)).toList());
      });
    case '4':
      final marca = lerLinha('Marca: ');
      final valor = lerDouble('Valor: ');
      final quantidade = lerIntOpcional('Quantidade inicial (opcional, padrão 0): ');
      final pontoReposicao = lerIntOpcional('Ponto de reposição (opcional, padrão 0): ');
      await executar(() async {
        final peca = Peca(
          marca: marca,
          valor: valor,
          quantidade: quantidade ?? 0,
          pontoReposicao: pontoReposicao ?? 0,
        );
        final json = await api.post('/pecas', peca.toJson());
        print('✓ Peça criada: ${Peca.fromJson(json)}');
      });
    case '5':
      final id = lerInt('ID da peça: ');
      final quantidade = lerInt('Quantidade a repor: ');
      await executar(() async {
        final json = await api.patch('/pecas/$id/repor', {'quantidade': quantidade});
        print('✓ Estoque atualizado: ${Peca.fromJson(json)}');
      });
    case '6':
      final id = lerInt('ID da peça a descontinuar: ');
      await executar(() async {
        final json = await api.patch('/pecas/$id/descontinuar');
        print('✓ Peça descontinuada: ${Peca.fromJson(json)}');
      });
    case '0':
      return;
    default:
      print('Opção inválida.');
  }
}

// ---------- servicos ----------

Future<void> menuServicos(ApiClient api) async {
  print('\n--- Serviços ---');
  print('1. Listar');
  print('2. Buscar por ID');
  print('3. Criar');
  print('4. Remover');
  print('0. Voltar');

  switch (lerLinha('Escolha uma opção: ')) {
    case '1':
      await executar(() async {
        final json = await api.get('/servicos') as List;
        listar('Serviços', json.map((e) => Servico.fromJson(e)).toList());
      });
    case '2':
      final id = lerInt('ID do serviço: ');
      await executar(() async {
        final json = await api.get('/servicos/$id');
        print(Servico.fromJson(json));
      });
    case '3':
      final nome = lerLinha('Nome: ');
      final valor = lerDouble('Valor da mão de obra: ');
      final descricao = lerOpcional('Descrição (opcional): ');
      await executar(() async {
        final servico = Servico(nome: nome, valor: valor, descricao: descricao);
        final json = await api.post('/servicos', servico.toJson());
        print('✓ Serviço criado: ${Servico.fromJson(json)}');
      });
    case '4':
      final id = lerInt('ID do serviço a remover: ');
      await executar(() async {
        await api.delete('/servicos/$id');
        print('✓ Serviço #$id removido.');
      });
    case '0':
      return;
    default:
      print('Opção inválida.');
  }
}

// ---------- ordens ----------

Future<void> menuOrdens(ApiClient api) async {
  print('\n--- Ordens de serviço ---');
  print('1. Listar');
  print('2. Buscar por ID');
  print('3. Abrir nova ordem');
  print('4. Aprovar ordem');
  print('5. Concluir ordem');
  print('6. Cancelar ordem');
  print('0. Voltar');

  switch (lerLinha('Escolha uma opção: ')) {
    case '1':
      await executar(() async {
        final json = await api.get('/ordens') as List;
        listar('Ordens', json.map((e) => Ordem.fromJson(e)).toList());
      });
    case '2':
      final id = lerInt('ID da ordem: ');
      await executar(() async {
        final json = await api.get('/ordens/$id');
        print(Ordem.fromJson(json));
      });
    case '3':
      await abrirOrdem(api);
    case '4':
      final id = lerInt('ID da ordem a aprovar: ');
      await executar(() async {
        final json = await api.patch('/ordens/$id/aprovar');
        print('✓ Ordem aprovada: ${Ordem.fromJson(json)}');
      });
    case '5':
      final id = lerInt('ID da ordem a concluir: ');
      await executar(() async {
        final json = await api.patch('/ordens/$id/concluir');
        print('✓ Ordem concluída: ${Ordem.fromJson(json)}');
      });
    case '6':
      final id = lerInt('ID da ordem a cancelar: ');
      await executar(() async {
        await api.delete('/ordens/$id');
        print('✓ Ordem #$id cancelada. As peças reservadas voltaram ao estoque.');
      });
    case '0':
      return;
    default:
      print('Opção inválida.');
  }
}

Future<void> abrirOrdem(ApiClient api) async {
  final placa = lerLinha('Placa do veículo: ');

  final itens = <Map<String, dynamic>>[];
  print('Adicione as peças da ordem (deixe o ID vazio para parar):');
  while (true) {
    final idTexto = lerLinha('  ID da peça: ');
    if (idTexto.isEmpty) break;
    final pecaId = int.tryParse(idTexto);
    if (pecaId == null) {
      print('  ID inválido.');
      continue;
    }
    final quantidade = lerInt('  Quantidade: ');
    itens.add({'pecaId': pecaId, 'quantidade': quantidade});
  }

  final servicoIds = <int>[];
  print('Adicione os serviços da ordem (deixe o ID vazio para parar):');
  while (true) {
    final idTexto = lerLinha('  ID do serviço: ');
    if (idTexto.isEmpty) break;
    final servicoId = int.tryParse(idTexto);
    if (servicoId == null) {
      print('  ID inválido.');
      continue;
    }
    servicoIds.add(servicoId);
  }

  await executar(() async {
    final json = await api.post('/ordens', {
      'placa': placa,
      'itens': itens,
      'servicoIds': servicoIds,
    });
    print('✓ Ordem aberta: ${Ordem.fromJson(json)}');
  });
}
