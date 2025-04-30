import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import './waiting_room_screen.dart';

class EnterNicknameScreen extends StatelessWidget {
  final String quizCode; // Receive the quizCode
  final TextEditingController _nicknameController = TextEditingController();

  EnterNicknameScreen({super.key, required this.quizCode});

  final database = FirebaseDatabase.instanceFor(
    app: Firebase.app(), 
    databaseURL: 'https://mentimeterclone-d624e-default-rtdb.firebaseio.com', // ✅ correct URL
  );

  @override
  Widget build(BuildContext context) {
   void _joinSession() async {
  final nickname = _nicknameController.text.trim();

  if (nickname.isEmpty || quizCode.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter a nickname and quiz code')),
    );
    return;
  }

  try {
    // 1. Find the Quiz by quizCode (Firestore)
    var quizQuerySnapshot = await FirebaseFirestore.instance
        .collection('quizzes')
        .where('quizCode', isEqualTo: quizCode)
        .limit(1)
        .get();

    if (quizQuerySnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz not found')),
      );
      return;
    }

    final quizDoc = quizQuerySnapshot.docs.first;
    final quizId = quizDoc.id;

    // 2. Find the active session in Realtime Database using quizId
    final sessionSnapshot = await database
        .ref('sessions')
        .orderByChild('quizId')
        .equalTo(quizId)
        .get(); // use .get() instead of .once()

    if (sessionSnapshot.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active session found for this quiz')),
      );
      return;
    }

    // 3. Get first session (there might be only one active session for each quiz)
    final sessionsMap = Map<String, dynamic>.from(sessionSnapshot.value as Map);
    final sessionId = sessionsMap.keys.first; // first active session id

    // 4. Add participant under the session
    final newParticipantRef = database
        .ref('sessions/$sessionId/participants')
        .push(); // creates new participant id

    await newParticipantRef.set({
      'nickname': nickname,
      'joinedAt': ServerValue.timestamp,
      'score': 0,
    });

    // 5. Auto-remove participant on disconnect
    await newParticipantRef.onDisconnect().remove();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Successfully joined session!')),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WaitingRoomScreen(
          nickname: nickname,
          quizCode: quizCode,
          sessionId: sessionId,             // 🔥 Pass sessionId
          participantId: newParticipantRef.key!,  // 🔥 Pass participantId
        ),
      ),
    );
  } catch (e) {
    print('Error joining session: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to join session')),
    );
  }
}



    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Nickname'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Joining quiz: $quizCode',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _nicknameController,
              decoration: InputDecoration(
                labelText: 'Enter your nickname',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _joinSession,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Join Quiz'),
            ),
          ],
        ),
      ),
    );
  }
}

