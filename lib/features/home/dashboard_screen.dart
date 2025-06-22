import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:apprendi/services/local_storage_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? userName;
  String? userPhoto;
  bool isAdmin = false;
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await LocalStorageService.getUserData();

    if (userData != null) {
      setState(() {
        userName = userData['nama'];
        userPhoto = userData['image_profil'];
        isAdmin = userData['role'] == 'ADMIN';
        loaded = true;
      });
    } else {
      setState(() => loaded = true);
    }
  }

  void showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (ctx) => AlertDialog(
            title: const Center(
              child: Text(
                "Konfirmasi",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            content: const Text(
              "Apakah Anda yakin ingin keluar dari aplikasi?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () => _logout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Ya, Logout"),
              ),
            ],
          ),
    );
  }

  void _logout(BuildContext context) async {
    await LocalStorageService.clear();
    if (!context.mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final cards = <Widget>[
      _DashboardCard(
        title: 'Absensi',
        icon: Icons.check_circle,
        color: Colors.blue,
        onTap: () => context.go('/absensi'),
      ),
      _DashboardCard(
        title: 'Riwayat',
        icon: Icons.history,
        color: Colors.orange,
        onTap: () => context.go('/riwayat'),
      ),
      _DashboardCard(
        title: 'Statistik',
        icon: Icons.bar_chart,
        color: Colors.green,
        onTap: () => context.go('/statistik'),
      ),
    ];

    if (isAdmin) {
      cards.add(
        _DashboardCard(
          title: 'Report',
          icon: Icons.pie_chart,
          color: Colors.purple,
          onTap: () => context.go('/report'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text(""), automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Foto dan nama user
            Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[300],
                  backgroundImage:
                      (userPhoto != null && userPhoto!.isNotEmpty)
                          ? NetworkImage(userPhoto!)
                          : null,
                  child:
                      (userPhoto == null || userPhoto!.isEmpty)
                          ? const Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.white,
                          )
                          : null,
                ),
                const SizedBox(height: 12),
                Text(
                  'Halo, ${userName ?? '-'}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Card grid menu
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: cards,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => showLogoutDialog(context),
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.1),
              ),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
