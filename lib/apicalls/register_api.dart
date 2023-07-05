import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:cardhub/structures/constants.dart';

class RegisterApi {
  Future<String> registerWithCode(String uniqueId) async {
    try {
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
      if (jsonDecode(response.body)['status'] == "success") {
        return 'registerSuccess';
      } else if (jsonDecode(response.body)['status'] == "error") {
        return jsonDecode(response.body)['message'];
      } else {
        Exception e = Exception(jsonDecode(response.body)['message']);
        log(e.toString());
      }
    } catch (e) {
      log(e.toString());
    }
    return 'apiError';
  }
}
