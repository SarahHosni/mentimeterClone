import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class LeaderboardScreen extends StatefulWidget {
  final String sessionId; // sessionId to fetch participants

  const LeaderboardScreen({required this.sessionId, Key? key}) : super(key: key);

  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late DatabaseReference participantsRef;
  List<Map<String, dynamic>> participants = [];

  @override
  void initState() {
    super.initState();
    // Initialize the reference to participants based on the session ID
    participantsRef = FirebaseDatabase.instance
        .ref('sessions/${widget.sessionId}/participants');
    
    // Fetch participants data from Firebase
    _fetchParticipants();
  }

  Future<void> _fetchParticipants() async {
    final snapshot = await participantsRef.get();

    if (snapshot.exists) {
      final participantsMap = Map<String, dynamic>.from(snapshot.value as Map);
      final rankedParticipants = participantsMap.entries.map((entry) {
        final data = Map<String, dynamic>.from(entry.value);
        return {
          'id': entry.key,
          'nickname': data['nickname'] ?? '',
          'score': data['score'] ?? 0,
        };
      }).toList();

      // Sort participants by score in descending order
      rankedParticipants.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

      setState(() {
        participants = rankedParticipants;
      });
    } else {
      print("No participants data found");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Leaderboard")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: participants.isEmpty
            ? Center(child: CircularProgressIndicator())  // Show loading while fetching
            : ListView.builder(
                itemCount: participants.length,
                itemBuilder: (context, index) {
                  final participant = participants[index];
                  return ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(participant['nickname'] ?? 'Unnamed'),
                    trailing: Text('${participant['score']}'),
                  );
                },
              ),
      ),
    );
  }
}
