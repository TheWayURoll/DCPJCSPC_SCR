import 'package:dcpjcspc_scr/pages/login_page.dart';
import 'package:flutter/material.dart';

class MainscreenPage extends StatefulWidget {
  const MainscreenPage({super.key});

  @override
  State<MainscreenPage> createState() => _MainscreenPageState();
}

class _MainscreenPageState extends State<MainscreenPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image(image: NetworkImage('https://plus.unsplash.com/premium_photo-1682310215405-3f493a5fecde?q=80&w=3012&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D'),width: 150,height: 150, fit: BoxFit.cover,),
            const SizedBox(height: 30),
            Text('ยินดีต้อนรับสู่', style: TextStyle(fontWeight: FontWeight.bold,fontSize: 30.0),),
            Text('คลินิกปัญญาชล', style: TextStyle(fontWeight: FontWeight.bold,fontSize: 30.0),),
            const SizedBox(height: 20),
            Text('หากต้องการใช้บริการแอป', style: TextStyle(fontSize: 16.0),),
            Text('กรุณากด "ตกลง" เพื่อเข้าสู่ขั้นตอนถัดไป', style: TextStyle(fontSize: 16.0),),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () {
              Navigator.push(context,MaterialPageRoute<void>(builder: (context) => const LoginPage(),),);
            },
            style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 90, vertical: 10),
                foregroundColor: Colors.white,
                backgroundColor: Colors.deepPurple.shade400,
                shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              )
            ), 
            child: Text('ตกลง')),
          ],
        ),
      ),
    );
  }
}