import 'package:flutter/material.dart';
import 'package:dcpjcspc_scr/widgets/history_Cards/admin_history_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminHistorylist extends StatelessWidget {
  const AdminHistorylist({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'ประวัติการจองคิวทั้งหมด',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('historyLists')
            .snapshots(), // ไม่มีการกรอง แสดงทั้งหมด
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'ไม่มีประวัติการจองคิวในระบบ',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          final historyDocs = snapshot.data!.docs;
          
          // เรียงลำดับตามวันที่ในฝั่ง client
          historyDocs.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            
            final dateA = dataA['logHisDate'];
            final dateB = dataB['logHisDate'];
            
            // เรียงจากใหม่ไปเก่า (descending)
            if (dateA is Timestamp && dateB is Timestamp) {
              return dateB.compareTo(dateA);
            }
            return 0;
          });

          return Column(
            children: [
              // แสดงจำนวนรายการทั้งหมด
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.list_alt,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'รายการทั้งหมด: ${historyDocs.length} รายการ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // รายการประวัติ
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: historyDocs.length,
                  itemBuilder: (context, index) {
                    final doc = historyDocs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    // ดึงข้อมูลจาก Firestore
                    final logHisDate = data['logHisDate'] ?? '';
                    final docId = data['logHisDocId']?['docId'] ?? 'ไม่ระบุ';
                    final userIdCard = data['logHisUserId']?['userIdCard'] ?? 'ไม่ระบุ';
                    final logHisText = data['logHisText'] ?? 'ไม่มีรายละเอียด';

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('doctor')
                          .doc(docId)
                          .get(),
                      builder: (context, doctorSnapshot) {
                        String doctorName = 'แพทย์ไม่ระบุ';
                        
                        if (doctorSnapshot.connectionState == ConnectionState.done) {
                          if (doctorSnapshot.hasData && doctorSnapshot.data!.exists) {
                            final doctorData = doctorSnapshot.data!.data() as Map<String, dynamic>;
                            doctorName = doctorData['docName'] ?? 'แพทย์ไม่ระบุ';
                          }
                        } else if (doctorSnapshot.connectionState == ConnectionState.waiting) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            height: 120,
                            child: const Center(child: CircularProgressIndicator()),
                          );
                        }

                        String appointmentDetails = _formatAppointmentDetails(logHisText);

                        return AdminHistoryCard(
                          date: logHisDate is Timestamp 
                              ? logHisDate.toDate().toIso8601String()
                              : _formatFirebaseDate(logHisDate),
                          doctorName: doctorName,
                          patientId: userIdCard,
                          appointmentDetails: appointmentDetails,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatAppointmentDetails(String logHisText) {
    if (logHisText.isEmpty || logHisText == 'null') {
      return 'คำอธิบายเพิ่มเติม: null';
    }
    return 'คำอธิบายเพิ่มเติม: $logHisText';
  }

  String _formatFirebaseDate(dynamic dateField) {
    try {
      if (dateField is Timestamp) {
        final date = dateField.toDate();
        return '${date.day}/${date.month}/${date.year}';
      } else if (dateField is String) {
        if (dateField.contains('UTC') || dateField.contains('at')) {
          // Parse Firebase date string format
          final parts = dateField.split(' ');
          if (parts.length >= 3) {
            final datePart = parts[0] + ' ' + parts[1] + ' ' + parts[2];
            final date = DateTime.tryParse(datePart);
            if (date != null) {
              return '${date.day}/${date.month}/${date.year}';
            }
          }
        }
        return dateField;
      }
      return DateTime.now().toString().split(' ')[0];
    } catch (e) {
      return DateTime.now().toString().split(' ')[0];
    }
  }
}