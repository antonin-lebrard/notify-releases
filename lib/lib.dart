library lib;


import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mailer/mailer.dart';
import 'package:notify_releases/simplehttpserver.dart';
import 'package:notify_releases/utils/utils.dart';
import 'package:notify_releases/models/model.dart';

part 'config.dart';
part 'lastfm.dart';
part 'musicbrainz.dart';
part 'tasks.dart';
part 'filehandling.dart';
part 'mbremote.dart';



TimerWrapper lastFmTimer;
TimerWrapper mailTimer;
