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
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _customerFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  // Define your available products list.
  final List<Product> availableProducts = [
    // When scanning the barcode "1738521408773", this product will be matched.
    Product(name: "Papier Mouchoir", price: 1.99, barcode: "6130649000131"),
    Product(name: "Ayris 1.5L", price: 1.99, barcode: "6130534000031"),
    Product(name: "Abou Sofiane 1L", price: 1.99, barcode: "6135498000028"),
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
    _initTabController(initialIndex: 0);
    // Ensure search field is focused when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  // Handle keyboard shortcuts
  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      // Handle * key for quantity multiplication
      if (event.logicalKey == LogicalKeyboardKey.numpadMultiply ||
          event.logicalKey == LogicalKeyboardKey.asterisk) {
        _showQuantityDialog();
      }
    }
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
    _searchFocusNode.dispose();
    _customerFocusNode.dispose();
    _searchController.dispose();
    _tabController.dispose();
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
        purchasedProducts:
            List.from(sessions[_tabController.index].selectedProducts),
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
          final input = textEditingValue.text;
          if (input.isEmpty) {
            return const Iterable<Product>.empty();
          }
          final query = input.toLowerCase();
          return availableProducts.where(
            (Product product) =>
                product.name.toLowerCase().contains(query) ||
                product.barcode.toLowerCase().contains(query),
          );
        },
        displayStringForOption: (Product product) => product.name,
        fieldViewBuilder: (
          BuildContext context,
          TextEditingController textEditingController,
          FocusNode focusNode,
          VoidCallback onFieldSubmitted,
        ) {
          return TextField(
            controller: textEditingController,
            focusNode: _searchFocusNode,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Scan or Search Product',
              hintText: 'Scan barcode or type product name',
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: const Icon(Icons.qr_code_scanner),
              suffixIcon: textEditingController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        textEditingController.clear();
                        setState(() {});
                        _searchFocusNode
                            .requestFocus(); // Keep focus after clearing
                      },
                    )
                  : null,
            ),
            onChanged: (value) => setState(() {}),
            onSubmitted: (value) {
              final query = value.trim();
              if (query.isEmpty) {
                textEditingController.clear();
                setState(() {});
                return;
              }

              Product? matchingProduct;
              try {
                matchingProduct = availableProducts.firstWhere(
                  (product) =>
                      product.barcode.toLowerCase() == query.toLowerCase(),
                );
              } catch (e) {
                try {
                  matchingProduct = availableProducts.firstWhere(
                    (product) => product.name
                        .toLowerCase()
                        .contains(query.toLowerCase()),
                  );
                } catch (e) {
                  matchingProduct = null;
                }
              }

              if (matchingProduct != null) {
                setState(() {
                  _addProductToSession(matchingProduct!);
                });
                textEditingController.clear();
                _searchFocusNode
                    .requestFocus(); // Keep focus after adding product
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('No product found for "$query"'),
                    backgroundColor: Colors.red[400],
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          );
        },
        onSelected: (Product product) {
          setState(() {
            _addProductToSession(product);
          });
          _searchFocusNode.requestFocus(); // Keep focus after selecting product
        },
      ),
    );
  }

  /// Adds the product to the current session.
  /// If the product (by barcode) is already present, increment its quantity.
  void _addProductToSession(Product product) {
    List<Product> sessionProducts =
        sessions[_tabController.index].selectedProducts;
    final int existingIndex =
        sessionProducts.indexWhere((p) => p.barcode == product.barcode);

    setState(() {
      if (existingIndex != -1) {
        // If product exists, increment its quantity
        sessionProducts[existingIndex].quantity++;
      } else {
        // If product doesn't exist, add it with quantity 1
        sessionProducts.add(Product(
          name: product.name,
          price: product.price,
          barcode: product.barcode,
          quantity: 1,
        ));
      }
    });
  }

  /// Clears the search input and hides the suggestion menu.
  void _clearCombinedSearch() {
    _searchController.clear();
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
          return TextField(
            controller: textEditingController,
            focusNode: _customerFocusNode,
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
              _searchFocusNode
                  .requestFocus(); // Return focus to search after submitting
            },
          );
        },
        onSelected: (String selection) {
          setState(() {
            sessions[_tabController.index].loyalCustomer = selection;
          });
          _searchFocusNode
              .requestFocus(); // Return focus to search after selecting
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        'Total:\n\$${totalPrice.toStringAsFixed(2)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(flex: 3, child: _buildCombinedProductSearchBar()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  _buildLoyalCustomerField(),
                  const SizedBox(width: 16.0),
                  _buildAutoPrintCheckbox(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _clearCurrentSession,
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear Session'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFF44336), // Material Red
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: session.selectedProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 48, color: Colors.blue[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No products selected.',
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: session.selectedProducts.length,
                    itemBuilder: (context, index) => _buildProductListItem(
                      session.selectedProducts[index],
                      index,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Clears all scanned products and resets the loyal customer in the current session.
  void _clearCurrentSession() {
    setState(() {
      sessions[_tabController.index].selectedProducts.clear();
      sessions[_tabController.index].loyalCustomer = "client";
    });
  }

  void _switchToSession(int index) {
    if (index < sessions.length) {
      _tabController.animateTo(index);
    } else if (index == sessions.length && sessions.length < maxSessions) {
      _addNewSession();
    }
  }

  // Show dialog to input quantity multiplier
  void _showQuantityDialog() {
    if (sessions[_tabController.index].selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No products selected to modify quantity'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final lastIndex =
        sessions[_tabController.index].selectedProducts.length - 1;
    final product = sessions[_tabController.index].selectedProducts[lastIndex];
    final TextEditingController quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Quantity for ${product.name}'),
        content: TextField(
          controller: quantityController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Enter quantity',
            hintText: 'e.g., 5',
            border: OutlineInputBorder(),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          onSubmitted: (value) {
            _validateAndSetQuantity(value, product, context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _validateAndSetQuantity(
                  quantityController.text, product, context);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  void _validateAndSetQuantity(
      String value, Product product, BuildContext context) {
    final quantity = int.tryParse(value);
    if (quantity != null && quantity > 0) {
      setState(() {
        product.quantity = quantity;
      });
      Navigator.pop(context);
      _searchFocusNode.requestFocus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid quantity'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Update the product list item to use the same validation
  Widget _buildProductListItem(Product product, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        title: Text(
          product.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          'Price: \$${product.price.toStringAsFixed(2)}',
          style: TextStyle(
            color: Colors.blue[700],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: const Color(0xFFF44336),
              tooltip: 'Delete Item',
              onPressed: () => _deleteProduct(index),
            ),
            Container(
              width: 80,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: InkWell(
                onTap: () {
                  final TextEditingController quantityController =
                      TextEditingController(
                    text: product.quantity.toString(),
                  );
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Set Quantity for ${product.name}'),
                      content: TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Enter quantity',
                          hintText: 'e.g., 5',
                          border: OutlineInputBorder(),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onSubmitted: (value) {
                          _validateAndSetQuantity(value, product, context);
                        },
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _validateAndSetQuantity(
                                quantityController.text, product, context);
                          },
                          child: const Text('Set'),
                        ),
                      ],
                    ),
                  );
                },
                child: Center(
                  child: Text(
                    '${product.quantity}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_tabController == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Selling Screen'),
          elevation: 0,
          backgroundColor: const Color(0xFF2196F3), // Material Blue
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildTabBar(),
            ),
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
                    elevation: 4,
                    backgroundColor: const Color(0xFF4CAF50), // Material Green
                  )
                : null,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue[50]!,
                Colors.blue[100]!,
              ],
            ),
          ),
          child: TabBarView(
            controller: _tabController,
            children: [
              for (final session in sessions) _buildSessionContent(session),
              Container(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline,
                          size: 48, color: Colors.blue[300]),
                      const SizedBox(height: 16),
                      Text(
                        "Tap the '+' tab to add a new session",
                        style: TextStyle(color: Colors.blue[700]),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                const SnackBar(content: Text('Amount paid is insufficient')),
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
