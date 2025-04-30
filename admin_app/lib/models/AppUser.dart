import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String userName;
  final String email;

  AppUser({
    required this.uid,
    required this.userName,
    required this.email,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;

    return AppUser(
      userName: data['userName'],
      email: data['email'],
      uid: data['uid'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userName': userName,
      'email': email,
      'uid': uid,
    };
  }
}
