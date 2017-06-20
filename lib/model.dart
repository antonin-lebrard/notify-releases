part of lib;





class Artist {
  String mbid;
  String name;

  Artist(Map json){
    name = json["name"];
    mbid = json["mbid"];
  }

  static Map<String, String> toJSON(Artist a){
    Map<String, String> map = new Map<String, String>();
    map["mbid"] = a.mbid;
    map["name"] = a.name;
    return map;
  }

}

class LastRelease {
  String mbid;
  String name;
  DateTime lastRelease;
  int timestampLastChecked;

  LastRelease(Map json){
    name = json["name"];
    mbid = json["mbid"];
    lastRelease = DateFromString(json["lastRelease"]);
    timestampLastChecked = int.parse(json["timestampLastChecked"]);
  }

  static Map<String, String> toJSON(LastRelease l){
    Map<String, String> map = new Map<String, String>();
    map["name"] = l.name;
    map["mbid"] = l.mbid;
    map["lastRelease"] = StringFromDate(l.lastRelease);
    map["timestampLastChecked"] = l.timestampLastChecked.toString();
    return map;
  }

}

class ReleaseGroup {
  String title;
  DateTime first_release_date;
  String primary_type;
  String artist;

  ReleaseGroup(Map json, this.artist){
    title = json["title"];
    first_release_date = DateFromString(json["first-release-date"]);
    primary_type = json["primary-type"];
    if (json["secondary-types"] != null){
      List<String> secondaryTypes = json["secondary-types"];
      if (secondaryTypes.length == 0)
        return;
      primary_type = secondaryTypes[0];
    }
  }

  ReleaseGroup.mapWithArtist(Map json){
    title = json["title"];
    first_release_date = DateFromString(json["first-release-date"]);
    primary_type = json["primary-type"];
    artist = json["artist"];
    if (json["secondary-types"] != null){
      List<String> secondaryTypes = json["secondary-types"];
      if (secondaryTypes.length == 0)
        return;
      primary_type = secondaryTypes[0];
    }
  }

  static Map<String, String> toJSON(ReleaseGroup r){
    Map<String, String> map = new Map<String, String>();
    map["title"] = r.title;
    map["first-release-date"] = StringFromDate(r.first_release_date);
    map["primary-type"] = r.primary_type;
    map["artist"] = r.artist;
    return map;
  }

}