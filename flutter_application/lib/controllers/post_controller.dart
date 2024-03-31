import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application/config.dart';

class PostController {
  Future uploadPost(user_id, caption, image_path) async {
    final _uploadPosturl = hostName + "/api/posts";

    var response = await http.post(Uri.parse(_uploadPosturl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "user_id": user_id,
          "caption": caption,
          "image_path": image_path
        }));
    if (response.statusCode == 200) {
      print("Fusic No.1 Success");
      return true;
    } else {
      print("Fusic No.1 Fail");
      return false;
    }
  }

    Future<List<Map<String, dynamic>>> getUserPost(userid) async {
      final _getUserPost = hostName + "/api/posts/" + userid;

      try {
        var response = await http.get(
          Uri.parse(_getUserPost),
          headers: {'Content-Type': 'application/json'},
        );
        if (response.statusCode == 200) {
          List<dynamic> jsonData = jsonDecode(response.body);
          print("Flow 1");
          return jsonData.cast<Map<String, dynamic>>();
        } else {
          print("Error ${response.statusCode}");
          print("Flow 2");
          return [];
        }
      } catch (e) {
        print("Exception: $e");
        print("Flow 3");
        return [];
      }
    }
}
