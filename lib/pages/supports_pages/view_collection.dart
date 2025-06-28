import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yeriko_app/models/user_collection_model.dart';

class CollectionsTablePage extends StatelessWidget {
  final List<CollectionItem> collections;

  const CollectionsTablePage({super.key, required this.collections});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mchakato wa Mchango'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: collections.isEmpty
          ? const Center(child: Text('Hakuna data ya mchango.'))
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.resolveWith<Color?>(
                  (Set<MaterialState> states) => Colors.blue.shade50,
                ),
                dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                  (Set<MaterialState> states) =>
                      states.contains(MaterialState.selected) ? Colors.blue.shade100 : Colors.white,
                ),
                headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
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
                  DataColumn(label: Text('Kiasi')),
                  DataColumn(label: Text('Mwezi')),
                  DataColumn(label: Text('Tarehe')),
                ],
                rows: collections.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return DataRow(
                    cells: [
                      DataCell(Text('${index + 1}')),
                      DataCell(Text(
                        NumberFormat('#,##0', 'en_US').format(int.tryParse(item.amount) ?? 0),
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
