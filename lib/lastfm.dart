part of lib;



class LastFMRemote {

  static String _lastFmUri(String method, [Map<String, dynamic> queryParams]) {
    String lastfmBaseUrl = "http://ws.audioscrobbler.com/2.0/?method=${method}&api_key=${Config.lastFMApiKey}";

    if (queryParams == null || queryParams.isEmpty) {
      return "$lastfmBaseUrl&format=json";
    }
    String params = "";
    queryParams.forEach((String key, dynamic value) {
      params += "&$key=$value";
    });
    return "$lastfmBaseUrl$params&format=json";
  }

  static Future<List<T>> _commonPaginationFetch<T>(Future<int> fetchAndProcessPage(List<T> toFill, int page)) async {
    Completer<List<T>> completer = new Completer<List<T>>();
    List<T> content = new List<T>();
    int page = 1;
    StreamController controller = new StreamController();
    Stream stream = controller.stream;
    StreamSubscription sub;
    sub = stream.listen((_) async {
      int totalPage = await fetchAndProcessPage(content, page);
      page++;
      if (page <= totalPage){
        controller.add(null);
      } else {
        controller.close();
      }
    }, onDone: (){
      sub.cancel();
      completer.complete(content);
    });
    controller.add(null);
    return completer.future;
  }

  static Future<int> _commonPageFetch(String url, String topLevelKey, String contentKey, void processContent(List<Map> pageContent)) {
    Completer<int> completer = new Completer();
    http.get(url).then((http.Response resp) {
      Map body = json.decode(resp.body);
      /// error case (actually not handled for now)
      if (body.containsKey("error")) {
        print(url);
        print(body);
        return completer.completeError(new LastFMError(body["error"], body["message"]));
      }
      /// find the totalPages
      body = body[topLevelKey];
      int totalPages = int.parse(body["@attr"]["totalPages"] ?? "0", onError: (_) => 0);
      List<Map> content = castL<Map>(body[contentKey]);
      /// process the content (part not common to each lastfm page fetch)
      processContent(content);
      /// complete with totalPages
      completer.complete(totalPages);
    });
    return completer.future;
  }

  static Future<Map> _commonFetch(String url, String topLevelKey) {
    Completer<Map> completer = new Completer();
    http.get(url).then((http.Response resp) {
      Map body = json.decode(resp.body);
      /// error case (actually not handled for now)
      if (body.containsKey("error")) {
        print(url);
        print(body);
        return completer.completeError(new LastFMError(body["error"], body["message"]));
      }
      /// find the totalPages
      body = body[topLevelKey];
      completer.complete(body);
    });
    return completer.future;
  }

  static Future<int> _getFriendsPage(List<User> users, int page) {
    return _commonPageFetch(
        _lastFmUri("user.getfriends", { "user": Config.lastFMUsername, "page": page }),
        "friends",
        "user",
        (List<Map> usersContent) {
          for (Map user in usersContent) {
            users.add(new User(user));
          }
        }
    );
  }

  static Future<int> _getArtistPage(List<Artist> artists, int page) {
    return _commonPageFetch(
        _lastFmUri("library.getartists", { "user": Config.lastFMUsername, "page": page }),
        "artists",
        "artist",
        (List<Map> artistsContent) {
          for (Map artist in artistsContent) {
            if (artist["mbid"] != null &&
                artist["mbid"] != "" &&
                !artist["name"].toLowerCase().contains("feat.")) {
              artists.add(new Artist(artist));
            }
          }
        }
    );
  }

  static Future<List<User>> getFriends() async {
    return _commonPaginationFetch<User>(_getFriendsPage);
  }

  static Future<List<Artist>> getArtists() async {
    return _commonPaginationFetch<Artist>(_getArtistPage);
  }

  static Future<List<Album>> getWeeklyAlbums(String forUser) async {
    List<Album> toReturn = new List<Album>();
    return _commonPageFetch(
        _lastFmUri("user.getweeklyalbumchart", { "user": forUser }),
        "weeklyalbumchart",
        "album",
        (List<Map> albumsContent) {
          for (Map album in albumsContent) {
            toReturn.add(new Album(album));
          }
        }
    ).then((_) => toReturn);
  }

  static Future<List<Track>> getWeeklyTracks(String forUser) async {
    List<Track> toReturn = new List<Track>();
    return _commonPageFetch(
        _lastFmUri("user.getweeklytrackchart", { "user": forUser }),
        "weeklytrackchart",
        "track",
        (List<Map> tracksContent) {
          for (Map track in tracksContent) {
            toReturn.add(new Track(track));
          }
        }
    ).then((_) => toReturn);
  }

  static Future<Album> getAlbumFromTrack(String track, String artist) {
    return _commonFetch(
        _lastFmUri("track.getinfo", { "artist": artist, "track": track }),
        "track"
    ).then((Map track) {
      track["album"]["artist"] = track["artist"];
      return new Album(track["album"]);
    });
  }

}

class LastFMError {
  int code;
  String message;
  LastFMError(this.code, this.message);
  toString() => "$code : $message";
}
