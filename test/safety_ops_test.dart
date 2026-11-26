import 'package:flutter_test/flutter_test.dart';
import 'package:ubnetwork_flutter/data/hub_catalog.dart';
import 'package:ubnetwork_flutter/features/safety/safety_bira_screen.dart';
import 'package:ubnetwork_flutter/features/safety/safety_device_screen.dart';
import 'package:ubnetwork_flutter/features/safety/safety_kpi_screen.dart';

void main() {
  test('All 6 operational Safety sub-hub modules are marked native ready', () {
    final safety = HubCatalog.subHubs['safety']!;
    final readyRoutes = safety.modules.where((m) => m.isNativeReady).map((m) => m.route).toSet();
    expect(readyRoutes, containsAll([
      '/safety/temuan',
      '/kyt/monitoring',
      '/safety/group',
      '/safety/device',
      '/safety/bira',
      '/safety/kpi',
    ]));
  });

  test('Default Safety Device, BIRA, and Nearmiss seed models serialize cleanly', () {
    final dev = defaultSafetyDevices().first;
    expect(SafetyDeviceItem.fromJson(dev.toJson()).id, 'DEV-01');

    final bira = defaultBiraRecords().first;
    expect(BiraRecord.fromJson(bira.toJson()).kategori, 'Safe Action');

    final nm = defaultNearmissLogs().first;
    expect(NearmissLog.fromJson(nm.toJson()).id, 'NM-2026-089');
  });
}
