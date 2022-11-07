import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:cardhub/structures/constants.dart';
import 'package:cardhub/database/dbhelper.dart';

import '../pages/create_new_card.dart';

class UploadCard {
  Future<String> uploadCardToDB(String loginCode, CardToUpload cardToUpload) async {
    try {
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
      );
      print(response.body);
      if (jsonDecode(response.body)['status'] == "error") {
        return 'uploadFail';
      } else {
        return 'uploadSuccess';
      }
    } catch (e) {
      print('UploadCard error try catch');
      log(e.toString());
    }
    return 'apiError';
  }
}
