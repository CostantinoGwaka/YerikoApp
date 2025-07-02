import 'package:flutter/material.dart';
import 'package:jumuiya_yangu/models/user_collection_table_model.dart';

const List<String> months = [
  "JANUARY",
  "FEBRUARY",
  "MARCH",
  "APRIL",
  "MAY",
  "JUNE",
  "JULY",
  "AUGUST",
  "SEPTEMBER",
  "OCTOBER",
  "NOVEMBER",
  "DECEMBER"
];

class UserMonthlyCollectionTable extends StatelessWidget {
  final UserMonthlyCollectionResponse? data; // from API

  const UserMonthlyCollectionTable({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: (data != null && data!.data.isNotEmpty)
          ? DataTable(
              columns: [
                const DataColumn(label: Text(' Mwanajumuiya')),
                ...months.map((m) => DataColumn(label: Text(m.substring(0, 3)))),
              ],
              rows: data!.data.map((user) {
                final List<String> collectedMonths = List<String>.from(user.monthsCollected);
                int userIndex = data!.data.indexOf(user) + 1;
                return DataRow(
                  cells: [
                    DataCell(Text('$userIndex. ${user.userFullName}')),
                    ...months.map((month) {
                      final hasCollection = collectedMonths.contains(month);
                      return DataCell(
                        hasCollection ? const Icon(Icons.check, color: Colors.green) : const SizedBox.shrink(),
                      );
                    }),
                  ],
                );
              }).toList(),
            )
          : const Center(child: Text('No data available')),
    );
  }
}
