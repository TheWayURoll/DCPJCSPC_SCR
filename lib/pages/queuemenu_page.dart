import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
  
  
class QueueMenuPage extends StatefulWidget {
  final String userIdCard;
  QueueMenuPage({Key? key, required this.userIdCard}) : super(key: key);

  @override
  State<QueueMenuPage> createState() => _QueueMenuPageState();
}

class _QueueMenuPageState extends State<QueueMenuPage> {
  Future<void> fetchDoctors() async {
    setState(() { isLoadingDoctors = true; });
    final snapshot = await FirebaseFirestore.instance.collection('doctor').get();
    final doctorNames = snapshot.docs.map((doc) => doc['docName'] as String).toList();
    setState(() {
      doctors = doctorNames;
      isLoadingDoctors = false;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchDoctors();
  }
  Future<void> saveQueue() async {
    if (!isFormValid) return;
    String? docId;
    if (selectedDoctor != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('doctor')
          .where('docName', isEqualTo: selectedDoctor)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        docId = snapshot.docs.first['docId'] as String?;
      }
    }
    if (docId == null) return;
    if (selectedTime == null) return;
    final DateTime queueDateTime = DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );
    try {
      String? queueId;
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final queueRef = FirebaseFirestore.instance.collection('queueLists');
        final duplicateSnap = await queueRef
            .where('queueDocList.docId', isEqualTo: docId)
            .where('queueDate', isEqualTo: queueDateTime)
            .get();
        if (duplicateSnap.docs.isNotEmpty) {
          throw Exception('มีการจองคิวนี้แล้ว กรุณาเลือกเวลาใหม่');
        }
        final queueSnapshot = await queueRef.get();
        Set<int> usedNums = {};
        for (var doc in queueSnapshot.docs) {
          final id = doc.id;
          final match = RegExp(r'queueList(\d+)').firstMatch(id);
          if (match != null) {
            final num = int.tryParse(match.group(1) ?? '0') ?? 0;
            usedNums.add(num);
          }
        }
        // หาเลขที่ว่างต่ำสุด
        int nextQueueNum = 1;
        while (usedNums.contains(nextQueueNum)) {
          nextQueueNum++;
        }
        final queueDocId = 'queueList$nextQueueNum';
        queueId = 'qi${nextQueueNum.toString().padLeft(3, '0')}';
        transaction.set(queueRef.doc(queueDocId), {
          'queueDate': queueDateTime,
          'queueDocList': {'docId': docId},
          'queueId': queueId,
          'queueText': descriptionController.text,
          'queueUserList': {
            'userIdCard': widget.userIdCard,
          },
        });
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกสำเร็จ')),
        );
        setState(() {
          selectedDoctor = null;
          selectedDay = DateTime.now();
          selectedTime = null;
          descriptionController.clear();
          _timeErrorText = null;
        });
        await fetchBookedTimes();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }
  // State variables for queue booking and calendar
  String? selectedDoctor;
  DateTime selectedDay = DateTime.now();
  TimeOfDay? selectedTime;
  TextEditingController descriptionController = TextEditingController();
  String? _timeErrorText;
  List<String> doctors = [];
  bool isLoadingDoctors = true;
  List<DateTime> _bookedDateTimes = [];

  Map<DateTime, Map<String, dynamic>> _calendarStatusMap = {};

  bool get isFormValid {
    final isDoctorSelected = selectedDoctor != null && selectedDoctor!.isNotEmpty;
    final isDescFilled = descriptionController.text.trim().isNotEmpty;
    final isTimeValid = selectedTime != null && ((selectedTime!.hour >= 9 && selectedTime!.hour < 17) ||
      (selectedTime!.hour == 17 && selectedTime!.minute == 0));
    final isMinuteValid = selectedTime != null && selectedTime!.minute % 15 == 0;
    return isDoctorSelected && isDescFilled && isTimeValid && isMinuteValid;
  }

  bool get isDoctorSelected => selectedDoctor != null && selectedDoctor!.isNotEmpty;

  List<TimeOfDay> get availableTimes {
    final List<TimeOfDay> times = [];
    for (int h = 9; h < 17; h++) {
      for (int m = 0; m < 60; m += 15) {
        if (h == 12 && (m == 0 || m == 15)) continue; // เว้นพักหมอ
        times.add(TimeOfDay(hour: h, minute: m));
      }
    }
    return times;
  }

