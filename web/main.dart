
import 'dart:html';
import 'dart:convert';
import 'package:http/browser_client.dart';
import 'package:http/http.dart';
import 'package:notify_releases/lib.dart' show ReleaseGroup;

List<ReleaseGroup> releasesBatch;

void main() {
  new BrowserClient().get("http://localhost:9100", headers: {"method": "getWebBatch"}).then((Response rep){
    List<Map> batchJson = JSON.decode(rep.body);
    releasesBatch = new List.generate(batchJson.length, (int idx) => new ReleaseGroup.mapWithArtistAndMbid(batchJson[idx]));
    display();
  });
}

void display(){
  for (ReleaseGroup rel in releasesBatch){
    document.body.appendHtml("<div>${rel.artist} has released a new ${rel.primary_type} named ${rel.title}");
  }
}