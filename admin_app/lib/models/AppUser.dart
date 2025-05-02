import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String userName;
  final String email;
  final List<SharedQuiz> shared;

  AppUser({
    required this.uid,
    required this.userName,
    required this.email,
    List<SharedQuiz>? shared, // optional
  }) : shared = shared ?? [];

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;

    return AppUser(
      uid: data['uid'],
      userName: data['userName'],
      email: data['email'],
      shared: (data['shared'] as List?)
              ?.map((item) => SharedQuiz.fromMap(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'userName': userName,
      'email': email,
      'shared': shared.map((s) => s.toMap()).toList(),
    };
  }
}

class SharedQuiz {
  final String quizId;
  final String right; // 'read' or 'edit'

  SharedQuiz({
    required this.quizId,
    required this.right,
  });

  factory SharedQuiz.fromMap(Map<String, dynamic> map) {
    return SharedQuiz(
      quizId: map['quizId'],
      right: map['right'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'quizId': quizId,
      'right': right,
    };
  }
}
