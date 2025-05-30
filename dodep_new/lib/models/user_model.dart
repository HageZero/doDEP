class UserModel {
  final String id;
  final String username;
  final String password;
  final double balance;
  final List<String> purchasedStyles;
  final String? avatarUrl;
  final double totalWinnings;
  final int spinsCount;
  final double maxWin;

  UserModel({
    required this.id,
    required this.username,
    required this.password,
    required this.balance,
    required this.purchasedStyles,
    this.avatarUrl,
    required this.totalWinnings,
    required this.spinsCount,
    required this.maxWin,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'balance': balance,
      'purchasedStyles': purchasedStyles.join(','),
      'avatarUrl': avatarUrl,
      'totalWinnings': totalWinnings,
      'spinsCount': spinsCount,
      'maxWin': maxWin,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      balance: map['balance'],
      purchasedStyles: (map['purchasedStyles'] as String).split(','),
      avatarUrl: map['avatarUrl'],
      totalWinnings: map['totalWinnings'],
      spinsCount: map['spinsCount'],
      maxWin: map['maxWin'],
    );
  }
} 