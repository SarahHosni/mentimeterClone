import 'package:firebase_database/firebase_database.dart';

class ScoreService {
  final DatabaseReference participantsRef;

  ScoreService({required this.participantsRef});

  /// Calculates a score based on correctness and remaining time.
  ///
  /// Returns a score between 0 and 100.
  static int calculateScore({
    required bool isCorrect,
    required int remainingTime,
    required int maxTime,
  }) {
    if (!isCorrect || maxTime <= 0 || remainingTime <= 0) {
      return 0;
    }

    double timeRatio = remainingTime / maxTime;
    int score = (timeRatio * 100).round();

    return score.clamp(0, 100);
  }

  /// Fetches participants and returns them sorted by descending score.
  Future<List<Map<String, dynamic>>> fetchAndRankParticipants() async {
    final snapshot = await participantsRef.get();

    if (!snapshot.exists) return [];

    final participantsMap = Map<String, dynamic>.from(snapshot.value as Map);

    final rankedParticipants = participantsMap.entries.map((entry) {
      final data = Map<String, dynamic>.from(entry.value);
      return {
        'id': entry.key,
        'nickname': data['nickname'] ?? 'Unnamed',
        'score': (data['score'] ?? 0) is int
            ? data['score']
            : int.tryParse(data['score'].toString()) ?? 0,
      };
    }).toList();

    rankedParticipants.sort(
        (a, b) => (b['score'] as int).compareTo(a['score'] as int));

    return rankedParticipants;
  }
}
