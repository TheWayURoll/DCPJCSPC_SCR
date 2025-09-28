import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserQueueEdit extends StatefulWidget {
  final String queueDocId;
  final String userIdCard;
  const UserQueueEdit({Key? key, required this.queueDocId, required this.userIdCard}) : super(key: key);

  @override
  State<UserQueueEdit> createState() => _UserQueueEditState();
}

class _UserQueueEditState extends State<UserQueueEdit> {
  bool _doctorSelected = false;
  // เวลาที่เลือกได้เหมือน queuemenu_page.dart
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

  List<DateTime> _bookedDateTimes = [];

  bool isTimeBooked(TimeOfDay t) {
    return _bookedDateTimes.any((dt) =>
      dt.year == _selectedDate?.year &&
      dt.month == _selectedDate?.month &&
      dt.day == _selectedDate?.day &&
      dt.hour == t.hour &&
      dt.minute == t.minute
    );
  }

  Future<void> fetchBookedTimes() async {
    if (_selectedDoctorId == null || _selectedDate == null) {
      if (!mounted) return;
      setState(() { _bookedDateTimes = []; });
      return;
    }
    final snapshot = await FirebaseFirestore.instance.collection('queueLists')
      .where('queueDocList.docId', isEqualTo: _selectedDoctorId)
      .get();
    if (!mounted) return;
    setState(() {
      _bookedDateTimes = snapshot.docs
        .where((doc) => doc.id != widget.queueDocId) // exclude current editing queue
        .map((doc) {
          final ts = doc['queueDate'];
          return ts is DateTime ? ts : (ts as Timestamp).toDate();
        }).toList();
    });
  }
  final _formKey = GlobalKey<FormState>();
  TextEditingController _descController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedDoctorId;
  bool _loading = true;
  List<Map<String, dynamic>> _doctors = [];
  Map<DateTime, Map<String, dynamic>> _calendarStatusMap = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final queueDoc = await FirebaseFirestore.instance.collection('queueLists').doc(widget.queueDocId).get();
    final data = queueDoc.data() ?? {};
    final Timestamp? queueDate = data['queueDate'];
    _selectedDate = queueDate?.toDate();
    _selectedTime = _selectedDate != null ? TimeOfDay(hour: _selectedDate!.hour, minute: _selectedDate!.minute) : null;
    _descController.text = data['queueText'] ?? '';
  _selectedDoctorId = data['queueDocList']?['docId'];
  _doctorSelected = false; // ยังไม่ได้เลือกหมอใหม่

    // ดึงรายชื่อหมอทั้งหมด
    final doctorSnap = await FirebaseFirestore.instance.collection('doctor').get();
    _doctors = doctorSnap.docs.map((d) => {
      'docId': d['docId'],
      'docName': d['docName'],
    }).toList();

    // เรียก fetchBookedTimes ถ้ามีหมอและวันที่
    if (_selectedDoctorId != null && _selectedDate != null) {
      await fetchBookedTimes();
    }
    if (!mounted) return;
    setState(() { _loading = false; });
  }

  Future<void> fetchCalendarStatus() async {
    if (_selectedDoctorId == null) return;
    final calSnap = await FirebaseFirestore.instance.collection('docCalendar')
        .where('calDocId', isEqualTo: _selectedDoctorId)
        .get();
    final Map<DateTime, Map<String, dynamic>> statusMap = {};
    for (var doc in calSnap.docs) {
      final data = doc.data();
      final ts = data['calDocDate'];
      final date = ts is DateTime ? ts : (ts as Timestamp).toDate();
      statusMap[DateTime(date.year, date.month, date.day)] = data;
    }
    if (mounted) setState(() { _calendarStatusMap = statusMap; });
  }

  Future<void> _saveEdit() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null || _selectedTime == null || _selectedDoctorId == null) return;
    final newDateTime = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedTime!.hour, _selectedTime!.minute);
    await FirebaseFirestore.instance.collection('queueLists').doc(widget.queueDocId).update({
      'queueDate': newDateTime,
      'queueText': _descController.text,
      'queueDocList': {'docId': _selectedDoctorId},
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แก้ไขรายการนัดหมาย'),
        backgroundColor: Colors.deepPurple,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedDoctorId,
                      items: _doctors.map<DropdownMenuItem<String>>((d) => DropdownMenuItem<String>(
                        value: d['docId'] as String,
                        child: Text(d['docName'] as String),
                      )).toList(),
                      onChanged: (val) async {
                        setState(() {
                          _selectedDoctorId = val;
                          _doctorSelected = true;
                        });
                        await fetchBookedTimes();
                        await fetchCalendarStatus();
                      },
                      decoration: const InputDecoration(labelText: 'เลือกแพทย์'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'คำอธิบาย'),
                      validator: (v) => v == null || v.isEmpty ? 'กรุณากรอกคำอธิบาย' : null,
                      enabled: _doctorSelected,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(_selectedDate == null ? '' : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                        ),
                        TextButton(
                          onPressed: _doctorSelected
                              ? () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDate ?? DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(2100),
                                    selectableDayPredicate: (day) {
                                      final normalizedDay = DateTime(day.year, day.month, day.day);
                                      return !_calendarStatusMap.containsKey(normalizedDay);
                                    },
                                  );
                                  if (picked != null) {
                                    setState(() => _selectedDate = picked);
                                    await fetchBookedTimes();
                                  }
                                }
                              : null,
                          child: const Text('เลือกวันที่'),
                        ),
                      ],
                    ),
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
                              value: _selectedDoctorId != null && _selectedTime != null && availableTimes.contains(_selectedTime)
                                  ? _selectedTime
                                  : null,
                              items: _doctorSelected
                                  ? availableTimes.map((t) {
                                      final booked = isTimeBooked(t);
                                      final label = t.format(context) + (booked ? ' (จองแล้ว)' : '');
                                      return DropdownMenuItem<TimeOfDay>(
                                        value: booked ? null : t,
                                        enabled: !booked,
                                        child: Text(label, style: TextStyle(fontSize: 20, color: booked ? Colors.grey : Colors.black)),
                                      );
                                    }).toList()
                                  : [],
                              onChanged: _doctorSelected
                                  ? (t) {
                                      setState(() {
                                        _selectedTime = t;
                                      });
                                    }
                                  : null,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                fillColor: Colors.white,
                                filled: true,
                                hintText: _doctorSelected ? null : 'กรุณาเลือกแพทย์ก่อน',
                              ),
                              disabledHint: const Text('กรุณาเลือกแพทย์ก่อน'),
                            ),
                            // สามารถเพิ่ม error text ได้ถ้าต้องการ เช่น
                            // if (_timeErrorText != null)
                            //   Padding(
                            //     padding: const EdgeInsets.only(top: 8.0),
                            //     child: Text(
                            //       _timeErrorText!,
                            //       style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            //     ),
                            //   ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveEdit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('บันทึก', style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}