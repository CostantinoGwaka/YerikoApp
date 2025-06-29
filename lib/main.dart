import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:yeriko_app/models/auth_model.dart';
import 'package:yeriko_app/models/current_fy_model.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:yeriko_app/pages/home_page.dart';
import 'package:yeriko_app/pages/login_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yeriko_app/shared/localstorage/index.dart';
import 'package:yeriko_app/utils/url.dart';
import 'package:http/http.dart' as http;

LoginResponse? userData;
ActiveChurchYearResponse? currentYear;

Future<void> getCurrentChurchYearData() async {
  try {
    String myApi = "$baseUrl/year/get_active_year.php";
    final response = await http.get(
      Uri.parse(myApi),
      headers: {'Accept': 'application/json'},
    );

    var jsonResponse = json.decode(response.body);

    if (response.statusCode == 200 && jsonResponse != null) {
      currentYear = ActiveChurchYearResponse.fromJson(jsonResponse);
    }
  } catch (e) {
    if (kDebugMode) {
      print("Tafadhali hakikisha umeunganishwa na intaneti: $e");
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterLocalization.instance.ensureInitialized();
  await getCurrentChurchYearData();
  runApp(Phoenix(child: const MyApp()));
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
          LoginResponse user = LoginResponse.fromJson(userMap);
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
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('sw', 'TZ'),
      ], // Optional: Swahili locale
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: (userData != null && userData!.user.phone!.isNotEmpty) ? HomePage() : LoginPage(),
    );
  }
}
