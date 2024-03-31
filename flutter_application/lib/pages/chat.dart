import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/config.dart';
import 'package:flutter_application/controllers/chat_controller.dart';
import 'package:flutter_application/controllers/item_controller.dart';
import 'package:flutter_application/pages/message.dart';
import 'package:flutter_application/pages/profile.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final String senderStdCode;
  final List<String> chatList;
  final String token;

  ChatPage({
    Key? key,
    required this.senderStdCode,
    required this.chatList,
    required this.token,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  ChatController chatController = ChatController();
  late Map<String, dynamic> userDetail;
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _chatUsers = [];
  List<Map<String, dynamic>> _chatList = [];
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;
  Map<String, dynamic> itemDetail = {};
  ItemController itemController = ItemController();
  int spearCount = 0;

  @override
  void initState() {
    super.initState();
    userDetail = JwtDecoder.decode(widget.token);
    getItems(JwtDecoder.decode(widget.token)["std_code"]);
    getAllUsers();
  }

  void getItems(String stdCode) async {
    itemDetail = await itemController.getItems(stdCode);
    setState(() {
      _cooldownSeconds =
          itemDetail["spear_cooldown"] - itemDetail["date_time_now"];
    });
    if (_cooldownSeconds > 0) {
      _startCooldown();
    } else {
      setState(() {
        spearCount = 1;
      });
    }
  }

  void _startCooldown() {
    _cooldownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_cooldownSeconds > 0) {
          _cooldownSeconds--;
        } else {
          _cooldownTimer?.cancel(); // Cancel the timer
        }
      });
    });
  }

  Future<void> createChat() async {
    _chatList = [];
    // ChatList example : -> รายชื่อแชท
    // print(_chatUsers);
    //[{std_code: 6310406272, id: 2, first_name: CHATCHAWAN, heart_id: 5368340392, exp: 1711020543, middle_name: , last_name: SAMA, iss: 2, is_active: true,

    for (var i = 0; i < _chatUsers.length; i++) {
      // Check if the chat already exists in Firestore
      bool chatExists = await checkIfUserExists(
          widget.senderStdCode, _chatUsers[i]["std_code"]);
      if (!chatExists) {
        try {
          await FirebaseFirestore.instance.collection('chats').add({
            'chatId': widget.senderStdCode + _chatUsers[i]["std_code"],
            'users': [userDetail["std_code"], _chatUsers[i]['std_code']],
            'reveal': false,
            'createdAt': FieldValue.serverTimestamp(),
          });

          // init chat from firebase
          QuerySnapshot chatData = await FirebaseFirestore.instance
              .collection('chats')
              .where('chatId',
                  isEqualTo: userDetail["std_code"] + _chatUsers[i]['std_code'])
              .get();

          if (chatData.docs.isEmpty) {
            chatData = await FirebaseFirestore.instance
                .collection('chats')
                .where('chatId',
                    isEqualTo:
                        _chatUsers[i]['std_code'] + userDetail["std_code"])
                .get();
          }

          _chatUsers[i]["reveal"] = chatData.docs[0]['reveal'];

          Map<String, dynamic> chatDataMap = {
            'id': chatData.docs[0]['chatId'],
            'reveal': chatData.docs[0]['reveal'],
            "unreadCount": "0"
          };
          setState(() {
            _chatList.add(chatDataMap);
          });
        } catch (e) {
          print("Error uploading chatDetail to Firestore: $e");
        }
      } else {
        // init chat from firebase
        QuerySnapshot chatData = await FirebaseFirestore.instance
            .collection('chats')
            .where('chatId',
                isEqualTo: userDetail["std_code"] + _chatUsers[i]['std_code'])
            .get();

        if (chatData.docs.isEmpty) {
          chatData = await FirebaseFirestore.instance
              .collection('chats')
              .where('chatId',
                  isEqualTo: _chatUsers[i]['std_code'] + userDetail["std_code"])
              .get();
        }

        _chatUsers[i]["reveal"] = chatData.docs[0]['reveal'];

        Map<String, dynamic> chatDataMap = {
          'id': chatData.docs[0]['chatId'],
          'reveal': chatData.docs[0]['reveal'],
          "unreadCount": "0"
        };
        setState(() {
          _chatList.add(chatDataMap);
        });
      }
    }
  }

  Future<bool> checkIfUserExists(String user1Id, String user2Id) async {
    QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore
        .instance
        .collection('chats')
        .where('chatId', isEqualTo: user1Id + user2Id)
        .get();
    if (querySnapshot.docs.isEmpty) {
      querySnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('chatId', isEqualTo: user2Id + user1Id)
          .get();
    }

    if (querySnapshot.docs.isNotEmpty) {
      return true;
    } else {
      return false;
    }
  }

  Future<void> getAllUsers() async {
    try {
      final QuerySnapshot userSnapshot =
          await FirebaseFirestore.instance.collection('user').get();

      if (userSnapshot.docs.isNotEmpty) {
        for (var doc in userSnapshot.docs) {
          Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
          _allUsers.add(userData);
        }

        for (var i in widget.chatList) {
          for (var j in _allUsers) {
            if (i == j["std_code"]) {
              _chatUsers.add(j);
            }
          }
        }

        await createChat();
        await updateUnreadCounts();
      } else {
        print("No users found in Firestore collection 'user'.");
      }
    } catch (e) {
      print("Error fetching users from Firestore: $e");
    }
  }

  Future<void> updateUnreadCounts() async {
    for (var chat in _chatList) {
      FirebaseFirestore.instance
          .collection('messages')
          .where('to', isEqualTo: widget.senderStdCode)
          .where('read', isEqualTo: false)
          .snapshots()
          .listen((snapshot) {
        setState(() {
          chat["unreadCount"] = snapshot.docs.length;
        });
      });
    }
  }

  String formatLastActive(int unixTimestamp) {
    final lastActive =
        DateTime.fromMillisecondsSinceEpoch(unixTimestamp * 1000);
    final now = DateTime.now();
    final difference = now.difference(lastActive);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays <= 3) {
      return '${difference.inDays} days ago';
    } else {
      return 'More than 3 days ago';
    }
  }

  String formatCooldown(int cooldownSeconds) {
    final hours = cooldownSeconds ~/ 3600;
    final minutes = (cooldownSeconds % 3600) ~/ 60;
    final seconds = cooldownSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ChatPage"),
        centerTitle: false,
        actions: <Widget>[
          Row(
            children: [
              SizedBox(width: 50),
              Icon(Icons.assignment_turned_in_outlined),
              _cooldownSeconds <= 0
                  ? SizedBox(
                      child: Text(" x ${spearCount}"),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(90.0),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          '${formatCooldown(_cooldownSeconds)}',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
              _cooldownSeconds <= 0
                  ? SizedBox(
                      width: 20,
                    )
                  : const SizedBox()
            ],
          )
        ],
      ),
      body: _chatList.isNotEmpty ? buildChatList() : buildEmptyChatList(),
    );
  }

  Widget buildChatList() {
    return ListView.builder(
      itemCount: _chatUsers.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MessagePage(
                  token: widget.token,
                  recipientUserDetail: _chatUsers[index],
                  chatDetail: _chatList[index],
                  spearCount: spearCount,
                ),
              ),
            );

            // Handle the result here
            getItems(JwtDecoder.decode(widget.token)["std_code"]);
            _startCooldown();
            await createChat();
          },
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  FutureBuilder<String>(
                    future: getImageUrl(_chatUsers[index]["std_code"]),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(
                            "https://firebasestorage.googleapis.com/v0/b/ku-cupid-storage.appspot.com/o/default_profile.png?alt=media&token=cbd16987-b824-4adb-b53a-cf7ee20a0b0b",
                          ),
                        );
                      } else {
                        return CircleAvatar(
                          radius: 24,
                          backgroundImage: _chatUsers[index]["reveal"] == false
                              ? NetworkImage(
                                  "https://firebasestorage.googleapis.com/v0/b/ku-cupid-storage.appspot.com/o/default_profile.png?alt=media&token=cbd16987-b824-4adb-b53a-cf7ee20a0b0b",
                                )
                              : NetworkImage(snapshot.data!),
                          child: Stack(
                            children: [
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 15,
                                  height: 15,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _chatUsers[index]["is_active"]
                                        ? Colors.green
                                        : const Color.fromARGB(
                                            255, 110, 109, 109),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (_chatUsers[index]["reveal"] ?? false)
                              ? "${_chatUsers[index]["first_name"]} ${_chatUsers[index]["last_name"]}"
                              : "Anonymous",
                          style: TextStyle(fontSize: 16),
                        ),
                        _chatUsers[index]["is_active"]
                            ? const Text("Active now")
                            : Text(
                                "last seen : ${formatLastActive(_chatUsers[index]["last_active"])}",
                                style: TextStyle(
                                    color: Colors.black, fontSize: 12),
                              ),
                      ],
                    ),
                  ),
                  (_chatList[index]["unreadCount"].toString() == "0" ||
                          _chatList[index]["unreadCount"].toString() == null)
                      ? Container()
                      : Container(
                          padding: EdgeInsets.all(2),
                          child: CircleAvatar(
                            backgroundColor: Colors.red,
                            radius: 12,
                            child: Text(
                              _chatList[index]["unreadCount"].toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildEmptyChatList() {
    return Center(
      child: Text("No chats available"),
    );
  }
}
