import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jumuiya_yangu/main.dart';
import 'package:jumuiya_yangu/models/pending_requests_model.dart';
import 'package:jumuiya_yangu/theme/colors.dart';
import 'package:jumuiya_yangu/utils/url.dart';
import 'package:http/http.dart' as http;

class PendingRequestsViewer extends StatefulWidget {
  const PendingRequestsViewer({super.key});

  @override
  State<PendingRequestsViewer> createState() => _PendingRequestsViewerState();
}

class _PendingRequestsViewerState extends State<PendingRequestsViewer> {
  PendingRequestsResponse? pendingRequests;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    getPendingRequests();
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
    await getPendingRequests();
    setState(() {}); // Refresh UI after fetching data
  }

  Future<PendingRequestsResponse?> getPendingRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String myApi = "$baseUrl/auth/get_all_user_associated_by_jumuiya_id.php";
      final response = await http.post(Uri.parse(myApi),
          headers: {'Content-type': 'application/json'},
          body: json.encode({
            'jumuiya_id': userData!.user.jumuiya_id,
          }));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse != null) {
          pendingRequests = PendingRequestsResponse.fromJson(jsonResponse);
          setState(() {
            _isLoading = false;
          });
          return pendingRequests;
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Tafadhali hakikisha umeunganishwa na intaneti: $e")),
      );
    }

    return null;
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
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: const Icon(
                                CupertinoIcons.back,
                                color: Colors.orange,
                                size: 24,
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Maombi Yanayosubiri",
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
                                "${pendingRequests?.data.length ?? 0} maombi${_searchQuery.isNotEmpty ? ' (${_filterRequests(pendingRequests?.data ?? []).length} yamepatikana)' : ''}",
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
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Tafuta ombi...",
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
        ),
        SliverToBoxAdapter(
          child: _isLoading
              ? SizedBox(
                  height: 300,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: mainFontColor.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text(
                          "Inatafuta maombi...",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildRequestsList(),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: 20),
        ),
      ],
    );
  }

  Widget _buildRequestsList() {
    if (pendingRequests == null || pendingRequests!.data.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.clock, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                "Hakuna maombi yanayosubiri.",
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

    final filteredRequests = _filterRequests(pendingRequests!.data);

    if (filteredRequests.isEmpty && _searchQuery.isNotEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.search, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                "Hakuna ombi lililopatikana\nkwa utafutaji '$_searchQuery'",
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
      itemCount: filteredRequests.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemBuilder: (context, index) {
        final request = filteredRequests[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Pending status indicator
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange[300]!, Colors.orange[400]!],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.clock_fill, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      "INASUBIRI IDHINI",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with name and request date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request.userFullName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "@${request.userName}",
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
                              colors: request.role == "ADMIN"
                                  ? [Colors.red[400]!, Colors.red[600]!]
                                  : [Colors.blue[400]!, Colors.blue[600]!],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            request.role,
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

                    // Request details
                    _buildInfoRow(
                      icon: Icons.calendar_today,
                      label: "Tarehe ya ombi",
                      value: _formatDate(request.associatedDate),
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      icon: Icons.person_add,
                      label: "Aliposajiliwa na",
                      value: request.registeredBy,
                      color: Colors.purple,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      icon: Icons.phone,
                      label: "Simu",
                      value: request.phone,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      icon: Icons.location_on,
                      label: "Mahali anapoishi",
                      value: request.location,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      icon: Icons.person,
                      label: "Jinsia",
                      value: request.gender,
                      color: Colors.teal,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      icon: Icons.cake,
                      label: "Tarehe ya kuzaliwa",
                      value: request.dobdate,
                      color: Colors.pink,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      icon: Icons.favorite,
                      label: "Hali ya ndoa",
                      value: request.martialstatus,
                      color: Colors.red,
                    ),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.phone,
                        label: "Piga Simu",
                        color: Colors.blue,
                        onPressed: () async {
                          final phone = (request.phone).replaceAll(' ', '');
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
  }

  List<PendingRequest> _filterRequests(List<PendingRequest> requests) {
    if (_searchQuery.isEmpty) {
      return requests;
    }

    return requests.where((request) {
      final userName = request.userName.toLowerCase();
      final userFullName = request.userFullName.toLowerCase();
      final phone = request.phone.toLowerCase();
      final location = request.location.toLowerCase();
      final registeredBy = request.registeredBy.toLowerCase();

      return userName.contains(_searchQuery) ||
          userFullName.contains(_searchQuery) ||
          phone.contains(_searchQuery) ||
          location.contains(_searchQuery) ||
          registeredBy.contains(_searchQuery);
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
            child: Column(
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateString;
    }
  }

  String formatPhoneNumber(String phone) {
    if (phone.startsWith("255") && phone.length > 3) {
      return "0${phone.substring(3)}";
    }
    return phone;
  }
}
