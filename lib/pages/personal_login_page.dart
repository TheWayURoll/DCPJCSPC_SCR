import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dcpjcspc_scr/pages/doctor/docmainmenu_page.dart';
import 'package:dcpjcspc_scr/pages/admin/adminmainmenu_page.dart';

class PersonalLoginPage extends StatefulWidget {
  const PersonalLoginPage({super.key});

  @override
  State<PersonalLoginPage> createState() => _PersonalLoginPageState();
}

class _PersonalLoginPageState extends State<PersonalLoginPage> {
  bool _obscurePassword = true;
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _loginPersonal() async {
    final id = _idController.text.trim();
    final password = _passwordController.text.trim();
    if (id.isEmpty || password.isEmpty) {
      _showErrorDialog('กรุณากรอก ID และรหัสผ่าน');
      return;
    }
    try {
      // ตรวจสอบว่ามี ID ใน doctor หรือไม่
      final doctorIdQuery = await FirebaseFirestore.instance
          .collection('doctor')
          .where('docId', isEqualTo: id)
          .limit(1)
          .get();
      // ตรวจสอบว่ามี ID ใน admin หรือไม่
      final adminIdQuery = await FirebaseFirestore.instance
          .collection('admin')
          .where('adminId', isEqualTo: id)
          .limit(1)
          .get();
      if (doctorIdQuery.docs.isEmpty && adminIdQuery.docs.isEmpty) {
        _showErrorDialog('ไม่พบข้อมูลหรือไม่มีผู้ใช้บัญชี ID นี้');
        return;
      }
      // ตรวจสอบหมอ (ID + password)
      final doctorQuery = await FirebaseFirestore.instance
          .collection('doctor')
          .where('docId', isEqualTo: id)
          .where('docPassword', isEqualTo: password)
          .limit(1)
          .get();
      if (doctorQuery.docs.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DocmainmenuPage()),
        );
        return;
      }
      // ตรวจสอบแอดมิน (ID + password)
      final adminQuery = await FirebaseFirestore.instance
          .collection('admin')
          .where('adminId', isEqualTo: id)
          .where('adminPassword', isEqualTo: password)
          .limit(1)
          .get();
      if (adminQuery.docs.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminmainmenuPage()),
        );
        return;
      }
      _showErrorDialog('ID หรือรหัสผ่านไม่ถูกต้อง');
    } catch (e) {
      _showErrorDialog('เกิดข้อผิดพลาด กรุณาลองใหม่');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('แจ้งเตือน'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ตกลง'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Image(
              image: NetworkImage('https://plus.unsplash.com/premium_photo-1682310215405-3f493a5fecde?q=80&w=3012&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D'),
              width: 150,
              height: 150,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: TextField(
                controller: _idController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'กรุณาใส่ ID ของคุณ',
                  hintText: 'กรุณาใส่ ID ของคุณ',
                ),
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'กรุณาใส่รหัสผ่าน',
                  hintText: 'กรุณาใส่รหัสผ่าน',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _loginPersonal,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 90, vertical: 10),
                foregroundColor: Colors.white,
                backgroundColor: Colors.deepPurple.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('ตกลง'),
            ),
          ],
        ),
      ),
    );
  }
}