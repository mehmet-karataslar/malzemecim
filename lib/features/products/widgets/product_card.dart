import 'package:flutter/material.dart';
import '../../../shared/models/product_model.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Expanded(
            child: Center(child: Text(product.name)),
          ),
          Text('₺${product.price.toStringAsFixed(2)}'),
        ],
      ),
    );
  }
}

