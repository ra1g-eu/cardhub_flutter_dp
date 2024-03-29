import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:cardhub/structures/constants.dart';
import 'package:cardhub/database/dbhelper.dart';

class GetAllShops {
  Future<String> getShopsWithCode(String loginCode) async {
    try {
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
      if (jsonDecode(response.body)['status'] == "success") {
        final shopsOnly = jsonDecode(response.body)['message'];
        await DBHelper().saveShops(shopsOnly);
        return 'shopsSuccess';
      } else if (jsonDecode(response.body)['status'] == "error") {
        return jsonDecode(response.body)['message'];
      } else {
        Exception e = Exception(jsonDecode(response.body)['message']);
        print(e.toString());
      }
    } catch (e) {
      print(e.toString());
    }
    return 'apiError';
  }
}
