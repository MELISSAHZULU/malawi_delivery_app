import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class OfflineQueueProvider extends ChangeNotifier {
  Box? _queueBox;
  List<Map<String, dynamic>> _queue = [];

  List<Map<String, dynamic>> get queue => _queue;
  int get queueLength => _queue.length;

  OfflineQueueProvider() {
    _initBox();
  }

  Future<void> _initBox() async {
    try {
      _queueBox = await Hive.openBox('offlineQueue');
      _queue = List.from(_queueBox?.get('queue', defaultValue: []) ?? []);
      notifyListeners();
    } catch (e) {
      print('Error initializing offline queue: $e');
    }
  }

  Future<void> addToQueue(Map<String, dynamic> data) async {
    _queue.add(data);
    await _queueBox?.put('queue', _queue);
    notifyListeners();
  }

  Future<void> removeFromQueue(int index) async {
    if (index >= 0 && index < _queue.length) {
      _queue.removeAt(index);
      await _queueBox?.put('queue', _queue);
      notifyListeners();
    }
  }

  Future<void> clearQueue() async {
    _queue.clear();
    await _queueBox?.put('queue', _queue);
    notifyListeners();
  }

  Future<void> syncQueue() async {
    if (_queue.isEmpty) return;

    // Process each item in queue
    for (int i = _queue.length - 1; i >= 0; i--) {
      final item = _queue[i];
      try {
        // Attempt to send to backend
        final success = await _sendToBackend(item);
        if (success) {
          await removeFromQueue(i);
        }
      } catch (e) {
        print('Sync error: $e');
      }
    }
  }

  Future<bool> _sendToBackend(Map<String, dynamic> data) async {
    // Implement API call to send data to backend
    // Return true if successful
    try {
      // For now, simulate successful sync
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      return false;
    }
  }
}
