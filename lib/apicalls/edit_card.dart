import 'dart:convert';
import 'dart:developer';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:http/http.dart' as http;
import 'package:cardhub/structures/constants.dart';
import 'package:cardhub/database/dbhelper.dart';

import '../pages/details_card.dart';

class EditCard {
  Future<String> EditCardToDB(String loginCode, CardToEdit cardToEdit) async {
    try {
      Trace editCardTrace = FirebasePerformance.instance.newTrace('apicalls/edit_card/EditCardToDB');
      await editCardTrace.start();
      var response = await http.post(
        Uri.parse(
            "${ApiConstants.baseUrl}${ApiConstants.editCardWithCode}"),
        headers: <String, String>{
          "Content-type": "application/json",
          "Accept": "application/json",
          'Authorization': 'SystemCode $loginCode',
          'App-Request-Header': 'CardHub/REQ/CH/1.0.0',
        },
        body: jsonEncode(<String, dynamic>{
          'cardUuid': cardToEdit.cardUuid,
          'cardDesc': cardToEdit.cardNotes,
          'cardManualCode': cardToEdit.cardManualCode,
        }),
      ).timeout(
        const Duration(seconds: 7),
      );
      await editCardTrace.stop();
      if (jsonDecode(response.body)['status'] == "error") {
        print(jsonDecode(response.body)['message']);
        return 'editFail';
      } else {
        await DBHelper().editCard(cardToEdit);
        return 'editSuccess';
      }
    } catch (e) {
      await FirebaseCrashlytics.instance.recordError(
          e,
          StackTrace.current,
          reason: 'apicalls/edit_card/try_catch'
      );
    }
    return 'apiError';
  }
}
