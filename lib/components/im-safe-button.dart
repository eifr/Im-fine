import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class ImSafeButton extends StatefulWidget {
  final void Function() stopListen;
  const ImSafeButton({
    super.key,
    required this.stopListen,
  });

  @override
  State<ImSafeButton> createState() => _ImSafeButton();
}

class _ImSafeButton extends State<ImSafeButton> {
  final LocalAuthentication auth = LocalAuthentication();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.shield_outlined),
      onPressed: widget.stopListen,
      label: const Text("אני בסדר"),
    );
  }
}
