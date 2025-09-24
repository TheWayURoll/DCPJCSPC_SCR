import 'package:dcpjcspc_scr/pages/login_page.dart';
import 'package:dcpjcspc_scr/pages/mainmenu_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _obscurePassword = true;
  final TextEditingController _idCardController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
  _idCardController.dispose();
  _nameController.dispose();
  _phoneController.dispose();
  _passwordController.dispose();
    super.dispose();
  }

  // ฟังก์ชันสำหรับตรวจสอบและบันทึกข้อมูลใหม่
  Future<void> _registerUser() async {
    final idCard = _idCardController.text.trim();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
  // ไม่มี username แล้ว
    final password = _passwordController.text.trim();

    // ตรวจสอบข้อมูลที่กรอก
    if (idCard.isEmpty || name.isEmpty || phone.isEmpty || password.isEmpty) {
      _showErrorDialog('กรุณากรอกข้อมูลให้ครบถ้วน');
      return;
    }

    if (idCard.length != 13) {
      _showErrorDialog('เลขบัตรประชาชนต้องมี 13 หลัก');
      return;
    }

    if (phone.length != 10) {
      _showErrorDialog('เบอร์โทรศัพท์ต้องมี 10 หลัก');
      return;
    }

    try {
      // ตรวจสอบว่า username ซ้ำหรือไม่โดยเช็คข้อมูลภายใน document
      final userCollection = await FirebaseFirestore.instance
          .collection('user')
          .get();

      // เช็คว่ามี userId ซ้ำกับที่มีอยู่แล้วไหม
      bool idCardExists = false;
      for (var doc in userCollection.docs) {
        final data = doc.data();
        if (data['userIdCard'] == idCard) {
          idCardExists = true;
        }
      }
      if (idCardExists) {
        _showErrorDialog('เลขบัตรประชาชนนี้ถูกลงทะเบียนแล้ว');
        return;
      }

      // หา document ID ใหม่ที่ไม่ซ้ำกับที่มีอยู่แล้ว
      String newDocumentId;
      int nextUserNumber = 1;
      
      // สร้าง list ของ document ID ที่มีอยู่แล้ว
      Set<String> existingDocumentIds = userCollection.docs.map((doc) => doc.id).toSet();
      
      // หา userX ที่ยังไม่มี
      while (true) {
        newDocumentId = 'user$nextUserNumber';
        if (!existingDocumentIds.contains(newDocumentId)) {
          break; // พบ document ID ที่ไม่ซ้ำ
        }
        nextUserNumber++;
      }

      // บันทึกข้อมูลใหม่ไปยัง Firebase โดยใช้ userX เป็นชื่อ document
      await FirebaseFirestore.instance.collection('user').doc(newDocumentId).set({
        'userIdCard': idCard,
        'userName': name,
        'userPhoneNumber': phone,
        'userPassword': password,
      });

      print('Created new user document: $newDocumentId');

      // แสดงข้อความสำเร็จและเข้าสู่ระบบทันที
      _showSuccessDialog('ลงทะเบียนสำเร็จ! กำลังเข้าสู่ระบบ...');
      
      // รอ 1.5 วินาที แล้วไปหน้า MainMenu
      await Future.delayed(Duration(milliseconds: 1500));
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainmenuPage(userIdCard: idCard),
          ),
        );
      }

    } catch (e) {
      print('Error during registration: $e');
      _showErrorDialog('เกิดข้อผิดพลาดในการลงทะเบียน กรุณาลองใหม่อีกครั้ง');
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

  // ฟังก์ชันแสดงข้อความสำเร็จ
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('สำเร็จ'),
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(child: Text(message)),
            ],
          ),
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
            Padding(padding: EdgeInsets.symmetric(vertical: 5)),
            Image(image: NetworkImage('https://plus.unsplash.com/premium_photo-1682310215405-3f493a5fecde?q=80&w=3012&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D'),width: 150,height: 150, fit: BoxFit.cover,),
            const SizedBox(height: 30),
            Padding(padding: EdgeInsets.symmetric(horizontal: 30), child: TextField(
              maxLength: 13,
              keyboardType: TextInputType.number,
              controller: _idCardController,
              decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'เลขบัตรประชาชน', counterText: '', hintText: 'กรุณาใส่เลขบัตรประชาชน 13 หลัก'),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(padding: EdgeInsets.symmetric(horizontal: 30), child: TextField(
              controller: _nameController,
              decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'ชื่อ-นามสกุล', hintText: 'กรุณาใส่ชื่อ-นามสกุล'),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[ก-๙a-zA-Z\s]')),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(padding: EdgeInsets.symmetric(horizontal: 30), child: TextField(
              controller: _phoneController,  
              decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'เบอร์โทรศัพท์', counterText: '', hintText: 'กรุณาใส่เบอร์โทรศัพท์ 10 หลัก'),
              keyboardType: TextInputType.number,
              maxLength: 10,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // ...ช่อง Username ถูกลบออก...
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
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _registerUser,
            style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 90, vertical: 10),
                foregroundColor: Colors.white,
                backgroundColor: Colors.deepPurple.shade400,
                shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              )
            ), 
            child: Text('ตกลง')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () {
              _idCardController.clear();
              _nameController.clear();
              _phoneController.clear();
              _passwordController.clear();
              Navigator.pop(context, MaterialPageRoute<void>(builder: (context) => const LoginPage(),),);
            },
            style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 90, vertical: 10),
                foregroundColor: Colors.white,
                backgroundColor: Colors.deepPurple.shade400,
                shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              )
            ), 
            child: Text('ยกเลิก')),
          ],
        ),
      ),
    );
  }
}