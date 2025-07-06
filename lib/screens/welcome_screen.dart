import 'package:flutter/material.dart';
import 'package:future_app/screens/signin_screen.dart';
import 'package:future_app/screens/TeacherLoginScreen.dart';
import '../widgets/my_button.dart';

class WelcomeScreen extends StatefulWidget {
  static const String screenRoute = 'welcome_screen';

  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:
          false, // تم إضافة هذا السطر لحل مشكلة الشريط الأصفر
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                Container(
                  height: 180,
                  child: Image.asset('images/wallepaper.png'),
                ),
                Text(
                  'Future Education App',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),
            MyButton(
              color: Colors.deepPurple[700]!,
              title: 'Sign in as a parent',
              onPressed: () {
                Navigator.pushNamed(context, SignInScreen.screenRoute);
              },
            ),
            MyButton(
              color: Colors.blue[700]!,
              title: 'Sign in as a teacher',
              onPressed: () {
                Navigator.pushNamed(context, TeacherLoginScreen.screenRoute);
              },
            )
          ],
        ),
      ),
    );
  }
}
