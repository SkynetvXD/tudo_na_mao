class ChecklistItem {
  String name;
  bool isChecked;
  DateTime? createdAt;
  
  ChecklistItem({
    required this.name, 
    this.isChecked = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  
  Map<String, dynamic> toJson() => {
    'name': name,
    'isChecked': isChecked,
    'createdAt': createdAt?.toIso8601String(),
  };
  
  factory ChecklistItem.fromJson(Map<String, dynamic> json) => ChecklistItem(
    name: json['name'],
    isChecked: json['isChecked'] ?? false,
    createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt']) 
        : DateTime.now(),
  );
  
  ChecklistItem copyWith({
    String? name,
    bool? isChecked,
    DateTime? createdAt,
  }) {
    return ChecklistItem(
      name: name ?? this.name,
      isChecked: isChecked ?? this.isChecked,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  @override
  String toString() {
    return 'ChecklistItem(name: $name, isChecked: $isChecked, createdAt: $createdAt)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChecklistItem &&
        other.name == name &&
        other.isChecked == isChecked &&
        other.createdAt == createdAt;
  }
  
  @override
  int get hashCode => name.hashCode ^ isChecked.hashCode ^ createdAt.hashCode;
}