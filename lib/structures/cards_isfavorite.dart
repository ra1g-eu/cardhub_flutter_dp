// To parse this JSON data, do
//
//     final cardsIsFavorite = cardsIsFavoriteFromMap(jsonString);

import 'dart:convert';

List<CardsIsFavorite> cardsIsFavoriteFromMap(String str) => List<CardsIsFavorite>.from(json.decode(str).map((x) => CardsIsFavorite.fromMap(x)));

String cardsIsFavoriteToMap(List<CardsIsFavorite> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class CardsIsFavorite {
  CardsIsFavorite({
    required this.id,
    required this.cardUuid,
    required this.isFavorite,
    required this.timesClicked,
  });

  String id;
  String cardUuid;
  bool isFavorite;
  int timesClicked;

  factory CardsIsFavorite.fromMap(Map<String, dynamic> json) => CardsIsFavorite(
    id: json["id"],
    cardUuid: json["cardUuid"],
    isFavorite: json["isFavorite"],
    timesClicked: json['timesClicked'],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "cardUuid": cardUuid,
    "isFavorite": isFavorite,
    "timesClicked": timesClicked,
  };
}