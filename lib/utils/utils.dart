library utils;


import 'dart:async';



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
