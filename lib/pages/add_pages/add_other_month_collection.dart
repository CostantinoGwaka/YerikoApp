import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:jumuiya_yangu/main.dart';
import 'package:jumuiya_yangu/models/auth_model.dart';
import 'package:jumuiya_yangu/models/other_collection_model.dart'
    show OtherCollection, CollectionType;
import 'package:jumuiya_yangu/shared/components/modern_widgets.dart';
import 'package:jumuiya_yangu/theme/colors.dart';
import 'package:jumuiya_yangu/utils/url.dart';
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
  State<AddOtherMonthCollectionUserAdmin> createState() =>
      _AddOtherMonthCollectionUserAdminState();
}

class _AddOtherMonthCollectionUserAdminState
    extends State<AddOtherMonthCollectionUserAdmin> {
  final _formKey = GlobalKey<FormState>();
  List<User> users = [];
  List<CollectionType> collectionTypeResponse = [];
  User? selectedUser;
  CollectionType? selectedType;

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

  Future<void> fetchCollectionTypes() async {
    final response = await http.get(Uri.parse(
        '$baseUrl/collectiontype/get_all_collection_type.php?jumuiya_id=${userData!.user.jumuiya_id}'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        collectionTypeResponse = (data['data'] as List)
            .map((u) => CollectionType.fromJson(u))
            .toList();
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

        if (response.statusCode == 200 &&
            jsonResponse != null &&
            jsonResponse['status'] == '200') {
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
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      minChildSize: 0.6,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle indicator
                Center(
                  child: Container(
                    height: 4,
                    width: 40,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Text(
                  widget.initialData != null
                      ? "Hariri Mchango wa Mwezi"
                      : "Ongeza Mchango wa Mwezi",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: primaryGradient[0],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Jaza taarifa za mchango wa mwezi",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: textSecondary,
                      ),
                ),
                const SizedBox(height: 24),

                // Month Selection
                ModernCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Mwezi wa Mchango",
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedMonth,
                        decoration: InputDecoration(
                          hintText: "Chagua mwezi...",
                          prefixIcon: Icon(Icons.calendar_month,
                              color: primaryGradient[0]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: primaryGradient[0], width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
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
                        ]
                            .map((month) => DropdownMenuItem(
                                  value: month,
                                  child: Text(month),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => selectedMonth = val);
                        },
                        validator: (value) =>
                            value == null ? "Chagua mwezi" : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Amount Input
                ModernCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Kiasi cha Mchango",
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                      ),
                      const SizedBox(height: 12),
                      ModernTextField(
                        controller: amountController,
                        hintText: "Weka kiasi cha mchango...",
                        prefixIcon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Weka kiasi cha mchango";
                          }
                          if (double.tryParse(value) == null ||
                              double.parse(value) <= 0) {
                            return "Weka kiasi sahihi";
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // User Selection
                ModernCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Mwanajumuiya",
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<User>(
                        initialValue: selectedUser,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: "Chagua mwanajumuiya...",
                          prefixIcon:
                              Icon(Icons.person, color: primaryGradient[0]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: primaryGradient[0], width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        items: users.map((user) {
                          return DropdownMenuItem<User>(
                            value: user,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor:
                                      primaryGradient[0].withValues(alpha: 0.1),
                                  child: Text(
                                    user.userFullName
                                            ?.substring(0, 1)
                                            .toUpperCase() ??
                                        "?",
                                    style: TextStyle(
                                      color: primaryGradient[0],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    user.userFullName!,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
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
                            value == null ? "Chagua mwanajumuiya" : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Collection Type Selection
                ModernCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Aina ya Mchango",
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<CollectionType>(
                        initialValue: selectedType,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: "Chagua aina ya mchango...",
                          prefixIcon:
                              Icon(Icons.category, color: primaryGradient[0]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: primaryGradient[0], width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        items: collectionTypeResponse.map((type) {
                          return DropdownMenuItem<CollectionType>(
                            value: type,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: secondary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.category_outlined,
                                    color: secondary,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    type.collectionName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
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
                        validator: (value) =>
                            value == null ? "Chagua aina ya mchango" : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ModernButton(
                        text: "Ghairi",
                        onPressed: () => Navigator.pop(context),
                        backgroundColor: grey,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ModernButton(
                        text: widget.initialData != null
                            ? "Sasisha Mchango"
                            : "Hifadhi Mchango",
                        onPressed: _isLoading
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  final data = {
                                    "id": widget.initialData?.id,
                                    "amount": amountController.text,
                                    "jumuiya_id": userData!.user.jumuiya_id,
                                    "user": {"id": selectedUser?.id ?? 0},
                                    "churchYearEntity": {
                                      "id": currentYear!.data.id
                                    },
                                    "collection_type": {"id": selectedType!.id},
                                    "monthly": selectedMonth,
                                    "registered_by":
                                        userData!.user.userFullName,
                                  };
                                  saveOtherMonthlyContribution(data);
                                }
                              },
                        isLoading: _isLoading,
                        icon: widget.initialData != null
                            ? Icons.update
                            : Icons.save,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Remove this duplicate method definition to avoid conflicts.
}
