import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yeriko_app/main.dart';
import 'package:yeriko_app/models/auth_model.dart';
import 'package:yeriko_app/utils/url.dart';
import 'package:http/http.dart' as http;

class AddPrayerSchedulePage extends StatefulWidget {
  final void Function(Map<String, dynamic>)? onSubmit;
  final BuildContext rootContext;

  const AddPrayerSchedulePage({
    super.key,
    required this.rootContext,
    this.onSubmit,
  });

  @override
  State<AddPrayerSchedulePage> createState() => _AddPrayerSchedulePageState();
}

class _AddPrayerSchedulePageState extends State<AddPrayerSchedulePage> {
  final _formKey = GlobalKey<FormState>();
  List<UserModel> users = [];
  UserModel? selectedUser;
  bool _isLoading = false;

  Future<void> fetchUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/auth/get_all_users.php'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        users = (data['data'] as List).map((u) => UserModel.fromJson(u)).toList();
      });
    } else {
      // handle error
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<dynamic> saveTimeTable(dynamic data) async {
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
        String myApi = "$baseUrl/church_timetable/add.php";
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
            datePrayerController.clear();
            latIdController.clear();
            longIdController.clear();
            locationController.clear();
            messageController.clear();
            userNameController.clear();
            userFullNameController.clear();
            userPhoneController.clear();
            userRoleController.clear();
            yearRegisteredController.clear();
          });

          // ignore: use_build_context_synchronously
          Navigator.pop(context);
          if (widget.onSubmit != null) {
            widget.onSubmit!(data);
          }
          //end here
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(widget.rootContext).showSnackBar(
            SnackBar(content: Text("Umefanikiwa! Kusajili ratiba mfumo kwa mafanikio")),
          );
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
            SnackBar(content: Text("Imegoma kusajili kwenye mfumo wetu")),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(widget.rootContext).showSnackBar(
        SnackBar(content: Text("Tafadhali hakikisha umeunganishwa na intaneti: $e")),
      );
    }
  }

  final TextEditingController datePrayerController = TextEditingController();
  final TextEditingController latIdController = TextEditingController(text: "N/A");
  final TextEditingController longIdController = TextEditingController(text: "N/A");
  final TextEditingController locationController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController userFullNameController = TextEditingController();
  final TextEditingController userPhoneController = TextEditingController();
  final TextEditingController userRoleController = TextEditingController();
  final TextEditingController yearRegisteredController = TextEditingController();

  bool isActive = true;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
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
                const Text("➕ Ongeza Ratiba ya Maombi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildDatePickerField("📅 Tarehe ya Maombi", datePrayerController),
                _buildTextField("📍 Mahali", locationController),
                // _buildTextField("🛰 LatId", latIdController),
                // _buildTextField("🛰 LongId", longIdController),
                _buildTextField("💬 Ujumbe", messageController),
                // _buildTextField("🖊 Aliyesajili", registeredByController),
                const SizedBox(height: 12),
                const Divider(),
                const Text("👤 Taarifa za Mtumiaji", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<UserModel>(
                  value: selectedUser,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: "Chagua Mtumiaji",
                    border: OutlineInputBorder(),
                  ),
                  items: users.map((user) {
                    return DropdownMenuItem<UserModel>(
                      value: user,
                      child: Text(user.userFullName!),
                    );
                  }).toList(),
                  onChanged: (user) {
                    if (user != null) {
                      setState(() {
                        selectedUser = user;
                        userFullNameController.text = user.userFullName!;
                        userNameController.text = user.userName!;
                        userPhoneController.text = user.phone!;
                        userRoleController.text = user.role!;
                        yearRegisteredController.text = user.yearRegistered!;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                const Divider(),
                const Text("📆 Mwaka wa Kanisa", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildChurchYearInfo(
                  churchYear: currentYear!.data.churchYear,
                  isActive: currentYear!.data.isActive,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final data = {
                        "datePrayer": datePrayerController.text,
                        "latId": "N/A", //latIdController.text,
                        "longId": "N/A",
                        "location": locationController.text.toUpperCase(),
                        "message": messageController.text,
                        "registeredBy": userData!.user.userFullName,
                        "user": {
                          "id": selectedUser?.id ?? 0,
                          "userFullName": userFullNameController.text,
                          "userName": userNameController.text,
                          "phone": userPhoneController.text,
                          "role": userRoleController.text,
                          "yearRegistered": yearRegisteredController.text,
                        },
                        "churchYearEntity": {
                          "id": currentYear!.data.id,
                          "churchYear": currentYear!.data.churchYear,
                          "isActive": currentYear!.data.isActive ? "0" : "1",
                        }
                      };

                      saveTimeTable(data);
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text("Hifadhi Ratiba"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChurchYearInfo({required String churchYear, required bool isActive}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("📆 Mwaka wa Kanisa", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_month, color: Colors.blueGrey),
              const SizedBox(width: 8),
              Text(
                churchYear,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isActive ? Icons.check_circle : Icons.cancel,
                color: isActive ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                isActive ? "Mwaka huu ni Hai" : "Mwaka huu si Hai",
                style: TextStyle(
                  fontSize: 15,
                  color: isActive ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) => value == null || value.isEmpty ? "Tafadhali jaza sehemu hii" : null,
      ),
    );
  }

  Widget _buildDatePickerField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        validator: (value) => value == null || value.isEmpty ? "Tafadhali chagua tarehe" : null,
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
            context: widget.rootContext,
            initialDate: DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
            locale: const Locale('sw', 'TZ'),
          );

          if (pickedDate != null) {
            controller.text = DateFormat("dd-MM-yyyy").format(pickedDate);
          }
        },
      ),
    );
  }
}
