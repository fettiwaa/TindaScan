/// The two roles in a single-branch store.
enum UserRole {
  owner('owner'),
  staff('staff');

  const UserRole(this.value);

  /// Value stored in Firestore (`users/{uid}.role`).
  final String value;

  /// Parses a stored value; unknown values fall back to the least-privileged
  /// role so a corrupt document can never grant owner access.
  static UserRole fromValue(Object? value) =>
      value == UserRole.owner.value ? UserRole.owner : UserRole.staff;

  bool get isOwner => this == UserRole.owner;
}
