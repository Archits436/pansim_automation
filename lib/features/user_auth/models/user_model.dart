class UserModel {
  final String? id;
  final String email;
  final String macAddress;
  final String status;

  const UserModel({
    this.id,
    required this.email,
    required this.macAddress,
    required this.status,
  });

  toJson() {
    return {
      "Email": email,
      "Mac Address": macAddress,
      "Status": status,
    };
  }
}
