import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/pages/badge_club.dart';
import 'package:flutter_application/pages/profile.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_application/config.dart';

final FirebaseStorage _storage = FirebaseStorage.instance;

class SearchPage extends StatefulWidget {
  final String userIdCode;

  const SearchPage({Key? key, required this.userIdCode}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _foundUsers = [];
  String profilePath = "";
  Map<int, bool> _isPressedMap = {};
  List<Map<String, String>> profileImageMap = [];

  @override
  void initState() {
    super.initState();
    getAllUsers();
  }

  Future<void> getAllUsers() async {
    final String url = hostName + "/api/user";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        _allUsers = jsonData.cast<Map<String, dynamic>>();
        _foundUsers = List.from(_allUsers);
      } else {
        print("Error fetching users: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    }
    setState(() {});
  }

  void _runFilter(String enteredKeyword) {
    setState(() {
      if (enteredKeyword.isEmpty) {
        _foundUsers = List.from(_allUsers);
      } else {
        _foundUsers = _allUsers.where((user) {
          final String firstName = (user["middle_name"] == ""
                  ? "${user["first_name"]} ${user["last_name"]}"
                  : "${user["first_name"]} ${user["middle_name"]} ${user["last_name"]}")
              .toLowerCase();
          return firstName.contains(enteredKeyword.toLowerCase());
        }).toList();
      }
    });
  }

  Future<String> getImageUrl(stdCode) async {
    final ref = FirebaseStorage.instance.ref().child(stdCode + "profile.png");

    try {
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      print("File does not exist: $e");
      return "https://firebasestorage.googleapis.com/v0/b/ku-cupid-storage.appspot.com/o/default_profile.png?alt=media&token=cbd16987-b824-4adb-b53a-cf7ee20a0b0b";
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Badge",
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                        fontSize: 10,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      "Club",
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                        fontSize: 10,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BadgeClub(
                          userIdCode: widget.userIdCode,
                        ),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    // radius: 45,
                    backgroundColor: Colors.white,
                    backgroundImage: AssetImage("images/badgeclub_icon.png"),
                  ),
                ),
                SizedBox(width: 20),
              ],
            ),
            TextField(
              onChanged: _runFilter,
              decoration: InputDecoration(
                labelText: "Search",
                suffixIcon: Icon(Icons.search),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: _foundUsers.isNotEmpty
                  ? ListView.builder(
                      itemCount: _foundUsers.length,
                      itemBuilder: (context, index) {
                        final user = _foundUsers[index];
                        final int userId = user["id"];
                        final bool isPressed = _isPressedMap[userId] ?? false;
                        final id = user["std_code"];
                        return user["std_code"] != widget.userIdCode
                            ? Card(
                                key: ValueKey(userId),
                                color: isPressed
                                    ? Colors.deepPurple
                                    : Colors.white,
                                elevation: isPressed ? 8 : 4,
                                margin: EdgeInsets.symmetric(vertical: 10),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isPressedMap[userId] = !isPressed;
                                    });
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProfilePage(
                                          userIdCode: widget.userIdCode,
                                          profileIdCode: user["std_code"],
                                        ),
                                      ),
                                    );
                                  },
                                  child: ListTile(
                                    leading: FutureBuilder<String>(
                                      future: getImageUrl(user["std_code"]),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                                ConnectionState.waiting ||
                                            snapshot.hasError) {
                                          return CircleAvatar(
                                            radius: 32,
                                            backgroundImage: NetworkImage(
                                              "https://firebasestorage.googleapis.com/v0/b/ku-cupid-storage.appspot.com/o/default_profile.png?alt=media&token=cbd16987-b824-4adb-b53a-cf7ee20a0b0b",
                                            ),
                                          );
                                        } else {
                                          return CircleAvatar(
                                            radius: 32,
                                            backgroundImage:
                                                NetworkImage(snapshot.data!),
                                          );
                                        }
                                      },
                                    ),
                                    title: Text(
                                      user["middle_name"] == ""
                                          ? "${user["first_name"]} ${user["last_name"]}"
                                          : "${user["first_name"]} ${user["middle_name"]} ${user["last_name"]}",
                                      style: TextStyle(
                                        color: isPressed
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      user["std_code"],
                                      style: TextStyle(
                                        color: isPressed
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : SizedBox();
                      },
                    )
                  : Container(),
            ),
          ],
        ),
      ),
    );
  }
}
