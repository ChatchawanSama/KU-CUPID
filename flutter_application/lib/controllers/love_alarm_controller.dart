import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application/config.dart';

class LoveAlarmController {
  Future updateLocation(stdCode, latitude, longitude) async {
    final _url = hostName + "/api/location";
    latitude = latitude.toString(); // data[string]string
    longitude = longitude.toString();
    try {
      var response = await http.put(Uri.parse(_url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "std_code": stdCode,
            "latitude": latitude,
            "longitude": longitude
          }));
      if (response.statusCode == 200) {
        return true;
      } else {
        print("Error ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Exception: $e");
      return false;
    }
  }

  Future<List> getLoverStdCode(user_std_code) async {
    final _url = hostName + "/api/lover/location";
    try {
      var response = await http.post(Uri.parse(_url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({"user_std_code": user_std_code}));
      List<dynamic> jsonData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return jsonData;
      } else {
        print("Error ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Exception: $e");
      return [];
    }
  }

  Future getAllBound(user_std_code) async {
    final _url = hostName + "/api/lover";
    try {
      var response = await http.post(Uri.parse(_url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({"user_std_code": user_std_code}));
      List<dynamic> jsonData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return jsonData;
      } else {
        print("Error get all bond ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Exception: $e");
      return [];
    }
  }
}
