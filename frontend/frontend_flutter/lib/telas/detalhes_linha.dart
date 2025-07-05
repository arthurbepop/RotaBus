import 'package:flutter/material.dart';

class TelaDetalhesLinha extends StatefulWidget {
  final String nomeLinha;

  const TelaDetalhesLinha({Key? key, required this.nomeLinha}) : super(key: key);

  @override
  _TelaDetalhesLinhaState createState() => _TelaDetalhesLinhaState();
}

class _TelaDetalhesLinhaState extends State<TelaDetalhesLinha> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  
  // TODO: Buscar dados reais da API
  List<Map<String, String>> _paradas = [];
  List<Map<String, String>> _horarios = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _carregarDados();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _carregarDados() {
    // TODO: Conectar com API para buscar dados reais
    // Por enquanto, dados simulados
    setState(() {
      _paradas = [
        {'nome': 'Terminal Central', 'endereco': 'Centro - Santa Cruz do Sul'},
        {'nome': 'UNISC', 'endereco': 'Av. Independência, 2293'},
        {'nome': 'Shopping Santa Cruz', 'endereco': 'Av. Independência, 1000'},
        {'nome': 'Hospital Ana Nery', 'endereco': 'Rua Fernando Ferrari'},
        {'nome': 'Rodoviária', 'endereco': 'Av. Senador Tarso Dutra'},
      ];
      
      _horarios = [
        {'saida': '06:00', 'chegada': '06:45', 'sentido': 'Centro → Bairro'},
        {'saida': '07:00', 'chegada': '07:45', 'sentido': 'Centro → Bairro'},
        {'saida': '08:00', 'chegada': '08:45', 'sentido': 'Centro → Bairro'},
        {'saida': '06:30', 'chegada': '07:15', 'sentido': 'Bairro → Centro'},
        {'saida': '07:30', 'chegada': '08:15', 'sentido': 'Bairro → Centro'},
        {'saida': '08:30', 'chegada': '09:15', 'sentido': 'Bairro → Centro'},
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nomeLinha),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(icon: Icon(Icons.location_on), text: 'Paradas'),
            Tab(icon: Icon(Icons.schedule), text: 'Horários'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Aba de Paradas
          ListView.builder(
            padding: EdgeInsets.all(8),
            itemCount: _paradas.length,
            itemBuilder: (context, index) {
              final parada = _paradas[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    parada['nome']!,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(parada['endereco']!),
                  trailing: Icon(Icons.location_on, color: Colors.green),
                ),
              );
            },
          ),
          // Aba de Horários
          ListView.builder(
            padding: EdgeInsets.all(8),
            itemCount: _horarios.length,
            itemBuilder: (context, index) {
              final horario = _horarios[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: Icon(
                    Icons.access_time,
                    color: Colors.orange,
                    size: 32,
                  ),
                  title: Text(
                    '${horario['saida']} → ${horario['chegada']}',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  subtitle: Text(
                    horario['sentido']!,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '45 min',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implementar "Ver no Mapa"
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Mostrando trajeto no mapa...')),
          );
        },
        icon: Icon(Icons.map),
        label: Text('Ver no Mapa'),
        backgroundColor: Colors.green,
      ),
    );
  }
}