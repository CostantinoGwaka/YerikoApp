import 'dart:convert';
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

class AdminOtherAllUserCollections extends StatefulWidget {
  const AdminOtherAllUserCollections({super.key});

  @override
  State<AdminOtherAllUserCollections> createState() => _AdminOtherAllUserCollectionsState();
}

class _AdminOtherAllUserCollectionsState extends State<AdminOtherAllUserCollections> {
  OtherCollectionResponse? collectionsOthers;
  UserMonthlyCollectionResponse? userMonthlyCollectionResponse;
  int selectedTabIndex = 0;
  bool viewTable = false;
  bool isLoading = false;

  //month
  String filterOption = 'TAARIFA ZOTE';
  User? selectedUser;
  CollectionType? selectedCollectionType;
  String? selectedMonth;

  List<String> filterOptions = ['TAARIFA ZOTE', 'TAARIFA KWA MWANAJUMUIYA', 'KWA MWEZI', 'KWA AINA YA MCHANGO'];
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

  Future<void> fetchCollectionTypes() async {
    collectionTypeResponse = [];
    final response = await http
        .get(Uri.parse('$baseUrl/collectiontype/get_all_collection_type.php?jumuiya_id=${userData!.user.jumuiya_id}'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        collectionTypeResponse = (data['data'] as List).map((u) => CollectionType.fromJson(u)).toList();
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
      } else if (filterOption == 'TAARIFA KWA MWANAJUMUIYA' && selectedUser != null) {
        getUserYearCollections();
      } else if (filterOption == 'KWA MWEZI' && selectedMonth != null) {
        displayedData = allData.where((item) => item.monthly == selectedMonth).toList();
      } else if (filterOption == 'KWA AINA YA MCHANGO' && selectedMonth != null) {
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
            const SnackBar(content: Text("⚠️ Hakuna taarifa zaidi kuwezesha kupata taarifa")),
          );
        }
        // setState(() => _isLoading = false);
        return null;
      }

