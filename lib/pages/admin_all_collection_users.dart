// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jumuiya_yangu/main.dart';
import 'package:jumuiya_yangu/models/auth_model.dart';
import 'package:jumuiya_yangu/models/user_collection_model.dart';
import 'package:jumuiya_yangu/models/user_collection_table_model.dart';
import 'package:jumuiya_yangu/models/user_trials_number_response.dart';
import 'package:jumuiya_yangu/pages/add_pages/add_month_collection.dart';
import 'package:jumuiya_yangu/pages/add_pages/add_other_month_collection.dart';
import 'package:jumuiya_yangu/pages/admin_all_other_collection_users.dart';
import 'package:jumuiya_yangu/pages/supports_pages/collection_table_against_month.dart';
import 'package:jumuiya_yangu/pages/user_features_payment_page.dart';
import 'package:jumuiya_yangu/theme/colors.dart';
import 'package:jumuiya_yangu/utils/url.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class AdminAllUserCollections extends StatefulWidget {
  const AdminAllUserCollections({super.key});

  @override
  State<AdminAllUserCollections> createState() =>
      _AdminAllUserCollectionsState();
}

class _AdminAllUserCollectionsState extends State<AdminAllUserCollections> {
  // Add new state variables
  bool isPremiumUser = false;
  bool showPremiumDialog = false;

  CollectionResponse? collectionsMonthly;
  UserTrialsNumberResponse? userTrialsNumber;
  CollectionResponse? collectionsOthers;
  UserMonthlyCollectionResponse? userMonthlyCollectionResponse;
  int selectedTabIndex = 0;
  bool viewTable = false;
  bool isLoading = false;
  bool showUserCollections = false;
  bool isDataLoaded = false;

  // Totals
  double totalMonthlyCollections = 0.0;
  double totalOtherCollections = 0.0;

  //month
  String filterOption = 'TAARIFA ZOTE';
  User? selectedUser;
  String? selectedMonth;

  List<String> filterOptions = [
    'TAARIFA ZOTE',
    'TAARIFA KWA MWANAJUMUIYA',
    'KWA MWEZI',
    'MICHANGO YOTE YA MWANAJUMUIYA'
  ];
  List<User> users = []; // replace with real User objects
  List<String> months = [
    'JANUARY',
    'FEBRUARY',
    'MARCH',
    'APRIL',
    'MAY',
    'JUNE',
    'JULY',
    'AUGUST',
    'SEPTEMBER',
    'OCTOBER',
    'NOVEMBER',
    'DECEMBER'
  ];

