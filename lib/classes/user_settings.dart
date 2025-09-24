import 'package:flutter/material.dart';
import 'package:dcpjcspc_scr/classes/user_edit_profile.dart'; // Import the UserEditProfile page

class UserSettings extends StatefulWidget {
  const UserSettings({super.key});

  @override
  State<UserSettings> createState() => _UserSettingsState();
}

class _UserSettingsState extends State<UserSettings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 16, left: 16, bottom: 16),
            child: Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B3FA2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 8,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  label: const Text('กลับ', style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildSettingsButton(Icons.person, 'จัดการบัญชีผู้ใช้'),
            const SizedBox(height: 16),
            _buildSettingsButton(Icons.star, 'เกี่ยวกับแอป'),
            const SizedBox(height: 16),
            _buildSettingsButton(Icons.error, 'รายงาน'),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsButton(IconData icon, String label) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE7DEF4),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (label == 'จัดการบัญชีผู้ใช้') {
              final userIdCard = ModalRoute.of(context)?.settings.arguments as String?;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserEditProfile(userIdCard: userIdCard),
                ),
              ).then((value) {
                if (value == true) {
                  Navigator.pop(context, true); // ส่งค่า true กลับไป accouts_page เพื่อรีเฟรช
                }
              });
            }
            // TODO: Add navigation or action for other buttons
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            child: Row(
              children: [
                Icon(icon, color: Color(0xFF5B3FA2), size: 28),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF5B3FA2),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}