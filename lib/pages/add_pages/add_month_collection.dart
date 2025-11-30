import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:jumuiya_yangu/main.dart';
import 'package:jumuiya_yangu/models/auth_model.dart';
import 'package:jumuiya_yangu/models/user_collection_model.dart';
import 'package:jumuiya_yangu/utils/url.dart';
import 'package:jumuiya_yangu/shared/components/modern_widgets.dart';
import 'package:jumuiya_yangu/theme/colors.dart';
import 'package:http/http.dart' as http;

class AddMonthCollectionUserAdmin extends StatefulWidget {
  final void Function(Map<String, dynamic>)? onSubmit;
  final CollectionItem? initialData; // 👈 Add this
  final BuildContext rootContext;

  const AddMonthCollectionUserAdmin({
    super.key,
    required this.rootContext,
    this.initialData,
    this.onSubmit,
  });

  @override
  State<AddMonthCollectionUserAdmin> createState() =>
      _AddMonthCollectionUserAdminState();
}

class _AddMonthCollectionUserAdminState
    extends State<AddMonthCollectionUserAdmin> {
  final _formKey = GlobalKey<FormState>();
  List<User> users = [];
  User? selectedUser;

  final TextEditingController amountController = TextEditingController();
  String? selectedMonth;
  bool _isLoading = false;

  Future<void> fetchUsers() async {
    final response = await http.get(Uri.parse(
        '$baseUrl/auth/get_all_users.php?jumuiya_id=${userData!.user.jumuiya_id}'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        users = (data['data'] as List).map((u) => User.fromJson(u)).toList()
          ..sort(
              (a, b) => (a.userFullName ?? '').compareTo(b.userFullName ?? ''));
      });
    } else {
      // handle error
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    fetchUsers();

    if (widget.initialData != null) {
      final data = widget.initialData!;

      amountController.text = data.amount.toString();
      selectedMonth = data.monthly; // Default to January if null

      setState(() {
        selectedUser = data.user;
      });
    }
  }

  Future<dynamic> saveMonthlyContribution(dynamic data) async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (data['amount'] == null ||
          data['amount'].toString().isEmpty ||
          data['jumuiya_id'] == null ||
          data['user'] == null ||
          data['user']['id'] == null ||
          data['churchYearEntity'] == null ||
          data['churchYearEntity']['id'] == null ||
          data['monthly'] == null ||
          data['monthly'].toString().isEmpty ||
          data['registeredBy'] == null ||
          data['registeredBy'].toString().isEmpty) {
        // ignore: use_build_context_synchronously
        Navigator.pop(context);
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hakikisha umejaza sehemu zote ipasavyo.")),
        );
      } else {
        String myApi = "$baseUrl/monthly/add.php";
        final response = await http.post(
          Uri.parse(myApi),
          headers: {
            'Accept': 'application/json',
          },
          body: jsonEncode(data),
        );

        var jsonResponse = json.decode(response.body);

        if (response.statusCode == 200 && jsonResponse != null) {
          setState(() {
            _isLoading = false;
          });

          setState(() {
            // Clear all relevant controllers
            amountController.clear();
            selectedMonth = null; // Reset to default month
            selectedUser = null; // Reset selected user
          });

          // ignore: use_build_context_synchronously
          Navigator.pop(context);
          if (widget.onSubmit != null) {
            widget.onSubmit!(data);
          }
          //end here
          if (widget.initialData != null) {
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(widget.rootContext).showSnackBar(
              SnackBar(
                  content: Text(
                      "✅ Umefanikiwa! Kuhuisha mchango kwenye mfumo kwa mafanikio")),
            );
          } else {
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(widget.rootContext).showSnackBar(
              SnackBar(
                  content: Text(
                      "✅ Umefanikiwa! Kusajili mchango mfumo kwa mafanikio")),
            );
          }
        } else if (response.statusCode == 404) {
          //end here
          setState(() {
            _isLoading = false;
          });
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(widget.rootContext).showSnackBar(
            SnackBar(content: Text(jsonResponse['message'])),
          );
        } else {
          setState(() {
            _isLoading = false;
          });
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(widget.rootContext).showSnackBar(
            SnackBar(content: Text("❎ Imegoma kusajili kwenye mfumo wetu")),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(widget.rootContext).showSnackBar(
        SnackBar(
            content: Text("⚠️ Tafadhali hakikisha umeunganishwa na intaneti")),
      );
    }
  }

  bool isActive = true;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: LoadingOverlay(
          isLoading: _isLoading,
          child: SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      height: 4,
                      width: 40,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: successGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.savings_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.initialData != null
                                  ? "Hariri Mchango"
                                  : "Ongeza Mchango wa Mwezi",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              "Sajili mchango wa mwanajumuiya",
                              style: TextStyle(
                                fontSize: 14,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Form
                  _buildFormSection(
                    "Taarifa za Mchango",
                    Icons.account_balance_wallet_rounded,
                    [
                      _buildMonthDropdown(),
                      const SizedBox(height: 16),
                      ModernTextField(
                        controller: amountController,
                        labelText: "Kiasi cha Mchango (TSh)",
                        prefixIcon: Icons.monetization_on_rounded,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Tafadhali weka kiasi cha mchango";
                          }
                          if (double.tryParse(value) == null ||
                              double.parse(value) <= 0) {
                            return "Kiasi cha mchango lazima kiwe namba kubwa kuliko sifuri";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildUserDropdown(),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ModernButton(
                      onPressed: _handleSubmit,
                      text: widget.initialData != null
                          ? "Hifadhi Mabadiliko"
                          : "Hifadhi Mchango",
                      icon: widget.initialData != null
                          ? Icons.update_rounded
                          : Icons.save_rounded,
                      backgroundColor: successColor,
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection(String title, IconData icon, List<Widget> children) {
    return ModernCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: successColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMonthDropdown() {
    final months = [
      {"value": "JANUARY", "label": "Januari"},
      {"value": "FEBRUARY", "label": "Februari"},
      {"value": "MARCH", "label": "Machi"},
      {"value": "APRIL", "label": "Aprili"},
      {"value": "MAY", "label": "Mei"},
      {"value": "JUNE", "label": "Juni"},
      {"value": "JULY", "label": "Julai"},
      {"value": "AUGUST", "label": "Agosti"},
      {"value": "SEPTEMBER", "label": "Septemba"},
      {"value": "OCTOBER", "label": "Oktoba"},
      {"value": "NOVEMBER", "label": "Novemba"},
      {"value": "DECEMBER", "label": "Desemba"},
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: selectedMonth,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: "Chagua Mwezi",
          prefixIcon: Icon(Icons.calendar_month_rounded, color: successColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: cardColor,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: months.map((month) {
          return DropdownMenuItem<String>(
            value: month["value"],
            child: Text(
              month["label"]!,
              style: const TextStyle(color: textPrimary),
            ),
          );
        }).toList(),
        onChanged: (val) {
          if (val != null) setState(() => selectedMonth = val);
        },
        validator: (value) => value == null ? "Tafadhali chagua mwezi" : null,
        dropdownColor: cardColor,
        style: const TextStyle(color: textPrimary),
      ),
    );
  }

  Widget _buildUserDropdown() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonFormField<User>(
        initialValue: selectedUser,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: "Chagua Mwanajumuiya",
          prefixIcon: Icon(Icons.person_rounded, color: successColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: cardColor,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: users.map((user) {
          return DropdownMenuItem<User>(
            value: user,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: successColor.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.person,
                    color: successColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    user.userFullName ?? "Jina halijulikani",
                    style: const TextStyle(color: textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (user) {
          if (user != null) {
            setState(() {
              selectedUser = user;
            });
          }
        },
        validator: (value) =>
            value == null ? "Tafadhali chagua mwanajumuiya" : null,
        dropdownColor: cardColor,
        style: const TextStyle(color: textPrimary),
      ),
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      final data = {
        "id": widget.initialData?.id,
        "amount": amountController.text,
        "jumuiya_id": userData!.user.jumuiya_id,
        "user": {"id": selectedUser?.id ?? 0},
        "churchYearEntity": {
          "id": currentYear!.data.id,
        },
        "monthly": selectedMonth,
        "registeredBy": userData!.user.userFullName,
      };
      saveMonthlyContribution(data);
    }
  }

  // Remove this duplicate method definition to avoid conflicts.
}
