import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sale_transaction.dart';
import 'package:supermarket_app/screens/selling_screen.dart'; // For accessing purchaseHistory
import 'package:syncfusion_flutter_charts/charts.dart'; // New charting library

/// A simple data model for time-series profit data.
class TimeSeriesProfit {
  final DateTime date;
  final double profit;
  TimeSeriesProfit(this.date, this.profit);
}

/// AnalyticsScreen displays three tabs:
///  - Profit Analytics (with realtime Syncfusion charts)
///  - Product Analytics
///  - Customer Analytics
class AnalyticsScreen extends StatelessWidget {
  final List<SaleTransaction> saleTransactions;

  const AnalyticsScreen({super.key, required this.saleTransactions});

  @override
  Widget build(BuildContext context) {
    // Use a DefaultTabController with three tabs.
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Analytics"),
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
            ProfitAnalytics(),
            ProductAnalytics(),
            CustomerAnalytics(),
          ],
        ),
      ),
    );
  }
}

/// Displays profit analytics charts with realtime updates using Syncfusion charts.
class ProfitAnalytics extends StatefulWidget {
  const ProfitAnalytics({super.key});

  @override
  _ProfitAnalyticsState createState() => _ProfitAnalyticsState();
}

class _ProfitAnalyticsState extends State<ProfitAnalytics> {
  List<TimeSeriesProfit> _dailyData = [];
  List<TimeSeriesProfit> _weeklyData = [];
  List<TimeSeriesProfit> _monthlyData = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Initialize sample data with current time as reference.
    DateTime now = DateTime.now();
    _dailyData = [
      TimeSeriesProfit(now.subtract(const Duration(days: 4)), 1500),
      TimeSeriesProfit(now.subtract(const Duration(days: 3)), 2000),
      TimeSeriesProfit(now.subtract(const Duration(days: 2)), 1800),
      TimeSeriesProfit(now.subtract(const Duration(days: 1)), 2200),
      TimeSeriesProfit(now, 2500),
    ];

    _weeklyData = [
      TimeSeriesProfit(now.subtract(const Duration(days: 28)), 12000),
      TimeSeriesProfit(now.subtract(const Duration(days: 21)), 15000),
      TimeSeriesProfit(now.subtract(const Duration(days: 14)), 13000),
      TimeSeriesProfit(now.subtract(const Duration(days: 7)), 17000),
      TimeSeriesProfit(now, 18000),
    ];

    _monthlyData = [
      TimeSeriesProfit(now.subtract(const Duration(days: 120)), 50000),
      TimeSeriesProfit(now.subtract(const Duration(days: 90)), 52000),
      TimeSeriesProfit(now.subtract(const Duration(days: 60)), 48000),
      TimeSeriesProfit(now.subtract(const Duration(days: 30)), 55000),
      TimeSeriesProfit(now, 60000),
    ];

    // Simulate realtime updates every 5 seconds.
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      setState(() {
        // Update Daily data: remove the oldest, and add a new data point with simulated profit.
        _dailyData.removeAt(0);
        double lastDailyProfit = _dailyData.last.profit;
        double newDailyProfit = lastDailyProfit + (100 * (1 + timer.tick % 3));
        _dailyData.add(TimeSeriesProfit(DateTime.now(), newDailyProfit));

        // Update Weekly data.
        _weeklyData.removeAt(0);
        double lastWeeklyProfit = _weeklyData.last.profit;
        double newWeeklyProfit = lastWeeklyProfit + (500 * (1 + timer.tick % 3));
        _weeklyData.add(TimeSeriesProfit(DateTime.now(), newWeeklyProfit));

        // Update Monthly data.
        _monthlyData.removeAt(0);
        double lastMonthlyProfit = _monthlyData.last.profit;
        double newMonthlyProfit = lastMonthlyProfit + (1000 * (1 + timer.tick % 3));
        _monthlyData.add(TimeSeriesProfit(DateTime.now(), newMonthlyProfit));
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ProfitLineChart(
            chartTitle: "Daily Profit",
            data: _dailyData,
          ),
          const SizedBox(height: 16),
          ProfitLineChart(
            chartTitle: "Weekly Profit",
            data: _weeklyData,
          ),
          const SizedBox(height: 16),
          ProfitLineChart(
            chartTitle: "Monthly Profit",
            data: _monthlyData,
          ),
        ],
      ),
    );
  }
}

/// A helper widget that builds a Syncfusion line chart.
class ProfitLineChart extends StatelessWidget {
  final String chartTitle;
  final List<TimeSeriesProfit> data;

  const ProfitLineChart({
    super.key,
    required this.chartTitle,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              chartTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(
              height: 200,
              child: SfCartesianChart(
                primaryXAxis: DateTimeAxis(
                  dateFormat: DateFormat.Md(), // formats date as month/day
                ),
                primaryYAxis: NumericAxis(
                  numberFormat: NumberFormat.compact(),
                ),
                series: <ChartSeries>[
                  LineSeries<TimeSeriesProfit, DateTime>(
                    dataSource: data,
                    xValueMapper: (TimeSeriesProfit profit, _) => profit.date,
                    yValueMapper: (TimeSeriesProfit profit, _) => profit.profit,
                    markerSettings: const MarkerSettings(isVisible: true),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Displays a placeholder for product analytics.
class ProductAnalytics extends StatelessWidget {
  const ProductAnalytics({super.key});

  @override
  Widget build(BuildContext context) {
    // As product analytics is not implemented yet, show a placeholder message.
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

/// Displays a list of the top 10 loyal customers.
class CustomerAnalytics extends StatelessWidget {
  const CustomerAnalytics({super.key});

  @override
  Widget build(BuildContext context) {
    // Group purchase records by loyal customer.
    final Map<String, int> customerMap = {};
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