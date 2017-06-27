
import 'dart:html';
import 'dart:convert';
import 'dart:async';
import 'package:notify_releases/utils/utils.dart';

List<Album> releasesBatch;

Future<String> get(String url, {Map<String, String> headers, String body}){
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

void main() {
  get("http://localhost:9100", headers: {"method": "getWebBatch"}).then((String rep){
    List<Map> batchJson = JSON.decode(rep);
    releasesBatch = new List.generate(batchJson.length, (int idx) => new Album(batchJson[idx]));
    display();
  });
}

void display(){
  for (Album rel in releasesBatch){
    querySelector("#listAlbums").append(rel.createDiv());
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

  DivElement imageDiv;

  Album(Map json) {
    title = json["title"];
    first_release_date = DateFromString(json["first-release-date"]);
    primary_type = json["primary-type"];
    artist = json["artist"];
    mbid = json["mbid"];
    getImageUrl().then((_){
      imageDiv.style.backgroundImage = 'url("$chosenImageUrl")';
    });
  }

  DivElement createDiv(){
    DivElement artistDiv = new DivElement();
    artistDiv.classes.add("artist");
    DivElement content = new DivElement();
    content.classes..add("content");
    artistDiv..append(content..append(_metadataDiv())..append(_imageDiv()));
    return artistDiv;
  }

  DivElement _metadataDiv(){
    DivElement metadataWrapperDiv = new DivElement();
    metadataWrapperDiv.classes.add("metadataWrapper");
    DivElement nameDiv = new DivElement();
    nameDiv.classes.add("name");
    DivElement playCountDiv = new DivElement();
    playCountDiv.classes.add("playCount");
    nameDiv.text = this.title;
    playCountDiv.text = this.artist;
    return metadataWrapperDiv..append(nameDiv)..append(playCountDiv);
  }

  DivElement _imageDiv(){
    DivElement imageWrapperDiv = new DivElement();
    imageWrapperDiv.classes.add("imageWrapper");
    imageDiv = new DivElement();
    imageDiv.classes.add("image");
    //imageDiv.style.backgroundImage = 'url("$chosenImageUrl")';
    return imageWrapperDiv..append(imageDiv);
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
    return get(lastFmAlbumInfo).then((String rep){
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