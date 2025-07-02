
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;


class TelaInicial extends StatefulWidget {
  const TelaInicial({Key? key}) : super(key: key);

  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  LatLng? _currentPosition;
  GoogleMapController? _mapController;
  String? _erroLocalizacao;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: Icon(Icons.person),
                title: Text('Perfil'),
                onTap: () {},
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.account_balance_wallet),
                title: Text('Saldo'),
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          // Mapa de fundo
          Positioned.fill(
            child: _erroLocalizacao != null
                ? Center(child: Text(_erroLocalizacao!, style: TextStyle(color: Colors.red, fontSize: 18)))
                : _currentPosition == null
                    ? Center(child: CircularProgressIndicator())
                    : GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _currentPosition!,
                          zoom: 15,
                        ),
                        onMapCreated: (controller) {
                          _mapController = controller;
                        },
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        zoomControlsEnabled: false,
                        padding: EdgeInsets.only(bottom: 64.0, right: 24.0),
                      ),
          ),
          // Logo colada no topo à esquerda
          Positioned(
            top: 0,
            left: 0,
            child: Image.asset(
              'assets/logosuperior.png',
              width: 170,
              height: 170,
              fit: BoxFit.contain,
            ),
          ),
          // Botão menu alinhado ao topo à direita
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 24,
            child: Builder(
              builder: (context) => Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: Icon(Icons.menu, color: Colors.black, size: 36),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                  tooltip: 'Menu',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
