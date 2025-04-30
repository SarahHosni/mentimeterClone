import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class SessionService {
  final database = FirebaseDatabase.instanceFor(
    app: Firebase.app(), 
    databaseURL: 'https://mentimeterclone-d624e-default-rtdb.firebaseio.com', // ✅ correct URL
  );

  Future<String> createSession(String quizId) async {
    final sessionRef = database.ref('sessions').push(); // 🔵 Create a new session
    await sessionRef.set({
      'quizId': quizId,
      'isActive': true,
      'createdAt': ServerValue.timestamp,
    });
    return sessionRef.key!; // ✅ Return the session ID
  }

  Future<void> endSession(String sessionId) async {
    await database.ref('sessions/$sessionId').remove(); // 🔥 Delete the session if admin leaves
  }
}
