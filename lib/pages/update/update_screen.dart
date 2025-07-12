import 'package:flutter/material.dart';
import 'package:open_store/open_store.dart';

class UpdateAvailablePage extends StatefulWidget {
  const UpdateAvailablePage({super.key});

  @override
  State<UpdateAvailablePage> createState() => _UpdateAvailablePageState();
}

class _UpdateAvailablePageState extends State<UpdateAvailablePage> {
  @override
  void initState() {
    super.initState();
  }

  Widget _buildStep(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontFamily: "gotham_bold",
        color: Colors.black54,
      ),
    );
  }

  Widget _buildSubStep(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: "gotham_bold",
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.white,
        size: 28,
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.white,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 18,
        color: Colors.white,
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height / 10,
                left: MediaQuery.of(context).size.width / 10,
                right: MediaQuery.of(context).size.width / 10,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Sasisho Jipya la Jumuiya Yangu Linapatikana",
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: "gotham_bold",
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  const Padding(
                    padding: EdgeInsets.only(right: 20),
                    child: Text(
                      "Sasisho jipya linapatikana! Tafadhali sasisha hadi toleo jipya ili kupata huduma bora zaidi.",
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: "gotham_bold",
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Kama sasisho halijasanikishwa moja kwa moja, fuata hatua hizi:",
                          style: TextStyle(
                            fontSize: 15,
                            fontFamily: "gotham_bold",
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        _buildStep("1. Ondoa toleo la zamani"),
                        _buildSubStep("• Kwa Android: Nenda kwenye Mipangilio > Programu > [Jina la App] > Ondoa."),
                        _buildSubStep("• Kwa iOS: Bonyeza na ushikilie ikoni ya app, kisha chagua Futa App."),
                        const SizedBox(height: 10),
                        _buildStep("2. Pakua toleo jipya"),
                        _buildSubStep(
                            "• Kwa Android: Fungua Google Play Store, tafuta [Jina la App], kisha bonyeza Sakinisha."),
                        _buildSubStep("• Kwa iOS: Fungua App Store, tafuta [Jina la App], kisha bonyeza Pata."),
                        const SizedBox(height: 10),
                        _buildStep("3. Fungua app na ingia ili kuendelea kutumia huduma mpya."),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  SizedBox(
                    width: 150,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: () {
                        OpenStore.instance.open(
                          appStoreId: '6748091565',
                          androidAppBundleId: 'com.isoftzt.jumuiya_yangu',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // <-- Radius
                        ),
                      ),
                      child: const Text('Sasisha Sasa'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: Padding(
              padding: const EdgeInsets.only(right: 26, bottom: 20),
              child: PopupMenuButton(
                color: Colors.white,
                child: Row(
                  children: [
                    const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white,
                    ),
                    Card(
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                          color: Colors.white70,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: ClipOval(
                        child: Container(
                          color: Colors.white,
                          child: const Image(
                            fit: BoxFit.contain,
                            width: 40.0,
                            height: 40.0,
                            image: AssetImage('assets/appicon.png'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                itemBuilder: (context) {
                  return [
                    const PopupMenuItem(
                        value: 'help',
                        child: Row(
                          children: [
                            Icon(
                              Icons.help_outline_rounded,
                              size: 25,
                              color: Colors.black,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text("Msaada")
                          ],
                        )),
                  ];
                },
                onSelected: (value) async {
                  if (value == "help") {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) {
                        return DraggableScrollableSheet(
                          expand: false,
                          initialChildSize: 1, // Default height: 60% of the screen
                          minChildSize: 0.4, // Minimum height when dragged down
                          maxChildSize: 1, // Maximum height when dragged up
                          builder: (context, scrollController) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              child: Column(
                                children: [
                                  // Drag handle
                                  Container(
                                    width: 50,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[400],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // Title Row (Title + Close Button)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  // List of details
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Title
                                        const Text(
                                          "Get in Touch",
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 15),

                                        // Contact Options
                                        _buildContactItem(
                                          icon: Icons.email,
                                          label: "Barua pepe",
                                          value: "jumuiyayangu@gmail.com",
                                          onTap: () => {},
                                        ),
                                        const Divider(),
                                        _buildContactItem(
                                          icon: Icons.phone,
                                          label: "Namba ya Simu",
                                          value: "+255 659 515 042",
                                          onTap: () => {},
                                        ),
                                        const Divider(),
                                        _buildContactItem(
                                          icon: Icons.web,
                                          label: "Tovuti",
                                          value: "www.jumuiyayangu.com",
                                          onTap: () => {},
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
                    );
                  }
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
