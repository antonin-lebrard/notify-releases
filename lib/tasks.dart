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
    if (!FileHandling.webBatchRelease.fileToBlock.existsSync()){
      FileHandling.webBatchRelease.fileToBlock.createSync();
      FileHandling.webBatchRelease.fileToBlock.writeAsStringSync("[]");
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
    List<Map<String, String>> artistsJson = castML<String, String>(json.decode(await FileHandling.readFile(FileHandling.lastFMList)));
    /// set lastRelease some time before for every artist, configurable
    DateTime genDate = new DateTime.now();
    genDate = genDate.subtract(new Duration(days: Config.daysToSubtract));
    String lastReleaseGen = StringFromDate(genDate);
    /// generate LastReleases list
    List<LastRelease> lastReleases = new List<LastRelease>.generate(artistsJson.length, (int idx){
      artistsJson[idx]["lastRelease"] = lastReleaseGen;
      artistsJson[idx]["timestampLastChecked"] = (new DateTime.now()).millisecondsSinceEpoch.toString();
      return new LastRelease(artistsJson[idx]);
    }, growable: false);
    /// write it to file
    return FileHandling.blockedFileOperation(FileHandling.mbLastRelease, (_) => json.encode(lastReleases));
  }

}

/**
 * Fetch every artist listened to that has been Scrobbled on lastFM
 */
class LastFMTask {

  static Future doTask([bool firstLaunch = false]) async {
    return LastFMRemote.getArtists().then((List<Artist> artists) async {
      await FileHandling.blockedFileOperation(FileHandling.lastFMList, (String fileContent) {
        return json.encode(artists);
      });
      /// stops here if this is the first launch
      if (firstLaunch) {
        return new Future.value(null);
      }
      /// this next part is to update our mbLastRelease file,
      /// with any updates in the listening habits of our lastfm user
      return await FileHandling.blockedFileOperation(FileHandling.mbLastRelease, (String fileContent) {
        /// merge lastFMList with mbLastRelease
        List<Map<String, String>> save = castML<String, String>(json.decode(fileContent));
        /// keep the new artists, update playcount for the already present
        artists.removeWhere((Artist a) {
          Map<String, String> correspondingLastRelease = save.firstWhere((m) => m["mbid"] == a.mbid, orElse: () => null);
          if (correspondingLastRelease == null)
            return false;
          /// if existent, update playcount
          correspondingLastRelease["playcount"] = a.playCount.toString();
          return true;
        });
        DateTime genDate = new DateTime.now();
        genDate = genDate.subtract(new Duration(days: Config.daysToSubtract));
        String lastReleaseGen = StringFromDate(genDate);
        artists.forEach((Artist a) {
          Map<String, String> toAdd = a.toJson();
          toAdd["lastRelease"] = lastReleaseGen;
          toAdd["timestampLastChecked"] = (new DateTime.now()).millisecondsSinceEpoch.toString();
          save.add(toAdd);
        });
        return json.encode(save);
      });
    });
  }

}

class AutoRecommendLastFMFriendsTrendsTask {

  static Future doTask() async {
    /// get all our friends's username
    List<User> friends = await LastFMRemote.getFriends();
    Map<Track, int> nbFriendsByTracks = new Map<Track, int>();
    int i = 0;
    try {
      await asyncForEach(friends, (friend) async {
        /// get tracks listened last week for each of our friends
        List<Track> weeklyAlbums = await LastFMRemote.getWeeklyTracks(friend.name);
        print("friends charts done: ${++i}/${friends.length}");
        weeklyAlbums.forEach((Track track) {
          if (!nbFriendsByTracks.containsKey(track))
            nbFriendsByTracks[track] = 1;
          else
            nbFriendsByTracks[track]++;
        });
      }, continueOnError: true);
    } catch (error, stacktrace) {
      print(error);
      print(stacktrace);
    }
    List<Track> trendingTracks = new List<Track>();
    /// filter out tracks listened by only one of our friends
    nbFriendsByTracks.forEach((t, nb) {
      if (nb > 1) trendingTracks.add(t);
    });
    nbFriendsByTracks.clear();
    if (trendingTracks.length == 0) {
      print("no trending tracks found on friends weekly charts");
      return new Future.value(null);
    }
    Map<String, ReleaseGroup> trendingAlbums = new Map<String, ReleaseGroup>();
    try {
      await asyncForEach(trendingTracks, (Track track) async {
        /// get the album associated with each track
        Album album = await LastFMRemote.getAlbumFromTrack(track.name, track.artist.name);
        Map convertToReleaseGroup = {
          "title": album.name,
          "artist": album.artist.name,
          "mbid": album.mbid,
          "first-release-date": StringFromDate(new DateTime.now()),
          "primary-type": "auto_friends_recommendation"
        };
        /// and regroup them into unique albums (filter out duplicates)
        trendingAlbums.putIfAbsent(album.mbid ?? album.name,
                () => new ReleaseGroup.mapWithArtistAndMbid(convertToReleaseGroup));
      }, continueOnError: true);
    } catch (error, stacktrace) {
      print(error);
      print(stacktrace);
    }
    List<ReleaseGroup> rels = trendingAlbums.values.toList();
    print("found ${rels.length} albums trending in friends weekly charts");
    return Future.wait([
      MusicBrainzFetching.saveIntoBatchReleases(rels),
      MusicBrainzFetching.saveIntoWebBatchReleases(rels)
    ]);
  }

}

