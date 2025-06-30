import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yeriko_app/main.dart';
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
          SnackBar(content: Text("Tafadhali hakikisha umeweka namba ya simu na nenosiri")),
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
            SnackBar(content: Text("Umefanikiwa! Kubadili nenosiri lako kwenye mfumo kwa mafanikio")),
          );
        } else {
          setState(() {
            _isLoading = false;
          });
          // ignore: use_build_context_synchronously
          Navigator.pop(rootContext);
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(rootContext).showSnackBar(
            SnackBar(content: Text(jsonResponse['message'] ?? "Imegoma kubadili nenosiri kwenye mfumo wetu")),
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
        SnackBar(content: Text("Tafadhali hakikisha umeunganishwa na intaneti: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext rootContext) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Akaunti'),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.edit),
        //     onPressed: () {
        //       // Navigate to edit page or open dialog
        //     },
        //   )
        // ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          Center(
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: MediaQuery.of(context).size.height / 20,
              child: CircleAvatar(
                radius: MediaQuery.of(context).size.height / 8,
                backgroundColor: Colors.white,
                backgroundImage: const AssetImage("assets/avatar.png"),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              userData!.user.userFullName ?? "User Name",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Center(child: Text("+${userData!.user.phone}", style: const TextStyle(color: Colors.grey))),
          const SizedBox(height: 30),
          const Divider(),

          /// Menu Options
          ProfileMenuItem(
            icon: Icons.person,
            text: 'Edit Profile',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("✅ Bado Ipo Katika Ujenzi.")),
              );
            },
          ),
          ProfileMenuItem(
            icon: Icons.language,
            text: 'Change Language',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("✅ Bado Ipo Katika Ujenzi.")),
              );
            },
          ),
          ProfileMenuItem(
            icon: Icons.lock,
            text: 'Badilisha Nenosiri',
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) {
                  final _formKey = GlobalKey<FormState>();
                  final TextEditingController oldPasswordController = TextEditingController();
                  final TextEditingController newPasswordController = TextEditingController();
                  final TextEditingController confirmPasswordController = TextEditingController();

                  return Padding(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                      top: 20,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Change Password',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          StatefulBuilder(
                            builder: (context, setState) {
                              return Column(
                                children: [
                                  TextFormField(
                                    controller: oldPasswordController,
                                    obscureText: !oldPasswordVisible,
                                    decoration: InputDecoration(
                                      labelText: 'Nenosiri la Zamani',
                                      border: const OutlineInputBorder(),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          oldPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            oldPasswordVisible = !oldPasswordVisible;
                                          });
                                        },
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Tafadhali ingiza nenosiri lako la zamani';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: newPasswordController,
                                    obscureText: !newPasswordVisible,
                                    decoration: InputDecoration(
                                      labelText: 'New Password',
                                      border: const OutlineInputBorder(),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          newPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            newPasswordVisible = !newPasswordVisible;
                                          });
                                        },
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Tafadhali ingiza nenosiri jipya';
                                      }
                                      if (value.length < 6) {
                                        return 'Nenosiri lazima liwe na angalau herufi 6';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: confirmPasswordController,
                                    obscureText: !confirmPasswordVisible,
                                    decoration: InputDecoration(
                                      labelText: 'Confirm New Password',
                                      border: const OutlineInputBorder(),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            confirmPasswordVisible = !confirmPasswordVisible;
                                          });
                                        },
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value != newPasswordController.text) {
                                        return 'Passwords do not match';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        updatePassword(
                                            rootContext, oldPasswordController.text, newPasswordController.text);
                                      }
                                    },
                                    child: const Text('Update Password'),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          ProfileMenuItem(
            icon: Icons.phone,
            text: 'Msaada na Usaidizi',
            onTap: () async {
              // Call support number
              const phoneNumber = '0659515041'; // Change to your support number
              final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
              if (await canLaunchUrl(launchUri)) {
                await launchUrl(launchUri);
              } else {
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Imeshindikana kupiga simu.')),
                );
              }
            },
          ),
          ProfileMenuItem(
            icon: Icons.logout,
            text: 'Toka',
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Toka'),
                    content: const Text('Una uhakika unataka kutoka?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          logout(context);
                        },
                        child: const Text('Toka'),
                      ),
                    ],
                  );
                },
              );
            },
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
                  const SizedBox(height: 10),
                  const Text('Developed by Yeriko Team'),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () async {
                      final Uri url = Uri.parse('https://www.instagram.com/isofttz_/?hl=en');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      } else {
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Imeshindikana kufungua tovuti.')),
                        );
                      }
                    },
                    child: const Text('Visit our website'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
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
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
