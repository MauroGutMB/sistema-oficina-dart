import 'util.dart';
import 'veiculo.dart';
import 'peca.dart';
import 'servico.dart';

class ItemPeca {
  int pecaId;
  int quantidade;
  double? valorUnitario;
  Peca? peca;

  ItemPeca({
    required this.pecaId,
    required this.quantidade,
    this.valorUnitario,
    this.peca,
  });

  Map<String, dynamic> toJson() => {'pecaId': pecaId, 'quantidade': quantidade};

  static ItemPeca fromJson(Map<String, dynamic> json) => ItemPeca(
        pecaId: json['pecaId'],
        quantidade: json['quantidade'],
        valorUnitario: json['valorUnitario'] != null
            ? parseNum(json['valorUnitario'])
            : null,
        peca: json['peca'] != null ? Peca.fromJson(json['peca']) : null,
      );
}

class ItemServico {
  int servicoId;
  double? valorUnitario;
  Servico? servico;

  ItemServico({required this.servicoId, this.valorUnitario, this.servico});

  static ItemServico fromJson(Map<String, dynamic> json) => ItemServico(
        servicoId: json['servicoId'],
        valorUnitario: json['valorUnitario'] != null
            ? parseNum(json['valorUnitario'])
            : null,
        servico:
            json['servico'] != null ? Servico.fromJson(json['servico']) : null,
      );
}

class Ordem {
  final int? id;
  int veiculoId;
  Veiculo? veiculo;
  List<ItemPeca> itens;
  List<ItemServico> servicos;
  double valorTotal;
  String status;
  DateTime? dataHoraAbertura;
  DateTime? dataHoraConclusao;

  Ordem({
    this.id,
    required this.veiculoId,
    this.veiculo,
    this.itens = const [],
    this.servicos = const [],
    this.valorTotal = 0,
    this.status = 'aberta',
    this.dataHoraAbertura,
    this.dataHoraConclusao,
  });

  static Ordem fromJson(Map<String, dynamic> json) => Ordem(
        id: json['id'],
        veiculoId: json['veiculoId'],
        veiculo:
            json['veiculo'] != null ? Veiculo.fromJson(json['veiculo']) : null,
        itens: (json['itens'] as List? ?? [])
            .map((e) => ItemPeca.fromJson(e as Map<String, dynamic>))
            .toList(),
        servicos: (json['servicos'] as List? ?? [])
            .map((e) => ItemServico.fromJson(e as Map<String, dynamic>))
            .toList(),
        valorTotal: parseNum(json['valorTotal'] ?? 0),
        status: json['status'] ?? 'aberta',
        dataHoraAbertura: json['dataHoraAbertura'] != null
            ? DateTime.tryParse(json['dataHoraAbertura'])
            : null,
        dataHoraConclusao: json['dataHoraConclusao'] != null
            ? DateTime.tryParse(json['dataHoraConclusao'])
            : null,
      );
}
