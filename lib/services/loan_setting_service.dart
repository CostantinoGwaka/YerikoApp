import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jumuiya_yangu/utils/url.dart';
import '../models/loan_setting.dart';

class LoanSettingService {
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
}
