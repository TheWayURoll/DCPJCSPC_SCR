import 'package:dcpjcspc_scr/pages/doctor/doc_accout_page.dart';
import 'package:dcpjcspc_scr/pages/doctor/doc_calwork_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DocmainmenuPage extends StatefulWidget {
  final String docId;
  const DocmainmenuPage({super.key, required this.docId});

  @override
  State<DocmainmenuPage> createState() => _DocmainmenuPageState();
}

class _DocmainmenuPageState extends State<DocmainmenuPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Tab 0: หน้าหลักหมอ
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMenuIcon(Icons.edit, 'จัดการคิว'),
                      _buildMenuIcon(Icons.notifications, 'ข่าวประชาสัมพันธ์'),
                      _buildMenuIcon(Icons.calendar_today, 'กิจกรรม'),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'รายการคิววันนี้',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('queueLists')
                          .where('queueDate', isGreaterThanOrEqualTo: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day))
                          .where('queueDate', isLessThan: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day + 1))
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Text('ยังไม่มีรายการคิววันนี้', style: TextStyle(color: Colors.black54));
                        }
                        final docs = snapshot.data!.docs;
                        return SingleChildScrollView(
                          child: Column(
                            children: docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final queueDate = (data['queueDate'] as Timestamp).toDate();
                              final dateStr = '${queueDate.day}/${queueDate.month}/${queueDate.year}';
                              final queueText = data['queueText'] ?? '';
                              final docId = data['queueDocList']?['docId'] ?? '';
                              // รองรับทั้งแบบ queueUserList: {userIdCard: 'xxx', userName: 'yyy'} และแบบ queueUserList: {userIdCard: {userName: 'yyy'}}
                              String userIdCard = '';
                              String? userNameFromQueue;
                              final queueUserList = data['queueUserList'];
                              if (queueUserList != null) {
                                if (queueUserList['userIdCard'] is String) {
                                  userIdCard = queueUserList['userIdCard'];
                                  userNameFromQueue = queueUserList['userName'] as String?;
                                } else if (queueUserList['userIdCard'] is Map) {
                                  // กรณี queueUserList: {userIdCard: {userName: ...}}
                                  final userMap = queueUserList['userIdCard'] as Map<String, dynamic>;
                                  userIdCard = data['queueUserList']?['userIdCard']?['userName'] ?? '';
                                  userNameFromQueue = userMap['userName'] as String?;
                                }
                              }
                              // ตรวจสอบและสร้าง user document หากยังไม่มี
                              Future<void> ensureUserDocument(String userIdCard) async {
                                final userDoc = await FirebaseFirestore.instance.collection('user').doc(userIdCard).get();
                                if (!userDoc.exists) {
                                  await FirebaseFirestore.instance.collection('user').doc(userIdCard).set({
                                    'userName': userIdCard,
                                  });
                                }
                              }
                              ensureUserDocument(userIdCard);
                              return Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.pink[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.pink[100]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dateStr,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 8),
                                    FutureBuilder<DocumentSnapshot>(
                                      future: FirebaseFirestore.instance.collection('doctor').doc(docId).get(),
                                      builder: (context, docSnap) {
                                        String doctorName = '';
                                        if (docSnap.hasData && docSnap.data!.exists) {
                                          doctorName = docSnap.data!['docName'] ?? '';
                                        }
                                        // ดึงชื่อจาก queueUserList ก่อน ถ้าไม่มีค่อย fallback ไป userIdCard
                    final userName = (userNameFromQueue != null && userNameFromQueue.trim().isNotEmpty)
                      ? userNameFromQueue
                      : userIdCard;
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'นัดหมาย $doctorName :',
                                              style: const TextStyle(color: Colors.black87, fontSize: 14),
                                            ),
                                            Text(
                                              '($queueText)',
                                              style: const TextStyle(color: Colors.black87, fontSize: 14),
                                            ),
                                            Text(
                                              'โดย $userName',
                                              style: const TextStyle(color: Colors.black87, fontSize: 14),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Tab 1: ตารางงาน (mock)
          DocCalworkPage(),
          // Tab 2: ประวัติการจอง (mock)
          SafeArea(child: Center(child: Text('ประวัติการจอง', style: TextStyle(fontSize: 24)))),
          // Tab 3: บัญชีหมอ
          DocAccoutPage(docId: widget.docId),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.purple.shade400,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'หน้าหลัก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'ตารางงาน',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'ประวัติการจอง',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'บัญชี',
          ),
        ],
      ),
    );
  }

  Widget _buildMenuIcon(IconData icon, String label) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 35,
            color: Colors.black87,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}