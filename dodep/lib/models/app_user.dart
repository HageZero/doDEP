class AppUser {
  final String username;
  final String uid;
  final int balance;
  final List<String> purchasedStyles;
  final int spinsCount;
  final int maxWin;
  final String? avatarPath;

  AppUser({
    required this.username,
    required this.uid,
    this.balance = 0,
    this.purchasedStyles = const [],
    this.spinsCount = 0,
    this.maxWin = 0,
    this.avatarPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'uid': uid,
      'balance': balance,
      'purchasedStyles': purchasedStyles,
      'spinsCount': spinsCount,
      'maxWin': maxWin,
      'avatarPath': avatarPath,
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      username: json['username'] as String,
      uid: json['uid'] as String,
      balance: json['balance'] as int? ?? 0,
      purchasedStyles: (json['purchasedStyles'] as List<dynamic>?)?.cast<String>() ?? [],
      spinsCount: json['spinsCount'] as int? ?? 0,
      maxWin: json['maxWin'] as int? ?? 0,
      avatarPath: json['avatarPath'] as String?,
    );
  }

  AppUser copyWith({
    String? username,
    String? uid,
    int? balance,
    List<String>? purchasedStyles,
    int? spinsCount,
    int? maxWin,
    String? avatarPath,
  }) {
    return AppUser(
      username: username ?? this.username,
      uid: uid ?? this.uid,
      balance: balance ?? this.balance,
      purchasedStyles: purchasedStyles ?? this.purchasedStyles,
      spinsCount: spinsCount ?? this.spinsCount,
      maxWin: maxWin ?? this.maxWin,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }
} 