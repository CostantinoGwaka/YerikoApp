import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jumuiya_yangu/main.dart';
import 'package:jumuiya_yangu/models/user_collection_model.dart';
import 'package:jumuiya_yangu/theme/colors.dart';
import 'package:jumuiya_yangu/utils/url.dart';
import 'package:jumuiya_yangu/shared/components/modern_widgets.dart';
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
            const SnackBar(
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
        SnackBar(
            content: Text("⚠️ Tafadhali hakikisha umeunganishwa na intaneti")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: ModernAppBar(
        title: "Michango Yangu",
        actions: [
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
            // Summary Section
            _buildSummarySection(),

            const SizedBox(height: 24),

            // Collections List
            FutureBuilder(
              future: getUserCollections(),
              builder: (context, AsyncSnapshot<CollectionResponse?> snapshot) {
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
                } else if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
                  return EmptyState(
                    icon: Icons.account_balance_wallet_rounded,
                    title: "Hakuna Michango",
                    subtitle: "Haujachangia chochote bado. Anza kuchangia leo!",
                  );
                }

                final collections = snapshot.data!.data;
                return _buildCollectionsList(collections);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return FutureBuilder(
      future: getUserCollections(),
      builder: (context, AsyncSnapshot<CollectionResponse?> snapshot) {
        if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
          return const SizedBox.shrink();
        }

        final collections = snapshot.data!.data;
        final totalAmount = collections.fold<int>(
          0,
          (sum, item) => sum + (int.tryParse(item.amount) ?? 0),
        );
        final thisMonthCount = collections.where((item) {
          final currentMonth =
              DateFormat('MMMM').format(DateTime.now()).toUpperCase();
          return item.monthly == currentMonth;
        }).length;

        return Row(
          children: [
            Expanded(
              child: ModernCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: successGradient),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Jumla",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "TSh ${NumberFormat('#,##0').format(totalAmount)}",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: successColor,
                      ),
                    ),
                    Text(
                      "${collections.length} michango",
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ModernCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: infoColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.calendar_month_rounded,
                            color: infoColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Mwezi huu",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "$thisMonthCount",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: infoColor,
                      ),
                    ),
                    Text(
                      "michango",
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCollectionsList(List<CollectionItem> collections) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Historia ya Michango",
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
          itemCount: collections.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = collections[index];
            return _buildCollectionCard(item);
          },
        ),
      ],
    );
  }

  Widget _buildCollectionCard(CollectionItem item) {
    String formattedDate;
    try {
      final date = DateTime.parse(item.registeredDate);
      formattedDate = DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      formattedDate = item.registeredDate;
    }

    return ModernCard(
      onTap: () => _showCollectionDetails(context, item),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: successGradient),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.savings_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "TSh ${NumberFormat('#,##0').format(int.tryParse(item.amount) ?? 0)}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    StatusChip(
                      label: _getMonthName(item.monthly),
                      color: infoColor,
                      icon: Icons.calendar_month_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
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

  String _getMonthName(String month) {
    final months = {
      "JANUARY": "Januari",
      "FEBRUARY": "Februari",
      "MARCH": "Machi",
      "APRIL": "Aprili",
      "MAY": "Mei",
      "JUNE": "Juni",
      "JULY": "Julai",
      "AUGUST": "Agosti",
      "SEPTEMBER": "Septemba",
      "OCTOBER": "Oktoba",
      "NOVEMBER": "Novemba",
      "DECEMBER": "Desemba",
    };
    return months[month] ?? month;
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
                          gradient: LinearGradient(colors: successGradient),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.receipt_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Maelezo ya Mchango",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              "Taarifa kamili za mchango",
                              style: TextStyle(
                                fontSize: 14,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Amount Card
                  ModernCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: successColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_rounded,
                            color: successColor,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Kiasi cha Mchango",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "TSh ${NumberFormat('#,##0').format(int.tryParse(item.amount) ?? 0)}",
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: successColor,
                                ),
                              ),
                              StatusChip(
                                label: _getMonthName(item.monthly),
                                color: infoColor,
                                icon: Icons.calendar_month_rounded,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // User Info
                  _buildDetailSection(
                    "Taarifa za Mtumiaji",
                    Icons.person_rounded,
                    [
                      _buildDetailRow("Jina Kamili", user.userFullName ?? ""),
                      _buildDetailRow("Namba ya Simu", user.phone ?? ""),
                      _buildDetailRow("Jina la Mtumiaji", user.userName ?? ""),
                      _buildDetailRow("Nafasi", user.role ?? ""),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Collection Info
                  _buildDetailSection(
                    "Taarifa za Mchango",
                    Icons.info_rounded,
                    [
                      _buildDetailRow("Mwaka wa Kanisa", year.churchYear),
                      _buildDetailRow("Tarehe ya Usajili",
                          _formatDate(item.registeredDate)),
                      _buildDetailRow("Aliyesajili", item.registeredBy),
                    ],
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
            width: 120,
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

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMMM yyyy').format(date);
    } catch (_) {
      return dateString;
    }
  }
}
