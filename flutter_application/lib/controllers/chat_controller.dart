import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application/config.dart';

class ChatController {
  String chatId = "";
  TextEditingController heartIdController = TextEditingController();
  bool reveal = false;

  Future<dynamic> createPrivateChat(stdCode, userTargetStdCode) async {
    final _url = hostName + "/api/chat";
    try {
      var response = await http.post(Uri.parse(_url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({"from": stdCode, "to": userTargetStdCode}));
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

  Future<dynamic> activeHeartId(chatId, userTargetStdCode) async {
    final _url = hostName + "/api/chat/reveal/heartId";
    try {
      var response = await http.post(Uri.parse(_url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "chat_id": chatId.toString(),
            "target_heart_id": heartIdController.text,
            "user_target_std_code": userTargetStdCode
          }));
      if (response.statusCode == 200) {
        await FirebaseFirestore.instance
            .collection('chats')
            .where('chatId', isEqualTo: chatId.toString())
            .get()
            .then((querySnapshot) {
          querySnapshot.docs.forEach((doc) {
            doc.reference.update({
              'reveal': true,
            });
          });
        });
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

  Future<dynamic> useSpear(chatId, stdCode) async {
    final _url = hostName + "/api/items/spear";
    try {
      var response = await http.put(Uri.parse(_url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "std_code": stdCode,
            "chat_id": chatId.toString(),
          }));
      if (response.statusCode == 200) {
        print(chatId.toString());
        await FirebaseFirestore.instance
            .collection('chats')
            .where('chatId', isEqualTo: chatId.toString())
            .get()
            .then((querySnapshot) {
          querySnapshot.docs.forEach((doc) {
            doc.reference.update({
              'reveal': true,
            });
          });
        });
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
