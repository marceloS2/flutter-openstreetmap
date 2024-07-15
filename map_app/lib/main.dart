import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  LatLng? currentPosition; // Posição atual do usuário
  late String tileDir; // Diretório onde os tiles BPF estão armazenados

  @override
  void initState() {
    super.initState();
    _initializeTileDir(); // Inicializa o diretório dos tiles
    _determinePosition(); // Determinar a posição inicial
    _startTracking(); // Começar a rastrear a posição em tempo real
  }

  // Inicializa o diretório onde os tiles BPF estão armazenados
  Future<void> _initializeTileDir() async {
    final directory = await getApplicationDocumentsDirectory();
    tileDir = '${directory.path}/tiles';
  }

  // Determina a posição inicial do usuário
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verificar se o serviço de localização está habilitado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Serviço de localização está desabilitado.');
    }

    // Verificar se temos permissão para acessar a localização
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Permissão de localização foi negada.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Permissão de localização foi negada permanentemente.');
    }

    // Obter a posição atual
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      currentPosition = LatLng(position.latitude, position.longitude);
    });
  }

  // Começar a rastrear a posição do usuário em tempo real
  void _startTracking() {
    Geolocator.getPositionStream(
      locationSettings:
          LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((Position position) {
      setState(() {
        currentPosition = LatLng(position.latitude, position.longitude);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Guard agua Map',
          style: TextStyle(fontSize: 22),
        ),
      ),
      body: currentPosition == null
          ? Center(
              child:
                  CircularProgressIndicator()) // Mostrar um indicador de carregamento até a posição ser carregada
          : content(),
    );
  }

  Widget content() {
    return FlutterMap(
      options: MapOptions(
        initialZoom: 11,
        interactionOptions:
            const InteractionOptions(flags: ~InteractiveFlag.doubleTapDragZoom),
      ),
      children: [
        openStreetMapTileLayer,
        if (currentPosition != null)
          MarkerLayer(
            markers: [
              Marker(
                point: currentPosition!,
                width: 60,
                height: 60,
                alignment: Alignment.center,
                child: Icon(
                  Icons.location_pin,
                  size: 60,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        if (currentPosition != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point: currentPosition!,
                color: Colors.blue.withOpacity(0.3),
                borderStrokeWidth: 2,
                borderColor: Colors.blue,
                radius: 50, // Raio do círculo em metros
              ),
            ],
          ),
      ],
    );
  }
}

TileLayer get openStreetMapTileLayer => TileLayer(
      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'dev.fleaflet.flutter_map.example',
    );
