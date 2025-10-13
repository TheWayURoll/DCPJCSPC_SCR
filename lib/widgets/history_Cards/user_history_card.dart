import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserHistoryCard extends StatelessWidget {
  final String date;
  final String doctorName;
  final String patientId;
  final String appointmentDetails;

  const UserHistoryCard({
    super.key,
    required this.date,
    required this.doctorName,
    required this.patientId,
    required this.appointmentDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // วันที่
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(date),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // ชื่อแพทย์และรายละเอียด
            Text(
              doctorName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            
            // รายละเอียดการนัด
            Text(
              'ผู้นัดหมาย : ($patientId) $appointmentDetails',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      DateTime date;
      
      // ตรวจสอบรูปแบบต่างๆ ของวันที่
      if (dateString.contains('T')) {
        // ISO8601 format เช่น 2025-10-13T08:15:00.576
        date = DateTime.parse(dateString);
        
        // แปลงเป็นเวลาท้องถิ่น
        date = date.toLocal();
        
        // แปลงเป็นรูปแบบภาษาไทยพร้อมเวลาแบบ ชั่วโมง:นาที เท่านั้น
        final dateFormatter = DateFormat('d/M/yyyy');
        final timeFormatter = DateFormat('HH:mm');
        
        return '${dateFormatter.format(date)} เวลา ${timeFormatter.format(date)}';
        
      } else if (dateString.contains('UTC') || dateString.contains('at')) {
        // Firebase string format
        date = DateTime.parse(dateString);
        
        // แปลงเป็นเวลาท้องถิ่น
        date = date.toLocal();
        
        final dateFormatter = DateFormat('d/M/yyyy');
        final timeFormatter = DateFormat('HH:mm');
        
        return '${dateFormatter.format(date)} เวลา ${timeFormatter.format(date)}';
        
      } else if (dateString.contains('/')) {
        // วันที่ในรูปแบบ d/M/yyyy
        return '$dateString';
      } else {
        // fallback
        date = DateTime.now();
        final dateFormatter = DateFormat('d/M/yyyy');
        final timeFormatter = DateFormat('HH:mm');
        
        return '${dateFormatter.format(date)} เวลา ${timeFormatter.format(date)}';
      }
    } catch (e) {
      // หากแปลงไม่ได้ ให้ลองแสดงแค่วันที่
      if (dateString.contains('T')) {
        final parts = dateString.split('T');
        if (parts.length >= 2) {
          final datePart = parts[0]; // 2025-10-13
          final timePart = parts[1].split(':'); // [01, 09, 40.421999]
          if (timePart.length >= 2) {
            final dateComponents = datePart.split('-'); // [2025, 10, 13]
            if (dateComponents.length == 3) {
              return '${dateComponents[2]}/${dateComponents[1]}/${dateComponents[0]} เวลา ${timePart[0]}:${timePart[1]}';
            }
          }
        }
      }
      return dateString;
    }
  }
}