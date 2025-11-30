// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:jumuiya_yangu/main.dart';
import 'package:jumuiya_yangu/models/sms_bando_model.dart';
import 'package:jumuiya_yangu/pages/sms_bando/sms_bando_form_page.dart';
import 'package:jumuiya_yangu/shared/components/modern_widgets.dart';
import 'package:jumuiya_yangu/theme/colors.dart';
import 'package:jumuiya_yangu/utils/url.dart';
import 'package:page_transition/page_transition.dart';
import 'package:url_launcher/url_launcher.dart';

class SmsBandoListPage extends StatefulWidget {
  const SmsBandoListPage({super.key});

  @override
  State<SmsBandoListPage> createState() => _SmsBandoListPageState();
}

class _SmsBandoListPageState extends State<SmsBandoListPage> {
  bool _isLoading = false;
  List<SmsBandoSubscription> subscriptions = [];
  List<SmsBandoSubscription> filteredSubscriptions = [];
  String searchTerm = '';
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat currencyFormat = NumberFormat.currency(
    symbol: 'Tsh ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _fetchSubscriptions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterSubscriptions() {
    if (searchTerm.isEmpty) {
      setState(() {
        filteredSubscriptions = List.from(subscriptions);
      });
      return;
    }

    setState(() {
      filteredSubscriptions = subscriptions.where((subscription) {
        return subscription.smsNumber
                .toString()
                .toLowerCase()
                .contains(searchTerm.toLowerCase()) ||
            subscription.packageName
                .toLowerCase()
                .contains(searchTerm.toLowerCase()) ||
            subscription.paymentStatus
                .toLowerCase()
                .contains(searchTerm.toLowerCase()) ||
            subscription.tarehe
                .toLowerCase()
                .contains(searchTerm.toLowerCase()) ||
            currencyFormat
                .format(subscription.tsh)
                .toLowerCase()
                .contains(searchTerm.toLowerCase());
      }).toList();
    });
  }

