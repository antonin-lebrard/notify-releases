part of lib;




class FirstLaunchTask {

  static Future doTask() async {
    await Config.loadConfigFromFile("config.json");
    if (!FileHandling.lastFMList.fileToBlock.existsSync()){
      FileHandling.lastFMList.fileToBlock.createSync();
      await LastFMTask.doTask();
    }
    if (!FileHandling.mbLastRelease.fileToBlock.existsSync()){
      FileHandling.mbLastRelease.fileToBlock.createSync();
      await GenerateLastReleaseTask.doTask();
    }
    if (!FileHandling.batchReleaseToNotify.fileToBlock.existsSync()){
      FileHandling.batchReleaseToNotify.fileToBlock.createSync();
      FileHandling.batchReleaseToNotify.fileToBlock.writeAsStringSync("[]");
    }
  }

}

/**
 * Generate first version of last release per artist file
 * Used to know for each artist, when was the last known release
 * Should be used only at first launch
 */
class GenerateLastReleaseTask {

  static Future doTask() async {
    List<Map<String, String>> artistsJson = JSON.decode(await FileHandling.readFile(FileHandling.lastFMList));
    /// set lastRelease some time before for every artist, configurable
    DateTime genDate = new DateTime.now();
    genDate = genDate.subtract(new Duration(days: Config.daysToSubtract));
    String lastReleaseGen = StringFromDate(genDate);
    /// generate LastReleases list
    List<LastRelease> lastReleases = new List.generate(artistsJson.length, (int idx){
      artistsJson[idx]["lastRelease"] = lastReleaseGen;
      artistsJson[idx]["timestampLastChecked"] = (new DateTime.now()).millisecondsSinceEpoch.toString();
      return new LastRelease(artistsJson[idx]);
    }, growable: false);
    /// write it to file
    return FileHandling.writeToFile(FileHandling.mbLastRelease, JSON.encode(lastReleases, toEncodable: LastRelease.toJSON));
  }

}

/**
 * Fetch every artist listened to that has been Scrobbled on lastFM
 */
class LastFMTask {

  static Future doTask() async {
    LastFMFetching remote = new LastFMFetching();
    List<Artist> artists = new List<Artist>();
    return remote.getArtists(artists).then((List<Artist> artists){
      return FileHandling.writeToFile(FileHandling.lastFMList, JSON.encode(artists, toEncodable: Artist.toJSON));
    });
  }

}

/**
 * Get the artist that has been checked the longest ago, and check its releases on MusicBrainz
 */
class MusicBrainzCheckTask {

  static Future doTask() async {
    List<Map<String, String>> json = (JSON.decode(await FileHandling.readFile(FileHandling.mbLastRelease)) as List<Map<String, String>>);
    List<LastRelease> list = new List.generate(json.length, (int idx) => new LastRelease(json[idx]));
    LastRelease lastRelease = list.reduce((LastRelease one, LastRelease other) => (one.timestampLastChecked > other.timestampLastChecked) ? other : one);
    print("preparing request for name : ${lastRelease.name}");
    return MusicBrainzFetching.fetchArtistInfo(lastRelease.mbid, lastRelease.lastRelease);
  }

}

class WhileTrueMBCheckTask {

  static StreamController _whileController = new StreamController();
  static Stream _whileStream = _whileController.stream;

  static Future continuousMBCheckTask() async {
    _whileStream.listen((_) async {
      await MusicBrainzCheckTask.doTask();
      _whileController.add(null);
    });
    _whileController.add(null);
  }

}

/**
 * Send a mail containing all the new releases saved in batch.json
 */
class MailBatchTask {

  static Future doTask() async {
    SmtpOptions opt = new SmtpOptions()
        ..hostName = Config.mailSmtpHostname
        ..port = Config.mailSmtpPort
        ..secured = Config.mailSmtpSecured
        ..username = Config.mailSmtpUsername
        ..password = Config.mailSmtpPassword
        ..requiresAuthentication = true;

    SmtpTransport emailTransport = new SmtpTransport(opt);

    Envelope mail = new Envelope()
        ..from = Config.mailSmtpUsername
        ..recipients.add(Config.mailAddressToContactForNewReleases)
        ..subject = "See new Releases from the artists you follows"
        ..text = "";

    List<Map<String, String>> batchJson = JSON.decode(await FileHandling.readFile(FileHandling.batchReleaseToNotify));
    List<ReleaseGroup> newReleases = new List.generate(batchJson.length, (int idx) => new ReleaseGroup.mapWithArtist(batchJson[idx]), growable: false);
    if (newReleases.length == 0){
      return new Future.value(null);
    }
    newReleases.forEach((ReleaseGroup release){
      mail.text += "\n${release.artist} has released a new ${release.primary_type}, named ${release.title} since ${release.first_release_date}\n";
    });

    return emailTransport.send(mail).then((_) async {
      print("batch email successfully sent!");
      return FileHandling.writeToFile(FileHandling.batchReleaseToNotify, "[]");
    });
  }

}







