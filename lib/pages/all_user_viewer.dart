// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Border;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:jumuiya_yangu/models/user_trials_number_response.dart';
import 'package:jumuiya_yangu/pages/user_features_payment_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jumuiya_yangu/main.dart';
import 'package:jumuiya_yangu/models/all_users_model.dart';
import 'package:jumuiya_yangu/pages/add_pages/add_user.dart';
import 'package:jumuiya_yangu/pages/pending_requests_viewer.dart';
import 'package:jumuiya_yangu/pages/user_pending_requests_viewer.dart';
import 'package:jumuiya_yangu/theme/colors.dart';
import 'package:jumuiya_yangu/utils/url.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;

class AllViewerUserWithAdmin extends StatefulWidget {
  const AllViewerUserWithAdmin({super.key});

  @override
  State<AllViewerUserWithAdmin> createState() => _AllViewerUserWithAdminState();
}

class _AllViewerUserWithAdminState extends State<AllViewerUserWithAdmin> {
  AllUsersResponse? collections;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _hasUserPendingRequests = false;
  int _pendingRequestsCount = 0;
  bool isLoading = false;
  UserTrialsNumberResponse? userTrialsNumber;

  @override
  void initState() {
    super.initState();
    getUsersCollections();
    getUserTrialsNumber();
    if (userData != null &&
        (userData!.user.role == "USER" ||
            userData!.user.role == "ADMIN" ||
            userData!.user.role == "KATIBU" ||
            userData!.user.role == "KATIBU MSAIDIZI" ||
            userData!.user.role == "MWENYEKITI MSAIDIZI")) {
      checkUserPendingRequests();
    }
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reloadData() async {
    await getUsersCollections();
    if (userData != null &&
        (userData!.user.role == "USER" ||
            userData!.user.role == "ADMIN" ||
            userData!.user.role == "KATIBU" ||
            userData!.user.role == "KATIBU MSAIDIZI" ||
            userData!.user.role == "MWENYEKITI MSAIDIZI")) {
      setState(() {}); // Refresh UI after fetching data

      await checkUserPendingRequests();
    }
  }

  Future<UserTrialsNumberResponse?> getUserTrialsNumber() async {
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

  Future<void> checkUserPendingRequests() async {
    try {
      final String myApi =
          "$baseUrl/auth/get_all_user_associated_by_user_id.php";
      final response = await http.post(
        Uri.parse(myApi),
        headers: {'Content-type': 'application/json'},
        body: json.encode({'user_id': userData!.user.id}),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse != null && jsonResponse['data'] != null) {
          final dataList = jsonResponse['data'] as List;
          setState(() {
            _pendingRequestsCount = dataList.length;
            _hasUserPendingRequests = dataList.isNotEmpty;
          });
        } else {
          setState(() {
            _pendingRequestsCount = 0;
            _hasUserPendingRequests = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _pendingRequestsCount = 0;
        _hasUserPendingRequests = false;
      });
    }
  }

  Future<AllUsersResponse?> getUsersCollections() async {
    try {
      final String myApi =
          "$baseUrl/auth/get_all_users.php?jumuiya_id=${userData!.user.jumuiya_id}";
      final response = await http
          .get(Uri.parse(myApi), headers: {'Accept': 'application/json'});

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse != null) {
          collections = AllUsersResponse.fromJson(jsonResponse);
          return collections;
        }
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
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              "Error: ${response.statusCode}",
            ),
          ),
        );
      }
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: primary,
        body: RefreshIndicator(onRefresh: _reloadData, child: getBody()),
        floatingActionButton: _buildPremiumFeaturesFAB());
  }

  Widget _buildPremiumFeaturesFAB() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (userTrialsNumber != null &&
            int.parse(userTrialsNumber!.data[0].reportTrials) != 0) ...[
          FloatingActionButton.small(
            heroTag: 'export_pdf_user1',
            onPressed: () => _exportToPDF(),
            backgroundColor: Colors.blue,
            child: const Icon(Icons.picture_as_pdf),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'export_excel_user1',
            onPressed: () => _exportToExcel(),
            backgroundColor: Colors.green,
            child: const Icon(Icons.table_chart),
          ),
          const SizedBox(height: 8),
        ],
        if (userTrialsNumber != null &&
            int.parse(userTrialsNumber!.data[0].reportTrials) == 0) ...[
          FloatingActionButton.small(
            heroTag: 'upgrade_user1',
            onPressed: () => _showPremiumDialog(),
            backgroundColor: Colors.amber,
            child: const Icon(Icons.star),
          ),
          const SizedBox(height: 16),
        ],
      ],
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

  Future<void> _exportToPDF() async {
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
      final pdf = pw.Document();

      // Create data array
      /* Example structure:
       'Jina',
        'Simu',
        'Anapoishi',
        'Jinsia',
            'Hali ya Ndoa',
        'Tarehe',
      */
      final tableData = collections?.data.map((item) {
            return [
              item.userFullName ?? '',
              item.phone,
              item.location ?? '',
              item.gender ?? '',
              item.martialstatus ?? '',
              item.dobdate,
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
                        pw.Text('Ripoti ya Wanajumuiya',
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
                          children: [
                            'Jina',
                            'Simu',
                            'Anapoishi',
                            'Jinsia',
                            'Hali ya Ndoa',
                            'Tarehe',
                          ]
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
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text('Hitilafu: $e')),
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
        'Jina',
        'Simu',
        'Anapoishi',
        'Jinsia',
        'Hali ya Ndoa',
        'Tarehe',
      ];
      for (int i = 0; i < headers.length; i++) {
        var cell =
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = headers[i];
        cell.cellStyle = headerStyle;
      }

      // Add data rows
      int rowIndex = 1;
      collections?.data.forEach((item) {
        // Name
        var nameCell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
        nameCell.value = item.userFullName ?? '';

        // Phone
        var phoneCell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex));
        phoneCell.value = item.phone ?? '';

        // Location
        var locationCell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex));
        locationCell.value = item.location ?? '';

        // Gender
        var genderCell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex));
        genderCell.value = item.gender ?? '';

        // Marital Status
        var maritalStatusCell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex));
        maritalStatusCell.value = item.martialstatus ?? '';

        // Date
        var dateCell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex));
        dateCell.value = item.dobdate ?? '';

        rowIndex++;
      });

      // Add summary row
      // if (collections?.data.isNotEmpty == true) {
      //   rowIndex++; // Skip a row

      //   // Summary label
      //   var summaryLabelCell = sheet.cell(
      //       CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
      //   summaryLabelCell.value = 'JUMLA';
      //   summaryLabelCell.cellStyle = CellStyle(bold: true);

      //   // Summary amount
      //   var summaryAmountCell = sheet.cell(
      //       CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex));
      //   summaryAmountCell.value = totalMonthlyCollections;
      //   summaryAmountCell.cellStyle = CellStyle(bold: true);

      //   // Total count
      //   rowIndex++;
      //   var countLabelCell = sheet.cell(
      //       CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
      //   countLabelCell.value = 'Idadi ya Wanajumuiya';
      //   countLabelCell.cellStyle = CellStyle(bold: true);

      //   var countCell = sheet.cell(
      //       CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex));
      //   countCell.value = collections?.data.length ?? 0;
      //   countCell.cellStyle = CellStyle(bold: true);
      // }

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

        // Show success message
        // ignore: use_build_context_synchronously
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
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text('Hitilafu: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget getBody() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          floating: true,
          pinned: true,
          backgroundColor: primary,
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primary,
                    primary.withValues(alpha: 0.9),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Wanajumuiya",
                                style: TextStyle(
                                  color: const Color.fromARGB(255, 32, 21, 234)
                                      .withValues(alpha: 0.8),
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.3),
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                "${collections?.data.length ?? 0} wanachama${_searchQuery.isNotEmpty ? ' (${_filterUsers(collections?.data ?? []).length} wamepatikana)' : ''}",
                                style: TextStyle(
                                  color: const Color.fromARGB(255, 32, 21, 234)
                                      .withValues(alpha: 0.7),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  shadows: [
                                    Shadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.2),
                                      offset: Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              if (userData != null &&
                                      userData!.user.role == "ADMIN" ||
                                  userData!.user.role == "KATIBU" ||
                                  userData!.user.role ==
                                      "MWENYEKITI MSAIDIZI" ||
                                  userData!.user.role == "KATIBU MSAIDIZI") ...[
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const PendingRequestsViewer(),
                                        ),
                                      );
                                    },
                                    child: const Icon(
                                      CupertinoIcons.clock_fill,
                                      color: Colors.orange,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(width: 5),
                              if (userData != null &&
                                  (userData!.user.role == "USER" ||
                                      userData!.user.role == "ADMIN" ||
                                      userData!.user.role == "KATIBU" ||
                                      userData!.user.role ==
                                          "MWENYEKITI MSAIDIZI" ||
                                      userData!.user.role ==
                                          "KATIBU MSAIDIZI") &&
                                  _hasUserPendingRequests) ...[
                                GestureDetector(
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const UserPendingRequestsViewer(),
                                      ),
                                    );
                                  },
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.orange
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        child: InkWell(
                                          onTap: () async {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const UserPendingRequestsViewer(),
                                              ),
                                            );
                                            // Refresh the count when user returns
                                            if (userData != null &&
                                                (userData!.user.role ==
                                                        "USER" ||
                                                    userData!.user.role ==
                                                        "ADMIN")) {
                                              checkUserPendingRequests();
                                            }
                                          },
                                          child: const Icon(
                                            CupertinoIcons.bell_circle_fill,
                                            color: Colors.orange,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.red[400]!,
                                                Colors.red[600]!
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.red
                                                    .withValues(alpha: 0.4),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 20,
                                            minHeight: 20,
                                          ),
                                          child: Text(
                                            _pendingRequestsCount > 99
                                                ? '99+'
                                                : _pendingRequestsCount
                                                    .toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              // Container(
                              //   decoration: BoxDecoration(
                              //     color: Colors.white.withValues(alpha: 0.2),
                              //     borderRadius: BorderRadius.circular(12),
                              //   ),
                              //   padding: const EdgeInsets.all(8),
                              //   child: Icon(
                              //     CupertinoIcons.person_3_fill,
                              //     color: const Color.fromARGB(255, 32, 21, 234).withValues(alpha: 0.7),
                              //     size: 24,
                              //   ),
                              // ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickySearchHeaderDelegate(
            child: Container(
              color: primary,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: "Tafuta mwanajumuiya...",
                            prefixIcon: Icon(CupertinoIcons.search,
                                color: Colors.grey[600]),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear,
                                        color: Colors.grey[600]),
                                    onPressed: () {
                                      _searchController.clear();
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    if (userData != null && userData!.user.role == "ADMIN" ||
                        userData!.user.role == "KATIBU" ||
                        userData!.user.role == "MWENYEKITI MSAIDIZI" ||
                        userData!.user.role == "KATIBU MSAIDIZI") ...[
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              mainFontColor,
                              mainFontColor.withValues(alpha: 0.8)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: mainFontColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(25)),
                                ),
                                builder: (_) => AddUserPageAdmin(
                                  rootContext: context,
                                  onSubmit: (data) {
                                    _reloadData();
                                  },
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add,
                                      color: Colors.white, size: 20),
                                  const SizedBox(width: 4),
                                  const Text(
                                    "Ongeza",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: FutureBuilder(
            future: getUsersCollections(),
            builder: (context, AsyncSnapshot<AllUsersResponse?> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(
                  height: 300,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                            color: mainFontColor.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text(
                          "Inatafuta wanajumuiya...",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else if (snapshot.hasError) {
                return SizedBox(
                  height: 300,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          "Imeshindikana kupakia taarifa za wanajumuiya.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
                return SizedBox(
                  height: 300,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.person_3,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          "Hakuna taarifa za wanajumuiya zilizopatikana.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final collections = snapshot.data!.data;
              final filteredUsers = _filterUsers(collections);

              if (filteredUsers.isEmpty && _searchQuery.isNotEmpty) {
                return SizedBox(
                  height: 300,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.search,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          "Hakuna mwanajumuiya aliyepatikana\nkwa utafutaji '$_searchQuery'",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: filteredUsers.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemBuilder: (context, index) {
                  final item = filteredUsers[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with name and role
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.userFullName ?? "Jina Halipo",
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "@${item.userName}",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: item.role == "ADMIN" ||
                                                item.role == "KATIBU" ||
                                                item.role ==
                                                    "MWENYEKITI MSAIDIZI" ||
                                                item.role == "KATIBU MSAIDIZI"
                                            ? [
                                                Colors.red[400]!,
                                                Colors.red[600]!
                                              ]
                                            : [
                                                Colors.blue[400]!,
                                                Colors.blue[600]!
                                              ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      item.role ?? "Role Halipo",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Contact Info
                              _buildInfoRow(
                                icon: Icons.phone,
                                label: "Simu",
                                value: item.phone ?? "Hajaongeza",
                                color: Colors.green,
                                showCopy: true,
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                icon: Icons.calendar_today,
                                label: "Mwaka wa usajili",
                                value: item.yearRegistered ?? "Hajaongeza",
                                color: Colors.orange,
                              ),

                              // Admin-only details
                              if (userData != null &&
                                      userData!.user.role == "ADMIN" ||
                                  userData!.user.role == "KATIBU" ||
                                  userData!.user.role == "MWENYEKITI" ||
                                  userData!.user.role == "MHAZINI" ||
                                  userData!.user.role ==
                                      "MWENYEKITI MSAIDIZI" ||
                                  userData!.user.role == "KATIBU MSAIDIZI") ...[
                                const SizedBox(height: 8),
                                _buildInfoRow(
                                  icon: Icons.location_on,
                                  label: "Mahali anapoishi",
                                  value: item.location ?? "Hajaongeza",
                                  color: Colors.purple,
                                ),
                                const SizedBox(height: 8),
                                _buildInfoRow(
                                  icon: Icons.person,
                                  label: "Jinsia",
                                  value: item.gender ?? "Hajaongeza",
                                  color: Colors.teal,
                                ),
                                const SizedBox(height: 8),
                                _buildInfoRow(
                                  icon: Icons.cake,
                                  label: "Tarehe ya kuzaliwa",
                                  value: item.dobdate ?? "Hajaongeza",
                                  color: Colors.pink,
                                ),
                                const SizedBox(height: 8),
                                _buildInfoRow(
                                  icon: Icons.favorite,
                                  label: "Hali ya ndoa",
                                  value: item.martialstatus ?? "Hajaongeza",
                                  color: Colors.red,
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Action buttons
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              if (userData != null &&
                                      userData!.user.role == "ADMIN" ||
                                  userData!.user.role == "KATIBU" ||
                                  userData!.user.role ==
                                      "MWENYEKITI MSAIDIZI" ||
                                  userData!.user.role == "KATIBU MSAIDIZI") ...[
                                Expanded(
                                  child: _buildActionButton(
                                    icon: Icons.edit_outlined,
                                    label: "Hariri",
                                    color: Colors.blue,
                                    onPressed: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(25)),
                                        ),
                                        builder: (_) => AddUserPageAdmin(
                                          rootContext: context,
                                          initialData: item,
                                          onSubmit: (data) {
                                            _reloadData();
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.phone,
                                  label: "Piga Simu",
                                  color: Colors.green,
                                  onPressed: () async {
                                    final phone =
                                        (item.phone ?? '').replaceAll(' ', '');
                                    String formattedPhone =
                                        formatPhoneNumber(phone);
                                    if (phone.isNotEmpty) {
                                      final Uri url =
                                          Uri.parse('tel:$formattedPhone');
                                      if (await canLaunchUrl(url)) {
                                        await launchUrl(url);
                                      } else {
                                        // ignore: use_build_context_synchronously
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                "Imeshindikana kupiga simu."),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: 20),
        ),
      ],
    );
  }

  List<dynamic> _filterUsers(List<dynamic> users) {
    if (_searchQuery.isEmpty) {
      return users;
    }

    return users.where((user) {
      final userName = (user.userName ?? '').toLowerCase();
      final userFullName = (user.userFullName ?? '').toLowerCase();
      final phone = (user.phone ?? '').toLowerCase();
      final location = (user.location ?? '').toLowerCase();
      final role = (user.role ?? '').toLowerCase();

      return userName.contains(_searchQuery) ||
          userFullName.contains(_searchQuery) ||
          phone.contains(_searchQuery) ||
          location.contains(_searchQuery) ||
          role.contains(_searchQuery);
    }).toList();
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool showCopy = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (showCopy)
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label imenakiliwa'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: color,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.copy, size: 16, color: color),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String formatPhoneNumber(String phone) {
    if (phone.startsWith("255") && phone.length > 3) {
      return "0${phone.substring(3)}";
    }
    return phone;
  }
}

class _StickySearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickySearchHeaderDelegate({required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 80.0; // Height when fully expanded

  @override
  double get minExtent => 80.0; // Height when collapsed

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
