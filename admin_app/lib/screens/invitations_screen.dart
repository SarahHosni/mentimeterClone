import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class InvitationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invitations'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purple.shade300],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('invitations')
            .where('toEmail',
                isEqualTo: FirebaseAuth.instance.currentUser!.email)
            .where('status',
                isEqualTo: 'pending') // Only show pending invitations
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final invitations = snapshot.data!.docs;

          if (invitations.isEmpty) {
            return Center(child: Text('No new invitations'));
          }

          return ListView.builder(
            itemCount: invitations.length,
            itemBuilder: (context, index) {
              final invitation =
                  invitations[index].data() as Map<String, dynamic>;
              final quizId = invitation['quizId'];
              final permission = invitation['right'];
              final fromUid = invitation['fromUid'];
              final fromUser = _getUserName(fromUid);

              return ListTile(
                title: Text('Quiz: $quizId'),
                subtitle: Text('Permission: $permission\nFrom: $fromUser'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.check, color: Colors.green),
                      onPressed: () {
                        // Accept the invitation
                        _acceptInvitation(
                            invitations[index].id, quizId, permission);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Invitation accepted!')),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        // Decline the invitation
                        _declineInvitation(invitations[index].id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Invitation declined.')),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Helper method to fetch the user name (assuming there's a 'users' collection)
  Future<String> _getUserName(String uid) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (userDoc.exists) {
      return userDoc.data()!['userName'] ?? 'Unknown';
    }
    return 'Unknown';
  }

  // Method to accept the invitation
  Future<void> _acceptInvitation(
      String invitationId, String quizId, String permission) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    // Add quiz to the user's shared list
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'shared': FieldValue.arrayUnion([
        {'quizId': quizId, 'right': permission}
      ])
    });

    // Update invitation status to 'accepted'
    await FirebaseFirestore.instance
        .collection('invitations')
        .doc(invitationId)
        .update({
      'status': 'accepted',
    });
  }

  // Method to decline the invitation
  Future<void> _declineInvitation(String invitationId) async {
    // Update invitation status to 'declined'
    await FirebaseFirestore.instance
        .collection('invitations')
        .doc(invitationId)
        .update({
      'status': 'declined',
    });
  }
}
