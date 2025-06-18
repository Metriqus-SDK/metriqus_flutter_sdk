import 'dart:io' show Platform;
import '../EventLogger/Parameters/TypedParameter.dart';

/// Represents in-app revenue details, including product information, pricing, promotions, and transaction IDs.
class MetriqusInAppRevenue {
  /// The total revenue amount for the in-app purchase.
  double? _revenue;

  /// The currency of the transaction.
  String? _currency;

  /// The unique identifier for the purchased product.
  String? productId;

  /// The name of the purchased product.
  String? name;

  /// The brand associated with the product.
  String? brand;

  /// The product variant.
  String? variant;

  /// The primary product category.
  String? category;

  /// Additional product category levels.
  String? category2;
  String? category3;
  String? category4;
  String? category5;

  /// The price per unit of the product.
  double? price;

  /// The quantity of items purchased.
  int? quantity;

  /// The amount refunded for this purchase.
  double? refund;

  /// The applied coupon code, if any.
  String? coupon;

  /// The store or affiliate responsible for the sale.
  String? affiliation;

  /// The location identifier of the sale.
  String? locationId;

  /// Identifier for the list in which the product appears.
  String? listId;

  /// The name of the product list.
  String? listName;

  /// The index position of the product within a list.
  int? listIndex;

  /// Promotion details for the product.
  String? promotionId;
  String? promotionName;

  /// The name and slot of the creative asset used in advertising.
  String? creativeName;
  String? creativeSlot;

  /// Additional parameters for the item.
  List<TypedParameter>? itemParams;

  /// The purchase token for Android transactions or transaction ID for iOS.
  String? _transactionId;

  // Getters
  double? get revenue => _revenue;
  String? get currency => _currency;

  /// Default constructor
  MetriqusInAppRevenue();

  /// Constructor with revenue amount and currency
  MetriqusInAppRevenue.withRevenue(double amount, String currency) {
    _revenue = amount;
    _currency = currency;
  }

  /// Sets the revenue amount and currency
  void setRevenue(double amount, String currency) {
    _revenue = amount;
    _currency = currency;
  }

  /// Sets the transaction ID based on the platform
  void setTransactionId(String id) {
    _transactionId = id;
  }

  /// Retrieves the transaction ID
  String getTransactionId() {
    return _transactionId ?? "";
  }

  /// Converts to JSON map
  Map<String, dynamic> toJson() {
    return {
      'revenue': _revenue,
      'currency': _currency,
      'productId': productId,
      'name': name,
      'brand': brand,
      'variant': variant,
      'category': category,
      'category2': category2,
      'category3': category3,
      'category4': category4,
      'category5': category5,
      'price': price,
      'quantity': quantity,
      'refund': refund,
      'coupon': coupon,
      'affiliation': affiliation,
      'locationId': locationId,
      'listId': listId,
      'listName': listName,
      'listIndex': listIndex,
      'promotionId': promotionId,
      'promotionName': promotionName,
      'creativeName': creativeName,
      'creativeSlot': creativeSlot,
      'transactionId': _transactionId,
      'itemParams': itemParams?.length ?? 0,
    };
  }

  /// Creates instance from JSON map
  factory MetriqusInAppRevenue.fromJson(Map<String, dynamic> json) {
    final revenue = MetriqusInAppRevenue();
    revenue._revenue = json['revenue']?.toDouble();
    revenue._currency = json['currency'];
    revenue.productId = json['productId'];
    revenue.name = json['name'];
    revenue.brand = json['brand'];
    revenue.variant = json['variant'];
    revenue.category = json['category'];
    revenue.category2 = json['category2'];
    revenue.category3 = json['category3'];
    revenue.category4 = json['category4'];
    revenue.category5 = json['category5'];
    revenue.price = json['price']?.toDouble();
    revenue.quantity = json['quantity'];
    revenue.refund = json['refund']?.toDouble();
    revenue.coupon = json['coupon'];
    revenue.affiliation = json['affiliation'];
    revenue.locationId = json['locationId'];
    revenue.listId = json['listId'];
    revenue.listName = json['listName'];
    revenue.listIndex = json['listIndex'];
    revenue.promotionId = json['promotionId'];
    revenue.promotionName = json['promotionName'];
    revenue.creativeName = json['creativeName'];
    revenue.creativeSlot = json['creativeSlot'];
    revenue._transactionId = json['transactionId'];
    // itemParams will be handled separately when TypedParameter.fromJson is available
    return revenue;
  }
}
