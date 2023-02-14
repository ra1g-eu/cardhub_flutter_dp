import 'dart:convert';
import 'dart:developer';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:http/http.dart' as http;
import 'package:cardhub/structures/constants.dart';
import 'package:cardhub/database/dbhelper.dart';

class GetAllShops {
  Future<String> getShopsWithCode(String loginCode) async {
    try {
      Trace getShopsTrace = FirebasePerformance.instance.newTrace('apicalls/get_shops/getShopsWithCode');
      await getShopsTrace.start();
      var response = await http.get(
        Uri.parse(
            "${ApiConstants.baseUrl}${ApiConstants.getShopsWithCode}"),
        headers: <String, String>{
          'Authorization': 'SystemCode $loginCode',
          'App-Request-Header': 'CardHub/REQ/CH/1.0.0',
        },
      ).timeout(
        const Duration(seconds: 7),
      );
      await getShopsTrace.stop();
      if (jsonDecode(response.body)['status'] == "success") {
        final shopsOnly = jsonDecode(response.body)['message'];
        await DBHelper().saveShops(shopsOnly);
        return 'shopsSuccess';
      } else if (jsonDecode(response.body)['status'] == "error") {
        return jsonDecode(response.body)['message'];
      } else {
        Exception e = Exception(jsonDecode(response.body)['message']);
        await FirebaseCrashlytics.instance.recordError(
            e,
            StackTrace.current,
            reason: 'apicalls/get_shops/corrupted_json_response'
        );
        throw e;
      }
    } catch (e) {
      await FirebaseCrashlytics.instance.recordError(
          e,
          StackTrace.current,
          reason: 'apicalls/get_shops/try_catch'
      );
    }
    return 'apiError';
  }
}
