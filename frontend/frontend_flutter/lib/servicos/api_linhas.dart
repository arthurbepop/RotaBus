import '../modelos/linha.dart';

class ApiLinhas {
  // Simula um delay como se fosse uma chamada HTTP
  Future<List<Linha>> obterLinhas() async {
    await Future.delayed(Duration(seconds: 1));
    return [
      Linha(id: '1', nome: 'Linha 1 - Centro'),
      Linha(id: '2', nome: 'Linha 2 - Bairro A'),
      Linha(id: '3', nome: 'Linha 3 - Bairro B'),
      Linha(id: '4', nome: 'Linha 4 - Terminal'),
    ];
  }
}
// Esta classe simula uma API que retorna uma lista de linhas de ônibus.
// Em um aplicativo real, você faria uma requisição HTTP para obter esses dados.