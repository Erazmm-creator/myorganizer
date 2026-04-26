// lib/models/warranty.dart

class Warranty {
  final int? id;
  final String title;
  final String category;
  final String? modelNumber;
  final DateTime purchaseDate;
  final DateTime expiryDate;
  final String? imagePath;

  Warranty({
    this.id,
    required this.title,
    required this.category,
    this.modelNumber,
    required this.purchaseDate,
    required this.expiryDate,
    this.imagePath,
  });

  int get daysRemaining => expiryDate.difference(DateTime.now()).inDays;

  double get progressPercent {
    final total = expiryDate.difference(purchaseDate).inDays;
    final elapsed = DateTime.now().difference(purchaseDate).inDays;
    if (total <= 0) return 1.0;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  String get status {
    if (daysRemaining < 0) return 'expired';
    if (daysRemaining <= 30) return 'expiring';
    return 'active';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'modelNumber': modelNumber,
      'purchaseDate': purchaseDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'imagePath': imagePath,
    };
  }

  factory Warranty.fromMap(Map<String, dynamic> map) {
    return Warranty(
      id: map['id'],
      title: map['title'],
      category: map['category'],
      modelNumber: map['modelNumber'],
      purchaseDate: DateTime.parse(map['purchaseDate']),
      expiryDate: DateTime.parse(map['expiryDate']),
      imagePath: map['imagePath'],
    );
  }

  Warranty copyWith({
    int? id,
    String? title,
    String? category,
    String? modelNumber,
    DateTime? purchaseDate,
    DateTime? expiryDate,
    String? imagePath,
  }) {
    return Warranty(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      modelNumber: modelNumber ?? this.modelNumber,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expiryDate: expiryDate ?? this.expiryDate,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
