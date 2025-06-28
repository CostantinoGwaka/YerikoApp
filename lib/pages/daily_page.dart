import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';
import 'package:yeriko_app/main.dart';
import 'package:yeriko_app/models/user_collection_model.dart';
import 'package:yeriko_app/models/user_total_model.dart';
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
  UserTotalsResponse? userTotalData;
  // UserCollectionResponse userCollectionData;

  @override
  void initState() {
    super.initState();
    if (userData != null && currentYear != null) {
      getTotalSummary(userData!.userDetails.id, currentYear!.response.churchYear);
      // getUserCollections(userData!.userDetails.id, currentYear!.response.churchYear);
    }
  }

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

  Future<dynamic> getTotalSummary(int userId, String year) async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (userId.toString().isEmpty || year == "" || year.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Tafadhali hakikisha umeweka User ID na mwaka")),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      } else {
        String myApi = "$baseUrl/monthly/total/$userId/$year";
        final response = await http.get(
          Uri.parse(myApi),
          headers: await authHeader,
        );

        var jsonResponse = json.decode(response.body);

        if (response.statusCode == 200 && jsonResponse != null) {
          setState(() {
            _isLoading = false;
          });

          userTotalData = UserTotalsResponse.fromJson(jsonResponse);
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

  Future<UserCollectionResponse> getUserCollections(int userId, String year) async {
    print("User ID: $userId, Year: $year");
    try {
      if (userId.toString().isEmpty || year == "") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please make sure you have provide username and password")),
        );
        setState(() {
          _isLoading = false;
        });
        return UserCollectionResponse(
          statusCode: 400,
          message: "Please make sure you have provide username and password",
          response: [],
        );
      } else {
        String myApi = "$baseUrl/monthly/getMonthly/$userId";
        final response = await http.get(
          Uri.parse(myApi),
          headers: await authHeader,
        );

        var jsonResponse = json.decode(response.body);

        if (response.statusCode == 200 && jsonResponse != null) {
          setState(() {
            _isLoading = false;
          });

          return UserCollectionResponse.fromJson(jsonResponse);
        } else if (response.statusCode == 404) {
          //end here
          setState(() {
            _isLoading = false;
          });
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(jsonResponse['message'])),
          );
          return UserCollectionResponse(
            statusCode: 404,
            message: jsonResponse['message'],
            response: [],
          );
        } else {
          setState(() {
            _isLoading = false;
          });
          return UserCollectionResponse(
            statusCode: 404,
            message: jsonResponse['message'],
            response: [],
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
      return UserCollectionResponse(
        statusCode: 404,
        message: "Tafadhali hakikisha umeunganishwa na intaneti: $e",
        response: [],
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Mwaka wa Kanisa",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            currentYear != null ? currentYear!.response.churchYear : "Hakuna Mwaka wa Kanisa",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: mainFontColor,
                            ),
                          ),
                        ],
                      ),
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
                              "+${userData!.userDetails.phone}",
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
                      Column(
                        children: [
                          _isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(
                                  (userTotalData != null && userTotalData!.response.isNotEmpty)
                                      ? "${NumberFormat("#,##0", "en_US").format(
                                          userTotalData!.response
                                              .firstWhere(
                                                (e) => e.name == "totalMonthly",
                                              )
                                              .total,
                                        )}/="
                                      : "0.00",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: mainFontColor,
                                  ),
                                ),
                          SizedBox(height: 5),
                          Text(
                            "Jumla Kuu",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w100,
                              color: black,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 0.5,
                        height: 40,
                        color: black.withAlpha((0.3 * 255).round()),
                      ),
                      Column(
                        children: [
                          _isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(
                                  (userTotalData != null && userTotalData!.response.isNotEmpty)
                                      ? "${NumberFormat("#,##0", "en_US").format(
                                          userTotalData!.response
                                              .firstWhere(
                                                (e) => e.name == "totalMonthlyByCurrent",
                                              )
                                              .total,
                                        )}/="
                                      : "0.00",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: mainFontColor,
                                  ),
                                ),
                          SizedBox(height: 5),
                          Text(
                            "Jumla Kuu",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w100,
                              color: black,
                            ),
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
                        const Text("Michango",
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
                Text(
                  DateFormat('MMM d, yyyy').format(DateTime.now()),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: mainFontColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          // Padding(
          //   padding: const EdgeInsets.all(8.0),
          //   child: Column(
          //     children: [
          //       Row(
          //         children: [
          //           Expanded(
          //             child: Container(
          //               margin: const EdgeInsets.only(
          //                 top: 20,
          //                 left: 25,
          //                 right: 25,
          //               ),
          //               decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(25), boxShadow: [
          //                 BoxShadow(
          //                   color: grey.withAlpha((0.03 * 255).round()),
          //                   spreadRadius: 10,
          //                   blurRadius: 3,
          //                   // changes position of shadow
          //                 ),
          //               ]),
          //               child: Padding(
          //                 padding: const EdgeInsets.only(top: 10, bottom: 10, right: 20, left: 20),
          //                 child: Row(
          //                   children: [
          //                     Container(
          //                       width: 50,
          //                       height: 50,
          //                       decoration: BoxDecoration(
          //                         color: arrowbgColor,
          //                         borderRadius: BorderRadius.circular(15),
          //                         // shape: BoxShape.circle
          //                       ),
          //                       child: const Center(child: Icon(Icons.arrow_upward_rounded)),
          //                     ),
          //                     const SizedBox(
          //                       width: 15,
          //                     ),
          //                     Expanded(
          //                       child: SizedBox(
          //                         width: (size.width - 90) * 0.7,
          //                         child: Column(
          //                             mainAxisAlignment: MainAxisAlignment.center,
          //                             crossAxisAlignment: CrossAxisAlignment.start,
          //                             children: [
          //                               const Text(
          //                                 "Sent",
          //                                 style: TextStyle(fontSize: 15, color: black, fontWeight: FontWeight.bold),
          //                               ),
          //                               const SizedBox(
          //                                 height: 5,
          //                               ),
          //                               Text(
          //                                 "Sending Payment to Clients",
          //                                 style: TextStyle(
          //                                     fontSize: 12,
          //                                     color: black.withAlpha((0.5 * 255).round()),
          //                                     fontWeight: FontWeight.w400),
          //                               ),
          //                             ]),
          //                       ),
          //                     ),
          //                     Expanded(
          //                       child: const Row(
          //                         mainAxisAlignment: MainAxisAlignment.end,
          //                         children: [
          //                           Text(
          //                             "\$150",
          //                             style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: black),
          //                           )
          //                         ],
          //                       ),
          //                     )
          //                   ],
          //                 ),
          //               ),
          //             ),
          //           ),
          //         ],
          //       ),
          //       const SizedBox(
          //         height: 5,
          //       ),
          //     ],
          //   ),
          // )
          FutureBuilder(
            future: getUserCollections(userData!.userDetails.id, currentYear!.response.churchYear), // Your async method
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Center(child: Text("Failed to load collection data."));
              } else if (!snapshot.hasData || snapshot.data!.response.isEmpty) {
                return const Center(child: Text("No collection data found."));
              }

              final collections = snapshot.data!.response;

              return ListView.builder(
                itemCount: collections.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final item = collections[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: grey.withOpacity(0.05),
                            spreadRadius: 5,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: arrowbgColor,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(Icons.monetization_on_rounded, color: Colors.white),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.monthly,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: black),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${item.registeredBy} (${item.user.userFullName})",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: black.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "TZS ${item.amount.toString()}",
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: black),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    ));
  }
}
