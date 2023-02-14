import 'dart:convert';
import 'dart:developer';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';

import 'package:http/http.dart' as http;
import 'package:cardhub/structures/constants.dart';
import 'package:cardhub/database/dbhelper.dart';

import '../pages/create_new_card.dart';

class UploadCard {
  Future<String> uploadCardToDB(String loginCode, CardToUpload cardToUpload) async {
    try {
      Trace uploadCardTrace = FirebasePerformance.instance.newTrace('apicalls/upload_card/uploadCardToDB');
      await uploadCardTrace.start();
      var response = await http.post(
        Uri.parse(
            "${ApiConstants.baseUrl}${ApiConstants.uploadCardWithCode}"),
        headers: <String, String>{
          "Content-type": "application/json",
          "Accept": "application/json",
          'Authorization': 'SystemCode $loginCode',
          'App-Request-Header': 'CardHub/REQ/CH/1.0.0',
        },
        body: jsonEncode(<String, dynamic>{
          'cardName': cardToUpload.cardName,
          'cardCountry': cardToUpload.cardCountry,
          'shopId': cardToUpload.shopId,
          'cardDesc': cardToUpload.cardDescription,
          'cardManualCode': cardToUpload.cardCode,
        }),
      ).timeout(
        const Duration(seconds: 30),
      );
      await uploadCardTrace.stop();
      //print(response.body);
      if (jsonDecode(response.body)['status'] == "error") {
        return 'uploadFail';
      } else {
        return 'uploadSuccess';
      }
    } catch (e) {
      await FirebaseCrashlytics.instance.recordError(
          e,
          StackTrace.current,
          reason: 'apicalls/upload_card/try_catch'
      );
    }
    return 'apiError';
  }
}
