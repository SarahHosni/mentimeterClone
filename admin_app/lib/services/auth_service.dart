import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:admin_app/services/user_service.dart';
import 'package:admin_app/models/AppUser.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

 
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      
      return result.user;
    } catch (e) {
      print('Error during sign-in: $e');
      return null;
    }
  }

  // Register with email and password
  Future<User?> registerWithEmailAndPassword(String userName, String email, String password) async {
  try {
    UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    // Get the Firebase Auth user
    User? firebaseUser = result.user;

    if (firebaseUser != null) {
        final newUser = AppUser(
          uid: firebaseUser.uid,
          userName: userName,
          email: email,
        );
        await UserService().createUser(newUser);
      }

    return firebaseUser;
  } catch (e) {
    print('Error during registration: $e');
    return null;
  }
}


  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error during sign-out: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      print('Error sending password reset email: $e');
    }
  }


  Future<UserCredential?> signInWithGoogle(BuildContext context,{required bool isRegistering}) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: "44011533978-afrsk1u2l4d5m72orohh0ab8rdlvkq8k.apps.googleusercontent.com", 
        scopes: ['email'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null; // User canceled sign-in

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
          User? user = userCredential.user;

    if (isRegistering && user != null) {
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        if (!doc.exists) {
          final newUser = AppUser(
            uid: user.uid,
            userName: user.displayName ?? "Google User",
            email: user.email ?? "unknown",
          );
          await UserService().createUser(newUser);
        }
      }
     
     
      return userCredential;
    } catch (e) {
      print("Error signing in with Google: $e");
      return null;
    }
  }
}

