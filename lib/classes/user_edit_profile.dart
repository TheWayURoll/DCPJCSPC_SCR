import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserEditProfile extends StatefulWidget {
  final String? userIdCard;
  const UserEditProfile({Key? key, this.userIdCard}) : super(key: key);

  @override
  State<UserEditProfile> createState() => _UserEditProfileState();
}

class _UserEditProfileState extends State<UserEditProfile> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _idCardController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (widget.userIdCard == null) return;
    setState(() => _loading = true);
    final query = await FirebaseFirestore.instance
        .collection('user')
        .where('userIdCard', isEqualTo: widget.userIdCard)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      final data = query.docs.first.data();
      _idCardController.text = data['userIdCard'] ?? '';
      _nameController.text = data['userName'] ?? '';
      _phoneController.text = data['userPhoneNumber'] ?? '';
      _passwordController.text = data['userPassword'] ?? '';
    }
    setState(() => _loading = false);
  }

  Future<void> _updateUserData() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final query = await FirebaseFirestore.instance
        .collection('user')
        .where('userIdCard', isEqualTo: _idCardController.text)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.update({
        'userName': _nameController.text,
        'userPhoneNumber': _phoneController.text,
        'userPassword': _passwordController.text,
      });
    }
    setState(() => _loading = false);
    if (mounted) Navigator.pop(context, true); // ส่ง true กลับไปเพื่อรีเฟรช
  }

  @override
  void dispose() {
    _idCardController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildField(_idCardController, 'เลขบัตรประชาชน', readOnly: true),
                      const SizedBox(height: 24),
                      _buildField(_nameController, 'ชื่อ'),
                      const SizedBox(height: 24),
                      _buildField(_phoneController, 'เบอร์โทร'),
                      const SizedBox(height: 24),
                      _buildField(_passwordController, 'Password', isPassword: true),
                      const SizedBox(height: 36),
                      _buildButton('ตกลง', onPressed: _updateUserData),
                      const SizedBox(height: 20),
                      _buildButton('ยกเลิก',
                          onPressed: () => Navigator.pop(context),
                          color: const Color(0xFF6C5A8E)),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildField(TextEditingController controller, String label,
      {bool readOnly = false, bool isPassword = false}) {
    bool isObscure = isPassword;
    return StatefulBuilder(
      builder: (context, setState) {
        return TextFormField(
          controller: controller,
          readOnly: readOnly,
          enabled: !readOnly,
          obscureText: isObscure,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontWeight: FontWeight.w500),
            filled: true,
            fillColor: const Color(0xFFF7F7FA),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD1C4E9)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF5B3FA2), width: 2),
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => isObscure = !isObscure),
                  )
                : null,
          ),
          validator: (value) {
            if (!readOnly && (value == null || value.isEmpty)) {
              return 'กรุณากรอก$label';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildButton(String label, {required VoidCallback onPressed, Color? color}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? const Color(0xFF5B3FA2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 2,
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.white, // แก้ไขให้ข้อความในปุ่มเป็นสีขาว
          ),
        ),
      ),
    );
  }
}