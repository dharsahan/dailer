import 'dart:isolate';

import '../../core/trie.dart';

class ContactRepository {
  // Simulating contact fetching and indexing in an Isolate
  Future<List<String>> searchContacts(String query) async {
    final receivePort = ReceivePort();
    await Isolate.spawn(_isolateEntry, receivePort.sendPort);
    
    final sendPort = await receivePort.first as SendPort;
    final responsePort = ReceivePort();
    
    sendPort.send([query, responsePort.sendPort]);
    return await responsePort.first as List<String>;
  }

  static void _isolateEntry(SendPort sendPort) {
    final port = ReceivePort();
    sendPort.send(port.sendPort);

    final trie = TrieNode();
    // Seed with dummy data for now
    _seedContacts(trie);

    port.listen((message) {
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
}
