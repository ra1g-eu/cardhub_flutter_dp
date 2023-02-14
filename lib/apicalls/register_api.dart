import 'dart:convert';
import 'dart:developer';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:http/http.dart' as http;
import 'package:cardhub/structures/constants.dart';

class RegisterApi {
  Future<String> registerWithCode(String uniqueId) async {
    try {
      Trace registerTrace = FirebasePerformance.instance.newTrace('apicalls/register_api/registerWithCode');
      await registerTrace.start();
      var response = await http.post(
        Uri.parse(
            "${ApiConstants.baseUrl}${ApiConstants.registerWithCode}/"),
        headers: <String, String>{
          "Content-type": "application/json",
          "Accept": "application/json",
          'App-Request-Header': 'CardHub/REQ/CH/1.0.0',
        },
          body: jsonEncode(<String, dynamic>{
            'registrationCode': uniqueId,
            'maxUsersLimit': 300,
          })
      ).timeout(
        const Duration(seconds: 7),
      );
      await registerTrace.stop();
      if (jsonDecode(response.body)['status'] == "success") {
        return 'registerSuccess';
      } else if (jsonDecode(response.body)['status'] == "error") {
        return jsonDecode(response.body)['message'];
      } else {
        Exception e = Exception(jsonDecode(response.body)['message']);
        await FirebaseCrashlytics.instance.recordError(
            e,
            StackTrace.current,
            reason: 'apicalls/register_api/corrupted_json_response'
        );
        throw e;
      }
    } catch (e) {
      await FirebaseCrashlytics.instance.recordError(
          e,
          StackTrace.current,
          reason: 'apicalls/register_api/try_catch'
      );
    }
    return 'apiError';
  }
}
