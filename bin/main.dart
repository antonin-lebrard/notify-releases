

import 'package:notify_releases/lib.dart';
import 'dart:async';
import 'package:future_goodies/future_goodies.dart';



main(List<String> args) async {
  await FirstLaunchTask.doTask();
  lastFmTimer = new Timer.periodic(new Duration(days: 1), (_) => LastFMTask.doTask());

  WhileTrueMBCheckTask.continuousMBCheckTask();
  //await WhileTrueAsync.run(MusicBrainzCheckTask.doTask);
}


class WhileTrueAsync {

  static bool neverStop(dynamic) => false;

  static hasNoUse(_) => null;

  static Future run(Future asyncToRun()) async {
    List genNextMBTask(dynamic) => [asyncToRun(), null];
    await unfold(genNextMBTask, neverStop, hasNoUse, null);
  }

}




