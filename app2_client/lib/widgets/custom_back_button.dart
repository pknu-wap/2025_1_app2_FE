import 'package:flutter/material.dart';

class CustomBackButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const CustomBackButton({Key? key, this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      mini: true,
      backgroundColor: Colors.white,
      child: const Icon(Icons.arrow_back, color: Colors.black),
      onPressed: onPressed ?? () => Navigator.pop(context),
    );
  }
}