import 'dart:convert';

List<Product> productFromJson(String str) =>
    List<Product>.from(json.decode(str).map((x) => Product.fromJson(x)));

String productToJson(List<Product> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Product {
  int pk;
  Fields fields;

  Product({
    required this.pk,
    required this.fields,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        pk: json["pk"],
        fields: Fields.fromJson(json["fields"]),
      );

  Map<String, dynamic> toJson() => {
        "pk": pk,
        "fields": fields.toJson(),
      };
}

class Fields {
  String name;
  int price;
  String rating;
  String unitsSold;
  String imageUrl;
  String? store;
  String storeName;

  Fields({
    required this.name,
    required this.price,
    required this.rating,
    required this.unitsSold,
    required this.imageUrl,
    this.store,
    required this.storeName,
  });

  factory Fields.fromJson(Map<String, dynamic> json) => Fields(
        name: json["name"],
        price: json["price"],
        rating: json["rating"] ?? "-",
        unitsSold: json["units_sold"] ?? "-",
        imageUrl: json["image_url"] ?? "",
        store: json["store"]?.toString(),
        storeName: json["store_name"] ?? "Unknown Store",
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "price": price,
        "rating": rating,
        "units_sold": unitsSold,
        "image_url": imageUrl,
        "store": store,
        "store_name": storeName,
      };
}

class Cart {
  String status;
  List<CartItem> items;
  int totalPrice;

  Cart({
    required this.status,
    required this.items,
    required this.totalPrice,
  });

  factory Cart.fromJson(Map<String, dynamic> json) => Cart(
        status: json["status"],
        items: List<CartItem>.from(json["items"].map((x) => CartItem.fromJson(x))),
        totalPrice: json["total_price"],
      );
}

class CartItem {
  int id;
  CartProduct product;
  int quantity;
  int totalPrice;

  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.totalPrice,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: json["id"],
        product: CartProduct.fromJson(json["product"]),
        quantity: json["quantity"],
        totalPrice: json["total_price"],
      );
}

class CartProduct {
  int pk;
  String name;
  int price;
  String imageUrl;

  CartProduct({
    required this.pk,
    required this.name,
    required this.price,
    required this.imageUrl,
  });

  factory CartProduct.fromJson(Map<String, dynamic> json) => CartProduct(
        pk: json["pk"],
        name: json["name"],
        price: json["price"],
        imageUrl: json["image_url"] ?? "",
      );
}