import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared/models/question_model.dart';
import 'package:shared/services/score_service.dart';

class PlayerQuizScreen extends StatefulWidget {
  final String sessionId;
  final String participantId;
  final List<dynamic> questions;
  final int currentQuestionIndex;

  const PlayerQuizScreen({
    super.key,
    required this.sessionId,
    required this.participantId,
    required this.questions,
    required this.currentQuestionIndex,
  });

  @override
  State<PlayerQuizScreen> createState() => _PlayerQuizScreenState();
}

class _PlayerQuizScreenState extends State<PlayerQuizScreen> {
  late DatabaseReference sessionRef;
  late DatabaseReference responsesRef;

  late int currentQuestionIndex;
  late List<dynamic> questions;
  bool isAnswered = false;
  String? selectedOption;
  int remainingTime = 0;
  bool isTimerRunning = false;
  bool? isCorrectAnswer;

  StreamSubscription<DatabaseEvent>? sessionListener;
  StreamSubscription<DatabaseEvent>? timerListener;

  @override
  void initState() {
    super.initState();

    questions = widget.questions;
    currentQuestionIndex = widget.currentQuestionIndex;

    sessionRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://mentimeterclone-d624e-default-rtdb.firebaseio.com',
    ).ref('sessions/${widget.sessionId}');

    responsesRef = sessionRef.child('responses');

    sessionListener = sessionRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null && mounted) {
        final int newIndex = data['currentQuestionIndex'] ?? 0;
        if (newIndex != currentQuestionIndex) {
          setState(() {
            currentQuestionIndex = newIndex;
            isAnswered = false;
            selectedOption = null;
            isCorrectAnswer = null;
          });
        }
      }
    });

    timerListener = sessionRef.child('timerState').onValue.listen((event) {
      final timerData = event.snapshot.value as Map?;
      if (timerData != null && mounted) {
        final bool newIsRunning = timerData['isRunning'] ?? false;
        final int newRemainingTime = timerData['remainingTime'] ?? 0;

        setState(() {
          isTimerRunning = newIsRunning;
          remainingTime = newRemainingTime;
        });

        if (!newIsRunning && isAnswered && isCorrectAnswer == null) {
          final question = QuestionModel.fromMap(questions[currentQuestionIndex]);
          final int selectedIndex = question.options.indexOf(selectedOption!);
          final bool correct = selectedIndex == question.correctAnswerIndex;

          setState(() {
            isCorrectAnswer = correct;
          });
        }
      }
    });
  }

  void submitAnswer(String option) async {
    if (!isAnswered && isTimerRunning && remainingTime > 0) {
      setState(() {
        isAnswered = true;
        selectedOption = option;
        isCorrectAnswer = null; // Reset
      });

      final question = QuestionModel.fromMap(questions[currentQuestionIndex]);

      final int selectedIndex = question.options.indexOf(option);
      final bool isCorrect = selectedIndex == question.correctAnswerIndex;
      final int maxTime = question.duration;

      int score = ScoreService.calculateScore(
        isCorrect: isCorrect,
        remainingTime: remainingTime,
        maxTime: maxTime,
      );

      try {
        // Submit answer
        await responsesRef
            .child('question_$currentQuestionIndex/${widget.participantId}')
            .set(option);

        print("Answer submitted: $option");

        // Update score cumulatively
        final participantRef =
            sessionRef.child('participants/${widget.participantId}');

        final snapshot = await participantRef.child('score').get();
        final int currentScore = snapshot.exists ? (snapshot.value as int) : 0;
        final int updatedScore = currentScore + score;

        await participantRef.child('score').set(updatedScore);

        print("Score updated: $updatedScore");
      } catch (e) {
        print("Error submitting answer or updating score: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live Quiz')),
        body: const Center(child: Text('No questions available.')),
      );
    }

    final question = (currentQuestionIndex < questions.length)
        ? QuestionModel.fromMap(questions[currentQuestionIndex])
        : null;

    if (question == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live Quiz')),
        body: const Center(child: Text('No question available.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Quiz'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Time Left: ${isTimerRunning ? remainingTime : 0}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question ${currentQuestionIndex + 1}/${questions.length}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              question.questionText,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            ...question.options.map((opt) => RadioListTile<String>(
                  title: Text(opt, style: const TextStyle(fontSize: 18)),
                  value: opt,
                  groupValue: selectedOption,
                  onChanged: isAnswered
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() {
                              selectedOption = value;
                            });
                          }
                        },
                )),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: (!isAnswered &&
                      selectedOption != null &&
                      isTimerRunning &&
                      remainingTime > 0)
                  ? () => submitAnswer(selectedOption!)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(isAnswered ? 'Answer Submitted' : 'Valider'),
            ),
            if (isAnswered && !isTimerRunning && isCorrectAnswer != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  isCorrectAnswer! ? 'Your answer is correct!' : 'Your answer is incorrect!',
                  style: TextStyle(
                    fontSize: 18,
                    color: isCorrectAnswer! ? Colors.green : Colors.red,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    sessionListener?.cancel();
    timerListener?.cancel();
    super.dispose();
  }
}
