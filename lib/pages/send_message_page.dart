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
  bool _sendToAll = true;
  List<dynamic> _members = [];
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
    var size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: mainFontColor,
        foregroundColor: Colors.white,
        title: const Text('Tuma Ujumbe'),
        elevation: 0,
        actions: [],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: !_isLoadingSmsSummary
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SMS Bando Summary Section
                  !_isLoadingSmsSummary
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.black
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.message_rounded,
                                                color: Colors.black,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 2),
                                            const Text(
                                              "Muhtasari wa SMS",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 2),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: mainFontColor,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              horizontal:
                                                  isSmallScreen ? 12 : 16,
                                              vertical: isSmallScreen ? 8 : 10,
                                            ),
                                            elevation: 3,
                                          ),
                                          icon: Icon(
                                            Icons.visibility_rounded,
                                            size: isSmallScreen ? 14 : 16,
                                          ),
                                          label: Text(
                                            "Tazama",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: isSmallScreen ? 12 : 14,
                                            ),
                                          ),
                                          onPressed: () => {
                                            Navigator.push(
                                              context,
                                              PageTransition(
                                                type: PageTransitionType
                                                    .rightToLeft,
                                                child: const SmsSentListPage(),
                                              ),
                                            )
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          _buildSmsStatItem(
                                            "SMS Zilizopo",
                                            smsBandoSummaryList.isNotEmpty
                                                ? smsBandoSummaryList[0]
                                                    .smsTotal
                                                    .toString()
                                                : "0",
                                            Colors.blue,
                                          ),
                                          _buildSmsStatItem(
                                            "Zilizotumiwa",
                                            usedSummary != null
                                                ? usedSummary.totalWaliotumiwa
                                                    .toString()
                                                : "0",
                                            Colors.green,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _isLoadingSmsSummary
                                  ? const Center(
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black,
                                        ),
                                      ),
                                    )
                                  : smsBandoSummaryList.isEmpty
                                      ? const Text(
                                          "Hakuna taarifa za SMS",
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 13,
                                          ),
                                        )
                                      : SizedBox.shrink(),
                            ],
                          ),
                        )
                      : SizedBox.shrink(),
                  const SizedBox(height: 2),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Text(
                            'Andika Ujumbe Wako',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        TextField(
                          controller: _messageController,
                          maxLines: 5,
                          maxLength: 250,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            hintText: 'Andika ujumbe hapa...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            contentPadding: const EdgeInsets.all(16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[200]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[200]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: mainFontColor),
                            ),
                            counterText:
                                '${_messageController.text.length}/250',
                            counterStyle: TextStyle(color: Colors.grey[600]),
                          ),
                          onChanged: (value) {
                            if (value.length <= 250) {
                              setState(() => _messageController.text = value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Switch(
                        value: _sendToAll,
                        onChanged: (v) {
                          setState(() {
                            _sendToAll = v;
                            _selectedPhones.clear();
                          });
                        },
                      ),
                      Text(_sendToAll
                          ? 'Tuma kwa Wote (${_members.length})'
                          : 'Chagua Wapokeaji  (${_selectedPhones.length})'),
                    ],
                  ),
                  if (!_sendToAll)
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                              itemCount: _members.length,
                              itemBuilder: (context, i) {
                                final member = _members[i];
                                final phone = member['phone'].toString();
                                final name = member['userFullName'] ?? '';
                                return CheckboxListTile(
                                  value: _selectedPhones.contains(phone),
                                  onChanged: (_) => _togglePhone(phone),
                                  title: Text(name),
                                  subtitle: Text(phone),
                                );
                              },
                            ),
                    ),
                  const SizedBox(height: 16),
                  Visibility(
                    visible: (!_isLoadingSmsSummary &&
                                _sendToAll &&
                                _members.isNotEmpty ||
                            !_sendToAll && _selectedPhones.isNotEmpty) &&
                        _messageController.text.trim().isNotEmpty,
                    child: Column(
                      children: [
                        if (smsBandoSummaryList.isNotEmpty) ...[
                          int.parse(smsBandoSummaryList[0]
                                      .smsTotal
                                      .toString()) <
                                  (_sendToAll
                                      ? _members.length
                                      : _selectedPhones.length)
                              ? Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    border: Border.all(color: Colors.red),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.warning,
                                          color: Colors.red, size: 20),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Salio la SMS (${smsBandoSummaryList[0].smsTotal}) ni dogo kuliko idadi ya wapokeaji (${_sendToAll ? _members.length : _selectedPhones.length}). Tafadhali ongeza salio au punguza wapokeaji.',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ],
                        if (smsBandoSummaryList.isNotEmpty) ...[
                          int.parse(smsBandoSummaryList[0]
                                      .smsTotal
                                      .toString()) <
                                  (_sendToAll
                                      ? _members.length
                                      : _selectedPhones.length)
                              ? SizedBox.shrink()
                              : SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.send),
                                    label: Text(_isLoading
                                        ? 'Inatuma...'
                                        : 'Tuma Ujumbe'),
                                    onPressed: _isLoading
                                        ? null
                                        : () {
                                            if (smsBandoSummaryList
                                                    .isNotEmpty &&
                                                int.parse(smsBandoSummaryList[0]
                                                        .smsTotal
                                                        .toString()) >=
                                                    (_sendToAll
                                                        ? _members.length
                                                        : _selectedPhones
                                                            .length)) {
                                              _sendMessage();
                                            }
                                          },
                                  ),
                                ),
                        ],
                      ],
                    ),
                  )
                ],
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
