
import 'dart:html';
import 'dart:convert';
import 'dart:async';
import 'package:notify_releases/utils/utils.dart';

List<Album> releasesBatch;

class HttpRequestHelper {

  static Future<String> get(String url, {Map<String, String> headers, String body}){
    Completer completer = new Completer<String>();
    HttpRequest req = new HttpRequest()..open("GET", url);
    headers?.forEach((String key, String value){
      req.setRequestHeader(key, value);
    });
    StreamSubscription sub;
    sub = req.onLoad.listen((event){
      completer.complete(event.target.responseText);
      sub.cancel();
    });
    req.send(body);
    return completer.future;
  }

}

void main() {
  HttpRequestHelper.get("http://localhost:9100", headers: {"method": "getWebBatch"}).then((String rep){
    List<Map> batchJson = JSON.decode(rep);
    releasesBatch = new List.generate(batchJson.length, (int idx) => new Album(batchJson[idx]));
    display();
  });
}

void display(){
  for (Album rel in releasesBatch){
    document.body.appendHtml("<div>${rel.artist} has released a new ${rel.primary_type} named ${rel.title}");
  }
}

class Album {

  static String LastFM_API_KEY = "";

  static String ARTIST = "&&&INSERT_ARTIST_HERE&&&";
  static String ALBUM  = "&&&INSERT_ALBUM_HERE&&&";

  static String lastFMAlbumInfoUrl = "https://ws.audioscrobbler.com/2.0/?"
      "method=album.getinfo&api_key=$LastFM_API_KEY"
      "&artist=$ARTIST&album=$ALBUM&format=json";

  String title;
  DateTime first_release_date;
  String primary_type;
  String artist;
  String mbid;

  String chosenImageUrl;

  Album(Map json) {
    title = json["title"];
    first_release_date = DateFromString(json["first-release-date"]);
    primary_type = json["primary-type"];
    artist = json["artist"];
    mbid = json["mbid"];
    getImageUrl();
  }

  Future getImageUrl() async {
    chosenImageUrl = _getCachedChosenImageUrl() ?? await _fetchChosenImageUrl();
  }

  String _getCachedChosenImageUrl(){
    return window.localStorage[mbid+title];
  }

  Future<String> _fetchChosenImageUrl() {
    String lastFmAlbumInfo = lastFMAlbumInfoUrl
        .replaceFirst(ARTIST, Uri.encodeFull(artist))
        .replaceFirst(ALBUM, Uri.encodeFull(title));
    return HttpRequestHelper.get(lastFmAlbumInfo).then((String rep){
      Map json = JSON.decode(rep);
      if (json.containsKey("error"))
        return "";
      json = json["album"];
      List<Map> images = json['image'];
      if (images != null) {
        for (int i = 0; i < images.length; i++) {
          if (images[i]['size'] == "large") {
            String imageUrl = images[i]['#text'];
            window.localStorage[mbid+title] = imageUrl;
            return imageUrl;
          }
        }
      }
    });
  }


}