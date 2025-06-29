import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yeriko_app/models/other_collection_model.dart'; // Adjust path accordingly

class OtherCollectionsTablePage extends StatelessWidget {
  final List<OtherCollection> otherCollections;

  const OtherCollectionsTablePage({super.key, required this.otherCollections});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Michango Mengineyo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: otherCollections.isEmpty
          ? const Center(child: Text('Hakuna data ya mchango mwingine.'))
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.resolveWith<Color?>(
                  (Set<WidgetState> states) => Colors.indigo.shade50,
                ),
                dataRowColor: WidgetStateProperty.resolveWith<Color?>(
                  (Set<WidgetState> states) =>
                      states.contains(WidgetState.selected) ? Colors.indigo.shade100 : Colors.white,
                ),
                headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                  fontSize: 16,
                ),
                dataTextStyle: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                ),
                columnSpacing: 28,
                dividerThickness: 1.2,
                columns: const [
                  DataColumn(label: Text('SN')),
                  DataColumn(label: Text('Aina')),
                  DataColumn(label: Text('Kiasi')),
                  DataColumn(label: Text('Mwezi')),
                  DataColumn(label: Text('Tarehe')),
                ],
                rows: otherCollections.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return DataRow(
                    cells: [
                      DataCell(Text('${index + 1}')),
                      DataCell(Text(item.collectionType.collectionName)),
                      DataCell(Text(
                        'TZS ${NumberFormat('#,##0', 'en_US').format(int.tryParse(item.amount) ?? 0)}',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.green),
                      )),
                      DataCell(Text(item.monthly)),
                      DataCell(Text(item.registeredDate)),
                    ],
                  );
                }).toList(),
              ),
            ),
    );
  }
}
