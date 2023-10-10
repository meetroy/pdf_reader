import 'package:flutter/material.dart';
import 'package:pdf_reader/recent_files.dart';

class DrawerHelper extends StatefulWidget {
  final VoidCallback onTap;

  const DrawerHelper({Key? key, required this.onTap}) : super(key: key);

  @override
  State<DrawerHelper> createState() => _DrawerHelperState();
}

class _DrawerHelperState extends State<DrawerHelper> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.65,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 108.0),
        child: Column(
          children: [
            ListTile(
              onTap: () {
                Navigator.pop(context, true);
              },
              leading: const Icon(Icons.home),
              title: const Text("Home"),
            ),
            const Divider(
              height: 3,
              thickness: 2,
            ),
            ListTile(
              onTap: widget.onTap,
              leading: const Icon(Icons.folder),
              title: const Text("From Storage"),
            ),
            const Divider(
              height: 3,
              thickness: 2,
            ),
            ListTile(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RecentFile(),
                    ));
              },
              leading: const Icon(Icons.refresh),
              title: const Text("Recent"),
            ),
            const Divider(
              height: 3,
              thickness: 2,
            ),
            const ListTile(
              leading: Icon(Icons.logout),
              title: Text("Logout"),
            ),
          ],
        ),
      ),
    );
  }
}
