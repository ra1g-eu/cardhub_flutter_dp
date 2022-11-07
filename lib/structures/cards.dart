// To parse this JSON data, do
//
//     final cards = cardsFromMap(jsonString);

import 'dart:convert';

List<Cards> cardsFromMap(String str) =>
    List<Cards>.from(json.decode(str).map((x) => Cards.fromMap(x)));

String cardsToMap(List<Cards> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class Cards {
  late String cardUuid;
  late String cardName;
  late String cardImage;
  late String cardNotes;
  late String manualCode;
  late String shopLogo;
  late String shopName;
  late String shopUrlSk;
  late String shopUrlCz;
  late String countryName;
  late bool isFavorite;
  late int timesClicked;

  Cards(
      this.cardUuid,
      this.cardName,
      this.cardImage,
      this.cardNotes,
      this.manualCode,
      this.shopLogo,
      this.shopName,
      this.shopUrlSk,
      this.shopUrlCz,
      this.countryName,
      [this.isFavorite = false, this.timesClicked = 0]);

  Cards.fromMap(Map<String, dynamic> map) {
    cardUuid = map["card_uuid"];
    cardName = map["card_name"];
    cardImage = map["card_image"];
    cardNotes = map["cardNotes"];
    manualCode = map["manualCode"];
    shopLogo = map["shopLogo"];
    shopName = map["shop_name"];
    shopUrlSk = map["shopUrlSK"];
    shopUrlCz = map["shopUrlCZ"];
    countryName = map["country_name"];
  }

  Map<String, dynamic> toMap() => {
        "cardUuid": cardUuid,
        "cardName": cardName,
        "cardImage": cardImage,
        "cardNotes": cardNotes,
        "cardManualCode": manualCode,
        "shopLogo": shopLogo,
        "shopName": shopName,
        "shopUrlSk": shopUrlSk,
        "shopUrlCz": shopUrlCz,
        "countryName": countryName,
      };
}
