class Linha {
  final String id;
  final String nome;

  Linha({required this.id, required this.nome});

  // Para simular uma resposta vinda de API
  factory Linha.fromJson(Map<String, dynamic> json) {
    return Linha(
      id: json['id'],
      nome: json['nome'],
    );
  }
}
