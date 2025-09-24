// ...existing code...
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// เรียกใช้หลังเพิ่ม logHistory ใหม่ทุกครั้ง
Future<void> enforceLogHistoryLimit(String userIdCard, {int maxCount = 50}) async {
  final query = await FirebaseFirestore.instance
      .collection('logHistory')
      .where('userIdCard', isEqualTo: userIdCard)
      .orderBy('queueDate') // ต้องมี field queueDate ใน logHistory
      .get();
  final docs = query.docs;
  if (docs.length > maxCount) {
    final overDocs = docs.take(docs.length - maxCount);
    final batch = FirebaseFirestore.instance.batch();
    for (var doc in overDocs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

// ดึงชื่อหมอทั้งหมดแบบ batch เพื่อลด FutureBuilder ซ้อน
Future<Map<String, String>> _fetchDoctorNames(List<String> docIds) async {
  if (docIds.isEmpty) return {};
  final snap = await FirebaseFirestore.instance.collection('doctor').where('docId', whereIn: docIds).get();
  return {for (var d in snap.docs) d['docId'] as String: d['docName'] as String};
}

class HistoryListPage extends StatefulWidget {
  final String userIdCard;
  const HistoryListPage({Key? key, required this.userIdCard}) : super(key: key);

  @override
  State<HistoryListPage> createState() => _HistoryListPageState();
}

class _HistoryListPageState extends State<HistoryListPage> {
  Map<String, String> _doctorMap = {};
  List<DocumentSnapshot> _docs = [];
  bool _loading = true;
  bool _loadedOnce = false;
  // Map<String, Map<String, dynamic>> _queueDetailMap = {}; // เก็บข้อมูล queueText, queueDate จาก queueLists

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedOnce) {
      _fetchHistory();
      _loadedOnce = true;
      // รีเฟรชอีกครั้งหลัง build เสร็จ (เช่นเมื่อกดปุ่มเมนูเข้าหน้านี้)
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _fetchHistory();
      });
    }
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _loading = true;
    });
  final snapshot = await FirebaseFirestore.instance
    .collection('logHistory')
    .where('userIdCard', isEqualTo: widget.userIdCard)
    .orderBy('queueDate', descending: true)
    .get();
    final docs = snapshot.docs;
    final docIds = docs
        .map((d) => (d.data()['docId'] ?? ''))
        .toSet()
        .where((id) => id != '')
        .map((id) => id.toString())
        .toList();
    final doctorMap = await _fetchDoctorNames(docIds);

    // ดึง queueId ทั้งหมดจาก logHistory
    final queueIds = docs
        .map((d) => (d.data()['queueId'] ?? ''))
        .toSet()
        .where((id) => id != '')
        .map((id) => id.toString())
        .toList();
    Map<String, Map<String, dynamic>> queueDetailMap = {};
    // Firestore whereIn จำกัด 10 รายการต่อ 1 query ต้องแบ่ง batch
    const batchSize = 10;
    for (var i = 0; i < queueIds.length; i += batchSize) {
      final batchIds = queueIds.sublist(i, i + batchSize > queueIds.length ? queueIds.length : i + batchSize);
      final queueSnap = await FirebaseFirestore.instance
          .collection('queueLists')
          .where('queueId', whereIn: batchIds)
          .get();
      for (var q in queueSnap.docs) {
        queueDetailMap[q['queueId']] = q.data();
      }
    }
    if (mounted) {
      setState(() {
        _docs = docs;
        _doctorMap = doctorMap;
        // _queueDetailMap = queueDetailMap;
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _fetchHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'ประวัติการจองคิว',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
        centerTitle: false,
        toolbarHeight: 70,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xF2EAE5EC),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(20),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _docs.isEmpty
                  ? const Text('ยังไม่มีประวัติการจองคิว', style: TextStyle(color: Colors.black54))
                  : RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.builder(
                        itemCount: _docs.length,
                        itemBuilder: (context, idx) {
                          final data = _docs[idx].data() as Map<String, dynamic>;
                          final docId = data['docId'] ?? '';
                          final doctorName = _doctorMap[docId] ?? docId;
                          final queueDate = data['queueDate'];
                          String dateStr = '-';
                          if (queueDate is Timestamp) {
                            final dt = queueDate.toDate();
                            dateStr = '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                          }
                          final detail = data['queueText'] ?? '';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xF2EAE5EC),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dateStr,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'นัดหมาย $doctorName :',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  '($detail)',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ),
    );
  }
}