import 'dart:convert';
import 'dart:developer';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'package:firebase_performance/firebase_performance.dart';
import 'package:http/http.dart' as http;
import 'package:cardhub/structures/constants.dart';
import 'package:cardhub/database/dbhelper.dart';

class GetAllCards {
  Future<String> getCardsWithCode(String loginCode) async {
    final getCardsNetworkTrace = FirebasePerformance.instance
        .newHttpMetric("${ApiConstants.baseUrl}${ApiConstants.getCardsWithCode}", HttpMethod.Get);
    try {
      Trace getCardsTrace = FirebasePerformance.instance.newTrace('apicalls/get_all_cards/getCardsWithCode');
      await getCardsTrace.start();
      await getCardsNetworkTrace.start();
      var response = await http.get(
        Uri.parse(
            "${ApiConstants.baseUrl}${ApiConstants.getCardsWithCode}/${loginCode.split("#")[0]}/${loginCode.split("#")[1]}"),
        headers: <String, String>{
          'Authorization': 'SystemCode $loginCode',
          'App-Request-Header': 'CardHub/REQ/CH/1.0.0',
        },
      ).timeout(
        const Duration(seconds: 7),
      );
      await getCardsTrace.stop();

      if (jsonDecode(response.body)['status'] == "success") {
        final cardsOnly = jsonDecode(response.body)['message'];
        await DBHelper().saveCards(cardsOnly);
        return 'cardsSuccess';
      } else if (jsonDecode(response.body)['status'] == "error") {
        return jsonDecode(response.body)['message'];
      } else {
        Exception e = Exception(jsonDecode(response.body)['message']);
        await FirebaseCrashlytics.instance.recordError(
            e,
            StackTrace.current,
            reason: 'apicalls/get_all_cards/corrupted_json_response'
        );
        throw e;
      }
    } catch (e) {
      await FirebaseCrashlytics.instance.recordError(
          e,
          StackTrace.current,
          reason: 'apicalls/get_all_cards/try_catch'
      );
      //log(e.toString());
    } finally {
      await getCardsNetworkTrace.stop();
    }
    return 'apiError';
  }
}
