import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jumuiya_yangu/main.dart';
import 'package:jumuiya_yangu/models/auth_model.dart';
import 'package:jumuiya_yangu/utils/url.dart';
import 'package:jumuiya_yangu/shared/components/modern_widgets.dart';
import 'package:jumuiya_yangu/theme/colors.dart';
import 'package:http/http.dart' as http;

class AddUserPageAdmin extends StatefulWidget {
  final void Function(Map<String, dynamic>)? onSubmit;
  final User? initialData; // 👈 Add this
  final BuildContext rootContext;

  const AddUserPageAdmin({
    super.key,
    required this.rootContext,
    this.initialData,
    this.onSubmit,
  });

  @override
  State<AddUserPageAdmin> createState() => _AddUserPageAdminState();
}

class _AddUserPageAdminState extends State<AddUserPageAdmin> {
  final _formKey = GlobalKey<FormState>();
  List<User> users = [];
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController martialstatusController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController jumuiyaIdController = TextEditingController();
  String selectedRole = "USER"; // default
  String selectedGender = "MWANAUME"; // default
  String selectedMartialStatus = "AMEOLEWA"; // default
  bool _isLoading = false;
  final roles = ["USER", "ADMIN"];
  final listGenders = ["MWANAUME", "MWANAMKE"];
  final listStatus = ["AMEOLEWA", "AMEOA", "HAJAOA", "HAJAOLEWA", "WALIOACHANA", "MJANE", "MGANE"];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      final data = widget.initialData!;

