// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import '../models/sale_transaction.dart';
import 'package:supermarket_app/screens/selling_screen.dart'; // For accessing purchaseHistory

/// Displays a history of transactions with a summary card at the top and a
/// bottom bar that shows the total Net Profit and the Total Purchases from all sales.
class HistoryScreen extends StatelessWidget {
  final List<SaleTransaction> dailyTransactions;

  const HistoryScreen({Key? key, required this.dailyTransactions})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use a DefaultTabController with three tabs.
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("History"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Profit"),
              Tab(text: "Products"),
              Tab(text: "Customers"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ProfitAnalyticsHistory(),
            ProductAnalyticsHistory(),
            CustomerAnalyticsHistory(),
          ],
        ),
      ),
    );
  }
}

/// Displays a placeholder for profit analytics charts in History.
class ProfitAnalyticsHistory extends StatelessWidget {
  const ProfitAnalyticsHistory({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Display placeholders for Daily, Weekly, and Monthly profit analytics.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Daily Profit",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(
            height: 200,
            child: Container(
              color: Colors.grey.shade300,
              child:
                  const Center(child: Text('Profit chart not available')),
            ),
          ),
          const SizedBox(height: 16),
          const Text("Weekly Profit",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(
            height: 200,
            child: Container(
              color: Colors.grey.shade300,
              child:
                  const Center(child: Text('Profit chart not available')),
            ),
          ),
          const SizedBox(height: 16),
          const Text("Monthly Profit",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(
            height: 200,
            child: Container(
              color: Colors.grey.shade300,
              child:
                  const Center(child: Text('Profit chart not available')),
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays a placeholder for product analytics in History.
class ProductAnalyticsHistory extends StatelessWidget {
  const ProductAnalyticsHistory({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Since chart functionality has been removed, display a message.
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          "Product analytics chart not available.",
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Displays a list of the top 10 loyal customers in History.
class CustomerAnalyticsHistory extends StatelessWidget {
  const CustomerAnalyticsHistory({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Group purchase records by loyal customer.
    Map<String, int> customerMap = {};
    for (var record in purchaseHistory) {
      customerMap[record.loyalCustomer] =
          (customerMap[record.loyalCustomer] ?? 0) + 1;
    }
    List<CustomerData> customerList = customerMap.entries
        .map((entry) => CustomerData(entry.key, entry.value))
        .toList();
    customerList.sort((a, b) => b.purchases.compareTo(a.purchases));
    if (customerList.length > 10) {
      customerList = customerList.sublist(0, 10);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: customerList.length,
      itemBuilder: (context, index) {
        final customer = customerList[index];
        return ListTile(
          leading: CircleAvatar(child: Text('${index + 1}')),
          title: Text(customer.customer),
          trailing: Text('Purchases: ${customer.purchases}'),
        );
      },
    );
  }
}

/// Data model for customer analytics.
class CustomerData {
  final String customer;
  final int purchases;
  CustomerData(this.customer, this.purchases);
}
