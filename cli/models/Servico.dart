import 'util.dart';

class Servico {
  final int? id;
  String nome;
  double valor;
  String? descricao;

  Servico({
    this.id,
    required this.nome,
    required this.valor,
    this.descricao,
  });

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'valor': valor,
        if (descricao != null) 'descricao': descricao,
      };

  static Servico fromJson(Map<String, dynamic> json) => Servico(
        id: json['id'],
        nome: json['nome'],
        valor: parseNum(json['valor']),
        descricao: json['descricao'],
      );

  @override
  String toString() =>
      '#$id  $nome  R\$${valor.toStringAsFixed(2)}  ${descricao ?? ''}';
}
