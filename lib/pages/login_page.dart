import 'package:dcpjcspc_scr/pages/mainmenu_page.dart';
import 'package:dcpjcspc_scr/pages/register_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ฟังก์ชันสำหรับตรวจสอบข้อมูลล็อกอินจาก Firebase
  Future<void> _loginUser() async {
    final userIdCard = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (userIdCard.isEmpty || password.isEmpty) {
      _showErrorDialog('กรุณาใส่เลขบัตรประชาชนและรหัสผ่าน');
      return;
    }

    try {
      // ค้นหาผู้ใช้จาก Firebase Firestore ด้วย userIdCard
      log('Attempting login for userIdCard: $userIdCard');
      log('Password entered: $password');
      final userQuery = await FirebaseFirestore.instance
          .collection('user')
          .where('userIdCard', isEqualTo: userIdCard)
          .where('userPassword', isEqualTo: password)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        // ล็อกอินสำเร็จ
        _usernameController.clear();
        _passwordController.clear();
        final userData = userQuery.docs.first.data();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainmenuPage(userIdCard: userData['userIdCard']),
          ),
        );
      } else {
        // ไม่พบข้อมูลผู้ใช้
        _showErrorDialog('ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง');
      }
    } catch (e) {
      // เกิดข้อผิดพลาดในการเชื่อมต่อ
      _showErrorDialog('เกิดข้อผิดพลาดในการเชื่อมต่อ กรุณาลองใหม่อีกครั้ง');
    }
  }

  // ฟังก์ชันแสดงข้อความแจ้งเตือน
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('แจ้งเตือน'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ตกลง'),
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
            Padding(padding: EdgeInsets.symmetric(vertical: 10)),
            Image(image: NetworkImage('https://plus.unsplash.com/premium_photo-1682310215405-3f493a5fecde?q=80&w=3012&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D'),width: 150,height: 150, fit: BoxFit.cover,),
            const SizedBox(height: 50),
            Padding(padding: EdgeInsets.symmetric(horizontal: 30), child: TextField(
              controller: _usernameController,
              maxLength: 13,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(), 
                labelText: 'เลขบัตรประชาชน', 
                hintText: 'กรุณาใส่เลขบัตรประชาชน',
                counterText: ''
              ),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Password',
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
            ElevatedButton(onPressed: _loginUser,
            style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 90, vertical: 10),
                foregroundColor: Colors.white,
                backgroundColor: Colors.deepPurple.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ), 
            child: Text('ตกลง'),
            ),
            const SizedBox(height: 40),
            ElevatedButton(onPressed: () {
              _passwordController.clear();
              _usernameController.clear();
              Navigator.push(context, MaterialPageRoute<void>(builder: (context) => const RegisterPage(),),);
            },
            style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                foregroundColor: Colors.white,
                backgroundColor: Colors.deepPurple.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ), 
            child: Text('สมัครสมาชิก'),
            ),
          ],
        ),
      ),
    );
  }
}