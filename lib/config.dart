part of lib;





class Config {

  /**
   * LastFM username : used to get the list of artist to follow
   * The list will be fetched once a day to check new artist
   */
  static String lastFMUsername = "";

  /**
   * The days to subtract to [DateTime.now()] serving as first lastReleaseDate
   * For the first launch of the program, the program will generate the list of artist to follow from your LastFM account,
   * But it needs a Date from which it can say any album from any artist is new.
   */
  static int daysToSubtract = 30;


}