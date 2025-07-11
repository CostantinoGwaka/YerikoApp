import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jumuiya_yangu/models/user_collection_model.dart';

class CollectionsTablePage extends StatelessWidget {
  final List<CollectionItem> collections;

  const CollectionsTablePage({super.key, required this.collections});

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mchakato wa Mchango'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: collections.isEmpty
            ? const Center(child: Text('Hakuna data ya mchango.'))
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  padding: EdgeInsets.all(MediaQuery.of(context).size.width / 90),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          DataTable(
                            headingRowColor: WidgetStateProperty.resolveWith<Color?>(
                              (Set<WidgetState> states) => Colors.indigo.shade100,
                            ),
                            dataRowColor: WidgetStateProperty.resolveWith<Color?>(
                              (Set<WidgetState> states) =>
                                  states.contains(WidgetState.selected) ? Colors.indigo.shade50 : Colors.white,
                            ),
                            headingTextStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                              fontSize: 17,
                              letterSpacing: 1.1,
                            ),
                            dataTextStyle: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                            columnSpacing: MediaQuery.of(context).size.width / 30,
                            dividerThickness: 1.0,
                            columns: const [
                              DataColumn(
                                  label: Padding(
                                padding: EdgeInsets.symmetric(vertical: 2.0),
                                child: Text('SN'),
                              )),
                              DataColumn(
                                  label: Padding(
                                padding: EdgeInsets.symmetric(vertical: 6.0),
                                child: Text('Kiasi'),
                              )),
                              DataColumn(
                                  label: Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text('Mwezi'),
                              )),
                              DataColumn(
                                  label: Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text('Tarehe'),
                              )),
                            ],
                            rows: [
                              ...collections.asMap().entries.map((entry) {
                                final index = entry.key;
                                final item = entry.value;
                                String formattedDate;
                                try {
                                  final date = DateTime.parse(item.registeredDate);
                                  formattedDate = DateFormat('yyyy-MM-dd').format(date);
                                } catch (_) {
                                  formattedDate = item.registeredDate;
                                }
                                return DataRow(
                                  cells: [
                                    DataCell(Text('${index + 1}')),
                                    DataCell(Text(
                                      NumberFormat('#,##0', 'en_US').format(int.tryParse(item.amount) ?? 0),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green,
                                      ),
                                    )),
                                    DataCell(Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                                      child: Text(item.monthly),
                                    )),
                                    DataCell(Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                                      child: Text(formattedDate),
                                    )),
                                  ],
                                );
                              }),
                              // Total row
                              DataRow(
                                color: WidgetStateProperty.resolveWith<Color?>(
                                  (Set<WidgetState> states) => Colors.indigo.shade50,
                                ),
                                cells: [
                                  const DataCell(
                                    Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8.0),
                                      child: Text(
                                        'Jumla',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.indigo,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                                      child: Text(
                                        NumberFormat('#,##0', 'en_US').format(
                                          collections.fold<int>(
                                            0,
                                            (sum, item) => sum + (int.tryParse(item.amount) ?? 0),
                                          ),
                                        ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const DataCell(
                                    Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8.0),
                                      child: Text(''),
                                    ),
                                  ),
                                  const DataCell(
                                    Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8.0),
                                      child: Text(''),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
