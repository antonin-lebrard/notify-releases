library lib;


import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;


part 'config.dart';
part 'lastfm.dart';
part 'musicbrainz.dart';
part 'model.dart';
part 'tasks.dart';
part 'filehandling.dart';
part 'mbremote.dart';



Timer lastFmTimer;


DateTime DateFromString(String s){
  List<String> parts = s.split('-');
  List<int> intParts = new List.generate(parts.length, (int idx) => int.parse(parts[idx]), growable: false);
  return new DateTime(intParts[0], intParts[1], intParts[2]);
}

String StringFromDate(DateTime d){
  return "${d.year}-${d.month}-${d.day}";
}

Future waitForDuration(Duration d){
  Completer completer = new Completer();
  new Timer(d, () {
    completer.complete();
  });
  return completer.future;
}
