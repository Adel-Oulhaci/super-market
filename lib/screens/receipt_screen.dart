import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'selling_screen.dart'; // Ensure that PurchaseRecord is imported from this file

class ReceiptScreen extends StatelessWidget {
  final PurchaseRecord receiptData;

  const ReceiptScreen({
    Key? key,
    required this.receiptData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Build the receipt UI with purchase details and a rendered barcode image.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Customer: ${receiptData.loyalCustomer}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              Text(
                "Date: ${receiptData.dateTime.toLocal().toString()}",
                style: const TextStyle(fontSize: 14),
              ),
              const Divider(),
              const SizedBox(height: 8.0),
              const Text(
                "Items:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              ...receiptData.purchasedProducts.map((product) {
                double productTotal = product.price * product.quantity;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    "${product.name} x ${product.quantity} - \$${productTotal.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              const Divider(),
              Text(
                "Total: \$${receiptData.totalPrice.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16.0),
              Center(
                child: BarcodeWidget(
                  data: receiptData.barcode,
                  barcode: Barcode.code128(),
                  width: 200,
                  height: 80,
                ),
              ),
              const SizedBox(height: 8.0),
              Center(
                child: Text(
                  "Barcode Data: ${receiptData.barcode}",
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 