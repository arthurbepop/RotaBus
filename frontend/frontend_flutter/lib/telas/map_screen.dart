import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'dart:async';
import 'linhas_onibus.dart';
import 'detalhes_linha.dart';
import '../servicos/api_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _currentPosition;
  GoogleMapController? _mapController;
  String? _erroLocalizacao;
  TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  List<String> _linhasDisponiveis = [];
  List<String> _linhasFiltradas = [];
  bool _showSuggestions = false;
  bool _isLoading = true;
  Set<Marker> _paradaMarkers = {};
  bool _paradasCarregadas = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _carregarLinhas();
  }

  Future<void> _carregarLinhas() async {
    try {
      final linhas = await _apiService.buscarLinhas();
      setState(() {
        _linhasDisponiveis = linhas.map((linha) => linha['nome'].toString()).toList();
        _linhasFiltradas = _linhasDisponiveis;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filtrarLinhas(String busca) {
    setState(() {
      if (busca.isEmpty) {
        _linhasFiltradas = _linhasDisponiveis;
        _showSuggestions = false;
      } else {
        _linhasFiltradas = _linhasDisponiveis
            .where((linha) => linha.toLowerCase().contains(busca.toLowerCase()))
            .toList();
        _showSuggestions = _linhasFiltradas.isNotEmpty;
      }
    });
  }

  void _selecionarLinha(String linha) {
    _searchController.text = linha;
    setState(() {
      _showSuggestions = false;
    });
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TelaDetalhesLinha(nomeLinha: linha),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      geo.Position position = await geo.Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _erroLocalizacao = null;
      });
      if (_mapController != null && _currentPosition != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(_currentPosition!),
        );
      }
    } catch (e) {
      setState(() {
        _currentPosition = null;
        _erroLocalizacao = 'Não foi possível obter sua localização. Verifique as permissões do app.';
      });
    }
  }

  Future<void> _mostrarParadasProximas() async {
    if (_paradasCarregadas) return; // Só carrega uma vez
    final url = Uri.parse('http://192.168.0.10:5000/paradas'); // Ajuste o IP se necessário
    final response = await http.get(url);
    if (response.statusCode == 200) {
      List<dynamic> paradas = json.decode(response.body);
      Set<Marker> markers = {};
      for (var parada in paradas) {
        if (parada['lat'] != null && parada['lng'] != null) {
          markers.add(
            Marker(
              markerId: MarkerId(parada['estacao'] ?? parada['nome'] ?? ''),
              position: LatLng(parada['lat'], parada['lng']),
              infoWindow: InfoWindow(title: parada['estacao'] ?? parada['nome'] ?? ''),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure), // azul claro
            ),
          );
        }
      }
      setState(() {
        _paradaMarkers = markers;
        _paradasCarregadas = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar paradas do servidor')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Rota',
                style: TextStyle(
                  fontWeight: FontWeight.w300, // Mais leve
                  fontSize: 22,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              TextSpan(
                text: 'Bus',
                style: TextStyle(
                  fontWeight: FontWeight.w700, // Mais pesado para contraste
                  fontSize: 22,
                  color: Colors.white,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 3.0,
                      color: Colors.black26,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent, // Transparente para mostrar gradiente
        foregroundColor: Colors.white,
        elevation: 0, // Remove sombra padrão
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue[600]!,
                Colors.blue[700]!,
                Colors.blue[800]!,
              ],
              stops: [0.0, 0.5, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        iconTheme: IconThemeData(
          color: Colors.white,
          size: 26,
        ),
        toolbarHeight: 65, // Altura maior para visual mais moderno
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue[600]!,
                    Colors.blue[700]!,
                    Colors.blue[800]!,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Ícone do app no drawer
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Icon(
                      Icons.directions_bus,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  SizedBox(height: 12),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Rota',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 0.5,
                          ),
                        ),
                        TextSpan(
                          text: 'Bus',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 2.0,
                                color: Colors.black26,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Transporte Público - Santa Cruz do Sul',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.directions_bus, color: Colors.blue),
              title: Text('Linhas de Ônibus'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TelaLinhasOnibus()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.location_on, color: Colors.green),
              title: Text('Paradas Próximas'),
              onTap: () async {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Carregando paradas...')),
                );
                await _mostrarParadasProximas();
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
            ListTile(
              leading: Icon(Icons.schedule, color: Colors.orange),
              title: Text('Horários'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Funcionalidade em desenvolvimento')),
                );
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.person, color: Colors.grey),
              title: Text('Perfil'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.account_balance_wallet, color: Colors.grey),
              title: Text('Saldo'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: _erroLocalizacao != null
          ? Center(child: Text(_erroLocalizacao!, style: TextStyle(color: Colors.red, fontSize: 18)))
          : _currentPosition == null
              ? Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _currentPosition!,
                        zoom: 15,
                      ),
                      onMapCreated: (controller) => _mapController = controller,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      markers: _paradaMarkers,
                    ),
                    // BARRA DE PESQUISA
                    Positioned(
                      top: 10, // Mais próximo da AppBar
                      left: 16,
                      right: 16,
                      child: Column(
                        children: [
                          // Campo de busca
                          Container(
                            height: 60, // Altura fixa maior
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3), // Sombra mais forte
                                  blurRadius: 15,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Digite a linha (ex: Linha 01)',
                                hintStyle: TextStyle(color: Colors.grey),
                                prefixIcon: Icon(Icons.directions_bus, color: Colors.blue),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(Icons.clear),
                                        onPressed: () {
                                          _searchController.clear();
                                          _filtrarLinhas('');
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                              ),
                              onChanged: (value) {
                                _filtrarLinhas(value);
                              },
                            ),
                          ),
                          // Lista de sugestões
                          if (_showSuggestions && _linhasFiltradas.isNotEmpty)
                            Container(
                              margin: EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 10,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              constraints: BoxConstraints(maxHeight: 200),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _linhasFiltradas.length,
                                itemBuilder: (context, index) {
                                  final linha = _linhasFiltradas[index];
                                  return ListTile(
                                    leading: Icon(Icons.directions_bus, color: Colors.blue),
                                    title: Text(linha),
                                    onTap: () => _selecionarLinha(linha),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
