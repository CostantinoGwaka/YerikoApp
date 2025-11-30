// ignore_for_file: unrelated_type_equality_checks, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:jumuiya_yangu/main.dart';
import 'package:jumuiya_yangu/models/loan_setting.dart';
import 'package:jumuiya_yangu/models/user_total_model.dart';
import 'package:jumuiya_yangu/models/user_loan_model.dart';
import 'package:jumuiya_yangu/theme/colors.dart';
import 'package:jumuiya_yangu/utils/url.dart';

class LoanAppsUserPage extends StatefulWidget {
  const LoanAppsUserPage({super.key});

  @override
  State<LoanAppsUserPage> createState() => _LoanAppsUserPageState();
}

class _LoanAppsUserPageState extends State<LoanAppsUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _monthsController = TextEditingController();

  bool _isLoadingSettings = true;
  bool _isSubmitting = false;

  LoanSetting? loanSettings;
  UserTotalsResponse? userTotalData;
  double totalSavings = 0.0;
  double eligibleAmount = 0.0;
  double interestRate = 0.0;
  double totalAmount = 0.0;
  double monthlyInstallment = 0.0;
  int maxMonths = 12;
  String loanType = '';

  List<UserLoan> userLoans = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _amountController.addListener(_calculateLoanDetails);
    _monthsController.addListener(_calculateLoanDetails);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _monthsController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingSettings = true);
    await Future.wait([
      _fetchLoanSettings(),
      _fetchUserSavings(),
      _fetchUserLoans(),
    ]);
    setState(() => _isLoadingSettings = false);
  }

  Future<void> _fetchLoanSettings() async {
    try {
      // Replace with your actual user data source
      final response = await http.get(
        Uri.parse(
            '$baseUrl/loans/get_loan_setting_by_jumuiya_id.php?jumuiya_id=${userData!.user.jumuiya_id}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final loanSetting = LoanSetting.fromJson(data['data']);
        setState(() {
          loanSettings = loanSetting;
          interestRate = double.parse(loanSetting.interestRate.toString());
          maxMonths = int.parse(loanSetting.maxPeriodMonths.toString());

          // Determine loan type
          if (loanSetting.multiplier != null && loanSetting.multiplier != '0') {
            loanType = 'multiplier';
          } else if (loanSetting.percentage != null &&
              loanSetting.percentage != '0') {
            loanType = 'percentage';
          }

          _monthsController.text = maxMonths.toString();
        });
      }
    } catch (e) {
      _showError('Failed to load loan settings: $e');
    }
  }

  Future<void> _fetchUserSavings() async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/monthly/get_total_by_user_statistics.php?userId=${userData!.user.id}&year=${currentYear!.data.churchYear}&jumuiya_id=${userData!.user.jumuiya_id}'),
        headers: await authHeader,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        userTotalData = UserTotalsResponse.fromJson(data);
        setState(() {
          totalSavings = double.parse(userTotalData!.overallTotal.toString());
          _calculateEligibleAmount();
        });
      }
    } catch (e) {
      _showError('Failed to load savings: $e');
    }
  }

  void _calculateEligibleAmount() {
    if (loanSettings == null) return;

    if (loanType == 'multiplier') {
      final multiplier = double.parse(loanSettings!.multiplier.toString());
      eligibleAmount = totalSavings * multiplier;
    } else if (loanType == 'percentage') {
      final percentage = double.parse(loanSettings!.percentage.toString());
      eligibleAmount = totalSavings * (percentage / 100);
    }
  }

  void _calculateLoanDetails() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final months = int.tryParse(_monthsController.text) ?? 1;

    if (amount > 0 && months > 0) {
      setState(() {
        totalAmount = amount + (amount * interestRate / 100);
        monthlyInstallment = totalAmount / months;
      });
    }
  }

  Future<void> _fetchUserLoans() async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/loans/get_loans_application_by_user_id.php?user_id=${userData!.user.id}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final loansResponse = UserLoansResponse.fromJson(data);

        setState(() {
          userLoans = loansResponse.data;
        });
      }
    } catch (e) {
      _showError('Failed to load loans: $e');
    }
  }

  Future<void> _submitLoanApplication() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text);
    if (amount > eligibleAmount) {
      _showError('Amount exceeds eligible loan amount');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/loans/loan_application.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userData!.user.id,
          'jumuiya_id': userData!.user.jumuiya_id,
          'amount': amount,
          'interest_rate': interestRate,
          'total_amount': totalAmount,
          'monthly_installment': monthlyInstallment,
          'status': 'pending',
          'loan_type': loanType,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == '200') {
          _showSuccess('Ombi la mkopo limewasilishwa kikamilifu');
          _amountController.clear();
          _fetchUserLoans();
        } else {
          _showError(data['message']);
        }
      } else {
        _showError('Failed to submit loan application');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: mainFontColor,
        foregroundColor: Colors.white,
        title: const Text('Maombi ya Mkopo'),
        elevation: 0,
        actions: [],
      ),
      body: _isLoadingSettings
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadInitialData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildSavingsCard(),
                    _buildUserLoansSection(),
                    _buildLoanApplicationForm(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSavingsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: mainFontColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jumla ya Akiba',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    NumberFormat.currency(symbol: 'TSh ').format(totalSavings),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.savings, color: Colors.white70, size: 40),
            ],
          ),
          const Divider(color: Colors.white24, height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mkopo Unaostahili',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    NumberFormat.currency(symbol: 'TSh ')
                        .format(eligibleAmount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  loanType == 'multiplier'
                      ? '${loanSettings?.multiplier}x mara'
                      : '${loanSettings?.percentage}% ya akiba',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoanApplicationForm() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Omba Mkopo',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Kiasi cha Mkopo',
                hintText: 'Weka kiasi',
                prefixIcon: const Icon(Icons.money),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Tafadhali weka kiasi';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Tafadhali weka kiasi sahihi';
                }
                if (amount > eligibleAmount) {
                  return 'Kiasi kimezidi kikomo';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _monthsController,
              decoration: InputDecoration(
                labelText: 'Muda wa Malipo (Miezi)',
                hintText: 'Weka miezi',
                prefixIcon: const Icon(Icons.calendar_today),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Tafadhali weka muda wa malipo';
                }
                final months = int.tryParse(value);
                if (months == null || months <= 0) {
                  return 'Tafadhali weka muda sahihi';
                }
                if (months > maxMonths) {
                  return 'Muda wa juu ni miezi $maxMonths';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Riba', '$interestRate%'),
                  const Divider(height: 20),
                  _buildDetailRow(
                    'Jumla ya Malipo',
                    NumberFormat.currency(symbol: 'TSh ').format(totalAmount),
                    bold: true,
                  ),
                  const Divider(height: 20),
                  _buildDetailRow(
                    'Malipo ya Kila Mwezi',
                    NumberFormat.currency(symbol: 'TSh ')
                        .format(monthlyInstallment),
                    color: Colors.blue[700],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitLoanApplication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Wasilisha Ombi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool bold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildUserLoansSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mikopo Yangu',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          userLoans.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: userLoans.length,
                  itemBuilder: (context, index) => _buildLoanCard(
                    userLoans[index],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Hakuna mikopo bado',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanCard(UserLoan loan) {
    final status = loan.status;
    final statusColor = status == 'approved'
        ? Colors.green
        : status == 'rejected'
            ? Colors.red
            : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                NumberFormat.currency(symbol: 'TSh ').format(
                  double.parse(loan.amount),
                ),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status == 'approved'
                      ? 'IMEIDHINISHWA'
                      : status == 'rejected'
                          ? 'IMEKATALIWA'
                          : 'INASUBIRI',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildLoanDetailRow(
            Icons.percent,
            'Riba',
            '${loan.interestRate}%',
          ),
          _buildLoanDetailRow(
            Icons.account_balance_wallet,
            'Jumla ya Malipo',
            NumberFormat.currency(symbol: 'TSh ').format(
              double.parse(loan.totalAmount),
            ),
          ),
          _buildLoanDetailRow(
            Icons.payment,
            'Malipo ya Kila Mwezi',
            NumberFormat.currency(symbol: 'TSh ').format(
              double.parse(loan.monthlyInstallment),
            ),
          ),
          _buildLoanDetailRow(
            Icons.calendar_today,
            'Tarehe ya Ombi',
            _formatDate(loan.requestedAt),
          ),
          if (loan.approvedAt != null)
            _buildLoanDetailRow(
              Icons.check_circle,
              'Imeidhinishwa',
              _formatDate(loan.approvedAt),
            ),
        ],
      ),
    );
  }

  Widget _buildLoanDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(date);
      return DateFormat('MMM dd, yyyy').format(dateTime);
    } catch (e) {
      return date;
    }
  }
}
