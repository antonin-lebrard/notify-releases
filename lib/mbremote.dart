part of lib;


/**
 * For the moment, not working as intended
 */
class MBRemote {

  static String rootAPIUri = "https://musicbrainz.org/ws/2/artist/";
  static String suffixApi = "?inc=release-groups&fmt=json";

  static DateTime lastXRatelimitReset = new DateTime.now();

  static Future<String> doRequest(String mbid) async {
    DateTime now = new DateTime.now();
    if (lastXRatelimitReset.isAfter(now))
      await waitForDuration(now.difference(lastXRatelimitReset));
    String url = rootAPIUri + mbid + suffixApi;
    return http.get(url).then((http.Response resp){
      String xRatelimit = resp.headers["x-ratelimit-reset"];
      if (xRatelimit == null){
        print(resp.headers);
        print(resp.body);
      }
      else
        print(xRatelimit);
      if (xRatelimit == null || xRatelimit == "")
        xRatelimit = (now.add(new Duration(seconds: 30)).millisecondsSinceEpoch / 1000).floor().toString();
      int convertRatelimit = int.parse(xRatelimit) * 1000 + 2;
      lastXRatelimitReset = new DateTime.fromMillisecondsSinceEpoch(convertRatelimit);
      return resp.body;
    });
  }

}