  Future<void> _fetchSubscriptions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/sms_bando/get_sms_bando_history.php?jumuiya_id=${userData!.user.jumuiya_id}'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == "200") {
          setState(() {
            subscriptions = (data['data'] as List)
                .map((item) => SmsBandoSubscription.fromJson(item))
                .toList();
            filteredSubscriptions = List.from(subscriptions);
          });
        } else {
          // Handle error response
          _showSnackBar(data['message'] ?? "Failed to fetch subscriptions");
        }
      } else {
        _showSnackBar("Failed to connect to server");
      }
    } catch (e) {
      _showSnackBar("⚠️ Tafadhali hakikisha umeunganishwa na intaneti.");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteSubscription(int id) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await http.post(
        Uri.parse('$baseUrl/sms_bando/delete_sms_bando.php'),
        headers: {'Accept': 'application/json'},
        body: jsonEncode({
          'id': id.toString(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == "200") {
          _showSnackBar("✅ Umefanikiwa kufuta malipo ya SMS");
          _fetchSubscriptions();
        } else {
          _showSnackBar(data['message'] ?? "Failed to delete subscription");
        }
      } else {
        _showSnackBar("Failed to connect to server");
      }
    } catch (e) {
      _showSnackBar("⚠️ Tafadhali hakikisha umeunganishwa na intaneti.");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _confirmDelete(SmsBandoSubscription subscription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thibitisha Kufuta'),
        content: Text(
            'Una uhakika unataka kufuta malipo ya SMS ${subscription.smsNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ghairi'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: errorColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteSubscription(subscription.id!);
            },
            child: const Text('Futa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mainFontColor,
        foregroundColor: Colors.white,
        title: const Text('Historia ya SMS'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchSubscriptions,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'sms_bando_add',
        onPressed: () {
          Navigator.push(
            context,
            PageTransition(
              type: PageTransitionType.rightToLeft,
              child: const SmsBandoFormPage(),
            ),
          ).then((_) => _fetchSubscriptions());
        },
        backgroundColor: mainFontColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Ongeza SMS',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : subscriptions.isEmpty
              ? _buildEmptyState()
              : _buildSubscriptionsListWithSearch(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.message_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Hakuna malipo ya SMS yaliyopatikana',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ongeza malipo ya kwanza ya SMS',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(
              Icons.add,
              color: Colors.white,
            ),
            label: const Text(
              'Ongeza SMS',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: mainFontColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              Navigator.push(
                context,
                PageTransition(
                  type: PageTransitionType.rightToLeft,
                  child: const SmsBandoFormPage(),
                ),
              ).then((_) => _fetchSubscriptions());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionsListWithSearch() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tafuta...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchTerm.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          searchTerm = '';
                          _filterSubscriptions();
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: mainFontColor),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                searchTerm = value;
                _filterSubscriptions();
              });
            },
          ),
        ),

        // Results count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'Matokeo: ${filteredSubscriptions.length} kati ya ${subscriptions.length}',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        // List of subscriptions
        Expanded(
          child: filteredSubscriptions.isEmpty
              ? _buildNoResultsFound()
              : _buildSubscriptionsList(),
        ),
      ],
    );
  }

  Widget _buildNoResultsFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Hakuna matokeo yaliyopatikana',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Jaribu kutafuta kitu kingine',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionsList() {
    return RefreshIndicator(
      onRefresh: _fetchSubscriptions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredSubscriptions.length,
        itemBuilder: (context, index) {
          final subscription = filteredSubscriptions[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ModernCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(subscription.paymentStatus)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _getStatusText(subscription.paymentStatus),
                              style: TextStyle(
                                color:
                                    _getStatusColor(subscription.paymentStatus),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(
                              width: 4,
                            ),
                            Text(
                              subscription.packageName,
                              style: TextStyle(
                                color:
                                    subscription.packageName == 'NORMAL PACKAGE'
                                        ? Colors.blue
                                        : subscription.packageName ==
                                                'PREMIUM PACKAGE'
                                            ? Colors.purple
                                            : subscription.packageName ==
                                                    'GOLD PACKAGE'
                                                ? Colors.amber[700]
                                                : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            )
                          ],
                        ),
                      ),
                      Visibility(
                        visible: subscription.paymentStatus == 'Inasubiri',
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  PageTransition(
                                    type: PageTransitionType.rightToLeft,
                                    child: SmsBandoFormPage(
                                        subscription: subscription),
                                  ),
                                ).then((_) => _fetchSubscriptions());
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: errorColor),
                              onPressed: () => _confirmDelete(subscription),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildInfoItem(
                        'SMS ${subscription.paymentStatus == 'Inasubiri' ? "Zilizoombwa" : "Zilizonunuliwa"}',
                        subscription.smsNumber.toString(),
                        Icons.sms,
                        blue,
                      ),
                      const SizedBox(width: 16),
                      _buildInfoItem(
                        'Kiasi',
                        currencyFormat.format(subscription.tsh),
                        Icons.payments,
                        green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        subscription.tarehe,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (subscription.paymentStatus == 'Inasubiri')
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.info, color: Colors.orange),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Tafadhali piga simu namba kufanya malipo ya SMS',
                                    style: TextStyle(
                                      color: Colors.orange[800],
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final Uri telLaunchUri = Uri(
                                  scheme: 'tel',
                                  path: '0659515042',
                                );
                                try {
                                  await launchUrl(telLaunchUri);
                                } catch (e) {
                                  _showSnackBar('Imeshindwa kufungua simu');
                                }
                              },
                              icon: const Icon(Icons.phone),
                              label: const Text('Piga 0659515042'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                minimumSize: const Size(double.infinity, 40),
                              ),
                            ),
                          ],
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

  Widget _buildInfoItem(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return green;
      case 'pending':
        return orange;
      case 'cancelled':
        return errorColor;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'Imelipwa';
      case 'pending':
        return 'Inasubiri';
      case 'cancelled':
        return 'Imeghairiwa';
      default:
        return status;
    }
  }
}
