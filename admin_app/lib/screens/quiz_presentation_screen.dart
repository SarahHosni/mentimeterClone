import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared/models/quiz_model.dart';

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
  bool _isQuizStarted = false; // To track if quiz has started
  int _currentQuestionIndex = 0; // Track the current question index
  Map<int, int> _results = {}; // To store results for the current question
  bool _isTimerRunning = false; // To track if the timer is running
  Timer? _timer; // Timer to manage question duration

  @override
  void initState() {
    super.initState();
    // Set up references
    participantsRef = database.ref('sessions/${widget.sessionId}/participants');
    sessionRef = database.ref('sessions/${widget.sessionId}');
    responsesRef = database.ref('sessions/${widget.sessionId}/responses');

    // Listen for changes in the participants
    participantsRef.onChildAdded.listen(_onParticipantAdded);
    participantsRef.onChildRemoved.listen(_onParticipantRemoved);

    sessionRef.onDisconnect().remove();
  }

  @override
  void dispose() {
    // Clean up listeners and timer
    participantsRef.onChildAdded.listen(_onParticipantAdded).cancel();
    participantsRef.onChildRemoved.listen(_onParticipantRemoved).cancel();
    _timer?.cancel();
    super.dispose();
  }

  // When a new participant is added
  void _onParticipantAdded(DatabaseEvent event) {
    setState(() {
      if (event.snapshot.value != null) {
        participants.add(Map<String, dynamic>.from(event.snapshot.value as Map));
      }
    });
  }

  // When a participant is removed
  void _onParticipantRemoved(DatabaseEvent event) {
    setState(() {
      participants.removeWhere((participant) =>
          participant['nickname'] == event.snapshot.key); // Remove participant by key
    });
  }

  // Start the quiz and set the first question to show
  void _startQuiz() {
    setState(() {
      _isQuizStarted = true;
      _startTimer(); // Start the timer for the first question
    });

    // Update Firebase to indicate that the quiz has started
    sessionRef.update({'quizStarted': true, 'currentQuestionIndex': _currentQuestionIndex});
  }

  // Start the timer for the current question
  void _startTimer() {
    final questionDuration = widget.quiz.questions[_currentQuestionIndex].duration ?? 30; // Default 30 seconds
    setState(() {
      _isTimerRunning = true;
    });

    _timer = Timer(Duration(seconds: questionDuration), () {
      setState(() {
        _isTimerRunning = false; // Timer finished
        _loadResults(); // Load results after timer ends
      });
    });
  }

  // Load results for the current question
  void _loadResults() async {
    final questionKey = 'question_$_currentQuestionIndex';
    final snapshot = await responsesRef.child(questionKey).get();

    if (snapshot.exists) {
      final responses = Map<String, dynamic>.from(snapshot.value as Map);
      final optionCounts = <int, int>{};

      for (var i = 0; i < widget.quiz.questions[_currentQuestionIndex].options.length; i++) {
        optionCounts[i] = 0;
      }

      responses.forEach((_, answerIndex) {
        optionCounts[answerIndex] = (optionCounts[answerIndex] ?? 0) + 1;
      });

      setState(() {
        _results = optionCounts;
      });
    }
  }

  // Go to the next question
  void _goToNextQuestion() {
    if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _results.clear(); // Clear previous results
        _isTimerRunning = false; // Reset timer state
      });

      // Update the current question index in Firebase for sync with participants
      sessionRef.update({'currentQuestionIndex': _currentQuestionIndex});

      // Start the timer for the new question
      _startTimer();
    }
  }

  // Go to the previous question
  void _goToPreviousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _results.clear(); // Clear results when going back
        _isTimerRunning = false; // Reset timer state
      });

      // Update the current question index in Firebase for sync with participants
      sessionRef.update({'currentQuestionIndex': _currentQuestionIndex});
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = widget.quiz.questions.isEmpty
        ? null
        : widget.quiz.questions[_currentQuestionIndex];

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // If the quiz hasn't started, show participants
            if (!_isQuizStarted) ...[
              Text(
                'Waiting for players...',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                            leading: CircleAvatar(child: Text('${index + 1}')),
                            title: Text(nickname),
                          );
                        },
                      ),
              ),
            ]
            // Show question and options after quiz starts
            else ...[
              Text(
                'Question ${_currentQuestionIndex + 1}/${widget.quiz.questions.length}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text(
                currentQuestion?.questionText ?? 'No question available',
                style: TextStyle(fontSize: 24),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Column(
                children: currentQuestion?.options.map((option) {
                      return Container(
                        width: 300, // Limit the width of options
                        margin: EdgeInsets.symmetric(vertical: 8),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blueGrey),
                        ),
                        child: Text(option, style: TextStyle(fontSize: 18)),
                      );
                    }).toList() ??
                    [],
              ),
              SizedBox(height: 20),
              if (_isTimerRunning)
                Text(
                  'Time remaining: ${widget.quiz.questions[_currentQuestionIndex].duration}s',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                )
              else if (_results.isNotEmpty) ...[
                Text(
                  'Results:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ..._results.entries.map((entry) {
                  final optionIndex = entry.key;
                  final count = entry.value;
                  return ListTile(
                    title: Text(widget.quiz.questions[_currentQuestionIndex].options[optionIndex]),
                    trailing: Text('$count votes'),
                  );
                }).toList(),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _currentQuestionIndex > 0 ? _goToPreviousQuestion : null,
                    child: Text("Previous"),
                  ),
                  ElevatedButton(
                    onPressed: !_isTimerRunning && _currentQuestionIndex < widget.quiz.questions.length - 1
                        ? _goToNextQuestion
                        : null,
                    child: Text("Next"),
                  ),
                ],
              ),
            ],
            SizedBox(height: 20),
            // Show the start button if quiz hasn't started yet
            if (!_isQuizStarted)
              ElevatedButton(
                onPressed: _startQuiz,
                child: Text('Start Quiz'),
              ),
          ],
        ),
      ),
    );
  }
}