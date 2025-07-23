import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jumuiya_yangu/models/user_collection_model.dart';
import 'package:jumuiya_yangu/shared/components/modern_widgets.dart';
import 'package:jumuiya_yangu/theme/colors.dart';

class CollectionsTablePage extends StatelessWidget {
  final List<CollectionItem> collections;

  const CollectionsTablePage({super.key, required this.collections});

  @override
  Widget build(BuildContext context) {
    final totalAmount = collections.fold<int>(
      0,
      (sum, item) => sum + (int.tryParse(item.amount) ?? 0),
    );

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: ModernAppBar(
        title: "Mchakato wa Mchango",
      ),
      body: collections.isEmpty
          ? EmptyState(
              icon: Icons.account_balance_wallet_rounded,
              title: "Hakuna Mchango",
              subtitle: "Hakuna data ya mchango inayopatikana kwa sasa.",
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Card
                  ModernCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: successGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Jumla ya Mchango",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "TSh ${NumberFormat('#,##0', 'en_US').format(totalAmount)}",
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: successColor,
                                ),
                              ),
                              Text(
                                "${collections.length} michango",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    "Historia ya Mchango",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Collections List
                  ModernCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: primaryGradient[0].withValues(alpha: 0.1),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: Row(
                            children: [
                              const Expanded(
                                flex: 1,
                                child: Text(
                                  "SN",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const Expanded(
                                flex: 2,
                                child: Text(
                                  "Kiasi",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const Expanded(
                                flex: 2,
                                child: Text(
                                  "Mwezi",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const Expanded(
                                flex: 2,
                                child: Text(
                                  "Tarehe",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Data Rows
                        ...collections.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          String formattedDate;
                          try {
                            final date = DateTime.parse(item.registeredDate);
                            formattedDate = DateFormat('dd/MM/yyyy').format(date);
                          } catch (_) {
                            formattedDate = item.registeredDate;
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: borderColor.withValues(alpha: 0.5),
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    NumberFormat('#,##0').format(int.tryParse(item.amount) ?? 0),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: successColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: infoColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _getMonthName(item.monthly),
                                      style: const TextStyle(
                                        color: infoColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    formattedDate,
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _getMonthName(String month) {
    final months = {
      "JANUARY": "Januari",
      "FEBRUARY": "Februari",
      "MARCH": "Machi",
      "APRIL": "Aprili",
      "MAY": "Mei",
      "JUNE": "Juni",
      "JULY": "Julai",
      "AUGUST": "Agosti",
      "SEPTEMBER": "Septemba",
      "OCTOBER": "Oktoba",
      "NOVEMBER": "Novemba",
      "DECEMBER": "Desemba",
    };
    return months[month] ?? month;
  }
}
