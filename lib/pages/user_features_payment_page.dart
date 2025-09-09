// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:jumuiya_yangu/main.dart';
import 'package:jumuiya_yangu/theme/colors.dart';
import 'package:jumuiya_yangu/utils/url.dart';

class Service {
  final int id;
  final String serviceName;
  final String servicePrice;
  final String paymentType;
  final String forUserType;
  final bool status;
  final String tarehe;

  Service(
      {required this.id,
      required this.serviceName,
      required this.paymentType,
      required this.servicePrice,
      required this.forUserType,
      required this.status,
      required this.tarehe});

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] ?? '',
      serviceName: json['serviceName'] ?? '',
      paymentType: json['paymentType'] ?? '',
      servicePrice: json['servicePrice'] ?? '',
      forUserType: json['forUserType'] ?? '',
      status: json['status'] ?? '',
      tarehe: json['tarehe'] ?? '',
    );
  }
}

class ServicesResponse {
  final String message;
  final List<Service> data;

  ServicesResponse({
    required this.message,
    required this.data,
  });

  factory ServicesResponse.fromJson(Map<String, dynamic> json) {
    return ServicesResponse(
      message: json['message'] ?? '',
      data: (json['data'] as List?)
              ?.map((service) => Service.fromJson(service))
              .toList() ??
          [],
    );
  }
}

class UserFeaturesPaymentPage extends StatefulWidget {
  const UserFeaturesPaymentPage({super.key});

  @override
  State<UserFeaturesPaymentPage> createState() =>
      _UserFeaturesPaymentPageState();
}

class _UserFeaturesPaymentPageState extends State<UserFeaturesPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  List<Service> services = [];
  Service? selectedService;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchServices();
  }

  Future<void> fetchServices() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/report_features/get_all_services.php'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final servicesResponse = ServicesResponse.fromJson(jsonResponse);

        setState(() {
          services = servicesResponse.data;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage =
              'Imeshindwa kupata huduma zinazohitajika. Jaribu tena baadae.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage =
            'Imeshindwa kupata huduma zinazohitajika. Jaribu tena baadae.';
        isLoading = false;
      });
    }
  }

  Future<void> submitFeatureRequest() async {
    if (_formKey.currentState?.validate() != true || selectedService == null) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/report_features/add_user_features_payment.php'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'jumuiya_id': userData!.user.jumuiya_id.toString(),
          'service_id': selectedService!.id,
          'sdate': 'Not SET',
          'edate': 'Not SET',
          'price': selectedService!.servicePrice,
          'active': '0',
          'user_name': userData!.user.userFullName,
          'user_id': userData!.user.id.toString(),
          'payment_status': 'NOT_PAID',
        }),
      );

      final jsonResponse = json.decode(response.body);

      if (response.statusCode == 200 &&
          (jsonResponse['status'] == 'success' ||
              jsonResponse['status'] == true)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Maombi ya huduma yamefanyika kikamilifu',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text(jsonResponse['message'] ??
                  'Imeshindwa kutuma maombi. Jaribu tena baadae.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text(
                'Imeshindwa kutuma maombi. Tafadhali hakikisha umeunganishwa na intaneti.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mainFontColor,
        foregroundColor: Colors.white,
        title: const Text('Huduma za Ziada'),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? _buildErrorView()
              : services.isEmpty
                  ? _buildEmptyView()
                  : _buildFormView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: fetchServices,
            icon: const Icon(Icons.refresh),
            label: const Text('Jaribu Tena'),
            style: ElevatedButton.styleFrom(
              backgroundColor: mainFontColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Hakuna huduma za ziada kwa sasa.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: fetchServices,
            icon: const Icon(Icons.refresh),
            label: const Text('Onyesha Upya'),
            style: ElevatedButton.styleFrom(
              backgroundColor: mainFontColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.star, color: Colors.amber),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Huduma za Ziada',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Chagua huduma unayotaka kuomba',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Service selection
              const Text(
                'Chagua Huduma',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: DropdownButtonFormField<Service>(
                  value: selectedService,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.arrow_drop_down),
                  elevation: 2,
                  style: const TextStyle(color: Colors.black87),
                  onChanged: (Service? newValue) {
                    setState(() {
                      selectedService = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Tafadhali chagua huduma';
                    }
                    return null;
                  },
                  items: services
                      .map<DropdownMenuItem<Service>>((Service service) {
                    return DropdownMenuItem<Service>(
                      value: service,
                      child: Text(service.serviceName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          )),
                    );
                  }).toList(),
                ),
              ),

              if (selectedService != null) ...[
                const SizedBox(height: 24),

                // Service details card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Maelezo ya Huduma',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${selectedService!.serviceName} - ${selectedService!.paymentType}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.payment,
                              size: 18, color: Colors.green),
                          const SizedBox(width: 8),
                          const Text(
                            'Bei:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${NumberFormat("#,##0").format(int.parse(selectedService!.servicePrice))} TZS',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 18, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            'Hali ya malipo:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'HAIJALIPWA',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : submitFeatureRequest,
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(
                    isLoading ? 'Inatuma ombi...' : 'Tuma Ombi',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainFontColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              // Notice text
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber[700]),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Taarifa Muhimu',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Baada ya kutuma ombi lako, utapigiwa simu ili kupata maelekezo jinsi ya kulipa. Huduma itakuwa tayari kutumika mara baada ya kuthibitisha malipo yako.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
