import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application/config.dart';

class LoverController {
  Future Love(user_std_code, lover_std_code) async {
    final _url = hostName + "/api/love";

    var response = await http.post(Uri.parse(_url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "user_std_code": user_std_code,
          "lover_user_std_code": lover_std_code
        }));
    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  Future unLove(user_std_code, lover_std_code) async {
    final _url = hostName + "/api/love";

    var response = await http.delete(Uri.parse(_url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "user_std_code": user_std_code,
          "lover_user_std_code": lover_std_code
        }));
    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> isLoved(String user_std_code, String lover_std_code) async {
    final _url = hostName + "/api/lover";
    bool cond1 = false;
    bool cond2 = false;

    var response = await http.post(Uri.parse(_url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "user_std_code": user_std_code,
        }));

    if (response.statusCode == 200) {
      List<dynamic> jsonData = jsonDecode(response.body);

      // Filter data based on user_std_code
      var userEntries =
          jsonData.where((entry) => entry["user_std_code"] == user_std_code);

      bool isLoved = userEntries
          .any((entry) => entry["lover_user_std_code"] == lover_std_code);

      cond1 = isLoved;

      // var userEntries2 =
      //     jsonData.where((entry) => entry["user_std_code"] == lover_std_code);
      // bool isLoved2 = userEntries2
      //     .any((entry) => entry["lover_user_std_code"] == user_std_code);

      // cond2 = isLoved2;

      // return cond1 & cond2;
      return cond1;
    } else {
      print("Error: ${response.statusCode}");
      return false; // or throw an exception based on your error handling strategy
    }
  }
}
