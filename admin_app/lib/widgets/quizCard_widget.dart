import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared/models/quiz_model.dart';
import '../screens/create_quiz_screen.dart';
import '../screens/quiz_presentation_screen.dart'; // Assuming this is the presentation screen

class QuizCard extends StatelessWidget {
  final QuizModel quiz;
  final VoidCallback onDelete;
  final VoidCallback onEdited;
  final VoidCallback onTap;
  final VoidCallback onStartPresentation;
  final bool IsEdit;
  // final String sharedBy;
  const QuizCard({
    super.key,
    required this.quiz,
    required this.onDelete,
    required this.onEdited,
    required this.onTap,
    required this.onStartPresentation,
    required this.IsEdit,
    // required this.sharedBy
  });

  String _formatDate(DateTime date) {
    return '${_monthName(date.month)} ${date.day}, ${date.year}';
  }

  String _monthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month];
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 6, // Slightly higher elevation for a more refined look
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18), // More rounded corners
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 129, // Slightly increased preview section height
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                color: Colors.deepPurple[50], // Light purple background
              ),
              child: Center(
                child: Text(
                  'Preview', // Ideally replace this with a quiz thumbnail or placeholder
                  style: TextStyle(color: Colors.deepPurple[300], fontSize: 16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24, // Slightly larger avatar for better visibility
                    backgroundColor: Colors.deepPurple[200],
                    child: Text(
                      user?.email?[0].toUpperCase() ?? 'A',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz.title.isEmpty ? 'Untitled Quiz' : quiz.title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors
                                .deepPurple[800], // Darker purple for title
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          quiz.editedAt != null
                              ? 'Edited ${_formatDate(quiz.editedAt!.toDate())}'
                              : 'Created ${_formatDate(quiz.createdAt.toDate())}',
                          style: TextStyle(
                              color: Colors.deepPurple[400], fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  if (IsEdit)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          onEdited();
                        } else if (value == 'delete') {
                          onDelete();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ElevatedButton(
                onPressed: onStartPresentation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple, // Deep purple button
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 32), // Adjust horizontal and vertical padding
                ),
                child: Text(
                  'Present',
                  style: TextStyle(
                      fontSize: 16, color: Colors.white), // White text
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
