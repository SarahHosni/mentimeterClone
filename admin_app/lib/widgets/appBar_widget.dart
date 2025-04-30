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
      backgroundColor: Colors.grey[400],
      title: Text(title, style: TextStyle(color: Colors.black)),
      leading: arrow
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: const Color.fromARGB(255, 3, 3, 3)),
              onPressed: () {
                Navigator.pushNamed(context, '/dashboard');
              },
            )
          : null, // No arrow if arrow == false
      actions: [
        IconButton(
          icon: Icon(Icons.exit_to_app, color: const Color.fromARGB(255, 0, 0, 0)),
          onPressed: onLogout,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
