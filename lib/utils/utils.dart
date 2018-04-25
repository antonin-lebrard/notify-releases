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

int ComparableIntFromDate(DateTime d){
  return (d.year * 10000000000) + (d.month * 100000000) + (d.day * 1000000) + (d.hour * 10000) + (d.minute * 100) + d.second;
}

Future waitForDuration(Duration d){
  Completer completer = new Completer();
  new Timer(d, () {
    completer.complete();
  });
  return completer.future;
}

Future asyncForEach<T>(List<T> list, Future eachFn(T element), {bool continueOnError: false}) async {
  if (list.length == 0) return new Future.value(null);

  Completer completer = new Completer();
  StreamController<T> controller = new StreamController<T>();
  Stream<T> stream = controller.stream;

  Object error = null;
  StackTrace trace = null;
  int i = 0;
  /// set the 'for' loop code with the stream method
  stream.listen((T element) async {
    try {
      /// here is [eachFn] method called
      await eachFn(element);
    } catch (err, tr) {
      /// if anything bad happens,
      /// close every resources and set the error and stacktrace
      error = err;
      trace = tr;
      /// the asyncForEach user will receive the error directly,
      /// instead of waiting the end of each processing
      if (!continueOnError)
        controller.close();
    }
    /// go one step further
    i++;
    /// verify stop condition
    if (i >= list.length) {
      controller.close();
    } else {
      controller.add(list[i]);
    }
  }, onDone: () {
    if (error != null)
      completer.completeError(error, trace);
    else
      completer.complete(null);
  });
  /// launch the for loop with the first element
  controller.add(list[i]);

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
    isPaused = false;
    _internal = new Timer.periodic(duration, (Timer timer){
      launchTime = new DateTime.now();
      _callbackWithTimer(timer);
    });
  }

  _launchSimpleTimer(){
    launchTime = new DateTime.now();
    isPaused = false;
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