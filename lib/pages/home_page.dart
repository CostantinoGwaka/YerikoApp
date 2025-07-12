import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jumuiya_yangu/main.dart';
import 'package:jumuiya_yangu/pages/admin_all_collection_users.dart';
import 'package:jumuiya_yangu/pages/all_collection_users.dart';
import 'package:jumuiya_yangu/pages/all_user_viewer.dart';
import 'package:jumuiya_yangu/pages/church_time_table.dart';
import 'package:jumuiya_yangu/pages/daily_page.dart';
import 'package:jumuiya_yangu/pages/profile_user.dart';
import 'package:jumuiya_yangu/pages/update/maintance_screen.dart';
import 'package:jumuiya_yangu/pages/update/update_screen.dart';
import 'package:jumuiya_yangu/theme/colors.dart';
import 'package:jumuiya_yangu/utils/global/global_setting.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int pageIndex = 0;
  final int collectionPageIndex = 2;
  bool isFloatingClicked = false;
  final GlobalProvider globalProvider = GlobalProvider();

  List<Widget> get pages => [
        const DailyPage(), // index 0
        const ChurchTimeTable(), // index 1
        (userData != null && userData!.user.role == "ADMIN")
            ? AdminAllUserCollections()
            : AllUserCollections(), // index 2
        AllViewerUserWithAdmin(), // index 3
        const ProfilePage(), // index 4
      ];

  Future<void> checkAppSettings() async {
    // internetGloabalCheck = await InternetConnection().hasInternetAccess;

    String message = await globalProvider.checkAppSettings();

    print(message);

    if (message == "UPDATE_NEEDED") {
      // ignore: use_build_context_synchronously
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const UpdateAvailablePage()),
        (Route<dynamic> route) => false,
      );
    } else if (message == "APP_MAINTENANCE") {
      // ignore: use_build_context_synchronously
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AppMaintanacePage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    checkAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: primary,
        body: getBody(),
        bottomNavigationBar: getFooter(),
        floatingActionButton: SafeArea(
          child: FloatingActionButton(
            onPressed: () {
              setTabs(3); // ✅ Go to the correct page
              setState(() {
                pageIndex = 3;
                isFloatingClicked = true;
              });
            },
            backgroundColor: buttoncolor,
            child: const Icon(
              Icons.people,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  Widget getBody() {
    return IndexedStack(
      index: pageIndex,
      children: pages,
    );
  }

  Widget getFooter() {
    List<IconData> iconItems = [
      CupertinoIcons.home,
      CupertinoIcons.location_circle,
      CupertinoIcons.money_dollar,
      CupertinoIcons.person,
    ];

    return AnimatedBottomNavigationBar.builder(
      backgroundColor: primary,
      itemCount: iconItems.length,
      tabBuilder: (int index, bool isActive) {
        return Container(
          decoration: isActive && !isFloatingClicked
              ? const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                )
              : null,
          padding: const EdgeInsets.all(8),
          child: Icon(
            iconItems[index],
            size: 25,
            color: isActive && !isFloatingClicked ? Colors.white : black.withAlpha((0.5 * 255).toInt()),
          ),
        );
      },
      splashColor: secondary,
      gapLocation: GapLocation.center,
      activeIndex: pageIndex == 4 && !isFloatingClicked ? 3 : pageIndex,
      notchSmoothness: NotchSmoothness.softEdge,
      leftCornerRadius: 10,
      rightCornerRadius: 10,
      elevation: 2,
      onTap: (index) {
        // Adjust for extra center FAB
        if (index == 3) {
          setTabs(4);
        } else {
          setTabs(index);
        }
        setState(() {
          isFloatingClicked = false;
        });
      },
    );
  }

  void setTabs(int index) {
    setState(() {
      pageIndex = index;
    });
  }
}
