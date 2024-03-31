import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/config.dart';
import 'package:flutter_application/controllers/auth_controller.dart';
import 'package:flutter_application/controllers/love_alarm_controller.dart';
import 'package:flutter_application/pages/profile.dart';
import 'package:http/http.dart' as http;

class BadgeClub extends StatefulWidget {
  final String userIdCode;
  const BadgeClub({Key? key, required this.userIdCode}) : super(key: key);

  @override
  State<BadgeClub> createState() => _BadgeClubState();
}

class _BadgeClubState extends State<BadgeClub> {
  final AuthController authController = AuthController();
  late List<Map<String, dynamic>> _allUser = [];
  List<dynamic> users = [];

  @override
  void initState() {
    super.initState();
    getUsers();
  }

  Future<void> getUsers() async {
    final String _getUsers = hostName + "/api/user";

    try {
      final response = await http.get(Uri.parse(_getUsers));
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        _allUser = jsonData.cast<Map<String, dynamic>>();
        _allUser.sort((a, b) => b['lover_count'].compareTo(a['lover_count']));
        print(_allUser);

        final topUsers = _allUser.take(10).toList();

        setState(() {
          users = topUsers;
        });
        print("--------------------------------------->");
        print(users);
      } else {
        print("Error fetching users: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(40),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Color.fromARGB(62, 248, 28, 131),
              ),
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.white,
            centerTitle: false,
            elevation: 0,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            // Align children to the center horizontally
            children: [
              SizedBox(height: 20),
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                backgroundImage: AssetImage("images/badgeclub_icon.png"),
              ),
              Text("Badge Club",
                  style: TextStyle(
                      color: Color.fromRGBO(234, 40, 102, 1),
                      fontWeight: FontWeight.w900,
                      fontSize: 20)),
              SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];

                    return ListTile(
                      leading: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            // Assuming 'image_path' contains the URL to the user's profile image
                            backgroundImage: user['image_path'] != ""
                                ? NetworkImage(user['image_path'])
                                    as ImageProvider
                                : AssetImage("images/default_profile.png"),
                          ),
                        ],
                      ),
                      title: Text(
                        user['first_name'] + " " + user['last_name'] ?? '',
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            letterSpacing: 0.4),
                      ),
                      subtitle: Text(user['std_code'] ?? ''),
                      trailing: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Color.fromRGBO(234, 40, 102, 1),
                          fontWeight: FontWeight.w600,
                          fontSize: (index + 1 == 1)
                              ? 30
                              : (index + 1 == 2)
                                  ? 25
                                  : (index + 1 == 3)
                                      ? 20
                                      : 16,
                        ),
                      ),
                      onTap: () {
                        // Navigate to the user's profile page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfilePage(
                              userIdCode: widget.userIdCode,
                              profileIdCode: user['std_code'],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
