

import 'package:notify_releases/lib.dart';
import 'dart:async';



main(List<String> args) async {
  await FirstLaunchTask.doTask();

  ServeWebBatch.doTask();
  lastFmTimer = new Timer.periodic(new Duration(days: 1), (_) => LastFMTask.doTask());
  mailTimer = new Timer.periodic(new Duration(minutes: 30), (_) => MailBatchTask.doTask());

  WhileTrueMBCheckTask.continuousMBCheckTask();
}