      fullNameController.text = data.userFullName ?? '';
      userNameController.text = data.userName ?? '';
      phoneController.text =
          (data.phone != null && data.phone!.startsWith('255')) ? '0${data.phone!.substring(3)}' : (data.phone ?? '');
      locationController.text = data.location ?? '';
      genderController.text = data.gender ?? '';
      dobController.text = data.dobdate ?? '';
      martialstatusController.text = data.martialstatus ?? '';
      passwordController.text = ''; // Password is not prefilled for security
      jumuiyaIdController.text = data.jumuiya_id ?? '';
      selectedRole = data.role ?? "USER";
    }
  }

  Future<dynamic> saveUser(BuildContext context, dynamic data) async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (data['datePrayer'] == "" ||
          data['latId'] == "" ||
          data['longId'] == "" ||
          data['location'] == "" ||
          data['message'] == "" ||
          data['registeredBy'] == "") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hakikisha umejaza sehemu zote ipasavyo.")),
        );
      } else {
        String myApi = "$baseUrl/auth/jisajili.php";
        final response = await http.post(
          Uri.parse(myApi),
          headers: {
            'Accept': 'application/json',
          },
          body: data,
        );

        var jsonResponse = json.decode(response.body);

        if (response.statusCode == 200 && jsonResponse != null && jsonResponse['status'] == '200') {
          setState(() {
            _isLoading = false;
          });

          setState(() {
            // Clear all relevant controllers
            fullNameController.clear();
            userNameController.clear();
            phoneController.clear();
            passwordController.clear();
            jumuiyaIdController.clear();
            selectedRole = "USER";
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
              SnackBar(content: Text("✅ Umefanikiwa! Kuhuisha ratiba mfumo kwa mafanikio")),
            );
          } else {
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(widget.rootContext).showSnackBar(
              SnackBar(content: Text("✅ Umefanikiwa! Kusajili ratiba mfumo kwa mafanikio")),
            );
          }
        } else if (response.statusCode == 404) {
          // ignore: use_build_context_synchronously
          Navigator.pop(context);
          //end here
          setState(() {
            _isLoading = false;
          });
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(widget.rootContext).showSnackBar(
            SnackBar(content: Text(jsonResponse['message'])),
          );
        } else {
          // ignore: use_build_context_synchronously
          Navigator.pop(context);
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
        SnackBar(content: Text("⚠️ Tafadhali hakikisha umeunganishwa na intaneti: $e")),
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
                        color: primaryGradient[0].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.person_add_rounded,
                        color: primaryGradient[0],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.initialData != null ? "Hariri Mwanajumuiya" : "Ongeza Mwanajumuiya",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            "Jaza taarifa za mwanajumuiya mpya",
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
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormSection(
                        "Taarifa za Kibinafsi",
                        Icons.person_outline_rounded,
                        [
                          ModernTextField(
                            controller: fullNameController,
                            labelText: "Jina Kamili",
                            prefixIcon: Icons.person_rounded,
                            validator: (value) => value == null || value.isEmpty ? "Tafadhali jaza sehemu hii" : null,
                          ),
                          const SizedBox(height: 16),
                          ModernTextField(
                            controller: locationController,
                            labelText: "Mahali anapoishi",
                            prefixIcon: Icons.location_on_rounded,
                            validator: (value) => value == null || value.isEmpty ? "Tafadhali jaza sehemu hii" : null,
                          ),
                          const SizedBox(height: 16),
                          _buildModernDropdown(
                            "Jinsia",
                            selectedGender,
                            listGenders,
                            Icons.wc_rounded,
                            (value) => setState(() => selectedGender = value!),
                          ),
                          const SizedBox(height: 16),
                          _buildDatePickerField("Tarehe ya kuzaliwa", dobController),
                          const SizedBox(height: 16),
                          _buildModernDropdown(
                            "Hali ya Ndoa",
                            selectedMartialStatus,
                            listStatus,
                            Icons.favorite_rounded,
                            (value) => setState(() => selectedMartialStatus = value!),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      _buildFormSection(
                        "Taarifa za Mawasiliano",
                        Icons.contact_phone_rounded,
                        [
                          ModernTextField(
                            controller: phoneController,
                            labelText: "Namba ya Simu",
                            prefixIcon: Icons.phone_rounded,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Tafadhali jaza sehemu hii";
                              }
                              if (!RegExp(r'^(06|07)\d{8}$').hasMatch(value)) {
                                return "Namba ya simu lazima ianze na 06 au 07 na iwe tarakimu 10";
                              }
                              return null;
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      _buildFormSection(
                        "Taarifa za Mfumo",
                        Icons.admin_panel_settings_rounded,
                        [
                          _buildModernDropdown(
                            "Aina ya Mtumiaji",
                            selectedRole,
                            roles,
                            Icons.admin_panel_settings_rounded,
                            (value) => setState(() => selectedRole = value!),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ModernButton(
                          onPressed: _handleSubmit,
                          text: widget.initialData != null ? "Hifadhi Mabadiliko" : "Hifadhi Mtumiaji",
                          icon: widget.initialData != null ? Icons.update_rounded : Icons.save_rounded,
                          isLoading: _isLoading,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String capitalizeEachWord(String text) {
    return text
        .trim()
        .split(' ')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : '')
        .join(' ');
  }

  String toUnderscore(String text) {
    return text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
  }

  void _handleSubmit() {
    // Validate the form
    // Check if user is at least 18 years old
    if (dobController.text.trim().isNotEmpty) {
      try {
        final inputFormat = DateFormat("dd-MM-yyyy");
        final dob = inputFormat.parse(dobController.text.trim());
        final today = DateTime.now();
        final age = today.year -
            dob.year -
            ((today.month < dob.month || (today.month == dob.month && today.day < dob.day)) ? 1 : 0);
        if (age < 18) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Umri wa mtumiaji lazima uwe angalau miaka 18.")),
          );
          return;
        }
      } catch (e) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tarehe ya kuzaliwa si sahihi.")),
        );
        return;
      }
    }

    try {
      if (_formKey.currentState!.validate()) {
        final user = {
          "fname": capitalizeEachWord(fullNameController.text.trim()),
          "uname": toUnderscore(fullNameController.text.trim()),
          "phone": phoneController.text.trim().replaceFirst(RegExp(r'^0'), '255'),
          "password": phoneController.text.trim(),
          "location": locationController.text.trim(),
          "gender": selectedGender,
          "dobdate": dobController.text.trim(),
          "martialstatus": selectedMartialStatus,
          "role": selectedRole,
          "jumuiya_id": userData!.user.jumuiya_id,
        };

        if (widget.initialData != null) {
          user['id'] = widget.initialData!.id.toString();
        }

        saveUser(context, user);
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Kosa: $e")),
      );
    }
  }

  Widget _buildFormSection(String title, IconData icon, List<Widget> children) {
    return ModernCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: primaryGradient[0]),
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

  Widget _buildModernDropdown(
    String label,
    String value,
    List<String> items,
    IconData icon,
    void Function(String?) onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(
              item,
              style: const TextStyle(color: textPrimary),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primaryGradient[0]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: cardColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        dropdownColor: cardColor,
        style: const TextStyle(color: textPrimary),
      ),
    );
  }

  Widget _buildDatePickerField(String label, TextEditingController controller) {
    return GestureDetector(
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
          locale: const Locale('sw', 'TZ'),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: primaryGradient[0],
                  onPrimary: Colors.white,
                  surface: cardColor,
                  onSurface: textPrimary,
                ),
              ),
              child: child!,
            );
          },
        );

        if (pickedDate != null) {
          controller.text = DateFormat("dd-MM-yyyy").format(pickedDate);
        }
      },
      child: AbsorbPointer(
        child: ModernTextField(
          controller: controller,
          labelText: label,
          prefixIcon: Icons.calendar_today_rounded,
          suffixIcon: Icon(
            Icons.arrow_drop_down_rounded,
            color: primaryGradient[0],
          ),
          validator: (value) => value == null || value.isEmpty ? "Tafadhali chagua tarehe" : null,
        ),
      ),
    );
  }
}
