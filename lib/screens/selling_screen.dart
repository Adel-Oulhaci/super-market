import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'receipt_screen.dart';

/// Record model for past purchases.
class PurchaseRecord {
  final DateTime dateTime;
  final List<Product> purchasedProducts;
  final String loyalCustomer;
  final double totalPrice;
  final double amountPaid;
  final double change;
  final String barcode; // Stored barcode value

  PurchaseRecord({
    required this.dateTime,
    required this.purchasedProducts,
    required this.loyalCustomer,
    required this.totalPrice,
    required this.amountPaid,
    required this.change,
    required this.barcode,
  });
}

/// Global purchase history list.
List<PurchaseRecord> purchaseHistory = [];

/// Global notifier to update purchase history count in real time.
ValueNotifier<int> purchaseHistoryCountNotifier = ValueNotifier<int>(0);

/// Updated Product model.
class Product {
  final String name;
  int quantity;
  final double price;
  final String barcode;

  Product(
      {required this.name,
      this.quantity = 1,
      required this.price,
      required this.barcode});
}

/// A simple session model to hold a session's selected products and loyal customer info.
class Session {
  final String name;
  List<Product> selectedProducts;
  String loyalCustomer;

  Session({
    required this.name,
    this.loyalCustomer = "client",
    List<Product>? selectedProducts,
  }) : selectedProducts = selectedProducts ?? [];
}

/// A simple class to return payment results from PaymentDialog.
class PaymentResult {
  final double amountPaid;
  final double change;
  final bool autoPrint;
  PaymentResult({
    required this.amountPaid,
    required this.change,
    required this.autoPrint,
  });
}

class SellingScreen extends StatefulWidget {
  const SellingScreen({super.key});

  @override
  _SellingScreenState createState() => _SellingScreenState();
}

