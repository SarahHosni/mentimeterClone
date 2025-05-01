import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared/models/quiz_model.dart';

class QuizDetailScreen extends StatefulWidget {
  final String quizId;

  QuizDetailScreen({required this.quizId});

  @override
  _QuizDetailScreenState createState() => _QuizDetailScreenState();
}

class _QuizDetailScreenState extends State<QuizDetailScreen> {
  late Future<QuizModel> _quizDetails;

  @override
  void initState() {
    super.initState();
    if (widget.quizId.isEmpty) {
      throw Exception("Quiz ID is null or empty");
    }
    _quizDetails = _fetchQuizDetails(widget.quizId);
  }

  Future<QuizModel> _fetchQuizDetails(String quizId) async {
    try {
      final quizSnapshot =
          await FirebaseFirestore.instance.collection('quizzes').doc(quizId).get();

      if (quizSnapshot.exists) {
        return QuizModel.fromFirestore(quizSnapshot);
      } else {
        throw Exception('Quiz not found');
      }
    } catch (e) {
      throw Exception('Failed to load quiz details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 600;

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
        title: FutureBuilder<QuizModel>(
          future: _quizDetails,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text('Loading...');
            } else if (snapshot.hasError) {
              return Text('Error');
            } else if (snapshot.hasData) {
              return Text(snapshot.data!.title);
            }
            return Text('No Title');
          },
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/dashboard');
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              _showSnackBar(context, 'Share feature coming soon!');
            },
          ),
        ],
      ),
      body: FutureBuilder<QuizModel>(
        future: _quizDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Failed to load quiz details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _quizDetails = _fetchQuizDetails(widget.quizId);
                      });
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasData) {
            final quiz = snapshot.data!;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 32, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Description Section
                  Card(
                    margin: EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quiz.title,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 24 : 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            quiz.description.isNotEmpty
                                ? quiz.description
                                : 'No description available',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                              SizedBox(width: 8),
                              Text(
                                'Created on: ${_formatDate(quiz.createdAt.toDate())}',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.question_answer, size: 16, color: Colors.grey[600]),
                              SizedBox(width: 8),
                              Text(
                                '${quiz.questions.length} Questions',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Questions Section
                  if (quiz.questions.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: quiz.questions.map((question) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                question.questionText,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 18 : 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              ...question.options.map((option) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.circle,
                                        size: 8,
                                        color: Colors.grey[600],
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        option,
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 14 : 16,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            );
          } else {
            return Center(child: Text('No quiz found.'));
          }
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${_monthName(date.month)} ${date.day}, ${date.year}';
  }

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }
}