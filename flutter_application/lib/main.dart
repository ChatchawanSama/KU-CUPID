import 'package:flutter/material.dart';
import 'package:flutter_application/firebase_options.dart';
import 'package:flutter_application/pages/home.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/login.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
  SharedPreferences prefs = await SharedPreferences.getInstance();
  runApp(MyApp(
    token: prefs.get("token"),
  ));
}

class MyApp extends StatelessWidget {
  var token;
  MyApp({
    @required this.token,
    Key? key,
  }) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'KU Cupid',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: (token != null)
            ? HomePage(
                title: 'HomePage',
                token: token,
              )
            : LoginPage(title: "Login"));
  }
}
