import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:kgps_locator_kelvyn/main.dart';
import 'package:material_ui/material_ui.dart';

class FakeGeolocator extends GeolocatorPlatform {
  final positions = StreamController<Position>.broadcast();

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) =>
      positions.stream;
}

void main() {
  testWidgets('bloqueia cadastro sem GPS e permite navegar e excluir', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const KGpsLocatorApp());
    await tester.tap(find.text('Add Waypoint'));
    await tester.pump();
    expect(
      find.text('Aguardando posição GPS para cadastrar waypoint.'),
      findsOneWidget,
    );

    await tester.longPress(find.text('WP001'));
    await tester.pump();
    expect(find.text('NAVEGANDO PARA'), findsOneWidget);
    expect(find.text('STOP'), findsOneWidget);

    await tester.drag(find.byType(Dismissible).first, const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('WP001'), findsNothing);
    expect(find.text('STOP'), findsNothing);
  });

  testWidgets('cadastra somente nome válido com coordenadas recebidas do GPS', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final previous = GeolocatorPlatform.instance;
    final fake = FakeGeolocator();
    GeolocatorPlatform.instance = fake;
    addTearDown(() async {
      GeolocatorPlatform.instance = previous;
      await fake.positions.close();
    });

    await tester.pumpWidget(const KGpsLocatorApp());
    await tester.pumpAndSettle();
    expect(fake.positions.hasListener, isTrue);
    fake.positions.add(
      Position(
        longitude: -46.123456,
        latitude: -23.123456,
        timestamp: DateTime(2026),
        accuracy: 1,
        altitude: 760,
        altitudeAccuracy: 1,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('-23.123456°'), findsOneWidget);

    await tester.tap(find.text('Add Waypoint'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await tester.pump();
    expect(find.text('Informe o nome do waypoint'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '  Meu ponto  ');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Meu ponto'), findsOneWidget);
    expect(find.text('-23.123456, -46.123456'), findsOneWidget);

    await tester.tap(find.text('Add Waypoint'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Cancelado');
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Cancelado'), findsNothing);
  });
}
