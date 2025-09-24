import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DocPersonalsPage extends StatelessWidget {
  const DocPersonalsPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const DocPersonals();
}

class DocPersonals extends StatelessWidget {
  const DocPersonals({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 16, left: 16, bottom: 16), // เพิ่ม bottom
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
        padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0), // เพิ่ม top
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('doctor').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('ไม่พบข้อมูลแพทย์'));
            }
            final docs = snapshot.data!.docs;
            return ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final name = doc['docName'] ?? '-';
                final specialty = doc['docDepart'] ?? '-';
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EFFF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD1C4E9)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFFD1C4E9),
                        radius: 28,
                        child: Text(
                          name.isNotEmpty ? name[0] : 'A',
                          style: const TextStyle(fontSize: 24, color: Color(0xFF5B3FA2), fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF222222)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              specialty,
                              style: const TextStyle(fontSize: 16, color: Color(0xFF5B3FA2)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}