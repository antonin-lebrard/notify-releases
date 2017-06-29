
import 'dart:html';
import 'dart:convert';
import 'dart:async';
import 'package:notify_releases/utils/utils.dart';

List<Album> releasesBatch;
Timer timerRemainingTime;
bool isEmailPaused;

Element elementLastClicked;

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
  window.onClick.listen((MouseEvent event){
    manualBlur(elementLastClicked);
    elementLastClicked = event.target;
  });
  getWebBatch();
  getEmailBatchInfos();
  prepareEmailsButtons();
}

void getWebBatch(){
  getMethod("getWebBatch").then((String rep){
    List<Map> batchJson = JSON.decode(rep);
    releasesBatch = new List.generate(batchJson.length, (int idx) => new Album(batchJson[idx]));
    querySelector("#listAlbums").children.clear();
    for (Album album in releasesBatch){
      querySelector("#listAlbums").append(album.createDiv());
    }
  });
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

void manualBlur(Element element){
  if (element == null) return;
  releasesBatch.forEach((Album album){
    if (album.imageWrapperDiv == element){
      album.clickableWrapperDiv.style.zIndex = "";
      album.imageDiv.style.setProperty("-webkit-filter", "");
      album.metadataWrapperDiv.style.setProperty("-webkit-filter", "");
    }
  });
}

class SearchUrlHelper {

  static String googlePlayMusicSearchUrl = "https://play.google.com/music/listen?u=0#/sr/";
  static String deezerSearchUrl = "http://www.deezer.com/search/";
  static String spotifySearchUrl = "https://open.spotify.com/search/results/";

  static String searchGoogleMusic(String searchTerms){
    List<String> toEncode = searchTerms.split(" ");
    toEncode = toEncode.map<String>((String s) => Uri.encodeFull(s)).toList(growable: false);
    String search = toEncode.join("+");
    return googlePlayMusicSearchUrl + search;
  }

  static String searchDeezer(String searchTerms){
    return deezerSearchUrl + Uri.encodeFull(searchTerms);
  }
  
  static String searchSpotify(String searchTerms){
    return spotifySearchUrl + Uri.encodeFull(searchTerms);
  }

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

  String _chosenImageUrl;

  DivElement artistDiv;
  DivElement metadataWrapperDiv;
  DivElement imageWrapperDiv;
  DivElement clickableWrapperDiv;
  DivElement imageDiv;

  Completer _imageUrlSetCompleter;
  Future _imageDivCreated;

  Album(Map json) {
    _imageUrlSetCompleter = new Completer();
    _imageDivCreated = _imageUrlSetCompleter.future;
    title = json["title"];
    first_release_date = DateFromString(json["first-release-date"]);
    primary_type = json["primary-type"];
    artist = json["artist"];
    mbid = json["mbid"];
    getImageUrl().then((_){
      _imageDivCreated.then((_){
        imageDiv.style.backgroundImage = 'url("$_chosenImageUrl")';
      });
    });
  }

  DivElement createDiv(){
    artistDiv = new DivElement();
    artistDiv.classes.add("artist");
    DivElement content = new DivElement();
    content.classes..add("content");
    artistDiv..append(content..append(_metadataDiv())..append(_imageDiv())..append(_clickableLinksDiv()));
    return artistDiv;
  }

  DivElement _metadataDiv(){
    metadataWrapperDiv = new DivElement();
    metadataWrapperDiv.classes.add("metadataWrapper");
    DivElement titleDiv = new DivElement();
    titleDiv.classes.add("name");
    DivElement artistNameDiv = new DivElement();
    artistNameDiv.classes.add("artistName");
    titleDiv.text = this.title.length > 24 ? this.title.substring(0, 21) + "..." : this.title;
    artistNameDiv.text = this.artist.length > 24 ? this.artist.substring(0, 21) + "..." : this.artist;
    return metadataWrapperDiv..append(titleDiv)..append(artistNameDiv);
  }

  DivElement _imageDiv(){
    imageWrapperDiv = new DivElement();
    imageWrapperDiv.classes.add("imageWrapper");
    imageDiv = new DivElement();
    imageDiv.classes.add("image");
    _imageUrlSetCompleter.complete();
    imageWrapperDiv.onClick.listen((_) {
      clickableWrapperDiv.style.zIndex = "1";
      imageDiv.style.setProperty("-webkit-filter", "blur(3px)");
      metadataWrapperDiv.style.setProperty("-webkit-filter", "blur(1px)");
    });
    return imageWrapperDiv..append(imageDiv);
  }

  DivElement _clickableLinksDiv(){
    clickableWrapperDiv = new DivElement();
    clickableWrapperDiv.classes.add("clickableWrapper");
    DivElement googleMusicDiv = new DivElement();
    googleMusicDiv.classes..add("icon")..add("googleMusic");
    googleMusicDiv.style.backgroundImage = "url('https://play-music.gstatic.com/fe/b9659330fe8ab3a7debed69d371b7063/favicon_96x96.png')";
    googleMusicDiv.onClick.listen((_) =>
        window.open(SearchUrlHelper.searchGoogleMusic("$title $artist"), "Search on Google Music"));
    DivElement deezerDiv = new DivElement();
    deezerDiv.classes..add("icon")..add("deezer");
    deezerDiv.style.backgroundImage = "url('https://e-cdns-files.dzcdn.net/images/common/favicon/favicon-96x96-v00400039.png')";
    deezerDiv.onClick.listen((_) =>
        window.open(SearchUrlHelper.searchDeezer("$title $artist"), "Search on Deezer"));
    DivElement spotifyDiv = new DivElement();
    spotifyDiv.classes..add("icon")..add("spotify");
    spotifyDiv.style.backgroundImage = "url('https://play.spotify.edgekey.net/site/e244a4f/images/favicon.png')";
    spotifyDiv.onClick.listen((_) =>
        window.open(SearchUrlHelper.searchSpotify("$title $artist"), "Search on Spotify"));
    DivElement deleteDiv = new DivElement();
    deleteDiv.classes..add("icon")..add("delete");
    deleteDiv.style.backgroundImage = "url('garbage.png')";
    deleteDiv.onClick.listen((_){
      List<Map<String, String>> encoding = new List()..add(this);
      getMethod("deleteReleases", body: JSON.encode(encoding)).then((_){
        getWebBatch();
      });
    });
    clickableWrapperDiv..append(googleMusicDiv)..append(deezerDiv)..append(spotifyDiv)..append(deleteDiv);
    return clickableWrapperDiv;
  }

  Future getImageUrl() async {
    _chosenImageUrl = _getCachedChosenImageUrl() ?? await _fetchChosenImageUrl();
    if (_chosenImageUrl == "")
      _chosenImageUrl = blankCoverArtUrl;
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

  Map<String, String> toJson() {
    return {
      "title": title,
      "first-release-date": StringFromDate(first_release_date),
      "primary-type": primary_type,
      "artist": artist,
      "mbid": mbid
    };
  }


}