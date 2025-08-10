class NotificationService {
  final List<Map<String, String>> _items = [];
  List<Map<String, String>> get items => List.unmodifiable(_items);

  void push({required String title, required String body}) {
    _items.insert(0, {
      'title': title,
      'body': body,
      'ts': DateTime.now().toIso8601String(),
    });
  }

  void clear() => _items.clear();
}
