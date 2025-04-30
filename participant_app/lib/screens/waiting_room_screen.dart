import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:participant_app/screens/player_quiz_screen.dart';

final database = FirebaseDatabase.instanceFor(
  app: Firebase.app(),
  databaseURL: 'https://mentimeterclone-d624e-default-rtdb.firebaseio.com',
);

class WaitingRoomScreen extends StatefulWidget {
  final String nickname;
  final String quizCode;
  final String sessionId;
  final String participantId;

  const WaitingRoomScreen({
    super.key,
    required this.nickname,
    required this.quizCode,
    required this.sessionId,
    required this.participantId,
  });

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  late DatabaseReference sessionRef;

  @override
  void initState() {
    super.initState();

    sessionRef = database.ref('sessions/${widget.sessionId}');

    // Listen specifically for changes to the `quizStarted` field
    sessionRef.child('quizStarted').onValue.listen(
      (event) async {
        final data = event.snapshot.value;
        if (data is bool && data) {
          print("Quiz has started. Preparing to redirect participant...");

          // Quiz has started — check if questions are ready
          try {
            final sessionSnapshot = await sessionRef.get();
            final sessionData = sessionSnapshot.value as Map?;

            if (sessionData != null && sessionData['quizId'] != null) {
              final quizId = sessionData['quizId'];
              final currentQuestionIndex = sessionData['currentQuestionIndex'] ?? 0;

              // Load questions from Firestore
              final quizDoc = await FirebaseFirestore.instance.collection('quizzes').doc(quizId).get();
              if (quizDoc.exists) {
                final quizData = quizDoc.data();
                if (quizData != null && quizData['questions'] != null) {
                  final rawQuestions = List<Map<String, dynamic>>.from(quizData['questions']);
                  final questions = rawQuestions.map((q) => q).toList();

                  // Ensure there are questions and the index is valid
                  if (questions.isNotEmpty && currentQuestionIndex < questions.length) {
                    print("Questions loaded successfully. Redirecting participant...");
if (context.mounted) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => PlayerQuizScreen(
        sessionId: widget.sessionId,
        participantId: widget.participantId,
        questions: questions, // Pass the loaded questions
        currentQuestionIndex: currentQuestionIndex, // Pass the current question index
      ),
    ),
  );
}
                  } else {
                    print("Error: No valid questions found in Firestore for quizId: $quizId");
                  }
                } else {
                  print("Error: No questions field found in Firestore for quizId: $quizId");
                }
              } else {
                print("Error: Quiz not found in Firestore for quizId: $quizId");
              }
            } else {
              print("Error: Missing quizId or invalid session data.");
            }
          } catch (e) {
            print("Error while preparing to redirect participant: $e");
          }
        }
      },
      onError: (error) {
        print('Error while listening to quizStarted: $error');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Waiting Room'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Hello, ${widget.nickname}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'The quiz will start shortly...',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(),
            const SizedBox(height: 40),
            const Text(
              'Quiz Code:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            SelectableText(
              widget.quizCode,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                _leaveSession(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Leave Waiting Room'),
            ),
          ],
        ),
      ),
    );
  }

  void _leaveSession(BuildContext context) async {
    try {
      await database
          .ref('sessions/${widget.sessionId}/participants/${widget.participantId}')
          .remove();
      print("Participant removed successfully.");
    } catch (e) {
      print('Error removing participant: $e');
    }

    if (context.mounted) {
      Navigator.pop(context);
    }
  }
}