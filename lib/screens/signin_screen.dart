import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:future_app/screens/children_screen.dart';
import '../widgets/my_button.dart';

class SignInScreen extends StatefulWidget {
  static const String screenRoute = 'signin_screen';

  const SignInScreen({Key? key}) : super(key: key);

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _auth = FirebaseAuth.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _stayLoggedIn = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final stayLoggedIn = prefs.getBool('stay_logged_in') ?? false;

    if (savedEmail != null) {
      setState(() {
        _emailController.text = savedEmail;
        _stayLoggedIn = stayLoggedIn;
      });
    }
  }

  // Function to validate parent email
  bool _isValidParentEmail(String email) {
    final regex = RegExp(r'^[a-zA-Z0-9_.+-]+@gmail\.com$');
    return regex.hasMatch(email);
  }

  Future<void> _signIn() async {
    setState(() => _isLoading = true);

    final email = _emailController.text;
    final password = _passwordController.text;

    // First check if fields are filled
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields!'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    // Check email validity
    if (!_isValidParentEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid email! Must be a parent Gmail account'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    // Attempt login after passing all validations
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Save credentials if "Stay logged in" is checked
        final prefs = await SharedPreferences.getInstance();
        if (_stayLoggedIn) {
          await prefs.setString('saved_email', email);
          await prefs.setBool('stay_logged_in', true);
        } else {
          await prefs.remove('saved_email');
          await prefs.remove('stay_logged_in');
        }

        Navigator.pushReplacementNamed(
          context,
          ChildrenScreen.screenRoute,
          arguments: userCredential.user!.uid,
        );
      }
    } catch (e) {
      print('failed to sign in: $e');

      // Firebase error message
      String errorMessage = 'Sign in failed';

      // Determine error type based on Firebase message
      if (e is FirebaseAuthException) {
        if (e.code == 'user-not-found') {
          errorMessage = 'Email is not registered';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Incorrect password';
        } else if (e.code == 'invalid-credential') {
          errorMessage = 'Invalid credentials';
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Function to handle password reset
  Future<void> _resetPassword() async {
    final email = _emailController.text;

    // Validate email before sending reset link
    if (email.isEmpty || !_isValidParentEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid Gmail address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);

      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Password Reset Sent'),
          content: Text(
            'A password reset link has been sent to $email. '
            'Please check your inbox and follow the instructions.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email';
          break;
        default:
          errorMessage = 'Error sending reset email: ${e.message}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Row(children: [
          Text("Sign in Page"),
        ]),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        // تم إضافة SingleChildScrollView لحل مشكلة الشريط الأصفر
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20), // إضافة مسافة من الأعلى
              Container(
                height: 180,
                child: Image.asset('images/signphoto.png'),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'Enter your Email',
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 20,
                  ),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.orange,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.blue,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 20,
                  ),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.orange,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.blue,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Checkbox(
                          value: _stayLoggedIn,
                          onChanged: (value) {
                            setState(() {
                              _stayLoggedIn = value!;
                            });
                          },
                          activeColor: Colors.deepPurple,
                        ),
                        Flexible(
                          child: const Text(
                            'Stay logged in',
                            style: TextStyle(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _resetPassword,
                        child: const Text(
                          'Forgot password?',
                          style:
                              TextStyle(fontSize: 16, color: Colors.deepPurple),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Colors.deepPurple))
                  : MyButton(
                      color: Colors.deepPurple,
                      title: 'Sign in',
                      onPressed: _signIn,
                    ),
              const SizedBox(height: 20), // إضافة مسافة من الأسفل
            ],
          ),
        ),
      ),
    );
  }
}
