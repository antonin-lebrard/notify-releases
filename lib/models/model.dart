library models;


import 'dart:async';
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

  Map<String, String> toJson(){
    Map<String, String> map = new Map<String, String>();
    map["mbid"] = this.mbid;
    map["name"] = this.name;
    map["playcount"] = this.playCount.toString();
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

  Map<String, String> toJson(){
    Map<String, String> map = new Map<String, String>();
    map["name"] = this.name;
    map["mbid"] = this.mbid;
    map["lastRelease"] = StringFromDate(this.lastRelease);
    map["timestampLastChecked"] = this.timestampLastChecked.toString();
    map["playcount"] = this.playCount.toString();
    return map;
  }
}

class ReleaseGroup {
  String title;
  DateTime first_release_date;
  String primary_type;
  String artist;
  String mbid;
  String bandcampUrl;
  bool hasSearchedForBandcampUrl;

  static String ARTIST = "&&&INSERT_ARTIST_HERE&&&";
  static String ALBUM  = "&&&INSERT_ALBUM_HERE&&&";
  static String directAlbumBandcampUrl = "https://${ARTIST}.bandcamp.com/album/${ALBUM}";
  static String directTrackBandcampUrl = "https://${ARTIST}.bandcamp.com/track/${ALBUM}";
  static String searchBandcampUrl = "https://bandcamp.com/search?q=";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ReleaseGroup &&
              mbid == other.mbid && title == other.title;

  ReleaseGroup(Map json, this.artist, this.mbid) {
    title = json["title"];
    first_release_date = DateFromString(json["first-release-date"]);
    primary_type = json["primary-type"];
    bandcampUrl = json["bandcampUrl"];
    hasSearchedForBandcampUrl = json["hasSearchedForBandcampUrl"] == "true";
    if (json["secondary-types"] != null){
      List<String> secondaryTypes = castL<String>(json["secondary-types"]);
      if (secondaryTypes.length == 0)
        return;
      primary_type = secondaryTypes[0];
    }
  }

  ReleaseGroup.mapWithArtistAndMbid(Map json) {
    title = json["title"];
    first_release_date = DateFromString(json["first-release-date"]);
    primary_type = json["primary-type"];
    artist = json["artist"];
    mbid = json["mbid"];
    bandcampUrl = json["bandcampUrl"];
    hasSearchedForBandcampUrl = json["hasSearchedForBandcampUrl"] == "true";
    if (json["secondary-types"] != null){
      List<String> secondaryTypes = castL<String>(json["secondary-types"]);
      if (secondaryTypes.length == 0)
        return;
      primary_type = secondaryTypes[0];
    }
  }

  Future prepareBandcamp() async {
    if (!hasSearchedForBandcampUrl) {
      bandcampUrl = await searchBandcamp(this.artist, this.title);
      hasSearchedForBandcampUrl = true;
    }
  }

  static Future<String> searchBandcamp(String artist, String album) async {
    String directArtist = artist.split(" ").join("").toLowerCase();
    String directAlbum = album.split(" ").join("+").toLowerCase();
    String directAlbumUrl = directAlbumBandcampUrl.replaceFirst(ARTIST, directArtist).replaceFirst(ALBUM, directAlbum);
    String directTrackUrl = directTrackBandcampUrl.replaceFirst(ARTIST, directArtist).replaceFirst(ALBUM, directAlbum);
    if (await isHttpPageExists(directAlbumUrl)) return directAlbumUrl;
    if (await isHttpPageExists(directTrackUrl)) return directTrackUrl;
    return searchBandcampUrl + Uri.encodeFull(artist + " " + album);
  }

  Map<String, String> toJson(){
    Map<String, String> map = new Map<String, String>();
    map["title"] = this.title;
    map["first-release-date"] = StringFromDate(this.first_release_date);
    map["primary-type"] = this.primary_type;
    map["artist"] = this.artist;
    map["mbid"] = this.mbid;
    map["bandcampUrl"] = this.bandcampUrl;
    map["hasSearchedForBandcampUrl"] = this.hasSearchedForBandcampUrl.toString();
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
