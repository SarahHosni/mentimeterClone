import 'package:admin_app/screens/quiz_presentation_screen.dart';
import 'package:shared/models/quiz_model.dart';
import 'package:admin_app/screens/quizDetails_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared/models/session_model.dart';
import 'firebase_options.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/create_quiz_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin App - Mentimeter Clone',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AuthGate(), // 👈 this is the key part
      routes: {
        '/login': (context) => Login(),
        '/register': (context) => Register(),
        '/dashboard': (context) => DashboardScreen(),
        '/create-quiz': (context) => CreateQuizScreen(),
        '/quiz-details': (context) => QuizDetailScreen(quizId: ModalRoute.of(context)!.settings.arguments as String),

        
  '/presentation': (context) {
  final args = ModalRoute.of(context)?.settings.arguments as Map?;
  if (args == null) {
    return Scaffold(
      body: Center(child: Text('No arguments were passed to the presentation screen.')),
    );
  }

  final quiz = args['quiz'];
  final sessionId = args['sessionId'];

  if (quiz == null || sessionId == null) {
    return Scaffold(
      body: Center(child: Text('Required arguments are missing.')),
    );
  }

  return QuizPresentationScreen(
    quiz: quiz, 
    sessionId: sessionId,
  );
},



      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Delay pushing to ensure build completes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (snapshot.hasData) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          } else {
            Navigator.pushReplacementNamed(context, '/login');
          }
        });

        return SizedBox(); // Return empty widget for now
      },
    );
  }
}


