import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:jumuiya_yangu/utils/url.dart';
import '../models/loan_setting.dart';

class LoanSettingService {
  static List<Map<String, dynamic>> statusList = [
    {
      'value': 'pending',
      'label': 'Inasubiri',
      'color': Colors.orange,
      'icon': Icons.pending
    },
    {
      'value': 'in-progress',
      'label': 'Inaendelea',
      'color': Colors.blue,
      'icon': Icons.hourglass_empty
    },
    {
      'value': 'completed',
      'label': 'Imekamilika',
      'color': Colors.teal,
      'icon': Icons.done_all
    },
    {
      'value': 'approved',
      'label': 'Imeidhinishwa',
      'color': Colors.green,
      'icon': Icons.check_circle
    },
    {
      'value': 'rejected',
      'label': 'Imekataliwa',
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

  Future<List<LoanSetting>> getAllLoanSettingsByJumuiyaId(
      dynamic jumuiyaId) async {
    try {
      String myApi =
          "$baseUrl/loans/get_loan_setting_by_jumuiya_id.php?jumuiya_id=$jumuiyaId";
      final response = await http.get(
        Uri.parse(myApi),
        headers: {'Accept': 'application/json'},
      );

      var jsonResponse = json.decode(response.body);

      if (response.statusCode == 200 && jsonResponse['status'] == 200) {
        List<dynamic> data = jsonResponse['data'];
        return data.map((json) => LoanSetting.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching loan settings: $e");
      }
      return [];
    }
  }

  static Color getStatusColor(String status) {
    return statusList.firstWhere((s) => s['value'] == status,
        orElse: () => statusList[0])['color'];
  }

  static String getStatusLabel(String status) {
    return statusList.firstWhere((s) => s['value'] == status,
        orElse: () => statusList[0])['label'];
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