  Future<void> fetchBookedTimes() async {
    String? docId;
    if (selectedDoctor != null) {
      final snapshot = await FirebaseFirestore.instance
        .collection('doctor')
        .where('docName', isEqualTo: selectedDoctor)
        .limit(1)
        .get();
      if (snapshot.docs.isNotEmpty) {
        docId = snapshot.docs.first['docId'] as String?;
      }
    }
    if (docId == null) {
      setState(() { _bookedDateTimes = []; });
      return;
    }
    final snapshot = await FirebaseFirestore.instance.collection('queueLists')
      .where('queueDocList.docId', isEqualTo: docId)
      .get();
    setState(() {
      _bookedDateTimes = snapshot.docs.map((doc) {
        final ts = doc['queueDate'];
        return ts is DateTime ? ts : (ts as Timestamp).toDate();
      }).toList();
    });
  }

  Future<void> fetchCalendarStatus() async {
    if (selectedDoctor == null) return;
    final doctorSnap = await FirebaseFirestore.instance.collection('doctor')
        .where('docName', isEqualTo: selectedDoctor)
        .limit(1).get();
    if (doctorSnap.docs.isEmpty) return;
    final docId = doctorSnap.docs.first['docId'] as String?;
    if (docId == null) return;
    final calSnap = await FirebaseFirestore.instance.collection('docCalendar')
        .where('calDocId', isEqualTo: docId).get();
    final Map<DateTime, Map<String, dynamic>> statusMap = {};
    for (var doc in calSnap.docs) {
      final data = doc.data();
      final ts = data['calDocDate'];
      final date = ts is DateTime ? ts : (ts as Timestamp).toDate();
      // Normalize date to year, month, day only
      final normalizedDate = DateTime(date.year, date.month, date.day);
      statusMap[normalizedDate] = data;
    }
    setState(() { _calendarStatusMap = statusMap; });
    print('StatusMap keys:');
    for (final k in _calendarStatusMap.keys) {
      print(k.toIso8601String());
    }
    print('StatusMap: $_calendarStatusMap');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchBookedTimes();
  }

  /// อัปเดต queueLists และ logHistory ที่ queueId เดียวกัน
Future<void> updateQueueAndLogHistory({
  required String queueDocId,
  required String queueId,
  required String newQueueText,
  required DateTime newQueueDate,
}) async {
  // อัปเดต queueLists
  await FirebaseFirestore.instance.collection('queueLists').doc(queueDocId).update({
    'queueText': newQueueText,
    'queueDate': newQueueDate,
  });

  // อัปเดต logHistory ที่ queueId เดียวกัน
  final logSnap = await FirebaseFirestore.instance
      .collection('logHistory')
      .where('queueId', isEqualTo: queueId)
      .get();
  for (var doc in logSnap.docs) {
    await doc.reference.update({
      'queueText': newQueueText,
      'queueDate': newQueueDate,
    });
  }
}

// ตัวอย่างการเรียกใช้ (หลังจากแก้ไขข้อมูลนัดหมาย)
// await updateQueueAndLogHistory(
//   queueDocId: 'queueList1',
//   queueId: 'qi001',
//   newQueueText: 'ข้อความใหม่',
//   newQueueDate: DateTime.now(),
// );

