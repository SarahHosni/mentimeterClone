import 'package:admin_app/models/AppUser.dart';
import 'package:shared/models/quiz_model.dart';
import 'package:admin_app/screens/create_quiz_screen.dart';
import 'package:admin_app/screens/quiz_presentation_screen.dart';
import 'package:shared/services/quiz_service.dart';
import 'package:shared/services/session_service.dart';
import 'package:admin_app/services/user_service.dart';
import 'package:admin_app/widgets/appBar_widget.dart';
import 'package:admin_app/widgets/navigationRail_widget.dart';
import 'package:admin_app/widgets/quizCard_widget.dart';
import 'package:admin_app/screens/quizDetails_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _auth = FirebaseAuth.instance;
  final _quizService = QuizService();
  late Future<List<QuizModel>> _quizzes;
  AppUser? _user;
  bool isExpanded = false;
  int _selectedIndex = 0;
  QuizModel? _selectedQuiz;
    final _sessionService = SessionService();

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadQuizzes();
  }

  void _loadUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      final fetchedUser = await UserService().getUser(uid);
      if (mounted) { // Check if the widget is still mounted
        setState(() {
          _user = fetchedUser;
        });
      }
    }
  }

  void _loadQuizzes() {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      _quizzes = _quizService.getQuizzesByUser(uid);
    } else {
      _quizzes = Future.value([]);
    }
    if (mounted) { // Check if the widget is still mounted
      setState(() {});
    }
  }

  // Handle navigation based on selected index
  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
      _selectedQuiz = null; // Clear quiz detail when navigating
    });
  }

  // Handle quiz selection to show its details
  void _onQuizSelected(QuizModel quiz) {
    setState(() {
      _selectedQuiz = quiz;
    });
  }

  // Logout function
  void _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
  void _startQuizPresentation(QuizModel quiz) async {
  // 1. Create a session first
  final sessionId = await _startQuizSession(quiz.id!); // ✅ sessionId is a String?

  // 2. If session creation is successful, navigate to presentation screen
  if (sessionId != null) {
    Navigator.pushNamed(
  context,
  '/presentation',
  arguments: {
    'quiz': quiz,
    'sessionId': sessionId,
  },
);
  } else {
    print("Session creation failed");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to start the quiz session')),
    );
  }
}

Future<String?> _startQuizSession(String quizId) async {
  try {
    final sessionId = await _sessionService.createSession(quizId);
    print('Session started with ID: $sessionId');
    return sessionId;
  } catch (e) {
    print('Failed to create session: $e');
    return null; // 🔵 Important: Return null if it fails
  }
}


  // Delete quiz function
  void _deleteQuiz(String quizId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Quiz"),
        content: Text("Are you sure you want to delete this quiz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Delete")),
        ],
      ),
    );
    if (confirm == true) {
      await _quizService.deleteQuiz(quizId);
      if (mounted) {
        _loadQuizzes();
      }
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRailWidget(
            isExpanded: isExpanded,
            onToggle: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onDestinationSelected,
          ),
          Expanded(
            child: Column(
              children: [
                CustomAppBar(
                  title: 'Admin Dashboard',
                  onLogout: _logout,
                  arrow: false
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _selectedQuiz != null
                        ? QuizDetailScreen(quizId: _selectedQuiz!.id!) 
                        : _buildQuizListView(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Builds the list of quizzes in a grid view
  @override
Widget _buildQuizListView() {
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome, ${_user?.userName ?? 'User'}',
          style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CreateQuizScreen()),
            ).then((_) => _loadQuizzes());
          },
          child: Text('Create New Quiz'),
        ),
        SizedBox(height: 20),
        FutureBuilder<List<QuizModel>>(
          future: _quizzes,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            if (snapshot.data == null || snapshot.data!.isEmpty) {
              return Text('No quizzes created yet.');
            }
            final quizzes = snapshot.data!;
            return GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 4 / 3,
              ),
              itemCount: quizzes.length,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final quiz = quizzes[index];
                return QuizCard(
                  quiz: quiz,
                  onEdited: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateQuizScreen(quiz: quiz),
                      ),
                    ).then((_) => _loadQuizzes());
                  },
                  onDelete: () => _deleteQuiz(quiz.id!),
                  onTap: () => _onQuizSelected(quiz),
                  onStartPresentation: () => _startQuizPresentation(quiz), // Add the start presentation handler
                );
              },
            );
          },
        ),
      ],
    ),
  );
}
}
