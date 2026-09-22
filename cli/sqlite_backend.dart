/*
Backend local em SQLite, usado como fallback quando nenhuma API HTTP
responde (nem OFICINA_API_URL, nem o gist, nem localhost:3000). Reimplementa
em Dart as mesmas regras de negócio de api/service.ts (as validações, os
status de erro e o formato de resposta são pensados pra bater com o que a
API real devolveria), pra que main.dart funcione idêntico não importa qual
dos dois backends está por trás.

O arquivo .db fica ao lado deste script (cli/oficina_local.db), criado na
primeira vez que o CLI cai nesse fallback.
*/

import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import 'api_como_servico.dart';
import 'httpHandler.dart' show ApiException;

class SqliteApiClient implements ApiComoServico {
  SqliteApiClient._(this._db, this._caminho);

  final Database _db;
  final String _caminho;

  factory SqliteApiClient.abrir({String? caminho}) {
    final arquivo = caminho ?? _caminhoPadrao();
    final db = sqlite3.open(arquivo);
    db.execute('PRAGMA foreign_keys = ON;');
    _criarSchema(db);
    return SqliteApiClient._(db, arquivo);
  }

  static String _caminhoPadrao() {
    final dirDoScript = File(Platform.script.toFilePath()).parent.path;
    return '$dirDoScript/oficina_local.db';
  }

  static void _criarSchema(Database db) {
    db.execute('''
      CREATE TABLE IF NOT EXISTS Cliente (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        cpf TEXT NOT NULL UNIQUE,
        telefone TEXT,
        endereco TEXT
      )
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS Veiculo (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        modelo TEXT NOT NULL,
        ano INTEGER NOT NULL,
        placa TEXT NOT NULL UNIQUE,
        clienteId INTEGER NOT NULL REFERENCES Cliente(id)
      )
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS Peca (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        marca TEXT NOT NULL,
        valor REAL NOT NULL,
        quantidade INTEGER NOT NULL DEFAULT 0,
        pontoReposicao INTEGER NOT NULL DEFAULT 0,
        descontinuada INTEGER NOT NULL DEFAULT 0
      )
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS Servico (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        valor REAL NOT NULL,
        descricao TEXT
      )
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS Ordem (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        veiculoId INTEGER NOT NULL REFERENCES Veiculo(id),
        valorTotal REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'aberta',
        dataHoraAbertura TEXT NOT NULL,
        dataHoraConclusao TEXT
      )
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS OrdemPeca (
        ordemId INTEGER NOT NULL REFERENCES Ordem(id) ON DELETE CASCADE,
        pecaId INTEGER NOT NULL REFERENCES Peca(id),
        quantidade INTEGER NOT NULL,
        valorUnitario REAL NOT NULL,
        PRIMARY KEY (ordemId, pecaId)
      )
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS OrdemServico (
        ordemId INTEGER NOT NULL REFERENCES Ordem(id) ON DELETE CASCADE,
        servicoId INTEGER NOT NULL REFERENCES Servico(id),
        valorUnitario REAL NOT NULL,
        PRIMARY KEY (ordemId, servicoId)
      )
    ''');
  }

  @override
  String get origem => 'SQLite local ($_caminho)';

  @override
  void close() => _db.dispose();

  // ---------- despacho, imitando as rotas da API ----------

  @override
  Future<dynamic> get(String path) async => _get(_segmentos(path));

  @override
  Future<dynamic> post(String path, [Map<String, dynamic>? corpo]) async =>
      _post(_segmentos(path), corpo ?? const {});

  @override
  Future<dynamic> patch(String path, [Map<String, dynamic>? corpo]) async =>
      _patch(_segmentos(path), corpo ?? const {});

  @override
  Future<dynamic> delete(String path) async => _delete(_segmentos(path));

  List<String> _segmentos(String path) =>
      path.split('/').where((s) => s.isNotEmpty).toList();

