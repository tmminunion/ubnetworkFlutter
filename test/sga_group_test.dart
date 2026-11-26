import 'package:flutter_test/flutter_test.dart';
import 'package:ubnetwork_flutter/data/hub_catalog.dart';
import 'package:ubnetwork_flutter/services/sga_group_store.dart';

void main() {
  test('SgaGroupStore seed groups separate WHITE and RED shifts with rosters', () {
    final seeds = SgaGroupStore.defaultSeedGroups();
    final white = seeds.where((g) => g.shift == 'WHITE').toList();
    final red = seeds.where((g) => g.shift == 'RED').toList();
    expect(white.length, 3);
    expect(red.length, 2);
    for (final g in seeds) {
      expect(g.members, isNotEmpty);
      expect(g.tlName, isNotEmpty);
    }
  });

  test('Safety sub-hub marks /safety/group as native ready', () {
    final safety = HubCatalog.subHubs['safety']!;
    final group = safety.modules.firstWhere((m) => m.route == '/safety/group');
    expect(group.isNativeReady, isTrue);
  });
}