      final String myApi =
          "$baseUrl/monthly/get_all_other_collection_user_by_year.php?yearId=${currentYear!.data.id}&jumuiya_id=${userData!.user.jumuiya_id}";
      final response = await http.get(Uri.parse(myApi), headers: {'Accept': 'application/json'});

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse != null) {
          // setState(() => _isLoading = false);
          collectionsOthers = OtherCollectionResponse.fromJson(jsonResponse);

          return collectionsOthers;
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

  Future<OtherCollectionResponse?> getUserOtherByTypeCollections() async {
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

  Future<OtherCollectionResponse?> getUserMonthCollections() async {
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

  Future<OtherCollectionResponse?> getUserYearCollections() async {
    try {
      if (userData?.user.id == null || userData!.user.id.toString().isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("⚠️ Hakuna taarifa zaidi kuwezesha kupata taarifa")),
          );
        }
        return null;
      }

      final String myApi =
          "$baseUrl/monthly/get_all_other_collection_by_user_id_year_id.php?user_id=${selectedUser!.id}&year_id=${currentYear!.data.id}";

      final response = await http.get(Uri.parse(myApi), headers: {'Accept': 'application/json'});

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse != null) {
          collectionsOthers = OtherCollectionResponse.fromJson(jsonResponse);
          return collectionsOthers;
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

  Future<void> deleteTimeTable(dynamic id) async {
    try {
      final String myApi = "$baseUrl/church_timetable/delete_time_table.php?id=$id";
      final response = await http.delete(
        Uri.parse(myApi),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
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
        SnackBar(content: Text("⚠️ Tafadhali hakikisha umeunganishwa na intaneti: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(onRefresh: _reloadData, child: getBody());
  }

  Widget getBody() {
    var size = MediaQuery.of(context).size;

    return SafeArea(
        child: SingleChildScrollView(
      child: Column(
        children: [
          // Display loading indicator while fetching data'
          Visibility(
              visible: viewTable,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : UserMonthlyCollectionTable(data: userMonthlyCollectionResponse),
                ],
              )),
          Visibility(
            visible: !viewTable,
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
                              Text(""),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: mainFontColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: (size.width - 40) / 22,
                                    vertical: (size.width - 40) / 50,
                                  ),
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
                                    builder: (_) => AddOtherMonthCollectionUserAdmin(
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
                        if (filterOption == 'KWA AINA YA MCHANGO')
                          Padding(
                            padding: EdgeInsets.only(top: (size.height - 40) / 60),
                            child: DropdownButtonFormField<CollectionType>(
                              value: selectedCollectionType,
                              isExpanded: true,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                filled: true,
                                fillColor: Colors.grey[200], // Light background color
                                hintText: "Chagua Aina ya Mchango",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30), // <-- Rounded edges
                                  borderSide: BorderSide.none, // No visible border
                                ),
                              ),
                              items: collectionTypeResponse.map((type) {
                                return DropdownMenuItem<CollectionType>(
                                  value: type,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.person, color: Colors.blueGrey, size: 20),
                                      const SizedBox(width: 8),
                                      Text(type.collectionName),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (type) {
                                if (type != null) {
                                  setState(() {
                                    selectedCollectionType = type;
                                  });
                                  loadData();
                                }
                              },
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
                                      : (filterOption == 'KWA AINA YA MCHANGO' && selectedCollectionType != null)
                                          ? getUserOtherByTypeCollections()
                                          : getUserCollections(),
                          builder: (context, AsyncSnapshot<OtherCollectionResponse?> snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return const Center(child: Text("Imeshindikana kupakia data ya michango."));
                            } else if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
                              if (selectedUser != null) {
                                return Center(
                                    child: Text(
                                        "Hakuna data ya michango iliyopatikana ya ${selectedUser!.userFullName}."));
                              } else {
                                return const Center(child: Text("Hakuna data ya michango iliyopatikana."));
                              }
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
                                                          Text(
                                                            "👤 ${item.user.userFullName}",
                                                            style: const TextStyle(
                                                              fontSize: 15,
                                                              color: Colors.black,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                          Text(
                                                            "💰 TZS ${NumberFormat("#,##0", "en_US").format(int.parse(item.amount))} (${item.collectionType.collectionName})",
                                                            style: const TextStyle(
                                                              fontSize: 15,
                                                              color: Colors.black,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 5),
                                                          Text(
                                                            "📅 ${item.registeredDate}",
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.black.withAlpha((0.5 * 255).toInt()),
                                                            ),
                                                          ),
                                                          const SizedBox(height: 5),
                                                          Text(
                                                            "🗓 ${item.churchYearEntity.churchYear}",
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.black.withAlpha((0.5 * 255).toInt()),
                                                            ),
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
                  Visibility(
                    visible: selectedTabIndex == 1 && !viewTable,
                    child: SizedBox(
                      child: FutureBuilder(
                        future: getUserCollections(),
                        builder: (context, AsyncSnapshot<OtherCollectionResponse?> snapshot) {
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
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 14), // less padding

                                            child: Row(
                                              children: [
                                                const SizedBox(width: 2),
                                                Expanded(
                                                  child: SizedBox(
                                                    width: (size.width - 90) * 0.2,
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          "👤 ${item.user.userFullName}",
                                                          style: const TextStyle(
                                                            fontSize: 15,
                                                            color: Colors.black,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                        Text(
                                                          "💰 TZS ${NumberFormat("#,##0", "en_US").format(int.parse(item.amount))} (${item.monthly})",
                                                          style: const TextStyle(
                                                            fontSize: 15,
                                                            color: Colors.black,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 5),
                                                        Text(
                                                          "📅 ${item.registeredDate}",
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.black.withAlpha((0.5 * 255).toInt()),
                                                          ),
                                                        ),
                                                        const SizedBox(height: 5),
                                                        Text(
                                                          "🗓 ${item.churchYearEntity.churchYear}",
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.black.withAlpha((0.5 * 255).toInt()),
                                                          ),
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
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    ));
  }

  void _showCollectionDetails(BuildContext rootContext, OtherCollection dataItem) {
    final user = dataItem.user;
    final year = dataItem.churchYearEntity;
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
                                builder: (_) => AddOtherMonthCollectionUserAdmin(
                                  rootContext: rootContext,
                                  initialData: dataItem,
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
                                deleteTimeTable(dataItem.id);
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
                    Text("💰 Kiasi:        TZS ${NumberFormat("#,##0", "en_US").format(int.parse(dataItem.amount))}"),
                    const SizedBox(height: 4),
                    Text("🗓 Mwezi:        ${dataItem.monthly}"),
                    const SizedBox(height: 4),
                    Text("📅 Tarehe ya Usajili: ${dataItem.registeredDate}"),
                    const SizedBox(height: 4),
                    Text("🖊 Aliyesajili:   ${dataItem.registeredBy}"),
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
