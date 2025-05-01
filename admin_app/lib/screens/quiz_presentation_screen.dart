import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared/models/quiz_model.dart';
import 'package:shared/screens/leaderboard_screen.dart'; // Make sure the path is correct

class QuizPresentationScreen extends StatefulWidget {
  final QuizModel quiz;
  final String sessionId;

  const QuizPresentationScreen({
    required this.quiz,
    required this.sessionId,
    Key? key,
  }) : super(key: key);

  @override
  _QuizPresentationScreenState createState() => _QuizPresentationScreenState();
}

class _QuizPresentationScreenState extends State<QuizPresentationScreen> {
  final database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://mentimeterclone-d624e-default-rtdb.firebaseio.com',
  );
  late DatabaseReference participantsRef;
  late DatabaseReference sessionRef;
  late DatabaseReference responsesRef;

  List<Map<String, dynamic>> participants = [];
  bool _isQuizStarted = false;
  int _currentQuestionIndex = 0;
  Map<int, int> _results = {};
  bool _isTimerRunning = false;
  int _remainingTime = 0;
  Timer? _timer;
  bool _showingResults = false;

  @override
  void initState() {
    super.initState();
    participantsRef = database.ref('sessions/${widget.sessionId}/participants');
    sessionRef = database.ref('sessions/${widget.sessionId}');
    responsesRef = database.ref('sessions/${widget.sessionId}/responses');
    participantsRef.onChildAdded.listen(_onParticipantAdded);
    participantsRef.onChildRemoved.listen(_onParticipantRemoved);
    sessionRef.onDisconnect().remove();
  }

  @override
  void dispose() {
    participantsRef.onChildAdded.listen(_onParticipantAdded).cancel();
    participantsRef.onChildRemoved.listen(_onParticipantRemoved).cancel();
    _timer?.cancel();
    super.dispose();
  }

  void _onParticipantAdded(DatabaseEvent event) {
    setState(() {
      if (event.snapshot.value != null) {
        participants.add(Map<String, dynamic>.from(event.snapshot.value as Map));
      }
    });
  }

  void _onParticipantRemoved(DatabaseEvent event) {
    setState(() {
      participants.removeWhere((participant) =>
          participant['nickname'] == event.snapshot.key);
    });
  }

  void _startQuiz() {
    setState(() {
      _isQuizStarted = true;
      _startTimer();
    });
    sessionRef.update({
      'quizStarted': true,
      'currentQuestionIndex': _currentQuestionIndex,
      'timerState': {'isRunning': true, 'remainingTime': _remainingTime},
    });
  }

  void _startTimer() {
    final questionDuration = widget.quiz.questions[_currentQuestionIndex].duration ?? 30;
    setState(() {
      _remainingTime = questionDuration;
      _isTimerRunning = true;
    });
    sessionRef.update({
      'timerState': {'isRunning': true, 'remainingTime': _remainingTime},
    });
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
          sessionRef.update({
            'timerState': {'isRunning': true, 'remainingTime': _remainingTime},
          });
        } else {
          _timer?.cancel();
          _isTimerRunning = false;
          sessionRef.update({
            'timerState': {'isRunning': false, 'remainingTime': 0},
          });
          _loadResults();
          _showingResults = true;
        }
      });
    });
  }

  Future<void> _loadResults() async {
    final questionKey = 'question_$_currentQuestionIndex';
    final snapshot = await responsesRef.child(questionKey).get();
    if (snapshot.exists) {
      final responses = Map<String, dynamic>.from(snapshot.value as Map);
      final optionCounts = <int, int>{};
      final currentOptions = widget.quiz.questions[_currentQuestionIndex].options;
      for (int i = 0; i < currentOptions.length; i++) {
        optionCounts[i] = 0;
      }
      responses.forEach((_, answerText) {
        if (answerText is String) {
          int index = currentOptions.indexOf(answerText);
          if (index != -1) {
            optionCounts[index] = (optionCounts[index] ?? 0) + 1;
          }
        }
      });
      setState(() {
        _results = optionCounts;
      });
    }
  }

  Future<void> _goToNextQuestion() async {
    setState(() {
      _showingResults = true;
    });
    await _loadResults();
    await Future.delayed(Duration(seconds: 3));
    final isLastQuestion = _currentQuestionIndex >= widget.quiz.questions.length - 1;
    if (isLastQuestion) {
      // Mark quiz as ended
      await sessionRef.update({'quizEnded': true});
      // Navigate to leaderboard
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LeaderboardScreen(sessionId: widget.sessionId),
          ),
        );
      }
    } else {
      // Go to next question
      setState(() {
        _currentQuestionIndex++;
        _results.clear();
        _isTimerRunning = false;
        _showingResults = false;
      });
      sessionRef.update({
        'currentQuestionIndex': _currentQuestionIndex,
        'timerState': {'isRunning': false, 'remainingTime': 0},
      });
      _startTimer();
    }
  }

  void _goToPreviousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _results.clear();
        _isTimerRunning = false;
        _showingResults = false;
      });
      sessionRef.update({
        'currentQuestionIndex': _currentQuestionIndex,
        'timerState': {'isRunning': false, 'remainingTime': 0},
      });
    }
  }

  Future<void> _terminateQuiz() async {
    await sessionRef.remove();
    if (mounted) {
      Navigator.of(context).pop(); // Return to previous screen
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 600;

    final currentQuestion = widget.quiz.questions.isEmpty
        ? null
        : widget.quiz.questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purple.shade300],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          'Quiz Presentation',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.stop_circle_outlined),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('End Quiz?'),
                  content: Text('Are you sure you want to terminate the quiz session?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('Terminate'),
                    ),
                  ],
                ),
              );
              if (confirm == true) _terminateQuiz();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Progress Indicator
              LinearProgressIndicator(
                value: (_currentQuestionIndex + 1) / widget.quiz.questions.length,
                backgroundColor: Colors.grey[300],
                color: Colors.deepPurple,
                minHeight: 8,
              ),
              SizedBox(height: 16),

              if (!_isQuizStarted) ...[
                Text(
                  'Waiting for players...',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: participants.isEmpty
                      ? Center(child: Text('No participants yet'))
                      : ListView.builder(
                          itemCount: participants.length,
                          itemBuilder: (context, index) {
                            final participant = participants[index];
                            final nickname = participant['nickname'] ?? 'Unnamed';
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.deepPurple,
                                child: Text('${index + 1}'),
                              ),
                              title: Text(nickname),
                            );
                          },
                        ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _startQuiz,
                  child: Text('Start Quiz', style: TextStyle(color:Colors.white,)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                    textStyle: TextStyle(fontSize: 18),
                  ),
                ),
              ] else ...[
                Text(
                  'Question ${_currentQuestionIndex + 1}/${widget.quiz.questions.length}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        if (!_showingResults) ...[
                          Card(
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentQuestion?.questionText ?? 'No question available',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 20),
                                  Column(
                                    children: currentQuestion?.options.map((option) {
                                          return Container(
                                            width: 1100,
                                            height:55,
                                            margin: EdgeInsets.symmetric(vertical: 8),
                                            padding: EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: const Color.fromARGB(255, 240, 237, 245),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: Colors.deepPurple),
                                            ),
                                            child: Text(
                                              option,
                                              style: TextStyle(fontSize: 18),
                                            ),
                                          );
                                        }).toList() ??
                                        [],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else if (_results.isNotEmpty) ...[
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Results:',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  ..._results.entries.map((entry) {
                                    final optionIndex = entry.key;
                                    final count = entry.value;
                                    final totalVotes =
                                        _results.values.fold(0, (a, b) => a + b);
                                    final percentage =
                                        totalVotes == 0 ? 0.0 : (count / totalVotes);
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          currentQuestion!.options[optionIndex],
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.deepPurple,
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        LinearProgressIndicator(
                                          value: percentage,
                                          minHeight: 14,
                                          backgroundColor: Colors.grey[300],
                                          color: Colors.deepPurple,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          '$count votes (${(percentage * 100).toStringAsFixed(1)}%)',
                                          style: TextStyle(color: Colors.deepPurple),
                                        ),
                                        SizedBox(height: 12),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10),
                if (_isTimerRunning)
                  Text(
                    'Time remaining: $_remainingTime seconds',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _currentQuestionIndex > 0 ? _goToPreviousQuestion : null,
                      child: Text("Previous", style: TextStyle(color:Colors.white,)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      ),
                    ),
                    SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: !_isTimerRunning &&
                              _showingResults &&
                              _currentQuestionIndex < widget.quiz.questions.length
                          ? _goToNextQuestion
                          : null,
                      child: Text("Next" ,style: TextStyle(color:Colors.white,)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}