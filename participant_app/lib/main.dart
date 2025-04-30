import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/waiting_room_screen.dart';
import 'screens/player_quiz_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mentimeter Clone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) =>  HomeScreen(),
        '/waiting-room': (context) => WaitingRoomScreen(
              nickname: '', // Replace with actual values when navigating
              quizCode: '',
              sessionId: '',
              participantId: '',
            ),
        '/playerQuiz': (context) => PlayerQuizScreen(
              sessionId: '', // Replace with actual values when navigating
              participantId: '',
              questions: [], // Pass preloaded questions
              currentQuestionIndex: 0, // Pass initial question index
            ),
      },
    );
  }
}