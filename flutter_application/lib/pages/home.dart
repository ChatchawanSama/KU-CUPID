import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/controllers/auth_controller.dart';
import 'package:flutter_application/pages/love_alarm.dart';
import 'package:flutter_application/pages/profile.dart';
import 'package:flutter_application/pages/search.dart';
import 'package:flutter_application/pages/your_love.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  final String title;
  final String token;

  const HomePage({Key? key, required this.title, required this.token})
      : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late String stdCode;
  late String heartId;
  late Position userLocation;
  AuthController authController = AuthController();
  int _selectedIndex = 0;
  late Timer locationTimer;

  @override
  void initState() {
    super.initState();
    // startLocationTimer();
    // initPermission();
    Map<String, dynamic> jwtDecodedToken = JwtDecoder.decode(widget.token);
    stdCode = jwtDecodedToken["std_code"];
    heartId = jwtDecodedToken["heart_id"];
    uploadTokenToFirestore(jwtDecodedToken);
    WidgetsBinding.instance?.addObserver(this);
  }

  void uploadTokenToFirestore(Map<String, dynamic> jwtDecodedToken) async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      CollectionReference usersCollection = firestore.collection('user');
      await usersCollection.doc(stdCode).set(jwtDecodedToken);
      print('Token uploaded to Firestore successfully');
    } catch (e) {
      print('Error uploading token to Firestore: $e');
    }
  }

  // void startLocationTimer() {
  //   locationTimer = Timer.periodic(Duration(seconds: 5), (Timer timer) {
  //     _getLocation();
  //   });
  // }

  @override
  void dispose() {
    locationTimer.cancel(); // Cancel the timer when the widget is disposed
    WidgetsBinding.instance?.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        // The app is now visible and active
        print('App is resumed');
        // Set user active status to true
        updateUserActiveStatus(true);
        break;
      case AppLifecycleState.inactive:
        // The app is inactive, for example, when the user receives a call or switches to another app
        print('App is inactive');
        // Set user active status to false
        updateUserActiveStatus(false);
        break;
      case AppLifecycleState.paused:
        // The app is paused, for example, when the user switches to the home screen or another app
        print('App is paused');
        // Set user active status to false
        updateUserActiveStatus(false);
        break;
      case AppLifecycleState.detached:
        // The app is detached, which happens when the platform returns to the home screen or another app is launched
        print('App is detached');
        // Set user active status to false
        updateUserActiveStatus(false);
        break;
      case AppLifecycleState.hidden:
      // TODO: Handle this case.
    }
  }

  void updateUserActiveStatus(bool isActive) async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      CollectionReference usersCollection = firestore.collection('user');
      await usersCollection.doc(stdCode).update({'is_active': isActive});
      print('User active status updated to Firestore successfully');
    } catch (e) {
      print('Error updating user active status to Firestore: $e');
    }
  }

  Future<Position> _getLocation() async {
    try {
      userLocation = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      setState(() {}); // Trigger a rebuild of the UI to update the location
    } catch (e) {
      print(e);
    }
    return userLocation;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.grey, // Set your border color here
              width: 0.5, // Set the border width here
            ),
          ),
        ),
        child: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: "Love",
            ),
            BottomNavigationBarItem(
                icon: Icon(Icons.account_box_rounded), label: "Profile"),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          // backgroundColor: Colors.blue, // Set your desired background color here
          selectedItemColor: Colors.purple,
          unselectedItemColor: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildBody(int index) {
    switch (index) {
      case 0:
        return _buildHomePageContent();
      case 1:
        return SearchPage(
          userIdCode: stdCode,
        );
      case 2:
        return YourLove(userStdCode: stdCode);
      case 3:
        return ProfilePage(
          userIdCode: stdCode,
          profileIdCode: stdCode,
        );
      default:
        return Container();
    }
  }

  Widget _buildHomePageContent() {
    return FutureBuilder<Position>(
      future: _determinePosition(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          return LoveAlarm(
            token: widget.token,
            heart_id: heartId,
          );
          // return Center(
          //   child: Text(
          //     'Latitude: ${snapshot.data!.latitude}\nLongitude: ${snapshot.data!.longitude}',
          //     style: TextStyle(fontSize: 18),
          //   ),
          // );
        } else {
          return Container();
        }
      },
    );
  }

  Future<Position> _determinePosition() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
