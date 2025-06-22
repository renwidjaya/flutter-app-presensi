import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:apprendi/services/local_storage_service.dart';

class BottomNav extends StatefulWidget {
  final int currentIndex;
  const BottomNav({super.key, required this.currentIndex});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  bool isAdmin = false;
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadRole);
  }

  Future<void> _loadRole() async {
    final user = await LocalStorageService.getUserData();
    final role = user?['role']?.toString().toUpperCase();
    if (role == 'ADMIN') {
      isAdmin = true;
    }
    setState(() => loaded = true);
  }

  void _onItemTapped(BuildContext context, int idx) {
    final routes = [
      '/dashboard',
      '/riwayat',
      '/statistik',
      if (isAdmin) '/report',
    ];
    if (idx < routes.length) {
      context.go(routes[idx], extra: {'transition': 'fade'});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) return const SizedBox(height: 56);

    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.home),
        activeIcon: Icon(CupertinoIcons.house_fill),
        label: 'Home',
      ),
      const BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.time),
        activeIcon: Icon(CupertinoIcons.time_solid),
        label: 'Riwayat',
      ),
      const BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.chart_bar),
        activeIcon: Icon(CupertinoIcons.chart_bar_alt_fill),
        label: 'Statistik',
      ),
      if (isAdmin)
        const BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.chart_pie),
          activeIcon: Icon(CupertinoIcons.chart_pie_fill),
          label: 'Report',
        ),
    ];

    final idx = widget.currentIndex < items.length ? widget.currentIndex : 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -1),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        child: BottomNavigationBar(
          currentIndex: idx,
          onTap: (i) => _onItemTapped(context, i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.blue.shade700,
          unselectedItemColor: Colors.grey.shade500,
          backgroundColor: Colors.white,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: items,
        ),
      ),
    );
  }
}
