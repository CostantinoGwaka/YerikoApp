// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:jumuiya_yangu/main.dart';
import 'package:jumuiya_yangu/models/user_loan_model.dart';
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
            ],
          ),
        ),
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
