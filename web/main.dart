
import 'dart:html';
import 'dart:convert';
import 'dart:async';
import 'package:notify_releases/utils/utils.dart';

List<Album> releasesBatch;
Timer timerRemainingTime;
bool isEmailPaused;

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

Future<String> getMethod(String method, {String body}) {
  return get("http://localhost:9100", headers: {"method": method}, body: body);
}

void main() {
  getMethod("getWebBatch").then((String rep){
    List<Map> batchJson = JSON.decode(rep);
    releasesBatch = new List.generate(batchJson.length, (int idx) => new Album(batchJson[idx]));
    display();
  });
  getEmailBatchInfos();
  prepareEmailsButtons();
}

void display(){
  for (Album album in releasesBatch){
    querySelector("#listAlbums").append(album.createDiv());
    if (!album.isImageUrlSet){
      album.setImageUrl();
    }
  }
}

void getEmailBatchInfos(){
  getMethod("getEmailBatchInfos").then(handleEmailBatchInfos);
}

void handleEmailBatchInfos(String bodyRep){
  Map json = JSON.decode(bodyRep);
  List<String> timeRemainingString = json["timeRemaining"].split(":");
  Duration timeRemaining = new Duration(minutes: int.parse(timeRemainingString[0]),
      seconds: int.parse(timeRemainingString[1]));
  isEmailPaused = json["isEmailSendingPaused"];
  int nbReleasesToSend = json["nbReleasesToSend"];
  if (!isEmailPaused)
    launchTimeRemainingTimer(timeRemaining);
  else {
    querySelector('#timeRemaining').innerHtml = "N/A";
    timerRemainingTime?.cancel();
  }
  querySelector("#nbAlbumsToNotifyEmail").innerHtml = nbReleasesToSend.toString();
  querySelector("#pauseRestartBtn").innerHtml = isEmailPaused ? "Restart" : "Pause";
}

void launchTimeRemainingTimer(Duration duration){
  int minutes = duration.inMinutes;
  querySelector('#timeRemaining').innerHtml = minutes.toString();
  int sec = 0;
  timerRemainingTime = new Timer.periodic(new Duration(seconds: 1), (_){
    sec++;
    if (sec == 60){
      sec = 0;
      minutes--;
      if (minutes == -1){
        timerRemainingTime.cancel();
        // this will produce a stack overflow if the page is left open for a very long time
        getEmailBatchInfos();
        return;
      }
      querySelector('#timeRemaining').innerHtml = minutes.toString();
    }
  });
}

void prepareEmailsButtons(){
  querySelector("#pauseRestartBtn").onClick.listen((MouseEvent evt){
    if (isEmailPaused)
      getMethod("restartEmailSending").then((_) => getEmailBatchInfos());
    else
      getMethod("pauseEmailSending").then((_) => getEmailBatchInfos());
  });
  querySelector("#prolongEmailBtn").onClick.listen((_){
    getMethod("prolongEmailSending").then(handleEmailBatchInfos);
  });
  querySelector("#shortenEmailBtn").onClick.listen((_){
    getMethod("shortenEmailSending").then(handleEmailBatchInfos);
  });
}

class Album {

  static String LastFM_API_KEY = "";

  static String ARTIST = "&&&INSERT_ARTIST_HERE&&&";
  static String ALBUM  = "&&&INSERT_ALBUM_HERE&&&";

  static String lastFMAlbumInfoUrl = "https://ws.audioscrobbler.com/2.0/?"
      "method=album.getinfo&api_key=$LastFM_API_KEY"
      "&artist=$ARTIST&album=$ALBUM&format=json";

  static String blankCoverArtUrl = "Album_cover_with_notes_01.png";

  String title;
  DateTime first_release_date;
  String primary_type;
  String artist;
  String mbid;

  String chosenImageUrl;

  DivElement artistDiv;
  DivElement imageDiv;

  bool isImageUrlSet = false;

  Album(Map json) {
    title = json["title"];
    first_release_date = DateFromString(json["first-release-date"]);
    primary_type = json["primary-type"];
    artist = json["artist"];
    mbid = json["mbid"];
    getImageUrl().then((_){
      if (imageDiv != null) {
        setImageUrl();
      }
    });
  }

  DivElement createDiv(){
    artistDiv = new DivElement();
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
    return imageWrapperDiv..append(imageDiv);
  }

  void setImageUrl(){
    imageDiv.style.backgroundImage = 'url("$chosenImageUrl")';
    isImageUrlSet = true;
  }

  Future getImageUrl() async {
    chosenImageUrl = _getCachedChosenImageUrl() ?? await _fetchChosenImageUrl();
    if (chosenImageUrl == "")
      chosenImageUrl = blankCoverArtUrl;
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