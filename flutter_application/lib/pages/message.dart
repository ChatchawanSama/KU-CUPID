import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application/controllers/chat_controller.dart';
import 'package:flutter_application/controllers/item_controller.dart';
import 'package:flutter_application/pages/utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class MessagePage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> recipientUserDetail;
  final Map<String, dynamic> chatDetail;
  final int spearCount;

  const MessagePage({
    Key? key,
    required this.token,
    required this.recipientUserDetail,
    required this.chatDetail,
    required this.spearCount,
  }) : super(key: key);

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  late CollectionReference _messagesCollection;
  late Map<String, dynamic> userDetail;
  late TextEditingController _messageController;
  String heartId = "";
  ChatController chatController = ChatController();
  bool reveal = false;
  Uint8List? _imageMessage;
  late int spear;

  @override
  void initState() {
    super.initState();
    _messagesCollection = _firestore.collection('messages');
    _messageController = TextEditingController();
    userDetail = JwtDecoder.decode(widget.token);
    updateReadStatus();
    print(widget.chatDetail);

    setState(() {
      spear = widget.spearCount;
      reveal = widget.chatDetail["reveal"];
    });
  }

  Future<String?> openHeartIdDialog() => showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Heart ID"),
          content: TextField(
            decoration: const InputDecoration(hintText: "Enter Heart ID"),
            controller: chatController.heartIdController,
          ),
          actions: [
            TextButton(
              onPressed: () => submit(
                widget.chatDetail["id"].toString(),
                widget.recipientUserDetail["std_code"],
              ),
              child: Text("Submit"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
          ],
        ),
      );

  Future<void> openSpearDialog() => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Use spear ? "),
          content: spear == 0
              ? Text("You don't have spear.")
              : Text(" You have ${spear} spear."),
          actions: [
            spear == 0
                ? SizedBox()
                : TextButton(
                    onPressed: () => userSpear(
                        widget.chatDetail["id"].toString(),
                        userDetail["std_code"]),
                    child: Text("Yes"),
                  ),
            spear == 0
                ? TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text("OK"),
                  )
                : TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text("No"),
                  ),
          ],
        ),
      );

  void userSpear(String chatId, String stdCode) async {
    Map<String, dynamic> result =
        await chatController.useSpear(chatId, stdCode);
    if (result != null) {
      setState(() {
        reveal = true;
      });
    } else {
      print("Result is null");
    }
    Navigator.of(context).pop("user spear");
  }


  void submit(String chatId, String userTargetStdCode) async {
    if (chatController.heartIdController.text !=
        widget.recipientUserDetail["heart_id"]) {
      // print(chatController.heartIdController.text);
      // print( widget.recipientUserDetail["std_code"]);
      // Show dialog indicating incorrect Heart ID
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Incorrect Heart ID"),
          content: Text("The Heart ID you entered is incorrect."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK"),
            ),
          ],
        ),
      );
    } else {
      // Heart ID matches, proceed with submission
      Map<String, dynamic> result =
          await chatController.activeHeartId(chatId, userTargetStdCode);
      print(result);
      setState(() {
        reveal = result["reveal"];
      });
      Navigator.of(context).pop(chatController.heartIdController.text);
    }
  }

  Future<void> revealPrivateWithChatHeartId(
      String chatId, String userTargetHeartId, String userTargetStdCode) async {
    try {
      final chatDoc =
          FirebaseFirestore.instance.collection('chats').doc(chatId);
      final userTargetDoc = FirebaseFirestore.instance
          .collection('user')
          .where('std_code', isEqualTo: userTargetStdCode);

      final chatSnapshot = await chatDoc.get();
      final userTargetSnapshot = await userTargetDoc.get();

      if (!chatSnapshot.exists || userTargetSnapshot.docs.isEmpty) {
        return;
      }

      final chatData = chatSnapshot.data() as Map<String, dynamic>;
      final userTargetData =
          userTargetSnapshot.docs.first.data() as Map<String, dynamic>;

      if (userTargetData['heartId'] == userTargetHeartId) {
        await chatDoc.update({'reveal': true});
      }
    } catch (e) {
      print("Exception: $e");
      // Handle error
    }
  }

  void selectImage() async {
    Uint8List img = await pickImage(ImageSource.gallery);
    setState(() {
      _imageMessage = img;
    });

    String resp =
        await saveData(stdIdCode: userDetail["std_code"], file: _imageMessage!);
  }

  Future<String> uploadImageToStorage(String childName, Uint8List file) async {
    Reference ref = _storage.ref().child(childName);
    UploadTask uploadTask = ref.putData(file);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<String> saveData(
      {required String stdIdCode, required Uint8List file}) async {
    String resp = "Some Error Occured";
    var timestamp = DateTime.now().millisecondsSinceEpoch;
    String fileName = "$timestamp-${userDetail["std_code"]}.png";
    try {
      if (stdIdCode.isNotEmpty) {
        String imageUrl = await uploadImageToStorage(fileName, file);
        await _firestore.collection('messages').add({
          'chatId': widget.chatDetail["id"].toString(),
          'from': userDetail["std_code"],
          'to': widget.recipientUserDetail["std_code"],
          'type': "Image",
          'read': false,
          'contents': _messageController.text,
          'timestamp': DateTime.now(),
          'ImagePath': imageUrl
        });
        resp = "Success";
      }
    } catch (err) {
      resp = err.toString();
      print(" Save image error : ${resp}");
    }
    return resp;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: reveal
            ? Text(
                "${widget.recipientUserDetail["first_name"]} ${widget.recipientUserDetail["last_name"]}")
            : Text("Anonymous"),
        actions: <Widget>[
          reveal
              ? SizedBox()
              : IconButton(
                  icon: Icon(Icons.assignment_turned_in_outlined),
                  onPressed: () async {
                    openSpearDialog();
                    // heartId = (await openHeartIdDialog())!;
                    // if (heartId == null || heartId.isEmpty) return;

                    // setState(() {
                    //   heartId = heartId;
                    // });
                  },
                ),
          reveal
              ? SizedBox()
              : IconButton(
                  icon: Icon(Icons.favorite),
                  onPressed: () async {
                    heartId = (await openHeartIdDialog())!;
                    if (heartId == null || heartId.isEmpty) return;

                    setState(() {
                      heartId = heartId;
                    });
                  },
                )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _messagesCollection
                  .where('chatId',
                      isEqualTo: widget.chatDetail["id"].toString())
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                List<DocumentSnapshot> documents = snapshot.data!.docs;
                // Sort documents by timestamp
                documents.sort((a, b) {
                  Timestamp timestampA = a['timestamp'];
                  Timestamp timestampB = b['timestamp'];
                  return timestampB.compareTo(timestampA); // Descending order
                });
                return ListView(
                  reverse: true,
                  children: documents.map((DocumentSnapshot document) {
                    Map<String, dynamic> data =
                        document.data() as Map<String, dynamic>;
                    return buildMessageBubble(data);
                  }).toList(),
                );
              },
            ),
          ),
          Divider(height: 1),
          buildMessageInputField(),
          SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> updateReadStatus() async {
    await _messagesCollection
        .where('chatId', isEqualTo: widget.chatDetail["id"].toString())
        .where('to', isEqualTo: userDetail["std_code"])
        .where('read', isEqualTo: false)
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        doc.reference.update({'read': true});
      });
    });
  }

  Widget buildMessageBubble(Map<String, dynamic> message) {
    bool isSentByUser = message["from"] == userDetail["std_code"];
    bool isImageMessage = message["type"] == "Image";

    return Align(
      alignment: isSentByUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSentByUser ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: isImageMessage
            ? Image.network(
                message["ImagePath"],
                width: 200, // Adjust the width as needed
                height: 200, // Adjust the height as needed
                fit: BoxFit.cover,
              )
            : GestureDetector(
                onLongPressStart: (details) {
                  if (message["type"] == "Text") {
                    _showCopyMenu(message["contents"], details.globalPosition);
                  }
                },
                child: Text(
                  message["contents"],
                  style: TextStyle(
                    color: isSentByUser ? Colors.white : Colors.black,
                  ),
                ),
              ),
      ),
    );
  }

  void _showCopyMenu(String text, Offset tapPosition) async {
    await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        tapPosition.dx,
        tapPosition.dy,
        tapPosition.dx + 50,
        tapPosition.dy + 20,
      ),
      items: [
        PopupMenuItem(
          value: 'copy',
          child: Row(
            children: [
              Icon(Icons.copy),
              SizedBox(width: 8),
              Text('Copy'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'copy') {
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Text copied to clipboard'),
        ));
      }
    });
  }

  Widget buildMessageInputField() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.attach_file),
            onPressed: () {
              selectImage();
              print('Upload image button pressed');
            },
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () async {
              if (_messageController.text.isNotEmpty) {
                await _messagesCollection.add({
                  'chatId': widget.chatDetail["id"].toString(),
                  'from': userDetail["std_code"],
                  'to': widget.recipientUserDetail["std_code"],
                  'type': "Text",
                  'read': false,
                  'contents': _messageController.text,
                  'timestamp': DateTime.now(),
                });
                _messageController.clear(); // Clear the text field
              }
            },
          ),
        ],
      ),
    );
  }
}
