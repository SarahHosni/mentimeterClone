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

  const CreateQuizScreen({super.key, this.quiz});

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
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rand = Random();
    return List.generate(6, (index) => chars[rand.nextInt(chars.length)]).join();
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Question ${index + 1}",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepPurple),
            ),
            SizedBox(height: 12),
            TextField(
              controller: questionController,
              decoration: InputDecoration(
                labelText: 'Question Text',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              onChanged: (value) => question.questionText = value,
            ),
            SizedBox(height: 12),
            ...List.generate(4, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Option ${i + 1}',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                  onChanged: (value) => question.options[i] = value,
                ),
              );
            }),
            SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: question.correctAnswerIndex,
              decoration: InputDecoration(
                labelText: 'Correct Answer',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
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
            SizedBox(height: 12),
            TextField(
              controller: TextEditingController(text: question.duration.toString()),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Duration (seconds)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
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
        arrow: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text('Quiz Details', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.deepPurple)),
            SizedBox(height: 10),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Quiz Title',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Quiz Description',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
            SizedBox(height: 20),
            Text('Questions', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.deepPurple)),
            SizedBox(height: 10),
            ..._questions.asMap().entries.map(
                  (entry) => _buildQuestionCard(entry.key, entry.value),
                ),
            Center(
              child: TextButton.icon(
                onPressed: _addQuestion,
                icon: Icon(Icons.add, color: Colors.white),
                label: Text('Add Question', style: TextStyle(color: Colors.white)),
                style: TextButton.styleFrom(backgroundColor: Colors.deepPurple, padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8)),
              ),
            ),
            SizedBox(height: 10),
            if (_errorMessage.isNotEmpty)
              Text(_errorMessage, style: TextStyle(color: Colors.red)),
            SizedBox(height: 20),
            Center(
              child: _isSaving
                  ? CircularProgressIndicator()
                  : ElevatedButton.icon(
                      icon: Icon(Icons.save, color: Colors.white),
                      label: Text('Save Quiz', style: TextStyle(color: Colors.white)),
                      onPressed: _saveQuiz,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
