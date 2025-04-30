import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared/models/quiz_model.dart';
import 'package:shared/services/quiz_service.dart';
import 'package:shared/models/question_model.dart';
import 'dart:math';
import '../widgets/appBar_widget.dart';
import '../services/auth_service.dart';

class CreateQuizScreen extends StatefulWidget {
  final QuizModel? quiz; // Optional for edit mode

  CreateQuizScreen({this.quiz});

  @override
  _CreateQuizScreenState createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quizService = QuizService();
  final _auth = AuthService();

  List<QuestionModel> _questions = [];
  bool _isSaving = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    if (widget.quiz != null) {
      // If editing an existing quiz, initialize the form with the quiz data
      _titleController.text = widget.quiz!.title;
      _descriptionController.text = widget.quiz!.description;
      _questions = List.from(widget.quiz!.questions); // Load the quiz questions
    }
  }

  String generateQuizCode() {
    const _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random _rand = Random();
    return List.generate(6, (index) => _chars[_rand.nextInt(_chars.length)]).join();
  }

  void _addQuestion() {
    setState(() {
      _questions.add(
        QuestionModel(
          questionText: '',
          options: ['', '', '', ''],
          correctAnswerIndex: 0,
          duration: 30,  // Default duration
        ),
      );
    });
  }

  Future<void> _saveQuiz() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _questions.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields and add at least one question.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = '';
    });

    final quiz = QuizModel(
      id: widget.quiz?.id,  // If it's an existing quiz, keep the ID; else, it's new
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      createdAt: widget.quiz?.createdAt ?? Timestamp.now(),
      editedAt: Timestamp.now(),
      questions: _questions,
      quizCode: widget.quiz?.quizCode ?? generateQuizCode(),
      createdBy: FirebaseAuth.instance.currentUser!.uid,
    );

    try {
      if (quiz.id != null) {
        await _quizService.updateQuiz(quiz);  // Update existing quiz
      } else {
        await _quizService.saveQuiz(quiz);  // Create a new quiz
      }
      Navigator.pop(context);  // Go back after saving
    } catch (e) {
      setState(() {
        _errorMessage = 'Error saving quiz: $e';
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Widget _buildQuestionCard(int index, QuestionModel question) {
    final questionController = TextEditingController(text: question.questionText);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Question ${index + 1}", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            TextField(
              controller: questionController,
              decoration: InputDecoration(labelText: 'Question Text'),
              onChanged: (value) => question.questionText = value,
            ),
            ...List.generate(4, (i) {
              return TextField(
                decoration: InputDecoration(labelText: 'Option ${i + 1}'),
                onChanged: (value) => question.options[i] = value,
              );
            }),
            SizedBox(height: 10),
            DropdownButtonFormField<int>(
              value: question.correctAnswerIndex,
              decoration: InputDecoration(labelText: 'Correct Answer'),
              items: List.generate(4, (i) {
                return DropdownMenuItem(value: i, child: Text('Option ${i + 1}'));
              }),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    question.correctAnswerIndex = value;
                  });
                }
              },
            ),
            SizedBox(height: 10),
            TextField(
              controller: TextEditingController(text: question.duration.toString()),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Duration (seconds)'),
              onChanged: (value) {
                final duration = int.tryParse(value);
                if (duration != null) {
                  question.duration = duration;
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.quiz == null ? 'Create Quiz' : 'Edit Quiz',
        onLogout: _auth.signOut,
        arrow: true
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text('Quiz Details', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 10),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Quiz Title'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Quiz Description'),
            ),
            SizedBox(height: 20),
            Text('Questions', style: Theme.of(context).textTheme.titleLarge),
            ..._questions.asMap().entries.map(
                  (entry) => _buildQuestionCard(entry.key, entry.value),
                ),
            TextButton.icon(
              onPressed: _addQuestion,
              icon: Icon(Icons.add),
              label: Text('Add Question'),
            ),
            SizedBox(height: 10),
            if (_errorMessage.isNotEmpty)
              Text(_errorMessage, style: TextStyle(color: Colors.red)),
            SizedBox(height: 20),
            _isSaving
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    icon: Icon(Icons.save),
                    label: Text('Save Quiz'),
                    onPressed: _saveQuiz,
                  ),
          ],
        ),
      ),
    );
  }
}
