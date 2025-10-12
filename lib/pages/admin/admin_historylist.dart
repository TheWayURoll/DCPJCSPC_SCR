import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminHistorylist extends StatelessWidget {
  const AdminHistorylist({super.key});
  
  get userIdCard => null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'ประวัติการจองคิว',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.grey[100],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('queueLists')
              .orderBy('queueDate', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'ไม่มีประวัติการจองคิว',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              );
            }

            final docs = snapshot.data!.docs;

            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final queueDate = (data['queueDate'] as Timestamp).toDate();
                final dateStr = '${queueDate.day}/${queueDate.month}/${queueDate.year}';
                final queueText = data['queueText'] ?? '';
                final doctorId = data['queueDocList']?['docId'] ?? '';
                
                // ดึงข้อมูลผู้ใช้
                String userName = '';
                final queueUserList = data['queueUserList'];
                if (queueUserList != null) {
                  if (queueUserList['userName'] != null) {
                    userName = queueUserList['userName'];
                  } else if (queueUserList['userIdCard'] is Map && 
                             queueUserList['userIdCard']['userName'] != null) {
                    userName = queueUserList['userIdCard']['userName'];
                  }
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('doctor')
                            .doc(doctorId)
                            .get(),
                        builder: (context, docSnapshot) {
                          String doctorName = 'หมอ';
                          String doctorDepartment = '';
                          
                          if (docSnapshot.hasData && docSnapshot.data!.exists) {
                            final docData = docSnapshot.data!.data() as Map<String, dynamic>?;
                            if (docData != null) {
                              doctorName = docData['docName'] ?? 'หมอ';
                              doctorDepartment = docData['docDepart'] ?? '';
                            }
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'นัดหมาย นาย$doctorName ${doctorDepartment.isNotEmpty ? doctorDepartment : ''} ผาตุ :',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '($queueText) โดย $userIdCard',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          );
                        },
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