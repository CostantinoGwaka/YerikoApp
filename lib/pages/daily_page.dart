import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';
import 'package:jumuiya_yangu/main.dart';
import 'package:jumuiya_yangu/models/auth_model.dart';
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
import 'package:restart_app/restart_app.dart';

class DailyPage extends StatefulWidget {
  const DailyPage({super.key});

  @override
  State<DailyPage> createState() => _DailyPageState();
}

class _DailyPageState extends State<DailyPage> {
  bool _isLoading = false;
  bool _isLoadingJumuiya = false;
  UserTotalsResponse? userTotalData;
  CollectionResponse? collections;
  OtherCollectionResponse? otherCollectionResponse;
  List<Map<String, dynamic>> jumuiyaData = [];
  // UserCollectionResponse userCollectionData;

  @override
  void initState() {
    super.initState();
    if (userData != null && currentYear != null) {
      setState(() {});
      getTotalSummary(userData!.user.id!, currentYear!.data.churchYear);
      getUserOtherCollections();
      fetchJumuiyaNames();
    }
  }

  Future<void> reloadData() async {
    await getUserCollections();
    if (userData != null && currentYear != null) {
      getTotalSummary(userData!.user.id!, currentYear!.data.churchYear);
    }
    // Refresh jumuiya names as well
    fetchJumuiyaNames();
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
        const SnackBar(
            backgroundColor: Colors.green,
            content: Text("✅ Umefanikiwa! Umetoka kwenye mfumo.")),
      );
    });
  }

  Future<void> fetchJumuiyaNames() async {
    try {
      final response = await http.post(
          headers: {'Accept': 'application/json'},
          Uri.parse('$baseUrl/auth/get_my_jumuiya.php'),
          body: jsonEncode({
            "user_id": userData!.user.id.toString(),
          }));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == "200" && data['data'] != null) {
          setState(() {
            jumuiyaData = (data['data'] as List)
                .map((item) => {
                      'name': item['name'] as String,
                      'id': item['id'] as dynamic,
                    })
                .toList();
          });
        }
      }
    } catch (e) {
      // Handle error silently or show message
      if (kDebugMode) {
        print('Error fetching jumuiya data');
      }
    }
  }

  Future<void> switchJumuiya(dynamic jumuiyaId, String jumuiyaName) async {
    try {
      setState(() {
        _isLoadingJumuiya = true;
      });

      // Locally update user jumuiya info without API call
      final updatedUser = User(
        id: userData!.user.id,
        phone: userData!.user.phone,
        userFullName: userData!.user.userFullName,
        yearRegistered: userData!.user.yearRegistered,
        createdAt: userData!.user.createdAt,
        userName: userData!.user.userName,
        location: userData!.user.location,
        gender: userData!.user.gender,
        dobdate: userData!.user.dobdate,
        martialstatus: userData!.user.martialstatus,
        role: userData!.user.role,
        jina_jumuiya: jumuiyaName,
        jumuiya_id: jumuiyaId,
      );

      userData = LoginResponse(
        status: userData!.status,
        message: userData!.message,
        user: updatedUser,
      );

      // Save updated user data to local storage
      String updatedUserJson = jsonEncode(userData!.toJson());
      await LocalStorage.setStringItem("user_data", updatedUserJson);

      setState(() {
        _isLoadingJumuiya = false;
      });

      // Refresh data for new jumuiya
      reloadData();
      Restart.restartApp(
        notificationTitle: 'Jumuiya Yangu',
        notificationBody: 'Tafadhali gusa hapa kufungua programu tena.',
      );

      // Show success message
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: Colors.green,
              content: Text("✅ Umebadilishwa kwa jumuiya: $jumuiyaName")),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingJumuiya = false;
      });
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: Colors.red,
              content:
                  Text("⚠️ Tafadhali hakikisha umeunganishwa na intaneti")),
        );
      }
    }
  }

  void _showJumuiyaSwitchDialog() {
    if (jumuiyaData.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: Colors.red,
            content: Text("⚠️ Huna jumuiya zaidi ya moja za kubadilishia")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.swap_horizontal_circle_rounded, color: mainFontColor),
              SizedBox(width: 8),
              Text('Badilisha Jumuiya'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chagua jumuiya unayotaka kubadilisha:'),
              SizedBox(height: 16),
              ...jumuiyaData.map(
                (jumuiyaItem) {
                  final jumuiyaName = jumuiyaItem['name'] as String;
                  final jumuiyaId = jumuiyaItem['id'];
                  final isCurrentJumuiya =
                      userData!.user.jina_jumuiya == jumuiyaName;

                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        Icons.group_rounded,
                        color: isCurrentJumuiya ? mainFontColor : Colors.grey,
                      ),
                      title: Text(
                        jumuiyaName,
                        style: TextStyle(
                          fontWeight: isCurrentJumuiya
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color:
                              isCurrentJumuiya ? mainFontColor : Colors.black87,
                        ),
                      ),
                      trailing: isCurrentJumuiya
                          ? Icon(Icons.check_circle, color: mainFontColor)
                          : null,
                      onTap: isCurrentJumuiya
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              // Show confirmation dialog before switching
                              showDialog(
                                context: context,
                                builder: (BuildContext confirmContext) {
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    title: Row(
                                      children: [
                                        Icon(Icons.warning_rounded,
                                            color: Colors.orange[400]),
                                        SizedBox(width: 8),
                                        Text('Thibitisha'),
                                      ],
                                    ),
                                    content: Text(
                                        'Una uhakika unataka kubadilisha hadi jumuiya "$jumuiyaName"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(confirmContext).pop(),
                                        child: Text(
                                          'Hapana',
                                          style: TextStyle(
                                              color: Colors.grey[600]),
                                        ),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: mainFontColor,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.of(confirmContext).pop();
                                          switchJumuiya(jumuiyaId, jumuiyaName);
                                        },
                                        child: const Text('Ndiyo'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Funga',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<dynamic> getTotalSummary(int userId, String year) async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (userId.toString().isEmpty || year == "" || year.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: Colors.red,
              content: Text("⚠️ Tafadhali hakikisha umeweka User ID na mwaka")),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      } else {
        String myApi =
            "$baseUrl/monthly/get_total_by_user_statistics.php?userId=$userId&year=$year&jumuiya_id=${userData!.user.jumuiya_id}";
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
            SnackBar(
                backgroundColor: Colors.red,
                content: Text(jsonResponse['message'])),
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
        SnackBar(
            backgroundColor: Colors.red,
            content: Text("⚠️ Tafadhali hakikisha umeunganishwa na intaneti")),
      );
    }
  }

  Future<CollectionResponse?> getUserCollections() async {
    try {
      if (userData?.user.id == null || userData!.user.id.toString().isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                backgroundColor: Colors.red,
                content:
                    Text("⚠️ Hakuna taarifa zaidi kuwezesha kupata taarifa")),
          );
        }
        // setState(() => _isLoading = false);
        return null;
      }

      final String myApi =
          "$baseUrl/monthly/get_collection_by_user_id.php?user_id=${userData!.user.id}&jumuiya_id=${userData!.user.jumuiya_id}";
      final response = await http
          .get(Uri.parse(myApi), headers: {'Accept': 'application/json'});

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
            SnackBar(
                backgroundColor: Colors.red,
                content: Text("Error: ${response.statusCode}")),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: Colors.red,
              content:
                  Text("⚠️ Tafadhali hakikisha umeunganishwa na intaneti")),
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
            const SnackBar(
                backgroundColor: Colors.red,
                content:
                    Text("⚠️ Hakuna taarifa zaidi kuwezesha kupata taarifa")),
          );
        }
        // setState(() => _isLoading = false);
        return null;
      }

      final String myApi =
          "$baseUrl/monthly/get_all_other_collection_by_user.php?userId=${userData!.user.id}&jumuiyaId=${userData!.user.jumuiya_id}";
      final response = await http
          .get(Uri.parse(myApi), headers: {'Accept': 'application/json'});

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse != null) {
          // setState(() => _isLoading = false);
          otherCollectionResponse =
              OtherCollectionResponse.fromJson(jsonResponse);
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
          SnackBar(
              backgroundColor: Colors.red,
              content:
                  Text("⚠️ Tafadhali hakikisha umeunganishwa na intaneti")),
        );
      }
    }

    // 🔁 Always return something to complete Future
    return null;
  }

  // Helper methods for navigation
  void _navigateToCollections() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CollectionsTablePage(
            collections: collections != null ? collections!.data : []),
      ),
    );
  }

  void _navigateToOtherCollections() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtherCollectionsTablePage(
          otherCollections: otherCollectionResponse != null
              ? otherCollectionResponse!.data
              : [],
        ),
      ),
    );
  }

  // Helper widget for stat cards
  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String? value,
    required VoidCallback onTap,
    required bool isSmall,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isSmall ? 12 : 16,
          horizontal: isSmall ? 8 : 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: isSmall ? 20 : 24,
            ),
            SizedBox(height: 8),
            if (value == null)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              Text(
                value,
                style: TextStyle(
                  fontSize: isSmall ? 10 : 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: isSmall ? 8 : 10,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;
    final isMediumScreen = size.width < 600;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: reloadData,
        color: mainFontColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with date and greeting
              Container(
                margin: EdgeInsets.symmetric(
                  horizontal: size.width * 0.05,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userData!.user.jina_jumuiya ?? 'Hujambo 👋',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 24,
                            fontWeight: FontWeight.bold,
                            color: mainFontColor,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 6),
                            Text(
                              DateFormat('EEEE, MMM d, yyyy')
                                  .format(DateTime.now()),
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: isSmallScreen ? 12 : 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
                            spreadRadius: 1,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: mainFontColor,
                          size: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 8,
                        onSelected: (value) {
                          if (value == 'logout') {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: Row(
                                    children: [
                                      Icon(Icons.logout_rounded,
                                          color: Colors.red[400]),
                                      SizedBox(width: 8),
                                      Text('Toka'),
                                    ],
                                  ),
                                  content:
                                      const Text('Una uhakika unataka kutoka?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: Text(
                                        'Hapana',
                                        style:
                                            TextStyle(color: Colors.grey[600]),
                                      ),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red[400],
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        logout(context);
                                      },
                                      child: const Text('Ndiyo'),
                                    ),
                                  ],
                                );
                              },
                            );
                          } else if (value == 'switch_jumuiya') {
                            _showJumuiyaSwitchDialog();
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          // Switch Jumuiya option - only show if user has 2 or more jumuiya
                          if (jumuiyaData.length >= 2)
                            PopupMenuItem<String>(
                              value: 'switch_jumuiya',
                              child: Row(
                                children: [
                                  if (_isLoadingJumuiya)
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  else
                                    Icon(
                                      Icons.swap_horizontal_circle_rounded,
                                      color: mainFontColor,
                                      size: 18,
                                    ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Badilisha Jumuiya',
                                    style: TextStyle(
                                      color: mainFontColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          PopupMenuItem<String>(
                            value: 'logout',
                            child: Row(
                              children: [
                                if (_isLoading)
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                else
                                  Icon(
                                    Icons.logout_rounded,
                                    color: Colors.red[400],
                                    size: 18,
                                  ),
                                SizedBox(width: 12),
                                Text(
                                  'Toka',
                                  style: TextStyle(
                                    color: Colors.red[400],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Profile Card
              Container(
                margin: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      mainFontColor,
                      mainFontColor.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: mainFontColor.withValues(alpha: 0.3),
                      spreadRadius: 1,
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(isMediumScreen ? 20 : 24),
                  child: Column(
                    children: [
                      // Year and Status Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_month_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  currentYear != null
                                      ? currentYear!.data.churchYear
                                      : "Hakuna Mwaka",
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 12 : 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.verified_user_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 10),

                      // Profile Info
                      Column(
                        children: [
                          SizedBox(height: 2),
                          Text(
                            userData != null
                                ? userData!.user.userFullName!
                                : "Mtumiaji",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 18 : 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.phone_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  userData != null
                                      ? "+${userData!.user.phone}"
                                      : "",
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 12 : 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 10),

                      // Statistics Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              icon: Icons.account_balance_wallet_rounded,
                              label: "Jumla Yote",
                              value: _isLoading
                                  ? null
                                  : (userTotalData != null &&
                                          userTotalData!.overallTotal
                                              .toString()
                                              .isNotEmpty)
                                      ? "${NumberFormat("#,##0", "en_US").format(userTotalData!.overallTotal)}/="
                                      : "0.00",
                              onTap: () => _navigateToCollections(),
                              isSmall: isSmallScreen,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              icon: Icons.trending_up_rounded,
                              label: "Mwaka Huu",
                              value: _isLoading
                                  ? null
                                  : (userTotalData != null &&
                                          userTotalData!.currentYearTotal
                                              .toString()
                                              .isNotEmpty)
                                      ? "${NumberFormat("#,##0", "en_US").format(userTotalData!.currentYearTotal)}/="
                                      : "0.00",
                              onTap: () => _navigateToCollections(),
                              isSmall: isSmallScreen,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              icon: Icons.category_rounded,
                              label: "Mengine",
                              value: _isLoading
                                  ? null
                                  : (userTotalData != null &&
                                          userTotalData!.otherTotal
                                              .toString()
                                              .isNotEmpty)
                                      ? "${NumberFormat("#,##0", "en_US").format(userTotalData!.otherTotal)}/="
                                      : "0.00",
                              onTap: () => _navigateToOtherCollections(),
                              isSmall: isSmallScreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Loans Section
              Container(
                margin: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: mainFontColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.savings_rounded,
                            color: mainFontColor,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Mikopo",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 18 : 22,
                            color: mainFontColor,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainFontColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12 : 16,
                          vertical: isSmallScreen ? 8 : 10,
                        ),
                        elevation: 3,
                      ),
                      icon: Icon(
                        Icons.visibility_rounded,
                        size: isSmallScreen ? 14 : 16,
                      ),
                      label: Text(
                        "Tazama Yote",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                      ),
                      onPressed: () => _navigateToCollections(),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),
              // Collections List
              FutureBuilder(
                future: getUserCollections(),
                builder:
                    (context, AsyncSnapshot<CollectionResponse?> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      margin:
                          EdgeInsets.symmetric(horizontal: size.width * 0.05),
                      height: 200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(mainFontColor),
                            ),
                            SizedBox(height: 16),
                            Text(
                              "Inatafuta michango...",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Container(
                      margin:
                          EdgeInsets.symmetric(horizontal: size.width * 0.05),
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: Colors.red[400],
                            size: 32,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Imeshindikana kupakia michango",
                            style: TextStyle(
                              color: Colors.red[700],
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
                    return Container(
                      margin:
                          EdgeInsets.symmetric(horizontal: size.width * 0.05),
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_rounded,
                            color: Colors.grey[400],
                            size: 48,
                          ),
                          SizedBox(height: 12),
                          Text(
                            "Hakuna michango iliyopatikana",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Michango itaonekana hapa baada ya kuongezwa",
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  final collections = snapshot.data!.data;
                  final displayCount =
                      collections.length > 4 ? 4 : collections.length;

                  return Column(
                    children: [
                      ListView.builder(
                        itemCount: displayCount,
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final item = collections[index];
                          return _buildCollectionCard(
                              context, item, index, collections, isSmallScreen);
                        },
                      ),
                      if (collections.length > 4)
                        Container(
                          margin: EdgeInsets.symmetric(
                              horizontal: size.width * 0.05, vertical: 16),
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: mainFontColor,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                    color:
                                        mainFontColor.withValues(alpha: 0.3)),
                              ),
                            ),
                            icon: Icon(Icons.expand_more_rounded),
                            label: Text(
                              "Tazama zaidi (${collections.length - 4})",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            onPressed: () => _navigateToCollections(),
                          ),
                        ),
                    ],
                  );
                },
              ),

              // Collections List

              SizedBox(height: isSmallScreen ? 16 : 24),

              // Collections Section
              Container(
                margin: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: mainFontColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.savings_rounded,
                            color: mainFontColor,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Michango",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 18 : 22,
                            color: mainFontColor,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainFontColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12 : 16,
                          vertical: isSmallScreen ? 8 : 10,
                        ),
                        elevation: 3,
                      ),
                      icon: Icon(
                        Icons.visibility_rounded,
                        size: isSmallScreen ? 14 : 16,
                      ),
                      label: Text(
                        "Tazama Yote",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                      ),
                      onPressed: () => _navigateToCollections(),
                    ),
                  ],
                ),
              ),

              SizedBox(height: isSmallScreen ? 12 : 16),

              // Collections List
              FutureBuilder(
                future: getUserCollections(),
                builder:
                    (context, AsyncSnapshot<CollectionResponse?> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      margin:
                          EdgeInsets.symmetric(horizontal: size.width * 0.05),
                      height: 200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(mainFontColor),
                            ),
                            SizedBox(height: 16),
                            Text(
                              "Inatafuta michango...",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Container(
                      margin:
                          EdgeInsets.symmetric(horizontal: size.width * 0.05),
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: Colors.red[400],
                            size: 32,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Imeshindikana kupakia michango",
                            style: TextStyle(
                              color: Colors.red[700],
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
                    return Container(
                      margin:
                          EdgeInsets.symmetric(horizontal: size.width * 0.05),
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_rounded,
                            color: Colors.grey[400],
                            size: 48,
                          ),
                          SizedBox(height: 12),
                          Text(
                            "Hakuna michango iliyopatikana",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Michango itaonekana hapa baada ya kuongezwa",
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  final collections = snapshot.data!.data;
                  final displayCount =
                      collections.length > 4 ? 4 : collections.length;

                  return Column(
                    children: [
                      ListView.builder(
                        itemCount: displayCount,
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final item = collections[index];
                          return _buildCollectionCard(
                              context, item, index, collections, isSmallScreen);
                        },
                      ),
                      if (collections.length > 4)
                        Container(
                          margin: EdgeInsets.symmetric(
                              horizontal: size.width * 0.05, vertical: 16),
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: mainFontColor,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                    color:
                                        mainFontColor.withValues(alpha: 0.3)),
                              ),
                            ),
                            icon: Icon(Icons.expand_more_rounded),
                            label: Text(
                              "Tazama zaidi (${collections.length - 4})",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            onPressed: () => _navigateToCollections(),
                          ),
                        ),
                    ],
                  );
                },
              ),

              SizedBox(height: isSmallScreen ? 12 : 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollectionCard(BuildContext context, CollectionItem item,
      int index, List<CollectionItem> collections, bool isSmallScreen) {
    return GestureDetector(
      onTap: () => _showCollectionDetails(context, item),
      child: Container(
        margin: EdgeInsets.only(
          left: MediaQuery.of(context).size.width * 0.05,
          right: MediaQuery.of(context).size.width * 0.05,
          bottom: 12,
        ),
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          child: Row(
            children: [
              // Trend indicator
              Container(
                width: isSmallScreen ? 40 : 48,
                height: isSmallScreen ? 40 : 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _getTrendColors(item, index, collections),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: _getTrendIcon(item, index, collections),
                ),
              ),

              SizedBox(width: 12),

              // Collection info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month and amount row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                size: isSmallScreen ? 14 : 16,
                                color: mainFontColor,
                              ),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  item.monthly,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    color: mainFontColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: mainFontColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "TZS ${NumberFormat("#,##0", "en_US").format(int.parse(item.amount))}",
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              fontWeight: FontWeight.bold,
                              color: mainFontColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 8),

                    // Registration info
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: isSmallScreen ? 12 : 14,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            "${item.registeredDate} • ${item.registeredBy}",
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10 : 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow indicator
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getTrendColors(
      CollectionItem item, int index, List<CollectionItem> collections) {
    int currentAmount = int.tryParse(item.amount) ?? 0;
    int? prevAmount;
    if (index > 0) {
      prevAmount = int.tryParse(collections[index - 1].amount);
    }

    if (prevAmount == null || currentAmount >= prevAmount) {
      return [Colors.green[400]!, Colors.green[600]!];
    } else {
      return [Colors.orange[400]!, Colors.orange[600]!];
    }
  }

  Widget _getTrendIcon(
      CollectionItem item, int index, List<CollectionItem> collections) {
    int currentAmount = int.tryParse(item.amount) ?? 0;
    int? prevAmount;
    if (index > 0) {
      prevAmount = int.tryParse(collections[index - 1].amount);
    }

    if (prevAmount == null) {
      return Icon(Icons.trending_up_rounded, color: Colors.white, size: 20);
    } else if (currentAmount > prevAmount) {
      return Icon(Icons.trending_up_rounded, color: Colors.white, size: 20);
    } else if (currentAmount < prevAmount) {
      return Icon(Icons.trending_down_rounded, color: Colors.white, size: 20);
    } else {
      return Icon(Icons.trending_flat_rounded, color: Colors.white, size: 20);
    }
  }
}

void _showCollectionDetails(BuildContext context, CollectionItem item) {
  final user = item.user;
  final year = item.churchYearEntity;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
        ),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (_, controller) => Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    height: 4,
                    width: 50,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Header
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: mainFontColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: mainFontColor,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      "Maelezo ya Mchango",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: mainFontColor,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24),

                // Amount highlight
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        mainFontColor.withValues(alpha: 0.1),
                        mainFontColor.withValues(alpha: 0.05)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Kiasi cha Mchango",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "TZS ${NumberFormat("#,##0", "en_US").format(int.parse(item.amount))}",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: mainFontColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Mwezi: ${item.monthly}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Details sections
                Expanded(
                  child: ListView(
                    controller: controller,
                    children: [
                      _buildDetailSection(
                        icon: Icons.person_rounded,
                        title: "Taarifa za Mtumiaji",
                        items: [
                          _buildDetailItem("Jina Kamili",
                              user.userFullName ?? "Hakijapatikana"),
                          _buildDetailItem("Namba ya Simu", "+${user.phone}"),
                          _buildDetailItem("Jina la Mtumiaji",
                              user.userName ?? "Hakijapatikana"),
                          _buildDetailItem(
                              "Nafasi", user.role ?? "Hakijapatikana"),
                        ],
                      ),
                      SizedBox(height: 20),
                      _buildDetailSection(
                        icon: Icons.calendar_month_rounded,
                        title: "Taarifa za Mwaka",
                        items: [
                          _buildDetailItem("Mwaka wa Kanisa", year.churchYear),
                          _buildDetailItem("Hali ya Mwaka",
                              year.isActive ? 'Hai' : 'Hauhai'),
                        ],
                      ),
                      SizedBox(height: 20),
                      _buildDetailSection(
                        icon: Icons.info_rounded,
                        title: "Maelezo ya Usajili",
                        items: [
                          _buildDetailItem(
                              "Tarehe ya Usajili", item.registeredDate),
                          _buildDetailItem("Alisajiliwa na", item.registeredBy),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildDetailSection({
  required IconData icon,
  required String title,
  required List<Widget> items,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, color: mainFontColor, size: 20),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: mainFontColor,
            ),
          ),
        ],
      ),
      SizedBox(height: 12),
      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: items,
        ),
      ),
    ],
  );
}

Widget _buildDetailItem(String label, String value) {
  return Padding(
    padding: EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            "$label:",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
