import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yeriko_app/main.dart';
import 'package:yeriko_app/models/all_users_model.dart';
import 'package:yeriko_app/pages/add_pages/add_time_table.dart';
import 'package:yeriko_app/theme/colors.dart';
import 'package:yeriko_app/utils/url.dart';
import 'package:http/http.dart' as http;

class AllViewerUserWithAdmin extends StatefulWidget {
  const AllViewerUserWithAdmin({super.key});

  @override
  State<AllViewerUserWithAdmin> createState() => _AllViewerUserWithAdminState();
}

class _AllViewerUserWithAdminState extends State<AllViewerUserWithAdmin> {
  AllUsersResponse? collections;

  @override
  void initState() {
    super.initState();
    getUsersCollections();
  }

  Future<void> _reloadData() async {
    await getUsersCollections();
    setState(() {}); // Refresh UI after fetching data
  }

  Future<AllUsersResponse?> getUsersCollections() async {
    try {
      final String myApi = "$baseUrl/auth/get_all_users.php?jumuiya_id=${userData!.user.jumuiya_id}";
      final response = await http.get(Uri.parse(myApi), headers: {'Accept': 'application/json'});

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse != null) {
          collections = AllUsersResponse.fromJson(jsonResponse);
          return collections;
        }
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
                Text("Wanajumuiya wote",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: mainFontColor,
                    )),
                if (userData != null && userData!.user.role == "ADMIN") ...[
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
                      "Ongeza",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                        ),
                        builder: (_) => AddPrayerSchedulePage(
                          rootContext: context,
                          onSubmit: (data) {
                            _reloadData();
                          },
                        ),
                      );
                    },
                  ),
                ]
              ],
            ),
          ),
          FutureBuilder(
            future: getUsersCollections(),
            builder: (context, AsyncSnapshot<AllUsersResponse?> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Center(child: Text("Imeshindikana kupakia taarifa za wanajumuiya."));
              } else if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
                return const Center(child: Text("Hakuna taarifa za wanajumuiya zilizopatikana."));
              }

              final collections = snapshot.data!.data;

              return ListView.builder(
                itemCount: collections.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final item = collections[index];
                  return GestureDetector(
                    onTap: () => _showChurchTimeTableDetails(context, item),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.only(
                                top: (size.width - 40) / 40,
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
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  item.userFullName ?? "Jina Halipo",
                                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: item.role == "ADMIN" ? Colors.redAccent : Colors.blueAccent,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  item.role ?? "Role Halipo",
                                                  style: const TextStyle(
                                                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                  child: Text("Jina la mtumiaji: ${item.userName}",
                                                      style: const TextStyle(fontSize: 12))),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              const Icon(Icons.phone, size: 14, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                  child: Text("Namba ya simu: ${item.phone}",
                                                      style: const TextStyle(fontSize: 12))),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                  child: Text("Mwaka wa usajili: ${item.yearRegistered}",
                                                      style: const TextStyle(fontSize: 12))),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: ElevatedButton.icon(
                                              icon: const Icon(Icons.call, color: Colors.white, size: 14),
                                              label: const Text("Piga Simu", style: TextStyle(fontSize: 12)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                elevation: 0,
                                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                minimumSize: Size(0, 28),
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              onPressed: () async {
                                                final phone = (item.phone ?? '').replaceAll(' ', '');
                                                String formattedPhone = formatPhoneNumber(phone);
                                                if (phone.isNotEmpty) {
                                                  final Uri url = Uri.parse('tel:$formattedPhone');
                                                  if (await canLaunchUrl(url)) {
                                                    await launchUrl(url);
                                                  } else {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text("Imeshindikana kupiga simu.")),
                                                    );
                                                  }
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  //
                                ],
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
    ));
  }

  void _showChurchTimeTableDetails(BuildContext rootContext, item) {
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
          initialChildSize: 0.6,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, controller) => SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      "📋 Maelezo ya Ratiba ya Jumuiya",
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
                                builder: (_) => AddPrayerSchedulePage(
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
                const Divider(height: 20),
                // 🕊 Ratiba ya Maombi
                const Text("🕊 Taarifa za Jumuiya", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildDetailRow("Tarehe ya Maombi", item.datePrayer),
                _buildDetailRow("Mahali", item.location),
                _buildDetailRow("Ujumbe", item.message),
                _buildDetailRow("Latitiude ID", item.latId),
                _buildDetailRow("Longitude ID", item.longId),
                _buildDetailRow("Tarehe ya Usajili", item.createdAt),
                _buildDetailRow("Aliyesajili", item.registeredBy),

                const SizedBox(height: 16),

                // 👤 Mtumiaji
                const Text("👤 Taarifa za Mwenyeji", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildDetailRow("Jina Kamili", user?.userFullName),
                _buildDetailRow("Jina la Mtumiaji", user?.userName),
                _buildDetailRow("Simu", user?.phone),
                _buildDetailRow("Nafasi", user?.role),
                _buildDetailRow("Mwaka wa Usajili", user?.yearRegistered),
                _buildDetailRow("Alisajiliwa Tarehe", user?.createdAt),

                const SizedBox(height: 16),

                // 📆 Mwaka wa Kanisa
                const Text("📆 Taarifa za Mwaka wa Kanisa", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildDetailRow("Mwaka", year?.churchYear),
                // _buildDetailRow("Uhai", year?.isActive == true ? "Ndiyo" : "Hapana"),

                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.call),
                      label: const Text("Piga Simu"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final phone = user.phone?.replaceAll(' ', '') ?? '';
                        String formattedPhone = formatPhoneNumber(phone);
                        if (phone.isNotEmpty) {
                          final Uri url = Uri.parse('tel:$formattedPhone');
                          // ignore: deprecated_member_use
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          } else {
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Imeshindikana kupiga simu.")),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String formatPhoneNumber(String phone) {
    if (phone.startsWith("255") && phone.length > 3) {
      return "0${phone.substring(3)}";
    }
    return phone;
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value ?? "Haipo",
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }
}