  List<dynamic> allData = []; // replace with your actual data
  List<dynamic> displayedData = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    setState(() {
      isPremiumUser = false; // Default to false for testing
    });
  }

  Future<void> _loadInitialData() async {
    setState(() {
      isDataLoaded = false;
    });

    await Future.wait([
      getUserCollections(),
      getOtherUserCollections(),
      fetchUsers(),
      getUserTrialsNumber()
    ]);

    setState(() {
      isDataLoaded = true;
    });
  }

  Future<void> getOtherUserCollections() async {
    try {
      if (userData?.user.id == null || userData!.user.id.toString().isEmpty) {
        return;
      }

      final String myApi =
          "$baseUrl/monthly/get_all_other_collection_user_by_year.php?yearId=${currentYear!.data.id}&jumuiya_id=${userData!.user.jumuiya_id}";
      final response = await http
          .get(Uri.parse(myApi), headers: {'Accept': 'application/json'});

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse != null) {
          collectionsOthers = CollectionResponse.fromJson(jsonResponse);
          calculateTotals();
        }
      }
    } catch (e) {
      // Handle error silently

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

  void calculateTotals() {
    totalMonthlyCollections = 0.0;
    totalOtherCollections = 0.0;

    if (collectionsMonthly?.data != null) {
      for (var item in collectionsMonthly!.data) {
        totalMonthlyCollections += double.tryParse(item.amount) ?? 0.0;
      }
    }

    if (collectionsOthers?.data != null) {
      for (var item in collectionsOthers!.data) {
        totalOtherCollections += double.tryParse(item.amount) ?? 0.0;
      }
    }

    setState(() {});
  }

  double _calculateUserMonthlyTotal() {
    if (collectionsMonthly?.data == null) return 0.0;
    double total = 0.0;
    for (var item in collectionsMonthly!.data) {
      total += double.tryParse(item.amount) ?? 0.0;
    }
    return total;
  }

  double _calculateUserOtherTotal() {
    if (collectionsOthers?.data == null) return 0.0;
    double total = 0.0;
    for (var item in collectionsOthers!.data) {
      total += double.tryParse(item.amount) ?? 0.0;
    }
    return total;
  }

  Future<void> fetchUsers() async {
    final response = await http.get(Uri.parse(
        '$baseUrl/auth/get_all_users.php?jumuiya_id=${userData!.user.jumuiya_id}'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        users = (data['data'] as List).map((u) => User.fromJson(u)).toList()
          ..sort(
              (a, b) => (a.userFullName ?? '').compareTo(b.userFullName ?? ''));
      });
    } else {
      // handle error
    }
  }

  void loadData() async {
    setState(() {
      showUserCollections = false;
      isDataLoaded = false;
    });

    if (filterOption == 'TAARIFA ZOTE') {
      await getUserCollections();
    } else if (filterOption == 'TAARIFA KWA MWANAJUMUIYA' &&
        selectedUser != null) {
      await getUserYearCollections();
    } else if (filterOption == 'KWA MWEZI' && selectedMonth != null) {
      await getUserMonthCollections();
    } else if (filterOption == 'MICHANGO YOTE YA MWANAJUMUIYA' &&
        selectedUser != null) {
      showUserCollections = true;
      await getUserAllCollections();
    }

    setState(() {
      isDataLoaded = true;
    });
  }

  Future<void> getUserAllCollections() async {
    // This will show both monthly and other collections for the selected user
    await getUserYearCollections();
    await getUserOtherCollections();
    await getUserTrialsNumber();
  }

  Future<CollectionResponse?> getUserOtherCollections() async {
    try {
      if (userData?.user.id == null ||
          userData!.user.id.toString().isEmpty ||
          selectedUser == null) {
        return null;
      }

      final String myApi =
          "$baseUrl/monthly/get_all_other_collection_by_user_id_year_id.php?user_id=${selectedUser!.id}&year_id=${currentYear!.data.id}&jumuiya_id=${userData!.user.jumuiya_id}";

      final response = await http
          .get(Uri.parse(myApi), headers: {'Accept': 'application/json'});

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse != null) {
          collectionsOthers = CollectionResponse.fromJson(jsonResponse);
          return collectionsOthers;
        }
      }
    } catch (e) {
      if (context.mounted) {
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
    return null;
  }

  Future<void> _reloadData() async {
    setState(() {
      isDataLoaded = false;
    });

    await Future.wait([
      getUserCollections(),
      getOtherUserCollections(),
      getUserTrialsNumber()
    ]);

    setState(() {
      isDataLoaded = true;
    });
  }

  Future<CollectionResponse?> getUserCollections() async {
    try {
      if (userData?.user.id == null || userData!.user.id.toString().isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.yellow,
              content: Text("⚠️ Hakuna taarifa zaidi kuwezesha kupata taarifa"),
            ),
          );
        }
        // setState(() => _isLoading = false);
        return null;
      }

      final String myApi =
          "$baseUrl/monthly/get_all_collection_user_by_year.php?yearId=${currentYear!.data.id}&jumuiya_id=${userData!.user.jumuiya_id}";
      final response = await http
          .get(Uri.parse(myApi), headers: {'Accept': 'application/json'});

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse != null) {
          // setState(() => _isLoading = false);
          collectionsMonthly = CollectionResponse.fromJson(jsonResponse);
          calculateTotals();
          return collectionsMonthly;
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text("Error: ${response.statusCode}"),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
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

  Future<UserTrialsNumberResponse?> getUserTrialsNumber() async {
    try {
      if (userData?.user.id == null || userData!.user.id.toString().isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.yellow,
              content: Text(
                "⚠️ Hakuna taarifa zaidi kuwezesha kupata taarifa",
              ),
            ),
          );
        }
        return null;
      }

      final String myApi =
          "$baseUrl/report_features/get_my_trials_report.php?user_id=${userData!.user.id}";
      final response = await http
          .get(Uri.parse(myApi), headers: {'Accept': 'application/json'});

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse != null) {
          setState(() {
            userTrialsNumber = UserTrialsNumberResponse.fromJson(jsonResponse);
          });

          return userTrialsNumber;
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text("Error: ${response.statusCode}"),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
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

  Future<void> reduceUserTrials() async {
    try {
      final response = await http.post(
          headers: {'Accept': 'application/json'},
          Uri.parse('$baseUrl/report_features/update_my_report_trials.php'),
          body: jsonEncode({
            "user_id": userData!.user.id.toString(),
          }));

      if (response.statusCode == 200) {
        getUserTrialsNumber();
      }
    } catch (e) {
      // Handle error silently or show message
      if (kDebugMode) {
        print('Error fetching jumuiya data');
      }
    }
  }

  Future<UserMonthlyCollectionResponse?> getUserCollectionAgainstTable() async {
    setState(() {
      isLoading = true;
    });
    try {
      if (userData?.user.id == null || userData!.user.id.toString().isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                backgroundColor: Colors.yellow,
                content:
                    Text("⚠️ Hakuna taarifa zaidi kuwezesha kupata taarifa")),
          );
        }
        setState(() {
          isLoading = false;
        });
        return null;
      }

      final String myApi =
          "$baseUrl/monthly/get_all_collection_year_id_table_data.php?year_id=${currentYear!.data.id}&jumuiya_id=${userData!.user.jumuiya_id}";
      final response = await http
          .get(Uri.parse(myApi), headers: {'Accept': 'application/json'});

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse != null) {
          setState(() {
            isLoading = false;
          });
          userMonthlyCollectionResponse =
              UserMonthlyCollectionResponse.fromJson(jsonResponse);
          return userMonthlyCollectionResponse;
        }
      } else {
        setState(() {
          isLoading = false;
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                backgroundColor: Colors.red,
                content: Text("Error: ${response.statusCode}")),
          );
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (context.mounted) {
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

  Future<CollectionResponse?> getUserMonthCollections() async {
    try {
      if (userData?.user.id == null || userData!.user.id.toString().isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.red,
              content: Text(
                "⚠️ Hakuna taarifa zaidi kuwezesha kupata taarifa",
              ),
            ),
          );
        }
        // setState(() => _isLoading = false);
        return null;
      }

      final String myApi =
          "$baseUrl/monthly/get_all_collection_by_month.php?month=$selectedMonth&jumuiya_id=${userData!.user.jumuiya_id}";
      final response = await http
          .get(Uri.parse(myApi), headers: {'Accept': 'application/json'});

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse != null) {
          // setState(() => _isLoading = false);
          collectionsMonthly = CollectionResponse.fromJson(jsonResponse);
          return collectionsMonthly;
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text(
                "Error: ${response.statusCode}",
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
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

  Future<CollectionResponse?> getUserYearCollections() async {
    try {
      if (userData?.user.id == null || userData!.user.id.toString().isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                backgroundColor: Colors.yellow,
                content:
                    Text("⚠️ Hakuna taarifa zaidi kuwezesha kupata taarifa")),
          );
        }
        // setState(() => _isLoading = false);
        return null;
      }

      final String myApi =
          "$baseUrl/monthly/get_all_collection_by_user_id_year_id.php?user_id=${selectedUser!.id}&year_id=${currentYear!.data.id}&jumuiya_id=${userData!.user.jumuiya_id}";

      final response = await http
          .get(Uri.parse(myApi), headers: {'Accept': 'application/json'});

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse != null) {
          collectionsMonthly = CollectionResponse.fromJson(jsonResponse);
          return collectionsMonthly;
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text(
                "Error: ${response.statusCode}",
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
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

  Future<void> deleteTimeTable(dynamic id) async {
    try {
      final String myApi =
          "$baseUrl/church_timetable/delete_time_table.php?id=$id";
      final response = await http.delete(
        Uri.parse(myApi),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        // final jsonResponse = json.decode(response.body);
        // print(jsonResponse);
        // Example: await deleteTimeTable(item.id);

        Navigator.pop(context); // Close bottom sheet

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              backgroundColor: Colors.green,
              content: Text('Mchango umefutwa kikamirifu.')),
        );
        _reloadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: Colors.red,
              content: Text("Error: ${response.statusCode}")),
        );
      }
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: RefreshIndicator(
        onRefresh: _reloadData,
        color: mainFontColor,
        child: getBody(),
      ),
      floatingActionButton: selectedTabIndex == 0
          ? _buildPremiumFeaturesFAB()
          : SizedBox.shrink(),
    );
  }

  Widget getBody() {
    var size = MediaQuery.of(context).size;

    return SafeArea(
      child: Column(
        children: [
          // Modern Header with gradient

          Visibility(
            visible: selectedTabIndex == 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    mainFontColor,
                    mainFontColor.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "💰 Michango ya Kila Mwezi",
                            style: TextStyle(
                              fontSize: (size.width - 40) / 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Dhibiti na ufuatilie michango ya mwezi",
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  Colors.white.withAlpha((0.8 * 255).toInt()),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "Jumla: TZS ${NumberFormat("#,##0", "en_US").format(totalMonthlyCollections)}",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: IconButton(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(25)),
                                ),
                                child: AddMonthCollectionUserAdmin(
                                  rootContext: context,
                                  onSubmit: (data) {
                                    _reloadData();
                                  },
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add,
                              color: Colors.white, size: 28),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Visibility(
            visible: selectedTabIndex == 1,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    mainFontColor,
                    mainFontColor.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "💰 Michango ya Wanajumuiya",
                            style: TextStyle(
                              fontSize: (size.width - 40) / 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Dhibiti na ufuatilie michango",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "Jumla: TZS ${NumberFormat("#,##0", "en_US").format(totalOtherCollections)}",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: IconButton(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(25)),
                                ),
                                child: AddOtherMonthCollectionUserAdmin(
                                  rootContext: context,
                                  onSubmit: (data) {
                                    _reloadData();
                                  },
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add,
                              color: Colors.white, size: 28),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Tab selector
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTabIndex = 0;
                        viewTable = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selectedTabIndex == 0
                            ? mainFontColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          "Michango ya Mwezi",
                          style: TextStyle(
                            color: selectedTabIndex == 0
                                ? Colors.white
                                : Colors.grey[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTabIndex = 1;
                        viewTable = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selectedTabIndex == 1
                            ? mainFontColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          "Michango Mingineyo",
                          style: TextStyle(
                            color: selectedTabIndex == 1
                                ? Colors.white
                                : Colors.grey[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content area
          Expanded(
            child: viewTable
                ? _buildTableView()
                : selectedTabIndex == 0
                    ? _buildMonthlyCollectionsView(size)
                    : const AdminOtherAllUserCollections(),
          ),
        ],
      ),
    );
  }

  Widget _buildTableView() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Close table button
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.table_chart, color: mainFontColor, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      "Jedwali la Michango",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[50],
                    foregroundColor: Colors.red[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text(
                    "Funga",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {
                    setState(() {
                      viewTable = false;
                    });
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Table content
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : UserMonthlyCollectionTable(
                    data: userMonthlyCollectionResponse,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyCollectionsView(Size size) {
    return Column(
      children: [
        // Controls Card
        // Toggle button to show/hide controls
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              userTrialsNumber != null &&
                      int.parse(userTrialsNumber!.data[0].reportTrials) != 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.shade100,
                            Colors.blue.shade100,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.workspace_premium,
                            color: Colors.amber[700],
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${userTrialsNumber != null ? int.parse(userTrialsNumber!.data[0].reportTrials) : '0'} Ripoti Bure',
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SizedBox.shrink(),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: mainFontColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: Icon(
                  isLoading
                      ? Icons.hourglass_top
                      : (showUserCollections
                          ? Icons.visibility_off
                          : Icons.visibility),
                  size: 18,
                  color: mainFontColor,
                ),
                label: Text(showUserCollections
                    ? "Onyesha Vichujio"
                    : "Ficha Vichujio"),
                onPressed: () {
                  setState(() {
                    showUserCollections = !showUserCollections;
                  });
                },
              ),
            ],
          ),
        ),
        // Controls Card (show/hide based on showUserCollections)
        if (!showUserCollections)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.08),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: mainFontColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                          Icon(Icons.dashboard, color: mainFontColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Dhibiti Michango",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[50],
                          foregroundColor: Colors.blue[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.table_chart, size: 18),
                        label: const Text(
                          "Jedwali",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        onPressed: () async {
                          setState(() {
                            viewTable = true;
                          });
                          await getUserCollectionAgainstTable();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mainFontColor.withValues(alpha: 0.1),
                          foregroundColor: mainFontColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.filter_list, size: 18),
                        label: const Text(
                          "Chuja",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        onPressed: () {
                          // Filter functionality can be expanded here
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Filter dropdown
                _buildModernDropdown<String>(
                  value: filterOption,
                  hint: "Chagua Aina ya Utafutaji",
                  icon: Icons.search,
                  items: filterOptions
                      .map((option) => DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      filterOption = value!;
                      selectedUser = null;
                      selectedMonth = null;
                    });
                    loadData();
                  },
                ),

                // Conditional dropdowns
                if (filterOption == 'TAARIFA KWA MWANAJUMUIYA') ...[
                  const SizedBox(height: 16),
                  _buildModernDropdown<User>(
                    value: selectedUser,
                    hint: "Chagua Mwanajumuiya",
                    icon: Icons.person,
                    items: users
                        .map(
                          (user) => DropdownMenuItem<User>(
                            value: user,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor:
                                      mainFontColor.withValues(alpha: 0.1),
                                  child: Text(
                                    (user.userFullName ?? '').isNotEmpty
                                        ? user.userFullName![0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: mainFontColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(user.userFullName ?? '')),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (user) {
                      if (user != null) {
                        setState(() {
                          selectedUser = user;
                        });
                        loadData();
                      }
                    },
                  ),
                ],

                if (filterOption == 'MICHANGO YOTE YA MWANAJUMUIYA') ...[
                  const SizedBox(height: 16),
                  _buildModernDropdown<User>(
                    value: selectedUser,
                    hint: "Chagua Mwanajumuiya",
                    icon: Icons.person,
                    items: users
                        .map(
                          (user) => DropdownMenuItem<User>(
                            value: user,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor:
                                      mainFontColor.withValues(alpha: 0.1),
                                  child: Text(
                                    (user.userFullName ?? '').isNotEmpty
                                        ? user.userFullName![0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: mainFontColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(user.userFullName ?? '')),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (user) {
                      if (user != null) {
                        setState(() {
                          selectedUser = user;
                        });
                        loadData();
                      }
                    },
                  ),
                ],

                if (filterOption == 'KWA MWEZI') ...[
                  const SizedBox(height: 16),
                  _buildModernDropdown<String>(
                    value: selectedMonth,
                    hint: "Chagua Mwezi",
                    icon: Icons.calendar_month,
                    items: months
                        .map((month) => DropdownMenuItem(
                              value: month,
                              child: Text(month),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedMonth = value;
                      });
                      loadData();
                    },
                  ),
                ],
              ],
            ),
          ),

        const SizedBox(height: 16),

        // Collections List
        Expanded(
          child: showUserCollections &&
                  filterOption == 'MICHANGO YOTE YA MWANAJUMUIYA' &&
                  selectedUser != null
              ? _buildUserAllCollectionsView(size)
              : !isDataLoaded
                  ? _buildLoadingCard()
                  : _buildCollectionsContent(size),
        ),
      ],
    );
  }

  Widget _buildModernDropdown<T>({
    required T? value,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: mainFontColor, size: 20),
        ),
        items: items,
        onChanged: onChanged,
        dropdownColor: Colors.white,
        style: const TextStyle(color: Colors.black87, fontSize: 14),
      ),
    );
  }

  Widget _buildCollectionsContent(Size size) {
    if (collectionsMonthly == null || collectionsMonthly!.data.isEmpty) {
      String message = selectedUser != null
          ? "Hakuna data ya michango iliyopatikana ya ${selectedUser!.userFullName}."
          : "Hakuna data ya michango iliyopatikana.";
      return _buildEmptyCard(message);
    }

    final collections = collectionsMonthly!.data;
    return _buildCollectionsList(collections, size);
  }

  Widget _buildLoadingCard() {
    final screenSize = MediaQuery.of(context).size;
    final horizontalMargin = screenSize.width * 0.02; // 4% of width
    final verticalPadding = screenSize.height * 0.01; // 3% of height

    return Container(
      margin: EdgeInsets.all(horizontalMargin),
      padding: EdgeInsets.all(verticalPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(screenSize.width * 0.02), // 5% of width
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: screenSize.width * 0.08,
              height: screenSize.width * 0.08,
              child: CircularProgressIndicator(color: mainFontColor),
            ),
            SizedBox(height: screenSize.height * 0.02),
            Text(
              "Inatafuta...",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: screenSize.width * 0.04,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 30,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 2),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionsList(List<dynamic> collections, Size size) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        itemCount: collections.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = collections[index];
          return _buildCollectionCard(item, size);
        },
      ),
    );
  }

  Widget _buildCollectionCard(dynamic item, Size size) {
    bool isTopContributor =
        double.parse(item.amount) >= 100000; // Example threshold

    return GestureDetector(
      onTap: () => _showCollectionDetails(context, item),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: mainFontColor.withValues(alpha: 0.1),
              child: Text(
                (item.user.userFullName?.isNotEmpty ?? false)
                    ? item.user.userFullName![0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: mainFontColor,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item.user.userFullName ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (isPremiumUser && isTopContributor) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star,
                                  color: Colors.amber[600], size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'Top Contributor',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.payments, size: 14, color: Colors.green[600]),
                      const SizedBox(width: 4),
                      Text(
                        "TZS ${NumberFormat("#,##0", "en_US").format(int.parse(item.amount))}",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.monthly,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        item.registeredDate,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: mainFontColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          item.churchYearEntity.churchYear,
                          style: TextStyle(
                            fontSize: 10,
                            color: mainFontColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  void _showCollectionDetails(
      BuildContext rootContext, CollectionItem dataItem) {
    final user = dataItem.user;
    final year = dataItem.churchYearEntity;

    showModalBottomSheet(
      context: rootContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
            ),
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6,
              maxChildSize: 0.95,
              minChildSize: 0.4,
              builder: (_, controller) => Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        height: 4,
                        width: 40,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header with actions
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: mainFontColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(Icons.receipt_long,
                              color: mainFontColor, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Maelezo ya Mchango",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                "Taarifa kamili za mchango",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (userData!.user.role == "ADMIN") ...[
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Colors.blue, size: 20),
                              tooltip: 'Hariri',
                              onPressed: () {
                                Navigator.pop(context);
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(25)),
                                    ),
                                    child: AddMonthCollectionUserAdmin(
                                      rootContext: rootContext,
                                      initialData: dataItem,
                                      onSubmit: (data) {
                                        Navigator.of(context).pop();
                                        _reloadData();
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red, size: 20),
                              tooltip: 'Futa',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    title: Row(
                                      children: [
                                        Icon(Icons.warning,
                                            color: Colors.orange[600]),
                                        const SizedBox(width: 8),
                                        const Text('Futa Mchango'),
                                      ],
                                    ),
                                    content: const Text(
                                        'Una uhakika unataka kufuta mchango huu?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(false),
                                        child: Text('Hapana',
                                            style: TextStyle(
                                                color: Colors.grey[600])),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(true),
                                        child: const Text('Ndiyo'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  Navigator.of(context)
                                      .pop(); // Close the modal first
                                  deleteTimeTable(dataItem.id);
                                }
                              },
                            ),
                          ),
                        ]
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        controller: controller,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User info card
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFF),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color:
                                        mainFontColor.withValues(alpha: 0.1)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: mainFontColor
                                            .withValues(alpha: 0.1),
                                        child: Text(
                                          (user.userFullName?.isNotEmpty ??
                                                  false)
                                              ? user.userFullName![0]
                                                  .toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: mainFontColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              user.userFullName ?? '',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            Text(
                                              user.role ?? '',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildDetailRow(
                                      Icons.phone, "Simu", user.phone ?? ''),
                                  _buildDetailRow(Icons.account_circle,
                                      "Jina la Mtumiaji", user.userName ?? ''),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Amount card
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.green[50]!,
                                    Colors.green[100]!,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Colors.green.withValues(alpha: 0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.green
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Icon(Icons.payments,
                                            color: Colors.green[700], size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        "Kiasi cha Mchango",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "TZS ${NumberFormat("#,##0", "en_US").format(int.parse(dataItem.amount))}",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Details card
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Colors.grey.withValues(alpha: 0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Icon(Icons.info_outline,
                                            color: Colors.blue[700], size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        "Maelezo ya Ziada",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildDetailRow(Icons.calendar_month, "Mwezi",
                                      dataItem.monthly),
                                  _buildDetailRow(
                                      Icons.calendar_today,
                                      "Tarehe ya Usajili",
                                      dataItem.registeredDate),
                                  _buildDetailRow(Icons.person_outline,
                                      "Aliyesajili", dataItem.registeredBy),
                                  _buildDetailRow(Icons.date_range,
                                      "Mwaka wa Kanisa", year.churchYear),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ));
      },
    );
  }

  Widget _buildPremiumFeaturesFAB() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (userTrialsNumber != null &&
            int.parse(userTrialsNumber!.data[0].reportTrials) != 0) ...[
          FloatingActionButton.small(
            heroTag: 'export_pdf_admin',
            onPressed: () => _exportToPDF(),
            backgroundColor: Colors.blue,
            child: const Icon(Icons.picture_as_pdf),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'export_excel_admin',
            onPressed: () => _exportToExcel(),
            backgroundColor: Colors.green,
            child: const Icon(Icons.table_chart),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'detailed_report_admin',
            onPressed: () => _showDetailedReport(),
            backgroundColor: Colors.purple,
            child: const Icon(Icons.analytics),
          ),
          const SizedBox(height: 16),
        ],
        if (userTrialsNumber != null &&
            int.parse(userTrialsNumber!.data[0].reportTrials) == 0) ...[
          FloatingActionButton.small(
            heroTag: 'upgrade_admin',
            onPressed: () => _showPremiumDialog(),
            backgroundColor: Colors.amber,
            child: const Icon(Icons.star),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.star, color: Colors.amber[600]),
            const SizedBox(width: 8),
            const Text('Huduma za Ziada'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPremiumFeature(
              Icons.analytics,
              'Ripoti za Kina',
              'Pata ufahamu kamili kuhusu michango',
            ),
            _buildPremiumFeature(
              Icons.picture_as_pdf,
              'Hamisha kwenda PDF',
              'Pakua ripoti za kitaalamu za PDF',
            ),
            _buildPremiumFeature(
              Icons.table_chart,
              'Hamisha kwenda Excel',
              'Changanuza data katika majedwali',
            ),
            _buildPremiumFeature(
              Icons.workspace_premium,
              'Beji za Wachangiaji',
              'Tambua wachangiaji wakuu',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Baadaye',
              style: TextStyle(
                fontSize: 12.0,
              ),
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.star),
            label: const Text(
              'Huduma za Ziada',
              style: TextStyle(
                fontSize: 12.0,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black87,
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const UserFeaturesPaymentPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFeature(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.amber[700]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToPDF() async {
    try {
      if (int.parse(userTrialsNumber!.data[0].reportTrials) != 0) {
        // Show remaining trials dialog
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.info_outline,
                            color: Colors.blue[600], size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Taarifa ya Majaribio',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade100),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time,
                            color: Colors.amber[700], size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Una majaribio ${userTrialsNumber!.data[0].reportTrials} yaliyobaki',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.monetization_on,
                            color: Colors.green[600], size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Baada ya majaribio kuisha, utahitaji kulipia TZS 1,000 kwa mwezi kupata huduma hii.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Sawa, Nimeelewa',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
      setState(() => isLoading = true);
      final pdf = pw.Document();

      // Create data array
      final tableData = collectionsMonthly?.data.map((item) {
            return [
              item.user.userFullName ?? '',
              'TZS ${NumberFormat("#,##0").format(int.parse(item.amount))}',
              item.monthly,
              item.registeredDate,
            ];
          }).toList() ??
          [];

      // Debug: Print the data length

      // Define rows per page (adjust based on your needs)
      const int rowsPerPage = 25;

      // Calculate number of pages needed
      int totalPages = (tableData.length / rowsPerPage).ceil();
      if (totalPages == 0) totalPages = 1; // At least one page

      // Create pages with data
      for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
        final startIndex = pageIndex * rowsPerPage;
        final endIndex = (startIndex + rowsPerPage > tableData.length)
            ? tableData.length
            : startIndex + rowsPerPage;

        final pageData = tableData.sublist(startIndex, endIndex);

        pdf.addPage(
          pw.Page(
            theme: pw.ThemeData.withFont(
              base: pw.Font.courier(),
              bold: pw.Font.courierBold(),
            ),
            build: (context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header (show on every page)
                  pw.Header(
                    level: 0,
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Ripoti ya Michango',
                            style: pw.TextStyle(
                                fontSize: 24, font: pw.Font.courierBold())),
                        pw.Text(
                          DateFormat('dd/MM/yyyy').format(DateTime.now()),
                          style: const pw.TextStyle(
                            color: PdfColors.black,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Page info
                  pw.Text(
                    'Ukurasa ${pageIndex + 1} wa $totalPages',
                    style: pw.TextStyle(fontSize: 12),
                  ),
                  pw.SizedBox(height: 10),

                  // Table
                  pw.Expanded(
                    child: pw.Table(
                      border: pw.TableBorder.all(),
                      columnWidths: {
                        0: const pw.FlexColumnWidth(3), // Name column wider
                        1: const pw.FlexColumnWidth(2), // Amount column
                        2: const pw.FlexColumnWidth(2), // Month column
                        3: const pw.FlexColumnWidth(2), // Date column
                      },
                      children: [
                        // Header row (show on every page)
                        pw.TableRow(
                          decoration:
                              pw.BoxDecoration(color: PdfColors.grey300),
                          children: ['Mwanajumuiya', 'Kiasi', 'Mwezi', 'Tarehe']
                              .map((header) => pw.Container(
                                    padding: const pw.EdgeInsets.all(6),
                                    child: pw.Text(
                                      header,
                                      style: pw.TextStyle(
                                        font: pw.Font.courierBold(),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                        // Data rows for this page
                        ...pageData.map((row) => pw.TableRow(
                              children: row
                                  .map((cell) => pw.Container(
                                        padding: const pw.EdgeInsets.all(6),
                                        child: pw.Text(
                                          cell.toString(),
                                          style: pw.TextStyle(fontSize: 9),
                                        ),
                                      ))
                                  .toList(),
                            )),
                      ],
                    ),
                  ),

                  // Summary (show only on last page)
                  if (pageIndex == totalPages - 1) ...[
                    pw.SizedBox(height: 15),
                    pw.Divider(),
                    pw.Text(
                      'Jumla ya Michango: TZS ${NumberFormat("#,##0").format(totalMonthlyCollections)}',
                      style: pw.TextStyle(
                        font: pw.Font.courierBold(),
                        fontSize: 12,
                      ),
                    ),
                    pw.Text(
                      'Jumla ya Wanajumuiya: ${tableData.length}',
                      style: pw.TextStyle(
                        font: pw.Font.courierBold(),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        );
      }

      // Handle case where there's no data
      if (tableData.isEmpty) {
        pdf.addPage(
          pw.Page(
            theme: pw.ThemeData.withFont(
              base: pw.Font.courier(),
              bold: pw.Font.courierBold(),
            ),
            build: (context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Header(
                    level: 0,
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Ripoti ya Michango',
                            style: pw.TextStyle(
                                fontSize: 24, font: pw.Font.courierBold())),
                        pw.Text(
                          DateFormat('dd/MM/yyyy').format(DateTime.now()),
                          style: const pw.TextStyle(
                            color: PdfColors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text('Hakuna data ya kuonyesha.'),
                ],
              );
            },
          ),
        );
      }

      // Save the PDF file
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'Ripoti_${DateFormat('dd_MM_yyyy').format(DateTime.now())}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Share the actual PDF file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Ripoti ya Michango',
        subject: fileName,
      );
      await reduceUserTrials();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Hitilafu: $e',
          ),
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _exportToExcel() async {
    if (int.parse(userTrialsNumber!.data[0].reportTrials) != 0) {
      // Show remaining trials dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(Icons.info_outline,
                          color: Colors.blue[600], size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Taarifa ya Majaribio',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time,
                          color: Colors.amber[700], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Una majaribio ${userTrialsNumber!.data[0].reportTrials} yaliyobaki',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.monetization_on,
                          color: Colors.green[600], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Baada ya majaribio kuisha, utahitaji kulipia TZS 1,000 kwa mwezi kupata huduma hii.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Sawa, Nimeelewa',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    setState(() => isLoading = true);
    try {
      // Create Excel workbook
      var excel = Excel.createExcel();

      // Remove default sheet and create custom one
      excel.delete('Sheet1');
      var sheet = excel['Michango'];

      // Style for headers
      var headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: '#D3D3D3',
        horizontalAlign: HorizontalAlign.Center,
      );

      // Add headers with styling
      var headers = [
        'Mwanajumuiya',
        'Kiasi (TZS)',
        'Mwezi',
        'Tarehe ya Usajili'
      ];
      for (int i = 0; i < headers.length; i++) {
        var cell =
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = headers[i];
        cell.cellStyle = headerStyle;
      }

      // Add data rows
      int rowIndex = 1;
      collectionsMonthly?.data.forEach((item) {
        // Name
        var nameCell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
        nameCell.value = item.user.userFullName ?? '';

        // Amount (formatted as number)
        var amountCell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex));
        try {
          amountCell.value = int.parse(item.amount);
        } catch (e) {
          amountCell.value = item.amount; // Keep as string if parsing fails
        }

        // Month
        var monthCell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex));
        monthCell.value = item.monthly;

        // Registration Date
        var dateCell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex));
        dateCell.value = item.registeredDate;

        rowIndex++;
      });

      // Add summary row
      if (collectionsMonthly?.data.isNotEmpty == true) {
        rowIndex++; // Skip a row

        // Summary label
        var summaryLabelCell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
        summaryLabelCell.value = 'JUMLA';
        summaryLabelCell.cellStyle = CellStyle(bold: true);

        // Summary amount
        var summaryAmountCell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex));
        summaryAmountCell.value = totalMonthlyCollections;
        summaryAmountCell.cellStyle = CellStyle(bold: true);

        // Total count
        rowIndex++;
        var countLabelCell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
        countLabelCell.value = 'Idadi ya Wanajumuiya';
        countLabelCell.cellStyle = CellStyle(bold: true);

        var countCell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex));
        countCell.value = collectionsMonthly?.data.length ?? 0;
        countCell.cellStyle = CellStyle(bold: true);
      }

      // Auto-fit columns (approximate)
      sheet.setColWidth(0, 25); // Name column
      sheet.setColWidth(1, 15); // Amount column
      sheet.setColWidth(2, 12); // Month column
      sheet.setColWidth(3, 15); // Date column

      // Save the Excel file
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'Ripoti_${DateFormat('dd_MM_yyyy').format(DateTime.now())}.xlsx';
      final file = File('${directory.path}/$fileName');

      // Encode and save
      var excelBytes = excel.encode();
      if (excelBytes != null) {
        await file.writeAsBytes(excelBytes);

        // // Debug: Check if file was created
        // print('Excel file created: ${file.path}');
        // print('File exists: ${await file.exists()}');
        // print('File size: ${await file.length()} bytes');

        // Share the actual Excel file
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Ripoti ya Michango (Excel)',
          subject: fileName,
        );

        await reduceUserTrials();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel file imesajiliwa na kushirikiwa!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to encode Excel file');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Hitilafu: $e',
          ),
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _showDetailedReport() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.analytics, color: Colors.purple),
                  ),
                  const SizedBox(width: 15),
                  const Text(
                    'Uchambuzi wa Michango',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Monthly trend chart
                  _buildChartCard(
                    'Mwenendo wa Michango',
                    _buildLineChart(),
                  ),
                  const SizedBox(height: 20),
                  // Collection type distribution
                  _buildChartCard(
                    'Mgawanyo wa Aina za Michango',
                    _buildPieChart(),
                  ),
                  const SizedBox(height: 20),
                  // Top contributors
                  _buildTopContributorsCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: chart,
          ),
        ],
      ),
    );
  }

  Widget _buildTopContributorsCard() {
    // Sort contributors by amount
    List<CollectionItem> sortedContributors = [];

    if (collectionsMonthly?.data != null) {
      sortedContributors = List.from(collectionsMonthly!.data);
      // Group by user and sum their contributions
      Map<String, double> userTotals = {};
      Map<String, CollectionItem> userItems = {};

      for (var item in sortedContributors) {
        String userId = item.user.id.toString();
        double amount = double.tryParse(item.amount) ?? 0.0;

        if (userTotals.containsKey(userId)) {
          userTotals[userId] = (userTotals[userId] ?? 0) + amount;
        } else {
          userTotals[userId] = amount;
          userItems[userId] = item;
        }
      }

      // Convert back to a list for sorting
      sortedContributors = [];
      userTotals.forEach((userId, total) {
        if (userItems.containsKey(userId)) {
          CollectionItem item = userItems[userId]!;
          // Create a copy with the updated amount
          // Note: this is simplified, in a real app you'd need to create a proper copy
          item.total = total.toString();
          sortedContributors.add(item);
        }
      });

      // Sort by amount (descending)
      sortedContributors.sort((a, b) {
        double amountA = double.tryParse(a.total) ?? 0.0;
        double amountB = double.tryParse(b.total) ?? 0.0;
        return amountB.compareTo(amountA);
      });
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Wachangiaji Wakuu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          if (sortedContributors.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Hakuna data ya kuonyesha',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            )
          else
            ...List.generate(
              sortedContributors.length > 3 ? 3 : sortedContributors.length,
              (index) {
                final contributor = sortedContributors[index];
                return _buildTopContributorItem(
                  name: contributor.user.userFullName ?? 'Unknown',
                  amount: double.tryParse(contributor.total) ?? 0.0,
                  rank: index + 1,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label ($count)',
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildTopContributorItem({
    required String name,
    required double amount,
    required int rank,
  }) {
    final icons = [
      Icons.workspace_premium,
      Icons.star,
      Icons.military_tech,
    ];
    final colors = [
      Colors.amber,
      Colors.grey[400],
      Colors.brown[300],
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors[rank - 1]?.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icons[rank - 1], color: colors[rank - 1]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'TZS ${NumberFormat("#,##0").format(amount)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors[rank - 1]?.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '#$rank',
              style: TextStyle(
                color: colors[rank - 1],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    // Process data to group collections by month
    Map<String, double> monthlyTotals = {};

    if (collectionsMonthly?.data != null) {
      for (var item in collectionsMonthly!.data) {
        // Extract month from the monthly field or use registration date
        String month = item.monthly.split(' ').first;
        double amount = double.tryParse(item.amount) ?? 0.0;

        // Add amount to corresponding month
        if (monthlyTotals.containsKey(month)) {
          monthlyTotals[month] = (monthlyTotals[month] ?? 0) + amount;
        } else {
          monthlyTotals[month] = amount;
        }
      }
    }

    // Sort months chronologically
    List<String> sortedMonths = monthlyTotals.keys.toList();
    sortedMonths.sort((a, b) {
      // Assuming month names are standard - can be enhanced with a more robust month sorting
      final months = [
        'JANUARY',
        'FEBRUARY',
        'MARCH',
        'APRIL',
        'MAY',
        'JUNE',
        'JULY',
        'AUGUST',
        'SEPTEMBER',
        'OCTOBER',
        'NOVEMBER',
        'DECEMBER'
      ];
      return months.indexOf(a.toUpperCase()) - months.indexOf(b.toUpperCase());
    });

    // Create spots for the chart, limited to the last 6 months if there are more
    List<FlSpot> spots = [];
    if (sortedMonths.isNotEmpty) {
      final displayMonths = sortedMonths.length > 6
          ? sortedMonths.sublist(sortedMonths.length - 6)
          : sortedMonths;

      for (int i = 0; i < displayMonths.length; i++) {
        String month = displayMonths[i];
        spots.add(FlSpot(
            i.toDouble(),
            monthlyTotals[month]! /
                100000)); // Scale down for better visualization
      }
    } else {
      // Fallback if no data
      spots = [const FlSpot(0, 0)];
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt() * 100}K',
                    style: const TextStyle(fontSize: 10, color: Colors.grey));
              },
              reservedSize: 40,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (sortedMonths.isNotEmpty &&
                    index >= 0 &&
                    index < sortedMonths.length) {
                  // Show abbreviated month name
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(sortedMonths[index].substring(0, 3),
                        style: const TextStyle(fontSize: 10)),
                  );
                }
                return const Text('');
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.withOpacity(0.2))),
        minX: 0,
        maxX: (spots.isEmpty ? 1 : spots.length - 1).toDouble(),
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.purple,
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.purple.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    // Categorize data for the pie chart based on amount ranges
    int smallContributions = 0; // < 50K
    int mediumContributions = 0; // 50K - 100K
    int largeContributions = 0; // > 100K

    if (collectionsMonthly?.data != null) {
      for (var item in collectionsMonthly!.data) {
        double amount = double.tryParse(item.amount) ?? 0.0;

        if (amount < 50000) {
          smallContributions++;
        } else if (amount <= 100000) {
          mediumContributions++;
        } else {
          largeContributions++;
        }
      }
    }

    // Calculate total contributions
    int totalContributions =
        smallContributions + mediumContributions + largeContributions;

    // Calculate percentages, ensuring we don't divide by zero
    double smallPercentage = totalContributions > 0
        ? (smallContributions / totalContributions) * 100
        : 0;
    double mediumPercentage = totalContributions > 0
        ? (mediumContributions / totalContributions) * 100
        : 0;
    double largePercentage = totalContributions > 0
        ? (largeContributions / totalContributions) * 100
        : 0;

    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                if (smallPercentage > 0)
                  PieChartSectionData(
                    color: Colors.blue,
                    value: smallPercentage,
                    title: '${smallPercentage.toStringAsFixed(1)}%',
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                if (mediumPercentage > 0)
                  PieChartSectionData(
                    color: Colors.green,
                    value: mediumPercentage,
                    title: '${mediumPercentage.toStringAsFixed(1)}%',
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                if (largePercentage > 0)
                  PieChartSectionData(
                    color: Colors.orange,
                    value: largePercentage,
                    title: '${largePercentage.toStringAsFixed(1)}%',
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                // Show a placeholder if no data
                if (totalContributions == 0)
                  PieChartSectionData(
                    color: Colors.grey.shade300,
                    value: 100,
                    title: 'No Data',
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Legend
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem('< 50,000 TZS', Colors.blue, smallContributions),
              _buildLegendItem(
                  '50,000 - 100,000 TZS', Colors.green, mediumContributions),
              _buildLegendItem(
                  '> 100,000 TZS', Colors.orange, largeContributions),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            "$label:",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
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

  Widget _buildUserAllCollectionsView(Size size) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Header showing user info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  mainFontColor.withValues(alpha: 0.1),
                  mainFontColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: mainFontColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: mainFontColor.withValues(alpha: 0.1),
                  child: Text(
                    (selectedUser?.userFullName?.isNotEmpty ?? false)
                        ? selectedUser!.userFullName![0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: mainFontColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Michango ya ${selectedUser?.userFullName ?? ''}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: mainFontColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Michango ya kila mwezi na michango mingineyo",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Summary Card showing totals
          SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.green[50]!,
                    Colors.green[100]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet,
                          color: Colors.green[700]),
                      const SizedBox(width: 8),
                      Text(
                        "Muhtasari wa Michango",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              "Michango ya Mwezi",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "TZS ${NumberFormat("#,##0", "en_US").format(_calculateUserMonthlyTotal())}",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.grey[300],
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              "Michango Mingineyo",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "TZS ${NumberFormat("#,##0", "en_US").format(_calculateUserOtherTotal())}",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.grey[300],
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              "Jumla",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "TZS ${NumberFormat("#,##0", "en_US").format(_calculateUserMonthlyTotal() + _calculateUserOtherTotal())}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
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
          ),
        ],
      ),
    );
  }
}
