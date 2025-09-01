import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jumuiya_yangu/main.dart';
import 'package:jumuiya_yangu/models/auth_model.dart';
import 'package:jumuiya_yangu/models/user_collection_model.dart';
import 'package:jumuiya_yangu/models/user_collection_table_model.dart';
import 'package:jumuiya_yangu/pages/add_pages/add_month_collection.dart';
import 'package:jumuiya_yangu/pages/add_pages/add_other_month_collection.dart';
import 'package:jumuiya_yangu/pages/admin_all_other_collection_users.dart';
import 'package:jumuiya_yangu/pages/supports_pages/collection_table_against_month.dart';
import 'package:jumuiya_yangu/theme/colors.dart';
import 'package:jumuiya_yangu/utils/url.dart';
import 'package:http/http.dart' as http;

class AdminAllUserCollections extends StatefulWidget {
  const AdminAllUserCollections({super.key});

  @override
  State<AdminAllUserCollections> createState() =>
      _AdminAllUserCollectionsState();
}

class _AdminAllUserCollectionsState extends State<AdminAllUserCollections> {
  CollectionResponse? collectionsMonthly;
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
  }

  Future<void> _loadInitialData() async {
    setState(() {
      isDataLoaded = false;
    });

    await Future.wait([
      getUserCollections(),
      getOtherUserCollections(),
      fetchUsers(),
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
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("⚠️ Tafadhali hakikisha umeunganishwa na intaneti")),
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
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text("⚠️ Tafadhali hakikisha umeunganishwa na intaneti")),
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
                content:
                    Text("⚠️ Hakuna taarifa zaidi kuwezesha kupata taarifa")),
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
              content:
                  Text("⚠️ Tafadhali hakikisha umeunganishwa na intaneti")),
        );
      }
    }

    // 🔁 Always return something to complete Future
    return null;
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
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${response.statusCode}")),
          );
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
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

  Future<CollectionResponse?> getUserMonthCollections() async {
    try {
      if (userData?.user.id == null || userData!.user.id.toString().isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text("⚠️ Hakuna taarifa zaidi kuwezesha kupata taarifa")),
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
              content:
                  Text("⚠️ Tafadhali hakikisha umeunganishwa na intaneti")),
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
              content:
                  Text("⚠️ Tafadhali hakikisha umeunganishwa na intaneti")),
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
        // ignore: use_build_context_synchronously
        Navigator.pop(context); // Close bottom sheet
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mchango umefutwa kikamirifu.')),
        );
        _reloadData();
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("⚠️ Tafadhali hakikisha umeunganishwa na intaneti")),
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
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
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
                  Text(
                    item.user.userFullName ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
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
                                // ignore: use_build_context_synchronously
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
                                  color: mainFontColor.withValues(alpha: 0.1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor:
                                          mainFontColor.withValues(alpha: 0.1),
                                      child: Text(
                                        (user.userFullName?.isNotEmpty ?? false)
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
                                        color:
                                            Colors.green.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(10),
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
                                        color:
                                            Colors.blue.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
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
          ),
        );
      },
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

          const SizedBox(height: 16),

          // // Tab selector for Monthly vs Other collections
          // Container(
          //   padding: const EdgeInsets.all(4),
          //   decoration: BoxDecoration(
          //     color: Colors.white,
          //     borderRadius: BorderRadius.circular(25),
          //     boxShadow: [
          //       BoxShadow(
          //         color: Colors.grey.withValues(alpha: 0.1),
          //         spreadRadius: 2,
          //         blurRadius: 10,
          //         offset: const Offset(0, 3),
          //       ),
          //     ],
          //   ),
          //   child: Row(
          //     children: [
          //       Expanded(
          //         child: GestureDetector(
          //           onTap: () {
          //             setState(() {
          //               selectedTabIndex = 0;
          //             });
          //           },
          //           child: Container(
          //             padding: const EdgeInsets.symmetric(vertical: 8),
          //             decoration: BoxDecoration(
          //               color: selectedTabIndex == 0 ? mainFontColor : Colors.transparent,
          //               borderRadius: BorderRadius.circular(20),
          //             ),
          //             child: Center(
          //               child: Text(
          //                 "Michango ya Mwezi",
          //                 style: TextStyle(
          //                   color: selectedTabIndex == 0 ? Colors.white : Colors.grey[600],
          //                   fontSize: 12,
          //                   fontWeight: FontWeight.w600,
          //                 ),
          //               ),
          //             ),
          //           ),
          //         ),
          //       ),
          //       Expanded(
          //         child: GestureDetector(
          //           onTap: () {
          //             setState(() {
          //               selectedTabIndex = 1;
          //             });
          //           },
          //           child: Container(
          //             padding: const EdgeInsets.symmetric(vertical: 8),
          //             decoration: BoxDecoration(
          //               color: selectedTabIndex == 1 ? mainFontColor : Colors.transparent,
          //               borderRadius: BorderRadius.circular(20),
          //             ),
          //             child: Center(
          //               child: Text(
          //                 "Michango Mingineyo",
          //                 style: TextStyle(
          //                   color: selectedTabIndex == 1 ? Colors.white : Colors.grey[600],
          //                   fontSize: 12,
          //                   fontWeight: FontWeight.w600,
          //                 ),
          //               ),
          //             ),
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),

          // const SizedBox(height: 16),

          // // Collections List based on selected tab
          // Expanded(
          //   child: selectedTabIndex == 0 ? _buildUserMonthlyCollections(size) : _buildUserOtherCollections(size),
          // ),
        ],
      ),
    );
  }

  // Widget _buildUserMonthlyCollections(Size size) {
  //   if (collectionsMonthly == null || collectionsMonthly!.data.isEmpty) {
  //     return _buildEmptyCard("Hakuna michango ya kila mwezi ya ${selectedUser?.userFullName ?? ''}.");
  //   }

  //   return ListView.separated(
  //     itemCount: collectionsMonthly!.data.length,
  //     separatorBuilder: (context, index) => const SizedBox(height: 12),
  //     itemBuilder: (context, index) {
  //       final item = collectionsMonthly!.data[index];
  //       return _buildCollectionCard(item, size);
  //     },
  //   );
  // }

  // Widget _buildUserOtherCollections(Size size) {
  //   if (collectionsOthers == null || collectionsOthers!.data.isEmpty) {
  //     return _buildEmptyCard("Hakuna michango mingineyo ya ${selectedUser?.userFullName ?? ''}.");
  //   }

  //   return ListView.separated(
  //     itemCount: collectionsOthers!.data.length,
  //     separatorBuilder: (context, index) => const SizedBox(height: 12),
  //     itemBuilder: (context, index) {
  //       final item = collectionsOthers!.data[index];
  //       return _buildCollectionCard(item, size);
  //     },
  //   );
  // }
}
