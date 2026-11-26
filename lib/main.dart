import 'dart:async';

import 'package:flutter_device_compass/flutter_device_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:material_ui/material_ui.dart';

import 'models/waypoint.dart';
import 'widgets/compass.dart';

void main() {
  runApp(const KGpsLocatorApp());
}

class KGpsLocatorApp extends StatelessWidget {
  const KGpsLocatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: 'kGPS-Locator', home: HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double? latitude;
  double? longitude;
  double? altitude;
  double heading = 0.0;

  String gpsStatus = 'Aguardando GPS...';
  String compassStatus = 'Aguardando bússola...';

  StreamSubscription<Position>? gpsSubscription;
  StreamSubscription<CompassEvent>? compassSubscription;

  Waypoint? navegandoPara;

  final List<Waypoint> waypoints = [
    const Waypoint(nome: 'WP001', latitude: -23.164281, longitude: -45.896756),
    const Waypoint(nome: 'WP002', latitude: -23.189425, longitude: -46.026272),
    const Waypoint(nome: 'WP003', latitude: -23.811881, longitude: -45.396372),
  ];

  void navegarPara(Waypoint waypoint) {
    debugPrint('Voce acionou o Navegar para ${waypoint.nome}');
    setState(() => navegandoPara = waypoint);
  }

  void pararNavegacao() {
    if (navegandoPara != null) {
      debugPrint('Voce parou o Navegar para ${navegandoPara!.nome}');
    }
    setState(() => navegandoPara = null);
  }

  Future<void> adicionarWaypoint() async {
    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aguardando posição GPS para cadastrar waypoint.'),
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    String nomeNovoWaypoint = '';
    final String? nome = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Novo Waypoint'),
          content: Form(
            key: formKey,
            child: TextFormField(
              autofocus: true,
              maxLength: 40,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome',
                hintText: 'Ex.: Entrada principal',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe o nome do waypoint';
                }
                return null;
              },
              onChanged: (value) => nomeNovoWaypoint = value,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop(nomeNovoWaypoint.trim());
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (!mounted || nome == null) return;
    final double? latAtual = latitude;
    final double? lonAtual = longitude;
    if (latAtual == null || lonAtual == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Posição GPS indisponível.')),
      );
      return;
    }

    final novoWaypoint = Waypoint(
      nome: nome,
      latitude: latAtual,
      longitude: lonAtual,
    );
    setState(() => waypoints.add(novoWaypoint));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Waypoint "$nome" cadastrado.')));
  }

  void excluirWaypoint(Waypoint waypoint) {
    setState(() {
      waypoints.remove(waypoint);
      if (identical(navegandoPara, waypoint)) {
        navegandoPara = null;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Waypoint "${waypoint.nome}" excluído.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> iniciarGPS() async {
    try {
      final servicoAtivo = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return;
      if (!servicoAtivo) {
        setState(() => gpsStatus = 'Ative a localização do dispositivo.');
        return;
      }

      var permissao = await Geolocator.checkPermission();
      if (!mounted) return;
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
        if (!mounted) return;
      }
      if (permissao == LocationPermission.denied ||
          permissao == LocationPermission.deniedForever) {
        setState(() => gpsStatus = 'Permissão de localização não concedida.');
        return;
      }

      gpsSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 1,
            ),
          ).listen(
            (Position position) {
              if (!mounted) return;
              setState(() {
                latitude = position.latitude;
                longitude = position.longitude;
                altitude = position.altitude;
                gpsStatus = 'GPS ativo';
              });
            },
            onError: (Object error) {
              if (!mounted) return;
              setState(() => gpsStatus = 'Erro ao obter localização.');
              debugPrint('Erro GPS: $error');
            },
          );
    } catch (error) {
      if (!mounted) return;
      setState(() => gpsStatus = 'Falha ao iniciar GPS.');
      debugPrint('Falha GPS: $error');
    }
  }

  void iniciarBussola() {
    compassSubscription = FlutterCompass.events?.listen(
      (CompassEvent event) {
        if (!mounted) return;
        if (event.heading == null) {
          setState(() => compassStatus = 'Sensor de bússola indisponível.');
          return;
        }
        setState(() {
          heading = event.heading!;
          compassStatus = 'Bússola ativa';
        });
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() => compassStatus = 'Erro no sensor de bússola.');
        debugPrint('Erro bússola: $error');
      },
    );
    if (compassSubscription == null) {
      setState(() => compassStatus = 'Sensor de bússola indisponível.');
    }
  }

  @override
  void initState() {
    super.initState();
    iniciarGPS();
    iniciarBussola();
  }

  @override
  void dispose() {
    gpsSubscription?.cancel();
    compassSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('kGPS-Locator')),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Compass(heading: heading),
            const SizedBox(height: 8),
            Text(
              'Heading: ${heading.toStringAsFixed(1)}°',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildLocationInfo(),
            const SizedBox(height: 12),
            if (navegandoPara != null) _buildNavigationInfo(),
            const SizedBox(height: 8),
            Expanded(child: _buildWaypointList()),
          ],
        ),
      ),
      floatingActionButton: navegandoPara != null
          ? FloatingActionButton.extended(
              onPressed: pararNavegacao,
              icon: const Icon(Icons.stop),
              label: const Text('STOP'),
            )
          : null,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: FilledButton.icon(
          onPressed: adicionarWaypoint,
          icon: const Icon(Icons.add_location_alt),
          label: const Text('Add Waypoint'),
        ),
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _infoRow(
                'Latitude',
                latitude == null ? '--' : '${latitude!.toStringAsFixed(6)}°',
              ),
              _infoRow(
                'Longitude',
                longitude == null ? '--' : '${longitude!.toStringAsFixed(6)}°',
              ),
              _infoRow(
                'Altitude',
                altitude == null ? '--' : '${altitude!.toStringAsFixed(1)} m',
              ),
              const SizedBox(height: 8),
              Text(gpsStatus),
              const SizedBox(height: 8),
              Text(compassStatus),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationInfo() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text(
              'NAVEGANDO PARA',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(navegandoPara!.nome, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            const Text('Azimute: --°    Distância: -- m'),
          ],
        ),
      ),
    );
  }

  Widget _buildWaypointList() {
    return ListView.builder(
      itemCount: waypoints.length,
      itemBuilder: (context, index) {
        final waypoint = waypoints[index];
        return Dismissible(
          key: ObjectKey(waypoint),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, size: 30),
          ),
          onDismissed: (_) => excluirWaypoint(waypoint),
          child: ListTile(
            leading: const Icon(Icons.location_on),
            title: Text(waypoint.nome),
            subtitle: Text(
              '${waypoint.latitude.toStringAsFixed(6)}, '
              '${waypoint.longitude.toStringAsFixed(6)}',
            ),
            onLongPress: () => navegarPara(waypoint),
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}
