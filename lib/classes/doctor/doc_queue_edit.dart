import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

class DocQueueEdit extends StatefulWidget {
  final String? queueDocId;
  const DocQueueEdit({Key? key, this.queueDocId}) : super(key: key);

  @override
  State<DocQueueEdit> createState() => _DocQueueEditState();
}

class _DocQueueEditState extends State<DocQueueEdit> {
  String? selectedDoctor;
  DateTime selectedDay = DateTime.now();
  TimeOfDay? selectedTime;
  TextEditingController descriptionController = TextEditingController();
  String? _timeErrorText;
  List<String> doctors = [];
  bool isLoadingDoctors = true;
  List<DateTime> _bookedDateTimes = [];
  Map<DateTime, Map<String, dynamic>> _calendarStatusMap = {};

  @override
  void initState() {
    super.initState();
    fetchDoctors();
    if (widget.queueDocId != null) {
      fetchQueueData();
    }
  }

  Future<void> fetchDoctors() async {
    setState(() { isLoadingDoctors = true; });
    final snapshot = await FirebaseFirestore.instance.collection('doctor').get();
    final doctorNames = snapshot.docs.map((doc) => doc['docName'] as String).toList();
    setState(() {
      doctors = doctorNames;
      isLoadingDoctors = false;
    });
  }

  Future<void> fetchQueueData() async {
    final doc = await FirebaseFirestore.instance.collection('queueLists').doc(widget.queueDocId).get();
    final data = doc.data();
    if (data != null) {
      final docId = data['queueDocList']?['docId'];
      if (docId != null) {
        final doctorSnap = await FirebaseFirestore.instance.collection('doctor').doc(docId).get();
        selectedDoctor = doctorSnap['docName'];
      }
      final ts = data['queueDate'];
      selectedDay = ts is DateTime ? ts : (ts as Timestamp).toDate();
      selectedTime = TimeOfDay(hour: selectedDay.hour, minute: selectedDay.minute);
      descriptionController.text = data['queueText'] ?? '';
      setState(() {});
      await fetchBookedTimes();
      await fetchCalendarStatus();
    }
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
      _bookedDateTimes = snapshot.docs
        .where((doc) => doc.id != widget.queueDocId)
        .map((doc) {
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
      final normalizedDate = DateTime(date.year, date.month, date.day);
      statusMap[normalizedDate] = data;
    }
    setState(() { _calendarStatusMap = statusMap; });
  }

  List<TimeOfDay> get availableTimes {
    final List<TimeOfDay> times = [];
    for (int h = 9; h < 17; h++) {
      for (int m = 0; m < 60; m += 15) {
        if (h == 12 && (m == 0 || m == 15)) continue;
        times.add(TimeOfDay(hour: h, minute: m));
      }
    }
    return times;
  }

  bool get isDoctorSelected => selectedDoctor != null && selectedDoctor!.isNotEmpty;

  bool get isFormValid {
    final isDescFilled = descriptionController.text.trim().isNotEmpty;
    final isTimeValid = selectedTime != null && ((selectedTime!.hour >= 9 && selectedTime!.hour < 17) ||
      (selectedTime!.hour == 17 && selectedTime!.minute == 0));
    final isMinuteValid = selectedTime != null && selectedTime!.minute % 15 == 0;
    return isDoctorSelected && isDescFilled && isTimeValid && isMinuteValid;
  }

  Future<void> saveQueueEdit() async {
    if (!isFormValid || widget.queueDocId == null) return;
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
    await FirebaseFirestore.instance.collection('queueLists').doc(widget.queueDocId).update({
      'queueDate': queueDateTime,
      'queueDocList': {'docId': docId},
      'queueText': descriptionController.text,
    });
    if (mounted) Navigator.pop(context, true); // ส่ง true เพื่อรีเฟรชหน้าก่อนหน้า
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        elevation: 0,
        title: const Text('แก้ไขรายการนัดหมาย', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                          selectedTime = null;
                        });
                        await fetchBookedTimes();
                        await fetchCalendarStatus();
                      },
                    ),
              const SizedBox(height: 18),
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
                        return !_calendarStatusMap.containsKey(DateTime(day.year, day.month, day.day));
                      },
                      calendarBuilders: CalendarBuilders(),
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
                      return !_calendarStatusMap.containsKey(normalizedDay);
                    },
                  );
                  if (picked != null) {
                    setState(() => selectedDay = picked);
                  } else {
                    setState(() {});
                  }
                },
              ),
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
              const SizedBox(height: 10),
              // เพิ่มระยะห่างด้านล่าง
              SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isFormValid
                          ? () async {
                              await saveQueueEdit();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFormValid ? const Color(0xFF5B3FA2) : const Color(0xFFD1C4E9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('บันทึก', style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 70),
            ],
          ),
        ),
      ),
    );
  }
}