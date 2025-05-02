import 'package:flutter/material.dart';

class NavigationRailWidget extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const NavigationRailWidget({
    super.key,
    required this.isExpanded,
    required this.onToggle,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isExpanded ? 230 : 88,
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: NavigationRail(
              extended: isExpanded,
              backgroundColor: Colors.transparent,
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              selectedIconTheme: const IconThemeData(
                color: Colors.deepPurple,
                size: 28,
              ),
              selectedLabelTextStyle: const TextStyle(
                color: Colors.deepPurple,
                fontWeight: FontWeight.w600,
              ),
              unselectedIconTheme: const IconThemeData(
                color: Colors.grey,
              ),
              unselectedLabelTextStyle: const TextStyle(
                color: Colors.grey,
              ),
              destinations: const [
                NavigationRailDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: Text("Home")),
                NavigationRailDestination(
                    icon: Icon(Icons.bar_chart_outlined),
                    selectedIcon: Icon(Icons.bar_chart),
                    label: Text("Reports")),
                NavigationRailDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: Text("Profile")),
                NavigationRailDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings),
                    label: Text("Settings")),
              ],
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  isExpanded ? Icons.arrow_back_ios : Icons.menu,
                  color: Colors.deepPurple[900],
                ),
                onPressed: onToggle,
                tooltip: 'Toggle Navigation',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
