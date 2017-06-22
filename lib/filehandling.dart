part of lib;


enum StorageFile {
  lastFMList
}

class FileToBlock {
  File fileToBlock;
  bool isBlocked = false;
  StreamController<bool> _noLongerBlocked = new StreamController<bool>.broadcast();
  Stream<bool> noLongerBlocked;
  FileToBlock(String path){
    if (Directory.current.path.endsWith("bin"))
      fileToBlock = new File(path);
    else
      fileToBlock = new File("bin/" + path);
    noLongerBlocked = _noLongerBlocked.stream;
  }
  /// [toDoDuringBlock] has to be synced
  String block(String toDoDuringBlock()) {
    isBlocked = true;
    String res = toDoDuringBlock();
    isBlocked = false;
    _noLongerBlocked.add(true);
    return res;
  }
}

class FileHandling {

  static FileToBlock lastFMList = new FileToBlock("lastFMList.json");

  static FileToBlock mbLastRelease = new FileToBlock("mbLastRelease.json");

  static FileToBlock batchReleaseToNotify = new FileToBlock("batch.json");

  static FileToBlock webBatchRelease = new FileToBlock("webBatch.json");

  static Future writeToFile(FileToBlock file, String content){
    Completer completer = new Completer();
    if (!file.isBlocked){
      _writeToFile(file, content);
      completer.complete(null);
    } else {
      StreamSubscription<bool> sub;
      sub = file.noLongerBlocked.listen((bool isNoLongerBlocked){
        if (isNoLongerBlocked) {
          _writeToFile(file, content);
          sub.cancel();
          completer.complete(null);
        }
      });
    }
    return completer.future;
  }

  static Future<String> readFile(FileToBlock file){
    Completer<String> completer = new Completer<String>();
    if (!file.isBlocked){
      completer.complete(_readFile(file));
    } else {
      StreamSubscription<bool> sub;
      sub = file.noLongerBlocked.listen((bool isNoLongerBlocked){
        if (isNoLongerBlocked) {
          sub.cancel();
          completer.complete(_readFile(file));
        }
      });
    }
    return completer.future;
  }

  static void _writeToFile(FileToBlock file, String content){
    file.block((){
      file.fileToBlock.writeAsStringSync(content);
    });
  }

  static String _readFile(FileToBlock file){
    return file.block((){
      return file.fileToBlock.readAsStringSync();
    });
  }
}