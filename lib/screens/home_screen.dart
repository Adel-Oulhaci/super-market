// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:supermarket_app/screens/analytics_screen.dart';
import 'selling_screen.dart';
import 'stock_management_screen.dart';
import 'smart_carts_screen.dart';
import 'package:supermarket_app/screens/history_screen.dart'; // AnalyticsScreen resides here
import '../models/sale_transaction.dart';

class HomeScreen extends StatelessWidget {
  final List<SaleTransaction> saleTransactions;

  const HomeScreen({super.key, required this.saleTransactions});

  // A helper method that creates a styled feature card.
  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Material(
        borderRadius: BorderRadius.circular(16.0),
        elevation: 4,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
              color: Colors.white,
            ),
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
            child: Row(
              children: [
                Icon(icon, color: Colors.blue, size: 32.0),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supermarket App'),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        // A gradient background adds a modern look.
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFeatureCard(
                  context,
                  icon: Icons.point_of_sale,
                  title: 'Selling',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SellingScreen(),
                      ),
                    );
                  },
                ),
                _buildFeatureCard(
                  context,
                  icon: Icons.inventory,
                  title: 'Stock Management',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StockManagementScreen(),
                      ),
                    );
                  },
                ),
                _buildFeatureCard(
                  context,
                  icon: Icons.shopping_cart,
                  title: 'Smart Carts',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SmartCartsScreen(),
                      ),
                    );
                  },
                ),
                Card(
                  child: ListTile(
                    title: const Text('Purchase History'),
                    subtitle: Text('Total Purchases: ${purchaseHistory.length}'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const PurchaseHistoryScreen()),
                      );
                    },
                  ),
                ),
                Card(
                  elevation: 3,
                  child: ListTile(
                    leading: const Icon(Icons.analytics, size: 36),
                    title: const Text("Analytics"),
                    subtitle: const Text("View daily/weekly/monthly profit, top sold products and loyal customers"),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AnalyticsScreen(saleTransactions: saleTransactions),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Detail screen to show purchase history, filtered and sorted by date/time.
class PurchaseHistoryScreen extends StatelessWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sort purchaseHistory by newest first.
    final sortedHistory = List<PurchaseRecord>.from(purchaseHistory)
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase History'),
      ),
      body: sortedHistory.isEmpty
          ? const Center(child: Text('No purchase history yet.'))
          : ListView.builder(
              itemCount: sortedHistory.length,
              itemBuilder: (context, index) {
                final record = sortedHistory[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(
                        'Purchase on ${record.dateTime.toLocal().toString().split('.')[0]}'),
                    subtitle: Text(
                        'Total: \$${record.totalPrice.toStringAsFixed(2)} | Change: \$${record.change.toStringAsFixed(2)}'),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Purchase Details'),
                            content: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Date/Time: ${record.dateTime.toLocal().toString().split('.')[0]}'),
                                  Text('Loyal Customer: ${record.loyalCustomer.isEmpty ? "N/A" : record.loyalCustomer}'),
                                  Text(
                                      'Total: \$${record.totalPrice.toStringAsFixed(2)}'),
                                  Text(
                                      'Amount Paid: \$${record.amountPaid.toStringAsFixed(2)}'),
                                  Text(
                                      'Change: \$${record.change.toStringAsFixed(2)}'),
                                  const SizedBox(height: 8),
                                  const Text('Items:'),
                                  ...record.purchasedProducts.map((product) => Text(
                                      '${product.name} x${product.quantity} - \$${(product.price * product.quantity).toStringAsFixed(2)}')),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Close'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}