// lib/services/quiz_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quiz_model.dart';

class QuizService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
   final _quizCollection = FirebaseFirestore.instance.collection('quizzes');

  Future<void> addQuiz(String quizTitle, List<String> questions, String quizCode, int duration) async {
  try {
    await _firestore.collection('quizzes').add({
      'title': quizTitle,
      'questions': questions,
      'createdAt': Timestamp.now(),
      'quizCode': quizCode,
      'duration': duration,
    });

    print('Quiz added successfully!');
  } catch (e) {
    print('Error adding quiz: $e');
  }
}

 Future<List<QuizModel>> getQuizzesByUser(String uid) async {
    try {
      final querySnapshot = await _quizCollection
          .where('createdBy', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => QuizModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching user quizzes: $e');
      return [];
    }
  }

  // Save a quiz to Firestore
  Future<void> saveQuiz(QuizModel quiz) async {
    try {
      await _firestore.collection('quizzes').add(quiz.toMap());
    } catch (e) {
      print('Error saving quiz: $e');
    }
  }

 Future<void> updateQuiz(QuizModel quiz) async {
  if (quiz.id == null) throw Exception("Quiz ID is required for update.");
  await FirebaseFirestore.instance
      .collection('quizzes')
      .doc(quiz.id)
      .update(quiz.toMap());
}

  Future<void> deleteQuiz(String quizId) async {
    try {
      await _quizCollection.doc(quizId).delete();
    } catch (e) {
      print('Error deleting quiz: $e');
    }
  }


}
