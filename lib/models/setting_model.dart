class SettingModel {
  final String language;
  final String currency;
  final bool darkMode;
  final bool notificationEnabled;
  final String theme;
  final String dateFormat;
  final int? defaultWalletId;
  final bool showBalanceOnHome;
  final bool autoBackup;
  final String backupFrequency;
  final String reminderTime;
  final bool budgetAlertEnabled;
  final double budgetThreshold;

  SettingModel({
    required this.language,
    required this.currency,
    required this.darkMode,
    required this.notificationEnabled,
    required this.theme,
    required this.dateFormat,
    this.defaultWalletId,
    required this.showBalanceOnHome,
    required this.autoBackup,
    required this.backupFrequency,
    required this.reminderTime,
    required this.budgetAlertEnabled,
    required this.budgetThreshold,
  });

  factory SettingModel.fromJson(Map<String, dynamic> json) {
    return SettingModel(
      language: json['language'],
      currency: json['currency'],
      darkMode: json['darkMode'],
      notificationEnabled: json['notificationEnabled'],
      theme: json['theme'],
      dateFormat: json['dateFormat'],
      defaultWalletId: json['defaultWalletId'],
      showBalanceOnHome: json['showBalanceOnHome'],
      autoBackup: json['autoBackup'],
      backupFrequency: json['backupFrequency'],
      reminderTime: json['reminderTime'],
      budgetAlertEnabled: json['budgetAlertEnabled'],
      budgetThreshold: (json['budgetThreshold'] as num).toDouble(),
    );
  }
}
