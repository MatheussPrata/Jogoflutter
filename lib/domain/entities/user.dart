/// Entidade de usuário (sem dependência de serialização).
class User {
  final String id;
  final String username;
  final String email;
  final String passwordHash;
  final String salt;
  final int xp;
  final DateTime createdAt;
  final bool isAdmin;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.passwordHash,
    required this.salt,
    required this.xp,
    required this.createdAt,
    this.isAdmin = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      passwordHash: json['passwordHash'] as String,
      salt: json['salt'] as String,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isAdmin: json['isAdmin'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'passwordHash': passwordHash,
      'salt': salt,
      'xp': xp,
      'createdAt': createdAt.toIso8601String(),
      'isAdmin': isAdmin,
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? passwordHash,
    String? salt,
    int? xp,
    DateTime? createdAt,
    bool? isAdmin,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      salt: salt ?? this.salt,
      xp: xp ?? this.xp,
      createdAt: createdAt ?? this.createdAt,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}