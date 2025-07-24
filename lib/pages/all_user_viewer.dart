import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jumuiya_yangu/main.dart';
import 'package:jumuiya_yangu/models/all_users_model.dart';
import 'package:jumuiya_yangu/pages/add_pages/add_user.dart';
import 'package:jumuiya_yangu/theme/colors.dart';
import 'package:jumuiya_yangu/utils/url.dart';
import 'package:http/http.dart' as http;

class AllViewerUserWithAdmin extends StatefulWidget {
  const AllViewerUserWithAdmin({super.key});

  @override
  State<AllViewerUserWithAdmin> createState() => _AllViewerUserWithAdminState();
}

class _AllViewerUserWithAdminState extends State<AllViewerUserWithAdmin> {
  AllUsersResponse? collections;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    getUsersCollections();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reloadData() async {
    await getUsersCollections();
    setState(() {}); // Refresh UI after fetching data
  }

  Future<AllUsersResponse?> getUsersCollections() async {
    try {
      final String myApi = "$baseUrl/auth/get_all_users.php?jumuiya_id=${userData!.user.jumuiya_id}";
      final response = await http.get(Uri.parse(myApi), headers: {'Accept': 'application/json'});

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse != null) {
          collections = AllUsersResponse.fromJson(jsonResponse);
          return collections;
        }
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Tafadhali hakikisha umeunganishwa na intaneti: $e")),
      );
    }

    // 🔁 Always return something to complete Future
    return null;
  }

  Future<void> deleteTimeTable(dynamic id) async {
    try {
      final String myApi = "$baseUrl/church_timetable/delete_time_table.php?id=$id";
      final response = await http.delete(
        Uri.parse(myApi),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        // final jsonResponse = json.decode(response.body);
        // print(jsonResponse);
        // Example: await deleteTimeTable(item.id);
        // ignore: use_build_context_synchronously
        Navigator.pop(context); // Close bottom sheet
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ratiba imefutwa kikamirifu.')),
        );
        _reloadData();
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Tafadhali hakikisha umeunganishwa na intaneti: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primary,
      body: RefreshIndicator(onRefresh: _reloadData, child: getBody()),
    );
  }

  Widget getBody() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          floating: true,
          pinned: true,
          backgroundColor: primary,
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primary,
                    primary.withValues(alpha: 0.9),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Wanajumuiya",
                                style: TextStyle(
                                  color: const Color.fromARGB(255, 32, 21, 234).withValues(alpha: 0.8),
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                "${collections?.data.length ?? 0} wanachama${_searchQuery.isNotEmpty ? ' (${_filterUsers(collections?.data ?? []).length} wamepatikana)' : ''}",
                                style: TextStyle(
                                  color: const Color.fromARGB(255, 32, 21, 234).withValues(alpha: 0.7),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      offset: Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              CupertinoIcons.person_3_fill,
                              color: Colors.white,
                              size: 24,
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
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Tafuta mwanajumuiya...",
                        prefixIcon: Icon(CupertinoIcons.search, color: Colors.grey[600]),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey[600]),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
                if (userData != null && userData!.user.role == "ADMIN") ...[
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [mainFontColor, mainFontColor.withValues(alpha: 0.8)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: mainFontColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                            ),
                            builder: (_) => AddUserPageAdmin(
                              rootContext: context,
                              onSubmit: (data) {
                                _reloadData();
                              },
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add, color: Colors.white, size: 20),
                              const SizedBox(width: 4),
                              const Text(
                                "Ongeza",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: FutureBuilder(
            future: getUsersCollections(),
            builder: (context, AsyncSnapshot<AllUsersResponse?> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(
                  height: 300,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: mainFontColor.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text(
                          "Inapakia wanajumuiya...",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else if (snapshot.hasError) {
                return SizedBox(
                  height: 300,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          "Imeshindikana kupakia taarifa za wanajumuiya.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
                return SizedBox(
                  height: 300,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.person_3, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          "Hakuna taarifa za wanajumuiya zilizopatikana.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final collections = snapshot.data!.data;
              final filteredUsers = _filterUsers(collections);

              if (filteredUsers.isEmpty && _searchQuery.isNotEmpty) {
                return SizedBox(
                  height: 300,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.search, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          "Hakuna mwanajumuiya aliyepatikana\nkwa utafutaji '$_searchQuery'",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: filteredUsers.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemBuilder: (context, index) {
                  final item = filteredUsers[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with name and role
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.userFullName ?? "Jina Halipo",
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "@${item.userName}",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: item.role == "ADMIN"
                                            ? [Colors.red[400]!, Colors.red[600]!]
                                            : [Colors.blue[400]!, Colors.blue[600]!],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      item.role ?? "Role Halipo",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Contact Info
                              _buildInfoRow(
                                icon: Icons.phone,
                                label: "Simu",
                                value: item.phone ?? "Hajaongeza",
                                color: Colors.green,
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                icon: Icons.calendar_today,
                                label: "Mwaka wa usajili",
                                value: item.yearRegistered ?? "Hajaongeza",
                                color: Colors.orange,
                              ),

                              // Admin-only details
                              if (userData != null && userData!.user.role == "ADMIN") ...[
                                const SizedBox(height: 8),
                                _buildInfoRow(
                                  icon: Icons.location_on,
                                  label: "Mahali anapoishi",
                                  value: item.location ?? "Hajaongeza",
                                  color: Colors.purple,
                                ),
                                const SizedBox(height: 8),
                                _buildInfoRow(
                                  icon: Icons.person,
                                  label: "Jinsia",
                                  value: item.gender ?? "Hajaongeza",
                                  color: Colors.teal,
                                ),
                                const SizedBox(height: 8),
                                _buildInfoRow(
                                  icon: Icons.cake,
                                  label: "Tarehe ya kuzaliwa",
                                  value: item.dobdate ?? "Hajaongeza",
                                  color: Colors.pink,
                                ),
                                const SizedBox(height: 8),
                                _buildInfoRow(
                                  icon: Icons.favorite,
                                  label: "Hali ya ndoa",
                                  value: item.martialstatus ?? "Hajaongeza",
                                  color: Colors.red,
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Action buttons
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              if (userData != null && userData!.user.role == "ADMIN") ...[
                                Expanded(
                                  child: _buildActionButton(
                                    icon: Icons.edit_outlined,
                                    label: "Hariri",
                                    color: Colors.blue,
                                    onPressed: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                                        ),
                                        builder: (_) => AddUserPageAdmin(
                                          rootContext: context,
                                          initialData: item,
                                          onSubmit: (data) {
                                            _reloadData();
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.phone,
                                  label: "Piga Simu",
                                  color: Colors.green,
                                  onPressed: () async {
                                    final phone = (item.phone ?? '').replaceAll(' ', '');
                                    String formattedPhone = formatPhoneNumber(phone);
                                    if (phone.isNotEmpty) {
                                      final Uri url = Uri.parse('tel:$formattedPhone');
                                      if (await canLaunchUrl(url)) {
                                        await launchUrl(url);
                                      } else {
                                        // ignore: use_build_context_synchronously
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Imeshindikana kupiga simu.")),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: 20),
        ),
      ],
    );
  }

  List<dynamic> _filterUsers(List<dynamic> users) {
    if (_searchQuery.isEmpty) {
      return users;
    }

    return users.where((user) {
      final userName = (user.userName ?? '').toLowerCase();
      final userFullName = (user.userFullName ?? '').toLowerCase();
      final phone = (user.phone ?? '').toLowerCase();
      final location = (user.location ?? '').toLowerCase();
      final role = (user.role ?? '').toLowerCase();

      return userName.contains(_searchQuery) ||
          userFullName.contains(_searchQuery) ||
          phone.contains(_searchQuery) ||
          location.contains(_searchQuery) ||
          role.contains(_searchQuery);
    }).toList();
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String formatPhoneNumber(String phone) {
    if (phone.startsWith("255") && phone.length > 3) {
      return "0${phone.substring(3)}";
    }
    return phone;
  }
}
