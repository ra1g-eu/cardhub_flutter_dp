import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:cardhub/structures/constants.dart';
import 'package:cardhub/database/dbhelper.dart';

class LogOutApi {
  Future<String> logOutWithCode(String loginCode, bool isLateLogOut) async {
    try {
      var response = await http.get(
        Uri.parse(
            "${ApiConstants.baseUrl}${ApiConstants.logoutWithCode}/${loginCode.split("#")[0]}/${loginCode.split("#")[1]}"),
        headers: <String, String>{
          'Authorization': 'SystemCode $loginCode',
          'App-Request-Header': 'CardHub/REQ/CH/1.0.0',
        },
      );
      if (jsonDecode(response.body)['status'] == "success") {
        if(!isLateLogOut){
          await DBHelper().purgeDBAfterLogOut();
          return 'logoutSuccess';
        }
        return 'lateLogoutSuccess';
      } else if (jsonDecode(response.body)['status'] == "error") {
        return jsonDecode(response.body)['message'];
      } else {
        throw Exception(jsonDecode(response.body)['message']);
      }
    } catch (e) {
      print('getallcards error try catch');
      log(e.toString());
    }
    return 'apiError';
  }

  Future<bool> forceLogOut() async{
    await DBHelper().purgeDBAfterLogOut();
    return true;
  }
}
