import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:random_avatar/random_avatar.dart';

import './waiting_room_screen.dart';

class EnterNicknameScreen extends StatefulWidget {
  final String quizCode;

  const EnterNicknameScreen({super.key, required this.quizCode});

  @override
  State<EnterNicknameScreen> createState() => _EnterNicknameScreenState();
}

class _EnterNicknameScreenState extends State<EnterNicknameScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://mentimeterclone-d624e-default-rtdb.firebaseio.com',
  );

  @override
  void initState() {
    super.initState();
    _nicknameController.addListener(() {
      setState(() {}); // For avatar preview update
    });
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  void joinSession() async {
    final nickname = _nicknameController.text.trim();

    if (nickname.isEmpty || widget.quizCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a nickname and quiz code')),
      );
      return;
    }

    try {
      final quizQuerySnapshot = await FirebaseFirestore.instance
          .collection('quizzes')
          .where('quizCode', isEqualTo: widget.quizCode)
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

      final sessionSnapshot = await database
          .ref('sessions')
          .orderByChild('quizId')
          .equalTo(quizId)
          .get();

      if (sessionSnapshot.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No active session found for this quiz')),
        );
        return;
      }

      final sessionsMap =
          Map<String, dynamic>.from(sessionSnapshot.value as Map);
      final sessionId = sessionsMap.keys.first;

      final newParticipantRef =
          database.ref('sessions/$sessionId/participants').push();

      final String avatarSvg = RandomAvatarString(nickname, trBackground: true);

      await newParticipantRef.set({
        'nickname': nickname,
        'joinedAt': ServerValue.timestamp,
        'score': 0,
        'avatar': avatarSvg,
      });

      await newParticipantRef.onDisconnect().remove();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully joined session!')),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WaitingRoomScreen(
            nickname: nickname,
            quizCode: widget.quizCode,
            sessionId: sessionId,
            participantId: newParticipantRef.key!,
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

  @override
  Widget build(BuildContext context) {
    final nickname = _nicknameController.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Nickname'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Joining quiz: ${widget.quizCode}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            if (nickname.isNotEmpty)
              SvgPicture.string(
                RandomAvatarString(nickname, trBackground: true),
                width: 100,
                height: 100,
              )
            else
              const SizedBox(height: 100),
            const SizedBox(height: 20),
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
              onPressed: joinSession,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
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
