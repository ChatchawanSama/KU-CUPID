import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/controllers/post_controller.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_application/pages/profile.dart';

final FirebaseStorage _storage = FirebaseStorage.instance;
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class AddPost extends StatefulWidget {
  final String userIdCode;
  final String profileIdCode;
  final int userId;

  AddPost(
      {Key? key,
      required this.userIdCode,
      required this.profileIdCode,
      required this.userId})
      : super(key: key);

  @override
  State<AddPost> createState() => _AddPostState();
}

class _AddPostState extends State<AddPost> {
  PostController postController = PostController();
  final captionController = TextEditingController();
  final List<Widget> _mediaList = [];
  final List<File> path = [];
  File? _file;
  int currentPage = 0;
  int? lastPage;
  String _caption = "";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _fetchNewMedia();
  }

  // void newPost() async {
  //   // Navigator.pop(context);
  //   Uint8List bytes = _file!.readAsBytesSync() as Uint8List;
  //   print(_file!);

  //   String resp = await saveData(stdIdCode: widget.profileIdCode, file: bytes);
  //   print("Save Success");
  //   print(resp);
  //   Navigator.pop(context);
  // }

  void newPost() async {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents user from dismissing the dialog
      builder: (context) => Center(
        child: CircularProgressIndicator(), // Show loading indicator
      ),
    );

    try {
      Uint8List bytes = _file!.readAsBytesSync() as Uint8List;

      String resp =
          await saveData(stdIdCode: widget.profileIdCode, file: bytes);
      if (resp == "Success") {
        Navigator.pop(context); // Close the loading indicator dialog
        Navigator.pop(context); // Close the current screen
        // Navigator.pop(context);
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => ProfilePage(
        //         userIdCode: widget.userIdCode,
        //         profileIdCode: widget.profileIdCode),
        //   ),
        // );

        // Navigator.pop(context);
      }
    } catch (e) {
      print("Error: $e");
      // Handle error if necessary
      Navigator.pop(context); // Close the loading indicator dialog
      // Optionally, show an error message to the user
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Error"),
          content: Text("Failed to upload the file. Please try again later."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  Future<String> uploadImageToStorage(String childName, Uint8List file) async {
    Reference ref = _storage.ref().child(childName);
    UploadTask uploadTask = ref.putData(file);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    _caption = captionController.text;
    final uploadResult =
        postController.uploadPost(widget.userId, _caption, downloadUrl);
    return downloadUrl;
  }

  // void sayHi() {
  //   print("SAYHI");

  //   Navigator.pop(context);
  // }

  Future<String> saveData(
      {required String stdIdCode, required Uint8List file}) async {
    String resp = "Some Error Occured";
    try {
      if (stdIdCode.isNotEmpty) {
        String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

        String imageUrl = await uploadImageToStorage(
            widget.profileIdCode + 'post_' + timestamp + ".png", file);
        resp = "Success";
      }
    } catch (err) {
      resp = err.toString();
      print(" Save image error : ${resp}");
    }
    return resp;
  }

  @override
  _fetchNewMedia() async {
    lastPage = currentPage;
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    // if (ps.isAuth) {
    List<AssetPathEntity> album =
        await PhotoManager.getAssetPathList(type: RequestType.image);
    List<AssetEntity> media =
        await album[0].getAssetListPaged(page: currentPage, size: 60);

    for (var asset in media) {
      if (asset.type == AssetType.image) {
        final file = await asset.file;
        if (file != null) {
          path.add(File(file.path));
          _file = path[0];
        }
      }
    }

    List<Widget> temp = [];
    for (var asset in media) {
      temp.add(
        FutureBuilder(
          future: asset.thumbnailDataWithSize(ThumbnailSize(200, 200)),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done)
              return Container(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.memory(
                        snapshot.data!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              );

            return Container();
          },
        ),
      );
    }
    setState(() {
      _mediaList.addAll(temp);
      currentPage++;
    });
    // }
  }

  int indexx = 0;

  Future<void> _saveImageToLocalStorage(int index) async {
    try {
      final Widget selectedImage = _mediaList[index];
      // Now you need to extract the file path from the selectedImage
      // You can use this path to save the image to local storage
      print('Image saved to local storage');
    } catch (e) {
      print('Error saving image to local storage: $e');
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'New Post',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: false,
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: GestureDetector(
                // onTap: () => newPost(context),
                onTap: newPost,
                // onTap: () => {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => ProfilePage(
                //         userIdCode: widget.userIdCode,
                //         profileIdCode: widget.profileIdCode),
                //   ),
                // )
                // },
                child: Text('Post',
                    style: TextStyle(fontSize: 15, color: Colors.blue)),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            SingleChildScrollView(
              child: SizedBox(
                width: 400,
                height: 50,
                child: TextField(
                  controller: captionController,
                  decoration: const InputDecoration(
                    hintText: 'Write a caption ...',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 375,
              child: GridView.builder(
                itemCount: _mediaList.isEmpty ? _mediaList.length : 1,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  mainAxisSpacing: 1,
                  crossAxisSpacing: 1,
                ),
                itemBuilder: (context, index) {
                  return _mediaList[indexx];
                },
              ),
            ),
            SizedBox(
              height: 40,
              child: Container(
                color: Colors.white,
                child: Row(
                  children: [
                    SizedBox(width: 10),
                    Text(
                      'Recent',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                itemCount: _mediaList.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 1,
                  crossAxisSpacing: 2,
                ),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        indexx = index;
                        _file = path[index];
                      });
                    },
                    child: _mediaList[index],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
