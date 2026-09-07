enum AccountType {
  debt, // Deuda: Dinero que yo debo pagar
  debtor; // Deudor: Dinero que me deben a mí

  String get displayName {
    switch (this) {
      case AccountType.debt:
        return 'Deuda';
      case AccountType.debtor:
        return 'Deudor';
    }
  }
}

class AccountModel {
  final String id;
  final String name;
  final AccountType type;
  final String categoryId;
  final String categoryName;
  final double initialAmount;
  final double currentAmount;
  final String colorHex;
  final int iconCodePoint;
  final String? notes;

  const AccountModel({
    required this.id,
    required this.name,
    required this.type,
    required this.categoryId,
    required this.categoryName,
    required this.initialAmount,
    required this.currentAmount,
    required this.colorHex,
    required this.iconCodePoint,
    this.notes,
  });

  bool get isDebt => type == AccountType.debt;
  bool get isDebtor => type == AccountType.debtor;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type.name,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'initialAmount': initialAmount,
        'currentAmount': currentAmount,
        'colorHex': colorHex,
        'iconCodePoint': iconCodePoint,
        'notes': notes,
      };

  factory AccountModel.fromMap(Map<dynamic, dynamic> map) {
    return AccountModel(
      id: map['id'] as String,
      name: map['name'] as String,
      type: AccountType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AccountType.debt,
      ),
      categoryId: map['categoryId'] as String? ?? '',
      categoryName: map['categoryName'] as String? ?? '',
      initialAmount: (map['initialAmount'] as num?)?.toDouble() ?? 0.0,
      currentAmount: (map['currentAmount'] as num?)?.toDouble() ?? 0.0,
      colorHex: map['colorHex'] as String? ?? 'FFF59E0B',
      iconCodePoint: map['iconCodePoint'] as int? ?? 0xe043,
      notes: map['notes'] as String?,
    );
  }

  AccountModel copyWith({
    String? name,
    AccountType? type,
    String? categoryId,
    String? categoryName,
    double? initialAmount,
    double? currentAmount,
    String? colorHex,
    int? iconCodePoint,
    String? notes,
  }) {
    return AccountModel(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      initialAmount: initialAmount ?? this.initialAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      colorHex: colorHex ?? this.colorHex,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      notes: notes ?? this.notes,
    );
  }
}
