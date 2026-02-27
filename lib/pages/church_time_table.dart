import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jumuiya_yangu/main.dart';
// ignore: library_prefixes
import 'package:jumuiya_yangu/models/church_time_table.dart' as TimeTableModel;
import 'package:jumuiya_yangu/pages/add_pages/add_time_table.dart';
import 'package:jumuiya_yangu/theme/colors.dart';
import 'package:jumuiya_yangu/utils/url.dart';
import 'package:jumuiya_yangu/shared/components/modern_widgets.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ChurchTimeTable extends StatefulWidget {
  const ChurchTimeTable({super.key});

  @override
  State<ChurchTimeTable> createState() => _ChurchTimeTableState();
}

class _ChurchTimeTableState extends State<ChurchTimeTable> {
  TimeTableModel.ChurchTimeTableResponse? collections;
  late Box _timeTableBox;
  bool _isOnline = true;
  final Connectivity _connectivity = Connectivity();

  @override
  void initState() {
    super.initState();
    _initHive();
    _checkConnectivity();
    getTimeTableCollections();
  }

  Future<void> _initHive() async {
    _timeTableBox = await Hive.openBox('church_time_table');
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    setState(() {
      _isOnline = !connectivityResult.contains(ConnectivityResult.none);
    });

    _connectivity.onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      setState(() {
        _isOnline = !result.contains(ConnectivityResult.none);
      });
      if (_isOnline) {
        getTimeTableCollections();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _reloadData() async {
    await getTimeTableCollections();
    setState(() {}); // Refresh UI after fetching data
  }

  Future<TimeTableModel.ChurchTimeTableResponse?>
      getTimeTableCollections() async {
    // Check connectivity first
    final connectivityResult = await _connectivity.checkConnectivity();
    final isConnected = !connectivityResult.contains(ConnectivityResult.none);

    if (!isConnected) {
      // Load from Hive when offline
      return _loadFromHive();
    }

    try {
      final String myApi =
          "$baseUrl/church_timetable/get_all.php?jumuiya_id=${userData!.user.jumuiya_id}";
      final response = await http.get(Uri.parse(myApi), headers: {
        'Accept': 'application/json'
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse != null) {
          collections =
              TimeTableModel.ChurchTimeTableResponse.fromJson(jsonResponse);

          // Save to Hive for offline access
          await _saveToHive(jsonResponse);

          return collections;
        }
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: Colors.red,
              content: Text("Error: ${response.statusCode}")),
        );
        // Load from cache if API fails
        return _loadFromHive();
      }
    } catch (e) {
      // Load from Hive when there's an error
      final cachedData = _loadFromHive();

      if (cachedData != null) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.orange,
            content: Text(
              "📱 Kuonyesha data iliyohifadhiwa (Offline mode)",
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
        return cachedData;
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
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

  Future<void> _saveToHive(Map<String, dynamic> data) async {
    try {
      await _timeTableBox.put('timetable_${userData!.user.jumuiya_id}', data);
      await _timeTableBox.put('last_updated', DateTime.now().toIso8601String());
    } catch (e) {
      // Silent fail for caching
    }
  }

  TimeTableModel.ChurchTimeTableResponse? _loadFromHive() {
    try {
      final data = _timeTableBox.get('timetable_${userData!.user.jumuiya_id}');
      if (data != null) {
        return TimeTableModel.ChurchTimeTableResponse.fromJson(
          Map<String, dynamic>.from(data),
        );
      }
    } catch (e) {
      // Silent fail
    }
    return null;
  }

  Future<void> deleteTimeTable(dynamic id) async {
    // Check if online
    if (!_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text(
            "⚠️ Huwezi kufuta wakati uko offline",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    try {
      final String myApi =
          "$baseUrl/church_timetable/delete_time_table.php?id=$id";
      final response = await http.delete(
        Uri.parse(myApi),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        // ignore: use_build_context_synchronously
        Navigator.pop(context); // Close bottom sheet
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              backgroundColor: Colors.red,
              content: Text('Ratiba imefutwa kikamirifu.')),
        );
        _reloadData();
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: Colors.red,
              content: Text("Error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
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
      backgroundColor: surfaceColor,
      appBar: ModernAppBar(
        title: "Ratiba za Jumuiya",
        automaticallyImplyLeading: false,
        actions: [
          // Connectivity indicator
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isOnline
                  ? Colors.green.withOpacity(0.2)
                  : Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  _isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                  size: 16,
                  color: _isOnline ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  _isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _isOnline ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reloadData,
        color: primaryGradient[0],
        child: getBody(),
      ),
      floatingActionButton: userData?.user.role == "ADMIN" ||
              userData!.user.role == "KATIBU" ||
              userData!.user.role == "KATIBU MSAIDIZI"
          ? FloatingActionButton.extended(
              heroTag: 'home_church',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.white,
                  builder: (BuildContext context) {
                    return AddPrayerSchedulePage(
                      rootContext: context,
                      onSubmit: (data) {
                        _reloadData();
                      },
                    );
                  },
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text("Ongeza Ratiba"),
              backgroundColor: primaryGradient[0],
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget getBody() {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder(
              future: getTimeTableCollections(),
              builder: (context,
                  AsyncSnapshot<TimeTableModel.ChurchTimeTableResponse?>
                      snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return ModernCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: errorColor,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Imeshindikana kupakia data",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Jaribu tena baada ya muda",
                          style: TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData ||
                    snapshot.data?.data?.isEmpty == true) {
                  return EmptyState(
                    icon: Icons.schedule_rounded,
                    title: "Hakuna Ratiba",
                    subtitle: "Hakuna ratiba za jumuiya zilizosajiliwa bado.",
                    actionText: userData?.user.role == "ADMIN" ||
                            userData!.user.role == "KATIBU" ||
                            userData!.user.role == "KATIBU MSAIDIZI"
                        ? "Ongeza Ratiba"
                        : null,
                    onAction: userData?.user.role == "ADMIN" ||
                            userData!.user.role == "KATIBU" ||
                            userData!.user.role == "KATIBU MSAIDIZI"
                        ? () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.white,
                              builder: (BuildContext context) {
                                return AddPrayerSchedulePage(
                                  rootContext: context,
                                  onSubmit: (data) {
                                    _reloadData();
                                  },
                                );
                              },
                            );
                          }
                        : null,
                  );
                }

                final timeTable = snapshot.data!.data!;
                return _buildTimeTableList(timeTable);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeTableList(List<TimeTableModel.ChurchTimeTable> timeTable) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Ratiba za Jumuiya",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: timeTable.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = timeTable[index];
            return _buildTimeTableCard(item);
          },
        ),
      ],
    );
  }

  Widget _buildTimeTableCard(TimeTableModel.ChurchTimeTable item) {
    return ModernCard(
      onTap: () => _showTimeTableDetails(context, item),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: Colors.white,
              size: 15,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.eventName ?? "Ratiba ya Jumuiya",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  softWrap: false,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        item.time ?? "Wakati haujatolewa",
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        item.datePrayer ?? "Tarehe haijatolewa",
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                  ],
                ),
                if (item.location?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.location ?? "",
                          style: TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: textSecondary,
          ),
        ],
      ),
    );
  }