  void showEditQueueDialog(BuildContext context, String queueDocId, String queueId, String oldText, DateTime oldDate) {
  final TextEditingController editController = TextEditingController(text: oldText);
  DateTime selectedDate = oldDate;
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('แก้ไขรายการนัดหมาย'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: editController,
              decoration: const InputDecoration(labelText: 'คำอธิบาย'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  selectedDate = DateTime(
                    picked.year, picked.month, picked.day,
                    selectedDate.hour, selectedDate.minute,
                  );
                }
              },
              child: const Text('เลือกวันที่'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              await updateQueueAndLogHistory(
                queueDocId: queueDocId,
                queueId: queueId,
                newQueueText: editController.text,
                newQueueDate: selectedDate,
              );
              Navigator.pop(context);
            },
            child: const Text('บันทึก'),
          ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        elevation: 0,
        title: const Text('สร้างรายการนัดหมาย', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        automaticallyImplyLeading: false, // ไม่แสดงปุ่มย้อนกลับ
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Doctor Dropdown
              isLoadingDoctors
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      value: selectedDoctor,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      hint: const Text('เลือกแพทย์'),
                      items: doctors
                          .map((doc) => DropdownMenuItem(value: doc, child: Text(doc)))
                          .toList(),
                      onChanged: (value) async {
                        setState(() {
                          selectedDoctor = value;
                          selectedTime = null; // reset time when doctor changes
                        });
                        await fetchBookedTimes();
                        await fetchCalendarStatus();
                      },
                    ),
              const SizedBox(height: 18),

              // Calendar
              Container(
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ตารางแพทย์', style: TextStyle(fontWeight: FontWeight.w500)),
                    TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: selectedDay,
                      selectedDayPredicate: (day) => isSameDay(day, selectedDay),
                      onDaySelected: (selected, focused) {
                        final status = _calendarStatusMap[DateTime(selected.year, selected.month, selected.day)];
                        if (status != null) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('สถานะหมอ'),
                              content: Text('${status['calDocStatus'] ?? ''}\n${status['calDocReason'] ?? ''}'),
                              actions: [TextButton(child: Text('ปิด'), onPressed: () => Navigator.pop(context))],
                            ),
                          );
                          return;
                        }
                        setState(() {
                          selectedDay = selected;
                        });
                        fetchBookedTimes();
                      },
                      enabledDayPredicate: (day) {
                        // ถ้าวันนี้มีสถานะหมอ (ไม่ว่าง/ลาพัก) จะ disable
                        return !_calendarStatusMap.containsKey(DateTime(day.year, day.month, day.day));
                      },
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          final normalizedDay = DateTime(day.year, day.month, day.day);
                          final status = _calendarStatusMap[normalizedDay];
                          if (status != null) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  width: 36,
                                  height: 36,
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${day.day}',
                                    style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  status['calDocStatus'] ?? '',
                                  style: const TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            );
                          }
                          return null;
                        },
                        markerBuilder: (context, day, events) {
                          final status = _calendarStatusMap[DateTime(day.year, day.month, day.day)];
                          if (status != null) {
                            return Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(bottom: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            );
                          }
                          return null;
                        },
                      ),
                      calendarStyle: CalendarStyle(
                        selectedDecoration: BoxDecoration(
                          color: Colors.deepPurple,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: Colors.deepPurple.shade100,
                          shape: BoxShape.circle,
                        ),
                      ),
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Date Picker Field
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'เลือกวันที่จองคิว',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                controller: TextEditingController(
                  text: "${selectedDay.day}/${selectedDay.month}/${selectedDay.year}",
                ),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDay,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                    selectableDayPredicate: (day) {
                      final normalizedDay = DateTime(day.year, day.month, day.day);
                      // ปิดไม่ให้เลือกวันที่ที่มีสถานะหมอ
                      return !_calendarStatusMap.containsKey(normalizedDay);
                    },
                  );
                  if (picked != null) {
                    setState(() => selectedDay = picked);
                  } else {
                    setState(() {}); // เพื่อให้ปุ่มอัปเดตแม้ไม่ได้เลือกวันใหม่
                  }
                },
              ),
              // แสดงสถานะหมอใต้ช่องเลือกวันที่
              Builder(
                builder: (context) {
                  final normalizedDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
                  final status = _calendarStatusMap[normalizedDay];
                  if (status != null) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.red, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            status['calDocStatus'] ?? '',
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                          if ((status['calDocReason'] ?? '').toString().isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              status['calDocReason'],
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ]
                        ],
                      ),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
              const SizedBox(height: 18),

              // Time Dropdown
              Container(
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Enter time', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<TimeOfDay>(
                      value: isDoctorSelected && selectedTime != null && availableTimes.contains(selectedTime)
                          ? selectedTime
                          : null,
                      items: isDoctorSelected
                          ? availableTimes.map((t) {
                              final booked = _bookedDateTimes.any((dt) =>
                                  dt.year == selectedDay.year &&
                                  dt.month == selectedDay.month &&
                                  dt.day == selectedDay.day &&
                                  dt.hour == t.hour &&
                                  dt.minute == t.minute);
                              final label = t.format(context) + (booked ? ' (จองแล้ว)' : '');
                              return DropdownMenuItem<TimeOfDay>(
                                value: booked ? null : t,
                                enabled: !booked,
                                child: Text(label, style: TextStyle(fontSize: 20, color: booked ? Colors.grey : Colors.black)),
                              );
                            }).toList()
                          : [],
                      onChanged: isDoctorSelected
                          ? (t) {
                              setState(() {
                                selectedTime = t;
                                _timeErrorText = null;
                              });
                            }
                          : null,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        fillColor: Colors.white,
                        filled: true,
                        hintText: isDoctorSelected ? null : 'กรุณาเลือกแพทย์ก่อน',
                      ),
                    ),
                    if (_timeErrorText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _timeErrorText!,
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Description
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'คำอธิบาย',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  fillColor: Colors.white,
                  filled: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isFormValid
                          ? () async {
                              await saveQueue();
                              // อาจแสดง dialog หรือ pop กลับ
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFormValid ? const Color(0xFF5B3FA2) : const Color(0xFFD1C4E9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: isFormValid ? 4 : 0,
                      ),
                      child: Text(
                        'ตกลง',
                        style: TextStyle(
                          fontSize: 18,
                          color: isFormValid ? Colors.white : const Color(0xFF8D7BBF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedDoctor = null;
                          selectedDay = DateTime.now();
                          selectedTime = TimeOfDay(hour: 9, minute: 0);
                          descriptionController.clear();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD1C4E9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      child: const Text(
                        'ยกเลิก',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF8D7BBF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
