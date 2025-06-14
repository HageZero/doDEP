class AppUser {
  final String username;
  final String uid;
  final int balance;
  final List<String> purchasedStyles;
  final String selectedStyle;
  final int spinsCount;
  final int maxWin;
  final String? avatarPath;
  final DateTime? lastUpdated;

  AppUser({
    required this.username,
    required this.uid,
    this.balance = 0,
    this.purchasedStyles = const [],
    this.selectedStyle = 'classic',
    this.spinsCount = 0,
    this.maxWin = 0,
    this.avatarPath,
    this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'uid': uid,
      'balance': balance,
      'purchasedStyles': purchasedStyles,
      'selectedStyle': selectedStyle,
      'spinsCount': spinsCount,
      'maxWin': maxWin,
      'avatarPath': avatarPath,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    DateTime? lastUpdated;
    final raw = json['lastUpdated'];
    if (raw is String) {
      lastUpdated = DateTime.tryParse(raw);
    } else if (raw != null && raw.runtimeType.toString() == 'Timestamp') {
      // Для Firestore Timestamp (без импорта)
      lastUpdated = (raw as dynamic).toDate();
    } else if (raw is Map && raw['_seconds'] != null) {
      lastUpdated = DateTime.fromMillisecondsSinceEpoch((raw['_seconds'] as int) * 1000);
    }
    return AppUser(
      username: json['username'] as String? ?? '',
      uid: json['uid'] as String? ?? '',
      balance: json['balance'] as int? ?? 0,
      purchasedStyles: (json['purchasedStyles'] as List<dynamic>?)?.cast<String>() ?? [],
      selectedStyle: json['selectedStyle'] as String? ?? 'classic',
      spinsCount: json['spinsCount'] as int? ?? 0,
      maxWin: json['maxWin'] as int? ?? 0,
      avatarPath: json['avatarPath'] as String?,
      lastUpdated: lastUpdated,
    );
  }

  AppUser copyWith({
    String? username,
    String? uid,
    int? balance,
    List<String>? purchasedStyles,
    String? selectedStyle,
    int? spinsCount,
    int? maxWin,
    String? avatarPath,
    DateTime? lastUpdated,
  }) {
    return AppUser(
      username: username ?? this.username,
      uid: uid ?? this.uid,
      balance: balance ?? this.balance,
      purchasedStyles: purchasedStyles ?? this.purchasedStyles,
      selectedStyle: selectedStyle ?? this.selectedStyle,
      spinsCount: spinsCount ?? this.spinsCount,
      maxWin: maxWin ?? this.maxWin,
      avatarPath: avatarPath ?? this.avatarPath,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
} 