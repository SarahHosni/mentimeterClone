import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onLogout;
  final bool arrow;

  const CustomAppBar({
    Key? key,
    required this.title,
    required this.onLogout,
    required this.arrow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.deepPurple,
      elevation: 4,
      automaticallyImplyLeading: false,
      leading: arrow
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              tooltip: 'Back',
              onPressed: () {
                Navigator.pushNamed(context, '/dashboard');
              },
            )
          : null,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          tooltip: 'Logout',
          onPressed: onLogout,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
