// ignore_for_file: use_super_parameters, deprecated_member_use

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:jumuiya_yangu/shared/components/modern_widgets.dart';

import '../main.dart';
import '../models/paid_feature_model.dart';

import '../theme/colors.dart';
import '../utils/url.dart';

class HudumaZaZiadaPage extends StatefulWidget {
  const HudumaZaZiadaPage({Key? key}) : super(key: key);

  @override
  State<HudumaZaZiadaPage> createState() => _HudumaZaZiadaPageState();
}

class _HudumaZaZiadaPageState extends State<HudumaZaZiadaPage> {
  bool _isLoading = false;
  List<PaidFeatureModel> _paidFeatures = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchPaidFeatures();
  }

  Future<void> _fetchPaidFeatures() async {
    if (userData?.user.jumuiya_id == null) {
      setState(() {
        _errorMessage = 'Hakuna taarifa za jumuiya';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/report_features/get_all_my_payment_features.php'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "user_id": userData!.user.id.toString(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'].toString() == "200" && data['data'] != null) {
          List<dynamic> featuresJson = data['data'];
          setState(() {
            _paidFeatures = featuresJson
                .map((feature) => PaidFeatureModel.fromJson(feature))
                .toList();
          });
        } else {
          setState(() {
            _errorMessage = 'Hakuna huduma zilizolipiwa zilizopatikana';
          });
        }
      } else {
        setState(() {
          _errorMessage =
              'Imeshindwa kupakua taarifa. Tafadhali jaribu tena baadaye.';
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching paid features: $e');
      }
      setState(() {
        _errorMessage = 'Kuna tatizo la mtandao. Tafadhali jaribu tena.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String formatDate(String dateString) {
    if (dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mainFontColor,
        foregroundColor: Colors.white,
        title: const Text('Huduma Za Ziada'),
        elevation: 0,
        actions: [],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchPaidFeatures,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 60,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _fetchPaidFeatures,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Jaribu Tena'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: mainFontColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : _paidFeatures.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.receipt_long,
                                size: 60,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Hakuna huduma za ziada zilizolipiwa bado',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () {
                                  // Navigate to buy features page
                                  // This would be implemented in a future update
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Kipengele cha kununua huduma kitakuja hivi karibuni!'),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add_shopping_cart),
                                label: const Text('Nunua Huduma'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: mainFontColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _paidFeatures.length,
                        itemBuilder: (context, index) {
                          final feature = _paidFeatures[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: ModernCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: green.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.electric_bolt_rounded,
                                          color: green,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${feature.service!.sname} -(${feature.service!.spaymentType})',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              'TZS ${feature.price}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: feature.active
                                              ? green.withValues(alpha: 0.1)
                                              : Colors.red
                                                  .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          feature.active
                                              ? 'Inatumika'
                                              : 'Bado Kutumika',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: feature.active
                                                ? green
                                                : Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                    'Kwa ajili ya:',
                                    feature.service!.forUserType,
                                    Colors.black87,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                    'Hali ya Malipo:',
                                    feature.paymentStatus,
                                    feature.paymentStatus.toLowerCase() ==
                                            'paid'
                                        ? green
                                        : orange,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                    'Mtumiaji:',
                                    feature.user?.userFullName ??
                                        feature.userName,
                                    Colors.black87,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                    'Tarehe ya Kuanza:',
                                    formatDate(feature.startDate),
                                    Colors.black87,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                    'Tarehe ya Kuisha:',
                                    formatDate(feature.endDate),
                                    Colors.black87,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to buy features page
          // This would be implemented in a future update
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Kipengele cha kununua huduma kitakuja hivi karibuni!'),
            ),
          );
        },
        backgroundColor: mainFontColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}
