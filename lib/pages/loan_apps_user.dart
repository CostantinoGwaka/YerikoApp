// ignore_for_file: unrelated_type_equality_checks, deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:jumuiya_yangu/main.dart';
import 'package:jumuiya_yangu/models/loan_setting.dart';
import 'package:jumuiya_yangu/models/user_total_model.dart';
import 'package:jumuiya_yangu/models/user_loan_model.dart';
import 'package:jumuiya_yangu/pages/loan_from_all_users.dart';
import 'package:jumuiya_yangu/services/loan_setting_service.dart';
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
  List<UserLoan> filteredLoans = [];
  String selectedStatus = 'all'; // Default to show all loans

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
          _filterLoansByStatus();
        });
      }
    } catch (e) {
      _showError('Failed to load loans: $e');
    }
  }

  void _filterLoansByStatus() {
    setState(() {
      if (selectedStatus == 'all') {
        filteredLoans = List.from(userLoans);
      } else {
        filteredLoans =
            userLoans.where((loan) => loan.status == selectedStatus).toList();
      }
    });
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

  void _showLoanApplicationBottomSheet(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.60,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: _buildLoanApplicationForm(
                        screenWidth, isTablet, setModalState),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final maxWidth = isTablet ? 800.0 : screenWidth;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: mainFontColor,
        foregroundColor: Colors.white,
        title: Text(
          'Maombi ya Mkopo',
          style: TextStyle(fontSize: isTablet ? 22 : 18),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showLoanApplicationBottomSheet(context),
          ),
        ],
      ),
      body: _isLoadingSettings
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadInitialData,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _buildSavingsCard(screenWidth, isTablet),
                      _buildUserLoansSection(screenWidth, isTablet),
                      SizedBox(height: screenHeight * 0.02),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSavingsCard(double screenWidth, bool isTablet) {
    final horizontalPadding = screenWidth * 0.04;
    final verticalPadding = screenWidth * 0.05;

    return Container(
      margin: EdgeInsets.all(screenWidth * 0.04),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        boxShadow: [
          BoxShadow(
            color: mainFontColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jumla ya Akiba',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: isTablet ? 16 : 14,
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.01),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        NumberFormat.currency(symbol: 'TSh ')
                            .format(totalSavings),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 28 : 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.savings,
                color: Colors.white70,
                size: isTablet ? 50 : 40,
              ),
            ],
          ),
          Divider(
            color: Colors.white24,
            height: screenWidth * 0.08,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mkopo Unaostahili',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: isTablet ? 16 : 14,
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.01),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        NumberFormat.currency(symbol: 'TSh ')
                            .format(eligibleAmount),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 24 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.03,
                  vertical: screenWidth * 0.015,
                ),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(screenWidth * 0.05),
                ),
                child: Text(
                  loanType == 'multiplier'
                      ? '${loanSettings?.multiplier}x mara'
                      : '${loanSettings?.percentage}% ya akiba',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 14 : 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoanApplicationForm(double screenWidth, bool isTablet,
      [StateSetter? setModalState]) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenWidth * 0.005,
      ),
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
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
            Text(
              'Omba Mkopo',
              style: TextStyle(
                fontSize: isTablet ? 24 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: screenWidth * 0.05),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Kiasi cha Mkopo',
                labelStyle: TextStyle(fontSize: isTablet ? 16 : 14),
                hintText: 'Weka kiasi',
                prefixIcon: Icon(Icons.money, size: isTablet ? 28 : 24),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenWidth * 0.04,
                ),
              ),
              style: TextStyle(fontSize: isTablet ? 18 : 16),
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
            SizedBox(height: screenWidth * 0.04),
            TextFormField(
              controller: _monthsController,
              decoration: InputDecoration(
                labelText: 'Muda wa Malipo (Miezi)',
                labelStyle: TextStyle(fontSize: isTablet ? 16 : 14),
                hintText: 'Weka miezi',
                prefixIcon:
                    Icon(Icons.calendar_today, size: isTablet ? 28 : 24),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenWidth * 0.04,
                ),
              ),
              style: TextStyle(fontSize: isTablet ? 18 : 16),
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
            SizedBox(height: screenWidth * 0.05),
            Container(
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Riba', '$interestRate%', isTablet),
                  Divider(height: screenWidth * 0.05),
                  _buildDetailRow(
                    'Jumla ya Malipo',
                    NumberFormat.currency(symbol: 'TSh ').format(totalAmount),
                    isTablet,
                    bold: true,
                  ),
                  Divider(height: screenWidth * 0.05),
                  _buildDetailRow(
                    'Malipo ya Kila Mwezi',
                    NumberFormat.currency(symbol: 'TSh ')
                        .format(monthlyInstallment),
                    isTablet,
                    color: Colors.blue[700],
                  ),
                ],
              ),
            ),
            SizedBox(height: screenWidth * 0.06),
            SizedBox(
              width: double.infinity,
              height: isTablet ? 60 : 50,
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;

                        final amount = double.parse(_amountController.text);
                        if (amount > eligibleAmount) {
                          _showError('Amount exceeds eligible loan amount');
                          return;
                        }

                        if (setModalState != null) {
                          setModalState(() => _isSubmitting = true);
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
                              if (setModalState != null) {
                                setModalState(() => _isSubmitting = false);
                              }
                              setState(() => _isSubmitting = false);
                              Navigator.pop(context);
                              _showSuccess(
                                  'Ombi la mkopo limewasilishwa kikamilifu');
                              _amountController.clear();
                              _monthsController.text = maxMonths.toString();
                              _fetchUserLoans();
                            } else {
                              if (setModalState != null) {
                                setModalState(() => _isSubmitting = false);
                              }
                              setState(() => _isSubmitting = false);
                              Navigator.pop(context);
                              _showError(data['message']);
                            }
                          } else {
                            if (setModalState != null) {
                              setModalState(() => _isSubmitting = false);
                            }
                            setState(() => _isSubmitting = false);
                            Navigator.pop(context);
                            _showError('Failed to submit loan application');
                          }
                        } catch (e) {
                          if (setModalState != null) {
                            setModalState(() => _isSubmitting = false);
                          }
                          setState(() => _isSubmitting = false);
                          Navigator.pop(context);
                          _showError('Error: $e');
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isSubmitting ? Colors.grey : Colors.blue[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  ),
                ),
                child: _isSubmitting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Inawasilisha...',
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Wasilisha Ombi',
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 16,
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

  Widget _buildDetailRow(String label, String value, bool isTablet,
      {bool bold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: Colors.grey[700],
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildUserLoansSection(double screenWidth, bool isTablet) {
    return Container(
      margin: EdgeInsets.all(screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mikopo Yangu',
                style: TextStyle(
                  fontSize: isTablet ? 24 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (userLoans.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${filteredLoans.length} of ${userLoans.length}',
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: screenWidth * 0.005),
          if (userLoans.isNotEmpty) ...[
            SizedBox(height: screenWidth * 0.03),
            // Status Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // All loans chip
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: selectedStatus == 'all',
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.all_inclusive,
                            size: 16,
                            color: selectedStatus == 'all'
                                ? Colors.white
                                : Colors.grey[700],
                          ),
                          const SizedBox(width: 6),
                          const Text('All'),
                        ],
                      ),
                      selectedColor: Colors.grey[700],
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: selectedStatus == 'all'
                            ? Colors.white
                            : Colors.black87,
                        fontWeight: selectedStatus == 'all'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            selectedStatus = 'all';
                          });
                          _filterLoansByStatus();
                        }
                      },
                    ),
                  ),
                  // Status chips
                  ...LoanSettingService.statusList.map((status) {
                    final isSelected = selectedStatus == status['value'];
                    final count = userLoans
                        .where((loan) => loan.status == status['value'])
                        .length;

                    if (count == 0) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              status['icon'],
                              size: 16,
                              color:
                                  isSelected ? Colors.white : status['color'],
                            ),
                            const SizedBox(width: 6),
                            Text('${status['label']} ($count)'),
                          ],
                        ),
                        selectedColor: status['color'],
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              selectedStatus = status['value'];
                            });
                            _filterLoansByStatus();
                          }
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
          SizedBox(height: screenWidth * 0.03),
          filteredLoans.isEmpty
              ? _buildEmptyState(screenWidth, isTablet)
              : ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredLoans.length,
                  itemBuilder: (context, index) => LoanCard(
                    loan: filteredLoans[index],
                    statusColor: LoanSettingService.getStatusColor(
                        filteredLoans[index].status),
                    formatCurrency: LoanSettingService.formatCurrency,
                    formatDate: LoanSettingService.formatDate,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(double screenWidth, bool isTablet) {
    final isFiltered = selectedStatus != 'all';

    // Get the label for the selected status
    String statusLabel = selectedStatus;
    if (isFiltered) {
      final statusItem = LoanSettingService.statusList.firstWhere(
        (status) => status['value'] == selectedStatus,
        orElse: () => {'label': selectedStatus},
      );
      statusLabel = statusItem['label'] as String;
    }

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              isFiltered ? Icons.filter_list_off : Icons.receipt_long,
              size: isTablet ? 80 : 64,
              color: Colors.grey[300],
            ),
            SizedBox(height: screenWidth * 0.05),
            Text(
              isFiltered
                  ? 'Hakuna mikopo ya "$statusLabel"'
                  : 'Huna mkopo wowote',
              style: TextStyle(
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: screenWidth * 0.02),
            Text(
              isFiltered
                  ? 'Huna mikopo yenye hadhi ya "$statusLabel" kwa sasa.'
                  : 'Wakati huu huna mikopo iliyowekwa. Tafadhali wasilisha ombi la mkopo ili uone hapa.',
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (isFiltered) ...[
              SizedBox(height: screenWidth * 0.04),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    selectedStatus = 'all';
                  });
                  _filterLoansByStatus();
                },
                icon: const Icon(Icons.clear),
                label: const Text('Onyesha mikopo yote'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
