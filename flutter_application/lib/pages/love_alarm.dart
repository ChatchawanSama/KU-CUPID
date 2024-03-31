// ignore_for_file: must_call_super

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/controllers/auth_controller.dart';
import 'package:flutter_application/controllers/love_alarm_controller.dart';
import 'package:flutter_application/controllers/lover_controller.dart';
import 'package:flutter_application/pages/chat.dart';
import 'package:geolocator/geolocator.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:permission_handler/permission_handler.dart';

class LoveAlarm extends StatefulWidget {
  final String token;
  final String heart_id;

  LoveAlarm({Key? key, required this.token, required this.heart_id})
      : super(key: key);

  @override
  State<LoveAlarm> createState() => _LoveAlarmState();
}

class _LoveAlarmState extends State<LoveAlarm> with TickerProviderStateMixin {
  AuthController authController = AuthController();
  late String user_idcode;
  AnimationController? _controller;
  late AnimationController _controller2;
  late Animation<double> _animation;
  List<String> nearlyLoverList = [];
  int totalLover = 0;
  // double distanceThreshold = 0.033;
  double distanceThreshold = 999999;
  int count_gps = 0;
  bool _isLove = false;
  // Timer? _timer;

  bool _isShaking = false;
  LoveAlarmController loveAlarmController = LoveAlarmController();
  LoverController loverController = LoverController();
  List listFound = [];
  List<dynamic> loverData = [];
  // Timer? _timer;
  late Timer locationTimer;
  var listRange = [];
  List<dynamic> cupidSync = [];
  List<dynamic> cupidNoSync = [];

  @override
  void initState() {
    super.initState();
    Map<String, dynamic> jwtDecodedToken = JwtDecoder.decode(widget.token);
    user_idcode = jwtDecodedToken["std_code"];

    initLoverData();
    initUserLocation();
    initPermission();
    startLocationTimer();
    _controller = AnimationController(
      vsync: this,
      lowerBound: 0.5,
      duration: Duration(seconds: 5),
    )..repeat();

    _controller2 = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: -0.22,
      end: 0.22,
    ).animate(_controller2)
      ..addListener(() {
        setState(() {});
      });

