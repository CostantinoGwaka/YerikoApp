// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jumuiya_yangu/utils/global/appSetting.dart';
import 'package:page_transition/page_transition.dart';
import 'package:jumuiya_yangu/main.dart';
import 'package:jumuiya_yangu/models/auth_model.dart';
import 'package:jumuiya_yangu/pages/home_page.dart';
import 'package:jumuiya_yangu/shared/localstorage/index.dart';
import 'package:jumuiya_yangu/theme/colors.dart';
import 'package:jumuiya_yangu/utils/url.dart';
import 'package:http/http.dart' as http;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool isPasswordVisible = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // final size = MediaQuery.of(context).size;
    // final isSmallScreen = size.width < 360;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: getBody(),
    );
  }

  Future<dynamic> login(
      BuildContext context, String username, String password) async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (username == "" || password == "") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "⚠️ Tafadhali hakikisha umeweka namba ya simu na nenosiri")),
        );
      } else {
        String myApi = "$baseUrl/auth/login.php";
        final response = await http.post(
          Uri.parse(myApi),
          headers: {'Accept': 'application/json'},
          body: {
            "uname": "255${username.substring(1)}",
            "password": password,
          },
        );

        await LocalStorage.removeItem("user_data");
        await LocalStorage.clearSharedPrefs();

        var jsonResponse = json.decode(response.body);

        if (response.statusCode == 200 &&
            jsonResponse != null &&
            jsonResponse['status'] == '200') {
          setState(() {
            _isLoading = false;
          });

          setState(() {
            _phone.clear();
            _password.clear();
          });

          final loginModel = LoginResponse.fromJson(jsonResponse);

          final jsonString = jsonEncode(loginModel.toJson());
          await LocalStorage.setStringItem("user_data", jsonString);

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

          Navigator.push(
            // ignore: use_build_context_synchronously
            context,
            PageTransition(
                type: PageTransitionType.fade, child: const HomePage()),
          );

          //end here
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text("✅ Umefanikiwa! Umeingia kwenye mfumo kwa mafanikio")),
          );
        } else if (jsonResponse['status'] == '300' ||
            jsonResponse['status'] == '403') {
          //end here
          setState(() {
            _isLoading = false;
          });
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(jsonResponse['message'])),
          );
        } else {
          setState(() {
            _isLoading = false;
          });
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(jsonResponse['message'] ??
                    "ℹ️ Mtumiaji hakupatikana kwenye mfumo wetu")),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("⚠️ Tafadhali hakikisha umeunganishwa na intaneti")),
      );
    }
  }

  Widget getBody() {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
            child: Column(children: [
              SizedBox(height: size.height * 0.01),
              // Logo and Title Section
              Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          mainFontColor,
                          mainFontColor.withOpacity(0.7),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: mainFontColor.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Image.asset(
                        'assets/appicon.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.01),
                  Text(
                    "Jumuiya Yangu",
                    style: TextStyle(
                      fontSize: isSmallScreen ? 28 : 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: mainFontColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Karibu tena! Ingia kwenye akaunti yako",
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              SizedBox(height: size.height * 0.02),

              // Login Form
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 20 : 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 0,
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Phone Number Field
                    Text(
                      "Namba ya Simu",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: mainFontColor,
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _phone,
                        cursorColor: mainFontColor,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(12),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: mainFontColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.phone_rounded,
                              color: mainFontColor,
                              size: 20,
                            ),
                          ),
                          hintText: "0700123456",
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          counterText: "",
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    // Password Field
                    Text(
                      "Nenosiri",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: mainFontColor,
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        obscureText: !isPasswordVisible,
                        controller: _password,
                        cursorColor: mainFontColor,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(12),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: mainFontColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.lock_rounded,
                              color: mainFontColor,
                              size: 20,
                            ),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              isPasswordVisible
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: Colors.grey[500],
                              size: 22,
                            ),
                            onPressed: () {
                              setState(() {
                                isPasswordVisible = !isPasswordVisible;
                              });
                            },
                          ),
                          hintText: "Weka nenosiri lako",
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 32),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () async {
                                if (_phone.text.length == 10 &&
                                    _password.text.isNotEmpty) {
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  login(context, _phone.text, _password.text);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                          "⚠️ Tafadhali weka namba sahihi ya simu na nenosiri."),
                                      backgroundColor: Colors.orange[400],
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isLoading
                              ? mainFontColor.withOpacity(0.7)
                              : mainFontColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: _isLoading ? 0 : 3,
                          shadowColor: mainFontColor.withOpacity(0.3),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.login_rounded, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    "Ingia",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Forgot Password Link
              TextButton(
                onPressed: () {
                  showSnackBar(context, "✅ Bado Ipo Katika Ujenzi.");
                },
                style: TextButton.styleFrom(
                  foregroundColor: mainFontColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(
                  "Umesahau nenosiri?",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.01),

              // App Version
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Toleo ${AppSettings.appVersion}",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: FloatingActionButton(
                      heroTag: "helpDeskBtn",
                      backgroundColor: mainFontColor,
                      onPressed: () {
                        showSnackBar(context, "📞 Help Desk: 0659515042");
                      },
                      child: Icon(Icons.support_agent_rounded,
                          color: Colors.white),
                    ),
                  ),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
