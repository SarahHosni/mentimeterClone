import 'package:cloud_firestore/cloud_firestore.dart';
import 'question_model.dart';
class QuizModel {
  String? id;
  String title;
  String description;
  Timestamp createdAt;
  List<QuestionModel> questions;
  String quizCode;
  String createdBy; 
  Timestamp? editedAt;

  QuizModel({
   this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.questions,
    required this.quizCode,
    required this.createdBy, 
    this.editedAt,
  });

  factory QuizModel.fromFirestore(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    var questionsData = (data['questions'] as List)
        .map((q) => QuestionModel.fromMap(q))
        .toList();

    return QuizModel(
      id: doc.id,
      title: data['title'],
      description: data['description'],
      createdAt: data['createdAt'],
      questions: questionsData,
      quizCode: data['quizCode'],
      createdBy: data['createdBy'], 
      editedAt: data['editedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'createdAt': createdAt,
      'questions': questions.map((q) => q.toMap()).toList(),
      'quizCode': quizCode,
      'createdBy': createdBy, 
    };
  }
}
