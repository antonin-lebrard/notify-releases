part of lib;




class MusicBrainzFetching {

  static Future fetchArtistInfo(String mbid, DateTime lastChecked) async {
    List<ReleaseGroup> saving = new List<ReleaseGroup>();
    print("its mbid : $mbid");
    if (mbid != null || mbid != "") {
      try {
        saving = await getReleasesForMBid(mbid, lastChecked);
      } catch (e) {
        return new Future.value([]);
      }
    }
    return Future.wait([
      _saveNewLastReleaseDate(mbid, saving),
      saveIntoBatchReleases(saving),
      saveIntoWebBatchReleases(saving)
    ]);
  }

  static Future<List<ReleaseGroup>> getReleasesForMBid(String mbid, DateTime lastChecked, [int recursiveIndex = 1]) async {
    return MBRemote.doRequest(mbid).then((String body) async {
      Map releasesJson = json.decode(body);
      if (releasesJson.containsKey("error") && releasesJson["error"] != "Not Found") {
        print(releasesJson);
        if (recursiveIndex == 20){
          print("too many tries for one mbid, will skip it now");
          return [];
        }
        int duration = 3 * (recursiveIndex / 2).ceil();
        print("will wait for $duration minutes, to see if the error will dissipate");
        await waitForDuration(new Duration(minutes: duration));
        return getReleasesForMBid(mbid, lastChecked, recursiveIndex++);
      } else if (releasesJson.containsKey("error")) {
        print('artist not found on musicbrainz');
        print(json);
        return [];
      }
      String artist = releasesJson["name"];
      List<Map> jsonRel = castL<Map>(releasesJson["release-groups"]);
      if (jsonRel == null) {
        print(releasesJson);
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
        return new ReleaseGroup(jsonRel[idx], artist, mbid);
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
    return await FileHandling.blockedFileOperation(FileHandling.mbLastRelease, (String fileContent) {
      List<Map<String, String>> save = castML<String, String>(json.decode(fileContent));
      for (Map<String, String> entry in save){
        if (entry["mbid"] == mbid){
          if (newLastReleaseDate != null) {
            entry["lastRelease"] = StringFromDate(newLastReleaseDate);
          }
          entry["timestampLastChecked"] = (new DateTime.now()).millisecondsSinceEpoch.toString();
          if (entry["nbTimesChecked"] == null)
            entry["nbTimesChecked"] = "0";
          entry["nbTimesChecked"] = (int.parse(entry["nbTimesChecked"], onError: (s) => 0) + 1).toString();
        }
      }
      return json.encode(save);
    });
  }

  static Future<List<Map>> _updateMissingBandcampUrl(List<Map> jsonRels) async {
    List<ReleaseGroup> rels = new List.generate(jsonRels.length,
            (int idx) => new ReleaseGroup.mapWithArtistAndMbid(jsonRels[idx]));
    await asyncForEach(rels, (ReleaseGroup rel) async => await rel.prepareBandcamp(), continueOnError: true);
    return new List<Map>.generate(rels.length, (int idx) => rels[idx].toJson());
  }

  static Future _saveIntoFile(List<ReleaseGroup> toSave, FileToBlock file) async {
    if (toSave.length == 0)
      return new Future.value(null);
    await asyncForEach(toSave, (ReleaseGroup rel) async => await rel.prepareBandcamp(), continueOnError: true);
    return await FileHandling.blockedAsyncFileOperation(file, (String fileContent) async {
      List<Map> jsonRel = castL<Map>(json.decode(fileContent));
      if (jsonRel.any((Map rel) => rel["bancampUrl"] == null)) {
        jsonRel = await _updateMissingBandcampUrl(jsonRel);
      }
      jsonRel.addAll(new List.generate(toSave.length, (int idx) => toSave[idx].toJson()));
      return json.encode(jsonRel);
    });
  }

  static Future saveIntoBatchReleases(List<ReleaseGroup> toSave) async {
    return _saveIntoFile(toSave, FileHandling.batchReleaseToNotify);
  }

  static Future saveIntoWebBatchReleases(List<ReleaseGroup> toSave) async {
    return _saveIntoFile(toSave, FileHandling.webBatchRelease);
  }

}
