import 'dart:async';
import 'dart:isolate';

import '../../core/trie.dart';

class ContactRepository {
  SendPort? _sendPort;
  final Completer<void> _isolateReady = Completer<void>();
  Isolate? _isolate;

  ContactRepository() {
    _initIsolate();
  }

  Future<void> _initIsolate() async {
    final receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_isolateEntry, receivePort.sendPort);
    _sendPort = await receivePort.first as SendPort;
    _isolateReady.complete();
  }

  // Simulating contact fetching and indexing in an Isolate
  Future<List<String>> searchContacts(String query) async {
    await _isolateReady.future;
    
    // We create a temporary ReceivePort for this specific request
    final responsePort = ReceivePort();
    _sendPort!.send([query, responsePort.sendPort]);
    return await responsePort.first as List<String>;
  }

  static void _isolateEntry(SendPort sendPort) {
    final port = ReceivePort();
    sendPort.send(port.sendPort);

    final trie = TrieNode();
    // Seed with dummy data for now
    _seedContacts(trie);

    port.listen((message) {
      if (message == 'kill') {
        port.close();
        return;
      }
      final query = message[0] as String;
      final replyPort = message[1] as SendPort;
      
      final results = trie.search(query);
      replyPort.send(results);
    });
  }

  static void _seedContacts(TrieNode trie) {
    // Map names to T9 keys
    // A,B,C -> 2
    // D,E,F -> 3
    // ...
    // Example: "DAD" -> "323"
    
    // Adding "Mom" -> 666
    trie.insert("666", "Mom");
    // Adding "Dad" -> 323
    trie.insert("323", "Dad");
    // Adding "John" -> 5646
    trie.insert("5646", "John");
  }

  void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
  }
}
