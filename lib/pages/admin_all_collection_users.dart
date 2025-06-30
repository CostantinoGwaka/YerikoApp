import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yeriko_app/main.dart';
import 'package:yeriko_app/models/auth_model.dart';
import 'package:yeriko_app/models/user_collection_model.dart';
import 'package:yeriko_app/models/user_collection_table_model.dart';
import 'package:yeriko_app/pages/add_pages/add_month_collection.dart';
import 'package:yeriko_app/pages/admin_all_other_collection_users.dart';
import 'package:yeriko_app/pages/supports_pages/collection_table_against_month.dart';
import 'package:yeriko_app/theme/colors.dart';
import 'package:yeriko_app/utils/url.dart';
import 'package:http/http.dart' as http;

class AdminAllUserCollections extends StatefulWidget {
  const AdminAllUserCollections({super.key});

  @override
  State<AdminAllUserCollections> createState() => _AdminAllUserCollectionsState();
}

class _AdminAllUserCollectionsState extends State<AdminAllUserCollections> {
  CollectionResponse? collectionsMonthly;
  CollectionResponse? collectionsOthers;
  UserMonthlyCollectionResponse? userMonthlyCollectionResponse;
  int selectedTabIndex = 0;
  bool viewTable = false;
  bool isLoading = false;

  //month
  String filterOption = 'TAARIFA ZOTE';
  User? selectedUser;
  String? selectedMonth;

