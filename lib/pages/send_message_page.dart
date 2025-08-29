// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jumuiya_yangu/main.dart';
import 'package:jumuiya_yangu/utils/url.dart';

class SendMessagePage extends StatefulWidget {
  const SendMessagePage({Key? key}) : super(key: key);

  @override
  State<SendMessagePage> createState() => _SendMessagePageState();
}

class _SendMessagePageState extends State<SendMessagePage> {
  final TextEditingController _messageController = TextEditingController();
  bool _sendToAll = true;
  List<dynamic> _members = [];
  List<String> _selectedPhones = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
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
    return Scaffold(
      appBar: AppBar(title: const Text('Tuma Ujumbe')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _messageController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Ujumbe',
                border: OutlineInputBorder(),
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
                Text(_sendToAll ? 'Tuma kwa Wote' : 'Chagua Wapokeaji'),
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: Text(_isLoading ? 'Inatuma...' : 'Tuma Ujumbe'),
                onPressed: _isLoading ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
