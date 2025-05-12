import 'package:flutter/material.dart';

/// A product model for the stock management section.
class StockProduct {
  final String id; // Unique product identifier.
  String name;
  double? buyingPrice; // Changed to nullable for safety.
  double? sellingPrice; // Changed to nullable for safety.
  int stock;
  List<String> barcodes;

  StockProduct({
    required this.id,
    required this.name,
    this.buyingPrice,
    this.sellingPrice,
    required this.stock,
    List<String>? barcodes,
  }) : barcodes = barcodes ?? [];

  // The profit is computed as selling minus buying.
  // If a price is null, a default of 0.0 is used.
  double get profit => (sellingPrice ?? 0.0) - (buyingPrice ?? 0.0);
}

class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({super.key});

  @override
  _StockManagementScreenState createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> {
  // Sample list of products in stock.
  List<StockProduct> products = [
    StockProduct(
        id: '1',
        name: 'Apple',
        buyingPrice: 0.80,
        sellingPrice: 1.20,
        stock: 50,
        barcodes: ['111111']),
    StockProduct(
        id: '2',
        name: 'Banana',
        buyingPrice: 0.30,
        sellingPrice: 0.50,
        stock: 100),
    StockProduct(
        id: '3',
        name: 'Orange',
        buyingPrice: 0.50,
        sellingPrice: 0.80,
        stock: 80),
    StockProduct(
        id: '4',
        name: 'Milk',
        buyingPrice: 1.20,
        sellingPrice: 1.50,
        stock: 30),
    StockProduct(
        id: '5',
        name: 'Bread',
        buyingPrice: 1.80,
        sellingPrice: 2.00,
        stock: 20),
  ];

  // Controller for the product search field.
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = _searchController.text;
    });
  }

  // Returns the list of products filtered by the search query.
  List<StockProduct> get filteredProducts {
    if (searchQuery.isEmpty) return products;
    return products.where((product) {
      return product.name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  // Increases the stock of a given product.
  void _increaseStock(StockProduct product) {
    setState(() {
      product.stock++;
    });
  }

  // Decreases the stock of a given product.
  void _decreaseStock(StockProduct product) {
    setState(() {
      if (product.stock > 0) product.stock--;
    });
  }

  /// Updated _scanBarcode method with an extra parameter.
  /// When useRootNavigator is true the dialog uses the root navigator,
  /// helping avoid nested dialog freezes.
  Future<String?> _scanBarcode(
      {BuildContext? customContext, bool useRootNavigator = false}) async {
    final BuildContext effectiveContext = customContext ?? context;
    return await showDialog<String>(
      context: effectiveContext,
      useRootNavigator: useRootNavigator,
      builder: (context) {
        final TextEditingController barcodeController = TextEditingController();
        return AlertDialog(
          title: const Text("Scan Barcode"),
          content: TextField(
            controller: barcodeController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Barcode',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(barcodeController.text.trim()),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  /// Updated add product method using QR code scanning.
  void _addNewProduct() async {
    // First, scan the product's barcode.
    final String? scannedBarcode = await _scanBarcode();
    if (scannedBarcode == null || scannedBarcode.isEmpty) return;

    // Create text controllers for each input field.
    final TextEditingController nameController = TextEditingController();
    final TextEditingController buyingPriceController =
        TextEditingController(text: "0.0");
    final TextEditingController sellingPriceController =
        TextEditingController(text: "0.0");
    final TextEditingController stockController =
        TextEditingController(text: "1");

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("New Product Details"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("Scanned Barcode: $scannedBarcode"),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: buyingPriceController,
                  decoration: const InputDecoration(
                    labelText: 'Buying Price',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: sellingPriceController,
                  decoration: const InputDecoration(
                    labelText: 'Selling Price',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: stockController,
                  decoration: const InputDecoration(
                    labelText: 'Stock Quantity',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final String name = nameController.text.trim();
                final double? buyingPrice =
                    double.tryParse(buyingPriceController.text.trim());
                final double? sellingPrice =
                    double.tryParse(sellingPriceController.text.trim());
                final int? stock = int.tryParse(stockController.text.trim());
                if (name.isEmpty ||
                    buyingPrice == null ||
                    sellingPrice == null ||
                    stock == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Please enter valid product details")),
                  );
                  return;
                }
                setState(() {
                  products.add(
                    StockProduct(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      buyingPrice: buyingPrice,
                      sellingPrice: sellingPrice,
                      stock: stock,
                      barcodes: [scannedBarcode],
                    ),
                  );
                });
                Navigator.of(context).pop();
              },
              child: const Text("Add Product"),
            ),
          ],
        );
      },
    );
  }

  /// Updated edit product method. This dialog is similar to the add product dialog
  /// but pre-populates fields with the existing product details.
  /// The "Scan Barcode" button now calls _scanBarcode with useRootNavigator: true,
  /// which launches the scanning dialog outside the nested dialog hierarchy to prevent freezing.
  void _editProduct(StockProduct product) {
    final TextEditingController nameController =
        TextEditingController(text: product.name);
    final TextEditingController buyingPriceController =
        TextEditingController(text: (product.buyingPrice ?? 0.0).toString());
    final TextEditingController sellingPriceController =
        TextEditingController(text: (product.sellingPrice ?? 0.0).toString());
    final TextEditingController stockController =
        TextEditingController(text: product.stock.toString());
    final List<String> currentBarcodes = List.from(product.barcodes);

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Edit Product'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Edit product name.
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Edit buying price.
                    TextField(
                      controller: buyingPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Buying Price',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 8),
                    // Edit selling price.
                    TextField(
                      controller: sellingPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Selling Price',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 8),
                    // Edit stock quantity.
                    TextField(
                      controller: stockController,
                      decoration: const InputDecoration(
                        labelText: 'Stock Quantity',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    // Barcode row with a Scan button.
                    Row(
                      children: [
                        const Text('Barcodes:'),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Scan Barcode',
                          icon: const Icon(Icons.qr_code_scanner),
                          onPressed: () async {
                            final String? scannedBarcode = await _scanBarcode(
                              customContext: context,
                              useRootNavigator: true,
                            );
                            if (scannedBarcode != null &&
                                scannedBarcode.isNotEmpty) {
                              setModalState(() {
                                currentBarcodes.add(scannedBarcode);
                              });
                            }
                          },
                        )
                      ],
                    ),
                    // Display barcode chips in a horizontally scrollable row.
                    if (currentBarcodes.isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: currentBarcodes.map((barcode) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Chip(
                                label: Text(barcode),
                                onDeleted: () {
                                  setModalState(() {
                                    currentBarcodes.remove(barcode);
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Cancel editing.
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final String newName = nameController.text.trim();
                    final double? newBuyingPrice =
                        double.tryParse(buyingPriceController.text.trim());
                    final double? newSellingPrice =
                        double.tryParse(sellingPriceController.text.trim());
                    final int? newStock =
                        int.tryParse(stockController.text.trim());
                    if (newName.isEmpty ||
                        newBuyingPrice == null ||
                        newSellingPrice == null ||
                        newStock == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter valid product details.'),
                        ),
                      );
                      return;
                    }
                    setState(() {
                      product.name = newName;
                      product.buyingPrice = newBuyingPrice;
                      product.sellingPrice = newSellingPrice;
                      product.stock = newStock;
                      product.barcodes = currentBarcodes;
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                )
              ],
            );
          },
        );
      },
    );
  }

  // Shows a confirmation dialog and deletes the product.
  void _deleteProduct(StockProduct product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                products.remove(product);
              });
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Updated method to add a new product by scanning its barcode.
  void _scanAndAddProduct() async {
    // 1. Scan a barcode.
    final String? scannedBarcode = await _scanBarcode();
    if (scannedBarcode == null || scannedBarcode.isEmpty) return;

    // 2. Check if a product with the scanned barcode already exists.
    StockProduct? existingProduct;
    try {
      existingProduct = products.firstWhere(
        (product) => product.barcodes.contains(scannedBarcode),
      );
    } catch (e) {
      existingProduct = null;
    }

    if (existingProduct != null) {
      // Increment stock if the product exists.
      setState(() {
        existingProduct?.stock++;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Increased stock for ${existingProduct.name} by 1")),
      );
    } else {
      // Otherwise, open a dialog to add new product details.
      final TextEditingController nameController = TextEditingController();
      final TextEditingController buyingPriceController =
          TextEditingController(text: "0.0");
      final TextEditingController sellingPriceController =
          TextEditingController(text: "0.0");
      final TextEditingController stockController =
          TextEditingController(text: "1");

      await showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text("New Product Details"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text("Scanned Barcode: $scannedBarcode"),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Product Name',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: buyingPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Buying Price',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: sellingPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Selling Price',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: stockController,
                    decoration: const InputDecoration(
                      labelText: 'Stock Quantity',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  final String name = nameController.text.trim();
                  final double? buyingPrice =
                      double.tryParse(buyingPriceController.text.trim());
                  final double? sellingPrice =
                      double.tryParse(sellingPriceController.text.trim());
                  final int? stock = int.tryParse(stockController.text.trim());
                  if (name.isEmpty ||
                      buyingPrice == null ||
                      sellingPrice == null ||
                      stock == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Please enter valid product details")),
                    );
                    return;
                  }
                  setState(() {
                    products.add(
                      StockProduct(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: name,
                        buyingPrice: buyingPrice,
                        sellingPrice: sellingPrice,
                        stock: stock,
                        barcodes: [scannedBarcode],
                      ),
                    );
                  });
                  Navigator.of(context).pop(); // Close the dialog.
                },
                child: const Text("Add Product"),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add New Product',
            onPressed: _addNewProduct,
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan and Add Product',
            onPressed: _scanAndAddProduct,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search field.
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Product',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          // List of products.
          Expanded(
            child: ListView.builder(
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    title: Text(product.name),
                    subtitle: Text(
                      'Buying Price: \$${(product.buyingPrice ?? 0.0).toStringAsFixed(2)}\n'
                      'Selling Price: \$${(product.sellingPrice ?? 0.0).toStringAsFixed(2)}\n'
                      'Profit: \$${product.profit.toStringAsFixed(2)}\n'
                      'Stock: ${product.stock}\n'
                      'Barcodes: ${product.barcodes.join(", ")}',
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Decrease Stock',
                          icon: const Icon(Icons.remove),
                          onPressed: () => _decreaseStock(product),
                        ),
                        Text('${product.stock}'),
                        IconButton(
                          tooltip: 'Increase Stock',
                          icon: const Icon(Icons.add),
                          onPressed: () => _increaseStock(product),
                        ),
                        IconButton(
                          tooltip: 'Edit Product',
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editProduct(product),
                        ),
                        IconButton(
                          tooltip: 'Delete Product',
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteProduct(product),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
