import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yeriko_app/main.dart';
import 'package:yeriko_app/models/user_collection_model.dart';
import 'package:yeriko_app/theme/colors.dart';
import 'package:yeriko_app/utils/url.dart';
import 'package:http/http.dart' as http;

class AllUserCollections extends StatefulWidget {
  const AllUserCollections({super.key});

  @override
  State<AllUserCollections> createState() => _AllUserCollectionsState();
}

class _AllUserCollectionsState extends State<AllUserCollections> {
  CollectionResponse? collections;

  @override
  void initState() {
    super.initState();
    getUserCollections();
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
        SnackBar(content: Text("⚠️ Tafadhali hakikisha umeunganishwa na intaneti: $e")),
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
                Text("Michango yako yote",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: mainFontColor,
                    )),
              ],
            ),
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
                              decoration:
                                  BoxDecoration(color: white, borderRadius: BorderRadius.circular(25), boxShadow: [
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
                                                const Text("💰", style: TextStyle(fontSize: 15)),
                                                Text(
                                                  "TZS ${NumberFormat("#,##0", "en_US").format(int.parse(item.amount))} (${item.monthly})",
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 5),
                                            Row(
                                              children: [
                                                const Text("🗓 ", style: TextStyle(fontSize: 12)),
                                                Text(
                                                  item.registeredDate,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black.withAlpha((0.5 * 255).toInt()),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 5),
                                            Row(
                                              children: [
                                                const Text("📆 ", style: TextStyle(fontSize: 12)),
                                                Text(
                                                  item.churchYearEntity.churchYear,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black.withAlpha((0.5 * 255).toInt()),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 5),
                                            Row(
                                              children: [
                                                const Text("🖊 ", style: TextStyle(fontSize: 12)),
                                                Expanded(
                                                  child: Text(
                                                    'Imesajiliwa na: ${item.registeredBy}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.black.withValues(alpha: 128),
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
          // Container(
          //   padding: const EdgeInsets.all(16),
          //   margin: const EdgeInsets.all(25),
          //   decoration: BoxDecoration(color: buttoncolor, borderRadius: BorderRadius.circular(25)),
          //   child: const Center(
          //     child: Text(
          //       "See Details",
          //       style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          //     ),
          //   ),
          // ),
        ],
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
