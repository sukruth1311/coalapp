class UserModel {
  String uid;
  String email;
  String role;
  String employeeID; // Add employee ID field

  UserModel(
      {required this.uid,
      required this.email,
      required this.role,
      this.employeeID = ''});

  factory UserModel.fromFirestore(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'],
      email: data['email'],
      role: data['role'],
      employeeID: data['employeeID'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'employeeID': employeeID,
    };
  }
}
