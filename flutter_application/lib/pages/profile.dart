import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/config.dart';
import 'package:flutter_application/controllers/auth_controller.dart';
import 'package:flutter_application/controllers/lover_controller.dart';
import 'package:flutter_application/controllers/post_controller.dart';
import 'package:flutter_application/pages/add_post.dart';
import 'package:flutter_application/pages/edit_profile.dart';
import 'package:flutter_application/pages/gallery.dart';
import 'package:flutter_application/pages/setting.dart';
import 'package:flutter_application/pages/utils.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

FirebaseAuth auth = FirebaseAuth.instance;
User? user = auth.currentUser;

final FirebaseStorage _storage = FirebaseStorage.instance;
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class ProfilePage extends StatefulWidget {
  final String userIdCode;
  final String profileIdCode;

  ProfilePage({Key? key, required this.userIdCode, required this.profileIdCode})
      : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final picker = ImagePicker();
  late File? _image;
  String profileFullName = "";
  String profilePath = "";
  bool samePerson = false;
  List<Map<String, dynamic>> profileDetail = [];
  LoverController loverController = LoverController();
  late Future<bool> isLoved;
  final AuthController authController = AuthController();
  Uint8List? _imageProfile;
  int userId = 0;
  List<dynamic> posts = [];
  late List<Map<String, dynamic>> _allPost = [];
  int postLength = 0;
  int lover_count = 0;
  String bio = "";

  @override
  void initState() {
    super.initState();
    isLoved = loverController.isLoved(widget.userIdCode, widget.profileIdCode);
    // getUserProfile();
    getUserProfile().then((_) {
      getImageUrl();
      getPosts();
      setState(() {}); // Trigger rebuild after fetching userId
    });
    if (widget.userIdCode == widget.profileIdCode) {
      setState(() {
        samePerson = true;
      });
    }
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
        if (profileDetail[0]["middle_name"] == "") {
          setState(() {
            profileFullName =
                "${profileDetail[0]["first_name"]} ${profileDetail[0]["last_name"]} ";
            userId = profileDetail[0]["id"];
            lover_count = profileDetail[0]["lover_count"];
            bio = profileDetail[0]["bio"];
          });
        } else {
          setState(() {
            profileFullName =
                "${profileDetail[0]["first_name"]} ${profileDetail[0]["middle_name"]} ${profileDetail[0]["last_name"]} ";
            userId = profileDetail[0]["id"];
            lover_count = profileDetail[0]["lover_count"];
            bio = profileDetail[0]["bio"];
          });
        }
      } else {
        print("Error fetching users: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> getPosts() async {
    final String url = hostName + "/api/posts/" + userId.toString();
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        _allPost = jsonData.cast<Map<String, dynamic>>();
        setState(() {
          posts = _allPost;
        });
        postLength = posts.length;
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

    String resp = await saveData(
        name: profileFullName,
        stdIdCode: widget.profileIdCode,
        file: _imageProfile!);
  }

  Future<String> uploadImageToStorage(String childName, Uint8List file) async {
    Reference ref = _storage.ref().child(childName);
    UploadTask uploadTask = ref.putData(file);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    authController.updateImageProfile(userId.toString(), downloadUrl);
    return downloadUrl;
  }

  Future<String> saveData(
      {required String name,
      required String stdIdCode,
      required Uint8List file}) async {
    String resp = "Some Error Occured";
    try {
      if (name.isNotEmpty || stdIdCode.isNotEmpty) {
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
              widget.profileIdCode,
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
            ),
            centerTitle: false,
            elevation: 0,
            actions: [
              samePerson
                  ? IconButton(
                      icon: Icon(
                        Icons.add_box_outlined,
                        color: Colors.black,
                      ),
                      // onPressed: _selectImage,
                      onPressed: () => {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddPost(
                                userIdCode: widget.userIdCode,
                                profileIdCode: widget.profileIdCode,
                                userId: userId),
                          ),
                        )
                      },
                    )
                  : Container(),
              samePerson
                  ? IconButton(
                      icon: Icon(
                        Icons.settings,
                        color: Colors.black,
                      ),
                      onPressed: () => {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SettingPage(),
                          ),
                        )
                      },
                    )
                  : Container()
            ],
          ),
        ),
      ),
      body: DefaultTabController(
        length: 3,
        child: NestedScrollView(
          headerSliverBuilder: (context, _) {
            return [
              SliverList(
                delegate: SliverChildListDelegate(
                  [profileHeader(context)],
                ),
              ),
            ];
          },
          body: Column(
            children: <Widget>[
              Expanded(
                  child: TabBarView(
                children: [
                  userId != 0
                      ? postLength > 0
                          ? Gallery(
                              userId: userId,
                              fullname: profileFullName,
                              profilePath: profilePath,
                            )
                          // : Text("Nn Posts Yet")
                          : Center(
                              child: Text("No Post Yet :(",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                  )),
                            )
                      : Center(
                          child: CircularProgressIndicator(
                            color: Color.fromRGBO(237, 41, 106, 1),
                            backgroundColor: Colors.grey[400],
                          ),
                        ),
                ],
              ))
            ],
          ),
        ),
      ),
    );
  }

  Widget profileHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white),
      child: Padding(
        padding: const EdgeInsets.only(left: 18.0, right: 18.0, bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 20,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment
                  .start, // Ensure content starts from the top
              children: [
                widget.userIdCode == widget.profileIdCode
                    ? Expanded(
                        flex: 2, // Adjust flex values as needed
                        child: _imageProfile != null
                            ? GestureDetector(
                                onLongPress: selectImage,
                                child: CircleAvatar(
                                  radius: 45,
                                  backgroundColor: Color(0xff74EDED),
                                  backgroundImage: MemoryImage(_imageProfile!),
                                ),
                              )
                            : GestureDetector(
                                onLongPress: selectImage,
                                child: CircleAvatar(
                                  radius: 45,
                                  backgroundImage: profilePath != ""
                                      ? NetworkImage(profilePath)
                                          as ImageProvider
                                      : AssetImage(
                                          "images/default_profile.png"),
                                ),
                              ),
                      )
                    : Expanded(
                        flex: 2, // Adjust flex values as needed
                        child: _imageProfile != null
                            ? GestureDetector(
                                child: CircleAvatar(
                                  radius: 45,
                                  backgroundColor: Color(0xff74EDED),
                                  backgroundImage: MemoryImage(_imageProfile!),
                                ),
                              )
                            : GestureDetector(
                                child: CircleAvatar(
                                  radius: 45,
                                  backgroundImage: profilePath != ""
                                      ? NetworkImage(profilePath)
                                          as ImageProvider
                                      : AssetImage(
                                          "images/default_profile.png"),
                                ),
                              ),
                      ),
                SizedBox(
                  width:
                      20, // Adjust spacing between the profile picture and profile information
                ),
                Expanded(
                  flex: 5, // Adjust flex values as needed
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profileFullName,
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          letterSpacing: 0.4,
                        ),
                      ),
                      SizedBox(
                          height:
                              5), // Add some vertical spacing between the full name and other information
                      Row(
                        children: [
                          Text(
                            postLength.toString() + " " + "Posts",
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          SizedBox(
                              width:
                                  20), // Adjust spacing between posts and lovers
                          Text(
                            lover_count.toString() + " " + "Lovers",
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      SizedBox(
                          height:
                              5), // Add some vertical spacing before the bio
                      bio == ""
                          ? Text(
                              "No Bio Yet.",
                              style: TextStyle(letterSpacing: 0.4),
                            )
                          : Text(
                              bio,
                              style: TextStyle(letterSpacing: 0.4),
                            ),
                    ],
                  ),
                )
              ],
            ),
            SizedBox(
              height: 8,
            ),
            samePerson ? editProfileButton(context) : loveButton(context),
            SizedBox(
              height: 20,
            )
          ],
        ),
      ),
    );
  }

  Widget loveButton(BuildContext context) {
    return FutureBuilder<bool>(
        future: isLoved,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            bool currentIsLoved = snapshot.data ?? false;
            return ElevatedButton.icon(
              onPressed: () async {
                if (currentIsLoved) {
                  await loverController.unLove(
                      widget.userIdCode, widget.profileIdCode);
                  getUserProfile();
                } else {
                  await loverController.Love(
                      widget.userIdCode, widget.profileIdCode);
                  getUserProfile();
                }
                setState(() {
                  isLoved = loverController.isLoved(
                      widget.userIdCode, widget.profileIdCode);
                });
                setState(() {});
              },
              icon: Icon(
                currentIsLoved ? Icons.favorite : Icons.favorite_border,
                color: Color.fromRGBO(237, 41, 106, 1),
              ),
              label: Text(
                currentIsLoved ? "Unlove" : "Love",
                style: TextStyle(color: Colors.black),
              ),
            );
          }
        });
  }

  Widget editProfileButton(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: OutlinedButton(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child:
                  Text("Edit Profile", style: TextStyle(color: Colors.black)),
            ),
            style: OutlinedButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: Size(0, 30),
                side: BorderSide(
                  color: Colors.grey,
                )),
            onPressed: () => {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfilePage(
                      userIdCode: widget.userIdCode,
                      profileIdCode: widget.profileIdCode),
                ),
              )
            },
          ),
        ),
      ],
    );
  }
}
