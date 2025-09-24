import 'package:dcpjcspc_scr/pages/historylist_page.dart';
import 'package:flutter/material.dart';
import 'package:dcpjcspc_scr/pages/accouts_page.dart';
import 'package:dcpjcspc_scr/pages/queuemenu_page.dart';
import 'package:dcpjcspc_scr/classes/doc_personals.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dcpjcspc_scr/classes/user_queue_edit.dart';
import 'dart:async';

class MainmenuPage extends StatefulWidget {
  final String userIdCard;
  const MainmenuPage({Key? key, required this.userIdCard}) : super(key: key);

  @override
  State<MainmenuPage> createState() => _MainmenuPageState();
}

// --- StatefulWidget สำหรับรูปภาพ 3 รูปด้านบน ---
class _ImageCarousel extends StatefulWidget {
  const _ImageCarousel({Key? key}) : super(key: key);

  @override
  _ImageCarouselState createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  late PageController _pageController;
  late Timer _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentPage < 2) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      onPageChanged: (int page) {
        setState(() {
          _currentPage = page;
        });
      },
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image, size: 50, color: Colors.grey[600]),
                Text('รูปภาพ 1', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: Colors.blue[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image, size: 50, color: Colors.blue[600]),
                Text('รูปภาพ 2', style: TextStyle(color: Colors.blue[600])),
              ],
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: Colors.green[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image, size: 50, color: Colors.green[600]),
                Text('รูปภาพ 3', style: TextStyle(color: Colors.green[600])),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MainmenuPageState extends State<MainmenuPage> {

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
          // หน้าหลัก
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ...existing code for main page...
                  SizedBox(
                    height: 200,
                    child: _ImageCarousel(),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMenuIcon(Icons.calendar_today, 'กิจกรรม'),
                      _buildMenuIcon(Icons.notifications, 'ข่าวประชา\nสัมพันธ์'),
                      _buildMenuIcon(Icons.people, 'บุคลากร'),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'กิจกรรมของท่าน',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 15),
                  // ...แทนที่ Container สีชมพูเดิมด้วย StreamBuilder...
                  SizedBox(
                    height: 350, // หรือปรับตามต้องการ
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('queueLists')
                          .where('queueUserList.userIdCard', isEqualTo: widget.userIdCard)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Text('ยังไม่มีรายการนัดหมาย', style: TextStyle(color: Colors.black54));
                        }
                        final docs = snapshot.data!.docs;
                        return SingleChildScrollView(
                          child: Column(
                            children: docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final queueDate = (data['queueDate'] as Timestamp).toDate();
                              final dateStr = '${queueDate.day}/${queueDate.month}/${queueDate.year}';
                              final timeStr = '${queueDate.hour.toString().padLeft(2, '0')}:${queueDate.minute.toString().padLeft(2, '0')}';
                              final queueText = data['queueText'] ?? '';
                              final docId = data['queueDocList']?['docId'] ?? '';
                              return Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.pink[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.pink[100]!),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$dateStr $timeStr',
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
                                              return Text(
                                                'นัดหมาย $doctorName :\n($queueText)',
                                                style: const TextStyle(color: Colors.black87, fontSize: 14),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.black54),
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => UserQueueEdit(
                                              queueDocId: doc.id,
                                              userIdCard: widget.userIdCard,
                                            ),
                                          ),
                                        );
                                        if (result == true) setState(() {});
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () async {
                                        await FirebaseFirestore.instance.collection('queueLists').doc(doc.id).delete();
                                        setState(() {});
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
                  const Spacer(),
                ],
              ),
            ),
          ),
          // Tab 1: จองคิว (queue menu)
          QueueMenuPage(userIdCard: widget.userIdCard),
          // Tab 2: ประวัติการจอง (history list)
          HistoryListPage(userIdCard: widget.userIdCard),
          // Tab 3: บัญชี
          AccoutsPage(userIdCard: widget.userIdCard),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue.shade400,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'หน้าหลัก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'จองคิว',
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
    return GestureDetector(
      onTap: () {
        if (label == 'บุคลากร') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DocPersonalsPage()),
          );
        }
      },
      child: Container(
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
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}