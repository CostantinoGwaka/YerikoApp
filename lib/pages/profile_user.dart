import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yeriko_app/main.dart';
import 'package:yeriko_app/models/other_collection_model.dart';
import 'package:yeriko_app/pages/login_page.dart';
import 'package:yeriko_app/shared/localstorage/index.dart';
import 'package:yeriko_app/utils/url.dart';
import 'package:http/http.dart' as http;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool oldPasswordVisible = false;
  bool newPasswordVisible = false;
  bool confirmPasswordVisible = false;
  bool _isLoading = false;
  List<CollectionType> collectionTypeResponse = [];

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

  Future<dynamic> logout(BuildContext context) async {
    // Clear storage first
    await LocalStorage.clearSharedPrefs();

    // Use Future.microtask to delay navigation until next frame
    Future.microtask(() {
      Navigator.pushAndRemoveUntil(
        // ignore: use_build_context_synchronously
        context,
        PageTransition(
          type: PageTransitionType.fade,
          child: const LoginPage(),
        ),
        (route) => false, // Remove all previous routes
      );
    });

    // Show snackBar AFTER navigation is complete using post-frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Success! You have logged out.")),
      );
    });
  }

  Future<dynamic> updatePassword(BuildContext rootContext, String oldpassword, String newpassword) async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (oldpassword == "" || newpassword == "") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ Tafadhali hakikisha umeweka namba ya simu na nenosiri")),
        );
      } else {
        String myApi = "$baseUrl/auth/update_password.php";
        final response = await http.post(
          Uri.parse(myApi),
          headers: {'Accept': 'application/json'},
          body: {
            "user_id": userData!.user.id.toString(),
            "old_password": oldpassword,
            "password": newpassword,
          },
        );

        var jsonResponse = json.decode(response.body);

        if (response.statusCode == 200 && jsonResponse != null && jsonResponse['status'] == "200") {
          setState(() {
            _isLoading = false;
          });

          setState(() {});

          //end here
          // ignore: use_build_context_synchronously
          Navigator.pop(rootContext);

          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(rootContext).showSnackBar(
            SnackBar(content: Text("✅ Umefanikiwa! Kubadili nenosiri lako kwenye mfumo kwa mafanikio")),
          );
        } else {
          setState(() {
            _isLoading = false;
          });
          // ignore: use_build_context_synchronously
          Navigator.pop(rootContext);
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(rootContext).showSnackBar(
            SnackBar(content: Text(jsonResponse['message'] ?? "❎ Imegoma kubadili nenosiri kwenye mfumo wetu")),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // ignore: use_build_context_synchronously
      Navigator.pop(rootContext);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Tafadhali hakikisha umeunganishwa na intaneti: $e")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchCollectionTypes();
  }

  @override
  Widget build(BuildContext rootContext) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Akaunti'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 20),
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: Colors.grey[200],
              backgroundImage: const AssetImage("assets/avatar.png"),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              userData!.user.userFullName ?? "User Name",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: Text(
              "+${userData!.user.phone}",
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const Padding(
            padding: EdgeInsets.only(bottom: 10, top: 5),
            child: Text("⚙️ Mipangilio", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ProfileMenuItem(
            icon: Icons.person,
            text: 'Hariri Taarifa',
            onTap: () {
              showSnackBar(context, "✅ Bado Ipo Katika Ujenzi.");
            },
          ),
          ProfileMenuItem(
            icon: Icons.language,
            text: 'Badili Lugha',
            onTap: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) {
                  return Padding(
                    padding: EdgeInsets.only(
                      top: 20,
                      left: 20,
                      right: 20,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Chagua Lugha',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.flag),
                          title: const Text('Kiswahili'),
                          onTap: () {
                            Navigator.pop(context);
                            showSnackBar(context, "✅ Lugha imebadilishwa kuwa Kiswahili.");
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.flag_outlined),
                          title: const Text('English'),
                          onTap: () {
                            Navigator.pop(context);
                            showSnackBar(context, "✅ Language changed to English.");
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          if (userData != null && userData!.user.role == "ADMIN") ...[
            ProfileMenuItem(
              icon: Icons.category,
              text: 'Aina ya Michango',
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) {
                    // Dummy list of categories, replace with your data source
                    // final List<String> categories = [
                    //   "Michango ya Harusi",
                    //   "Michango ya Maendeleo",
                    //   "Michango ya Matibabu",
                    // ];
                    return Padding(
                      padding: EdgeInsets.only(
                        top: 20,
                        left: 20,
                        right: 20,
                        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Aina ya Michango',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          ...collectionTypeResponse.map((cat) => ListTile(
                                leading: const Icon(Icons.label_outline),
                                title: Text(cat.collectionName),
                              )),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Ongeza Aina Mpya'),
                            onPressed: () {
                              Navigator.pop(context); // Dismiss current bottom sheet
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                builder: (context) {
                                  final TextEditingController controller = TextEditingController();
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      top: 20,
                                      left: 20,
                                      right: 20,
                                      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'Ongeza Aina Mpya ya Mchango',
                                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 16),
                                        TextField(
                                          controller: controller,
                                          decoration: const InputDecoration(
                                            labelText: 'Jina la Aina',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          child: const Text('Hifadhi'),
                                          onPressed: () {
                                            Navigator.pop(context);
                                            showSnackBar(
                                              context,
                                              "✅ Aina mpya imeongezwa: ${controller.text}",
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
          ProfileMenuItem(
            icon: Icons.lock,
            text: 'Badilisha Nenosiri',
            onTap: () => _showPasswordChangeSheet(context),
          ),
          ProfileMenuItem(
            icon: Icons.phone,
            text: 'Msaada na Usaidizi',
            onTap: () async {
              final Uri launchUri = Uri(scheme: 'tel', path: '0659515041');
              if (await canLaunchUrl(launchUri)) {
                await launchUrl(launchUri);
              } else {
                // ignore: use_build_context_synchronously
                showSnackBar(context, "Imeshindikana kupiga simu.");
              }
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.only(bottom: 10, top: 5),
            child: Text("ℹ️ Maelezo ya Programu", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ProfileMenuItem(
            icon: Icons.info,
            text: 'Taarifa ya Programu',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Jumuiya App',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.app_registration),
                children: [
                  const Text('Jumuiya Yangu App ni mfumo wa usimamizi wa Jumuiya.'),
                  const Text('Imeundwa na iSoftTz'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Wasiliana nasi:'),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () async {
                          final Uri emailUri = Uri(
                            scheme: 'mailto',
                            path: 'info@isofttz.com',
                          );
                          if (await canLaunchUrl(emailUri)) {
                            await launchUrl(emailUri);
                          } else {
                            // ignore: use_build_context_synchronously
                            showSnackBar(context, "Imeshindikana kufungua barua pepe.");
                          }
                        },
                        child: const Text(
                          'info@isofttz.com',
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () async {
                      final Uri url = Uri.parse('https://www.instagram.com/isofttz_/?hl=en');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      } else {
                        // ignore: use_build_context_synchronously
                        showSnackBar(context, "Imeshindikana kufungua tovuti.");
                      }
                    },
                    child: const Text('Tembelea Tovuti Yetu'),
                  ),
                ],
              );
            },
          ),
          ProfileMenuItem(
            icon: Icons.logout,
            text: 'Toka',
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Toka'),
                  content: const Text('Una uhakika unataka kutoka?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Ghairi'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        logout(context);
                      },
                      child: const Text('Toka'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showPasswordChangeSheet(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool oldVisible = false, newVisible = false, confirmVisible = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: StatefulBuilder(
              builder: (context, setState) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Badilisha Nenosiri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  buildPasswordField(
                      'Nenosiri la Zamani', oldPasswordController, oldVisible, (v) => setState(() => oldVisible = v)),
                  const SizedBox(height: 12),
                  buildPasswordField(
                      'Nenosiri Jipya', newPasswordController, newVisible, (v) => setState(() => newVisible = v)),
                  const SizedBox(height: 12),
                  buildPasswordField('Rudia Nenosiri', confirmPasswordController, confirmVisible,
                      (v) => setState(() => confirmVisible = v)),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text('Hifadhi Nenosiri'),
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              updatePassword(
                                context,
                                oldPasswordController.text,
                                newPasswordController.text,
                              );
                            }
                          },
                        ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildPasswordField(String label, TextEditingController controller, bool isVisible, Function(bool) toggle) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: () => toggle(!isVisible),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Jaza $label';
        return null;
      },
    );
  }

  void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(text),
      onTap: onTap,
    );
  }
}
