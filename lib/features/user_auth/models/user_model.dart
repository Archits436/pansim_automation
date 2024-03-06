class UserModel {
  final String? id;
  final String userId;
  final String macAddress;
  final String status;
  final String wifi;

  const UserModel({
    this.id,
    required this.userId,
    required this.macAddress,
    required this.status,
    required this.wifi,
  });

  toJson() {
    return {
      "User Id": userId,
      "Mac Address": macAddress,
      "Status": status,
      "Wifi": wifi,
    };
  }
}
