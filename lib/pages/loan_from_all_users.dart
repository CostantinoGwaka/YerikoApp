// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:jumuiya_yangu/main.dart';
import 'package:jumuiya_yangu/models/user_loan_model.dart';
import 'package:jumuiya_yangu/models/loan_repayment_history_model.dart';
import 'package:jumuiya_yangu/pages/loan_setting.dart';
import 'package:jumuiya_yangu/theme/colors.dart';
import 'package:jumuiya_yangu/utils/url.dart';
import 'package:page_transition/page_transition.dart';
import 'package:jumuiya_yangu/services/loan_setting_service.dart';

class LoanFromAllUsersPage extends StatefulWidget {
  final String jumuiyaId;

  const LoanFromAllUsersPage({super.key, required this.jumuiyaId});

  @override
  State<LoanFromAllUsersPage> createState() => _LoanFromAllUsersPageState();
}

class _LoanFromAllUsersPageState extends State<LoanFromAllUsersPage> {
  String selectedStatus = 'pending';
  List<UserLoan> loans = [];
  List<UserLoan> filteredLoans = [];
  bool isLoading = false;
  String errorMessage = '';
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchLoans();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = _searchController.text.toLowerCase();
      _filterLoans();
    });
  }

  void _filterLoans() {
    setState(() {
      if (searchQuery.isEmpty) {
        filteredLoans = List.from(loans);
      } else {
        filteredLoans = loans.where((loan) {
          final userName = loan.user.userFullName.toLowerCase();
          final loanType = loan.loanType.toLowerCase();
          return userName.contains(searchQuery) ||
              loanType.contains(searchQuery);
        }).toList();
      }
    });
  }

  Future<void> fetchLoans() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/loans/get_loans_application_jumuiya_id_status.php'),
        body: jsonEncode({
          'jumuiya_id': widget.jumuiyaId,
          'status': selectedStatus,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == '200') {
          final loansResponse = UserLoansResponse.fromJson(data);
          setState(() {
            loans = loansResponse.data;
            filteredLoans = List.from(loans);
            isLoading = false;
          });
          _filterLoans(); // Apply filter after loading
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Failed to load loans';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Server error: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = '⚠️ Tafadhali hakikisha umeunganishwa na intaneti';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mainFontColor,
        foregroundColor: Colors.white,
        title: const Text('Mikopo'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeft,
                child: LoanSettingPage(
                  jumuiyaId: userData?.user.jumuiya_id ?? 0,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or loan type...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Status Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.05),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: LoanSettingService.statusList.map((status) {
                  final isSelected = selectedStatus == status['value'];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      selected: isSelected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            status['icon'],
                            size: 16,
                            color: isSelected ? Colors.white : status['color'],
                          ),
                          const SizedBox(width: 6),
                          Text(status['label']),
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
                          fetchLoans();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Results Count
          if (!isLoading && errorMessage.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${filteredLoans.length} loan${filteredLoans.length != 1 ? 's' : ''} found',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (searchQuery.isNotEmpty)
                    Text(
                      'of ${loans.length} total',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ),

          // Loans List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 60, color: Colors.red.shade300),
                            const SizedBox(height: 16),
                            Text(errorMessage,
                                style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: fetchLoans,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : filteredLoans.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox,
                                    size: 80, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  searchQuery.isNotEmpty
                                      ? 'No loans match your search'
                                      : 'No $selectedStatus loans found',
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600),
                                ),
                                if (searchQuery.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  TextButton.icon(
                                    onPressed: () {
                                      _searchController.clear();
                                    },
                                    icon: const Icon(Icons.clear),
                                    label: const Text('Clear search'),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: fetchLoans,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: filteredLoans.length,
                              itemBuilder: (context, index) {
                                final loan = filteredLoans[index];
                                return LoanCard(
                                  loan: loan,
                                  statusColor:
                                      LoanSettingService.getStatusColor(
                                          loan.status),
                                  formatCurrency:
                                      LoanSettingService.formatCurrency,
                                  formatDate: LoanSettingService.formatDate,
                                  searchQuery: searchQuery,
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class LoanCard extends StatelessWidget {
  final UserLoan loan;
  final Color statusColor;
  final String Function(dynamic) formatCurrency;
  final String Function(String?) formatDate;
  final String searchQuery;

  const LoanCard({
    super.key,
    required this.loan,
    required this.statusColor,
    required this.formatCurrency,
    required this.formatDate,
    this.searchQuery = '',
  });

  Future<void> _updateLoanStatus(
      BuildContext context, int loanId, String status) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/loans/loan_status_update.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id': loanId,
          'status': status,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == '200') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(data['message']), backgroundColor: Colors.green),
          );
          // Refresh the page
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LoanFromAllUsersPage(
                jumuiyaId: loan.jumuiya.id.toString(),
              ),
            ),
          );
        } else {
          throw Exception(data['message']);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showRepaymentBottomSheet(BuildContext context) {
    final amountController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.payment,
                            color: Colors.green.shade700, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Rejesha Mkopo',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              loan.user.userFullName,
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Kiasi cha Rejesho',
                      hintText: 'Weka kiasi',
                      prefixIcon: const Icon(Icons.money),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (amountController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Tafadhali weka kiasi'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);

                              try {
                                final response = await http.post(
                                  Uri.parse(
                                      '$baseUrl/loans/loan_repayment.php'),
                                  headers: {'Content-Type': 'application/json'},
                                  body: json.encode({
                                    'loan_id': loan.id,
                                    'jumuiya_id': loan.jumuiya.id,
                                    'amount': amountController.text,
                                    'collected_by': userData!.user.id,
                                  }),
                                );

                                if (response.statusCode == 200) {
                                  final data = json.decode(response.body);
                                  if (data['status'] == '200') {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(data['message']),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } else {
                                    throw Exception(data['message']);
                                  }
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } finally {
                                setModalState(() => isSubmitting = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Wasilisha Rejesho',
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
        },
      ),
    );
  }

  void _showRepaymentHistory(BuildContext context, UserLoan userLoan) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: FutureBuilder(
          future: http.post(
            Uri.parse('$baseUrl/loans/loan_repayment_history.php'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'loan_id': userLoan.id,
            }),
          ),
          builder: (context, AsyncSnapshot<http.Response> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 60, color: Colors.red.shade300),
                    const SizedBox(height: 16),
                    Text('Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red)),
                  ],
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: Text('No data'));
            }

            try {
              final responseData = json.decode(snapshot.data!.body);

              if (responseData == null) {
                return const Center(child: Text('No response data'));
              }

              final historyResponse =
                  LoanRepaymentHistoryResponse.fromJson(responseData);

              if (historyResponse.status != '200') {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline,
                          size: 60, color: Colors.orange.shade300),
                      const SizedBox(height: 16),
                      Text(historyResponse.message,
                          textAlign: TextAlign.center),
                    ],
                  ),
                );
              }

              final statistics = historyResponse.statistics;
              final repayments = historyResponse.repayments;

              return Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.history,
                              color: Colors.blue.shade700, size: 28),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Historia ya Marejesho',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Takwimu na marejesho',
                                style:
                                    TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Statistics Cards
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.account_balance,
                                  label: 'Mkopo Uliotolewa',
                                  value:
                                      'TZS ${formatCurrency(statistics.totalLoanTaken)}',
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.paid,
                                  label: 'Umerudishwa',
                                  value:
                                      'TZS ${formatCurrency(statistics.totalLoanRepaid)}',
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.pending_actions,
                                  label: 'Baki',
                                  value:
                                      'TZS ${formatCurrency(statistics.remainingLoan)}',
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.trending_up,
                                  label: 'Asilimia',
                                  value:
                                      '${statistics.percentagePaid.toStringAsFixed(1)}%',
                                  color: Colors.purple,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Progress Bar
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade50,
                                  Colors.green.shade100
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Maendeleo ya Malipo',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${statistics.percentagePaid.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: statistics.percentagePaid / 100,
                                    minHeight: 10,
                                    backgroundColor: Colors.grey.shade300,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.green.shade700,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Malipo: ${statistics.numberOfPaymentsMade}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    if (statistics.lastPaymentDate != null)
                                      Text(
                                        'Mwisho: ${formatDate(statistics.lastPaymentDate)}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),
                          const Text(
                            'Historia ya Marejesho',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),

                          // Repayments List
                          if (repayments.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    Icon(Icons.receipt_long,
                                        size: 64, color: Colors.grey.shade300),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Hakuna marejesho bado',
                                      style: TextStyle(
                                          color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: repayments.length,
                              itemBuilder: (context, index) {
                                final repayment = repayments[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(Icons.payment,
                                          color: Colors.green.shade700),
                                    ),
                                    title: Text(
                                      'TZS ${formatCurrency(repayment.amount)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      formatDate(repayment.paidAt),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: Text(
                                      '#${repayment.id}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            } catch (e) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 60, color: Colors.red.shade300),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Error parsing data: $e',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  TextSpan _highlightText(String text, String query) {
    if (query.isEmpty) {
      return TextSpan(text: text);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final matches = <TextSpan>[];
    int start = 0;

    while (start < text.length) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        matches.add(TextSpan(text: text.substring(start)));
        break;
      }

      if (index > start) {
        matches.add(TextSpan(text: text.substring(start, index)));
      }

      matches.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: const TextStyle(
            backgroundColor: Colors.yellow,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      start = index + query.length;
    }

    return TextSpan(children: matches);
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = userData?.user.role == "ADMIN";
    final canApprove = loan.status == 'pending' && isAdmin;
    final canRepay =
        (loan.status == 'approved' || loan.status == 'in-progress') && isAdmin;
    final completed =
        (loan.status == 'completed' || loan.status == 'in-progress') && isAdmin;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigate to loan details
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            children: [
                              _highlightText(
                                  loan.user.userFullName, searchQuery),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@${loan.user.userName}',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor, width: 1.5),
                    ),
                    child: Text(
                      loan.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const Divider(height: 24),

              // Loan Details
              Row(
                children: [
                  Expanded(
                    child: _DetailItem(
                      icon: Icons.account_balance_wallet,
                      label: 'Amount',
                      value: 'TZS ${formatCurrency(loan.amount)}',
                      color: Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _DetailItem(
                      icon: Icons.percent,
                      label: 'Interest',
                      value: '${loan.interestRate}%',
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DetailItem(
                      icon: Icons.payments,
                      label: 'Total Amount',
                      value: 'TZS ${formatCurrency(loan.totalAmount)}',
                      color: Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _DetailItem(
                      icon: Icons.calendar_today,
                      label: 'Monthly',
                      value: 'TZS ${formatCurrency(loan.monthlyInstallment)}',
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),

              const Divider(height: 24),

              // Additional Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.category,
                                size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Flexible(
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700),
                                  children: [
                                    const TextSpan(text: 'Type: '),
                                    _highlightText(loan.loanType, searchQuery),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.group,
                                size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                loan.jumuiya.name,
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey.shade700),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text(
                            'Requested',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      Text(
                        formatDate(loan.requestedAt),
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),

              if (loan.approvedAt != null && loan.approvedAt != 'null') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.check_circle,
                        size: 16, color: Colors.green.shade600),
                    const SizedBox(width: 6),
                    Text(
                      'Approved: ${formatDate(loan.approvedAt.toString())}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ],

              if (isAdmin) ...[
                const SizedBox(height: 16),

                // Status Update Buttons (for pending loans)
                if (canApprove) ...[
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _updateLoanStatus(context, loan.id, 'rejected'),
                          icon: const Icon(Icons.cancel, size: 18),
                          label: const Text('Kataa'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateLoanStatus(
                              context, loan.id, 'in-progress'),
                          icon: const Icon(Icons.hourglass_empty, size: 18),
                          label: const Text('In Progress'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _updateLoanStatus(context, loan.id, 'approved'),
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text('Kubali'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // Repayment & History Buttons (for approved/in-progress loans)
                if (canRepay) ...[
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showRepaymentHistory(context, loan),
                          icon: const Icon(Icons.history, size: 18),
                          label: const Text('Historia'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showRepaymentBottomSheet(context),
                          icon: const Icon(Icons.payment, size: 18),
                          label: const Text('Rejesha'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                // History Buttons (for approved/in-progress loans)
                if (completed) ...[
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showRepaymentHistory(context, loan),
                          icon: const Icon(Icons.history, size: 18),
                          label: const Text('Historia'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
