import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String currencyCode;
  final DateTime? createdAt;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.currencyCode = 'LKR',
    this.createdAt,
  });

  factory UserProfile.fromJson(String uid, Map<String, dynamic> json) {
    return UserProfile(
      uid: uid,
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      currencyCode: json['currencyCode'] as String? ?? 'LKR',
      createdAt: switch (json['createdAt']) {
        Timestamp timestamp => timestamp.toDate(),
        String date => DateTime.tryParse(date),
        _ => null,
      },
    );
  }

  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? currencyCode,
    DateTime? createdAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      currencyCode: currencyCode ?? this.currencyCode,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
