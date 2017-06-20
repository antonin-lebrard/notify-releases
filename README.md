# Notify Releases

Notify new releases from a list of artist you follow

The list of artist to follow is got through [LastFM](https://www.last.fm), so you will need an account there.
The list is updated each day.

Then the program will launch regular request to the MusicBrainz API to check any new release of each artist, one artist per request.

And every 30 minutes it will send a mail with the new releases (if found) it has found since then.

## What is needed to launch it :

- The [DartSDK](https://www.dartlang.org/install)
- A [LastFM](https://www.last.fm) account
- A mail account to use to deliver the new releases
- The email address of your mail account you which to receive at the new releases mails

## How to use it : 

Download it somewhere, then launch the `pub get` command to get the dependencies at the root of the `notify-releases` folder :
```bash
$> pub get
```
Then go inside the `bin` folder and edit the [config.json](https://github.com/antonin-lebrard/notify-releases/blob/master/bin/config.json) file

Some explanation for each parameter is in [this file](https://github.com/antonin-lebrard/notify-releases/blob/master/lib/config.dart)

An example of this file could be this one :
```json
{
  "lastFMUsername": "test",
  "daysToSubtract": 30,
  "mailSmtpHostname": "smtp.gmail.com",
  "mailSmtpPort": 465,
  "mailSmtpSecured": true,
  "mailSmtpUsername": "GmailUsername",
  "mailSmtpPassword": "GmailPassword",
  "mailAddressToContactForNewReleases": "my.main.address@hotmail.com"
}
```
