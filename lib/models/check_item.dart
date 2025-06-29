class CheckItem {
  String name;
  bool isChecked;

  CheckItem({
    required this.name,
    this.isChecked = false,
  });

  // Converter para JSON string simples
  String toJson() {
    return '{"name":"$name","isChecked":$isChecked}';
  }

  // Criar objeto a partir de JSON string
  factory CheckItem.fromJson(String json) {
    final map = _parseJson(json);
    return CheckItem(
      name: map['name'] ?? '',
      isChecked: map['isChecked'] ?? false,
    );
  }

  // Parser JSON simples (sem dependências externas)
  static Map<String, dynamic> _parseJson(String json) {
    json = json.replaceAll('{', '').replaceAll('}', '').replaceAll('"', '');
    final parts = json.split(',');
    final map = <String, dynamic>{};
    
    for (final part in parts) {
      final keyValue = part.split(':');
      if (keyValue.length == 2) {
        final key = keyValue[0].trim();
        final value = keyValue[1].trim();
        if (key == 'isChecked') {
          map[key] = value == 'true';
        } else {
          map[key] = value;
        }
      }
    }
    
    return map;
  }
}