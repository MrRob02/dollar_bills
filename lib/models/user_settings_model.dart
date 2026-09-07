class UserSettingsModel {
  final double currentBalance;
  final double initialBalance;
  final bool isInitialSetupDone;

  const UserSettingsModel({
    this.currentBalance = 0.0,
    this.initialBalance = 0.0,
    this.isInitialSetupDone = false,
  });

  Map<String, dynamic> toMap() => {
        'currentBalance': currentBalance,
        'initialBalance': initialBalance,
        'isInitialSetupDone': isInitialSetupDone,
      };

  factory UserSettingsModel.fromMap(Map<dynamic, dynamic> map) {
    return UserSettingsModel(
      currentBalance: (map['currentBalance'] as num?)?.toDouble() ?? 0.0,
      initialBalance: (map['initialBalance'] as num?)?.toDouble() ?? 0.0,
      isInitialSetupDone: map['isInitialSetupDone'] as bool? ?? false,
    );
  }

  UserSettingsModel copyWith({
    double? currentBalance,
    double? initialBalance,
    bool? isInitialSetupDone,
  }) {
    return UserSettingsModel(
      currentBalance: currentBalance ?? this.currentBalance,
      initialBalance: initialBalance ?? this.initialBalance,
      isInitialSetupDone: isInitialSetupDone ?? this.isInitialSetupDone,
    );
  }
}
