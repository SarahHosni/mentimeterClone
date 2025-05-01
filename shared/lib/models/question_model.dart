class QuestionModel {
  String questionText;
  List<String> options;
  int correctAnswerIndex;
  int duration;

  QuestionModel({
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
     required this.duration,
  });

  // Convert from Map (Firestore format)
  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      questionText: map['questionText'],
      options: List<String>.from(map['options']),
      correctAnswerIndex: map['correctAnswerIndex'],
      duration: map['duration'] ?? 30,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'questionText': questionText,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'duration': duration,
    };
  }
}
