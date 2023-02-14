import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
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
    Trace initDBTrace = FirebasePerformance.instance.newTrace('database/dbhelper/initDB');
    await initDBTrace.start();
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
    await initDBTrace.stop();
    return await openDatabase(path, readOnly: false);
  }

  Future<void> purgeDBAfterLogOut() async {
    Trace purgeDBTrace = FirebasePerformance.instance.newTrace('database/dbhelper/purgeDBAfterLogOut');
    await purgeDBTrace.start();
    var dbClient = await db;
    await dbClient.rawQuery('DELETE FROM shops');
    await dbClient.rawQuery('DELETE FROM cards');
    await dbClient.rawQuery('DELETE FROM cards_favorite');
    await dbClient.rawQuery('DELETE FROM sqlite_sequence');
    await purgeDBTrace.stop();
  }

  Future<void> saveSingleCard(var cardToSave) async {
    Trace saveSingleCardTrace = FirebasePerformance.instance.newTrace('database/dbhelper/saveSingleCard');
    await saveSingleCardTrace.start();
    List cardUpload = cardToSave;

    var dbClient = await db;

    for (var val in cardUpload) {
      Cards cards = Cards.fromMap(val);
      await dbClient.insert('shops', cards.toMap());
    }
    await saveSingleCardTrace.stop();
  }

  Future<void> editCard(CardToEdit cardToEdit) async {
    Trace editCardTrace = FirebasePerformance.instance.newTrace('database/dbhelper/editCard');
    await editCardTrace.start();
    var dbClient = await db;
    await dbClient.rawUpdate('UPDATE cards SET cardNotes = ?, cardManualCode = ? WHERE cardUuid = ?', [cardToEdit.cardNotes, cardToEdit.cardManualCode, cardToEdit.cardUuid]);
    await editCardTrace.stop();
  }

  Future<void> saveCards(var cardsInJson) async {
    Trace saveCardsTrace = FirebasePerformance.instance.newTrace('database/dbhelper/saveCards');
    Trace saveCardsTraceParseCards = FirebasePerformance.instance.newTrace('database/dbhelper/saveCards/forLoop_ParseCardsList');
    Trace saveCardsTraceInsertDB = FirebasePerformance.instance.newTrace('database/dbhelper/saveCards/forLoop_InsertToDB');
    await saveCardsTrace.start();

    var dbClient = await db;

    await saveCardsTraceParseCards.start();
    List cardsList = cardsInJson;
    for (var item in cardsList) {
      //replace network image with base64 encoding to not be dependent on internet connection
      if (item['card_image'] != '--') {
        item['card_image'] =
            await networkImageToBase64(Uri.parse(item['card_image']));
      }
      item['shopLogo'] = await networkImageToBase64(Uri.parse(item['shopLogo']));
      await dbClient.rawQuery('INSERT OR IGNORE INTO cards_favorite (cardUuid, isFavorite, timesClicked) VALUES (?, ?, ?)', [item['card_uuid'], 0, 0]);
    }
    await saveCardsTraceParseCards.stop();


    await dbClient.delete("cards");
    Batch batch = dbClient.batch();

    await saveCardsTraceInsertDB.start();
    for (var val in cardsList) {
      Cards card = Cards.fromMap(val);
      batch.insert('cards', card.toMap());
    }
    await saveCardsTraceInsertDB.stop();

    batch.commit();
    await saveCardsTrace.stop();
  }

  Future<void> saveShops(var shopsInJson) async {
    Trace saveShopsTrace = FirebasePerformance.instance.newTrace('database/dbhelper/saveShops');
    Trace saveShopsTraceForLoop = FirebasePerformance.instance.newTrace('database/dbhelper/saveShops/forLoop_ParseShopsList');
    Trace saveShopsTraceShopsList = FirebasePerformance.instance.newTrace('database/dbhelper/saveShops/forLoop_InsertToDB');
    await saveShopsTrace.start();

    await saveShopsTraceForLoop.start();
    List shopsList = shopsInJson;
    for (var item in shopsList) {
      //replace network image with base64 encoding to not be dependent on internet connection
      item['shopLogo'] =
          await networkImageToBase64(Uri.parse(item['shopLogo']));
    }
    await saveShopsTraceForLoop.stop();


    var dbClient = await db;
    await dbClient.rawQuery('DELETE FROM shops');
    Batch batch = dbClient.batch();

    await saveShopsTraceShopsList.start();
    for (var val in shopsList) {
      Shops shops = Shops.fromMap(val);
      batch.insert('shops', shops.toMap());
    }
    await saveShopsTraceShopsList.stop();
    batch.commit();
    await saveShopsTrace.stop();
  }

  Future<List<Cards>> getCards() async {
    Trace getCardsTrace = FirebasePerformance.instance.newTrace('database/dbhelper/getCards');
    Trace getCardsTraceAddToMap = FirebasePerformance.instance.newTrace('database/dbhelper/getCards/forLoop_AddCardsToList');
    await getCardsTrace.start();
    var dbClient = await db;
    List<Map> list = await dbClient.rawQuery('SELECT * FROM cards');
    List<Cards> cards = [];

    await getCardsTraceAddToMap.start();
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
    await getCardsTraceAddToMap.stop();
    //print("db_helper.getUA() database length: "+ua.length.toString());
    await getCardsTrace.stop();
    return cards;
  }

  Future<List<Cards>> getCardsWithExtraInfo() async {
    Trace getCardsTrace = FirebasePerformance.instance.newTrace('database/dbhelper/getCardsWithExtraInfo');
    Trace getCardsTraceAddToList = FirebasePerformance.instance.newTrace('database/dbhelper/getCardsWithExtraInfo/forLoop_AddCardsToList');
    await getCardsTrace.start();
    // get also isFavorite and timesClicked parameters
    var dbClient = await db;
    List<Map> list = await dbClient.rawQuery(
        'SELECT cards.cardUuid, cards.cardName as cardName, cards.cardImage as cardImage, cards.cardNotes as cardNotes, cards.cardManualCode as cardManualCode, cards.shopLogo as shopLogo, cards.shopName as shopName, cards.shopUrlSk as shopUrlSk, cards.shopUrlCz as shopUrlCz, cards.countryName as countryName, cards_favorite.isFavorite as isFavorite, cards_favorite.timesClicked as timesClicked FROM cards'
            ' INNER JOIN cards_favorite ON cards_favorite.cardUuid=cards.cardUuid');
    List<Cards> cards = [];

    await getCardsTraceAddToList.start();
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
    await getCardsTraceAddToList.stop();

    //print("db_helper.getUA() database length: "+ua.length.toString());
    await getCardsTrace.stop();
    return cards;
  }
  
  Future<bool> isCardFavorite(String cardUuid) async{
    Trace isCardFavoriteTrace = FirebasePerformance.instance.newTrace('database/dbhelper/isCardFavorite');
    await isCardFavoriteTrace.start();
    var dbClient = await db;
    int? rowLength = Sqflite.firstIntValue(await dbClient.rawQuery('SELECT isFavorite FROM cards_favorite WHERE cardUuid = ? AND isFavorite = 1', [cardUuid])) ?? 0;
    //print(rowLength);
    await isCardFavoriteTrace.stop();
    if(rowLength > 0){
      return true;
    } else {
      return false;
    }
  }

  Future<void> setCardFavorite(String cardUuid, bool status) async{
    Trace setCardFavoriteTrace = FirebasePerformance.instance.newTrace('database/dbhelper/setCardFavorite');
    await setCardFavoriteTrace.start();
    var dbClient = await db;
    await dbClient.rawUpdate('UPDATE cards_favorite SET isFavorite = ? WHERE cardUuid = ?', [status ? 1 : 0, cardUuid]);
    //print('card $cardUuid updated with isFavorite value ${status ? 1 : 0}');
    await setCardFavoriteTrace.stop();
  }

  Future<void> updateTimesClicked(String cardUuid) async{
    Trace updateTimesClickedTrace = FirebasePerformance.instance.newTrace('database/dbhelper/updateTimesClicked');
    await updateTimesClickedTrace.start();
    var dbClient = await db;
    int? rowLength = Sqflite.firstIntValue(await dbClient.rawQuery('SELECT * FROM cards_favorite WHERE cardUuid = ? LIMIT 1', [cardUuid])) ?? 0;
    if(rowLength > 0){
      await dbClient.rawUpdate('UPDATE cards_favorite SET timesClicked = timesClicked+1 WHERE cardUuid = ?', [cardUuid]);
      print('updated card visit $cardUuid');
    } else {
      await dbClient.rawInsert('INSERT INTO cards_favorite (cardUuid, isFavorite, timesClicked) VALUES (?, ?, ?)', [cardUuid, 0, 0]);
      print('inserted first card visit $cardUuid');
    }
    await updateTimesClickedTrace.stop();
  }

  Future<List<Shops>> getShops() async {
    Trace getShopsTrace = FirebasePerformance.instance.newTrace('database/dbhelper/getShops');
    Trace getShopsTraceAddToList = FirebasePerformance.instance.newTrace('database/dbhelper/getShops/forLoop_AddShopsToList');
    await getShopsTrace.start();
    var dbClient = await db;
    List<Map> list = await dbClient.rawQuery('SELECT * FROM shops');
    List<Shops> shops = [];

    await getShopsTraceAddToList.start();
    for (int i = 0; i < list.length; i++) {
      shops.add(
          Shops(list[i]["shopId"], list[i]["shopName"], list[i]["shopLogo"]));
    }
    await getShopsTraceAddToList.stop();

    await getShopsTrace.stop();
    return shops;
  }

  Future<List<Cards>> getSingleCard(String cardUuid) async {
    Trace getSingleCardTrace = FirebasePerformance.instance.newTrace('database/dbhelper/getSingleCard');
    Trace getSingleCardTraceAddToList = FirebasePerformance.instance.newTrace('database/dbhelper/getSingleCard/forLoop_AddCardsToList');
    await getSingleCardTrace.start();
    var dbClient = await db;
    List<Map> list = await dbClient
        .rawQuery('SELECT * FROM cards WHERE cardUuid = "$cardUuid" LIMIT 1');
    List<Cards> card = [];

    await getSingleCardTraceAddToList.start();
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
    await getSingleCardTraceAddToList.stop();

    await getSingleCardTrace.stop();
    return card;
  }

  Future<List<Cards>> getCardForEdit(String cardUuid) async {
    Trace getCardForEditTrace = FirebasePerformance.instance.newTrace('database/dbhelper/getCardForEdit');
    Trace getCardForEditTraceAddToList = FirebasePerformance.instance.newTrace('database/dbhelper/getCardForEdit/forLoop_AddCardsToList');
    await getCardForEditTrace.start();
    var dbClient = await db;
    List<Map> list = await dbClient
        .rawQuery('SELECT * FROM cards WHERE cardUuid = "$cardUuid"');
    List<Cards> card = [];

    await getCardForEditTraceAddToList.start();
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
    await getCardForEditTraceAddToList.stop();

    await getCardForEditTrace.stop();
    return card;
  }

  Future networkImageToBase64(Uri url) async {
    try {
      Trace networkImageToBase64Trace = FirebasePerformance.instance.newTrace('database/dbhelper/networkImageToBase64');
      await networkImageToBase64Trace.start();
      http.Response response = await http.get(url);
      await networkImageToBase64Trace.stop();
      return base64.encode(response.bodyBytes);
    } catch (e) {
      await FirebaseCrashlytics.instance.recordError(
          e,
          StackTrace.current,
          reason: 'database/dbhelper/networkImageToBase64/try_catch'
      );
    }
  }

  Future<String> deleteCard(String cardUuid) async {
    Trace deleteCardTrace = FirebasePerformance.instance.newTrace('database/dbhelper/deleteCard');
    await deleteCardTrace.start();
    var dbClient = await db;
    int rowDel = await dbClient
        .rawDelete('DELETE FROM cards WHERE cardUuid = ?', [cardUuid]);
    await deleteCardTrace.stop();
    if (rowDel > 0) {
      return 'cardDeleted';
    } else {
      return 'cardNotDeleted';
    }
  }
}
