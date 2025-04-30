import 'package:cloud_firestore/cloud_firestore.dart';

class SessionModel {
  final String id; // Firestore document ID
  final String quizId;
  final Timestamp startedAt;
  final bool isActive;
  final int currentQuestionIndex;

  SessionModel({
    required this.id,
    required this.quizId,
    required this.startedAt,
    required this.isActive,
    required this.currentQuestionIndex,
  });

  Map<String, dynamic> toMap() {
    return {
      'quizId': quizId,
      'startedAt': startedAt,
      'isActive': isActive,
      'currentQuestionIndex': currentQuestionIndex,
    };
  }

  factory SessionModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SessionModel(
      id: doc.id,
      quizId: data['quizId'],
      startedAt: data['startedAt'],
      isActive: data['isActive'],
      currentQuestionIndex: data['currentQuestionIndex'],
    );
  }
}
