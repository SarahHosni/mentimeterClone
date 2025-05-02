import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:participant_app/screens/ended_screen.dart';
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
  bool isTimedOut = false;
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

    // Listen for changes in the session data
    sessionListener = sessionRef.onValue.listen((event) async {
      final data = event.snapshot.value as Map?;
      if (data != null && mounted) {
        // Check if the quiz has ended
        final bool quizEnded = data['quizEnded'] ?? false;
        if (quizEnded) {
          final participantRef =
              sessionRef.child('participants/${widget.participantId}');
          final snapshot = await participantRef.child('score').get();
          final int participantScore =
              snapshot.exists ? (snapshot.value as int) : 0;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => QuizEndedScreen(score: participantScore),
            ),
          );
        }

        // Update current question index
        final int newIndex = data['currentQuestionIndex'] ?? 0;
        if (newIndex != currentQuestionIndex) {
          setState(() {
            currentQuestionIndex = newIndex;
            isAnswered = false;
            isTimedOut = false;
            selectedOption = null;
            isCorrectAnswer = null;
          });
        }
      }
    });

    // Listen for timer updates
    timerListener = sessionRef.child('timerState').onValue.listen((event) {
      final timerData = event.snapshot.value as Map?;
      if (timerData != null && mounted) {
        final bool newIsRunning = timerData['isRunning'] ?? false;
        final int newRemainingTime = timerData['remainingTime'] ?? 0;
        setState(() {
          isTimerRunning = newIsRunning;
          remainingTime = newRemainingTime;
        });

        if (!newIsRunning) {
          // If user submitted but hasn't got result yet
          if (isAnswered && isCorrectAnswer == null) {
            final question =
                QuestionModel.fromMap(questions[currentQuestionIndex]);
            final int selectedIndex = question.options.indexOf(selectedOption!);
            final bool correct = selectedIndex == question.correctAnswerIndex;
            setState(() {
              isCorrectAnswer = correct;
            });
          }

          // ✅ Timeout logic
          if (!isAnswered && !isTimedOut) {
            setState(() {
              isTimedOut = true;
              isAnswered = true; // Lock the options
            });
          }
        }
      }
    });
  }

  void submitAnswer(String option) async {
    if (!isAnswered && isTimerRunning && remainingTime > 0) {
      setState(() {
        isAnswered = true;
        selectedOption = option;
        isCorrectAnswer = null;
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
        await responsesRef
            .child('question_$currentQuestionIndex/${widget.participantId}')
            .set(option);

        final participantRef =
            sessionRef.child('participants/${widget.participantId}');
        final snapshot = await participantRef.child('score').get();
        final int currentScore = snapshot.exists ? (snapshot.value as int) : 0;
        final int updatedScore = currentScore + score;
        await participantRef.child('score').set(updatedScore);
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
        backgroundColor: Colors.deepPurple,
        title: const Text('Live Quiz'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.timer, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  '${isTimerRunning ? remainingTime : 0}s',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Question ${currentQuestionIndex + 1}/${questions.length}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      question.questionText,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 24),
                    ...question.options.map(
                      (opt) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: selectedOption == opt
                              ? Colors.deepPurple.withOpacity(0.1)
                              : Colors.grey[100],
                          border: Border.all(
                            color: selectedOption == opt
                                ? Colors.deepPurple
                                : Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: RadioListTile<String>(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          title:
                              Text(opt, style: const TextStyle(fontSize: 16)),
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
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: (!isAnswered &&
                              selectedOption != null &&
                              isTimerRunning &&
                              remainingTime > 0)
                          ? () => submitAnswer(selectedOption!)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isAnswered ? 'Answer Submitted' : 'Submit',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    if (isAnswered && !isTimerRunning)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Row(
                          children: [
                            Icon(
                              isTimedOut
                                  ? Icons.hourglass_empty
                                  : (isCorrectAnswer!
                                      ? Icons.check_circle
                                      : Icons.cancel),
                              color: isTimedOut
                                  ? Colors.orange
                                  : (isCorrectAnswer!
                                      ? Colors.green
                                      : Colors.red),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isTimedOut
                                  ? 'Time\'s up!'
                                  : (isCorrectAnswer!
                                      ? 'Correct!'
                                      : 'Incorrect!'),
                              style: TextStyle(
                                fontSize: 18,
                                color: isTimedOut
                                    ? Colors.orange
                                    : (isCorrectAnswer!
                                        ? Colors.green
                                        : Colors.red),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
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
