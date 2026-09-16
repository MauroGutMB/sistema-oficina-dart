class Cliente {
  final int? id;
  String nome;
  String cpf;
  String? telefone;
  String? endereco;

  Cliente({
    this.id,
    required this.nome,
    required this.cpf,
    this.telefone,
    this.endereco,
  });

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'cpf': cpf,
        if (telefone != null && telefone!.isNotEmpty) 'telefone': telefone,
        if (endereco != null && endereco!.isNotEmpty) 'endereco': endereco,
      };

  static Cliente fromJson(Map<String, dynamic> json) => Cliente(
        id: json['id'],
        nome: json['nome'],
        cpf: json['cpf'],
        telefone: json['telefone'],
        endereco: json['endereco'],
      );
}
