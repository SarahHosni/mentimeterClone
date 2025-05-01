import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class LeaderboardScreen extends StatefulWidget {
  final String sessionId;

  const LeaderboardScreen({required this.sessionId, Key? key}) : super(key: key);

  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with TickerProviderStateMixin {
  late DatabaseReference participantsRef;
  List<Map<String, dynamic>> participants = [];
  bool isLoading = true;
  List<AnimationController> _controllers = [];
  List<Animation<Offset>> _animations = [];

  @override
  void initState() {
    super.initState();
    participantsRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://mentimeterclone-d624e-default-rtdb.firebaseio.com',
    ).ref('sessions/${widget.sessionId}/participants');
    _fetchParticipants();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchParticipants() async {
    final snapshot = await participantsRef.get();

    if (snapshot.exists) {
      final participantsMap = Map<String, dynamic>.from(snapshot.value as Map);
      final ranked = participantsMap.entries.map((entry) {
        final data = Map<String, dynamic>.from(entry.value);
        return {
          'id': entry.key,
          'nickname': data['nickname'] ?? 'Unnamed',
          'score': data['score'] ?? 0,
        };
      }).toList();

      ranked.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

      for (int i = 0; i < ranked.length; i++) {
        final controller = AnimationController(
          vsync: this,
          duration: Duration(milliseconds: 300 + i * 100),
        );
        final animation = Tween<Offset>(
          begin: Offset(0, 0.5),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
        _controllers.add(controller);
        _animations.add(animation);
      }

      setState(() {
        participants = ranked;
        isLoading = false;
      });

      for (final controller in _controllers) {
        controller.forward();
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildMedal(int index) {
    switch (index) {
      case 0:
        return Icon(Icons.emoji_events, color: Colors.amber, size: 28);
      case 1:
        return Icon(Icons.emoji_events, color: Colors.grey, size: 26);
      case 2:
        return Icon(Icons.emoji_events, color: Colors.brown, size: 24);
      default:
        return CircleAvatar(
          backgroundColor: Colors.deepPurple,
          child: Text(
            '${index + 1}',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
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
          'LeaderBoard',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : participants.isEmpty
              ? Center(child: Text("No participants yet", style: TextStyle(fontSize: 18)))
              : Center(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 600),
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Text(
                              'Top Participants',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Expanded(
                              child: ListView.builder(
                                itemCount: participants.length,
                                itemBuilder: (context, index) {
                                  final p = participants[index];
                                  return SlideTransition(
                                    position: _animations[index],
                                    child: FadeTransition(
                                      opacity: _controllers[index],
                                      child: Card(
                                        color: Colors.deepPurple[50],
                                        elevation: 3,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        margin: const EdgeInsets.symmetric(vertical: 8),
                                        child: ListTile(
                                          leading: _buildMedal(index),
                                          title: Text(
                                            p['nickname'],
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                          trailing: Text(
                                            '${p['score']} pts',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.deepPurple,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}
