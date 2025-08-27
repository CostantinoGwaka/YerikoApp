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
  String _selectedPaymentStatus = 'paid';
  bool _isLoading = false;

  final List<String> _paymentStatuses = ['paid', 'pending', 'cancelled'];
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();

    if (widget.subscription != null) {
      _smsNumberController.text = widget.subscription!.smsNumber.toString();
      _tshController.text = widget.subscription!.tsh.toString();
      _dateController.text = widget.subscription!.dates;
      _selectedPaymentStatus = widget.subscription!.paymentStatus;
    } else {
      _dateController.text = _dateFormat.format(DateTime.now());
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateController.text.isEmpty
          ? DateTime.now()
          : DateTime.parse(_dateController.text),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: mainFontColor,
              onPrimary: Colors.white,
              onSurface: textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateController.text = _dateFormat.format(picked);
      });
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

      final endpoint = widget.subscription != null
          ? '$baseUrl/sms_bando/update.php'
          : '$baseUrl/sms_bando/add.php';

      final Map<String, dynamic> requestBody = {
        'sms_number': smsNumber.toString(),
        'tsh': tsh.toString(),
        'payment_status': _selectedPaymentStatus,
        'dates': _dateController.text,
        'jumuiya_id': userData!.user.jumuiya_id.toString(),
        'user_id': userData!.user.id.toString(),
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
                      : "✅ SMS imeongezwa kikamilifu")),
            );
          }
        } else {
          _showSnackBar(data['message'] ?? "Failed to save subscription");
        }
      } else {
        _showSnackBar("Failed to connect to server");
      }
    } catch (e) {
      _showSnackBar("Error: $e");
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
                      _buildFormSection(),
                      const SizedBox(height: 24),
                      ModernButton(
                        text: widget.subscription != null
                            ? 'Hifadhi Mabadiliko'
                            : 'Ongeza SMS',
                        icon: Icons.save,
                        backgroundColor: mainFontColor,
                        onPressed: _saveSubscription,
                        isLoading: _isLoading,
                        padding: const EdgeInsets.all(12),
                      ),
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
            'Unaweza kuongeza au kubadilisha malipo ya SMS za jumuiya hapa. Kila malipo yanahusiana na idadi ya SMS na kiasi kilicholipwa.',
            style: TextStyle(
              color: textSecondary,
              fontSize: 14,
            ),
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
            label: 'Idadi ya SMS',
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
              return null;
            },
            prefixIcon: Icons.sms,
          ),
          const SizedBox(height: 20),
          _buildFormField(
            label: 'Kiasi (TSH)',
            hintText: 'Ingiza kiasi cha fedha',
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
          ),
          const SizedBox(height: 20),
          _buildDateField(),
          const SizedBox(height: 20),
          _buildStatusDropdown(),
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

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tarehe',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: AbsorbPointer(
            child: TextFormField(
              controller: _dateController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Tafadhali chagua tarehe';
                }
                return null;
              },
              decoration: InputDecoration(
                hintText: 'Chagua tarehe',
                prefixIcon: Icon(Icons.calendar_today, color: mainFontColor),
                suffixIcon: Icon(Icons.arrow_drop_down, color: mainFontColor),
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
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hali ya Malipo',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedPaymentStatus,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.payment, color: mainFontColor),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            items: _paymentStatuses.map((String status) {
              String displayText;
              Color statusColor;

              switch (status) {
                case 'paid':
                  displayText = 'Imelipwa';
                  statusColor = green;
                  break;
                case 'pending':
                  displayText = 'Inasubiri';
                  statusColor = orange;
                  break;
                case 'cancelled':
                  displayText = 'Imeghairiwa';
                  statusColor = errorColor;
                  break;
                default:
                  displayText = status;
                  statusColor = Colors.grey;
              }

              return DropdownMenuItem<String>(
                value: status,
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      displayText,
                      style: TextStyle(color: textPrimary),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedPaymentStatus = newValue;
                });
              }
            },
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _smsNumberController.dispose();
    _tshController.dispose();
    _dateController.dispose();
    super.dispose();
  }
}
