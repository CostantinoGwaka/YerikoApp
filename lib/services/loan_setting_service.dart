import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:jumuiya_yangu/utils/url.dart';
import '../models/loan_setting.dart';

class LoanSettingService {
  static List<Map<String, dynamic>> statusList = [
    {
      'value': 'pending',
      'label': 'Pending',
      'color': Colors.orange,
      'icon': Icons.pending
    },
    {
      'value': 'in-progress',
      'label': 'In Progress',
      'color': Colors.blue,
      'icon': Icons.hourglass_empty
    },
    {
      'value': 'completed',
      'label': 'Completed',
      'color': Colors.teal,
      'icon': Icons.done_all
    },
    {
      'value': 'approved',
      'label': 'Approved',
      'color': Colors.green,
      'icon': Icons.check_circle
    },
    {
      'value': 'rejected',
      'label': 'Rejected',
      'color': Colors.red,
      'icon': Icons.cancel
    },
  ];

  Future<Map<String, dynamic>> createLoanSetting(
      LoanSetting loanSetting) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/loans/loan_settings.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(loanSetting.toJson()),
      );

      final data = json.decode(response.body);
      return data;
    } catch (e) {
      throw Exception('Failed to create loan setting: $e');
    }
  }

  Future<LoanSetting?> getLoanSettingByJumuiyaId(dynamic jumuiyaId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/loans/get_loan_setting_by_jumuiya_id.php?jumuiya_id=$jumuiyaId',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      final data = json.decode(response.body);

      if (data['status'] == '200' && data['data'] != null) {
        return LoanSetting.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get loan setting: $e');
    }
  }

  static Color getStatusColor(String status) {
    return statusList.firstWhere((s) => s['value'] == status,
        orElse: () => statusList[0])['color'];
  }

  static String formatCurrency(dynamic amount) {
    return NumberFormat('#,##0.00')
        .format(double.tryParse(amount.toString()) ?? 0);
  }

  static String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
