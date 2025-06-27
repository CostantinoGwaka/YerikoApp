import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:yeriko_app/models/auth_model.dart';
import 'package:yeriko_app/pages/home_page.dart';
import 'package:yeriko_app/pages/login_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yeriko_app/shared/localstorage/index.dart';

LoginResponseModel? userData;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    getUserLocalData();
  }

  void getUserLocalData() async {
    LocalStorage.getStringItem('user_data').then((value) {
      if (value.isNotEmpty) {
        setState(() {
          Map<String, dynamic> userMap = jsonDecode(value);
          LoginResponseModel user = LoginResponseModel.fromJson(userMap);
          userData = user;
        });
      } else {
        userData = null;
      }
    });
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: GoogleFonts.poppins().fontFamily,
      ),
      home: (userData != null && userData!.accessToken.isNotEmpty) ? HomePage() : LoginPage(),
    );
  }
}
