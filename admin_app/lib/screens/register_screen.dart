import 'package:flutter/material.dart';
import 'package:admin_app/screens/dashboard_screen.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:admin_app/screens/login_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
class Register extends StatefulWidget{
  const Register({super.key});
  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register>{
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final AuthService _auth = AuthService();
 
   @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 500), 
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Register',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                  onPressed: () async {
                UserCredential? userCredential = await _auth.signInWithGoogle(context,isRegistering: true);
                if (userCredential != null) {
                  print("User signed in: ${userCredential.user?.displayName}");
                }
              },

              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(19.0),
                ),
                side: BorderSide(color: Colors.black),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/icons/google.png', 
                    height: 24,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Register with google')
                ])),
                  SizedBox(height: 10),
                  Text("Or using email",
                  style: TextStyle(color: Colors.grey), 
                  textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                          CustomTextField(
                            controller: _userNameController,
                            labelText: 'UserName',
                            keyboardType: TextInputType.name,
                          ),
                          const SizedBox(height: 20),
                          CustomTextField(
                            controller: _emailController,
                            labelText: 'Email',
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _passwordController,
                            labelText: 'Password',
                            obscureText: true,
                          ),
                          const SizedBox(height: 24),
                          CustomButton(
                            onPressed: () async {
                              dynamic result = await _auth.registerWithEmailAndPassword( _userNameController.text ,_emailController.text, _passwordController.text);
                              if(result!=null) {
                                print("user registred successfully");
                              } else {
                                print("error while registring user");
                              }
                            },
                            text:'Register',
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => Login()),
                            );
                            },
                            child: Text(
                              'Already have an account? Login',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).primaryColor,
                      ),
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
