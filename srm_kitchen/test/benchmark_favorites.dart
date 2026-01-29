import 'dart:io';
import 'package:hive/hive.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Hive Benchmark: Linear Search vs Direct Key', () async {
    final tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
    final box = await Hive.openBox<String>('benchmark_box');

    const int itemCount = 10000;

    // ---------------------------------------------------------
    // BASELINE: Linear Search (Current Implementation)
    // ---------------------------------------------------------
    await box.clear();
    // Populate with auto-increment int keys (0, 1, 2...)
    for (int i = 0; i < itemCount; i++) {
      await box.add('item_$i');
    }

    final stopwatchOld = Stopwatch()..start();

    // Simulate finding and deleting the last item 'item_9999' (Worst Case)
    final targetId = 'item_${itemCount - 1}';
    final map = box.toMap().cast<dynamic, String>();
    dynamic keyToDelete;
    map.forEach((key, value) {
      if (value == targetId) keyToDelete = key;
    });
    if (keyToDelete != null) await box.delete(keyToDelete);

    stopwatchOld.stop();
    print('Baseline (Linear Search) Time: ${stopwatchOld.elapsedMicroseconds} us');


    // ---------------------------------------------------------
    // OPTIMIZED: Direct Key Access
    // ---------------------------------------------------------
    await box.clear();
    // Populate with String keys matching IDs
    for (int i = 0; i < itemCount; i++) {
      await box.put('item_$i', 'item_$i');
    }

    final stopwatchNew = Stopwatch()..start();

    // Simulate deleting 'item_9999' using direct key
    if (box.containsKey(targetId)) {
        await box.delete(targetId);
    } else {
        // Fallback (simulated cost if not found, but here we expect to find it)
    }

    stopwatchNew.stop();
    print('Optimized (Direct Key) Time: ${stopwatchNew.elapsedMicroseconds} us');

    // Cleanup
    await box.close();
    tempDir.deleteSync(recursive: true);
  });
}
