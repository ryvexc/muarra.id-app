import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppSidebar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  bool expanded = true;

  static const Color sidebarColor = Color(0xFF111318);
  static const Color accentColor = Color(0xFF3B82F6);
  static const Color mutedColor = Color(0xFF858B98);
  static const Color selectedColor = Color(0xFF1D293D);

  final List<Map<String, dynamic>> menus = [
    {'title': 'Home', 'icon': Icons.grid_view_rounded},
    {'title': 'Users', 'icon': Icons.people_outline_rounded},
    {'title': 'Orders', 'icon': Icons.shopping_bag_outlined},
    {'title': 'Analytics', 'icon': Icons.bar_chart_rounded},
    {'title': 'Products', 'icon': Icons.inventory_2_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
      width: expanded ? 250 : 76,
      color: sidebarColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isExpanded = constraints.maxWidth >= 200;

          return Column(
            children: [
              const SizedBox(height: 28),

              _buildBrand(isExpanded),

              const SizedBox(height: 48),

              if (isExpanded)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'WORKSPACE',
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 14),

              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: isExpanded ? 12 : 6,
                  ),
                  itemCount: menus.length,
                  itemBuilder: (context, index) {
                    return _buildMenuItem(index, isExpanded);
                  },
                ),
              ),

              _buildBottomSection(isExpanded),
            ],
          );
        },
      ),
    );
  }

  // BRAND

  Widget _buildBrand(bool isExpanded) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isExpanded ? 22 : 0),
      child: SizedBox(
        width: double.infinity,
        child: Row(
          mainAxisAlignment: isExpanded
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.layers_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
            if (isExpanded) ...[
              const SizedBox(width: 12),
              const Flexible(
                child: Text(
                  'muarra',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // MENU ITEM
  Widget _buildMenuItem(int index, bool isExpanded) {
    final selected = widget.selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Tooltip(
        message: menus[index]['title'] as String,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => widget.onItemSelected(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 46,
            decoration: BoxDecoration(
              color: selected ? selectedColor : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 3,
                  height: selected ? 24 : 0,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: isExpanded
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.center,
                    children: [
                      if (isExpanded) const SizedBox(width: 12),
                      Icon(
                        menus[index]['icon'] as IconData,
                        size: 20,
                        color: selected ? accentColor : mutedColor,
                      ),
                      if (isExpanded) ...[
                        const SizedBox(width: 14),
                        Flexible(
                          child: Text(
                            menus[index]['title'] as String,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFFB0B5C0),
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // BOTTOM SECTION
  Widget _buildBottomSection(bool isExpanded) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isExpanded ? 12 : 4),
      child: Column(
        children: [
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 24),

          // Settings
          // Settings
          Builder(
            builder: (context) {
              final settingsIndex = menus.length; // 5
              final selected = widget.selectedIndex == settingsIndex;

              return Tooltip(
                message: 'Settings',
                child: InkWell(
                  onTap: () => widget.onItemSelected(settingsIndex),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected ? selectedColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: isExpanded
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.center,
                      children: [
                        if (isExpanded) const SizedBox(width: 12),
                        Icon(
                          Icons.settings_outlined,
                          color: selected ? accentColor : mutedColor,
                          size: 20,
                        ),
                        if (isExpanded) ...[
                          const SizedBox(width: 14),
                          Text(
                            'Settings',
                            style: TextStyle(
                              color: selected ? Colors.white : mutedColor,
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          _buildProfile(isExpanded),

          const SizedBox(height: 8),

          Align(
            alignment: isExpanded ? Alignment.centerRight : Alignment.center,
            child: IconButton(
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              onPressed: () {
                setState(() => expanded = !expanded);
              },
              tooltip: isExpanded ? 'Collapse' : 'Expand',
              icon: Icon(
                isExpanded
                    ? Icons.keyboard_double_arrow_left
                    : Icons.keyboard_double_arrow_right,
                color: mutedColor,
                size: 20,
              ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // PROFILE
  Widget _buildProfile(bool isExpanded) {
    return Container(
      padding: EdgeInsets.all(isExpanded ? 10 : 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: isExpanded
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 17,
            backgroundColor: Color(0xFF334155),
            child: Icon(Icons.person, color: Colors.white, size: 19),
          ),
          if (isExpanded) ...[
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Administrator',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'admin@muarra.id',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: mutedColor, fontSize: 9),
                  ),
                ],
              ),
            ),
            const Icon(Icons.more_vert, color: mutedColor, size: 18),
          ],
        ],
      ),
    );
  }
}
