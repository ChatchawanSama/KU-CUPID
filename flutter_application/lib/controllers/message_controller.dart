import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application/config.dart';

class MessageController {

  Future<Map<String,dynamic>> sendMessage(
      chatId, stdCode, userTargetStdCode, contents) async {
    print(" haha ${chatId}, ${stdCode}, ${userTargetStdCode}, ${contents}");
    final url = hostName + "/api/messages";
    try {
      var response = await http.post(Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "chat_id": chatId.toString(),
            "from": stdCode,
            "to": userTargetStdCode,
            "contents": contents
          }));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Error ${response.statusCode}");
        return {};
      }
    } catch (e) {
      print("Exception: $e");
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getMessage(chatId) async {
    final url = hostName + "/api/messages" + "/" + chatId;
    try {
      var response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.cast<Map<String, dynamic>>();
      } else {
        print("Error ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Exception: $e");
      return [];
    }
  }
}
