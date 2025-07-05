import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio = Dio();
  final String baseUrl = 'http://192.168.0.10:5000'; // SUBSTITUA pelo IP do backend
  
  // Configurações de timeout
  ApiService() {
    _dio.options.connectTimeout = Duration(seconds: 5);
    _dio.options.receiveTimeout = Duration(seconds: 3);
  }

  // Buscar todas as linhas
  Future<List<Map<String, dynamic>>> buscarLinhas() async {
    try {
      final response = await _dio.get('$baseUrl/linhas');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print('Erro ao buscar linhas: $e');
      // Retorna dados simulados em caso de erro
      return _mockLinhas();
    }
  }

  // Buscar paradas de uma linha específica
  Future<List<Map<String, dynamic>>> buscarParadas(String codigoLinha) async {
    try {
      final response = await _dio.get('$baseUrl/linhas/$codigoLinha/paradas');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print('Erro ao buscar paradas: $e');
      // Retorna dados simulados em caso de erro
      return _mockParadas();
    }
  }

  // Buscar horários de uma linha específica
  Future<List<Map<String, dynamic>>> buscarHorarios(String codigoLinha) async {
    try {
      final response = await _dio.get('$baseUrl/linhas/$codigoLinha/horarios');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print('Erro ao buscar horários: $e');
      // Retorna dados simulados em caso de erro
      return _mockHorarios();
    }
  }

  // Dados simulados para fallback
  List<Map<String, dynamic>> _mockLinhas() {
    return [
      {'id': '01', 'nome': 'Linha 01 - Centro'},
      {'id': '02', 'nome': 'Linha 02 - Bom Jesus'},
      {'id': '03', 'nome': 'Linha 03 - Universitário'},
      {'id': '04', 'nome': 'Linha 04 - Industrial'},
      {'id': '05', 'nome': 'Linha 05 - Shopping'},
      {'id': '06', 'nome': 'Linha 06 - Aeroporto'},
      {'id': '07', 'nome': 'Linha 07 - Rodoviária'},
    ];
  }

  List<Map<String, dynamic>> _mockParadas() {
    return [
      {'nome': 'Terminal Central', 'endereco': 'Centro - Santa Cruz do Sul'},
      {'nome': 'UNISC', 'endereco': 'Av. Independência, 2293'},
      {'nome': 'Shopping Santa Cruz', 'endereco': 'Av. Independência, 1000'},
      {'nome': 'Hospital Ana Nery', 'endereco': 'Rua Fernando Ferrari'},
      {'nome': 'Rodoviária', 'endereco': 'Av. Senador Tarso Dutra'},
    ];
  }

  List<Map<String, dynamic>> _mockHorarios() {
    return [
      {'saida': '06:00', 'chegada': '06:45', 'sentido': 'Centro → Bairro'},
      {'saida': '07:00', 'chegada': '07:45', 'sentido': 'Centro → Bairro'},
      {'saida': '08:00', 'chegada': '08:45', 'sentido': 'Centro → Bairro'},
      {'saida': '06:30', 'chegada': '07:15', 'sentido': 'Bairro → Centro'},
      {'saida': '07:30', 'chegada': '08:15', 'sentido': 'Bairro → Centro'},
      {'saida': '08:30', 'chegada': '09:15', 'sentido': 'Bairro → Centro'},
    ];
  }
}