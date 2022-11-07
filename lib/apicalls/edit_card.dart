import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:cardhub/structures/constants.dart';
import 'package:cardhub/database/dbhelper.dart';

import '../pages/details_card.dart';

class EditCard {
  Future<String> EditCardToDB(String loginCode, CardToEdit cardToEdit) async {
    try {
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
      );
      if (jsonDecode(response.body)['status'] == "error") {
        print(jsonDecode(response.body)['message']);
        return 'editFail';
      } else {
        await DBHelper().editCard(cardToEdit);
        return 'editSuccess';
      }
    } catch (e) {
      print('EditCard error try catch');
      log(e.toString());
    }
    return 'apiError';
  }
}
