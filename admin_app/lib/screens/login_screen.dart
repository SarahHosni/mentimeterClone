import 'package:flutter/material.dart';
import 'package:admin_app/screens/dashboard_screen.dart';
import 'package:admin_app/screens/register_screen.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
class Login extends StatefulWidget{
  const Login({super.key});
  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login>{
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
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
                    'Login',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  OutlinedButton(
                        onPressed: () async {
                                  UserCredential? userCredential = await _auth.signInWithGoogle(context,isRegistering: false);
                                  if (userCredential != null) {
                                            Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(builder: (context) => DashboardScreen()),
                                              );
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
                              'Login with google')
                          ])
                    ),
                  SizedBox(height: 10),
                  Text("Or using email",
                  style: TextStyle(color: Colors.grey), 
                  textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                          CustomTextField(
                            controller: _emailController,
                            labelText: 'Email',
                            keyboardType: TextInputType.emailAddress,
                          ),
                  SizedBox(height: 16),
                  CustomTextField(
                    controller: _passwordController,
                    labelText: 'Password',
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    onPressed:() async{ 
                      dynamic result = 
                      await _auth.signInWithEmailAndPassword(_emailController.text, _passwordController.text);
                      if(result!=null) {Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(builder: (context) => DashboardScreen()),
                                              );
                                        print("user signed in");} 
                      else print("error signing in");
                    },
                    text:'Login',
                  ),
                  SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Register()),
                      );
                    },
                    child: Text(
                      'Don''t have an account? Register',
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