/**
 * Get the artist that has been checked the longest ago, and check its releases on MusicBrainz
 */
class MusicBrainzCheckTask {

  static Future doTask() async {
    List<Map> save = castL<Map>(json.decode(await FileHandling.readFile(FileHandling.mbLastRelease)));
    List<LastRelease> list = new List<LastRelease>.generate(save.length, (int idx) => new LastRelease(save[idx]));
    LastRelease lastRelease = list.where((LastRelease rel) {
      return rel.playCount > Config.minPlayCountToNotify;
    }).reduce((LastRelease one, LastRelease other){
      return (one.timestampLastChecked > other.timestampLastChecked) ? other : one;
    });
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

    List<Map> batchJson = castL<Map>(json.decode(await FileHandling.readFile(FileHandling.batchReleaseToNotify)));
    List<ReleaseGroup> newReleases = new List<ReleaseGroup>.generate(
        batchJson.length, (int idx) => new ReleaseGroup.mapWithArtistAndMbid(batchJson[idx]), growable: false
    );
    if (newReleases.length == 0){
      return new Future.value(null);
    }
    newReleases.forEach((ReleaseGroup release){
      mail.text += "\n${release.artist} has released a new ${release.primary_type}, named ${release.title} since ${release.first_release_date}\n";
    });

    return emailTransport.send(mail).then((_) async {
      print("batch email successfully sent!");
      return FileHandling.blockedFileOperation(FileHandling.batchReleaseToNotify, (_) {
        return "[]";
      });
    });
  }

}



class ServeWebBatch {

  static Future doTask() async {
    SimpleHttpServer server = new SimpleHttpServer();
    await server.bindHttpServer(9100);
    server..addGetHandler(_getWebBatch, "getWebBatch")
          ..addGetHandler(_getEmailBatchInfos, "getEmailBatchInfos")
          ..addGetHandler(_prolongEmailSending, "prolongEmailSending")
          ..addGetHandler(_shortenEmailSending, "shortenEmailSending")
          ..addGetHandler(_pauseEmailSending, "pauseEmailSending")
          ..addGetHandler(_restartEmailSending, "restartEmailSending")
          ..addPostHandler(_deleteReleases, "deleteReleases");
  }

  static Future<String> _getWebBatch(){
    return FileHandling.readFile(FileHandling.webBatchRelease);
  }

  static Future<String> _deleteReleases(String requestBody) async {
    List<Map> relJsonToDel = castL<Map>(json.decode(requestBody));
    return await FileHandling.blockedFileOperation(FileHandling.webBatchRelease, (String fileContent) {
      List<Map> allBatchJson = castL<Map>(json.decode(fileContent));
      List<ReleaseGroup> relToDel = new List<ReleaseGroup>.generate(relJsonToDel.length, (int idx) => new ReleaseGroup.mapWithArtistAndMbid(relJsonToDel[idx]));
      List<ReleaseGroup> allBatch = new List<ReleaseGroup>.generate(allBatchJson.length, (int idx) => new ReleaseGroup.mapWithArtistAndMbid(allBatchJson[idx]));
      allBatch.removeWhere((ReleaseGroup rel) => relToDel.contains(rel));
      allBatchJson = new List.generate(allBatch.length, (int idx) => allBatch[idx].toJson());
      return json.encode(allBatchJson);
    });
  }

  static Future<String> _getEmailBatchInfos() async {
    if (mailTimer == null) {
      return json.encode({
        "timeRemaining": "Not enabled",
        "isEmailSendingPaused": true,
        "nbReleasesToSend": 0,
      });
    }
    return json.encode({
      "timeRemaining": "${mailTimer.timeRemaining.inMinutes}:${mailTimer.timeRemaining.inSeconds - mailTimer.timeRemaining.inMinutes*60}",
      "isEmailSendingPaused": mailTimer.isPaused,
      "nbReleasesToSend": castL<dynamic>(json.decode(await FileHandling.readFile(FileHandling.batchReleaseToNotify))).length,
    });
  }

  static Future<String> _prolongEmailSending(){
    mailTimer?.prolongDuration();
    return _getEmailBatchInfos();
  }

  static Future<String> _shortenEmailSending(){
    mailTimer?.shortenDuration();
    return _getEmailBatchInfos();
  }

  static Future<String> _pauseEmailSending(){
    mailTimer?.pause();
    return new Future.value("");
  }

  static Future<String> _restartEmailSending(){
    mailTimer?.restart();
    return _getEmailBatchInfos();
  }

}