  void _showTimeTableDetails(
      BuildContext context, TimeTableModel.ChurchTimeTable item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            minChildSize: 0.4,
            builder: (_, controller) => SingleChildScrollView(
              controller: controller,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      height: 4,
                      width: 40,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: primaryGradient),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.schedule_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.eventName ?? "Ratiba ya Jumuiya",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              "Maelezo ya ratiba ya shughuli",
                              style: TextStyle(
                                fontSize: 14,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (userData?.user.role == "ADMIN" ||
                          userData!.user.role == "KATIBU" ||
                          userData!.user.role == "KATIBU MSAIDIZI")
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert_rounded,
                              color: textSecondary),
                          onSelected: (value) {
                            if (value == 'edit') {
                              Navigator.pop(context);
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.white,
                                builder: (BuildContext context) {
                                  return AddPrayerSchedulePage(
                                    rootContext: context,
                                    initialData: item,
                                    onSubmit: (data) {
                                      _reloadData();
                                    },
                                  );
                                },
                              );
                            } else if (value == 'delete') {
                              _showDeleteConfirmation(context, item);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_rounded, size: 20),
                                  SizedBox(width: 8),
                                  Text('Hariri'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_rounded,
                                      size: 20, color: errorColor),
                                  SizedBox(width: 8),
                                  Text('Futa',
                                      style: TextStyle(color: errorColor)),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Event Details
                  _buildDetailSection(
                    "Taarifa za Shughuli",
                    Icons.event_rounded,
                    [
                      _buildDetailRow("Jina la Shughuli",
                          item.eventName ?? "Ratiba ya Jumuiya"),
                      _buildDetailRow(
                          "Tarehe", item.datePrayer ?? "Haijatolewa"),
                      _buildDetailRow("Muda", item.time ?? "Haujatolewa"),
                      _buildDetailRow(
                          "Mahali",
                          item.location?.isNotEmpty == true
                              ? item.location!
                              : "Halijatolewa"),
                      _buildDetailRow(
                          "Maelezo",
                          item.message?.isNotEmpty == true
                              ? item.message!
                              : "Hakuna maelezo zaidi"),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // User Info
                  if (item.user != null)
                    _buildDetailSection(
                      "Aliyesajili",
                      Icons.person_rounded,
                      [
                        _buildDetailRow("Jina", item.user!.userFullName ?? ""),
                        _buildDetailRow("Simu", item.user!.phone ?? ""),
                        _buildDetailRow("Nafasi", item.user!.role ?? ""),
                      ],
                    ),

                  const SizedBox(height: 24),

                  // Location Action
                  if (item.location?.isNotEmpty == true)
                    SizedBox(
                      width: double.infinity,
                      child: ModernButton(
                        text: "Onesha Mahali kwenye Ramani",
                        icon: Icons.map_rounded,
                        backgroundColor: infoColor,
                        onPressed: () =>
                            _openMap(item.latId ?? "", item.longId ?? ""),
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

  Widget _buildDetailSection(
      String title, IconData icon, List<Widget> children) {
    return ModernCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: primaryGradient[0]),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, TimeTableModel.ChurchTimeTable item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Futa Ratiba'),
          content: Text(
              'Je, una uhakika unataka kufuta ratiba ya "${item.eventName ?? "Hii"}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ghairi'),
            ),
            ModernButton(
              text: 'Futa',
              backgroundColor: errorColor,
              onPressed: () {
                Navigator.pop(context);
                deleteTimeTable(item.id);
              },
            ),
          ],
        );
      },
    );
  }

  void _openMap(String lat, String lng) async {
    final Uri url =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Imeshindikana kufungua ramani')),
      );
    }
  }
}
