import 'package:flutter/material.dart';
import 'package:flutter_application/controllers/auth_controller.dart';
import 'package:flutter_application/pages/login.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({Key? key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  AuthController authController = AuthController();

  bool _showOnNearby = true;
  bool _showBySearch = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Setting")),
      body: Column(
        children: [
          ListTile(
            title: Text("Don't show me on nearby"),
            trailing: Switch(
              value: _showOnNearby,
              onChanged: (value) {
                setState(() {
                  _showOnNearby = value;
                });
              },
            ),
          ),
          ListTile(
            title: Text("Don't show me by search"),
            trailing: Switch(
              value: _showBySearch,
              onChanged: (value) {
                setState(() {
                  _showBySearch = value;
                });
              },
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              // Call the logout method from AuthController
              await authController.logout();
              // Navigate back to the login page
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginPage(title: "Login"),
                ),
              );
            },
            icon: Icon(Icons.logout),
            label: Text("Logout"),
          ),
        ],
      ),
    );
  }
}
