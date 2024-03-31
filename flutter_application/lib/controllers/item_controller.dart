import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application/config.dart';

class ItemController {
  Future<dynamic> getItems(stdCode) async {
    final _url = hostName + "/api/items";
    try {
      var response = await http.post(Uri.parse(_url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({"std_code": stdCode}));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Error ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Exception: $e");
      return false;
    }
  }

  Future<dynamic> userSpear(chatId, userTargetStdCode) async {
    final _url = hostName + "/api/chat/reveal/heartId";
    try {
      var response = await http.post(Uri.parse(_url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "chat_id": chatId.toString(),
            "user_target_std_code": userTargetStdCode
          }));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Error ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Exception: $e");
      return false;
    }
  }
}
