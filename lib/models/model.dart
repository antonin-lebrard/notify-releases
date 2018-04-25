library models;


import 'package:notify_releases/utils/utils.dart';



class Artist {
  String mbid;
  String name;
  int playCount;

  Artist(Map json){
    name = json["name"] ?? json["#text"];
    mbid = json["mbid"];
    playCount = int.parse(json["playcount"] ?? "0", onError: (_) => 0);
  }

  static Map<String, String> toJSON(Artist a){
    Map<String, String> map = new Map<String, String>();
    map["mbid"] = a.mbid;
    map["name"] = a.name;
    map["playcount"] = a.playCount.toString();
    return map;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Artist &&
              mbid == other.mbid && name == other.name;
}

class LastRelease {
  String mbid;
  String name;
  DateTime lastRelease;
  int timestampLastChecked;
  int playCount;

  LastRelease(Map json){
    name = json["name"];
    mbid = json["mbid"];
    lastRelease = DateFromString(json["lastRelease"]);
    timestampLastChecked = int.parse(json["timestampLastChecked"]);
    playCount = int.parse(json["playcount"]);
  }

  static Map<String, String> toJSON(LastRelease l){
    Map<String, String> map = new Map<String, String>();
    map["name"] = l.name;
    map["mbid"] = l.mbid;
    map["lastRelease"] = StringFromDate(l.lastRelease);
    map["timestampLastChecked"] = l.timestampLastChecked.toString();
    map["playcount"] = l.playCount.toString();
    return map;
  }
}

class ReleaseGroup {
  String title;
  DateTime first_release_date;
  String primary_type;
  String artist;
  String mbid;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ReleaseGroup &&
              mbid == other.mbid && title == other.title;

  ReleaseGroup(Map json, this.artist, this.mbid){
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

  ReleaseGroup.mapWithArtistAndMbid(Map json){
    title = json["title"];
    first_release_date = DateFromString(json["first-release-date"]);
    primary_type = json["primary-type"];
    artist = json["artist"];
    mbid = json["mbid"];
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
    map["mbid"] = r.mbid;
    return map;
  }
}

class User {
  String name;
  String url;
  int playcount;

  User(Map json) {
    name = json["name"];
    url = json["url"];
    playcount = int.parse(json["playcount"] ?? "0", onError: (_) => 0);
  }
}

class Album {
  Artist artist;
  String name;
  String mbid;
  int playcount;

  Album(Map json) {
    artist = new Artist(json["artist"]);
    name = json["name"] ?? json["title"];
    mbid = json["mbid"] == "" ? null : json["mbid"];
    playcount = int.parse(json["playcount"] ?? "0", onError: (_) => 0);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Album &&
              mbid == other.mbid && name == other.name && artist == other.artist;
}

class Track {
  Artist artist;
  String name;
  String mbid;
  int playcount;

  Track(Map json) {
    artist = new Artist(json["artist"]);
    name = json["name"];
    mbid = json["mbid"] == "" ? null : json["mbid"];
    playcount = int.parse(json["playcount"] ?? "0", onError: (_) => 0);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Track &&
              mbid == other.mbid && name == other.name && artist == other.artist;
}