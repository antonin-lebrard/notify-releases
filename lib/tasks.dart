part of lib;




class FirstLaunchTask {

  static Future doTask() async {
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
    String mbid = list.reduce((LastRelease one, LastRelease other) => (one.timestampLastChecked > other.timestampLastChecked) ? other : one)
        .mbid;
    await MusicBrainzFetching.fetchArtistInfo(mbid);
  }

}









