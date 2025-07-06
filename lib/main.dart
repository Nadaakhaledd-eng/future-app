/*import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:future_app/firebase_options.dart';
import 'package:device_preview/device_preview.dart';
import 'package:future_app/screens/signin_screen.dart';
import 'package:future_app/screens/welcome_screen.dart';
import 'package:future_app/screens/children_screen.dart';
import 'package:future_app/screens/TeacherLoginScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
/*
  runApp(
    DevicePreview(
      //enabled: true,
      builder: (context) => const MyApp(),
    ),
  );
}*/

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FUTURE',
      locale: DevicePreview.locale(context),
      debugShowCheckedModeBanner: false,
      builder: DevicePreview.appBuilder,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        fontFamily: 'Cairo',
      ),
      initialRoute: WelcomeScreen.screenRoute,
      routes: {
        WelcomeScreen.screenRoute: (context) => const WelcomeScreen(),
        SignInScreen.screenRoute: (context) => const SignInScreen(),
        TeacherLoginScreen.screenRoute: (context) => const TeacherLoginScreen(),
        ChildrenScreen.screenRoute: (context) => const ChildrenScreen(),
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
*/
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:future_app/firebase_options.dart';
import 'package:future_app/screens/signin_screen.dart';
import 'package:future_app/screens/welcome_screen.dart';
import 'package:future_app/screens/children_screen.dart';
import 'package:future_app/screens/TeacherLoginScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FUTURE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        fontFamily: 'Cairo',
      ),
      initialRoute: WelcomeScreen.screenRoute,
      routes: {
        WelcomeScreen.screenRoute: (context) => const WelcomeScreen(),
        SignInScreen.screenRoute: (context) => const SignInScreen(),
        TeacherLoginScreen.screenRoute: (context) => const TeacherLoginScreen(),
        ChildrenScreen.screenRoute: (context) => const ChildrenScreen(),
      },
    );
  }
}
