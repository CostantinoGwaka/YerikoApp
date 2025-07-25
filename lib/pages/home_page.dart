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

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int pageIndex = 0;
  final int collectionPageIndex = 2;
  bool isFloatingClicked = false;
  final GlobalProvider globalProvider = GlobalProvider();
  late AnimationController _fabAnimationController;
  late AnimationController _borderRadiusAnimationController;
  late Animation<double> _fabAnimation;
  late Animation<double> borderRadiusAnimation;
  late CurvedAnimation _fabCurve;
  late CurvedAnimation borderRadiusCurve;

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
  void initState() {
    super.initState();
    // checkAppSettings();

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _borderRadiusAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fabCurve = CurvedAnimation(
      parent: _fabAnimationController,
      curve: const Interval(0.5, 1.0, curve: Curves.fastOutSlowIn),
    );
    borderRadiusCurve = CurvedAnimation(
      parent: _borderRadiusAnimationController,
      curve: const Interval(0.5, 1.0, curve: Curves.fastOutSlowIn),
    );

    _fabAnimation = Tween<double>(begin: 0, end: 1).animate(_fabCurve);
    borderRadiusAnimation = Tween<double>(begin: 0, end: 1).animate(borderRadiusCurve);

    Future.delayed(
      const Duration(seconds: 1),
      () => _fabAnimationController.forward(),
    );
    Future.delayed(
      const Duration(seconds: 1),
      () => _borderRadiusAnimationController.forward(),
    );
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _borderRadiusAnimationController.dispose();
    super.dispose();
  }

  Future<void> checkAppSettings() async {
    // internetGloabalCheck = await InternetConnection().hasInternetAccess;

    String message = await globalProvider.checkAppSettings();

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
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: getBody(),
        bottomNavigationBar: getFooter(),
        floatingActionButton: AnimatedBuilder(
          animation: _fabAnimation,
          builder: (context, child) => Transform.scale(
            scale: _fabAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: mainFontColor.withValues(alpha: 0.3),
                    spreadRadius: 2,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () {
                  setTabs(3);
                  setState(() {
                    pageIndex = 3;
                    isFloatingClicked = true;
                  });
                },
                backgroundColor: mainFontColor,
                elevation: 0,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        mainFontColor,
                        mainFontColor.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.people_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
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
      CupertinoIcons.calendar,
      CupertinoIcons.money_dollar_circle,
      CupertinoIcons.person_circle,
    ];

    List<String> labels = [
      'Nyumbani',
      'Ratiba',
      'Michango',
      'Wasifu',
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: AnimatedBottomNavigationBar.builder(
        backgroundColor: Colors.transparent,
        itemCount: iconItems.length,
        tabBuilder: (int index, bool isActive) {
          final bool isCurrentActive = isActive && !isFloatingClicked;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: EdgeInsets.all(isCurrentActive ? 8 : 6),
                  decoration: BoxDecoration(
                    color: isCurrentActive ? mainFontColor.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    iconItems[index],
                    size: isCurrentActive ? 26 : 24,
                    color: isCurrentActive ? mainFontColor : Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    fontSize: isCurrentActive ? 12 : 11,
                    fontWeight: isCurrentActive ? FontWeight.w600 : FontWeight.w500,
                    color: isCurrentActive ? mainFontColor : Colors.grey[500],
                  ),
                  child: Text(labels[index]),
                ),
              ],
            ),
          );
        },
        splashColor: mainFontColor.withValues(alpha: 0.1),
        gapLocation: GapLocation.center,
        activeIndex: pageIndex == 4 && !isFloatingClicked ? 3 : pageIndex,
        notchSmoothness: NotchSmoothness.softEdge,
        leftCornerRadius: 20,
        rightCornerRadius: 20,
        elevation: 0,
        height: 80,
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
      ),
    );
  }

  void setTabs(int index) {
    setState(() {
      pageIndex = index;
    });
  }
}
