import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  const PasswordField({Key? key, required this.controller}) : super(key: key);

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Password',
        hintText: 'กรุณาใส่รหัสผ่าน',
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
      ],
    );
  }
}