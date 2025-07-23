import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jumuiya_yangu/main.dart';
import 'package:jumuiya_yangu/models/other_collection_model.dart';
import 'package:jumuiya_yangu/pages/login_page.dart';
import 'package:jumuiya_yangu/shared/localstorage/index.dart';
import 'package:jumuiya_yangu/shared/components/modern_widgets.dart';
import 'package:jumuiya_yangu/theme/colors.dart';
import 'package:jumuiya_yangu/utils/url.dart';
import 'package:http/http.dart' as http;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = false;
  List<CollectionType> collectionTypeResponse = [];

  Future<void> fetchCollectionTypes() async {
    collectionTypeResponse = [];
    final response = await http
        .get(Uri.parse('$baseUrl/collectiontype/get_all_collection_type.php?jumuiya_id=${userData!.user.jumuiya_id}'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        collectionTypeResponse = (data['data'] as List).map((u) => CollectionType.fromJson(u)).toList();
      });
      setState(() {});
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
        const SnackBar(content: Text("✅ Umefanikiwa! Umetoka kwenye mfumo.")),
      );
    });
  }

  Future<dynamic> registerCollectionType(
      BuildContext rootContext, String collectionName, CollectionType? collection) async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (collectionName == "") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ Tafadhali hakikisha aina ya mchango")),
        );
      } else {
        String myApi = "$baseUrl/collectiontype/add.php";
        final response = await http.post(
          Uri.parse(myApi),
          headers: {'Accept': 'application/json'},
          body: jsonEncode({
            "id": collection != null ? collection.id : "",
            "collection_name": collectionName,
            "jumuiya_id": userData!.user.jumuiya_id.toString(),
            "registeredBy": userData!.user.userFullName.toString(),
          }),
        );

        var jsonResponse = json.decode(response.body);
        if (response.statusCode == 200 && jsonResponse != null && jsonResponse['status'] == "200") {
          setState(() {
            _isLoading = false;
          });

          setState(() {});

          //end here
          // ignore: use_build_context_synchronously
          Navigator.pop(context);

          fetchCollectionTypes();

          setState(() {});

          // ignore: use_build_context_synchronously
          Navigator.pop(context);

          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(rootContext).showSnackBar(
            SnackBar(content: Text("✅ Umefanikiwa! kuongeza aina ya mchango lako kwenye mfumo kwa mafanikio")),
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

  String toUnderscore(String text) {
    return text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
  }

  Future<dynamic> updateUserName(BuildContext rootContext, String newname) async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (newname == "") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ Tafadhali hakikisha umeweka namba ya jina lako")),
        );
      } else {
        String myApi = "$baseUrl/auth/update_profile_name_only.php";
        final response = await http.post(
          Uri.parse(myApi),
          headers: {'Accept': 'application/json'},
          body: {
            "user_id": userData!.user.id.toString(),
            "userFullName": newname,
            "userName": toUnderscore(newname),
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
          logout(context);
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
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      mainFontColor,
                      mainFontColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    // Profile Image
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 0,
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: isSmallScreen ? 45 : 55,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: isSmallScreen ? 42 : 52,
                          backgroundColor: Colors.white,
                          backgroundImage: const AssetImage("assets/avatar.png"),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // User Name
                    Text(
                      userData?.user.userFullName ?? "Mtumiaji",
                      style: TextStyle(
                        fontSize: isSmallScreen ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: 8),
                    
                    // Phone Number
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.phone_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "+${userData?.user.phone ?? ''}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 12),
                    
                    // Role Badge
                    if (userData?.user.role != null)
                      StatusChip(
                        label: userData!.user.role!,
                        color: Colors.white,
                        icon: Icons.verified_user_rounded,
                      ),
                  ],
                ),
              ),
              
              SizedBox(height: 24),
              
              // Menu Items
              Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Settings Section
                    _buildSectionTitle("⚙️ Mipangilio", isSmallScreen),
                    SizedBox(height: 16),
                    
                    ModernCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildModernMenuItem(
                            icon: Icons.person_rounded,
                            title: "Hariri Taarifa",
                            subtitle: "Badilisha jina lako",
                            onTap: () => _showEditProfileDialog(context),
                            color: blue,
                          ),
                          Divider(height: 1, color: Colors.grey[200]),
                          _buildModernMenuItem(
                            icon: Icons.lock_rounded,
                            title: "Badili Nenosiri",
                            subtitle: "Hifadhi akaunti yako",
                            onTap: () => _showChangePasswordDialog(context),
                            color: orange,
                          ),
                          if (userData?.user.role == "ADMIN") ...[
                            Divider(height: 1, color: Colors.grey[200]),
                            _buildModernMenuItem(
                              icon: Icons.category_rounded,
                              title: "Ongeza Aina ya Mchango",
                              subtitle: "Tengeneza mchango mpya",
                              onTap: () => showAddCollectionTypeDialog(context),
                              color: green,
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 24),
                    
                    // App Information Section
                    _buildSectionTitle("ℹ️ Taarifa za Programu", isSmallScreen),
                    SizedBox(height: 16),
                    
                    ModernCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildModernMenuItem(
                            icon: Icons.share_rounded,
                            title: "Shiriki Programu",
                            subtitle: "Shiriki na marafiki",
                            onTap: () => _shareApp(),
                            color: purple,
                          ),
                          Divider(height: 1, color: Colors.grey[200]),
                          _buildModernMenuItem(
                            icon: Icons.privacy_tip_rounded,
                            title: "Sera za Faragha",
                            subtitle: "Juu ya data yako",
                            onTap: () => _openPrivacyPolicy(),
                            color: blue,
                          ),
                          Divider(height: 1, color: Colors.grey[200]),
                          _buildModernMenuItem(
                            icon: Icons.info_rounded,
                            title: "Kuhusu Programu",
                            subtitle: "Toleo na maelezo",
                            onTap: () => _showAboutDialog(context),
                            color: grey,
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 32),
                    
                    // Logout Button
                    ModernButton(
                      text: "Toka",
                      icon: Icons.logout_rounded,
                      backgroundColor: errorColor,
                      onPressed: () => _showLogoutDialog(context),
                      isLoading: _isLoading,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isSmallScreen) {
    return Text(
      title,
      style: TextStyle(
        fontSize: isSmallScreen ? 16 : 18,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
    );
  }

  Widget _buildModernMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: color,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 13,
          color: textSecondary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: Colors.grey[400],
      ),
    );
  }
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            child: const Text('Hifadhi'),
                            onPressed: () {
                              updateUserName(rootContext, controller.text);
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
                icon: Icons.catching_pokemon_rounded,
                text: 'Aina ya Michango',
                onTap: () {
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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Aina ya Michango',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            _isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : Column(
                                    children: collectionTypeResponse
                                        .map(
                                          (cat) => ListTile(
                                            leading: CircleAvatar(
                                              backgroundColor: Colors.blue.shade100,
                                              child: Text(
                                                (collectionTypeResponse.indexOf(cat) + 1).toString(),
                                                style: const TextStyle(
                                                  color: Colors.blue,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            title: Text(cat.collectionName),
                                            trailing: IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.blue),
                                              onPressed: () {
                                                final TextEditingController controller =
                                                    TextEditingController(text: cat.collectionName);
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
                                                      child: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          const Text(
                                                            'Hariri Aina ya Mchango',
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
                                                            child: const Text('Hifadhi Mabadiliko'),
                                                            onPressed: () {
                                                              registerCollectionType(rootContext, controller.text, cat);
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
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
                                              registerCollectionType(rootContext, controller.text, null);
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
              icon: Icons.share,
              text: 'Shirikisha na Wengine',
              onTap: () {
                try {
                  // URL for Android and iOS app downloads
                  const String androidLink = "https://play.google.com/store/apps/details?id=com.isoftzt.jumuiya_yangu";
                  const String iosLink =
                      "https://apps.apple.com/tz/app/jumuiya-yangu/id6748091565"; // Replace with actual App Store ID
                  const String appName = "Jumuiya Yangu";
                  const String message =
                      "Habari! Jaribu $appName - mfumo bora wa usimamizi wa Jumuiya yako. Pakua sasa:\n\nAndroid: $androidLink\niOS: $iosLink\n\nUngana nasi kuboresha usimamizi wa Jumuiya yako!";

                  // Use the Share plugin to share the message
                  // ignore: deprecated_member_use
                  Share.share(message);
                } catch (e) {
                  showSnackBar(context, "Imeshindikana kushirikisha wengine.");
                }
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
