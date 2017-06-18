# Notify Releases

Notify new releases from a list of artist you follow

You will need the [Dart SDK](https://www.dartlang.org/tools/sdk) to launch it

The list of artist to follow is got through [LastFM](https://www.last.fm), so you will need an account there.
The list is updated each day.

Then the program will launch regular request to the MusicBrainz API to check any new release of each artist, one artist per request.

For the moment it only save each new release in a json file called batch.json, but there may be some evolution to send an email 
for example with a list of new release to check.
