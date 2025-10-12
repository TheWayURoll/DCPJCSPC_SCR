import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dcpjcspc_scr/classes/admin/admin_queue_edit.dart';

class AdminManagements extends StatefulWidget {
  const AdminManagements({super.key});

  @override
  State<AdminManagements> createState() => _AdminManagementsState();
}

class _AdminManagementsState extends State<AdminManagements> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('queueLists').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('ไม่มีรายการนัดหมาย', style: TextStyle(fontSize: 18)));
                  }
                  final docs = snapshot.data!.docs;
                  // จัดเรียงตามวันเวลา
                  docs.sort((a, b) {
                    final aDate = (a['queueDate'] as Timestamp).toDate();
                    final bDate = (b['queueDate'] as Timestamp).toDate();
                    return aDate.compareTo(bDate);
                  });
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final queueDate = (data['queueDate'] as Timestamp).toDate();
                      final dateStr = '${queueDate.day}/${queueDate.month}/${queueDate.year}';
                      final timeStr = '${queueDate.hour.toString().padLeft(2, '0')}:${queueDate.minute.toString().padLeft(2, '0')}';
                      final queueText = data['queueText'] ?? '';
                      final docId = data['queueDocList']?['docId'] ?? '';
                      final queueUserList = data['queueUserList'];
                      String userName = '';
                      String userIdCard = '';
                      if (queueUserList != null) {
                        if (queueUserList['userName'] != null) {
                          userName = queueUserList['userName'];
                        } else if (queueUserList['userIdCard'] is Map && queueUserList['userIdCard']['userName'] != null) {
                          userName = queueUserList['userIdCard']['userName'];
                        }
                        if (queueUserList['userIdCard'] != null && queueUserList['userIdCard'] is String) {
                          userIdCard = queueUserList['userIdCard'];
                        } else if (queueUserList['userIdCard'] is Map && queueUserList['userIdCard']['userIdCard'] != null) {
                          userIdCard = queueUserList['userIdCard']['userIdCard'];
                        }
                      }
                      return Center(
                        child: Container(
                          width: 350,
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD7D2DF),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(dateStr, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                              const SizedBox(height: 4),
                              Text('เวลา $timeStr', style: const TextStyle(fontSize: 18, color: Colors.black87)),
                              const SizedBox(height: 12),
                              FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance.collection('doctor').doc(docId).get(),
                                builder: (context, docSnap) {
                                  String doctorName = '';
                                  if (docSnap.hasData && docSnap.data!.exists) {
                                    doctorName = docSnap.data!['docName'] ?? '';
                                  }
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('นัดหมาย $doctorName :', style: const TextStyle(fontSize: 16, color: Colors.black87)),
                                      Text('($queueText) โดย $userName', style: const TextStyle(fontSize: 16, color: Colors.black87)),
                                      Text('เลขบัตรประชาชน: $userIdCard', style: const TextStyle(fontSize: 16, color: Colors.black87)),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('ยืนยันการลบคิว'),
                                          content: const Text('คุณต้องการยกเลิกคิวนี้ใช่หรือไม่?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(false),
                                              child: const Text('ยกเลิก'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(true),
                                              child: const Text('ลบ', style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await FirebaseFirestore.instance.collection('queueLists').doc(docs[index].id).delete();
                                        if (mounted) setState(() {});
                                      }
                                    },
                                    child: const Text('ยกเลิกคิว', style: TextStyle(color: Colors.red, fontSize: 16)),
                                  ),
                                  const SizedBox(width: 16),
                                  TextButton(
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AdminQueueEdit(queueDocId: docs[index].id),
                                        ),
                                      );
                                      if (result == true && mounted) {
                                        setState(() {});
                                      }
                                    },
                                    child: const Text('แก้ไขคิว', style: TextStyle(color: Color(0xFF6C5A8E), fontSize: 16)),
                                  ),
                                  const SizedBox(width: 16),
                                  TextButton(
                                    onPressed: () {
                                      // TODO: เพิ่มฟังก์ชันยอมรับคิว
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('อนุมัติคิวเรียบร้อยแล้ว'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    },
                                    child: const Text('อนุมัติ', style: TextStyle(color: Colors.green, fontSize: 16)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}