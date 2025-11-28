class TrieNode {
  final Map<String, TrieNode> children = {};
  bool isEndOfWord = false;
  List<String> data = []; // Store contact IDs or Names associated with this sequence

  void insert(String key, String value) {
    TrieNode current = this;
    for (int i = 0; i < key.length; i++) {
      String char = key[i];
      if (!current.children.containsKey(char)) {
        current.children[char] = TrieNode();
      }
      current = current.children[char]!;
    }
    current.isEndOfWord = true;
    current.data.add(value);
  }

  List<String> search(String prefix) {
    TrieNode current = this;
    for (int i = 0; i < prefix.length; i++) {
      String char = prefix[i];
      if (!current.children.containsKey(char)) {
        return [];
      }
      current = current.children[char]!;
    }
    return _collectAll(current);
  }

  List<String> _collectAll(TrieNode node) {
    List<String> results = [];
    if (node.isEndOfWord) {
      results.addAll(node.data);
    }
    for (var child in node.children.values) {
      results.addAll(_collectAll(child));
    }
    return results;
  }
}
