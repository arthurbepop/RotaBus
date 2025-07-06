import 'package:flutter/material.dart';

class SaldoManager extends ChangeNotifier {
  static final SaldoManager _instance = SaldoManager._internal();
  factory SaldoManager() => _instance;
  SaldoManager._internal();

  // Valores atualizados das tarifas de Santa Cruz do Sul
  static const double TARIFA_INTEGRAL = 5.50;
  static const double TARIFA_MEIA = 2.25;

  double _saldoAtual = 15.50;
  bool _saldoVisivel = true;
  
  List<Map<String, dynamic>> _transacoes = [
    {
      'tipo': 'viagem',
      'descricao': 'Linha 01 - Centro/UNISC (Meia)',
      'valor': -2.25,
      'data': DateTime.now().subtract(Duration(hours: 2)),
      'saldo_anterior': 17.75,
      'saldo_atual': 15.50,
    },
    {
      'tipo': 'recarga',
      'descricao': 'Recarga via PIX',
      'valor': 20.00,
      'data': DateTime.now().subtract(Duration(days: 1)),
      'saldo_anterior': 0.00,
      'saldo_atual': 20.00,
    },
    {
      'tipo': 'viagem',
      'descricao': 'Linha 02 - Bom Jesus (Integral)',
      'valor': -5.50,
      'data': DateTime.now().subtract(Duration(days: 2)),
      'saldo_anterior': 25.50,
      'saldo_atual': 20.00,
    },
    {
      'tipo': 'recarga',
      'descricao': 'Recarga via Cartão',
      'valor': 30.00,
      'data': DateTime.now().subtract(Duration(days: 3)),
      'saldo_anterior': 0.00,
      'saldo_atual': 30.00,
    },
  ];

  // Getters
  double get saldoAtual => _saldoAtual;
  bool get saldoVisivel => _saldoVisivel;
  List<Map<String, dynamic>> get transacoes => _transacoes;
  String get saldoFormatado => 'R\$ ${_saldoAtual.toStringAsFixed(2)}';

  // Métodos
  void toggleSaldoVisibilidade() {
    _saldoVisivel = !_saldoVisivel;
    notifyListeners();
  }

  void adicionarRecarga(double valor) {
    final saldoAnterior = _saldoAtual;
    _saldoAtual += valor;
    
    _transacoes.insert(0, {
      'tipo': 'recarga',
      'descricao': 'Recarga via App',
      'valor': valor,
      'data': DateTime.now(),
      'saldo_anterior': saldoAnterior,
      'saldo_atual': _saldoAtual,
    });
    
    notifyListeners();
  }

  void adicionarViagem(String linha, {bool meia = false}) {
    final valor = meia ? -TARIFA_MEIA : -TARIFA_INTEGRAL;
    final tipoPassagem = meia ? '(Meia)' : '(Integral)';
    
    if (_saldoAtual + valor >= 0) {
      final saldoAnterior = _saldoAtual;
      _saldoAtual += valor; // valor já é negativo
      
      _transacoes.insert(0, {
        'tipo': 'viagem',
        'descricao': '$linha $tipoPassagem',
        'valor': valor,
        'data': DateTime.now(),
        'saldo_anterior': saldoAnterior,
        'saldo_atual': _saldoAtual,
      });
      
      notifyListeners();
    }
  }

  bool podeUsarTransporte({bool meia = false}) {
    final valorNecessario = meia ? TARIFA_MEIA : TARIFA_INTEGRAL;
    return _saldoAtual >= valorNecessario;
  }
}