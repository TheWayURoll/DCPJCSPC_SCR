import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dcpjcspc_scr/classes/user_settings.dart'; // <-- Import UserSettings page


class AccoutsPage extends StatefulWidget {
	final String userIdCard;
	AccoutsPage({Key? key, required this.userIdCard}) : super(key: key);

	@override
	State<AccoutsPage> createState() => _AccoutsPageState();
}

class _AccoutsPageState extends State<AccoutsPage> {
	String name = '';
	String idCard = '';
	bool isLoading = true;

	@override
	void initState() {
		super.initState();
		_fetchUserData();
	}

		Future<void> _fetchUserData() async {
			// ดึงข้อมูลจาก Firestore ด้วย userIdCard ที่ส่งมาจาก login
			final query = await FirebaseFirestore.instance
					.collection('user')
					.where('userIdCard', isEqualTo: widget.userIdCard)
					.limit(1)
					.get();
			if (query.docs.isNotEmpty) {
				final data = query.docs.first.data();
						setState(() {
							name = data['userName'] ?? '';
							idCard = data['userIdCard'] ?? '';
							isLoading = false;
						});
			} else {
				setState(() {
					isLoading = false;
				});
			}
		}

	void _logout() async {
		await FirebaseAuth.instance.signOut();
		if (mounted) {
			Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
		}
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: Colors.grey[100],
			body: SafeArea(
				child: Padding(
					padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
					child: isLoading
							? Center(child: CircularProgressIndicator())
							: Column(
									crossAxisAlignment: CrossAxisAlignment.stretch,
									children: [
										SizedBox(height: 16),
										_buildReadOnlyField('ชื่อนามสกุล', name),
										SizedBox(height: 16),
										_buildReadOnlyField('เลขบัตรประชาชน', idCard),
										SizedBox(height: 32),
										_buildLargeButton(
											icon: Icons.settings,
											label: 'ตั้งค่า',
											onPressed: () async {
												final result = await Navigator.push(
													context,
													MaterialPageRoute(
														builder: (context) => UserSettings(),
														settings: RouteSettings(arguments: widget.userIdCard),
													),
												);
												if (result == true) {
													_fetchUserData(); // รีเฟรชข้อมูลเมื่อกลับมาจากหน้า settings
												}
											},
										),
										SizedBox(height: 16),
										_buildLargeButton(
											icon: Icons.arrow_back,
											label: 'ออกจากระบบ',
											onPressed: _logout,
										),
									],
								),
				),
			),
		);
	}

		Widget _buildReadOnlyField(String label, String value) {
			return TextField(
				controller: TextEditingController(text: value),
				readOnly: true,
				enabled: false,
				decoration: InputDecoration(
					hintText: label,
					filled: true,
					fillColor: Colors.white,
					contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
					border: OutlineInputBorder(
						borderRadius: BorderRadius.circular(10),
						borderSide: BorderSide(color: Colors.grey.shade300),
					),
					enabledBorder: OutlineInputBorder(
						borderRadius: BorderRadius.circular(10),
						borderSide: BorderSide(color: Colors.grey.shade300),
					),
					focusedBorder: OutlineInputBorder(
						borderRadius: BorderRadius.circular(10),
						borderSide: BorderSide(color: Colors.deepPurple),
					),
				),
				style: TextStyle(color: Colors.black87),
			);
		}

	Widget _buildLargeButton({required IconData icon, required String label, required VoidCallback onPressed}) {
		return ElevatedButton.icon(
			style: ElevatedButton.styleFrom(
				backgroundColor: const Color(0xFF5B3FA2),
				shape: RoundedRectangleBorder(
					borderRadius: BorderRadius.circular(28),
				),
				elevation: 2,
				minimumSize: const Size.fromHeight(56),
			),
			icon: Icon(icon, color: Colors.white, size: 28),
			label: Text(
				label,
				style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w500),
			),
			onPressed: onPressed,
		);
	}
}
