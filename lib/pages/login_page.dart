import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:page_transition/page_transition.dart';
import 'package:yeriko_app/main.dart';
import 'package:yeriko_app/models/auth_model.dart';
import 'package:yeriko_app/pages/home_page.dart';
import 'package:yeriko_app/shared/localstorage/index.dart';
import 'package:yeriko_app/theme/colors.dart';
import 'package:yeriko_app/utils/url.dart';
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
    return Scaffold(
      backgroundColor: primary,
      body: getBody(),
    );
  }

  Future<dynamic> login(BuildContext context, String username, String password) async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (username == "" || password == "") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Tafadhali hakikisha umeweka namba ya simu na nenosiri")),
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

        if (response.statusCode == 200 && jsonResponse != null) {
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
            PageTransition(type: PageTransitionType.fade, child: const HomePage()),
          );

          //end here
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Umefanikiwa! Umeingia kwenye mfumo kwa mafanikio")),
          );
        } else if (response.statusCode == 404) {
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
            SnackBar(content: Text(jsonResponse['message'] ?? "Mtumiaji hakupatikana kwenye mfumo wetu")),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Tafadhali hakikisha umeunganishwa na intaneti: $e")),
      );
    }
  }

  Widget getBody() {
    return SafeArea(
        child: Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Column(
              children: [
                const SizedBox(height: 2),
                Text(
                  "YERIKO APP",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: buttoncolor,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 50,
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 25),
              decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(25), boxShadow: [
                BoxShadow(
                  color: grey.withAlpha((0.03 * 255).round()),
                  spreadRadius: 10,
                  blurRadius: 3,
                ),
              ]),
              child: Padding(
                padding: const EdgeInsets.only(left: 20, top: 15, bottom: 5, right: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Namba ya simu",
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Color(0xff67727d)),
                    ),
                    TextField(
                      controller: _phone,
                      cursorColor: black,
                      keyboardType: TextInputType.phone, // Show numeric keyboard
                      maxLength: 10, // Limit to 10 characters
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly, // Only allow digits
                        LengthLimitingTextInputFormatter(10), // Enforce 10 digit limit
                      ],
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: black,
                      ),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.phone_android),
                        prefixIconColor: black,
                        hintText: "Namba ya simu (tarakimu 10)",
                        border: InputBorder.none,
                        counterText: "", // Hide the character counter
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 25),
              decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(25), boxShadow: [
                BoxShadow(
                  color: grey.withAlpha((0.03 * 255).round()),
                  spreadRadius: 10,
                  blurRadius: 3,
                ),
              ]),
              child: Padding(
                padding: const EdgeInsets.only(left: 20, top: 15, bottom: 5, right: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Nenosiri",
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Color(0xff67727d)),
                    ),
                    TextField(
                      obscureText: !isPasswordVisible, // Toggle based on state
                      controller: _password,
                      cursorColor: black,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: black),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        prefixIconColor: Colors.black,
                        suffixIcon: IconButton(
                          icon: Icon(isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          color: Colors.black,
                          onPressed: () {
                            setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                        ),
                        hintText: "Nenosiri",
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            GestureDetector(
              onTap: _isLoading
                  ? null
                  : () async {
                      // Disable tap when loading
                      if (_phone.text.length == 10 && _password.text.isNotEmpty) {
                        // Start loading
                        setState(() {
                          _isLoading = true;
                        });
                        login(context, _phone.text, _password.text);
                        // try {
                        //   // Simulate login process (replace with your actual login logic)
                        //   await Future.delayed(const Duration(seconds: 2));

                        //   // Navigate to HomePage if login is successful
                        //   if (mounted) {
                        //     // Check if widget is still mounted
                        //     Navigator.pushReplacement(
                        //       context,
                        //       MaterialPageRoute(builder: (context) => const HomePage()),
                        //     );
                        //   }
                        // } catch (e) {
                        //   // Handle login error
                        //   if (mounted) {
                        //     ScaffoldMessenger.of(context).showSnackBar(
                        //       const SnackBar(content: Text("Login failed. Please try again.")),
                        //     );
                        //   }
                        // } finally {
                        //   // Stop loading
                        //   if (mounted) {
                        //     setState(() {
                        //       _isLoading = false;
                        //     });
                        //   }
                        // }
                      } else {
                        // Show validation error
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please enter a valid phone number and password.")),
                        );
                      }
                    },
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 25),
                decoration: BoxDecoration(
                    color: _isLoading
                        ? buttoncolor.withAlpha((0.7 * 255).toInt())
                        : buttoncolor, // Dim button when loading
                    borderRadius: BorderRadius.circular(25)),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.login, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              "Ingia",
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            const Padding(
              padding: EdgeInsets.only(left: 26.0, right: 26.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "",
                    style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w300),
                  ),
                  Text(
                    "",
                    style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w300),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    ));
  }
}
