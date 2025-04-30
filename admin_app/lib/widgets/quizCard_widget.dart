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
  final VoidCallback onStartPresentation; // Add callback for starting presentation

  const QuizCard({
    Key? key,
    required this.quiz,
    required this.onDelete,
    required this.onEdited,
    required this.onTap,
    required this.onStartPresentation, // Initialize start presentation callback
  }) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                color: Colors.grey[200],
              ),
              child: Center(
                child: Text(
                  'Preview',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey.shade300,
                    child: Text(
                      user?.email?[0].toUpperCase() ?? 'A',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz.title.isEmpty ? 'Untitled Quiz' : quiz.title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          quiz.editedAt != null
                              ? 'Edited ${_formatDate(quiz.editedAt!.toDate())}'
                              : 'Created ${_formatDate(quiz.createdAt.toDate())}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
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
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: onStartPresentation, // Add the start presentation functionality
                child: Text('Start Presentation'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
