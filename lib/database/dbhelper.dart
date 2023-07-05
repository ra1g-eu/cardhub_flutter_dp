import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:cardhub/structures/cards.dart';
import 'package:cardhub/structures/constants.dart';
import 'package:http/http.dart' as http;

import '../pages/details_card.dart';
import '../structures/shops.dart';

class DBHelper {
  static Database? _db;

  Future<Database> get db async => _db ??= await initDB();

  Future<Database> initDB() async {
    var dbPath = await getDatabasesPath();
    var path = join(dbPath, ApiConstants.dbName);

    var exists = await databaseExists(path);
    if (!exists) {
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}
      ByteData data = await rootBundle.load(join("db", ApiConstants.dbName));
      List<int> bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes, flush: true);
    }
    return await openDatabase(path, readOnly: false);
  }

  Future<void> purgeDBAfterLogOut() async {
    var dbClient = await db;
    await dbClient.rawQuery('DELETE FROM shops');
    await dbClient.rawQuery('DELETE FROM cards');
    await dbClient.rawQuery('DELETE FROM cards_favorite');
    await dbClient.rawQuery('DELETE FROM sqlite_sequence');
  }

  Future<void> saveSingleCard(var cardToSave) async {
    List cardUpload = cardToSave;

    var dbClient = await db;

    for (var val in cardUpload) {
      Cards cards = Cards.fromMap(val);
      await dbClient.insert('shops', cards.toMap());
    }
  }

  Future<void> editCard(CardToEdit cardToEdit) async {
    ;
    var dbClient = await db;
    await dbClient.rawUpdate(
        'UPDATE cards SET cardNotes = ?, cardManualCode = ? WHERE cardUuid = ?',
        [cardToEdit.cardNotes, cardToEdit.cardManualCode, cardToEdit.cardUuid]);
  }

  Future<void> saveCards(var cardsInJson) async {
    var dbClient = await db;

    List cardsList = cardsInJson;
    for (var item in cardsList) {
      //replace network image with base64 encoding to not be dependent on internet connection
      if (item['card_image'] != '--') {
        item['card_image'] =
            await networkImageToBase64(Uri.parse(item['card_image']));
      }
      item['shopLogo'] =
          await networkImageToBase64(Uri.parse(item['shopLogo']));
      await dbClient.rawQuery(
          'INSERT OR IGNORE INTO cards_favorite (cardUuid, isFavorite, timesClicked) VALUES (?, ?, ?)',
          [item['card_uuid'], 0, 0]);
    }

    await dbClient.delete("cards");
    Batch batch = dbClient.batch();

    for (var val in cardsList) {
      Cards card = Cards.fromMap(val);
      batch.insert('cards', card.toMap());
    }

    batch.commit();
  }

  Future<void> saveShops(var shopsInJson) async {
    List shopsList = shopsInJson;
    for (var item in shopsList) {
      //replace network image with base64 encoding to not be dependent on internet connection
      item['shopLogo'] =
          await networkImageToBase64(Uri.parse(item['shopLogo']));
    }

    var dbClient = await db;
    await dbClient.rawQuery('DELETE FROM shops');
    Batch batch = dbClient.batch();
    for (var val in shopsList) {
      Shops shops = Shops.fromMap(val);

      batch.insert('shops', shops.toMap());
    }

    batch.commit();
  }

  Future<List<Cards>> getCards() async {
    var dbClient = await db;
    List<Map> list = await dbClient.rawQuery('SELECT * FROM cards');
    List<Cards> cards = [];

    for (int i = 0; i < list.length; i++) {
      cards.add(Cards(
          list[i]["cardUuid"],
          list[i]["cardName"],
          list[i]["cardImage"],
          list[i]["cardNotes"],
          list[i]["cardManualCode"],
          list[i]["shopLogo"],
          list[i]["shopName"],
          list[i]["shopUrlSk"],
          list[i]["shopUrlCz"],
          list[i]["countryName"]));
    }

    //print("db_helper.getUA() database length: "+ua.length.toString());

    return cards;
  }

  Future<List<Cards>> getCardsWithExtraInfo() async {
    // get also isFavorite and timesClicked parameters
    var dbClient = await db;
    List<Map> list = await dbClient.rawQuery(
        'SELECT cards.cardUuid, cards.cardName as cardName, cards.cardImage as cardImage, cards.cardNotes as cardNotes, cards.cardManualCode as cardManualCode, cards.shopLogo as shopLogo, cards.shopName as shopName, cards.shopUrlSk as shopUrlSk, cards.shopUrlCz as shopUrlCz, cards.countryName as countryName, cards_favorite.isFavorite as isFavorite, cards_favorite.timesClicked as timesClicked FROM cards'
        ' INNER JOIN cards_favorite ON cards_favorite.cardUuid=cards.cardUuid');
    List<Cards> cards = [];

    for (int i = 0; i < list.length; i++) {
      cards.add(Cards(
          list[i]["cardUuid"],
          list[i]["cardName"],
          list[i]["cardImage"],
          list[i]["cardNotes"],
          list[i]["cardManualCode"],
          list[i]["shopLogo"],
          list[i]["shopName"],
          list[i]["shopUrlSk"],
          list[i]["shopUrlCz"],
          list[i]["countryName"],
          list[i]["isFavorite"] == 1 ? true : false,
          list[i]["timesClicked"]));
    }

    //print("db_helper.getUA() database length: "+ua.length.toString());

    return cards;
  }

  Future<bool> isCardFavorite(String cardUuid) async {
    var dbClient = await db;
    int? rowLength = Sqflite.firstIntValue(await dbClient.rawQuery(
            'SELECT isFavorite FROM cards_favorite WHERE cardUuid = ? AND isFavorite = 1',
            [cardUuid])) ??
        0;
    //print(rowLength);
    if (rowLength > 0) {
      return true;
    } else {
      return false;
    }
  }

  Future<void> setCardFavorite(String cardUuid, bool status) async {
    var dbClient = await db;
    await dbClient.rawUpdate(
        'UPDATE cards_favorite SET isFavorite = ? WHERE cardUuid = ?',
        [status ? 1 : 0, cardUuid]);
    //print('card $cardUuid updated with isFavorite value ${status ? 1 : 0}');
  }

  Future<void> updateTimesClicked(String cardUuid) async {
    var dbClient = await db;
    int? rowLength = Sqflite.firstIntValue(await dbClient.rawQuery(
            'SELECT * FROM cards_favorite WHERE cardUuid = ? LIMIT 1',
            [cardUuid])) ??
        0;
    if (rowLength > 0) {
      await dbClient.rawUpdate(
          'UPDATE cards_favorite SET timesClicked = timesClicked+1 WHERE cardUuid = ?',
          [cardUuid]);
      print('updated card visit $cardUuid');
    } else {
      await dbClient.rawInsert(
          'INSERT INTO cards_favorite (cardUuid, isFavorite, timesClicked) VALUES (?, ?, ?)',
          [cardUuid, 0, 0]);
      print('inserted first card visit $cardUuid');
    }
  }

  Future<List<Shops>> getShops() async {
    var dbClient = await db;
    List<Map> list = await dbClient.rawQuery('SELECT * FROM shops');
    List<Shops> shops = [];

    for (int i = 0; i < list.length; i++) {
      shops.add(
          Shops(list[i]["shopId"], list[i]["shopName"], list[i]["shopLogo"]));
    }

    return shops;
  }

  Future<List<Cards>> getSingleCard(String cardUuid) async {
    var dbClient = await db;
    List<Map> list = await dbClient
        .rawQuery('SELECT * FROM cards WHERE cardUuid = ? LIMIT 1', [cardUuid]);
    List<Cards> card = [];

    for (int i = 0; i < list.length; i++) {
      card.add(Cards(
          list[i]["cardUuid"],
          list[i]["cardName"],
          list[i]["cardImage"],
          list[i]["cardNotes"],
          list[i]["cardManualCode"],
          list[i]["shopLogo"],
          list[i]["shopName"],
          list[i]["shopUrlSk"],
          list[i]["shopUrlCz"],
          list[i]["countryName"]));
    }

    return card;
  }

  Future<List<Cards>> getCardForEdit(String cardUuid) async {
    var dbClient = await db;
    List<Map> list = await dbClient
        .rawQuery('SELECT * FROM cards WHERE cardUuid = ?', [cardUuid]);
    List<Cards> card = [];

    for (int i = 0; i < list.length; i++) {
      card.add(Cards(
          list[i]["cardUuid"],
          list[i]["cardName"],
          list[i]["cardImage"],
          list[i]["cardNotes"],
          list[i]["cardManualCode"],
          list[i]["shopLogo"],
          list[i]["shopName"],
          list[i]["shopUrlSk"],
          list[i]["shopUrlCz"],
          list[i]["countryName"]));
    }

    return card;
  }

  Future networkImageToBase64(Uri url) async {
    try {
      http.Response response = await http.get(url);

      String toEncode;
      String encoded;
      toEncode = base64.encode(response.bodyBytes);
      encoded = toEncode;

      return encoded;
    } catch (e) {
      print(e.toString());
    }
  }

  Future<String> deleteCard(String cardUuid) async {
    var dbClient = await db;
    int rowDel = await dbClient
        .rawDelete('DELETE FROM cards WHERE cardUuid = ?', [cardUuid]);
    if (rowDel > 0) {
      return 'cardDeleted';
    } else {
      return 'cardNotDeleted';
    }
  }
}
