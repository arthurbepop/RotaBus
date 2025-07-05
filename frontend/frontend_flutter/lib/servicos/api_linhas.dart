import 'package:dio/dio.dart';
import '../modelos/linha.dart';

class ApiLinhas {
  final Dio _dio = Dio();
  final String baseUrl = 'http://192.168.0.10'; // Troque pelo IP do seu computador

  Future<List<Linha>> obterLinhas() async {
    try {
      final response = await _dio.get('$baseUrl/linhas');
      final List dados = response.data;
      return dados.map((json) => Linha.fromJson(json)).toList();
    } catch (e) {
      print('Erro ao buscar linhas: $e');
      return []; // Retorna lista vazia em caso de erro
    }
  }

  Future<List<dynamic>> obterParadas(String codigo) async {
    try {
      final response = await _dio.get('$baseUrl/linhas/$codigo/paradas');
      return response.data;
    } catch (e) {
      print('Erro ao buscar paradas: $e');
      return [];
    }
  }

  Future<List<dynamic>> obterHorarios(String codigo) async {
    try {
      final response = await _dio.get('$baseUrl/linhas/$codigo/horarios');
      return response.data;
    } catch (e) {
      print('Erro ao buscar horários: $e');
      return [];
    }
  }
}