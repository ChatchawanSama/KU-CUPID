import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/config.dart';
import 'package:flutter_application/controllers/auth_controller.dart';
import 'package:flutter_application/pages/utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

final FirebaseStorage _storage = FirebaseStorage.instance;
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class EditProfilePage extends StatefulWidget {
  final String userIdCode;
  final String profileIdCode;

  EditProfilePage(
      {Key? key, required this.userIdCode, required this.profileIdCode})
      : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  bool showPassword = false;
  String profilePath = "";
  Uint8List? _imageProfile;
  List<Map<String, dynamic>> profileDetail = [];
  String profileFullName = "", heartId = "", bio = "";
  int userId = 0;
  final AuthController authController = AuthController();

  @override
  void initState() {
    super.initState();
    getUserProfile();
    getImageUrl();
  }

  Future<void> getUserProfile() async {
    final String url = hostName + "/api/user";
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        var profile = jsonData
            .where((entry) => entry["std_code"] == widget.profileIdCode);
        profileDetail = List.from(profile.cast<Map<String, dynamic>>());
        bio = profileDetail[0]["bio"];
        if (profileDetail[0]["middle_name"] == "") {
          setState(() {
            profileFullName =
                "${profileDetail[0]["first_name"]} ${profileDetail[0]["last_name"]} ";
            heartId = profileDetail[0]["heart_id"];
            userId = profileDetail[0]["id"];
          });
        } else {
          setState(() {
            profileFullName =
                "${profileDetail[0]["first_name"]} ${profileDetail[0]["middle_name"] == ""} ${profileDetail[0]["last_name"]} ";
            heartId = profileDetail[0]["heart_id"];
            userId = profileDetail[0]["id"];
          });
        }
      } else {
        print("Error fetching users: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> getImageUrl() async {
    final ref = _storage.ref().child(widget.profileIdCode + "profile.png");
    final url = await ref.getDownloadURL();
    setState(() {
      profilePath = url;
    });
  }

  void selectImage() async {
    Uint8List img = await pickImage(ImageSource.gallery);
    setState(() {
      _imageProfile = img;
    });
    String resp = await saveData(file: _imageProfile!);
  }

  Future<String> uploadImageToStorage(String childName, Uint8List file) async {
    Reference ref = _storage.ref().child(childName);
    UploadTask uploadTask = ref.putData(file);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    authController.updateImageProfile(userId.toString(), downloadUrl);
    return downloadUrl;
  }

  Future<String> saveData({required Uint8List file}) async {
    String resp = "Some Error Occured";
    try {
      if (widget.profileIdCode.isNotEmpty) {
        String imageUrl = await uploadImageToStorage(
            widget.profileIdCode + 'profile.png', file);
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
            title: Text(
              "Edit Profile",
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
            ),
            centerTitle: false,
            elevation: 0,
          ),
        ),
      ),
      body: Container(
        padding: EdgeInsets.only(left: 16, top: 25, right: 16),
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: ListView(
            children: [
              Center(
                child: Stack(
                  children: [
                    _imageProfile != null
                        ? Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              border: Border.all(
                                  width: 4,
                                  color: Theme.of(context)
                                      .scaffoldBackgroundColor),
                              boxShadow: [
                                BoxShadow(
                                    spreadRadius: 2,
                                    blurRadius: 10,
                                    color: Colors.black.withOpacity(0.1),
                                    offset: Offset(0, 10))
                              ],
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                fit: BoxFit.cover,
                                image: MemoryImage(_imageProfile!),
                              ),
                            ),
                          )
                        : Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              border: Border.all(
                                  width: 4,
                                  color: Theme.of(context)
                                      .scaffoldBackgroundColor),
                              boxShadow: [
                                BoxShadow(
                                    spreadRadius: 2,
                                    blurRadius: 10,
                                    color: Colors.black.withOpacity(0.1),
                                    offset: Offset(0, 10))
                              ],
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                fit: BoxFit.cover,
                                image: profilePath != ""
                                    ? NetworkImage(profilePath) as ImageProvider
                                    : AssetImage("images/default_profile.png"),
                              ),
                            ),
                          ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          // print("Test Green");
                          selectImage();
                        },
                        child: Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              width: 4,
                              color: Theme.of(context).scaffoldBackgroundColor,
                            ),
                            color: Color.fromRGBO(237, 41, 106, 1),
                          ),
                          child: Icon(
                            Icons.edit,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 35,
              ),
              buildText("Full Name", profileFullName),
              buildText("Student ID", widget.profileIdCode),
              buildText("Heart ID", heartId),
              Container(
                // child: bio == ""
                //     ? const TextField(
                //         decoration: InputDecoration(
                //             contentPadding: EdgeInsets.only(bottom: 3),
                //             labelText: "BIO",
                //             floatingLabelBehavior: FloatingLabelBehavior.always,
                //             hintText: "No Bio Yet, Describe yourself now :)",
                //             hintStyle: TextStyle(
                //               fontSize: 16,
                //               fontWeight: FontWeight.normal,
                //               color: Colors.black,
                //             )),
                //       )
                //     : EditableTextField(bio: bio, userId: userId),
                child: EditableTextField(bio: bio, userId: userId),
              ),
              SizedBox(
                height: 35,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildText(String labelText, String placeholder) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 35.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            labelText,
            style: TextStyle(
              fontSize: 14, // Adjust the font size as needed
              fontWeight: FontWeight.normal, // Use a normal font weight
              color: Colors.black,
            ),
          ),
          SizedBox(
            width: double
                .infinity, // Set the width of the SizedBox to match the parent width
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                      color: Colors.black,
                      width:
                          1.0), // Adjust the color and width of the underline
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                    bottom:
                        5.0), // Add some padding to separate the text from the underline
                child: Text(
                  placeholder,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EditableTextField extends StatefulWidget {
  String bio;
  int userId;

  EditableTextField({Key? key, required this.bio, required this.userId})
      : super(key: key);
  @override
  _EditableTextFieldState createState() => _EditableTextFieldState();
}

class _EditableTextFieldState extends State<EditableTextField> {
  bool _isEditing = false;
  TextEditingController _textEditingController = TextEditingController();
  String inputBio = '';
  AuthController authController = AuthController();

  @override
  void initState() {
    super.initState();
    _textEditingController.text = widget.bio; // Set initial text
    inputBio = widget.bio; // Initialize inputBio with the initial bio value
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "BIO",
          style: TextStyle(
            fontSize: 14, // Adjust the font size as needed
            fontWeight: FontWeight.normal, // Use a normal font weight
            color: Colors.black,
          ),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                enabled: _isEditing,
                controller: _textEditingController,
                decoration: InputDecoration(
                  hintText: widget.bio,
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.edit,
                color:
                    _isEditing ? Color.fromRGBO(237, 41, 106, 1) : Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  if (_isEditing) {
                    inputBio = _textEditingController.text;
                    authController
                        .updateBIO(widget.userId.toString(), inputBio)
                        .then((result) {
                      print(result); // Handle result as needed
                    });
                  }
                  _isEditing = !_isEditing;
                });
              },
            ),
            // Text(inputBio)
          ],
        )
      ],
    );
  }
}
