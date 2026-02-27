import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jumuiya_yangu/main.dart';
import 'package:jumuiya_yangu/models/auth_model.dart';
import 'package:jumuiya_yangu/models/church_time_table.dart';
import 'package:jumuiya_yangu/utils/url.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AddPrayerSchedulePage extends StatefulWidget {
  final void Function(Map<String, dynamic>)? onSubmit;
  final ChurchTimeTable? initialData; // 👈 Add this
  final BuildContext rootContext;

  const AddPrayerSchedulePage({
    super.key,
    required this.rootContext,
    this.initialData,
    this.onSubmit,
  });

  @override
  State<AddPrayerSchedulePage> createState() => _AddPrayerSchedulePageState();
}

class _AddPrayerSchedulePageState extends State<AddPrayerSchedulePage> {
  final _formKey = GlobalKey<FormState>();
  List<User> users = [];
  User? selectedUser;
  late TextEditingController datePrayerController = TextEditingController();
  late TextEditingController latIdController =
      TextEditingController(text: "N/A");
  late TextEditingController longIdController =
      TextEditingController(text: "N/A");
  late TextEditingController locationController = TextEditingController();
  late TextEditingController messageController = TextEditingController();
  late TextEditingController userNameController = TextEditingController();
  late TextEditingController userFullNameController = TextEditingController();
  late TextEditingController userPhoneController = TextEditingController();
  late TextEditingController userRoleController = TextEditingController();
  late TextEditingController yearRegisteredController = TextEditingController();
  bool _isLoading = false;
  late Box _usersBox;
  final Connectivity _connectivity = Connectivity();

  Future<void> _initHive() async {
    _usersBox = await Hive.openBox('users_cache');
  }

  Future<void> fetchUsers() async {
    // Check connectivity first
    final connectivityResult = await _connectivity.checkConnectivity();
    final isConnected = !connectivityResult.contains(ConnectivityResult.none);

    if (!isConnected) {
      // Load from cache when offline
      _loadUsersFromCache();
      return;
    }

    try {
      final response = await http
          .get(Uri.parse(
              '$baseUrl/auth/get_all_users.php?jumuiya_id=${userData!.user.jumuiya_id}'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final usersList =
            (data['data'] as List).map((u) => User.fromJson(u)).toList();

        setState(() {
          users = usersList;
        });

        // Save to cache
        await _saveUsersToCache(data);
      } else {
        // Load from cache if API fails
        _loadUsersFromCache();
      }
    } catch (e) {
      // Load from cache on error
      _loadUsersFromCache();
    }
  }

  Future<void> _saveUsersToCache(Map<String, dynamic> data) async {
    try {
      await _usersBox.put('users_${userData!.user.jumuiya_id}', data);
    } catch (e) {
      // Silent fail
    }
  }

  void _loadUsersFromCache() {
    try {
      final data = _usersBox.get('users_${userData!.user.jumuiya_id}');
      if (data != null) {
        final cachedData = Map<String, dynamic>.from(data);
        setState(() {
          users = (cachedData['data'] as List)
              .map((u) => User.fromJson(u))
              .toList();
        });
      }
    } catch (e) {
      // Silent fail
    }
  }

  @override
  void initState() {
    super.initState();
    _initHive().then((_) => fetchUsers());

    if (widget.initialData != null) {
      final data = widget.initialData!;

      datePrayerController = TextEditingController(text: data.datePrayer ?? '');
      latIdController = TextEditingController(text: data.latId ?? 'N/A');
      longIdController = TextEditingController(text: data.longId ?? 'N/A');
      locationController = TextEditingController(text: data.location ?? '');
      messageController = TextEditingController(text: data.message ?? '');

      userFullNameController =
          TextEditingController(text: data.user?.userFullName ?? '');
      userNameController =
          TextEditingController(text: data.user?.userName ?? '');
      userPhoneController = TextEditingController(text: data.user?.phone ?? '');
      userRoleController = TextEditingController(text: data.user?.role ?? '');
      yearRegisteredController =
          TextEditingController(text: data.user?.yearRegistered ?? '');

      setState(() {
        selectedUser = data.user;
      });

      isActive = (data.churchYearEntity?.isActive?.toString() == '1' ||
          data.churchYearEntity?.isActive == true);
    }
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
          if (widget.initialData != null) {
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(widget.rootContext).showSnackBar(
              SnackBar(
                  content: Text(
                      "✅ Umefanikiwa! Kuhuisha ratiba mfumo kwa mafanikio")),
            );
          } else {
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(widget.rootContext).showSnackBar(
              SnackBar(
                  content: Text(
                      "✅ Umefanikiwa! Kusajili ratiba mfumo kwa mafanikio")),
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
    }
  }

  bool isActive = true;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
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
                const Text("➕ Ongeza Ratiba ya Kukutana",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildDatePickerField(
                    "📅 Tarehe ya Kukutana", datePrayerController),
                _buildTextField("📍 Mahali", locationController),
                // _buildTextField("🛰 LatId", latIdController),
                // _buildTextField("🛰 LongId", longIdController),
                _buildTextField("💬 Ujumbe", messageController),
                // _buildTextField("🖊 Aliyesajili", registeredByController),
                const SizedBox(height: 12),
                const Divider(),
                const Text("👤 Taarifa za Mtumiaji",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButtonFormField<User>(
                    initialValue: selectedUser,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: "Chagua Mwenyeji",
                      border: OutlineInputBorder(),
                    ),
                    items: users.map((user) {
                      return DropdownMenuItem<User>(
                        value: user,
                        child: Row(
                          children: [
                            const Icon(Icons.person,
                                color: Colors.blueGrey, size: 20),
                            const SizedBox(width: 8),
                            Text(user.userFullName!),
                          ],
                        ),
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
                ),
                const SizedBox(height: 12),
                const Divider(),
                const Text("📆 Mwaka",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (currentYear != null)
                  _buildChurchYearInfo(
                    churchYear: currentYear!.data.churchYear,
                    isActive: currentYear!.data.isActive,
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      "⚠️ Taarifa za mwaka hazipatikani",
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      // Check connectivity before saving
                      final connectivityResult =
                          await _connectivity.checkConnectivity();
                      final isConnected =
                          !connectivityResult.contains(ConnectivityResult.none);

                      if (!isConnected) {
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.orange,
                            content: Text(
                              "⚠️ Huwezi kuongeza/kuhariri wakati uko offline",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                        return;
                      }

                      if (currentYear == null) {
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.orange,
                            content: Text(
                              "⚠️ Taarifa za mwaka hazipatikani. Jaribu tena baadaye.",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                        return;
                      }

                      final data = {
                        "id": widget.initialData?.id,
                        "datePrayer": datePrayerController.text,
                        "jumuiya_id": userData!
                            .user.jumuiya_id, // Ensure this is set correctly
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

  Widget _buildChurchYearInfo(
      {required String churchYear, required bool isActive}) {
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
            color: Colors.grey.withAlpha((0.1 * 255).toInt()),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("📆 Mwaka", style: TextStyle(fontWeight: FontWeight.bold)),
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
        validator: (value) =>
            value == null || value.isEmpty ? "Tafadhali jaza sehemu hii" : null,
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
        validator: (value) =>
            value == null || value.isEmpty ? "Tafadhali chagua tarehe" : null,
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
