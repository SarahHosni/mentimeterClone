import 'package:flutter/material.dart';

import 'package:shared/models/quiz_model.dart';

class QuizDetailScreen extends StatelessWidget {
  final QuizModel quiz;

  QuizDetailScreen({required this.quiz});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(quiz.title),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/dashboard'); // This will pop the current screen and go back to the previous one
          },
        ),
      ),
      body: Center(child: Text('Details for quiz: ${quiz.title}')),
    );
  }
}
