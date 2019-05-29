
import 'dart:html';
import 'dart:convert';
import 'dart:async';
import 'package:notify_releases/utils/utils.dart';

/**
 * Needed for all request to LastFM API
 */
String LastFM_API_KEY = "";
/**
 * The http address to access the controls and releases list of the program
 */
String httpAddressRemoteServer = "http://localhost:9100";

List<Album> releasesBatch;
Timer timerRemainingTime;
bool isEmailPaused;
int middleMarginForIcons = 87;

Element elementLastClicked;

Future<String> get(String url, {Map<String, String> headers, String body}){
  Completer completer = new Completer<String>();
  String method = body == null ? "GET" : "POST";
  HttpRequest req = new HttpRequest()..open(method, url);
  headers?.forEach((String key, String value){
    req.setRequestHeader(key, value);
  });
  StreamSubscription sub;
  sub = req.onLoad.listen((_){
    if (req.status != 200){
      print("HTTP Request Error ${req.status}");
      completer.completeError(req.status);
      return;
    }
    completer.complete(req.responseText);
    sub.cancel();
  });
  req.send(body);
  return completer.future;
}

Future<String> getMethod(String method, {String body}) {
  return get(httpAddressRemoteServer, headers: {"method": method}, body: body);
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
    List<Map> batchJson = castL<Map>(json.decode(rep));
    releasesBatch =
      new List.generate(batchJson.length, (int idx) {
        if (DateFromString(batchJson[idx]["first-release-date"]).compareTo(new DateTime.now()) <= 0)
          return new Album(batchJson[idx]);
        return null;
      })..retainWhere((alb) => alb != null);
    querySelector("#listAlbums").children.clear();
    for (Album album in releasesBatch){
      if (album.first_release_date.compareTo(new DateTime.now()) <= 0) {
        querySelector("#listAlbums").append(album.createDiv());
      }
    }
  });
}

void getEmailBatchInfos(){
  getMethod("getEmailBatchInfos").then(handleEmailBatchInfos);
}

void handleEmailBatchInfos(String bodyRep){
  Map jsonMap = json.decode(bodyRep);
  if (jsonMap["timeRemaining"] == "Not enabled") {
    querySelector("#timeRemaining").innerHtml = "N/A";
    querySelector("#nbAlbumsToNotifyEmail").innerHtml = "0";
    querySelector("#header").style.display = "none";
  } else {
    querySelector("#header").style.display = "";
    List<String> timeRemainingString = jsonMap["timeRemaining"].split(":");
    Duration timeRemaining = new Duration(minutes: int.parse(timeRemainingString[0]),
        seconds: int.parse(timeRemainingString[1]));
    isEmailPaused = jsonMap["isEmailSendingPaused"];
    int nbReleasesToSend = jsonMap["nbReleasesToSend"];
    if (!isEmailPaused)
      launchTimeRemainingTimer(timeRemaining);
    else {
      querySelector('#timeRemaining').innerHtml = "N/A";
      timerRemainingTime?.cancel();
    }
    querySelector("#nbAlbumsToNotifyEmail").innerHtml = nbReleasesToSend.toString();
    querySelector("#pauseRestartBtn").innerHtml = isEmailPaused ? "Restart" : "Pause";
  }
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
      album.blur();
    }
  });
}

class SearchUrlHelper {

  static String googlePlayMusicSearchUrl = "https://play.google.com/music/listen?u=0#/sr/";
  static String deezerSearchUrl = "http://www.deezer.com/search/";
  static String spotifySearchUrl = "https://open.spotify.com/search/results/";
  static String searchBandcampUrl = "https://bandcamp.com/search?q=";

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

  static String searchBandcamp(String searchTerms){
    return searchBandcampUrl + Uri.encodeFull(searchTerms);
  }

}

class Album {

  static String ARTIST = "&&&INSERT_ARTIST_HERE&&&";
  static String ALBUM  = "&&&INSERT_ALBUM_HERE&&&";
  static String MBID  = "&&&INSERT_MBID_HERE&&&";

