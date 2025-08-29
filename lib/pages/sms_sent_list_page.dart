// ignore_for_file: unused_local_variable, deprecated_member_use, unnecessary_brace_in_string_interps

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jumuiya_yangu/theme/colors.dart';
import 'package:jumuiya_yangu/utils/url.dart';
import 'package:jumuiya_yangu/main.dart';

class SmsSentListPage extends StatefulWidget {
  const SmsSentListPage({super.key});

  @override
  State<SmsSentListPage> createState() => _SmsSentListPageState();
}

class _SmsSentListPageState extends State<SmsSentListPage> {
  bool _isLoading = false;
  List<dynamic> _smsList = [];

  @override
  void initState() {
    super.initState();
    _fetchSmsSent();
  }

  Future<void> _fetchSmsSent() async {
    if (userData?.user.jumuiya_id == null) return;
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sms_bando/get_all_sms_sent.php'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'jumuiya_id': userData!.user.jumuiya_id.toString(),
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'].toString() == '200' && data['data'] != null) {
          setState(() {
            _smsList = data['data'] as List;
          });
        }
      }
    } catch (e) {
      // Handle error silently
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mainFontColor,
        foregroundColor: Colors.white,
        title: const Text('SMS Zilizotumwa'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _smsList.isEmpty
              ? const Center(child: Text('Hakuna SMS zilizotumwa.'))
              : ListView.builder(
                  itemCount: _smsList.length,
                  itemBuilder: (context, i) {
                    final sms = _smsList[i];
                    int waliopokeaCount = 0;
                    // waliopokea can be a comma separated string or a list
                    if (sms['waliopokea'] != null &&
                        sms['waliopokea'].toString().isNotEmpty) {
                      if (sms['waliopokea'] is List) {
                        waliopokeaCount = sms['waliopokea'].length;
                      } else if (sms['waliopokea'] is String) {
                        waliopokeaCount = sms['waliopokea']
                            .toString()
                            .split(',')
                            .where((e) => e.trim().isNotEmpty)
                            .length;
                      }
                    }
                    String packageType = 'NORMAL PACKAGE';
                    Color packageColor = Colors.blue;
                    if (waliopokeaCount >= 1 && waliopokeaCount <= 1000) {
                      packageType = 'NORMAL PACKAGE';
                      packageColor = Colors.blue;
                    } else if (waliopokeaCount >= 1001 &&
                        waliopokeaCount <= 5000) {
                      packageType = 'PREMIUM PACKAGE';
                      packageColor = Colors.orange;
                    } else if (waliopokeaCount >= 5001 &&
                        waliopokeaCount <= 10000) {
                      packageType = 'GOLD PACKAGE';
                      packageColor = Colors.amber;
                    }
                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            packageColor.withOpacity(0.12),
                            Colors.white
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: packageColor.withOpacity(0.08),
                            spreadRadius: 1,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Container(
                                //   padding: const EdgeInsets.symmetric(
                                //       horizontal: 10, vertical: 4),
                                //   decoration: BoxDecoration(
                                //     color: packageColor,
                                //     borderRadius: BorderRadius.circular(8),
                                //   ),
                                //   child: Text(
                                //     packageType,
                                //     style: const TextStyle(
                                //       color: Colors.white,
                                //       fontWeight: FontWeight.bold,
                                //       fontSize: 12,
                                //     ),
                                //   ),
                                // ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    sms['jumbe'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.group,
                                    size: 16, color: Colors.blue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Waliotumiwa: ${sms['waliotumiwa'] ?? ''}',
                                    style:
                                        const TextStyle(color: Colors.black54),
                                  ),
                                ),
                              ],
                            ),
                            if (sms['waliopokea'] != null &&
                                sms['waliopokea'].toString().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      size: 16, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Waliopokea (${waliopokeaCount}): ${sms['waliopokea']}',
                                      style: const TextStyle(
                                          color: Colors.black54),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 16, color: Colors.orange),
                                const SizedBox(width: 8),
                                Text(
                                  'Tarehe: ${sms['tarehe'] ?? ''}',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
