import 'dart:convert';
import 'dart:developer';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:http/http.dart' as http;
import 'package:cardhub/structures/constants.dart';
import 'package:cardhub/database/dbhelper.dart';

class DeleteCard {
  Future<String> deleteCardWithCode(String loginCode, String cardUuid) async {
    try {
      Trace deleteCardTrace = FirebasePerformance.instance.newTrace('apicalls/delete_card/deleteCardWithCode');
      await deleteCardTrace.start();
      var response = await http.get(
        Uri.parse(
            "${ApiConstants.baseUrl}${ApiConstants.deleteCardWithCode}/${loginCode.split("#")[0]}/${loginCode.split("#")[1]}/$cardUuid"),
        headers: <String, String>{
          'Authorization': 'SystemCode $loginCode',
          'App-Request-Header': 'CardHub/REQ/CH/1.0.0',
        },
      ).timeout(
        const Duration(seconds: 7),
      );
      await deleteCardTrace.start();
      if (jsonDecode(response.body)['status'] == "success") {
        String result = await DBHelper().deleteCard(cardUuid);
        if(result == 'cardDeleted'){
          return 'deleteSuccess';
        } else {
          return 'deleteFail';
        }
      } else if (jsonDecode(response.body)['status'] == "error") {
        return jsonDecode(response.body)['message'];
      } else {
        throw Exception(jsonDecode(response.body)['message']);
      }
    } catch (e) {
      await FirebaseCrashlytics.instance.recordError(
          e,
          StackTrace.current,
          reason: 'apicalls/delete_card/try_catch'
      );
    }
    return 'apiError';
  }
}
