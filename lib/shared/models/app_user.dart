import 'package:flutter/foundation.dart';

import 'package:tindascan/core/constants/firestore_paths.dart';
import 'package:tindascan/shared/models/firestore_parsing.dart';
import 'package:tindascan/shared/models/user_role.dart';

/// Profile stored at `users/{uid}`. The role lives here (not in custom
/// claims) so the app works on the free Spark plan without Cloud Functions.
@immutable
class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.active,
    this.createdAt,
  });

  factory AppUser.fromMap(String uid, Map<String, Object?> map) => AppUser(
    uid: uid,
    name: map.readString(UserFields.name),
    email: map.readString(UserFields.email),
    role: UserRole.fromValue(map[UserFields.role]),
    active: map.readBool(UserFields.active),
    createdAt: map.readDateTime(UserFields.createdAt),
  );

  final String uid;
  final String name;
  final String email;
  final UserRole role;

  /// Deactivated users are signed out and blocked by the rules.
  final bool active;

  /// Server-assigned creation time (null until the write is acknowledged).
  final DateTime? createdAt;

  bool get isOwner => role.isOwner;

  /// Fields written on creation; timestamps are added by the repository.
  Map<String, Object?> toMap() => {
    UserFields.name: name,
    UserFields.email: email,
    UserFields.role: role.value,
    UserFields.active: active,
  };

  AppUser copyWith({String? name, bool? active}) => AppUser(
    uid: uid,
    name: name ?? this.name,
    email: email,
    role: role,
    active: active ?? this.active,
    createdAt: createdAt,
  );

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.uid == uid &&
      other.name == name &&
      other.email == email &&
      other.role == role &&
      other.active == active &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(uid, name, email, role, active, createdAt);
}
