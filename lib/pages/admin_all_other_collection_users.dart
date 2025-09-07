// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jumuiya_yangu/main.dart';
import 'package:jumuiya_yangu/models/auth_model.dart';
import 'package:jumuiya_yangu/models/other_collection_model.dart';
import 'package:jumuiya_yangu/models/user_collection_table_model.dart';
import 'package:jumuiya_yangu/pages/add_pages/add_other_month_collection.dart';
import 'package:jumuiya_yangu/pages/supports_pages/collection_table_against_month.dart';
import 'package:jumuiya_yangu/theme/colors.dart';
import 'package:jumuiya_yangu/utils/url.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminOtherAllUserCollections extends StatefulWidget {
  const AdminOtherAllUserCollections({super.key});

  @override
  State<AdminOtherAllUserCollections> createState() =>
      _AdminOtherAllUserCollectionsState();
}

class _AdminOtherAllUserCollectionsState
    extends State<AdminOtherAllUserCollections> {
  OtherCollectionResponse? collectionsOthers;
  UserMonthlyCollectionResponse? userMonthlyCollectionResponse;
  int selectedTabIndex = 0;
  bool viewTable = false;
  bool isLoading = false;
  bool showUserCollections = false;

  //month
  String filterOption = 'TAARIFA ZOTE';
  User? selectedUser;
  CollectionType? selectedCollectionType;
  String? selectedMonth;

  List<String> filterOptions = [
    'TAARIFA ZOTE',
    'TAARIFA KWA MWANAJUMUIYA',
    'KWA MWEZI',
    'KWA AINA YA MCHANGO'
  ];
  List<User> users = []; // replace with real User objects
  List<CollectionType> collectionTypeResponse = [];

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
    getUserCollections();
    fetchUsers();
    fetchCollectionTypes();
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

  Future<void> fetchCollectionTypes() async {
    collectionTypeResponse = [];
    final response = await http.get(Uri.parse(
        '$baseUrl/collectiontype/get_all_collection_type.php?jumuiya_id=${userData!.user.jumuiya_id}'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        collectionTypeResponse = (data['data'] as List)
            .map((u) => CollectionType.fromJson(u))
            .toList();
      });
      setState(() {});
    } else {
      // handle error
    }
  }

  void loadData() {
    setState(() {
      if (filterOption == 'TAARIFA ZOTE') {
        displayedData = allData;
      } else if (filterOption == 'TAARIFA KWA MWANAJUMUIYA' &&
          selectedUser != null) {
        getUserYearCollections();
      } else if (filterOption == 'KWA MWEZI' && selectedMonth != null) {
        displayedData =
            allData.where((item) => item.monthly == selectedMonth).toList();
      } else if (filterOption == 'KWA AINA YA MCHANGO' &&
          selectedMonth != null) {
        getUserOtherByTypeCollections();
      }
    });
  }

  Future<void> _reloadData() async {
    await getUserCollections();
    setState(() {}); // Refresh UI after fetching data
  }

  Future<OtherCollectionResponse?> getUserCollections() async {
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
          "$baseUrl/monthly/get_all_other_collection_user_by_year.php?yearId=${currentYear!.data.id}&jumuiya_id=${userData!.user.jumuiya_id}";
      final response = await http
          .get(Uri.parse(myApi), headers: {'Accept': 'application/json'});

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse != null) {
          // setState(() => _isLoading = false);
          collectionsOthers = OtherCollectionResponse.fromJson(jsonResponse);

          return collectionsOthers;
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${response.statusCode}")),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
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

  Future<OtherCollectionResponse?> getUserOtherByTypeCollections() async {
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
          "$baseUrl/monthly/get_all_collection_user_by_collection_type.php?yearId=${currentYear!.data.id}&jumuiya_id=${userData!.user.jumuiya_id}&collection_type_id=${selectedCollectionType!.id}";

      final response = await http.get(
        Uri.parse(myApi),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse != null) {
          // setState(() => _isLoading = false);
          collectionsOthers = OtherCollectionResponse.fromJson(jsonResponse);

          return collectionsOthers;
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${response.statusCode}")),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
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

  Future<OtherCollectionResponse?> getUserMonthCollections() async {
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
          "$baseUrl/monthly/get_all_other_collection_by_month.php?month=$selectedMonth&jumuiya_id=${userData!.user.jumuiya_id}";

      final response = await http.get(
        Uri.parse(myApi),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse != null) {
          // setState(() => _isLoading = false);
          collectionsOthers = OtherCollectionResponse.fromJson(jsonResponse);

          return collectionsOthers;
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${response.statusCode}")),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
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

  Future<OtherCollectionResponse?> getUserYearCollections() async {
    try {
      if (userData?.user.id == null || userData!.user.id.toString().isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text("⚠️ Hakuna taarifa zaidi kuwezesha kupata taarifa")),
          );
        }
        return null;
      }

      final String myApi =
          "$baseUrl/monthly/get_all_other_collection_by_user_id_year_id.php?user_id=${selectedUser!.id}&year_id=${currentYear!.data.id}&jumuiya_id${userData!.user.jumuiya_id}";

      final response = await http
          .get(Uri.parse(myApi), headers: {'Accept': 'application/json'});

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse != null) {
          collectionsOthers = OtherCollectionResponse.fromJson(jsonResponse);
          return collectionsOthers;
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${response.statusCode}")),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
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
      final String myApi = "$baseUrl/monthly/delete_other.php?id=$id";
      final response = await http.delete(
        Uri.parse(myApi),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        Navigator.pop(context); // Close bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mchango umefutwa kikamirifu.')),
        );
        _reloadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.statusCode}")),
        );
      }
    } catch (e) {
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
      floatingActionButton: _buildPremiumFeaturesFAB(),
    );
  }

  Widget getBody() {
    var size = MediaQuery.of(context).size;

    return SafeArea(
      child: Column(
        children: [
          // Modern Header with gradient

          // Expanded content area
          Expanded(
            child: viewTable ? _buildTableView() : _buildListView(size),
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
      child: isLoading
          ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            )
          : UserMonthlyCollectionTable(data: userMonthlyCollectionResponse),
    );
  }

  Widget _buildListView(Size size) {
    return Column(
      children: [
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
        if (!showUserCollections)
          // Filters Card
          Container(
            margin: const EdgeInsets.all(16),
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
                      child: Icon(Icons.filter_list,
                          color: mainFontColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Chuja Michango",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Filter Option Dropdown
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
                      selectedCollectionType = null;
                      loadData();
                    });
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
                        .map((user) => DropdownMenuItem<User>(
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
                                  Expanded(
                                      child: Text(user.userFullName ?? '')),
                                ],
                              ),
                            ))
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
                        loadData();
                      });
                    },
                  ),
                ],

                if (filterOption == 'KWA AINA YA MCHANGO') ...[
                  const SizedBox(height: 16),
                  _buildModernDropdown<CollectionType>(
                    value: selectedCollectionType,
                    hint: "Chagua Aina ya Mchango",
                    icon: Icons.category,
                    items: collectionTypeResponse
                        .map((type) => DropdownMenuItem<CollectionType>(
                              value: type,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color:
                                          mainFontColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(Icons.payments,
                                        color: mainFontColor, size: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(type.collectionName)),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (type) {
                      if (type != null) {
                        setState(() {
                          selectedCollectionType = type;
                        });
                        loadData();
                      }
                    },
                  ),
                ],
              ],
            ),
          ),

        // Collections List
        Expanded(
          child: FutureBuilder(
            future: filterOption == 'TAARIFA ZOTE'
                ? getUserCollections()
                : (filterOption == 'TAARIFA KWA MWANAJUMUIYA' &&
                        selectedUser != null)
                    ? getUserYearCollections()
                    : (filterOption == 'KWA MWEZI' && selectedMonth != null)
                        ? getUserMonthCollections()
                        : (filterOption == 'KWA AINA YA MCHANGO' &&
                                selectedCollectionType != null)
                            ? getUserOtherByTypeCollections()
                            : getUserCollections(),
            builder:
                (context, AsyncSnapshot<OtherCollectionResponse?> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingCard();
              } else if (snapshot.hasError) {
                return _buildErrorCard(
                    "Imeshindikana kupakia data ya michango.");
              } else if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
                String message = selectedUser != null
                    ? "Hakuna data ya michango iliyopatikana ya ${selectedUser!.userFullName}."
                    : "Hakuna data ya michango iliyopatikana.";
                return _buildEmptyCard(message);
              }

              final collections = snapshot.data!.data;
              return _buildCollectionsList(collections, size);
            },
          ),
        ),

        // Secondary list (if needed)
        if (selectedTabIndex == 1 && !viewTable)
          Expanded(
            child: FutureBuilder(
              future: getUserCollections(),
              builder:
                  (context, AsyncSnapshot<OtherCollectionResponse?> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingCard();
                } else if (snapshot.hasError) {
                  return _buildErrorCard(
                      "Imeshindikana kupakia data ya michango.");
                } else if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
                  return _buildEmptyCard(
                      "Hakuna data ya michango iliyopatikana.");
                }

                final collections = snapshot.data!.data;
                return _buildCollectionsList(collections, size,
                    isSecondary: true);
              },
            ),
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

  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(40),
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
            CircularProgressIndicator(color: mainFontColor),
            const SizedBox(height: 2),
            Text(
              "Inatafuta...",
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

  Widget _buildErrorCard(String message) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(30),
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
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(30),
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
            Icon(Icons.inbox_outlined, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 2),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionsList(List<dynamic> collections, Size size,
      {bool isSecondary = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        itemCount: collections.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = collections[index];
          return _buildCollectionCard(item, size, isSecondary);
        },
      ),
    );
  }

  Widget _buildCollectionCard(dynamic item, Size size, bool isSecondary) {
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
                item.user.userFullName.isNotEmpty
                    ? item.user.userFullName[0].toUpperCase()
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
                    item.user.userFullName,
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
                    isSecondary
                        ? item.monthly
                        : item.collectionType.collectionName,
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

            // Premium badge (if applicable)
            if (true) ...[
              _buildContributorBadge(double.parse(item.amount)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContributorBadge(double amount) {
    IconData icon;
    Color color;

    if (amount >= 1000000) {
      icon = Icons.diamond;
      color = Colors.blue;
    } else if (amount >= 500000) {
      icon = Icons.star;
      color = Colors.amber;
    } else if (amount >= 100000) {
      icon = Icons.workspace_premium;
      color = Colors.brown;
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(4),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }

  void _showCollectionDetails(
      BuildContext rootContext, OtherCollection dataItem) {
    final user = dataItem.user;
    final year = dataItem.churchYearEntity;

    showModalBottomSheet(
      context: context,
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
                                  child: AddOtherMonthCollectionUserAdmin(
                                    rootContext: rootContext,
                                    initialData: dataItem,
                                    onSubmit: (data) {
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
                                _buildDetailRow(
                                    Icons.category,
                                    "Aina ya Mchango",
                                    dataItem.collectionType.collectionName),
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

  Widget _buildPremiumFeaturesFAB() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (true) ...[
          FloatingActionButton.small(
            heroTag: 'export_pdf',
            onPressed: () => _exportToPDF(),
            backgroundColor: Colors.blue,
            child: const Icon(Icons.picture_as_pdf),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'export_excel',
            onPressed: () => _exportToExcel(),
            backgroundColor: Colors.green,
            child: const Icon(Icons.table_chart),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'detailed_report',
            onPressed: () => _showDetailedReport(),
            backgroundColor: Colors.purple,
            child: const Icon(Icons.analytics),
          ),
          const SizedBox(height: 16),
        ],
        if (!(false)) ...[
          FloatingActionButton.small(
            heroTag: 'upgrade',
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
            child: const Text('Later'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.star),
            label: const Text('Upgrade Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black87,
            ),
            onPressed: () {
              Navigator.pop(context);
              // Navigate to subscription page
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
      setState(() => isLoading = true);
      final pdf = pw.Document();

      // Create data array
      final tableData = collectionsOthers?.data.map((item) {
            return [
              item.user.userFullName ?? '',
              'TZS ${NumberFormat("#,##0").format(int.parse(item.amount))}',
              item.collectionType.collectionName,
              item.monthly,
              item.registeredDate,
            ];
          }).toList() ??
          [];

      // Debug: Print the data length

      // Define rows per page (adjust based on your needs)
      const int rowsPerPage = 20; // Reduced due to extra column

      // Calculate number of pages needed
      int totalPages = (tableData.length / rowsPerPage).ceil();
      if (totalPages == 0) totalPages = 1; // At least one page

      // Calculate total amount for summary
      int totalAmount = 0;
      collectionsOthers?.data.forEach((item) {
        try {
          totalAmount += int.parse(item.amount);
        } catch (e) {
          // print('Error parsing amount: ${item.amount}');
        }
      });

      // Create pages with data
      for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
        final startIndex = pageIndex * rowsPerPage;
        final endIndex = (startIndex + rowsPerPage > tableData.length)
            ? tableData.length
            : startIndex + rowsPerPage;

        final pageData = tableData.sublist(startIndex, endIndex);

        pdf.addPage(
          pw.Page(
            orientation: pw.PageOrientation.landscape, // Better for 5 columns
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
                        pw.Text('Ripoti ya Michango Mengineyo',
                            style: pw.TextStyle(
                                fontSize: 20, font: pw.Font.courierBold())),
                        pw.Text(
                          DateFormat('dd/MM/yyyy').format(DateTime.now()),
                          style: const pw.TextStyle(
                            color: PdfColors.black,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Page info
                  pw.Text(
                    'Ukurasa ${pageIndex + 1} wa $totalPages',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 8),

                  // Table
                  pw.Expanded(
                    child: pw.Table(
                      border: pw.TableBorder.all(),
                      columnWidths: {
                        0: const pw.FlexColumnWidth(2.5), // Name column
                        1: const pw.FlexColumnWidth(1.5), // Amount column
                        2: const pw.FlexColumnWidth(2), // Type column
                        3: const pw.FlexColumnWidth(1.5), // Month column
                        4: const pw.FlexColumnWidth(1.5), // Date column
                      },
                      children: [
                        // Header row (show on every page)
                        pw.TableRow(
                          decoration:
                              pw.BoxDecoration(color: PdfColors.grey300),
                          children: [
                            'Mwanajumuiya',
                            'Kiasi',
                            'Aina',
                            'Mwezi',
                            'Tarehe'
                          ]
                              .map((header) => pw.Container(
                                    padding: const pw.EdgeInsets.all(4),
                                    child: pw.Text(
                                      header,
                                      style: pw.TextStyle(
                                        font: pw.Font.courierBold(),
                                        fontSize: 8,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                        // Data rows for this page
                        ...pageData.map((row) => pw.TableRow(
                              children: row
                                  .map((cell) => pw.Container(
                                        padding: const pw.EdgeInsets.all(4),
                                        child: pw.Text(
                                          cell.toString(),
                                          style: pw.TextStyle(fontSize: 7),
                                        ),
                                      ))
                                  .toList(),
                            )),
                      ],
                    ),
                  ),

                  // Summary (show only on last page)
                  if (pageIndex == totalPages - 1) ...[
                    pw.SizedBox(height: 10),
                    pw.Divider(),
                    pw.Text(
                      'Jumla ya Michango: TZS ${NumberFormat("#,##0").format(totalAmount)}',
                      style: pw.TextStyle(
                        font: pw.Font.courierBold(),
                        fontSize: 10,
                      ),
                    ),
                    pw.Text(
                      'Jumla ya Wanajumuiya: ${tableData.length}',
                      style: pw.TextStyle(
                        font: pw.Font.courierBold(),
                        fontSize: 9,
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
                        pw.Text('Ripoti ya Michango Mengineyo',
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
          'Ripoti_Mengineyo_${DateFormat('dd_MM_yyyy').format(DateTime.now())}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Share the actual PDF file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Ripoti ya Michango Mengineyo',
        subject: fileName,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hitilafu: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _exportToExcel() async {
    try {
      setState(() => isLoading = true);
      var excel = Excel.createExcel();
      var sheet = excel['Michango'];

      // Add headers
      sheet.appendRow([
        'Mwanajumuiya',
        'Kiasi',
        'Aina ya Mchango',
        'Mwezi',
        'Tarehe ya Usajili'
      ]);

      // Add data
      collectionsOthers?.data.forEach((item) {
        sheet.appendRow([
          item.user.userFullName,
          item.amount,
          item.collectionType.collectionName,
          item.monthly,
          item.registeredDate,
        ]);
      });

      // Save and share
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
          '${directory.path}/michango_${DateTime.now().millisecondsSinceEpoch}.xlsx');
      await file.writeAsBytes(excel.encode()!);

      await Share.share(
        'Ripoti ya Michango (Excel)',
        subject:
            'Ripoti_${DateFormat('dd_MM_yyyy').format(DateTime.now())}.xlsx',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hitilafu: $e')),
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

  Widget _buildLineChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                if (value.toInt() < months.length) {
                  return Text(months[value.toInt()]);
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              const FlSpot(0, 3),
              const FlSpot(1, 1),
              const FlSpot(2, 4),
              const FlSpot(3, 2),
              const FlSpot(4, 5),
              const FlSpot(5, 3),
            ],
            isCurved: true,
            color: Colors.purple,
            barWidth: 3,
            dotData: FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    return PieChart(
      PieChartData(
        sectionsSpace: 0,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            color: Colors.blue,
            value: 40,
            title: '40%',
            radius: 50,
          ),
          PieChartSectionData(
            color: Colors.red,
            value: 30,
            title: '30%',
            radius: 50,
          ),
          PieChartSectionData(
            color: Colors.green,
            value: 30,
            title: '30%',
            radius: 50,
          ),
        ],
      ),
    );
  }

  Widget _buildTopContributorsCard() {
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
          ...List.generate(
            3,
            (index) => _buildTopContributorItem(
              name: 'Mwanajumuiya ${index + 1}',
              amount: (3 - index) * 500000,
              rank: index + 1,
            ),
          ),
        ],
      ),
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
}
