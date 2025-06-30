import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:yeriko_app/main.dart';
import 'package:yeriko_app/pages/admin_all_collection_users.dart';
import 'package:yeriko_app/pages/all_collection_users.dart';
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

  List<Widget> pages = [
    const DailyPage(),
    const ChurchTimeTable(),
    (userData != null && userData!.user.role == "ADMIN") ? AdminAllUserCollections() : AllUserCollections(),
    ProfilePage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primary,
      body: getBody(),
      bottomNavigationBar: getFooter(),
      floatingActionButton: SafeArea(
        child: SizedBox(
          // height: 30,
          // width: 40,
          child: FloatingActionButton(
            onPressed: () {
              setState(() {
                pageIndex = 3;
              });
            },
            backgroundColor: buttoncolor,
            child: Icon(
              Icons.people,
              color: Colors.white,
              size: 20,
            ),
            // shape:
            //     BeveledRectangleBorder(borderRadius: BorderRadius.circular(4)),
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
    return AnimatedBottomNavigationBar(
        backgroundColor: primary,
        icons: iconItems,
        splashColor: secondary,
        inactiveColor: black.withValues(alpha: 0.5),
        gapLocation: GapLocation.center,
        activeIndex: pageIndex,
        notchSmoothness: NotchSmoothness.softEdge,
        leftCornerRadius: 10,
        iconSize: 25,
        rightCornerRadius: 10,
        elevation: 2,
        onTap: (index) {
          setTabs(index);
        });
  }

  // ignore: strict_top_level_inference
  void setTabs(index) {
    setState(() {
      pageIndex = index;
    });
  }
}
