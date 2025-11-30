import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jumuiya_yangu/pages/loan_apps_user.dart';
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

  // Add loan statistics variables
  double totalLoanTaken = 0.0;
  double totalLoanRepaid = 0.0;
  double remainingLoan = 0.0;
  bool _isLoadingLoans = false;

  @override
  void initState() {
    super.initState();
    if (userData != null && currentYear != null) {
      setState(() {});
      getTotalSummary(userData!.user.id!, currentYear!.data.churchYear);
      getUserOtherCollections();
      fetchJumuiyaNames();
      _fetchLoanStatistics();
    }
  }

  Future<void> _fetchLoanStatistics() async {
    setState(() => _isLoadingLoans = true);

    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/loans/get_loans_statistics.php?user_id=${userData!.user.id}'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == "200") {
          setState(() {
            totalLoanTaken =
                double.tryParse(data['total_loan_taken'].toString()) ?? 0.0;
            totalLoanRepaid =
                double.tryParse(data['total_loan_repaid'].toString()) ?? 0.0;
            remainingLoan =
                double.tryParse(data['remaining_loan'].toString()) ?? 0.0;
            _isLoadingLoans = false;
          });
        } else {
          setState(() {
            _isLoadingLoans = false;
          });
        }
      } else {
        setState(() {
          _isLoadingLoans = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingLoans = false;
      });
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text("⚠️ Imeshindikana kupata taarifa za mikopo"),
          ),
        );
      }
    }
  }

  Future<void> reloadData() async {
    await getUserCollections();
    if (userData != null && currentYear != null) {
      getTotalSummary(userData!.user.id!, currentYear!.data.churchYear);
    }
    fetchJumuiyaNames();
    _fetchLoanStatistics();
    setState(() {});
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
            backgroundColor: Colors.yellow,
            content: Text(
              "⚠️ Tafadhali hakikisha umeunganishwa na intaneti",
              style: TextStyle(
                color: Colors.black,
              ),
            ),
          ),
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
          backgroundColor: Colors.yellow,
          content: Text(
            "⚠️ Tafadhali hakikisha umeunganishwa na intaneti",
            style: TextStyle(
              color: Colors.black,
            ),
          ),
        ),
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
            content: Text(
              "⚠️ Tafadhali hakikisha umeunganishwa na intaneti",
            ),
          ),
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
            backgroundColor: Colors.yellow,
            content: Text(
              "⚠️ Tafadhali hakikisha umeunganishwa na intaneti",
              style: TextStyle(
                color: Colors.black,
              ),
            ),
          ),
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

  void _navigateToLoanAppsUserPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoanAppsUserPage(),
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

  // Updated stat card with smaller, more elegant design
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
          vertical: isSmall ? 10 : 12,
          horizontal: isSmall ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: isSmall ? 16 : 18,
            ),
            SizedBox(height: 6),
            if (value == null)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              Text(
                value,
                style: TextStyle(
                  fontSize: isSmall ? 9 : 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: isSmall ? 7 : 8,
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

  // New widget for loan statistics card
  Widget _buildLoanStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isSmall,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 10 : 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmall ? 9 : 10,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmall ? 13 : 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
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
              // Compact Header
              Container(
                margin: EdgeInsets.symmetric(
                  horizontal: size.width * 0.05,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userData!.user.jina_jumuiya ?? 'Hujambo 👋',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 20,
                              fontWeight: FontWeight.bold,
                              color: mainFontColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 11,
                                color: Colors.grey[500],
                              ),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  DateFormat('EEE, MMM d')
                                      .format(DateTime.now()),
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 10 : 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.08),
                            spreadRadius: 1,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert_rounded,
                            color: mainFontColor, size: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 8,
                        onSelected: (value) {
                          if (value == 'logout') {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  title: Row(
                                    children: [
                                      Icon(Icons.logout_rounded,
                                          color: Colors.red[400], size: 20),
                                      SizedBox(width: 8),
                                      Text('Toka',
                                          style: TextStyle(fontSize: 16)),
                                    ],
                                  ),
                                  content: const Text(
                                      'Una uhakika unataka kutoka?',
                                      style: TextStyle(fontSize: 14)),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: Text('Hapana',
                                          style: TextStyle(
                                              color: Colors.grey[600])),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red[400],
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
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
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))
                                  else
                                    Icon(Icons.swap_horizontal_circle_rounded,
                                        color: mainFontColor, size: 16),
                                  SizedBox(width: 10),
                                  Text('Badilisha Jumuiya',
                                      style: TextStyle(
                                          color: mainFontColor, fontSize: 13)),
                                ],
                              ),
                            ),
                          PopupMenuItem<String>(
                            value: 'logout',
                            child: Row(
                              children: [
                                if (_isLoading)
                                  SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                else
                                  Icon(Icons.logout_rounded,
                                      color: Colors.red[400], size: 16),
                                SizedBox(width: 10),
                                Text('Toka',
                                    style: TextStyle(
                                        color: Colors.red[400], fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Modern Compact Profile Card
              Container(
                margin: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      mainFontColor,
                      mainFontColor.withValues(alpha: 0.85)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: mainFontColor.withValues(alpha: 0.25),
                      spreadRadius: 0,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(isMediumScreen ? 16 : 18),
                  child: Column(
                    children: [
                      // Compact Year Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_month_rounded,
                                    color: Colors.white, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  currentYear != null
                                      ? currentYear!.data.churchYear
                                      : "N/A",
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 10 : 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.verified_user_rounded,
                                color: Colors.white, size: 15),
                          ),
                        ],
                      ),

                      SizedBox(height: 8),

                      // User Info - Compact
                      Column(
                        children: [
                          Text(
                            userData != null
                                ? userData!.user.userFullName!
                                : "Mtumiaji",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 15 : 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.phone_rounded,
                                    color: Colors.white, size: 11),
                                SizedBox(width: 4),
                                Text(
                                  userData != null
                                      ? "+${userData!.user.phone}"
                                      : "",
                                  style: TextStyle(
                                      fontSize: isSmallScreen ? 10 : 11,
                                      color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 10),

                      // Compact Statistics Grid
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              icon: Icons.account_balance_wallet_rounded,
                              label: "Jumla",
                              value: _isLoading
                                  ? null
                                  : (userTotalData != null)
                                      ? "${NumberFormat.compact().format(userTotalData!.overallTotal)}/="
                                      : "0",
                              onTap: () => _navigateToCollections(),
                              isSmall: isSmallScreen,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              icon: Icons.trending_up_rounded,
                              label: "Mwaka",
                              value: _isLoading
                                  ? null
                                  : (userTotalData != null)
                                      ? "${NumberFormat.compact().format(userTotalData!.currentYearTotal)}/="
                                      : "0",
                              onTap: () => _navigateToCollections(),
                              isSmall: isSmallScreen,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              icon: Icons.category_rounded,
                              label: "Mengine",
                              value: _isLoading
                                  ? null
                                  : (userTotalData != null)
                                      ? "${NumberFormat.compact().format(userTotalData!.otherTotal)}/="
                                      : "0",
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

              SizedBox(height: 16),

              // Michango Section - Compact Header
              Container(
                margin: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: mainFontColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.savings_rounded,
                              color: mainFontColor, size: 15),
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Michango",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 14 : 16,
                            color: mainFontColor,
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: mainFontColor,
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      icon: Icon(Icons.arrow_forward_rounded, size: 14),
                      label: Text("Yote",
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                      onPressed: () => _navigateToCollections(),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 10),

              // Collections List
              FutureBuilder(
                future: getUserCollections(),
                builder:
                    (context, AsyncSnapshot<CollectionResponse?> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      margin:
                          EdgeInsets.symmetric(horizontal: size.width * 0.05),
                      height: 120,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    mainFontColor),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text("Inapakia...",
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Container(
                      margin:
                          EdgeInsets.symmetric(horizontal: size.width * 0.05),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded,
                              color: Colors.red[400], size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Imeshindikana kupakia",
                              style: TextStyle(
                                  color: Colors.red[700], fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
                    return Container(
                      margin:
                          EdgeInsets.symmetric(horizontal: size.width * 0.05),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.inbox_rounded,
                              color: Colors.grey[400], size: 32),
                          SizedBox(height: 8),
                          Text(
                            "Hakuna michango",
                            style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
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
                              horizontal: size.width * 0.05, vertical: 10),
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: mainFontColor,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                    color:
                                        mainFontColor.withValues(alpha: 0.3)),
                              ),
                            ),
                            icon: Icon(Icons.expand_more_rounded, size: 16),
                            label: Text("+${collections.length - 4} zaidi",
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600)),
                            onPressed: () => _navigateToCollections(),
                          ),
                        ),
                    ],
                  );
                },
              ),

              SizedBox(height: 20),

              // Loan Statistics Section - NEW & IMPROVED
              Container(
                margin: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.account_balance_rounded,
                                  color: Colors.orange[700], size: 15),
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Mikopo",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallScreen ? 14 : 16,
                                color: mainFontColor,
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: mainFontColor,
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                          ),
                          icon: Icon(Icons.arrow_forward_rounded, size: 14),
                          label: Text(
                            "Yote",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: _navigateToLoanAppsUserPage,
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    if (_isLoadingLoans)
                      SizedBox(
                        height: 120,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(mainFontColor),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildLoanStatCard(
                                  icon: Icons.arrow_upward_rounded,
                                  label: "Uliochukuliwa",
                                  value:
                                      "TZS ${NumberFormat.compact().format(totalLoanTaken)}",
                                  color: Colors.blue[700]!,
                                  isSmall: isSmallScreen,
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: _buildLoanStatCard(
                                  icon: Icons.arrow_downward_rounded,
                                  label: "Umerudisha",
                                  value:
                                      "TZS ${NumberFormat.compact().format(totalLoanRepaid)}",
                                  color: Colors.green[700]!,
                                  isSmall: isSmallScreen,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  mainFontColor,
                                  mainFontColor.withValues(alpha: 0.85)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withValues(alpha: 0.3),
                                  spreadRadius: 0,
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.pending_actions_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "Mkopo Uliobaki",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isSmallScreen ? 11 : 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  "TZS ${NumberFormat.compact().format(remainingLoan)}",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isSmallScreen ? 14 : 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              SizedBox(height: 16),
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
          bottom: 8,
        ),
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              spreadRadius: 0,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
          child: Row(
            children: [
              // Compact Trend Indicator
              Container(
                width: isSmallScreen ? 34 : 38,
                height: isSmallScreen ? 34 : 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _getTrendColors(item, index, collections),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    _getTrendIconData(item, index, collections),
                    color: Colors.white,
                    size: isSmallScreen ? 16 : 18,
                  ),
                ),
              ),

              SizedBox(width: 10),

              // Collection Info - Compact
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.calendar_month_rounded,
                                  size: isSmallScreen ? 12 : 13,
                                  color: mainFontColor.withValues(alpha: 0.7)),
                              SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  item.monthly,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 12 : 13,
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
                              EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: mainFontColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "${NumberFormat.compact().format(int.parse(item.amount))}/=",
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                              fontWeight: FontWeight.bold,
                              color: mainFontColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded,
                            size: isSmallScreen ? 10 : 11,
                            color: Colors.grey[500]),
                        SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            "${item.registeredDate} • ${item.registeredBy}",
                            style: TextStyle(
                              fontSize: isSmallScreen ? 9 : 10,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Icon(Icons.chevron_right_rounded,
                  color: Colors.grey[300], size: 18),
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

  IconData _getTrendIconData(
      CollectionItem item, int index, List<CollectionItem> collections) {
    int currentAmount = int.tryParse(item.amount) ?? 0;
    int? prevAmount;
    if (index > 0) {
      prevAmount = int.tryParse(collections[index - 1].amount);
    }

    if (prevAmount == null) {
      return Icons.trending_up_rounded;
    } else if (currentAmount > prevAmount) {
      return Icons.trending_up_rounded;
    } else if (currentAmount < prevAmount) {
      return Icons.trending_down_rounded;
    } else {
      return Icons.trending_flat_rounded;
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
