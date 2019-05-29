part of lib;





class Config {

  /**
   * LastFM API Key : used for all calls to the lastFM API
   */
  static String lastFMApiKey = "";

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

  /**
   * Interval of minutes at which the program should send the email to notify [mailAddressToContactForNewReleases]
   */
  static int minutesUntilNextMail = 60;

  /**
   * How many scrobbles an artist should have to be notified of its new releases
   */
  static int minPlayCountToNotify = 20;

  /**
   * Is the notification by email enabled ?
   * If this is not the case, no need to fill the next parameters,
   * they will never be used
   */
  static bool mailNotificationEnabled = false;

  /**
   * The smtp server hostname like "smtp.gmail.com" for example
   */
  static String mailSmtpHostname = "";

  /**
   * The smtp port, usually 465 for a secured one
   */
  static int mailSmtpPort = 465;

  /**
   * Is the smtp server secured by TLS or SSL
   * Warning : If not your password will be sent unencrypted through internet,
   * you should change your mail service if it's the case.
   */
  static bool mailSmtpSecured = true;

  /**
   * The username to use to connect to your mail account
   */
  static String mailSmtpUsername = "";

  /**
   * The password to use to connect to your mail account
   */
  static String mailSmtpPassword = "";

  /**
   * The mail address to send the messages to, when new releases need to be sent
   */
  static String mailAddressToContactForNewReleases = "";


  static Future loadConfigFromFile(String filename) async {
    File configFile = new File(filename);
    if (!(await configFile.exists())){
      configFile = new File("bin/$filename");
    }
    Map config = json.decode(await configFile.readAsString());
    lastFMApiKey = config["lastFMApiKey"] ?? "";
    lastFMUsername = config["lastFMUsername"] ?? "";
    daysToSubtract = config["daysToSubtract"] ?? 30;
    minutesUntilNextMail = config["minutesUntilNextMail"] ?? 60;
    minPlayCountToNotify = config["minPlayCountToNotify"] ?? 20;
    mailNotificationEnabled = config["mailNotificationEnabled"] ?? false;
    mailSmtpHostname = config["mailSmtpHostname"] ?? "";
    mailSmtpPort = config["mailSmtpPort"] ?? 465;
    mailSmtpSecured = config["mailSmtpSecured"] ?? true;
    mailSmtpUsername = config["mailSmtpUsername"] ?? "";
    mailSmtpPassword = config["mailSmtpPassword"] ?? "";
    mailAddressToContactForNewReleases = config["mailAddressToContactForNewReleases"] ?? "";
  }

}
