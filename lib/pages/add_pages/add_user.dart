import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:yeriko_app/main.dart';
import 'package:yeriko_app/models/auth_model.dart';
import 'package:yeriko_app/models/church_time_table.dart';
import 'package:yeriko_app/utils/url.dart';
import 'package:http/http.dart' as http;

class AddUserPageAdmin extends StatefulWidget {
  final void Function(Map<String, dynamic>)? onSubmit;
  final ChurchTimeTable? initialData; // 👈 Add this
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
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController jumuiyaIdController = TextEditingController();
  String selectedRole = "USER"; // default
  bool _isLoading = false;
  final roles = ["USER", "ADMIN"];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      final data = widget.initialData!;

      fullNameController.text = data.user?.userFullName ?? '';
      userNameController.text = data.user?.userName ?? '';
      phoneController.text = data.user?.phone ?? '';
      passwordController.text = ''; // Password is not prefilled for security
      jumuiyaIdController.text = data.user?.jumuiya_id ?? '';
      selectedRole = data.user?.role ?? "USER";

      isActive = (data.churchYearEntity?.isActive?.toString() == '1' || data.churchYearEntity?.isActive == true);
    }
  }

  Future<dynamic> saveTimeTable(BuildContext context, dynamic data) async {
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
      builder: (_, controller) => SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                ),
              ),
            if (!_isLoading) ...[
              Center(
                child: Container(
                  height: 5,
                  width: 50,
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const Text("➕ Ongeza Mwanajumuiya", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("🆕 Sajili Mtumiaji", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildTextField("👤 Jina Kamili", fullNameController),
                    // const SizedBox(height: 8),
                    // _buildTextField("🧑‍💻 Jina la Mtumiaji", userNameController),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      decoration: const InputDecoration(
                        labelText: "📞 Namba ya Simu",
                        border: OutlineInputBorder(),
                        counterText: "", // Hide counter
                      ),
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
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      items: roles.map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(role),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedRole = value);
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: "🧾 Aina ya Mtumiaji",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final user = {
                            "fname": capitalizeEachWord(fullNameController.text.trim()),
                            "uname": toUnderscore(fullNameController.text.trim()),
                            "phone": phoneController.text.trim().replaceFirst(RegExp(r'^0'), '255'),
                            "password": phoneController.text.trim(),
                            "role": selectedRole,
                            "jumuiya_id": userData!.user.jumuiya_id,
                          };

                          saveTimeTable(context, user);
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text("Hifadhi Mtumiaji"),
                    ),
                  ],
                ),
              )
            ],
          ],
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

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType inputType = TextInputType.text, bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) => value == null || value.isEmpty ? "Tafadhali jaza sehemu hii" : null,
      ),
    );
  }
}
