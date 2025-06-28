import 'dart:io';

import 'package:yeriko_app/main.dart';

const String accessToken = 'accessToken';
const String userInfo = 'userInfo';
const String fTimeValue = '0';
const String loginTime = 'loginTime';
const String userIdCode = 'userIdCode';
const String expirationDuration = 'expirationDuration';
const String currency = 'TZS';

//url
//
const String localIp = "http://localhost:8888/yeriko_jumuiya/api";
const String remoteIp = "192.168.0.126";
const String activeIp = localIp;
const String port = "8081";
final String baseUrl = localIp; //"http://$activeIp:$port/api";

String getFirstWord(String inputString) {
  List<String> wordList = inputString.split(" ");
  if (wordList.isNotEmpty) {
    String mystring = wordList[0];
    return mystring[0];
  } else {
    return ' ';
  }
}

Future<Map<String, String>> get authHeader async => {
      'Content-Type': 'application/json',
      HttpHeaders.authorizationHeader: 'Bearer ${userData!.user.id}',
    };
