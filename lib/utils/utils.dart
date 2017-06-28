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


typedef void CallbackWithTimer(Timer timer);
typedef void Callback();

class TimerWrapper {

  Timer _internal;
  CallbackWithTimer _callbackWithTimer;
  Callback _callback;
  bool _isPeriodic;
  DateTime launchTime;
  Duration duration;
  bool isPaused = false;

  Duration get timeSinceLaunch => new DateTime.now().difference(launchTime);
  Duration get timeRemaining => duration - timeSinceLaunch;

  TimerWrapper.periodic(this.duration, this._callbackWithTimer){
    _isPeriodic = true;
    _launchPeriodicTimer();
  }

  TimerWrapper(this.duration, this._callback){
    _isPeriodic = false;
    _launchSimpleTimer();
  }

  _launchPeriodicTimer(){
    launchTime = new DateTime.now();
    _internal = new Timer.periodic(duration, (Timer timer){
      launchTime = new DateTime.now();
      _callbackWithTimer(timer);
    });
  }

  _launchSimpleTimer(){
    launchTime = new DateTime.now();
    _internal = new Timer(duration, _callback);
  }

  prolongDuration(){
    _internal.cancel();
    duration *= 2;  // multiply by two the duration
    _isPeriodic ? _launchPeriodicTimer() : _launchSimpleTimer();
  }

  shortenDuration(){
    _internal.cancel();
    duration ~/= 2; // divide by two the duration
    _isPeriodic ? _launchPeriodicTimer() : _launchSimpleTimer();
  }

  pause(){
    _internal.cancel();
    isPaused = true;
  }

  restart(){
    _isPeriodic ? _launchPeriodicTimer() : _launchSimpleTimer();
    isPaused = false;
  }

}