// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:jumuiya_yangu/main.dart';
import 'package:jumuiya_yangu/models/sms_bando_model.dart';
import 'package:jumuiya_yangu/shared/components/modern_widgets.dart';
import 'package:jumuiya_yangu/theme/colors.dart';
import 'package:jumuiya_yangu/utils/url.dart';

class SmsPackage {
  final String name;
  final int minSms;
  final int maxSms;
  final double pricePerSms;

  const SmsPackage({
    required this.name,
    required this.minSms,
    required this.maxSms,
    required this.pricePerSms,
  });
}

class SmsBandoFormPage extends StatefulWidget {
  final SmsBandoSubscription? subscription;

  const SmsBandoFormPage({super.key, this.subscription});

  @override
  State<SmsBandoFormPage> createState() => _SmsBandoFormPageState();
}

class _SmsBandoFormPageState extends State<SmsBandoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _smsNumberController = TextEditingController();
  final _tshController = TextEditingController();
  final _dateController = TextEditingController();
  bool _isLoading = false;

  // Package definitions
  final List<SmsPackage> _packages = [
    const SmsPackage(
        name: 'NORMAL PACKAGE', minSms: 1, maxSms: 1000, pricePerSms: 30),
    const SmsPackage(
        name: 'PREMIUM PACKAGE', minSms: 1001, maxSms: 5000, pricePerSms: 25),
    const SmsPackage(
        name: 'GOLD PACKAGE', minSms: 5001, maxSms: 10000, pricePerSms: 20),
  ];

  SmsPackage _selectedPackage = const SmsPackage(
      name: 'NORMAL PACKAGE', minSms: 1, maxSms: 1000, pricePerSms: 30);
  String _packageName = 'NORMAL PACKAGE';

  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();

    if (widget.subscription != null) {
      _smsNumberController.text = widget.subscription!.smsNumber.toString();
      _tshController.text = widget.subscription!.tsh.toString();
      _dateController.text = widget.subscription!.tarehe;

      // Determine the package based on SMS number
      _setPackageBasedOnSmsNumber(int.parse(_smsNumberController.text));
    } else {
      _dateController.text = _dateFormat.format(DateTime.now());
    }

    // Add listener to SMS number controller to update the amount automatically
    _smsNumberController.addListener(_updateAmount);
  }

  void _setPackageBasedOnSmsNumber(int smsNumber) {
    for (var package in _packages) {
      if (smsNumber >= package.minSms && smsNumber <= package.maxSms) {
        setState(() {
          _selectedPackage = package;
          _packageName = package.name;
        });
        break;
      }
    }
  }

  // Method to update the amount based on SMS number
  void _updateAmount() {
    if (_smsNumberController.text.isNotEmpty &&
        int.tryParse(_smsNumberController.text) != null) {
      final smsCount = int.parse(_smsNumberController.text);

      // Update package based on SMS count
      _setPackageBasedOnSmsNumber(smsCount);

      setState(() {
        _tshController.text =
            (smsCount * _selectedPackage.pricePerSms).toString();
      });
    } else {
      _tshController.text = '0';
    }
  }

  Future<void> _saveSubscription() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final smsNumber = int.parse(_smsNumberController.text);
      final tsh = double.parse(_tshController.text);

      final endpoint = '$baseUrl/sms_bando/request_sms_bando.php';

      final Map<String, dynamic> requestBody = {
        'sms_number': smsNumber.toString(),
        'tsh': tsh.toString(),
        'payment_status': 'Inasubiri',
        'dates': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        'jumuiya_id': userData!.user.jumuiya_id.toString(),
        'user_id': userData!.user.id.toString(),
        'package_name': _packageName,
      };

      if (widget.subscription != null) {
        requestBody['id'] = widget.subscription!.id.toString();
      }

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Accept': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == "200") {
          if (mounted) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(widget.subscription != null
                    ? "✅ SMS imeboreshwa kikamilifu"
                    : "✅ SMS imeongezwa kikamilifu"),
              ),
            );
          }
        } else {
          _showSnackBar(data['message'] ?? "Failed to save subscription");
        }
      } else {
        _showSnackBar("Failed to connect to server");
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.yellow,
          content: Text(
            "⚠️ Tafadhali hakikisha umeunganishwa na intaneti",
            style: TextStyle(
              color: Colors.black,
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mainFontColor,
        foregroundColor: Colors.white,
        title: Text(widget.subscription != null
            ? 'Badilisha Malipo ya SMS'
            : 'Ongeza Malipo ya SMS'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoBanner(),
                      const SizedBox(height: 24),
                      _buildPackageSelector(),
                      const SizedBox(height: 24),
                      _buildFormSection(),
                      const SizedBox(height: 24),
                      Visibility(
                          visible: _tshController.text != "0",
                          child: ModernButton(
                            text: widget.subscription != null
                                ? 'Hifadhi Mabadiliko'
                                : 'Ongeza SMS',
                            icon: Icons.save,
                            backgroundColor: mainFontColor,
                            onPressed: _saveSubscription,
                            isLoading: _isLoading,
                            padding: const EdgeInsets.all(12),
                          ))
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: blue.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: blue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Malipo ya SMS za Jumuiya',
                style: TextStyle(
                  color: blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Unaweza kuongeza au kubadilisha malipo ya SMS za jumuiya hapa. Chagua kifurushi kinachofaa kutoka kwenye orodha.',
            style: TextStyle(
              color: textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageSelector() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chagua Kifurushi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: _packages.map((package) {
              final isSelected = package.name == _selectedPackage.name;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedPackage = package;
                    _packageName = package.name;

                    // Reset SMS number if needed to fit within package range
                    if (_smsNumberController.text.isNotEmpty) {
                      final smsCount =
                          int.tryParse(_smsNumberController.text) ?? 0;
                      if (smsCount < package.minSms) {
                        _smsNumberController.text = package.minSms.toString();
                      } else if (smsCount > package.maxSms) {
                        _smsNumberController.text = package.maxSms.toString();
                      }
                      _updateAmount();
                    }
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? mainFontColor : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    color: isSelected
                        ? mainFontColor.withOpacity(0.1)
                        : Colors.white,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isSelected ? mainFontColor : Colors.transparent,
                          border: Border.all(
                            color:
                                isSelected ? mainFontColor : Colors.grey[400]!,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              package.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isSelected ? mainFontColor : textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${package.minSms} - ${package.maxSms} SMS',
                              style: TextStyle(
                                fontSize: 14,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'TSH ${package.pricePerSms.toStringAsFixed(0)} / SMS',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color:
                                    isSelected ? mainFontColor : textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormField(
            label:
                'Idadi ya SMS (${_selectedPackage.minSms}-${_selectedPackage.maxSms})',
            hintText: 'Ingiza idadi ya SMS',
            controller: _smsNumberController,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Tafadhali ingiza idadi ya SMS';
              }
              if (int.tryParse(value) == null) {
                return 'Tafadhali ingiza namba halali';
              }
              final smsCount = int.parse(value);
              if (smsCount < _selectedPackage.minSms ||
                  smsCount > _selectedPackage.maxSms) {
                return 'Idadi ya SMS lazima iwe kati ya ${_selectedPackage.minSms} na ${_selectedPackage.maxSms}';
              }
              return null;
            },
            prefixIcon: Icons.sms,
          ),
          const SizedBox(height: 20),
          _buildFormField(
            label: 'Kiasi (TSH)',
            hintText: 'Kiasi kitajazwa kiotomatiki',
            controller: _tshController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Tafadhali ingiza kiasi';
              }
              if (double.tryParse(value) == null) {
                return 'Tafadhali ingiza kiasi halali';
              }
              return null;
            },
            prefixIcon: Icons.payments,
            readOnly: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required TextInputType keyboardType,
    required String? Function(String?) validator,
    required IconData prefixIcon,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(prefixIcon, color: mainFontColor),
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
              borderSide: BorderSide(color: mainFontColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: errorColor, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _smsNumberController.removeListener(_updateAmount);
    _smsNumberController.dispose();
    _tshController.dispose();
    _dateController.dispose();
    super.dispose();
  }
}
