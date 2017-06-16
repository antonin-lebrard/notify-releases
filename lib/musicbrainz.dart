part of lib;




class MusicBrainzFetching {

  static Future fetchArtistInfo(String mbid, DateTime lastChecked) async {
    List<ReleaseGroup> saving = new List<ReleaseGroup>();
    print("doing req for mbid : $mbid");
    if (mbid != null || mbid != "") {
      saving = await getReleasesForMBid(mbid, lastChecked);
    }
    return Future.wait([_saveNewLastReleaseDate(mbid, saving), _saveIntoBatchReleases(saving)]);
  }

  static Future<List<ReleaseGroup>> getReleasesForMBid(String mbid, DateTime lastChecked, [int recursiveIndex = 1]) async {
    return MBRemote.doRequest(mbid).then((String body) async {
      Map json = JSON.decode(body);
      if (json.containsKey("error")) {
        print(json);
        if (recursiveIndex == 30){
          print("too many tries for one mbid, will skip it now");
          return [];
        }
        int duration = 3 * (recursiveIndex / 2).ceil();
        print("will wait for $duration minutes, to see if the error will dissipate");
        await waitForDuration(new Duration(minutes: duration));
        return getReleasesForMBid(mbid, lastChecked, recursiveIndex++);
      }
      String artist = json["name"];
      List<Map> jsonRel = (json["release-groups"] as List<Map>);
      if (jsonRel == null) {
        print(json);
        return [];
      }
      jsonRel.retainWhere((Map m) {
        if (m["primary-type"] == null) return false;
        if (m["title"] == null) return false;
        if (m["first-release-date"] == null) return false;
        if ((m["first-release-date"] as String)
            .split("-")
            .length != 3) return false;
        return true;
      });
      List<ReleaseGroup> releases = new List<ReleaseGroup>.generate(jsonRel.length, (int idx) {
        return new ReleaseGroup(jsonRel[idx], artist);
      });

      /// get only the new ones compared to last checked DateTime
      releases.retainWhere((ReleaseGroup r) {
        return r.first_release_date.compareTo(lastChecked) > 0;
      });
      return releases;
    });
  }

  static Future _saveNewLastReleaseDate(String mbid, List<ReleaseGroup> newReleases) async {
    DateTime newLastReleaseDate = null;
    if (newReleases.length > 0) {
      /// sort in reverse (later before, earlier at the end)
      newReleases.sort((ReleaseGroup one, ReleaseGroup other) {
        return other.first_release_date.compareTo(one.first_release_date);
      });
      newLastReleaseDate = newReleases[0].first_release_date;
    }
    List<Map<String, String>> json = JSON.decode(await FileHandling.readFile(FileHandling.mbLastRelease));
    for (Map<String, String> entry in json){
      if (entry["mbid"] == mbid){
        if (newLastReleaseDate != null) {
          entry["lastRelease"] = StringFromDate(newLastReleaseDate);
        }
        entry["timestampLastChecked"] = (new DateTime.now()).millisecondsSinceEpoch.toString();
        break;
      }
    }
    return FileHandling.writeToFile(FileHandling.mbLastRelease, JSON.encode(json));
  }

  static Future _saveIntoBatchReleases(List<ReleaseGroup> toSave) async {
    if (toSave.length == 0)
      return new Future.value(null);
    List<Map> jsonRel = JSON.decode(await FileHandling.readFile(FileHandling.batchReleaseToNotify));
    jsonRel.addAll(new List.generate(toSave.length, (int idx) => ReleaseGroup.toJSON(toSave[idx])));
    return FileHandling.writeToFile(FileHandling.batchReleaseToNotify, JSON.encode(jsonRel));
  }

}