import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final String name;
  final double price;
  final VoidCallback onTap;

  const ProductCard({
    Key? key,
    required this.name,
    required this.price,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
              Text('MWK ${price.toStringAsFixed(0)}'),
            ],
          ),
        ),
      ),
    );
  }
}
