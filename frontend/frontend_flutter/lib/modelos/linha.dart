class Linha {
  final String id;
  final String nome;
  final String sentido;

  Linha({required this.id, required this.nome, required this.sentido});

  // Para simular uma resposta vinda de API
  factory Linha.fromJson(Map<String, dynamic> json) {
    return Linha(
      id: json['id'],
      nome: json['nome'],
      sentido: json['sentido'] ?? '',
    );
  }
}
