import 'package:flutter/material.dart';
import 'package:muarra_app_v1/pages/discount_page.dart';
import 'package:muarra_app_v1/pages/menu_page.dart';
import 'package:muarra_app_v1/pages/order_page.dart';
import 'package:muarra_app_v1/pages/settings_page.dart';
import 'package:muarra_app_v1/widgets/app_sidebar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  final List<Widget> pages = [
    MenuPage(),
    DiscountsPage(),
    OrdersPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: true,
        left: false,
        right: false,
        child: Row(
          children: [
            // Sidebar
            AppSidebar(
              selectedIndex: selectedIndex,
              onItemSelected: (index) {
                setState(() {
                  selectedIndex = index;
                });
              },
            ),

            // Main content
            Expanded(
              child: Container(
                color: const Color(0xFFF3F4F6),
                child: pages[selectedIndex],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
