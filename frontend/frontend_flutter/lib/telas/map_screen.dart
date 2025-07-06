import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'dart:async';
import 'dart:math' as math;
import 'detalhes_linha.dart';
import '../servicos/api_service.dart';
import '../componentes/menu_lateral_melhorado.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../modelos/linha.dart';

class MapScreen extends StatefulWidget {
  final List<dynamic>? paradasDestacadas;
  final String? tituloLinha;
  
  const MapScreen({
    Key? key,
    this.paradasDestacadas,
    this.tituloLinha,
  }) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _currentPosition;
  GoogleMapController? _mapController;
  String? _erroLocalizacao;
  TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  List<Linha> _linhasDisponiveis = [];
  List<Linha> _linhasFiltradas = [];
  bool _showSuggestions = false;
  Set<Marker> _paradaMarkers = {};
  Set<Marker> _todasParadasMarkers = {}; // Guarda todos os marcadores
  Marker? _selectedMarker;
  List<dynamic> _proximasPartidas = [];

  String _mapStyle = '''[
  {
    "featureType": "poi",
    "elementType": "all",
    "stylers": [
      { "visibility": "off" }
    ]
  },
  {
    "featureType": "poi.bus_station",
    "elementType": "all",
    "stylers": [
      { "visibility": "on" }
    ]
  }
]''';

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
        _linhasDisponiveis = linhas.map((json) => Linha.fromJson(json)).toList();
        _linhasFiltradas = _linhasDisponiveis;
      });
    } catch (e) {
      setState(() {
        _linhasDisponiveis = [];
        _linhasFiltradas = [];
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
            .where((linha) => linha.nome.toLowerCase().contains(busca.toLowerCase()))
            .toList();
        _showSuggestions = _linhasFiltradas.isNotEmpty;
      }
    });
  }

  void _selecionarLinha(String nomeLinha) {
    _searchController.text = nomeLinha;
    setState(() {
      _showSuggestions = false;
    });
    final linhaObj = _linhasDisponiveis.firstWhere(
      (l) => l.nome == nomeLinha,
      orElse: () => _linhasDisponiveis.first,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TelaDetalhesLinha(linha: linhaObj),
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

  // Carrega e mostra as paradas próximas
  Future<void> _mostrarParadasProximas() async {
    final url = Uri.parse('http://192.168.0.10:5000/paradas');
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
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
              onTap: () {
                setState(() {
                  _selectedMarker = Marker(
                    markerId: MarkerId(parada['estacao'] ?? parada['nome'] ?? ''),
                    position: LatLng(parada['lat'], parada['lng']),
                    infoWindow: InfoWindow(title: parada['estacao'] ?? parada['nome'] ?? ''),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                  );
                  _paradaMarkers = {_selectedMarker!};
                });
                _mostrarBottomSheetProximasPartidas(
                  parada['estacao'] ?? parada['nome'] ?? '',
                );
              },
            ),
          );
        }
      }
      setState(() {
        _paradaMarkers = markers;
        _todasParadasMarkers = markers;
        _selectedMarker = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar paradas do servidor')),
      );
    }
  }

  void _restaurarTodasParadas() {
    setState(() {
      _paradaMarkers = _todasParadasMarkers;
      _selectedMarker = null;
    });
  }

  // Mostra paradas específicas destacadas no mapa
  void _mostrarParadasDestacadas() {
    if (widget.paradasDestacadas == null) return;
    
    Set<Marker> markers = {};
    for (var parada in widget.paradasDestacadas!) {
      // Verificar diferentes possíveis formatos de coordenadas
      double? lat, lng;
      String nome = '';
      
      if (parada['lat'] != null && parada['lng'] != null) {
        lat = parada['lat'] is String ? double.tryParse(parada['lat']) : parada['lat']?.toDouble();
        lng = parada['lng'] is String ? double.tryParse(parada['lng']) : parada['lng']?.toDouble();
        nome = parada['nome'] ?? parada['estacao'] ?? parada['endereco'] ?? '';
      } else if (parada['latitude'] != null && parada['longitude'] != null) {
        lat = parada['latitude'] is String ? double.tryParse(parada['latitude']) : parada['latitude']?.toDouble();
        lng = parada['longitude'] is String ? double.tryParse(parada['longitude']) : parada['longitude']?.toDouble();
        nome = parada['nome'] ?? parada['estacao'] ?? parada['endereco'] ?? '';
      }
      
      if (lat != null && lng != null && nome.isNotEmpty) {
        final markerId = MarkerId('destaque_$nome');
        final position = LatLng(lat, lng);
        final marker = Marker(
          markerId: markerId,
          position: position,
          infoWindow: InfoWindow(
            title: nome,
            snippet: widget.tituloLinha ?? 'Parada da linha',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue), // Azul para destacar
          onTap: () {
            final clickedMarker = Marker(
              markerId: markerId,
              position: position,
              infoWindow: InfoWindow(
                title: nome,
                snippet: widget.tituloLinha ?? 'Parada da linha',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed), // Vermelho quando selecionado
            );
            setState(() {
              _selectedMarker = clickedMarker;
              _paradaMarkers = {clickedMarker};
            });
            
            // Opcional: Mostrar próximas partidas se disponível
            _mostrarBottomSheetProximasPartidas(nome);
          },
        );
        markers.add(marker);
      }
    }
    
    setState(() {
      _paradaMarkers = markers;
      _todasParadasMarkers = markers;
      _selectedMarker = null;
    });
    
    // Ajustar zoom para mostrar todas as paradas destacadas
    if (markers.isNotEmpty && _mapController != null) {
      _ajustarZoomParaParadas(markers);
    }
  }

  // Ajusta o zoom do mapa para mostrar todas as paradas
  void _ajustarZoomParaParadas(Set<Marker> markers) {
    if (markers.isEmpty) return;
    
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;
    
    for (var marker in markers) {
      minLat = math.min(minLat, marker.position.latitude);
      maxLat = math.max(maxLat, marker.position.latitude);
      minLng = math.min(minLng, marker.position.longitude);
      maxLng = math.max(maxLng, marker.position.longitude);
    }
    
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0, // padding
      ),
    );
  }

  // Busca as próximas partidas para a parada e horário atual
  Future<void> _buscarProximasPartidas(String estacao) async {
    final agora = DateFormat('HH:mm').format(DateTime.now());
    final url = Uri.parse('http://192.168.0.10:5000/paradas/' + Uri.encodeComponent(estacao) + '/proximas_partidas?hora=$agora');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      setState(() {
        _proximasPartidas = json.decode(response.body);
      });
    } else {
      setState(() {
        _proximasPartidas = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar próximas partidas')),
      );
    }
  }

  // Mostra o bottom sheet com as próximas partidas
  void _mostrarBottomSheetProximasPartidas(String nomeParada) async {
    await _buscarProximasPartidas(nomeParada);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: EdgeInsets.all(16),
              child: _proximasPartidas.isEmpty
                  ? Center(child: Text('Nenhuma partida futura para esta parada.'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _proximasPartidas.length,
                      itemBuilder: (context, index) {
                        final partida = _proximasPartidas[index];
                        return ListTile(
                          leading: Icon(Icons.directions_bus, color: Colors.blue),
                          title: Text('Linha ${partida['linha']}'),
                          subtitle: Text('Sentido: ${partida['sentido']}\nHorário: ${partida['horario']}'),
                        );
                      },
                    ),
            );
          },
        );
      },
    ).whenComplete(() {
      _restaurarTodasParadas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.tituloLinha != null 
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Rota',
                          style: TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: 20,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        TextSpan(
                          text: 'Bus',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    widget.tituloLinha!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white70,
                    ),
                  ),
                ],
              )
            : RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Rota',
                      style: TextStyle(
                        fontWeight: FontWeight.w300,
                        fontSize: 22,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    TextSpan(
                      text: 'Bus',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
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
      drawer: MenuLateralMelhorado(
        onParadasProximas: _mostrarParadasProximas,
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
                        zoom: 18, // Zoom maior para mais detalhes
                      ),
                      onMapCreated: (controller) {
                        _mapController = controller;
                        _mapController?.setMapStyle(_mapStyle);
                        
                        // Se há paradas destacadas, mostra-las quando o mapa estiver pronto
                        if (widget.paradasDestacadas != null && widget.paradasDestacadas!.isNotEmpty) {
                          Future.delayed(Duration(milliseconds: 500), () {
                            _mostrarParadasDestacadas();
                          });
                        }
                      },
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
                                    title: Text(linha.nome),
                                    onTap: () => _selecionarLinha(linha.nome),
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
