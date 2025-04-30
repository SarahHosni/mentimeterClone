import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/AppUser.dart';

class UserService {
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  // CREATE
  Future<void> createUser(AppUser user) async {
    await usersCollection.doc(user.uid).set(user.toMap());
  }

  // READ
  Future<AppUser?> getUser(String uid) async {
    DocumentSnapshot doc = await usersCollection.doc(uid).get();
    if (doc.exists) {
      return AppUser.fromFirestore(doc);
    } else {
      return null;
    }
  }
  Future<AppUser?> getUserByEmail(String email) async {
    DocumentSnapshot doc = await usersCollection.doc(email).get();
    if (doc.exists) {
      return AppUser.fromFirestore(doc);
    } else {
      return null;
    }
  }

  // UPDATE
  Future<void> updateUser(AppUser user) async {
    await usersCollection.doc(user.uid).update(user.toMap());
  }

  // DELETE
  Future<void> deleteUser(String uid) async {
    await usersCollection.doc(uid).delete();
  }

  // STREAM (real-time updates)
  Stream<AppUser?> streamUser(String uid) {
    return usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      } else {
        return null;
      }
    });
  }
}