class _SellingScreenState extends State<SellingScreen>
    with TickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  final FocusNode _combinedSearchFocusNode = FocusNode();

  // Create a persistent text controller for the Autocomplete field.
  final TextEditingController _searchController = TextEditingController();

  // Create a combined search controller
  final TextEditingController _combinedSearchController =
      TextEditingController();

  // Define your available products list.
  final List<Product> availableProducts = [
    // When scanning the barcode "1738521408773", this product will be matched.
    Product(name: "Apple", price: 1.99, barcode: "1738521408713"),
    Product(name: "Banana", price: 1.99, barcode: "6134318000040"),
    Product(name: "Orange", price: 1.99, barcode: "1738721408743"),

    // Add other products as needed...
  ];

  // Dummy customers.
  final List<Map<String, String>> dummyCustomers = [
    {"id": "1001", "name": "Alice Johnson"},
    {"id": "1002", "name": "Bob Smith"},
    {"id": "1003", "name": "Charlie Brown"},
  ];

  // List of sessions, each representing its own "tab"
  List<Session> sessions = [Session(name: "Session 1")];

  // TabController used to drive the TabBar and TabBarView.
  // Note: We always add an extra tab at the end for "Add new session".
  late TabController _tabController;

  // Maximum allowed sessions.
  static const int maxSessions = 6;

  // New field for auto print receipt preference.
  bool _autoPrintReceipt = false;

  @override
  void initState() {
    super.initState();
    // Initialize the TabController in initState to avoid LateInitializationError.
    // Also, this ensures that by default, the first session ("Session 1") is active.
    _initTabController(initialIndex: 0);
  }

  /// Initializes the TabController based on the number of sessions.
  /// The length is sessions.length + 1 (the last tab is for adding a new session).
  void _initTabController({int initialIndex = 0}) {
    final int tabLength =
        (sessions.length < maxSessions) ? sessions.length + 1 : sessions.length;
    _tabController = TabController(
      length: tabLength,
      vsync: this,
      initialIndex: initialIndex,
    );
    _tabController.addListener(() {
      // Update the UI when the tab index changes.
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _searchController.dispose();
    _combinedSearchController.dispose();
    _combinedSearchFocusNode.dispose();
    _tabController.dispose();
    // DO NOT dispose _autocompleteController since Autocomplete manages it.
    super.dispose();
  }

  double get totalPrice => sessions[_tabController.index]
      .selectedProducts
      .fold(0.0, (sum, product) => sum + product.price * product.quantity);

  // Increments product quantity.
  void _incrementQuantity(int index) {
    setState(() {
      sessions[_tabController.index].selectedProducts[index].quantity++;
    });
  }

  // Decrements product quantity.
  void _decrementQuantity(int index) {
    setState(() {
      if (sessions[_tabController.index].selectedProducts[index].quantity > 1) {
        sessions[_tabController.index].selectedProducts[index].quantity--;
      }
    });
  }

  /// Deletes a product from the current session and resets its quantity.
  void _deleteProduct(int index) {
    setState(() {
      // Reset the quantity of the product before deleting it.
      sessions[_tabController.index].selectedProducts[index].quantity = 1;
      sessions[_tabController.index].selectedProducts.removeAt(index);
    });
  }

  // Shows the Payment dialog and awaits its result.
  void _showPaymentDialog() async {
    final PaymentResult? result = await showDialog<PaymentResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentDialog(totalPrice: totalPrice),
    );
    if (result != null) {
      final String customerName =
          sessions[_tabController.index].loyalCustomer.trim().isEmpty
              ? "client"
              : sessions[_tabController.index].loyalCustomer;
      // Generate a barcode for this purchase.
      final String barcode = _generateBarcode();
      // Save the purchase record.
      PurchaseRecord record = PurchaseRecord(
        dateTime: DateTime.now(),
        purchasedProducts: List.from(sessions[_tabController.index].selectedProducts),
        loyalCustomer: customerName,
        totalPrice: totalPrice,
        amountPaid: result.amountPaid,
        change: result.change,
        barcode: barcode,
      );
      purchaseHistory.add(record);
      purchaseHistoryCountNotifier.value = purchaseHistory.length;
      // Clear the current session.
      setState(() {
        sessions[_tabController.index].selectedProducts.clear();
      });
      // Do not call _printReceipt(record) here so that the receipt is only saved in history.
    }
  }

  // Generate a barcode string based on the current timestamp.
  String _generateBarcode() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Updated print receipt method which navigates to ReceiptScreen.
  // ReceiptScreen now expects the full PurchaseRecord so it can render a BarcodeWidget.
  void _printReceipt(PurchaseRecord record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiptScreen(receiptData: record),
      ),
    );
  }

  // Product search field using Autocomplete.
  Widget _buildCombinedProductSearchBar() {
    return SizedBox(
      height: 48,
      child: Autocomplete<Product>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return const Iterable<Product>.empty();
          }
          final query = textEditingValue.text.toLowerCase();
          return availableProducts.where((Product product) =>
              product.name.toLowerCase().contains(query) ||
              product.barcode.toString().toLowerCase().contains(query));
        },
        displayStringForOption: (Product product) => product.name,
        fieldViewBuilder: (
          BuildContext context,
          TextEditingController textEditingController,
          FocusNode focusNode,
          VoidCallback onFieldSubmitted,
        ) {
          // Synchronize our persistent controller.
          textEditingController.text = _combinedSearchController.text;
          // Use our persistent focus node.
          return TextField(
            controller: _combinedSearchController,
            focusNode: _combinedSearchFocusNode,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Search by Name or Barcode',
              border: const OutlineInputBorder(),
              suffixIcon: _combinedSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearCombinedSearch,
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (value) {
              final query = value.trim();
              Product? matchingProduct;
              try {
                matchingProduct = availableProducts.firstWhere(
                  (product) =>
                      product.barcode.toString().toLowerCase() ==
                      query.toLowerCase(),
                );
              } catch (e) {
                matchingProduct = null;
              }
              if (matchingProduct != null) {
                setState(() {
                  _addProductToSession(matchingProduct!);
                });
              }
              _clearCombinedSearch();
            },
          );
        },
        onSelected: (Product product) {
          setState(() {
            _addProductToSession(product);
          });
          _clearCombinedSearch();
        },
      ),
    );
  }

  /// Adds the product to the current session.
  /// If the product (by barcode) is already present, increment its quantity.
  void _addProductToSession(Product product) {
    List<Product> sessionProducts = sessions[_tabController.index].selectedProducts;
    final int existingIndex = sessionProducts.indexWhere((p) => p.barcode == product.barcode);
    if (existingIndex != -1) {
      sessionProducts[existingIndex].quantity++;
    } else {
      // Adding a new product (its quantity is 1 by default).
      sessionProducts.add(product);
    }
  }

  /// Clears the search input and immediately re-requests focus.
  void _clearCombinedSearch() {
    _combinedSearchController.clear();
    Future.delayed(Duration.zero, () {
      _combinedSearchFocusNode.requestFocus();
    });
    setState(() {});
  }

  // Updated Loyal customer field using Autocomplete for full editability.
  Widget _buildLoyalCustomerField() {
    return SizedBox(
      width: 250,
      child: Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return dummyCustomers.map((customer) => customer['name']!).toList();
          }
          final matches = dummyCustomers
              .map((customer) => customer['name']!)
              .where((name) => name
                  .toLowerCase()
                  .contains(textEditingValue.text.toLowerCase()))
              .toList();
          return matches.isNotEmpty ? matches : [textEditingValue.text];
        },
        fieldViewBuilder:
            (context, textEditingController, focusNode, onFieldSubmitted) {
          if (textEditingController.text.isEmpty) {
            textEditingController.text =
                sessions[_tabController.index].loyalCustomer;
          }
          return TextField(
            controller: textEditingController,
            focusNode: focusNode,
            decoration: const InputDecoration(
              labelText: 'Loyal Customer',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              setState(() {
                sessions[_tabController.index].loyalCustomer = value;
              });
            },
            onSubmitted: (value) {
              setState(() {
                sessions[_tabController.index].loyalCustomer =
                    value.trim().isEmpty ? "client" : value.trim();
              });
              textEditingController.text =
                  sessions[_tabController.index].loyalCustomer;
            },
          );
        },
        onSelected: (String selection) {
          setState(() {
            sessions[_tabController.index].loyalCustomer = selection;
          });
        },
      ),
    );
  }

  /// Widget to build the Auto Print Receipt checkbox.
  Widget _buildAutoPrintCheckbox() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: _autoPrintReceipt,
          onChanged: (value) {
            setState(() {
              _autoPrintReceipt = value ?? false;
            });
          },
        ),
        const Text("Auto Print Receipt"),
      ],
    );
  }

  ///
  /// Build a TabBar with one tab for each session and one extra tab for adding a new session.
  ///
  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      onTap: (index) {
        // If the "Add New Session" tab is tapped (last tab), add a new session.
        if (sessions.length < maxSessions && index == sessions.length) {
          _addNewSession();
        }
      },
      tabs: [
        for (final session in sessions) Tab(text: session.name),
        if (sessions.length < maxSessions) const Tab(icon: Icon(Icons.add)),
      ],
    );
  }

  /// Adds a new session, if the maximum has not been reached.
  /// After adding a session, reinitializes the TabController so that the "+" tab updates.
  void _addNewSession() {
    if (sessions.length >= maxSessions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Maximum $maxSessions sessions reached.")),
      );
      return;
    }
    setState(() {
      sessions.add(Session(name: "Session ${sessions.length + 1}"));
      _tabController.dispose();
      _initTabController(initialIndex: sessions.length - 1);
    });
  }

  /// Closes (removes) all sessions **except** the currently active one.
  void _closeOtherSessions() {
    int currentIndex = _tabController.index;
    setState(() {
      final Session currentSession = sessions[currentIndex];
      sessions = [currentSession];
      _tabController.dispose();
      _initTabController(initialIndex: 0);
    });
  }

  ///
  /// Build the content for each session. This includes the product search field
  /// and a list of the products added to the session.
  ///
  Widget _buildSessionContent(Session session) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  'Total:\n\$${totalPrice.toStringAsFixed(2)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.0,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(flex: 3, child: _buildCombinedProductSearchBar()),
          ],
        ),
        const SizedBox(height: 16.0),
        // Row with Loyal Customer field and Auto Print Receipt checkbox beside it.
        Row(
          children: [
            _buildLoyalCustomerField(),
            const SizedBox(width: 16.0),
            _buildAutoPrintCheckbox(),
          ],
        ),
        const SizedBox(height: 16.0),
        // "Clear Session" button clears all scanned products and resets the loyal customer.
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _clearCurrentSession,
            child: const Text('Clear Session'),
          ),
        ),
        const SizedBox(height: 8.0),
        // List of selected products.
        Expanded(
          child: session.selectedProducts.isEmpty
              ? const Center(
                  child: Text(
                    'No products selected.',
                    style: TextStyle(fontSize: 16.0),
                  ),
                )
              : ListView.builder(
                  itemCount: session.selectedProducts.length,
                  itemBuilder: (context, index) {
                    final product = session.selectedProducts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: ListTile(
                        title: Text(product.name),
                        subtitle: Text(
                            'Price: \$${product.price.toStringAsFixed(2)} | Quantity: ${product.quantity}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete),
                              tooltip: 'Delete Item',
                              onPressed: () => _deleteProduct(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () => _decrementQuantity(index),
                            ),
                            Text('${product.quantity}'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => _incrementQuantity(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// Clears all scanned products and resets the loyal customer in the current session.
  void _clearCurrentSession() {
    setState(() {
      sessions[_tabController.index].selectedProducts.clear();
      sessions[_tabController.index].loyalCustomer = "client";
    });
  }

  @override
  Widget build(BuildContext context) {
    // If _tabController is not yet initialized, show a loading indicator.
    if (_tabController == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      // Empty callback; shortcut conditions removed.
      onKeyEvent: (_) {},
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Selling Screen'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48.0),
            child: _buildTabBar(),
          ),
          actions: [
            if (sessions.length > 1)
              IconButton(
                icon: const Icon(Icons.clear_all),
                tooltip: "Close Other Sessions",
                onPressed: _closeOtherSessions,
              ),
          ],
        ),
        floatingActionButton:
            sessions[_tabController.index].selectedProducts.isNotEmpty
                ? FloatingActionButton.extended(
                    onPressed: _showPaymentDialog,
                    label: const Text("Payment"),
                    icon: const Icon(Icons.payment),
                  )
                : null,
        body: TabBarView(
          controller: _tabController,
          children: [
            for (final session in sessions) _buildSessionContent(session),
            Container(
              child: Center(child: Text("Tap the '+' tab to add a new session")),
            )
          ],
        ),
      ),
    );
  }
}

/// Payment dialog widget which now returns a PaymentResult when payment is confirmed.
class PaymentDialog extends StatefulWidget {
  final double totalPrice;
  const PaymentDialog({
    super.key,
    required this.totalPrice,
  });

  @override
  _PaymentDialogState createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final TextEditingController _amountController = TextEditingController();
  double _change = 0.0;

  void _calculateChange() {
    final amountPaid = double.tryParse(_amountController.text) ?? 0.0;
    setState(() {
      _change = amountPaid - widget.totalPrice;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Payment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Total: \$${widget.totalPrice.toStringAsFixed(2)}'),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount Paid',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => _calculateChange(),
          ),
          const SizedBox(height: 12),
          Text('Change: \$${_change.toStringAsFixed(2)}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Cancel returns null.
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final amountPaid = double.tryParse(_amountController.text) ?? 0.0;
            if (amountPaid < widget.totalPrice) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Amount paid is insufficient')),
              );
              return;
            }
            // Return a PaymentResult with autoPrint set to false (it will be overridden)
            Navigator.of(context).pop(
              PaymentResult(
                amountPaid: amountPaid,
                change: amountPaid - widget.totalPrice,
                autoPrint: false,
              ),
            );
          },
          child: const Text('Confirm Payment'),
        ),
      ],
    );
  }
}
