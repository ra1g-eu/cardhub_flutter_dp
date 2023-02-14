import 'dart:convert';
import 'dart:developer';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:http/http.dart' as http;
import 'package:cardhub/structures/constants.dart';
import 'package:cardhub/database/dbhelper.dart';

class LogOutApi {
  Future<String> logOutWithCode(String loginCode, bool isLateLogOut) async {
    try {
      Trace logOutTrace = FirebasePerformance.instance.newTrace('apicalls/logout/logOutWithCode');
      await logOutTrace.start();
      var response = await http.get(
        Uri.parse(
            "${ApiConstants.baseUrl}${ApiConstants.logoutWithCode}/${loginCode.split("#")[0]}/${loginCode.split("#")[1]}"),
        headers: <String, String>{
          'Authorization': 'SystemCode $loginCode',
          'App-Request-Header': 'CardHub/REQ/CH/1.0.0',
        },
      ).timeout(
        const Duration(seconds: 7),
      );
      await logOutTrace.stop();
      if (jsonDecode(response.body)['status'] == "success") {
        if(!isLateLogOut){
          await DBHelper().purgeDBAfterLogOut();
          return 'logoutSuccess';
        }
        return 'lateLogoutSuccess';
      } else if (jsonDecode(response.body)['status'] == "error") {
        return jsonDecode(response.body)['message'];
      } else {
        Exception e = Exception(jsonDecode(response.body)['message']);
        await FirebaseCrashlytics.instance.recordError(
            e,
            StackTrace.current,
            reason: 'apicalls/logout/corrupted_json_response'
        );
        throw e;
      }
    } catch (e) {
      await FirebaseCrashlytics.instance.recordError(
          e,
          StackTrace.current,
          reason: 'apicalls/logout/try_catch'
      );
    }
    return 'apiError';
  }

  Future<bool> forceLogOut() async{
    await DBHelper().purgeDBAfterLogOut();
    return true;
  }
}
