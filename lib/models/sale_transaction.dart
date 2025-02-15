class SaleTransaction {
  final String productName;
  final double buyingPrice;
  final double sellingPrice;
  final int quantity;
  final DateTime saleDate;

  SaleTransaction({
    required this.productName,
    required this.buyingPrice,
    required this.sellingPrice,
    required this.quantity,
    required this.saleDate,
  });

  // Total money entered from this transaction.
  double get revenue => sellingPrice * quantity;

  // Profit calculated as (sellingPrice - buyingPrice) * quantity.
  double get profit => (sellingPrice - buyingPrice) * quantity;
} 