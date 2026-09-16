import 'util.dart';

class Peca {
  final int? id;
  String marca;
  double valor;
  int quantidade;
  int pontoReposicao;
  bool descontinuada;

  Peca({
    this.id,
    required this.marca,
    required this.valor,
    this.quantidade = 0,
    this.pontoReposicao = 0,
    this.descontinuada = false,
  });

  Map<String, dynamic> toJson() => {
        'marca': marca,
        'valor': valor,
        'quantidade': quantidade,
        'pontoReposicao': pontoReposicao,
      };

  static Peca fromJson(Map<String, dynamic> json) => Peca(
        id: json['id'],
        marca: json['marca'],
        valor: parseNum(json['valor']),
        quantidade: json['quantidade'] ?? 0,
        pontoReposicao: json['pontoReposicao'] ?? 0,
        descontinuada: json['descontinuada'] ?? false,
      );
}
