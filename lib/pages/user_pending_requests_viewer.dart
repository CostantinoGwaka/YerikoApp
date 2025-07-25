import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jumuiya_yangu/main.dart';
import 'package:jumuiya_yangu/models/pending_requests_model.dart';
import 'package:jumuiya_yangu/theme/colors.dart';
import 'package:jumuiya_yangu/utils/url.dart';
import 'package:http/http.dart' as http;

class UserPendingRequestsViewer extends StatefulWidget {
  const UserPendingRequestsViewer({super.key});

  @override
  State<UserPendingRequestsViewer> createState() => _UserPendingRequestsViewerState();
}

class _UserPendingRequestsViewerState extends State<UserPendingRequestsViewer> {
  PendingRequestsResponse? pendingRequests;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    getUserPendingRequests();
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
    await getUserPendingRequests();
    setState(() {}); // Refresh UI after fetching data
  }

  Future<void> approveRequest(int requestId) async {
    try {
      final String myApi = "$baseUrl/auth/approve_request.php";
      final response = await http.post(
        Uri.parse(myApi),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'request_id': requestId}),
      );
      final jsonResponse = json.decode(response.body);
      if (response.statusCode == 200 && jsonResponse['status'] == '200') {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ombi limekubaliwa kikamilifu.')),
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

  Future<void> rejectRequest(int requestId) async {
    try {
      final String myApi = "$baseUrl/auth/reject_request.php";
      final response = await http.post(
        Uri.parse(myApi),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'request_id': requestId}),
      );
      final jsonResponse = json.decode(response.body);
      if (response.statusCode == 200 && jsonResponse['status'] == '200') {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ombi limekataliwa.')),
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

  Future<PendingRequestsResponse?> getUserPendingRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String myApi = "$baseUrl/auth/get_all_user_associated_by_user_id.php";
      final response = await http.post(
        Uri.parse(myApi),
        headers: {'Content-type': 'application/json'},
        body: json.encode({
          'user_id': userData!.user.id,
        }),
      );

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
          automaticallyImplyLeading: false,
          elevation: 0,
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
                          Padding(
                            padding: const EdgeInsets.only(left: 10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Maombi Yangu",
                                  style: TextStyle(
                                    color: const Color.fromARGB(255, 32, 21, 234).withValues(alpha: 0.8),
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        offset: const Offset(0, 2),
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
                                        offset: const Offset(0, 1),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickySearchHeaderDelegate(
            child: Container(
              color: primary,
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
                          "Inapakia maombi...",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : pendingRequests == null || pendingRequests!.data.isEmpty
                  ? SizedBox(
                      height: 300,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.clock, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              "Hakuna maombi yaliyopatikana.",
                              textAlign: TextAlign.center,
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
        const SliverToBoxAdapter(
          child: SizedBox(height: 20),
        ),
      ],
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
      final status = request.status.toLowerCase();
      final jumuiyaName = request.jumuiyaName.toLowerCase();
      final registeredBy = request.registeredBy.toLowerCase();

      return userName.contains(_searchQuery) ||
          userFullName.contains(_searchQuery) ||
          phone.contains(_searchQuery) ||
          status.contains(_searchQuery) ||
          jumuiyaName.contains(_searchQuery) ||
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
      width: double.infinity,
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

  Widget _buildRequestsList() {
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
                    // Header with name and status
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
                              colors: request.status == "PENDING"
                                  ? [Colors.orange[400]!, Colors.orange[600]!]
                                  : request.status == "APPROVED"
                                      ? [Colors.green[400]!, Colors.green[600]!]
                                      : [Colors.red[400]!, Colors.red[600]!],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            request.status,
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
                    Text(request.requestId.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        )),

                    // Request Info
                    _buildInfoRow(
                      icon: Icons.calendar_today,
                      label: "Tarehe ya kuomba",
                      value: request.associatedDate,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      icon: Icons.person_outline,
                      label: "Imeongozwa na",
                      value: request.registeredBy,
                      color: Colors.purple,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      icon: Icons.home,
                      label: "Jumuiya",
                      value: request.jumuiyaName,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      icon: Icons.phone,
                      label: "Simu",
                      value: request.phone,
                      color: Colors.teal,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      icon: Icons.location_on,
                      label: "Mahali anapoishi",
                      value: request.location,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      icon: Icons.person,
                      label: "Jinsia",
                      value: request.gender,
                      color: Colors.pink,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      icon: Icons.cake,
                      label: "Tarehe ya kuzaliwa",
                      value: request.dobdate,
                      color: Colors.indigo,
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

              // Action buttons (only for pending requests)
              if (request.status == "PENDING") ...[
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
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.check_circle,
                          label: "Kubali",
                          color: Colors.green,
                          onPressed: () => _showApprovalDialog(request),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.cancel,
                          label: "Kataa",
                          color: Colors.red,
                          onPressed: () => _showRejectionDialog(request),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showApprovalDialog(PendingRequest request) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24),
              const SizedBox(width: 8),
              const Text("Kubali Ombi"),
            ],
          ),
          content: Text(
            "Je, una uhakika unataka kukubali ombi la ${request.userFullName}?",
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Ghairi"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                approveRequest(request.requestId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text("Kubali"),
            ),
          ],
        );
      },
    );
  }

  void _showRejectionDialog(PendingRequest request) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.cancel, color: Colors.red, size: 24),
              const SizedBox(width: 8),
              const Text("Kataa Ombi"),
            ],
          ),
          content: Text(
            "Je, una uhakika unataka kukataa ombi la ${request.userFullName}?",
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Ghairi"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                rejectRequest(request.requestId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("Kataa"),
            ),
          ],
        );
      },
    );
  }
}

class _StickySearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickySearchHeaderDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 80.0; // Height when fully expanded

  @override
  double get minExtent => 80.0; // Height when collapsed

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
