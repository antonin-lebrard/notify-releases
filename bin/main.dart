

import 'package:notify_releases/lib.dart';
import 'package:notify_releases/utils/utils.dart';



main(List<String> args) async {
  await FirstLaunchTask.doTask();

  ServeWebBatch.doTask();
  lastFmTimer = new TimerWrapper.periodic(new Duration(days: 1), (_) => LastFMTask.doTask());
  mailTimer = new TimerWrapper.periodic(new Duration(minutes: Config.minutesUntilNextMail), (_) => MailBatchTask.doTask());

  WhileTrueMBCheckTask.continuousMBCheckTask();
}


