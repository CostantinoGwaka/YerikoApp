import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';
import 'package:jumuiya_yangu/main.dart';
import 'package:jumuiya_yangu/models/other_collection_model.dart';
import 'package:jumuiya_yangu/models/user_collection_model.dart';
import 'package:jumuiya_yangu/models/user_total_model.dart';
import 'package:jumuiya_yangu/pages/login_page.dart';
import 'package:jumuiya_yangu/pages/supports_pages/other_collection.dart';
import 'package:jumuiya_yangu/pages/supports_pages/view_collection.dart';
import 'package:jumuiya_yangu/shared/localstorage/index.dart';
import 'package:jumuiya_yangu/theme/colors.dart';
import 'package:jumuiya_yangu/utils/url.dart';
import 'package:http/http.dart' as http;

class DailyPage extends StatefulWidget {
  const DailyPage({super.key});

  @override
  State<DailyPage> createState() => _DailyPageState();
}

class _DailyPageState extends State<DailyPage> {
  bool _isLoading = false;
  UserTotalsResponse? userTotalData;
  CollectionResponse? collections;
  OtherCollectionResponse? otherCollectionResponse;
  // UserCollectionResponse userCollectionData;

  @override
  void initState() {
    super.initState();
    if (userData != null && currentYear != null) {
      setState(() {});
      getTotalSummary(userData!.user.id!, currentYear!.data.churchYear);
      getUserOtherCollections();
    }
  }

  Future<void> _reloadData() async {
    await getUserCollections();
    if (userData != null && currentYear != null) {
      getTotalSummary(userData!.user.id!, currentYear!.data.churchYear);
    }
    setState(() {}); // Refresh UI after fetching data
  }

