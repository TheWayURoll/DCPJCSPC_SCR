import 'package:flutter/material.dart';
import 'package:dcpjcspc_scr/classes/doctor/doc_edit_profile.dart';

class DocSettings extends StatefulWidget {
  const DocSettings({super.key});

  @override
  State<DocSettings> createState() => _DocSettingsState();
}

class _DocSettingsState extends State<DocSettings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B3FA2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    label: const Text('กลับ', style: TextStyle(color: Colors.white)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildLargeButton(
                icon: Icons.person,
                label: 'จัดการข้อมูลหมอ',
                onPressed: () {
                  // รับ docId จาก arguments ของ Navigator
                  final docId = ModalRoute.of(context)?.settings.arguments as String?;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DocEditProfile(docId: docId),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildLargeButton(
                icon: Icons.cancel,
                label: 'เกี่ยวกับแอป',
                onPressed: () {
                  // TODO: ไปหน้าเกี่ยวกับแอป
                },
              ),
              const SizedBox(height: 16),
              _buildLargeButton(
                icon: Icons.report,
                label: 'รายงาน',
                onPressed: () {
                  // TODO: ไปหน้ารายงาน
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLargeButton({required IconData icon, required String label, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFB9A7C9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        elevation: 2,
        minimumSize: const Size.fromHeight(56),
      ),
      icon: Icon(icon, color: Colors.deepPurple, size: 28),
      label: Text(
        label,
        style: const TextStyle(fontSize: 20, color: Colors.deepPurple, fontWeight: FontWeight.w500),
      ),
      onPressed: onPressed,
    );
  }
}