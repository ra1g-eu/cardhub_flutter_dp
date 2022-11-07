// To parse this JSON data, do
//
//     final Shops = ShopsFromMap(jsonString);

import 'dart:convert';

List<Shops> shopsFromMap(String str) => List<Shops>.from(json.decode(str).map((x) => Shops.fromMap(x)));

String shopsToMap(List<Shops> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class Shops {
  late int shopId;
  late String shopName;
  late String shopLogo;

  Shops(
      this.shopId,
      this.shopName,
      this.shopLogo,
      );

  Shops.fromMap(Map<String, dynamic> map){
    shopId = map["shopId"];
    shopName = map["shopName"];
    shopLogo = map["shopLogo"];
  }

  Map<String, dynamic> toMap() => {
    "shopId": shopId,
    "shopName": shopName,
    "shopLogo": shopLogo,
  };
}
