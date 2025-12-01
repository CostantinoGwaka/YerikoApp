// ignore_for_file: unrelated_type_equality_checks, deprecated_member_use, use_build_context_synchronously, curly_braces_in_flow_control_structures

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
  bool _isLoadingSettings = true;

  UserTotalsResponse? userTotalData;
  double totalSavings = 0.0;
  int totalShares = 0;

  List<UserLoan> userLoans = [];
  List<UserLoan> filteredLoans = [];
  List<LoanSetting> availableLoanSettings = [];
  String selectedStatus = 'all';

  Map<String, dynamic>? userLoanStatistics;
  bool isLoadingUserStats = false;
  bool _showStatistics = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingSettings = true);
    await Future.wait([
      _fetchUserSavings(),
      _fetchAvailableLoanSettings(),
      _fetchUserLoans(),
      _fetchUserLoanStatistics(),
    ]);
    setState(() => _isLoadingSettings = false);
  }

  Future<void> _fetchAvailableLoanSettings() async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/loans/get_loan_setting_by_jumuiya_id.php?jumuiya_id=${userData!.user.jumuiya_id}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 200) {
          final List<dynamic> settingsData = data['data'];
          setState(() {
            availableLoanSettings = settingsData
                .map((setting) => LoanSetting.fromJson(setting))
                .toList();
          });
        }
      }
    } catch (e) {
      _showError('Imeshindwa kupakia mipangilio ya mikopo: $e');
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
          // Calculate total shares if needed
          totalShares = (totalSavings / 1000).floor(); // Example calculation
        });
      }
    } catch (e) {
      _showError('Imeshindwa kupakia akiba: $e');
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
      _showError('Imeshindwa kupakia mikopo: $e');
    }
  }

  Future<void> _fetchUserLoanStatistics() async {
    setState(() {
      isLoadingUserStats = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/loans/get_loan_statistics_by_user.php?user_id=${userData!.user.id}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 200 || data['status'] == '200') {
          setState(() {
            userLoanStatistics = data['data'];
            isLoadingUserStats = false;
          });
        } else {
          setState(() {
            isLoadingUserStats = false;
          });
        }
      } else {
        setState(() {
          isLoadingUserStats = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingUserStats = false;
      });
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

  void _showLoanSelectionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [mainFontColor, mainFontColor.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Chagua Aina ya Mkopo',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: availableLoanSettings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.settings_suggest_rounded,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Hakuna mipangilio ya mikopo',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: availableLoanSettings.length,
                      itemBuilder: (context, index) {
                        final loanSetting = availableLoanSettings[index];
                        return _buildLoanSettingCard(loanSetting);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanSettingCard(LoanSetting loanSetting) {
    // Calculate eligible amount based on settings
    double eligibleAmount = 0.0;
    double baseAmount = 0.0;

    if (loanSetting.shareSaving == 'SAVING') {
      baseAmount = totalSavings;
    } else if (loanSetting.shareSaving == 'SHARE' &&
        loanSetting.sharePrice != null) {
      baseAmount = (totalSavings / loanSetting.sharePrice!).floor() *
          loanSetting.sharePrice!;
    }

    if (loanSetting.multiplier != null && loanSetting.multiplier! > 0) {
      eligibleAmount = baseAmount * loanSetting.multiplier!;
    } else if (loanSetting.percentage != null && loanSetting.percentage! > 0) {
      eligibleAmount = baseAmount * (loanSetting.percentage! / 100);
    }

    // Apply min/max constraints
    if (loanSetting.minAmounts != null &&
        eligibleAmount < loanSetting.minAmounts!) {
      eligibleAmount = loanSetting.minAmounts!;
    }
    if (loanSetting.maxAmounts != null &&
        eligibleAmount > loanSetting.maxAmounts!) {
      eligibleAmount = loanSetting.maxAmounts!;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            _showLoanApplicationForm(loanSetting, eligibleAmount, baseAmount);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: mainFontColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.account_balance_rounded,
                        color: mainFontColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loanSetting.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: loanSetting.shareSaving == 'SHARE'
                                  ? Colors.blue.withOpacity(0.15)
                                  : Colors.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              loanSetting.shareSaving == 'SHARE'
                                  ? 'Hisa'
                                  : 'Akiba',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: loanSetting.shareSaving == 'SHARE'
                                    ? Colors.blue[800]
                                    : Colors.green[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 20,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey[200], height: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        Icons.trending_up_rounded,
                        'Riba',
                        '${loanSetting.interestRate}%',
                        Colors.orange,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey[200],
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.calendar_month_rounded,
                        'Muda',
                        '${loanSetting.maxPeriodMonths} miezi',
                        Colors.teal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue[50]!,
                        Colors.blue[100]!.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Unastahili:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        NumberFormat.currency(symbol: 'TSh ')
                            .format(eligibleAmount),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
                if (loanSetting.minAmounts != null ||
                    loanSetting.maxAmounts != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Kikomo: Tsh ${loanSetting.minAmounts ?? 0} - ${loanSetting.maxAmounts != null ? NumberFormat().format(loanSetting.maxAmounts) : '∞'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(
      IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showLoanApplicationForm(
      LoanSetting loanSetting, double eligibleAmount, double baseAmount) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final monthsController =
        TextEditingController(text: loanSetting.maxPeriodMonths.toString());

    double totalAmount = 0.0;
    double monthlyInstallment = 0.0;
    bool isSubmitting = false;

    void calculateLoanDetails(StateSetter setModalState) {
      final amount = double.tryParse(amountController.text) ?? 0.0;
      final months = int.tryParse(monthsController.text) ?? 1;

      if (amount > 0 && months > 0) {
        totalAmount = amount + (amount * loanSetting.interestRate / 100);
        monthlyInstallment = totalAmount / months;
        setModalState(() {});
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          amountController
              .addListener(() => calculateLoanDetails(setModalState));
          monthsController
              .addListener(() => calculateLoanDetails(setModalState));

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
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
                      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                      left: 20,
                      right: 20,
                      top: 20,
                    ),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      mainFontColor,
                                      mainFontColor.withOpacity(0.7)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.request_quote_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loanSetting.name,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      'Omba Mkopo',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () => Navigator.pop(context),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.grey[100],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Savings/Share Info Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  loanSetting.shareSaving == 'SHARE'
                                      ? Colors.blue[50]!
                                      : Colors.green[50]!,
                                  Colors.white,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: loanSetting.shareSaving == 'SHARE'
                                    ? Colors.blue[200]!
                                    : Colors.green[200]!,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          loanSetting.shareSaving == 'SHARE'
                                              ? 'Jumla ya Hisa'
                                              : 'Jumla ya Akiba',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          NumberFormat.currency(symbol: 'TSh ')
                                              .format(baseAmount),
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Icon(
                                      loanSetting.shareSaving == 'SHARE'
                                          ? Icons.share_rounded
                                          : Icons.savings_rounded,
                                      size: 40,
                                      color: loanSetting.shareSaving == 'SHARE'
                                          ? Colors.blue[300]
                                          : Colors.green[300],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Divider(color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Mkopo Unaostahili',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          NumberFormat.currency(symbol: 'TSh ')
                                              .format(eligibleAmount),
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                            color: loanSetting.shareSaving ==
                                                    'SHARE'
                                                ? Colors.blue[700]
                                                : Colors.green[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color:
                                              loanSetting.shareSaving == 'SHARE'
                                                  ? Colors.blue[200]!
                                                  : Colors.green[200]!,
                                        ),
                                      ),
                                      child: Text(
                                        loanSetting.multiplier != null
                                            ? '${loanSetting.multiplier}x mara'
                                            : '${loanSetting.percentage}%',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              loanSetting.shareSaving == 'SHARE'
                                                  ? Colors.blue[700]
                                                  : Colors.green[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Amount Field
                          TextFormField(
                            controller: amountController,
                            decoration: InputDecoration(
                              labelText: 'Kiasi cha Mkopo',
                              hintText: 'Ingiza kiasi unachotaka',
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(12),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: mainFontColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.payments_rounded,
                                    color: mainFontColor, size: 20),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: mainFontColor, width: 2),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Tafadhali ingiza kiasi';
                              }
                              final amount = double.tryParse(value);
                              if (amount == null || amount <= 0) {
                                return 'Ingiza kiasi sahihi';
                              }
                              if (loanSetting.minAmounts != null &&
                                  amount < loanSetting.minAmounts!) {
                                return 'Kiasi kidogo ni Tsh ${loanSetting.minAmounts}';
                              }
                              if (loanSetting.maxAmounts != null &&
                                  amount > loanSetting.maxAmounts!) {
                                return 'Kiasi kikubwa ni Tsh ${loanSetting.maxAmounts}';
                              }
                              if (amount > eligibleAmount) {
                                return 'Kiasi kimezidi unaostahili';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          // Months Field
                          TextFormField(
                            controller: monthsController,
                            decoration: InputDecoration(
                              labelText: 'Muda wa Malipo (Miezi)',
                              hintText: 'Ingiza muda',
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(12),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: mainFontColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.calendar_month_rounded,
                                    color: mainFontColor, size: 20),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: mainFontColor, width: 2),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Tafadhali ingiza muda';
                              }
                              final months = int.tryParse(value);
                              if (months == null || months <= 0) {
                                return 'Ingiza muda sahihi';
                              }
                              if (months > loanSetting.maxPeriodMonths) {
                                return 'Muda wa juu ni miezi ${loanSetting.maxPeriodMonths}';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          // Calculation Summary
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange[200]!),
                            ),
                            child: Column(
                              children: [
                                _buildSummaryRow(
                                  'Riba',
                                  '${loanSetting.interestRate}%',
                                  false,
                                ),
                                const SizedBox(height: 12),
                                Divider(color: Colors.orange[200]),
                                const SizedBox(height: 12),
                                _buildSummaryRow(
                                  'Jumla ya Malipo',
                                  NumberFormat.currency(symbol: 'TSh ')
                                      .format(totalAmount),
                                  true,
                                ),
                                const SizedBox(height: 12),
                                Divider(color: Colors.orange[200]),
                                const SizedBox(height: 12),
                                _buildSummaryRow(
                                  'Malipo ya Kila Mwezi',
                                  NumberFormat.currency(symbol: 'TSh ')
                                      .format(monthlyInstallment),
                                  true,
                                  color: Colors.orange[700],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate())
                                        return;

                                      setModalState(() => isSubmitting = true);

                                      try {
                                        final amount =
                                            double.parse(amountController.text);
                                        final response = await http.post(
                                          Uri.parse(
                                              '$baseUrl/loans/loan_application.php'),
                                          headers: {
                                            'Content-Type': 'application/json'
                                          },
                                          body: json.encode({
                                            'user_id': userData!.user.id,
                                            'jumuiya_id':
                                                userData!.user.jumuiya_id,
                                            'loan_setting_id': loanSetting.id,
                                            'amount': amount,
                                            'interest_rate':
                                                loanSetting.interestRate,
                                            'total_amount': totalAmount,
                                            'monthly_installment':
                                                monthlyInstallment,
                                            'status': 'pending',
                                            'loan_type':
                                                loanSetting.multiplier != null
                                                    ? 'multiplier'
                                                    : 'percentage',
                                          }),
                                        );

                                        if (response.statusCode == 200) {
                                          final data =
                                              json.decode(response.body);
                                          if (data['status'] == '200') {
                                            Navigator.pop(context);
                                            _showSuccess(
                                                'Ombi la mkopo limewasilishwa kikamilifu');
                                            _fetchUserLoans();
                                          } else {
                                            setModalState(
                                                () => isSubmitting = false);
                                            _showError(data['message']);
                                          }
                                        } else {
                                          setModalState(
                                              () => isSubmitting = false);
                                          _showError(
                                              'Imeshindwa kuwasilisha ombi');
                                        }
                                      } catch (e) {
                                        setModalState(
                                            () => isSubmitting = false);
                                        _showError('Hitilafu: $e');
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: mainFontColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 4,
                              ),
                              child: isSubmitting
                                  ? const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Inawasilisha...',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Text(
                                      'Wasilisha Ombi',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).whenComplete(() {
      // amountController.dispose();
      // monthsController.dispose();
    });
  }

  Widget _buildSummaryRow(String label, String value, bool bold,
      {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final maxWidth = isTablet ? 800.0 : screenWidth;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        foregroundColor: mainFontColor,
        backgroundColor: Colors.white,
        title: Text(
          'Maombi ya Mkopo',
          style: TextStyle(
            fontSize: isTablet ? 22 : 18,
            color: mainFontColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.add_rounded,
              color: mainFontColor,
              size: 28,
            ),
            onPressed: () => _showLoanSelectionBottomSheet(context),
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
                      _buildUserLoansSection(screenWidth, isTablet),
                      SizedBox(height: screenHeight * 0.02),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildUserLoansSection(double screenWidth, bool isTablet) {
    return Container(
      margin: EdgeInsets.all(screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //show my statistics
          if (isLoadingUserStats)
            Container(
              padding: const EdgeInsets.all(16),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (userLoanStatistics != null)
            Column(
              children: [
                // Toggle Button
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _showStatistics = !_showStatistics;
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Takwimu Zangu za Mikopo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(
                          _showStatistics
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: mainFontColor,
                        ),
                      ],
                    ),
                  ),
                ),

                // Statistics Content (collapsible)
                if (_showStatistics)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Loan Statistics Row
                        Row(
                          children: [
                            Expanded(
                              child: _MiniStatCard(
                                icon: Icons.account_balance_rounded,
                                label: 'Jumla ya Mikopo',
                                value:
                                    'Tsh ${LoanSettingService.formatCurrency(userLoanStatistics!['loan_statistics']['totalLoanGiven'])}',
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MiniStatCard(
                                icon: Icons.trending_up_rounded,
                                label: 'Riba Inayotarajiwa',
                                value:
                                    'Tsh ${LoanSettingService.formatCurrency(userLoanStatistics!['loan_statistics']['totalInterestExpected'])}',
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _MiniStatCard(
                                icon: Icons.payments_rounded,
                                label: 'Jumla ya Kulipa',
                                value:
                                    'Tsh ${LoanSettingService.formatCurrency(userLoanStatistics!['loan_statistics']['totalExpectedToBeCollected'])}',
                                color: Colors.purple,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MiniStatCard(
                                icon: Icons.numbers_rounded,
                                label: 'Idadi ya Mikopo',
                                value:
                                    '${userLoanStatistics!['loan_statistics']['totalLoansCount']}',
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Collection Statistics Row
                        Row(
                          children: [
                            Expanded(
                              child: _MiniStatCard(
                                icon: Icons.check_circle_rounded,
                                label: 'Umelipa',
                                value:
                                    'Tsh ${LoanSettingService.formatCurrency(userLoanStatistics!['collection_statistics']['totalCollected'])}',
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MiniStatCard(
                                icon: Icons.pending_actions_rounded,
                                label: 'Baki',
                                value:
                                    'Tsh ${LoanSettingService.formatCurrency(userLoanStatistics!['collection_statistics']['remainingBalance'])}',
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Loan Details Row
                        Row(
                          children: [
                            Expanded(
                              child: _MiniLoanCard(
                                icon: Icons.arrow_upward_rounded,
                                label: 'Mkopo Mkubwa',
                                amount: userLoanStatistics!['biggest_loan']
                                    ['amount'],
                                totalAmount: userLoanStatistics!['biggest_loan']
                                    ['total_amount'],
                                color: Colors.indigo,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MiniLoanCard(
                                icon: Icons.arrow_downward_rounded,
                                label: 'Mkopo Mdogo',
                                amount: userLoanStatistics!['smallest_loan']
                                    ['amount'],
                                totalAmount:
                                    userLoanStatistics!['smallest_loan']
                                        ['total_amount'],
                                color: Colors.pink,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),

          const SizedBox(height: 16),

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

// Mini Statistics Card Widget
class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// Mini Loan Card Widget
class _MiniLoanCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final dynamic amount;
  final dynamic totalAmount;
  final Color color;

  const _MiniLoanCard({
    required this.icon,
    required this.label,
    required this.amount,
    required this.totalAmount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Mkopo: Tsh ${LoanSettingService.formatCurrency(amount)}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            'Jumla: Tsh ${LoanSettingService.formatCurrency(totalAmount)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
