import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DocCalworkPage extends StatefulWidget {
  final String docId;
  const DocCalworkPage({super.key, required this.docId});

  @override
  State<DocCalworkPage> createState() => _DocCalworkPageState();
}

class _DocCalworkPageState extends State<DocCalworkPage> {
  final TextEditingController _noteController = TextEditingController();

  void _resetForm() {
    setState(() {
      _selectedDate = null;
      _selectedStatus = 'ไม่ว่าง';
      _noteController.clear();
    });
  }
  DateTime? _selectedDate;
  String _selectedStatus = 'ไม่ว่าง';
  final List<String> _statusOptions = ['ไม่ว่าง', 'ลาพัก'];

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.deepPurple.shade300,
              onPrimary: Colors.white,
              surface: Colors.deepPurple.shade50,
              onSurface: Colors.deepPurple.shade900,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.deepPurple.shade400,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('เลือกวันที่ตารางงาน', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextField(
                    readOnly: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.deepPurple.shade200),
                      ),
                      hintText: _selectedDate == null
                          ? 'เลือกวันที่ตารางงาน'
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      suffixIcon: Icon(Icons.calendar_today, color: Colors.deepPurple.shade300),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                items: _statusOptions
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ))
                    .toList(),
                onChanged: _selectedDate == null
                    ? null
                    : (value) {
                        setState(() {
                          _selectedStatus = value!;
                        });
                      },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                disabledHint: Text(_selectedStatus),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _noteController,
                minLines: 1,
                maxLines: 3,
                enabled: _selectedDate != null,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'ระบุเหตุผลเพิ่มเติม เช่น วันนี้ไม่ว่าง มีธุระครับ',
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      if (_selectedDate == null) return;
                      final docCalendarRef = FirebaseFirestore.instance.collection('docCalendar');
                      final snapshot = await docCalendarRef.get();
                      int nextNum = 1;
                      final existingIds = snapshot.docs.map((doc) => doc.id).where((id) => id.startsWith('calDoc')).toList();
                      if (existingIds.isNotEmpty) {
                        final nums = existingIds.map((id) {
                          final match = RegExp(r'calDoc(\d+)').firstMatch(id);
                          return match != null ? int.tryParse(match.group(1) ?? '') ?? 0 : 0;
                        }).toList();
                        nextNum = nums.reduce((a, b) => a > b ? a : b) + 1;
                      }
                      final calDocId = 'calDoc$nextNum';
                      final calDocListId = 'cd${nextNum.toString().padLeft(3, '0')}';
                      await docCalendarRef.doc(calDocId).set({
                        'calDocDate': _selectedDate,
                        'calDocId': widget.docId, // รับ docId จากบัญชีที่เข้าสู่ระบบ
                        'calDocListId': calDocListId, // อ้างอิงตาม calDoc ที่สร้างขึ้น
                        'calDocReason': _noteController.text,
                        'calDocStatus': _selectedStatus,
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('บันทึกตารางงานสำเร็จ')),
                      );
                      _resetForm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text('ตกลง'),
                  ),
                  ElevatedButton(
                    onPressed: _resetForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple.shade200,
                      foregroundColor: Colors.deepPurple.shade900,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text('ยกเลิก'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}