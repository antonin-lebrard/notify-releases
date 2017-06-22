part of lib;



class LastFMFetching {

  static String API_KEY = "";

  StreamController<int> _loading = new StreamController.broadcast();
  Stream<int> loading;
  StreamController<LastFMError> _onError = new StreamController.broadcast();
  Stream<LastFMError> onError;

  Map attr = {
    "totalPages": "2",
    "isFake": true
  };

  LastFMFetching(){
    loading = _loading.stream;
    onError = _onError.stream;
  }

  Future<List<Artist>> getArtists(List<Artist> artists, [int page=1]){
    if (page > int.parse(attr['totalPages'])){
      return new Future.value(artists);
    }
    Completer completer = new Completer();
    if (attr['isFake'] == null || !attr['isFake']){
      int loadingPercentage = ((page / int.parse(attr['totalPages'])) * 100).toInt();
      _loading.add(loadingPercentage);
    }
    getArtistPage(page).then((List<Artist> artistsPage){
      artists.addAll(artistsPage);
      _loading.add(100);
      completer.complete(getArtists(artists, ++page));
    }).catchError((LastFMError error){
      _onError.add(error);
    });
    return completer.future as Future<List<Artist>>;
  }

  Future<List<Artist>> getArtistPage([int page = 0]){
    Completer<List<Artist>> completer = new Completer();
    List<Artist> artistsPage = new List();
    String url = "http://ws.audioscrobbler.com/2.0/?method=library.getartists&api_key=$API_KEY&user=${Config.lastFMUsername}&format=json";
    if (page > 0){
      url += "&page=$page";
    }
    http.get(url).then((http.Response resp) {
      Map content = JSON.decode(resp.body);
      if (content.containsKey("error")){
        print(content);
        return completer.completeError(new LastFMError(content["error"], content["message"]));
      }
      content = content["artists"];
      attr = content["@attr"];
      List artistsContent = content["artist"];
      print(attr);
      for (Map artist in artistsContent) {
        if (artist["mbid"] != null && artist["mbid"] != "" && !artist["name"].toLowerCase().contains("feat.")) {
          artistsPage.add(new Artist(artist));
        }
      }
      completer.complete(artistsPage);
    });
    return completer.future;
  }

}

class LastFMError {
  int code;
  String message;
  LastFMError(this.code, this.message);
  toString() => "$code : $message";
}