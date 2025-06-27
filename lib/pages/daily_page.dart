import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:yeriko_app/main.dart';
import 'package:yeriko_app/pages/login_page.dart';
import 'package:yeriko_app/shared/localstorage/index.dart';
import 'package:yeriko_app/theme/colors.dart';
import 'package:icon_badge/icon_badge.dart';
import 'package:yeriko_app/utils/url.dart';
import 'package:http/http.dart' as http;

class DailyPage extends StatefulWidget {
  const DailyPage({super.key});

  @override
  State<DailyPage> createState() => _DailyPageState();
}

class _DailyPageState extends State<DailyPage> {
  bool _isLoading = false;

  Future<dynamic> logout(BuildContext context) async {
    try {
      setState(() {
        _isLoading = true;
      });

      String myApi = "$baseUrl/auth/logout";
      final response = await http.post(
        Uri.parse(myApi),
        headers: {'Content-Type': 'application/json'},
      );

      var jsonResponse = json.decode(response.body);

      if (response.statusCode == 200 && jsonResponse != null) {
        setState(() {
          _isLoading = false;
        });

        await LocalStorage.clearSharedPrefs();

        Navigator.push(
          // ignore: use_build_context_synchronously
          context,
          PageTransition(
            type: PageTransitionType.fade,
            child: const LoginPage(),
          ),
        );

        //end here
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Success! You have Logout successfully")),
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
          SnackBar(content: Text(jsonResponse['message'] ?? "User not found in our system")),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please check your internet connection :$e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return SafeArea(
        child: SingleChildScrollView(
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 25, left: 25, right: 25, bottom: 10),
            decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(25), boxShadow: [
              BoxShadow(
                color: grey.withAlpha((0.03 * 255).round()),
                spreadRadius: 10,
                blurRadius: 3,
                // changes position of shadow
              ),
            ]),
            child: Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 25, right: 20, left: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.bar_chart),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == 'logout') {
                            logout(context);
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem<String>(
                            value: 'logout',
                            child: Row(
                              children: [
                                if (_isLoading)
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                else ...[
                                  Icon(Icons.logout, color: Colors.black54),
                                  SizedBox(width: 8),
                                ],
                                Text('Toka'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  Column(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: MediaQuery.of(context).size.height / 20,
                        child: CircleAvatar(
                          radius: MediaQuery.of(context).size.height / 8,
                          backgroundColor: Colors.white,
                          backgroundImage: const AssetImage("assets/avatar.png"),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      SizedBox(
                        width: (size.width - 40) * 0.6,
                        child: Column(
                          children: [
                            Text(
                              userData!.userDetails.userFullName,
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: mainFontColor),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Text(
                              "+255 ${userData!.userDetails.phone}",
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: black),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 50,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const Column(
                        children: [
                          Text(
                            "\$8900",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: mainFontColor),
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          Text(
                            "Jumla Kuu",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w100, color: black),
                          ),
                        ],
                      ),
                      Container(
                        width: 0.5,
                        height: 40,
                        color: black.withAlpha((0.3 * 255).round()),
                      ),
                      const Column(
                        children: [
                          Text(
                            "\$5500",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: mainFontColor),
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          Text(
                            "Jumla Mwaka",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w100, color: black),
                          ),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 25, right: 25),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Row(
                      children: [
                        const Text("Overview",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: mainFontColor,
                            )),
                        IconBadge(
                          icon: const Icon(Icons.notifications_none),
                          itemCount: 1,
                          badgeColor: Colors.red,
                          itemColor: mainFontColor,
                          hideZero: true,
                          top: -1,
                          onTap: () {
                            if (kDebugMode) {
                              print('test');
                            }
                          },
                        ),
                      ],
                    )
                  ],
                ),
                // Text("Overview",
                //     style: TextStyle(
                //       fontWeight: FontWeight.bold,
                //       fontSize: 20,
                //       color: mainFontColor,
                //     )),
                const Text("Jan 16, 2023",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: mainFontColor,
                    )),
              ],
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(
                          top: 20,
                          left: 25,
                          right: 25,
                        ),
                        decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(25), boxShadow: [
                          BoxShadow(
                            color: grey.withAlpha((0.03 * 255).round()),
                            spreadRadius: 10,
                            blurRadius: 3,
                            // changes position of shadow
                          ),
                        ]),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 10, right: 20, left: 20),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: arrowbgColor,
                                  borderRadius: BorderRadius.circular(15),
                                  // shape: BoxShape.circle
                                ),
                                child: const Center(child: Icon(Icons.arrow_upward_rounded)),
                              ),
                              const SizedBox(
                                width: 15,
                              ),
                              Expanded(
                                child: SizedBox(
                                  width: (size.width - 90) * 0.7,
                                  child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Sent",
                                          style: TextStyle(fontSize: 15, color: black, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        Text(
                                          "Sending Payment to Clients",
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: black.withAlpha((0.5 * 255).round()),
                                              fontWeight: FontWeight.w400),
                                        ),
                                      ]),
                                ),
                              ),
                              Expanded(
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      "\$150",
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: black),
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 5,
                ),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(
                          top: 10,
                          left: 25,
                          right: 25,
                        ),
                        decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(25), boxShadow: [
                          BoxShadow(
                            color: grey.withAlpha((0.03 * 255).round()),
                            spreadRadius: 10,
                            blurRadius: 3,
                            // changes position of shadow
                          ),
                        ]),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 10, right: 20, left: 20),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: arrowbgColor,
                                  borderRadius: BorderRadius.circular(15),
                                  // shape: BoxShape.circle
                                ),
                                child: const Center(child: Icon(Icons.arrow_downward_rounded)),
                              ),
                              const SizedBox(
                                width: 15,
                              ),
                              Expanded(
                                child: SizedBox(
                                  width: (size.width - 90) * 0.7,
                                  child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Receive",
                                          style: TextStyle(fontSize: 15, color: black, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        Text(
                                          "Receiving Payment from company",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: black.withValues(alpha: 0.5),
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ]),
                                ),
                              ),
                              Expanded(
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      "\$250",
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: black),
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 5,
                ),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(
                          top: 10,
                          left: 25,
                          right: 25,
                        ),
                        decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(25), boxShadow: [
                          BoxShadow(
                            color: grey.withValues(alpha: 0.03),
                            spreadRadius: 10,
                            blurRadius: 3,
                            // changes position of shadow
                          ),
                        ]),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 10, right: 20, left: 20),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: arrowbgColor,
                                  borderRadius: BorderRadius.circular(15),
                                  // shape: BoxShape.circle
                                ),
                                child: const Center(child: Icon(CupertinoIcons.money_dollar)),
                              ),
                              const SizedBox(
                                width: 15,
                              ),
                              Expanded(
                                child: SizedBox(
                                  width: (size.width - 90) * 0.7,
                                  child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Loan",
                                          style: TextStyle(fontSize: 15, color: black, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        Text(
                                          "Loan for the Car",
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: black.withValues(alpha: 0.5),
                                              fontWeight: FontWeight.w400),
                                        ),
                                      ]),
                                ),
                              ),
                              Expanded(
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      "\$400",
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: black),
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    ));
  }
}