    _controller2.repeat(reverse: true);
  }

  void initLoverData() async {
    loverData = await loveAlarmController.getAllBound(user_idcode);
  }

  Future<void> initCupid(double userLatitude, double userLongitude) async {
    setState(() {
      cupidSync = [];
      cupidNoSync = [];
    });

    // Initialize cupidSync
    for (int i = 0; i < loverData.length; i++) {
      if (loverData[i]["user_std_code"] == user_idcode) {
        for (int j = 0; j < loverData.length; j++) {
          if (loverData[j]["user_std_code"] ==
                  loverData[i]["lover_user_std_code"] &&
              loverData[j]["lover_user_std_code"] == user_idcode) {
            setState(() {
              cupidSync.add(loverData[j]["user_std_code"]);
            });
          }
        }
      }
    }

    // Initialize cupidNoSync
    for (int i = 0; i < loverData.length; i++) {
      if (loverData[i]["user_std_code"] != user_idcode) {
        setState(() {
          cupidNoSync.add(loverData[i]["user_std_code"]);
        });
      }
    }
    cupidNoSync.removeWhere((element) => cupidSync.contains(element));

    // print("No Love : ${cupidNoSync}");
    // print("Love : ${cupidSync}");

    if (cupidSync.isNotEmpty) {
      // Fetch data from Firestore for cupidSync std_codes
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('locations')
          .where('std_code', whereIn: cupidSync)
          .get();

      List<DocumentSnapshot> documents = querySnapshot.docs;
      for (var document in documents) {
        // Handle fetched data
        // Example usage: access document fields
        double latitude = document['latitude'];
        double longitude = document['longitude'];

        if (haversine(latitude, longitude, userLatitude, userLongitude) >
            distanceThreshold) {
          setState(() {
            cupidSync.remove(document['std_code']);
          });
        }
      }
    }

    if (cupidNoSync.isNotEmpty) {
      // Fetch data from Firestore for cupidNoSync std_codes
      QuerySnapshot querySnapshot2 = await FirebaseFirestore.instance
          .collection('locations')
          .where('std_code', whereIn: cupidNoSync)
          .get();

      List<DocumentSnapshot> documents2 = querySnapshot2.docs;
      for (var document in documents2) {
        // Handle fetched data
        // Example usage: access document fields
        double latitude = document['latitude'];
        double longitude = document['longitude'];

        if (haversine(latitude, longitude, userLatitude, userLongitude) >
            distanceThreshold) {
          setState(() {
            cupidNoSync.remove(document['std_code']);
          });
        }
      }
    }

    if (cupidSync.isNotEmpty) {
      setState(() {
        nearlyLoverList = cupidSync.map((item) => item.toString()).toList();
        _isLove = true;
      });
    }

    if (cupidNoSync.isNotEmpty || cupidSync.isNotEmpty) {
      setState(() {
        totalLover = cupidNoSync.length + cupidSync.length;
      });
    }
  }

  @override
  void dispose() {
    locationTimer.cancel();
    // _timer!.cancel();
    _controller!.dispose();
    _controller2.dispose();
    super.dispose();
  }

  void initPermission() async {
    PermissionStatus status = await Permission.location.request();
    if (status == PermissionStatus.granted) {
    } else {
      openAppSettings();
    }
  }

  void startLocationTimer() {
    locationTimer = Timer.periodic(Duration(seconds: 5), (Timer timer) {
      initUserLocation();
    });
  }

  void initUserLocation() async {
    try {
      Position userLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      loveAlarmController.updateLocation(
          user_idcode, userLocation.latitude, userLocation.longitude);

      // Check if a document with the same std_code exists
      var querySnapshot = await FirebaseFirestore.instance
          .collection('locations')
          .where('std_code', isEqualTo: user_idcode)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // If document with std_code exists, update its data
        var docId = querySnapshot.docs.first.id;
        await FirebaseFirestore.instance
            .collection('locations')
            .doc(docId)
            .update({
          'latitude': userLocation.latitude,
          'longitude': userLocation.longitude,
          'timestamp': DateTime.now(),
        });
      } else {
        // If document with std_code doesn't exist, add a new document
        await FirebaseFirestore.instance.collection('locations').add({
          'std_code': user_idcode,
          'latitude': userLocation.latitude,
          'longitude': userLocation.longitude,
          'timestamp': DateTime.now(),
        });
      }
      initCupid(userLocation.latitude, userLocation.longitude);
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  double radians(double degrees) {
    return degrees * (pi / 180);
  }

  double haversine(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371.0; // Earth's radius in kilometers

    // Convert latitude and longitude from degrees to radians
    final lat1Rad = radians(lat1);
    final lon1Rad = radians(lon1);
    final lat2Rad = radians(lat2);
    final lon2Rad = radians(lon2);

    // Calculate differences
    final dLat = lat2Rad - lat1Rad;
    final dLon = lon2Rad - lon1Rad;

    // Haversine formula
    final a = pow(sin(dLat / 2), 2) +
        cos(lat1Rad) * cos(lat2Rad) * pow(sin(dLon / 2), 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    // Calculate distance
    final distance = earthRadius * c;

    return distance;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xff01d2e5),
                  Color(0xffdeaab3),
                ],
              ),
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  child: Text(
                    "LoveAlarm",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                _isLove
                    ? // Add this condition
                    Container(
                        child: Text(
                          "Your love is within a 40 meter radius",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : SizedBox(),
                Container(
                  height: MediaQuery.of(context).size.width - 50,
                  child: AnimatedBuilder(
                    animation: CurvedAnimation(
                      parent: _controller!,
                      curve: Curves.linear,
                    ),
                    builder: (context, child) {
                      return Container(
                        width: MediaQuery.of(context).size.width - 50,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _buildContainer(
                                MediaQuery.of(context).size.width - 50, true),
                            _buildContainer(300 * _controller!.value, false),
                            _buildContainer(400 * _controller!.value, false),
                            _buildContainer(500 * _controller!.value, false),
                            _buildContainer(600 * _controller!.value, false),
                            _isLove
                                ? GestureDetector(
                                    onTap: () {
                                      // Navigate to another screen or perform any action here
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChatPage(
                                            senderStdCode: user_idcode,
                                            chatList: nearlyLoverList,
                                            token: widget.token,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Transform.rotate(
                                      angle: _animation.value,
                                      child: Icon(
                                        Icons.favorite,
                                        color: Colors.red,
                                        size: 100,
                                      ),
                                    ),
                                  )
                                : GestureDetector(
                                    onTap: () {},
                                    child: Icon(
                                      Icons.favorite,
                                      color: Colors.red,
                                      size: 100,
                                    ),
                                  )
                          ],
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Container(
                  child: Text(
                    (totalLover).toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Heart ID : ${widget.heart_id}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.content_copy),
                      color: Colors.white,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: widget.heart_id));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Heart ID copied to clipboard'),
                          duration: Duration(seconds: 1),
                        ));
                      },
                    ),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildContainer(double radius, bool isBg) {
    return Container(
      width: radius,
      height: radius,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          width: 15,
          color: Colors.white.withOpacity(
            1 - _controller!.value + (isBg ? 0.05 : 0.3),
          ),
        ),
      ),
    );
  }
}
