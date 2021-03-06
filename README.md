# Notify Releases

Notify new releases from a list of artist you follow

The list of artist to follow is got through [LastFM](https://www.last.fm), so you will need an account there.
The list is updated each day.

Then the program will launch regular request to the MusicBrainz API to check any new release of each artist, 
one artist per request.

The list of new releases can be browsed through a web page that communicate with the program via HTTP requests.

<b>Now Optional:</b> And every 30 minutes a mail might be sent with the new releases it has found since then.

<b>New:</b> Every week the program will lookup all the people you follow on LastFM, 
get all tracks they listened to, and for each tracks listened by at least two people, will generate a 'new release'
visible in the web page, or in the optional mails

### What is needed to launch it :

- The [DartSDK](https://www.dartlang.org/install)
- A [LastFM](https://www.last.fm) account, and an LastFM API key you can get by filling 
this form [LastFM API](https://www.last.fm/api/account/create) 
- <b>Now Optional:</b> A mail account to use to deliver the new releases 
(you have to know the smtp adress of the mail provider you use)
- <b>Now Optional:</b> The email address of your mail account on which you want to receive the new releases mails

### How to use it :

Download it somewhere, then launch the `pub get` command to get the dependencies at the root of the `notify-releases` folder:
```bash
~/Dev/notify-releases $> pub get
```
Then go inside the `bin` folder and edit the 
[config.json](https://github.com/antonin-lebrard/notify-releases/blob/master/bin/config.json) file

Some explanations for each parameter are in 
[this file](https://github.com/antonin-lebrard/notify-releases/blob/master/lib/config.dart)

An example of this file <b>without</b> mail notifications enabled could be this one :
```json
{
  "lastFMApiKey": "some long line of characters and numbers",
  "lastFMUsername": "test",
  "daysToSubtract": 30,
  "minutesUntilNextMail": 60,
  "minPlayCountToNotify": 10,
  "mailNotificationEnabled": false
}
```

Or an example of this file <b>with</b> mail notifications enabled could be this one :
```json
{
  "lastFMApiKey": "some long line of characters and numbers",
  "lastFMUsername": "test",
  "daysToSubtract": 30,
  "minutesUntilNextMail": 60,
  "minPlayCountToNotify": 10,
  "mailNotificationEnabled": true,
  "mailSmtpHostname": "smtp.gmail.com",
  "mailSmtpPort": 465,
  "mailSmtpSecured": true,
  "mailSmtpUsername": "GmailUsername",
  "mailSmtpPassword": "GmailPassword",
  "mailAddressToContactForNewReleases": "my.main.address@hotmail.com"
}
```

## The Web Part

The program comes with a web part that you can use to control it, 
or see a more adapted list of the release you have to check.

The list itself is independent of the ones sent in mail, so each mail you receive will not delete the records on this list.

![gif of the front end of the web part](https://github.com/antonin-lebrard/notify-releases/blob/master/test5.gif)

### How to use it

You will need to modify the `web/main.dart` file 
([link to it in github.com](https://github.com/antonin-lebrard/notify-releases/blob/master/web/main.dart))
to put your LastFM API key, and to put the http address of the program.

By default the program is listenning on "http://localhost:9100".

Then from the root of the project launch 
```bash
~/Dev/notify-releases $> pub build
```

You will have a new directory created at the root: `build/web`,
there you can launch the index.html file from any browser you want. 
