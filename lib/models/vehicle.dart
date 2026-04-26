// lib/models/vehicle.dart

class VehicleDocument {
  final int? id;
  final int vehicleId;
  final String type; // Гражданска, Каско, ГТП, Винетка, СБА, и т.н.
  final DateTime? validFrom;
  final DateTime? validTo;
  final String? imagePath;
  final String? notes;

  VehicleDocument({
    this.id,
    required this.vehicleId,
    required this.type,
    this.validFrom,
    this.validTo,
    this.imagePath,
    this.notes,
  });

  int get daysRemaining =>
      validTo != null ? validTo!.difference(DateTime.now()).inDays : 9999;

  String get status {
    if (validTo == null) return 'unknown';
    if (daysRemaining < 0) return 'expired';
    if (daysRemaining <= 30) return 'expiring';
    return 'active';
  }

  double get progressPercent {
    if (validFrom == null || validTo == null) return 0.0;
    final total = validTo!.difference(validFrom!).inDays;
    final elapsed = DateTime.now().difference(validFrom!).inDays;
    if (total <= 0) return 1.0;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'type': type,
      'validFrom': validFrom?.toIso8601String(),
      'validTo': validTo?.toIso8601String(),
      'imagePath': imagePath,
      'notes': notes,
    };
  }

  factory VehicleDocument.fromMap(Map<String, dynamic> map) {
    return VehicleDocument(
      id: map['id'],
      vehicleId: map['vehicleId'],
      type: map['type'],
      validFrom:
          map['validFrom'] != null ? DateTime.parse(map['validFrom']) : null,
      validTo: map['validTo'] != null ? DateTime.parse(map['validTo']) : null,
      imagePath: map['imagePath'],
      notes: map['notes'],
    );
  }

  VehicleDocument copyWith({
    int? id,
    int? vehicleId,
    String? type,
    DateTime? validFrom,
    DateTime? validTo,
    String? imagePath,
    String? notes,
  }) {
    return VehicleDocument(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      type: type ?? this.type,
      validFrom: validFrom ?? this.validFrom,
      validTo: validTo ?? this.validTo,
      imagePath: imagePath ?? this.imagePath,
      notes: notes ?? this.notes,
    );
  }
}

class Vehicle {
  final int? id;
  final String name;
  final String licensePlate;
  final String? brand;
  final String? model;
  final int? year;
  final List<VehicleDocument> documents;

  Vehicle({
    this.id,
    required this.name,
    required this.licensePlate,
    this.brand,
    this.model,
    this.year,
    this.documents = const [],
  });

  String get worstStatus {
    if (documents.isEmpty) return 'active';
    if (documents.any((d) => d.status == 'expired')) return 'expired';
    if (documents.any((d) => d.status == 'expiring')) return 'expiring';
    return 'active';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'licensePlate': licensePlate,
      'brand': brand,
      'model': model,
      'year': year,
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map,
      {List<VehicleDocument> documents = const []}) {
    return Vehicle(
      id: map['id'],
      name: map['name'],
      licensePlate: map['licensePlate'],
      brand: map['brand'],
      model: map['model'],
      year: map['year'],
      documents: documents,
    );
  }

  Vehicle copyWith({
    int? id,
    String? name,
    String? licensePlate,
    String? brand,
    String? model,
    int? year,
    List<VehicleDocument>? documents,
  }) {
    return Vehicle(
      id: id ?? this.id,
      name: name ?? this.name,
      licensePlate: licensePlate ?? this.licensePlate,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      documents: documents ?? this.documents,
    );
  }
}
