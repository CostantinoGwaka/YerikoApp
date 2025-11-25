import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jumuiya_yangu/models/auth_model.dart';
import 'package:jumuiya_yangu/models/current_fy_model.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:jumuiya_yangu/pages/home_page.dart';
import 'package:jumuiya_yangu/pages/login_page.dart';
import 'package:jumuiya_yangu/shared/localstorage/index.dart';
import 'package:jumuiya_yangu/theme/colors.dart';
import 'package:jumuiya_yangu/utils/url.dart';
import 'package:http/http.dart' as http;

LoginResponse? userData;
ActiveChurchYearResponse? currentYear;
final GlobalKey<NavigatorState> globalNavigatorKey =
    GlobalKey<NavigatorState>();

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
      print("⚠️ Tafadhali hakikisha umeunganishwa na intaneti");
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterLocalization.instance.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: mainFontColor, // 🔹 Status bar color
    statusBarIconBrightness: Brightness.light, // 🔹 Icon/text color
  ));

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarBrightness:
        Brightness.light, // 🔹 For iOS (controls background behind status bar)
    statusBarIconBrightness:
        Brightness.light, // 🔹 For Android (controls status bar icons)
  ));
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
        appBarTheme: AppBarTheme(
          backgroundColor: mainFontColor,
          foregroundColor: mainFontColor,
        ),
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
      home: (userData != null && userData!.user.phone!.isNotEmpty)
          ? HomePage()
          : LoginPage(),
    );
  }
}
