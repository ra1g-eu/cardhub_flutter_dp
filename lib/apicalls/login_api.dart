import 'dart:convert';
import 'dart:developer';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:http/http.dart' as http;
import 'package:cardhub/structures/constants.dart';
import 'package:cardhub/database/dbhelper.dart';

class LoginApi {
  Future<String> loginWithCode(String loginCode) async {
    try {
      Trace loginTrace = FirebasePerformance.instance.newTrace('apicalls/login_api/loginWithCode');
      await loginTrace.start();
      var response = await http.get(
        Uri.parse(
            "${ApiConstants.baseUrl}${ApiConstants.loginWithCode}/${loginCode.split("#")[0]}/${loginCode.split("#")[1]}"),
        headers: <String, String>{
          'Authorization': 'SystemCode $loginCode',
          'App-Request-Header': 'CardHub/REQ/CH/1.0.0',
        },
      ).timeout(
        const Duration(seconds: 7),
      );
      await loginTrace.stop();
      if (jsonDecode(response.body)['status'] == "success") {
        final cardsOnly = jsonDecode(response.body)['message'];
        //print(cardsOnly);
        if(cardsOnly != "Zatiaľ nemáš žiadne karty!"){
          await DBHelper().saveCards(cardsOnly);
        }
        return 'loginSuccess';
      } else if (jsonDecode(response.body)['status'] == "error") {
        return jsonDecode(response.body)['message'];
      } else {
        Exception e = Exception(jsonDecode(response.body)['message']);
        await FirebaseCrashlytics.instance.recordError(
            e,
            StackTrace.current,
            reason: 'apicalls/login_api/corrupted_json_response'
        );
        throw e;
      }
    } catch (e) {
      await FirebaseCrashlytics.instance.recordError(
          e,
          StackTrace.current,
          reason: 'apicalls/login_api/try_catch'
      );
    }
    return 'apiError';
  }
}