  List<String> filterOptions = ['TAARIFA ZOTE', 'TAARIFA KWA MWANAJUMUIYA', 'KWA MWEZI'];
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
    getUserCollections();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    final response =
        await http.get(Uri.parse('$baseUrl/auth/get_all_users.php?jumuiya_id=${userData!.user.jumuiya_id}'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        users = (data['data'] as List).map((u) => User.fromJson(u)).toList();
      });
    } else {
      // handle error
    }
  }

  void loadData() {
    setState(() {
      if (filterOption == 'TAARIFA ZOTE') {
        displayedData = allData;
      } else if (filterOption == 'TAARIFA KWA MWANAJUMUIYA' && selectedUser != null) {
        getUserYearCollections();
      } else if (filterOption == 'KWA MWEZI' && selectedMonth != null) {
        displayedData = allData.where((item) => item.monthly == selectedMonth).toList();
      }
    });
  }

  Future<void> _reloadData() async {
    await getUserCollections();
    setState(() {}); // Refresh UI after fetching data
  }

  Future<CollectionResponse?> getUserCollections() async {
    try {
      if (userData?.user.id == null || userData!.user.id.toString().isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please provide username and password")),
          );
        }
        // setState(() => _isLoading = false);
        return null;
      }

      final String myApi =
          "$baseUrl/monthly/get_all_collection_user_by_year.php?yearId=${currentYear!.data.id}&jumuiya_id=${userData!.user.jumuiya_id}";
      final response = await http.get(Uri.parse(myApi), headers: {'Accept': 'application/json'});

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
          SnackBar(content: Text("Tafadhali hakikisha umeunganishwa na intaneti: $e")),
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
            const SnackBar(content: Text("Please provide username and password")),
          );
        }
        setState(() {
          isLoading = false;
        });
        return null;
      }

      final String myApi =
          "$baseUrl/monthly/get_all_collection_year_id_table_data.php?year_id=${currentYear!.data.id}&jumuiya_id=${userData!.user.jumuiya_id}";
      final response = await http.get(Uri.parse(myApi), headers: {'Accept': 'application/json'});

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse != null) {
          setState(() {
            isLoading = false;
          });
          userMonthlyCollectionResponse = UserMonthlyCollectionResponse.fromJson(jsonResponse);
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
          SnackBar(content: Text("Tafadhali hakikisha umeunganishwa na intaneti: $e")),
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
            const SnackBar(content: Text("Please provide username and password")),
          );
        }
        // setState(() => _isLoading = false);
        return null;
      }

      final String myApi =
          "$baseUrl/monthly/get_all_collection_by_month.php?month=$selectedMonth&jumuiya_id=${userData!.user.jumuiya_id}";
      final response = await http.get(Uri.parse(myApi), headers: {'Accept': 'application/json'});

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
          SnackBar(content: Text("Tafadhali hakikisha umeunganishwa na intaneti: $e")),
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
            const SnackBar(content: Text("Please provide username and password")),
          );
        }
        // setState(() => _isLoading = false);
        return null;
      }

      final String myApi =
          "$baseUrl/monthly/get_all_collection_by_user_id_year_id.php?user_id=${selectedUser!.id}&year_id=${currentYear!.data.id}";

      final response = await http.get(Uri.parse(myApi), headers: {'Accept': 'application/json'});

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
          SnackBar(content: Text("Tafadhali hakikisha umeunganishwa na intaneti: $e")),
        );
      }
    }

    // 🔁 Always return something to complete Future
    return null;
  }

  Future<void> deleteTimeTable(dynamic id) async {
    try {
      final String myApi = "$baseUrl/church_timetable/delete_time_table.php?id=$id";
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
          const SnackBar(content: Text('Ratiba imefutwa kikamirifu.')),
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
        SnackBar(content: Text("Tafadhali hakikisha umeunganishwa na intaneti: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primary,
      body: RefreshIndicator(onRefresh: _reloadData, child: getBody()),
    );
  }

  Widget getBody() {
    var size = MediaQuery.of(context).size;

    return SafeArea(
        child: SingleChildScrollView(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: primary,
              boxShadow: [
                BoxShadow(
                  color: grey.withAlpha((0.01 * 255).toInt()),
                  spreadRadius: 10,
                  blurRadius: 3,
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.only(top: 20, bottom: 25, right: 20, left: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text(""), Icon(CupertinoIcons.search)],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Padding(
            padding: EdgeInsets.only(left: 25, right: 25, bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Michango",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: mainFontColor,
                    )),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 5, bottom: 20, left: 25, right: 25),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedTabIndex = 0;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.only(left: 25, right: 25, top: 5, bottom: 5),
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          color: selectedTabIndex == 0 ? buttoncolor : white,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Center(
                          child: Text(
                            "Mwezi",
                            style: TextStyle(
                              color: selectedTabIndex == 0 ? Colors.white : Colors.black.withAlpha((0.5 * 255).toInt()),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedTabIndex = 1;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.only(left: 25, right: 25, top: 5, bottom: 5),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: selectedTabIndex == 1 ? buttoncolor : white,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Center(
                          child: Text(
                            "Mingineyo",
                            style: TextStyle(
                              color: selectedTabIndex == 1 ? Colors.white : Colors.black.withAlpha((0.5 * 255).toInt()),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          // Display loading indicator while fetching data
          Visibility(
              visible: viewTable,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainFontColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.close, size: 15),
                      label: const Text(
                        "Funga michango",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      onPressed: () async {
                        setState(() {
                          viewTable = !viewTable;
                        });
                        if (viewTable) {
                          await getUserCollectionAgainstTable();
                        }
                      },
                    ),
                  ),
                  isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : UserMonthlyCollectionTable(data: userMonthlyCollectionResponse),
                ],
              )),
          Visibility(
            visible: selectedTabIndex == 0 && !viewTable,
            child: SizedBox(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: (size.width - 40) / 30),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 2, right: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
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
                                icon: const Icon(Icons.table_chart, size: 15),
                                label: const Text(
                                  "Tazama Michango",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                onPressed: () async {
                                  setState(() {
                                    viewTable = !viewTable;
                                  });
                                  if (viewTable) {
                                    await getUserCollectionAgainstTable();
                                  }
                                },
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
                                icon: const Icon(Icons.plus_one, size: 15),
                                label: const Text(
                                  "Ongeza Mchango",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                                    ),
                                    builder: (_) => AddMonthCollectionUserAdmin(
                                      rootContext: context,
                                      onSubmit: (data) {
                                        _reloadData();
                                      },
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: EdgeInsets.only(top: (size.height - 40) / 60),
                          child: DropdownButtonFormField<String>(
                            value: filterOption,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              filled: true,
                              fillColor: Colors.grey[200], // Light background color
                              hintText: "Chagua Aina ya Utafutaji",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30), // <-- Rounded edges
                                borderSide: BorderSide.none, // No visible border
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                filterOption = value!;
                                selectedUser = null;
                                selectedMonth = null;
                                loadData();
                              });
                            },
                            items: filterOptions.map((option) {
                              return DropdownMenuItem(
                                value: option,
                                child: Text(option),
                              );
                            }).toList(),
                          ),
                        ),
                        if (filterOption == 'TAARIFA KWA MWANAJUMUIYA')
                          Padding(
                            padding: EdgeInsets.only(top: (size.height - 40) / 60),
                            child: DropdownButtonFormField<User>(
                              value: selectedUser,
                              isExpanded: true,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                filled: true,
                                fillColor: Colors.grey[200], // Light background color
                                hintText: "Chagua Mwanajumuiya",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30), // <-- Rounded edges
                                  borderSide: BorderSide.none, // No visible border
                                ),
                              ),
                              items: users.map((user) {
                                return DropdownMenuItem<User>(
                                  value: user,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.person, color: Colors.blueGrey, size: 20),
                                      const SizedBox(width: 8),
                                      Text(user.userFullName ?? ''),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (user) {
                                if (user != null) {
                                  setState(() {
                                    selectedUser = user;
                                  });
                                  loadData();
                                }
                              },
                            ),
                          ),
                        if (filterOption == 'KWA MWEZI')
                          Padding(
                            padding: EdgeInsets.only(top: (size.height - 40) / 60),
                            child: DropdownButtonFormField<String>(
                              value: selectedMonth,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                filled: true,
                                fillColor: Colors.grey[200], // Light background
                                hintText: "Chagua Mwezi",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30), // <-- Rounded border
                                  borderSide: BorderSide.none, // Remove border line
                                ),
                              ),
                              hint: const Text("Chagua Mwezi"),
                              onChanged: (value) {
                                setState(() {
                                  selectedMonth = value;
                                  loadData();
                                });
                              },
                              items: months.map((month) {
                                return DropdownMenuItem(
                                  value: month,
                                  child: Text(month),
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder(
                    future: filterOption == 'TAARIFA ZOTE'
                        ? getUserCollections()
                        : (filterOption == 'TAARIFA KWA MWANAJUMUIYA' && selectedUser != null)
                            ? getUserYearCollections()
                            : (filterOption == 'KWA MWEZI' && selectedMonth != null)
                                ? getUserMonthCollections()
                                : getUserCollections(),
                    builder: (context, AsyncSnapshot<CollectionResponse?> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return const Center(child: Text("Imeshindikana kupakia data ya michango."));
                      } else if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
                        return const Center(child: Text("Hakuna data ya michango iliyopatikana."));
                      }

                      final collections = snapshot.data!.data;

                      return ListView.builder(
                        itemCount: collections.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final item = collections[index];
                          return GestureDetector(
                            onTap: () => _showCollectionDetails(context, item),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      margin: EdgeInsets.only(
                                        top: (size.width - 40) / 30,
                                        left: (size.width - 40) / 20,
                                        right: (size.width - 40) / 20,
                                        bottom: (size.width - 40) / 30,
                                      ),
                                      decoration: BoxDecoration(
                                          color: white,
                                          borderRadius: BorderRadius.circular(25),
                                          boxShadow: [
                                            BoxShadow(
                                              color: grey.withValues(alpha: (0.03 * 255)),
                                              spreadRadius: 10,
                                              blurRadius: 3,
                                              // changes position of shadow
                                            ),
                                          ]),
                                      child: Padding(
                                        padding: const EdgeInsets.all(2),
                                        child: Row(
                                          children: [
                                            const SizedBox(width: 2),
                                            Expanded(
                                              child: SizedBox(
                                                width: (size.width - 90) * 0.2,
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        const Text("👤 ", style: TextStyle(fontSize: 15)),
                                                        Expanded(
                                                          child: Text(
                                                            "${item.user.userFullName}",
                                                            style: const TextStyle(
                                                              fontSize: 15,
                                                              color: Colors.black,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Row(
                                                      children: [
                                                        const Text("💰 ", style: TextStyle(fontSize: 15)),
                                                        Expanded(
                                                          child: Text(
                                                            "TZS ${NumberFormat("#,##0", "en_US").format(int.parse(item.amount))} (${item.monthly})",
                                                            style: const TextStyle(
                                                              fontSize: 15,
                                                              color: Colors.black,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 5),
                                                    Row(
                                                      children: [
                                                        const Text("🗓 ", style: TextStyle(fontSize: 12)),
                                                        Expanded(
                                                          child: Text(
                                                            item.registeredDate,
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.black.withAlpha((0.5 * 255).toInt()),
                                                            ),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 5),
                                                    Row(
                                                      children: [
                                                        const Text("📆 ", style: TextStyle(fontSize: 12)),
                                                        Expanded(
                                                          child: Text(
                                                            item.churchYearEntity.churchYear,
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.black.withAlpha((0.5 * 255).toInt()),
                                                            ),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              size: 16,
                                              color: Colors.black,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Visibility(
            visible: selectedTabIndex == 1 && !viewTable,
            child: SizedBox(
              child: AdminOtherAllUserCollections(),
            ),
          )
        ],
      ),
    ));
  }

  void _showCollectionDetails(BuildContext rootContext, CollectionItem item) {
    final user = item.user;
    final year = item.churchYearEntity;
    var size = MediaQuery.of(context).size;

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "📋 Maelezo ya Mchango",
                      style: TextStyle(fontSize: (size.width - 40) / 30, fontWeight: FontWeight.bold),
                    ),
                    if (userData!.user.role == "ADMIN") ...[
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            tooltip: 'Hariri',
                            onPressed: () {
                              Navigator.pop(context); // Close bottom sheet
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                                ),
                                builder: (_) => AddMonthCollectionUserAdmin(
                                  rootContext: rootContext,
                                  initialData: item, // Pass current item for editing
                                  onSubmit: (data) {
                                    _reloadData();
                                  },
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Futa',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Futa Ratiba'),
                                  content: const Text('Una uhakika unataka kufuta ratiba hii?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(false),
                                      child: const Text('Hapana'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(true),
                                      child: const Text('Ndiyo'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                deleteTimeTable(item.id);
                              }
                            },
                          ),
                        ],
                      ),
                    ]
                  ],
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
                    // Text("Uhai:           ${year.isActive ? 'Ndiyo' : 'Hapana'}"),
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
