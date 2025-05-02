import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminQuizLobbyScreen extends StatelessWidget {
  final String quizCode; // Quiz code passed when navigating to this screen

  const AdminQuizLobbyScreen({super.key, required this.quizCode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz Lobby'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('quizzes')
            .doc(quizCode)
            .collection('players')
            .orderBy('joinedAt')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('Waiting for players to join...'),
            );
          }

          final players = snapshot.data!.docs;

          return ListView.builder(
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              final nickname = player['nickname'];

              return ListTile(
                leading: Icon(Icons.person),
                title: Text(nickname),
                subtitle: Text('Joined at: ${player['joinedAt'].toDate().toString()}'),
              );
            },
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            // Later: Start the quiz
            // For now, you can just print
            print('Start Quiz Pressed');
          },
          child: Text('Start Quiz'),
        ),
      ),
    );
  }
}
