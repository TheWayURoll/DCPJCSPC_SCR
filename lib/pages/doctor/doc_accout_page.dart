import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DocAccoutPage extends StatefulWidget {
  final String docId;
  const DocAccoutPage({super.key, required this.docId});

  @override
  State<DocAccoutPage> createState() => _DocAccoutPageState();
}

class _DocAccoutPageState extends State<DocAccoutPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 32, left: 32, right: 32),
          child: FutureBuilder(
            future: FirebaseFirestore.instance.collection('doctor').doc(widget.docId).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text('ไม่พบข้อมูลบัญชีหมอ'));
              }
              final data = snapshot.data!.data() as Map<String, dynamic>;
              final docName = (data['docName'] ?? '').toString();
              final docDepartment = (data['docDepart'] ?? '').toString();
              final imageUrl = (data['docProfileUrl'] ?? 'https://img.freepik.com/free-vector/doctor-character-background_1270-84.jpg').toString();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundImage: NetworkImage(imageUrl),
                    backgroundColor: Colors.grey[200],
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    enabled: false,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      hintText: docName,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    enabled: false,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      hintText: docDepartment,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: ไปหน้าตั้งค่า
                    },
                    icon: const Icon(Icons.settings, color: Colors.black54),
                    label: const Text(
                      'ตั้งค่า',
                      style: TextStyle(color: Colors.black87, fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple[100],
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
                      // TODO: ออกจากระบบ
                    },
                    icon: const Icon(Icons.arrow_back, color: Colors.deepPurple),
                    label: const Text(
                      'ออกจากระบบ',
                      style: TextStyle(color: Colors.deepPurple, fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple[50],
                      elevation: 2,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}