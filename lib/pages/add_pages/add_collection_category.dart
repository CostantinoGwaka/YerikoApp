import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:yeriko_app/main.dart';
import 'package:http/http.dart' as http;
import 'package:yeriko_app/utils/url.dart';

class AddCollectionTypePage extends StatefulWidget {
  final Function(dynamic)? onSubmit;
  final BuildContext rootContext;

  const AddCollectionTypePage({
    super.key,
    required this.rootContext,
    this.onSubmit,
  });

  @override
  State<AddCollectionTypePage> createState() => _AddCollectionTypePageState();
}

class _AddCollectionTypePageState extends State<AddCollectionTypePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController collectionNameController = TextEditingController();
  bool _isLoading = false;

  Future<void> saveCollectionType() async {
    if (!_formKey.currentState!.validate()) return;

    final payload = {
      "collection_name": collectionNameController.text.trim().toUpperCase(),
      "jumuiya_id": userData!.user.jumuiya_id,
      "registeredBy": userData!.user.userFullName,
    };

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/collection_type/add.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      final jsonResponse = json.decode(response.body);
      setState(() => _isLoading = false);

      if (response.statusCode == 200 && jsonResponse['status'] == "200") {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(widget.rootContext).showSnackBar(
          const SnackBar(content: Text("✅ Aina ya mchango imehifadhiwa kwa mafanikio")),
        );
        // ignore: use_build_context_synchronously
        Navigator.pop(context);
        if (widget.onSubmit != null) widget.onSubmit!(payload);
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(widget.rootContext).showSnackBar(
          SnackBar(content: Text("❌ Hitilafu: ${jsonResponse['message']}")),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(widget.rootContext).showSnackBar(
        SnackBar(content: Text("📡 Tatizo la intaneti au seva: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.85,
      minChildSize: 0.4,
      builder: (_, controller) => SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                const Text(
                  "➕ Ongeza Aina ya Mchango",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: collectionNameController,
                  decoration: const InputDecoration(
                    labelText: "✏️ Aina ya Mchango (Mf. Sadaka ya Maendeleo)",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty ? "Tafadhali jaza jina la mchango" : null,
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: saveCollectionType,
                  icon: const Icon(Icons.save),
                  label: const Text("Hifadhi"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
