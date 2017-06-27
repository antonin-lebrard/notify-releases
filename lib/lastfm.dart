part of lib;



class LastFMRemote {

  static Future<List<Artist>> getArtists() async {
    Completer<List<Artist>> completer = new Completer<List<Artist>>();
    List<Artist> artists = new List<Artist>();
    int page = 1;
    StreamController controller = new StreamController();
    Stream stream = controller.stream;
    StreamSubscription sub;
    sub = stream.listen((_) async {
      int totalPage = await getArtistPage(artists, page);
      page++;
      if (page <= totalPage){
        controller.add(null);
      } else {
        controller.close();
      }
    }, onDone: (){
      sub.cancel();
      completer.complete(artists);
    });
    controller.add(null);
    return completer.future;
  }

  static Future<int> getArtistPage(List<Artist> artists, int page){
    Completer<int> completer = new Completer();
    String url = "http://ws.audioscrobbler.com/2.0/?method=library.getartists&api_key=${Config.lastFMApiKey}&user=${Config.lastFMUsername}&page=$page&format=json";
    http.get(url).then((http.Response resp) {
      Map content = JSON.decode(resp.body);
      if (content.containsKey("error")){
        print(content);
        return completer.completeError(new LastFMError(content["error"], content["message"]));
      }
      content = content["artists"];
      int totalPages = int.parse(content["@attr"]["totalPages"]);
      List artistsContent = content["artist"];
      print(content["@attr"]);
      for (Map artist in artistsContent) {
        if (artist["mbid"] != null &&
                artist["mbid"] != "" &&
                !artist["name"].toLowerCase().contains("feat.")) {
          artists.add(new Artist(artist));
        }
      }
      completer.complete(totalPages);
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