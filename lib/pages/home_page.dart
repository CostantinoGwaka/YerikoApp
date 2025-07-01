import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:yeriko_app/main.dart';
import 'package:yeriko_app/pages/admin_all_collection_users.dart';
import 'package:yeriko_app/pages/all_collection_users.dart';
import 'package:yeriko_app/pages/all_user_viewer.dart';
import 'package:yeriko_app/pages/church_time_table.dart';
import 'package:yeriko_app/pages/daily_page.dart';
import 'package:yeriko_app/pages/profile_user.dart';
import 'package:yeriko_app/theme/colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int pageIndex = 0;
  final int collectionPageIndex = 2;
  bool isFloatingClicked = false;

  List<Widget> get pages => [
        const DailyPage(), // index 0
        const ChurchTimeTable(), // index 1
        (userData != null && userData!.user.role == "ADMIN")
            ? AdminAllUserCollections()
            : AllUserCollections(), // index 2
        AllViewerUserWithAdmin(), // index 3
        const ProfilePage(), // index 4
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
