import 'package:flutter/material.dart';
import 'package:dcpjcspc_scr/pages/personal_login_page.dart';


class AdminAccout extends StatefulWidget {
  final String? adminId;
  const AdminAccout({super.key, this.adminId});

  @override
  State<AdminAccout> createState() => _AdminAccoutState();
}

class _AdminAccoutState extends State<AdminAccout> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 32, left: 32, right: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextField(
                enabled: false,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  hintText: widget.adminId ?? 'Admin user ID',
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: ไปหน้า settings admin
                },
                icon: const Icon(Icons.settings, color: Color(0xFF6F5A7A)),
                label: const Text(
                  'ตั้งค่า',
                  style: TextStyle(color: Color(0xFF6F5A7A), fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFE6E0EC),
                  elevation: 2,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => PersonalLoginPage()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.arrow_back, color: Color(0xFF6F5A7A)),
                label: const Text(
                  'ออกจากระบบ',
                  style: TextStyle(color: Color(0xFF6F5A7A), fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFE6E0EC),
                  elevation: 2,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}