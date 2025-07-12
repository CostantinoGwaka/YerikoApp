import 'package:flutter/material.dart';

class AppMaintanacePage extends StatefulWidget {
  const AppMaintanacePage({super.key});

  @override
  State<AppMaintanacePage> createState() => _AppMaintanacePageState();
}

class _AppMaintanacePageState extends State<AppMaintanacePage> {
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
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Image(
                    width: MediaQuery.of(context).size.height / 2,
                    height: MediaQuery.of(context).size.height / 5,
                    image: const AssetImage(
                      "assets/tool.png",
                    ),
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height / 20,
                ),
                Text(
                  "Jumuiya Yangu iko kwenye matengenezo",
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.height / 50,
                    fontFamily: "gotham_bold",
                    color: Colors.black,
                  ),
                )
              ],
            ),
            Positioned(
              right: 0,
              child: Padding(
                padding: EdgeInsets.only(right: MediaQuery.of(context).size.width / 20),
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
                              Text("Msaada"),
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
      ),
    );
  }
}
