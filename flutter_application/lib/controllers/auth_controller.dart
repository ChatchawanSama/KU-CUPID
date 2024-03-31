import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application/config.dart';

class AuthController {
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  String token = "";

  late SharedPreferences prefs;

  Future login() async {
    final _url = hostName + "/api/login";
    var response = await http.post(Uri.parse(_url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "username": usernameController.text,
          "password": passwordController.text,
        }));

    if ((response.statusCode == 200) &&
        (jsonDecode(response.body)["code"] == "success")) {
      token = jsonDecode(response.body)["accesstoken"] ?? "";
      return true;
    } else {
      print(response.statusCode);
      return false;
    }
  }


  String getToken() {
    return token;
  }

  Future<bool> logout() async {
    final _logoutUrl = hostName + "/api/logout";

    prefs = await SharedPreferences.getInstance();
    try {
      var response = await http.post(Uri.parse(_logoutUrl));

      if (response.statusCode == 200) {
        // Clear the token
        token = "";

        // Clear the token from SharedPreferences
        await prefs.remove("token");

        return true; // Indicate successful logout
      } else {
        // Handle logout failure, you may want to log the error or show a message
        return false;
      }
    } catch (error) {
      print("Logout error: $error");
      return false;
    }
  }

  Future updateBIO(String userId, String bio) async {
    final _updateBioURL = hostName + "/api/user/" + userId;

    try {
      final response = await http.put(
        Uri.parse(_updateBioURL),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'bio': bio,
        }),
      );

      if (response.statusCode == 200) {
        return "Bio updated successfully!";
      } else {
        return "Failed to update bio: ${response.statusCode}";
      }
    } catch (e) {
      return "Error: $e";
    }
  }

  Future updateImageProfile(String userId, String imagePath) async {
    final _updateBioURL = hostName + "/api/user/" + userId;

    try {
      final response = await http.put(
        Uri.parse(_updateBioURL),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'image_path': imagePath,
        }),
      );

      if (response.statusCode == 200) {
        return "Image Profile updated successfully!";
      } else {
        return "Failed to update bio: ${response.statusCode}";
      }
    } catch (e) {
      return "Error: $e";
    }
  }
}
