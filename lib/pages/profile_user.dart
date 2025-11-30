// ignore_for_file: strict_top_level_inference, deprecated_member_use

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jumuiya_yangu/models/auth_model.dart';
import 'package:jumuiya_yangu/models/sms_bando_summary_model.dart';
import 'package:jumuiya_yangu/models/sms_bando_used_model.dart';
import 'package:jumuiya_yangu/pages/huduma_za_ziada_page.dart';
import 'package:page_transition/page_transition.dart';
import 'package:restart_app/restart_app.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jumuiya_yangu/main.dart';
import 'package:jumuiya_yangu/models/other_collection_model.dart';
import 'package:jumuiya_yangu/pages/login_page.dart';
import 'package:jumuiya_yangu/pages/sms_bando/sms_bando_list_page.dart';
import 'package:jumuiya_yangu/pages/send_message_page.dart';
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
  bool oldPasswordVisible = false;
  bool newPasswordVisible = false;
  bool _isLoadingJumuiya = false;
  bool confirmPasswordVisible = false;
  bool _isLoading = false;
  bool _isLoadingSmsSummary = false;
  List<CollectionType> collectionTypeResponse = [];
  dynamic usedSummary;
  List<Map<String, dynamic>> jumuiyaData = [];
  List<SmsBandoSummaryModel> smsBandoSummaryList = [];

  Future<void> fetchCollectionTypes() async {
    collectionTypeResponse = [];
    final response = await http.get(Uri.parse(
        '$baseUrl/collectiontype/get_all_collection_type.php?jumuiya_id=${userData!.user.jumuiya_id}'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        collectionTypeResponse = (data['data'] as List)
            .map((u) => CollectionType.fromJson(u))
            .toList();
      });
      setState(() {});
    } else {
      // handle error
    }
  }

  Future<void> fetchJumuiyaNames() async {
    try {
      final response = await http.post(
          headers: {'Accept': 'application/json'},
          Uri.parse('$baseUrl/auth/get_my_jumuiya.php'),
          body: jsonEncode({
            "user_id": userData!.user.id.toString(),
          }));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == "200" && data['data'] != null) {
          setState(() {
            jumuiyaData = (data['data'] as List)
                .map((item) => {
                      'name': item['name'] as String,
                      'id': item['id'] as dynamic,
                    })
                .toList();
          });
        }
      }
    } catch (e) {
      // Handle error silently or show message
      if (kDebugMode) {
        print('Error fetching jumuiya data');
      }
    }
  }

  Future<void> fetchSmsBandoSummary() async {
    if (userData?.user.jumuiya_id == null) return;

    setState(() {
      _isLoadingSmsSummary = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sms_bando/get_sms_bando_summary.php'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "jumuiya_id": userData!.user.jumuiya_id.toString(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'].toString() == "200" && data['data'] != null) {
          setState(() {
            smsBandoSummaryList = (data['data'] as List)
                .map((item) => SmsBandoSummaryModel.fromJson(item))
                .toList();
          });
        }
      }
    } catch (e) {
      // Handle error silently
      if (kDebugMode) {
        print('Error fetching SMS bando summary');
      }
    } finally {
      setState(() {
        _isLoadingSmsSummary = false;
      });
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

  Future<void> switchJumuiya(dynamic jumuiyaId, String jumuiyaName) async {
    try {
      setState(() {
        _isLoadingJumuiya = true;
      });

      // Locally update user jumuiya info without API call
      final updatedUser = User(
        id: userData!.user.id,
        phone: userData!.user.phone,
        userFullName: userData!.user.userFullName,
        yearRegistered: userData!.user.yearRegistered,
        createdAt: userData!.user.createdAt,
        userName: userData!.user.userName,
        location: userData!.user.location,
        gender: userData!.user.gender,
        dobdate: userData!.user.dobdate,
        martialstatus: userData!.user.martialstatus,
        role: userData!.user.role,
        jina_jumuiya: jumuiyaName,
        jumuiya_id: jumuiyaId,
      );

      userData = LoginResponse(
        status: userData!.status,
        message: userData!.message,
        user: updatedUser,
      );

      // Save updated user data to local storage
      String updatedUserJson = jsonEncode(userData!.toJson());
      await LocalStorage.setStringItem("user_data", updatedUserJson);

      setState(() {
        _isLoadingJumuiya = false;
      });

      // Refresh data for new jumuiya
      fetchCollectionTypes();
      // Refresh daily data if needed
      // fetchJumuiyaNames();
      Restart.restartApp(
        notificationTitle: 'Jumuiya Yangu',
        notificationBody: 'Tafadhali gusa hapa kufungua programu tena.',
      );

      // Onyesha ujumbe wa mafanikio
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("✅ Umefanikiwa kubadilisha jumuiya: $jumuiyaName")),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingJumuiya = false;
      });
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text("⚠️ Tafadhali hakikisha umeunganishwa na intaneti")),
        );
      }
    }
  }

  Future<dynamic> registerCollectionType(BuildContext rootContext,
      String collectionName, CollectionType? collection) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Check if collectionName already exists
      bool exists = collectionTypeResponse.any((type) =>
          type.collectionName.trim().toLowerCase() ==
          collectionName.trim().toLowerCase());
      if (exists) {
        Navigator.pop(context);
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text("⚠️ Aina ya mchango '$collectionName' tayari ipo.")),
        );
        return;
      }

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
        if (response.statusCode == 200 &&
            jsonResponse != null &&
            jsonResponse['status'] == "200") {
          setState(() {
            _isLoading = false;
          });

          setState(() {});

          fetchCollectionTypes();

          setState(() {});

          // ignore: use_build_context_synchronously
          Navigator.pop(context);

          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(rootContext).showSnackBar(
            SnackBar(
                content: Text(
                    "✅ Umefanikiwa! kuongeza aina ya mchango lako kwenye mfumo kwa mafanikio")),
          );
        } else {
          setState(() {
            _isLoading = false;
          });
          // ignore: use_build_context_synchronously
          Navigator.pop(rootContext);
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(rootContext).showSnackBar(
            SnackBar(
                content: Text(jsonResponse['message'] ??
                    "❎ Imegoma kubadili nenosiri kwenye mfumo wetu")),
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
        SnackBar(
            content: Text("⚠️ Tafadhali hakikisha umeunganishwa na intaneti")),
      );
    }
  }

  String toUnderscore(String text) {
    return text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
  }

  Future<dynamic> updateUserName(
      BuildContext rootContext, String newname) async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (newname == "") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text("⚠️ Tafadhali hakikisha umeweka namba ya jina lako")),
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

        if (response.statusCode == 200 &&
            jsonResponse != null &&
            jsonResponse['status'] == "200") {
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
            SnackBar(
                content: Text(jsonResponse['message'] ??
                    "❎ Imegoma kubadili nenosiri kwenye mfumo wetu")),
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
        SnackBar(
            content: Text("⚠️ Tafadhali hakikisha umeunganishwa na intaneti")),
      );
    }
  }

  Future<dynamic> updatePassword(
      BuildContext rootContext, String oldpassword, String newpassword) async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (oldpassword == "" || newpassword == "") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "⚠️ Tafadhali hakikisha umeweka namba ya simu na nenosiri")),
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

        if (response.statusCode == 200 &&
            jsonResponse != null &&
            jsonResponse['status'] == "200") {
          setState(() {
            _isLoading = false;
          });

          setState(() {});

          //end here
          // ignore: use_build_context_synchronously
          Navigator.pop(rootContext);

          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(rootContext).showSnackBar(
            SnackBar(
                content: Text(
                    "✅ Umefanikiwa! Kubadili nenosiri lako kwenye mfumo kwa mafanikio")),
          );
        } else {
          setState(() {
            _isLoading = false;
          });
          // ignore: use_build_context_synchronously
          Navigator.pop(rootContext);
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(rootContext).showSnackBar(
            SnackBar(
                content: Text(jsonResponse['message'] ??
                    "❎ Imegoma kubadili nenosiri kwenye mfumo wetu")),
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
        SnackBar(
            content: Text("⚠️ Tafadhali hakikisha umeunganishwa na intaneti")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchCollectionTypes();
    fetchJumuiyaNames();
    fetchSmsBandoSummary();
    fetchSmsBandoSummaryUsed();
  }

  Future<void> fetchSmsBandoSummaryUsed() async {
    if (userData?.user.jumuiya_id == null) return;

    setState(() {
      _isLoadingSmsSummary = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sms_bando/get_summary_used_sms.php'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "jumuiya_id": userData!.user.jumuiya_id.toString(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'].toString() == "200") {
          // Use the new model for used SMS
          usedSummary = SmsBandoUsedModel.fromJson(data);
        }
      }
    } catch (e) {
      // Handle error silently
      if (kDebugMode) {
        print('Error fetching used SMS summary');
      }
    } finally {
      setState(() {
        _isLoadingSmsSummary = false;
      });
    }
  }

  void _showJumuiyaSwitchDialog(jumuiyaId, jumuiyaName) {
    if (jumuiyaData.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("⚠️ Huna jumuiya zaidi ya moja za kubadilishia")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext confirmContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.orange[400]),
              SizedBox(width: 8),
              Text('Thibitisha'),
            ],
          ),
          content: Text(
              'Una uhakika unataka kubadilisha hadi jumuiya "$jumuiyaName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(confirmContext).pop(),
              child: Text(
                'Hapana',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: mainFontColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(confirmContext).pop();
                switchJumuiya(jumuiyaId, jumuiyaName);
              },
              child: const Text('Ndiyo'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    return Scaffold(
      // appBar: AppBar(
      //   backgroundColor: Colors.deepPurple,
      //   systemOverlayStyle: const SystemUiOverlayStyle(
      //     statusBarColor: Colors.deepPurple,
      //     statusBarIconBrightness: Brightness.light,
      //     statusBarBrightness: Brightness.dark,
      //   ),
      // ),
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
                      mainFontColor.withValues(alpha: 0.8),
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
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            spreadRadius: 0,
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius:
                            isSmallScreen ? size.height / 8 : size.height / 20,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: isSmallScreen
                              ? size.height / 8
                              : size.height / 20,
                          backgroundColor: Colors.white,
                          backgroundImage:
                              const AssetImage("assets/avatar.png"),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // User Name
                    Text(
                      userData?.user.userFullName ?? "Mtumiaji",
                      style: TextStyle(
                        fontSize:
                            isSmallScreen ? size.height / 80 : size.height / 50,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    // Phone Number
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.phone_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "+${userData?.user.phone ?? ''}",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Role Badge
                    if (userData?.user.role != null)
                      StatusChip(
                        label: userData!.user.role!,
                        color: Colors.white,
                        icon: Icons.verified_user_rounded,
                      ),

                    // Jumuiya Names Section (show if more than 2)
                    if (jumuiyaData.length >= 2) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.group_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Jumuiya Zangu",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_isLoadingJumuiya)
                              SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: jumuiyaData.map((jumuiyaItem) {
                                  final name = jumuiyaItem['name'] as String;
                                  final id = jumuiyaItem['id'];
                                  final isActive =
                                      userData?.user.jumuiya_id.toString() ==
                                          id.toString();

                                  return GestureDetector(
                                    onTap: () {
                                      if (!isActive) {
                                        _showJumuiyaSwitchDialog(id, name);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? Colors.white
                                                .withValues(alpha: 0.3)
                                            : Colors.white
                                                .withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isActive
                                              ? Colors.white
                                                  .withValues(alpha: 0.8)
                                              : Colors.white
                                                  .withValues(alpha: 0.4),
                                          width: isActive ? 2 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isActive) ...[
                                            Icon(
                                              Icons.check_circle,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 6),
                                          ],
                                          Text(
                                            name,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                              fontWeight: isActive
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                    ],
                    // SMS Bando Summary Section
                    if (userData?.user.role == "ADMIN") ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.message_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "Muhtasari wa SMS",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                // if (smsBandoSummaryList.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.refresh,
                                        color: Colors.white,
                                      ),
                                      onPressed: fetchSmsBandoSummary,
                                    ),
                                  ],
                                ),
                                // ],
                              ],
                            ),
                            const SizedBox(height: 12),
                            _isLoadingSmsSummary
                                ? const Center(
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : smsBandoSummaryList.isEmpty
                                    ? const Text(
                                        "Hakuna taarifa za SMS",
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      )
                                    : Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.black
                                                  .withOpacity(0.05),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                _buildSmsStatItem(
                                                  "SMS Zilizopo",
                                                  smsBandoSummaryList.isNotEmpty
                                                      ? smsBandoSummaryList[0]
                                                          .smsTotal
                                                          .toString()
                                                      : "0",
                                                  Colors.blue,
                                                ),
                                                _buildSmsStatItem(
                                                  "Zilizotumiwa",
                                                  usedSummary != null
                                                      ? usedSummary
                                                          .totalWaliotumiwa
                                                          .toString()
                                                      : "0",
                                                  Colors.green,
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            height: 4,
                                          ),
                                          if (smsBandoSummaryList
                                              .isNotEmpty) ...[
                                            GestureDetector(
                                              onTap: () => Navigator.push(
                                                context,
                                                PageTransition(
                                                  type: PageTransitionType
                                                      .rightToLeft,
                                                  child:
                                                      const SmsBandoListPage(),
                                                ),
                                              ),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: const [
                                                    Text(
                                                      "Angalia Zaidi",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    SizedBox(width: 4),
                                                    Icon(
                                                      Icons.arrow_forward_ios,
                                                      color: Colors.white,
                                                      size: 12,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Menu Items
              Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Settings Section
                    _buildSectionTitle("⚙️ Mipangilio", isSmallScreen),
                    const SizedBox(height: 16),

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
                              icon: Icons.money,
                              title: "Nunua Jumbe",
                              subtitle: "Nunua na Angalia jumbe ulizonunua",
                              onTap: () => Navigator.push(
                                context,
                                PageTransition(
                                  type: PageTransitionType.rightToLeft,
                                  child: const SmsBandoListPage(),
                                ),
                              ),
                              color: green,
                            ),
                            Divider(height: 1, color: Colors.grey[200]),
                            _buildModernMenuItem(
                              icon: Icons.message_rounded,
                              title: "Tuma Jumbe",
                              subtitle: "Tuma na tazama jumbe ulizotuma",
                              onTap: () => Navigator.push(
                                context,
                                PageTransition(
                                  type: PageTransitionType.rightToLeft,
                                  child: const SendMessagePage(),
                                ),
                              ),
                              color: green,
                            ),
                            Divider(height: 1, color: Colors.grey[200]),
                            _buildModernMenuItem(
                              icon: Icons.attach_money,
                              title: "Mikopo",
                              subtitle: "Mpangilio wa mikopo ya watumiaji",
                              onTap: () => Navigator.push(
                                context,
                                PageTransition(
                                  type: PageTransitionType.rightToLeft,
                                  child: const SendMessagePage(),
                                ),
                              ),
                              color: green,
                            ),
                            Divider(height: 1, color: Colors.grey[200]),
                            _buildModernMenuItem(
                              icon: Icons.category_rounded,
                              title: "Ongeza Aina ya Mchango",
                              subtitle: "Tengeneza mchango mpya",
                              onTap: () =>
                                  _showAddCollectionTypeDialog(context),
                              color: green,
                            ),
                            Divider(height: 1, color: Colors.grey[200]),
                            _buildModernMenuItem(
                              icon: Icons.money,
                              title: "Huduma Za Ziada",
                              subtitle: "Nunua na Angalia Huduma Za Ziada",
                              onTap: () => Navigator.push(
                                context,
                                PageTransition(
                                  type: PageTransitionType.rightToLeft,
                                  child: const HudumaZaZiadaPage(),
                                ),
                              ),
                              color: green,
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // App Information Section
                    _buildSectionTitle("ℹ️ Taarifa za Programu", isSmallScreen),
                    const SizedBox(height: 16),

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
                            icon: Icons.help_rounded,
                            title: "Msaada na Usaidizi",
                            subtitle: "Wasiliana nasi",
                            onTap: () => _contactSupport(),
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

                    const SizedBox(height: 24),

                    // Logout Button
                    ModernButton(
                      text: "Toka",
                      icon: Icons.logout_rounded,
                      backgroundColor: errorColor,
                      onPressed: () => _showLogoutDialog(context),
                      isLoading: _isLoading,
                      padding: const EdgeInsets.all(10),
                    ),

                    const SizedBox(height: 24),
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
          color: color.withValues(alpha: 0.1),
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

  // Helper methods
  void _showEditProfileDialog(BuildContext context) {
    final TextEditingController controller =
        TextEditingController(text: userData?.user.userFullName ?? "");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hariri Taarifa za Wasifu'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Jina Kamili',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ghairi'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                updateUserName(context, controller.text);
              }
            },
            child: const Text('Hifadhi'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    _showPasswordChangeSheet(context);
  }

  void _showAddCollectionTypeDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ongeza Aina ya Mchango'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Jina la Aina ya Mchango',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (collectionTypeResponse.isNotEmpty) ...[
              const Text('Aina za Michango Zilizopo:'),
              const SizedBox(height: 8),
              ...collectionTypeResponse.map(
                (type) => ListTile(
                  title: Text(type.collectionName),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      _editCollectionType(context, type);
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ghairi'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                registerCollectionType(context, controller.text, null);
              }
            },
            child: const Text('Ongeza'),
          ),
        ],
      ),
    );
  }

  void _editCollectionType(BuildContext context, CollectionType type) {
    final TextEditingController controller =
        TextEditingController(text: type.collectionName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hariri Aina ya Mchango'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Jina la Aina ya Mchango',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ghairi'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                registerCollectionType(context, controller.text, type);
              }
            },
            child: const Text('Hifadhi'),
          ),
        ],
      ),
    );
  }

  void _shareApp() {
    const String androidLink = "https://bit.ly/4225L5Z";
    // "https://play.google.com/store/apps/details?id=com.isofttz.jumuiya_yangu";
    const String iosLink = "https://apple.co/47mNeVQ";
    // "https://apps.apple.com/tz/app/jumuiya-yangu/id6748091565";
    const String appName = "Jumuiya Yangu";
    const String message =
        "Habari! Jaribu $appName - App bora wa usimamizi wa Jumuiya yako. Pakua sasa:\n\nAndroid: $androidLink\niOS: $iosLink\n\nUngana nasi kuboresha usimamizi wa Jumuiya yako!";

    Share.share(message);
  }

  void _contactSupport() async {
    final Uri launchUri = Uri(scheme: 'tel', path: '0659515042');
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Imeshindikana kupiga simu.")),
      );
    }
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Jumuiya Yangu',
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Imeshindikana kufungua barua pepe.")),
                  );
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
            final Uri url =
                Uri.parse('https://www.instagram.com/isofttz_/?hl=en');
            if (await canLaunchUrl(url)) {
              await launchUrl(url);
            } else {
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Imeshindikana kufungua tovuti.")),
              );
            }
          },
          child: const Text('Tembelea Tovuti Yetu'),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
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
                  const Text('Badilisha Nenosiri',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  buildPasswordField(
                      'Nenosiri la Zamani',
                      oldPasswordController,
                      oldVisible,
                      (v) => setState(() => oldVisible = v)),
                  const SizedBox(height: 12),
                  buildPasswordField('Nenosiri Jipya', newPasswordController,
                      newVisible, (v) => setState(() => newVisible = v)),
                  const SizedBox(height: 12),
                  buildPasswordField(
                      'Rudia Nenosiri',
                      confirmPasswordController,
                      confirmVisible,
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

  Widget buildPasswordField(String label, TextEditingController controller,
      bool isVisible, Function(bool) toggle) {
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildSmsStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
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
      onTap: onTap,
    );
  }
}
