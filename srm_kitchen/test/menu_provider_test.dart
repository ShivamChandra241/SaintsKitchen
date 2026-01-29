import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:srm_kitchen/providers/menu_provider.dart';
import 'package:srm_kitchen/services/database_service.dart';

void main() {
  setUp(() async {
    final tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
    // Open the favorites box as DatabaseService expects it
    await Hive.openBox<String>(DatabaseService.boxFavorites);
  });

  tearDown(() async {
    await Hive.close();
    // Cleaning up disk might fail if file locks held, but safe enough for temp dir usually
  });

  test('Legacy Support: Can delete item with integer key', () async {
    final box = Hive.box<String>(DatabaseService.boxFavorites);
    // Simulate legacy data: Key=int (auto-inc), Value=String
    await box.add('101'); // "101" is ID for Chole Bhature Thali

    final provider = MenuProvider();
    // Verify it's loaded as favorite
    final item = provider.items.firstWhere((i) => i.id == '101');
    expect(item.isFavorite, isTrue);

    // Toggle to remove
    provider.toggleFavorite(item);

    expect(item.isFavorite, isFalse);
    expect(box.values.contains('101'), isFalse);
  });

  test('New Optimization: Uses ID as key and can delete', () async {
    final box = Hive.box<String>(DatabaseService.boxFavorites);
    final provider = MenuProvider();
    final item = provider.items.firstWhere((i) => i.id == '102'); // Rajma Chawal
    expect(item.isFavorite, isFalse);

    // Toggle to Add
    provider.toggleFavorite(item);
    expect(item.isFavorite, isTrue);

    // Verify optimization: Key should be '102'
    // NOTE: This assertion will FAIL until we implement the fix.
    // If running this before fix, we expect it to fail or we can comment it out.
    // Ideally we see it fail first (TDD).
    expect(box.containsKey('102'), isTrue, reason: "Key should be the item ID for optimized access");
    expect(box.get('102'), '102');

    // Toggle to Remove
    provider.toggleFavorite(item);
    expect(item.isFavorite, isFalse);
    expect(box.containsKey('102'), isFalse);
  });
}
