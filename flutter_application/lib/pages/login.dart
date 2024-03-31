import 'package:flutter/material.dart';
import 'package:flutter_application/controllers/auth_controller.dart';
import 'package:flutter_application/pages/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application/models/user.dart' as ku_cupid_user;
import 'package:permission_handler/permission_handler.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();
  AuthController authController = AuthController();
  late SharedPreferences prefs;
  bool _obscureText = true;
  bool _isLoggingIn = false;

  @override
  void initState() {
    super.initState();
    initPermission();
    initSharedPref();
  }

  void initPermission() async {
    PermissionStatus status = await Permission.location.request();
    if (status == PermissionStatus.granted) {
      print("permission ok $status");
    } else {
      openAppSettings();
      print("error permission $status");
    }
  }

  void initSharedPref() async {
    prefs = await SharedPreferences.getInstance();
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Login Error"),
        content: Text(errorMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  Widget idField() {
    return TextFormField(
      controller: authController.usernameController,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.person),
        labelText: "Username",
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your username';
        }
        return null;
      },
    );
  }

  Widget passwordField() {
    return TextFormField(
      controller: authController.passwordController,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.lock),
        labelText: "Password",
        border: OutlineInputBorder(),
        suffixIcon: GestureDetector(
          onTap: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
          child: Icon(
            _obscureText ? Icons.visibility_off : Icons.visibility,
          ),
        ),
      ),
      obscureText: _obscureText,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height,
          color: Colors.white, // Set the background color to white
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.network(
                  'https://firebasestorage.googleapis.com/v0/b/ku-cupid-storage.appspot.com/o/ku_cupid_icon.png?alt=media&token=e25e3adf-7d0a-444e-93aa-f82c49aa6bf2',
                  width: MediaQuery.of(context).size.width * 0.5,
                ),
                // Image.asset(
                //   "images/ku_cupid_icon.png",
                //   width: MediaQuery.of(context).size.width * 0.5,
                // ),
                SizedBox(height: 20),
                idField(),
                SizedBox(height: 10),
                passwordField(),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoggingIn
                      ? null
                      : () async {
                          // Disable button if logging in
                          if (formKey.currentState!.validate()) {
                            formKey.currentState!.save();
                            setState(() {
                              _isLoggingIn = true; // Set logging in to true
                            });
                            final loginResult = await authController.login();

                            if (loginResult) {
                              var userToken = authController.getToken();
                              prefs.setString("token", userToken!);
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HomePage(
                                    title: "HomePage",
                                    token: userToken,
                                  ),
                                ),
                              );
                            } else {
                              setState(() {
                                _isLoggingIn = false; // Set logging in to false
                              });
                              _showErrorDialog("Invalid email or password");
                            }
                          }
                        },
                  child: _isLoggingIn
                      ? CircularProgressIndicator() // Show progress indicator while logging in
                      : Text("Login"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
