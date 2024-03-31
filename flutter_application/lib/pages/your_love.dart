import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/config.dart';
import 'package:flutter_application/controllers/love_alarm_controller.dart';
import 'package:flutter_application/pages/profile.dart';
import 'package:http/http.dart' as http;

class YourLove extends StatefulWidget {
  final String userStdCode;
  const YourLove({Key? key, required this.userStdCode}) : super(key: key);

  @override
  State<YourLove> createState() => _YourLoveState();
}

class _YourLoveState extends State<YourLove> {
  LoveAlarmController loveAlarmController = LoveAlarmController();
  List<dynamic> loverData = [];
  List<String> currentFollow = [];
  List<Map<String, dynamic>> userData = [];

  @override
  void initState() {
    super.initState();
    initLoverData();
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

  Future<void> initLoverData() async {
    loverData = await loveAlarmController.getAllBound(widget.userStdCode);

    setState(() {
      filterLoverData();
    });
    await loadUserData();
  }

  Future<void> loadUserData() async {
    for (String stdCode in currentFollow) {
      final userDataResponse = await FirebaseFirestore.instance
          .collection('user')
          .where('std_code', isEqualTo: stdCode)
          .get();
      if (userDataResponse.docs.isNotEmpty) {
        final userDataMap = userDataResponse.docs.first.data();
        userData.add(userDataMap);
      } else {
        print("No user data found for std_code: $stdCode");
      }
    }
    setState(() {});
  }

  void filterLoverData() {
    currentFollow = [];
    for (int i = 0; i < loverData.length; i++) {
      if (loverData[i]["user_std_code"] == widget.userStdCode) {
        currentFollow.add(loverData[i]["lover_user_std_code"].toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildFollowingText(),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: userData.length,
                itemBuilder: (context, index) {
                  final user = userData[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfilePage(
                            userIdCode: widget.userStdCode,
                            profileIdCode: user["std_code"],
                          ),
                        ),
                      );
                    },
                    child: ListTile(
                      leading: FutureBuilder<String>(
                        future: getImageUrl(user['std_code']),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            return CircleAvatar(
                              radius: 32,
                              backgroundImage: NetworkImage(
                                "https://firebasestorage.googleapis.com/v0/b/ku-cupid-storage.appspot.com/o/default_profile.png?alt=media&token=cbd16987-b824-4adb-b53a-cf7ee20a0b0b",
                              ),
                            );
                          } else {
                            return CircleAvatar(
                              radius: 32,
                              backgroundImage: NetworkImage(snapshot.data!),
                            );
                          }
                        },
                      ),
                      title: user['middle_name'] == ""
                          ? Text("${user["first_name"]} ${user["last_name"]}")
                          : Text(
                              "${user["first_name"]} ${user["middle_name"]} ${user["last_name"]}"),
                      subtitle: Text(user['std_code']),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowingText() {
    return Column(
      children: [
        Text(
          "Loving (${currentFollow.length})",
          style: TextStyle(
            fontSize: 20, // Adjust font size as needed
            fontWeight: FontWeight.bold, // Adjust font weight as needed
          ),
        ),
        Divider(
          // Add a separator
          color: Colors.black, // Customize separator color as needed
          thickness: 0.1, // Adjust thickness as needed
          height: 10, // Adjust height as needed
        ),
      ],
    );
  }
}
