import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:yeriko_app/main.dart';
import 'package:yeriko_app/models/auth_model.dart';
import 'package:yeriko_app/models/other_collection_model.dart' show OtherCollection, CollectionType;
import 'package:yeriko_app/utils/url.dart';
import 'package:http/http.dart' as http;

class AddOtherMonthCollectionUserAdmin extends StatefulWidget {
  final void Function(Map<String, dynamic>)? onSubmit;
  final OtherCollection? initialData; // 👈 Add this
  final BuildContext rootContext;

  const AddOtherMonthCollectionUserAdmin({
    super.key,
    required this.rootContext,
    this.initialData,
    this.onSubmit,
  });

  @override
  State<AddOtherMonthCollectionUserAdmin> createState() => _AddOtherMonthCollectionUserAdminState();
}

class _AddOtherMonthCollectionUserAdminState extends State<AddOtherMonthCollectionUserAdmin> {
  final _formKey = GlobalKey<FormState>();
  List<User> users = [];
  List<CollectionType> collectionTypeResponse = [];
  User? selectedUser;
  CollectionType? selectedType;

  final TextEditingController amountController = TextEditingController();
  String selectedMonth = "JANUARY";
  bool _isLoading = false;

  Future<void> fetchUsers() async {
    final response =
        await http.get(Uri.parse('$baseUrl/auth/get_all_users.php?jumuiya_id=${userData!.user.jumuiya_id}'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        users = (data['data'] as List).map((u) => User.fromJson(u)).toList();
      });
    } else {
      // handle error
    }
  }

  Future<void> fetchCollectionTypes() async {
    final response = await http
        .get(Uri.parse('$baseUrl/collectiontype/get_all_collection_type.php?jumuiya_id=${userData!.user.jumuiya_id}'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        collectionTypeResponse = (data['data'] as List).map((u) => CollectionType.fromJson(u)).toList();
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
    fetchCollectionTypes();

    if (widget.initialData != null) {
      final data = widget.initialData!;

      amountController.text = data.amount.toString();
      selectedMonth = data.monthly; // Default to January if null
      setState(() {
        selectedUser = data.user;
        selectedType = data.collectionType;
      });
    }
  }

  Future<dynamic> saveOtherMonthlyContribution(dynamic data) async {
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
          data['collection_type']['id'] == null ||
          data['monthly'] == null ||
          data['monthly'].toString().isEmpty ||
          data['registered_by'] == null ||
          data['registered_by'].toString().isEmpty) {
        Navigator.pop(context);
        setState(() {
          _isLoading = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hakikisha umejaza sehemu zote ipasavyo.")),
        );
      } else {
        String myApi = "$baseUrl/monthly/add_other_collection.php";
        final response = await http.post(
          Uri.parse(myApi),
          headers: {
            'Accept': 'application/json',
          },
          body: jsonEncode(data),
        );

        var jsonResponse = json.decode(response.body);

        if (response.statusCode == 200 && jsonResponse != null && jsonResponse['status'] == '200') {
          setState(() {
            _isLoading = false;
          });

          setState(() {
            // Clear all relevant controllers
            amountController.clear();
            selectedMonth = "JANUARY"; // Reset to default month
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
              SnackBar(content: Text("✅ Umefanikiwa! Kuhuisha mchango kwenye mfumo kwa mafanikio")),
            );
          } else {
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(widget.rootContext).showSnackBar(
              SnackBar(content: Text("✅ Umefanikiwa! Kusajili mchango mfumo kwa mafanikio")),
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
      // ignore: use_build_context_synchronously
      Navigator.pop(context);

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
        child: Form(
          key: _formKey,
          child: Column(
            children: [
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
              const Text("➕ Ongeza Mchango wa Mwezi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedMonth,
                decoration: const InputDecoration(labelText: "Chagua Mwezi", border: OutlineInputBorder()),
                isExpanded: true,
                items: [
                  "JANUARY",
                  "FEBRUARY",
                  "MARCH",
                  "APRIL",
                  "MAY",
                  "JUNE",
                  "JULY",
                  "AUGUST",
                  "SEPTEMBER",
                  "OCTOBER",
                  "NOVEMBER",
                  "DECEMBER"
                ].map((month) => DropdownMenuItem(value: month, child: Text(month))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => selectedMonth = val);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "💰 Kiasi cha Mchango", border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? "Weka kiasi" : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<User>(
                value: selectedUser,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: "Chagua Mwanajumuiya",
                  border: OutlineInputBorder(),
                ),
                items: users.map((user) {
                  return DropdownMenuItem<User>(
                    value: user,
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Colors.blueGrey, size: 20),
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
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<CollectionType>(
                value: selectedType,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: "Chagua Aina ya Mchango",
                  border: OutlineInputBorder(),
                ),
                items: collectionTypeResponse.map((type) {
                  return DropdownMenuItem<CollectionType>(
                    value: type,
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Colors.blueGrey, size: 20),
                        const SizedBox(width: 8),
                        Text(type.collectionName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (type) {
                  if (type != null) {
                    setState(() {
                      selectedType = type;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text("Hifadhi Mchango"),
                      onPressed: () {
                        final data = {
                          // ignore: prefer_null_aware_operators
                          "id": widget.initialData != null
                              ? widget.initialData!.id
                              : null, // Ensure this is set correctly
                          "amount": amountController.text,
                          "jumuiya_id": userData!.user.jumuiya_id, // Ensure this is set correctly
                          "user": {"id": selectedUser?.id ?? 0},
                          "churchYearEntity": {
                            "id": currentYear!.data.id,
                          },
                          "collection_type": {
                            "id": selectedType!.id,
                          },
                          "monthly": selectedMonth,
                          "registered_by": userData!.user.userFullName,
                        };
                        saveOtherMonthlyContribution(data);
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // Remove this duplicate method definition to avoid conflicts.
}
