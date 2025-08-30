// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jumuiya_yangu/main.dart';
import 'package:jumuiya_yangu/models/sms_bando_summary_model.dart';
import 'package:jumuiya_yangu/models/sms_bando_used_model.dart';
import 'package:jumuiya_yangu/pages/sms_sent_list_page.dart';
import 'package:jumuiya_yangu/theme/colors.dart';
import 'package:jumuiya_yangu/utils/url.dart';
import 'package:page_transition/page_transition.dart';

class SendMessagePage extends StatefulWidget {
  const SendMessagePage({super.key});

  @override
  State<SendMessagePage> createState() => _SendMessagePageState();
}

class _SendMessagePageState extends State<SendMessagePage> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _memberSearchController = TextEditingController();
  bool _sendToAll = true;
  List<dynamic> _members = [];
  List<dynamic> _filteredMembers = [];
  final List<String> _selectedPhones = [];
  bool _isLoadingSmsSummary = false;
  dynamic usedSummary;
  List<SmsBandoSummaryModel> smsBandoSummaryList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
    fetchSmsBandoSummary();
    fetchSmsBandoSummaryUsed();
    _memberSearchController.addListener(_filterMembers);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _memberSearchController.dispose();
    super.dispose();
  }

  void _filterMembers() {
    if (_memberSearchController.text.isEmpty) {
      setState(() {
        _filteredMembers = List.from(_members);
      });
      return;
    }

    final query = _memberSearchController.text.toLowerCase();
    setState(() {
      _filteredMembers = _members.where((member) {
        final name = (member['userFullName'] ?? '').toString().toLowerCase();
        final phone = (member['phone'] ?? '').toString().toLowerCase();
        return name.contains(query) || phone.contains(query);
      }).toList();
    });
  }

  Future<void> fetchSmsBandoSummary() async {
    if (userData?.user.jumuiya_id == null) return;

    setState(() {
      _isLoadingSmsSummary = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sms_bando/get_sms_bando_summary.php'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "jumuiya_id": userData!.user.jumuiya_id.toString(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'].toString() == "200" && data['data'] != null) {
          setState(() {
            smsBandoSummaryList = (data['data'] as List)
                .map((item) => SmsBandoSummaryModel.fromJson(item))
                .toList();
          });
        }
      }
    } catch (e) {
      // Handle error silently
      if (kDebugMode) {
        print('Error fetching SMS bando summary: $e');
      }
    } finally {
      setState(() {
        _isLoadingSmsSummary = false;
      });
    }
  }

  Future<void> fetchSmsBandoSummaryUsed() async {
    if (userData?.user.jumuiya_id == null) return;

    setState(() {
      _isLoadingSmsSummary = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sms_bando/get_summary_used_sms.php'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "jumuiya_id": userData!.user.jumuiya_id.toString(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'].toString() == "200") {
          // Use the new model for used SMS
          usedSummary = SmsBandoUsedModel.fromJson(data);
          // You can now use usedSummary.totalWaliotumiwa and usedSummary.count as needed
          // For example, you might want to store them in state variables or use them in the UI
          // Example:
          if (kDebugMode) {
            print(
                'Used SMS: ${usedSummary.totalWaliotumiwa}, Count: ${usedSummary.count}');
          }
        }
      }
    } catch (e) {
      // Handle error silently
      if (kDebugMode) {
        print('Error fetching used SMS summary: $e');
      }
    } finally {
      setState(() {
        _isLoadingSmsSummary = false;
      });
    }
  }

  Future<void> _fetchMembers() async {
    setState(() => _isLoading = true);
    final response = await http.get(Uri.parse(
      '$baseUrl/auth/get_all_users.php?jumuiya_id=${userData!.user.jumuiya_id}',
    ));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _members = (data['data'] as List?) ?? [];
        _filteredMembers = List.from(_members);
      });
    }
    setState(() => _isLoading = false);
  }

  void _togglePhone(String phone) {
    setState(() {
      if (_selectedPhones.contains(phone)) {
        _selectedPhones.remove(phone);
      } else {
        _selectedPhones.add(phone);
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Andika ujumbe kwanza.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    final waliopokea = _sendToAll ? [] : _selectedPhones;
    final body = jsonEncode({
      'jumuiya_id': userData!.user.jumuiya_id.toString(),
      'jumbe': _messageController.text.trim(),
      'waliotumiwa': _sendToAll ? 'ALL' : 'SELECTED',
      'waliopokea': waliopokea,
    });
    final response = await http.post(
      Uri.parse('$baseUrl/sms_bando/send_jumbe_kwa_member.php'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    setState(() => _isLoading = false);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'].toString() == '200') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ujumbe umetumwa!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Imeshindikana kutuma.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imeshindikana kutuma.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // var size = MediaQuery.of(context).size;
    // final isSmallScreen = size.width < 360;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: mainFontColor,
        foregroundColor: Colors.white,
        title: const Text('Tuma Ujumbe'),
        elevation: 0,
        actions: [],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: !_isLoadingSmsSummary
            ? SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SMS Summary Statistics
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildSmsStatItem(
                                'SMS Zilizobaki',
                                smsBandoSummaryList.isNotEmpty
                                    ? smsBandoSummaryList[0].smsTotal.toString()
                                    : '0',
                                Colors.blue,
                              ),
                              _buildSmsStatItem(
                                'SMS Zilizotumwa',
                                usedSummary?.totalWaliotumiwa?.toString() ??
                                    '0',
                                Colors.green,
                              ),
                              _buildSmsStatItem(
                                'Waliopokea',
                                usedSummary?.totalWaliotumiwa?.toString() ??
                                    '0',
                                Colors.orange,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                PageTransition(
                                  type: PageTransitionType.rightToLeft,
                                  child: const SmsSentListPage(),
                                ),
                              );
                            },
                            child: const Text('Angalia SMS Zilizotumwa'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: TextField(
                              controller: _messageController,
                              maxLines: 5,
                              decoration: const InputDecoration(
                                hintText: 'Andika ujumbe hapa...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Tuma kwa wote:'),
                        Switch(
                          value: _sendToAll,
                          onChanged: (value) =>
                              setState(() => _sendToAll = value),
                        ),
                      ],
                    ),
                    if (!_sendToAll)
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: TextField(
                              controller: _memberSearchController,
                              decoration: InputDecoration(
                                hintText: 'Tafuta mwanachama...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 0),
                              ),
                            ),
                          ),
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : _filteredMembers.isEmpty
                                    ? const Center(
                                        child: Text(
                                            'Hakuna mwanachama aliyepatikana'))
                                    : ListView.builder(
                                        itemCount: _filteredMembers.length,
                                        itemBuilder: (context, i) {
                                          final member = _filteredMembers[i];
                                          final phone =
                                              member['phone'].toString();
                                          final name =
                                              member['userFullName'] ?? '';
                                          return CheckboxListTile(
                                            value:
                                                _selectedPhones.contains(phone),
                                            onChanged: (_) =>
                                                _togglePhone(phone),
                                            title: Text(name),
                                            subtitle: Text(phone),
                                          );
                                        },
                                      ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    Visibility(
                      visible: !_isLoading,
                      child: Container(
                        width: double.infinity,
                        height: 55,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: LinearGradient(
                            colors: [
                              mainFontColor,
                              mainFontColor.withOpacity(0.8),
                              mainFontColor.withOpacity(0.6),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: mainFontColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _sendMessage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            'TUMA',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildSmsStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.black54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
