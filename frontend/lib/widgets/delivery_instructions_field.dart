// lib/widgets/delivery_instructions_field.dart

import 'package:flutter/material.dart';

class DeliveryInstructionsField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const DeliveryInstructionsField({
    Key? key,
    required this.controller,
    this.hintText = 'e.g., Leave at gate, ring bell, call on arrival',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: 'Delivery Instructions (Optional)',
          hintText: hintText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(12),
          prefixIcon: const Icon(Icons.note_add_outlined, color: Colors.grey),
        ),
        maxLines: 2,
      ),
    );
  }
}