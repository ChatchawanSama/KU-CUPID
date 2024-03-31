import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application/config.dart';
import 'package:flutter_application/controllers/post_controller.dart';
import 'package:http/http.dart' as http;

class Gallery extends StatefulWidget {
  int userId;
  String fullname;
  String profilePath;

  Gallery(
      {required this.userId,
      required this.fullname,
      required this.profilePath});

  @override
  _GalleryState createState() => _GalleryState();
}

class _GalleryState extends State<Gallery> {
  late OverlayEntry _popupDialog;
  List<String> imageUrls = [];
  List<dynamic> posts = [];
  PostController postController = PostController();

  late List<Map<String, dynamic>> _allPost = [];

  @override
  void initState() {
    super.initState();
    getImage(widget.userId.toString());
  }

  Future<void> getImage(userId) async {
    final String url = hostName + "/api/posts/" + userId;
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        _allPost = jsonData.cast<Map<String, dynamic>>();
        setState(() {
          posts = _allPost;
          imageUrls = _allPost
              .map<String>((post) => post['image_path'] as String)
              .toList();
        });
        imageUrls = imageUrls.reversed.toList();
        posts = posts.reversed.toList();
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
      body: GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        // children: imageUrls.map(_createGridTileWidget).toList(),
        children: List.generate(
          imageUrls.length,
          (index) =>
              _createGridTileWidget(imageUrls[index], posts[index]['caption']),
        ),
      ),
    );
  }

  Widget _createGridTileWidget(String url, String caption) => Builder(
        builder: (context) => GestureDetector(
          onLongPress: () {
            _popupDialog = _createPopupDialog(url, caption);
            Overlay.of(context).insert(_popupDialog);
          },
          onLongPressEnd: (details) => _popupDialog?.remove(),
          child: Image.network(url, fit: BoxFit.cover),
        ),
      );

  OverlayEntry _createPopupDialog(String url, String caption) {
    return OverlayEntry(
      builder: (context) => AnimatedDialog(
        child: _createPopupContent(url, caption),
      ),
    );
  }

  Widget _createPhotoTitle() => Container(
      width: double.infinity,
      color: Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: widget.profilePath != ""
              ? NetworkImage(widget.profilePath) as ImageProvider
              : AssetImage("images/default_profile.png"),
        ),
        title: Text(
          widget.fullname,
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ));

  Widget _createActionBar(String caption) => Container(
        padding: EdgeInsets.symmetric(vertical: 10.0),
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment
              .start, // Align children to the start (left) of the row
          children: [
            caption != ""
                ? Padding(
                    padding: const EdgeInsets.only(
                        left: 16.0), // Add some padding to the left of the text
                    child: Text(
                      // "This is my caption.",
                      caption,
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        letterSpacing: 0.4,
                      ),
                    ),
                  )
                : Container()
          ],
        ),
      );

  Widget _createPopupContent(String url, String caption) => Container(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _createPhotoTitle(),
              // Image.network(url, fit: BoxFit.cover),
              AspectRatio(
                aspectRatio: 16 / 16, // adjust the ratio as needed
                child: Image.network(url, fit: BoxFit.cover),
              ),
              _createActionBar(caption),
            ],
          ),
        ),
      );
}

class AnimatedDialog extends StatefulWidget {
  const AnimatedDialog({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  State<StatefulWidget> createState() => AnimatedDialogState();
}

class AnimatedDialogState extends State<AnimatedDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> opacityAnimation;
  late Animation<double> scaleAnimation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    scaleAnimation =
        CurvedAnimation(parent: controller, curve: Curves.easeOutExpo);
    opacityAnimation = Tween<double>(begin: 0.0, end: 0.6).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutExpo));

    controller.addListener(() => setState(() {}));
    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(opacityAnimation.value),
      child: Center(
        child: FadeTransition(
          opacity: scaleAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
