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
      _bookedDateTimes = snapshot.docs.map((doc) {
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

    // ดึงรายชื่อหมอทั้งหมด
    final doctorSnap = await FirebaseFirestore.instance.collection('doctor').get();
    _doctors = doctorSnap.docs.map((d) => {
      'docId': d['docId'],
      'docName': d['docName'],
    }).toList();
  if (!mounted) return;
  setState(() { _loading = false; });
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
                        });
                        await fetchBookedTimes();
                      },
                      decoration: const InputDecoration(labelText: 'เลือกแพทย์'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'คำอธิบาย'),
                      validator: (v) => v == null || v.isEmpty ? 'กรุณากรอกคำอธิบาย' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(_selectedDate == null ? '' : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => _selectedDate = picked);
                              await fetchBookedTimes();
                            }
                          },
                          child: const Text('เลือกวันที่'),
                        ),
                      ],
                    ),
                    DropdownButtonFormField<TimeOfDay>(
                      value: _selectedTime,
                      items: availableTimes.map((t) {
                        final booked = isTimeBooked(t);
                        final label = t.format(context) + (booked ? ' (จองแล้ว)' : '');
                        return DropdownMenuItem<TimeOfDay>(
                          value: t,
                          enabled: !booked || (_selectedTime != null && t.hour == _selectedTime!.hour && t.minute == _selectedTime!.minute),
                          child: Text(label, style: TextStyle(fontSize: 20, color: booked ? Colors.grey : Colors.black)),
                        );
                      }).toList(),
                      onChanged: (t) {
                        if (t == null) return;
                        // ไม่อนุญาตเลือกเวลาที่จองแล้ว
                        if (isTimeBooked(t) && (_selectedTime == null || t != _selectedTime)) return;
                        setState(() {
                          _selectedTime = t;
                        });
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        fillColor: Colors.white,
                        filled: true,
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
