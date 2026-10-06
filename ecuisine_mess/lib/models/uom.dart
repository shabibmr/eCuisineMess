class Uom {
  final String id;
  final String uomName;
  final int sortOrder;
  final bool isActive;

  Uom({
    required this.id,
    required this.uomName,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory Uom.fromJson(Map<String, dynamic> json) {
    return Uom(
      id: json['id']?.toString() ?? '',
      uomName: json['uom_name']?.toString() ?? '',
      sortOrder: int.tryParse(json['sort_order']?.toString() ?? '0') ?? 0,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }
}