  T _transacao<T>(T Function() acao) {
    _db.execute('BEGIN');
    try {
      final resultado = acao();
      _db.execute('COMMIT');
      return resultado;
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  // ---------- conversão linha -> JSON ----------

  Map<String, dynamic> _linhaCliente(Row r) => {
    'id': r['id'],
    'nome': r['nome'],
    'cpf': r['cpf'],
    'telefone': r['telefone'],
    'endereco': r['endereco'],
  };

  Map<String, dynamic> _linhaVeiculo(Row r) => {
    'id': r['id'],
    'modelo': r['modelo'],
    'ano': r['ano'],
    'placa': r['placa'],
    'clienteId': r['clienteId'],
  };

  Map<String, dynamic> _linhaPeca(Row r) => {
    'id': r['id'],
    'marca': r['marca'],
    'valor': r['valor'],
    'quantidade': r['quantidade'],
    'pontoReposicao': r['pontoReposicao'],
    'descontinuada': r['descontinuada'] == 1,
  };

  Map<String, dynamic> _linhaServico(Row r) => {
    'id': r['id'],
    'nome': r['nome'],
    'valor': r['valor'],
    'descricao': r['descricao'],
  };

  Map<String, dynamic> _linhaOrdem(Row r) => {
    'id': r['id'],
    'veiculoId': r['veiculoId'],
    'valorTotal': r['valorTotal'],
    'status': r['status'],
    'dataHoraAbertura': r['dataHoraAbertura'],
    'dataHoraConclusao': r['dataHoraConclusao'],
  };

  // ---------- buscas internas ----------

  Map<String, dynamic>? _clientePorId(int id) {
    final linhas = _db.select('SELECT * FROM Cliente WHERE id = ?', [id]);
    return linhas.isEmpty ? null : _linhaCliente(linhas.first);
  }

  Map<String, dynamic>? _veiculoPorId(int id) {
    final linhas = _db.select('SELECT * FROM Veiculo WHERE id = ?', [id]);
    return linhas.isEmpty ? null : _linhaVeiculo(linhas.first);
  }

  Map<String, dynamic>? _veiculoPorPlaca(String placa) {
    final linhas = _db.select('SELECT * FROM Veiculo WHERE placa = ?', [placa]);
    return linhas.isEmpty ? null : _linhaVeiculo(linhas.first);
  }

  Map<String, dynamic>? _pecaPorId(int id) {
    final linhas = _db.select('SELECT * FROM Peca WHERE id = ?', [id]);
    return linhas.isEmpty ? null : _linhaPeca(linhas.first);
  }

  Map<String, dynamic>? _servicoPorId(int id) {
    final linhas = _db.select('SELECT * FROM Servico WHERE id = ?', [id]);
    return linhas.isEmpty ? null : _linhaServico(linhas.first);
  }

  Map<String, dynamic>? _ordemCompleta(int id) {
    final linhas = _db.select('SELECT * FROM Ordem WHERE id = ?', [id]);
    if (linhas.isEmpty) return null;

    final ordem = _linhaOrdem(linhas.first);
    final veiculo = _veiculoPorId(ordem['veiculoId'] as int);
    if (veiculo != null) {
      veiculo['cliente'] = _clientePorId(veiculo['clienteId'] as int);
    }
    ordem['veiculo'] = veiculo;

    final itens = _db.select(
      'SELECT * FROM OrdemPeca WHERE ordemId = ?',
      [id],
    );
    ordem['itens'] = [
      for (final item in itens)
        {
          'pecaId': item['pecaId'],
          'quantidade': item['quantidade'],
          'valorUnitario': item['valorUnitario'],
          'peca': _pecaPorId(item['pecaId'] as int),
        },
    ];

    final servicosUsados = _db.select(
      'SELECT * FROM OrdemServico WHERE ordemId = ?',
      [id],
    );
    ordem['servicos'] = [
      for (final item in servicosUsados)
        {
          'servicoId': item['servicoId'],
          'valorUnitario': item['valorUnitario'],
          'servico': _servicoPorId(item['servicoId'] as int),
        },
    ];

    return ordem;
  }

  // ---------- GET ----------

  dynamic _get(List<String> s) {
    switch (s) {
      case ['clientes']:
        return [
          for (final r in _db.select('SELECT * FROM Cliente ORDER BY nome ASC')) _linhaCliente(r),
        ];

      case ['clientes', final idTexto]:
        final cliente = _clientePorId(int.parse(idTexto));
        if (cliente == null) throw ApiException(404, 'Cliente não encontrado');
        cliente['veiculos'] = [
          for (final r in _db.select('SELECT * FROM Veiculo WHERE clienteId = ?', [cliente['id']]))
            _linhaVeiculo(r),
        ];
        return cliente;

      case ['veiculos']:
        return [
          for (final r in _db.select('SELECT * FROM Veiculo'))
            _linhaVeiculo(r)..['cliente'] = _clientePorId(r['clienteId'] as int),
        ];

      case ['veiculos', final idTexto]:
        final veiculo = _veiculoPorId(int.parse(idTexto));
        if (veiculo == null) throw ApiException(404, 'Veículo não encontrado');
        veiculo['cliente'] = _clientePorId(veiculo['clienteId'] as int);
        veiculo['ordens'] = [
          for (final r in _db.select('SELECT * FROM Ordem WHERE veiculoId = ?', [veiculo['id']]))
            _linhaOrdem(r),
        ];
        return veiculo;

      case ['pecas']:
        return [
          for (final r in _db.select('SELECT * FROM Peca ORDER BY marca ASC')) _linhaPeca(r),
        ];

      case ['pecas', 'repor']:
        return [
          for (final r in _db.select(
            'SELECT * FROM Peca WHERE descontinuada = 0 AND quantidade <= pontoReposicao ORDER BY marca ASC',
          ))
            _linhaPeca(r),
        ];

      case ['pecas', final idTexto]:
        final peca = _pecaPorId(int.parse(idTexto));
        if (peca == null) throw ApiException(404, 'Peça não encontrada');
        return peca;

      case ['servicos']:
        return [
          for (final r in _db.select('SELECT * FROM Servico ORDER BY nome ASC')) _linhaServico(r),
        ];

      case ['servicos', final idTexto]:
        final servico = _servicoPorId(int.parse(idTexto));
        if (servico == null) throw ApiException(404, 'Serviço não encontrado');
        return servico;

      case ['ordens']:
        final ids = _db.select('SELECT id FROM Ordem ORDER BY dataHoraAbertura DESC');
        return [for (final r in ids) _ordemCompleta(r['id'] as int)];

      case ['ordens', final idTexto]:
        final ordem = _ordemCompleta(int.parse(idTexto));
        if (ordem == null) throw ApiException(404, 'Ordem não encontrada');
        return ordem;

      default:
        throw ApiException(404, 'Rota não encontrada: ${s.join('/')}');
    }
  }

  // ---------- POST ----------

  dynamic _post(List<String> s, Map<String, dynamic> corpo) {
    switch (s) {
      case ['clientes']:
        return _criarCliente(corpo);
      case ['veiculos']:
        return _criarVeiculo(corpo);
      case ['pecas']:
        return _criarPeca(corpo);
      case ['servicos']:
        return _criarServico(corpo);
      case ['ordens']:
        return _abrirOrdem(corpo);
      default:
        throw ApiException(404, 'Rota não encontrada: ${s.join('/')}');
    }
  }

  Map<String, dynamic> _criarCliente(Map<String, dynamic> corpo) {
    final nome = corpo['nome'] as String?;
    final cpf = corpo['cpf'] as String?;
    if (nome == null || nome.isEmpty || cpf == null || cpf.isEmpty) {
      throw ApiException(400, 'nome e cpf são obrigatórios');
    }

    final existente = _db.select('SELECT id FROM Cliente WHERE cpf = ?', [cpf]);
    if (existente.isNotEmpty) {
      throw ApiException(409, 'Já existe um cliente com esse CPF');
    }

    _db.execute('INSERT INTO Cliente (nome, cpf, telefone, endereco) VALUES (?, ?, ?, ?)', [
      nome,
      cpf,
      corpo['telefone'],
      corpo['endereco'],
    ]);
    return _clientePorId(_db.lastInsertRowId)!;
  }

  Map<String, dynamic> _criarVeiculo(Map<String, dynamic> corpo) {
    final modelo = corpo['modelo'] as String?;
    final placa = corpo['placa'] as String?;
    final ano = corpo['ano'];
    final clienteId = corpo['clienteId'];
    if (modelo == null || modelo.isEmpty || placa == null || placa.isEmpty || ano == null || clienteId == null) {
      throw ApiException(400, 'modelo, ano, placa e clienteId são obrigatórios');
    }

    if (_clientePorId(clienteId as int) == null) {
      throw ApiException(409, 'Cliente não encontrado');
    }
    if (_veiculoPorPlaca(placa) != null) {
      throw ApiException(409, 'Já existe um veículo com essa placa');
    }

    _db.execute('INSERT INTO Veiculo (modelo, ano, placa, clienteId) VALUES (?, ?, ?, ?)', [
      modelo,
      ano,
      placa,
      clienteId,
    ]);
    return _veiculoPorId(_db.lastInsertRowId)!;
  }

  Map<String, dynamic> _criarPeca(Map<String, dynamic> corpo) {
    final marca = corpo['marca'] as String?;
    final valor = corpo['valor'];
    if (marca == null || marca.isEmpty || valor == null) {
      throw ApiException(400, 'marca e valor são obrigatórios');
    }

    _db.execute(
      'INSERT INTO Peca (marca, valor, quantidade, pontoReposicao, descontinuada) VALUES (?, ?, ?, ?, 0)',
      [marca, (valor as num).toDouble(), corpo['quantidade'] ?? 0, corpo['pontoReposicao'] ?? 0],
    );
    return _pecaPorId(_db.lastInsertRowId)!;
  }

  Map<String, dynamic> _criarServico(Map<String, dynamic> corpo) {
    final nome = corpo['nome'] as String?;
    final valor = corpo['valor'];
    if (nome == null || nome.isEmpty || valor == null) {
      throw ApiException(400, 'nome e valor são obrigatórios');
    }

    _db.execute('INSERT INTO Servico (nome, valor, descricao) VALUES (?, ?, ?)', [
      nome,
      (valor as num).toDouble(),
      corpo['descricao'],
    ]);
    return _servicoPorId(_db.lastInsertRowId)!;
  }

  /// Espelha ordemService.abrir: valida tudo antes de mexer no estoque,
  /// congela o preço de cada item no momento da abertura, e só confirma se
  /// tudo der certo (transação).
  Map<String, dynamic> _abrirOrdem(Map<String, dynamic> corpo) {
    final placa = corpo['placa'] as String?;
    if (placa == null || placa.isEmpty) {
      throw ApiException(400, 'placa é obrigatória');
    }

    final itens = (corpo['itens'] as List? ?? const [])
        .cast<Map>()
        .map((e) => {'pecaId': e['pecaId'] as int, 'quantidade': e['quantidade'] as int})
        .toList();
    final servicoIds = (corpo['servicoIds'] as List? ?? const []).cast<int>();

    if (itens.isEmpty && servicoIds.isEmpty) {
      throw ApiException(400, 'A ordem precisa de ao menos uma peça ou um serviço');
    }

    return _transacao(() {
      final veiculo = _veiculoPorPlaca(placa);
      if (veiculo == null) throw ApiException(400, 'Veículo não encontrado');

      final pecas = <int, Map<String, dynamic>>{};
      for (final item in itens) {
        final peca = _pecaPorId(item['pecaId'] as int);
        if (peca == null) throw ApiException(400, 'Peça ${item['pecaId']} não encontrada');
        if ((item['quantidade'] as int) <= 0) {
          throw ApiException(400, 'Quantidade inválida para ${peca['marca']}');
        }
        if (peca['descontinuada'] == true) {
          throw ApiException(400, 'A peça ${peca['marca']} está descontinuada');
        }
        if ((peca['quantidade'] as int) < (item['quantidade'] as int)) {
          throw ApiException(
            400,
            'Estoque insuficiente de ${peca['marca']}: ${peca['quantidade']} em estoque, '
                '${item['quantidade']} solicitadas',
          );
        }
        pecas[peca['id'] as int] = peca;
      }

      final servicos = <int, Map<String, dynamic>>{};
      for (final id in servicoIds) {
        final servico = _servicoPorId(id);
        if (servico == null) throw ApiException(400, 'Algum serviço informado não existe');
        servicos[id] = servico;
      }

      final totalPecas = itens.fold<double>(
        0,
        (soma, item) => soma + (pecas[item['pecaId']]!['valor'] as num) * (item['quantidade'] as int),
      );
      final totalServicos = servicos.values.fold<double>(0, (soma, s) => soma + (s['valor'] as num));

      final agora = DateTime.now().toIso8601String();
      _db.execute(
        "INSERT INTO Ordem (veiculoId, valorTotal, status, dataHoraAbertura) VALUES (?, ?, 'aberta', ?)",
        [veiculo['id'], totalPecas + totalServicos, agora],
      );
      final ordemId = _db.lastInsertRowId;

      for (final item in itens) {
        final peca = pecas[item['pecaId']]!;
        _db.execute(
          'INSERT INTO OrdemPeca (ordemId, pecaId, quantidade, valorUnitario) VALUES (?, ?, ?, ?)',
          [ordemId, peca['id'], item['quantidade'], peca['valor']],
        );
        _db.execute('UPDATE Peca SET quantidade = quantidade - ? WHERE id = ?', [
          item['quantidade'],
          peca['id'],
        ]);
      }

      for (final servico in servicos.values) {
        _db.execute(
          'INSERT INTO OrdemServico (ordemId, servicoId, valorUnitario) VALUES (?, ?, ?)',
          [ordemId, servico['id'], servico['valor']],
        );
      }

      return _ordemCompleta(ordemId)!;
    });
  }

  // ---------- PATCH ----------

  dynamic _patch(List<String> s, Map<String, dynamic> corpo) {
    switch (s) {
      case ['pecas', final idTexto, 'repor']:
        return _reporPeca(int.parse(idTexto), corpo);
      case ['pecas', final idTexto, 'descontinuar']:
        return _descontinuarPeca(int.parse(idTexto));
      case ['ordens', final idTexto, 'aprovar']:
        return _aprovarOrdem(int.parse(idTexto));
      case ['ordens', final idTexto, 'concluir']:
        return _concluirOrdem(int.parse(idTexto));
      default:
        throw ApiException(404, 'Rota não encontrada: ${s.join('/')}');
    }
  }

  Map<String, dynamic> _reporPeca(int id, Map<String, dynamic> corpo) {
    final quantidade = corpo['quantidade'];
    if (quantidade == null) throw ApiException(400, 'quantidade é obrigatória');
    if ((quantidade as num) <= 0) throw ApiException(400, 'A quantidade deve ser positiva');

    final peca = _pecaPorId(id);
    if (peca == null) throw ApiException(400, 'Peça não encontrada');
    if (peca['descontinuada'] == true) {
      throw ApiException(400, 'Não é possível repor uma peça descontinuada');
    }

    _db.execute('UPDATE Peca SET quantidade = quantidade + ? WHERE id = ?', [quantidade, id]);
    return _pecaPorId(id)!;
  }

  Map<String, dynamic> _descontinuarPeca(int id) {
    if (_pecaPorId(id) == null) throw ApiException(404, 'Peça não encontrada');
    _db.execute('UPDATE Peca SET descontinuada = 1 WHERE id = ?', [id]);
    return _pecaPorId(id)!;
  }

  Map<String, dynamic> _aprovarOrdem(int id) {
    final ordem = _ordemCompleta(id);
    if (ordem == null) throw ApiException(400, 'Ordem não encontrada');
    if (ordem['status'] != 'aberta') {
      throw ApiException(400, 'Só é possível aprovar uma ordem aberta');
    }
    _db.execute("UPDATE Ordem SET status = 'aprovada' WHERE id = ?", [id]);
    return _ordemCompleta(id)!;
  }

  Map<String, dynamic> _concluirOrdem(int id) {
    final ordem = _ordemCompleta(id);
    if (ordem == null) throw ApiException(400, 'Ordem não encontrada');
    if (ordem['status'] != 'aprovada') {
      throw ApiException(400, 'Só é possível concluir uma ordem aprovada');
    }
    final agora = DateTime.now().toIso8601String();
    _db.execute("UPDATE Ordem SET status = 'concluida', dataHoraConclusao = ? WHERE id = ?", [
      agora,
      id,
    ]);
    return _ordemCompleta(id)!;
  }

  // ---------- DELETE ----------

  dynamic _delete(List<String> s) {
    switch (s) {
      case ['clientes', final idTexto]:
        _removerCliente(int.parse(idTexto));
        return null;
      case ['veiculos', final idTexto]:
        _removerVeiculo(int.parse(idTexto));
        return null;
      case ['servicos', final idTexto]:
        _removerServico(int.parse(idTexto));
        return null;
      case ['ordens', final idTexto]:
        _cancelarOrdem(int.parse(idTexto));
        return null;
      default:
        throw ApiException(404, 'Rota não encontrada: ${s.join('/')}');
    }
  }

  void _removerCliente(int id) {
    if (_clientePorId(id) == null) throw ApiException(409, 'Cliente não encontrado');
    final veiculos = _db.select('SELECT COUNT(*) AS n FROM Veiculo WHERE clienteId = ?', [id]);
    if ((veiculos.first['n'] as int) > 0) {
      throw ApiException(409, 'Não é possível remover um cliente com veículos cadastrados');
    }
    _db.execute('DELETE FROM Cliente WHERE id = ?', [id]);
  }

  void _removerVeiculo(int id) {
    if (_veiculoPorId(id) == null) throw ApiException(409, 'Veículo não encontrado');
    final ordens = _db.select('SELECT COUNT(*) AS n FROM Ordem WHERE veiculoId = ?', [id]);
    if ((ordens.first['n'] as int) > 0) {
      throw ApiException(409, 'Não é possível remover um veículo com ordens');
    }
    _db.execute('DELETE FROM Veiculo WHERE id = ?', [id]);
  }

  void _removerServico(int id) {
    if (_servicoPorId(id) == null) throw ApiException(409, 'Serviço não encontrado');
    final usos = _db.select('SELECT COUNT(*) AS n FROM OrdemServico WHERE servicoId = ?', [id]);
    if ((usos.first['n'] as int) > 0) {
      throw ApiException(409, 'Serviço já usado em ordens e não pode ser removido');
    }
    _db.execute('DELETE FROM Servico WHERE id = ?', [id]);
  }

  void _cancelarOrdem(int id) {
    _transacao(() {
      final ordem = _ordemCompleta(id);
      if (ordem == null) throw ApiException(400, 'Ordem não encontrada');
      if (ordem['status'] == 'concluida') {
        throw ApiException(400, 'Não é possível cancelar uma ordem concluída');
      }

      for (final item in (ordem['itens'] as List).cast<Map>()) {
        _db.execute('UPDATE Peca SET quantidade = quantidade + ? WHERE id = ?', [
          item['quantidade'],
          item['pecaId'],
        ]);
      }

      _db.execute('DELETE FROM Ordem WHERE id = ?', [id]);
      return null;
    });
  }
}
