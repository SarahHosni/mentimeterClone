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

    if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
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
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _startQuiz,
                child: Text('Start Quiz'),
              ),
            ] else ...[
              Text(
                'Question ${_currentQuestionIndex + 1}/${widget.quiz.questions.length}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (!_showingResults) ...[
                        Text(
                          currentQuestion?.questionText ?? 'No question available',
                          style: TextStyle(fontSize: 24),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),
                        Column(
                          children: currentQuestion?.options.map((option) {
                                return Container(
                                  width: 300,
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
                      ] else if (_results.isNotEmpty) ...[
                        Text(
                          'Results:',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        ..._results.entries.map((entry) {
                          final optionIndex = entry.key;
                          final count = entry.value;
                          final totalVotes = _results.values.fold(0, (a, b) => a + b);
                          final percentage = totalVotes == 0 ? 0.0 : (count / totalVotes);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentQuestion!.options[optionIndex],
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                              SizedBox(height: 6),
                              LinearProgressIndicator(
                                value: percentage,
                                minHeight: 14,
                                backgroundColor: Colors.grey[300],
                                color: Colors.blueAccent,
                              ),
                              SizedBox(height: 4),
                              Text('$count votes (${(percentage * 100).toStringAsFixed(1)}%)'),
                              SizedBox(height: 12),
                            ],
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10),
              if (_isTimerRunning)
                Text(
                  'Time remaining: $_remainingTime seconds',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _currentQuestionIndex > 0 ? _goToPreviousQuestion : null,
                    child: Text("Previous"),
                  ),
                  SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: !_isTimerRunning &&
                            _showingResults &&
                            _currentQuestionIndex < widget.quiz.questions.length - 1
                        ? _goToNextQuestion
                        : null,
                    child: Text("Next"),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
