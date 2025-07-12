import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:jumuiya_yangu/models/app_setting_model.dart';
import 'package:jumuiya_yangu/utils/global/appSetting.dart';
import 'package:jumuiya_yangu/utils/url.dart';

class GlobalProvider extends ChangeNotifier {
  Future<String> checkAppSettings() async {
    AppVersion globalResponse = await getMobileSettings();
    if (globalResponse.lockStatus == 'OFF') {
      if (AppSettings.oldversionCode == "" || AppSettings.newversionCode == "") {
        return "UPDATE_NEEDED";
      }

      if (int.parse(globalResponse.appVersion) > int.parse(AppSettings.oldversionCode) &&
          int.parse(globalResponse.appVersion) != int.parse(AppSettings.newversionCode)) {
        return "UPDATE_NEEDED";
      }
    } else if (globalResponse.lockStatus == 'ON') {
      return "APP_MAINTENANCE";
    } else {
      return "CHECK_FAILED";
    }
    return "NOTHING";
  }

  Future<dynamic> getMobileSettings() async {
    try {
      String myApi = "$baseUrl/app_setting/get_app_version.php";
      final response = await http.post(Uri.parse(myApi), headers: {
        'Accept': 'application/json',
      });

      var jsonResponse = json.decode(response.body);

      if (response.statusCode == 200 && jsonResponse is Map<String, dynamic>) {
        // Print the jsonResponse to inspect the data structure

        // Check if "data" exists and is not a List
        if (jsonResponse["data"] is Map<String, dynamic>) {
          // If "data" is a single object (not a list), handle it here
          var appSetting = jsonResponse["data"]; // Single object instead of a list

          // Initialize higherList
          List<AppVersion> setting = [];

          // Convert the single object to a AppVersion instance and add it to the list
          AppVersion bet = AppVersion.fromJson(appSetting);
          setting.add(bet);

          // If the list contains a bet, assign the first bet

          // Return the list containing the single AppVersion object
          return setting[0];
        } else {
          // Handle the case where "data" is neither a List nor a Map
          return []; // Return an empty list if the format is unexpected
        }
      } else {
        // Handle invalid response or status code
        return []; // Return an empty list if the response status is not 200
      }
    } catch (e) {
      return [];
    }
  }
}
