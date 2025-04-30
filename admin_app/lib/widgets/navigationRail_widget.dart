import 'package:flutter/material.dart';

class NavigationRailWidget extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const NavigationRailWidget({
    Key? key,
    required this.isExpanded,
    required this.onToggle,
    required this.selectedIndex,
    required this.onDestinationSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isExpanded ? 230 : 90,
      color: Colors.grey[350],
      child: Stack(
        children: [
          // NavigationRail itself, with top padding to make space for the toggle button
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: NavigationRail(
              extended: isExpanded,
              backgroundColor: Colors.grey[350],
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              unselectedIconTheme: const IconThemeData(color: Colors.grey),
              unselectedLabelTextStyle: const TextStyle(color: Colors.grey),
              selectedIconTheme: const IconThemeData(
                color: Color.fromARGB(255, 0, 0, 0),
              ),
              selectedLabelTextStyle: const TextStyle(
                color: Color.fromARGB(255, 0, 0, 0),
              ),
              destinations: const [
                NavigationRailDestination(
                    icon: Icon(Icons.home), label: Text("Home")),
                NavigationRailDestination(
                    icon: Icon(Icons.bar_chart), label: Text("Reports")),
                NavigationRailDestination(
                    icon: Icon(Icons.person), label: Text("Profile")),
                NavigationRailDestination(
                    icon: Icon(Icons.settings), label: Text("Settings")),
              ],
            ),
          ),

          // Menu toggle button at top-left corner
          Positioned(
            top: 10,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.menu, color: Color.fromARGB(255, 0, 0, 0)),
              onPressed: onToggle,
              tooltip: 'Toggle Navigation',
            ),
          ),
        ],
      ),
    );
  }
}