  Future<dynamic> logout(BuildContext context) async {
    // Clear storage first
    await LocalStorage.clearSharedPrefs();

    // Use Future.microtask to delay navigation until next frame
    Future.microtask(() {
      Navigator.pushAndRemoveUntil(
        // ignore: use_build_context_synchronously
        context,
        PageTransition(
          type: PageTransitionType.fade,
          child: const LoginPage(),
        ),
        (route) => false, // Remove all previous routes
      );
    });

    // Show snackBar AFTER navigation is complete using post-frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Umefanikiwa! Umetoka kwenye mfumo.")),
      );
    });
  }

  Future<dynamic> getTotalSummary(int userId, String year) async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (userId.toString().isEmpty || year == "" || year.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ Tafadhali hakikisha umeweka User ID na mwaka")),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      } else {
        String myApi = "$baseUrl/monthly/get_total_by_user_statistics.php?userId=$userId&year=$year";
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
        SnackBar(content: Text("⚠️ Tafadhali hakikisha umeunganishwa na intaneti: $e")),
      );
    }
  }

  Future<CollectionResponse?> getUserCollections() async {
    try {
      if (userData?.user.id == null || userData!.user.id.toString().isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("⚠️ Hakuna taarifa zaidi kuwezesha kupata taarifa")),
          );
        }
        // setState(() => _isLoading = false);
        return null;
      }

      final String myApi = "$baseUrl/monthly/get_collection_by_user_id.php?user_id=${userData!.user.id}";
      final response = await http.get(Uri.parse(myApi), headers: {'Accept': 'application/json'});

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse != null) {
          // setState(() => _isLoading = false);
          collections = CollectionResponse.fromJson(jsonResponse);
          return collections;
        }
      } else {
        if (context.mounted) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${response.statusCode}")),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ Tafadhali hakikisha umeunganishwa na intaneti: $e")),
        );
      }
    }

    // 🔁 Always return something to complete Future
    return null;
  }

  Future<OtherCollectionResponse?> getUserOtherCollections() async {
    try {
      if (userData?.user.id == null || userData!.user.id.toString().isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("⚠️ Hakuna taarifa zaidi kuwezesha kupata taarifa")),
          );
        }
        // setState(() => _isLoading = false);
        return null;
      }

      final String myApi = "$baseUrl/monthly/get_all_other_collection_by_user.php?userId=${userData!.user.id}";
      final response = await http.get(Uri.parse(myApi), headers: {'Accept': 'application/json'});

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse != null) {
          // setState(() => _isLoading = false);
          otherCollectionResponse = OtherCollectionResponse.fromJson(jsonResponse);
          return otherCollectionResponse;
        }
      } else {
        if (context.mounted) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${response.statusCode}")),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ Tafadhali hakikisha umeunganishwa na intaneti: $e")),
        );
      }
    }

    // 🔁 Always return something to complete Future
    return null;
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return SafeArea(
        child: RefreshIndicator(
      onRefresh: _reloadData,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(left: 8.0, right: (size.width - 40) / 30, bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
            Container(
              margin: EdgeInsets.only(
                  top: 10, left: (size.width - 40) / 30, right: (size.width - 40) / 30, bottom: (size.width - 40) / 30),
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
                              currentYear != null ? currentYear!.data.churchYear : "Hakuna Mwaka wa Kanisa",
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
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Toka'),
                                    content: const Text('Una uhakika unataka kutoka?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          logout(context);
                                        },
                                        child: const Text('Toka'),
                                      ),
                                    ],
                                  );
                                },
                              );
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
                                userData != null ? userData!.user.userFullName! : "",
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: mainFontColor),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Text(
                                userData != null ? "+${userData!.user.phone}" : "",
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
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CollectionsTablePage(collections: collections != null ? collections!.data : []),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              _isLoading
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Text(
                                      (userTotalData != null && userTotalData!.overallTotal.toString().isNotEmpty)
                                          ? "${NumberFormat("#,##0", "en_US").format(userTotalData!.overallTotal)}/="
                                          : "0.00",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: mainFontColor,
                                      ),
                                    ),
                              SizedBox(height: 5),
                              Text(
                                "Jumla Yote",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w100,
                                  color: black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 0.5,
                          height: 40,
                          color: black.withAlpha((0.3 * 255).round()),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CollectionsTablePage(collections: collections != null ? collections!.data : []),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              _isLoading
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Text(
                                      (userTotalData != null && userTotalData!.overallTotal.toString().isNotEmpty)
                                          ? "${NumberFormat("#,##0", "en_US").format(userTotalData!.currentYearTotal)}/="
                                          : "0.00",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: mainFontColor,
                                      ),
                                    ),
                              SizedBox(height: 5),
                              Text(
                                "Michango ya Mwaka",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w100,
                                  color: black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 0.5,
                          height: 40,
                          color: black.withAlpha((0.3 * 255).round()),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OtherCollectionsTablePage(
                                  otherCollections:
                                      otherCollectionResponse != null ? otherCollectionResponse!.data : [],
                                ),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              _isLoading
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Text(
                                      (userTotalData != null && userTotalData!.otherTotal.toString().isNotEmpty)
                                          ? "${NumberFormat("#,##0", "en_US").format(userTotalData!.otherTotal)}/="
                                          : "0.00",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: mainFontColor,
                                      ),
                                    ),
                              SizedBox(height: 5),
                              Text(
                                "Michango Mingine",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w100,
                                  color: black,
                                ),
                              ),
                            ],
                          ),
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
              padding: const EdgeInsets.only(left: 20, right: 20),
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
                          // IconBadge(
                          //   icon: const Icon(Icons.notifications_none),
                          //   itemCount: 1,
                          //   badgeColor: Colors.red,
                          //   itemColor: mainFontColor,
                          //   hideZero: true,
                          //   top: -1,
                          //   onTap: () {
                          //     if (kDebugMode) {
                          //       print('test');
                          //     }
                          //   },
                          // ),
                        ],
                      )
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainFontColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.visibility, size: 15),
                    label: const Text(
                      "Tazama Yote",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CollectionsTablePage(collections: collections != null ? collections!.data : []),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            FutureBuilder(
              future: getUserCollections(),
              builder: (context, AsyncSnapshot<CollectionResponse?> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text("Failed to load collection data."));
                } else if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
                  return const Center(child: Text("No collection data found."));
                }

                final collections = snapshot.data!.data;

                return ListView.builder(
                  itemCount: collections.length > 4 ? 4 : collections.length,
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final item = collections[index];
                    return GestureDetector(
                      onTap: () => _showCollectionDetails(context, item),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 5.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.only(left: 25, right: 25),
                                    decoration: BoxDecoration(
                                      color: white,
                                      borderRadius: BorderRadius.circular(25),
                                      boxShadow: [
                                        BoxShadow(
                                          color: grey.withAlpha((0.03 * 255).round()),
                                          spreadRadius: 10,
                                          blurRadius: 3,
                                        ),
                                      ],
                                    ),
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
                                            ),
                                            child: Center(
                                              child: Builder(
                                                builder: (context) {
                                                  // Find previous item amount if available
                                                  int currentAmount = int.tryParse(item.amount) ?? 0;
                                                  int? prevAmount;
                                                  if (index > 0) {
                                                    prevAmount = int.tryParse(collections[index - 1].amount);
                                                  }
                                                  // If no previous, show up arrow by default
                                                  if (prevAmount == null) {
                                                    return const Icon(Icons.arrow_upward_rounded, color: Colors.white);
                                                  }
                                                  if (currentAmount > prevAmount) {
                                                    return const Icon(Icons.arrow_upward_rounded, color: Colors.white);
                                                  } else if (currentAmount < prevAmount) {
                                                    return const Icon(Icons.arrow_downward_rounded,
                                                        color: Colors.white);
                                                  } else {
                                                    return const Icon(Icons.remove, color: Colors.white);
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 15),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Text(
                                                      "🗓 ",
                                                      style: TextStyle(fontSize: 15),
                                                    ),
                                                    Text(
                                                      item.monthly,
                                                      style: const TextStyle(
                                                        fontSize: 15,
                                                        color: black,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 5),
                                                Row(
                                                  children: [
                                                    const Text(
                                                      "🖊 ",
                                                      style: TextStyle(fontSize: 12),
                                                    ),
                                                    Flexible(
                                                      child: Text(
                                                        "${item.registeredDate} (${item.registeredBy})",
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: black.withAlpha((0.5 * 255).round()),
                                                          fontWeight: FontWeight.w400,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              const Text(
                                                "💰 ",
                                                style: TextStyle(fontSize: 15),
                                              ),
                                              Text(
                                                "TZS ${NumberFormat("#,##0", "en_US").format(int.parse(item.amount))}",
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: black,
                                                ),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            )
          ],
        ),
      ),
    ));
  }

  void _showCollectionDetails(BuildContext context, CollectionItem item) {
    final user = item.user;
    final year = item.churchYearEntity;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5, // 80% of screen height
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, controller) => Padding(
            padding: const EdgeInsets.all(20.0),
            child: Wrap(
              children: [
                Center(
                  child: Container(
                    height: 5,
                    width: 50,
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const Text(
                  "Maelezo ya Mchango",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text("👤 Taarifa za Mtumiaji", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text("Jina Kamili:     ${user.userFullName}"),
                    const SizedBox(height: 4),
                    Text("Simu:           ${user.phone}"),
                    const SizedBox(height: 4),
                    Text("Jina la Mtumiaji: ${user.userName}"),
                    const SizedBox(height: 4),
                    Text("Nafasi:         ${user.role}"),
                    const SizedBox(height: 12),
                    const Text("📆 Taarifa za Mwaka", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text("Mwaka:          ${year.churchYear}"),
                    Text("Uhai:           ${year.isActive ? 'Ndiyo' : 'Hapana'}"),
                    const SizedBox(height: 10),
                    Text("💰 Kiasi:        TZS ${NumberFormat("#,##0", "en_US").format(int.parse(item.amount))}"),
                    const SizedBox(height: 4),
                    Text("🗓 Mwezi:        ${item.monthly}"),
                    const SizedBox(height: 4),
                    Text("📅 Tarehe ya Usajili: ${item.registeredDate}"),
                    const SizedBox(height: 4),
                    Text("🖊 Aliyesajili:   ${item.registeredBy}"),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
