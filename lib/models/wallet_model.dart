class Wallet {
  final int? id;
  final String walletName;
  final double balance;
  final String type;
  final DateTime? createdAt;
  final int? userId;

  Wallet({
    this.id,
    required this.walletName,
    required this.balance,
    required this.type,
    this.createdAt,
    this.userId,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    double balance = 0.0;
    try {
      if (json['balance'] != null) {
        if (json['balance'] is String) {
          balance = double.tryParse(json['balance']) ?? 0.0;
        } else if (json['balance'] is num) {
          balance = (json['balance'] as num).toDouble();
        }
      }
    } catch (e) {
    }

    return Wallet(
      id: json['id'] ?? json['wallet_id'],
      walletName: json['walletName'] ?? '',
      balance: balance,
      type: json['type'] ?? 'cash',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      userId: json['user']?['id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'walletName': walletName,
      'balance': balance,
      'type': type,
      'createdAt': createdAt?.toIso8601String(),
      'userId': userId,
    };
  }
}