  static String lastFMAlbumInfoUrl = "https://ws.audioscrobbler.com/2.0/?"
      "method=album.getinfo&api_key=$LastFM_API_KEY"
      "&artist=$ARTIST&album=$ALBUM&format=json";

  static String lastFMArtistInfoUrl = "https://ws.audioscrobbler.com/2.0/?"
      "method=artist.getinfo&api_key=$LastFM_API_KEY"
      "&mbid=$MBID&format=json";

  static String blankCoverArtUrl = "Album_cover_with_notes_01.png";

  String title;
  DateTime first_release_date;
  String primary_type;
  String artist;
  String mbid;
  String bandcampUrl;

  String _chosenImageUrl;

  DivElement artistDiv;
  DivElement metadataWrapperDiv;
  DivElement imageWrapperDiv;
  DivElement clickableWrapperDiv;
  DivElement imageDiv;
  List<DivElement> icons = new List();

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
    bandcampUrl = json["bandcampUrl"];
    getImageUrl().then((_){
      _imageDivCreated.then((_){
        imageDiv.style.backgroundImage = 'url("$_chosenImageUrl")';
      });
    });
  }

  DivElement createDiv() {
    artistDiv = new DivElement();
    artistDiv.classes.add("artist");
    DivElement content = new DivElement();
    content.classes..add("content");
    artistDiv..append(content..append(_metadataDiv())..append(_imageDiv())..append(_clickableLinksDiv()));
    return artistDiv;
  }

  DivElement _metadataDiv() {
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

  void blur() {
    icons.forEach((DivElement d){
      d.style.marginLeft = "${middleMarginForIcons}px";
      d.style.marginTop = "${middleMarginForIcons}px";
    });
    clickableWrapperDiv.style.opacity = "";
    new Timer(new Duration(milliseconds: 500), (){
      clickableWrapperDiv.style.zIndex = "";
    });
    imageDiv.style.setProperty("-webkit-filter", "");
    metadataWrapperDiv.style.setProperty("-webkit-filter", "");
  }

  void focus() {
    clickableWrapperDiv.style.zIndex = "1";
    clickableWrapperDiv.style.opacity = "1";
    icons.forEach((DivElement d) {
      d.style.marginLeft = "";
      d.style.marginTop = "";
    });
    imageDiv.style.setProperty("-webkit-filter", "blur(3px)");
    metadataWrapperDiv.style.setProperty("-webkit-filter", "blur(1px)");
  }

  DivElement _imageDiv() {
    imageWrapperDiv = new DivElement();
    imageWrapperDiv.classes.add("imageWrapper");
    imageDiv = new DivElement();
    imageDiv.classes.add("image");
    _imageUrlSetCompleter.complete();
    imageWrapperDiv.onClick.listen((_) {
      focus();
    });
    return imageWrapperDiv..append(imageDiv);
  }

  DivElement _clickableLinksDiv() {
    clickableWrapperDiv = new DivElement();
    clickableWrapperDiv.classes.add("clickableWrapper");
    DivElement googleMusicDiv = new DivElement();
    googleMusicDiv.classes..add("icon")..add("googleMusic");
    googleMusicDiv.style.backgroundImage = "url('https://play-music.gstatic.com/fe/b9659330fe8ab3a7debed69d371b7063/favicon_96x96.png')";
    googleMusicDiv.onClick.listen((_) =>
        window.open(SearchUrlHelper.searchGoogleMusic("$title $artist"), "Search on Google Music"));
    DivElement deezerDiv = new DivElement();
    deezerDiv.classes..add("icon")..add("deezer");
    deezerDiv.style.backgroundImage = "url('https://e-cdns-files.dzcdn.net/img/common/ogdeezer.jpg')";
    deezerDiv.onClick.listen((_) =>
        window.open(SearchUrlHelper.searchDeezer("$title $artist"), "Search on Deezer"));
    DivElement bandcampDiv = new DivElement();
    bandcampDiv.classes..add("icon")..add("bandcamp");
    bandcampDiv.style.backgroundImage = "url('https://s4.bcbits.com/img/bc_favicon.ico')";
    bandcampDiv.onClick.listen((_) =>
        window.open(bandcampUrl ?? SearchUrlHelper.searchBandcamp("$artist $title"), "Search on Bandcamp"));
    DivElement deleteDiv = new DivElement();
    deleteDiv.classes..add("icon")..add("delete");
    deleteDiv.style.backgroundImage = "url('garbage.png')";
    deleteDiv.onClick.listen((_){
      List<Map<String, String>> encoding = new List()..add(this.toJson());
      getMethod("deleteReleases", body: json.encode(encoding)).then((_){
        window.localStorage.remove("$mbid $title");
        window.localStorage.remove(mbid);
        getWebBatch();
      });
    });
    icons..add(googleMusicDiv)..add(deezerDiv)..add(bandcampDiv)..add(deleteDiv);
    icons.forEach((DivElement d) {
      d.style.marginLeft = "${middleMarginForIcons}px";
      d.style.marginTop = "${middleMarginForIcons}px";
    });
    clickableWrapperDiv..append(googleMusicDiv)..append(deezerDiv)..append(bandcampDiv)..append(deleteDiv);
    return clickableWrapperDiv;
  }

  Future getImageUrl() async {
    _chosenImageUrl = _getCachedChosenImageUrl() ?? await _fetchChosenImageUrl();
    if (_chosenImageUrl == "")
      _chosenImageUrl = blankCoverArtUrl;
  }

  String _getCachedChosenImageUrl() {
    String cachedUrl = window.localStorage["$mbid $title"];
    if (cachedUrl == "" || cachedUrl == null){
      _refreshCache().then((_){
        if (window.localStorage["$mbid $title"] == "")
          _putArtistImageUrl();
      });
    }
    return cachedUrl;
  }

  Future _refreshCache() async {
    int lastCacheRefresh =
      window.localStorage["lastCacheRefresh"] != null
          ? int.parse(window.localStorage["lastCacheRefresh"], onError:(_) => 0)
          : 0;
    DateTime nowDate = new DateTime.now();
    // put the date into a int : 2017-07-18 19:10,59 will becomes 20170718191059 as int;
    int now = ComparableIntFromDate(nowDate);
    if (now - lastCacheRefresh > 5){
      String url = await _fetchChosenImageUrl();
      window.localStorage["lastCacheRefresh"] = now.toString();
      if (url != "")
        imageDiv.style.backgroundImage = 'url("$_chosenImageUrl")';
    }
  }

  Future _putArtistImageUrl() async {
    String url = _getCachedArtistImageUrl() ?? await _fetchArtistImageUrl();
    if (url != "" || url != null)
      imageDiv.style.backgroundImage = 'url("$url")';
  }

  Future<String> _fetchChosenImageUrl() {
    String lastFmAlbumInfo = lastFMAlbumInfoUrl
        .replaceFirst(ARTIST, Uri.encodeFull(artist))
        .replaceFirst(ALBUM, Uri.encodeFull(title));
    return get(lastFmAlbumInfo).then((String rep){
      Map jsonMap = json.decode(rep);
      if (jsonMap.containsKey("error")) {
        window.localStorage["$mbid $title"] = "";
        return "";
      }
      jsonMap = jsonMap["album"];
      List<Map> images = castL<Map>(jsonMap['image']);
      if (images != null) {
        for (int i = 0; i < images.length; i++) {
          if (images[i]['size'] == "large") {
            String imageUrl = images[i]['#text'];
            window.localStorage["$mbid $title"] = imageUrl;
            return imageUrl;
          }
        }
      }
    });
  }

  String _getCachedArtistImageUrl() {
    return window.localStorage[mbid];
  }

  Future<String> _fetchArtistImageUrl() {
    String lastFmArtistInfo = lastFMArtistInfoUrl
        .replaceFirst(MBID, mbid);
    return get(lastFmArtistInfo).then((String rep){
      Map jsonMap = json.decode(rep);
      if (jsonMap.containsKey("error"))
        return "";
      jsonMap = jsonMap["artist"];
      List<Map> images = castL<Map>(jsonMap['image']);
      if (images != null) {
        for (int i = 0; i < images.length; i++) {
          if (images[i]['size'] == "large") {
            String imageUrl = images[i]['#text'];
            window.localStorage[mbid] = imageUrl;
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
