import 'Cliente.dart';

class Veiculo {
  final int? id;
  String modelo;
  int ano;
  String placa;
  int clienteId;
  Cliente? cliente;

  Veiculo({
    this.id,
    required this.modelo,
    required this.ano,
    required this.placa,
    required this.clienteId,
    this.cliente,
  });

  Map<String, dynamic> toJson() => {
        'modelo': modelo,
        'ano': ano,
        'placa': placa,
        'clienteId': clienteId,
      };

  static Veiculo fromJson(Map<String, dynamic> json) => Veiculo(
        id: json['id'],
        modelo: json['modelo'],
        ano: json['ano'],
        placa: json['placa'],
        clienteId: json['clienteId'],
        cliente:
            json['cliente'] != null ? Cliente.fromJson(json['cliente']) : null,
      );

  @override
  String toString() =>
      '#$id  $placa  $modelo ($ano)  Cliente: ${cliente?.nome ?? clienteId}';
}
